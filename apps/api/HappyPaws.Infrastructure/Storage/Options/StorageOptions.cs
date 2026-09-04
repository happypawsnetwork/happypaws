namespace HappyPaws.Infrastructure.Storage.Options;

public sealed class StorageOptions
{
    public const string SectionName = "Storage";

    public string ServiceUrl { get; init; } = "http://localhost:9000";
    public string AccessKey { get; init; } = string.Empty;
    public string SecretKey { get; init; } = string.Empty;
    public string PublicBucketName { get; init; } = "happypaws-public";
    public string PrivateBucketName { get; init; } = "happypaws-private";
    public string? PublicCdnUrl { get; init; }
    public bool ForcePathStyle { get; init; } = true;
}
