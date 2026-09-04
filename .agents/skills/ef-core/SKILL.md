---
name: ef-core
description: Comprehensive Entity Framework Core (EF Core 10) best practices, Npgsql PostgreSQL provider configurations, DDD mappings, interceptors, and performance optimization.
---

# Entity Framework Core Best Practices (.NET 10 & PostgreSQL)

Comprehensive guide for designing, configuring, and optimizing Entity Framework Core within a Clean Architecture and Domain-Driven Design (DDD) .NET 10 application using the Npgsql PostgreSQL provider.

## Architecture and Organization

### 1. Separate Entity Configurations
Never clutter `DbContext.OnModelCreating` with inline entity mappings. Implement `IEntityTypeConfiguration<T>` in dedicated configuration classes within the Infrastructure layer.

```csharp
public class AnimalConfiguration : IEntityTypeConfiguration<Animal>
{
    public void Configure(EntityTypeBuilder<Animal> builder)
    {
        builder.ToTable("animals");

        builder.HasKey(a => a.Id);
        builder.Property(a => a.Id)
            .ValueGeneratedOnAdd()
            .UseIdentityAlwaysColumn();

        builder.Property(a => a.Name)
            .IsRequired()
            .HasColumnType("text");

        builder.Property(a => a.Species)
            .IsRequired()
            .HasMaxLength(50);

        builder.Property(a => a.CreatedAt)
            .IsRequired()
            .HasColumnType("timestamptz")
            .HasDefaultValueSql("now()");
    }
}
```

In `AppDbContext.cs`, register all configurations dynamically:
```csharp
protected override void OnModelCreating(ModelBuilder modelBuilder)
{
    base.OnModelCreating(modelBuilder);
    modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly);
}
```

---

## Domain-Driven Design (DDD) Mapping Patterns

### 1. Strongly Typed IDs (Value Converters)
Prevent primitive obsession by using strongly typed IDs mapped with Value Converters.

```csharp
public readonly record struct AnimalId(Guid Value)
{
    public static AnimalId New() => new(Guid.NewGuid());
}

// In Configuration
builder.Property(a => a.Id)
    .HasConversion(id => id.Value, value => new AnimalId(value));
```

### 2. Value Objects via Complex Types (.NET 8/9/10)
Use `ComplexProperty` for immutable Value Objects stored inline in the same table.

```csharp
public record GeoLocation(double Latitude, doubleページLongitude);

// In Configuration
builder.ComplexProperty(r => r.Location, loc =>
{
    loc.Property(l => l.Latitude).HasColumnName("latitude").IsRequired();
    loc.Property(l => l.Longitude).HasColumnName("longitude").IsRequired();
});
```

### 3. Private Fields and Encapsulation
Map navigation properties directly to private collection backing fields to protect aggregate invariants.

```csharp
public class RescueCase
{
    private readonly List<RescueUpdate> _updates = new();
    public IReadOnlyCollection<RescueUpdate> Updates => _updates.AsReadOnly();
}

// In Configuration
builder.HasMany(r => r.Updates)
    .WithOne()
    .HasForeignKey("RescueCaseId")
    .IsRequired()
    .OnDelete(DeleteBehavior.Cascade);

builder.Metadata
    .FindNavigation(nameof(RescueCase.Updates))!
    .SetPropertyAccessMode(PropertyAccessMode.Field);
```

---

## PostgreSQL & Npgsql Specific Configurations

### 1. Spatial Data with NetTopologySuite
For geographic locations, use NetTopologySuite `Point` types mapped to PostGIS geography/geometry.

```csharp
// Configuration
builder.Property(r => r.LocationPoint)
    .HasColumnType("geography(Point, 4326)")
    .IsRequired();

// Querying with spatial distance
var nearby = await context.RescueCases
    .Where(r => r.LocationPoint.Distance(userLocation) <= radiusMeters)
    .ToListAsync(cancellationToken);
```

### 2. PostgreSQL Native Arrays and JSONB
Map native C# collections directly to PostgreSQL primitive arrays or JSONB columns.

