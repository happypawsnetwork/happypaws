using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class UserRole
{
    public long UserId { get; set; }
    public RoleName RoleName { get; set; }
    public bool IsVerified { get; set; } = false;
    public bool IsVisible { get; set; } = true;
}
