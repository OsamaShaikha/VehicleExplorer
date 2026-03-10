using MediatR;
using VehicleExplorer.Application.Common.Models;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetModels;

public record GetModelsQuery(int MakeId, int Year) : IRequest<ApiResponse<List<VehicleModelDto>>>;
