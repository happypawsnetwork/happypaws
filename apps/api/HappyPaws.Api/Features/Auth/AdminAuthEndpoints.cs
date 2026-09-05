using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Hosting;

namespace HappyPaws.Api.Features.Auth;

public sealed class AdminAuthEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/auth/admin")
            .WithTags("Admin Authentication")
            .RequireRateLimiting("AuthPolicy");

        group.MapPost("/login", Login)
            .WithName("AdminLogin")
            .WithSummary("Validate credentials and send 2FA OTP")
            .Produces<AdminLoginResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status403Forbidden)
            .ProducesProblem(StatusCodes.Status429TooManyRequests)
            .AllowAnonymous();

        group.MapPost("/verify-otp", VerifyOtp)
            .WithName("AdminVerifyOtp")
            .WithSummary("Verify OTP and create a secure cookie session")
            .Produces<TokensResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status429TooManyRequests)
            .AllowAnonymous();

        group.MapPost("/refresh", Refresh)
            .WithName("AdminRefresh")
            .AllowAnonymous();

        group.MapPost("/revoke", Revoke)
            .WithName("AdminRevoke")
            .RequireAuthorization();

        group.MapGet("/me", GetMe)
            .WithName("GetAdminMe")
            .WithSummary("Get authenticated admin profile")
            .RequireAuthorization()
            .Produces<UserResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static async Task<Results<Ok<AdminLoginResponse>, UnauthorizedHttpResult, ForbidHttpResult, ProblemHttpResult>> Login(
        AdminLoginRequest request,
        IApplicationDbContext db,
        IDistributedCache cache,
        IEmailService emailService,
        IAuthRateLimitService rateLimitService,
        IWebHostEnvironment env,
        ITokenService tokenService,
        Microsoft.Extensions.Logging.ILogger<AdminAuthEndpoints> logger,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var remaining = await rateLimitService.GetLockoutRemainingAsync(ip, request.Email);
        if (remaining.HasValue)
        {
            logger.LogWarning("[AdminAuthentication] Lockout triggered for IP {IP} on login attempt for {Email}. Remaining: {Remaining}", ip, request.Email, remaining.Value);
            var minutes = (int)Math.Ceiling(remaining.Value.TotalMinutes);
            var msg = minutes > 1 ? $"Too many failed attempts. Try again in {minutes} minutes." : "Too many failed attempts. Try again in 1 minute.";
            return TypedResults.Problem(msg, statusCode: StatusCodes.Status429TooManyRequests);
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Email.ToLower() == request.Email.ToLower(), ct);

        if (user is null)
        {
            logger.LogWarning("[AdminAuthentication] Failed login attempt for non-existent user {Email}", request.Email);
            await rateLimitService.RecordFailureAsync(ip, request.Email);
            return TypedResults.Unauthorized();
        }

        // Must be an Administrator
        bool isAdmin = false;
        foreach (var role in user.Roles)
        {
            if (role.RoleName == RoleName.Administrator)
            {
                isAdmin = true;
                break;
            }
        }

        if (!isAdmin)
        {
            logger.LogWarning("[AdminAuthentication] Forbidden login attempt by non-admin user {Email}", request.Email);
            return TypedResults.Forbid();
        }

        var passwordHasher = new PasswordHasher<User>();
        var result = passwordHasher.VerifyHashedPassword(user, user.PasswordHash, request.Password);

        if (result == PasswordVerificationResult.Failed)
        {
            logger.LogWarning("[AdminAuthentication] Invalid password attempt for admin {Email}", request.Email);
            await rateLimitService.RecordFailureAsync(ip, request.Email);
            return TypedResults.Unauthorized();
        }

        await rateLimitService.ClearFailuresAsync(ip, request.Email);

        if (env.IsDevelopment())
        {
            logger.LogInformation("[AdminAuthentication] Development Mode: Bypassing 2FA for {Email}. Issuing tokens.", user.Email);

            var (accessToken, refreshToken) = tokenService.GenerateTokens(user);
            var refreshDays = request.RememberMe ? 30 : 1;

            var refreshTokenEntity = new RefreshToken
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                TokenHash = tokenService.HashToken(refreshToken),
                ExpiresAt = DateTime.UtcNow.AddDays(refreshDays),
                CreatedAt = DateTime.UtcNow,
                CreatedByIp = ip
            };

            db.RefreshTokens.Add(refreshTokenEntity);
            await db.SaveChangesAsync(ct);

            return TypedResults.Ok(new AdminLoginResponse(
                Guid.Empty,
                300,
                DevBypass: true,
                AccessToken: accessToken,
                RefreshToken: refreshToken,
                RefreshExpiresIn: refreshDays * 86400));
        }

        var otp = OtpHelpers.Generate();
        var verificationToken = Guid.NewGuid();

        var cacheOptions = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
        };

        var cacheValue = $"{user.Id}:{otp}:{request.RememberMe}";
        await cache.SetStringAsync($"otp:{verificationToken}", cacheValue, cacheOptions, ct);

        var variables = new Dictionary<string, object>
        {
            { "OtpCode", otp }
        };

        logger.LogInformation("[AdminAuthentication] Valid credentials for {Email}. 2FA OTP generated and dispatched", request.Email);

        // Ensure email sends in background or awaited. We await it here for simplicity.
        await emailService.SendEmailAsync(user.Email, "Web Admin Verification", "otp-verification", variables, ct);

        return TypedResults.Ok(new AdminLoginResponse(verificationToken, 300));
    }

    private static async Task<Results<Ok<TokensResponse>, UnauthorizedHttpResult, ProblemHttpResult>> VerifyOtp(
        AdminVerifyOtpRequest request,
        HttpContext httpContext,
        IApplicationDbContext db,
        IDistributedCache cache,
        IAuthRateLimitService rateLimitService,
        ITokenService tokenService,
        Microsoft.Extensions.Logging.ILogger<AdminAuthEndpoints> logger,
        CancellationToken ct)
    {
        var ip = httpContext.Connection.RemoteIpAddress?.ToString() ?? "unknown";
        var identifier = request.VerificationToken.ToString();

        var remaining = await rateLimitService.GetLockoutRemainingAsync(ip, identifier);
        if (remaining.HasValue)
        {
            logger.LogWarning("[AdminAuthentication] Lockout triggered for IP {IP} on OTP verification {Token}. Remaining: {Remaining}", ip, identifier, remaining.Value);
            var minutes = (int)Math.Ceiling(remaining.Value.TotalMinutes);
            var msg = minutes > 1 ? $"Too many failed attempts. Try again in {minutes} minutes." : "Too many failed attempts. Try again in 1 minute.";
            return TypedResults.Problem(msg, statusCode: StatusCodes.Status429TooManyRequests);
        }

        var cacheValue = await cache.GetStringAsync($"otp:{request.VerificationToken}", ct);
        if (string.IsNullOrEmpty(cacheValue))
        {
            logger.LogWarning("[AdminAuthentication] Expired or invalid OTP token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        var parts = cacheValue.Split(':');
        if (parts.Length < 2 || !OtpHelpers.ConstantTimeEquals(parts[1], request.OtpCode))
        {
            logger.LogWarning("[AdminAuthentication] Invalid OTP code submitted for token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        var rememberMe = parts.Length > 2
            && bool.TryParse(parts[2], out var cachedRemember)
            && cachedRemember;
        var refreshDays = rememberMe ? 30 : 1;

        if (!long.TryParse(parts[0], out var userId))
        {
            logger.LogWarning("[AdminAuthentication] Malformed OTP cache payload for token {Token}", identifier);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        var user = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == userId, ct);

        if (user is null)
        {
            logger.LogWarning("[AdminAuthentication] OTP user {UserId} not found in database", userId);
            await rateLimitService.RecordFailureAsync(ip, identifier);
            return TypedResults.Unauthorized();
        }

        await rateLimitService.ClearFailuresAsync(ip, identifier);

        // OTP is valid. Remove from cache to prevent replay
        await cache.RemoveAsync($"otp:{request.VerificationToken}", ct);

        logger.LogInformation("[AdminAuthentication] 2FA successful for admin {Email}. Issuing tokens.", user.Email);

        var (accessToken, refreshToken) = tokenService.GenerateTokens(user);

        var refreshTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = user.Id,
            TokenHash = tokenService.HashToken(refreshToken),
            ExpiresAt = DateTime.UtcNow.AddDays(refreshDays),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ip
        };

        db.RefreshTokens.Add(refreshTokenEntity);
        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new TokensResponse(accessToken, refreshToken, 900, refreshDays * 86400)); // 15 mins
    }

    private static async Task<Results<Ok<TokensResponse>, UnauthorizedHttpResult, ProblemHttpResult>> Refresh(
        RefreshRequest request,
        HttpContext httpContext,
        IApplicationDbContext db,
        ITokenService tokenService,
        Microsoft.Extensions.Logging.ILogger<AdminAuthEndpoints> logger,
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
            logger.LogWarning("[AdminAuthentication] Refresh failed: Token not found.");
            return TypedResults.Unauthorized();
        }

        if (existingToken.IsRevoked)
        {
            // Reuse detection: If a revoked token is used, invalidate ALL tokens for this user
            logger.LogWarning("[AdminAuthentication] REUSE DETECTED: Revoked token used for user {UserId}. Invalidating all sessions.", existingToken.UserId);

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
            logger.LogWarning("[AdminAuthentication] Refresh failed: Token expired.");
            return TypedResults.Unauthorized();
        }

        // Token is valid. Rotate it preserving duration window.
        existingToken.RevokedAt = DateTime.UtcNow;
        existingToken.RevokedByIp = ip;
        existingToken.ReasonRevoked = "Rotated";

        var (newAccess, newRefresh) = tokenService.GenerateTokens(existingToken.User);

        var originalDuration = existingToken.ExpiresAt - existingToken.CreatedAt;
        var refreshDays = originalDuration.TotalDays > 7 ? 30 : 1;

        var newTokenEntity = new RefreshToken
        {
            Id = Guid.NewGuid(),
            UserId = existingToken.UserId,
            TokenHash = tokenService.HashToken(newRefresh),
            ExpiresAt = DateTime.UtcNow.AddDays(refreshDays),
            CreatedAt = DateTime.UtcNow,
            CreatedByIp = ip
        };

        existingToken.ReplacedByToken = newTokenEntity.TokenHash;

        db.RefreshTokens.Add(newTokenEntity);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[AdminAuthentication] Token successfully refreshed for user {UserId}", existingToken.UserId);
        return TypedResults.Ok(new TokensResponse(newAccess, newRefresh, 900, refreshDays * 86400));
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

    private static async Task<Results<Ok<UserResponse>, UnauthorizedHttpResult, NotFound>> GetMe(
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
            roles
        ));
    }
}

/// <summary>
/// Payload submitted by administrators to initiate the login process.
/// </summary>
public record AdminLoginRequest(string Email, string Password, bool RememberMe = false);

/// <summary>
/// Contains a tracking identifier to correlate the requested OTP for 2FA, or tokens directly if bypassed in development.
/// </summary>
public record AdminLoginResponse(
    Guid VerificationToken,
    int ExpiresIn,
    bool DevBypass = false,
    string? AccessToken = null,
    string? RefreshToken = null,
    int? RefreshExpiresIn = null);

/// <summary>
/// Payload to verify a previously sent 2FA OTP using the tracking identifier.
/// </summary>
public record AdminVerifyOtpRequest(Guid VerificationToken, string OtpCode);

/// <summary>
/// Contains the JWT access token and refresh token upon successful authentication.
/// </summary>
public record TokensResponse(string AccessToken, string RefreshToken, int ExpiresIn, int RefreshExpiresIn = 86400);

/// <summary>
/// Payload to request a token refresh or revocation.
/// </summary>
public record RefreshRequest(string RefreshToken);
