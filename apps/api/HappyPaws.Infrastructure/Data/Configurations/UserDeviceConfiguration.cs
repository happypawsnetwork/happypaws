using System;
using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class UserDeviceConfiguration : IEntityTypeConfiguration<UserDevice>
{
    public void Configure(EntityTypeBuilder<UserDevice> builder)
    {
        builder.ToTable("user_devices", t =>
        {
            t.HasCheckConstraint("CK_user_devices_device_type", "device_type IN ('ANDROID', 'IOS', 'WEB')");
        });

        builder.HasKey(d => d.Id);
        builder.Property(d => d.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd()
            .UseIdentityAlwaysColumn();

        builder.Property(d => d.UserId)
            .HasColumnName("user_id")
            .IsRequired();

        builder.Property(d => d.FcmToken)
            .HasColumnName("fcm_token")
            .IsRequired()
            .HasColumnType("text");

        builder.Property(d => d.DeviceType)
            .HasColumnName("device_type")
            .HasConversion(
                v => v.HasValue ? v.Value.ToString().ToUpper() : null,
                v => v != null ? Enum.Parse<HappyPaws.Domain.Enums.DeviceType>(v, true) : null
            )
            .HasColumnType("text");

        builder.Property(d => d.LastActiveAt)
            .HasColumnName("last_active_at")
            .IsRequired()
            .HasColumnType("timestamptz")
            .HasDefaultValueSql("now()");

        builder.Property(d => d.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired()
            .HasColumnType("timestamptz")
            .HasDefaultValueSql("now()");

        builder.Property(d => d.RefreshTokenHash)
            .HasColumnName("refresh_token_hash")
            .HasColumnType("text");

        builder.Property(d => d.RefreshTokenExpiryTime)
            .HasColumnName("refresh_token_expiry_time")
            .HasColumnType("timestamptz");

        builder.HasIndex(d => d.FcmToken)
            .IsUnique();

        builder.HasIndex(d => d.UserId)
            .HasDatabaseName("idx_user_devices_user_id");
    }
}
