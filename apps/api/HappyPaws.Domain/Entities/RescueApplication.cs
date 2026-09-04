using System;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class RescueApplication
{
    public Guid Id { get; set; }
    public Guid RescuePostId { get; set; }
    public long ApplicantId { get; set; }
    public ApplicantRole ApplicantRole { get; set; }
    public string? Message { get; set; }
    public string? ExperienceSummary { get; set; }
    public bool HasVehicle { get; set; } = false;
    public RescueApplicationStatus Status { get; set; } = RescueApplicationStatus.Pending;
    public DateTimeOffset? PosterReviewedAt { get; set; }
    public DateTimeOffset? AdminReviewedAt { get; set; }
    public long? AdminReviewerId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    public Post RescuePost { get; set; } = null!;
    public User Applicant { get; set; } = null!;
    public User? AdminReviewer { get; set; }
}
