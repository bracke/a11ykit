# Actions Guide

Actions are stable semantic requests exposed by nodes that support action
capabilities. Backends translate native invocations into these requests and do
not mutate semantic state directly.

## Action Discovery

Providers expose a stable set of supported action identifiers and an optional
default action. Action names are protocol identifiers, not localized user-facing
descriptions.
Each action also carries common metadata for idempotency, whether parameters are
required, whether asynchronous acceptance is permitted, dispatcher behavior, and
security policy. Backends consume these classifications instead of inventing
platform-specific policy for focus changes, selection changes, value mutation,
window operations, or ordinary application-authorized actions.

## Preconditions

Common preconditions check lifecycle, availability, enabled state,
capabilities, and action-specific semantic state before dispatching to provider
code.
`Validate_Request` first checks the node's immutable supported action set, then
applies the common state preconditions, so native backends do not invoke
providers for unsupported, disabled, busy, read-only, or defunct actions.
State-aware native action invocations use the same central precondition checks
after resolving the stable `Node_Id` and before entering provider code.
State-aware provider invocation uses support-first ordering too: an unsupported
action returns `Unsupported_Action` without masking the failure as disabled,
busy, read-only, or defunct.
Platform action mappers also provide state-aware overloads, so native pattern
or selector discovery can reject disabled, busy, read-only, defunct, or
unsupported actions before advertising an invokable native operation.
Native request routers and method layers pass committed action-state snapshots
to those validation points, keeping action discovery and invocation rejection
aligned with the semantic model.

## Results

Expected action outcomes are structured: success, accepted asynchronous,
unsupported action, disabled, busy, invalid state, cancelled, timed out, node
unavailable, backend shutdown, permission denied, and internal error.

## Dispatch

Native action calls resolve the target `Node_Id`, validate exposure, enter the
dispatcher, invoke the provider, and return a structured result. Provider state
changes publish ordinary semantic events afterward.

## Security

Backends must not invoke actions on disabled or read-only controls contrary to
application semantics, and must not bypass application authorization policy.
