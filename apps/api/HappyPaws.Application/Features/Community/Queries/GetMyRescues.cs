using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record MyRescueResponse(
    Guid ApplicationId,
    Guid RescuePostId,
    string PostTitle,
    string? AnimalSpecies,
    string? AnimalName,
    string Status,
    DateTimeOffset CreatedAt
);

public static class GetMyRescues
{
    public static async Task<IReadOnlyList<MyRescueResponse>> HandleAsync(
        IApplicationDbContext db,
        long userId,
        CancellationToken ct)
    {
        var apps = await db.RescueApplications
            .Include(a => a.RescuePost)
            .Where(a => a.ApplicantId == userId && a.Status == RescueApplicationStatus.Approved)
            .OrderByDescending(a => a.CreatedAt)
            .ToListAsync(ct);

        return apps.Select(a => new MyRescueResponse(
            a.Id,
            a.RescuePostId,
            a.RescuePost.Title,
            a.RescuePost.AnimalSpecies,
            a.RescuePost.AnimalName,
            a.Status.ToString(),
            a.CreatedAt
        )).ToList();
    }
}
