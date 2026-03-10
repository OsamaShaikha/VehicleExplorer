# Backend Architecture - Complete Guide

## Overview

The Vehicle Explorer backend follows **Clean Architecture** principles with **CQRS** (Command Query Responsibility Segregation) pattern using **MediatR**. The architecture is divided into 4 layers, each with specific responsibilities.

## Architecture Layers

```
┌─────────────────────────────────────────────┐
│         VehicleExplorer.API (Layer 4)       │  ← Presentation Layer
│     Controllers, Middleware, Program.cs     │
├─────────────────────────────────────────────┤
│    VehicleExplorer.Infrastructure (Layer 3) │  ← External Services
│        HTTP Clients, NHTSA API Client       │
├─────────────────────────────────────────────┤
│    VehicleExplorer.Application (Layer 2)    │  ← Business Logic
│    CQRS Queries, Handlers, Behaviors        │
├─────────────────────────────────────────────┤
│      VehicleExplorer.Domain (Layer 1)       │  ← Core Domain
│      Entities, Interfaces, Exceptions       │
└─────────────────────────────────────────────┘
```

### Dependency Rule
- **Domain** → No dependencies (pure business logic)
- **Application** → Depends on Domain only
- **Infrastructure** → Depends on Application (implements interfaces)
- **API** → Depends on Application + Infrastructure (composition root)

---

## Layer 1: Domain (VehicleExplorer.Domain)

**Purpose**: Contains the core business entities and rules. No external dependencies.

### Entities

#### Make.cs
```csharp
public class Make
{
    public int Id { get; private set; }
    public string Name { get; private set; }
    
    private Make() { } // Private constructor prevents direct instantiation
    
    public static Make Create(int id, string name)
    {
        if (string.IsNullOrWhiteSpace(name))
            throw new DomainException("Make name cannot be empty.");
        return new Make { Id = id, Name = name };
    }
}
```

**Key Points**:
- Private setters prevent external modification
- Factory method `Create()` ensures validation
- Throws `DomainException` if business rules violated
- Encapsulates business logic for creating a Make

#### VehicleType.cs & VehicleModel.cs
Similar structure to Make - simple entities with factory methods.

### Interfaces

#### IVehicleRepository.cs
```csharp
public interface IVehicleRepository
{
    Task<IReadOnlyList<Make>> GetAllMakesAsync(CancellationToken ct = default);
    Task<IReadOnlyList<VehicleType>> GetVehicleTypesForMakeAsync(int makeId, CancellationToken ct);
    Task<IReadOnlyList<VehicleModel>> GetModelsForMakeAndYearAsync(int makeId, int year, CancellationToken ct);
}
```

**Key Points**:
- Defines contract for data access
- Domain doesn't know HOW data is fetched (HTTP, database, etc.)
- Returns domain entities, not DTOs
- Infrastructure layer implements this interface

### Exceptions

#### DomainException.cs
```csharp
public class DomainException : Exception
{
    public DomainException(string message) : base(message) { }
}
```

**Purpose**: Represents business rule violations (e.g., invalid entity state)

---

## Layer 2: Application (VehicleExplorer.Application)

**Purpose**: Contains application business logic, CQRS queries/commands, and cross-cutting concerns.

### Structure
```
Application/
├── Common/
│   ├── Behaviors/          # MediatR pipeline behaviors
│   ├── Interfaces/         # Application interfaces
│   └── Models/             # Shared models (ApiResponse)
└── Features/
    └── Vehicles/
        └── Queries/        # CQRS queries
```

### Common Models

#### ApiResponse.cs
```csharp
public class ApiResponse<T>
{
    public bool Success { get; init; }
    public int Count { get; init; }
    public T? Data { get; init; }
    public string? Error { get; init; }
    
    public static ApiResponse<T> Ok(T data) => new()
    {
        Success = true,
        Data = data,
        Count = data is ICollection c ? c.Count : 1
    };
    
    public static ApiResponse<T> Fail(string error) => new()
    {
        Success = false,
        Error = error
    };
}
```

**Purpose**: Standardizes all API responses with consistent structure


#### ICacheable.cs
```csharp
public interface ICacheable
{
    string CacheKey { get; }
    TimeSpan CacheDuration { get; }
}
```

**Purpose**: Marker interface for queries that should be cached

### CQRS Pattern - Queries

#### GetAllMakesQuery.cs
```csharp
public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>, ICacheable
{
    public string CacheKey => "vehicles:makes:all";
    public TimeSpan CacheDuration => TimeSpan.FromHours(24);
}
```

