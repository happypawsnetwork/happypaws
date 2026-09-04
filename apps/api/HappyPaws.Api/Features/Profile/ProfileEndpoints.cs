using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Distributed;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Api.Features.Profile;

public sealed class ProfileEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/profile").RequireAuthorization();

        group.MapGet("/", GetProfileAsync)
            .WithName("GetProfile")
            .WithTags("Profile")
            .WithSummary("Get authenticated user profile details")
            .WithDescription("Retrieves the full profile of the authenticated user including personal details, roles, and reputation points.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapGet("/public/{userId:long}", GetPublicProfileAsync)
            .WithName("GetPublicProfile")
            .WithTags("Profile")
            .WithSummary("Get user public profile")
            .WithDescription("Retrieves public profile details and visible posts for a given user ID.")
            .Produces<PublicUserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPut("/", UpdateProfileAsync)
            .WithName("UpdateProfile")
            .WithTags("Profile")
            .WithSummary("Update user profile personal details")
            .WithDescription("Updates the user's first name, last name, phone number, and tagline.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapGet("/check-username", CheckUsernameAvailabilityAsync)
            .WithName("CheckUsernameAvailability")
            .WithTags("Profile")
            .WithSummary("Check username availability")
            .WithDescription("Checks if a given username is available.")
            .Produces<bool>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapPut("/tagline", SetTaglineAsync)
            .WithName("SetProfileTagline")
            .WithTags("Profile")
            .WithSummary("Set or update user profile tagline")
            .WithDescription("Updates the short tagline headline for the authenticated user account.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/avatar", UploadAvatarAsync)
            .WithName("UploadProfileAvatar")
            .WithTags("Profile")
            .WithSummary("Upload and set user profile avatar")
            .WithDescription("Uploads an image file to object storage and updates the user avatar URL.")
            .Produces<UploadAvatarResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound)
            .DisableAntiforgery();

        group.MapDelete("/avatar", DeleteAvatarAsync)
            .WithName("DeleteProfileAvatar")
            .WithTags("Profile")
            .WithSummary("Remove user profile avatar")
            .WithDescription("Removes the user profile avatar and deletes the stored image file from object storage.")
            .Produces<UserProfileResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/email/send-code", SendEmailUpdateCodeAsync)
            .WithName("SendEmailUpdateCode")
            .WithTags("Profile")
            .WithSummary("Send email update verification code")
            .WithDescription("Dispatches a 6-digit OTP to the requested new email address.")
            .Produces<VerificationTokenResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/email/verify-code", VerifyEmailUpdateCodeAsync)
            .WithName("VerifyEmailUpdateCode")
            .WithTags("Profile")
            .WithSummary("Verify email update code and save new email")
            .WithDescription("Verifies the submitted OTP and commits the new email address to the user account.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/password", ChangePasswordAsync)
            .WithName("ChangeProfilePassword")
            .WithTags("Profile")
            .WithSummary("Change account password")
            .WithDescription("Verifies the current password and hashes the new password, revoking other active sessions.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapGet("/sessions", GetSessionsAsync)
            .WithName("GetProfileSessions")
            .WithTags("Profile")
            .WithSummary("Get active user login sessions")
            .WithDescription("Retrieves the list of active refresh token sessions associated with the user account.")
            .Produces<IReadOnlyList<UserSessionDto>>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapDelete("/sessions/{id:guid}", RevokeSessionAsync)
            .WithName("RevokeProfileSession")
            .WithTags("Profile")
            .WithSummary("Revoke an active session")
            .WithDescription("Terminates a specific login session by revoking its refresh token.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/sessions/revoke-others", RevokeOtherSessionsAsync)
            .WithName("RevokeOtherProfileSessions")
            .WithTags("Profile")
            .WithSummary("Revoke all other active sessions")
            .WithDescription("Terminates all active login sessions across devices.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapGet("/lifestyle", GetLifestyleProfileAsync)
            .WithName("GetLifestyleProfile")
            .WithTags("Profile")
            .WithSummary("Get lifestyle profile")
            .WithDescription("Retrieves the user's lifestyle profile.")
            .Produces<LifestyleDto>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPut("/lifestyle", UpdateLifestyleProfileAsync)
            .WithName("UpdateLifestyleProfile")
            .WithTags("Profile")
            .WithSummary("Update lifestyle profile")
            .WithDescription("Updates the user's lifestyle profile.")
            .Produces<LifestyleDto>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPut("/roles/visibility", ToggleRoleVisibilityAsync)
            .WithName("ToggleProfileRoleVisibility")
            .WithTags("Profile")
            .WithSummary("Toggle user profile role visibility")
            .WithDescription("Updates whether a specific assigned role is publicly visible on the user profile.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static async Task<Results<Ok<bool>, BadRequest<string>, UnauthorizedHttpResult>> CheckUsernameAvailabilityAsync(
        string username,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(username))
        {
            return TypedResults.BadRequest("Username cannot be empty.");
        }

        var newUsername = username.Trim().ToLowerInvariant();
        if (!System.Text.RegularExpressions.Regex.IsMatch(newUsername, @"^[a-z0-9_]{3,30}$"))
        {
            return TypedResults.BadRequest("Username must be 3-30 characters long and contain only lowercase letters, numbers, and underscores.");
        }

        var isTaken = await db.Users.AnyAsync(u => u.Username == newUsername && u.Id != userId, ct);
        return TypedResults.Ok(!isTaken);
    }

    private static async Task<Results<Ok<UserProfileResponse>, UnauthorizedHttpResult, NotFound>> GetProfileAsync(
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

        var response = new UserProfileResponse(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.PhoneNumber,
            user.AvatarUrl,
            user.Tagline,
            user.Username,
            user.ReputationPoints,
            user.Roles.Select(r => r.RoleName.ToString()).ToList(),
            user.CreatedAt,
            user.UpdatedAt,
            user.AddressLine1,
            user.AddressLine2,
            user.City,
            user.State,
            user.PostalCode,
            user.Country,
            user.HomeLatitude,
            user.HomeLongitude,
            user.ReceiveMessages
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Ok<UserProfileResponse>, BadRequest<string>, UnauthorizedHttpResult, NotFound>> UpdateProfileAsync(
        UpdateProfileRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        if (!string.IsNullOrWhiteSpace(request.FirstName))
        {
            user.FirstName = request.FirstName.Trim();
            user.LastName = request.LastName?.Trim() ?? string.Empty;
        }
        else if (!string.IsNullOrWhiteSpace(request.Name))
        {
            var names = request.Name.Trim().Split(' ', 2);
            user.FirstName = names[0];
            user.LastName = names.Length > 1 ? names[1] : string.Empty;
        }

        if (request.PhoneNumber != null)
        {
            user.PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim();
        }

        if (request.Tagline != null)
        {
            user.Tagline = string.IsNullOrWhiteSpace(request.Tagline) ? null : request.Tagline.Trim();
        }

        if (request.Username != null)
        {
            var newUsername = string.IsNullOrWhiteSpace(request.Username) ? null : request.Username.Trim().ToLowerInvariant();
            if (newUsername != user.Username)
            {
                if (newUsername != null)
                {
                    if (!System.Text.RegularExpressions.Regex.IsMatch(newUsername, @"^[a-z0-9_]{3,30}$"))
                    {
                        return TypedResults.BadRequest("Username must be 3-30 characters long and contain only lowercase letters, numbers, and underscores.");
                    }

                    var isTaken = await db.Users.AnyAsync(u => u.Username == newUsername, ct);
                    if (isTaken)
                    {
                        return TypedResults.BadRequest("Username is already taken.");
                    }
                }
                user.Username = newUsername;
            }
        }
        if (request.AddressLine1 != null) user.AddressLine1 = string.IsNullOrWhiteSpace(request.AddressLine1) ? null : request.AddressLine1.Trim();
        if (request.AddressLine2 != null) user.AddressLine2 = string.IsNullOrWhiteSpace(request.AddressLine2) ? null : request.AddressLine2.Trim();
        if (request.City != null) user.City = string.IsNullOrWhiteSpace(request.City) ? null : request.City.Trim();
        if (request.State != null) user.State = string.IsNullOrWhiteSpace(request.State) ? null : request.State.Trim();
        if (request.PostalCode != null) user.PostalCode = string.IsNullOrWhiteSpace(request.PostalCode) ? null : request.PostalCode.Trim();
        if (request.Country != null) user.Country = string.IsNullOrWhiteSpace(request.Country) ? null : request.Country.Trim();

        if (request.HomeLatitude.HasValue) user.HomeLatitude = request.HomeLatitude.Value;
        if (request.HomeLongitude.HasValue) user.HomeLongitude = request.HomeLongitude.Value;
        if (request.ReceiveMessages.HasValue) user.ReceiveMessages = request.ReceiveMessages.Value;

        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Updated profile details for user {UserId}", userId);

        var response = new UserProfileResponse(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.PhoneNumber,
            user.AvatarUrl,
            user.Tagline,
            user.Username,
            user.ReputationPoints,
            user.Roles.Select(r => r.RoleName.ToString()).ToList(),
            user.CreatedAt,
            user.UpdatedAt,
            user.AddressLine1,
            user.AddressLine2,
            user.City,
            user.State,
            user.PostalCode,
            user.Country,
            user.HomeLatitude,
            user.HomeLongitude,
            user.ReceiveMessages
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Ok<UserProfileResponse>, BadRequest<string>, UnauthorizedHttpResult, NotFound>> SetTaglineAsync(
        SetTaglineRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        if (request.Tagline != null && request.Tagline.Trim().Length > 150)
        {
            return TypedResults.BadRequest("Tagline cannot exceed 150 characters.");
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        user.Tagline = string.IsNullOrWhiteSpace(request.Tagline) ? null : request.Tagline.Trim();
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Updated tagline for user {UserId}", userId);

        var response = new UserProfileResponse(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.PhoneNumber,
            user.AvatarUrl,
            user.Tagline,
            user.Username,
            user.ReputationPoints,
            user.Roles.Select(r => r.RoleName.ToString()).ToList(),
            user.CreatedAt,
            user.UpdatedAt,
            user.AddressLine1,
            user.AddressLine2,
            user.City,
            user.State,
            user.PostalCode,
            user.Country,
            user.HomeLatitude,
            user.HomeLongitude
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Ok<UploadAvatarResponse>, BadRequest<string>, UnauthorizedHttpResult, NotFound>> UploadAvatarAsync(
        IFormFile file,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        IStorageService storageService,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        if (file.Length == 0)
        {
            return TypedResults.BadRequest("Uploaded file is empty.");
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
                ".gif" => "image/gif",
                ".svg" => "image/svg+xml",
                _ => "image/jpeg"
            };
        }

        var oldAvatarUrl = user.AvatarUrl;
        var key = $"avatars/{userId}-{Guid.NewGuid()}{ext}";

        using var stream = file.OpenReadStream();
        var url = await storageService.UploadPublicFileAsync(key, stream, contentType, ct);

        user.AvatarUrl = url;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Uploaded new avatar for user {UserId}", userId);

        if (!string.IsNullOrWhiteSpace(oldAvatarUrl))
        {
            try
            {
                var avatarsIdx = oldAvatarUrl.IndexOf("avatars/", StringComparison.OrdinalIgnoreCase);
                if (avatarsIdx >= 0)
                {
                    var oldKey = oldAvatarUrl[avatarsIdx..];
                    await storageService.DeletePublicFileAsync(oldKey, ct);
                    logger.LogInformation("[Profile] Deleted old avatar with key {OldKey} for user {UserId}", oldKey, userId);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[Profile] Failed to delete old avatar {OldAvatarUrl} for user {UserId}", oldAvatarUrl, userId);
            }
        }

        return TypedResults.Ok(new UploadAvatarResponse(url));
    }

    private static async Task<Results<Ok<UserProfileResponse>, UnauthorizedHttpResult, NotFound>> DeleteAvatarAsync(
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        IStorageService storageService,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        var oldAvatarUrl = user.AvatarUrl;
        user.AvatarUrl = null;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Removed avatar for user {UserId}", userId);

        if (!string.IsNullOrWhiteSpace(oldAvatarUrl))
        {
            try
            {
                var avatarsIdx = oldAvatarUrl.IndexOf("avatars/", StringComparison.OrdinalIgnoreCase);
                if (avatarsIdx >= 0)
                {
                    var oldKey = oldAvatarUrl[avatarsIdx..];
                    await storageService.DeletePublicFileAsync(oldKey, ct);
                    logger.LogInformation("[Profile] Deleted avatar with key {OldKey} for user {UserId}", oldKey, userId);
                }
            }
            catch (Exception ex)
            {
                logger.LogWarning(ex, "[Profile] Failed to delete avatar {OldAvatarUrl} for user {UserId}", oldAvatarUrl, userId);
            }
        }

        var response = new UserProfileResponse(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.PhoneNumber,
            user.AvatarUrl,
            user.Tagline,
            user.Username,
            user.ReputationPoints,
            user.Roles.Select(r => r.RoleName.ToString()).ToList(),
            user.CreatedAt,
            user.UpdatedAt,
            user.AddressLine1,
            user.AddressLine2,
            user.City,
            user.State,
            user.PostalCode,
            user.Country,
            user.HomeLatitude,
            user.HomeLongitude
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Ok<VerificationTokenResponse>, BadRequest<string>, UnauthorizedHttpResult, NotFound>> SendEmailUpdateCodeAsync(
        SendEmailUpdateCodeRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        IDistributedCache cache,
        IEmailService emailService,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null)
        {
            return TypedResults.NotFound();
        }

        var existingUser = await db.Users.FirstOrDefaultAsync(u => u.Email == request.NewEmail, ct);
        if (existingUser != null)
        {
            return TypedResults.BadRequest("This email address is already in use by another account.");
        }

        var verificationToken = Guid.NewGuid();
        var otp = Random.Shared.Next(100000, 999999).ToString();

        var cacheOptions = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
        };
        await cache.SetStringAsync($"email_update:{verificationToken}", $"{userId}:{request.NewEmail}:{otp}", cacheOptions, ct);

        var variables = new Dictionary<string, object>
        {
            { "OtpCode", otp }
        };
        logger.LogInformation("[Profile] Sending email update OTP to {NewEmail}", request.NewEmail);
        await emailService.SendEmailAsync(request.NewEmail, "Verify Your New Email", "otp-verification", variables, ct);

        return TypedResults.Ok(new VerificationTokenResponse(verificationToken));
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult, BadRequest<string>, NotFound>> VerifyEmailUpdateCodeAsync(
        VerifyEmailUpdateCodeRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        IDistributedCache cache,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var cacheValue = await cache.GetStringAsync($"email_update:{request.VerificationToken}", ct);
        if (string.IsNullOrEmpty(cacheValue))
        {
            return TypedResults.BadRequest("Verification token has expired or is invalid.");
        }

        var parts = cacheValue.Split(':');
        if (parts.Length != 3 || parts[0] != userId.ToString() || parts[2] != request.OtpCode)
        {
            return TypedResults.BadRequest("Invalid verification OTP code.");
        }

        var newEmail = parts[1];
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null)
        {
            return TypedResults.NotFound();
        }

        user.Email = newEmail;
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);
        await cache.RemoveAsync($"email_update:{request.VerificationToken}", ct);

        logger.LogInformation("[Profile] Verified and updated email to {Email} for user {UserId}", newEmail, userId);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult, BadRequest<string>, NotFound>> ChangePasswordAsync(
        ChangePasswordRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users
            .Include(u => u.Devices)
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null)
        {
            return TypedResults.NotFound();
        }

        var passwordHasher = new PasswordHasher<User>();
        var result = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.OldPassword);

        if (result == PasswordVerificationResult.Failed)
        {
            return TypedResults.BadRequest("Current password does not match our records.");
        }

        user.PasswordHash = passwordHasher.HashPassword(user, request.NewPassword);
        user.UpdatedAt = DateTimeOffset.UtcNow;

        // Invalidate other active sessions
        foreach (var device in user.Devices)
        {
            device.RefreshTokenHash = null;
            device.RefreshTokenExpiryTime = null;
        }

        foreach (var rt in user.RefreshTokens.Where(t => t.IsActive))
        {
            rt.RevokedAt = DateTime.UtcNow;
            rt.ReasonRevoked = "Password changed by user";
        }

        await db.SaveChangesAsync(ct);
        logger.LogInformation("[Profile] Password changed for user {UserId}", userId);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok<IReadOnlyList<UserSessionDto>>, UnauthorizedHttpResult, NotFound>> GetSessionsAsync(
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var sessions = await db.RefreshTokens
            .AsNoTracking()
            .Where(rt => rt.UserId == userId && rt.RevokedAt == null && rt.ExpiresAt > DateTime.UtcNow)
            .OrderByDescending(rt => rt.CreatedAt)
            .Select(rt => new UserSessionDto(
                rt.Id,
                rt.CreatedAt,
                rt.ExpiresAt,
                rt.CreatedByIp ?? "Unknown",
                rt.IsActive
            ))
            .ToListAsync(ct);

        return TypedResults.Ok<IReadOnlyList<UserSessionDto>>(sessions);
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult, NotFound>> RevokeSessionAsync(
        Guid id,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var session = await db.RefreshTokens.FirstOrDefaultAsync(rt => rt.Id == id && rt.UserId == userId, ct);
        if (session is null)
        {
            return TypedResults.NotFound();
        }

        session.RevokedAt = DateTime.UtcNow;
        session.ReasonRevoked = "Revoked by user";
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Revoked session {SessionId} for user {UserId}", id, userId);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult, NotFound>> RevokeOtherSessionsAsync(
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var activeTokens = await db.RefreshTokens
            .Where(rt => rt.UserId == userId && rt.RevokedAt == null && rt.ExpiresAt > DateTime.UtcNow)
            .ToListAsync(ct);

        foreach (var token in activeTokens)
        {
            token.RevokedAt = DateTime.UtcNow;
            token.ReasonRevoked = "Bulk session revocation";
        }

        await db.SaveChangesAsync(ct);
        logger.LogInformation("[Profile] Revoked all sessions for user {UserId}", userId);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok<LifestyleDto>, UnauthorizedHttpResult, NotFound>> GetLifestyleProfileAsync(
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
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        var lp = user.LifestyleProfile ?? new LifestyleProfile();
        return TypedResults.Ok(new LifestyleDto(
            lp.HomeSize?.ToString(),
            lp.HasEnclosedYard,
            lp.HasChildren,
            lp.ActivityTempo?.ToString(),
            lp.ExistingPets
        ));
    }

    private static async Task<Results<Ok<LifestyleDto>, UnauthorizedHttpResult, NotFound>> UpdateLifestyleProfileAsync(
        UpdateLifestyleRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var user = await db.Users
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null || user.IsDeleted || !user.IsActive)
        {
            return TypedResults.NotFound();
        }

        if (user.LifestyleProfile == null)
        {
            user.LifestyleProfile = new LifestyleProfile();
        }

        if (!string.IsNullOrEmpty(request.HomeSize) && Enum.TryParse<HappyPaws.Domain.Enums.HomeSize>(request.HomeSize, out var homeSize))
        {
            user.LifestyleProfile.HomeSize = homeSize;
        }
        else
        {
            user.LifestyleProfile.HomeSize = null;
        }

        user.LifestyleProfile.HasEnclosedYard = request.HasEnclosedYard;
        user.LifestyleProfile.HasChildren = request.HasChildren;

        if (!string.IsNullOrEmpty(request.ActivityTempo) && Enum.TryParse<HappyPaws.Domain.Enums.ActivityTempo>(request.ActivityTempo, out var tempo))
        {
            user.LifestyleProfile.ActivityTempo = tempo;
        }
        else
        {
            user.LifestyleProfile.ActivityTempo = null;
        }

        user.LifestyleProfile.ExistingPets = request.ExistingPets ?? new List<string>();

        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Updated lifestyle profile for user {UserId}", userId);

        return TypedResults.Ok(new LifestyleDto(
            user.LifestyleProfile.HomeSize?.ToString(),
            user.LifestyleProfile.HasEnclosedYard,
            user.LifestyleProfile.HasChildren,
            user.LifestyleProfile.ActivityTempo?.ToString(),
            user.LifestyleProfile.ExistingPets
        ));
    }

    private static async Task<Results<Ok, BadRequest<string>, UnauthorizedHttpResult, NotFound>> ToggleRoleVisibilityAsync(
        ToggleRoleVisibilityRequest request,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        ILogger<ProfileEndpoints> logger,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !long.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        if (!Enum.TryParse<HappyPaws.Domain.Enums.RoleName>(request.RoleName, true, out var roleName))
        {
            return TypedResults.BadRequest("Invalid role name specified.");
        }

        var userRole = await db.UserRoles
            .FirstOrDefaultAsync(r => r.UserId == userId && r.RoleName == roleName, ct);

        if (userRole is null)
        {
            return TypedResults.NotFound();
        }

        userRole.IsVisible = request.IsVisible;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Profile] Updated role visibility for user {UserId}, role {Role} to {IsVisible}", userId, roleName, request.IsVisible);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok<PublicUserProfileResponse>, NotFound>> GetPublicProfileAsync(
        long userId,
        ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var user = await db.Users
            .AsNoTracking()
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId && !u.IsDeleted && u.IsActive, ct);

        if (user is null)
        {
            return TypedResults.NotFound();
        }

        bool canMessage = true;
        var callerIdStr = userPrincipal.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (long.TryParse(callerIdStr, out var callerId))
        {
            if (callerId == userId)
            {
                canMessage = true; // Allow messaging yourself for saved messages
            }
            else
            {
                var caller = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == callerId, ct);
                if (caller != null)
                {
                    bool isCallerAdmin = caller.Roles.Any(r => r.RoleName == RoleName.Administrator);
                    if (!isCallerAdmin)
                    {
                        bool isTargetAdmin = user.Roles.Any(r => r.RoleName == RoleName.Administrator);
                        if (isTargetAdmin)
                        {
                            canMessage = await db.CanMessages.AnyAsync(c => c.FromUserId == callerId && c.ToUserId == userId && c.IsAllowed, ct);
                        }
                        else
                        {
                            bool isBlocked = await db.CanMessages.AnyAsync(c => c.FromUserId == callerId && c.ToUserId == userId && !c.IsAllowed, ct);
                            if (isBlocked)
                            {
                                canMessage = false;
                            }
                            else if (!user.ReceiveMessages)
                            {
                                canMessage = await db.CanMessages.AnyAsync(c => c.FromUserId == callerId && c.ToUserId == userId && c.IsAllowed, ct);
                            }
                        }
                    }
                }
            }
        }

        var visibleRoles = user.Roles
            .Where(r => r.IsVisible)
            .Select(r => r.RoleName.ToString())
            .ToList();

        var posts = await db.Posts
            .AsNoTracking()
            .Include(p => p.Media)
            .Where(p => p.AuthorId == userId && !p.IsDeleted && p.Status == PostStatus.Active)
            .OrderByDescending(p => p.CreatedAt)
            .Take(20)
            .ToListAsync(ct);

        var publicPosts = posts.Select(p => new PostSummaryResponse(
            p.Id,
            p.Type.ToString(),
            p.Status.ToString(),
            p.Title,
            p.Body,
            p.LikeCount,
            false,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.AvatarUrl,
            user.Id,
            p.LocationLabel,
            p.LocationPoint != null ? p.LocationPoint.Y : null,
            p.LocationPoint != null ? p.LocationPoint.X : null,
            p.AnimalSpecies,
            p.AnimalName,
            p.Media.OrderBy(m => m.SortOrder).Select(m => m.CdnUrl).FirstOrDefault(),
            p.Media.Count,
            p.CreatedAt,
            p.UrgencyLevel != null ? p.UrgencyLevel.ToString() : null,
            p.AiTriageReason,
            p.IsUrgencyManuallyOverridden,
            false
        )).ToList();

        var response = new PublicUserProfileResponse(
            user.Id,
            $"{user.FirstName} {user.LastName}".Trim(),
            user.AvatarUrl,
            user.Tagline,
            user.Username,
            user.ReputationPoints,
            visibleRoles,
            user.CreatedAt,
            publicPosts,
            canMessage
        );

        return TypedResults.Ok(response);
    }
}

/// <summary>
/// Payload to update user personal profile details.
/// </summary>
public sealed record UpdateProfileRequest(
    string? Name,
    string? FirstName,
    string? LastName,
    string? PhoneNumber,
    string? Tagline,
    string? Username,
    string? AddressLine1,
    string? AddressLine2,
    string? City,
    string? State,
    string? PostalCode,
    string? Country,
    double? HomeLatitude,
    double? HomeLongitude,
    bool? ReceiveMessages = null);

/// <summary>
/// Payload to set or clear user profile tagline.
/// </summary>
public sealed record SetTaglineRequest(string? Tagline);

/// <summary>
/// Full user profile information.
/// </summary>
public sealed record UserProfileResponse(
    long Id,
    string Email,
    string FirstName,
    string LastName,
    string FullName,
    string? PhoneNumber,
    string? AvatarUrl,
    string? Tagline,
    string? Username,
    int ReputationPoints,
    IReadOnlyList<string> Roles,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt,
    string? AddressLine1,
    string? AddressLine2,
    string? City,
    string? State,
    string? PostalCode,
    string? Country,
    double? HomeLatitude,
    double? HomeLongitude,
    bool ReceiveMessages = true);

/// <summary>
/// Response payload containing the uploaded public avatar URL.
/// </summary>
public sealed record UploadAvatarResponse(string AvatarUrl);

/// <summary>
/// Request payload to initiate an email address update.
/// </summary>
public sealed record SendEmailUpdateCodeRequest(string NewEmail);

/// <summary>
/// Response payload containing the email verification correlation token.
/// </summary>
public sealed record VerificationTokenResponse(Guid VerificationToken);

/// <summary>
/// Request payload to verify email update OTP.
/// </summary>
public sealed record VerifyEmailUpdateCodeRequest(Guid VerificationToken, string OtpCode);

/// <summary>
/// Request payload to change account password.
/// </summary>
public sealed record ChangePasswordRequest(string OldPassword, string NewPassword);

/// <summary>
/// Represents an active user session.
/// </summary>
public sealed record UserSessionDto(
    Guid Id,
    DateTime CreatedAt,
    DateTime ExpiresAt,
    string IpAddress,
    bool IsActive);

public sealed record LifestyleDto(
    string? HomeSize,
    bool HasEnclosedYard,
    bool HasChildren,
    string? ActivityTempo,
    List<string> ExistingPets
);

public sealed record UpdateLifestyleRequest(
    string? HomeSize,
    bool HasEnclosedYard,
    bool HasChildren,
    string? ActivityTempo,
    List<string> ExistingPets
);

/// <summary>
/// Payload to toggle the visibility of a user role on public profiles.
/// </summary>
public sealed record ToggleRoleVisibilityRequest(
    string RoleName,
    bool IsVisible);

/// <summary>
/// Public profile information for a user.
/// </summary>
public sealed record PublicUserProfileResponse(
    long Id,
    string FullName,
    string? AvatarUrl,
    string? Tagline,
    string? Username,
    int ReputationPoints,
    IReadOnlyList<string> Roles,
    DateTimeOffset CreatedAt,
    IReadOnlyList<PostSummaryResponse> Posts,
    bool CanMessage = true);

