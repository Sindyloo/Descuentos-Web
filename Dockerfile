# Imagen base con .NET 6.0
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# Imagen de construcción con SDK de .NET 6.0
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copiar y restaurar dependencias
COPY ["DescuentosWeb/DescuentosWeb.csproj", "DescuentosWeb/"]
RUN dotnet restore "DescuentosWeb/DescuentosWeb.csproj"

# Copia el resto del código y compila
COPY . .
WORKDIR "/src/DescuentosWeb"
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish --no-restore

# Imagen final con Playwright
FROM base AS final
WORKDIR /app

# Instalar Node.js y Playwright
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g playwright && \
    npx playwright install --with-deps

# Copiar archivos compilados
COPY --from=build /app/publish .

# Comando de inicio
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
