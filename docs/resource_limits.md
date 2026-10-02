# Resource Limit Guide

Resource limits bound externally triggered work and native-facing allocation.
Exceeding a limit returns a structured result or safe native fallback.

## Shared Limits

`A11y.Resource_Limits` owns defaults and validation for event queues, native
object caches, tombstone retention, relation targets, selection materialization,
text returned per request, traversal depth, native arrays, native strings,
outstanding callbacks, shutdown duration, diagnostics, coalescing windows, and
virtual-node realization.

## Configuration

Backends and fixtures accept validated resource-limit configuration. Invalid
configs fail without mutating the previous safe configuration.

## Native Values

D-Bus strings/object paths, BSTR values, SAFEARRAY values, NSString values,
NSArray values, diagnostic fields, and metadata text all obey shared bounds.

## Overflow Behavior

Overflow should preserve correctness. Prefer structured resource-limit results,
loss diagnostics, or documented invalidation over silent truncation that changes
semantic meaning.

Property retrieval maps bounded content failures to the common
`resource-limited` property status while preserving the structured
`Resource_Limit` result for backend and native translation.

Native object tombstone retention is a bounded metadata cache, not permission
to keep destroyed nodes live. When the retention limit is full, older retained
tombstone records may be evicted so newer destruction can be recorded. Native
object ids remain non-reused for the session, stale ids still resolve as
unavailable, and the cache keeps a separate defunct-node index so evicting
tombstone metadata does not permit rematerializing a native object for that
node. The runtime destroyed-node ledger provides the same resurrection guard at
backend-session scope.

Native callback admission is bounded by `Outstanding_Callbacks`. A full gate
returns `Resource_Limit`; a reset attempted while callbacks are still
outstanding returns `Invalid_State` through the structured overload and keeps
the active tokens valid for deterministic unwind.

Semantic session limit reconfiguration is also preflighted. The event queue,
relation graph, and registry callback pin limits are all checked before any
component mutates, so a failed relation-target or callback-pin shrink cannot
leave the event queue with a partially applied capacity change.

Native backend limit reconfiguration is two-phase. Runtime object-cache bounds
and diagnostic retention bounds are checked before either subsystem mutates, so
failed reconfiguration leaves the previous limits in force.

## Testing

Release and router tests cover invalid limits, oversized strings and arrays,
bounded relation targets, selection materialization, native object caches, and
diagnostic record bounds.
