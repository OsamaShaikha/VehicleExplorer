# MediatR - Complete Guide

## What is MediatR?

MediatR is a **Mediator Pattern** implementation for .NET that enables **in-process messaging**. It decouples the sender of a request from the handler that processes it.

### The Problem MediatR Solves

**Without MediatR:**
```csharp
public class VehiclesController
{
    private readonly IVehicleRepository _repository;
    private readonly ILogger _logger;
    private readonly IMemoryCache _cache;
    private readonly IValidator _validator;
    
    public VehiclesController(IVehicleRepository repo, ILogger logger, IMemoryCache cache, IValidator validator)
    {
        _repository = repo;
        _logger = logger;
        _cache = cache;
        _validator = validator;
    }
    
    public async Task<IActionResult> GetMakes()
    {
        // Logging
        _logger.LogInformation("Getting makes");
        var sw = Stopwatch.StartNew();
        
        // Validation
        // ... validation logic
        
        // Caching
        if (_cache.TryGetValue("makes", out var cached))
            return Ok(cached);
        
        // Business logic
        var makes = await _repository.GetAllMakesAsync();
        var dtos = makes.Select(m => new MakeDto(m.Id, m.Name)).ToList();
        
        // Cache result
        _cache.Set("makes", dtos, TimeSpan.FromHours(24));
        
        // Logging
        sw.Stop();
        _logger.LogInformation($"Completed in {sw.ElapsedMilliseconds}ms");
        
        return Ok(dtos);
    }
}
```

**Problems:**
- Controller has too many dependencies
- Cross-cutting concerns (logging, caching, validation) mixed with business logic
- Hard to test
- Code duplication across endpoints
- Violates Single Responsibility Principle

**With MediatR:**
```csharp
public class VehiclesController
{
    private readonly IMediator _mediator;
    
    public VehiclesController(IMediator mediator)
    {
        _mediator = mediator;
    }
    
    public async Task<IActionResult> GetMakes(CancellationToken ct)
        => Ok(await _mediator.Send(new GetAllMakesQuery(), ct));
}
```

**Benefits:**
- Single dependency (IMediator)
- Clean, readable code
- Cross-cutting concerns handled by pipeline behaviors
- Easy to test
- Business logic separated from infrastructure

---

## Core Concepts

### 1. Request (Query/Command)

A request is a simple message object that represents an intent.

```csharp
// This is a REQUEST
public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>;
```

**Key Points:**
- Implements `IRequest<TResponse>` where TResponse is the return type
- Immutable (using `record`)
- Contains only data needed for the request
- No logic - just a data container


### 2. Handler

A handler processes a specific request type.

```csharp
// This is a HANDLER
public class GetAllMakesHandler : IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>>
{
    private readonly IVehicleRepository _repository;
    
    public GetAllMakesHandler(IVehicleRepository repository)
    {
        _repository = repository;
    }
    
    public async Task<ApiResponse<List<MakeDto>>> Handle(GetAllMakesQuery request, CancellationToken ct)
    {
        var makes = await _repository.GetAllMakesAsync(ct);
        var dtos = makes.Select(m => new MakeDto(m.Id, m.Name)).ToList();
        return ApiResponse<List<MakeDto>>.Ok(dtos);
    }
}
```

**Key Points:**
- Implements `IRequestHandler<TRequest, TResponse>`
- One handler per request type
- Contains the business logic
- Can have dependencies injected

### 3. Mediator

The mediator routes requests to appropriate handlers.

```csharp
// In controller
var result = await _mediator.Send(new GetAllMakesQuery(), cancellationToken);
```

**What happens:**
1. Mediator receives the request
2. Finds the registered handler for that request type
3. Executes pipeline behaviors (if any)
4. Calls the handler
5. Returns the response

---

## How MediatR Works Internally

### Registration Process

