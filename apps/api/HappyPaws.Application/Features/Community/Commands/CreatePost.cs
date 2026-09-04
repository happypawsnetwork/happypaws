using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Entities;
using HappyPaws.Domain.Enums;

namespace HappyPaws.Application.Features.Community.Commands;

public sealed record CreatePostRequest
{
    public string Type { get; init; } = null!;
    public string Title { get; init; } = null!;
    public string Body { get; init; } = null!;
    public Guid? ParentPostId { get; init; }
    public double? Latitude { get; init; }
    public double? Longitude { get; init; }
    public string? LocationLabel { get; init; }
    public string? AnimalSpecies { get; init; }
    public string? AnimalName { get; init; }
    public string? AnimalDescription { get; init; }
    public string? UrgencyLevel { get; init; }
    public string? AiTriageReason { get; init; }
    public string? VetReasonForVisit { get; init; }
    public string? VetClinicName { get; init; }
    public DateTimeOffset? VetAppointmentDate { get; init; }
    public bool VetTransportNeeded { get; init; }
    public string? SponsorGoalDescription { get; init; }
    public decimal? SponsorEstimatedAmountLkr { get; init; }

    public string? LifestyleHomeSize { get; init; }
    public bool? LifestyleRequiresEnclosedYard { get; init; }
    public bool? LifestyleGoodWithChildren { get; init; }
    public string? LifestyleActivityTempo { get; init; }
    public List<string>? LifestyleGoodWithPets { get; init; }
}

public sealed record FileUploadData(Stream Stream, string FileName, string ContentType, long Length);

