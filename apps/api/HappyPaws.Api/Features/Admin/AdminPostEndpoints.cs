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
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Api.Features.Admin;

public sealed class AdminPostEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/admin/posts")
            .RequireAuthorization(policy => policy.RequireRole(RoleName.Administrator.ToString()));

        group.MapGet("/", async (
            IAdminPostQueryService queryService,
            string? type,
            string? status,
            string? search,
            bool? includeDeleted,
            CancellationToken ct = default) =>
        {
            var result = await HappyPaws.Application.Features.Community.Queries.GetAdminPosts.HandleAsync(
                queryService, type, status, search, includeDeleted ?? false, ct);
            return TypedResults.Ok(result);
        })
        .WithName("GetAdminPosts")
        .WithSummary("Get admin community posts feed across all types");

        group.MapPatch("/{postId:guid}/approve", async (
            Guid postId,
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var success = await AdminApprovePost.HandleAsync(db, postId, ct);
            return success ? Results.Ok() : Results.NotFound();
        })
        .WithName("AdminApprovePost")
        .WithSummary("Admin approve a pending post");

        group.MapPost("/{postId:guid}/restore", async Task<Microsoft.AspNetCore.Http.HttpResults.Results<Microsoft.AspNetCore.Http.HttpResults.Ok, Microsoft.AspNetCore.Http.HttpResults.NotFound>> (
            Guid postId,
            IApplicationDbContext db,
            CancellationToken ct) =>
        {
            var post = await db.Posts.IgnoreQueryFilters().FirstOrDefaultAsync(p => p.Id == postId, ct);
            if (post == null) return TypedResults.NotFound();
            post.IsDeleted = false;
            await db.SaveChangesAsync(ct);
            return TypedResults.Ok();
        })
        .WithName("AdminRestorePost")
        .WithSummary("Admin restore a deleted post");

        group.MapDelete("/{postId:guid}/permanent", async Task<Microsoft.AspNetCore.Http.HttpResults.Results<Microsoft.AspNetCore.Http.HttpResults.Ok, Microsoft.AspNetCore.Http.HttpResults.NotFound>> (
            Guid postId,
            IApplicationDbContext db,
            IStorageService storage,
            CancellationToken ct) =>
        {
            var success = await AdminPermanentDeletePost.HandleAsync(db, storage, postId, ct);
            return success ? TypedResults.Ok() : TypedResults.NotFound();
        })
        .WithName("AdminPermanentDeletePost")
        .WithSummary("Admin permanently delete a post and associated media")
        .WithDescription("Permanently removes a post, its media files from storage, likes, and associated details.");
    }
}

