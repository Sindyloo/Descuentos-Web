# Imagen base con .NET 6.0
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app

# ⚠️ Railway usa el puerto 8080 por defecto
ENV PORT=3000
EXPOSE 3000

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

# ⚠️ Instalar Node.js, npm y Playwright con dependencias necesarias
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g playwright && \
    npx playwright install --with-deps

# Copiar archivos compilados
COPY --from=build /app/publish .

# Comando de inicio
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
