using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record AdminReviewSponsorshipRequest(bool Approved, string? Notes);

public static class AdminReviewSponsorship
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long adminId,
        AdminReviewSponsorshipRequest request,
        CancellationToken ct)
    {
        var post = await db.Posts
            .Include(p => p.SponsorshipDetails)
            .FirstOrDefaultAsync(p => p.Id == postId && p.Type == PostType.SponsorshipRequest && !p.IsDeleted, ct);

        if (post == null || post.Status != PostStatus.PendingApproval)
            throw new Exception("Post not found or not pending approval");

        if (request.Approved)
        {
            post.Status = PostStatus.Active;
        }
        else
        {
            post.Status = PostStatus.Rejected;
            if (post.SponsorshipDetails != null)
            {
                post.SponsorshipDetails.AdminRejectionNotes = request.Notes;
            }
        }

        await db.SaveChangesAsync(ct);
        return true;
    }
}
