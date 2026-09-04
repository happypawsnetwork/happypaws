using Microsoft.AspNetCore.Routing;

namespace HappyPaws.Api.Extensions;

public interface IEndpointGroup
{
    void MapEndpoints(IEndpointRouteBuilder app);
}
