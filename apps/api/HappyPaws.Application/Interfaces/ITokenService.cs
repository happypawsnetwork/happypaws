using HappyPaws.Domain.Entities;

namespace HappyPaws.Application.Interfaces;

public interface ITokenService
{
    (string AccessToken, string RefreshToken) GenerateTokens(User user);
    string HashToken(string token);
}
