using System;

namespace HappyPaws.Domain.Entities;

public class PostMedia
{
    public Guid Id { get; set; }
    public Guid PostId { get; set; }
    public string StorageKey { get; set; } = null!;
    public string CdnUrl { get; set; } = null!;
    public string MimeType { get; set; } = null!;
    public int FileSizeBytes { get; set; }
    public short SortOrder { get; set; } = 0;
    public DateTimeOffset UploadedAt { get; set; }

    public Post Post { get; set; } = null!;
}
