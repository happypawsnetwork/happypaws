using System;
using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record AdminPostResponse(
    Guid Id,
    string Type,
    string Status,
    string Title,
    string Body,
    int LikeCount,
    string AuthorDisplayName,
    string? AuthorEmail,
    long AuthorId,
    string? AuthorAvatarUrl,
    string? LocationLabel,
    double? Latitude,
    double? Longitude,
    string? AnimalSpecies,
    string? AnimalName,
    string? FirstPhotoUrl,
    int PhotoCount,
    IReadOnlyList<string> PhotoUrls,
    string? UrgencyLevel,
    string? AiTriageReason,
    bool IsUrgencyManuallyOverridden,
    bool IsDeleted,
    DateTimeOffset CreatedAt,
    DateTimeOffset UpdatedAt
);

public static class GetAdminPosts
{
    public static async Task<IReadOnlyList<AdminPostResponse>> HandleAsync(
        IAdminPostQueryService queryService,
        string? type,
        string? status,
        string? search,
        bool includeDeleted,
        CancellationToken ct)
    {
        return await queryService.GetAdminPostsAsync(type, status, search, includeDeleted, ct);
    }
}
