using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace HappyPaws.Application.Features.Community.Queries;

public static class GetNearbyFeed
{
    public static async Task<IReadOnlyList<PostSummaryResponse>> HandleAsync(
        IApplicationDbContext db,
        double lat,
        double lon,
        double radiusKm,
        long currentUserId,
        Guid? cursorId = null,
        DateTimeOffset? cursorDate = null,
        int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var radiusMetres = radiusKm * 1000;
        var searchPoint = new Point(lon, lat) { SRID = 4326 };

        var query = db.Posts.AsNoTracking()
            .Include(p => p.Author)
            .Include(p => p.Media)
            .Where(p => !p.IsDeleted && p.LocationPoint != null)
            .Where(p => p.LocationPoint.IsWithinDistance(searchPoint, radiusMetres))
            .Where(p => !(p.Type == PostType.RescueAlert && p.Status == PostStatus.Completed))
            .Where(p => !(p.Type == PostType.AdoptionListing && p.Status == PostStatus.Completed))
            .Where(p => !(p.Type == PostType.SponsorshipRequest && (p.Status == PostStatus.PendingApproval || p.Status == PostStatus.Rejected || p.Status == PostStatus.Cancelled)));

        if (cursorDate.HasValue)
        {
            if (cursorId.HasValue)
            {
                query = query.Where(p => p.CreatedAt < cursorDate.Value || (p.CreatedAt == cursorDate.Value && p.Id != cursorId.Value));
            }
            else
            {
                query = query.Where(p => p.CreatedAt < cursorDate.Value);
            }
        }

        query = query.OrderByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id);

        pageSize = Math.Clamp(pageSize, 1, 50);
        var posts = await query.Take(pageSize).ToListAsync(cancellationToken);

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
