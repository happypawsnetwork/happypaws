using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record VetRequestDetailsResponse(
    string ReasonForVisit,
    string? ClinicName,
    DateTimeOffset? AppointmentDate,
    bool TransportNeeded
);
