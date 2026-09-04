using HappyPaws.Application.Features.Community.Queries;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Infrastructure.Services;

public sealed class AdminPostQueryService : IAdminPostQueryService
{
    private readonly IApplicationDbContext _db;

    public AdminPostQueryService(IApplicationDbContext db)
    {
        _db = db;
    }

    public async Task<IReadOnlyList<AdminPostResponse>> GetAdminPostsAsync(
        string? type,
        string? status,
        string? search,
        bool includeDeleted,
        CancellationToken ct)
    {
        var query = includeDeleted
            ? _db.Posts.IgnoreQueryFilters().AsNoTracking()
            : _db.Posts.AsNoTracking();

        query = query
            .Include(p => p.Author)
            .Include(p => p.Media)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(type) && !string.Equals(type, "All", StringComparison.OrdinalIgnoreCase))
        {
            if (Enum.TryParse<PostType>(type, true, out var postType))
            {
                query = query.Where(p => p.Type == postType);
            }
        }

        if (!string.IsNullOrWhiteSpace(status) && !string.Equals(status, "All", StringComparison.OrdinalIgnoreCase))
        {
            if (Enum.TryParse<PostStatus>(status, true, out var postStatus))
            {
                query = query.Where(p => p.Status == postStatus);
            }
        }

        if (!string.IsNullOrWhiteSpace(search))
        {
            var s = search.Trim().ToLower();
            query = query.Where(p =>
                p.Title.ToLower().Contains(s) ||
                p.Body.ToLower().Contains(s) ||
                (p.AnimalName != null && p.AnimalName.ToLower().Contains(s)) ||
                (p.Author.FirstName.ToLower() + " " + p.Author.LastName.ToLower()).Contains(s) ||
                p.Author.Email.ToLower().Contains(s));
        }

        query = query.OrderByDescending(p => p.CreatedAt);

        var posts = await query.ToListAsync(ct);

        return posts.Select(p =>
        {
            var orderedMedia = p.Media.OrderBy(m => m.SortOrder).ToList();
            var photoUrls = orderedMedia.Select(m => m.CdnUrl).ToList();

            return new AdminPostResponse(
                p.Id,
                p.Type.ToString(),
                p.Status.ToString(),
                p.Title,
                p.Body,
                p.LikeCount,
                $"{p.Author.FirstName} {p.Author.LastName}".Trim(),
                p.Author.Email,
                p.AuthorId,
                p.Author.AvatarUrl,
                p.LocationLabel,
                p.LocationPoint?.Y,
                p.LocationPoint?.X,
                p.AnimalSpecies,
                p.AnimalName,
                photoUrls.FirstOrDefault(),
                orderedMedia.Count,
                photoUrls,
                p.UrgencyLevel?.ToString(),
                p.AiTriageReason,
                p.IsUrgencyManuallyOverridden,
                p.IsDeleted,
                p.CreatedAt,
                p.UpdatedAt
            );
        }).ToList();
    }
}