**Key Points**:
- Immutable record (no setters)
- Implements `IRequest<TResponse>` from MediatR
- Implements `ICacheable` to enable caching
- No logic - just a message/request object

#### MakeDto.cs
```csharp
public record MakeDto(int MakeId, string MakeName);
```

**Purpose**: Data Transfer Object - shapes data for API responses

#### GetAllMakesHandler.cs
```csharp
public class GetAllMakesHandler : IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>>
{
    private readonly IVehicleRepository _repository;
    
    public GetAllMakesHandler(IVehicleRepository repository) => _repository = repository;
    
    public async Task<ApiResponse<List<MakeDto>>> Handle(GetAllMakesQuery request, CancellationToken ct)
    {
        var makes = await _repository.GetAllMakesAsync(ct);
        var dtos = makes.Select(m => new MakeDto(m.Id, m.Name)).ToList();
        return ApiResponse<List<MakeDto>>.Ok(dtos);
    }
}
```

**Key Points**:
- Handles the query execution
- Depends on `IVehicleRepository` (not concrete implementation)
- Converts domain entities to DTOs
- Returns wrapped response

### Validators

#### GetModelsValidator.cs
```csharp
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
```

**Purpose**: Validates query parameters using FluentValidation


### MediatR Pipeline Behaviors

Behaviors are executed in order for EVERY request:

#### 1. LoggingBehavior.cs
```csharp
public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;
    
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        var name = typeof(TRequest).Name;
        _logger.LogInformation("[START] {Request}: {@Payload}", name, request);
        
        var sw = Stopwatch.StartNew();
        var response = await next(); // Call next behavior/handler
        sw.Stop();
        
        _logger.LogInformation("[END] {Request} completed in {Ms}ms", name, sw.ElapsedMilliseconds);
        return response;
    }
}
```

**Purpose**: 
- Logs every request start/end
- Measures execution time
- Helps with debugging and monitoring

#### 2. ValidationBehavior.cs
```csharp
public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;
    
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        if (!_validators.Any()) return await next();
        
        var context = new ValidationContext<TRequest>(request);
        var failures = _validators
            .Select(v => v.Validate(context))
            .SelectMany(r => r.Errors)
            .Where(f => f is not null)
            .ToList();
        
        if (failures.Count > 0)
            throw new ValidationException(failures);
        
        return await next();
    }
}
```

**Purpose**:
- Runs all validators for the request
- Throws `ValidationException` if validation fails
- Prevents invalid requests from reaching handlers

#### 3. CachingBehavior.cs
```csharp
public class CachingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    private readonly IMemoryCache _cache;
    
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        if (request is not ICacheable cacheable) return await next();
        
        if (_cache.TryGetValue(cacheable.CacheKey, out TResponse? cached) && cached is not null)
            return cached; // Return cached response
        
        var response = await next(); // Execute handler
        _cache.Set(cacheable.CacheKey, response, cacheable.CacheDuration);
        return response;
    }
}
```

**Purpose**:
- Caches responses for queries implementing `ICacheable`
- Improves performance by avoiding repeated API calls
- Makes endpoint cached for 24 hours


### DependencyInjection.cs
```csharp
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
```

**Purpose**: Registers all Application layer services with DI container

---

## Layer 3: Infrastructure (VehicleExplorer.Infrastructure)

**Purpose**: Implements interfaces defined in Domain/Application. Handles external concerns.

### NhtsaClient.cs

```csharp
public class NhtsaClient : IVehicleRepository
{
    private readonly HttpClient _httpClient;
    private readonly ILogger<NhtsaClient> _logger;
    
    public NhtsaClient(HttpClient httpClient, ILogger<NhtsaClient> logger)
    {
        _httpClient = httpClient;
        _logger = logger;
    }
    
    public async Task<IReadOnlyList<Make>> GetAllMakesAsync(CancellationToken ct = default)
    {
        var response = await _httpClient.GetFromJsonAsync<NhtsaResponse<NhtsaMakeResult>>(
            "vehicles/getallmakes?format=json", ct);
        
        var makes = response?.Results
            .Where(r => !string.IsNullOrWhiteSpace(r.MakeName))
            .Select(r => Make.Create(r.MakeId, r.MakeName))
            .ToList();
        
        return makes ?? new List<Make>();
    }
}
```

