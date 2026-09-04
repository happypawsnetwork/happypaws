using System;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class VerificationDocument
{
    public long Id { get; set; }
    public long VerificationRequestId { get; set; }
    public DocumentType DocumentType { get; set; }
    public required string DocumentUri { get; set; }
    public DateTimeOffset UploadDate { get; set; } = DateTimeOffset.UtcNow;

    public VerificationRequest VerificationRequest { get; set; } = null!;
}

