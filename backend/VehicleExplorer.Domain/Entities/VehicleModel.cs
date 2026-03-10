namespace VehicleExplorer.Domain.Entities;

public class VehicleModel
{
    public int Id { get; private set; }
    public string Name { get; private set; } = string.Empty;

    private VehicleModel() { }

    public static VehicleModel Create(int id, string name)
    {
        if (id <= 0)
            throw new ArgumentException("Vehicle model ID must be positive.", nameof(id));

        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Vehicle model name cannot be empty.", nameof(name));

        return new VehicleModel
        {
            Id = id,
            Name = name.Trim()
        };
    }
}
