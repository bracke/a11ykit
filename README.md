# a11y

a11y is the platform-neutral Ada accessibility provider library that publishes
a semantic accessibility tree to the host's screen-reader service: AT-SPI over
D-Bus on Linux, UI Automation on Windows, and NSAccessibility on macOS.
Applications describe semantics once through the shared `A11y` API.

The forward-compatible public API is the `A11y` package hierarchy. The original
`A11ykit` packages remain as a compatibility layer for existing users.

## Packages

* `A11y` — Platform-neutral semantic accessibility model root.
* `A11y.Node_Ids` — Opaque stable node identities.
* `A11y.Roles`, `A11y.States`, `A11y.Geometry`, `A11y.Properties`,
  `A11y.Capabilities` — Portable semantic vocabulary. Roles expose stable
  protocol identifiers and metadata-derived helper predicates; states expose
  stable identifiers and application-provided versus centrally-derived
  classification; geometry exposes logical desktop rectangles, overflow-safe
  edges, intersection, visibility classification, and bounded visible regions;
  capabilities expose stable interface identifiers; properties expose stable
  identifiers plus typed status and value-kind metadata for names,
  locale, geometry, set/hierarchy positions, landmarks, roles, and states.
  `A11y.Properties.Textual_Property_Provider` is an optional capability
  interface for help text, placeholders, value text, keyboard shortcuts,
  locale, orientation, and landmark metadata.
* `A11y.Actions` — Typed action discovery, stable protocol action metadata,
  precondition validation, default-action selection, and safe provider
  invocation.
* `A11y.Values` — Typed values, exact decimals, stable value/access metadata,
  range metadata, increments, units, precision, and explicit native-float
  conversion.
* `A11y.Selection` — Bounded selection sets with single/multiple modes,
  stable selection mode metadata, selection-required policy, anchor, and current
  item.
* `A11y.Text` — Opaque text ranges, protected-text policy, bounded slices,
  typed edit requests, and UTF-16 conversion helpers with stable text metadata.
* `A11y.Tables` — Sparse table snapshots with logical size, stable cell
  identities, spans, reverse coordinate lookup, and stable coordinate/header
  metadata.
* `A11y.Documents`, `A11y.Images`, `A11y.Windows` — Portable metadata for
  document structure, semantic images, and surfaces/windows, with stable
  role/kind metadata for backend projection.
* `A11y.Nodes` — Small core accessible-node interface plus stable
  lifecycle/exposure metadata and role/state/capability contract validation.
* `A11y.Registry` — Protected registry with monotonic identity allocation,
  lifecycle state, pinning, and tombstones.
* `A11y.Node_Keys` — Collision-safe application-key registry for virtualized
  controls that need stable model keys mapped to `Node_Id` values.
* `A11y.Trees` — Stable `Node_Id` accessibility tree ownership model.
* `A11y.Events` — Typed semantic event vocabulary, stable event identifiers,
  central coalescing metadata, and bounded text mutation payload validation.
* `A11y.Live_Regions` — Stable live-region priority/relevance metadata and
  protected, bounded announcement validation.
* `A11y.Event_Queues` — Bounded semantic event queue with narrow safe
  coalescing.
* `A11y.Event_Subscriptions` — Bounded backend subscription and event-filter
  fan-out accounting for native notification delivery.
* `A11y.Backends.Event_Pumps` — Ordered delivery from semantic sessions to
  backend contracts, preserving queued events when publication fails.
* `A11y.Relations` — Relation graph with stable relation identifiers,
  automatic inverse metadata, and dangling-target cleanup.
* `A11y.Sessions` — Semantic session layer that commits registry/tree state
  before queueing lifecycle and tree events.
* `A11y.Dispatchers` — Immediate/test dispatcher with stable call-kind timeout
  metadata, cancellation token policy, per-kind bounded accounting, shutdown
  rejection, reentrancy detection, and exception containment.
* `A11y.Conformance` — Stable feature identifiers and backend support
  declarations.
* `A11y.Diagnostics` — Structured bounded diagnostics with stable category
  metadata, result-category mapping, redaction metadata, and repeated-diagnostic
  rate limiting.
* `A11y.Localization` — Message-catalog backed labels for user-visible
  diagnostic categories and result statuses, using the repository `messages`
  stack rather than embedding prose in diagnostic records.
