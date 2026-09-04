using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class AdminUpdateRescueUrgency
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        string urgencyLevel,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);

        if (post == null || post.Type != PostType.RescueAlert)
        {
            return false;
        }

        if (Enum.TryParse<RescueUrgencyLevel>(urgencyLevel, true, out var level))
        {
            post.UrgencyLevel = level;
            post.IsUrgencyManuallyOverridden = true;

            await db.SaveChangesAsync(ct);
            return true;
        }

        return false;
    }
}
