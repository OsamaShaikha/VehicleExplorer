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
