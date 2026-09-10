using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public static class GetCommunityFeed
{
    public static async Task<IReadOnlyList<PostSummaryResponse>> HandleAsync(
        IApplicationDbContext db,
        string? type,
        string? status,
        string sort,
        Guid? cursorId,
        DateTimeOffset? cursorDate,
        long currentUserId,
        int pageSize = 10,
        CancellationToken cancellationToken = default)
    {
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == currentUserId, cancellationToken);
        var lp = user?.LifestyleProfile;

        var userHomeSize = lp?.HomeSize;
        bool userHasYard = lp?.HasEnclosedYard ?? false;
        bool userHasChildren = lp?.HasChildren ?? false;
        var userActivityTempo = lp?.ActivityTempo;
        var userExistingPets = lp?.ExistingPets ?? new List<string>();

        var query = db.Posts.AsNoTracking()
            .Include(p => p.Author)
                .ThenInclude(u => u.Roles)
            .Include(p => p.Media)
            .Where(p => !p.IsDeleted);

        if (string.IsNullOrEmpty(status))
        {
            query = query
                .Where(p => !(p.Type == PostType.RescueAlert && p.Status == PostStatus.Completed))
                .Where(p => !(p.Type == PostType.AdoptionListing && p.Status == PostStatus.Completed))
                .Where(p => !(p.Type == PostType.SponsorshipRequest && (p.Status == PostStatus.PendingApproval || p.Status == PostStatus.Rejected || p.Status == PostStatus.Cancelled)));
        }
        else if (Enum.TryParse<PostStatus>(status, true, out var postStatus))
        {
            query = query.Where(p => p.Status == postStatus);
        }

        if (!string.IsNullOrEmpty(type) && Enum.TryParse<PostType>(type, true, out var postType))
        {
            query = query.Where(p => p.Type == postType);
        }

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

        if (string.Equals(sort, "oldest", StringComparison.OrdinalIgnoreCase))
        {
            query = query.OrderBy(p => p.CreatedAt).ThenBy(p => p.Id);
        }
        else if (string.Equals(sort, "likes", StringComparison.OrdinalIgnoreCase) || string.Equals(sort, "popular", StringComparison.OrdinalIgnoreCase))
        {
            query = query.OrderByDescending(p => p.LikeCount).ThenByDescending(p => p.CreatedAt);
        }
        else if (string.Equals(sort, "newest", StringComparison.OrdinalIgnoreCase))
        {
            query = query.OrderByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id);
        }
        else
        {
            // Rank AdoptionListing posts that match the user's lifestyle first.
            query = query.OrderByDescending(p =>
                p.Type == PostType.AdoptionListing && p.Expectations != null &&
                (!p.Expectations.RequiresEnclosedYard || userHasYard) &&
                (p.Expectations.GoodWithChildren || !userHasChildren) &&
                (p.Expectations.HomeSize == null || userHomeSize == null || p.Expectations.HomeSize <= userHomeSize) &&
                (p.Expectations.ActivityTempo == null || userActivityTempo == null || p.Expectations.ActivityTempo <= userActivityTempo)
            ).ThenByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id);
        }

        pageSize = Math.Clamp(pageSize, 1, 50);
        var posts = await query.Take(pageSize).ToListAsync(cancellationToken);

        var postIds = posts.Select(p => p.Id).ToList();
        var userLikes = await db.PostLikes.AsNoTracking()
            .Where(pl => pl.UserId == currentUserId && postIds.Contains(pl.PostId))
            .Select(pl => pl.PostId)
            .ToListAsync(cancellationToken);
        var userLikesSet = new HashSet<Guid>(userLikes);

        return posts.Select(p =>
        {
            bool isRecommended = false;
            if (p.Type == PostType.AdoptionListing && p.Expectations != null)
            {
                // GoodWithPets: the post's required-compatible species must overlap with the user's existing pets.
                bool petsCompatible = p.Expectations.GoodWithPets.Count == 0
                    || p.Expectations.GoodWithPets.All(pet => userExistingPets.Contains(pet));

                isRecommended =
                    (!p.Expectations.RequiresEnclosedYard || userHasYard) &&
                    (p.Expectations.GoodWithChildren || !userHasChildren) &&
                    (p.Expectations.HomeSize == null || userHomeSize == null || p.Expectations.HomeSize <= userHomeSize) &&
                    (p.Expectations.ActivityTempo == null || userActivityTempo == null || p.Expectations.ActivityTempo <= userActivityTempo) &&
                    petsCompatible;
            }

            return new PostSummaryResponse(
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
                isRecommended,
                p.Author.Roles.Any(r => r.IsVerified)
            );
        }).ToList();
    }
}
