namespace VehicleExplorer.Application.Common.Interfaces;

public interface ICacheable
{
    string CacheKey { get; }
    TimeSpan CacheDuration { get; }
}