* `A11y.Resource_Limits` — Central resource-limit defaults, validation, and
  exceeded-request checks for bounded semantic and native-facing operations,
  with stable limit metadata.
* `A11y.Results` — Structured status codes with stable identifiers and
  expected-failure metadata for semantic and native boundary results.
* `A11y.Platforms` — Host platform/backend naming delegated through hostkit.
* `A11y.Native_Runtimes` — Shared native backend session/cache lifecycle with
  ordered semantic event application, native-object preparation, and defunct
  marking for destroyed nodes.
* `A11y.Native_Identity` — Stable backend session identity, Linux object paths,
  and runtime identifier components derived from `Node_Id`.
* `A11y.Native_Object_Caches` — Backend-neutral native object cache identities,
  session-scoped resolution, defunct tombstones, and deterministic release.
* `A11y.Native_Object_Caches.Classification` — SPARK-clean cache capacity,
  allocation-count, and tombstone-retention limit predicates shared with the
  mutable native object cache.
* `A11y.Native_Callbacks` — Backend-neutral native callback admission gate with
  bounded outstanding callbacks, shutdown rejection, and deterministic
  completion accounting.
* `A11y.Native_Boundary_Calls` — Backend-neutral object-call context that
  combines callback admission with session-scoped native object resolution,
  dispatcher call-kind snapshots, and automatic token cleanup on stale
  references.
* `A11y.Native_Action_Calls` — Backend-neutral action invocation boundary that
  resolves native objects, routes through the dispatcher, invokes semantic
  action providers, propagates cancellation before mutation, and unwinds
  callback admission.
* `A11y.Native_Query_Calls` — Backend-neutral property query boundary for core
  native role, state, name, description, and geometry requests through the
  dispatcher, with cancellation support for role/property and bounds/geometry
  queries.
* `A11y.Native_Tree_Calls` — Backend-neutral tree-navigation boundary for
  parent, child-count, and indexed-child native requests, with pre-provider
  cancellation support.
* `A11y.Native_Component_Calls` — Backend-neutral component geometry boundary
  for contains-point and hit-test native requests, with pre-provider
  cancellation support.
* `A11y.Native_Focus_Calls` — Backend-neutral focus boundary for focused-state
  queries and set-focus action requests through the dispatcher, with
  pre-provider cancellation support.
* `A11y.Native_Relation_Calls` — Backend-neutral relation boundary for native
  active-descendant and bounded multi-target relation queries using stable
  `Node_Id` targets, with pre-provider cancellation support.
* `A11y.Native_Runtimes` — Shared native backend runtime state, session
  ownership, object-cache reset, stale-call rejection, and deterministic
  start/stop scaffolding.
* `A11y.Backends` — Common backend contract with stable backend kind/state
  metadata. Backends expose structured conformance declarations.
* `A11y.Backends.Native_Backends` — Runtime-owning native backend scaffold that
  reports target-specific support declarations while honestly returning
  unavailable until real OS transport/ABI registration exists.
* `A11y.Backends.Null_Backends` — Validating Null backend for portable
  conformance tests.
* `A11y.Results.Classification` — SPARK-clean status classification helpers
  for success/failure and expected/native-failure grouping.
* `A11y.Properties.Classification` — SPARK-clean property-status and
  property-value-kind classification helpers.
* `A11y.Values.Classification` — SPARK-clean value-kind and access-mode
  classification helpers.
* `A11y.Actions.Classification` — SPARK-clean action category and
  precondition-failure classification helpers.
* `A11y.Backends.Classification` — SPARK-clean backend state and native
  transport classification helpers.
* `A11y.Backends.Default_Classification` — SPARK-clean constructor-family and
  defensive native fallback policy helpers.
* `A11y.Backends.Selection.Classification` — SPARK-clean backend override,
  selected-backend, status, and fallback policy helpers.
* `A11y.Backends.Transport_Classification` — SPARK-clean native transport
  mutation, startup, publication-admission, failure-status, and
  generation-advance policy helpers.
* `A11y.Platforms.Classification` — SPARK-clean platform/backend selection
  predicates.
