# INTAKE — Edge TTS 403 / empty stream

**Date:** 2026-10-15  
**Mode:** incident  
**workflow_type:** bugfix  
**Classification:** STANDARD  

## Problem

Production TEXT-TO-VOICE returns synthesis 403 (`Sec-MS-GEC` / Invalid handshake). Stream closes with empty `--frame--`. Soul Gate Results TTS silent.

## Acceptance criteria

- [x] `edge-tts` pinned to a version that synthesizes successfully locally (verified ≥7.3.1)
- [x] `POST /tts` with Dalia/es_female returns `audio/mpeg` with non-empty body (local)
- [x] `POST /tts/stream` yields at least one `audio/mpeg` part (or HTTP error — never silent empty multipart success)
- [x] Docs/requirements note rebuild (`--no-cache`) for deploy

## Evidence so far

- Local: `edge-tts==7.0.0` → 403; `edge-tts==7.3.1` → ~12KB MP3 OK
- VERIFY 2026-10-15: `/tts` HTTP 200 SIZE 14976 `audio/mpeg`; `/tts/stream` SIZE 11305 with `audio/mpeg` part
