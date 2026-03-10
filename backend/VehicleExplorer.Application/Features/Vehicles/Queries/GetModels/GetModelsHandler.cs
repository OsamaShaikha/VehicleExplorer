using MediatR;
using VehicleExplorer.Application.Common.Models;
using VehicleExplorer.Domain.Interfaces;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetModels;

public class GetModelsHandler : IRequestHandler<GetModelsQuery, ApiResponse<List<VehicleModelDto>>>
{
    private readonly IVehicleRepository _repository;

    public GetModelsHandler(IVehicleRepository repository)
    {
        _repository = repository;
    }

    public async Task<ApiResponse<List<VehicleModelDto>>> Handle(GetModelsQuery request, CancellationToken cancellationToken)
    {
        var models = await _repository.GetModelsForMakeAndYearAsync(request.MakeId, request.Year, cancellationToken);
        var dtos = models.Select(m => new VehicleModelDto(m.Id, m.Name)).ToList();
        return ApiResponse<List<VehicleModelDto>>.Ok(dtos);
    }
}
