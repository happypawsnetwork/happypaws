using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class CloseRescueCase
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long userId,
        CancellationToken ct)
    {
        var post = await db.Posts
            .Include(p => p.AssignedApplication)
            .FirstOrDefaultAsync(p => p.Id == postId && p.Type == PostType.RescueAlert && !p.IsDeleted, ct);

        if (post == null) return false;

        bool isAuthor = post.AuthorId == userId;
        bool isAssigned = post.AssignedApplication != null && post.AssignedApplication.ApplicantId == userId;

        if (!isAuthor && !isAssigned)
            throw new UnauthorizedAccessException("Not authorized to close this case");

        post.Status = PostStatus.Completed;
        await db.SaveChangesAsync(ct);
        return true;
    }
}
