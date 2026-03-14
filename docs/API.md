# clpkg-irc-clients — API Reference

## Packages

### clpkg-irc-clients/net
TCP/TLS connection + rate limiter + reconnect.

| Symbol | Type | Description |
|--------|------|-------------|
| `irc-connection` | struct | Connection state (host, port, tls-p, state, reconnect params) |
| `connect!` | function | `(conn) → conn` — transition to :connected |
| `disconnect!` | function | `(conn) → conn` — transition to :disconnected |
| `reconnect!` | function | `(conn) → conn` — reconnect with count tracking |
| `rate-limiter` | struct | Sliding-window rate limiter |
| `rate-limit-check` | function | `(rl now) → boolean` |
| `rate-limit-record!` | function | `(rl now) → rl` (signals `rate-limit-exceeded`) |
| `connection-refused` | condition | Max reconnects exceeded |
| `connection-timeout` | condition | Connection timeout |
| `rate-limit-exceeded` | condition | Rate limit exceeded |

### clpkg-irc-clients/events
Typed event hierarchy + dispatch.

| Symbol | Type | Description |
|--------|------|-------------|
| `irc-event` | struct | Event (kind, source, target, payload, timestamp) |
| `event-dispatcher` | struct | Listener registry |
| `register-listener` | function | `(dispatcher kind handler) → dispatcher` |
| `dispatch-event` | function | `(dispatcher event) → list-of-results` |
| `event-kind` | type | `:connect :disconnect :message :join :part :quit :nick :mode :kick :topic :invite :notice :privmsg :ctcp :numeric :error :raw` |

### clpkg-irc-clients/commands
High-level IRC command formatters.

| Symbol | Type | Description |
|--------|------|-------------|
| `irc-command` | struct | Command (verb, args) |
| `format-join` | function | `(channel) → irc-command` |
| `format-part` | function | `(channel &optional msg) → irc-command` |
| `format-privmsg` | function | `(target message) → irc-command` |
| `format-nick` | function | `(nick) → irc-command` |
| `format-quit` | function | `(&optional message) → irc-command` |
| `format-mode` | function | `(target modes) → irc-command` |
| `format-raw` | function | `(line) → irc-command` |

### clpkg-irc-clients/client
Main IRC client object + state tracking.

| Symbol | Type | Description |
|--------|------|-------------|
| `irc-client` | struct | Client (nick, user, realname, connection, dispatcher, channels, state) |
| `client-connect!` | function | `(client) → client` |
| `client-disconnect!` | function | `(client) → client` |
| `client-join!` | function | `(client channel) → client` |
| `client-part!` | function | `(client channel) → client` |
| `client-privmsg!` | function | `(client target msg) → client` |
| `client-quit!` | function | `(client) → client` |

### clpkg-irc-clients/history
Ring-buffer message history.

| Symbol | Type | Description |
|--------|------|-------------|
| `history-buffer` | struct | Ring buffer (capacity, entries, count) |
| `history-push!` | function | `(buffer entry) → buffer` |
| `history-entries` | function | `(buffer &key limit) → list` |
| `history-search` | function | `(buffer query) → list` |

### clpkg-irc-clients/multi
Multi-server connection manager.

| Symbol | Type | Description |
|--------|------|-------------|
| `server-manager` | struct | Named client registry |
| `manager-add!` | function | `(mgr name client) → mgr` |
| `manager-remove!` | function | `(mgr name) → mgr` |
| `manager-get` | function | `(mgr name) → client-or-nil` |
| `manager-connect-all!` | function | `(mgr) → mgr` |
| `manager-disconnect-all!` | function | `(mgr) → mgr` |
| `sm-active-count` | function | `(mgr) → fixnum` |

## Coalton Modules

### Core.ModeTypes
Channel/user mode ADTs (ChannelModeOp, UserModeOp, ArgSpec, ModeError).

### Core.StateTypes
Network state ADTs (Membership, Channel, User, Network, StateError).

### Core.Mode
Mode parser (parse-mode-line, parse-mode-tokens).

### Core.State
Pure state reducer (reduce-event, reduce-events, apply-mode-delta).

### Core.IrcMessage
IRC message parser/serializer (Prefix, Command, IrcMessage).

### Core.CtcpTags
CTCP + IRCv3 message tags (CtcpMessage, MessageTag).

### Core.CapSasl
CAP negotiation + SASL state machines.
