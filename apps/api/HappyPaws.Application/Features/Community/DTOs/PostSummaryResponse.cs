using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record PostSummaryResponse(
    Guid Id,
    string Type,
    string Status,
    string Title,
    string Body,
    int LikeCount,
    bool IsLikedByCurrentUser,
    string AuthorDisplayName,
    string? AuthorAvatarUrl,
    long AuthorId,
    string? LocationLabel,
    double? Latitude,
    double? Longitude,
    string? AnimalSpecies,
    string? AnimalName,
    string? FirstPhotoUrl,
    int PhotoCount,
    DateTimeOffset CreatedAt,
    string? UrgencyLevel,
    string? AiTriageReason,
    bool IsUrgencyManuallyOverridden,
    bool IsRecommended,
    bool IsAuthorVerified = false
);
