# Complete Backend Project Creation Script
# Run this script from vehicle-explorer folder

Write-Host "Creating complete backend project..." -ForegroundColor Green

# Create all necessary directories
$directories = @(
    "backend/VehicleExplorer.Application/Common/Behaviors",
    "backend/VehicleExplorer.Application/Common/Interfaces",
    "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetAllMakes",
    "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetVehicleTypes",
    "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetModels",
    "backend/VehicleExplorer.Infrastructure/ExternalApis",
    "backend/VehicleExplorer.API/Controllers",
    "backend/VehicleExplorer.API/Middleware",
    "backend/VehicleExplorer.API/Properties"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

Write-Host "✓ Created directory structure" -ForegroundColor Green

# Application Layer - Interfaces
@"
namespace VehicleExplorer.Application.Common.Interfaces;

public interface ICacheable
{
    string CacheKey { get; }
    TimeSpan CacheDuration { get; }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Common/Interfaces/ICacheable.cs" -Encoding UTF8

# Application Layer - Behaviors
@"
using MediatR;
using Microsoft.Extensions.Logging;
using System.Diagnostics;

namespace VehicleExplorer.Application.Common.Behaviors;

public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;

    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger)
    {
        _logger = logger;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        var requestName = typeof(TRequest).Name;
        _logger.LogInformation("[START] {Request}: {@Payload}", requestName, request);

        var stopwatch = Stopwatch.StartNew();
        var response = await next();
        stopwatch.Stop();

        _logger.LogInformation("[END] {Request} completed in {ElapsedMilliseconds}ms", requestName, stopwatch.ElapsedMilliseconds);

        return response;
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Common/Behaviors/LoggingBehavior.cs" -Encoding UTF8

@"
using FluentValidation;
using MediatR;

namespace VehicleExplorer.Application.Common.Behaviors;

public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;

    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators)
    {
        _validators = validators;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (!_validators.Any())
            return await next();

        var context = new ValidationContext<TRequest>(request);

        var validationResults = await Task.WhenAll(
            _validators.Select(v => v.ValidateAsync(context, cancellationToken)));

        var failures = validationResults
            .SelectMany(r => r.Errors)
            .Where(f => f != null)
            .ToList();

        if (failures.Count != 0)
            throw new ValidationException(failures);

        return await next();
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Common/Behaviors/ValidationBehavior.cs" -Encoding UTF8

@"
using MediatR;
using Microsoft.Extensions.Caching.Memory;
using VehicleExplorer.Application.Common.Interfaces;

namespace VehicleExplorer.Application.Common.Behaviors;

public class CachingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IMemoryCache _cache;

    public CachingBehavior(IMemoryCache cache)
    {
        _cache = cache;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (request is not ICacheable cacheable)
            return await next();

        if (_cache.TryGetValue(cacheable.CacheKey, out TResponse? cachedResponse) && cachedResponse is not null)
            return cachedResponse;

        var response = await next();

        _cache.Set(cacheable.CacheKey, response, cacheable.CacheDuration);

        return response;
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Common/Behaviors/CachingBehavior.cs" -Encoding UTF8

Write-Host "✓ Created Application behaviors" -ForegroundColor Green

# GetAllMakes Query
@"
using MediatR;
using VehicleExplorer.Application.Common.Interfaces;
using VehicleExplorer.Application.Common.Models;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetAllMakes;

public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>, ICacheable
{
    public string CacheKey => "vehicles:makes:all";
    public TimeSpan CacheDuration => TimeSpan.FromHours(24);
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetAllMakes/GetAllMakesQuery.cs" -Encoding UTF8

@"
namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetAllMakes;

public record MakeDto(int MakeId, string MakeName);
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetAllMakes/MakeDto.cs" -Encoding UTF8

@"
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
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetAllMakes/GetAllMakesHandler.cs" -Encoding UTF8

Write-Host "✓ Created GetAllMakes query" -ForegroundColor Green

# GetVehicleTypes Query
@"
using MediatR;
using VehicleExplorer.Application.Common.Models;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetVehicleTypes;

public record GetVehicleTypesQuery(int MakeId) : IRequest<ApiResponse<List<VehicleTypeDto>>>;
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetVehicleTypes/GetVehicleTypesQuery.cs" -Encoding UTF8

@"
namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetVehicleTypes;

public record VehicleTypeDto(int VehicleTypeId, string VehicleTypeName);
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetVehicleTypes/VehicleTypeDto.cs" -Encoding UTF8

@"
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
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetVehicleTypes/GetVehicleTypesHandler.cs" -Encoding UTF8

@"
using FluentValidation;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetVehicleTypes;

public class GetVehicleTypesValidator : AbstractValidator<GetVehicleTypesQuery>
{
    public GetVehicleTypesValidator()
    {
        RuleFor(x => x.MakeId)
            .GreaterThan(0).WithMessage("MakeId must be a positive integer.");
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetVehicleTypes/GetVehicleTypesValidator.cs" -Encoding UTF8

Write-Host "✓ Created GetVehicleTypes query" -ForegroundColor Green

# GetModels Query
@"
using MediatR;
using VehicleExplorer.Application.Common.Models;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetModels;

public record GetModelsQuery(int MakeId, int Year) : IRequest<ApiResponse<List<VehicleModelDto>>>;
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetModels/GetModelsQuery.cs" -Encoding UTF8

@"
namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetModels;

public record VehicleModelDto(int ModelId, string ModelName);
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetModels/VehicleModelDto.cs" -Encoding UTF8

@"
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
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetModels/GetModelsHandler.cs" -Encoding UTF8

@"
using FluentValidation;

namespace VehicleExplorer.Application.Features.Vehicles.Queries.GetModels;

public class GetModelsValidator : AbstractValidator<GetModelsQuery>
{
    public GetModelsValidator()
    {
        RuleFor(x => x.MakeId)
            .GreaterThan(0).WithMessage("MakeId must be a positive integer.");

        RuleFor(x => x.Year)
            .InclusiveBetween(1995, DateTime.Now.Year)
            .WithMessage($"Year must be between 1995 and {DateTime.Now.Year}.");
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/Features/Vehicles/Queries/GetModels/GetModelsValidator.cs" -Encoding UTF8

Write-Host "✓ Created GetModels query" -ForegroundColor Green

# DependencyInjection
@"
using FluentValidation;
using MediatR;
using Microsoft.Extensions.DependencyInjection;
using System.Reflection;
using VehicleExplorer.Application.Common.Behaviors;

namespace VehicleExplorer.Application;

public static class DependencyInjection
{
    public static IServiceCollection AddApplication(this IServiceCollection services)
    {
        services.AddMediatR(cfg =>
        {
            cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
            cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(CachingBehavior<,>));
        });

        services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());
        services.AddMemoryCache();

        return services;
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.Application/DependencyInjection.cs" -Encoding UTF8

Write-Host "✓ Created Application DependencyInjection" -ForegroundColor Green

Write-Host "`n✅ Backend project created successfully!" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Create Infrastructure layer (run CREATE_INFRASTRUCTURE.ps1)"
Write-Host "2. Create API layer (run CREATE_API.ps1)"
Write-Host "3. Build the project: dotnet build"
