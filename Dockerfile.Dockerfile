# Utiliza una imagen base de .NET para la construcción
FROM mcr.microsoft.com/dotnet/aspnet:7.0 AS base
WORKDIR /app
EXPOSE 80

# Usamos la imagen de SDK de .NET para compilar la aplicación
FROM mcr.microsoft.com/dotnet/sdk:7.0 AS build
WORKDIR /src

# Copia el archivo csproj y restaura las dependencias
COPY ["DescuentosWeb/DescuentosWeb.csproj", "DescuentosWeb/"]
RUN dotnet restore "DescuentosWeb/DescuentosWeb.csproj"

# Copia el resto del código y compílalo
COPY . .
WORKDIR "/src/DescuentosWeb"
RUN dotnet build "DescuentosWeb.csproj" -c Release -o /app/build

# Publica la aplicación
RUN dotnet publish "DescuentosWeb.csproj" -c Release -o /app/publish

# Instalar las dependencias necesarias para Playwright
FROM base AS final
WORKDIR /app

# Instalar las dependencias necesarias para Playwright
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    libglib2.0-0 \
    libnss3 \
    libgdk-pixbuf2.0-0 \
    libx11-xcb1 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libxcb-dri3-0 \
    libxss1 \
    libgdk-pixbuf2.0-0 \
    libasound2 \
    libnss3 \
    libxtst6 \
    && rm -rf /var/lib/apt/lists/*

# Instalar Playwright
RUN npm install -g playwright && npx playwright install

# Copiar los archivos compilados a la imagen final
COPY --from=build /app/publish .

# Configura el entorno de ejecución y expone el puerto
ENTRYPOINT ["dotnet", "DescuentosWeb.dll"]
