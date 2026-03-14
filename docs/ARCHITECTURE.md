# clpkg-irc-clients — Architecture

## Layer Diagram

```
┌─────────────────────────────────────────────────┐
│             Coalton Core Layer                  │
│  mode-types.coal  state-types.coal  mode.coal   │
│  state.coal  irc-message.coal  cap-sasl.coal    │
│  ctcp-tags.coal  invariants.coal                │
└──────────────────┬──────────────────────────────┘
                   │ pure typed ADTs + reducers
┌──────────────────┴──────────────────────────────┐
│             Net Layer (CL)                      │
│  connection.lisp (TCP/TLS + rate limit)         │
└──────────────────┬──────────────────────────────┘
                   │ transport
┌──────────────────┴──────────────────────────────┐
│             Client Layer (CL)                   │
│  events.lisp  commands.lisp  client.lisp        │
│  history.lisp  multi.lisp                       │
└─────────────────────────────────────────────────┘
```

## Design Principles

1. **Coalton-first for pure core** — mode parsing, state reduction, message ADTs, and CAP/SASL state machines use Coalton for total type safety.
2. **CL for IO and state** — connection management, event dispatch, and client lifecycle use typed Common Lisp with `ftype` declarations.
3. **Typed conditions** — error paths use structured conditions (`connection-refused`, `rate-limit-exceeded`) not strings.
4. **Pure reducers** — state transitions are pure functions: `Event → State → Result StateError State`.
5. **Ring-buffer history** — bounded memory per channel with configurable capacity.

## Module Dependencies

| Module | Depends On | Provides |
|--------|-----------|----------|
| Coalton Core | (none) | Mode/state ADTs, parser, reducer |
| connection.lisp | (none) | TCP/TLS lifecycle, rate limiting |
| events.lisp | (none) | Event dispatch |
| commands.lisp | (none) | Command formatting |
| client.lisp | net, events, commands | Client lifecycle |
| history.lisp | (none) | Message history |
| multi.lisp | client | Multi-server management |

## Security Model

- **Rate limiting** — sliding-window flood protection per connection
- **Reconnect guards** — configurable max reconnect count prevents infinite loops
- **TLS support** — connection struct carries tls-p flag for upgrade

## Testing Strategy

- **Surface verification** — symbol presence checks via SBCL scripts
- **Property+fixture suite** — ADT exhaustiveness, golden IRC dialect fixtures (InspIRCd/Ergo/Solanum), determinism, totality
- **E2E scenarios** — 18 scenarios covering full client lifecycle
- **Mock server** — deterministic queue-driven pump loop for transcript verification
