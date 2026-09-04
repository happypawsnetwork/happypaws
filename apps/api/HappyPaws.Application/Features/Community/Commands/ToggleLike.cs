using System;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Commands;

public static class ToggleLike
{
    public static async Task<(bool isLiked, int likeCount)> HandleAsync(
        IApplicationDbContext db,
        IReputationService reputationService,
        Guid postId,
        long userId,
        CancellationToken ct)
    {
        var post = await db.Posts.FirstOrDefaultAsync(p => p.Id == postId && !p.IsDeleted, ct);
        if (post == null)
            throw new Exception("Post not found");

        var existingLike = await db.PostLikes.FirstOrDefaultAsync(l => l.PostId == postId && l.UserId == userId, ct);

        bool isLiked;
        if (existingLike != null)
        {
            db.PostLikes.Remove(existingLike);
            post.LikeCount = Math.Max(0, post.LikeCount - 1);
            isLiked = false;
        }
        else
        {
            db.PostLikes.Add(new PostLike
            {
                PostId = postId,
                UserId = userId,
                LikedAt = DateTimeOffset.UtcNow
            });
            post.LikeCount++;
            isLiked = true;
        }

        await db.SaveChangesAsync(ct);

        if (isLiked)
        {
            await reputationService.ProcessPostLikedAsync(post.AuthorId, postId, ct);
        }

        return (isLiked, post.LikeCount);
    }
}