public static class CreatePost
{
    public static async Task<Guid> HandleAsync(
        IApplicationDbContext db,
        IStorageService storage,
        CreatePostRequest request,
        IReadOnlyList<FileUploadData>? photos,
        IReadOnlyList<FileUploadData>? proofs,
        long authorId,
        CancellationToken ct)
    {
        if (!Enum.TryParse<PostType>(request.Type, true, out var postType))
        {
            throw new ArgumentException("Invalid post type");
        }

        var allowedPhotoMimes = new[] { "image/jpeg", "image/png", "image/webp", "image/heic" };
        var allowedProofMimes = new[] { "image/jpeg", "image/png", "image/webp", "image/heic", "application/pdf" };
        var maxPhotoSize = 5 * 1024 * 1024; // 5 MB

        photos ??= Array.Empty<FileUploadData>();
        if (postType == PostType.Highlight && (photos.Count < 1 || photos.Count > 8))
            throw new ArgumentException("Highlight posts must have 1-8 photos");
        if (postType != PostType.Highlight && photos.Count > 4)
            throw new ArgumentException("Posts can have at most 4 photos");

        foreach (var photo in photos)
        {
            if (!allowedPhotoMimes.Contains(photo.ContentType.ToLowerInvariant()))
                throw new ArgumentException("Invalid photo format");
            if (photo.Length > maxPhotoSize)
                throw new ArgumentException("Photo exceeds 5MB");
        }

        proofs ??= Array.Empty<FileUploadData>();
        if (postType == PostType.SponsorshipRequest && proofs.Count < 1)
            throw new ArgumentException("Sponsorship posts must have at least 1 proof document");

        foreach (var proof in proofs)
        {
            if (!allowedProofMimes.Contains(proof.ContentType.ToLowerInvariant()))
                throw new ArgumentException("Invalid proof format");
        }

        var post = new Post
        {
            Id = Guid.NewGuid(),
            AuthorId = authorId,
            Type = postType,
            Status = postType == PostType.SponsorshipRequest ? PostStatus.PendingApproval : PostStatus.Active,
            Title = request.Title,
            Body = request.Body,
            ParentPostId = request.ParentPostId,
            LocationLabel = request.LocationLabel,
            AnimalSpecies = request.AnimalSpecies,
            AnimalName = request.AnimalName,
            AnimalDescription = request.AnimalDescription
        };

        if (request.Latitude.HasValue && request.Longitude.HasValue)
        {
            post.LocationPoint = new NetTopologySuite.Geometries.Point(request.Longitude.Value, request.Latitude.Value) { SRID = 4326 };
        }

        if (postType == PostType.RescueAlert && !string.IsNullOrEmpty(request.UrgencyLevel) && Enum.TryParse<RescueUrgencyLevel>(request.UrgencyLevel, true, out var level))
        {
            post.UrgencyLevel = level;
            post.AiTriageReason = request.AiTriageReason;
            post.UrgencyAssessedAt = DateTimeOffset.UtcNow;
        }

        if (postType == PostType.AdoptionListing)
        {
            post.Expectations = new LifestyleExpectations
            {
                RequiresEnclosedYard = request.LifestyleRequiresEnclosedYard ?? false,
                GoodWithChildren = request.LifestyleGoodWithChildren ?? true,
                GoodWithPets = request.LifestyleGoodWithPets ?? new List<string>()
            };
            if (!string.IsNullOrEmpty(request.LifestyleHomeSize) && Enum.TryParse<HomeSize>(request.LifestyleHomeSize, true, out var homeSize))
            {
                post.Expectations.HomeSize = homeSize;
            }
            if (!string.IsNullOrEmpty(request.LifestyleActivityTempo) && Enum.TryParse<ActivityTempo>(request.LifestyleActivityTempo, true, out var actTempo))
            {
                post.Expectations.ActivityTempo = actTempo;
            }
        }

        db.Posts.Add(post);

        if (postType == PostType.VetRequest && !string.IsNullOrEmpty(request.VetReasonForVisit))
        {
            post.VetDetails = new VetRequestDetails
            {
                PostId = post.Id,
                ReasonForVisit = request.VetReasonForVisit,
                ClinicName = request.VetClinicName,
                AppointmentDate = request.VetAppointmentDate,
                TransportNeeded = request.VetTransportNeeded
            };

            if (request.VetTransportNeeded)
            {
                var transportTask = new TransportTask
                {
                    Id = Guid.NewGuid(),
                    ParentPostId = post.Id,
                    RequesterId = authorId,
                    Status = TransportTaskStatus.Open,
                    PickupPoint = post.LocationPoint ?? new NetTopologySuite.Geometries.Point(0, 0),
                    PickupAddress = request.LocationLabel ?? "Unknown",
                    DropoffAddress = request.VetClinicName ?? "Unknown Clinic",
                    DropoffPoint = new NetTopologySuite.Geometries.Point(0, 0)
                    // Note: dropoff info might not be available, just basic linking
                };
                db.TransportTasks.Add(transportTask);
            }
        }

        if (postType == PostType.SponsorshipRequest && !string.IsNullOrEmpty(request.SponsorGoalDescription))
        {
            post.SponsorshipDetails = new SponsorshipDetails
            {
                PostId = post.Id,
                GoalDescription = request.SponsorGoalDescription,
                EstimatedAmountLkr = request.SponsorEstimatedAmountLkr
            };
        }

        int photoOrder = 1;
        foreach (var photo in photos)
        {
            var ext = Path.GetExtension(photo.FileName).TrimStart('.');
            if (string.IsNullOrEmpty(ext)) ext = "jpg";
            var key = $"posts/{post.Id}/{Guid.NewGuid()}.{ext}";

            var url = await storage.UploadPublicFileAsync(key, photo.Stream, photo.ContentType, ct);

            db.PostMedia.Add(new PostMedia
            {
                Id = Guid.NewGuid(),
                PostId = post.Id,
                CdnUrl = url,
                StorageKey = key,
                FileSizeBytes = (int)photo.Length,
                MimeType = photo.ContentType,
                SortOrder = (short)photoOrder++
            });
        }

        foreach (var proof in proofs)
        {
            var ext = Path.GetExtension(proof.FileName).TrimStart('.');
            if (string.IsNullOrEmpty(ext)) ext = "pdf";
            var key = $"sponsorship-proofs/{post.Id}/{Guid.NewGuid()}.{ext}";

            await storage.UploadPrivateFileAsync(key, proof.Stream, proof.ContentType, ct);

            db.SponsorshipProofDocuments.Add(new SponsorshipProofDocument
            {
                Id = Guid.NewGuid(),
                PostId = post.Id,
                FileName = proof.FileName,
                StorageKey = key,
                MimeType = proof.ContentType,
                FileSizeBytes = (int)proof.Length,
                UploadedAt = DateTimeOffset.UtcNow
            });
        }

        await db.SaveChangesAsync(ct);
        return post.Id;
    }
}