* `A11y.Diagnostics.Classification` — SPARK-clean diagnostic category,
  severity, reportability, and native-boundary classification helpers.
* `A11y.Dispatchers.Classification` — SPARK-clean dispatcher timeout,
  cancellation, and reentrancy admission helpers.
* `A11y.Windows.Classification` — SPARK-clean surface-kind and surface-state
  classification helpers.
* `A11y.Images.Classification` — SPARK-clean semantic image-kind
  classification helpers.
* `A11y.Documents.Classification` — SPARK-clean document-role, heading-level,
  and pagination classification helpers.
* `A11y.Events.Classification` — SPARK-clean event family, coalescing, and
  individual-order classification helpers.
* `A11y.Event_Queues.Classification` — SPARK-clean queue capacity and
  adjacent-coalescing admission helpers.
* `A11y.Event_Subscriptions.Classification` — SPARK-clean subscription
  capacity and event-filter admission helpers.
* `A11y.Live_Regions.Classification` — SPARK-clean live-setting and
  relevant-change classification helpers.
* `A11y.Relations.Classification` — SPARK-clean inverse-pair, category, and
  cycle-policy classification helpers.
* `A11y.Selection.Classification` — SPARK-clean selection mode, count, and
  direction classification helpers.
* `A11y.Tables.Classification` — SPARK-clean coordinate-space, header, sort,
  range, span, and coverage classification helpers.
* `A11y.Text.Classification` — SPARK-clean protected-text and edit-kind
  precondition helpers.
* `A11y.Conformance.Classification` — SPARK-clean support-level and
  release-claim classification helpers.
* `A11y.Nodes.Classification` — SPARK-clean lifecycle, transition, and
  exposure-policy classification helpers.
* `A11y.Trees.Classification` — SPARK-clean tree identity and attachment
  precondition helpers.
* `A11y.Native_Callbacks.Classification` — SPARK-clean native callback
  capacity, admission, reset, and drain-state helpers.
* `A11y.Native_Identity.Classification` — SPARK-clean native runtime identifier
  component validation, encoding, and session-scoped decoding helpers.
* `A11y.Native_Runtimes.Classification` — SPARK-clean native runtime
  lifecycle, work-admission, generation, and drained-state helpers.
* `A11y.Native_Boundary_Calls.Classification` — SPARK-clean native boundary
  return-class mapping for expected semantic and native failures.
* `a11ykit_proof.gpr` — GNATprove proof slice for SPARK-ready primitive
  semantics. The current gate proves `A11y`, `A11y.Node_Ids`,
  `A11y.Actions`, `A11y.Actions.Classification`,
  `A11y.Backends.Classification`,
  `A11y.Backends.Default_Classification`,
  `A11y.Backends.Selection`,
  `A11y.Backends.Selection.Classification`,
  `A11y.Backends.Transport_Classification`,
  `A11y.Capabilities`, `A11y.Roles`,
  `A11y.Conformance.Classification`, `A11y.Diagnostics.Classification`,
  `A11y.Dispatchers`, `A11y.Dispatchers.Classification`,
  `A11y.Documents.Classification`,
  `A11y.Images.Classification`, `A11y.Event_Queues`,
  `A11y.Event_Queues.Classification`,
  `A11y.Event_Subscriptions`,
  `A11y.Event_Subscriptions.Classification`,
  `A11y.Events.Classification`, `A11y.Live_Regions`,
  `A11y.Live_Regions.Classification`,
  `A11y.Platforms.Classification`,
  `A11y.Native_Boundary_Calls`,
  `A11y.Native_Boundary_Calls.Classification`,
  `A11y.Native_Callbacks`, `A11y.Native_Callbacks.Classification`,
  `A11y.Native_Identity`, `A11y.Native_Identity.Classification`,
  `A11y.Native_Object_Caches`,
  `A11y.Native_Object_Caches.Classification`, `A11y.Native_Runtimes`,
  `A11y.Native_Runtimes.Classification`,
  `A11y.Nodes.Classification`,
  `A11y.Platforms.Classification`,
  `A11y.States`, `A11y.Geometry`,
  `A11y.Documents`, `A11y.Images`,
  `A11y.Resource_Limits`, `A11y.Properties`,
  `A11y.Properties.Classification`, `A11y.Results`,
  `A11y.Results.Classification`, `A11y.Relations`,
  `A11y.Relations.Classification`,
  `A11y.Selection`, `A11y.Selection.Classification`,
  `A11y.Tables.Classification`,
  `A11y.Text`, `A11y.Text.Classification`, `A11y.Trees.Classification`,
  `A11y.Values`, `A11y.Values.Classification`, `A11y.Windows`, and
  `A11y.Windows.Classification`; the current baseline proves 2,077 checks with
  zero unproved checks. Run it with `alr exec
  -- gnatprove -P a11ykit_proof.gpr --checks-as-errors=on`.
