using MediatR;
using VehicleExplorer.Application.Common.Interfaces;
using VehicleExplorer.Application.Common.Models;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetAllMakes;

public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>, ICacheable
{
    public string CacheKey => "vehicles:makes:all";
    public TimeSpan CacheDuration => TimeSpan.FromHours(24);
}
