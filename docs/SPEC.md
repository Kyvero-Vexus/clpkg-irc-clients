# clpkg-irc-clients — Full Specification

> Sanitized public version (internal tracker IDs removed).


**Repo target:** Kyvero-Vexus/clpkg-irc-clients
**Status:** ACTIVE — fully tractable

---

## 1. Product Vision & Requirements

A **typed, modern Common Lisp IRC client library** providing a reusable protocol engine, connection manager, and client API. Designed as the IRC backbone for a future CL-Emacs but usable standalone by any CL program.

### 1.1 Capability Matrix

| Capability | Priority | Status |
|---|---|---|
| RFC 2812 message parsing/serialization | P0 | Actionable |
| TCP + TLS connection lifecycle | P0 | Actionable |
| Channel/user state machine | P0 | Actionable |
| IRCv3.2 capability negotiation | P0 | Actionable |
| SASL authentication (PLAIN, EXTERNAL) | P0 | Actionable |
| Message tags (IRCv3) | P1 | Actionable |
| CTCP (VERSION, ACTION, TIME, PING) | P1 | Actionable |
| Multi-server connection management | P1 | Actionable |
| Automatic reconnection w/ backoff | P1 | Actionable |
| Channel logging/history buffer | P1 | Actionable |
| DCC SEND/CHAT | P2 | Actionable |
| IRCv3.3 features (message IDs, replies, typing, read-marker) | P2 | Actionable |
| SCRAM-SHA-256 SASL | P2 | Actionable |
| Bot framework (command dispatch, rate limiting) | P2 | Actionable |
| Client certificate auth | P1 | Actionable |
| SOCKS5/HTTP CONNECT proxy support | P2 | Actionable |
| Bouncer protocol (BOUNCER IRCv3 draft) | P3 | Actionable but deferred — spec still draft |
| IRCv3 batch processing | P2 | Actionable |

### 1.2 Non-goals (explicit)

- No built-in GUI/TUI — this is a protocol + state library
- No IRC server/daemon implementation
- No bridging to other protocols (Matrix, XMPP)

---

## 2. Architecture

### 2.1 Module Map

```
clpkg-irc/
├── core/              # Coalton — pure protocol logic
│   ├── message.coal   # IRC message ADT, parser, serializer
│   ├── numeric.coal   # Numeric reply catalog (001-999)
│   ├── mode.coal      # Channel/user mode parser & state
│   ├── capability.coal # IRCv3 CAP negotiation state machine
│   ├── sasl.coal      # SASL mechanism implementations
│   ├── ctcp.coal      # CTCP encode/decode
│   └── state.coal     # Channel/user/network state graph
├── net/               # SBCL-typed CL — IO boundary
│   ├── connection.lisp # TCP/TLS socket lifecycle
│   ├── proxy.lisp     # SOCKS5/HTTP CONNECT
│   ├── rate-limit.lisp # Flood protection (token bucket)
│   └── reconnect.lisp # Exponential backoff reconnection
├── client/            # SBCL-typed CL — user-facing API
│   ├── client.lisp    # Main client object + event loop
│   ├── events.lisp    # Event type hierarchy + dispatch
│   ├── commands.lisp  # High-level command API (join, msg, etc.)
│   ├── history.lisp   # Ring buffer message history
│   └── multi.lisp     # Multi-server manager
├── bot/               # SBCL-typed CL — bot framework
│   ├── handler.lisp   # Command router + prefix dispatch
│   └── plugin.lisp    # Plugin protocol (CLOS)
└── compat/            # Portability shims (future: ECL, CCL)
    └── shim.lisp
```

### 2.2 Coalton Core Rationale

The `core/` module is **pure Coalton** because:
- Message parsing is a pure function (bytes → ADT) — perfect for algebraic types
- State transitions (CAP negotiation, SASL challenge-response) are pure state machines
- Exhaustive pattern matching prevents silent drops of new numeric codes
- Property-based testing is trivial on pure functions