```csharp
// In DependencyInjection.cs
services.AddMediatR(cfg =>
{
    cfg.RegisterServicesFromAssembly(Assembly.GetExecutingAssembly());
});
```

**What this does:**
1. Scans the assembly for all classes implementing `IRequestHandler<,>`
2. Registers each handler with the DI container
3. Registers the `IMediator` implementation
4. Creates a mapping: Request Type → Handler Type

**Example mapping created:**
```
GetAllMakesQuery → GetAllMakesHandler
GetVehicleTypesQuery → GetVehicleTypesHandler
GetModelsQuery → GetModelsHandler
```

### Request Execution Flow

```csharp
await _mediator.Send(new GetAllMakesQuery(), ct);
```

**Step-by-step:**

```
1. _mediator.Send() is called
   ↓
2. MediatR looks up handler for GetAllMakesQuery
   - Finds: GetAllMakesHandler
   ↓
3. MediatR resolves handler from DI container
   - Creates instance with dependencies
   ↓
4. MediatR executes pipeline behaviors (if registered)
   - LoggingBehavior
   - ValidationBehavior
   - CachingBehavior
   ↓
5. MediatR calls handler.Handle()
   ↓
6. Handler executes business logic
   ↓
7. Handler returns response
   ↓
8. Response flows back through behaviors
   ↓
9. Response returned to caller
```

---

## Pipeline Behaviors - The Magic

Pipeline behaviors wrap around handler execution, allowing cross-cutting concerns.

### How Behaviors Work

```csharp
public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    public async Task<TResponse> Handle(
        TRequest request, 
        RequestHandlerDelegate<TResponse> next,  // ← This is the "next" in the pipeline
        CancellationToken ct)
    {
        // BEFORE handler execution
        Console.WriteLine("Before handler");
        
        var response = await next();  // ← Calls next behavior or handler
        
        // AFTER handler execution
        Console.WriteLine("After handler");
        
        return response;
    }
}
```

### Pipeline Execution Order

```csharp
services.AddMediatR(cfg =>
{
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));      // 1st
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));   // 2nd
    cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(CachingBehavior<,>));      // 3rd
});
```

**Execution flow:**
```
Request
  ↓
LoggingBehavior (before)
  ↓
ValidationBehavior (before)
  ↓
CachingBehavior (before)
  ↓
HANDLER
  ↓
CachingBehavior (after)
  ↓
ValidationBehavior (after)
  ↓
LoggingBehavior (after)
  ↓
Response
```


### Visual Example with Our Behaviors

```
_mediator.Send(new GetAllMakesQuery())
    ↓
┌─────────────────────────────────────────┐
│ LoggingBehavior                         │
│ • Logs "[START] GetAllMakesQuery"      │
│ • Starts stopwatch                      │
│   ↓                                     │
│ ┌─────────────────────────────────────┐ │
│ │ ValidationBehavior                  │ │
│ │ • Checks for validators             │ │
│ │ • None found, continues             │ │
│ │   ↓                                 │ │
│ │ ┌─────────────────────────────────┐ │ │
│ │ │ CachingBehavior                 │ │ │
│ │ │ • Checks cache for key          │ │ │
│ │ │ • Cache MISS                    │ │ │
│ │ │   ↓                             │ │ │
│ │ │ ┌─────────────────────────────┐ │ │ │
│ │ │ │ GetAllMakesHandler          │ │ │ │
│ │ │ │ • Calls repository          │ │ │ │
│ │ │ │ • Gets makes from NHTSA     │ │ │ │
│ │ │ │ • Converts to DTOs          │ │ │ │
│ │ │ │ • Returns response          │ │ │ │
│ │ │ └─────────────────────────────┘ │ │ │
│ │ │   ↓                             │ │ │
│ │ │ • Stores in cache (24h)         │ │ │
│ │ └─────────────────────────────────┘ │ │
│ │   ↓                                 │ │
│ │ • No post-processing                │ │
│ └─────────────────────────────────────┘ │
│   ↓                                     │
│ • Stops stopwatch                       │
│ • Logs "[END] completed in 1200ms"     │
└─────────────────────────────────────────┘
    ↓
Response returned to controller
```

