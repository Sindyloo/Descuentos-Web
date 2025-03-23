# 1️⃣ Imagen base para la ejecución
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443

# 2️⃣ Imagen de construcción con SDK de .NET
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copia y restaura dependencias
COPY ["DescuentosWeb/DescuentosWeb.csproj", "DescuentosWeb/"]
RUN dotnet restore "DescuentosWeb/DescuentosWeb.csproj"

# Copia el resto del código y compílalo en pasos separados (ahorra memoria)
COPY . . 
WORKDIR "/src/DescuentosWeb"

# 🔹 Optimización para evitar consumo alto de memoria en Railway
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish --no-restore -p:UseSharedCompilation=false -p:ConcurrentBuild=false

# 3️⃣ Imagen final con Playwright y dependencias
FROM base AS final
WORKDIR /app

# 🔹 Instalar Node.js antes de npm
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

# 🔹 Instalar Playwright con npm (NO con dotnet)
RUN npm install -g playwright && playwright install-deps && playwright install

# 🔹 Copiamos los archivos compilados
COPY --from=build /app/publish .

# Comando de inicio
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
