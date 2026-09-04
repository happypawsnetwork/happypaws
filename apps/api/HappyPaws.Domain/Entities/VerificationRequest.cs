using System;
using System.Collections.Generic;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class VerificationRequest : IAuditableEntity
{
    public long Id { get; set; }
    public long UserId { get; set; }
    public RoleName RequestedRole { get; set; }
    public VerificationStatus Status { get; set; } = VerificationStatus.Pending;
    public string? Notes { get; set; }

    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User User { get; set; } = null!;

    private readonly List<VerificationDocument> _documents = new();
    public IReadOnlyCollection<VerificationDocument> Documents => _documents.AsReadOnly();

    public void AddDocument(DocumentType type, string uri)
    {
        _documents.Add(new VerificationDocument
        {
            DocumentType = type,
            DocumentUri = uri
        });
    }
}

