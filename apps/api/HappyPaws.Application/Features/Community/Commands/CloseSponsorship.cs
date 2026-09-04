using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class CloseSponsorship
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long userId,
        bool isAdmin,
        CancellationToken ct)
    {
        var post = await db.Posts
            .FirstOrDefaultAsync(p => p.Id == postId && p.Type == PostType.SponsorshipRequest && !p.IsDeleted, ct);

        if (post == null) return false;

        if (post.AuthorId != userId && !isAdmin)
            throw new UnauthorizedAccessException("Not authorized to close sponsorship");

        post.Status = PostStatus.Cancelled;

        await db.SaveChangesAsync(ct);
        return true;
    }
}