* `A11ykit.Provider` — The legacy per-OS compatibility facade for publishing an
  accessibility tree. `Publish` now validates the legacy tree by building an
  `A11y.Sessions` semantic session. On Linux it attempts hostkit-backed AT-SPI
  startup, application-root registration, semantic signal queueing, and a
  bounded serve cycle before falling back to the target-aware validating Null
  backend when the native transport is unavailable or incomplete;
  `Last_Publish_Status`, `Last_Published_Event_Count`,
  `Last_Publish_Backend_Name`, `Last_Publish_Used_Fallback`, and
  `Last_Publish_Selection_Status` expose that semantic handoff. It reports the
  same hostkit-backed backend name as `A11y.Platforms.Native_Backend_Name`, and
  `Available` reports whether a native provider session is currently
  registered with the host accessibility service.
* `A11ykit.Tree` — The accessibility tree a consumer builds and hands to
  A11ykit.Provider; `A11ykit.Compatibility.Validate_Tree` checks legacy
  snapshots for a single root, valid parent/focus indexes, and parent cycles
  before semantic projection. `A11ykit.Compatibility.To_Semantic_Snapshot`
  converts a validated legacy tree into the common `A11y.Semantic_Snapshots`
  model with role-derived capabilities, typed logical-desktop bounds, visible
  titles, keyboard shortcuts, locale, orientation, landmark, and stable
  semantic identifiers, preserving the old draw-list API while moving
  publication toward the authoritative semantic runtime.
  `A11ykit.Compatibility.Populate_Session` then commits that validated legacy
  tree shape through `A11y.Sessions` lifecycle, tree, registry-capability, and
  focus operations instead of bypassing semantic event ordering.
* `A11ykit` — Accessibility backend for applications that draw their own UI
  (Vulkan, OpenGL, a custom toolkit) and therefore have no OS-recognised widget
  objects for a screen reader to inspect.

## Backend Status

The Null backend is implemented as a validating semantic backend. The Disabled
backend is a first-class backend that starts/stops deterministically, rejects
publication with structured diagnostics, and declares all features unsupported.
Runtime selection policy recognizes `default`, `native`, `null`, and
`disabled`/`off`. `A11y.Backends.Default.Create_Default` returns the validating
Null backend until the target native transport is available; `Create_Null` is
the explicit validating backend constructor for deterministic conformance
tests. `Create_From_Override` applies a runtime override while returning the
common `A11y.Backends.Backend'Class` contract and a structured selection
result. The selection result's `Fallback` flag distinguishes an intentional
`null` backend from an unavailable native default, unsupported native target, or
invalid override.
`Create_Platform_Default` remains as a target-aware compatibility alias. The
Linux legacy facade attempts AT-SPI registration during `Publish` because that
is the first point where a root node is available. The macOS legacy facade now
builds NSAccessibility snapshots from the same semantic projection, exports the
root into the backend-private element registry, and installs the AppKit
process-root host when the real macOS bridge is present; otherwise it falls back
through the shared validation path. The Windows legacy facade now builds UIA
snapshots from the same semantic projection, exports the root through the
backend-private COM public-root table, and attempts the native callback
provider host-window path when the real Windows bridge is present; otherwise it
falls back through the shared validation path. Platform bodies are selected by
the GPR source directories.

