using System;

namespace HappyPaws.Domain.Entities;

public class CanMessage : IAuditableEntity
{
    public long Id { get; set; }

    public long FromUserId { get; set; }
    public User FromUser { get; set; } = null!;

    public long ToUserId { get; set; }
    public User ToUser { get; set; } = null!;

    public bool IsAllowed { get; set; } = false;

    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
}
