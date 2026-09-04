using System;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class RescueApplicationConfiguration : IEntityTypeConfiguration<RescueApplication>
{
    public void Configure(EntityTypeBuilder<RescueApplication> builder)
    {
        builder.ToTable("rescue_applications", t =>
        {
            t.HasCheckConstraint("CK_rescue_applications_role", "applicant_role IN ('Foster','Adopter')");
            t.HasCheckConstraint("CK_rescue_applications_status", "status IN ('Pending','Approved','Rejected','AdminOverridden')");
        });
        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(r => r.RescuePostId).HasColumnName("rescue_post_id");
        builder.Property(r => r.ApplicantId).HasColumnName("applicant_id");

        builder.Property(r => r.ApplicantRole).HasColumnName("applicant_role")
            .HasConversion(v => v.ToString(), v => Enum.Parse<ApplicantRole>(v));
        builder.Property(r => r.Status).HasColumnName("status")
            .HasConversion(v => v.ToString(), v => Enum.Parse<RescueApplicationStatus>(v));

        builder.Property(r => r.Message).HasColumnName("message").HasMaxLength(1000);
        builder.Property(r => r.ExperienceSummary).HasColumnName("experience_summary").HasMaxLength(500);
        builder.Property(r => r.HasVehicle).HasColumnName("has_vehicle").HasDefaultValue(false);
        builder.Property(r => r.PosterReviewedAt).HasColumnName("poster_reviewed_at").HasColumnType("timestamptz");
        builder.Property(r => r.AdminReviewedAt).HasColumnName("admin_reviewed_at").HasColumnType("timestamptz");
        builder.Property(r => r.AdminReviewerId).HasColumnName("admin_reviewer_id");
        builder.Property(r => r.CreatedAt).HasColumnName("created_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.HasIndex(r => new { r.RescuePostId, r.Status });
        builder.HasIndex(r => new { r.ApplicantId, r.Status });

        builder.HasOne(r => r.RescuePost)
            .WithMany()
            .HasForeignKey(r => r.RescuePostId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.Applicant)
            .WithMany()
            .HasForeignKey(r => r.ApplicantId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(r => r.AdminReviewer)
            .WithMany()
            .HasForeignKey(r => r.AdminReviewerId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);
        builder.HasQueryFilter(x => !x.Applicant.IsDeleted);
    }
}

