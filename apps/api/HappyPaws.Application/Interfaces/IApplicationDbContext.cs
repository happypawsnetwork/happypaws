using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Interfaces;

public interface IApplicationDbContext
{
    DbSet<User> Users { get; }
    DbSet<UserBadge> UserBadges { get; }
    DbSet<UserRole> UserRoles { get; }
    DbSet<UserDevice> UserDevices { get; }
    DbSet<RefreshToken> RefreshTokens { get; }
    DbSet<Post> Posts { get; }
    DbSet<PostMedia> PostMedia { get; }
    DbSet<PostLike> PostLikes { get; }
    DbSet<RescueApplication> RescueApplications { get; }
    DbSet<TransportTask> TransportTasks { get; }
    DbSet<TransportOffer> TransportOffers { get; }
    DbSet<SponsorshipProofDocument> SponsorshipProofDocuments { get; }
    DbSet<VerificationRequest> VerificationRequests { get; }
    DbSet<VerificationDocument> VerificationDocuments { get; }
    DbSet<ChatThread> ChatThreads { get; }
    DbSet<ChatParticipant> ChatParticipants { get; }
    DbSet<Message> Messages { get; }
    DbSet<CanMessage> CanMessages { get; }

    Task<int> SaveChangesAsync(CancellationToken cancellationToken);
}