---

## Real-World Examples from Our Project

### Example 1: Simple Query (No Parameters)

```csharp
// 1. Define the request
public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>, ICacheable
{
    public string CacheKey => "vehicles:makes:all";
    public TimeSpan CacheDuration => TimeSpan.FromHours(24);
}

// 2. Define the handler
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

// 3. Use in controller
[HttpGet("makes")]
public async Task<IActionResult> GetAllMakes(CancellationToken ct)
    => Ok(await _mediator.Send(new GetAllMakesQuery(), ct));
```

**What happens:**
1. Controller creates `GetAllMakesQuery` instance
2. Sends to MediatR
3. LoggingBehavior logs start
4. ValidationBehavior skips (no validator)
5. CachingBehavior checks cache (implements ICacheable)
6. If cache miss: Handler executes
7. CachingBehavior stores result
8. LoggingBehavior logs completion
9. Response returned

### Example 2: Query with Parameters and Validation

```csharp
// 1. Request with parameters
public record GetModelsQuery(int MakeId, int Year) : IRequest<ApiResponse<List<VehicleModelDto>>>;

// 2. Validator
public class GetModelsValidator : AbstractValidator<GetModelsQuery>
{
    public GetModelsValidator()
    {
        RuleFor(x => x.MakeId).GreaterThan(0);
        RuleFor(x => x.Year).InclusiveBetween(1995, DateTime.Now.Year);
    }
}

// 3. Handler
public class GetModelsHandler : IRequestHandler<GetModelsQuery, ApiResponse<List<VehicleModelDto>>>
{
    private readonly IVehicleRepository _repository;
    
    public GetModelsHandler(IVehicleRepository repository) => _repository = repository;
    
    public async Task<ApiResponse<List<VehicleModelDto>>> Handle(GetModelsQuery request, CancellationToken ct)
    {
        var models = await _repository.GetModelsForMakeAndYearAsync(request.MakeId, request.Year, ct);
        var dtos = models.Select(m => new VehicleModelDto(m.Id, m.Name)).ToList();
        return ApiResponse<List<VehicleModelDto>>.Ok(dtos);
    }
}

// 4. Controller
[HttpGet("makes/{makeId:int}/models")]
public async Task<IActionResult> GetModels(int makeId, [FromQuery] int year, CancellationToken ct)
    => Ok(await _mediator.Send(new GetModelsQuery(makeId, year), ct));
```

**What happens:**
1. Controller creates `GetModelsQuery(448, 2020)`
2. Sends to MediatR
3. LoggingBehavior logs start
4. ValidationBehavior finds `GetModelsValidator`
   - Validates MakeId > 0 ✓
   - Validates Year between 1995-2026 ✓
   - If validation fails: throws ValidationException (caught by middleware)
