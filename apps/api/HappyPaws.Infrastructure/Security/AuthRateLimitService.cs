using System;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using StackExchange.Redis;

namespace HappyPaws.Infrastructure.Security;

public class AuthRateLimitService : IAuthRateLimitService
{
    private readonly IDatabase _db;
    private const int MaxFailedAttempts = 5;
    private readonly TimeSpan LockoutDuration = TimeSpan.FromMinutes(15);

    public AuthRateLimitService(IConnectionMultiplexer multiplexer)
    {
        _db = multiplexer.GetDatabase();
    }

    public async Task<bool> IsLockedOutAsync(string ipAddress, string email)
    {
        var ipKey = $"lockout:ip:{ipAddress}";
        var emailKey = $"lockout:email:{email.ToLowerInvariant()}";

        var ipCount = (int?)await _db.StringGetAsync(ipKey) ?? 0;
        var emailCount = (int?)await _db.StringGetAsync(emailKey) ?? 0;

        return ipCount >= MaxFailedAttempts || emailCount >= MaxFailedAttempts;
    }

    public async Task<TimeSpan?> GetLockoutRemainingAsync(string ipAddress, string email)
    {
        var ipKey = $"lockout:ip:{ipAddress}";
        var emailKey = $"lockout:email:{email.ToLowerInvariant()}";

        var ipCount = (int?)await _db.StringGetAsync(ipKey) ?? 0;
        var emailCount = (int?)await _db.StringGetAsync(emailKey) ?? 0;

        if (ipCount >= MaxFailedAttempts)
        {
            return await _db.KeyTimeToLiveAsync(ipKey);
        }

        if (emailCount >= MaxFailedAttempts)
        {
            return await _db.KeyTimeToLiveAsync(emailKey);
        }

        return null;
    }

    public async Task RecordFailureAsync(string ipAddress, string email)
    {
        var ipKey = $"lockout:ip:{ipAddress}";
        var emailKey = $"lockout:email:{email.ToLowerInvariant()}";

        await _db.StringIncrementAsync(ipKey);
        await _db.KeyExpireAsync(ipKey, LockoutDuration);

        await _db.StringIncrementAsync(emailKey);
        await _db.KeyExpireAsync(emailKey, LockoutDuration);
    }

    public async Task ClearFailuresAsync(string ipAddress, string email)
    {
        var ipKey = $"lockout:ip:{ipAddress}";
        var emailKey = $"lockout:email:{email.ToLowerInvariant()}";

        await _db.KeyDeleteAsync(new RedisKey[] { ipKey, emailKey });
    }
}
