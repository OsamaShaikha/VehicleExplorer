using System.Text.Json.Serialization;

namespace VehicleExplorer.Infrastructure.ExternalApis;

public record NhtsaResponse<T>(int Count, List<T> Results);

public record NhtsaMakeResult(
    [property: JsonPropertyName("Make_ID")] int MakeId,
    [property: JsonPropertyName("Make_Name")] string MakeName
);

public record NhtsaVehicleTypeResult(
    [property: JsonPropertyName("VehicleTypeId")] int VehicleTypeId,
    [property: JsonPropertyName("VehicleTypeName")] string VehicleTypeName
);

public record NhtsaModelResult(
    [property: JsonPropertyName("Model_ID")] int ModelId,
    [property: JsonPropertyName("Model_Name")] string ModelName
);
