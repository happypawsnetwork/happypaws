using HappyPaws.Application.Interfaces;
using HappyPaws.Infrastructure.Data;
using HappyPaws.Infrastructure.Data.Interceptors;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace HappyPaws.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructureServices(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = configuration.GetConnectionString("Redis") + ",abortConnect=false";
        });

        // Register IConnectionMultiplexer lazily for atomic operations
        services.AddSingleton<StackExchange.Redis.IConnectionMultiplexer>(sp =>
            StackExchange.Redis.ConnectionMultiplexer.Connect((configuration.GetConnectionString("Redis") ?? "localhost:6379") + ",abortConnect=false"));

        // Register our custom rate limit service
        services.AddScoped<IAuthRateLimitService, Security.AuthRateLimitService>();
        services.AddScoped<AuditableEntityInterceptor>();

        services.AddDbContext<ApplicationDbContext>((sp, options) =>
        {
            options.UseNpgsql(configuration.GetConnectionString("DefaultConnection"), o => o.UseNetTopologySuite());
            options.AddInterceptors(sp.GetRequiredService<AuditableEntityInterceptor>());
            options.ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
        });

        services.AddScoped<IApplicationDbContext>(provider => provider.GetRequiredService<ApplicationDbContext>());

        // Register Email Options
        services.Configure<Emails.Options.EmailOptions>(configuration.GetSection(Emails.Options.EmailOptions.SectionName));
        services.Configure<Emails.Options.SystemOptions>(configuration.GetSection(Emails.Options.SystemOptions.SectionName));

        // Register Email Service
        services.AddHttpClient<IEmailService, Emails.Services.FluidEmailService>();

        // Register Auth
        services.Configure<Authentication.JwtOptions>(configuration.GetSection(Authentication.JwtOptions.SectionName));
        services.AddScoped<ITokenService, Authentication.TokenService>();

        // Register Storage (MinIO / Cloudflare R2)
        services.Configure<Storage.Options.StorageOptions>(configuration.GetSection(Storage.Options.StorageOptions.SectionName));
        services.AddSingleton<Amazon.S3.IAmazonS3>(sp =>
        {
            var options = sp.GetRequiredService<Microsoft.Extensions.Options.IOptions<Storage.Options.StorageOptions>>().Value;
            var config = new Amazon.S3.AmazonS3Config
            {
                ServiceURL = options.ServiceUrl,
                ForcePathStyle = options.ForcePathStyle,
                UseHttp = options.ServiceUrl?.StartsWith("http://", StringComparison.OrdinalIgnoreCase) ?? false
            };

            var credentials = new Amazon.Runtime.BasicAWSCredentials(options.AccessKey, options.SecretKey);
            return new Amazon.S3.AmazonS3Client(credentials, config);
        });
        services.AddScoped<IStorageService, Storage.Services.StorageService>();

        // Register Gemini Triage Service
        services.AddHttpClient("gemini");
        services.AddScoped<IGeminiTriageService, Services.GeminiTriageService>();

        // Register Reputation Service
        services.AddScoped<IReputationService, Services.ReputationService>();

        // Register Infrastructure Preflight Checks
        services.AddScoped<IAdminPostQueryService, Services.AdminPostQueryService>();
        services.AddHostedService<Preflight.PreflightCheckService>();

        return services;
    }
}
