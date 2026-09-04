using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class AdminPermanentDeletePost
{
    public static async Task<bool> HandleAsync(
        IApplicationDbContext db,
        IStorageService storage,
        Guid postId,
        CancellationToken ct)
    {
        var post = await db.Posts
            .IgnoreQueryFilters()
            .Include(p => p.Media)
            .Include(p => p.Likes)
            .Include(p => p.VetDetails)
            .Include(p => p.SponsorshipDetails)
            .FirstOrDefaultAsync(p => p.Id == postId, ct);

        if (post == null)
            return false;

        // Delete public media files from object storage
        foreach (var media in post.Media)
        {
            if (!string.IsNullOrWhiteSpace(media.StorageKey))
            {
                try
                {
                    await storage.DeletePublicFileAsync(media.StorageKey, ct);
                }
                catch
                {
                    // Proceed even if an asset is already missing from storage
                }
            }
        }

        // Delete sponsorship proof documents from private storage and database
        var proofDocs = await db.SponsorshipProofDocuments
            .IgnoreQueryFilters()
            .Where(d => d.PostId == postId)
            .ToListAsync(ct);

        foreach (var doc in proofDocs)
        {
            if (!string.IsNullOrWhiteSpace(doc.StorageKey))
            {
                try
                {
                    await storage.DeletePrivateFileAsync(doc.StorageKey, ct);
                }
                catch
                {
                    // Proceed even if an asset is already missing from storage
                }
            }
        }

        if (proofDocs.Count > 0)
        {
            db.SponsorshipProofDocuments.RemoveRange(proofDocs);
        }

        // Remove rescue applications linked to this post
        var rescueApps = await db.RescueApplications
            .IgnoreQueryFilters()
            .Where(r => r.RescuePostId == postId)
            .ToListAsync(ct);

        if (rescueApps.Count > 0)
        {
            db.RescueApplications.RemoveRange(rescueApps);
        }

        // Remove transport tasks linked to this post
        var transportTasks = await db.TransportTasks
            .IgnoreQueryFilters()
            .Where(t => t.ParentPostId == postId || t.TransportPostId == postId)
            .ToListAsync(ct);

        if (transportTasks.Count > 0)
        {
            db.TransportTasks.RemoveRange(transportTasks);
        }

        // Unlink any child posts so their foreign key references do not block deletion
        var childPosts = await db.Posts
            .IgnoreQueryFilters()
            .Where(p => p.ParentPostId == postId)
            .ToListAsync(ct);

        foreach (var child in childPosts)
        {
            child.ParentPostId = null;
        }

        db.Posts.Remove(post);
        await db.SaveChangesAsync(ct);
        return true;
    }
}
