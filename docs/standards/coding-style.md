# API coding style (.NET 10 and ASP.NET Core)

These rules apply to all C# code written for `happypaws-api` (`apps/api/`). Following them maintains consistency, high quality, and readability across the backend platform.

## Architecture and dependencies

Keep dependencies pointing inward according to Clean Architecture principles.
- **Domain**: Contains enterprise entities, value objects, domain events, and repository interfaces with zero external framework dependencies.
- **Application**: Houses business logic, CQRS command and query handlers, DTOs, and abstract service interfaces (such as `IStorageService`, `IEmailSender`, and `IAiTriageService`).
- **Infrastructure**: Implements interfaces defined in Domain and Application. Handles EF Core PostgreSQL access, Redis caching, MinIO and Cloudflare R2 object storage, and external HTTP clients for Gemini and Resend.
- **Api**: The presentation and entry layer. Configures dependency injection, registers middleware, maps Minimal API route groups, and hosts SignalR communication hubs.

Wrap third-party services behind interfaces. This practice speeds up unit testing with mocks and allows switching providers (such as moving from MinIO in development to Cloudflare R2 in production) without changing business logic.

Keep state scoped to the request lifecycle. Do not use static mutable fields or global singletons to hold state.

## Minimal API patterns

Minimal APIs are the repository standard. Do not use MVC controllers.

Group related endpoints together using `MapGroup` inside dedicated files under `Features/`. We use a Vertical Slice architecture, meaning everything related to a specific feature (Endpoints, DTOs, Handlers) should live together in its feature folder (e.g., `Features/Auth/`). Every endpoint group must implement the `IEndpointGroup` interface. Use a single extension method call in `Program.cs` to discover and register all endpoint groups automatically using assembly scanning. Do not scatter individual route mappings in `Program.cs`.

Always use `TypedResults` for responses. For example, return `TypedResults.Ok(value)` or `TypedResults.Created(uri, value)` instead of `Results.Ok(value)`. Returning strongly typed results preserves response type metadata at compile time, which enables the OpenAPI generator to produce complete schemas for Scalar without manual attribute clutter.

Use endpoint metadata instead of XML comments on route handlers. Chain fluent methods like `.WithName()`, `.WithTags()`, `.WithSummary()`, and `.WithDescription()` directly on the route builder.

## OpenAPI and Scalar documentation

The API generates native OpenAPI documents through `Microsoft.AspNetCore.OpenApi` and visualizes them using Scalar at `/scalar/v1`.

- Always set `.WithName()` to provide a stable, unique `operationId` for client SDK generation.
- Use `.WithSummary()` for short one-line titles displayed in navigation lists.
- Use `.WithDescription()` to document detailed behavior, side effects, and required permissions.
- Document expected error responses explicitly using `.ProducesProblem(StatusCodes.Status400BadRequest)` and `.ProducesProblem(StatusCodes.Status404NotFound)` when not using union `Results<T1, T2>` return types.
- Add standard XML documentation (`/// <summary>`) to all public request and response DTO records and properties. Scalar reads these XML comments to generate schema tables and field descriptions automatically.

## C# naming conventions

- Use PascalCase for class names, record names, interfaces (prefixed with `I`), method names, public properties, and enum values.
- Use camelCase for method parameters and local variables.
- Prefix private instance fields with an underscore and use camelCase (for example, `_dbContext` or `_storageService`).
- Suffix all asynchronous method names with `Async` (for example, `GetRescueCaseByIdAsync`).
- Name command and query records using clear intent (such as `CreateRescueCaseCommand` or `GetAnimalsByLocationQuery`).

## Error handling and validation

Allow unhandled exceptions to bubble up to the global exception handler middleware. The middleware catches them, logs the error details, and formats the response as an RFC 7807 `ProblemDetails` object. Do not catch exceptions in endpoints solely to log and rethrow them.

Validate incoming request DTOs with FluentValidation before execution reaches application services or domain logic. Register a global endpoint filter for FluentValidation to intercept invalid payloads and return HTTP 400 validation problem responses automatically.

Guard against null or invalid arguments at method entry points using modern guards like `ArgumentNullException.ThrowIfNull(param)` and `ArgumentException.ThrowIfNullOrWhiteSpace(param)`.

## Entity Framework Core and data access

Configure the database connection string as a single standard PostgreSQL connection string in the `ConnectionStrings` section (`ConnectionStrings__DefaultConnection` in `.env`). Do not introduce separate host, port, user, or password variables. Npgsql handles this format natively.

