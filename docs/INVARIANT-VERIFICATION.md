# IRC ADT Invariant Verification

This document captures invariant predicates and fixture coverage for the mode/state ADT surface.

## Predicate helpers

Implemented in `src/core/invariants.coal`:

- `membershipNickUniquenessHolds`
  - Ensures channel membership lists do not contain duplicate nick entries.
- `privilegeMonotonicityHolds`
  - Validates stable per-nick privilege transition shape between two snapshots.
- `modeSequenceArityHolds`
  - Verifies mode-operation argument arity correctness across a sequence.

## Fixture sets

`src/core/invariants.coal` exports positive/negative fixture families:

- `membershipPositiveFixtures` / `membershipNegativeFixtures`
- `privilegePositiveFixtures` / `privilegeNegativeFixtures`

Each fixture encodes an expected boolean result to support deterministic parser/reducer validation.

## Coverage summary

Invariant dimensions covered:

- membership integrity (duplicate nick rejection)
- privilege transition consistency (stable identity across transitions)
- mode argument arity checks (flag-only and arg-required modes)

## CI integration target

The fixture families are intended to be consumed by downstream FiveAM/Coalton checks so parser and reducer layers can assert invariants before state mutation.

This document is sanitized for public publication and omits internal tracker identifiers.
