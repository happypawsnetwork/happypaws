namespace HappyPaws.Infrastructure.Emails.Options;

public sealed class EmailOptions
{
    public const string SectionName = "Email";

    public string ApiKey { get; init; } = string.Empty;
    public string FromAddress { get; init; } = string.Empty;
    public string FromName { get; init; } = "Happy Paws";
}
