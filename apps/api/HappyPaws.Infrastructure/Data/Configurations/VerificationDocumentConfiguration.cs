using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class VerificationDocumentConfiguration : IEntityTypeConfiguration<VerificationDocument>
{
    public void Configure(EntityTypeBuilder<VerificationDocument> builder)
    {
        builder.ToTable("verification_documents");

        builder.HasKey(d => d.Id);

        builder.Property(d => d.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd();

        builder.Property(d => d.VerificationRequestId)
            .HasColumnName("verification_request_id")
            .IsRequired();

        builder.Property(d => d.DocumentType)
            .HasColumnName("document_type")
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(d => d.DocumentUri)
            .HasColumnName("document_uri")
            .HasMaxLength(1000)
            .IsRequired();

        builder.Property(d => d.UploadDate)
            .HasColumnName("upload_date")
            .IsRequired();

        builder.HasIndex(d => d.VerificationRequestId)
            .HasDatabaseName("idx_verification_documents_request_id");

        builder.HasQueryFilter(d => !d.VerificationRequest.User.IsDeleted);
    }
}

