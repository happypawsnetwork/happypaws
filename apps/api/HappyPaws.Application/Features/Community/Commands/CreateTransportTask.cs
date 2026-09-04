using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record CreateTransportTaskRequest(
    Guid ParentPostId,
    string PickupAddress,
    double PickupLat,
    double PickupLon,
    string DropoffAddress,
    double DropoffLat,
    double DropoffLon,
    DateTimeOffset? PickupWindowStart,
    DateTimeOffset? PickupWindowEnd,
    bool IsSelfCollection,
    string? Notes
);

public static class CreateTransportTask
{
    public static async Task<Guid> HandleAsync(
        IApplicationDbContext db,
        CreateTransportTaskRequest request,
        long requesterId,
        CancellationToken ct)
    {
        var parentPost = await db.Posts.FirstOrDefaultAsync(p => p.Id == request.ParentPostId, ct);
        if (parentPost == null) throw new Exception("Parent post not found");

        var task = new TransportTask
        {
            Id = Guid.NewGuid(),
            ParentPostId = request.ParentPostId,
            RequesterId = requesterId,
            PickupAddress = request.PickupAddress,
            PickupPoint = new Point(request.PickupLon, request.PickupLat) { SRID = 4326 },
            DropoffAddress = request.DropoffAddress,
            DropoffPoint = new Point(request.DropoffLon, request.DropoffLat) { SRID = 4326 },
            PickupWindowStart = request.PickupWindowStart,
            PickupWindowEnd = request.PickupWindowEnd,
            IsSelfCollection = request.IsSelfCollection,
            Status = request.IsSelfCollection ? TransportTaskStatus.Accepted : TransportTaskStatus.Open,
            Notes = request.Notes
        };

        db.TransportTasks.Add(task);

        if (!request.IsSelfCollection)
        {
            var transportPost = new Post
            {
                Id = Guid.NewGuid(),
                AuthorId = requesterId,
                Type = PostType.TransportRequest,
                Status = PostStatus.Active,
                Title = $"Transport needed: {request.PickupAddress} to {request.DropoffAddress}",
                Body = request.Notes ?? "Transport needed for an animal.",
                ParentPostId = request.ParentPostId,
                LocationLabel = request.PickupAddress,
                LocationPoint = task.PickupPoint,
                AnimalSpecies = parentPost.AnimalSpecies,
                AnimalName = parentPost.AnimalName
            };
            db.Posts.Add(transportPost);
            task.TransportPostId = transportPost.Id;
        }

        await db.SaveChangesAsync(ct);
        return task.Id;
    }
}
