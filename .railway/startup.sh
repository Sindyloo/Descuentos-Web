#!/bin/bash
curl -fsSL https://deb.nodesource.com/setup_16.x | bash -  # Instala Node.js
apt-get install -y nodejs  # Instala npm
npx playwright install --with-deps  # Instala Playwright
