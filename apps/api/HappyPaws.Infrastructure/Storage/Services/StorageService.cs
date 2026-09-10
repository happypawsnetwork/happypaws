using Amazon.Runtime;
using Amazon.S3;
using Amazon.S3.Model;
using HappyPaws.Application.Interfaces;
using HappyPaws.Infrastructure.Storage.Options;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace HappyPaws.Infrastructure.Storage.Services;

public sealed class StorageService : IStorageService
{
    private readonly IAmazonS3 _s3Client;
    private readonly StorageOptions _options;
    private readonly ILogger<StorageService> _logger;

    public StorageService(
        IAmazonS3 s3Client,
        IOptions<StorageOptions> options,
        ILogger<StorageService> logger)
    {
        _s3Client = s3Client;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<string> UploadPublicFileAsync(
        string key,
        byte[] content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(content);

        using var stream = new MemoryStream(content);
        return await UploadPublicFileAsync(key, stream, contentType, cancellationToken);
    }

    public async Task<string> UploadPublicFileAsync(
        string key,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(content);

        var request = new PutObjectRequest
        {
            BucketName = _options.PublicBucketName,
            Key = key,
            InputStream = content,
            ContentType = contentType,
            DisablePayloadSigning = _options.ShouldDisablePayloadSigning
        };

        await _s3Client.PutObjectAsync(request, cancellationToken);

        _logger.LogInformation("[Storage] Public file uploaded successfully with key: {Key}", key);

        return ResolvePublicUrl(key);
    }

    public async Task UploadPrivateFileAsync(
        string key,
        byte[] content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(content);

        using var stream = new MemoryStream(content);
        await UploadPrivateFileAsync(key, stream, contentType, cancellationToken);
    }

    public async Task UploadPrivateFileAsync(
        string key,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);
        ArgumentNullException.ThrowIfNull(content);

        var request = new PutObjectRequest
        {
            BucketName = _options.PrivateBucketName,
            Key = key,
            InputStream = content,
            ContentType = contentType,
            DisablePayloadSigning = _options.ShouldDisablePayloadSigning
        };

        await _s3Client.PutObjectAsync(request, cancellationToken);

        _logger.LogInformation("[Storage] Private file uploaded successfully with key: {Key}", key);
    }

    public Task<string> GetPresignedUrlAsync(
        string key,
        TimeSpan expiration,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);

        var request = new GetPreSignedUrlRequest
        {
            BucketName = _options.PrivateBucketName,
            Key = key,
            Expires = DateTime.UtcNow.Add(expiration),
            Verb = HttpVerb.GET,
            Protocol = _options.ServiceUrl.StartsWith("http://", StringComparison.OrdinalIgnoreCase)
                ? Protocol.HTTP
                : Protocol.HTTPS
        };

        var url = _s3Client.GetPreSignedURL(request);
        return Task.FromResult(url);
    }

    public async Task DeletePublicFileAsync(
        string key,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);

        var request = new DeleteObjectRequest
        {
            BucketName = _options.PublicBucketName,
            Key = key
        };

        await _s3Client.DeleteObjectAsync(request, cancellationToken);

        _logger.LogInformation("[Storage] Deleted public file with key: {Key}", key);
    }

    public async Task DeletePrivateFileAsync(
        string key,
        CancellationToken cancellationToken = default)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(key);

        var request = new DeleteObjectRequest
        {
            BucketName = _options.PrivateBucketName,
            Key = key
        };

        await _s3Client.DeleteObjectAsync(request, cancellationToken);

        _logger.LogInformation("[Storage] Deleted private file with key: {Key}", key);
    }

    public async Task<bool> VerifyBucketsExistAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            // Listing buckets tests authentication and connectivity to MinIO or Cloudflare R2
            var listResponse = await _s3Client.ListBucketsAsync(cancellationToken);
            var bucketNames = listResponse.Buckets.Select(b => b.BucketName).ToHashSet(StringComparer.OrdinalIgnoreCase);

            var publicExists = bucketNames.Contains(_options.PublicBucketName);
            var privateExists = bucketNames.Contains(_options.PrivateBucketName);

            if (!publicExists)
            {
                _logger.LogWarning("[Storage] Public bucket '{BucketName}' was not found in storage account", _options.PublicBucketName);
            }

            if (!privateExists)
            {
                _logger.LogWarning("[Storage] Private bucket '{BucketName}' was not found in storage account", _options.PrivateBucketName);
            }

            return publicExists && privateExists;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[Storage] Failed to verify storage connectivity and buckets");
            return false;
        }
    }

    private string ResolvePublicUrl(string key)
    {
        var cleanKey = key.TrimStart('/');

        if (!string.IsNullOrWhiteSpace(_options.PublicCdnUrl))
        {
            return $"{_options.PublicCdnUrl.TrimEnd('/')}/{cleanKey}";
        }

        return $"{_options.ServiceUrl.TrimEnd('/')}/{_options.PublicBucketName}/{cleanKey}";
    }
}
