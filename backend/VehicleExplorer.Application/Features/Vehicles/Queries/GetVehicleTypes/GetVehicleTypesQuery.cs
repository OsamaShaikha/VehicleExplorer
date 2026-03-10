using MediatR;
using VehicleExplorer.Application.Common.Models;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetVehicleTypes;

public record GetVehicleTypesQuery(int MakeId) : IRequest<ApiResponse<List<VehicleTypeDto>>>;
