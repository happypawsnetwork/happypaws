using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Api.Features.Verification;

public record RoleVerificationStatusDto(
    string Role,
    string Status
);

public record VerificationStatusResponse(
    IReadOnlyList<RoleVerificationStatusDto> Roles
);

public record UploadDocumentResponse(
    string DocumentUri,
    string DocumentType
);

public record VerificationDocumentDto(
    DocumentType DocumentType,
    string DocumentUri
);

public record SubmitVerificationRequest(
    RoleName RequestedRole,
    List<VerificationDocumentDto> Documents
);

public sealed class VerificationEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/verification").RequireAuthorization();

        group.MapGet("/status", GetVerificationStatusAsync)
            .WithName("GetVerificationStatus")
            .WithTags("Verification")
            .WithSummary("Get identity verification statuses for all roles")
            .WithDescription("Retrieves the verification state for each role for the authenticated user.")
            .Produces<VerificationStatusResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/upload", UploadDocumentAsync)
            .WithName("UploadVerificationDocument")
            .WithTags("Verification")
            .WithSummary("Upload a private verification document")
            .WithDescription("Uploads an identity document directly to private object storage.")
            .Produces<UploadDocumentResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .DisableAntiforgery();

        group.MapPost("/submit", SubmitVerificationAsync)
            .WithName("SubmitVerificationRequest")
            .WithTags("Verification")
            .WithSummary("Submit an identity verification application for a role")
            .WithDescription("Creates a new verification request with uploaded document references for staff review.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static async Task<Results<Ok<VerificationStatusResponse>, UnauthorizedHttpResult, NotFound>> GetVerificationStatusAsync(
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        var existingRequests = await db.VerificationRequests
            .AsNoTracking()
            .Where(r => r.UserId == userId)
            .OrderByDescending(r => r.CreatedAt)
            .ToListAsync(ct);

        var verifiableRoles = new[]
        {
            RoleName.Adopter,
            RoleName.Foster,
            RoleName.Sponsor,
            RoleName.Transporter,
            RoleName.Veterinarian
        };

        var roleStatuses = new List<RoleVerificationStatusDto>();

        foreach (var role in verifiableRoles)
        {
            var userRole = user.Roles.FirstOrDefault(r => r.RoleName == role);
            if (userRole != null && userRole.IsVerified)
            {
                roleStatuses.Add(new RoleVerificationStatusDto(role.ToString(), "Verified"));
                continue;
            }

            var request = existingRequests.FirstOrDefault(r => r.RequestedRole == role);
            if (request != null)
            {
                roleStatuses.Add(new RoleVerificationStatusDto(role.ToString(), request.Status.ToString()));
            }
            else
            {
                roleStatuses.Add(new RoleVerificationStatusDto(role.ToString(), "Unverified"));
            }
        }

        return TypedResults.Ok(new VerificationStatusResponse(roleStatuses));
    }

    private static async Task<Results<Ok<UploadDocumentResponse>, BadRequest<string>, UnauthorizedHttpResult, NotFound>> UploadDocumentAsync(
        IFormFile file,
        DocumentType documentType,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        IStorageService storageService,
        ILogger<VerificationEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        if (file.Length == 0)
        {
            return TypedResults.BadRequest("Uploaded document is empty.");
        }

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (string.IsNullOrEmpty(ext))
        {
            ext = ".jpg";
        }

        var contentType = file.ContentType;
        if (string.IsNullOrWhiteSpace(contentType) || contentType.Equals("application/octet-stream", StringComparison.OrdinalIgnoreCase))
        {
            contentType = ext switch
            {
                ".png" => "image/png",
                ".webp" => "image/webp",
                ".pdf" => "application/pdf",
                _ => "image/jpeg"
            };
        }

        var key = $"kyc/{userId}/{documentType}_{Guid.NewGuid()}{ext}";

        using var stream = file.OpenReadStream();
        await storageService.UploadPrivateFileAsync(key, stream, contentType, ct);

        logger.LogInformation("[Verification] Uploaded {DocumentType} for user {UserId} with key {Key}", documentType, userId, key);

        return TypedResults.Ok(new UploadDocumentResponse(key, documentType.ToString()));
    }

    private static async Task<Results<Ok, BadRequest<string>, UnauthorizedHttpResult, NotFound>> SubmitVerificationAsync(
        SubmitVerificationRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<VerificationEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        var userRole = user.Roles.FirstOrDefault(r => r.RoleName == request.RequestedRole);
        if (userRole != null && userRole.IsVerified)
        {
            return TypedResults.BadRequest("You are already verified for this role.");
        }

        var existingPending = await db.VerificationRequests
            .AnyAsync(r => r.UserId == userId && r.RequestedRole == request.RequestedRole && r.Status == VerificationStatus.Pending, ct);

        if (existingPending)
        {
            return TypedResults.BadRequest("You already have a pending verification request for this role.");
        }

        if (request.Documents == null || request.Documents.Count == 0)
        {
            return TypedResults.BadRequest("At least one document must be uploaded.");
        }

        var verificationRequest = new VerificationRequest
        {
            UserId = userId,
            RequestedRole = request.RequestedRole,
            Status = VerificationStatus.Pending,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        foreach (var doc in request.Documents)
        {
            verificationRequest.AddDocument(doc.DocumentType, doc.DocumentUri);
        }

        db.VerificationRequests.Add(verificationRequest);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Verification] User {UserId} submitted verification request for {RequestedRole} with {Count} documents",
            userId, request.RequestedRole, request.Documents.Count);

        return TypedResults.Ok();
    }
}

