using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class VerificationRequestConfiguration : IEntityTypeConfiguration<VerificationRequest>
{
    public void Configure(EntityTypeBuilder<VerificationRequest> builder)
    {
        builder.ToTable("verification_requests");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd();

        builder.Property(r => r.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(r => r.RequestedRole)
            .HasColumnName("requested_role")
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.Status)
            .HasColumnName("status")
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.Notes)
            .HasColumnName("notes")
            .HasMaxLength(1000);

        builder.Property(r => r.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired();

        builder.Property(r => r.UpdatedAt)
            .HasColumnName("updated_at")
            .IsRequired();

        builder.HasOne(r => r.User)
            .WithMany()
            .HasForeignKey(r => r.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasMany(r => r.Documents)
            .WithOne(d => d.VerificationRequest)
            .HasForeignKey(d => d.VerificationRequestId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.Navigation(r => r.Documents).UsePropertyAccessMode(PropertyAccessMode.Field);

        builder.HasIndex(r => new { r.UserId, r.RequestedRole, r.Status })
            .HasDatabaseName("idx_verification_requests_user_role_status");
        builder.HasQueryFilter(x => !x.User.IsDeleted);
    }
}