Write entity configurations in separate classes implementing `IEntityTypeConfiguration<T>`. Keep `OnModelCreating` clean by calling `modelBuilder.ApplyConfigurationsFromAssembly(typeof(AppDbContext).Assembly)`.

Apply `.AsNoTracking()` to all queries that only read data. This avoids tracking overhead, saves memory, and speeds up execution.

Map entities to dedicated response DTOs before returning data to the client. Never expose raw EF Core entity models directly through API endpoints.

Use NetTopologySuite `Point` geometry types for geographical coordinates to take advantage of PostGIS spatial indexes and functions like `ST_DWithin`.

## Security and privacy

Never log passwords, JWT secret keys, identity document file keys, or personally identifiable information (PII). Redact sensitive parameters before writing to logs.

To make debugging and log filtering extremely easy, **all log messages must be prefixed with their feature domain in brackets**. Do not write generic logs. Use structured logging templates for variable data.
- Good: `_logger.LogInformation("[Authentication] User {Email} successfully logged in", email)`
- Good: `_logger.LogWarning("[Rescues] Failed to triage rescue case {CaseId} due to AI timeout", caseId)`
- Bad: `_logger.LogInformation("User logged in")`

Enforce role-based access control by applying `.RequireAuthorization(new AuthorizeAttribute { Roles = "..." })` on endpoint groups or individual sensitive routes.

Keep identity verification documents (KYC) and veterinary licenses strictly in the private storage bucket (`happypaws-private`). Generate short-lived presigned URLs (valid for 5 to 15 minutes) only after authenticating and verifying the user role. Store public animal listing photos in the public bucket (`happypaws-public`) and serve them through CDN URLs.

## Documentation and comments

Explain why the code exists, not what it does. Write comments that clarify complex domain rules, performance trade-offs, and security choices. Omit comments that merely translate readable code into words.

When writing comments, XML documentation, or OpenAPI descriptions, adhere to the following rules:
- Write in plain, direct language.
- Do not use em dashes. Use commas, parentheses, or separate sentences instead.
- Do not use semicolons in documentation or explanatory text.
- Use the Oxford comma in all lists.
- Use sentence case for headings and titles.
- Avoid filler words like "utilize", "leverage", "ensure", and "streamline".

## Testing and dependency injection

Register services with explicit lifetimes (`Scoped`, `Transient`, or `Singleton`) in dependency injection extensions.
- Use `Scoped` for services that depend on `DbContext` or manage request-bound data.
- Use `Singleton` for stateless utilities, thread-safe caches, or expensive client instances.
- Use `Transient` for lightweight, stateless helper operations.

Follow the Single Responsibility Principle. Methods must stay compact and focused on a single task.

Inject dependencies exclusively through constructors. Avoid service locator anti-patterns (`IServiceProvider.GetService`) to maintain testability with xUnit and Moq.

---

## Example scenarios

Use these code snippets as blueprints when writing or refactoring backend components.

### 1. Minimal API endpoint group with OpenAPI metadata

This scenario shows a rescue reporting endpoint. It demonstrates route group registration, FluentValidation integration, strongly typed results, role-based authorization, and Scalar OpenAPI metadata.

