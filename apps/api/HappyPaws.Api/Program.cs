using System;
using DotNetEnv;
using HappyPaws.Api.Extensions;
using HappyPaws.Application;
using Microsoft.AspNetCore.RateLimiting;
using HappyPaws.Infrastructure;
using Scalar.AspNetCore;

// Load .env file (if it exists) before builder creation
Env.Load();

var builder = WebApplication.CreateBuilder(args);

builder.Services.AddApplicationServices();
builder.Services.AddInfrastructureServices(builder.Configuration);
builder.Services.AddHappyPawsAuthentication(builder.Configuration);
builder.Services.AddSignalR(options =>
{
    options.EnableDetailedErrors = true;
})
.AddJsonProtocol(options =>
{
    options.PayloadSerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
});

builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("GlobalPolicy", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 100;
        opt.QueueProcessingOrder = System.Threading.RateLimiting.QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 2;
    });

    options.AddFixedWindowLimiter("AuthPolicy", opt =>
    {
        opt.Window = TimeSpan.FromMinutes(1);
        opt.PermitLimit = 10;
        opt.QueueProcessingOrder = System.Threading.RateLimiting.QueueProcessingOrder.OldestFirst;
        opt.QueueLimit = 0;
    });
});

var configuredOrigins = builder.Configuration.GetValue<string>("Cors:AllowedOrigins");

string[] allowedOrigins;
if (!string.IsNullOrWhiteSpace(configuredOrigins))
{
    allowedOrigins = configuredOrigins.Split(
        ',',
        StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
}
else if (builder.Environment.IsDevelopment())
{
    allowedOrigins = ["http://localhost:3000"];
}
else
{
    throw new InvalidOperationException(
        "Cors:AllowedOrigins must be configured in non-development environments. " +
        "Set it as a comma-separated list of allowed origins.");
}

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod()
              .AllowCredentials();
    });
});

// Add services to the container.
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();
builder.Services.AddHealthChecks();

builder.Services.ConfigureHttpJsonOptions(options =>
{
    options.SerializerOptions.Converters.Add(new System.Text.Json.Serialization.JsonStringEnumConverter());
});

var app = builder.Build();

// Avoid database migrations and admin account seeding during design-time tooling or build-time OpenAPI document generation
var isDocumentGeneration = System.Reflection.Assembly.GetEntryAssembly()?.GetName().Name == "GetDocument.Insider"
    || Microsoft.EntityFrameworkCore.EF.IsDesignTime;

if (!isDocumentGeneration)
{
    await app.ApplyMigrationsAndSeedAsync();
}

var enableApiDocs = builder.Configuration.GetValue<bool>("ENABLE_API_DOCS");
if (enableApiDocs)
{
    app.MapOpenApi();
    app.MapScalarApiReference();

    // Redirect root to scalar documentation when API documentation is enabled
    app.MapGet("/", () => Results.Redirect("/scalar/v1"))
       .ExcludeFromDescription();
}

app.UseHttpsRedirection();

app.UseCors();
app.UseRateLimiter();

app.UseAuthentication();
app.UseAuthorization();

app.MapHub<HappyPaws.Api.Hubs.ChatHub>("/chatHub");
app.MapEndpoints();

var healthCheckOptions = new Microsoft.AspNetCore.Diagnostics.HealthChecks.HealthCheckOptions
{
    ResponseWriter = async (context, _) =>
    {
        context.Response.ContentType = "text/plain";
        await context.Response.WriteAsync("api.happypaws.lk is up and wagging its tail! Ready to connect paws with loving homes.");
    }
};
app.MapHealthChecks("/health", healthCheckOptions);
app.MapHealthChecks("/healthz", healthCheckOptions);

app.Run();