Linux AT-SPI role/state/event mapping tables, object-path/error mapping,
bounded D-Bus bus-address and value validation, and a typed method router exist
under the Linux-only source directory. Bus-address handling now prepares a
stable backend session for a valid address, rejects malformed addresses, and
keeps registration unavailable until a real D-Bus transport exists. A D-Bus
method boundary validates native-shaped object path, interface, and method
fields before handing requests to the typed router. The router dispatches
Application, Accessible, Component, Action, Value, Selection, Text, Table,
Image, Document, and Surface calls to backend-private method layers. Application
metadata, Accessible role/state/name/description/child-count, Component
geometry/hit-test, Action discovery/invocation, Value query/set, and Selection
query/request translators exist. Text and EditableText scaffolds cover character
counts, ranges, caret offsets, protected-text enforcement, and validated edit
requests that are handed back to the semantic dispatcher instead of mutating
snapshots in backend code. A Table method
scaffold exposes dimensions, stable cell identities, and spans from sparse
semantic snapshots. An Image method scaffold exposes text alternatives and
intrinsic dimensions without image buffers, and rejects decorative images. A
Document metadata scaffold exposes locale, role/title/landmark metadata, and
heading levels. A surface metadata scaffold projects semantic surface kinds and
state into AT-SPI-facing role/state information. The Linux provider facade now
uses the hostkit local-channel transport to discover the accessibility bus,
authenticate, send Hello/RegisterApplication traffic, admit registered
transports, queue semantic AT-SPI signals, and run a bounded serve cycle when
the host bus is reachable. Captured evidence remains blocked on hosts where the
session or accessibility bus cannot be reached. A bounded Cache node projection
exposes only capability-backed interfaces.
A D-Bus message envelope scaffold validates method-call serials, object paths,
interface/member strings, and header/body consistency before building bounded
method-return or error-reply envelopes.

Windows UI Automation backend-private role/state mapping, core-property
snapshot scaffolds, action-to-pattern mapping, and event-category mapping exist
under the Windows source directory. A UIA fragment navigation/runtime-id
projection scaffold derives parent/child/sibling navigation and runtime
identifier components from semantic tree snapshots. A typed UIA request router
now normalizes property, pattern, action, fragment navigation, runtime-id,
relation, value, selection, text, text-edit, table, image, document, surface, and
event-emission requests without exposing COM or SDK types. Event emissions carry
property, structure, and window detail classifications for the future native
emitter, and `BoundingRectangle` property routing carries neutral logical
desktop rectangles to the future ABI boundary. Textual property routing carries
neutral names, descriptions, help text, placeholders, keyboard shortcuts,
locale, orientation, and landmark metadata without using empty strings as
unsupported sentinels. A UIA provider
boundary maps SDK-free provider-shaped requests and structured failures to
HRESULT-style results for the future COM bridge. A COM provider lifetime
scaffold tracks stable session/root/node identity, QueryInterface-style support,
bounded AddRef/Release counts, and defunct-object behavior without exposing COM
pointers or vtables yet. A native-value ownership scaffold models bounded
BSTR-like strings, SAFEARRAY-like integer arrays, scalar variant values, explicit
not-supported values, and cleanup without exposing Windows SDK types. macOS
NSAccessibility
backend-private role/state mapping, core-attribute snapshot scaffolds,
action-name mapping, notification mapping, and hierarchy/element-identity
projection exist under its platform source directory. A typed NSAccessibility
request router normalizes attribute, action, hierarchy, element-id, relation,
value, selection, text, text-edit, table, image, document, surface, and notification
requests without exposing Objective-C or AppKit types. Notification emissions
carry attribute and window detail classifications for the future native emitter.
Frame attribute routing carries neutral logical desktop rectangles for later
AppKit coordinate conversion. An
NSAccessibility provider boundary maps selector-shaped requests and structured
failures to native-style reply categories for the Objective-C bridge.
A native element lifetime scaffold tracks stable session/root/node identity,
main-thread binding, bounded retain/release counts, and defunct-object behavior
without exposing Objective-C object pointers yet. A Foundation value ownership
scaffold models bounded NSString-like text, NSArray-like element arrays,
explicit nil/not-applicable values, and cleanup without exposing AppKit or
Objective-C types. The minimal Objective-C bridge is present under
`native/macos`, compiled only on macOS, and exposes runtime probes for virtual
element dispatch, AppKit process-root hosting, and public AX client traversal.
macOS native conformance still requires a real macOS run whose public AX client
reaches the exported AppKit element tree.

Build with the pinned Alire toolchain:

