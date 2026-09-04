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

public static class GetAdminSponsorships
{
    public static async Task<IReadOnlyList<PostDetailResponse>> HandleAsync(
        IApplicationDbContext db,
        string? status,
        CancellationToken ct)
    {
        var query = db.Posts.AsNoTracking()
            .Include(p => p.Author)
            .Include(p => p.Media)
            .Include(p => p.ParentPost)
            .Include(p => p.SponsorshipDetails)
            .Where(p => p.Type == PostType.SponsorshipRequest && !p.IsDeleted);

        if (!string.IsNullOrEmpty(status) && Enum.TryParse<PostStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(p => p.Status == parsedStatus);
        }

        var posts = await query
            .OrderBy(p => p.Status == PostStatus.PendingApproval ? 0 : 1)
            .ThenByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        return posts.Select(p => new PostDetailResponse(
            p.Id,
            p.Type.ToString(),
            p.Status.ToString(),
            p.Title,
            p.Body,
            p.LikeCount,
            false, // isLiked By current user not relevant for admin list usually, but defaulting to false
            p.Author.FirstName + " " + p.Author.LastName,
            p.Author.AvatarUrl,
            p.Author.Tagline,
            p.AuthorId,
            p.LocationLabel,
            p.LocationPoint?.Y,
            p.LocationPoint?.X,
            p.AnimalSpecies,
            p.AnimalName,
            p.AnimalDescription,
            p.Media.OrderBy(m => m.SortOrder).Select(m => new PostMediaResponse(m.Id, m.CdnUrl, m.MimeType, m.SortOrder)).ToList(),
            p.ParentPostId,
            p.ParentPost?.Title,
            null,
            null,
            p.SponsorshipDetails != null ? new SponsorshipDetailsResponse(p.SponsorshipDetails.GoalDescription, p.SponsorshipDetails.EstimatedAmountLkr, p.SponsorshipDetails.AdminRejectionNotes, p.SponsorshipDetails.FundedAt, 0) : null,
            p.CreatedAt,
            p.UrgencyLevel?.ToString(),
            p.AiTriageReason,
            p.IsUrgencyManuallyOverridden
        )).ToList();
    }
}
