# API documentation standard

This guide explains how we document .NET 10 Minimal API endpoints in the Happy Paws repository. Our goal is to build a flawless Scalar UI and a rich OpenAPI specification. We achieve this by combining route extensions for endpoints and XML comments for data models.

## Minimal API route extensions

Use endpoint metadata instead of XML comments on route handlers. Fluent extensions keep route metadata strongly typed, visible, and attached directly to the endpoint configuration.

- `.WithSummary("...")`: Write a short, single-sentence title displayed in navigation lists.
- `.WithDescription("...")`: Add a detailed explanation of the endpoint behavior, side effects, and permissions.
- `.WithTags("GroupName")`: Group related endpoints in the Scalar sidebar to make the API easier to navigate.
- `.Produces<T>(StatusCodes.Status200OK)`: Define the exact JSON response schema and the data transfer object returned on success.
- `.ProducesValidationProblem()`: Map standard validation errors cleanly so clients know what to expect when a request fails validation.
- `.RequireAuthorization()`: Indicate that the route requires a valid authentication token. This also adds a security padlock icon next to the endpoint in the UI.

## XML documentation comments

XML comments work best on data transfer objects, models, and shared properties. They provide rich editor tooltips and accurate schema descriptions for UI tools like Scalar. Use these tags to give developers the context they need.

- `<summary>`: Write a short, single-sentence description of the model or property.
- `<remarks>`: Add a detailed explanation, business logic, or usage context. Markdown formatting is supported here.
- `<example>`: Provide a realistic example value that Scalar can display in the API payload examples.

## C# logic and inline comments

When adding inline comments or XML documentation to C# logic, follow the rules defined in our API coding style guide.

- **Focus on the why**: Explain why the code exists, not what it does. Clarify complex domain rules, performance trade-offs, and security choices. Omit comments that translate readable code into words.
- **Tone and formatting**: Write in plain, direct language. Use sentence case for headings and titles. Use the Oxford comma in all lists.
- **Punctuation**: Do not use em dashes. Use commas, parentheses, or separate sentences instead. Do not use semicolons.
- **Word choice**: Avoid filler words like "utilize", "leverage", "ensure", and "streamline".

## Example scenarios

Use these examples as blueprints when documenting your code.

### Documenting a Minimal API route

This example shows how to chain route extensions on an endpoint and includes an inline comment focusing on the "why".

```csharp
var group = app.MapGroup("/api/v1/rescues")
    .WithTags("Rescue Operations")
    .RequireAuthorization();

group.MapPost("/", ReportRescueAsync)
    .WithName("ReportRescue")
    .WithSummary("Report a new animal rescue emergency")
    .WithDescription("Creates a new emergency rescue case, triggers automated AI severity triage, and alerts nearby responders.")
    .Produces<RescueCaseResponse>(StatusCodes.Status201Created)
    .ProducesValidationProblem()
    .ProducesProblem(StatusCodes.Status401Unauthorized);

// ... inside the route handler:

// Default to a moderate urgency if the AI triage fails or encounters rate limits.
// This fallback guarantees that medical responders still inspect the case during upstream API outages.
var urgencyLevel = UrgencyLevel.Moderate;
```

### Documenting a data transfer object

This example shows how to use XML comments on a record property so Scalar can generate accurate schemas.

```csharp
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
    /// Base64-encoded incident photo used for public records and automated AI vision triage.
    /// </summary>
    public required string PhotoBase64 { get; init; }
}
```
