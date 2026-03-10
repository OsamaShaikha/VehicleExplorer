FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["VehicleExplorer.Domain/VehicleExplorer.Domain.csproj", "VehicleExplorer.Domain/"]
COPY ["VehicleExplorer.Application/VehicleExplorer.Application.csproj", "VehicleExplorer.Application/"]
COPY ["VehicleExplorer.Infrastructure/VehicleExplorer.Infrastructure.csproj", "VehicleExplorer.Infrastructure/"]
COPY ["VehicleExplorer.API/VehicleExplorer.API.csproj", "VehicleExplorer.API/"]

RUN dotnet restore "VehicleExplorer.API/VehicleExplorer.API.csproj"

COPY . .
WORKDIR "/src/VehicleExplorer.API"
RUN dotnet build "VehicleExplorer.API.csproj" -c Release -o /app/build

FROM build AS publish
RUN dotnet publish "VehicleExplorer.API.csproj" -c Release -o /app/publish

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app
COPY --from=publish /app/publish .
EXPOSE 5000
ENV ASPNETCORE_URLS=http://+:5000
ENTRYPOINT ["dotnet", "VehicleExplorer.API.dll"]
