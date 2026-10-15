# SCOUT — Edge TTS 403 / empty stream

**Date:** 2026-10-15  
**Classification:** STANDARD  
**Confidence:** HIGH  
**Source:** [SCOUT TEXT-TO-VOICE](0d743766-e430-466b-a252-ea06271834f0) + parent verify

## Root cause

`edge-tts` ≤7.2.x → Microsoft WSS `403 Invalid response status` (Sec-MS-GEC v1). Fixed upstream in **7.3.0/7.3.1** (Sec-MS-GEC v2). Health stays green because it never calls Bing.

## Surface

- Sole synthesis: `app/main.py` (`Communicate.stream`)
- Old pin `>=7.0.0` allowed broken images; stream swallowed 403 → empty `--frame--`

## VALIDATION MANIFEST

```
VALIDATION MANIFEST
- lint_cmd: N/A (no lint script in TEXT-TO-VOICE)
- typecheck_cmd: N/A
- test_cmd: N/A (no automated TTS tests)
- build_cmd: docker compose build --no-cache
- browser_check: no
- migration_check: no
- smoke: uvicorn + curl POST /tts and /tts/stream
```

## Warm-up

- Skills: systematic-debugging, self-validate, verification-before-completion
- Subagents: explore (scout), code-reviewer, architect-reviewer, security-auditor, verification-specialist
