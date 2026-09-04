using System;
using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class UserRoleConfiguration : IEntityTypeConfiguration<UserRole>
{
    public void Configure(EntityTypeBuilder<UserRole> builder)
    {
        builder.ToTable("user_roles", t =>
        {
            t.HasCheckConstraint("CK_user_roles_role_name", "role_name IN ('ADOPTER', 'FOSTER', 'TRANSPORTER', 'VETERINARIAN', 'SPONSOR', 'ADMINISTRATOR')");
        });

        builder.HasKey(r => new { r.UserId, r.RoleName });

        builder.Property(r => r.UserId)
            .HasColumnName("user_id");

        builder.Property(r => r.RoleName)
            .HasColumnName("role_name")
            .HasConversion(
                v => v.ToString().ToUpper(),
                v => Enum.Parse<HappyPaws.Domain.Enums.RoleName>(v, true)
            )
            .IsRequired()
            .HasColumnType("text");

        builder.Property(r => r.IsVerified)
            .HasColumnName("is_verified")
            .HasDefaultValue(false);

        builder.Property(r => r.IsVisible)
            .HasColumnName("is_visible")
            .HasDefaultValue(true);

        builder.HasIndex(r => r.UserId)
            .HasDatabaseName("idx_user_roles_user_id");
    }
}
