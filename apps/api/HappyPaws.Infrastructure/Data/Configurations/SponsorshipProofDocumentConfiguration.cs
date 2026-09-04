using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class SponsorshipProofDocumentConfiguration : IEntityTypeConfiguration<SponsorshipProofDocument>
{
    public void Configure(EntityTypeBuilder<SponsorshipProofDocument> builder)
    {
        builder.ToTable("sponsorship_proof_documents", t =>
        {
            t.HasCheckConstraint("CK_sponsorship_proof_mime_type", "mime_type IN ('image/jpeg','image/png','image/webp','image/heic','application/pdf')");
            t.HasCheckConstraint("CK_sponsorship_proof_file_size", "file_size_bytes <= 5242880");
        });
        builder.HasKey(s => s.Id);

        builder.Property(s => s.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(s => s.PostId).HasColumnName("post_id");
        builder.Property(s => s.StorageKey).HasColumnName("storage_key").HasMaxLength(500);
        builder.Property(s => s.FileName).HasColumnName("file_name").HasMaxLength(200);
        builder.Property(s => s.MimeType).HasColumnName("mime_type").HasMaxLength(50);
        builder.Property(s => s.FileSizeBytes).HasColumnName("file_size_bytes");
        builder.Property(s => s.UploadedAt).HasColumnName("uploaded_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.HasOne(s => s.Post)
            .WithMany()
            .HasForeignKey(s => s.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(s => s.PostId);
        builder.HasQueryFilter(x => !x.Post.IsDeleted);
    }
}