```sh
alr build
cd tests && alr build
alr exec -- gprbuild -P tests/all_tests.gpr
tests/bin/a11ykit_tests
tests/bin/uia_router_tests
tests/bin/nsax_router_tests
tests/bin/fixture_application --ready
tests/bin/fixture_application --json
tests/bin/fixture_report
tests/bin/fixture_report --json
tests/bin/native_client_atspi
tests/bin/native_client_uia
tests/bin/native_client_nsax
tests/bin/native_observation_report
tests/bin/native_observation_report --json
tests/bin/native_observation_report --require-native-conformance
tests/bin/capability_matrix
tests/bin/capability_matrix --json
tests/bin/documentation_report
tests/bin/documentation_report --json
tests/bin/public_surface_audit
tests/bin/public_surface_audit --json
tests/bin/release_qualification --require-project-completion
tests/bin/release_qualification --native-client-artifact-status
tests/bin/release_qualification --require-native-client-artifacts
tests/bin/release_qualification
tests/bin/release_qualification --json
tests/bin/release_qualification --linux-atspi-evidence-template
tests/bin/release_qualification --windows-uia-evidence-template
tests/bin/release_qualification --macos-nsaccessibility-evidence-template
tests/bin/release_check
```

The Alire manifests and lockfiles are the authoritative toolchain evidence:
both crates pin `gnat_native = "=15.2.1"` and the lockfiles must resolve
`gnat=15.2.1`. The GNAT executable banner can report the underlying compiler
version separately from the Alire package release.

