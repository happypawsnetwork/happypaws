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
});

var configuredOrigins = builder.Configuration.GetValue<string>("Cors:AllowedOrigins");
var allowedOrigins = !string.IsNullOrWhiteSpace(configuredOrigins)
    ? configuredOrigins.Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
    : (builder.Environment.IsDevelopment() ? new[] { "http://localhost:3000" } : Array.Empty<string>());

builder.Services.AddCors(options =>
{
    options.AddDefaultPolicy(policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins)
                  .AllowAnyHeader()
                  .AllowAnyMethod()
                  .AllowCredentials();
        }
        else
        {
            policy.AllowAnyOrigin()
                  .AllowAnyHeader()
                  .AllowAnyMethod();
        }
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

await app.ApplyMigrationsAndSeedAsync();

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
