using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public static class GetMyPosts
{
    public static async Task<IReadOnlyList<PostSummaryResponse>> HandleAsync(
        IApplicationDbContext db,
        long currentUserId,
        CancellationToken cancellationToken)
    {
        var posts = await db.Posts.AsNoTracking()
            .Include(p => p.Author)
                .ThenInclude(u => u.Roles)
            .Include(p => p.Media)
            .Where(p => p.AuthorId == currentUserId && !p.IsDeleted)
            .OrderByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id)
            .Take(20)
            .ToListAsync(cancellationToken);

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
            null,
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
            p.Author.Roles.Any(r => r.IsVerified)
        )).ToList();
    }
}
