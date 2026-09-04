using HappyPaws.Domain.Enums;

namespace HappyPaws.Application.Interfaces;

/// <summary>
/// Sends animal photos to Gemini and returns an urgency classification
/// with a short plain-language explanation.
/// </summary>
public interface IGeminiTriageService
{
    /// <param name="photoStreams">
    /// The raw byte streams of the uploaded photos (JPEG, PNG, WebP, or HEIC).
    /// At least one photo is required.
    /// </param>
    /// <returns>
    /// The classified urgency level and the model's one-to-two sentence reason.
    /// <c>Reason</c> is null when the model returns no explanation.
    /// </returns>
    Task<(RescueUrgencyLevel UrgencyLevel, string? Reason)> AssessUrgencyAsync(
        IReadOnlyList<Stream> photoStreams,
        CancellationToken cancellationToken = default);
}
