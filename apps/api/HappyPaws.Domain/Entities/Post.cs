using System;
using System.Collections.Generic;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Domain.Entities;

public class Post : IAuditableEntity
{
    public Guid Id { get; set; }
    public long AuthorId { get; set; }
    public PostType Type { get; set; }
    public PostStatus Status { get; set; } = PostStatus.Active;
    public string Title { get; set; } = null!;
    public string Body { get; set; } = null!;
    public int LikeCount { get; set; } = 0;
    public Guid? ParentPostId { get; set; }
    public Guid? AssignedApplicationId { get; set; }
    public NetTopologySuite.Geometries.Point? LocationPoint { get; set; }
    public string? LocationLabel { get; set; }
    public string? AnimalSpecies { get; set; }
    public string? AnimalName { get; set; }
    public string? AnimalDescription { get; set; }

    /// <summary>AI-assessed urgency level. Only set for RescueAlert posts.</summary>
    public RescueUrgencyLevel? UrgencyLevel { get; set; }

    /// <summary>One or two sentences from Gemini explaining why this urgency level was assigned.</summary>
    public string? AiTriageReason { get; set; }

    /// <summary>When the AI triage assessment was last run for this post.</summary>
    public DateTimeOffset? UrgencyAssessedAt { get; set; }

    /// <summary>Indicates if the urgency level was manually adjusted by an administrator.</summary>
    public bool IsUrgencyManuallyOverridden { get; set; } = false;

    public bool IsDeleted { get; set; } = false;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    public User Author { get; set; } = null!;
    public Post? ParentPost { get; set; }

    private readonly List<Post> _childPosts = new();
    public IReadOnlyCollection<Post> ChildPosts => _childPosts.AsReadOnly();

    private readonly List<PostMedia> _media = new();
    public IReadOnlyCollection<PostMedia> Media => _media.AsReadOnly();

    private readonly List<PostLike> _likes = new();
    public IReadOnlyCollection<PostLike> Likes => _likes.AsReadOnly();

    public RescueApplication? AssignedApplication { get; set; }
    public VetRequestDetails? VetDetails { get; set; }
    public SponsorshipDetails? SponsorshipDetails { get; set; }
    public LifestyleExpectations? Expectations { get; set; }
}
