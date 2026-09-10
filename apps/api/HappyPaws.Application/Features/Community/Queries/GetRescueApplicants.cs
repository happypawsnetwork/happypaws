using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record RescueApplicantResponse(
    Guid Id,
    long ApplicantId,
    string ApplicantName,
    string? ApplicantAvatarUrl,
    string? Message,
    string ExperienceSummary,
    bool HasVehicle,
    string Status,
    DateTimeOffset CreatedAt,
    bool IsVerified = false
);

public static class GetRescueApplicants
{
    public static async Task<IReadOnlyList<RescueApplicantResponse>> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long requesterId,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);
        if (post == null || post.AuthorId != requesterId)
            throw new UnauthorizedAccessException("Not authorized to view applicants for this post");

        var apps = await db.RescueApplications
            .Include(a => a.Applicant)
                .ThenInclude(u => u.Roles)
            .Where(a => a.RescuePostId == postId)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(ct);

        return apps.Select(a => new RescueApplicantResponse(
            a.Id,
            a.ApplicantId,
            a.Applicant.FirstName + " " + a.Applicant.LastName,
            a.Applicant.AvatarUrl,
            a.Message,
            a.ExperienceSummary ?? string.Empty,
            a.HasVehicle,
            a.Status.ToString(),
            a.CreatedAt,
            a.Applicant.Roles.Any(r => r.IsVerified)
        )).ToList();
    }
}
