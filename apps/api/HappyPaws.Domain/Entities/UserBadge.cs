using System;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class UserBadge : IAuditableEntity
{
    public long Id { get; set; }
    public long UserId { get; set; }
    public BadgeType BadgeType { get; set; }
    public DateTimeOffset AwardedAt { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;
}
