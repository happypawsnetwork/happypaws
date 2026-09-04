using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record TransportOfferResponse(
    Guid Id,
    long TransporterId,
    string TransporterName,
    string? TransporterAvatarUrl,
    string? Message,
    DateTimeOffset ProposedPickupStart,
    string Status,
    DateTimeOffset CreatedAt
);

public sealed record TransportTaskResponse(
    Guid Id,
    Guid ParentPostId,
    Guid? TransportPostId,
    long RequesterId,
    string RequesterName,
    string? RequesterAvatarUrl,
    long? TransporterId,
    string? TransporterName,
    string PickupAddress,
    double PickupLat,
    double PickupLon,
    string DropoffAddress,
    double DropoffLat,
    double DropoffLon,
    DateTimeOffset? PickupWindowStart,
    DateTimeOffset? PickupWindowEnd,
    bool IsSelfCollection,
    string Status,
    string? Notes,
    DateTimeOffset CreatedAt,
    IReadOnlyList<TransportOfferResponse> Offers
);

public static class GetTransportTaskById
{
    public static async Task<TransportTaskResponse?> HandleAsync(
        IApplicationDbContext db,
        Guid taskId,
        CancellationToken ct)
    {
        var task = await db.TransportTasks.AsNoTracking()
            .Include(t => t.Requester)
            .Include(t => t.Transporter)
            .Include(t => t.Offers).ThenInclude(o => o.Transporter)
            .FirstOrDefaultAsync(t => t.Id == taskId, ct);

        if (task == null) return null;

        var offers = task.Offers.Select(o => new TransportOfferResponse(
            o.Id,
            o.TransporterId,
            o.Transporter.FirstName + " " + o.Transporter.LastName,
            o.Transporter.AvatarUrl,
            o.Message,
            o.ProposedPickupStart,
            o.Status.ToString(),
            o.CreatedAt
        )).ToList();

        return new TransportTaskResponse(
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
            offers
        );
    }
}
