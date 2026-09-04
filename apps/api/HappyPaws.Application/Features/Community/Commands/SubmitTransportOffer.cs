using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record SubmitTransportOfferRequest(string Message, DateTimeOffset ProposedPickupStart, DateTimeOffset ProposedPickupEnd);

public static class SubmitTransportOffer
{
    public static async Task<Guid> HandleAsync(
        IApplicationDbContext db,
        Guid taskId,
        SubmitTransportOfferRequest request,
        long transporterId,
        CancellationToken ct)
    {
        var task = await db.TransportTasks.FirstOrDefaultAsync(t => t.Id == taskId, ct);
        if (task == null || task.Status != TransportTaskStatus.Open)
            throw new Exception("Task is not open for offers");

        if (task.RequesterId == transporterId)
            throw new Exception("You cannot submit an offer for your own request");

        var existing = await db.TransportOffers.FirstOrDefaultAsync(o => o.TransportTaskId == taskId && o.TransporterId == transporterId && o.Status != TransportOfferStatus.Rejected, ct);
        if (existing != null)
            throw new Exception("You already have an active offer for this task");

        var offer = new TransportOffer
        {
            Id = Guid.NewGuid(),
            TransportTaskId = taskId,
            TransporterId = transporterId,
            Message = request.Message,
            ProposedPickupStart = request.ProposedPickupStart,
            ProposedPickupEnd = request.ProposedPickupEnd,
            Status = TransportOfferStatus.Pending
        };

        db.TransportOffers.Add(offer);
        await db.SaveChangesAsync(ct);
        return offer.Id;
    }
}
