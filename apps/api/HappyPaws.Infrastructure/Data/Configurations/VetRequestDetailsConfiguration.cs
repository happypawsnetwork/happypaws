using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class VetRequestDetailsConfiguration : IEntityTypeConfiguration<VetRequestDetails>
{
    public void Configure(EntityTypeBuilder<VetRequestDetails> builder)
    {
        builder.ToTable("vet_request_details");
        builder.HasKey(v => v.PostId);

        builder.Property(v => v.PostId).HasColumnName("post_id").ValueGeneratedNever();
        builder.Property(v => v.ReasonForVisit).HasColumnName("reason_for_visit").HasMaxLength(500);
        builder.Property(v => v.ClinicName).HasColumnName("clinic_name").HasMaxLength(200);
        builder.Property(v => v.AppointmentDate).HasColumnName("appointment_date").HasColumnType("timestamptz");
        builder.Property(v => v.TransportNeeded).HasColumnName("transport_needed").HasDefaultValue(false);

        builder.HasOne(v => v.Post)
            .WithOne(p => p.VetDetails)
            .HasForeignKey<VetRequestDetails>(v => v.PostId)
            .OnDelete(DeleteBehavior.Cascade);
        builder.HasQueryFilter(x => !x.Post.IsDeleted);
    }
}