```csharp
using System.Security.Claims;
using FluentValidation;
using HappyPaws.Application.Features.Rescues.Commands;
using HappyPaws.Application.Features.Rescues.DTOs;
using HappyPaws.Application.Interfaces;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Http.HttpResults;
using Microsoft.AspNetCore.Routing;

namespace HappyPaws.Api.Features.Rescues;

public sealed class RescueEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/rescues")
            .WithTags("Rescue Operations")
            .RequireAuthorization(); // Requires a valid JWT for all rescue actions

        group.MapPost("/", ReportRescueAsync)
            .WithName("ReportRescue")
            .WithSummary("Report a new animal rescue emergency")
            .WithDescription("Creates a new emergency rescue case, uploads incident media, triggers automated AI severity triage, and alerts nearby responders.")
            .ProducesProblem(StatusCodes.Status400BadRequest)
            .ProducesProblem(StatusCodes.Status401Unauthorized);

        group.MapGet("/{id:guid}", GetRescueByIdAsync)
            .WithName("GetRescueById")
            .WithSummary("Get rescue case details by identifier")
            .WithDescription("Retrieves the full status, location, AI triage score, and assigned volunteers for an active or completed rescue case.");
    }

    private static async Task<Results<Created<RescueCaseResponse>, BadRequest<ProblemDetails>, UnauthorizedHttpResult>> ReportRescueAsync(
        ReportRescueRequest request,
        ClaimsPrincipal user,
        IValidator<ReportRescueRequest> validator,
        IRescueService rescueService,
        CancellationToken cancellationToken)
    {
        var userId = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrWhiteSpace(userId))
        {
            return TypedResults.Unauthorized();
        }

        var validationResult = await validator.ValidateAsync(request, cancellationToken);
        if (!validationResult.IsValid)
        {
            return TypedResults.BadRequest(new ProblemDetails
            {
                Title = "Validation Failed",
                Detail = "One or more input fields are invalid.",
                Status = StatusCodes.Status400BadRequest,
                Extensions = { ["errors"] = validationResult.ToDictionary() }
            });
        }

        var command = new CreateRescueCaseCommand(
            ReporterId: userId,
            Description: request.Description,
            Latitude: request.Latitude,
            Longitude: request.Longitude,
            PhotoBase64: request.PhotoBase64,
            ReportedAnimalType: request.AnimalType);

        var response = await rescueService.CreateRescueCaseAsync(command, cancellationToken);

        return TypedResults.Created($"/api/v1/rescues/{response.Id}", response);
    }

    private static async Task<Results<Ok<RescueCaseResponse>, NotFound>> GetRescueByIdAsync(
        Guid id,
        IRescueService rescueService,
        CancellationToken cancellationToken)
    {
        var rescue = await rescueService.GetByIdAsync(id, cancellationToken);
        if (rescue is null)
        {
            return TypedResults.NotFound();
        }

        return TypedResults.Ok(rescue);
    }
}
```

### 2. Request and response DTOs with XML documentation

Scalar extracts XML documentation directly to build descriptive API schemas. Add clear comments to all properties.

```csharp
namespace HappyPaws.Application.Features.Rescues.DTOs;

/// <summary>
/// Payload submitted by field reporters to initiate an animal rescue case.
/// </summary>
public sealed record ReportRescueRequest
{
    /// <summary>
    /// Detailed text describing the animal condition, immediate hazards, and visible injuries.
    /// </summary>
    /// <example>Found an injured puppy on the side of Galle Road with a fractured hind leg.</example>
    public required string Description { get; init; }

    /// <summary>
    /// Category of animal observed at the scene.
    /// </summary>
    /// <example>Dog</example>
    public required string AnimalType { get; init; }

    /// <summary>
    /// GPS latitude coordinate collected from device location services.
    /// </summary>
    /// <example>6.9271</example>
    public required double Latitude { get; init; }

    /// <summary>
    /// GPS longitude coordinate collected from device location services.
    /// </summary>
    /// <example>79.8612</example>
    public required double Longitude { get; init; }

    /// <summary>
    /// Base64-encoded incident photo used for public records and automated AI vision triage.
    /// </summary>
    public required string PhotoBase64 { get; init; }
}

/// <summary>
/// Public information representing a recorded rescue operation.
/// </summary>
public sealed record RescueCaseResponse(
    Guid Id,
    string Description,
    string AnimalType,
    string Status,
    string UrgencyLevel,
    string PhotoUrl,
    double Latitude,
    double Longitude,
    DateTime CreatedAtUtc);
```

### 3. Business logic service with descriptive comments

This service demonstrates constructor injection, external service integration, and comments that explain the rationale behind business rules and edge cases.

