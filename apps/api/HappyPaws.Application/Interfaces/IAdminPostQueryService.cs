using HappyPaws.Application.Features.Community.Queries;

namespace HappyPaws.Application.Interfaces;

public interface IAdminPostQueryService
{
    Task<IReadOnlyList<AdminPostResponse>> GetAdminPostsAsync(
        string? type,
        string? status,
        string? search,
        bool includeDeleted,
        CancellationToken ct);
}
