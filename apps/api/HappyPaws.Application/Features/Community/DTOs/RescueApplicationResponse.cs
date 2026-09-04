using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record RescueApplicationResponse(
    Guid Id,
    Guid RescuePostId,
    long ApplicantId,
    string ApplicantDisplayName,
    string? ApplicantAvatarUrl,
    string ApplicantRole,
    string? Message,
    string? ExperienceSummary,
    bool HasVehicle,
    string Status,
    DateTimeOffset CreatedAt
);
