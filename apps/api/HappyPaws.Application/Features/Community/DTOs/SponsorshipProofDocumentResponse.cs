using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record SponsorshipProofDocumentResponse(
    Guid Id,
    string FileName,
    string MimeType,
    int FileSizeBytes,
    string PresignedUrl,
    DateTimeOffset UploadedAt
);
