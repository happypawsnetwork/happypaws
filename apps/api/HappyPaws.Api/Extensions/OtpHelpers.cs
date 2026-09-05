using System.Security.Cryptography;
using System.Text;

namespace HappyPaws.Api.Extensions;

internal static class OtpHelpers
{
    /// <summary>
    /// Generates a cryptographically secure 6-digit OTP.
    /// </summary>
    internal static string Generate() =>
        RandomNumberGenerator.GetInt32(100000, 1000000).ToString();

    /// <summary>
    /// Compares two OTP strings in constant time to prevent timing attacks.
    /// </summary>
    internal static bool ConstantTimeEquals(string a, string b)
    {
        var bytesA = Encoding.UTF8.GetBytes(a);
        var bytesB = Encoding.UTF8.GetBytes(b);
        return CryptographicOperations.FixedTimeEquals(bytesA, bytesB);
    }
}
