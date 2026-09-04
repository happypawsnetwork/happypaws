using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record CreateTransportTaskRequest(
    Guid ParentPostId,
    string PickupAddress,
    double PickupLatitude,
    double PickupLongitude,
    string DropoffAddress,
    double DropoffLatitude,
    double DropoffLongitude,
    bool IsSelfCollection,
    string? Notes
);
