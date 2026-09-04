using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record SubmitTransportOfferRequest(
    string? Message,
    DateTimeOffset ProposedPickupStart,
    DateTimeOffset ProposedPickupEnd
);