### 2.3 Key Types (Coalton)

```coalton
(define-type IrcMessage
  (IrcMessage
    (Optional MessageTags)    ; IRCv3 tags
    (Optional Prefix)         ; :nick!user@host or :server
    Command                   ; PRIVMSG, JOIN, numeric, etc.
    (List String)))           ; params

(define-type Prefix
  (ServerPrefix String)
  (UserPrefix Nickname (Optional Username) (Optional Hostname)))

(define-type Command
  (Named String)              ; PRIVMSG, JOIN, etc.
  (Numeric UFix))             ; 001, 433, etc.

(define-type MessageTags
  (MessageTags (Map String (Optional String))))

(define-type CapState
  CapNone
  (CapListing (List String))
  (CapRequesting (List String))
  CapNegotiated
  CapFailed)

(define-type SaslState
  SaslIdle
  (SaslAuthenticating SaslMechanism)
  SaslSuccess
  (SaslFailed String))
```

### 2.4 SBCL-Typed Boundary (net/client)

```lisp
(declaim (ftype (function (connection-config) (values irc-connection &optional))
                make-connection))
(declaim (ftype (function (irc-connection) (values irc-message &optional))
                read-message))
(declaim (ftype (function (irc-connection irc-message) (values null &optional))
                send-message))
```

All exported functions carry full `ftype` declarations. All structs use `(declaim (type ...))`. Safety 0 / Speed 3 only in hot loops with explicit `the` annotations.

### 2.5 Public API Surface

```lisp
;; Primary entry points
(defgeneric connect (client server &key port tls nick user real-name password
                     sasl-mechanism sasl-credentials
                     proxy-config capabilities))
(defgeneric disconnect (client &key quit-message))
(defgeneric reconnect (client))

;; Channel operations
(defgeneric join-channel (client channel &key key))
(defgeneric part-channel (client channel &key message))
(defgeneric send-privmsg (client target message))
(defgeneric send-notice (client target message))
(defgeneric send-action (client target message))

;; State queries (all return typed structs)
(defgeneric channels (client) → (list channel-state))
(defgeneric users-in (client channel) → (list user-state))
(defgeneric channel-topic (client channel) → (or null topic-info))
(defgeneric server-info (client) → server-state)

;; Event system
(defgeneric add-handler (client event-type handler &key priority))
(defgeneric remove-handler (client handler-id))

;; History
(defgeneric channel-history (client channel &key limit since) → (list irc-message))

;; Multi-server
(defgeneric add-server (manager name config) → client)
(defgeneric remove-server (manager name))
(defgeneric get-client (manager name) → (or null client))
```

### 2.6 Dependency Budget

| Dependency | Purpose | License |
|---|---|---|
| coalton | Core typed modules | MIT |
| usocket | TCP sockets | MIT |
| cl+ssl | TLS | MIT-like |
| bordeaux-threads | Threading | MIT |
| ironclad | SASL crypto (SCRAM) | BSD |
| alexandria | Utilities | Public Domain |
| flexi-streams | Encoding | BSD |

All dependencies are libre. No non-free dependencies permitted.

---

## 3. Security Model

### 3.1 Threat Model

| Threat | Vector | Mitigation |
|---|---|---|
| Credential theft | SASL PLAIN over non-TLS | **Refuse** PLAIN over non-TLS by default; require explicit `:allow-insecure t` |
| TLS downgrade | STARTTLS stripping | Enforce TLS-first (port 6697); warn loudly on port 6667 |
| Message injection | Malformed CRLF in user input | Strict input sanitization; reject embedded CR/LF |
| Buffer overflow | Oversized messages | Hard 8192-byte message limit per RFC; reject & log |
| Nick collision | Server impersonation | Verify server prefix against connection state |
| DCC exploit | Malicious file transfer | DCC disabled by default; opt-in with size limits |
| Flooding | Outbound flood | Token-bucket rate limiter (default: 1 msg/500ms burst 5) |
| CTCP abuse | CTCP VERSION fishing | Configurable CTCP responses; rate-limit CTCP replies |
| Proxy credential leak | SOCKS5 auth over cleartext | Only permit proxy auth to localhost/TLS tunnels |
| Memory exhaustion | Unbounded history | Ring buffers with configurable max (default 10k/channel) |

