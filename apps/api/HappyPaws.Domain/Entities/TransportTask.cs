using System;
using System.Collections.Generic;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class TransportTask : IAuditableEntity
{
    public Guid Id { get; set; }
    public Guid? TransportPostId { get; set; }
    public Guid ParentPostId { get; set; }
    public long RequesterId { get; set; }
    public long? TransporterId { get; set; }
    public string PickupAddress { get; set; } = null!;
    public NetTopologySuite.Geometries.Point PickupPoint { get; set; } = null!;
    public string DropoffAddress { get; set; } = null!;
    public NetTopologySuite.Geometries.Point DropoffPoint { get; set; } = null!;
    public DateTimeOffset? PickupWindowStart { get; set; }
    public DateTimeOffset? PickupWindowEnd { get; set; }
    public bool IsSelfCollection { get; set; } = false;
    public TransportTaskStatus Status { get; set; } = TransportTaskStatus.Open;
    public DateTimeOffset? CompletedAt { get; set; }
    public string? Notes { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public Post? TransportPost { get; set; }
    public Post ParentPost { get; set; } = null!;
    public User Requester { get; set; } = null!;
    public User? Transporter { get; set; }

    private readonly List<TransportOffer> _offers = new();
    public IReadOnlyCollection<TransportOffer> Offers => _offers.AsReadOnly();
}
