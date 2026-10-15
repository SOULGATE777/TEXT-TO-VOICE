# VALIDATION REPORT — Edge TTS 403 / empty stream

**Date:** 2026-10-15  
**Repo:** TEXT-TO-VOICE  
**Overall:** GREEN  
**Scope:** full (local TEXT-TO-VOICE service)  
**Independent re-probe:** 2026-10-15T23:11Z port **5034** (closes prior YELLOW from Ask-mode verify)

## Results | Evidence

| Check | Result | Evidence |
|-------|--------|----------|
| `edge-tts` version | GREEN | `.venv` → **7.3.1** |
| `GET /health` | GREEN | HTTP 200 `engine: edge-tts` |
| `POST /tts` | GREEN | HTTP **200** SIZE **14976** CT `audio/mpeg`; `file` → MPEG ADTS layer III |
| `POST /tts/stream` | GREEN | HTTP **200** SIZE **11305**; body has `Content-Type: audio/mpeg` + `--frame` |
| Pin + Docker docs | GREEN | `requirements.txt` `>=7.3.1,<8`; Dockerfile assert ≥(7,3); DOCKER.md `--no-cache` |
| EXIT A (intake) | GREEN | All 4 acceptance boxes `[x]` |

## Commands (exit 0)

```bash
cd /Users/kscius/Development/TEXT-TO-VOICE
.venv/bin/python -c "import importlib.metadata as m; print(m.version('edge-tts'))"
.venv/bin/uvicorn app.main:app --host 127.0.0.1 --port 5034
curl -sS -m 60 -X POST http://127.0.0.1:5034/tts \
  -H 'Content-Type: application/json' \
  -d '{"text":"Hola mundo prueba de audio.","lang":"es-MX","voice":"es-MX-DaliaNeural","speed":1.0}' \
  -o /tmp/ttv-fu.mp3 -w 'tts HTTP:%{http_code} SIZE:%{size_download}\n'
# → tts HTTP:200 SIZE:14976
curl -sS -m 60 -X POST http://127.0.0.1:5034/tts/stream \
  -H 'Content-Type: application/json' \
  -d '{"text":"Hola streaming.","lang":"e","voice":"es_female","speed":1.0}' \
  -o /tmp/ttv-fu-stream.bin -w 'stream HTTP:%{http_code} SIZE:%{size_download}\n'
# → stream HTTP:200 SIZE:11305 ; audio/mpeg: True
```

## Acceptance walk (EXIT A)

- [x] Pin synthesizes locally (≥7.3.1) → MET (7.3.1 + /tts MP3)
- [x] POST /tts non-empty audio/mpeg → MET (14976 bytes)
- [x] POST /tts/stream ≥1 audio/mpeg part → MET (multipart with audio/mpeg)
- [x] Docs/requirements rebuild note → MET (DOCKER.md + requirements + Dockerfile)

## Not validated (explicit)

- Production `soulgate-edge-tts` rebuild/deploy
- FE → API proxy → TTS on prod

## Residual risk

Microsoft may rotate Sec-MS-GEC; pin `<8` and watch edge-tts releases.
