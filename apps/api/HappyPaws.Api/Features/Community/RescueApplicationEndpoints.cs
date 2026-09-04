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

public sealed class RescueApplicationEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/community").RequireAuthorization();

        group.MapGet("/posts/{postId:guid}/rescue-applications", async (
            Guid postId,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetRescueApplicants.HandleAsync(db, postId, userId, ct);
            return Results.Ok(result);
        }).WithName("GetRescueApplicants").WithSummary("Get applicants");

        group.MapGet("/my-rescues", async (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetMyRescues.HandleAsync(db, userId, ct);
            return Results.Ok(result);
        }).WithName("GetMyRescues").WithSummary("My rescues");

        group.MapPost("/posts/{postId:guid}/rescue-applications", async (
            Guid postId,
            [FromBody] SubmitRescueApplicationRequest request,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var id = await SubmitRescueApplication.HandleAsync(db, postId, userId, request, ct);
            return Results.Ok(new { id });
        }).WithName("SubmitRescueApplication").WithSummary("Apply to rescue");

        group.MapPost("/posts/{postId:guid}/rescue-applications/{applicationId:guid}/review", async (
            Guid postId,
            Guid applicationId,
            [FromBody] ReviewRescueApplicationRequest request,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await ReviewRescueApplication.HandleAsync(db, postId, applicationId, userId, request, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("ReviewRescueApplication").WithSummary("Review application");

        group.MapPost("/posts/{postId:guid}/rescue-applications/{applicationId:guid}/admin-override", async (
            Guid postId,
            Guid applicationId,
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var success = await AdminOverrideRescue.HandleAsync(db, postId, applicationId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).RequireAuthorization(p => p.RequireRole("Administrator")).WithName("AdminOverrideRescue").WithSummary("Admin override rescue");
    }
}
