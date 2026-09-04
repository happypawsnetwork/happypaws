using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class PostMediaConfiguration : IEntityTypeConfiguration<PostMedia>
{
    public void Configure(EntityTypeBuilder<PostMedia> builder)
    {
        builder.ToTable("post_media", t =>
        {
            t.HasCheckConstraint("CK_post_media_mime_type", "mime_type IN ('image/jpeg','image/png','image/webp','image/heic')");
            t.HasCheckConstraint("CK_post_media_file_size", "file_size_bytes <= 5242880");
        });
        builder.HasKey(m => m.Id);

        builder.Property(m => m.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(m => m.PostId).HasColumnName("post_id");
        builder.Property(m => m.StorageKey).HasColumnName("storage_key").HasMaxLength(500);
        builder.Property(m => m.CdnUrl).HasColumnName("cdn_url").HasMaxLength(1000);
        builder.Property(m => m.MimeType).HasColumnName("mime_type").HasMaxLength(50);
        builder.Property(m => m.FileSizeBytes).HasColumnName("file_size_bytes");
        builder.Property(m => m.SortOrder).HasColumnName("sort_order").HasDefaultValue(0);
        builder.Property(m => m.UploadedAt).HasColumnName("uploaded_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.HasOne(m => m.Post)
            .WithMany(p => p.Media)
            .HasForeignKey(m => m.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(m => new { m.PostId, m.SortOrder });
        builder.HasQueryFilter(x => !x.Post.IsDeleted);
    }
}

