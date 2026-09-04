using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record CreatePostRequest(
    string Type,
    string Title,
    string Body,
    double? Latitude,
    double? Longitude,
    string? LocationLabel,
    string? AnimalSpecies,
    string? AnimalName,
    string? AnimalDescription,
    Guid? ParentPostId,
    string? VetReasonForVisit,
    string? VetClinicName,
    DateTimeOffset? VetAppointmentDate,
    bool? VetTransportNeeded,
    string? SponsorshipGoalDescription,
    decimal? SponsorshipEstimatedAmountLkr
);
