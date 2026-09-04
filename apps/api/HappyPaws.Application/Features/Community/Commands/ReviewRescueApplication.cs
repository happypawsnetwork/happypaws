using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record ReviewRescueApplicationRequest(bool Approved);

public static class ReviewRescueApplication
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        Guid applicationId,
        long reviewerId,
        ReviewRescueApplicationRequest request,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);
        if (post == null || post.AuthorId != reviewerId)
            throw new UnauthorizedAccessException("Only the post author can review applications");

        var app = await db.RescueApplications.FirstOrDefaultAsync(a => a.Id == applicationId && a.RescuePostId == postId, ct);
        if (app == null) return false;

        if (request.Approved)
        {
            app.Status = RescueApplicationStatus.Approved;

            post.Status = PostStatus.Fostered;
            post.AssignedApplicationId = app.Id;

            await db.RescueApplications
                .Where(a => a.RescuePostId == postId && a.Id != applicationId && a.Status == RescueApplicationStatus.Pending)
                .ExecuteUpdateAsync(s => s
                    .SetProperty(a => a.Status, RescueApplicationStatus.Rejected), ct);
        }
        else
        {
            app.Status = RescueApplicationStatus.Rejected;
        }

        await db.SaveChangesAsync(ct);
        return true;
    }
}
