using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class AcceptTransportOffer
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        Guid taskId,
        Guid offerId,
        long requesterId,
        CancellationToken ct)
    {
        var task = await db.TransportTasks.Include(t => t.TransportPost).FirstOrDefaultAsync(t => t.Id == taskId, ct);
        if (task == null || task.RequesterId != requesterId)
            throw new UnauthorizedAccessException("Not authorized to accept offers for this task");

        if (task.Status != TransportTaskStatus.Open)
            throw new Exception("Task is not open");

        var offer = await db.TransportOffers.FirstOrDefaultAsync(o => o.Id == offerId && o.TransportTaskId == taskId, ct);
        if (offer == null || offer.Status != TransportOfferStatus.Pending)
            throw new Exception("Invalid offer");

        offer.Status = TransportOfferStatus.Accepted;

        task.Status = TransportTaskStatus.Accepted;
        task.TransporterId = offer.TransporterId;
        task.PickupWindowStart = offer.ProposedPickupStart;
        task.PickupWindowEnd = offer.ProposedPickupEnd;

        if (task.TransportPost != null)
        {
            task.TransportPost.Status = PostStatus.Assigned;
        }

        await db.TransportOffers
            .Where(o => o.TransportTaskId == taskId && o.Id != offerId && o.Status == TransportOfferStatus.Pending)
            .ExecuteUpdateAsync(s => s
                .SetProperty(o => o.Status, TransportOfferStatus.Rejected), ct);

        await db.SaveChangesAsync(ct);
        return true;
    }
}
