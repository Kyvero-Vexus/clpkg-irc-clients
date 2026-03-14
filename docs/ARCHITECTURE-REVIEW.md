# Architecture Review: clpkg-irc-clients

**Reviewer:** Gensym (General Manager)
**Date:** 2026-03-14
**Bead:** workspace-ceo_chryso-iqi4
**Scope:** API stability, type coverage, security audit

---

## 1. API Stability & Consistency

### 1.1 Package Naming — ✅ PASS

All packages follow `clpkg-irc-clients/<subsystem>` convention:
- `clpkg-irc-clients/net`
- `clpkg-irc-clients/events`
- `clpkg-irc-clients/commands`
- `clpkg-irc-clients/client`
- `clpkg-irc-clients/harness`

Consistent and predictable.

### 1.2 Struct Naming & `:conc-name` — ✅ PASS

| Struct | `:conc-name` | Prefix consistent? |
|--------|-------------|-------------------|
| `irc-connection` | `conn-` | ✅ |
| `rate-limiter` | `rl-` | ✅ |
| `irc-event` | `ev-` | ✅ |
| `event-listener` | `el-` | ✅ |
| `event-dispatcher` | `ed-` | ✅ |
| `irc-command` | `icmd-` | ✅ |
| `irc-client` | `client-` | ✅ |
| `mock-server` | `server-` | ✅ |

All exported accessor names match their `:conc-name` prefix.

### 1.3 Condition Hierarchy — ✅ PASS (with note)

- Net layer: `connection-refused`, `connection-timeout`, `rate-limit-exceeded`
- All are direct subtypes of `error`

**Suggestion (non-blocking):** A common `irc-connection-condition` base would help downstream `handler-case` grouping.

### 1.4 API Surface vs. Spec — ⚠️ GAP

The spec (Section 2.5) defines a `defgeneric`-based API with methods like `connect`, `disconnect`, `join-channel`, `send-privmsg`, etc. The implementation uses `defun` with struct-typed parameters.

**Assessment:** Acceptable for current struct-based approach. The method names differ from spec:
- Spec: `connect` / `disconnect` → Impl: `client-connect!` / `client-disconnect!`
- Spec: `join-channel` → Impl: `client-join!`
- Spec: `send-privmsg` → Impl: `client-privmsg!`

The `!`-suffix convention is good (indicates mutation), but the naming divergence from spec should be documented.

**Missing from spec surface:**
- `add-handler` / `remove-handler` — implemented as `register-listener` (different name)
- `channel-history` — not implemented
- `multi.lisp` (multi-server) — not implemented
- `bot/` framework — not implemented
- `proxy.lisp` — not implemented

These are expected phase gaps.

### 1.5 Export Completeness — ✅ PASS

All exported symbols have corresponding implementations.

### 1.6 Compilation Warnings — ⚠️ MINOR

3 style warnings during compilation:
- `HOST`, `PORT`, `TLS-P` unused in `%ensure-init` — these params exist in `make-irc-client` but `%ensure-init` captures them from the client struct's connection. The `%ensure-init` signature should be cleaned up.

---

## 2. Type Coverage (ftype Declarations)

### 2.1 connection.lisp — ✅ FULL COVERAGE

- `rate-limit-check`, `rate-limit-record!` — declared
- `connect!`, `disconnect!`, `reconnect!` — declared

### 2.2 events.lisp — ✅ FULL COVERAGE

- `register-listener`, `dispatch-event` — declared
- Custom `event-kind` type defined

### 2.3 commands.lisp — ✅ FULL COVERAGE

- `format-join`, `format-part`, `format-privmsg`, `format-nick`, `format-quit`, `format-mode`, `format-raw` — all declared

### 2.4 client.lisp — ✅ FULL COVERAGE

- `client-connect!`, `client-disconnect!`, `client-send-command!`, `client-join!`, `client-part!`, `client-privmsg!`, `client-quit!` — all declared

### 2.5 mock-server.lisp — ✅ FULL COVERAGE

- `enqueue-line!`, `dequeue-line!`, `pump-once!`, `run-e2e-scenario` — all declared

### 2.6 Coalton modules — ✅ TYPED BY DESIGN

All `.coal` files have explicit type signatures. Particularly strong in `mode-types.coal` and `state-types.coal` with comprehensive ADT coverage.

**Summary:** 100% ftype coverage on all CL exports.

---

## 3. Security Audit

### 3.1 Input Validation — ⚠️ PARTIAL