### 3.2 Hardening Checklist

- [ ] All string inputs from network are validated against IRC grammar before use
- [ ] No `eval`/`read-from-string` on any network data
- [ ] TLS certificate verification enabled by default (with `:verify-mode :peer`)
- [ ] SASL credentials zeroed from memory after auth completes
- [ ] Connection timeout defaults (connect: 15s, read: 300s)
- [ ] All error conditions are handled; no unhandled conditions crash the client

---

## 4. Performance Model

### 4.1 Budgets

| Operation | Target | Measurement |
|---|---|---|
| Message parse (bytes → IrcMessage) | < 2μs per message | Microbenchmark with `sb-ext:get-internal-real-time` |
| Message serialize (IrcMessage → bytes) | < 1μs per message | Same |
| State update (JOIN/PART/QUIT) | < 5μs | Same |
| Sustained throughput | > 50,000 msg/s single-threaded | Synthetic flood test |
| Memory per connection (idle, 100 channels) | < 2MB | `sb-ext:dynamic-space-usage` delta |
| Connection startup (TCP+TLS+CAP+SASL) | < 3s on LAN | Wall clock |
| Reconnection (with backoff, 3 attempts) | < 30s | Wall clock |

### 4.2 Profiling Strategy

1. **Microbenchmarks:** Coalton core functions benchmarked in isolation via `trivial-benchmark`
2. **Load test:** Synthetic IRC server (local loopback) pumping 100k messages; measure throughput + allocation rate
3. **Memory profiling:** `sb-sprof` allocation profiling on sustained multi-channel session
4. **Latency profiling:** Measure event-handler dispatch latency under load

### 4.3 Optimization Notes

- Message parser uses direct byte-buffer scanning (no intermediate string allocation for routing)
- Channel user lists stored in hash tables, not alists
- History ring buffers are pre-allocated, not consed

---

## 5. End-to-End Usage Test Matrix

### 5.1 Test Infrastructure

- **Mock IRC server:** A simple TCP server in CL that speaks IRC protocol, used for all E2E tests
- **Test framework:** FiveAM for unit/integration; custom E2E harness for scenario playback
- **CI:** SBCL on Linux (primary), CCL smoke test (stretch)

### 5.2 Scenario Matrix

| ID | Scenario | Covers | Type |
|---|---|---|---|
| E01 | Connect to TLS server, authenticate SASL PLAIN, join #test, send msg, verify echo | Connection, TLS, SASL, JOIN, PRIVMSG | E2E |
| E02 | Connect, CAP negotiate (multi-prefix, sasl, message-tags), verify state | CAP negotiation state machine | E2E |
| E03 | Join 3 channels, receive NAMES, verify user lists populate correctly | State tracking | E2E |
| E04 | Receive TOPIC, MODE changes, verify state updates | State machine | E2E |
| E05 | Server sends ERROR, verify clean disconnect + reconnect | Reconnection | E2E |
| E06 | Kill connection mid-stream, verify auto-reconnect with backoff | Reconnection | E2E |
| E07 | Send messages at flood rate, verify rate limiter delays | Rate limiting | E2E |
| E08 | Receive CTCP VERSION, verify response sent | CTCP | E2E |
| E09 | Receive malformed messages (no CRLF, oversized, invalid UTF-8), verify graceful handling | Input validation | E2E |
| E10 | Multi-server: connect to 2 servers, join channels on each, verify isolation | Multi-server | E2E |
| E11 | Bot: register command handler, receive trigger, verify dispatch + response | Bot framework | E2E |
| E12 | DCC SEND offer received, verify not auto-accepted | DCC security | E2E |
| E13 | Channel history: send 100 messages, query last 50, verify order | History buffer | E2E |
| E14 | Nick collision (433), verify auto-retry with suffix | Error handling | E2E |
| E15 | SASL EXTERNAL with client cert, verify auth | Client cert auth | E2E |
| E16 | Parse 10,000 real-world IRC log lines, verify zero parse failures | Parser robustness | Integration |
| E17 | IRCv3 message-tags round-trip (parse, serialize, compare) | Tags | Unit (property) |
| E18 | All RFC 2812 numerics: verify catalog completeness | Numeric catalog | Unit |

