using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public sealed record SponsorshipProofDocumentResponse(
    Guid Id,
    string FileName,
    string MimeType,
    long FileSize,
    string Url
);

public static class GetSponsorshipProofDocuments
{
    public static async Task<IReadOnlyList<SponsorshipProofDocumentResponse>> HandleAsync(
        IApplicationDbContext db,
        IStorageService storage,
        Guid postId,
        long currentUserId,
        bool isAdmin,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && p.Type == PostType.SponsorshipRequest && !p.IsDeleted, ct);
        if (post == null)
            throw new Exception("Sponsorship post not found");

        var user = await db.Users.Include(u => u.Roles).FirstOrDefaultAsync(u => u.Id == currentUserId, ct);
        bool isSponsor = user?.Roles.Any(r => r.RoleName == RoleName.Sponsor) ?? false;
        bool isAuthor = post.AuthorId == currentUserId;

        if (!isAdmin && !isAuthor && !(isSponsor && post.Status == PostStatus.Active))
            throw new UnauthorizedAccessException("Not authorized to view these documents");

        var docs = await db.SponsorshipProofDocuments
            .Where(d => d.PostId == postId)
            .ToListAsync(ct);

        var responses = new List<SponsorshipProofDocumentResponse>();
        foreach (var doc in docs)
        {
            var url = await storage.GetPresignedUrlAsync(doc.StorageKey, TimeSpan.FromMinutes(10), ct);
            responses.Add(new SponsorshipProofDocumentResponse(
                doc.Id,
                doc.FileName,
                doc.MimeType,
                doc.FileSizeBytes,
                url
            ));
        }

        return responses;
    }
}
