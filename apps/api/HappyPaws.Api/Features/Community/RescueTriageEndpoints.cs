using HappyPaws.Api.Extensions;
using HappyPaws.Application.Features.Community.Commands;
using HappyPaws.Application.Interfaces;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Routing;

namespace HappyPaws.Api.Features.Community;

public sealed class RescueTriageEndpoints : IEndpointGroup
{
    public void MapEndpoints(IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/v1/community/rescue-triage").RequireAuthorization();

        group.MapPost("/assess", async (
            IFormFileCollection photos,
            IGeminiTriageService triage,
            CancellationToken ct) =>
        {
            if (photos.Count == 0)
                return Results.BadRequest("At least one photo is required for triage.");

            var streams = photos.Select(f => f.OpenReadStream()).ToList();
            try
            {
                var (level, reason) = await triage.AssessUrgencyAsync(streams, ct);
                return Results.Ok(new { urgencyLevel = level.ToString(), reason });
            }
            finally
            {
                foreach (var s in streams) await s.DisposeAsync();
            }
        })
        .WithName("AssessRescueUrgency")
        .WithSummary("Assess rescue urgency from photos using Gemini AI")
        .DisableAntiforgery();

    }
}
