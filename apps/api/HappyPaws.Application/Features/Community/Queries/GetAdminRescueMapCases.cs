using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record AdminRescueMapCaseResponse(
    Guid Id,
    string Title,
    string Status,
    string? AnimalName,
    string? AnimalSpecies,
    string? UrgencyLevel,
    string? AiTriageReason,
    bool IsUrgencyManuallyOverridden,
    double? Latitude,
    double? Longitude,
    string? LocationLabel,
    DateTimeOffset CreatedAt
);

public static class GetAdminRescueMapCases
{
    public static async Task<IReadOnlyList<AdminRescueMapCaseResponse>> HandleAsync(
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var targetStatuses = new[] { PostStatus.Active, PostStatus.Fostered, PostStatus.Assigned };

        var posts = await db.Posts.AsNoTracking()
            .Where(p => p.Type == PostType.RescueAlert && targetStatuses.Contains(p.Status) && !p.IsDeleted)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return posts.Select(p => new AdminRescueMapCaseResponse(
            p.Id,
            p.Title,
            p.Status.ToString(),
            p.AnimalName,
            p.AnimalSpecies,
            p.UrgencyLevel?.ToString(),
            p.AiTriageReason,
            p.IsUrgencyManuallyOverridden,
            p.LocationPoint?.Y,
            p.LocationPoint?.X,
            p.LocationLabel,
            p.CreatedAt
        )).ToList();
    }
}
