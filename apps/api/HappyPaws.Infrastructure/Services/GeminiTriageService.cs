using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using System.Text.Json;
using HappyPaws.Application.Interfaces;
using HappyPaws.Domain.Enums;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace HappyPaws.Infrastructure.Services;

/// <summary>
/// Calls the Google AI Studio Gemini API to assess the urgency of a rescue situation
/// from one or more animal photos.
/// </summary>
public sealed class GeminiTriageService : IGeminiTriageService
{
    private readonly HttpClient _http;
    private readonly string _apiKey;
    private readonly string _model;
    private readonly ILogger<GeminiTriageService> _logger;

    private static readonly string[] ValidLevels =
        ["Critical", "High", "Medium", "Low"];

    public GeminiTriageService(
        IHttpClientFactory httpClientFactory,
        IConfiguration configuration,
        ILogger<GeminiTriageService> logger)
    {
        _http = httpClientFactory.CreateClient("gemini");
        _apiKey = configuration["Gemini:ApiKey"]
            ?? throw new InvalidOperationException("Gemini:ApiKey is not configured.");
        if (string.IsNullOrWhiteSpace(_apiKey))
        {
            throw new InvalidOperationException("Gemini:ApiKey is not configured.");
        }
        _model = configuration["Gemini:TriageModel"] ?? "gemini-2.0-flash";
        _logger = logger;
    }

    public async Task<(RescueUrgencyLevel UrgencyLevel, string? Reason)> AssessUrgencyAsync(
        IReadOnlyList<Stream> photoStreams,
        CancellationToken cancellationToken = default)
    {
        // Build inline image parts
        var imageParts = new List<object>();
        foreach (var stream in photoStreams)
        {
            using var ms = new MemoryStream();
            await stream.CopyToAsync(ms, cancellationToken);
            var base64 = Convert.ToBase64String(ms.ToArray());
            imageParts.Add(new
            {
                inline_data = new { mime_type = "image/jpeg", data = base64 }
            });
        }

        // The prompt instructs Gemini to pick exactly one urgency level and give a reason
        const string systemPrompt = """
            You are an animal rescue triage assistant for the Happy Paws platform.
            You will receive one or more photos of an animal that needs rescue.
            Classify the urgency of the situation using EXACTLY one of these four values:
            Critical, High, Medium, Low.

            Definitions:
            - Critical: animal is in immediate life-threatening danger (severe injury, entrapment, drowning, etc.). Needs response within hours.
            - High: animal is in clear distress but not immediately life-threatening (visible wounds, extreme weather exposure, starvation). Needs response within 24 hours.
            - Medium: animal needs help but appears relatively stable (lost, scared, mild injury). Response within a few days is acceptable.
            - Low: animal needs monitoring or minor assistance (healthy stray, routine rescue). No immediate urgency.

            Respond with valid JSON only. No markdown, no code fences. Example:
            {"urgency":"High","reason":"The animal has a visible wound on its right leg and appears unable to walk."}

            The reason must be one or two plain sentences. If the images are unrelated to animals or completely unrecognizable, use "Medium" urgency and return the exact reason: "Our AI could not assess the image due to poor quality or unrecognizable content. An admin will review it shortly."
            """;

        var parts = new List<object>
        {
            new { text = systemPrompt }
        };
        parts.AddRange(imageParts);

        var requestBody = new
        {
            contents = new[]
            {
                new { parts = parts.ToArray() }
            },
            generationConfig = new
            {
                response_mime_type = "application/json",
                temperature = 0.1
            }
        };

        var url = $"https://generativelanguage.googleapis.com/v1beta/models/{_model}:generateContent?key={_apiKey}";
        var response = await _http.PostAsJsonAsync(url, requestBody, cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);
            _logger.LogError("Gemini API returned status code {StatusCode}: {ErrorBody}", response.StatusCode, errorBody);
            return (RescueUrgencyLevel.Medium, "Our AI could not assess the image due to a potential policy violation or network error. An admin will review it shortly.");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>(cancellationToken: cancellationToken);

        try
        {
            var text = json
                .GetProperty("candidates")[0]
                .GetProperty("content")
                .GetProperty("parts")[0]
                .GetProperty("text")
                .GetString() ?? string.Empty;

            var parsed = JsonSerializer.Deserialize<TriageResponse>(text,
                new JsonSerializerOptions { PropertyNameCaseInsensitive = true });

            if (parsed is null || !ValidLevels.Contains(parsed.Urgency, StringComparer.OrdinalIgnoreCase))
            {
                _logger.LogWarning("Gemini triage returned unexpected urgency value: {Value}", parsed?.Urgency);
                return (RescueUrgencyLevel.Medium, "Our AI could not assess the image due to a potential policy violation or network error. An admin will review it shortly.");
            }

            var level = Enum.Parse<RescueUrgencyLevel>(parsed.Urgency, ignoreCase: true);
            return (level, string.IsNullOrWhiteSpace(parsed.Reason) ? null : parsed.Reason);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to parse Gemini triage response.");
            return (RescueUrgencyLevel.Medium, "Our AI could not assess the image due to a potential policy violation or network error. An admin will review it shortly.");
        }
    }

    private sealed record TriageResponse(string Urgency, string? Reason);
}


