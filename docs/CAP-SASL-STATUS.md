# CAP/SASL State Machine Status (alwi)

Date: 2026-03-13

## Delivered

Added typed CAP + SASL state machine baseline:

- `src/core/cap-sasl.coal`
- `scripts/verify-cap-sasl-surface.lisp`

Exports:
- `CapState`, `SaslState`
- `CapEvent`, `SaslEvent`
- `step-cap`, `step-sasl`

## Verification

```bash
sbcl --script scripts/verify-cap-sasl-surface.lisp
```

Result: all required state/event/step symbols verified.

## Follow-up

Expand transition guards for invalid event sequences and wire these machines into mock-harness handshake scenarios.
