# Mode Parser Status (78ug.2)

Date: 2026-03-13

## Delivered

Added `src/core/mode.coal` parser surface with typed error channel and deterministic arg-cursor model:

- `ParseModeError` (position-aware failures)
- `ModeArgCursor` (arity-aware argument stream)
- `parse-mode-line`
- `parse-mode-tokens`

This bead establishes parser contracts against `Core.ModeTypes` ADTs and explicit `Result` error handling.

## Verification

Executed:

```bash
sbcl --script scripts/verify-mode-parser-surface.lisp
```

Result: required parser surface symbols verified.

## Next steps

1. Implement concrete char-by-char parser for grouped +/- mode segments.
2. Encode arity table for channel/user mode atoms (`o v b e I k l ...`).
3. Add dialect fixture matrix and round-trip parse tests.
