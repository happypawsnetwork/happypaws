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
    public bool? DisablePayloadSigning { get; init; }

    /// <summary>
    /// Evaluates whether payload signing should be disabled for uploads.
    /// AWS SDK forbids disabling payload signing over unencrypted HTTP.
    /// Cloudflare R2 runs on HTTPS and rejects chunked payload signing, which requires payload signing to stay disabled on HTTPS unless explicitly overridden.
    /// </summary>
    public bool ShouldDisablePayloadSigning =>
        ServiceUrl.StartsWith("https://", StringComparison.OrdinalIgnoreCase) && (DisablePayloadSigning ?? true);
}