5. CachingBehavior skips (doesn't implement ICacheable)
6. Handler executes
7. LoggingBehavior logs completion
8. Response returned


---

## Deep Dive: How Each Behavior Works

### 1. LoggingBehavior - Detailed Breakdown

```csharp
public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly ILogger<LoggingBehavior<TRequest, TResponse>> _logger;
    
    public LoggingBehavior(ILogger<LoggingBehavior<TRequest, TResponse>> logger) 
        => _logger = logger;
    
    public async Task<TResponse> Handle(
        TRequest request, 
        RequestHandlerDelegate<TResponse> next, 
        CancellationToken ct)
    {
        // 1. Get request type name
        var name = typeof(TRequest).Name;  // "GetAllMakesQuery"
        
        // 2. Log request start with payload
        _logger.LogInformation("[START] {Request}: {@Payload}", name, request);
        // Output: [START] GetAllMakesQuery: GetAllMakesQuery { }
        
        // 3. Start timing
        var sw = Stopwatch.StartNew();
        
        // 4. Call next behavior/handler
        var response = await next();
        
        // 5. Stop timing
        sw.Stop();
        
        // 6. Log completion with duration
        _logger.LogInformation("[END] {Request} completed in {Ms}ms", name, sw.ElapsedMilliseconds);
        // Output: [END] GetAllMakesQuery completed in 1200ms
        
        // 7. Return response unchanged
        return response;
    }
}
```

**Purpose**: Provides observability - you can see every request and how long it takes.

### 2. ValidationBehavior - Detailed Breakdown

```csharp
public class ValidationBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IEnumerable<IValidator<TRequest>> _validators;
    
    // DI injects ALL validators for this request type
    public ValidationBehavior(IEnumerable<IValidator<TRequest>> validators) 
        => _validators = validators;
    
    public async Task<TResponse> Handle(
        TRequest request, 
        RequestHandlerDelegate<TResponse> next, 
        CancellationToken ct)
    {
        // 1. Check if any validators exist
        if (!_validators.Any()) 
            return await next();  // No validators, skip validation
        
        // 2. Create validation context
        var context = new ValidationContext<TRequest>(request);
        
        // 3. Run ALL validators and collect failures
        var failures = _validators
            .Select(v => v.Validate(context))           // Run each validator
            .SelectMany(r => r.Errors)                  // Flatten all errors
            .Where(f => f is not null)                  // Remove nulls
            .ToList();
        
        // 4. If any failures, throw exception
        if (failures.Count > 0)
            throw new ValidationException(failures);
        
        // 5. Validation passed, continue to next behavior/handler
        return await next();
    }
}
```

**Example validation failure:**
```csharp
// Request: GetModelsQuery(0, 1990)
// Validator rules:
//   - MakeId > 0  ❌ FAILS (0 is not > 0)
//   - Year 1995-2026  ❌ FAILS (1990 < 1995)

// ValidationException thrown with:
// - "MakeId must be a positive integer."
// - "Year must be between 1995 and 2026."

// ExceptionHandlingMiddleware catches it:
// - Returns HTTP 400 Bad Request
// - Body: { "success": false, "error": "MakeId must be...; Year must be..." }
```

### 3. CachingBehavior - Detailed Breakdown

```csharp
public class CachingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IMemoryCache _cache;
    
    public CachingBehavior(IMemoryCache cache) => _cache = cache;
    
    public async Task<TResponse> Handle(
        TRequest request, 
        RequestHandlerDelegate<TResponse> next, 
        CancellationToken ct)
    {
        // 1. Check if request implements ICacheable
        if (request is not ICacheable cacheable) 
            return await next();  // Not cacheable, skip caching
        
        // 2. Try to get from cache
        if (_cache.TryGetValue(cacheable.CacheKey, out TResponse? cached) && cached is not null)
        {
            // Cache HIT - return immediately without calling handler
            return cached;
        }
        
        // 3. Cache MISS - execute handler
        var response = await next();
        
        // 4. Store in cache with specified duration
        _cache.Set(cacheable.CacheKey, response, cacheable.CacheDuration);
        
        // 5. Return response
        return response;
    }
}
```

**Example flow:**

**First request:**
```
Request: GetAllMakesQuery
  ↓
CachingBehavior checks cache for "vehicles:makes:all"
  ↓
Cache MISS (not found)
  ↓
Calls handler (takes 1200ms)
  ↓
Stores result in cache (expires in 24 hours)
  ↓
Returns result
```

**Second request (within 24 hours):**
```
Request: GetAllMakesQuery
  ↓
CachingBehavior checks cache for "vehicles:makes:all"
  ↓
Cache HIT (found!)
  ↓
Returns cached result immediately (0ms)
  ↓
Handler never called!
```

---

## MediatR vs Traditional Approach

### Scenario: Adding Logging to All Endpoints

**Traditional Approach:**
```csharp
public class VehiclesController
{
    public async Task<IActionResult> GetMakes()
    {
        _logger.LogInformation("Getting makes");
        var sw = Stopwatch.StartNew();
        // ... logic
        sw.Stop();
        _logger.LogInformation($"Completed in {sw.ElapsedMilliseconds}ms");
        return Ok(result);
    }
    
    public async Task<IActionResult> GetTypes(int makeId)
    {
        _logger.LogInformation("Getting types");
        var sw = Stopwatch.StartNew();
        // ... logic
        sw.Stop();
        _logger.LogInformation($"Completed in {sw.ElapsedMilliseconds}ms");
        return Ok(result);
    }
    
    // Repeat for every endpoint... 😫
}
```

**MediatR Approach:**
```csharp
// Add ONE behavior
public class LoggingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
{
    // ... implementation
}

// Register it ONCE
cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(LoggingBehavior<,>));

// ALL requests now have logging automatically! ✨
```


---

## Advanced Concepts

### 1. Request vs Command vs Query

**Query** (Read operation):
```csharp
public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>;
```
- Returns data
- Doesn't modify state
- Can be cached
- Idempotent (same result every time)

**Command** (Write operation):
```csharp
public record CreateMakeCommand(string Name) : IRequest<ApiResponse<MakeDto>>;
```
- Modifies state
- Usually not cached
- May have side effects
- Not idempotent

**Note**: Our project only uses Queries (read-only operations).

### 2. Generic Handlers

You can create generic handlers for common patterns:

```csharp
public class CachedQueryHandler<TQuery, TResponse> : IRequestHandler<TQuery, TResponse>
    where TQuery : IRequest<TResponse>, ICacheable
{
    // Generic handler for all cached queries
}
```

### 3. Notifications (Pub/Sub)

MediatR also supports notifications (not used in our project):

```csharp
// Notification
public record MakeCreatedNotification(int MakeId) : INotification;

// Multiple handlers can handle same notification
public class SendEmailHandler : INotificationHandler<MakeCreatedNotification> { }
public class LogHandler : INotificationHandler<MakeCreatedNotification> { }
public class CacheInvalidationHandler : INotificationHandler<MakeCreatedNotification> { }

// Publish
await _mediator.Publish(new MakeCreatedNotification(123));
// All 3 handlers execute in parallel
```

### 4. Pre/Post Processors

Alternative to behaviors for simpler scenarios:

```csharp
public class LoggingPreProcessor<TRequest> : IRequestPreProcessor<TRequest>
{
    public Task Process(TRequest request, CancellationToken ct)
    {
        Console.WriteLine($"Processing {typeof(TRequest).Name}");
        return Task.CompletedTask;
    }
}
```

---

## Testing with MediatR

### Testing a Handler in Isolation

```csharp
[Fact]
public async Task GetAllMakesHandler_ShouldReturnMakes()
{
    // Arrange
    var mockRepo = new Mock<IVehicleRepository>();
    mockRepo.Setup(r => r.GetAllMakesAsync(It.IsAny<CancellationToken>()))
        .ReturnsAsync(new List<Make> 
        { 
            Make.Create(1, "Toyota"),
            Make.Create(2, "Honda")
        });
    
    var handler = new GetAllMakesHandler(mockRepo.Object);
    var query = new GetAllMakesQuery();
    
    // Act
    var result = await handler.Handle(query, CancellationToken.None);
    
    // Assert
    Assert.True(result.Success);
    Assert.Equal(2, result.Count);
    Assert.Equal("Toyota", result.Data[0].MakeName);
}
```

### Testing with MediatR Pipeline

```csharp
[Fact]
public async Task GetAllMakes_ShouldBeCached()
{
    // Arrange
    var services = new ServiceCollection();
    services.AddMediatR(cfg => cfg.RegisterServicesFromAssembly(typeof(GetAllMakesQuery).Assembly));
    services.AddMemoryCache();
    services.AddSingleton<IVehicleRepository, MockRepository>();
    
    var provider = services.BuildServiceProvider();
    var mediator = provider.GetRequiredService<IMediator>();
    
    // Act
    var result1 = await mediator.Send(new GetAllMakesQuery());
    var result2 = await mediator.Send(new GetAllMakesQuery());
    
    // Assert
    Assert.Same(result1, result2); // Same instance = cached
}
```

---

## Common Patterns and Best Practices

### 1. One Handler Per Request

```csharp
// ✅ GOOD
public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>;
public class GetAllMakesHandler : IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>> { }

// ❌ BAD - Don't reuse handlers
public class VehicleHandler : 
    IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>>,
    IRequestHandler<GetVehicleTypesQuery, ApiResponse<List<VehicleTypeDto>>>
{
    // Too much responsibility!
}
```

### 2. Keep Requests Immutable

```csharp
// ✅ GOOD - Immutable record
public record GetModelsQuery(int MakeId, int Year) : IRequest<ApiResponse<List<VehicleModelDto>>>;

// ❌ BAD - Mutable class
public class GetModelsQuery : IRequest<ApiResponse<List<VehicleModelDto>>>
{
    public int MakeId { get; set; }  // Can be changed!
    public int Year { get; set; }
}
```

### 3. Use Descriptive Names

```csharp
// ✅ GOOD
public record GetAllMakesQuery() : IRequest<ApiResponse<List<MakeDto>>>;
public record GetVehicleTypesForMakeQuery(int MakeId) : IRequest<ApiResponse<List<VehicleTypeDto>>>;

// ❌ BAD
public record Query1() : IRequest<ApiResponse<List<MakeDto>>>;
public record GetStuff(int Id) : IRequest<ApiResponse<List<VehicleTypeDto>>>;
```

### 4. Validate in Behaviors, Not Handlers

```csharp
// ✅ GOOD - Validation in validator
public class GetModelsValidator : AbstractValidator<GetModelsQuery>
{
    public GetModelsValidator()
    {
        RuleFor(x => x.MakeId).GreaterThan(0);
    }
}

// ❌ BAD - Validation in handler
public class GetModelsHandler : IRequestHandler<GetModelsQuery, ApiResponse<List<VehicleModelDto>>>
{
    public async Task<ApiResponse<List<VehicleModelDto>>> Handle(GetModelsQuery request, CancellationToken ct)
    {
        if (request.MakeId <= 0)  // Don't do this!
            throw new ArgumentException("Invalid MakeId");
        // ...
    }
}
```

### 5. Keep Handlers Focused

```csharp
// ✅ GOOD - Single responsibility
public class GetAllMakesHandler : IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>>
{
    public async Task<ApiResponse<List<MakeDto>>> Handle(GetAllMakesQuery request, CancellationToken ct)
    {
        var makes = await _repository.GetAllMakesAsync(ct);
        var dtos = makes.Select(m => new MakeDto(m.Id, m.Name)).ToList();
        return ApiResponse<List<MakeDto>>.Ok(dtos);
    }
}

// ❌ BAD - Too much responsibility
public class GetAllMakesHandler : IRequestHandler<GetAllMakesQuery, ApiResponse<List<MakeDto>>>
{
    public async Task<ApiResponse<List<MakeDto>>> Handle(GetAllMakesQuery request, CancellationToken ct)
    {
        // Logging
        _logger.LogInformation("Getting makes");
        
        // Validation
        if (someCondition) throw new Exception();
        
        // Caching
        if (_cache.TryGetValue("makes", out var cached)) return cached;
        
        // Business logic
        var makes = await _repository.GetAllMakesAsync(ct);
        
        // More caching
        _cache.Set("makes", makes);
        
        // More logging
        _logger.LogInformation("Done");
        
        return result;
    }
}
```


---

## Performance Considerations

### 1. Handler Resolution

MediatR uses reflection to find handlers, but this is cached:

```csharp
// First call: Uses reflection (slower)
await _mediator.Send(new GetAllMakesQuery());

// Subsequent calls: Uses cached mapping (fast)
await _mediator.Send(new GetAllMakesQuery());
```

### 2. Behavior Overhead

Each behavior adds minimal overhead (~1-2ms per behavior):

```
No behaviors: 1000ms
With 3 behaviors: 1003ms
```

The benefits (logging, validation, caching) far outweigh the cost.

### 3. Memory Allocation

Records are lightweight and allocated on the heap:

```csharp
// Minimal allocation
var query = new GetAllMakesQuery();  // ~40 bytes
```

---

## Troubleshooting

### Issue: Handler Not Found

**Error**: `InvalidOperationException: Handler was not found for request`

**Cause**: Handler not registered or wrong assembly scanned

**Solution**:
```csharp
// Make sure you're scanning the correct assembly
services.AddMediatR(cfg => 
    cfg.RegisterServicesFromAssembly(typeof(GetAllMakesQuery).Assembly));
```

### Issue: Multiple Handlers for Same Request

**Error**: `InvalidOperationException: Multiple handlers registered`

**Cause**: Two classes implement `IRequestHandler<SameRequest, SameResponse>`

**Solution**: Only one handler per request type allowed.

### Issue: Validator Not Running

**Cause**: Validator not registered or ValidationBehavior not added

**Solution**:
```csharp
// Register validators
services.AddValidatorsFromAssembly(Assembly.GetExecutingAssembly());

// Add ValidationBehavior
cfg.AddBehavior(typeof(IPipelineBehavior<,>), typeof(ValidationBehavior<,>));
```

### Issue: Caching Not Working

**Cause**: Request doesn't implement `ICacheable` or IMemoryCache not registered

**Solution**:
```csharp
// Implement ICacheable
public record MyQuery() : IRequest<MyResponse>, ICacheable
{
    public string CacheKey => "my-key";
    public TimeSpan CacheDuration => TimeSpan.FromMinutes(30);
}

// Register IMemoryCache
services.AddMemoryCache();
```

---

## Summary

### What MediatR Provides

✅ **Decoupling**: Controllers don't know about handlers  
✅ **Single Responsibility**: Each handler does one thing  
✅ **Cross-Cutting Concerns**: Behaviors handle logging, validation, caching  
✅ **Testability**: Easy to test handlers in isolation  
✅ **Maintainability**: Easy to add new features without modifying existing code  
✅ **Consistency**: All requests flow through same pipeline  
✅ **Flexibility**: Easy to add/remove behaviors globally  

### Key Takeaways

1. **Request** = Message (what you want to do)
2. **Handler** = Processor (how to do it)
3. **Mediator** = Router (connects request to handler)
4. **Behaviors** = Pipeline (cross-cutting concerns)

### The MediatR Flow

```
Controller → Mediator → Behaviors → Handler → Response
```

### When to Use MediatR

✅ Use when:
- Building CQRS applications
- Need cross-cutting concerns (logging, validation, caching)
- Want to decouple controllers from business logic
- Building complex applications with many operations

❌ Don't use when:
- Building very simple CRUD apps
- Performance is absolutely critical (microseconds matter)
- Team is unfamiliar with the pattern

---

## Additional Resources

- [MediatR GitHub](https://github.com/jbogard/MediatR)
- [Jimmy Bogard's Blog](https://jimmybogard.com/) (creator of MediatR)
- [CQRS Pattern](https://martinfowler.com/bliki/CQRS.html)
- [Mediator Pattern](https://refactoring.guru/design-patterns/mediator)

---

**Congratulations!** You now understand how MediatR works and why it's so powerful for building maintainable applications! 🎉
