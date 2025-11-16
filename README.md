# LavApp 2025

Sistema de gestión de tickets para lavandería desarrollado en Flutter con Firebase.

## Descripción

LavApp es una aplicación web completa para administrar tickets de lavandería, con funcionalidades de:
- Gestión de tickets (crear, editar, consultar, archivar)
- Programación de fechas de entrega
- Filtros avanzados por fecha (hoy, esta semana, vencidos)
- Sistema de usuarios con roles y permisos
- Integración con WhatsApp para notificaciones
- Gestión de clientes
- Reportes y estadísticas
- Configuración de precios y extras

## Características Principales

### Gestión de Tickets
- **Creación de tickets**: Formulario completo con validaciones
  - Datos del cliente (nombre, teléfono)
  - Cantidad de bolsas
  - Extras con contador
  - Fecha de entrega programada
- **Estados de ticket**: En Proceso, Pendiente, Entregado
- **Filtrado**: Por fecha, nombre, teléfono, estado
- **Edición y archivado**: Modificar tickets existentes y archivar entregados

### Sistema de Fechas
- DatePicker en español para seleccionar fecha de entrega
- Filtros por fecha:
  - **Hoy**: Tickets del día actual
  - **Esta Semana**: Últimos 7 días
  - **Vencidos**: Más de 3 días de antigüedad
  - **Todos**: Sin filtro

### Sistema de Usuarios
- Autenticación con Firebase
- Roles: Admin y Usuario
- Sistema de permisos granular:
  - Preferencias
  - Consultar tickets
  - Reportes
  - Costos
  - Clientes
  - Usuarios (solo admin)

### Integración WhatsApp
- Envío de notificaciones automáticas
- Configuración de API key por usuario
- Plantillas de mensajes personalizables
- Variables: {nombre}, {costo}

### Reportes
- Visualización de estadísticas
- Gráficos con fl_chart
- Filtros por período

## Tecnologías Utilizadas

- **Flutter 3.4.4**: Framework principal
- **Firebase/Firestore**: Base de datos y autenticación
- **flutter_localizations**: Soporte multiidioma (español/inglés)
- **intl 0.20.2**: Formato de fechas
- **shared_preferences 2.2.3**: Almacenamiento local
- **fl_chart 0.70.2**: Gráficos y reportes
- **http 1.2.2**: Integración API WhatsApp

## Instalación

### Requisitos Previos
- Flutter SDK >= 3.4.4
- Dart SDK >= 3.0.0
- Cuenta de Firebase con Firestore habilitado

### Pasos de Instalación

1. **Clonar el repositorio**
```bash
git clone https://github.com/MattuGuati/Lavapp2025.git
cd lavapp
```

2. **Instalar dependencias**
```bash
flutter pub get
```