**Key Points**:
- Implements `IVehicleRepository` from Domain
- Uses HttpClient to call NHTSA API
- Converts NHTSA JSON responses to Domain entities
- Filters out invalid data (empty names)
- Domain layer doesn't know this is HTTP - could be database, file, etc.

### NhtsaResponseModels.cs

```csharp
public record NhtsaResponse<T>(int Count, List<T> Results);

public record NhtsaMakeResult(
    [property: JsonPropertyName("Make_ID")] int MakeId,
    [property: JsonPropertyName("Make_Name")] string MakeName
);
```

**Key Points**:
- Maps NHTSA JSON structure to C# objects
- Uses `JsonPropertyName` to handle NHTSA's underscore naming (Make_ID, Make_Name)
- Internal to Infrastructure - not exposed to other layers


### DependencyInjection.cs
```csharp
public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration config)
    {
        services.AddHttpClient<IVehicleRepository, NhtsaClient>(client =>
        {
            client.BaseAddress = new Uri(config["Nhtsa:BaseUrl"] 
                ?? "https://vpic.nhtsa.dot.gov/api/");
            client.Timeout = TimeSpan.FromSeconds(30);
        });
        
        return services;
    }
}
```

**Key Points**:
- Registers `NhtsaClient` as implementation of `IVehicleRepository`
- Configures HttpClient with base URL and timeout
- Uses typed HttpClient pattern for better testability

---

## Layer 4: API (VehicleExplorer.API)

**Purpose**: Presentation layer - handles HTTP requests, routing, middleware.

### VehiclesController.cs

```csharp
[ApiController]
[Route("api/vehicles")]
[Produces("application/json")]
public class VehiclesController : ControllerBase
{
    private readonly IMediator _mediator;
    
    public VehiclesController(IMediator mediator) => _mediator = mediator;
    
    /// <summary>Get all car makes</summary>
    [HttpGet("makes")]
    [ProducesResponseType(typeof(ApiResponse<List<MakeDto>>), 200)]
    public async Task<IActionResult> GetAllMakes(CancellationToken ct)
        => Ok(await _mediator.Send(new GetAllMakesQuery(), ct));
    
    /// <summary>Get vehicle types for a given make</summary>
    [HttpGet("makes/{makeId:int}/vehicle-types")]
    [ProducesResponseType(typeof(ApiResponse<List<VehicleTypeDto>>), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> GetVehicleTypes(int makeId, CancellationToken ct)
        => Ok(await _mediator.Send(new GetVehicleTypesQuery(makeId), ct));
    
    /// <summary>Get models for a given make and year</summary>
    [HttpGet("makes/{makeId:int}/models")]
    [ProducesResponseType(typeof(ApiResponse<List<VehicleModelDto>>), 200)]
    [ProducesResponseType(400)]
    public async Task<IActionResult> GetModels(int makeId, [FromQuery] int year, CancellationToken ct)
        => Ok(await _mediator.Send(new GetModelsQuery(makeId, year), ct));
}
```

**Key Points**:
- Thin controller - only sends queries to MediatR
- No business logic in controller
- Uses route parameters and query strings
- Returns IActionResult for HTTP responses
- Swagger annotations for API documentation


### ExceptionHandlingMiddleware.cs

```csharp
public class ExceptionHandlingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionHandlingMiddleware> _logger;
    
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context); // Call next middleware
        }
        catch (ValidationException ex)
        {
            context.Response.StatusCode = 400;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(
                string.Join("; ", ex.Errors.Select(e => e.ErrorMessage))));
        }
        catch (DomainException ex)
        {
            context.Response.StatusCode = 422;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(ex.Message));
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Unhandled exception");
            context.Response.StatusCode = 500;
            await context.Response.WriteAsJsonAsync(ApiResponse<object>.Fail(
                "An unexpected error occurred."));
        }
    }
}
```

**Purpose**:
- Global exception handling
- Converts exceptions to appropriate HTTP status codes
- Returns consistent error responses
- Prevents exception details from leaking to clients

### Program.cs (Composition Root)

```csharp
var builder = WebApplication.CreateBuilder(args);

// Register layers
builder.Services.AddApplication();                          // Application layer
builder.Services.AddInfrastructure(builder.Configuration);  // Infrastructure layer

// Add framework services
builder.Services.AddControllers();
builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "Vehicle Explorer API", Version = "v1" });
});

// Configure CORS
builder.Services.AddCors(options =>
{
    options.AddPolicy("Angular", policy =>
        policy.WithOrigins(
            builder.Configuration["AllowedOrigins"] ?? "http://localhost:4200",
            "http://localhost:4201")
              .AllowAnyHeader()
              .AllowAnyMethod());
});

builder.Services.AddHealthChecks();

var app = builder.Build();

// Configure middleware pipeline
app.UseMiddleware<ExceptionHandlingMiddleware>();
app.UseCors("Angular");
app.UseSwagger();
app.UseSwaggerUI();
app.UseHttpsRedirection();
app.MapControllers();
app.MapHealthChecks("/health");

app.Run();
```

