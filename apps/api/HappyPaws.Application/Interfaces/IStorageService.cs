namespace HappyPaws.Application.Interfaces;

/// <summary>
/// Provides abstractions for public and private cloud object storage.
/// </summary>
public interface IStorageService
{
    /// <summary>
    /// Uploads an asset to the public bucket and returns its accessible CDN URL.
    /// </summary>
    Task<string> UploadPublicFileAsync(
        string key,
        byte[] content,
        string contentType,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads a stream to the public bucket and returns its accessible CDN URL.
    /// </summary>
    Task<string> UploadPublicFileAsync(
        string key,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads an asset to the private bucket with zero public access.
    /// </summary>
    Task UploadPrivateFileAsync(
        string key,
        byte[] content,
        string contentType,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Uploads a stream to the private bucket with zero public access.
    /// </summary>
    Task UploadPrivateFileAsync(
        string key,
        Stream content,
        string contentType,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Generates a time-limited presigned URL for an item in the private bucket.
    /// </summary>
    Task<string> GetPresignedUrlAsync(
        string key,
        TimeSpan expiration,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a file from the public bucket.
    /// </summary>
    Task DeletePublicFileAsync(
        string key,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Deletes a file from the private bucket.
    /// </summary>
    Task DeletePrivateFileAsync(
        string key,
        CancellationToken cancellationToken = default);

    /// <summary>
    /// Checks connectivity to the storage provider and verifies that both buckets exist.
    /// </summary>
    Task<bool> VerifyBucketsExistAsync(
        CancellationToken cancellationToken = default);
}
