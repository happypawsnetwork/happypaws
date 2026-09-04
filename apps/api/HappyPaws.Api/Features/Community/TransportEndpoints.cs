using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.Commands;
using HappyPaws.Application.Features.Community.Queries;
using HappyPaws.Application.Interfaces;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Mvc;

using HappyPaws.Api.Extensions;
namespace HappyPaws.Api.Features.Community;

public sealed class TransportEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/community/transport-tasks").RequireAuthorization();

        group.MapGet("/{id:guid}", async (
            Guid id,
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var result = await GetTransportTaskById.HandleAsync(db, id, ct);
            return result != null ? Results.Ok(result) : Results.NotFound();
        }).WithName("GetTransportTaskById").WithSummary("Get transport task");

        group.MapGet("/mine", async (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            string? status,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetMyTransports.HandleAsync(db, userId, status, ct);
            return Results.Ok(result);
        }).WithName("GetMyTransports").WithSummary("Get my transports");

        group.MapGet("/admin", async (
            IApplicationDbContext db,
            string? status,
            CancellationToken ct) =>
        {
            var result = await GetAdminTransports.HandleAsync(db, status, ct);
            return Results.Ok(result);
        }).RequireAuthorization(p => p.RequireRole("Administrator")).WithName("GetAdminTransports").WithSummary("Get admin transports");

        group.MapPost("/", async (
            [FromBody] CreateTransportTaskRequest request,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var id = await CreateTransportTask.HandleAsync(db, request, userId, ct);
            return Results.Ok(new { id });
        }).WithName("CreateTransportTask").WithSummary("Create transport task");

        group.MapPost("/{taskId:guid}/offers", async (
            Guid taskId,
            [FromBody] SubmitTransportOfferRequest request,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var id = await SubmitTransportOffer.HandleAsync(db, taskId, request, userId, ct);
            return Results.Ok(new { id });
        }).WithName("SubmitTransportOffer").WithSummary("Submit transport offer");

        group.MapPost("/{taskId:guid}/offers/{offerId:guid}/accept", async (
            Guid taskId,
            Guid offerId,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await AcceptTransportOffer.HandleAsync(db, taskId, offerId, userId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("AcceptTransportOffer").WithSummary("Accept transport offer");

        group.MapPatch("/{taskId:guid}/status", async (
            Guid taskId,
            [FromBody] UpdateTransportStatusRequest request,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await UpdateTransportStatus.HandleAsync(db, taskId, request, userId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("UpdateTransportStatus").WithSummary("Update transport status");

        group.MapPost("/{taskId:guid}/confirm-delivery", async (
            Guid taskId,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await ConfirmTransportDelivery.HandleAsync(db, taskId, userId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("ConfirmTransportDelivery").WithSummary("Confirm transport delivery");

        group.MapPost("/{taskId:guid}/mark-self-collected", async (
            Guid taskId,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await MarkSelfCollected.HandleAsync(db, taskId, userId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("MarkSelfCollected").WithSummary("Mark self collected");

        group.MapPost("/{taskId:guid}/close-rescue", async (
            Guid taskId,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            // Re-using CloseRescueCase here - we pass taskId but it needs postId.
            // Wait, the spec says TransportEndpoints.cs POST .../close-rescue -> CloseRescueCase.
            // The route says {taskId:guid} but CloseRescueCase needs postId. Let's lookup the task to get parent post id.
            var task = await db.TransportTasks.FindAsync(new object[] { taskId }, ct);
            if (task == null) return Results.NotFound();
            var success = await CloseRescueCase.HandleAsync(db, task.ParentPostId, userId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("CloseRescueTaskCase").WithSummary("Close rescue from transport");
    }
}
