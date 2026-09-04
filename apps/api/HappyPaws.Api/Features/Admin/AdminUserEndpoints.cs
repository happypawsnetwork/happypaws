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
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Api.Features.Admin;

public sealed class AdminUserEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/admin/users")
            .WithTags("Admin Users")
            .RequireAuthorization();

        group.MapGet("/", GetUsersAsync)
            .WithName("GetAdminUsers")
            .WithSummary("Get paginated list of real registered users")
            .WithDescription("Retrieves a searchable, filterable list of user accounts with roles and activity status from the database.")
            .Produces<AdminUsersListResponse>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("/{id:long}", GetUserByIdAsync)
            .WithName("GetAdminUserById")
            .WithSummary("Get detailed user information by identifier")
            .WithDescription("Retrieves complete profile, role assignments, and session metadata for a specific user.")
            .Produces<AdminUserDetailDto>(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/", CreateUserAsync)
            .WithName("CreateAdminUser")
            .WithSummary("Create a new user account with assigned roles")
            .WithDescription("Provisions a new user profile with credentials and role privileges directly in the database.")
            .Produces<AdminUserSummaryDto>(StatusCodes.Status201Created)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapPatch("/{id:long}/status", UpdateUserStatusAsync)
            .WithName("UpdateAdminUserStatus")
            .WithSummary("Update active or deactivated state of a user account")
            .WithDescription("Updates the active or soft-deleted status of a user account to manage access.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPut("/{id:long}/roles", UpdateUserRolesAsync)
            .WithName("UpdateAdminUserRoles")
            .WithSummary("Update user role assignments")
            .WithDescription("Replaces the assigned system roles for the specified user account.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/{id:long}/reputation", AdjustReputationAsync)
            .WithName("AdjustAdminUserReputation")
            .WithSummary("Adjust user reputation points")
            .WithDescription("Updates the reputation score of a user account for trust or dispute resolution.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);

        group.MapPost("/{id:long}/reset-password", ResetPasswordAsync)
            .WithName("ResetAdminUserPassword")
            .WithSummary("Reset user password by administrator")
            .WithDescription("Sets a new password for the specified user and revokes existing active sessions.")
            .Produces(StatusCodes.Status200OK)
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized)
            .ProducesProblem(StatusCodes.Status404NotFound);
    }

    private static async Task<Results<Ok<AdminUsersListResponse>, UnauthorizedHttpResult>> GetUsersAsync(
        string? search,
        string? role,
        string? status,
        string? sortBy,
        int? page,
        int? pageSize,
        IApplicationDbContext db,
        ILogger<AdminUserEndpoints> logger,
        CancellationToken ct)
    {
        int currentPage = Math.Max(1, page ?? 1);
        int take = Math.Clamp(pageSize ?? 10, 1, 100);
        int skip = (currentPage - 1) * take;

        logger.LogInformation("[AdminUsers] Fetching users page {Page}, search: '{Search}', role: '{Role}', status: '{Status}', sort: '{Sort}'",
            currentPage, search, role, status, sortBy);

        var baseQuery = db.Users.AsNoTracking();

        // Calculate global stats across all accounts in database
        int totalUsers = await baseQuery.CountAsync(ct);
        int activeUsers = await baseQuery.CountAsync(u => u.IsActive && !u.IsDeleted, ct);
        int suspendedUsers = await baseQuery.CountAsync(u => !u.IsActive && !u.IsDeleted, ct);
        int deletedUsers = await baseQuery.CountAsync(u => u.IsDeleted, ct);

        var query = baseQuery.Include(u => u.Roles).AsQueryable();

        // Filter by status
        if (!string.IsNullOrWhiteSpace(status) && status != "all")
        {
            query = status.ToLowerInvariant() switch
            {
                "active" => query.Where(u => u.IsActive && !u.IsDeleted),
                "suspended" => query.Where(u => !u.IsActive && !u.IsDeleted),
                "deleted" => query.Where(u => u.IsDeleted),
                _ => query
            };
        }

        // Filter by search
        if (!string.IsNullOrWhiteSpace(search))
        {
            var term = search.Trim().ToLower();
            query = query.Where(u =>
                u.Email.ToLower().Contains(term) ||
                u.FirstName.ToLower().Contains(term) ||
                u.LastName.ToLower().Contains(term) ||
                (u.PhoneNumber != null && u.PhoneNumber.Contains(term)));
        }

        // Filter by role
        if (!string.IsNullOrWhiteSpace(role) && role != "all" && Enum.TryParse<RoleName>(role, true, out var parsedRole))
        {
            query = query.Where(u => u.Roles.Any(r => r.RoleName == parsedRole));
        }

        // Sorting
        query = (sortBy?.ToLowerInvariant()) switch
        {
            "oldest" => query.OrderBy(u => u.CreatedAt),
            "reputation_desc" => query.OrderByDescending(u => u.ReputationPoints),
            "reputation_asc" => query.OrderBy(u => u.ReputationPoints),
            "name_asc" => query.OrderBy(u => u.FirstName).ThenBy(u => u.LastName),
            "name_desc" => query.OrderByDescending(u => u.FirstName).ThenByDescending(u => u.LastName),
            _ => query.OrderByDescending(u => u.CreatedAt)
        };

        int filteredCount = await query.CountAsync(ct);

        var users = await query
            .Skip(skip)
            .Take(take)
            .Select(u => new AdminUserSummaryDto(
                u.Id,
                u.Email,
                u.FirstName,
                u.LastName,
                u.PhoneNumber,
                u.AvatarUrl,
                u.Tagline,
                u.ReputationPoints,
                u.IsActive,
                u.IsDeleted,
                u.Roles.Select(r => r.RoleName.ToString()).ToList(),
                u.CreatedAt,
                u.UpdatedAt
            ))
            .ToListAsync(ct);

        int totalPages = (int)Math.Ceiling(filteredCount / (double)take);

        var stats = new AdminUserStatsDto(totalUsers, activeUsers, suspendedUsers, deletedUsers);

        var response = new AdminUsersListResponse(
            Items: users,
            TotalCount: filteredCount,
            Page: currentPage,
            PageSize: take,
            TotalPages: totalPages,
            Stats: stats
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Ok<AdminUserDetailDto>, UnauthorizedHttpResult, NotFound>> GetUserByIdAsync(
        long id,
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var user = await db.Users
            .AsNoTracking()
            .Include(u => u.Roles)
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Id == id, ct);

        if (user is null)
        {
            return TypedResults.NotFound();
        }

        var activeSessions = user.RefreshTokens.Count(rt => rt.IsActive);

        var response = new AdminUserDetailDto(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.PhoneNumber,
            user.AvatarUrl,
            user.Tagline,
            user.ReputationPoints,
            user.IsActive,
            user.IsDeleted,
            user.Roles.Select(r => new Auth.UserRoleDto(r.RoleName.ToString(), r.IsVerified, r.IsVisible)).ToList(),
            activeSessions,
            user.CreatedAt,
            user.UpdatedAt
        );

        return TypedResults.Ok(response);
    }

    private static async Task<Results<Created<AdminUserSummaryDto>, BadRequest<string>, UnauthorizedHttpResult>> CreateUserAsync(
        CreateAdminUserRequest request,
        IApplicationDbContext db,
        ILogger<AdminUserEndpoints> logger,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Email) || string.IsNullOrWhiteSpace(request.Password))
        {
            return TypedResults.BadRequest("Email and password are required.");
        }

        var existing = await db.Users.AnyAsync(u => u.Email.ToLower() == request.Email.Trim().ToLower(), ct);
        if (existing)
        {
            return TypedResults.BadRequest("An account with this email address already exists.");
        }

        var user = new User
        {
            Email = request.Email.Trim().ToLower(),
            FirstName = request.FirstName.Trim(),
            LastName = request.LastName.Trim(),
            PhoneNumber = string.IsNullOrWhiteSpace(request.PhoneNumber) ? null : request.PhoneNumber.Trim(),
            ReputationPoints = Math.Max(0, request.InitialReputationPoints),
            IsActive = true,
            IsDeleted = false,
            PasswordHash = string.Empty,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        var hasher = new PasswordHasher<User>();
        user.PasswordHash = hasher.HashPassword(user, request.Password);

        if (request.Roles != null && request.Roles.Count > 0)
        {
            foreach (var roleStr in request.Roles)
            {
                if (Enum.TryParse<RoleName>(roleStr, true, out var roleEnum))
                {
                    user.AddRole(roleEnum);
                }
            }
        }
        else
        {
            user.AddRole(RoleName.Adopter);
        }

        db.Users.Add(user);
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[AdminUsers] Created new user {Email} with ID {UserId}", user.Email, user.Id);

        var dto = new AdminUserSummaryDto(
            user.Id,
            user.Email,
            user.FirstName,
            user.LastName,
            user.PhoneNumber,
            user.AvatarUrl,
            user.Tagline,
            user.ReputationPoints,
            user.IsActive,
            user.IsDeleted,
            user.Roles.Select(r => r.RoleName.ToString()).ToList(),
            user.CreatedAt,
            user.UpdatedAt
        );

        return TypedResults.Created($"/api/admin/users/{user.Id}", dto);
    }

    private static async Task<Results<Ok, BadRequest<string>, UnauthorizedHttpResult, NotFound>> UpdateUserStatusAsync(
        long id,
        UpdateAdminUserStatusRequest request,
        IApplicationDbContext db,
        ILogger<AdminUserEndpoints> logger,
        CancellationToken ct)
    {
        var user = await db.Users
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Id == id, ct);

        if (user is null)
        {
            return TypedResults.NotFound();
        }

        if (request.IsActive.HasValue)
        {
            user.IsActive = request.IsActive.Value;
            if (!user.IsActive)
            {
                // Invalidate active login sessions on suspension
                foreach (var token in user.RefreshTokens.Where(t => t.IsActive))
                {
                    token.RevokedAt = DateTime.UtcNow;
                    token.ReasonRevoked = "Account suspended by administrator";
                }
            }
        }

        if (request.IsDeleted.HasValue)
        {
            user.IsDeleted = request.IsDeleted.Value;
            if (user.IsDeleted)
            {
                user.IsActive = false;
                foreach (var token in user.RefreshTokens.Where(t => t.IsActive))
                {
                    token.RevokedAt = DateTime.UtcNow;
                    token.ReasonRevoked = "Account deactivated by administrator";
                }
            }
        }

        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[AdminUsers] Updated user {UserId} status (IsActive: {IsActive}, IsDeleted: {IsDeleted})",
            id, user.IsActive, user.IsDeleted);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, BadRequest<string>, UnauthorizedHttpResult, NotFound>> UpdateUserRolesAsync(
        long id,
        UpdateAdminUserRolesRequest request,
        IApplicationDbContext db,
        ILogger<AdminUserEndpoints> logger,
        CancellationToken ct)
    {
        var user = await db.Users
            .Include(u => u.Roles)
            .FirstOrDefaultAsync(u => u.Id == id, ct);

        if (user is null)
        {
            return TypedResults.NotFound();
        }

        if (request.Roles == null || request.Roles.Count == 0)
        {
            return TypedResults.BadRequest("A user must have at least one assigned role.");
        }

        // Remove existing roles
        var existingRoles = await db.UserRoles.Where(r => r.UserId == id).ToListAsync(ct);
        db.UserRoles.RemoveRange(existingRoles);

        // Add updated roles
        foreach (var roleStr in request.Roles)
        {
            if (Enum.TryParse<RoleName>(roleStr, true, out var roleEnum))
            {
                db.UserRoles.Add(new UserRole
                {
                    UserId = id,
                    RoleName = roleEnum
                });
            }
        }

        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[AdminUsers] Updated roles for user {UserId}", id);

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, BadRequest<string>, UnauthorizedHttpResult, NotFound>> AdjustReputationAsync(
        long id,
        AdjustReputationRequest request,
        IApplicationDbContext db,
        ILogger<AdminUserEndpoints> logger,
        CancellationToken ct)
    {
        var user = await db.Users.FirstOrDefaultAsync(u => u.Id == id, ct);
        if (user is null)
        {
            return TypedResults.NotFound();
        }

        user.ReputationPoints = Math.Max(0, request.Points);
        user.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        logger.LogInformation("[AdminUsers] Adjusted reputation points to {Points} for user {UserId}. Reason: {Reason}",
            user.ReputationPoints, id, request.Reason ?? "Not specified");

        return TypedResults.Ok();
    }

    private static async Task<Results<Ok, BadRequest<string>, UnauthorizedHttpResult, NotFound>> ResetPasswordAsync(
        long id,
        ResetPasswordAdminRequest request,
        IApplicationDbContext db,
        ILogger<AdminUserEndpoints> logger,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
        {
            return TypedResults.BadRequest("Password must contain at least 6 characters.");
        }

        var user = await db.Users
            .Include(u => u.RefreshTokens)
            .FirstOrDefaultAsync(u => u.Id == id, ct);

        if (user is null)
        {
            return TypedResults.NotFound();
        }

        var hasher = new PasswordHasher<User>();
        user.PasswordHash = hasher.HashPassword(user, request.NewPassword);
        user.UpdatedAt = DateTimeOffset.UtcNow;

        // Invalidate active sessions upon password reset
        foreach (var token in user.RefreshTokens.Where(t => t.IsActive))
        {
            token.RevokedAt = DateTime.UtcNow;
            token.ReasonRevoked = "Password reset by administrator";
        }

        await db.SaveChangesAsync(ct);

        logger.LogInformation("[AdminUsers] Reset password for user {UserId}", id);

        return TypedResults.Ok();
    }
}

