namespace VehicleExplorer.Domain.Entities;

public class Make
{
    public int Id { get; private set; }
    public string Name { get; private set; } = string.Empty;

    private Make() { }

    public static Make Create(int id, string name)
    {
        if (id <= 0)
            throw new ArgumentException("Make ID must be positive.", nameof(id));

        if (string.IsNullOrWhiteSpace(name))
            throw new ArgumentException("Make name cannot be empty.", nameof(name));

        return new Make
        {
            Id = id,
            Name = name.Trim()
        };
    }
}
