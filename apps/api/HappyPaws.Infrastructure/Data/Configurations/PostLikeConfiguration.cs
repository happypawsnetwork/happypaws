using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class PostLikeConfiguration : IEntityTypeConfiguration<PostLike>
{
    public void Configure(EntityTypeBuilder<PostLike> builder)
    {
        builder.ToTable("post_likes");
        builder.HasKey(pl => new { pl.PostId, pl.UserId });

        builder.Property(pl => pl.PostId).HasColumnName("post_id");
        builder.Property(pl => pl.UserId).HasColumnName("user_id");
        builder.Property(pl => pl.LikedAt).HasColumnName("liked_at").HasColumnType("timestamptz").HasDefaultValueSql("now()");

        builder.HasOne(pl => pl.Post)
            .WithMany(p => p.Likes)
            .HasForeignKey(pl => pl.PostId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(pl => pl.User)
            .WithMany()
            .HasForeignKey(pl => pl.UserId)
            .OnDelete(DeleteBehavior.Restrict);
        builder.HasQueryFilter(x => !x.Post.IsDeleted);
    }
}

