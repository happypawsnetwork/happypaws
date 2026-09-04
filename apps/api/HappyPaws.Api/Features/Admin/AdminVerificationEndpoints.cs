using System;
using System.Collections.Generic;
using System.Linq;
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

namespace HappyPaws.Api.Features.Admin;

public sealed class AdminVerificationEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/verifications")
            .WithTags("Admin Verifications")
            .RequireAuthorization();

        group.MapGet("/", ListVerificationsAsync)
            .WithName("ListAdminVerifications")
            .WithSummary("List verification requests with optional filters");

        group.MapPut("/{id:long}/approve", ApproveVerificationAsync)
            .WithName("ApproveAdminVerification")
            .WithSummary("Approve a verification request");

        group.MapPut("/{id:long}/reject", RejectVerificationAsync)
            .WithName("RejectAdminVerification")
            .WithSummary("Reject a verification request");
    }

    private static async Task<Ok<AdminVerificationListResponse>> ListVerificationsAsync(
        [AsParameters] AdminVerificationListQuery query,
        IApplicationDbContext db,
        IStorageService storageService,
        CancellationToken ct)
    {
        var q = db.VerificationRequests
            .Include(v => v.User)
            .Include(v => v.Documents)
            .AsQueryable();

        if (query.Status.HasValue)
        {
            q = q.Where(v => v.Status == query.Status.Value);
        }

        if (query.Role.HasValue)
        {
            q = q.Where(v => v.RequestedRole == query.Role.Value);
        }

        var total = await q.CountAsync(ct);

        var items = await q
            .OrderByDescending(v => v.CreatedAt)
            .Skip((query.Page - 1) * query.Limit)
            .Take(query.Limit)
            .ToListAsync(ct);

        var dtos = new List<AdminVerificationDto>();

        foreach (var item in items)
        {
            var docs = new List<AdminVerificationDocumentDto>();
            foreach (var doc in item.Documents)
            {
                var presignedUrl = await storageService.GetPresignedUrlAsync(doc.DocumentUri, TimeSpan.FromHours(1), ct);
                docs.Add(new AdminVerificationDocumentDto(doc.DocumentType.ToString(), presignedUrl));
            }

            dtos.Add(new AdminVerificationDto(
                item.Id,
                item.UserId,
                $"{item.User.FirstName} {item.User.LastName}".Trim(),
                item.RequestedRole.ToString(),
                item.Status.ToString(),
                item.CreatedAt,
                docs
            ));
        }

        return TypedResults.Ok(new AdminVerificationListResponse(dtos, total, query.Page, query.Limit));
    }

    private static async Task<Results<Ok, NotFound, BadRequest<string>>> ApproveVerificationAsync(
        long id,
        IApplicationDbContext db,
        ILogger<AdminVerificationEndpoints> logger,
        IStorageService storageService,
        CancellationToken ct)
    {
        var request = await db.VerificationRequests
            .Include(v => v.User)
            .ThenInclude(u => u.Roles)
            .Include(v => v.Documents)
            .FirstOrDefaultAsync(v => v.Id == id, ct);

        if (request is null) return TypedResults.NotFound();
        if (request.Status != VerificationStatus.Pending) return TypedResults.BadRequest("Request is already processed.");

        request.Status = VerificationStatus.Approved;
        request.UpdatedAt = DateTime.UtcNow;

        var existingRole = request.User.Roles.FirstOrDefault(r => r.RoleName == request.RequestedRole);
        if (existingRole is not null)
        {
            existingRole.IsVerified = true;
        }
        else
        {
            request.User.AddRole(request.RequestedRole, isVerified: true);
        }

        // Delete associated doc assets from private bucket
        foreach (var doc in request.Documents)
        {
            try
            {
                await storageService.DeletePrivateFileAsync(doc.DocumentUri, ct);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to delete private file {Key}", doc.DocumentUri);
            }
        }
        // Optionally remove the documents from DB so they aren't generated as presigned URLs anymore
        db.VerificationDocuments.RemoveRange(request.Documents);

        await db.SaveChangesAsync(ct);
        logger.LogInformation("[Admin] Approved verification request {Id} for User {UserId} as {Role}", id, request.UserId, request.RequestedRole);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, NotFound, BadRequest<string>>> RejectVerificationAsync(
        long id,
        IApplicationDbContext db,
        ILogger<AdminVerificationEndpoints> logger,
        IStorageService storageService,
        CancellationToken ct)
    {
        var request = await db.VerificationRequests
            .Include(v => v.Documents)
            .FirstOrDefaultAsync(v => v.Id == id, ct);

        if (request is null) return TypedResults.NotFound();
        if (request.Status != VerificationStatus.Pending) return TypedResults.BadRequest("Request is already processed.");

        request.Status = VerificationStatus.Rejected;
        request.UpdatedAt = DateTime.UtcNow;

        foreach (var doc in request.Documents)
        {
            try
            {
                await storageService.DeletePrivateFileAsync(doc.DocumentUri, ct);
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "Failed to delete private file {Key}", doc.DocumentUri);
            }
        }
        db.VerificationDocuments.RemoveRange(request.Documents);

        await db.SaveChangesAsync(ct);
        logger.LogInformation("[Admin] Rejected verification request {Id} for User {UserId}", id, request.UserId);

        return TypedResults.Ok();
    }
}

public record AdminVerificationListQuery(int Page = 1, int Limit = 50, VerificationStatus? Status = null, RoleName? Role = null);
public record AdminVerificationDocumentDto(string DocumentType, string PresignedUrl);
public record AdminVerificationDto(long Id, long UserId, string UserName, string RequestedRole, string Status, DateTimeOffset CreatedAt, List<AdminVerificationDocumentDto> Documents);
public record AdminVerificationListResponse(List<AdminVerificationDto> Items, int TotalCount, int Page, int Limit);
