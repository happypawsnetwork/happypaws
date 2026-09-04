using Microsoft.Extensions.DependencyInjection;

namespace HappyPaws.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplicationServices(this IServiceCollection services)
    {
        // Add Application layer services here (MediatR, FluentValidation, etc.)
        return services;
    }
}
