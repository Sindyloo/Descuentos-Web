# 🟢 1️⃣ Imagen base con Playwright y .NET 6.0
FROM mcr.microsoft.com/playwright/dotnet:v1.40.0-focal AS base
WORKDIR /app

# ⚠️ Railway usa el puerto 8080 por defecto
ENV PORT=8080
EXPOSE 8080

# 🟢 2️⃣ Imagen de compilación con SDK de .NET 6.0
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build
WORKDIR /src

# Copiar y restaurar dependencias
COPY ["DescuentosWeb/DescuentosWeb.csproj", "DescuentosWeb/"]
RUN dotnet restore "DescuentosWeb/DescuentosWeb.csproj"

# Copiar el resto del código y compilar
COPY . .
WORKDIR "/src/DescuentosWeb"
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish --no-restore

# 🟢 3️⃣ Imagen final con Chromium y Playwright
FROM base AS final
WORKDIR /app

# ⚠️ Instalar Node.js (si es necesario)
RUN apt-get update && apt-get install -y curl && \
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs 

# ⚠️ Instalar dependencias de Chromium necesarias para Playwright
RUN apt-get install -y \
    libnss3 \
    libatk1.0-0 \
    libxcomposite1 \
    libxrandr2 \
    libasound2 \
    libpangocairo-1.0-0 \
    libxdamage1 \
    libxcursor1 \
    libpango-1.0-0 \
    libglib2.0-0 \
    libgdk-pixbuf2.0-0 \
    libgtk-3-0 \
    libgbm-dev \
    xfonts-base \
    xfonts-75dpi

# ⚠️ Asegurar que Playwright y Chromium estén instalados
RUN npm install -g playwright@1.48.2 && npx playwright install --with-deps chromium

# Copiar archivos compilados
COPY --from=build /app/publish .

# Comando de inicio
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