### 5.3 Coverage Target

- Line coverage: > 90% on `core/` (Coalton)
- Line coverage: > 85% on `net/` and `client/`
- All P0/P1 capabilities have at least one E2E scenario
- All security mitigations have a negative test (attack attempt → correct rejection)

---

## 6. Repo Bootstrap Plan

```
Kyvero-Vexus/clpkg-irc-clients/
├── clpkg-irc.asd              # ASDF system definition
├── clpkg-irc-test.asd         # Test system
├── README.md
├── LICENSE                    # MIT or BSD-2
├── .gitignore
├── src/
│   ├── core/                  # Coalton modules
│   ├── net/                   # Network layer
│   ├── client/                # Client API
│   └── bot/                   # Bot framework
├── test/
│   ├── core/                  # Unit tests for Coalton core
│   ├── net/                   # Network layer tests
│   ├── client/                # Client API tests
│   ├── e2e/                   # End-to-end scenarios
│   ├── mock-server.lisp       # Mock IRC server
│   └── fixtures/              # IRC log fixtures
├── bench/
│   └── parse-bench.lisp       # Microbenchmarks
└── docs/
    ├── API.md
    └── ARCHITECTURE.md
```

---

## 7. Child Bead Tree

See bead IDs created below. Execution order follows dependency chain.

### Phase 1: Foundation (no deps)
- **jrs.2** — Implement Coalton core: message parser/serializer + types
- **jrs.3** — Implement Coalton core: numeric catalog + mode parser

### Phase 2: Protocol (depends on Phase 1)
- **jrs.4** — Implement Coalton core: CAP negotiation + SASL state machines
- **jrs.5** — Implement Coalton core: CTCP + message tags

### Phase 3: Network (depends on Phase 1)
- **jrs.6** — Implement net layer: TCP/TLS connection + rate limiter + reconnect

### Phase 4: Client (depends on Phase 2+3)
- **jrs.7** — Implement client layer: client object, event system, commands, state tracking
- **jrs.8** — Implement client layer: history, multi-server manager

### Phase 5: Bot + Polish (depends on Phase 4)
- **jrs.9** — Implement bot framework: command router + plugin protocol

### Verification (parallel with each phase)
- **jrs.10** — Mock IRC server + E2E test harness
- **jrs.11** — Full E2E scenario suite (E01–E18) + coverage gate
- **jrs.12** — Performance benchmarks + budget verification

### Review
- **jrs.13** — Architecture review: API stability, type coverage, security audit
- **jrs.14** — Documentation: API.md, ARCHITECTURE.md, README

---

## 8. Tractability Assessment

**Verdict: FULLY TRACTABLE.** IRC is a mature, well-specified protocol. All capabilities listed are implementable with existing CL infrastructure. Coalton is stable enough for the pure core. No blockers identified.

---

## 9. Handoff Summary

- **Spec doc:** `docs/clpkg-irc-clients-spec.md`
- **First executable step:** Create repo, bootstrap ASDF system, implement `jrs.2` (Coalton message parser)
- **Critical path:** jrs.2 → jrs.4 → jrs.6 → jrs.7 → jrs.11
- **Estimated total implementation beads:** 13

## 10. Active Bead Breakdown References

- `(internal-tracker)` detailed execution plan: `docs/jrs-78ug-mode-state-breakdown.md`
