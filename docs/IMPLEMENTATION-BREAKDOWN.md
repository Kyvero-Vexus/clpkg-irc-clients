# Implementation Breakdown (Sanitized)

## Core modules

- `core/message` — protocol message ADTs, parser, serializer
- `core/mode` / `core/state` — mode parsing and deterministic state transitions
- `core/capability` / `core/sasl` — capability negotiation and auth state machines

## Boundary modules

- `net/connection` — TCP/TLS lifecycle
- `net/reconnect` — retry/backoff
- `net/rate-limit` — flood control
- `client/events` + `client/commands` — stable public API surface

## Verification track

- Constructor/export closure checks for typed ADTs
- Transition error-space coverage
- Parser/reducer integration fixture matrix
- Throughput and allocation microbenchmarks
