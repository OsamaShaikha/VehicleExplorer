using MediatR;
using Microsoft.Extensions.Caching.Memory;
using VehicleExplorer.Application.Common.Interfaces;

namespace VehicleExplorer.Application.Common.Behaviors;

public class CachingBehavior<TRequest, TResponse> : IPipelineBehavior<TRequest, TResponse>
    where TRequest : IRequest<TResponse>
{
    private readonly IMemoryCache _cache;

    public CachingBehavior(IMemoryCache cache)
    {
        _cache = cache;
    }

    public async Task<TResponse> Handle(TRequest request, RequestHandlerDelegate<TResponse> next, CancellationToken cancellationToken)
    {
        if (request is not ICacheable cacheable)
            return await next();

        if (_cache.TryGetValue(cacheable.CacheKey, out TResponse? cachedResponse) && cachedResponse is not null)
            return cachedResponse;

        var response = await next();

        _cache.Set(cacheable.CacheKey, response, cacheable.CacheDuration);

        return response;
    }
}
