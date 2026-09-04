namespace HappyPaws.Domain.Enums;

/// <summary>Urgency classification for a rescue alert, assessed by Gemini AI.</summary>
public enum RescueUrgencyLevel
{
    /// <summary>Animal is in immediate life-threatening danger. Needs response within hours.</summary>
    Critical,

    /// <summary>Animal is in distress but not immediately life-threatening. Needs response within 24 hours.</summary>
    High,

    /// <summary>Animal needs help but is relatively stable. Response within a few days is acceptable.</summary>
    Medium,

    /// <summary>Animal needs monitoring or minor assistance. No immediate assistance required.</summary>
    Low
}
