using System;
using System.Collections.Generic;

namespace HappyPaws.Domain.Entities;

public class User : IAuditableEntity, ISoftDeletable
{
    public long Id { get; set; }
    public required string Email { get; set; }
    public required string PasswordHash { get; set; }
    public required string FirstName { get; set; }
    public required string LastName { get; set; }
    public string? PhoneNumber { get; set; }
    public string? AvatarUrl { get; set; }
    public string? Tagline { get; set; }
    public string? Username { get; set; }
    public int ReputationPoints { get; set; } = 0;
    public bool IsActive { get; set; } = true;
    public bool IsDeleted { get; set; } = false;
    public bool ReceiveMessages { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public string? AddressLine1 { get; set; }
    public string? AddressLine2 { get; set; }
    public string? City { get; set; }
    public string? State { get; set; }
    public string? PostalCode { get; set; }
    public string? Country { get; set; }
    public double? HomeLatitude { get; set; }
    public double? HomeLongitude { get; set; }

    public LifestyleProfile? LifestyleProfile { get; set; }

    private readonly List<UserRole> _roles = new();
    public IReadOnlyCollection<UserRole> Roles => _roles.AsReadOnly();

    private readonly List<UserDevice> _devices = new();
    public IReadOnlyCollection<UserDevice> Devices => _devices.AsReadOnly();

    private readonly List<RefreshToken> _refreshTokens = new();
    public IReadOnlyCollection<RefreshToken> RefreshTokens => _refreshTokens.AsReadOnly();

    private readonly List<UserBadge> _badges = new();
    public IReadOnlyCollection<UserBadge> Badges => _badges.AsReadOnly();

    public void AddReputationPoints(int points)
    {
        ReputationPoints += points;
    }

    public void AddRole(Enums.RoleName roleName, bool isVerified = false, bool isVisible = true)
    {
        var existingRole = _roles.FirstOrDefault(r => r.RoleName == roleName);
        if (existingRole == null)
        {
            _roles.Add(new UserRole { RoleName = roleName, IsVerified = isVerified, IsVisible = isVisible });
        }
        else if (isVerified && !existingRole.IsVerified)
        {
            existingRole.IsVerified = true;
        }
    }
}
