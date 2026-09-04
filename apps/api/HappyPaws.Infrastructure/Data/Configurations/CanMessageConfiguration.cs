using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class CanMessageConfiguration : IEntityTypeConfiguration<CanMessage>
{
    public void Configure(EntityTypeBuilder<CanMessage> builder)
    {
        builder.ToTable("can_message");
        builder.HasKey(c => c.Id);

        builder.HasOne(c => c.FromUser)
            .WithMany()
            .HasForeignKey(c => c.FromUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(c => c.ToUser)
            .WithMany()
            .HasForeignKey(c => c.ToUserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(c => new { c.FromUserId, c.ToUserId }).IsUnique();
    }
}
