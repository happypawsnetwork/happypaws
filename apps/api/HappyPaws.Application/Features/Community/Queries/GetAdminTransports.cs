using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record AdminTransportTaskResponse(
    Guid Id,
    Guid ParentPostId,
    string ParentPostTitle,
    long RequesterId,
    string RequesterDisplayName,
    string? RequesterAvatarUrl,
    long? TransporterId,
    string? TransporterDisplayName,
    string PickupAddress,
    string DropoffAddress,
    DateTimeOffset? PickupWindowStart,
    DateTimeOffset? PickupWindowEnd,
    bool IsSelfCollection,
    string Status,
    string? Notes,
    DateTimeOffset CreatedAt
);

public static class GetAdminTransports
{
    public static async Task<IReadOnlyList<AdminTransportTaskResponse>> HandleAsync(
        IApplicationDbContext db,
        string? status,
        CancellationToken ct)
    {
        var query = db.TransportTasks.AsNoTracking()
            .Include(t => t.ParentPost)
            .Include(t => t.Requester)
            .Include(t => t.Transporter)
            .AsQueryable();

        if (!string.IsNullOrWhiteSpace(status) && !string.Equals(status, "All", StringComparison.OrdinalIgnoreCase))
        {
            // Map "In Progress" or other filter strings to enum
            if (string.Equals(status, "In Progress", StringComparison.OrdinalIgnoreCase))
            {
                query = query.Where(t => t.Status == TransportTaskStatus.InTransit || t.Status == TransportTaskStatus.PickedUp);
            }
            else if (Enum.TryParse<TransportTaskStatus>(status, true, out var parsedStatus))
            {
                query = query.Where(t => t.Status == parsedStatus);
            }
        }

        var tasks = await query
            .OrderBy(t => t.Status == TransportTaskStatus.Completed ? 1 : 0)
            .ThenByDescending(t => t.CreatedAt)
            .ToListAsync(ct);

        return tasks.Select(task => new AdminTransportTaskResponse(
            task.Id,
            task.ParentPostId,
            task.ParentPost != null ? task.ParentPost.Title : "General Transport",
            task.RequesterId,
            $"{task.Requester.FirstName} {task.Requester.LastName}".Trim(),
            task.Requester.AvatarUrl,
            task.TransporterId,
            task.Transporter != null ? $"{task.Transporter.FirstName} {task.Transporter.LastName}".Trim() : null,
            task.PickupAddress,
            task.DropoffAddress,
            task.PickupWindowStart,
            task.PickupWindowEnd,
            task.IsSelfCollection,
            task.Status.ToString(),
            task.Notes,
            task.CreatedAt
        )).ToList();
    }
}
