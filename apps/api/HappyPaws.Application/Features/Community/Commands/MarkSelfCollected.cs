using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class MarkSelfCollected
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid taskId,
        long requesterId,
        CancellationToken ct)
    {
        var task = await db.TransportTasks.FirstOrDefaultAsync(t => t.Id == taskId, ct);
        if (task == null || task.RequesterId != requesterId)
            throw new UnauthorizedAccessException("Only the requester can mark as self collected");

        if (!task.IsSelfCollection || task.Status != TransportTaskStatus.Accepted)
            throw new Exception("Invalid task state for self collection");

        task.Status = TransportTaskStatus.Completed;
        task.CompletedAt = DateTimeOffset.UtcNow;

        await db.SaveChangesAsync(ct);
        return true;
    }
}
