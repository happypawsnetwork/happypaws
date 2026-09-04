using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record SponsorshipDetailsResponse(
    string GoalDescription,
    decimal? EstimatedAmountLkr,
    string? AdminRejectionNotes,
    DateTimeOffset? FundedAt,
    int ProofDocumentCount
);