3. **Configurar Firebase**
   - Crear proyecto en [Firebase Console](https://console.firebase.google.com)
   - Habilitar Firestore Database
   - Descargar `firebase_options.dart` (generado con FlutterFire CLI)
   - Colocar en `lib/firebase_options.dart`

4. **Configurar Firestore**

   Crear las siguientes colecciones:

   **users**
   ```javascript
   {
     "username": "admin",
     "password": "admin123", // CAMBIAR EN PRODUCCIÓN
     "role": "admin",
     "permissions": {
       "preferences": true,
       "consultTickets": true,
       "reports": true,
       "costs": true,
       "clients": true,
       "users": true
     },
     "phone": null,
     "whatsappApiKey": null,
     "countryCode": "54",
     "createdAt": "2025-01-01T00:00:00.000Z"
   }
   ```

   **preferences**
   ```javascript
   {
     "costPerBag": 500,
     "whatsappMessage": "¡Hola {nombre}! Ya podés pasar a retirar tu ropa. Costo: ${costo}."
   }
   ```

   **attributes** (Extras)
   ```javascript
   {
     "name": "Planchado",
     "price": 200,
     "hasCounter": false
   }
   ```

   **tickets** (se crean automáticamente)

   **archivedTickets** (se crean automáticamente)

5. **Compilar para Web**
```bash
flutter build web
```

6. **Servir la aplicación**
```bash
cd build/web
python3 -m http.server 8080 --bind 0.0.0.0
```

Acceder en: `http://localhost:8080`

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada, configuración MaterialApp
├── firebase_options.dart     # Configuración Firebase
├── models/
│   ├── user.dart            # Modelo de usuario con permisos
│   └── ticket.dart          # Modelo de ticket
├── screens/
│   ├── ticket_list_screen.dart      # Pantalla principal con login
│   ├── new_ticket_screen.dart       # Crear nuevo ticket
│   ├── edit_ticket_screen.dart      # Editar ticket existente
│   ├── consult_tickets_screen.dart  # Consultar y filtrar tickets
│   ├── reports_screen.dart          # Reportes y estadísticas
│   ├── cost_screen.dart             # Gestión de costos
│   ├── clients_screen.dart          # Gestión de clientes
│   ├── preferences_screen.dart      # Configuraciones
│   └── users_screen.dart            # Gestión de usuarios (admin)
├── services/
│   ├── database_service.dart        # Servicio Firestore
│   └── api_service.dart             # Servicio WhatsApp API
├── utils/
│   └── logger.dart                  # Sistema de logging
└── widgets/
    └── ticket_card.dart             # Widget tarjeta de ticket
```

## Uso

### Acceso
1. La primera vez, usar credenciales por defecto (configuradas en Firestore)
2. El sistema guarda la sesión en SharedPreferences
3. Los usuarios pueden configurar su WhatsApp API key en Preferencias

### Crear Ticket
1. Click en botón "Nuevo Ticket"
2. Ingresar datos del cliente:
   - Nombre (mínimo 2 caracteres)
   - Teléfono (mínimo 6 dígitos, validación regex)
3. Seleccionar fecha de entrega (opcional)
4. Indicar cantidad de bolsas
5. Seleccionar extras
6. Click en "Crear Ticket"

### Gestionar Tickets
- **Consultar**: Buscar por nombre, teléfono, filtrar por fecha
- **Editar**: Click en tarjeta de ticket
- **Cambiar Estado**: En Proceso → Pendiente → Entregado
- **Enviar WhatsApp**: Notificar al cliente (requiere API key configurada)
- **Archivar**: Los tickets "Entregados" se archivan automáticamente
- **Restaurar**: Desde consulta, restaurar tickets archivados

### Filtros de Fecha
- **Todos**: Muestra todos los tickets
- **Hoy**: Solo tickets creados hoy
- **Esta Semana**: Tickets de los últimos 7 días
- **Vencidos**: Tickets de más de 3 días

## Seguridad

### Recomendaciones de Producción
1. **Contraseñas**: Cambiar credenciales por defecto
2. **Firebase Rules**: Configurar reglas de seguridad en Firestore
3. **HTTPS**: Servir sobre HTTPS (no HTTP)
4. **API Keys**: No commitear claves en el código
5. **Validación**: Implementar autenticación Firebase Auth (actualmente usa validación manual)

### Reglas de Firestore Sugeridas
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Solo usuarios autenticados
    match /{document=**} {
      allow read, write: if request.auth != null;
    }

    // Solo admins pueden gestionar usuarios
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if get(/databases/$(database)/documents/users/$(request.auth.token.username)).data.role == 'admin';
    }
  }
}
```

## Problemas Conocidos y Soluciones

### Error "Null check operator used on a null value"
**Solución**: Ya corregido en la versión actual. Se reemplazaron operadores `!` inseguros por `?.` null-aware operators.

### DatePicker no se muestra en español
**Solución**: Ya corregido. Se agregó `flutter_localizations` y configuración de locale en MaterialApp.

### Build lento en modo debug
**Solución**: Usar `flutter build web` para producción en lugar de `flutter run`.

## Changelog

### Versión 1.0.0 (2025-01-16)
- ✅ Funcionalidad de fechas de entrega con DatePicker
- ✅ Filtros por fecha (Hoy, Esta Semana, Vencidos)
- ✅ Validaciones mejoradas en formularios
- ✅ Corrección de errores null check
- ✅ Reemplazo de prints por AppLogger
- ✅ Soporte de localización español/inglés
- ✅ Sistema de permisos por usuario
- ✅ Integración WhatsApp

## Contribuir

Este es un proyecto privado. Para reportar bugs o solicitar features, contactar al desarrollador.

## Licencia

Propietario: Matteo Peirano
Todos los derechos reservados.

## Soporte

Para soporte técnico o consultas, contactar a través del repositorio de GitHub.

## Créditos

Desarrollado con Flutter y Firebase.
