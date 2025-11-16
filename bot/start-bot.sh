#!/bin/bash
# Script para iniciar el bot de WhatsApp de LavApp

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

cd "$(dirname "$0")"

echo "🚀 Iniciando LavApp WhatsApp Bot..."
nvm use 20
npm start
