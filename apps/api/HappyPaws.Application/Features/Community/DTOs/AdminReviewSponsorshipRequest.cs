namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record AdminReviewSponsorshipRequest(
    bool Approved,
    string? RejectionNotes
);
