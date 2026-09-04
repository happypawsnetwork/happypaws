using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Infrastructure.Services;

public class ReputationService : IReputationService
{
    private readonly IApplicationDbContext _context;

    public ReputationService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task AwardPointsAsync(long userId, int points, CancellationToken cancellationToken = default)
    {
        var user = await _context.Users.FindAsync(new object[] { userId }, cancellationToken);
        if (user != null)
        {
            user.AddReputationPoints(points);
            await _context.SaveChangesAsync(cancellationToken);
        }
    }

    public async Task AwardBadgeAsync(long userId, BadgeType badgeType, CancellationToken cancellationToken = default)
    {
        bool hasBadge = await _context.UserBadges
            .AnyAsync(b => b.UserId == userId && b.BadgeType == badgeType, cancellationToken);

        if (!hasBadge)
        {
            var user = await _context.Users.FindAsync(new object[] { userId }, cancellationToken);
            if (user != null)
            {
                var newBadge = new UserBadge
                {
                    UserId = userId,
                    BadgeType = badgeType,
                    AwardedAt = DateTimeOffset.UtcNow,
                    CreatedAt = DateTimeOffset.UtcNow,
                    UpdatedAt = DateTimeOffset.UtcNow
                };

                _context.UserBadges.Add(newBadge);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }
    }

    public async Task ProcessAdoptionAcceptedAsync(long userId, Guid animalId, CancellationToken cancellationToken = default)
    {
        await AwardPointsAsync(userId, 100, cancellationToken);

        var adoptionsCount = await _context.RescueApplications
            .CountAsync(a => a.ApplicantId == userId && a.ApplicantRole == ApplicantRole.Adopter && a.Status == RescueApplicationStatus.Approved, cancellationToken);

        if (adoptionsCount == 1) // First adoption
        {
            await AwardBadgeAsync(userId, BadgeType.WelcomeHome, cancellationToken);
        }
        else if (adoptionsCount > 1) // Multiple adoptions
        {
            await AwardBadgeAsync(userId, BadgeType.GrowingFamily, cancellationToken);
        }

        // UNCONDITIONAL_LOVE
        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == animalId, cancellationToken);
        if (post != null && post.AnimalDescription != null && (post.AnimalDescription.Contains("special needs", StringComparison.OrdinalIgnoreCase) || post.AnimalDescription.Contains("behavioral challenge", StringComparison.OrdinalIgnoreCase)))
        {
            await AwardBadgeAsync(userId, BadgeType.UnconditionalLove, cancellationToken);
        }
    }

    public async Task ProcessFosterPlacementCreatedAsync(long userId, Guid animalId, CancellationToken cancellationToken = default)
    {
        // HEALING_HANDS check
        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == animalId, cancellationToken);
        if (post != null && post.AnimalDescription != null && post.AnimalDescription.Contains("medical recovery", StringComparison.OrdinalIgnoreCase))
        {
            await AwardBadgeAsync(userId, BadgeType.HealingHands, cancellationToken);
        }
    }

    public async Task ProcessFosterPlacementCompletedAsync(long userId, CancellationToken cancellationToken = default)
    {
        await AwardPointsAsync(userId, 50, cancellationToken);

        var fostersCount = await _context.RescueApplications
            .CountAsync(a => a.ApplicantId == userId && a.ApplicantRole == ApplicantRole.Foster && a.Status == RescueApplicationStatus.Approved, cancellationToken);

        if (fostersCount >= 10)
        {
            await AwardBadgeAsync(userId, BadgeType.EndlessLove, cancellationToken);
        }
    }

    public async Task ProcessTransportDeliveredAsync(long userId, Guid rescueCaseId, CancellationToken cancellationToken = default)
    {
        await AwardPointsAsync(userId, 20, cancellationToken);

        var transportsCount = await _context.TransportTasks
            .CountAsync(t => t.TransporterId == userId && t.Status == TransportTaskStatus.Completed, cancellationToken);

        if (transportsCount >= 10)
        {
            await AwardBadgeAsync(userId, BadgeType.PawPatrol, cancellationToken);
        }

        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == rescueCaseId, cancellationToken);
        if (post != null && post.UrgencyLevel == RescueUrgencyLevel.Critical)
        {
            await AwardBadgeAsync(userId, BadgeType.UrgentExpress, cancellationToken);
        }
    }

    public async Task ProcessSponsorshipFulfilledAsync(long userId, Guid rescueCaseId, CancellationToken cancellationToken = default)
    {
        await AwardPointsAsync(userId, 50, cancellationToken);

        // For ALWAYS_THERE and EMERGENCY_FUNDER, check how many sponsorships this user has
        // Currently there is no separate Sponsorships table mapping to users in the context easily
    }

    public async Task ProcessPostCreatedAsync(long userId, PostType postType, CancellationToken cancellationToken = default)
    {
        int points = postType switch
        {
            PostType.RescueAlert => 10,
            PostType.AdoptionListing => 10,
            PostType.FosterUpdate => 5,
            PostType.Highlight => 2,
            _ => 0
        };

        if (points > 0)
        {
            await AwardPointsAsync(userId, points, cancellationToken);
        }

        // Badges check
        var userPosts = await _context.Posts
            .Where(p => p.AuthorId == userId)
            .GroupBy(p => p.Type)
            .Select(g => new { Type = g.Key, Count = g.Count() })
            .ToListAsync(cancellationToken);

        var rescuesCount = userPosts.FirstOrDefault(x => x.Type == PostType.RescueAlert)?.Count ?? 0;
        var highlightsCount = userPosts.FirstOrDefault(x => x.Type == PostType.Highlight)?.Count ?? 0;
        var updatesCount = userPosts.FirstOrDefault(x => x.Type == PostType.FosterUpdate)?.Count ?? 0;

        if (postType == PostType.RescueAlert && rescuesCount == 1)
        {
            await AwardBadgeAsync(userId, BadgeType.FirstResponder, cancellationToken);
        }

        if (postType == PostType.Highlight && highlightsCount >= 5)
        {
            await AwardBadgeAsync(userId, BadgeType.Storyteller, cancellationToken);
        }

        if (postType == PostType.FosterUpdate && updatesCount >= 10)
        {
            await AwardBadgeAsync(userId, BadgeType.PawsitiveUpdates, cancellationToken);
        }
    }

    public async Task ProcessPostLikedAsync(long postAuthorId, Guid postId, CancellationToken cancellationToken = default)
    {
        await AwardPointsAsync(postAuthorId, 1, cancellationToken);

        var post = await _context.Posts.FirstOrDefaultAsync(p => p.Id == postId, cancellationToken);
        if (post != null && post.LikeCount >= 50)
        {
            await AwardBadgeAsync(postAuthorId, BadgeType.CommunityVoice, cancellationToken);
        }
    }
}
