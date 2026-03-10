using FluentValidation;
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
