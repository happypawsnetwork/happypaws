using System;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class TransportOffer
{
    public Guid Id { get; set; }
    public Guid TransportTaskId { get; set; }
    public long TransporterId { get; set; }
    public string? Message { get; set; }
    public DateTimeOffset ProposedPickupStart { get; set; }
    public DateTimeOffset ProposedPickupEnd { get; set; }
    public TransportOfferStatus Status { get; set; } = TransportOfferStatus.Pending;
    public DateTimeOffset CreatedAt { get; set; }

    public TransportTask Task { get; set; } = null!;
    public User Transporter { get; set; } = null!;
}
