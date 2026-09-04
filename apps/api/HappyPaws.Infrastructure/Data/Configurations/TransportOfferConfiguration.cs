using System;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class TransportOfferConfiguration : IEntityTypeConfiguration<TransportOffer>
{
    public void Configure(EntityTypeBuilder<TransportOffer> builder)
    {
        builder.ToTable("transport_offers", t =>
        {
            t.HasCheckConstraint("CK_transport_offers_status", "status IN ('Pending','Accepted','Rejected')");
        });
        builder.HasKey(t => t.Id);

        builder.Property(t => t.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(t => t.TransportTaskId).HasColumnName("transport_task_id");
        builder.Property(t => t.TransporterId).HasColumnName("transporter_id");
        builder.Property(t => t.Message).HasColumnName("message").HasMaxLength(500);
        builder.Property(t => t.ProposedPickupStart).HasColumnName("proposed_pickup_start").HasColumnType("timestamptz");
        builder.Property(t => t.ProposedPickupEnd).HasColumnName("proposed_pickup_end").HasColumnType("timestamptz");

        builder.Property(t => t.Status).HasColumnName("status")
            .HasConversion(v => v.ToString(), v => Enum.Parse<TransportOfferStatus>(v));

        builder.Property(t => t.CreatedAt).HasColumnName("created_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.HasIndex(t => new { t.TransportTaskId, t.Status });

        builder.HasOne(t => t.Task)
            .WithMany(tt => tt.Offers)
            .HasForeignKey(t => t.TransportTaskId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(t => t.Transporter)
            .WithMany()
            .HasForeignKey(t => t.TransporterId)
            .OnDelete(DeleteBehavior.Restrict);
        builder.HasQueryFilter(x => !x.Transporter.IsDeleted);
    }
}


