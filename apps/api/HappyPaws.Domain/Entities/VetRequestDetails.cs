using System;

namespace HappyPaws.Domain.Entities;

public class VetRequestDetails
{
    public Guid PostId { get; set; }
    public string ReasonForVisit { get; set; } = null!;
    public string? ClinicName { get; set; }
    public DateTimeOffset? AppointmentDate { get; set; }
    public bool TransportNeeded { get; set; } = false;

    public Post Post { get; set; } = null!;
}
