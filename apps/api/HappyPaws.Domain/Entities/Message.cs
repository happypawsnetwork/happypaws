using System;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class Message : ISoftDeletable
{
    public long Id { get; set; }
    public long ThreadId { get; set; }
    public ChatThread Thread { get; set; } = null!;

    public long SenderId { get; set; }
    public User Sender { get; set; } = null!;

    public MessageType MessageType { get; set; } = MessageType.Text;

    // Will hold text, or URL for images, or coordinates for location
    public string Content { get; set; } = string.Empty;

    public double? Latitude { get; set; }
    public double? Longitude { get; set; }

    public DateTimeOffset SentAt { get; set; }
    public DateTimeOffset? DeliveredAt { get; set; }
    public DateTimeOffset? SeenAt { get; set; }

    public bool IsDeleted { get; set; } = false;
}
