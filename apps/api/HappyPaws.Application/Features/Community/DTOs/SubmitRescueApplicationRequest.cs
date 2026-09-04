namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record SubmitRescueApplicationRequest(
    string ApplicantRole,
    string? Message,
    string? ExperienceSummary,
    bool HasVehicle
);
