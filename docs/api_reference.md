# Public API Reference

This reference summarizes the platform-neutral public package surface. Package
specifications remain the source of truth for exact Ada declarations.

## Semantic Packages

`A11y.Node_Ids`, `A11y.Roles`, `A11y.States`, `A11y.Geometry`,
`A11y.Properties`, `A11y.Capabilities`, `A11y.Results`, and
`A11y.Resource_Limits` define the primitive portable vocabulary.
`A11y.Localization` renders user-visible diagnostic category and result status
labels through the repository message catalog stack; stable semantic records
continue to store identifiers and structured fields, not localized prose.
`A11y.Properties` distinguishes property status from value kind and provides
typed result records for string, integer, boolean, rectangle, role, and
state-set values so backends do not collapse semantic properties into strings.
`Status_From_Result` centralizes the mapping from structured result status
codes into property statuses so query adapters preserve unsupported,
temporarily unavailable, node-unavailable, resource-limited, and error outcomes
consistently.
Security-driven denials such as protected text use `permission-denied` instead
of pretending the property is unsupported.
Safe structural property queries are limit-aware: set position and set size are
bounded by `Native_Array_Size`, while hierarchy and heading levels are bounded by
`Traversal_Depth`; failures clear integer payloads before backend projection.

## Provider Packages

`A11y.Nodes`, `A11y.Actions`, `A11y.Text`, `A11y.Values`,
`A11y.Selection`, `A11y.Tables`, `A11y.Documents`, `A11y.Images`,
`A11y.Relations`, and `A11y.Windows` define provider-facing semantics and
capability metadata.

## Runtime Packages

`A11y.Registry`, `A11y.Trees`, `A11y.Sessions`, `A11y.Events`,
`A11y.Event_Queues`, `A11y.Event_Subscriptions`, and `A11y.Dispatchers`
coordinate identity, lifecycle, tree ownership, event delivery, and provider
threading.

## Backend Packages

`A11y.Backends`, `A11y.Backends.Default`, `A11y.Backends.Selection`,
`A11y.Backends.Null_Backends`, `A11y.Backends.Disabled_Backends`, and
`A11y.Backends.Native_Backends` define the common backend contract and staged
backend selection behavior.
`A11y.Backends.Default.Create_Default` creates the target-aware common backend
and falls back to the validating Null backend when native transport is
unavailable. `Create_Null` creates the validating Null backend for deterministic
tests, and `Create_From_Override` applies `default`, `native`, `null`, and
`disabled` runtime overrides while returning only
`A11y.Backends.Backend'Class`. The selection result carries a `Fallback` flag
so unavailable native defaults, unsupported native targets, and invalid
overrides are not confused with a deliberate Null backend selection.
Native backend adapters use `Admit_Transport`, `Record_Transport_Failure`,
`Transport_Status`, and `Prepare_Publication` to manage the internal native
transport boundary without exposing D-Bus, COM, or Objective-C handles.
`Transport_Status` includes a monotonic `Generation` so adapters can detect
changed admission, running, unavailable, failed, and shutdown observations
without retaining native handles or application state.
`Prepare_Publication_With_Report` is the diagnostic form of publication
preparation and returns the same prepared event plus transport before/after
snapshots, event validity, runtime preparation evidence, prepared object flags,
and final structured status.
The `_With_Report` transport variants additionally return before/after
snapshots and transition facts for admission, failure recording, and stop.
`A11y.Native_Runtimes.Runtime_Snapshot` likewise exposes a backend-private
runtime `Generation` for session creation, running transition, defunct marking,
and shutdown reset observations.
The native runtime `_With_Report` lifecycle variants return before/after
snapshots and transition facts for initialize, start, and stop without exposing
native handles.
Its `Object_Cache_Generation` field mirrors the runtime-owned native object
cache mutation generation, while object snapshots carry the same
`Cache_Generation` value for stale-reference diagnostics.
`A11y.Native_Object_Caches` also provides `_With_Report` variants for ensure,
defunct marking, release, and reset. These return `Cache_Mutation_Report`
records for backend-private evidence under `native.object_cache.mutation_report`.
The platform-native registries provide matching `_With_Report` variants for
object/provider/element ensure, defunct marking, release, and drained reset
paths; their report records are backend-private evidence under
`native.object_registry.mutation_report`.
`A11y.Native_Boundary_Calls` carries that cache generation into native
call snapshots and outcomes after object or node resolution. Those snapshots
and outcomes also carry the runtime `Generation` observed before callback
admission, so backend bridges can diagnose stale session observations without
retaining application state or native object addresses.
`A11y.Native_Callbacks.Callback_Gate_Snapshot` exposes a backend-private
callback-gate `Generation` for callback admission, shutdown admission closure,
and successful reset observations.
Backend adapters use `A11y.Native_Query_Calls` for safe provider queries.
Its `Property_Value` helpers convert role, state-set, and bounds query results
into the common typed property records while preserving node-unavailable,
timeout, cancellation, unsupported, resource-limit, and error status classes
through `A11y.Properties.Status_From_Result`.

