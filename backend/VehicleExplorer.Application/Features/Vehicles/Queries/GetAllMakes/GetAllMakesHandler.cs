using MediatR;
using VehicleExplorer.Application.Common.Models;
using VehicleExplorer.Domain.Interfaces;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetAllMakes;

public class GetAllMakesHandler : IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>>
{
    private readonly IVehicleRepository _repository;

    public GetAllMakesHandler(IVehicleRepository repository)
    {
        _repository = repository;
    }

    public async Task<ApiResponse<List<MakeDto>>> Handle(GetAllMakesQuery request, CancellationToken cancellationToken)
    {
        var makes = await _repository.GetAllMakesAsync(cancellationToken);
        var dtos = makes.Select(m => new MakeDto(m.Id, m.Name)).ToList();
        return ApiResponse<List<MakeDto>>.Ok(dtos);
    }
}