```csharp
using HappyPaws.Application.Features.Rescues.Commands;
using HappyPaws.Application.Features.Rescues.DTOs;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using NetTopologySuite.Geometries;

namespace HappyPaws.Infrastructure.Services;

public sealed class RescueService : IRescueService
{
    private readonly IAppDbContext _dbContext;
    private readonly IStorageService _storageService;
    private readonly IAiTriageService _aiTriageService;
    private readonly INotificationService _notificationService;
    private readonly ILogger<RescueService> _logger;
    private readonly GeometryFactory _geometryFactory;

    public RescueService(
        IAppDbContext dbContext,
        IStorageService storageService,
        IAiTriageService aiTriageService,
        INotificationService notificationService,
        ILogger<RescueService> logger)
    {
        _dbContext = dbContext;
        _storageService = storageService;
        _aiTriageService = aiTriageService;
        _notificationService = notificationService;
        _logger = logger;
        
        // PostGIS uses spatial reference identifier 4326 for standard GPS latitude and longitude coordinates
        _geometryFactory = new GeometryFactory(new PrecisionModel(), 4326);
    }

    public async Task<RescueCaseResponse> CreateRescueCaseAsync(
        CreateRescueCaseCommand command, 
        CancellationToken cancellationToken)
    {
        ArgumentNullException.ThrowIfNull(command);

        // Upload incident photo to the public bucket first so the AI triage service and mobile apps can access the image URL
        var photoBytes = Convert.FromBase64String(command.PhotoBase64);
        var photoKey = $"rescues/{Guid.NewGuid():N}.jpg";
        var publicPhotoUrl = await _storageService.UploadPublicFileAsync(photoKey, photoBytes, "image/jpeg", cancellationToken);

        // Default to Moderate urgency if AI triage fails or encounters rate limits
        // This fallback guarantees that medical responders still inspect the case even during upstream API outages
        var urgencyLevel = UrgencyLevel.Moderate;
        try
        {
            urgencyLevel = await _aiTriageService.ClassifyUrgencyAsync(publicPhotoUrl, command.Description, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "Automated AI triage failed for rescue report. Falling back to Moderate severity.");
        }

        // Longitude represents the X coordinate and Latitude represents the Y coordinate in NetTopologySuite
        var location = _geometryFactory.CreatePoint(new Coordinate(command.Longitude, command.Latitude));

        var rescueCase = new RescueCase
        {
            Id = Guid.NewGuid(),
            ReporterId = command.ReporterId,
            Description = command.Description,
            AnimalType = command.ReportedAnimalType,
            Status = RescueStatus.Reported,
            UrgencyLevel = urgencyLevel,
            PhotoUrl = publicPhotoUrl,
            Location = location,
            CreatedAtUtc = DateTime.UtcNow
        };

        _dbContext.RescueCases.Add(rescueCase);
        await _dbContext.SaveChangesAsync(cancellationToken);

        // Dispatch geo-targeted push alerts to volunteers registered within a 15 km radius
        await _notificationService.BroadcastNearbyRescueAlertAsync(rescueCase.Id, command.Latitude, command.Longitude, urgencyLevel, cancellationToken);

        return new RescueCaseResponse(
            rescueCase.Id,
            rescueCase.Description,
            rescueCase.AnimalType,
            rescueCase.Status.ToString(),
            rescueCase.UrgencyLevel.ToString(),
            rescueCase.PhotoUrl,
            command.Latitude,
            command.Longitude,
            rescueCase.CreatedAtUtc);
    }

    public async Task<RescueCaseResponse?> GetByIdAsync(Guid id, CancellationToken cancellationToken)
    {
        // AsNoTracking avoids tracking overhead for read-only lookups
        return await _dbContext.RescueCases
            .AsNoTracking()
            .Where(r => r.Id == id)
            .Select(r => new RescueCaseResponse(
                r.Id,
                r.Description,
                r.AnimalType,
                r.Status.ToString(),
                r.UrgencyLevel.ToString(),
                r.PhotoUrl,
                r.Location.Y,
                r.Location.X,
                r.CreatedAtUtc))
            .FirstOrDefaultAsync(cancellationToken);
    }
}
```

### 4. Entity Framework Core configuration with spatial data

This example configures table mappings, enum string conversions, and PostGIS indexes using a clean configuration class.

```csharp
using HappyPaws.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace HappyPaws.Infrastructure.Data.Configurations;

public sealed class RescueCaseConfiguration : IEntityTypeConfiguration<RescueCase>
{
    public void Configure(EntityTypeBuilder<RescueCase> builder)
    {
        builder.ToTable("RescueCases");

        builder.HasKey(r => r.Id);

        builder.Property(r => r.Description)
            .IsRequired()
            .HasMaxLength(2000);

        builder.Property(r => r.AnimalType)
            .IsRequired()
            .HasMaxLength(100);

        // Storing enums as strings preserves database readability when queried by external business intelligence tools
        builder.Property(r => r.Status)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.UrgencyLevel)
            .HasConversion<string>()
            .HasMaxLength(50)
            .IsRequired();

        builder.Property(r => r.PhotoUrl)
            .IsRequired()
            .HasMaxLength(1000);

        // PostGIS point mapping with standard WGS84 coordinate reference system
        builder.Property(r => r.Location)
            .HasColumnType("geometry(Point, 4326)")
            .IsRequired();

        // Create spatial index for fast ST_DWithin radius searches across rescue coordinates
        builder.HasIndex(r => r.Location)
            .HasMethod("GIST");

        builder.Property(r => r.CreatedAtUtc)
            .IsRequired();
    }
}
```
