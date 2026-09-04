using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Application.Interfaces;

public interface IReputationService
{
    Task AwardPointsAsync(long userId, int points, CancellationToken cancellationToken = default);
    Task AwardBadgeAsync(long userId, BadgeType badgeType, CancellationToken cancellationToken = default);

    Task ProcessAdoptionAcceptedAsync(long userId, Guid animalId, CancellationToken cancellationToken = default);
    Task ProcessFosterPlacementCreatedAsync(long userId, Guid animalId, CancellationToken cancellationToken = default);
    Task ProcessFosterPlacementCompletedAsync(long userId, CancellationToken cancellationToken = default);
    Task ProcessTransportDeliveredAsync(long userId, Guid rescueCaseId, CancellationToken cancellationToken = default);
    Task ProcessSponsorshipFulfilledAsync(long userId, Guid rescueCaseId, CancellationToken cancellationToken = default);
    Task ProcessPostCreatedAsync(long userId, PostType postType, CancellationToken cancellationToken = default);
    Task ProcessPostLikedAsync(long postAuthorId, Guid postId, CancellationToken cancellationToken = default);
}
