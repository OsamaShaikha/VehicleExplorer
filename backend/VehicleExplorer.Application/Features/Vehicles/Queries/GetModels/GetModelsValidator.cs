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
