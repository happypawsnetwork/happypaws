using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public static class GetMyTransports
{
    public static async Task<IReadOnlyList<TransportTaskResponse>> HandleAsync(
        IApplicationDbContext db,
        long transporterId,
        string? status,
        CancellationToken ct)
    {
        var query = db.TransportTasks.AsNoTracking()
            .Include(t => t.Requester)
            .Include(t => t.Transporter)
            .Include(t => t.Offers).ThenInclude(o => o.Transporter)
            .Where(t => t.TransporterId == transporterId);

        if (!string.IsNullOrEmpty(status) && Enum.TryParse<TransportTaskStatus>(status, true, out var parsedStatus))
        {
            query = query.Where(t => t.Status == parsedStatus);
        }

        var tasks = await query
            .OrderBy(t => t.Status == TransportTaskStatus.Completed ? 1 : 0)
            .ThenByDescending(t => t.CreatedAt)
            .ToListAsync(ct);

        return tasks.Select(task => new TransportTaskResponse(
            task.Id,
            task.ParentPostId,
            task.TransportPostId,
            task.RequesterId,
            task.Requester.FirstName + " " + task.Requester.LastName,
            task.Requester.AvatarUrl,
            task.TransporterId,
            task.Transporter != null ? task.Transporter.FirstName + " " + task.Transporter.LastName : null,
            task.PickupAddress,
            task.PickupPoint.Y,
            task.PickupPoint.X,
            task.DropoffAddress,
            task.DropoffPoint.Y,
            task.DropoffPoint.X,
            task.PickupWindowStart,
            task.PickupWindowEnd,
            task.IsSelfCollection,
            task.Status.ToString(),
            task.Notes,
            task.CreatedAt,
            task.Offers.Select(o => new TransportOfferResponse(
                o.Id,
                o.TransporterId,
                o.Transporter.FirstName + " " + o.Transporter.LastName,
                o.Transporter.AvatarUrl,
                o.Message,
                o.ProposedPickupStart,
                o.Status.ToString(),
                o.CreatedAt
            )).ToList()
        )).ToList();
    }
}
