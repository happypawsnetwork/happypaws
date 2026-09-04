using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Api.Extensions;
using HappyPaws.Application.Features.Community.Commands;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;

namespace HappyPaws.Api.Features.Admin;

public sealed class AdminRescueEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/admin/rescues")
            .RequireAuthorization(policy => policy.RequireRole(RoleName.Administrator.ToString()));

        group.MapGet("/", async (
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var result = await HappyPaws.Application.Features.Community.Queries.GetAdminRescues.HandleAsync(db, ct);
            return TypedResults.Ok(result);
        })
        .WithName("GetAdminRescues")
        .WithSummary("Get active fostered rescue cases for admin monitoring and override");

        group.MapGet("/map", async (
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var result = await HappyPaws.Application.Features.Community.Queries.GetAdminRescueMapCases.HandleAsync(db, ct);
            return TypedResults.Ok(result);
        })
        .WithName("GetAdminRescueMapCases")
        .WithSummary("Get active rescue cases with coordinates for map visualization");

        group.MapPatch("/{postId:guid}/urgency", async (
            Guid postId,
            [FromBody] AdminUpdateUrgencyRequest request,
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var success = await AdminUpdateRescueUrgency.HandleAsync(
                db,
                postId,
                request.UrgencyLevel,
                ct);

            return success ? Results.Ok() : Results.NotFound();
        })
        .WithName("AdminUpdateRescueUrgency")
        .WithSummary("Admin override rescue urgency");
    }
}

public sealed record AdminUpdateUrgencyRequest(string UrgencyLevel);
