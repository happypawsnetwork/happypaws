using System;

namespace HappyPaws.Domain.Entities;

public class ChatParticipant
{
    public long ThreadId { get; set; }
    public ChatThread Thread { get; set; } = null!;

    public long UserId { get; set; }
    public User User { get; set; } = null!;

    public DateTimeOffset? LastReadAt { get; set; }
    public DateTimeOffset? ClearedAt { get; set; }
}
