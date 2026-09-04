namespace HappyPaws.Infrastructure.Emails.Options;

public sealed class SystemOptions
{
    public const string SectionName = "System";

    public string Domain { get; init; } = string.Empty;
    public string CdnBaseUrl { get; init; } = string.Empty;
}
