using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record TransportOfferResponse(
    Guid Id,
    Guid TransportTaskId,
    long TransporterId,
    string TransporterDisplayName,
    string? TransporterAvatarUrl,
    string? Message,
    DateTimeOffset ProposedPickupStart,
    DateTimeOffset ProposedPickupEnd,
    string Status,
    DateTimeOffset CreatedAt
);
