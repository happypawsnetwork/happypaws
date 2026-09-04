using System;

namespace HappyPaws.Domain.Entities;

public class SponsorshipDetails
{
    public Guid PostId { get; set; }
    public string GoalDescription { get; set; } = null!;
    public decimal? EstimatedAmountLkr { get; set; }
    public long? AdminApproverId { get; set; }
    public DateTimeOffset? AdminReviewedAt { get; set; }
    public string? AdminRejectionNotes { get; set; }
    public DateTimeOffset? FundedAt { get; set; }

    public Post Post { get; set; } = null!;
    public User? AdminApprover { get; set; }
}
