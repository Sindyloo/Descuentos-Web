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
RUN dotnet build "DescuentosWeb.csproj" -c Release -o /app/build --no-restore
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish --no-restore

# 3️⃣ Imagen final con Playwright y dependencias
FROM base AS final
WORKDIR /app

# 🔹 Instalar Node.js, npm y dependencias de Playwright
RUN apt-get update && apt-get install -y \
    wget curl ca-certificates \
    libglib2.0-0 libnss3 libgdk-pixbuf2.0-0 \
    libx11-xcb1 libatk-bridge2.0-0 libatk1.0-0 \
    libxcb-dri3-0 libxss1 libasound2 libxtst6 \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

# 🔹 Instalar Playwright con npm (NO con dotnet)
RUN npm install -g playwright && playwright install-deps && playwright install

# 🔹 Copiamos los archivos compilados
COPY --from=build /
