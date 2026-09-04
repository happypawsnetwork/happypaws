using System;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class TransportTaskConfiguration : IEntityTypeConfiguration<TransportTask>
{
    public void Configure(EntityTypeBuilder<TransportTask> builder)
    {
        builder.ToTable("transport_tasks", t =>
        {
            t.HasCheckConstraint("CK_transport_tasks_status", "status IN ('Open','Accepted','PickedUp','InTransit','Delivered','Completed','Cancelled')");
        });
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(t => t.TransportPostId).HasColumnName("transport_post_id");
        builder.Property(t => t.ParentPostId).HasColumnName("parent_post_id");
        builder.Property(t => t.RequesterId).HasColumnName("requester_id");
        builder.Property(t => t.TransporterId).HasColumnName("transporter_id");

        builder.Property(t => t.PickupAddress).HasColumnName("pickup_address").HasMaxLength(300);
        builder.Property(t => t.PickupPoint).HasColumnName("pickup_point").HasColumnType("geometry(Point,4326)");
        builder.Property(t => t.DropoffAddress).HasColumnName("dropoff_address").HasMaxLength(300);
        builder.Property(t => t.DropoffPoint).HasColumnName("dropoff_point").HasColumnType("geometry(Point,4326)");

        builder.Property(t => t.PickupWindowStart).HasColumnName("pickup_window_start").HasColumnType("timestamptz");
        builder.Property(t => t.PickupWindowEnd).HasColumnName("pickup_window_end").HasColumnType("timestamptz");

        builder.Property(t => t.IsSelfCollection).HasColumnName("is_self_collection").HasDefaultValue(false);

        builder.Property(t => t.Status).HasColumnName("status")
            .HasConversion(v => v.ToString(), v => Enum.Parse<TransportTaskStatus>(v));

        builder.Property(t => t.CompletedAt).HasColumnName("completed_at").HasColumnType("timestamptz");
        builder.Property(t => t.Notes).HasColumnName("notes").HasMaxLength(500);
        builder.Property(t => t.CreatedAt).HasColumnName("created_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");
        builder.Property(t => t.UpdatedAt).HasColumnName("updated_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.HasIndex(t => t.PickupPoint).HasMethod("gist");
        builder.HasIndex(t => new { t.TransporterId, t.Status });
        builder.HasIndex(t => new { t.Status, t.CreatedAt }).IsDescending(false, true);
        builder.HasIndex(t => t.ParentPostId);

        builder.HasOne(t => t.TransportPost)
            .WithMany()
            .HasForeignKey(t => t.TransportPostId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);

        builder.HasOne(t => t.ParentPost)
            .WithMany()
            .HasForeignKey(t => t.ParentPostId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(true);

        builder.HasOne(t => t.Requester)
            .WithMany()
            .HasForeignKey(t => t.RequesterId)
            .OnDelete(DeleteBehavior.Restrict);

        builder.HasOne(t => t.Transporter)
            .WithMany()
            .HasForeignKey(t => t.TransporterId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);

        builder.Metadata.FindNavigation(nameof(TransportTask.Offers))!.SetPropertyAccessMode(PropertyAccessMode.Field);
        builder.HasQueryFilter(x => !x.ParentPost.IsDeleted);
    }
}


