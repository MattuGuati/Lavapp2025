import { makeWASocket, DisconnectReason, useMultiFileAuthState } from '@whiskeysockets/baileys';
import qr from 'qr-image';
import fs from 'fs';
import path from 'path';
import http from 'http';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PORT = 3008;

// Mapa para almacenar múltiples clientes de WhatsApp (uno por cada API key)
const clients = new Map();
const qrCodes = new Map();
const sessionStatus = new Map();

/**
 * Obtiene o crea un cliente de WhatsApp para una API key específica
 */
async function getOrCreateClient(apiKey) {
    if (clients.has(apiKey)) {
        return clients.get(apiKey);
    }

    console.log(`🔄 Creando nueva sesión para API key: ${apiKey}`);

    const sessionPath = path.join(__dirname, '..', 'sessions', apiKey);

    if (!fs.existsSync(sessionPath)) {
        fs.mkdirSync(sessionPath, { recursive: true });
    }

    const { state, saveCreds } = await useMultiFileAuthState(sessionPath);

    const sock = makeWASocket({
        auth: state,
        printQRInTerminal: false,
        browser: ['LavApp Bot', 'Chrome', '1.0.0']
    });

    sock.ev.on('creds.update', saveCreds);

    sock.ev.on('connection.update', (update) => {
        const { connection, lastDisconnect, qr: qrCode } = update;

        if (qrCode) {
            console.log(`🔗 QR generado para ${apiKey}`);
            qrCodes.set(apiKey, qrCode);
            sessionStatus.set(apiKey, 'pending_qr');

            try {
                const qrPath = path.join(__dirname, '..', 'sessions', `${apiKey}.qr.png`);
                const qrImage = qr.image(qrCode, { type: 'png' });
                qrImage.pipe(fs.createWriteStream(qrPath));
                console.log(`✅ QR guardado para ${apiKey}`);
            } catch (err) {
                console.error(`Error guardando QR para ${apiKey}:`, err);
            }
        }

        if (connection === 'close') {
            const shouldReconnect = lastDisconnect?.error?.output?.statusCode !== DisconnectReason.loggedOut;
            console.log(`❌ Conexión cerrada para ${apiKey}, reconectando:`, shouldReconnect);

            if (shouldReconnect) {
                clients.delete(apiKey);
                sessionStatus.set(apiKey, 'reconnecting');
                setTimeout(() => getOrCreateClient(apiKey), 3000);
            } else {
                clients.delete(apiKey);
                qrCodes.delete(apiKey);
                sessionStatus.set(apiKey, 'logged_out');
            }
        } else if (connection === 'open') {
            console.log(`✅ Conectado a WhatsApp para ${apiKey}`);
            qrCodes.delete(apiKey);
            sessionStatus.set(apiKey, 'connected');
        }
    });

    clients.set(apiKey, sock);
    return sock;
}

// Crear servidor HTTP
const server = http.createServer(async (req, res) => {
    const url = req.url;
    const method = req.method;

    // CORS headers
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, X-API-Key');

    if (method === 'OPTIONS') {
        res.writeHead(200);
        res.end();
        return;
    }

    // Página principal
    if (url === '/' || url === '/status') {
        res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
        let sessionsHTML = '';
        
        if (clients.size === 0) {
            sessionsHTML = '<p>No hay sesiones activas</p>';
        } else {
            for (const [apiKey, sock] of clients.entries()) {
                const status = sessionStatus.get(apiKey) || 'unknown';
                sessionsHTML += `<div><strong>${apiKey}:</strong> ${status}</div>`;
            }
        }

        res.end(`
<!DOCTYPE html>
<html>
<head>
    <title>LavApp Bot - WhatsApp Multi-Sesión</title>
    <meta charset="UTF-8">
</head>
<body>
    <h1>🧼 LavApp Bot - WhatsApp Multi-Sesión</h1>
    <h2>Sesiones Activas (${clients.size})</h2>
    ${sessionsHTML}
    <p>Puerto: ${PORT}</p>
</body>
</html>
        `);
    }

    // Enviar mensaje
    else if (url === '/v1/messages' && method === 'POST') {
        let body = '';
        req.on('data', chunk => { body += chunk.toString(); });

        req.on('end', async () => {
            try {
                const apiKey = req.headers['x-api-key'] || 'default';
                const { number, message } = JSON.parse(body);

                const sock = await getOrCreateClient(apiKey);
                const recipient = number.includes('@s.whatsapp.net') ? number : `${number}@s.whatsapp.net`;
                await sock.sendMessage(recipient, { text: message });

                console.log(`✅ Mensaje enviado a ${recipient} (${apiKey})`);
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ success: true, message: 'Mensaje enviado' }));
            } catch (error) {
                console.error('Error enviando mensaje:', error);
                res.writeHead(500, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ error: error.message }));
            }
        });
    }
    
    else {
        res.writeHead(404);
        res.end('Not found');
    }
});

server.listen(PORT, () => {
    console.log(`🚀 Servidor WhatsApp Bot corriendo en http://localhost:${PORT}`);
    console.log(`📱 Multicliente - Usa header X-API-Key para distinguir clientes`);
});
