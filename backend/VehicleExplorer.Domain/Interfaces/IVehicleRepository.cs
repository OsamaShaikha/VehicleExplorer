using VehicleExplorer.Domain.Entities;

namespace VehicleExplorer.Domain.Interfaces;

public interface IVehicleRepository
{
    Task<IReadOnlyList<Make>> GetAllMakesAsync(CancellationToken cancellationToken = default);
    Task<IReadOnlyList<VehicleType>> GetVehicleTypesForMakeAsync(int makeId, CancellationToken cancellationToken = default);
    Task<IReadOnlyList<VehicleModel>> GetModelsForMakeAndYearAsync(int makeId, int year, CancellationToken cancellationToken = default);
}
