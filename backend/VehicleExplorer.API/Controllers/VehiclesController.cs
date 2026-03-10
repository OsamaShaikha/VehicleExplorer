using MediatR;
using Microsoft.AspNetCore.Mvc;
using VehicleExplorer.Application.Features.Vehicles.Queries.GetAllMakes;
using VehicleExplorer.Application.Features.Vehicles.Queries.GetModels;
using VehicleExplorer.Application.Features.Vehicles.Queries.GetVehicleTypes;

namespace VehicleExplorer.API.Controllers;

[ApiController]
[Route("api/vehicles")]
[Produces("application/json")]
public class VehiclesController : ControllerBase
{
    private readonly IMediator _mediator;

    public VehiclesController(IMediator mediator)
    {
        _mediator = mediator;
    }

    [HttpGet("makes")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> GetAllMakes(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAllMakesQuery(), cancellationToken);
        return Ok(result);
    }

    [HttpGet("makes/{makeId:int}/vehicle-types")]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> GetVehicleTypes(int makeId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetVehicleTypesQuery(makeId), cancellationToken);
        return Ok(result);
    }

    [HttpGet("makes/{makeId:int}/models")]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> GetModels(int makeId, [FromQuery] int year, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetModelsQuery(makeId, year), cancellationToken);
        return Ok(result);
    }
}
