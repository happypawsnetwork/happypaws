using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class MarkSponsorshipFunded
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long authorId,
        CancellationToken ct)
    {
        var post = await db.Posts
            .Include(p => p.SponsorshipDetails)
            .FirstOrDefaultAsync(p => p.Id == postId && p.Type == PostType.SponsorshipRequest && !p.IsDeleted, ct);

        if (post == null || post.AuthorId != authorId)
            throw new UnauthorizedAccessException("Not authorized to mark as funded");

        if (post.Status != PostStatus.Active)
            throw new Exception("Sponsorship is not active");

        post.Status = PostStatus.Funded;
        if (post.SponsorshipDetails != null)
        {
            post.SponsorshipDetails.FundedAt = DateTimeOffset.UtcNow;
        }

        await db.SaveChangesAsync(ct);
        return true;
    }
}
