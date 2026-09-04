using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class ConfirmTransportDelivery
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid taskId,
        long requesterId,
        CancellationToken ct)
    {
        var task = await db.TransportTasks.Include(t => t.TransportPost).FirstOrDefaultAsync(t => t.Id == taskId, ct);
        if (task == null || task.RequesterId != requesterId)
            throw new UnauthorizedAccessException("Only the requester can confirm delivery");

        if (task.Status != TransportTaskStatus.Delivered)
            throw new Exception("Task is not in Delivered state");

        task.Status = TransportTaskStatus.Completed;
        task.CompletedAt = DateTimeOffset.UtcNow;

        if (task.TransportPost != null)
        {
            task.TransportPost.Status = PostStatus.Completed;
        }

        await db.SaveChangesAsync(ct);
        return true;
    }
}
