# Security And Privacy

Accessibility exposes application semantics to privileged platform services.
The library treats this as a security boundary and keeps the semantic model in
charge of what can be observed or invoked.

## Protected Text

Protected text is mandatory for password and secure fields. Backends must not
expose raw protected content through names, values, text ranges, selections,
diagnostics, snapshots, event payloads, text counts, native offset conversion,
or caret metadata. Current portable and router tests cover protected text
redaction for semantic text, AT-SPI text scaffolds, UIA properties,
NSAccessibility attributes, and the common native value-text query boundary.
Providers can mark secure non-password value text through
`A11y.Properties.Privacy_Property_Provider`; protected value-text retrieval
returns a `permission-denied` property status rather than `unsupported`,
preserving the security reason without exposing content.

## Native Boundaries

Native boundary packages translate stale references, invalid arguments,
unsupported capabilities, shutdown, and internal failures into structured
results. Successful provider string query results are bounded by
`Native_String_Size` before native adapters consume them. Ada exceptions must be
contained before D-Bus, COM, or Objective-C boundaries.
The common native-boundary return classifier keeps those structured failures in
one backend-neutral set so platform bridges do not independently weaken stale
reference, resource-limit, shutdown, or permission-denied handling.

## Resource Limits

Externally triggered work is bounded by `A11y.Resource_Limits`. Limits cover
event queues, relation targets, native strings, native arrays, object caches,
callback admission, diagnostics, selections, text ranges, tables, documents,
and images.

## Diagnostics

Diagnostics are structured and bounded. Text fields are redacted unless a
future explicit opt-in diagnostic mode says otherwise. Free-form text is not
the primary diagnostic representation. Diagnostic logs revalidate direct record
aggregates against configured string limits before retention.
User-visible diagnostic/status labels are rendered through `A11y.Localization`
and the repository `messages` runtime, keeping localized prose out of retained
diagnostic records.

## Actions

Backends never mutate semantic state directly. Native action requests become
typed semantic action requests and are dispatched through the configured
dispatcher/provider contract.
