#!/bin/bash
# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
apt-get install -y nodejs
# Instalar Playwright
npx playwright install --with-deps
