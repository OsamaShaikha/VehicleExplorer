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