**Current state:** The Coalton `parse-irc-line` is a stub that wraps the entire raw input as a `CmdVerb`. In production, this would accept malformed messages without rejection.

**Risk:** Low (current) — no real network IO exists yet. The connection layer is a state-machine stub.

**Required before production:**
- CRLF injection prevention in user-supplied message content
- 8192-byte message length enforcement
- Invalid UTF-8 handling

### 3.2 Rate Limiting — ✅ PASS

- Token-bucket style rate limiter with configurable window and max
- `rate-limit-exceeded` condition on overflow
- Window auto-reset on expiry

### 3.3 Reconnect Limiting — ✅ PASS

- `max-reconnects` cap (default 10) prevents infinite reconnect loops
- `connection-refused` raised when exhausted

### 3.4 No eval/read-from-string — ✅ PASS

Zero uses of `eval`, `read-from-string`, or `compile` on network data.

### 3.5 Credential Handling — ❌ NOT YET IMPLEMENTED

The SASL module (`cap-sasl.coal`) has state machine types but no credential storage or zeroing. This is expected (SASL is typed scaffold only).

### 3.6 TLS — ❌ NOT YET IMPLEMENTED

`irc-connection` has a `tls-p` flag but no actual TLS socket integration. Expected at this phase.

### 3.7 Threat Model Coverage

| Threat | Mitigation Status |
|--------|------------------|
| Credential theft (PLAIN over non-TLS) | ❌ No TLS yet |
| TLS downgrade | ❌ No TLS yet |
| Message injection (CRLF) | ❌ No input sanitization |
| Buffer overflow (>8192) | ❌ No size enforcement |
| Nick collision | ❌ No auto-retry logic |
| DCC exploit | N/A — DCC not implemented |
| Flooding (outbound) | ✅ Rate limiter implemented |
| CTCP abuse | ❌ CTCP stub only |
| Proxy credential leak | N/A — proxy not implemented |
| Memory exhaustion | N/A — history not implemented |

### 3.8 CAP/SASL State Machines — ⚠️ REVIEW NOTE

`step-cap` and `step-sasl` ignore the current state — transitions are based solely on the event. This means invalid transitions (e.g., `EvCapAck` from `CapIdle`) are silently accepted. The state machine should reject invalid transitions with a typed error.

---

## 4. Code Quality Observations

### 4.1 Strengths
- Excellent Coalton ADT design: `ModeTypes`, `StateTypes` are comprehensive and well-documented
- Consumer mapping notes in `mode-types.coal` and `state-types.coal` are exemplary documentation
- Clean `!`-suffix convention for mutating functions
- Event dispatch system is simple and correct
- Mock server enables deterministic E2E testing without network

### 4.2 Improvement Suggestions (non-blocking)

1. **`%ensure-init` has unused parameters:** The function takes `host`, `port`, `tls-p` but doesn't use them (they come from `make-irc-client`'s keyword args). Fix: remove them or use them to initialize the connection.

2. **`client-send-command!` discards the command:** It dispatches an event with the verb but doesn't actually serialize/send. This is fine as a stub but should be documented.

3. **`client-join!` doesn't dispatch events:** Joining a channel pushes to the channel list but doesn't fire a `:join` event through the dispatcher. Same for `client-part!`.

4. **Coalton reducers are no-ops:** `apply-mode-delta` and `reduce-event` return `Ok state` unchanged. This is expected scaffolding but worth tracking.

5. **No ASDF system definition:** Like the markdown-notes project, no `.asd` file exists. Tests use raw `load`.

6. **Invariants module has broad pattern matching:** `modeArgValid` enumerates all valid operation combinations. If a new mode atom is added to `ModeTypes`, this function silently returns `False` rather than failing at compile time. Consider making it exhaustive.

---

## 5. Verdict

| Category | Status |
|----------|--------|
| API stability | ✅ PASS |
| Naming consistency | ✅ PASS |
| ftype coverage | ✅ 100% |
| Security (implemented) | ✅ Rate limiting only |
| Security (stubs/gaps) | ⚠️ Most mitigations not yet implemented |
| Compilation | ⚠️ 3 style warnings (minor) |
| Test suite | ✅ 18/18 E2E passing |
| Production readiness | ⚠️ Needs ASDF, real parser, TLS, CRLF sanitization |

**Overall: APPROVED for current phase.** The type system design (especially the Coalton ADTs for mode/state) is strong. The CL client/events/commands layer is clean and functional. Security mitigations are mostly future work, which is expected given the implementation phase — no real network IO exists yet.
