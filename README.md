# clpkg-irc-clients

A typed Common Lisp IRC client library with Coalton-first core, multi-server management, and comprehensive protocol support.

## Features

- **Typed core** — Coalton ADTs for mode parsing, state reduction, IRC messages, CAP/SASL, CTCP
- **Net layer** — TCP/TLS connections with sliding-window rate limiting and reconnect guards
- **Client layer** — event dispatch, command formatting, channel tracking, message history
- **Multi-server** — named server registry with connect-all/disconnect-all
- **Property-tested** — golden fixtures from InspIRCd, Ergo, and Solanum IRC daemons

## Requirements

- SBCL 2.5+
- Quicklisp (for Coalton dependencies)

## Quick Start

```lisp
(load "src/net/connection.lisp")
(load "src/client/events.lisp")
(load "src/client/commands.lisp")
(load "src/client/client.lisp")

(use-package :clpkg-irc-clients/client)

(let ((c (make-irc-client :nick "mybot" :user "bot" :realname "My Bot"
                          :host "irc.libera.chat" :port 6697)))
  (client-connect! c)
  (client-join! c "#lisp")
  (client-privmsg! c "#lisp" "Hello from Common Lisp!"))
```

## Testing

```bash
# Surface verification
sbcl --script scripts/verify-net-connection.lisp
sbcl --script scripts/verify-client-layer.lisp
sbcl --script scripts/verify-mode-parser-surface.lisp
sbcl --script scripts/verify-state-reducer-surface.lisp
sbcl --script scripts/verify-irc-message-surface.lisp
sbcl --script scripts/verify-ctcp-tags-surface.lisp
sbcl --script scripts/verify-cap-sasl-surface.lisp
sbcl --script scripts/verify-mock-irc-harness.lisp
sbcl --script scripts/verify-history-multi.lisp

# Property+fixture suite
sbcl --script tests/core/mode-state-tests.lisp

# E2E suite
sbcl --script tests/e2e/irc-e2e-scenarios.lisp
```

## Documentation

- [API Reference](docs/API.md)
- [Architecture](docs/ARCHITECTURE.md)

## License

MIT
