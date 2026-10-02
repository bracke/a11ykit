# a11y Quickstart

This guide shows the intended application-facing shape of the portable
provider API. Native transports are still staged, so examples should be read as
semantic-provider setup rather than a production AT-SPI, UIA, or
NSAccessibility registration recipe.

## Build

Use the pinned Alire toolchain from the repository root:

```sh
alr build
alr exec -- gprbuild -q -P tests/all_tests.gpr
```

The test crate produces portable semantic tests, backend router tests, the
capability matrix, the release qualification checklist, and the release gate.

## Provider Setup

Applications define one semantic tree using `A11y.Node_Ids`, `A11y.Roles`,
`A11y.States`, `A11y.Properties`, `A11y.Trees`, and the capability packages.
The semantic tree is the authoritative model. Backends project that model into
native concepts and do not own application state.

Use stable `Node_Id` values allocated by the registry or mapped through
`A11y.Node_Keys` for virtual controls. Do not derive identities from addresses,
native handles, row indexes, or localized labels.

## Backend Selection

Applications use the common backend contract in `A11y.Backends` and the
selection helpers in `A11y.Backends.Selection`/`A11y.Backends.Default`.
Supported override names are `default`, `native`, `null`, `disabled`, and
`off`. Current native backends are honest scaffolds and report unavailable
until transport registration is implemented.
Use `A11y.Backends.Default.Create_Default` for normal target-aware startup; it
falls back to the validating Null backend while the target native transport is
unavailable.
Use `Create_From_Override` when an environment variable, command-line option,
or toolkit setting must force `native`, `null`, or `disabled` while still
returning only the common `A11y.Backends.Backend'Class` contract. Inspect the
selection result's `Fallback` flag before treating Null as a deliberate backend
choice. Explicit `native` may still select a staged native scaffold and report
`Backend_Unavailable` until transport registration is implemented. Use
`Create_Null` only for deterministic semantic validation and headless
conformance tests.

## Events

Commit semantic state before publishing events. Native notifications are
derived from committed semantic events, and stale or hidden nodes must not leak
through native projection.

## Protected Text

Password and secure text providers must mark protected text. Protected text is
never exposed through value properties, text ranges, diagnostics, snapshots, or
event payloads.
