using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite;
using NetTopologySuite.Geometries;

namespace HappyPaws.Application.Features.Community.Queries;

public static class GetMapBoundsFeed
{
    public static async Task<IReadOnlyList<PostSummaryResponse>> HandleAsync(
        IApplicationDbContext db,
        double swLat,
        double swLon,
        double neLat,
        double neLon,
        string? type,
        long currentUserId,
        CancellationToken cancellationToken)
    {
        var geometryFactory = NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);
        var bounds = geometryFactory.CreatePolygon(new[]
        {
            new Coordinate(swLon, swLat),
            new Coordinate(swLon, neLat),
            new Coordinate(neLon, neLat),
            new Coordinate(neLon, swLat),
            new Coordinate(swLon, swLat)
        });

        var query = db.Posts.AsNoTracking()
            .Include(p => p.Author)
            .Include(p => p.Media)
            .Where(p => !p.IsDeleted && p.LocationPoint != null)
            .Where(p => bounds.Contains(p.LocationPoint))
            .Where(p => !(p.Type == PostType.RescueAlert && p.Status == PostStatus.Completed))
            .Where(p => !(p.Type == PostType.AdoptionListing && p.Status == PostStatus.Completed))
            .Where(p => !(p.Type == PostType.SponsorshipRequest && (p.Status == PostStatus.PendingApproval || p.Status == PostStatus.Rejected || p.Status == PostStatus.Cancelled)));

        if (!string.IsNullOrWhiteSpace(type) && Enum.TryParse<PostType>(type, true, out var postType))
        {
            query = query.Where(p => p.Type == postType);
        }

        query = query.OrderByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id);

        // Cap to 100 points to prevent overwhelming the client
        var posts = await query.Take(100).ToListAsync(cancellationToken);

        var postIds = posts.Select(p => p.Id).ToList();
        var userLikes = await db.PostLikes.AsNoTracking()
            .Where(pl => pl.UserId == currentUserId && postIds.Contains(pl.PostId))
            .Select(pl => pl.PostId)
            .ToListAsync(cancellationToken);
        var userLikesSet = new HashSet<Guid>(userLikes);

        return posts.Select(p => new PostSummaryResponse(
            p.Id,
            p.Type.ToString(),
            p.Status.ToString(),
            p.Title,
            p.Body,
            p.LikeCount,
            userLikesSet.Contains(p.Id),
            p.Author.FirstName + " " + p.Author.LastName,
            p.Author.AvatarUrl,
            p.AuthorId,
            p.LocationLabel,
            p.LocationPoint?.Y,
            p.LocationPoint?.X,
            p.AnimalSpecies,
            p.AnimalName,
            p.Media.OrderBy(m => m.SortOrder).FirstOrDefault()?.CdnUrl,
            p.Media.Count,
            p.CreatedAt,
            p.UrgencyLevel?.ToString(),
            p.AiTriageReason,
            p.IsUrgencyManuallyOverridden,
            false
        )).ToList();
    }
}
