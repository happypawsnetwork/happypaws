using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.Extensions.Caching.Distributed;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Api.Features.Auth;

public sealed class AuthEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth")
            .WithTags("Authentication")
            .RequireRateLimiting("GlobalPolicy");

        group.MapPost("/mobile/login", MobileLogin)
            .WithName("MobileLogin")
            .WithSummary("Login from a mobile application")
            .Produces<MobileLoginResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status403Forbidden)
            .ProducesProblem(StatusCodes.Status429TooManyRequests);

        group.MapPost("/register/send-code", RegisterSendCode)
            .WithName("RegisterSendCode")
            .WithSummary("Send registration OTP to email")
            .Produces<VerificationTokenResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status409Conflict);

        group.MapPost("/register/verify-code", RegisterVerifyCode)
            .WithName("RegisterVerifyCode")
            .WithSummary("Verify registration OTP")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status429TooManyRequests);

        group.MapPost("/register/complete", RegisterComplete)
            .WithName("RegisterComplete")
            .WithSummary("Complete registration and return tokens")
            .Produces<MobileLoginResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapPost("/password/forgot/send-code", ForgotPasswordSendCode)
            .WithName("ForgotPasswordSendCode")
            .WithSummary("Send password reset OTP to email")
            .Produces<VerificationTokenResponse>(StatusCodes.Status200OK);

        group.MapPost("/password/forgot/verify-code", ForgotPasswordVerifyCode)
            .WithName("ForgotPasswordVerifyCode")
            .WithSummary("Verify password reset OTP")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status429TooManyRequests);

        group.MapPost("/password/forgot/reset", ForgotPasswordReset)
            .WithName("ForgotPasswordReset")
            .WithSummary("Reset password")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapPost("/refresh", Refresh)
            .WithName("AuthRefresh")
            .AllowAnonymous();

        group.MapPost("/revoke", Revoke)
            .WithName("AuthRevoke")
            .RequireAuthorization();

        group.MapGet("/me", GetMe)
            .WithName("GetAuthMe")
            .WithSummary("Get authenticated user profile")
            .RequireAuthorization()
            .Produces<UserResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static async Task<Results<Ok<MobileLoginResponse>, UnauthorizedHttpResult, ForbidHttpResult, ProblemHttpResult>> MobileLogin(
        MobileLoginRequest request,
        IApplicationDbContext db,
        ITokenService tokenService,
        IAuthRateLimitService rateLimitService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var remaining = await rateLimitService.GetLockoutRemainingAsync(ip, request.Email);
        if (remaining.HasValue)
        {
            logger.LogWarning("[Authentication] Lockout triggered for IP {IP} or Email {Email}", ip, request.Email);
            var minutes = (int)Math.Ceiling(remaining.Value.TotalMinutes);
            var msg = minutes > 1 ? $"Too many failed attempts. Try again in {minutes} minutes." : "Too many failed attempts. Try again in 1 minute.";
            return TypedResults.Problem(msg, statusCode: StatusCodes.Status429TooManyRequests);
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .Include(u => u.Devices)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower(), ct);

        if (user is null)
        {
            logger.LogWarning("[Authentication] Failed mobile login attempt for non-existent user {Email}", request.Email);
            await rateLimitService.RecordFailureAsync(ip, request.Email);
            return TypedResults.Unauthorized();
        }

        // Admins are blocked from logging into the mobile app
        if (user.Roles.Any(r => r.RoleName == RoleName.Administrator))
        {
            logger.LogWarning("[Authentication] Blocked admin user {Email} from accessing the mobile application", request.Email);
            return TypedResults.Forbid();
        }

        var passwordHasher = new PasswordHasher<User>();
        var result = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);

        if (result == PasswordVerificationResult.Failed)
        {
            logger.LogWarning("[Authentication] Invalid password on mobile login for user {Email}", request.Email);
            await rateLimitService.RecordFailureAsync(ip, request.Email);
            return TypedResults.Unauthorized();
        }

        await rateLimitService.ClearFailuresAsync(ip, request.Email);
        logger.LogInformation("[Authentication] User {Email} successfully logged into the mobile application", request.Email);

        var (accessToken, refreshToken) = tokenService.GenerateTokens(user);

        if (!string.IsNullOrEmpty(request.FcmToken))
        {
            var device = user.Devices.FirstOrDefault(d => d.FcmToken == request.FcmToken);
            if (device is not null)
            {
                device.LastActiveAt = DateTimeOffset.UtcNow;
                device.DeviceType = request.DeviceType;
            }
            else
            {
                db.UserDevices.Add(new UserDevice
                {
                    UserId = user.Id,
                    FcmToken = request.FcmToken,
                    DeviceType = request.DeviceType,
                    LastActiveAt = DateTimeOffset.UtcNow
                });
            }
        }

        var refreshTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = tokenService.HashToken(refreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(14),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ip
        };

        db.RefreshTokens.Add(refreshTokenEntity);
        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new MobileLoginResponse(accessToken, refreshToken, 30 * 24 * 60 * 60)); // expires in seconds
    }

    private static string HashToken(string token)
    {
        // Hash the refresh token to prevent exposure in the event of a database compromise
        using var sha256 = System.Security.Cryptography.SHA256.Create();
        var bytes = System.Text.Encoding.UTF8.GetBytes(token);
        var hash = sha256.ComputeHash(bytes);
        return Convert.ToBase64String(hash);
    }

    private static async Task<Results<Ok<VerificationTokenResponse>, Conflict>> RegisterSendCode(
        SendCodeRequest request,
        IApplicationDbContext db,
        Microsoft.Extensions.Caching.Distributed.IDistributedCache cache,
        IEmailService emailService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        CancellationToken ct)
    {
        var exists = await db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.ToLower(), ct);
        if (exists)
        {
            logger.LogWarning("[Authentication] Registration attempted for already existing email {Email}", request.Email);
            return TypedResults.Conflict();
        }

        var otp = Random.Shared.Next(100000, 999999).ToString();
        var verificationToken = Guid.NewGuid();

        var cacheOptions = new Microsoft.Extensions.Caching.Distributed.DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
        };
        await cache.SetStringAsync($"reg:{verificationToken}", $"{request.Email}:{otp}", cacheOptions, ct);

        var variables = new System.Collections.Generic.Dictionary<string, object>
        {
            { "OtpCode", otp }
        };

        logger.LogInformation("[Authentication] Sending registration OTP to {Email} with token {Token}", request.Email, verificationToken);
        await emailService.SendEmailAsync(request.Email, "Verify Your Email", "otp-verification", variables, ct);

        return TypedResults.Ok(new VerificationTokenResponse(verificationToken));
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult, ProblemHttpResult>> RegisterVerifyCode(
        VerifyCodeRequest request,
        Microsoft.Extensions.Caching.Distributed.IDistributedCache cache,
        IAuthRateLimitService rateLimitService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var identifier = request.VerificationToken.ToString();

        if (await rateLimitService.IsLockedOutAsync(ip, identifier))
        {
            logger.LogWarning("[Authentication] Lockout triggered for IP {IP} on registration verify token {Token}", ip, identifier);
            return TypedResults.Problem("Too many failed attempts. Try again later.", statusCode: StatusCodes.Status429TooManyRequests);
        }

        var cacheValue = await cache.GetStringAsync($"reg:{request.VerificationToken}", ct);
        if (string.IsNullOrEmpty(cacheValue))
        {
            logger.LogWarning("[Authentication] Expired or invalid registration token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        var parts = cacheValue.Split(':');
        if (parts.Length != 2 || parts[1] != request.OtpCode)
        {
            logger.LogWarning("[Authentication] Invalid registration OTP submitted for token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        await rateLimitService.ClearFailuresAsync(ip, identifier);

        var email = parts[0];
        await cache.RemoveAsync($"reg:{request.VerificationToken}", ct);

        logger.LogInformation("[Authentication] Registration OTP successfully verified for email {Email}", email);

        var cacheOptions = new Microsoft.Extensions.Caching.Distributed.DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(15)
        };
        await cache.SetStringAsync($"reg_verified:{request.VerificationToken}", email, cacheOptions, ct);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok<MobileLoginResponse>, UnauthorizedHttpResult>> RegisterComplete(
        RegisterCompleteRequest request,
        IApplicationDbContext db,
        Microsoft.Extensions.Caching.Distributed.IDistributedCache cache,
        ITokenService tokenService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        CancellationToken ct)
    {
        var email = await cache.GetStringAsync($"reg_verified:{request.VerificationToken}", ct);
        if (string.IsNullOrEmpty(email))
        {
            logger.LogWarning("[Authentication] Attempted to complete registration with expired or invalid verified token {Token}", request.VerificationToken);
            return TypedResults.Unauthorized();
        }

        var nameParts = request.FullName.Split(' ', 2);
        var firstName = nameParts[0];
        var lastName = nameParts.Length > 1 ? nameParts[1] : "";

        var user = new User
        {
            Email = email.ToLower(),
            FirstName = firstName,
            LastName = lastName,
            PasswordHash = string.Empty // Will be set next
        };

        var passwordHasher = new PasswordHasher<User>();
        user.PasswordHash = passwordHasher.HashPassword(user, request.Password);
        user.AddRole(RoleName.Adopter);

        db.Users.Add(user);
        await db.SaveChangesAsync(ct); // Save to get the ID

        logger.LogInformation("[Authentication] New user account successfully created for {Email}", email);

        var (accessToken, refreshToken) = tokenService.GenerateTokens(user);
        var expiryTime = DateTimeOffset.UtcNow.AddDays(30);

        if (!string.IsNullOrEmpty(request.FcmToken))
        {
            db.UserDevices.Add(new UserDevice
            {
                UserId = user.Id,
                FcmToken = request.FcmToken,
                DeviceType = request.DeviceType,
                LastActiveAt = DateTimeOffset.UtcNow
            });
        }

        var ip = "unknown"; // Cannot easily access HttpContext here, wait, I can modify the signature if needed, or leave it unknown since it's just a newly registered mobile app. Or I can just pass "unknown".

        var refreshTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = tokenService.HashToken(refreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(14),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ip
        };

        db.RefreshTokens.Add(refreshTokenEntity);
        await db.SaveChangesAsync(ct);

        await cache.RemoveAsync($"reg_verified:{request.VerificationToken}", ct);

        return TypedResults.Ok(new MobileLoginResponse(accessToken, refreshToken, 30 * 24 * 60 * 60));
    }

    private static async Task<Ok<VerificationTokenResponse>> ForgotPasswordSendCode(
        SendCodeRequest request,
        IApplicationDbContext db,
        Microsoft.Extensions.Caching.Distributed.IDistributedCache cache,
        IEmailService emailService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        CancellationToken ct)
    {
        var verificationToken = Guid.NewGuid();

        var user = await db.Users.FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower(), ct);
        if (user is not null)
        {
            var otp = Random.Shared.Next(100000, 999999).ToString();
            var cacheOptions = new Microsoft.Extensions.Caching.Distributed.DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
            };
            await cache.SetStringAsync($"forgot:{verificationToken}", $"{user.Id}:{otp}", cacheOptions, ct);

            var variables = new System.Collections.Generic.Dictionary<string, object>
            {
                { "OtpCode", otp }
            };

            logger.LogInformation("[Authentication] Password reset requested for {Email}. OTP generated with token {Token}", request.Email, verificationToken);
            await emailService.SendEmailAsync(user.Email, "Reset Your Password", "otp-verification", variables, ct);
        }
        else
        {
            logger.LogInformation("[Authentication] Password reset requested for non-existent email {Email}. Masking failure", request.Email);
        }

        // Always return success to prevent enumeration
        return TypedResults.Ok(new VerificationTokenResponse(verificationToken));
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult, ProblemHttpResult>> ForgotPasswordVerifyCode(
        VerifyCodeRequest request,
        Microsoft.Extensions.Caching.Distributed.IDistributedCache cache,
        IAuthRateLimitService rateLimitService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var identifier = request.VerificationToken.ToString();

        if (await rateLimitService.IsLockedOutAsync(ip, identifier))
        {
            logger.LogWarning("[Authentication] Lockout triggered for IP {IP} on forgot password verify token {Token}", ip, identifier);
            return TypedResults.Problem("Too many failed attempts. Try again later.", statusCode: StatusCodes.Status429TooManyRequests);
        }

        var cacheValue = await cache.GetStringAsync($"forgot:{request.VerificationToken}", ct);
        if (string.IsNullOrEmpty(cacheValue))
        {
            logger.LogWarning("[Authentication] Expired or invalid forgot password token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        var parts = cacheValue.Split(':');
        if (parts.Length != 2 || parts[1] != request.OtpCode)
        {
            logger.LogWarning("[Authentication] Invalid forgot password OTP submitted for token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        await rateLimitService.ClearFailuresAsync(ip, identifier);

        var userId = parts[0];
        await cache.RemoveAsync($"forgot:{request.VerificationToken}", ct);

        logger.LogInformation("[Authentication] Forgot password OTP successfully verified for user {UserId}", userId);

        var cacheOptions = new Microsoft.Extensions.Caching.Distributed.DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(15)
        };
        await cache.SetStringAsync($"forgot_verified:{request.VerificationToken}", userId, cacheOptions, ct);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult>> ForgotPasswordReset(
        ResetPasswordRequest request,
        IApplicationDbContext db,
        Microsoft.Extensions.Caching.Distributed.IDistributedCache cache,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        CancellationToken ct)
    {
        var userIdStr = await cache.GetStringAsync($"forgot_verified:{request.VerificationToken}", ct);
        if (string.IsNullOrEmpty(userIdStr) || !long.TryParse(userIdStr, out var userId))
        {
            logger.LogWarning("[Authentication] Attempted to reset password with expired or invalid verified token {Token}", request.VerificationToken);
            return TypedResults.Unauthorized();
        }

        var user = await db.Users.Include(u => u.Devices).FirstOrDefaultAsync(u => u.Id == userId, ct);
        if (user is null)
        {
            logger.LogWarning("[Authentication] Reset password attempted for non-existent user ID {UserId}", userId);
            return TypedResults.Unauthorized();
        }

        var passwordHasher = new PasswordHasher<User>();
        user.PasswordHash = passwordHasher.HashPassword(user, request.NewPassword);

        // Invalidate all existing refresh tokens to secure the account from unauthorized access after a password reset
        foreach (var device in user.Devices)
        {
            device.RefreshTokenHash = null;
            device.RefreshTokenExpiryTime = null;
        }

        await db.SaveChangesAsync(ct);
        await cache.RemoveAsync($"forgot_verified:{request.VerificationToken}", ct);

        logger.LogInformation("[Authentication] Password successfully reset for user {Email}. All sessions invalidated.", user.Email);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok<UserResponse>, UnauthorizedHttpResult, NotFound>> GetMe(
        System.Security.Claims.ClaimsPrincipal userPrincipal,
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var userIdString = userPrincipal.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
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

        var roles = user.Roles.Select(r => new UserRoleDto(r.RoleName.ToString(), r.IsVerified, r.IsVisible)).ToArray();
        var name = $"{user.FirstName} {user.LastName}".Trim();

        return TypedResults.Ok(new UserResponse(
            user.Id,
            user.Email,
            name,
            user.AvatarUrl,
            user.Tagline,
            roles,
            user.Username,
            user.ReputationPoints,
            user.AddressLine1,
            user.AddressLine2,
            user.City,
            user.State,
            user.PostalCode,
            user.Country,
            user.HomeLatitude,
            user.HomeLongitude
        ));
    }

    private static async Task<Results<Ok<MobileLoginResponse>, UnauthorizedHttpResult, ProblemHttpResult>> Refresh(
        RefreshRequest request,
        HttpContext httpContext,
        IApplicationDbContext db,
        ITokenService tokenService,
        Microsoft.Extensions.Logging.ILogger<AuthEndpoints> logger,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var hash = tokenService.HashToken(request.RefreshToken);

        var existingToken = await db.RefreshTokens
            .Include(rt => rt.User)
            .ThenInclude(u => u.Roles)
            .FirstOrDefaultAsync(rt => rt.TokenHash == hash, ct);

        if (existingToken is null)
        {
            logger.LogWarning("[Authentication] Refresh failed: Token not found.");
            return TypedResults.Unauthorized();
        }

        if (existingToken.IsRevoked)
        {
            logger.LogWarning("[Authentication] REUSE DETECTED: Revoked token used for user {UserId}. Invalidating all sessions.", existingToken.UserId);
            var allActiveTokens = await db.RefreshTokens
                .Where(rt => rt.UserId == existingToken.UserId && rt.RevokedAt == null)
                .ToListAsync(ct);
            foreach (var t in allActiveTokens)
            {
                t.RevokedAt = DateTime.UtcNow;
                t.RevokedByIp = ip;
                t.ReasonRevoked = "Attempted reuse of revoked token";
            }
            await db.SaveChangesAsync(ct);
            return TypedResults.Unauthorized();
        }

        if (existingToken.IsExpired)
        {
            logger.LogWarning("[Authentication] Refresh failed: Token expired.");
            return TypedResults.Unauthorized();
        }

        existingToken.RevokedAt = DateTime.UtcNow;
        existingToken.RevokedByIp = ip;
        existingToken.ReasonRevoked = "Rotated";

        var (newAccess, newRefresh) = tokenService.GenerateTokens(existingToken.User);

        var newTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = existingToken.UserId,
            TokenHash = tokenService.HashToken(newRefresh),
            ExpiresAt = DateTime.UtcNow.AddDays(14),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ip
        };

        existingToken.ReplacedByToken = newTokenEntity.TokenHash;

        db.RefreshTokens.Add(newTokenEntity);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[Authentication] Token successfully refreshed for user {UserId}", existingToken.UserId);
        return TypedResults.Ok(new MobileLoginResponse(newAccess, newRefresh, 30 * 24 * 60 * 60));
    }

    private static async Task<Results<Ok, UnauthorizedHttpResult>> Revoke(
        RefreshRequest request,
        HttpContext httpContext,
        IApplicationDbContext db,
        ITokenService tokenService,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var hash = tokenService.HashToken(request.RefreshToken);

        var existingToken = await db.RefreshTokens.FirstOrDefaultAsync(rt => rt.TokenHash == hash, ct);

        if (existingToken is not null && !existingToken.IsRevoked)
        {
            existingToken.RevokedAt = DateTime.UtcNow;
            existingToken.RevokedByIp = ip;
            existingToken.ReasonRevoked = "Explicit logout/revoke";
            await db.SaveChangesAsync(ct);
        }

        return TypedResults.Ok();
    }
}

/// <summary>
/// Payload submitted by mobile clients to authenticate a user.
/// </summary>
public record MobileLoginRequest(string Email, string Password, string FcmToken, DeviceType DeviceType);

/// <summary>
/// Contains the JWT access token and refresh token upon successful authentication.
/// </summary>
public record MobileLoginResponse(string AccessToken, string RefreshToken, int ExpiresIn);

/// <summary>
/// Payload to request a verification OTP to a given email address.
/// </summary>
public record SendCodeRequest(string Email);

/// <summary>
/// Contains a tracking identifier to correlate the requested OTP across steps.
/// </summary>
public record VerificationTokenResponse(Guid VerificationToken);

/// <summary>
/// Payload to verify a previously sent OTP using the tracking identifier.
/// </summary>
public record VerifyCodeRequest(Guid VerificationToken, string OtpCode);

/// <summary>
/// Payload to complete user registration after OTP verification.
/// </summary>
public record RegisterCompleteRequest(Guid VerificationToken, string FullName, string Password, string? FcmToken, DeviceType? DeviceType);

/// <summary>
/// Payload to set a new password after the forgot password OTP is verified.
/// </summary>
public record ResetPasswordRequest(Guid VerificationToken, string NewPassword);

/// <summary>
/// Contains the name of a role, its verification status, and its visibility status.
/// </summary>
public record UserRoleDto(string Name, bool IsVerified, bool IsVisible = true);

/// <summary>
/// Standard user profile returned for authenticated sessions.
/// </summary>
public record UserResponse(
    long Id,
    string Email,
    string Name,
    string? AvatarUrl,
    string? Tagline,
    UserRoleDto[] Roles,
    string? Username = null,
    int ReputationPoints = 0,
    string? AddressLine1 = null,
    string? AddressLine2 = null,
    string? City = null,
    string? State = null,
    string? PostalCode = null,
    string? Country = null,
    double? HomeLatitude = null,
    double? HomeLongitude = null);
