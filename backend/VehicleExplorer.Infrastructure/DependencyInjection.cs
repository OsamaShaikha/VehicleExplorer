using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using VehicleExplorer.Domain.Interfaces;
using VehicleExplorer.Infrastructure.ExternalApis;

namespace VehicleExplorer.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddHttpClient<IVehicleRepository, NhtsaClient>(client =>
        {
            client.BaseAddress = new Uri(configuration["Nhtsa:BaseUrl"] ?? "https://vpic.nhtsa.dot.gov/api/");
            client.Timeout = TimeSpan.FromSeconds(30);
        });

        return services;
    }
}