## Compatibility Packages

The historical `A11ykit` packages remain as compatibility surface while the
new `A11y` hierarchy becomes the intended stable semantic API.
`A11ykit` maps to the primitive role/geometry/state packages, `A11ykit.Tree`
maps to the session-owned tree and registry model, and
`A11ykit.Compatibility.To_Semantic_Snapshot` converts a validated legacy tree
into `A11y.Semantic_Snapshots` metadata with central role/capability
validation, typed logical-desktop bounds, visible titles, keyboard shortcuts,
locale, orientation, landmark, and stable semantic identifiers.
`A11ykit.Compatibility.Populate_Session` commits that validated legacy tree
through `A11y.Sessions` node creation, attachment, focus, registry
capability, and event-queue operations. On Linux,
`A11ykit.Provider.Publish` now attempts hostkit-backed AT-SPI startup,
application-root registration, semantic signal queueing, and one bounded serve
cycle before falling back to the target-aware validating Null backend when the
native transport is unavailable or incomplete. `Last_Publish_Status`,
`Last_Published_Event_Count`, `Last_Publish_Backend_Name`,
`Last_Publish_Used_Fallback`, and `Last_Publish_Selection_Status` expose the
last semantic handoff result. `A11ykit.Provider` maps to the backend selection/default backend packages.
`A11ykit.Provider.Backend_Name`
uses the same hostkit-backed name as `A11y.Platforms.Native_Backend_Name`, while
`Available` reports whether the platform facade currently has a registered
native provider session.
`A11y` backend session and native provider registration path. These
compatibility packages are retained rather than removed; migration should be
additive until a specific legacy behavior is proven unsafe or semantically wrong.

`A11ykit.Compatibility` is the executable migration layer for legacy tree
snapshots. It maps old roles, framebuffer rectangles, basic state flags, parent
indices, and focus indices into neutral `A11y` roles, logical rectangles, state
sets, and `Node_Id` values for one snapshot. Those projected identities are
compatibility references, not a replacement for the session registry's durable
identity allocation.

`A11ykit.Compatibility.Validate_Tree` validates a legacy snapshot before it is
adapted or published. It requires one root, valid parent and focus indexes, and
an acyclic parent chain; malformed snapshots return structured `A11y.Results`
statuses instead of being silently projected.
`A11ykit.Compatibility.To_Semantic_Snapshot` preserves legacy names,
descriptions, roles, state flags, and role-derived capabilities in the common
semantic snapshot model so future provider delegation can consume the same
validated metadata as native backend mappers.
`A11ykit.Compatibility.Populate_Session` is the session-side adapter: it refuses
invalid legacy trees before mutation, checks event capacity up front, creates
metadata-backed nodes with explicit capabilities, attaches the same tree shape,
and sets focus through the common session lifecycle path.
