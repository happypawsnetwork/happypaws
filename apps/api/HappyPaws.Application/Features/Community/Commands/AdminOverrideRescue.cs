using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class AdminOverrideRescue
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        Guid applicationId,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);
        if (post == null) return false;

        var app = await db.RescueApplications.FirstOrDefaultAsync(a => a.Id == applicationId && a.RescuePostId == postId, ct);
        if (app == null) return false;

        app.Status = RescueApplicationStatus.AdminOverridden;

        post.Status = PostStatus.Active;
        if (post.AssignedApplicationId == applicationId)
        {
            post.AssignedApplicationId = null;
        }

        await db.SaveChangesAsync(ct);
        return true;
    }
}
