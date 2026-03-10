using MediatR;
using VehicleExplorer.Application.Common.Models;
using VehicleExplorer.Domain.Interfaces;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetVehicleTypes;

public class GetVehicleTypesHandler : IRequestHandler<GetVehicleTypesQuery, ApiResponse<List<VehicleTypeDto>>>
{
    private readonly IVehicleRepository _repository;

    public GetVehicleTypesHandler(IVehicleRepository repository)
    {
        _repository = repository;
    }

    public async Task<ApiResponse<List<VehicleTypeDto>>> Handle(GetVehicleTypesQuery request, CancellationToken cancellationToken)
    {
        var types = await _repository.GetVehicleTypesForMakeAsync(request.MakeId, cancellationToken);
        var dtos = types.Select(t => new VehicleTypeDto(t.Id, t.Name)).ToList();
        return ApiResponse<List<VehicleTypeDto>>.Ok(dtos);
    }
}
