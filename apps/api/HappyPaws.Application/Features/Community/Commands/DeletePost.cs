using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class DeletePost
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long currentUserId,
        bool isAdmin,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);
        if (post == null)
            return false;

        if (post.AuthorId != currentUserId && !isAdmin)
            throw new UnauthorizedAccessException("Cannot delete another user's post");

        post.IsDeleted = true;
        await db.SaveChangesAsync(ct);
        return true;
    }
}
