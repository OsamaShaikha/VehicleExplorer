namespace VehicleExplorer.Application.Common.Models;

public class ApiResponse<T>
{
    public bool Success { get; init; }
    public int Count { get; init; }
    public T? Data { get; init; }
    public string? Error { get; init; }

    public static ApiResponse<T> Ok(T data)
    {
        var count = data switch
        {
            System.Collections.ICollection collection => collection.Count,
            _ => 1
        };

        return new ApiResponse<T>
        {
            Success = true,
            Data = data,
            Count = count
        };
    }

    public static ApiResponse<T> Fail(string error)
    {
        return new ApiResponse<T>
        {
            Success = false,
            Error = error
        };
    }
}
