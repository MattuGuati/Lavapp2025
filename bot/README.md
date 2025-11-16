# 📱 LavApp WhatsApp Bot

Bot de WhatsApp multi-sesión para enviar notificaciones automáticas desde LavApp.

## 🚀 Estado Actual

✅ **Bot funcionando en puerto 3008**

## 📊 Panel de Control

Accede al panel: **http://localhost:3008**

Muestra:
- Sesiones activas de WhatsApp
- Estado de conexiones
- Total de clientes conectados

## 🔑 API Endpoints

### 1. Enviar Mensaje

```bash
POST http://localhost:3008/v1/messages
Headers:
  Content-Type: application/json
  X-API-Key: tu-clave-unica  # Opcional, para multi-cuenta

Body:
{
  "number": "5491155551234",
  "message": "Tu pedido está listo para retirar!"
}
```

**Ejemplo con curl:**
```bash
curl -X POST http://localhost:3008/v1/messages \
  -H "Content-Type: application/json" \
  -H "X-API-Key: lavapp-principal" \
  -d '{
    "number": "5491155551234",
    "message": "Hola! Tu pedido está listo"
  }'
```

### 2. Ver Estado

```bash
GET http://localhost:3008
GET http://localhost:3008/status
```

## 🔧 Gestión del Bot

### Iniciar
```bash
cd /home/mpeirano/proyectos_recuperados/lavapp/bot
./start-bot.sh
```

O manualmente:
```bash
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 20
npm start
```

### Ver logs en tiempo real
```bash
# Si está corriendo en background, ver el ID del proceso
ps aux | grep "whatsapp-bot"

# Ver logs (reemplaza [bash_id] con el ID del proceso)
# Usando la herramienta BashOutput si está en background
```

### Detener
```bash
# Encontrar el proceso
ps aux | grep "whatsapp-bot"

# Matar el proceso (reemplaza PID con el número del proceso)
kill PID
```

## 📱 Vinculación de WhatsApp

La primera vez que envíes un mensaje con una API Key nueva:

1. El bot generará un código QR
2. El QR se guarda en: `sessions/[api-key].qr.png`
3. Escanea el QR desde WhatsApp Web en tu teléfono
4. Una vez conectado, el bot guardará la sesión en `sessions/[api-key]/`

## 🔄 Multi-Sesión

El bot soporta **múltiples cuentas de WhatsApp simultáneas**:

- Cada API Key = Una cuenta de WhatsApp diferente
- Las sesiones se mantienen aunque reinicies el bot
- Ideal para tener una cuenta por sucursal

**Ejemplo:**
```bash
# Cuenta sucursal centro
curl -X POST http://localhost:3008/v1/messages \
  -H "X-API-Key: sucursal-centro" \
  -d '{"number": "54...", "message": "..."}'

# Cuenta sucursal norte
curl -X POST http://localhost:3008/v1/messages \
  -H "X-API-Key: sucursal-norte" \
  -d '{"number": "54...", "message": "..."}'
```

## 📁 Estructura de Archivos

```
bot/
├── package.json                 # Dependencias
├── start-bot.sh                 # Script de inicio
├── src/
│   └── whatsapp-bot-multisession.js  # Código principal
└── sessions/                    # Sesiones de WhatsApp
    ├── [api-key]/              # Datos de sesión
    └── [api-key].qr.png        # QR de vinculación
```

## 🛠️ Troubleshooting

### Bot no arranca
```bash
# Verificar Node.js 20
node --version  # Debe ser v20.x

# Si no es v20, cargar nvm
export NVM_DIR="$HOME/.nvm"
source "$NVM_DIR/nvm.sh"
nvm use 20
```

### Puerto 3008 ocupado
```bash
# Ver qué está usando el puerto
netstat -tuln | grep 3008

# Cambiar el puerto editando src/whatsapp-bot-multisession.js
# Línea 11: const PORT = 3008;
```

### Error al enviar mensajes
1. Verifica que el número incluya código de país (54 para Argentina)
2. Asegúrate de que el bot esté conectado (revisa http://localhost:3008)
3. Revisa los logs del bot

## 📝 Notas

- El bot se reconecta automáticamente si pierde conexión
- Las sesiones persisten entre reinicios
- Cada sesión consume ~50MB de RAM
- Los QR expiran en ~2 minutos, se regeneran automáticamente

---

**Instalado:** 2025-11-16
**Node.js:** v20.19.5
**Baileys:** v6.7.21
