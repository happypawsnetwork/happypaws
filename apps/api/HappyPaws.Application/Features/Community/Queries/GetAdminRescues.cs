using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record AdminRescueSummary(
    Guid? ApplicationId,
    string? AnimalName,
    string? AnimalSpecies,
    string? AssignedRescuerName,
    string? AssignedRescuerRole,
    bool HasVehicle,
    DateTimeOffset? DateApproved
);

public sealed record AdminRescueCaseResponse(
    Guid Id,
    string Title,
    string Status,
    string? AnimalName,
    string? AnimalSpecies,
    string? UrgencyLevel,
    string? AiTriageReason,
    bool IsUrgencyManuallyOverridden,
    string AuthorName,
    string? AuthorEmail,
    long AuthorId,
    DateTimeOffset CreatedAt,
    AdminRescueSummary Summary
);

public static class GetAdminRescues
{
    public static async Task<IReadOnlyList<AdminRescueCaseResponse>> HandleAsync(
        IApplicationDbContext db,
        CancellationToken ct)
    {
        var posts = await db.Posts.AsNoTracking()
            .Include(p => p.Author)
            .Where(p => p.Type == PostType.RescueAlert && p.Status == PostStatus.Fostered && !p.IsDeleted)
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);

        var postIds = posts.Select(p => p.Id).ToList();

        var applications = await db.RescueApplications.AsNoTracking()
            .Include(a => a.Applicant)
            .Where(a => postIds.Contains(a.RescuePostId) && a.Status == RescueApplicationStatus.Approved)
            .ToListAsync(ct);

        var appDict = applications.GroupBy(a => a.RescuePostId)
            .ToDictionary(g => g.Key, g => g.FirstOrDefault());

        return posts.Select(p =>
        {
            appDict.TryGetValue(p.Id, out var app);

            var summary = new AdminRescueSummary(
                app?.Id ?? p.AssignedApplicationId,
                p.AnimalName ?? "Unknown",
                p.AnimalSpecies ?? "Unknown",
                app != null ? $"{app.Applicant.FirstName} {app.Applicant.LastName}".Trim() : "Assigned",
                app != null ? app.ApplicantRole.ToString() : "Foster",
                app?.HasVehicle ?? false,
                app?.PosterReviewedAt ?? app?.AdminReviewedAt ?? p.UpdatedAt
            );

            return new AdminRescueCaseResponse(
                p.Id,
                p.Title,
                p.Status.ToString(),
                p.AnimalName,
                p.AnimalSpecies,
                p.UrgencyLevel?.ToString(),
                p.AiTriageReason,
                p.IsUrgencyManuallyOverridden,
                $"{p.Author.FirstName} {p.Author.LastName}".Trim(),
                p.Author.Email,
                p.AuthorId,
                p.CreatedAt,
                summary
            );
        }).ToList();
    }
}