**Key Points**:
- Composition root - wires everything together
- Registers all layers (Application, Infrastructure)
- Configures middleware pipeline (order matters!)
- Sets up CORS for frontend
- Enables Swagger for API documentation


---

## Request Flow - Complete Journey

Let's trace a request from start to finish:

### Example: GET /api/vehicles/makes

```
1. HTTP Request arrives
   ↓
2. ExceptionHandlingMiddleware (wraps everything in try-catch)
   ↓
3. CORS Middleware (checks origin)
   ↓
4. Routing Middleware (matches route to controller)
   ↓
5. VehiclesController.GetAllMakes()
   - Creates GetAllMakesQuery
   - Sends to MediatR
   ↓
6. MediatR Pipeline Behaviors (in order):
   
   a) LoggingBehavior
      - Logs "[START] GetAllMakesQuery"
      - Starts stopwatch
      ↓
   b) ValidationBehavior
      - Checks for validators (none for this query)
      - Continues
      ↓
   c) CachingBehavior
      - Checks if query implements ICacheable (YES)
      - Checks cache for key "vehicles:makes:all"
      - If found: returns cached data (0ms)
      - If not found: continues to handler
      ↓
   d) GetAllMakesHandler
      - Calls _repository.GetAllMakesAsync()
      ↓
7. NhtsaClient (Infrastructure)
   - Makes HTTP call to NHTSA API
   - Receives JSON response
   - Parses JSON to NhtsaMakeResult objects
   - Filters out empty names
   - Converts to Make domain entities
   - Returns List<Make>
   ↓
8. Back to Handler
   - Converts Make entities to MakeDto
   - Wraps in ApiResponse<List<MakeDto>>
   - Returns to CachingBehavior
   ↓
9. CachingBehavior
   - Stores response in cache (24 hours)
   - Returns response
   ↓
10. LoggingBehavior
    - Stops stopwatch
    - Logs "[END] GetAllMakesQuery completed in 1200ms"
    - Returns response
    ↓
11. Controller
    - Wraps in Ok(200) result
    - Returns IActionResult
    ↓
12. ASP.NET Core
    - Serializes ApiResponse to JSON
    - Sends HTTP 200 response
```

### Subsequent Requests (Cached)

```
Steps 1-6c same as above
↓
CachingBehavior finds cached data
↓
Returns immediately (0ms)
↓
LoggingBehavior logs "[END] completed in 0ms"
↓
Response sent
```

---

## Key Design Patterns Used

### 1. Clean Architecture
- Dependency Inversion: Inner layers define interfaces, outer layers implement
- Separation of Concerns: Each layer has single responsibility
- Testability: Easy to mock interfaces

### 2. CQRS (Command Query Responsibility Segregation)
- Queries: Read operations (GetAllMakes, GetModels)
- Commands: Write operations (not used in this project)
- Separation allows different optimization strategies

### 3. Mediator Pattern (MediatR)
- Decouples controllers from handlers
- Enables pipeline behaviors
- Single point for cross-cutting concerns

### 4. Repository Pattern
- Abstracts data access behind interface
- Domain doesn't know about HTTP, databases, etc.
- Easy to swap implementations (mock for testing)

### 5. Factory Pattern
- Entity creation through static factory methods
- Ensures validation on creation
- Encapsulates creation logic


### 6. Dependency Injection
- Constructor injection throughout
- Configured in Program.cs
- Enables loose coupling and testability

### 7. Pipeline Pattern
- MediatR behaviors form a pipeline
- Each behavior can modify request/response
- Order matters: Logging → Validation → Caching → Handler

---

## Benefits of This Architecture

### 1. Testability
```csharp
// Easy to test handler in isolation
var mockRepo = new Mock<IVehicleRepository>();
mockRepo.Setup(r => r.GetAllMakesAsync(It.IsAny<CancellationToken>()))
    .ReturnsAsync(new List<Make> { Make.Create(1, "Toyota") });

var handler = new GetAllMakesHandler(mockRepo.Object);
var result = await handler.Handle(new GetAllMakesQuery(), CancellationToken.None);

Assert.True(result.Success);
Assert.Single(result.Data);
```

