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

public sealed class SponsorshipEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/community/sponsorships").RequireAuthorization();

        group.MapGet("/admin", async (
            IApplicationDbContext db,
            string? status,
            CancellationToken ct) =>
        {
            var result = await GetAdminSponsorships.HandleAsync(db, status, ct);
            return Results.Ok(result);
        }).RequireAuthorization(p => p.RequireRole("Administrator")).WithName("GetAdminSponsorships").WithSummary("Get admin sponsorships");

        group.MapGet("/{id:guid}/proof-documents", async (
            Guid id,
            IApplicationDbContext db,
            IStorageService storage,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var isAdmin = user.IsInRole(HappyPaws.Domain.Enums.RoleName.Administrator.ToString());
            var result = await GetSponsorshipProofDocuments.HandleAsync(db, storage, id, userId, isAdmin, ct);
            return Results.Ok(result);
        }).WithName("GetSponsorshipProofDocuments").WithSummary("Get proof documents");

        group.MapPost("/", async Task<IResult> (
            [FromForm] HappyPaws.Application.Features.Community.Commands.CreatePostRequest request,
            IFormFileCollection? photos,
            IFormFileCollection? proofs,
            IApplicationDbContext db,
            IStorageService storage,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var photoData = photos?.Select(f => new FileUploadData(f.OpenReadStream(), f.FileName, f.ContentType, f.Length)).ToList();
            var proofData = proofs?.Select(f => new FileUploadData(f.OpenReadStream(), f.FileName, f.ContentType, f.Length)).ToList();
            var id = await CreatePost.HandleAsync(db, storage, request, photoData, proofData, userId, ct);
            return Results.Ok(new { id });
        }).WithName("CreateSponsorshipPost").WithSummary("Create sponsorship post").DisableAntiforgery();

        group.MapPost("/{id:guid}/admin-review", async (
            Guid id,
            [FromBody] AdminReviewSponsorshipRequest request,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await AdminReviewSponsorship.HandleAsync(db, id, userId, request, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).RequireAuthorization(p => p.RequireRole("Administrator")).WithName("AdminReviewSponsorship").WithSummary("Admin review sponsorship");

        group.MapPost("/{id:guid}/mark-funded", async (
            Guid id,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var success = await MarkSponsorshipFunded.HandleAsync(db, id, userId, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("MarkSponsorshipFunded").WithSummary("Mark sponsorship funded");

        group.MapPost("/{id:guid}/close", async (
            Guid id,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var isAdmin = user.IsInRole(HappyPaws.Domain.Enums.RoleName.Administrator.ToString());
            var success = await CloseSponsorship.HandleAsync(db, id, userId, isAdmin, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("CloseSponsorship").WithSummary("Close sponsorship");
    }
}
