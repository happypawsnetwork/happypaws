using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public class UserConfiguration : IEntityTypeConfiguration<User>
{
    public void Configure(EntityTypeBuilder<User> builder)
    {
        builder.ToTable("users");

        builder.HasKey(u => u.Id);
        builder.Property(u => u.Id)
            .HasColumnName("id")
            .ValueGeneratedOnAdd()
            .UseIdentityAlwaysColumn();

        builder.Property(u => u.Email)
            .HasColumnName("email")
            .IsRequired()
            .HasColumnType("text");

        builder.Property<uint>("Version")
            .IsRowVersion();

        builder.HasIndex(u => u.Email)
            .IsUnique()
            .HasDatabaseName("idx_users_lower_email");

        builder.Property(u => u.Username)
            .HasColumnName("username")
            .HasMaxLength(50)
            .HasColumnType("text");

        builder.HasIndex(u => u.Username)
            .IsUnique()
            .HasDatabaseName("idx_users_lower_username");

        builder.Property(u => u.PasswordHash)
            .HasColumnName("password_hash")
            .IsRequired()
            .HasColumnType("text");

        builder.Property(u => u.FirstName)
            .HasColumnName("first_name")
            .IsRequired()
            .HasColumnType("text");

        builder.Property(u => u.LastName)
            .HasColumnName("last_name")
            .IsRequired()
            .HasColumnType("text");

        builder.Property(u => u.PhoneNumber)
            .HasColumnName("phone_number")
            .HasColumnType("text");

        builder.Property(u => u.AvatarUrl)
            .HasColumnName("avatar_url")
            .HasColumnType("text");

        builder.Property(u => u.Tagline)
            .HasColumnName("tagline")
            .HasMaxLength(150)
            .HasColumnType("text");

        builder.Property(u => u.ReputationPoints)
            .HasColumnName("reputation_points")
            .IsRequired()
            .HasDefaultValue(0);

        builder.Property(u => u.IsActive)
            .HasColumnName("is_active")
            .IsRequired()
            .HasDefaultValue(true);

        builder.Property(u => u.IsDeleted)
            .HasColumnName("is_deleted")
            .IsRequired()
            .HasDefaultValue(false);

        builder.Property(u => u.ReceiveMessages)
            .HasColumnName("receive_messages")
            .IsRequired()
            .HasDefaultValue(true);

        builder.Property(u => u.CreatedAt)
            .HasColumnName("created_at")
            .IsRequired()
            .HasColumnType("timestamptz")
            .HasDefaultValueSql("now()");

        builder.Property(u => u.UpdatedAt)
            .HasColumnName("updated_at")
            .IsRequired()
            .HasColumnType("timestamptz")
            .HasDefaultValueSql("now()");

        builder.Property(u => u.AddressLine1)
            .HasColumnName("address_line1")
            .HasColumnType("text");

        builder.Property(u => u.AddressLine2)
            .HasColumnName("address_line2")
            .HasColumnType("text");

        builder.Property(u => u.City)
            .HasColumnName("city")
            .HasColumnType("text");

        builder.Property(u => u.State)
            .HasColumnName("state")
            .HasColumnType("text");

        builder.Property(u => u.PostalCode)
            .HasColumnName("postal_code")
            .HasColumnType("text");

        builder.Property(u => u.Country)
            .HasColumnName("country")
            .HasColumnType("text");

        builder.Property(u => u.HomeLatitude)
            .HasColumnName("home_latitude");

        builder.Property(u => u.HomeLongitude)
            .HasColumnName("home_longitude");

        builder.HasQueryFilter(u => !u.IsDeleted);

        builder.HasMany(u => u.Roles)
            .WithOne()
            .HasForeignKey(r => r.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Cascade);

        builder.OwnsOne(u => u.LifestyleProfile, lp =>
        {
            lp.Property(p => p.HomeSize).HasColumnName("lifestyle_home_size").HasConversion<string>();
            lp.Property(p => p.HasEnclosedYard).HasColumnName("lifestyle_has_yard");
            lp.Property(p => p.HasChildren).HasColumnName("lifestyle_has_children");
            lp.Property(p => p.ActivityTempo).HasColumnName("lifestyle_activity_tempo").HasConversion<string>();
            lp.Property(p => p.ExistingPets).HasColumnName("lifestyle_existing_pets");
        });

        builder.Metadata
            .FindNavigation(nameof(User.Roles))!
            .SetPropertyAccessMode(PropertyAccessMode.Field);

        builder.HasMany(u => u.Devices)
            .WithOne()
            .HasForeignKey(d => d.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Cascade);

        builder.Metadata
            .FindNavigation(nameof(User.Devices))!
            .SetPropertyAccessMode(PropertyAccessMode.Field);

        builder.HasMany(u => u.Badges)
            .WithOne(b => b.User)
            .HasForeignKey(b => b.UserId)
            .IsRequired()
            .OnDelete(DeleteBehavior.Cascade);

        builder.Metadata
            .FindNavigation(nameof(User.Badges))!
            .SetPropertyAccessMode(PropertyAccessMode.Field);
    }
}
