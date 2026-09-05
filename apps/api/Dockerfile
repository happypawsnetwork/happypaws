FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy the solution file and project files
COPY ["HappyPaws.slnx", "./"]
COPY ["HappyPaws.Api/HappyPaws.Api.csproj", "HappyPaws.Api/"]
COPY ["HappyPaws.Application/HappyPaws.Application.csproj", "HappyPaws.Application/"]
COPY ["HappyPaws.Domain/HappyPaws.Domain.csproj", "HappyPaws.Domain/"]
COPY ["HappyPaws.Infrastructure/HappyPaws.Infrastructure.csproj", "HappyPaws.Infrastructure/"]

# Restore dependencies
RUN dotnet restore "HappyPaws.slnx"

# Copy the remaining source code
COPY . .

# Publish the API
WORKDIR "/src/HappyPaws.Api"
RUN dotnet publish "HappyPaws.Api.csproj" -c Release -o /app/publish /p:UseAppHost=false

# Use the ASP.NET runtime image for the final image
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS final
WORKDIR /app

# Install curl for container health checks
RUN apt-get update && apt-get install -y --no-install-recommends curl && rm -rf /var/lib/apt/lists/*

# The default port for ASP.NET Core containers is 8080
EXPOSE 8080

COPY --from=build /app/publish .

# Tell Render to use port 8080 (optional but good practice)
ENV ASPNETCORE_HTTP_PORTS=8080

ENTRYPOINT ["dotnet", "HappyPaws.Api.dll"]
