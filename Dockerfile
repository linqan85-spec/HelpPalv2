FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy project files
COPY ["backend/HelpPal.Server/HelpPal.Server.csproj", "backend/HelpPal.Server/"]
COPY ["backend/HelpPal.Models/HelpPal.Models.csproj", "backend/HelpPal.Models/"]
COPY ["backend/HelpPal.Services/HelpPal.Services.csproj", "backend/HelpPal.Services/"]
COPY ["backend/HelpPal.Repositories/HelpPal.Repositories.csproj", "backend/HelpPal.Repositories/"]
COPY ["backend/HelpPal.Utils/HelpPal.Utils.csproj", "backend/HelpPal.Utils/"]
COPY ["backend/HelpPal.Validators/HelpPal.Validators.csproj", "backend/HelpPal.Validators/"]
COPY ["backend/HelpPal.Integrations/HelpPal.Integrations.csproj", "backend/HelpPal.Integrations/"]
COPY ["backend/HelpPal.PdfGenerator/HelpPal.PdfGenerator.csproj", "backend/HelpPal.PdfGenerator/"]
COPY ["backend/HelpPal.TaskScheduler/HelpPal.TaskScheduler.csproj", "backend/HelpPal.TaskScheduler/"]
COPY ["backend/HelpPal.DbMigrations/HelpPal.DbMigrations.csproj", "backend/HelpPal.DbMigrations/"]

# Restore dependencies
RUN dotnet restore "backend/HelpPal.Server/HelpPal.Server.csproj"

# Copy everything else
COPY . .

# Build the application
WORKDIR "/src/backend/HelpPal.Server"
RUN dotnet build "HelpPal.Server.csproj" -c Release -o /app/build

# Publish the application
FROM build AS publish
RUN dotnet publish "HelpPal.Server.csproj" -c Release -o /app/publish

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

# Install MySQL client for health checks
RUN apt-get update && apt-get install -y default-mysql-client && rm -rf /var/lib/apt/lists/*

COPY --from=publish /app/publish .

# Expose port
EXPOSE 8080

# Set environment variables
ENV ASPNETCORE_URLS=http://0.0.0.0:8080
ENV ASPNETCORE_ENVIRONMENT=Production

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["dotnet", "HelpPal.Server.dll"]
