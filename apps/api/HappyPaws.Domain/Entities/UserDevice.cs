using System;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class UserDevice
{
    public long Id { get; set; }
    public long UserId { get; set; }
    public required string FcmToken { get; set; }
    public DeviceType? DeviceType { get; set; }
    public DateTimeOffset LastActiveAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public string? RefreshTokenHash { get; set; }
    public DateTimeOffset? RefreshTokenExpiryTime { get; set; }
}
