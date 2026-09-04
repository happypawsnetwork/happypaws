using System.Threading.Tasks;

namespace HappyPaws.Application.Interfaces;

public interface IAuthRateLimitService
{
    Task<bool> IsLockedOutAsync(string ipAddress, string email);
    Task<TimeSpan?> GetLockoutRemainingAsync(string ipAddress, string email);
    Task RecordFailureAsync(string ipAddress, string email);
    Task ClearFailuresAsync(string ipAddress, string email);
}
