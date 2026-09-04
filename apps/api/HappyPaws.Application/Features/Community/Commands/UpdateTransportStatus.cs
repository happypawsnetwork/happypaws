using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record UpdateTransportStatusRequest(string NewStatus);

public static class UpdateTransportStatus
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid taskId,
        UpdateTransportStatusRequest request,
        long transporterId,
        CancellationToken ct)
    {
        var task = await db.TransportTasks.FirstOrDefaultAsync(t => t.Id == taskId, ct);
        if (task == null || task.TransporterId != transporterId)
            throw new UnauthorizedAccessException("Only the assigned transporter can update status");

        if (!Enum.TryParse<TransportTaskStatus>(request.NewStatus, true, out var newStatus))
            throw new ArgumentException("Invalid status");

        bool isValidTransition = (task.Status == TransportTaskStatus.Accepted && newStatus == TransportTaskStatus.PickedUp) ||
                                 (task.Status == TransportTaskStatus.PickedUp && newStatus == TransportTaskStatus.InTransit) ||
                                 (task.Status == TransportTaskStatus.InTransit && newStatus == TransportTaskStatus.Delivered);

        if (!isValidTransition)
            throw new Exception($"Invalid state transition from {task.Status} to {newStatus}");

        task.Status = newStatus;
        await db.SaveChangesAsync(ct);
        return true;
    }
}
