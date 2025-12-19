# 🎤 Cómo Funciona el Sistema de Texto a Voz (TTS)

Este documento explica en detalle cómo funciona el servicio de conversión de **Texto a Voz** (Text-to-Speech) de Soulgate.

---

## 📋 Índice

1. [Visión General](#-visión-general)
2. [Arquitectura del Sistema](#-arquitectura-del-sistema)
3. [Flujo de Procesamiento](#-flujo-de-procesamiento)
4. [Endpoints de la API](#-endpoints-de-la-api)
5. [Sistema de Voces](#-sistema-de-voces)
6. [Streaming de Audio](#-streaming-de-audio)
7. [Parámetros de Configuración](#-parámetros-de-configuración)

---

## 🌐 Visión General

El sistema utiliza **Microsoft Edge TTS** como motor de síntesis de voz. Este servicio online proporciona:

- ✅ **Bajo consumo de memoria**: ~20-50MB (vs ~800MB con Kokoro local)
- ✅ **400+ voces** en más de 100 idiomas
- ✅ **Alta calidad** de audio neural
- ✅ **Streaming en tiempo real**
- ⚠️ Requiere conexión a internet

---

## 🏗 Arquitectura del Sistema

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│                 │     │                 │     │                 │
│   Cliente/      │────▶│   FastAPI       │────▶│   Microsoft     │
│   Frontend      │     │   Server        │     │   Edge TTS      │
│                 │◀────│                 │◀────│   (Cloud)       │
│                 │     │                 │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
      HTTP               Procesamiento           Síntesis de Voz
    Request              & Streaming               Neural
```

### Componentes Principales

| Componente | Descripción |
|------------|-------------|
| **FastAPI Server** | Servidor HTTP que recibe las peticiones y gestiona la API REST |
| **Edge TTS Client** | Librería `edge-tts` que conecta con el servicio de Microsoft |
| **Sistema de Mapeo** | Convierte voces legacy (Kokoro) a voces Edge TTS |
| **Stream Manager** | Gestiona el streaming de audio por chunks |

---

## 🔄 Flujo de Procesamiento

### 1. Recepción de la Petición

```python
# El servidor recibe un JSON con:
{
    "text": "Hola, esto es una prueba",
    "lang": "e",           # Código de idioma
    "voice": "af_heart",   # Voz (legacy o Edge)
    "speed": 1.0           # Velocidad (0.5 - 2.0)
}
```

### 2. Mapeo de Voz

El sistema convierte las voces legacy de Kokoro a voces de Edge TTS:

```python
# Ejemplo de mapeo:
"af_heart" → "en-US-JennyNeural"
"es_female" → "es-MX-DaliaNeural"
"es_spain_male" → "es-ES-AlvaroNeural"
```

### 3. División del Texto (Chunking)

Para streaming fluido, el texto largo se divide en fragmentos:

```
Texto original: "Esta es una oración larga. Que se divide en partes..."
                        ↓
Chunks: ["Esta es una oración larga.", "Que se divide en partes..."]
```

**Algoritmo de división:**
1. Primero divide por párrafos (`\n\n`)
2. Luego por oraciones (`.`, `!`, `?`)
3. Máximo ~800 caracteres por chunk

### 4. Síntesis de Audio

```python
# Edge TTS genera audio para cada chunk
communicate = edge_tts.Communicate(texto, voz, rate=velocidad)

# Recolecta los datos de audio
async for chunk in communicate.stream():
    if chunk["type"] == "audio":
        audio_data += chunk["data"]
```

### 5. Respuesta al Cliente

- **Modo Normal** (`/tts`): Devuelve el audio completo en MP3
- **Modo Streaming** (`/tts/stream`): Envía chunks en formato multipart

---

## 🔌 Endpoints de la API

### `POST /tts` - Audio Completo

Genera y devuelve el audio completo en una sola respuesta.

```bash
curl -X POST 'http://localhost:8000/tts' \
  -H 'Content-Type: application/json' \
  -d '{"text": "Hola mundo", "lang": "e", "voice": "es_female"}' \
  --output audio.mp3
```

**Respuesta:** `audio/mpeg` (archivo MP3)

---

### `POST /tts/stream` - Streaming

Genera audio en chunks para reproducción inmediata.

```bash
curl -N -X POST 'http://localhost:8000/tts/stream' \
  -H 'Content-Type: application/json' \
  -d '{"text": "Texto largo para streaming...", "lang": "e"}'
```

**Respuesta:** `multipart/mixed; boundary=--frame`

Cada parte contiene:
```
--frame
Content-Type: audio/mpeg
Content-Length: 12345

[datos binarios del audio]
```

---

### `GET /voices` - Listar Voces

Obtiene todas las voces disponibles agrupadas por idioma.

```bash
curl http://localhost:8000/voices
```

---

### `GET /health` - Estado del Sistema

```bash
curl http://localhost:8000/health
```

Respuesta:
```json
{
  "status": "healthy",
  "engine": "edge-tts",
  "memory": {"usage_mb": 35.2},
  "stats": {
    "total_requests": 150,
    "successful_streams": 148
  }
}
```

---

## 🎭 Sistema de Voces

### Mapeo de Voces Legacy → Edge TTS

| Voz Kokoro | Voz Edge TTS | Descripción |
|------------|--------------|-------------|
| `af_heart` | `en-US-JennyNeural` | Femenina americana |
| `af_soul` | `en-US-AriaNeural` | Femenina americana |
| `am_adam` | `en-US-GuyNeural` | Masculina americana |
| `bf_emma` | `en-GB-SoniaNeural` | Femenina británica |
| `es_female` | `es-MX-DaliaNeural` | Femenina español (México) |
| `es_male` | `es-MX-JorgeNeural` | Masculina español (México) |
| `es_spain_female` | `es-ES-ElviraNeural` | Femenina español (España) |
| `es_spain_male` | `es-ES-AlvaroNeural` | Masculina español (España) |

### Códigos de Idioma

| Código | Idioma | Locale Edge |
|--------|--------|-------------|
| `a` | Inglés (EEUU) | `en-US` |
| `b` | Inglés (UK) | `en-GB` |
| `e` | Español (México) | `es-MX` |
| `es_spain` | Español (España) | `es-ES` |
| `f` | Francés | `fr-FR` |
| `i` | Italiano | `it-IT` |
| `p` | Portugués (Brasil) | `pt-BR` |
| `j` | Japonés | `ja-JP` |
| `z` | Chino | `zh-CN` |
| `h` | Hindi | `hi-IN` |

---

## 📡 Streaming de Audio

### ¿Por qué usar Streaming?

1. **Latencia reducida**: El audio comienza a reproducirse antes de que termine la generación
2. **Mejor UX**: El usuario no espera a que se genere todo el audio
3. **Eficiencia de memoria**: No se almacena todo el audio en memoria

### Formato Multipart/Mixed

El streaming usa el formato `multipart/mixed` con boundary `--frame`:

```
--frame
Content-Type: audio/mpeg
Content-Length: 8192

[chunk 1 de audio binario]
--frame
Content-Type: audio/mpeg
Content-Length: 6144

[chunk 2 de audio binario]
--frame--
```

### Diagrama de Streaming

```
Tiempo ──────────────────────────────────────────────▶

Servidor:  [Gen Chunk 1] [Gen Chunk 2] [Gen Chunk 3]
                  │             │             │
                  ▼             ▼             ▼
Red:       ─────[Envío]──────[Envío]──────[Envío]────▶

Cliente:        [Play 1]    [Play 2]    [Play 3]
                  🔊          🔊          🔊
```

---

## ⚙️ Parámetros de Configuración

### Parámetros de Petición

| Parámetro | Tipo | Default | Descripción |
|-----------|------|---------|-------------|
| `text` | string | requerido | Texto a sintetizar |
| `lang` | string | `"a"` | Código de idioma |
| `voice` | string | `"af_heart"` | Nombre de la voz |
| `speed` | float | `1.0` | Velocidad (0.5 - 2.0) |

### Conversión de Velocidad

```python
speed = 0.5  → rate = "-50%"  # Más lento
speed = 1.0  → rate = "+0%"   # Normal
speed = 1.5  → rate = "+50%"  # Más rápido
speed = 2.0  → rate = "+100%" # Doble velocidad
```

---

## 📊 Monitoreo y Estadísticas

El sistema mantiene estadísticas en tiempo real:

- `total_requests`: Peticiones totales
- `successful_streams`: Streams completados exitosamente
- `failed_streams`: Streams fallidos
- `cancelled_streams`: Streams cancelados por el cliente
- `chunks_sent`: Total de chunks enviados

Accede a las estadísticas en: `GET /stats`

---

## 🔧 Ejemplo de Integración

### JavaScript/Frontend

```javascript
async function textToSpeech(text, lang = 'e') {
  const response = await fetch('/tts/stream', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ text, lang, voice: 'es_female' })
  });
  
  const reader = response.body.getReader();
  const audioContext = new AudioContext();
  
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    // Procesar chunk de audio...
  }
}
```

### Python

```python
import httpx

async def text_to_speech(text: str):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://localhost:8000/tts",
            json={"text": text, "lang": "e", "voice": "es_female"}
        )
        
        with open("output.mp3", "wb") as f:
            f.write(response.content)
```

---

## 📝 Notas Técnicas

1. **Formato de Audio**: Edge TTS genera audio en formato MP3 por defecto
2. **Sample Rate**: 24kHz para voces neurales
3. **Conexión**: Requiere conexión estable a internet
4. **Límites**: No hay límites estrictos de caracteres, pero se recomienda < 5000 caracteres por petición

---

## 🚀 Inicio Rápido

```bash
# Instalar dependencias
pip install -r requirements.txt

# Iniciar servidor
uvicorn app.main:app --host 0.0.0.0 --port 8000

# Probar
curl -X POST http://localhost:8000/tts \
  -H "Content-Type: application/json" \
  -d '{"text": "Hola mundo", "lang": "e"}' \
  --output test.mp3
```

---

*Documentación generada para Soulgate TTS v2.0.0 - Edge TTS Edition*
