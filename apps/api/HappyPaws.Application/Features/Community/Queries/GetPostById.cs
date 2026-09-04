using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using HappyPaws.Application.Features.Community.DTOs;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace HappyPaws.Application.Features.Community.Queries;

public static class GetPostById
{
    public static async Task<PostDetailResponse?> HandleAsync(
        IApplicationDbContext db,
        Guid id,
        long currentUserId,
        CancellationToken cancellationToken)
    {
        var p = await db.Posts.AsNoTracking()
            .Include(x => x.Author)
            .Include(x => x.Media)
            .Include(x => x.ParentPost)
            .Include(x => x.VetDetails)
            .Include(x => x.SponsorshipDetails)
            .FirstOrDefaultAsync(x => x.Id == id && !x.IsDeleted, cancellationToken);

        if (p == null) return null;

        var isLiked = await db.PostLikes.AsNoTracking().AnyAsync(pl => pl.PostId == id && pl.UserId == currentUserId, cancellationToken);
        int? applicantCount = p.Type == PostType.RescueAlert
            ? await db.RescueApplications.CountAsync(ra => ra.RescuePostId == id && ra.Status == RescueApplicationStatus.Pending, cancellationToken)
            : null;

        return new PostDetailResponse(
            p.Id,
            p.Type.ToString(),
            p.Status.ToString(),
            p.Title,
            p.Body,
            p.LikeCount,
            isLiked,
            p.Author.FirstName + " " + p.Author.LastName,
            p.Author.AvatarUrl,
            p.Author.Tagline,
            p.AuthorId,
            p.LocationLabel,
            p.LocationPoint?.Y,
            p.LocationPoint?.X,
            p.AnimalSpecies,
            p.AnimalName,
            p.AnimalDescription,
            p.Media.OrderBy(m => m.SortOrder).Select(m => new PostMediaResponse(m.Id, m.CdnUrl, m.MimeType, m.SortOrder)).ToList(),
            p.ParentPostId,
            p.ParentPost?.Title,
            applicantCount,
            p.VetDetails != null ? new VetRequestDetailsResponse(p.VetDetails.ReasonForVisit, p.VetDetails.ClinicName, p.VetDetails.AppointmentDate, p.VetDetails.TransportNeeded) : null,
            p.SponsorshipDetails != null ? new SponsorshipDetailsResponse(p.SponsorshipDetails.GoalDescription, p.SponsorshipDetails.EstimatedAmountLkr, p.SponsorshipDetails.AdminRejectionNotes, p.SponsorshipDetails.FundedAt, 0) : null,
            p.CreatedAt,
            p.UrgencyLevel?.ToString(),
            p.AiTriageReason,
            p.IsUrgencyManuallyOverridden,
            p.Expectations != null ? new LifestyleExpectationsResponse(
                p.Expectations.HomeSize?.ToString(),
                p.Expectations.RequiresEnclosedYard,
                p.Expectations.GoodWithChildren,
                p.Expectations.ActivityTempo?.ToString(),
                p.Expectations.GoodWithPets ?? new List<string>()
            ) : null
        );
    }
}
