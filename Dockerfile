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

# Copia el resto del código y compílalo
COPY . . 
WORKDIR "/src/DescuentosWeb"
RUN dotnet build "DescuentosWeb.csproj" -c Release -o /app/build

# Publica la aplicación
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish

# 3️⃣ Imagen final con dependencias de Playwright
FROM base AS final
WORKDIR /app

# 🔹 Instalar Node.js 18 y actualizar npm
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest

# 🔹 Instalar dependencias necesarias para Playwright
RUN apt-get install -y \
    libglib2.0-0 libnss3 libgdk-pixbuf2.0-0 \
    libx11-xcb1 libatk-bridge2.0-0 libatk1.0-0 \
    libxcb-dri3-0 libxss1 libasound2 libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# 🔹 Instalar Playwright correctamente usando la CLI oficial de .NET
RUN dotnet tool install --global Microsoft.Playwright.CLI && playwright install-deps && playwright install

# 🔹 Copiamos los archivos compilados de la imagen de construcción
COPY --from=build /app/publish .

# 🔹 Configurar el punto de entrada
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