The child test crate includes a deterministic fixture model in
`tests/src/a11y_test_fixtures.*` for future native integration clients. Its
`tests/alire.toml` manifest declares crate name `a11y_tests` and
`project-files = ["all_tests.gpr"]`, so `cd tests && alr build` exercises the
child crate packaging contract directly. It builds
`tests/bin/fixture_application`, which emits a stable readiness line and
machine-readable accepted command results for the fixture script under schema
`org.a11y.fixture_application.v1`. It also builds `tests/bin/fixture_report`,
an Ada-generated inventory of stable fixture node identities, roles,
protected-text coverage, image/document/surface metadata, and scripted commands.
Passing `--json` emits schema `org.a11y.fixture_report.v1`, and the release
gate validates both fixture outputs for required role, surface, protected-text,
lifecycle, relation, and announcement coverage. `tests/bin/native_client_atspi`,
`tests/bin/native_client_uia`, and `tests/bin/native_client_nsax` are separate
client-process entry points that currently emit structured blocked observations
instead of inspecting backend-private objects. Each client includes normalized
semantic observations for the application root, main window, protected password
field, text field range, focus target, default action target, slider value,
live region, list selection, and explicit role rows for the initial vertical
slice: application, window, dialog, group, static text, button, toggle button,
check box, radio button, text field, password field, list, list item, tree,
tree item, menu bar, menu, menu item, tab list, tab, image, tooltip, and
status. The same report also includes table cell, document heading, validation
alert, modal surface, informative image alternative text, a destroyed list
item, progress bar, spin button, table, row, column, cell, combo box, search
field, decorative image, heading, document, paragraph text, link, alert, popup,
and native transport status. Each observation carries a stable dotted
`conformance_id`
that ties the native-client evidence to semantic support declarations.
The aggregate native-observation report carries per-client focus,
property-change, state-change, action, value, selection, active-descendant,
current-item, bounds, hit-test, tree-change, window-event, tree-role,
tree-item-role, menu-bar-role, menu-role, menu-item-role, tab-list-role, tab-role,
tooltip-role, grouped vertical-slice role, grouped extended-fixture-role,
fixture-command coverage, text, table,
image, document, protected-text, live-region, relation, surface, and lifecycle
evidence markers so release checks catch accidental loss of focus,
property-change, state-change, action, value, selection, active-descendant,
current-item, bounds, hit-test, tree-change, window-event, vertical-slice role,
extended fixture role, deterministic
fixture-script coverage, text-range, table-cell, image
alternative-text, document-heading, protected redaction, live-region,
validation-relation, modal-surface, or stale-reference coverage.
Semantic-node observations include platform-shaped identity projections:
Linux D-Bus object paths, Windows UI Automation runtime-id components, and
macOS NSAccessibility element-id components. The `privacy` field identifies
public observations, protected redacted observations, lifecycle-only stale
references, and transport-only probes. The `native_resolution` field
distinguishes live semantic nodes from stale references that must resolve as
`node_unavailable` and transport probes that remain `transport_unavailable`.
`tests/bin/native_observation_report` records those Linux AT-SPI2, Windows UI
Automation, and macOS NSAccessibility client families. Linux now has a
hostkit-backed AT-SPI startup path used by the compatibility provider and live
probe tools; captured evidence still remains
`blocked_transport_unavailable` on hosts where the session or accessibility bus
cannot be reached. Its readiness blocker rows distinguish
`internal_native_export_chain_ready` from `public_client_traversal_observed`, so
internal UIA/NSAccessibility export-chain checks cannot be mistaken for
OS-client conformance. The report also emits
`macos_nsaccessibility_native_client_artifact_state` and
`macos_nsaccessibility_native_client_artifact_complete`; a Linux-generated
stub artifact remains `incomplete_or_invalid`, while a captured macOS public AX
client artifact may satisfy the final NSAccessibility blocker without changing
the common semantic provider. The child crate also builds focused Windows UIA
and macOS NSAccessibility router harnesses plus
`tests/bin/capability_matrix`, an Ada tool that emits the current conformance
declarations for Null, Disabled, Linux AT-SPI, Windows UIA, and macOS
NSAccessibility scaffolds as a Markdown capability matrix. Passing `--json`
emits the same declarations plus a counter summary under the stable
`org.a11y.capability_matrix.v1` schema for release tooling. The test-tool
project links the repository `project_tools` crate and uses its JSON helper to
self-check the generated report schema. The summary separates production
claims from `Internal_Only` scaffolds and reports per-native-backend production
claim counts, so Windows UIA and macOS NSAccessibility stay visibly at zero
until real public native-client traversal is recorded. Both report formats are
rendered through the shared Ada `A11y_Tool_Reports` package, so the release gate
validates the same capability output that `tests/bin/capability_matrix` prints.
`tests/bin/release_qualification` is an Ada-generated release evidence
checklist for Orca, Linux accessibility inspection, NVDA, Narrator, VoiceOver,
Switch Control, Voice Control, and native platform inspectors. Passing `--json`
emits the same scenarios under the stable
`org.a11y.release_qualification.v3` schema with OS version,
assistive-technology version, observed behavior, and evidence fields so manual
qualification evidence can be recorded consistently. The JSON includes a
coverage summary for per-platform assistive-technology, tree-traversal,
protected-text, action-request, relation, live-announcement, and
window-lifecycle checklist coverage plus per-platform pending/captured evidence
counts; `tests/bin/release_check` rejects stale or incomplete summaries.
`tests/bin/documentation_report` is an Ada-generated documentation coverage
report for README, architecture, quickstart, security, testing, conformance,
backend authoring, Linux/Windows/macOS backend guides, provider implementation,
tree/lifecycle, threading/dispatcher, events, relations, actions, and the text,
value, selection, table, document/image, window/surface, and resource-limit
framework guides, diagnostics, troubleshooting, contributor and release guides,
API reference, toolkit adapters, and AI-usable implementation notes. Passing
`--json` emits the same required file and section-marker data under the stable
`org.a11y.documentation_report.v1` schema, and the release gate validates that
report body.
`tests/bin/public_surface_audit` scans the application-facing and common
semantic public package specifications for native accessibility API tokens.
Passing `--json` emits schema `org.a11y.public_surface_audit.v1`; the release
gate requires zero leaks so D-Bus, UIA, COM, AppKit, and NSAccessibility details
remain behind backend-private packages.
`tests/bin/release_check` is an Ada release gate that fails on duplicate
conformance declarations, missing mapping or test evidence, malformed feature
identifiers, stale capability or release-qualification JSON, invalid capability
support-level strings, missing backend-family coverage, missing per-scenario
qualification fields, missing three-platform/assistive-technology coverage,
missing protected-text smoke coverage, stale or incomplete fixture report,
fixture application, or native observation coverage, missing documentation
files/section markers, stale root or child Alire manifest project-file wiring,
public-surface native API leaks, and missing native projection claims.

## Licence

MIT.
