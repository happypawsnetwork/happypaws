using System;
using System.Collections.Generic;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record TransportTaskResponse(
    Guid Id,
    Guid? TransportPostId,
    Guid ParentPostId,
    string ParentPostTitle,
    long RequesterId,
    string RequesterDisplayName,
    long? TransporterId,
    string? TransporterDisplayName,
    string PickupAddress,
    double PickupLatitude,
    double PickupLongitude,
    string DropoffAddress,
    double DropoffLatitude,
    double DropoffLongitude,
    DateTimeOffset? PickupWindowStart,
    DateTimeOffset? PickupWindowEnd,
    bool IsSelfCollection,
    string Status,
    DateTimeOffset? CompletedAt,
    string? Notes,
    IReadOnlyList<TransportOfferResponse> Offers,
    DateTimeOffset CreatedAt
);
