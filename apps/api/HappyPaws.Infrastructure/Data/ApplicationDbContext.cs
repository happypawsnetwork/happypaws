using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Infrastructure.Data;

public class ApplicationDbContext : DbContext, IApplicationDbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<UserBadge> UserBadges => Set<UserBadge>();
    public DbSet<UserRole> UserRoles => Set<UserRole>();
    public DbSet<UserDevice> UserDevices => Set<UserDevice>();
    public DbSet<RefreshToken> RefreshTokens => Set<RefreshToken>();
    public DbSet<Post> Posts => Set<Post>();
    public DbSet<PostMedia> PostMedia => Set<PostMedia>();
    public DbSet<PostLike> PostLikes => Set<PostLike>();
    public DbSet<RescueApplication> RescueApplications => Set<RescueApplication>();
    public DbSet<TransportTask> TransportTasks => Set<TransportTask>();
    public DbSet<TransportOffer> TransportOffers => Set<TransportOffer>();
    public DbSet<SponsorshipProofDocument> SponsorshipProofDocuments => Set<SponsorshipProofDocument>();
    public DbSet<VerificationRequest> VerificationRequests => Set<VerificationRequest>();
    public DbSet<VerificationDocument> VerificationDocuments => Set<VerificationDocument>();
    public DbSet<ChatThread> ChatThreads => Set<ChatThread>();
    public DbSet<ChatParticipant> ChatParticipants => Set<ChatParticipant>();
    public DbSet<Message> Messages => Set<Message>();
    public DbSet<CanMessage> CanMessages => Set<CanMessage>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);
        modelBuilder.ApplyConfigurationsFromAssembly(typeof(ApplicationDbContext).Assembly);
    }
}
