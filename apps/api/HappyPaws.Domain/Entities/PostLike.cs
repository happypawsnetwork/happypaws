using System;

namespace HappyPaws.Domain.Entities;

public class PostLike
{
    public Guid PostId { get; set; }
    public long UserId { get; set; }
    public DateTimeOffset LikedAt { get; set; }

    public Post Post { get; set; } = null!;
    public User User { get; set; } = null!;
}
