using System;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record PostMediaResponse(
    Guid Id,
    string CdnUrl,
    string MimeType,
    short SortOrder
);
