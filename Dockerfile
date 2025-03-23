# 1️⃣ Imagen base para la ejecución con .NET 6.0
FROM mcr.microsoft.com/dotnet/aspnet:6.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# 2️⃣ Imagen de construcción con SDK de .NET 6.0
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copia y restaura dependencias
COPY ["DescuentosWeb/DescuentosWeb.csproj", "DescuentosWeb/"]
RUN dotnet restore "DescuentosWeb/DescuentosWeb.csproj"

# Copia el resto del código y compílalo
COPY . . 
WORKDIR "/src/DescuentosWeb"
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish --no-restore

# 3️⃣ Imagen final con Playwright y dependencias
FROM base AS final
WORKDIR /app

# 🔹 Instalar Node.js antes de npm
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 🔹 Instalar Playwright con npm
RUN npm install -g playwright && playwright install-deps && playwright install

# 🔹 Copiar archivos compilados
COPY --from=build /app/publish .

# Comando de inicio
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
