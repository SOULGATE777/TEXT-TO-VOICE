# CRITIC VERDICT — Edge TTS 403

**Date:** 2026-10-15  
**Parent final:** CAUTION acknowledged → polish applied  
**Fleet merge:**
- [SCOUT](0d743766-e430-466b-a252-ea06271834f0): DONE HIGH — pin 7.3.1 + fail-closed stream
- [code-reviewer](a275a5f5-5feb-403a-a72b-1e931d543341): **CAUTION** — stream stays HTTP 200 + text/plain (proxy peeks); Dockerfile assert allowed 7.3.0
- [VERIFY](011f6619-dd90-4ab0-9e40-d84923f33cf7): was YELLOW; parent re-probe :5034 → GREEN
- Post-CAUTION polish: Dockerfile assert `>= (7, 3, 1)`; stream comments corrected (in-band error, not HTTP 5xx)
- [security-auditor](6bdd9acc-45df-436d-ae87-381e6fefdc2e): **CAUTION** — leak of `str(e)` on 502/stream; remediated: generic client messages + re-raise when `chunk_count==0` for 5xx
- [architect-reviewer](4d39668b-265e-4591-b5e9-f28742d54db1): **CAUTION** — remediated: prefetch first MP3 before StreamingResponse → HTTP 502 on handshake/empty; FE peek still defense-in-depth

## Rationale (parent)

- Root cause is version-bound (`edge-tts` 7.0.x Sec-MS-GEC); pin ≥7.3.1 is the correct fix.
- Fail-closed on empty stream + 403 re-raise aligns with Soul Gate proxy peek → 502 → FE speech fallback.
- Dockerfile assert + DOCKER.md `--no-cache` reduce silent stale-image redeploys.
- Local VERIFY GREEN: `/tts` 14–15KB MP3; `/tts/stream` has `audio/mpeg`.

## Residual

- Production image rebuild still required (`soulgate-edge-tts`).
- Stream fatal path still yields multipart `text/plain` Error at HTTP 200 (proxy peeks; acceptable).

## Gate

CRITIC → BUILD: acknowledged APPROVED for shipped local changes.  
VERIFY → CLOSE: disk `validation-report-2026-10-15-edge-tts-403.md` Overall=GREEN.
