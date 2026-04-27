# Endpoints requeridos del backend (xneo-web.onrender.com)

## Autenticación
- POST /api/auth/register - Registro { username, password }
- POST /api/auth/login - Login { username, password }
- GET /api/auth/me - Obtener perfil (token)
- PUT /api/auth/profile - Actualizar perfil (token)
- POST /api/auth/logout - Cerrar sesión (token)

## Videos
- GET /api/videos - Listar videos
- GET /api/videos/mine - Mis videos (token)
- POST /api/videos/upload - Subir video (token, multipart)
- POST /api/videos/:id/like - Dar like (token)
- POST /api/videos/:id/dislike - Dar dislike (token)

## Chats
- GET /api/chats - Listar chats (token)
- GET /api/chats/:id/messages - Mensajes de un chat (token)
- POST /api/chats/:id/messages - Enviar mensaje (token)
- PUT /api/chats/:id/read - Marcar leído (token)
- DELETE /api/chats/:id - Eliminar chat (token)
- DELETE /api/chats/:id/messages - Vaciar chat (token)

## Usuarios
- GET /api/users - Listar usuarios (token)

## Descargas (opcional - se maneja localmente)
- La app descarga los videos directamente de la URL proporcionada
- Se almacenan en XNEO/ dentro de Downloads del dispositivo
