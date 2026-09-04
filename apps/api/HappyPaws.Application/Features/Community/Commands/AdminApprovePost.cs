using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class AdminApprovePost
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);

        if (post == null || post.Status != PostStatus.PendingApproval)
        {
            return false;
        }

        post.Status = PostStatus.Active;
        await db.SaveChangesAsync(ct);
        return true;
    }
}
