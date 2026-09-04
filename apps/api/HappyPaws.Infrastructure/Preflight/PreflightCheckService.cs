using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Exceptions;
using HappyPaws.Infrastructure.Data;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using StackExchange.Redis;

namespace HappyPaws.Infrastructure.Preflight;

public sealed class PreflightCheckService : IHostedLifecycleService
{
    private readonly IServiceProvider _serviceProvider;
    private readonly ILogger<PreflightCheckService> _logger;

    public PreflightCheckService(
        IServiceProvider serviceProvider,
        ILogger<PreflightCheckService> logger)
    {
        _serviceProvider = serviceProvider;
        _logger = logger;
    }

    public async Task StartingAsync(CancellationToken cancellationToken)
    {
        _logger.LogInformation("Starting infrastructure preflight checks.");

        using var scope = _serviceProvider.CreateScope();

        // 1. PostgreSQL Database Check
        try
        {
            var dbContext = scope.ServiceProvider.GetRequiredService<ApplicationDbContext>();
            var canConnect = await dbContext.Database.CanConnectAsync(cancellationToken);

            if (!canConnect)
            {
                throw new PreflightException("PostgreSQL rejected the connection attempt.");
            }

            _logger.LogInformation("PostgreSQL connectivity verified successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "Critical failure connecting to PostgreSQL.");
            throw new PreflightException("PostgreSQL preflight check failed.", ex);
        }

        // 2. Redis Cache Check
        try
        {
            var redis = scope.ServiceProvider.GetRequiredService<IConnectionMultiplexer>();
            var db = redis.GetDatabase();
            var pingLatency = await db.PingAsync();

            _logger.LogInformation("Redis cache connectivity verified successfully (latency: {LatencyMs} ms).", pingLatency.TotalMilliseconds);
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "Critical failure connecting to Redis.");
            throw new PreflightException("Redis preflight check failed.", ex);
        }

        // 3. Object Storage Check (MinIO / Cloudflare R2)
        try
        {
            var storageService = scope.ServiceProvider.GetRequiredService<IStorageService>();
            var bucketsExist = await storageService.VerifyBucketsExistAsync(cancellationToken);

            if (!bucketsExist)
            {
                throw new PreflightException("One or more required storage buckets were not found.");
            }

            _logger.LogInformation("Storage buckets (happypaws-public, happypaws-private) verified successfully.");
        }
        catch (Exception ex)
        {
            _logger.LogCritical(ex, "Critical failure verifying cloud storage buckets.");
            throw new PreflightException("Storage preflight check failed.", ex);
        }

        _logger.LogInformation("All infrastructure dependencies are healthy.");
    }

    public Task StartAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    public Task StartedAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    public Task StoppingAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    public Task StopAsync(CancellationToken cancellationToken) => Task.CompletedTask;
    public Task StoppedAsync(CancellationToken cancellationToken) => Task.CompletedTask;
}
