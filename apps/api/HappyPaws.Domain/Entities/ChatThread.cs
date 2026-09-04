using System;
using System.Collections.Generic;

namespace HappyPaws.Domain.Entities;

public class ChatThread : IAuditableEntity
{
    public long Id { get; set; }
    public bool IsDirectMessage { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    private readonly List<ChatParticipant> _participants = new();
    public IReadOnlyCollection<ChatParticipant> Participants => _participants.AsReadOnly();

    private readonly List<Message> _messages = new();
    public IReadOnlyCollection<Message> Messages => _messages.AsReadOnly();

    public void AddParticipant(ChatParticipant participant)
    {
        _participants.Add(participant);
    }
}
