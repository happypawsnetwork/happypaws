using System;
using System.Collections.Generic;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record PostDetailResponse(
    Guid Id,
    string Type,
    string Status,
    string Title,
    string Body,
    int LikeCount,
    bool IsLikedByCurrentUser,
    string AuthorDisplayName,
    string? AuthorAvatarUrl,
    string? AuthorTagline,
    long AuthorId,
    string? LocationLabel,
    double? Latitude,
    double? Longitude,
    string? AnimalSpecies,
    string? AnimalName,
    string? AnimalDescription,
    IReadOnlyList<PostMediaResponse> Media,
    Guid? ParentPostId,
    string? ParentPostTitle,
    int? ApplicantCount,
    VetRequestDetailsResponse? VetDetails,
    SponsorshipDetailsResponse? SponsorshipDetails,
    DateTimeOffset CreatedAt,
    string? UrgencyLevel,
    string? AiTriageReason,
    bool IsUrgencyManuallyOverridden,
    LifestyleExpectationsResponse? Expectations = null,
    bool IsAuthorVerified = false
);
