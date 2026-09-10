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

public static class SearchPosts
{
    public static async Task<IReadOnlyList<PostSummaryResponse>> HandleAsync(
        IApplicationDbContext db,
        string? query,
        string? species,
        string? location,
        string? urgency,
        string? type,
        string? status,
        double? lat,
        double? lon,
        double? radiusKm,
        string sort,
        Guid? cursorId,
        DateTimeOffset? cursorDate,
        long currentUserId,
        int pageSize = 20,
        CancellationToken cancellationToken = default)
    {
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == currentUserId, cancellationToken);
        var lp = user?.LifestyleProfile;

        var userHomeSize = lp?.HomeSize;
        bool userHasYard = lp?.HasEnclosedYard ?? false;
        bool userHasChildren = lp?.HasChildren ?? false;
        var userActivityTempo = lp?.ActivityTempo;
        var userExistingPets = lp?.ExistingPets ?? new List<string>();

        var postsQuery = db.Posts.AsNoTracking()
            .Include(p => p.Author)
                .ThenInclude(u => u.Roles)
            .Include(p => p.Media)
            .Where(p => !p.IsDeleted);

        // Filter by lifecycle status
        if (string.IsNullOrWhiteSpace(status) || string.Equals(status, "Active", StringComparison.OrdinalIgnoreCase))
        {
            postsQuery = postsQuery
                .Where(p => !(p.Type == PostType.RescueAlert && p.Status == PostStatus.Completed))
                .Where(p => !(p.Type == PostType.AdoptionListing && p.Status == PostStatus.Completed))
                .Where(p => !(p.Type == PostType.SponsorshipRequest && (p.Status == PostStatus.PendingApproval || p.Status == PostStatus.Rejected || p.Status == PostStatus.Cancelled)));
        }
        else if (Enum.TryParse<PostStatus>(status, true, out var postStatus))
        {
            postsQuery = postsQuery.Where(p => p.Status == postStatus);
        }

        // Filter by post type
        if (!string.IsNullOrWhiteSpace(type) && !string.Equals(type, "All", StringComparison.OrdinalIgnoreCase))
        {
            if (string.Equals(type, "FindHome", StringComparison.OrdinalIgnoreCase) ||
                string.Equals(type, "Find Home", StringComparison.OrdinalIgnoreCase))
            {
                postsQuery = postsQuery.Where(p => p.Type == PostType.AdoptionListing);
            }
            else if (string.Equals(type, "Rescue", StringComparison.OrdinalIgnoreCase))
            {
                postsQuery = postsQuery.Where(p => p.Type == PostType.RescueAlert);
            }
            else if (Enum.TryParse<PostType>(type, true, out var postType))
            {
                postsQuery = postsQuery.Where(p => p.Type == postType);
            }
        }

        // Filter by species
        if (!string.IsNullOrWhiteSpace(species) && !string.Equals(species, "All", StringComparison.OrdinalIgnoreCase))
        {
            var speciesTerm = species.Trim().ToLower();
            postsQuery = postsQuery.Where(p => p.AnimalSpecies != null && p.AnimalSpecies.ToLower().Contains(speciesTerm));
        }

        // Filter by location label
        if (!string.IsNullOrWhiteSpace(location) && !string.Equals(location, "All", StringComparison.OrdinalIgnoreCase))
        {
            var locationTerm = location.Trim().ToLower();
            postsQuery = postsQuery.Where(p => p.LocationLabel != null && p.LocationLabel.ToLower().Contains(locationTerm));
        }

        // Filter by coordinates and distance radius
        if (lat.HasValue && lon.HasValue)
        {
            var radiusMeters = (radiusKm ?? 10.0) * 1000.0;
            var searchPoint = new Point(lon.Value, lat.Value) { SRID = 4326 };
            postsQuery = postsQuery.Where(p => p.LocationPoint != null && p.LocationPoint.IsWithinDistance(searchPoint, radiusMeters));
        }

        // Filter by urgency level
        if (!string.IsNullOrWhiteSpace(urgency) && !string.Equals(urgency, "All", StringComparison.OrdinalIgnoreCase))
        {
            if (Enum.TryParse<RescueUrgencyLevel>(urgency, true, out var parsedUrgency))
            {
                postsQuery = postsQuery.Where(p => p.UrgencyLevel == parsedUrgency);
            }
        }

        // Search text query across title, body, animal name, animal description, species, and location
        if (!string.IsNullOrWhiteSpace(query))
        {
            var term = query.Trim().ToLower();
            postsQuery = postsQuery.Where(p =>
                p.Title.ToLower().Contains(term) ||
                p.Body.ToLower().Contains(term) ||
                (p.AnimalName != null && p.AnimalName.ToLower().Contains(term)) ||
                (p.AnimalDescription != null && p.AnimalDescription.ToLower().Contains(term)) ||
                (p.AnimalSpecies != null && p.AnimalSpecies.ToLower().Contains(term)) ||
                (p.LocationLabel != null && p.LocationLabel.ToLower().Contains(term)));
        }

        // Cursor pagination
        if (cursorDate.HasValue)
        {
            if (cursorId.HasValue)
            {
                postsQuery = postsQuery.Where(p => p.CreatedAt < cursorDate.Value || (p.CreatedAt == cursorDate.Value && p.Id != cursorId.Value));
            }
            else
            {
                postsQuery = postsQuery.Where(p => p.CreatedAt < cursorDate.Value);
            }
        }

        // Sorting independent of matching engine
        if (string.Equals(sort, "oldest", StringComparison.OrdinalIgnoreCase))
        {
            postsQuery = postsQuery.OrderBy(p => p.CreatedAt).ThenBy(p => p.Id);
        }
        else if (string.Equals(sort, "likes", StringComparison.OrdinalIgnoreCase) || string.Equals(sort, "popular", StringComparison.OrdinalIgnoreCase))
        {
            postsQuery = postsQuery.OrderByDescending(p => p.LikeCount).ThenByDescending(p => p.CreatedAt);
        }
        else
        {
            postsQuery = postsQuery.OrderByDescending(p => p.CreatedAt).ThenByDescending(p => p.Id);
        }

        pageSize = Math.Clamp(pageSize, 1, 50);
        var posts = await postsQuery.Take(pageSize).ToListAsync(cancellationToken);

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
