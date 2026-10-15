# BUILD REPORT — Edge TTS 403 fix

**Date:** 2026-10-15  
**Repo:** TEXT-TO-VOICE  
**Classification:** STANDARD  

## Changes

| File | Change |
|------|--------|
| `requirements.txt` | Pin `edge-tts>=7.3.1,<8` (7.0.x → WSS 403 Sec-MS-GEC) |
| `Dockerfile` | Build-time assert installed edge-tts ≥ 7.3 |
| `DOCKER.md` | Note `docker compose build --no-cache` after pin |
| `app/main.py` | Re-raise 403/handshake in stream; fail if `chunk_count==0`; `/tts` preserves `HTTPException`, empty/upstream → 502 |

## PRE-EDIT / SLOP

- Scoped to TTS failure paths and deploy pin only; no Kokoro/voice-map churn.

## Deploy note

Production `soulgate-edge-tts` must rebuild without cache so the image picks up edge-tts ≥ 7.3.1:

```bash
cd /Users/kscius/Development/TEXT-TO-VOICE
docker compose build --no-cache && docker compose up -d
```
