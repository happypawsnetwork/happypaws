using System;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class PostConfiguration : IEntityTypeConfiguration<Post>
{
    public void Configure(EntityTypeBuilder<Post> builder)
    {
        builder.ToTable("posts", t =>
        {
            t.HasCheckConstraint("CK_posts_type", "type IN ('RescueAlert', 'FosterUpdate', 'AdoptionListing', 'Highlight', 'TransportRequest', 'VetRequest', 'SponsorshipRequest')");
            t.HasCheckConstraint("CK_posts_status", "status IN ('Active', 'Fostered', 'Assigned', 'Completed', 'PendingApproval', 'Funded', 'Rejected', 'Cancelled')");
        });
        builder.HasKey(p => p.Id);

        builder.Property(p => p.Id).HasColumnName("id").ValueGeneratedNever();
        builder.Property(p => p.AuthorId).HasColumnName("author_id");

        builder.Property(p => p.Type).HasColumnName("type")
            .HasConversion(v => v.ToString(), v => Enum.Parse<PostType>(v));
        builder.Property(p => p.Status).HasColumnName("status")
            .HasConversion(v => v.ToString(), v => Enum.Parse<PostStatus>(v));

        builder.Property(p => p.Title).HasColumnName("title").HasMaxLength(120);
        builder.Property(p => p.Body).HasColumnName("body").HasMaxLength(4000);
        builder.Property(p => p.LikeCount).HasColumnName("like_count").HasDefaultValue(0);
        builder.Property(p => p.ParentPostId).HasColumnName("parent_post_id");
        builder.Property(p => p.AssignedApplicationId).HasColumnName("assigned_application_id");

        builder.Property(p => p.LocationPoint).HasColumnName("location_point").HasColumnType("geometry(Point,4326)");
        builder.HasIndex(p => p.LocationPoint).HasMethod("gist").HasDatabaseName("idx_posts_location");

        builder.Property(p => p.LocationLabel).HasColumnName("location_label").HasMaxLength(200);
        builder.Property(p => p.AnimalSpecies).HasColumnName("animal_species").HasMaxLength(50);
        builder.Property(p => p.AnimalName).HasColumnName("animal_name").HasMaxLength(80);
        builder.Property(p => p.AnimalDescription).HasColumnName("animal_description").HasMaxLength(1000);

        builder.Property(p => p.UrgencyLevel)
            .HasConversion<string>()
            .HasMaxLength(20);

        builder.Property(p => p.AiTriageReason)
            .HasMaxLength(1000);

        builder.Property(p => p.UrgencyAssessedAt)
            .HasColumnType("timestamptz");

        builder.Property(p => p.IsDeleted).HasColumnName("is_deleted").HasDefaultValue(false);

        builder.Property(p => p.CreatedAt).HasColumnName("created_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");
        builder.Property(p => p.UpdatedAt).HasColumnName("updated_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.OwnsOne(p => p.Expectations, ex =>
        {
            ex.Property(e => e.HomeSize).HasColumnName("expectations_home_size").HasConversion<string>();
            ex.Property(e => e.RequiresEnclosedYard).HasColumnName("expectations_requires_yard");
            ex.Property(e => e.GoodWithChildren).HasColumnName("expectations_good_with_children");
            ex.Property(e => e.ActivityTempo).HasColumnName("expectations_activity_tempo").HasConversion<string>();
            ex.Property(e => e.GoodWithPets).HasColumnName("expectations_good_with_pets");
        });

        builder.HasIndex(p => new { p.Type, p.Status, p.CreatedAt }).IsDescending(false, false, true);
        builder.HasIndex(p => new { p.AuthorId, p.CreatedAt }).IsDescending(false, true);
        builder.HasIndex(p => p.ParentPostId);

        builder.HasQueryFilter(p => !p.IsDeleted);

        builder.HasOne(p => p.ParentPost)
            .WithMany(p => p.ChildPosts)
            .HasForeignKey(p => p.ParentPostId)
            .OnDelete(DeleteBehavior.Restrict)
            .IsRequired(false);

        builder.HasOne(p => p.AssignedApplication)
            .WithOne()
            .HasForeignKey<Post>(p => p.AssignedApplicationId)
            .IsRequired(false)
            .OnDelete(DeleteBehavior.SetNull);

        builder.Metadata.FindNavigation(nameof(Post.ChildPosts))!.SetPropertyAccessMode(PropertyAccessMode.Field);
        builder.Metadata.FindNavigation(nameof(Post.Media))!.SetPropertyAccessMode(PropertyAccessMode.Field);
        builder.Metadata.FindNavigation(nameof(Post.Likes))!.SetPropertyAccessMode(PropertyAccessMode.Field);
    }
}
