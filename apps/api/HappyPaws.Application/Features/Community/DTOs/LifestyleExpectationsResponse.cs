using System.Collections.Generic;

namespace HappyPaws.Application.Features.Community.DTOs;

public sealed record LifestyleExpectationsResponse(
    string? HomeSize,
    bool RequiresEnclosedYard,
    bool GoodWithChildren,
    string? ActivityTempo,
    IReadOnlyList<string> GoodWithPets
);
