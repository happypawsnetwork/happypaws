using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class SponsorshipDetailsConfiguration : IEntityTypeConfiguration<SponsorshipDetails>
{
    public void Configure(EntityTypeBuilder<SponsorshipDetails> builder)
    {
        builder.ToTable("sponsorship_details");
        builder.HasKey(s => s.PostId);

        builder.Property(s => s.PostId).HasColumnName("post_id").ValueGeneratedNever();
        builder.Property(s => s.GoalDescription).HasColumnName("goal_description").HasMaxLength(1000);
        builder.Property(s => s.EstimatedAmountLkr).HasColumnName("estimated_amount_lkr").HasColumnType("decimal(12,2)");
        builder.Property(s => s.AdminApproverId).HasColumnName("admin_approver_id");
        builder.Property(s => s.AdminReviewedAt).HasColumnName("admin_reviewed_at").HasColumnType("timestamptz");
        builder.Property(s => s.AdminRejectionNotes).HasColumnName("admin_rejection_notes").HasMaxLength(500);
        builder.Property(s => s.FundedAt).HasColumnName("funded_at").HasColumnType("timestamptz");

        builder.HasOne(s => s.Post)
            .WithOne(p => p.SponsorshipDetails)
            .HasForeignKey<SponsorshipDetails>(s => s.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(s => s.AdminApprover)
            .WithMany()
            .HasForeignKey(s => s.AdminApproverId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);
        builder.HasQueryFilter(x => !x.Post.IsDeleted);
    }
}

