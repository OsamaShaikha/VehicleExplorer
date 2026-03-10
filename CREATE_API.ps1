# API Layer Creation Script

Write-Host "Creating API layer..." -ForegroundColor Green

# API project file
@"
<Project Sdk="Microsoft.NET.Sdk.Web">

  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <PackageReference Include="Swashbuckle.AspNetCore" Version="6.5.0" />
  </ItemGroup>

  <ItemGroup>
    <ProjectReference Include="..\VehicleExplorer.Application\VehicleExplorer.Application.csproj" />
    <ProjectReference Include="..\VehicleExplorer.Infrastructure\VehicleExplorer.Infrastructure.csproj" />
  </ItemGroup>

</Project>
"@ | Out-File -FilePath "backend/VehicleExplorer.API/VehicleExplorer.API.csproj" -Encoding UTF8

# Controllers
@"
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

    /// <summary>
    /// Get all car makes
    /// </summary>
    [HttpGet("makes")]
    [ProducesResponseType(200)]
    public async Task<IActionResult> GetAllMakes(CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetAllMakesQuery(), cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Get vehicle types for a given make
    /// </summary>
    [HttpGet("makes/{makeId:int}/vehicle-types")]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> GetVehicleTypes(int makeId, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetVehicleTypesQuery(makeId), cancellationToken);
        return Ok(result);
    }

    /// <summary>
    /// Get models for a given make and year
    /// </summary>
    [HttpGet("makes/{makeId:int}/models")]
    [ProducesResponseType(200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> GetModels(int makeId, [FromQuery] int year, CancellationToken cancellationToken)
    {
        var result = await _mediator.Send(new GetModelsQuery(makeId, year), cancellationToken);
        return Ok(result);
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.API/Controllers/VehiclesController.cs" -Encoding UTF8

# Middleware
@"
using FluentValidation;
using System.Text.Json;
using VehicleExplorer.Application.Common.Models;
using VehicleExplorer.Domain.Exceptions;

namespace VehicleExplorer.API.Middleware;

public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;

    public ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (ValidationException ex)
        {
            _logger.LogWarning(ex, "Validation error occurred");
            context.Response.StatusCode = StatusCodes.Status400BadRequest;
            context.Response.ContentType = "application/json";

            var errors = string.Join("; ", ex.Errors.Select(e => e.ErrorMessage));
            var response = ApiResponse<object>.Fail(errors);

            await context.Response.WriteAsJsonAsync(response);
        }
        catch (DomainException ex)
        {
            _logger.LogWarning(ex, "Domain error occurred");
            context.Response.StatusCode = StatusCodes.Status422UnprocessableEntity;
            context.Response.ContentType = "application/json";

            var response = ApiResponse<object>.Fail(ex.Message);
            await context.Response.WriteAsJsonAsync(response);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception occurred");
            context.Response.StatusCode = StatusCodes.Status500InternalServerError;
            context.Response.ContentType = "application/json";

            var response = ApiResponse<object>.Fail("An unexpected error occurred.");
            await context.Response.WriteAsJsonAsync(response);
        }
    }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.API/Middleware/ExceptionHandlingMiddleware.cs" -Encoding UTF8

# Program.cs
@"
using Microsoft.OpenApi.Models;
using VehicleExplorer.API.Middleware;
using VehicleExplorer.Application;
using VehicleExplorer.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

// Add services
builder.Services.AddApplication();
builder.Services.AddInfrastructure(builder.Configuration);

builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Vehicle Explorer API",
        Version = "v1",
        Description = "API for exploring vehicle makes, types, and models"
    });
});

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("Angular", policy =>
    {
        var allowedOrigins = builder.Configuration["AllowedOrigins"]?.Split(',') 
            ?? new[] { "http://localhost:4200", "http://localhost:4201" };

        policy.WithOrigins(allowedOrigins)
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure middleware pipeline
app.UseMiddleware<ExceptionHandlingMiddleware>();

if (app.Environment.IsDevelopment())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors("Angular");
app.UseHttpsRedirection();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
"@ | Out-File -FilePath "backend/VehicleExplorer.API/Program.cs" -Encoding UTF8

# appsettings.json
@"
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "Nhtsa": {
    "BaseUrl": "https://vpic.nhtsa.dot.gov/api/"
  },
  "AllowedOrigins": "http://localhost:4200"
}
"@ | Out-File -FilePath "backend/VehicleExplorer.API/appsettings.json" -Encoding UTF8

# appsettings.Development.json
@"
{
  "Logging": {
    "LogLevel": {
      "Default": "Debug",
      "System": "Information",
      "Microsoft": "Information"
    }
  },
  "AllowedOrigins": "http://localhost:4200,http://localhost:4201"
}
"@ | Out-File -FilePath "backend/VehicleExplorer.API/appsettings.Development.json" -Encoding UTF8

# launchSettings.json
@"
{
  "profiles": {
    "http": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "swagger",
      "applicationUrl": "http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    },
    "https": {
      "commandName": "Project",
      "dotnetRunMessages": true,
      "launchBrowser": true,
      "launchUrl": "swagger",
      "applicationUrl": "https://localhost:5001;http://localhost:5000",
      "environmentVariables": {
        "ASPNETCORE_ENVIRONMENT": "Development"
      }
    }
  }
}
"@ | Out-File -FilePath "backend/VehicleExplorer.API/Properties/launchSettings.json" -Encoding UTF8

Write-Host "✅ API layer created successfully!" -ForegroundColor Green
