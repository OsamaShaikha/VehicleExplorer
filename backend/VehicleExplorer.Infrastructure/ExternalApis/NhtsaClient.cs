using Microsoft.Extensions.Logging;
using System.Net.Http.Json;
using VehicleExplorer.Domain.Entities;
using VehicleExplorer.Domain.Interfaces;

namespace VehicleExplorer.Infrastructure.ExternalApis;

public class NhtsaClient : IVehicleRepository
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<NhtsaClient> _logger;

    public NhtsaClient(HttpClient httpClient, ILogger<NhtsaClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }

    public async Task<IReadOnlyList<Make>> GetAllMakesAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Fetching all makes from NHTSA API");

            var response = await _httpClient.GetFromJsonAsync<NhtsaResponse<NhtsaMakeResult>>(
                "vehicles/getallmakes?format=json", cancellationToken);

            if (response == null || response.Results == null)
            {
                _logger.LogWarning("NHTSA API returned null response for makes");
                return new List<Make>();
            }

            var makes = response.Results
                .Where(r => !string.IsNullOrWhiteSpace(r.MakeName))
                .Select(r => Make.Create(r.MakeId, r.MakeName))
                .ToList();

            _logger.LogInformation("Successfully fetched {Count} makes", makes.Count);
            return makes;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching makes from NHTSA API");
            throw;
        }
    }

    public async Task<IReadOnlyList<VehicleType>> GetVehicleTypesForMakeAsync(int makeId, CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Fetching vehicle types for make {MakeId}", makeId);

            var response = await _httpClient.GetFromJsonAsync<NhtsaResponse<NhtsaVehicleTypeResult>>(
                $"vehicles/GetVehicleTypesForMakeId/{makeId}?format=json", cancellationToken);

            if (response == null || response.Results == null)
            {
                _logger.LogWarning("NHTSA API returned null response for vehicle types");
                return new List<VehicleType>();
            }

            var types = response.Results
                .Where(r => !string.IsNullOrWhiteSpace(r.VehicleTypeName))
                .Select(r => VehicleType.Create(r.VehicleTypeId, r.VehicleTypeName))
                .ToList();

            _logger.LogInformation("Successfully fetched {Count} vehicle types for make {MakeId}", types.Count, makeId);
            return types;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching vehicle types for make {MakeId}", makeId);
            throw;
        }
    }

    public async Task<IReadOnlyList<VehicleModel>> GetModelsForMakeAndYearAsync(int makeId, int year, CancellationToken cancellationToken = default)
    {
        try
        {
            _logger.LogInformation("Fetching models for make {MakeId} and year {Year}", makeId, year);

            var response = await _httpClient.GetFromJsonAsync<NhtsaResponse<NhtsaModelResult>>(
                $"vehicles/GetModelsForMakeIdYear/makeId/{makeId}/modelyear/{year}?format=json", cancellationToken);

            if (response == null || response.Results == null)
            {
                _logger.LogWarning("NHTSA API returned null response for models");
                return new List<VehicleModel>();
            }

            var models = response.Results
                .Where(r => !string.IsNullOrWhiteSpace(r.ModelName))
                .Select(r => VehicleModel.Create(r.ModelId, r.ModelName))
                .ToList();

            _logger.LogInformation("Successfully fetched {Count} models for make {MakeId} and year {Year}", models.Count, makeId, year);
            return models;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error fetching models for make {MakeId} and year {Year}", makeId, year);
            throw;
        }
    }
}