### 2. Maintainability
- Each class has single responsibility
- Easy to find where logic lives
- Changes in one layer don't affect others

### 3. Scalability
- Can add new queries/commands without modifying existing code
- Can add new behaviors to pipeline globally
- Can swap implementations (e.g., add Redis caching)

### 4. Performance
- Caching reduces API calls
- Async/await throughout for non-blocking I/O
- Efficient pipeline processing

### 5. Security
- Input validation at multiple levels
- Exception handling prevents information leakage
- CORS configured properly

---

## Configuration (appsettings.json)

```json
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
```

**Configuration Sections**:
- `Logging`: Controls log verbosity
- `Nhtsa:BaseUrl`: NHTSA API endpoint
- `AllowedOrigins`: CORS allowed origins

---

## Common Operations

### Adding a New Query

1. **Create Query** (Application/Features/Vehicles/Queries/NewQuery/)
```csharp
public record NewQuery(int Param) : IRequest<ApiResponse<ResultDto>>;
```

2. **Create Handler**
```csharp
public class NewQueryHandler : IRequestHandler<NewQuery, ApiResponse<ResultDto>>
{
    public async Task<ApiResponse<ResultDto>> Handle(NewQuery request, CancellationToken ct)
    {
        // Implementation
    }
}
```

3. **Create Validator** (optional)
```csharp
public class NewQueryValidator : AbstractValidator<NewQuery>
{
    public NewQueryValidator()
    {
        RuleFor(x => x.Param).GreaterThan(0);
    }
}
```

4. **Add Controller Endpoint**
```csharp
[HttpGet("new-endpoint")]
public async Task<IActionResult> NewEndpoint([FromQuery] int param, CancellationToken ct)
    => Ok(await _mediator.Send(new NewQuery(param), ct));
```

That's it! MediatR auto-discovers handlers and validators.


### Adding Caching to a Query

Simply implement `ICacheable`:

```csharp
public record MyQuery() : IRequest<ApiResponse<MyDto>>, ICacheable
{
    public string CacheKey => "my:cache:key";
    public TimeSpan CacheDuration => TimeSpan.FromMinutes(30);
}
```

CachingBehavior automatically handles it!

### Adding a New Behavior

1. **Create Behavior**
```csharp
public class MyBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken ct)
    {
        // Before handler
        var response = await next();
        // After handler
        return response;
    }
}
```

2. **Register in DependencyInjection.cs**
```csharp
cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(MyBehavior<,>));
```

---

## Troubleshooting

### Issue: Cache not clearing
**Solution**: Restart the application (in-memory cache is lost on restart)

### Issue: CORS errors
**Solution**: Check `AllowedOrigins` in appsettings.json matches frontend URL

### Issue: Validation not working
**Solution**: Ensure validator is in same assembly and follows naming convention

### Issue: Handler not found
**Solution**: Check handler implements `IRequestHandler<TQuery, TResponse>`

### Issue: Empty results from NHTSA
**Solution**: Check JSON property names match NHTSA response (use `JsonPropertyName`)

---

## Performance Considerations

### Caching Strategy
- **Makes**: Cached 24 hours (rarely changes)
- **Vehicle Types**: Not cached (varies by make)
- **Models**: Not cached (varies by make + year)

### HTTP Client
- Uses typed HttpClient pattern
- Connection pooling handled by .NET
- 30-second timeout configured

### Async/Await
- All I/O operations are async
- Prevents thread blocking
- Improves scalability

---

## Security Best Practices

1. **Input Validation**: FluentValidation on all inputs
2. **Exception Handling**: No sensitive data in error messages
3. **CORS**: Restricted to specific origins
4. **HTTPS**: Redirect configured (production)
5. **Dependency Injection**: No hardcoded credentials

---

## Summary

The backend architecture provides:

✅ **Clean separation of concerns** - Each layer has specific responsibility  
✅ **Testable code** - Easy to mock and unit test  
✅ **Maintainable** - Easy to understand and modify  
✅ **Scalable** - Can add features without breaking existing code  
✅ **Performant** - Caching, async/await, efficient pipeline  
✅ **Secure** - Validation, exception handling, CORS  
✅ **Well-documented** - Clear structure and patterns  

The CQRS + MediatR + Clean Architecture combination provides a robust, enterprise-grade foundation for building APIs.