```csharp
// PostgreSQL text[]
builder.Property(p => p.Tags)
    .HasColumnType("text[]");

// PostgreSQL jsonb
builder.Property(p => p.Metadata)
    .HasColumnType("jsonb");
```

### 3. Concurrency Tokens via PostgreSQL `xmin`
Protect against concurrent update overwrites using the PostgreSQL system `xmin` column.

```csharp
builder.UseXminAsConcurrencyToken();
```

---

## Audit Logs, Soft Deletes, and Interceptors

### 1. Global Query Filters for Soft Deletes
Always configure global query filters on entities implementing `ISoftDeletable`.

```csharp
builder.HasQueryFilter(e => !e.IsDeleted);

// If deleted records must be queried explicitly:
var allCases = await context.RescueCases.IgnoreQueryFilters().ToListAsync();
```

### 2. Auto-Populating Timestamps via `SaveChangesInterceptor`
Never set `UpdatedAt` or `CreatedAt` manually in business services. Let an EF Core interceptor handle them automatically.

```csharp
public sealed class AuditableEntityInterceptor : SaveChangesInterceptor
{
    public override ValueTask<InterceptionResult<int>> SavingChangesAsync(
        DbContextEventData eventData,
        InterceptionResult<int> result,
        CancellationToken cancellationToken = default)
    {
        var context = eventData.Context;
        if (context == null) return base.SavingChangesAsync(eventData, result, cancellationToken);

        var utcNow = DateTimeOffset.UtcNow;

        foreach (var entry in context.ChangeTracker.Entries<IAuditableEntity>())
        {
            if (entry.State == EntityState.Added)
            {
                entry.Entity.CreatedAt = utcNow;
            }
            if (entry.State == EntityState.Added || entry.State == EntityState.Modified)
            {
                entry.Entity.UpdatedAt = utcNow;
            }
        }

        return base.SavingChangesAsync(eventData, result, cancellationToken);
    }
}
```

---

## Query Performance and Best Practices

### 1. Read-Only Queries
Always use `.AsNoTracking()` for read queries to bypass change tracking overhead and reduce memory consumption.

```csharp
public async Task<List<AnimalDto>> GetAdoptableAnimalsAsync(CancellationToken ct)
{
    return await context.Animals
        .AsNoTracking()
        .Where(a => a.Status == AnimalStatus.Adoptable)
        .Select(a => new AnimalDto(a.Id.Value, a.Name, a.Species))
        .ToListAsync(ct);
}
```

### 2. Split Queries for Multiple Collections
Prevent Cartesian explosion when eager-loading multiple collections with `.AsSplitQuery()`.

```csharp
var rescueCase = await context.RescueCases
    .AsNoTracking()
    .AsSplitQuery()
    .Include(r => r.Updates)
    .Include(r => r.Media)
    .FirstOrDefaultAsync(r => r.Id == caseId, ct);
```

### 3. Pagination (Keyset / Cursor vs Offset)
Avoid large `Skip(n).Take(m)` offsets on large tables. Prefer keyset pagination using indexed fields.

```csharp
// Keyset pagination on (CreatedAt, Id)
var nextPage = await context.RescueCases
    .AsNoTracking()
    .Where(r => r.CreatedAt < lastCreatedAt || (r.CreatedAt == lastCreatedAt && r.Id < lastId))
    .OrderByDescending(r => r.CreatedAt)
    .ThenByDescending(r => r.Id)
    .Take(pageSize)
    .ToListAsync(ct);
```

### 4. Batch Operations in EF Core 7+
Use `ExecuteUpdateAsync` and `ExecuteDeleteAsync` for high-throughput bulk updates without loading entities into memory.

```csharp
await context.RescueCases
    .Where(r => r.Status == CaseStatus.Resolved && r.UpdatedAt < cutoffDate)
    .ExecuteUpdateAsync(s => s.SetProperty(b => b.IsArchived, true), ct);
```
