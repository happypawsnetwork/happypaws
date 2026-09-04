using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Features.Community.Queries;
using HappyPaws.Application.Features.Community.Commands;
using HappyPaws.Application.Interfaces;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;
using Microsoft.AspNetCore.Mvc;

using HappyPaws.Api.Extensions;
namespace HappyPaws.Api.Features.Community;

public sealed class PostEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/community/posts").RequireAuthorization();

        group.MapGet("/", async Task<Ok<System.Collections.Generic.IReadOnlyList<PostSummaryResponse>>> (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            string? type,
            string? status = null,
            string sort = "newest",
            Guid? cursorId = null,
            DateTimeOffset? cursorDate = null,
            int pageSize = 10,
            CancellationToken ct = default) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetCommunityFeed.HandleAsync(db, type, status, sort, cursorId, cursorDate, userId, pageSize, ct);
            return TypedResults.Ok(result);
        }).WithName("GetCommunityFeed").WithSummary("Feed").WithDescription("Get feed");

        group.MapGet("/nearby", async Task<Ok<System.Collections.Generic.IReadOnlyList<PostSummaryResponse>>> (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            double lat,
            double lon,
            double radiusKm = 10,
            Guid? cursorId = null,
            DateTimeOffset? cursorDate = null,
            int pageSize = 10,
            CancellationToken ct = default) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetNearbyFeed.HandleAsync(db, lat, lon, radiusKm, userId, cursorId, cursorDate, pageSize, ct);
            return TypedResults.Ok(result);
        }).WithName("GetNearbyFeed").WithSummary("Nearby").WithDescription("Nearby feed");

        group.MapGet("/map-bounds", async Task<Ok<System.Collections.Generic.IReadOnlyList<PostSummaryResponse>>> (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            double swLat,
            double swLon,
            double neLat,
            double neLon,
            string? type,
            CancellationToken ct = default) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetMapBoundsFeed.HandleAsync(db, swLat, swLon, neLat, neLon, type, userId, ct);
            return TypedResults.Ok(result);
        }).WithName("GetMapBoundsFeed").WithSummary("Map Bounds").WithDescription("Get posts within geographical bounds");

        group.MapGet("/{id:guid}", async Task<Results<Ok<PostDetailResponse>, NotFound>> (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            Guid id,
            CancellationToken ct = default) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetPostById.HandleAsync(db, id, userId, ct);
            return result != null ? TypedResults.Ok(result) : TypedResults.NotFound();
        }).WithName("GetPostById").WithSummary("Get post").WithDescription("Get post details");

        group.MapGet("/me", async Task<Ok<System.Collections.Generic.IReadOnlyList<PostSummaryResponse>>> (
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct = default) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var result = await GetMyPosts.HandleAsync(db, userId, ct);
            return TypedResults.Ok(result);
        }).WithName("GetMyPosts").WithSummary("My posts").WithDescription("Get my posts");

        group.MapPost("/", async Task<IResult> (
            HttpContext httpContext,
            IApplicationDbContext db,
            IStorageService storage,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            HappyPaws.Application.Features.Community.Commands.CreatePostRequest request;
            System.Collections.Generic.List<FileUploadData>? photoData = null;
            System.Collections.Generic.List<FileUploadData>? proofData = null;

            if (httpContext.Request.HasJsonContentType())
            {
                var options = new System.Text.Json.JsonSerializerOptions { PropertyNameCaseInsensitive = true };
                var jsonBody = await httpContext.Request.ReadFromJsonAsync<HappyPaws.Application.Features.Community.Commands.CreatePostRequest>(options, ct);
                if (jsonBody == null)
                {
                    return Results.BadRequest("Invalid request body");
                }
                request = jsonBody;
            }
            else if (httpContext.Request.HasFormContentType)
            {
                var form = await httpContext.Request.ReadFormAsync(ct);
                request = new HappyPaws.Application.Features.Community.Commands.CreatePostRequest
                {
                    Type = form["type"].ToString(),
                    Title = form["title"].ToString(),
                    Body = form["body"].ToString(),
                    ParentPostId = Guid.TryParse(form["parentPostId"], out var parentId) ? parentId : null,
                    Latitude = double.TryParse(form["latitude"], out var lat) || double.TryParse(form["lat"], out lat) ? lat : null,
                    Longitude = double.TryParse(form["longitude"], out var lon) || double.TryParse(form["lon"], out lon) ? lon : null,
                    LocationLabel = form["locationLabel"].ToString(),
                    AnimalSpecies = form["animalSpecies"].ToString().Length > 0 ? form["animalSpecies"].ToString() : form["species"].ToString(),
                    AnimalName = form["animalName"].ToString(),
                    AnimalDescription = form["animalDescription"].ToString(),
                    UrgencyLevel = form["urgencyLevel"].ToString(),
                    AiTriageReason = form["aiTriageReason"].ToString(),
                    VetReasonForVisit = form["vetReasonForVisit"].ToString(),
                    VetClinicName = form["clinicName"].ToString().Length > 0 ? form["clinicName"].ToString() : form["vetClinicName"].ToString(),
                    VetAppointmentDate = DateTimeOffset.TryParse(form["vetAppointmentDate"].ToString().Length > 0 ? form["vetAppointmentDate"] : form["vetVisitDate"], out var appDate) ? appDate : null,
                    VetTransportNeeded = bool.TryParse(form["vetTransportNeeded"].ToString().Length > 0 ? form["vetTransportNeeded"] : form["needsTransport"], out var trans) && trans,
                    SponsorGoalDescription = form["sponsorGoalDescription"].ToString(),
                    SponsorEstimatedAmountLkr = decimal.TryParse(form["sponsorEstimatedAmountLkr"].ToString().Length > 0 ? form["sponsorEstimatedAmountLkr"] : form["sponsorAmount"], out var spAmount) ? spAmount : null,
                    LifestyleHomeSize = form["lifestyleHomeSize"].ToString(),
                    LifestyleRequiresEnclosedYard = bool.TryParse(form["lifestyleRequiresEnclosedYard"], out var reqYard) ? reqYard : null,
                    LifestyleGoodWithChildren = bool.TryParse(form["lifestyleGoodWithChildren"], out var goodWithChild) ? goodWithChild : null,
                    LifestyleActivityTempo = form["lifestyleActivityTempo"].ToString(),
                    LifestyleGoodWithPets = form["lifestyleGoodWithPets"].ToString().Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries).ToList()
                };

                photoData = form.Files.Where(f => f.Name == "photos" || f.Name == "photo").Select(f => new FileUploadData(f.OpenReadStream(), f.FileName, f.ContentType, f.Length)).ToList();
                proofData = form.Files.Where(f => f.Name == "proofs" || f.Name == "proof").Select(f => new FileUploadData(f.OpenReadStream(), f.FileName, f.ContentType, f.Length)).ToList();
            }
            else
            {
                return Results.BadRequest("Unsupported content type");
            }

            var id = await CreatePost.HandleAsync(db, storage, request, photoData, proofData, userId, ct);
            return Results.Ok(new { id });
        }).WithName("CreatePost").WithSummary("Create post").DisableAntiforgery();

        group.MapDelete("/{id:guid}", async Task<IResult> (
            Guid id,
            IApplicationDbContext db,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var isAdmin = user.IsInRole(HappyPaws.Domain.Enums.RoleName.Administrator.ToString());
            var success = await DeletePost.HandleAsync(db, id, userId, isAdmin, ct);
            return success ? Results.Ok() : Results.NotFound();
        }).WithName("DeletePost").WithSummary("Delete post");

        group.MapPost("/{id:guid}/like", async Task<IResult> (
            Guid id,
            IApplicationDbContext db,
            IReputationService reputationService,
            ClaimsPrincipal user,
            CancellationToken ct) =>
        {
            var userId = long.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var (isLiked, likeCount) = await ToggleLike.HandleAsync(db, reputationService, id, userId, ct);
            return Results.Ok(new { isLiked, likeCount });
        }).WithName("ToggleLike").WithSummary("Toggle like");
    }
}
