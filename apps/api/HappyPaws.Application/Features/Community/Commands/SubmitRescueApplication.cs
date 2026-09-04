using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record SubmitRescueApplicationRequest(string? Message, string? ExperienceSummary, bool HasVehicle);

public static class SubmitRescueApplication
{
    public static async Task<Guid> HandleAsync(
        IApplicationDbContext db,
        Guid postId,
        long applicantId,
        SubmitRescueApplicationRequest request,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);
        if (post == null || post.Type != PostType.RescueAlert || post.Status != PostStatus.Active)
            throw new Exception("Invalid or inactive rescue post");

        var existing = await db.RescueApplications.FirstOrDefaultAsync(a =>
            a.RescuePostId == postId &&
            a.ApplicantId == applicantId &&
            a.Status != RescueApplicationStatus.Rejected, ct);

        if (existing != null)
            throw new Exception("You already have an active application for this rescue");

        var application = new RescueApplication
        {
            Id = Guid.NewGuid(),
            RescuePostId = postId,
            ApplicantId = applicantId,
            Status = RescueApplicationStatus.Pending,
            Message = request.Message,
            ExperienceSummary = request.ExperienceSummary,
            HasVehicle = request.HasVehicle,
            CreatedAt = DateTimeOffset.UtcNow
        };

        db.RescueApplications.Add(application);
        await db.SaveChangesAsync(ct);

        return application.Id;
    }
}
