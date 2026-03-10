namespace VehicleExplorer.Domain.Entities;

public class VehicleType
{
    public int Id { get; private set; }
    public string Name { get; private set; } = string.Empty;

    private VehicleType() { }

    public static VehicleType Create(int id, string name)
    {
        if (id <= 0)
            throw new ArgumentException("Vehicle type ID must be positive.", nameof(id));

        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Vehicle type name cannot be empty.", nameof(name));

        return new VehicleType
        {
            Id = id,
            Name = name.Trim()
        };
    }
}