/// <summary>
/// Summary item for a user in the administrator user directory.
/// </summary>
public sealed record AdminUserSummaryDto(
    long Id,
    string Email,
    string FirstName,
    string LastName,
    string? PhoneNumber,
    string? AvatarUrl,
    string? Tagline,
    int ReputationPoints,
    bool IsActive,
    bool IsDeleted,
    IReadOnlyList<string> Roles,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

/// <summary>
/// Summary count of accounts grouped by system status.
/// </summary>
public sealed record AdminUserStatsDto(
    int TotalUsers,
    int ActiveUsers,
    int SuspendedUsers,
    int DeletedUsers);

/// <summary>
/// Paginated list of users with status breakdown stats.
/// </summary>
public sealed record AdminUsersListResponse(
    IReadOnlyList<AdminUserSummaryDto> Items,
    int TotalCount,
    int Page,
    int PageSize,
    int TotalPages,
    AdminUserStatsDto Stats);

/// <summary>
/// Detailed user information for inspector view.
/// </summary>
public sealed record AdminUserDetailDto(
    long Id,
    string Email,
    string FirstName,
    string LastName,
    string? PhoneNumber,
    string? AvatarUrl,
    string? Tagline,
    int ReputationPoints,
    bool IsActive,
    bool IsDeleted,
    IReadOnlyList<Auth.UserRoleDto> Roles,
    int ActiveSessionsCount,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt);

/// <summary>
/// Request payload to create a new user by administrator.
/// </summary>
public sealed record CreateAdminUserRequest(
    string FirstName,
    string LastName,
    string Email,
    string Password,
    string? PhoneNumber,
    IReadOnlyList<string>? Roles,
    int InitialReputationPoints);

/// <summary>
/// Request payload to update account active or deleted status.
/// </summary>
public sealed record UpdateAdminUserStatusRequest(
    bool? IsActive,
    bool? IsDeleted);

/// <summary>
/// Request payload to update role assignments.
/// </summary>
public sealed record UpdateAdminUserRolesRequest(
    IReadOnlyList<string> Roles);

/// <summary>
/// Request payload to adjust user reputation points.
/// </summary>
public sealed record AdjustReputationRequest(
    int Points,
    string? Reason);

/// <summary>
/// Request payload to reset a user password.
/// </summary>
public sealed record ResetPasswordAdminRequest(
    string NewPassword);
