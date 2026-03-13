# clpkg-irc-clients

Typed Common Lisp IRC client library (protocol + state engine + client API), designed for reuse in CL applications and future editor integrations.

## Status

- Public sanitized planning/specification repository
- Architecture and API specification available in `docs/SPEC.md`
- Implementation breakdown in `docs/IMPLEMENTATION-BREAKDOWN.md`

## Design goals

- Reusable package-first architecture
- Strict typed Common Lisp boundaries (SBCL declarations) with Coalton-first pure core modules
- Security-first networking defaults (TLS, bounded buffers, flood controls)
- End-to-end usage-driven test strategy

## License

AGPL-3.0-or-later
