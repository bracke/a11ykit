# Diagnostics Guide

Diagnostics are structured records used by semantic validation, backend
scaffolds, release tooling, and future native transports.

## Diagnostic Records

Records carry stable identifier, severity, subsystem, safe `Node_Id` where
available, feature identifier where relevant, structured fields, redaction
status, timestamp, and sequence/context identifiers.
Use `A11y.Diagnostics.Create` or `Create_For_Status` for new records so
identifier bounds, feature bounds, status-to-category mapping, default severity,
redaction, node, and sequence metadata are initialized consistently before a
record reaches a diagnostic log. Direct record aggregates remain possible for
tests and adapters, but logs revalidate them before retention.
User-visible diagnostic and status labels are rendered separately through
`A11y.Localization`, which uses the repository `messages` catalog runtime.
Severity labels use the same catalog-backed path, with stable machine keys such
as `severity.warning` and `severity.fatal`.
Diagnostic records therefore remain stable machine data and do not need to
store localized prose.

## Categories

Categories include backend initialization, native runtime connection, native
registration, node lifecycle, provider timeout, mapping fallback, unsupported
capability, resource limit, event overflow, stale native query, text
conversion, native allocation, ABI boundary failure, reference-count anomaly,
shutdown anomaly, and conformance failure.

## Redaction

Protected text and user-entered text are not logged by default. Diagnostics
record redaction status and keep free-form text secondary to stable structured
fields.

## Rate Limits

Diagnostic logs are bounded and repeated adjacent failures are rate-limited
without losing the dropped-count signal. The log revalidates diagnostic
identifiers, feature identifiers, and directly constructed field keys/values
against the configured `Native_String_Size` limit before retention, so callers
cannot bypass field constructors by appending public record aggregates.

## Native Boundaries

Native boundary packages map structured result categories to diagnostics before
returning D-Bus, UIA, or NSAccessibility-facing failures.
The shared native backend scaffold also records runtime publication failures
after transport admission, including the event sequence and stable `status`
field, so stale-node, ordering, shutdown, and resource failures remain
machine-classifiable.
