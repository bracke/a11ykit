# a11y Architecture

## Inspection And Compatibility Map

The repository currently contains:

* `alire.toml`: root Alire crate metadata and pinned `gnat_native = "=15.2.1"`.
* `a11ykit.gpr`: root library project with platform source-directory selection;
  retained under its historical name as a compatibility project file.
* `config/a11y_config.gpr`: Alire-generated host/build configuration for the
  `a11y` crate.
* `src/a11ykit.ads`: original shared role, rectangle, and state vocabulary.
* `src/a11ykit-tree.ads` and `.adb`: original flat-list to parented-tree builder.
* `src/a11ykit-provider.ads`: original platform-neutral provider facade.
* `src/platform/{linux,windows,macos,unsupported}/a11ykit-provider.adb`:
  platform-selected provider placeholders.
* `tests/a11ykit_tests.gpr` and `tests/src/a11ykit_tests.adb`: existing smoke
  tests, now extended with semantic registry and Null backend checks.

The original `A11ykit` API is retained. The new `A11y` hierarchy is additive
and is the intended stable semantic API for future native backend work.

Compatibility map:

| Existing surface | Retained behavior | New semantic surface | Migration direction |
| --- | --- | --- | --- |
| `A11ykit` | Small role, rectangle, and state vocabulary for existing consumers. | `A11y.Roles`, `A11y.Geometry`, `A11y.States`, `A11y.Properties`. | Keep compiling legacy code; new providers should use the typed `A11y` packages. |
| `A11ykit.Tree` | Flat draw-list hierarchy inference, deterministic child order, focused-index lookup, and pre-publication snapshot validation. | `A11ykit.Compatibility`, `A11y.Semantic_Snapshots`, `A11y.Node_Ids`, `A11y.Registry`, `A11y.Trees`, `A11y.Sessions`, `A11y.Events`. | Preserve the legacy builder and expose a neutral compatibility projection for roles, bounds, states, parent identity, focus, role-derived capabilities, and tree-shape validation; `To_Semantic_Snapshot` feeds common semantic metadata and `Populate_Session` commits the legacy tree through session lifecycle/events while sessions own durable stable identity and lifecycle. |
| `A11ykit.Provider` | Platform-selected facade with `Available`, `Start`, `Publish`, `Stop`, `Backend_Name`, and last-publication/fallback status. | `A11ykit.Compatibility`, `A11y.Linux.ATSPi_Backend_Sessions`, `A11y.Windows_Backend.UIA_*`, `A11y.MacOS_Backend.NSAccessibility_*`, `A11y.Backends.Event_Pumps`, `A11y.Backends.Null_Backends`, `A11y.Backends.Default`, `A11y.Backends.Selection`, `A11y.Backends.Native_Backends`. | `Publish` validates and adapts `A11ykit.Tree` snapshots into `A11y` sessions. On Linux it first attempts hostkit-backed AT-SPI startup, application-root registration, semantic signal queueing, and a bounded native event-loop batch; if native registration or event publication is unavailable it falls back to the validating Null backend. On Windows it builds UIA snapshots, exports the root through the backend-private COM object table and public-root verifier, creates a live bridge-owned callback-provider host window when the real Windows bridge is present, drains pending semantic events through `UiaRaiseAutomationEvent`, and retains that host until deterministic `Stop`; otherwise it falls back to validation. On macOS it builds NSAccessibility snapshots, exports the root into the backend-private element registry, installs the AppKit process-root host when the real bridge is present, and drains pending semantic events into root or per-node AppKit notifications after semantic publication; otherwise it falls back to validation. `Available` reports a live native registration, UIA callback-host publication, or AppKit host. |
| `a11ykit.gpr` | Historical project-file name retained for existing Alire/GPR consumers. | Alire crate name `a11y` plus additive `A11y.*` packages. | Do not rename the root project while compatibility consumers still import it. |

## Dependency Direction

The intended dependency direction is:

public semantic packages -> internal semantic implementation -> backend
contract -> backend mapper -> native protocol or ABI layer -> operating-system
runtime.

The current implementation establishes the first three layers:

* Public semantic packages: roles, states, properties, geometry, capabilities,
  node identity, events, relations, actions, values, selection, tables,
  documents, images, and surfaces.
* Internal semantic implementation: the protected `A11y.Registry.Node_Registry`,
  `A11y.Trees.Semantic_Tree`, `A11y.Event_Queues.Event_Queue`, and
  `A11y.Relations.Relation_Graph`.
* Session coordination: `A11y.Sessions.Semantic_Session`.
* Dispatch foundation: `A11y.Dispatchers.Immediate_Dispatcher`.
* Backend contract: `A11y.Backends`.
* First backend: `A11y.Backends.Null_Backends`.

Native protocol layers are intentionally not claimed yet.

`A11y.Roles` owns the stable platform-neutral role vocabulary and role metadata.
Stable role names are protocol identifiers, not localized user-facing role
descriptions. Helper predicates such as text-entry and surface classification
derive from that metadata so backends do not make independent semantic
decisions. Role metadata also centralizes focus behavior and selection behavior
for containers and selectable items; platform mappers translate those committed
semantics instead of inferring focus or selection policy from native role names.

`A11y.States` similarly owns stable state identifiers and source metadata.
Backends translate a committed semantic `State_Set` into native state/property
concepts, but they do not independently decide whether core states such as
`Defunct`, `Offscreen`, `Read_Only`, `Editable`, `Focusable`, `Showing`, or
`Active` are centrally derived. `A11y.States.Derive` is the shared state
normalization point for role/capability-derived states such as focusability,
editable text, and read-only text/value semantics. The conformance identifier
is `core.state.derivation`.
`A11y.States.Validate` owns cross-state invariants before native projection:
focused implies focusable, selected implies selectable, expanded implies
expandable, multi-selectable implies selectable, read-only and editable are
mutually exclusive, checked and indeterminate are mutually exclusive, showing
implies visible, and defunct nodes cannot simultaneously be active, focused, or
showing.
Provider-contract validation then applies role policy: `Selected` is valid only
on selectable item roles, while `Selectable` may also describe selection
containers that expose multi-selection behavior.

`A11y.Geometry` owns the neutral logical desktop coordinate model. Rectangle
edge calculation is overflow-safe, empty rectangles are never treated as
visible, and intersection plus viewport visibility classification happen before
backend-private conversion to AT-SPI, UIA, or AppKit coordinate systems. The
package also provides caller-owned bounded `Region` values for clipped visible
areas without heap ownership or native policy. The conformance identifiers are
`core.geometry.visibility` and `core.geometry.region`.

`A11y.Capabilities` owns stable names for semantic capability interfaces. These
names are used for conformance and backend projection decisions; native
interfaces, patterns, and attributes are mapped from the committed capability
set rather than inferred independently in each backend.

`A11y.Properties` owns the stable platform-neutral property identifiers,
property-status metadata, and value-kind metadata. Backends map native property
IDs or attributes back to these semantic identifiers before querying snapshots
or providers. Stable property names are protocol identifiers and must not be
treated as localized labels or as a substitute for property values. Status
metadata preserves the distinction between present, explicitly empty,
unsupported, temporarily unavailable, unavailable node, and error results.
The neutral identifier set covers names, titles, descriptions, help,
placeholders, value text, shortcuts, semantic identifiers, locale, bounds,
orientation, set position/size, hierarchy and heading levels, landmarks, role,
and state sets. Value-kind metadata distinguishes strings, integers, booleans,
rectangles, roles, and state sets without using native property types.
Safe structural property retrieval validates shared limits before projection:
set position/size use `Native_Array_Size`, and hierarchy/heading levels use
`Traversal_Depth`.

## Hostkit

General host policy is delegated to the sibling `hostkit` project. `a11ykit.gpr`
withs `../hostkit/hostkit.gpr`, and `A11y.Platforms` maps `Hostkit.Host.Current`
into a11y's own platform-neutral enum. Normal semantic packages do not inspect
environment variables, duplicate host detection, or import process-identity
syscalls. Linux AT-SPI fixture and native-client tooling obtains the default
EXTERNAL authentication user id through `Hostkit.Process.Current_User_Id`;
explicit `--atspi-uid=...` and `--probe-uid=...` arguments are test overrides.
The root GPR also owns target-specific native bridge admission: Windows builds
add `native/windows` and C language support, macOS builds add `native/macos`
and Objective-C language support for the AppKit bridge translation unit, and
macOS linker options include the AppKit, Foundation, and ApplicationServices
frameworks. Linux and unsupported builds remain Ada-only and do not parse
non-target SDK files.

## Linux AT-SPI Mapping

Linux backend-specific semantic mapping lives under `src/platform/linux`, so
non-Linux builds do not parse Linux-specific backend packages. The first mapper,
`A11y.Linux.ATSPi_Mappings`, centralizes:

* neutral role to AT-SPI role mapping;
* neutral state to AT-SPI state mapping;
* semantic event kind to AT-SPI event name mapping.

`native.role.exhaustive_map` requires this mapper to classify every common
semantic role without returning AT-SPI `Invalid`. Fallbacks are explicit
semantic mappings, not accidental Ada `others` branches.
`native.relation.exhaustive_map` requires every semantic relation kind to be
handled by the central relation mapper.

`A11y.Linux.ATSPi_Objects` adds the first protocol-facing object layer:

* AT-SPI interface names;
* stable object-path to `Node_Id` resolution scoped by backend session;
* structured result to D-Bus/AT-SPI error-name mapping.

The Linux backend does not open D-Bus or claim provider registration yet. A live
D-Bus transport, listener integration, and native client qualification remain
future Linux backend work.

`A11y.Linux.ATSPi_Bus` validates bounded D-Bus bus address strings for the
future accessibility-bus discovery path. It classifies known transports such as
`unix`, `tcp`, and `launchd`, reports missing addresses as
`Backend_Unavailable`, and rejects malformed or over-large addresses without
opening a socket or reading process environment directly. It also owns the
current Linux connection-lifecycle staging record: a valid address can prepare a
stable backend session, registration returns `Backend_Unavailable` while only an
address is resolved, an externally established transport can be admitted with
`Mark_Transport_Connected`, and application registration then advances the
staged context to `Registered`. Disconnect resets the staged context
deterministically.
The outgoing transport scaffold keeps the D-Bus queue and in-flight tracker
private while exposing pending capacity, overflow state, and in-flight capacity
through bus-level accessors for future socket writers and release checks.

`A11y.Linux.DBus_Codec` provides bounded D-Bus scalar/object-path validation and
signature metadata for the subset needed by AT-SPI method handling. Its
string/object-path constructors accept the common
`A11y.Resource_Limits.Resource_Limit_Config` and enforce
`Native_String_Size`, while the legacy constructors use the default bounded
configuration. It is not a transport and does not expose libdbus handles.

`A11y.Linux.ATSPi_DBus_Boundary` is the first native-shaped D-Bus entry
boundary. It validates object paths through the D-Bus codec, maps AT-SPI
interface names to backend-private enums, bounds method/interface strings with
the common snapshot resource-limit configuration, and turns accepted calls into
`A11y.Linux.ATSPi_Method_Router.Method_Request` records. EditableText payloads
are forwarded as neutral edit requests rather than being applied in the D-Bus
layer. Malformed paths, unknown interfaces, routed handler failures, and
unexpected exceptions become structured AT-SPI/D-Bus error replies; no Ada
exception or application state crosses this boundary.

`A11y.Linux.ATSPi_Accessible` is the first method-layer scaffold. It decodes a
stable session/path identity, rejects stale or defunct snapshots, maps the
semantic role and effective state set through the central mapper, and returns
bounded name, description, child-count, and relation-set replies. Name and
description strings use the snapshot's configured `Native_String_Size` limit
rather than a transport default. When sparse
`A11y.Semantic_Snapshots.Semantic_Snapshot` metadata is enabled, role,
capability-derived interfaces, state, name, description, help text,
placeholder, value text, keyboard shortcut, semantic identifier, locale,
orientation, landmark, protected-value-text policy, and exposure come from the
metadata for the resolved `Node_Id`. Child object paths without per-node
metadata fail closed as node unavailable. `GetState` derives effective states
from the resolved role, state set, and capability set before validation and
exposes the result as AT-SPI state bits. `GetAttributes` suppresses value text
for password roles and metadata marked as protected before building the native
attribute set. `GetRelationSet` reads the semantic
relation graph, maps relation kinds through `A11y.Linux.ATSPi_Mappings`, keeps
targets as stable `Node_Id` values for the later transport layer, and enforces
the central `Relation_Targets_Returned` bound. Unknown methods and stale nodes
return structured AT-SPI error names through `A11y.Linux.ATSPi_Objects`. It
rejects queries against hidden projected source nodes before returning role,
state, string, child, or relation data. It still receives a prepared semantic
snapshot from tests; it is not yet wired to a D-Bus transport or
dispatcher-backed provider query path.
The Accessible method layer validates supplied resource-limit configurations
before object-path resolution, semantic metadata lookup, exposure projection,
or native-facing role, state, string, child, and relation replies.

`A11y.Linux.ATSPi_Component` adds the same scaffold shape for geometry:
`GetExtents`, `Contains`, and `GetAccessibleAtPoint` operate on neutral logical
desktop coordinates and stable `Node_Id` hit-test targets. When a semantic tree
and exposure metadata are present, hit-test targets are filtered through
`A11y.Trees.Exposure_Views`: hidden targets are returned as `No_Node`, while
queries against a hidden component return `Node_Unavailable`. Native coordinate
system conversion and transport marshalling remain future backend work. The
Component method layer validates supplied resource-limit configurations before
object-path resolution or native-facing geometry, hit-test, and focus replies.

`A11y.Linux.ATSPi_Action` translates AT-SPI action method requests to the
neutral action model. It counts the immutable supported action set, resolves
zero-based native action indexes in stable `Action_Id` order, returns bounded
action names from `A11y.Actions.Metadata` with the configured
`Native_String_Size` limit, and turns `DoAction` into a neutral invocation
request. These action names are stable protocol identifiers, not localized
user-facing labels or descriptions. It does not directly mutate
application state; the future backend transport will pass the returned action
through the configured dispatcher and provider contract. When semantic tree
projection is present, hidden action nodes return `Node_Unavailable` before
action counts, action names, or invocation requests can be observed.
The Action method layer validates supplied resource-limit configurations before
object-path resolution or native-facing count, name, and invocation replies.
The Linux method router, D-Bus boundary, and outgoing D-Bus reply builder retain
the resolved neutral `Action_Id` for backend-private provider dispatch while the
serialized AT-SPI `DoAction` result remains a native boolean.

`A11y.Linux.ATSPi_Value` is the first value-interface scaffold. It reads current,
minimum, maximum, and small-increment values from neutral `Value_Metadata`,
converts numeric values to `Long_Float` only at the Linux backend boundary, and
turns writable `SetCurrentValue` requests into neutral semantic value requests.
The method router, D-Bus boundary, and outgoing D-Bus reply builder retain the
validated semantic value payload for backend-private bridge work while the
serialized AT-SPI reply remains a native boolean result.
Read-only, nonnumeric, out-of-range, stale, and unsupported cases return
structured errors. When semantic tree projection is present, hidden value nodes
return `Node_Unavailable` before numeric metadata or set requests can be
observed. The Value method layer validates supplied resource-limit
configurations before object-path resolution or native-facing numeric and
set-request replies.

Linux AT-SPI selection mutation requests retain backend-private semantic command
metadata after validation: `SelectChild`, `DeselectChild`, `SelectAll`, and
`ClearSelection` map to a typed request kind plus the stable target `Node_Id`
where one exists. Native replies still use the AT-SPI boolean/object return
shape, so provider dispatch does not need to recover semantics from D-Bus method
names.

`A11y.Linux.ATSPi_Selection` bridges AT-SPI's index-shaped selection methods to
stable semantic node identity. The snapshot carries a bounded child vector and a
neutral `Selection_Set`; selected-count and selected-child queries expose
`Node_Id` results, while select and deselect methods become neutral selection
requests for the future dispatcher path. Externally supplied AT-SPI indexes are
validated before Ada index conversion, and invalid child identities are rejected
instead of being exposed as successful native results. When a semantic tree and
exposure metadata are present, the selection layer uses
`A11y.Trees.Exposure_Views` for child-index resolution, selected-count filtering,
selected-child lookup, membership checks, and select/deselect request targets.
Selection query and request mappers validate supplied resource-limit
configuration before returning selected counts or staging mutations, even when
tree projection is disabled.
The portable selection primitive rejects every clear request for
selection-required sets, including already-empty invalid snapshots, so native
backends cannot normalize a required-selection violation into success.

Table provider safe helpers preserve lazy provider-specific cell lookup while
centrally validating successful resolved cell identities and spans. Native table
requests therefore share one malformed-cell, sparse-cell, stale-identity, and
range failure policy without forcing large virtual table snapshots to be copied.
Backend table mappers validate their resource-limit configuration before
returning even cheap dimension replies, so malformed native limit state cannot
produce successful count, cell, or span observations.

Surface validation centrally rejects mutually exclusive presentation states:
maximized and fullscreen cannot both be committed. Backend window, UIA, and
NSAccessibility mappers therefore project one neutral presentation state rather
than independently resolving contradictory provider metadata.

Document pagination is also validated centrally: page count/current page
metadata applies only to structural document blocks, not annotations or
embedded objects. Native document mappers therefore do not expose page metadata
for inline or embedded semantic roles.
Hidden selected nodes are not externally observable, flattened descendants are
indexed as exposed children, and hidden current containers return
`Node_Unavailable`.

`A11y.Linux.ATSPi_Text` keeps text positions in the neutral range model. It
reports code-point character counts and neutral caret offsets only for
plain-text snapshots, slices text through `A11y.Text.Slice`, and enforces
protected-text policy before any text count, range, caret, or native string
marshalling can occur. EditableText-style insert, delete, replace, and
whole-text set calls are validated into typed
`A11y.Text.Text_Edit_Request` values; the backend does not mutate text
snapshots. When semantic tree projection is present, hidden text nodes return
`Node_Unavailable` before character counts, ranges, caret offsets, or edit
requests can be observed. The AT-SPI method router, D-Bus boundary, and
outgoing D-Bus reply builder retain validated neutral edit-request payloads for
backend-private bridge work. The AT-SPI method router encodes successful
neutral wide-text ranges as UTF-8 before they enter D-Bus string payload construction,
including supplementary-plane characters.
The Text method layer validates supplied resource-limit configurations before
object-path resolution, semantic tree exposure checks, text snapshot copying,
or native-facing text query and edit replies.

`A11y.Linux.ATSPi_Table` exposes table dimensions, cell lookup, and row/column
spans from the sparse semantic table snapshot. Cell identity remains the stable
semantic `Node_Id`; row and column coordinates are query inputs, not durable
identity. Common table span validation is overflow-safe: invalid coordinates or
spans return structured `Invalid_Range` instead of relying on native integer
wraparound or Ada constraint failures. When semantic tree projection is present,
queries against hidden table nodes return `Node_Unavailable`, and cell identity
or span queries reject cells hidden by exposure policy instead of leaking their
stable identities.

`A11y.Linux.ATSPi_Image` exposes only semantic image metadata: text
alternatives, captions, stable image-kind names, and optional intrinsic
dimensions. It never exposes image buffers or rendering formats, distinguishes
missing descriptions and captions from empty descriptions and captions, and
rejects decorative images as unavailable because they should normally be
omitted from the tree. When tree projection metadata is present, hidden image
nodes also return `Node_Unavailable` before text alternatives, captions, long
descriptions, categories, or intrinsic dimensions can be observed. Returned
image strings use the configured `Native_String_Size` limit after semantic image
metadata validation succeeds. The mapper validates the supplied resource-limit
configuration before resolving object paths or constructing native-facing image
metadata replies.

`A11y.Linux.ATSPi_Document` exposes document metadata as bounded attributes:
locale, role, title, author, subject, version, revision, creation,
modification, landmark, heading level, page count, and current page. It
validates heading levels and pagination through the common document model,
encodes returned string attributes with the configured `Native_String_Size`
limit, validates supplied resource-limit configurations before resolving object
paths, and reports unsupported attributes as structured property failures.
When tree projection metadata is present, hidden document nodes return
`Node_Unavailable` before locale, title, role, landmark, pagination, or other
document metadata can be observed.

`A11y.Linux.ATSPi_Surfaces` projects neutral semantic surface metadata into
AT-SPI-facing role and state information. It maps modal dialogs, menus,
tooltips, popup/popover surfaces, and window-like surfaces without exposing
native window handles, and it derives visible, showing, modal, active,
enabled, and sensitive state bits from committed `Surface_Metadata`. It also
reports stable surface kind names and operation-capability booleans from the
central `A11y.Windows` metadata so Linux projection cannot drift into a
backend-private naming table. When tree
projection metadata is present, hidden surface nodes return `Node_Unavailable`
before role, state, modality, visibility, or activation data can be observed.
Surface mappers validate supplied resource-limit configurations before exposure
projection or native-facing replies. AT-SPI method-router calls pass their
configured traversal limits into this
surface projection rather than relying on mapper defaults.

`A11y.Linux.ATSPi_Method_Router` is the typed dispatch point for the Linux
method-layer scaffold. It selects a backend-private handler by AT-SPI interface,
normalizes handler-specific reply families into one routed reply kind, preserves
structured status codes, and contains exceptions at the dispatch boundary. The
current router covers Application, Accessible, Component, Action, Value,
Selection, Text/EditableText edit requests, Table/TableCell, Image, Document,
and Surface. It still
accepts prepared semantic snapshots; raw D-Bus decoding, dispatcher-backed
provider queries, and native registration are later Linux backend work.

`A11y.Linux.ATSPi_Signals` is the first notification scaffold. It accepts an
already committed semantic event, derives the stable AT-SPI object path from
session and `Node_Id`, maps the event kind through the central mapper, preserves
sequence/revision metadata, and rejects unsequenced or stale-source events before
any native D-Bus signal is emitted. `native.event.exhaustive_map` requires every
semantic event kind to produce a deterministic native-facing signal name for a
valid source and sequence.

`A11y.Linux.ATSPi_Objects` owns backend-private AT-SPI interface names and the
structured status to D-Bus error-name map. `native.boundary.error_map` requires
every public status code to map deterministically, including not-supported,
invalid-argument, permission, timeout, shutdown, resource-limit, backend, and
protocol failures.

`A11y.Linux.DBus_Messages` is the first transport-adjacent message envelope
layer. It validates method-call serials, object paths, interface names, member
names, absence of reply/error fields on method calls, decoded backend session
validity, and header/body consistency using the typed codec and the configured
`Native_String_Size` limit before a call reaches the AT-SPI method boundary. It
builds bounded method-return and structured error-reply envelopes from
`A11y.Linux.ATSPi_DBus_Boundary` results. Local validation failures, object-path
payload failures, and bounded error-reply failures still carry stable AT-SPI
D-Bus error names rather than empty native error fields. Normalized transport
envelopes can be
converted to bounded frame metadata and then to staged little-endian D-Bus
header/body byte strings for the supported message shapes, without exposing a
socket or libdbus handle. The Linux bus layer can now return those frame bytes
through an ordered send operation that marks the serial in flight only after
the frame has passed resource-limit validation. A final packet handoff joins
the validated header and body bytes into one bounded transport buffer for the
future writer while retaining the same serial metadata. The same layer now
validates fixed incoming packet headers before later field decoding, rejecting
unsupported endianness, unsupported message types, missing serials, inconsistent
lengths, misalignment, and packet sizes above configured bounds. For the staged
message shapes emitted today, it can also decode supported header fields and
object-path body arguments back into a normalized transport envelope before
method-router translation. Method-call packets can then be converted into the
backend-private `Incoming_Call` boundary object, with the active backend session
attached and the same object/interface/member coherence checks applied before
the dispatcher or provider layer is reachable. The Linux bus layer can consume
one such staged incoming packet, route it through the AT-SPI method boundary,
and queue a method return or structured error reply through the ordinary
bounded outgoing queue and monotonic serial allocator. Method-return body
signatures are mapped centrally from routed AT-SPI reply kinds so later wire
serialization cannot choose per-interface payload types inconsistently. The
same layer now serializes staged scalar, string, object-path, rectangle, size,
floating-point, and state-set return payload classes with resource bounds;
relation-set arrays are serialized from routed semantic relation targets into
stable backend-session object paths. Those payload bytes are carried through
normalized transport envelopes, frames, and packets.
The first Linux live-transport boundary is a backend-private adapter over
`Hostkit.Local_Channel`; hostkit owns the generic Unix-domain socket mechanics,
while a11y keeps the D-Bus packet format and AT-SPI semantics. The adapter can
send prepared packets and receive bounded packets for the existing D-Bus packet
decoder and method dispatcher.
The D-Bus authentication protocol is staged in backend-private a11y code:
`EXTERNAL` command construction, `OK`/`REJECTED`/`ERROR`/`DATA` response
classification, and `BEGIN` framing are protocol-specific. The local-channel
adapter composes hostkit Unix-socket connection, `EXTERNAL` auth, `BEGIN`, and
transport admission so a context is not marked connected until the auth boundary
succeeds. The test and native-client entrypoints obtain the default numeric
user id through `Hostkit.Process.Current_User_Id` and pass it across the
backend-private `External_User_Id` boundary. D-Bus `Hello` completion checks
the in-flight reply serial before decoding the unique-name body and records the
unique bus name only after payload validation. The Linux backend-private
address-discovery layer normalizes the value that hostkit or an adapter
supplies for `AT_SPI_BUS_ADDRESS` and returns structured
`Backend_Unavailable`, `Invalid_Argument`, or `Resource_Limit` results. The live
host environment entrypoint reads `AT_SPI_BUS_ADDRESS` through
`Hostkit.Process.Environment_Value`; a11y never imports
`Ada.Environment_Variables` in production backend code. The conformance
identifiers are `linux.dbus.address_discovery` for value normalization and
`linux.dbus.host_environment_startup` for the hostkit-backed live environment
entrypoint. The same package stages the
AT-SPI session-bus fallback by queueing
`org.a11y.Bus.GetAddress` on an already-connected session-bus context and
completing the string reply into a validated accessibility-bus address. Unknown
reply serials are rejected before decoding body bytes, so hostile replies do
not force irrelevant address parsing. The conformance identifier is
`linux.dbus.a11y_bus_get_address`. The local-channel
adapter can now compose authenticated session-bus connection, `Hello`,
`GetAddress`, reply decoding, and cleanup through
`linux.dbus.authenticated_get_address`; it still needs a hostkit-provided
session-bus address input. `A11y.Linux.ATSPi_Startup` can consume that
caller-supplied session-bus address, run the temporary session-bus discovery
connection, close it, and prepare the application accessibility-bus context
from the discovered address; the conformance identifier is
`linux.dbus.startup_session_discovery`. After admission, the bus layer can queue
D-Bus `Hello` and complete the matching string reply into the context's unique
bus name. The local-channel adapter composes authenticated connection through
`Hello` completion for the future live backend startup path, with deterministic
cleanup if a post-admission step fails. AT-SPI registry registration now has a
separate completion boundary:
queueing `Socket.Embed` does not itself mark the context registered; the
matching `(so)` method-return reply must complete the previously tracked method
call first, and unknown registration replies are rejected before payload
validation.
`A11y.Linux.ATSPi_Startup` owns the staged Linux bus/channel lifecycle
around these operations so future live backend startup has one deterministic
prepare/start/stop controller. Its one-iteration pump composes bounded packet
receive, typed method dispatch, and reply send after registration has
completed. `Can_Pump` and `Check_Pump_Ready` let a future hostkit event-loop
adapter test that exact readiness condition without reading from the channel;
that feature is tracked as `linux.dbus.startup_pump_readiness`.
Its bounded pump loop repeats that primitive only up to an explicit
caller-supplied iteration count and exposes pending/in-flight outgoing work
counts for future hostkit event-loop adapters. That boundary is tracked as
`linux.dbus.startup_outgoing_work`. The startup controller also exposes a
bounded `Interest` snapshot for read, write, and dispatch scheduling decisions;
the snapshot includes the structured pump-readiness status so hostkit adapters
can distinguish unavailable, native-failure, idle, and ready states without
duplicating startup policy, and it carries bounded outgoing capacity and
overflow metadata for back-pressure decisions. Startup read readiness is
derived from a zero-timeout hostkit channel-readability check, while startup
write readiness is derived from the bus-level D-Bus `Posting_Interest`,
keeping queue overflow and send decisions in one backend-private policy. Linux
bus send helpers use that same posting snapshot and refuse outgoing handoff
while overflow back pressure is pending; adapters must explicitly clear the
outgoing queue before beginning a recovery epoch. That boundary is tracked as
`linux.dbus.startup_event_loop_interest`. The snapshot also carries a
backend-private next-operation enum that classifies the same state as
wait-for-transport, transport-failed, write-outgoing, read-and-dispatch, or
idle; the conformance identifier is
`linux.dbus.startup_event_loop_operation`.
Startup also exposes `Wait_Writable`, `Flush_One_Outgoing`, and
`Flush_Bounded_Outgoing` so a future write-ready adapter can wait for hostkit
writable readiness and then send queued replies through the composed startup
controller without accessing the private D-Bus bus or local-channel records.
The bounded flush variant is a successful no-op when no outgoing packet is
pending and is tracked as `linux.dbus.startup_outgoing_flush`.
`A11y.Linux.ATSPi_Backend_Sessions.Drive_One_Event_Loop_Step` lifts that
policy to the backend-session boundary. It snapshots interest, performs at most
one selected registered read or writable-gated outgoing write operation, and
reports before and after interest plus pump/flush activity and write-wait status
without exposing private startup, bus, channel, or registry records. That
boundary is tracked as
`linux.dbus.backend_session_event_loop_step`.
Scheduler policy remains outside the transport adapter. It does not yet own
host event-loop integration.

## Windows UI Automation Mapping

Windows backend mapping scaffolding lives under `src/platform/windows`.
`A11y.Windows_Backend.UIA_Mappings` maps neutral roles and state sets to
backend-private UI Automation concepts without importing COM pointers, HRESULT,
BSTR, VARIANT, SAFEARRAY, HWND, or SDK headers into public packages.
`native.role.exhaustive_map` requires every common semantic role to be handled
explicitly, with UIA `Custom` reserved only for intentionally custom or currently
unmodeled row/column/cell projections in this scaffold.
`native.relation.exhaustive_map` requires every semantic relation to be either
mapped to a UIA relation property or explicitly classified as unsupported by the
mapper.

`A11y.Windows_Backend.UIA_Properties` adds a first SDK-free property snapshot
translator. It maps neutral roles to backend-private control types, neutral
effective states to Boolean UIA-style properties, and neutral string properties
to distinct present, empty, unsupported, or error replies. State snapshots carry
role, raw state set, and capability set, and the translator applies
`A11y.States.Derive` before validation and native mapping. `Bounding_Rectangle`
returns a neutral logical desktop rectangle; DPI and physical-screen conversion
remain behind the future ABI layer. Textual properties carry descriptions, help
text, placeholders, value text, keyboard shortcuts, locale, orientation, and
landmark metadata as neutral string-property results until the ABI layer
converts them to native strings.
`Value_Text` is denied for password roles and snapshots explicitly marked as
protected value text. The common native query boundary routes value-text queries
through `A11y.Nodes.Value_Text_Safely`, so password-role and provider-protected
values are rejected before textual provider data is requested.
Providers may also implement `A11y.Properties.Privacy_Property_Provider` and
return `Protected_Value_Text => Present (True)` for secure non-password fields;
the native query boundary then returns `Permission_Denied` without querying the
textual value.
Like the Linux Accessible layer, the UIA property snapshot can carry
`A11y.Semantic_Snapshots.Semantic_Snapshot` metadata keyed by stable `Node_Id`.
When enabled, name, description, role/control type, state, capability, and
exposure decisions come from that semantic view for the queried node. Help
text, placeholders, value text, and protected-value-text policy are projected
from the same semantic metadata, so UIA property routing cannot fall back to a
stale native-object snapshot for user-facing text or protected values. Missing
per-node metadata fails closed as node unavailable rather than reusing another
object's property snapshot.
Optional tree projection uses the central exposure view so hidden nodes do not
expose control types, names, values, states, or bounds through UIA property
routing. The package intentionally does not allocate BSTRs, VARIANTs,
SAFEARRAYs, or COM provider
objects.

`A11y.Windows_Backend.UIA_Request_Router` is the SDK-free dispatch boundary for
current UIA scaffolds. It normalizes property queries, pattern discovery, action
mapping, fragment navigation, runtime identifier construction, relation-target
queries, value queries, selection queries, text queries, table queries, image
queries, document queries, surface queries, and event emission requests into one
routed reply family while preserving structured semantic status codes. Relation
queries are classified through the UIA relation mapper and bounded by
`Relation_Targets_Returned`. Value queries read neutral `Value_Metadata` and
expose current/minimum/maximum and increment values only after deterministic
semantic conversion. Selection queries read the neutral `Selection_Set` and keep
selected, current, and anchor identities as stable `Node_Id` values. Text queries
read neutral text snapshots, enforce protected-text policy before returning any
range content, and localize UTF-16 unit counting to the backend mapper. Table
queries read the neutral `Table_Snapshot` for dimensions, stable cell identity
lookup, and row/column span metadata without materializing virtual cells. Image
queries read semantic image metadata for text alternatives and intrinsic size
while omitting decorative images. Document queries read neutral document
metadata for locale, title, landmark, role, and heading level. Surface queries
read neutral `Surface_Metadata` for surface kind, modality,
visibility/activation state, and operation capabilities such as close, resize,
and move. It is intentionally not a COM vtable or ABI bridge; future COM provider objects must
enter through this typed boundary before they query semantic snapshots or
dispatch provider actions.

`A11y.Windows_Backend.UIA_Provider_Boundary` is the first COM-shaped but
SDK-free provider boundary. It maps provider operations such as property lookup,
pattern discovery, action invocation, fragment navigation, runtime-id lookup,
relation target lookup, value lookup, selection lookup, text lookup, table
lookup, image lookup, document metadata lookup, surface metadata lookup, and
event raising into the typed request router. Editable text replacement payloads
are bounded by `Native_String_Size` before the typed request router receives
them, and property mapper string replies are bounded before native BSTR-style
copying. It converts structured semantic failures to
backend-private HRESULT-style
categories including `S_OK`,
`S_FALSE`, `UIA_E_ELEMENTNOTAVAILABLE`, `E_INVALIDARG`, `E_ACCESSDENIED`, and
`E_OUTOFMEMORY`. `native.boundary.error_map` requires every public structured
status code to map deterministically before an ABI bridge can translate it to a
real HRESULT. It still exposes no HRESULT, COM pointer, BSTR, VARIANT, SAFEARRAY,
or HWND in public packages; the future COM bridge should contain only ABI
adaptation around this boundary.

`A11y.Windows_Backend.UIA_Provider_Registry` is the session-local registry that
maps stable semantic `Node_Id` values to UIA provider ids. It never derives ids
from addresses, never reuses a released id during one registry session, enforces
the configured native-object cache bound, and keeps released providers as
tombstones while outstanding native calls drain. Stale ids resolve to structured
`Node_Unavailable` results before provider routing, preserving safe defunct
behavior for future COM objects that outlive semantic nodes. The conformance
identifier is `windows.uia.provider_registry`, and the same implementation
also provides the common `native.object_cache.identity` identity guarantee.
`Drained` reports registry-wide quiescence only after every admitted provider
call has returned.
`Reset_When_Drained` is the checked shutdown reset path; it returns structured
`Busy` without mutation while calls are still outstanding. Registry
snapshots include `Outstanding_Calls` so shutdown diagnostics can report why
the registry is not yet drained without walking individual COM providers.
Bare `Reset` is also drained-aware and leaves pinned provider tombstones, call
counts, and the registry generation unchanged until shutdown reaches quiescence.

`A11y.Windows_Backend.UIA_Com_Providers` is the first provider-object lifetime
scaffold. It records the stable backend session, fragment root, and semantic
`Node_Id`, supports core provider interfaces through QueryInterface-shaped
queries, bounds reference counts, and marks objects defunct before final
destruction. It does not expose COM pointers, vtables, BSTR, VARIANT, SAFEARRAY,
or HWND values, and it contains no accessibility semantics beyond lifetime and
interface availability bookkeeping. `Begin_Native_Call` derives a short-lived
call context from that immutable identity, including the runtime-id node
component needed by `A11y.Windows_Backend.UIA_Provider_Boundary`, and rejects
unsupported, defunct, destroyed, or otherwise unavailable provider objects before
a future COM ABI bridge can route a method call. `Drained` gives shutdown code a
named predicate for determining whether all admitted native calls have returned.
`Export_Descriptor` exposes the same stable session/root/node identity,
runtime-id node component, host-window binding metadata, and supported-interface
set to the future bridge without returning COM pointers or performing AddRef.

`A11y.Windows_Backend.UIA_Native_Values` is the first SDK-free native value
ownership scaffold. It represents BSTR-like text, SAFEARRAY-like integer arrays,
scalar VARIANT-like values, and explicit not-supported results with bounded
allocation and deterministic cleanup. Its text and array constructors accept the
common resource-limit configuration and enforce `Native_String_Size` and
`Native_Array_Size`. It intentionally does not allocate Windows `BSTR`,
`VARIANT`, or `SAFEARRAY` objects; the future ABI bridge must adapt these
wrappers into real native objects without changing ownership, absence, or
resource-limit semantics.

`A11y.Windows_Backend.UIA_Values` translates neutral value metadata into
UIA-shaped value replies for the request router. It does not force all semantic
values into floating point in the common model; conversion happens only at this
backend boundary, with unknown values reported as not supported and stale nodes
reported as unavailable. Optional tree projection uses the central exposure view
so hidden value nodes do not expose current values, ranges, increments, or
read-only state through UIA value routing.

`A11y.Windows_Backend.UIA_Selection` translates neutral selection metadata into
Selection and SelectionItem-shaped replies. It keeps selection separate from
focus and activation, exposes selected item lookup by stable `Node_Id`, and
returns structured errors for stale or invalid native requests. When supplied
with a semantic tree and exposure metadata, selected counts, selected-item
lookup, membership checks, and current/anchor replies are filtered through
`A11y.Trees.Exposure_Views`; hidden selected nodes are not exposed to UIA, and
hidden optional identities become empty replies rather than stale native
objects. Selection mutation replies retain the neutral request kind and stable
target `Node_Id` where one exists, so provider dispatch does not recover
semantics from UIA pattern method names.

`A11y.Windows_Backend.UIA_Text` translates neutral text snapshots into UIA-shaped
text replies. It reports code-point counts, neutral range slices, caret offsets,
UTF-16 unit counts, and validated text edit requests for plain-text snapshots
while preserving protected-text and read-only failures as structured denials.
Protected snapshots return `Permission_Denied` before text counts, ranges,
native offset conversion, caret offsets, or edit-request payloads are exposed.
Optional tree projection uses the central exposure view so hidden text nodes do
not expose range, caret, UTF-16, or edit-request data through UIA text routing.
The UIA request router carries successful backend-private payloads through
typed reply variants: properties, values and staged value-set requests,
selections, staged action request identifiers, text counts and neutral
wide-text ranges, text edit requests, tables, images, documents, and surfaces.
The future COM ABI layer can convert those retained values without re-querying
semantic state. The UIA provider
boundary retains the full routed reply payload alongside its compatibility
routed-kind field.

`A11y.Windows_Backend.UIA_Table` translates neutral table snapshots into
Grid/Table-shaped replies. It reports logical dimensions, stable cell
`Node_Id` values, and merged-cell spans while preserving invalid coordinates as
structured range failures. Optional semantic tree projection uses the central
exposure view so hidden table nodes, hidden cells, and hidden cell spans are not
observable through UIA table routing. The mapper validates the supplied
resource-limit configuration before constructing native-facing replies,
including row and column count replies.

`A11y.Windows_Backend.UIA_Image` translates neutral image metadata into
Image-shaped replies. It exposes supplied text alternatives, captions, stable
image-kind names, and intrinsic sizes only when the image is semantically
exposed, so decorative images remain omitted. Optional tree projection uses the
central exposure view so hidden image nodes do not expose descriptions,
captions, categories, or dimensions through UIA image routing. The mapper
validates the supplied resource-limit configuration before constructing
native-facing image metadata replies.

`A11y.Windows_Backend.UIA_Document` translates neutral document metadata into
document-shaped replies. It reports locale, title, author, subject, version,
revision, creation/modification metadata, landmark, role names, heading levels,
page count, current page, and landmark state while validating heading-level and
pagination bounds centrally. Optional tree projection uses the central exposure
view so hidden document nodes do not expose metadata through UIA document
routing. The mapper validates the supplied resource-limit configuration before
constructing native-facing document metadata replies.

`A11y.Windows_Backend.UIA_Surfaces` translates neutral surface metadata into
Window/Transform-shaped replies. It reports surface kind, top-level status,
modality, visibility, activation, window state, and operation capabilities
without exposing HWNDs or assuming every semantic surface is a native window.
Optional tree projection uses the central exposure view so hidden surface nodes
do not expose window metadata through UIA surface routing. The mapper validates
the supplied resource-limit configuration before constructing native-facing
surface metadata replies.

This is not a native COM provider implementation yet; it is the lifetime,
descriptor, and mapper boundary future COM provider objects must use.

## macOS NSAccessibility Mapping

macOS backend mapping scaffolding lives under `src/platform/macos`.
`A11y.MacOS_Backend.NSAccessibility_Mappings` maps neutral roles and state sets
to backend-private NSAccessibility concepts without exposing Objective-C object
pointers, NSString, NSArray, NSView, NSWindow, or NSAccessibilityElement in
public packages.
`native.role.exhaustive_map` requires every common semantic role to be handled
explicitly, with `Unknown` reserved for the neutral `Custom` role until a future
provider supplies richer subrole metadata.
`native.relation.exhaustive_map` requires every semantic relation to be either
mapped to an NSAccessibility relation attribute or explicitly classified as
unsupported by the mapper.

`A11y.MacOS_Backend.NSAccessibility_Elements` is the native-element lifetime
scaffold. It records the stable backend session, semantic root, and semantic
`Node_Id`, models retain/release counts with explicit resource bounds, tracks
whether the bridge has bound the object to AppKit main-thread handling, and
marks stale native elements defunct before final destruction. It
does not expose Objective-C object pointers, selectors, NSString, NSArray,
NSView, NSWindow, or NSAccessibilityElement values, and it contains no role,
tree, naming, action, or event policy. `Begin_Native_Call` creates a transient
call context with the virtual element identity component required by the
provider boundary, optionally requires the recorded main-thread binding, and
rejects stale, destroyed, or unbound-main-thread calls before the Objective-C
bridge can enter attribute/action routing. `Drained` gives AppKit
shutdown code a named predicate for determining whether all admitted native
calls have returned.
`Export_Descriptor` exposes stable session/root/node identity, the native node
component, main-thread binding, and native-view binding metadata to the
Objective-C bridge without exposing Objective-C objects or performing retain.

`A11y.MacOS_Backend.NSAccessibility_Element_Registry` is the session-local
registry that maps stable semantic `Node_Id` values to virtual element ids. It
does not derive ids from Objective-C object addresses, does not reuse released
ids during one registry session, enforces the configured native-object cache
bound, and keeps released elements as tombstones while outstanding native calls
drain. Stale ids resolve to structured `Node_Unavailable` results before
selector-style routing. The conformance identifier is
`macos.nsaccessibility.element_registry`, and the same implementation also
provides the common `native.object_cache.identity` identity guarantee.
`Drained` reports registry-wide quiescence only after every admitted element
call has returned.
`Reset_When_Drained` is the checked shutdown reset path; it returns structured
`Busy` without mutation while calls are still outstanding. Registry
snapshots include `Outstanding_Calls` so shutdown diagnostics can report why
the registry is not yet drained without walking individual AppKit elements.
Bare `Reset` is also drained-aware and leaves pinned element tombstones, call
counts, and the registry generation unchanged until shutdown reaches quiescence.

`A11y.MacOS_Backend.NSAccessibility_Native_Values` is the first SDK-free
Foundation value ownership scaffold. It represents NSString-like text,
NSArray-like integer element identifiers, scalar values, explicit nil, and
not-applicable results with bounded allocation and deterministic cleanup. Its
text and array constructors accept the common resource-limit configuration and
enforce `Native_String_Size` and `Native_Array_Size`. It does not allocate
Objective-C objects or retain Foundation references; the future Objective-C
bridge must adapt these wrappers into real Foundation/AppKit values without
changing ownership, absence, or resource-limit semantics.

`A11y.MacOS_Backend.NSAccessibility_Properties` adds an Objective-C-free
attribute snapshot translator. It maps neutral roles to backend-private
NSAccessibility role values, neutral effective states to Boolean attributes,
and neutral string properties to distinct present, empty, unsupported, or error
replies. State snapshots carry role, raw state set, and capability set, and the
translator applies `A11y.States.Derive` before validation and native mapping.
`Frame` returns a neutral logical desktop rectangle; AppKit screen-coordinate
conversion remains behind the Objective-C bridge. Foundation object allocation,
selector plumbing, AppKit main-thread rules, and native object ownership are
confined to bridge/private backend code. Optional tree projection uses the central
exposure view so hidden nodes do not expose roles, titles, labels, values,
states, or frames through NSAccessibility attribute routing.
The property snapshot can also carry sparse
`A11y.Semantic_Snapshots.Semantic_Snapshot` metadata. In metadata mode, label,
description, help text, placeholder, value text, protected-value-text policy,
role, state, capability, and exposure are resolved through the queried
`Node_Id`, and absent per-node metadata produces a structured node-unavailable
result. Native Objective-C objects therefore remain identity wrappers over
committed semantics rather than owners of role, naming, value, or privacy
policy.

`A11y.MacOS_Backend.NSAccessibility_Request_Router` is the Objective-C-free
dispatch boundary for current macOS scaffolds. It normalizes attribute queries,
action discovery and mapping, parent/children/indexed-child hierarchy queries,
stable virtual element identity construction, relation-target queries, and
value queries, selection queries, text queries, table queries, image queries,
document queries, surface queries, and notification requests into one routed reply family while
preserving structured semantic status codes.
Relation queries
are classified through the NSAccessibility relation mapper and bounded by
`Relation_Targets_Returned`. Value queries read neutral `Value_Metadata` and
report absent values as not applicable. Selection queries read the neutral
`Selection_Set` and keep selected, current, and anchor identities as stable
`Node_Id` values. Text queries read neutral text snapshots, enforce
protected-text policy, validate edit requests, and keep UTF-16 unit counting
localized to the backend mapper. Table queries read neutral table snapshots for dimensions, stable cell
identity lookup, and span metadata without Objective-C objects. Image queries
read semantic image metadata for text alternatives and intrinsic sizes while
omitting decorative images. Document queries read locale, title, landmark, role,
and heading metadata from the neutral document model. Surface queries read
neutral `Surface_Metadata` for surface kind, modality, visibility/activation
state, and operation capabilities without assuming every semantic surface is an
`NSWindow`. Future Objective-C classes and
NSAccessibilityElement objects must use this typed boundary before invoking
semantic/provider behavior.

`A11y.MacOS_Backend.NSAccessibility_Provider_Boundary` is the first
selector-shaped but Objective-C-free provider boundary. It maps native operations
such as copying attributes, listing actions, performing actions, traversing
hierarchy attributes, resolving virtual element identity, copying relation
targets, copying value attributes, copying selection attributes, copying text
attributes, copying table attributes, copying image attributes, copying document
attributes, copying surface attributes, and posting notifications into the typed request router. Editable text
replacement payloads are bounded by `Native_String_Size` before selector-shaped
requests enter the router. It converts
structured semantic failures to backend-private native-style categories such as
success, nil/not applicable, element unavailable, invalid argument, permission
denied, out of resources, busy, and failed. `native.boundary.error_map` requires
every public structured status code to map deterministically before an
Objective-C bridge can translate it to selector return policy. It exposes no
Objective-C object pointer, Foundation collection, selector, AppKit view, or
native callback signature.

`A11y.MacOS_Backend.NSAccessibility_Values` translates neutral value metadata
into NSAccessibility-shaped value replies without allocating Foundation objects
or crossing AppKit boundaries. Numeric conversion remains localized to this
backend mapper, and unknown metadata is returned as not applicable rather than
as a fabricated number. Optional tree projection uses the central exposure view
so hidden value nodes do not expose values, bounds, increments, or read-only
state through NSAccessibility value routing.

`A11y.MacOS_Backend.NSAccessibility_Selection` translates neutral selection
metadata into NSAccessibility-shaped selection replies without using Objective-C
objects. Empty optional selection identities become nil-shaped replies, while
invalid native indexes and stale snapshots remain structured failures. Optional
tree projection uses `A11y.Trees.Exposure_Views` to filter selected counts,
selected-item lookup, membership checks, and current/anchor identities before
the Objective-C bridge can materialize virtual elements; hidden selected nodes
are not exposed, and hidden optional identities become nil replies. Selection
mutation replies retain the neutral request kind and stable target `Node_Id`
where one exists, so provider dispatch does not recover semantics from
NSAccessibility selector names.

`A11y.MacOS_Backend.NSAccessibility_Text` translates neutral text snapshots into
NSAccessibility-shaped text replies without using Foundation objects. It reports
code-point counts, neutral range slices, caret offsets, UTF-16 unit counts, and
validated text edit requests for plain-text snapshots while preserving
protected-text and read-only failures as structured denials. Protected snapshots
return `Permission_Denied` before text counts, ranges, native offset conversion,
caret offsets, or edit-request payloads are exposed. Optional tree projection
uses the central exposure view so hidden text nodes do not expose range, caret,
UTF-16, or edit-request data through NSAccessibility text routing.
The NSAccessibility request router likewise preserves successful
backend-private payloads through typed reply variants: attributes, values and
staged value-set requests, selections, text counts and neutral wide-text
ranges, staged action request identifiers, text edit requests, tables, images,
documents, and surfaces. The AppKit bridge can convert those retained
values to native Foundation values without re-querying semantic state. The
NSAccessibility provider boundary
retains the full routed reply payload alongside its compatibility routed-kind
field.

`A11y.MacOS_Backend.NSAccessibility_Table` translates neutral table snapshots
into NSAccessibility-shaped table replies without allocating Foundation
collections. It reports logical dimensions, stable cell `Node_Id` values, and
merged-cell spans while preserving invalid coordinates as structured failures.
Optional semantic tree projection uses the central exposure view so hidden table
nodes, hidden cells, and hidden cell spans are not observable through
NSAccessibility table routing. The mapper validates the supplied resource-limit
configuration before constructing native-facing replies, including row and
column count replies.

`A11y.MacOS_Backend.NSAccessibility_Image` translates neutral image metadata
into NSAccessibility-shaped replies without allocating Foundation objects. It
exposes supplied text alternatives, captions, stable image-kind names, and
intrinsic sizes only when the image is semantically exposed, so decorative
images remain omitted. Optional tree projection uses the central exposure view
so hidden image nodes do not expose descriptions, captions, categories, or
dimensions through NSAccessibility image routing. The mapper validates the
supplied resource-limit configuration before constructing native-facing image
metadata replies.

`A11y.MacOS_Backend.NSAccessibility_Document` translates neutral document
metadata into NSAccessibility-shaped replies. It reports locale, title, author,
subject, version, revision, creation/modification metadata, landmark, role
names, heading levels, page count, current page, and landmark state while
validating heading-level and pagination bounds centrally. Optional tree
projection uses the central exposure view so hidden document nodes do not expose
metadata through NSAccessibility document routing. The mapper validates the
supplied resource-limit configuration before constructing native-facing
document metadata replies.

`A11y.MacOS_Backend.NSAccessibility_Surfaces` translates neutral surface
metadata into NSAccessibility-shaped replies. It reports surface kind, top-level
status, modality, visibility, activation, window state, and operation
capabilities without exposing NSWindow objects or assuming every semantic
surface is native. Optional tree projection uses the central exposure view so
hidden surface nodes do not expose window metadata through NSAccessibility
surface routing. The mapper validates the supplied resource-limit configuration
before constructing native-facing surface metadata replies.

This is not an Objective-C bridge or AppKit provider implementation yet; it is
the mapper boundary future native objects must use.

## Node Identity

`A11y.Node_Ids.Node_Id` is opaque to applications. `A11y.Node_Ids` owns the
shared fixed node-id table bound used by the registry and native runtime
stale-node ledger, so backend code does not depend on registry internals. The
registry allocates monotonically increasing identities, keeps tombstones after
removal, and never derives identity from Ada addresses, native pointers, object
paths, labels, or tree positions.

`A11y.Node_Keys` provides an explicit application-key registry for virtualization
adapters that need to recover stable semantic identity from application model
keys. Bindings are one-to-one: rebinding the same key to a different node, or
the same node to a different key, returns `Invalid_State` without changing the
registry. Empty keys and `No_Node` are rejected as `Invalid_Argument`.
Materialized key bindings are bounded by the shared
`Virtual_Node_Realization` resource limit; overflow returns `Resource_Limit`,
and shrinking below the current binding count returns `Invalid_State`.
This contract is tracked under `core.node_key.registry`.

`A11y.Native_Identity` derives backend-facing identities from the backend
session and `Node_Id`. Linux object paths are stable strings under
`/org/a11y/ada/session/.../node/...`; runtime identifier components are numeric
session/node combinations for Windows UIA runtime ids and macOS virtual element
ids, bounded so a node component cannot collide with another session's
component. The same package resolves Linux object paths and runtime identifier
components back to `Node_Id` only when the encoded session matches the active
backend session. Linux D-Bus, Windows UIA, and macOS NSAccessibility native
boundaries use this admission step to reject malformed, cross-session,
out-of-range, mismatched, or stale identities before reaching provider state. No
identity is
derived from an Ada address or native object pointer. Backend session allocation
is monotonic and non-reusing; if the finite session id space is exhausted,
`Create_Session` returns `No_Session` so later native setup fails validation
instead of reusing identity. Native runtime initialization and Linux
accessibility-bus preparation translate that failure to `Resource_Limit` and do
not continue with `No_Session`. Linux object-path parsing preserves structured
boundary failures: malformed syntax is `Invalid_Argument`, wrong sessions are
`Node_Unavailable`, and oversized numeric identity components are
`Resource_Limit`.
The Linux D-Bus codec and accessibility-bus parser also bound externally
provided strings before they can drive allocation or traversal: oversized D-Bus
strings/object paths, oversized bus addresses, and bus addresses with more than
`Max_Address_Fields` fields return `Resource_Limit` and leave the parsed value
or connection context invalid.

`A11y.Native_Object_Caches` is the backend-neutral cache/lifetime layer for
future D-Bus objects, COM providers, and Objective-C accessibility objects. It
allocates stable native cache identities scoped by backend session, resolves
them back to `Node_Id`, rejects cross-session lookups, marks stale entries
defunct, and retains tombstone metadata after release. It stores no application
widget or provider pointers. Live node-to-object acquisition is backed by an
internal `Node_Id` index so repeated native publication and query preparation do
not scan allocated native records; this is tracked by
`native.object_cache.node_index`. `Find_Object` exposes the non-mutating lookup
path for platform adapters that need an existing native object but must not
materialize one as a side effect. Once a node mapping is defunct, cache acquisition
for the same session and `Node_Id` returns `Node_Unavailable`; native objects
must not be resurrected after stale-reference protection has been activated.
Cache reset clears records, node indexes, and defunct-node indexes
deterministically with element-wise mutation rather than materializing a
temporary full cache table.
The cache defaults to `Max_Native_Objects` and can be configured from
`A11y.Resource_Limits.Native_Object_Cache_Size` and
`Tombstone_Retention`. Acquiring a new distinct native object after the
configured bound is reached returns `Resource_Limit`, leaves the cache
unchanged, and returns `No_Object`. Defunct/release transitions are also bounded
by the configured tombstone retention limit by evicting older retained
tombstone metadata before recording the newer stale object. Evicted native
object ids are still never reused in the same backend session, and resolving an
evicted stale id returns `Node_Unavailable` without exposing provider state.
These guarantees are tracked as `native.object_cache.identity`,
`native.object_export_descriptor`, `native.object_cache.session_scope`,
`native.object_cache.tombstone`, `native.object_cache.node_index`, and
`native.object_cache.resource_limit`.
`A11y.Native_Runtimes` layers a destroyed-node ledger over the cache. Applying
a `Node_Destroyed` event or directly marking a node defunct records the stable
`Node_Id` in that ledger, marks any cached native object defunct, and prevents
later native object creation for the same node even when no native object had
been materialized before removal. Duplicate destruction attempts fail
structurally instead of recreating cache entries. Tombstone pressure cannot keep
a destroyed node live; retention metadata may be dropped, but the destroyed-node
ledger remains authoritative for resurrection rejection.
Windows COM provider and macOS NSAccessibility element scaffolds validate
backend session, root, and node identity before entering the live state; invalid
identity initialization returns `Node_Unavailable` and leaves the native object
in its created, unreferenced state. COM `AddRef` and Objective-C-style
`Retain` bookkeeping are bounded by `Max_Reference_Count` and
`Max_Retain_Count`; overflowing either count returns `Resource_Limit` while
leaving the live reference/retain count unchanged. Once the final release
destroys a native object, later release attempts return `Node_Unavailable` and
leave the object in the destroyed, defunct state.
Both scaffolds also expose a backend-private platform-native call generation.
It advances on native-call admission and successful release, is copied into the
native-call context snapshot, resets on object initialization, and does not
advance when a stale copied call context is rejected. This gives COM and
Objective-C bridge diagnostics a monotonic observation point for copied or
out-of-order native call contexts without retaining application provider state.
The Linux AT-SPI object registry, UIA provider registry, and NSAccessibility
element registry expose a backend-private native registry generation tracked as
`native.object_registry.generation`. It advances on successful registry
configuration, first object/provider/element creation, defunct marking,
release, and reset; idempotent lookup, native-call admission, stale resolution,
capacity rejection, and rejected reset do not advance it. Record snapshots
carry the registry generation they were resolved under, giving platform
adapters a bounded way to detect stale registry observations.
The same registries declare `native.object_registry.drained_reset`: checked
reset returns structured `Busy` while native calls are outstanding, and bare
`Reset` is a drained-only no-op until those calls unwind.
They also expose backend-private `*_With_Report` mutation operations for ensure,
mark-defunct, release, and reset paths. Each report records the operation,
stable native object/provider/element id, session, node, status, generation
before and after, live and tombstone counts, outstanding callback counts, and
boolean change flags. This evidence is tracked as
`native.object_registry.mutation_report` without exposing native handles or
protocol identifiers through public semantic APIs.
The same registries expose begin/end native-call mutation reports for admitted
callback windows. Each report records the requested native id, backend session,
stable node identity, generation before/after, outstanding-call counts
before/after, the transient call-context snapshot, and whether the call remains
active after the operation. Failed admission returns an inactive rejected
context and records no outstanding-call mutation. This evidence is tracked as
`native.boundary.native_call_report`.
Native value wrappers also bound platform-owned text and array payloads before
they can cross a future ABI boundary: UIA BSTR/SAFEARRAY scaffolds and macOS
NSString/NSArray scaffolds return `Resource_Limit` with an empty/nil native
value when the configured string or array limit would be exceeded.

`A11y.Events` owns stable semantic event identifiers and central coalescing
metadata. `A11y.Event_Queues` consults that metadata instead of carrying an
independent backend or queue-local event policy. Observable events such as
text mutations, node destruction, relation additions/removals, and window
lifecycle changes are not coalescible; only explicitly marked high-frequency
state, geometry, value, caret, and equivalent update events may be merged for
the same node.

The event package also owns coarse event-family classification. `Is_Text_Event`
identifies events that may carry text payload validation; `Is_Lifecycle_Event`,
`Is_Tree_Event`, `Is_Table_Event`, `Is_Document_Event`, `Is_Relation_Event`,
`Is_Window_Event`, `Is_Property_Event`, `Is_State_Event`, `Is_Value_Event`,
`Is_Selection_Event`, and `Is_Focus_Event` provide stable groups for validating
backends, subscription filters, and native mappers. The Null backend consumes
the lifecycle classification when checking per-node event ordering, so backend
code does not need to duplicate event-family policy. The conformance identifier
for the shared classifier contract is `events.classification`.

`Validate_Event` checks the event envelope before any typed payload is mapped:
the sequence number must be assigned and the source must be a valid `Node_Id`.
Null, disabled, and native backends use this shared check before recording,
emitting, ignoring, or translating the event, so invalid event envelopes fail
consistently with structured `Invalid_Argument` or `Node_Unavailable` results.
The conformance identifier is `events.envelope`.

Non-text typed payload validators are exposed in constructor-style forms that
accept the semantic fields and in record-level forms that accept an existing
payload record. Backend mappers use the record-level forms before native
signal, property, notification, or structure mapping. This keeps stale cached
metadata, such as property value kind, state source, or value kind, checked by
the portable event layer rather than by AT-SPI, UIA, or NSAccessibility code.
Text payload validation has both constructor-style and public-record overloads.
The record overload still requires the current content length,
protected-text policy, and resource-limit configuration because those inputs are
intentionally not stored in the payload. It replays the record through the
constructor path and rejects hidden text when `Carries_Text` is false.

Text event payloads are validated centrally through
`Validate_Text_Event_Payload`. Insert and replace events may carry bounded
non-empty replacement text for plain text only; protected text returns
`Permission_Denied` and an empty payload. Empty insert and replace requests are
rejected as malformed no-op mutations. Remove, caret, selection, and attribute
text events carry neutral ranges or positions without copying deleted or
protected content.
Property-change payloads are validated through
`Validate_Property_Event_Payload`. The payload records the property id, value
kind from `A11y.Properties.Metadata`, and old/new property statuses, but not the
property value itself. Node-unavailable statuses are rejected because property
events for defunct sources must not be published as ordinary property changes.
Supported-to-supported status pairs are valid because the changed value may be
carried by the provider state rather than the event payload. Pairs where both
sides are unsupported remain invalid because they expose no observable property
transition.
Linux AT-SPI, UIA, and NSAccessibility event mappers provide payload-aware
overloads that map the neutral property id to backend-private signal detail,
native property, or attribute event categories while preserving the older coarse
event builders for callers that do not yet carry payloads. When a backend has no
native property/attribute event for a valid semantic property, its payload-aware
mapper returns a structured unsupported result instead of publishing a
misleading generic property notification. The conformance identifier is
`events.property.payload`.
State-change payloads are validated through `Validate_State_Event_Payload`.
The payload records the changed state flag, the centrally defined state source,
and the old/new Boolean values. No-op changes and payloads attached to non-state
events return `Invalid_Argument`, keeping state derivation policy centralized in
`A11y.States` rather than backend-specific event code. Linux AT-SPI emits a
state-specific signal detail such as `object:state-changed:focused`; UIA maps
supported state flags to backend-private property event categories; and
NSAccessibility maps them to backend-private attribute event categories. The
conformance identifier is `events.state.payload`.
Relation-change payloads are validated through
`Validate_Relation_Event_Payload`. The payload records the relation kind, its
canonical inverse from `A11y.Relations`, and an optional target `Node_Id`.
`Relation_Added` and `Relation_Removed` require a valid target; aggregate
`Relation_Targets_Changed` events may omit the target when the complete target
set changed. Omitted targets must carry `No_Node`, and validation rechecks the
inverse field on directly constructed public payload records, so callers cannot
publish a relation event whose canonical and inverse relation kinds disagree or
whose optional target flag contradicts its target value.
Native event mappers retain the validated relation payload: Linux AT-SPI
carries stable relation detail strings, UIA maps to backend-private relation
property categories where the native API has an equivalent, and NSAccessibility
maps to backend-private relation attributes. The conformance identifier is
`events.relation.payload`.
Bounds-change payloads are validated through `Validate_Bounds_Event_Payload`.
The payload carries old and new logical desktop rectangles and rejects no-op
changes or payloads attached to non-bounds events. Backend event mappers retain
these committed neutral rectangles on their event emissions so later native
notification code can convert coordinates without re-entering application
providers or deriving geometry independently. The conformance identifier is
`events.bounds.payload`.
Focus-change payloads are validated through `Validate_Focus_Event_Payload`.
The payload carries old and new focused `Node_Id` values, allowing either side
of the transition to be `No_Node` for focus entry or focus clearing, but rejects
no-op transitions and transitions with no valid endpoint. Linux AT-SPI, UIA, and
NSAccessibility event mappers retain the committed focus transition so native
notification code can report or invalidate focus without inspecting stale
provider state. The conformance identifier is `events.focus.payload`.
Node-reference payloads are validated through
`Validate_Node_Reference_Event_Payload` for `Active_Descendant_Changed` and
`Current_Item_Changed`. They carry old and new referenced `Node_Id` values,
allowing one side to be `No_Node` for creation or clearing while rejecting
no-op transitions and transitions with no valid endpoint. Backend mappers retain
these identities on their event emissions so virtual controls can report active
descendant and current-item changes without recomputing relation or selection
state at native notification time. The conformance identifier is
`events.node_reference.payload`.
Value-change payloads are validated through `Validate_Value_Event_Payload` for
`Value_Changed` and `Range_Changed`. They carry old and new
`A11y.Values.Semantic_Value` records and their kinds, reject no-op transitions,
and preserve exact decimals, unknown values, and indeterminate values without
forcing native floating-point conversion during event publication. Range-change
events may carry numeric, unknown, or indeterminate values, but reject known
nonnumeric values such as booleans or enumerations; ordinary value-change
events may still carry those semantic values. Linux AT-SPI, UIA, and
NSAccessibility event mappers retain the neutral value payload for later native
conversion at the protocol boundary. The conformance identifier is
`events.value.payload`.
Selection-change payloads are validated through
`Validate_Selection_Event_Payload` for `Selection_Changed`. They represent
either an item-level selection transition using a stable `Node_Id`, or a
bounded full-selection invalidation when no single changed node is authoritative.
Item-level payloads reject invalid node ids and no-op selected-state
transitions. Full-selection invalidation payloads require `No_Node` as the
changed node and reject selected-state flags that only make sense for an
item-level transition. AT-SPI, UIA, and NSAccessibility event mappers retain
that validated payload. The payload also preserves selection-required policy so
native backends can report selection changes without deriving generic selection
rules independently. The conformance identifier is `events.selection.payload`.

`A11y.Trees.Semantic_Tree` is the authoritative attached-node tree. Indexed
child lookup returns `No_Node` for detached nodes, leaves, and out-of-range
indexes; it does not raise at native projection boundaries for ordinary
external navigation misses. Internal child-index and sibling-navigation helpers
also treat empty child vectors as ordinary misses or stale snapshot errors
rather than indexing the container.
Tree validation has a limit-aware overload that uses
`A11y.Resource_Limits.Traversal_Depth`. If a parent chain exceeds the configured
depth, validation returns `Resource_Limit`; invalid resource-limit
configurations return `Invalid_Argument`.

`A11y.Native_Runtimes` is the shared native backend runtime scaffold. It owns a
backend session id, backend lifecycle state, and a native object cache. It
starts by creating a fresh backend session, exposes native objects only while
running, resolves native calls through the session-scoped cache, marks node
objects defunct during semantic removal, and deterministically resets session and
cache state during stop. `Drained` exposes the runtime quiescence predicate: no
live native objects, no tombstones, and no destroyed-node ledger entries remain.
The runtime snapshot also carries a monotonic `Generation`, tracked as
`native.runtime.generation`, which advances when the runtime creates a fresh
session, enters running state, marks a node defunct, or resets during shutdown.
Platform bridges can compare that generation with retained backend-private
metadata to detect stale runtime observations without dereferencing provider
state or exposing native handles.
It also applies committed semantic events in strictly
increasing sequence order with nondecreasing timestamps. Events with invalid
source identities, stale timestamps, stale lifecycle state, or native
object-realization overflow are rejected before sequence/timestamp state is
advanced, so failed native preparation cannot partially commit an event.
Runtime event admission uses the central `A11y.Events.Validate_Event` envelope
validator before enforcing runtime order and lifecycle checks, so native
preparation follows the same sequence/source rules as event queues and
subscriptions.
Runtime destroyed-node admission preserves the same final-event distinction as
the queue and subscription fan-out: duplicate `Node_Destroyed` preparation is
`Invalid_State`, while later non-destroy events for that source are
`Node_Unavailable`.
`Node_Destroyed` is handled centrally by marking any
cached native object for that `Node_Id` defunct before future platform bridges
attempt to emit native notifications, so stale D-Bus, COM, or Objective-C
objects can fail without touching application provider state. The runtime also
keeps a fixed-size destroyed-node ledger for the backend session, so events that
arrive after `Node_Destroyed` cannot create first-time native objects for stale
semantic identities, and direct native-object exposure also rejects destroyed
nodes before consulting backend caches. `Prepare_Event`
combines that ordering/lifecycle application with native-object preparation:
live-node events receive a stable session-scoped native object identity, while
destruction events are prepared without exposing a live object. The
`Prepare_Event_With_Report` variant returns the same prepared record plus a
structured audit report covering runtime state/generation, last committed
event, source, kind, object handoff, defunct status, admission, commit, and
structured status. `Initialize_With_Report`, `Start_With_Report`, and
`Stop_With_Report` similarly expose `native.runtime.lifecycle_report` for
runtime lifecycle transitions, recording before/after snapshots, status,
generation advancement, state/session changes, cache reset, and event-order
reset. The
platform-specific D-Bus, COM, and Objective-C bridges should use this layer
instead of owning independent lifecycle/session state.
`Validate_Prepared_Event` is the central prepared-publication shape validator
used before platform event projection. It preserves failed `Prepared_Event`
statuses as structured rejections, validates the event envelope, enforces the
destroyed-node/object handoff rule, rejects multiple simultaneous typed payload
flags, and revalidates the selected payload against the event kind. Linux
AT-SPI, Windows UIA, and macOS NSAccessibility event builders call this common
validator before mapping payloads into native notification concepts.
Runtime-owned native object and tombstone storage is configured through
`A11y.Native_Runtimes.Configure_Limits`, using
`Native_Object_Cache_Size` and `Tombstone_Retention` from the common
resource-limit configuration. Native backend `Configure_Limits` forwards the
same configuration to this runtime layer as well as to diagnostics, so native
storage bounds stay centralized. Reconfiguration preflights both runtime cache
bounds and diagnostic retention bounds before mutating either subsystem, so a
failure in one bound leaves all prior native backend limits intact.
The native object cache exposes a backend-private monotonic `Cache_Generation`,
tracked as `native.object_cache.generation`, through object snapshots and the
runtime `Object_Cache_Generation` snapshot field. It advances when cache limits
are successfully changed, a new native object identity is allocated, a node is
marked defunct, a native object is released, tombstone pressure evicts a stale
record, or the cache is reset for a fresh session/shutdown. Pure lookups,
identity reuse, overflow rejection, invalid sessions, and failed reconfiguration
do not advance the generation. Platform bridges can compare the generation with
their own retained backend-private metadata to detect stale cache observations
without deriving identity from native pointers or touching application state.
Backends that need structured cache-mutation evidence use
`Ensure_Object_With_Report`, `Mark_Defunct_With_Report`,
`Release_With_Report`, or `Reset_With_Report`. Their
`Cache_Mutation_Report` records before/after generation, live-object count,
tombstone count, resolved node/object identity, status, and change flags. This
is tracked as `native.object_cache.mutation_report`.

`A11y.Native_Callbacks` is the backend-neutral native callback admission gate.
It grants opaque callback tokens before native protocol threads enter
dispatcher/provider code, enforces a bound on outstanding callbacks configured
from `A11y.Resource_Limits.Outstanding_Callbacks`, rejects new callbacks after
shutdown begins, and records invalid completions. A completion must present the
exact active token it was granted; stale duplicate tokens cannot drain unrelated
outstanding callbacks, including after a freed admission slot is reused by a
later callback. The gate snapshot carries a monotonic `Generation`, tracked as
`native.callback.generation`, which advances when a callback is admitted, when
shutdown starts accepting no new callbacks, and when reset succeeds. It does
not advance for invalid completions or rejected reset attempts, so native
bridges can distinguish stale gate observations from ordinary failed calls.
Reset is also lifecycle-aware: a gate with outstanding
tokens rejects reset attempts and leaves those tokens valid so in-flight native
calls can still unwind through the ordinary completion path. `Drained` lets
backend shutdown code test that all admitted callbacks have returned before
resetting or releasing native bridge state. Backends should acquire a token
before resolving native references or invoking a dispatcher, and always release
it before returning through D-Bus, COM, or Objective-C boundaries.

`A11y.Native_Boundary_Calls` composes callback admission with session-scoped
native object resolution. A native bridge starts an object call by acquiring a
callback token, resolving the native object through `A11y.Native_Runtimes`, and
receiving a context containing the stable `Node_Id`. If the native object is
stale, cross-session, or unavailable, the package releases the callback token
before returning the structured failure. If the runtime returned a safe defunct
or released tombstone snapshot, the failed context preserves that metadata for
native error mapping without exposing application provider state; this is
tracked by `native.boundary.stale_metadata`. Successful
calls must end the context explicitly before returning through the native ABI.
Exception containment in the boundary also unwinds any admitted token before
returning `Internal_Error`.
Boundary snapshots and outcomes carry the native object cache generation that
was observed while resolving the object or node. Live calls, stale tombstones,
and released objects therefore report the same `native.object_cache.generation`
view as the runtime cache snapshot, while callback-admission failures that occur
before cache resolution report generation zero. Platform bridges can attach that
number to private diagnostics without exposing native handles or retaining
application provider references.
They also carry the runtime generation observed before callback admission,
reusing the `native.runtime.generation` contract for D-Bus, COM, and
Objective-C boundary diagnostics. This lets a bridge distinguish failures from
an older runtime session from failures observed after a deterministic
start/stop/reset transition, without retaining application pointers or native
object addresses.
`Begin_Node_Call` uses the runtime's non-mutating `Find_Object` path for
adapters that already resolved semantic identity and need to enter the same
callback window without materializing a native object as a side effect.
`Begin_Object_Call_With_Report` and `Begin_Node_Call_With_Report` additionally
return `Boundary_Call_Admission_Report`, a backend-neutral record of the
requested object or node, resolved identity, runtime and cache generations,
call kind, callback admission, defunct state, active state, structured status,
and native return class. Bridges use it for D-Bus, COM, and Objective-C
diagnostics without consulting backend-private state after a begin call fails.
The conformance identifier is `native.boundary.admission_report`.
`Complete_Call_With_Report` returns `Boundary_Call_Completion_Report`, which
records before/after snapshots, requested provider status, final mapped
status, status-recording result, callback-release result, release state, and
return class. The compatibility `Complete_Call` remains available and delegates
to the report variant. The conformance identifier is
`native.boundary.completion_report`.
`End_Call_With_Report` returns `Boundary_Call_Release_Report`, recording the
direct release before/after snapshots, preserved provider status,
callback-release result, release state, and return class. `End_Call` remains a
compatibility wrapper. The conformance identifier is
`native.boundary.release_report`.
Boundary context snapshots retain the last structured status, including failed
begin attempts and invalid/double completion attempts, so native protocol
bridges can map failures without inspecting backend-private state or exposing
Ada exceptions.
Active boundary contexts can also record the provider operation status before
the callback token is released. A successful `End_Call` preserves that recorded
status for later native return mapping; callback-release failures replace it
with the release failure so leaked or stale tokens remain observable. The
`Complete_Call` combines provider-status recording with callback-token release
for native call wrappers that already carry a structured status field. The
conformance identifier is `native.boundary.status_recording`.
Prepared native publications also carry the preparation result in
`Prepared_Event.Status`. Event admission, backend availability, native-object
materialization, defunct marking, and exception containment set this status
before a platform mapper sees the record. AT-SPI, UIA, and NSAccessibility
builders reject a failed prepared event status before consulting object shape,
so timeout, shutdown, resource-limit, and unavailable results survive the
publication handoff without being collapsed into a generic missing-object
failure.
`Boundary_Call_Outcome` adds the backend-neutral return class for that status:
success, unsupported, unavailable, invalid argument, invalid state, read-only,
disabled, busy, timed out, cancelled, shutting down, permission denied,
protocol failure, native failure, resource limit, or internal error. Platform
bridges still translate those classes into D-Bus errors, HRESULT values, or
NSAccessibility return policy privately.
The current UIA and NSAccessibility provider boundaries consume this classifier
directly before selecting HRESULT-style or Objective-C-free native reply
categories.
Snapshots also carry the dispatcher `Call_Kind` and its timeout limit, so a
native bridge can diagnose and map an action invocation differently from a tree
or geometry query while still depending only on the platform-neutral boundary.
Failed begin attempts preserve the decoded native object id and requested
`Call_Kind`, including stale-object resolution failures and callback-admission
shutdown rejections, so native bridges can produce structured diagnostics for
the original request without keeping their own parallel call context.
The conformance identifier is `native.boundary.call_kind`.
The return classifier is tracked as `native.boundary.return_class`.

`A11y.Native_Action_Calls` layers action invocation on top of the same native
boundary. Native handlers pass the protocol-decoded object and semantic action
identifier; the common boundary resolves the stable `Node_Id`, routes the call
through the dispatcher, invokes the platform-neutral `Action_Provider`, and
releases callback admission before returning a structured action result. When a
native adapter already has stable semantic identity, `Invoke_Node_Action` uses
the non-mutating node boundary to perform the same dispatch without
materializing a new native object; this is tracked by
`native.boundary.node_action_call`.
Provider exceptions are contained inside the common action boundary and return
`Internal_Error` after callback admission is released, so no Ada exception
crosses D-Bus, COM, Objective-C, or backend-private native scaffolding.
Action calls accept a dispatcher `Cancellation_Token`; a cancelled token returns
`Cancelled` before provider invocation and before any application mutation. The
conformance identifier is `native.boundary.cancellation`.

`A11y.Native_Query_Calls` provides the matching boundary for core provider
queries. Role, state, name, description, and geometry requests all acquire
native callback admission, resolve the stable semantic node, dispatch to the
provider, contain exceptions, preserve typed property status, and release the
callback token before the native protocol layer encodes its reply. Role and
state requests use `A11y.Nodes.Contract_Snapshot_Safely`, so invalid
role/capability contracts fail with structured semantic status before backend
mappers can observe or translate them.
`Query_Node_Role`, `Query_Node_States`, `Query_Node_Name`,
`Query_Node_Visible_Title`, `Query_Node_Description`, `Query_Node_Help_Text`,
`Query_Node_Placeholder`, `Query_Node_Value_Text`,
`Query_Node_Keyboard_Shortcut`, `Query_Node_Semantic_Identifier`,
`Query_Node_Locale`, `Query_Node_Orientation`, `Query_Node_Landmark`, and
`Query_Node_Bounds` use the same non-mutating node boundary for adapters that
already hold stable semantic identity; this is tracked by
`native.boundary.node_query_call`. Optional
visible title, help text, placeholder, value text, keyboard shortcut, semantic
identifier, locale, orientation, and landmark queries use
`A11y.Properties.Textual_Property_Provider` when the provider implements it and
otherwise return an explicit unsupported string-property status.
State queries expose the same derived effective state set validated by
`A11y.Nodes.Validate_Contract`, so backend mappers receive centralized
focusability, editable, and read-only semantics instead of deriving those states
independently.
Textual native query results validate the caller-supplied
`Resource_Limit_Config` before applying `Native_String_Size`, so malformed
native callback bounds fail with structured `Invalid_Argument` and redact the
returned text before any platform ABI layer can encode it.
Structural integer queries use `A11y.Properties.Structural_Property_Provider`;
`Query_Node_Set_Position`, `Query_Object_Set_Position`,
`Query_Node_Set_Size`, `Query_Object_Set_Size`,
`Query_Node_Hierarchical_Level`, `Query_Object_Hierarchical_Level`,
`Query_Node_Heading_Level`, and `Query_Object_Heading_Level` return typed
`Integer_Property` values and preserve unsupported statuses without collapsing
them into zero.
Role, state, textual-property, and bounds/geometry queries accept dispatcher
cancellation tokens; cancelled tokens return `Cancelled` before provider
invocation. The conformance identifier is
`native.boundary.query_cancellation`.

`A11y.Native_Tree_Calls` covers native tree-navigation requests with the
tree-query dispatcher class. It exposes parent, child-count, and indexed-child
queries through the same native admission and stale-object rules, keeping
backend protocol routers out of direct provider calls. Parent and child-count
queries use `A11y.Nodes.Tree_Snapshot_Safely`, and indexed-child queries use
`A11y.Nodes.Child_At_Safely`, so provider exceptions and invalid identities are
normalized before runtime liveness checks. Parent lookup allows `No_Node` only
for semantic roots and rejects other invalid parent identities.
`Query_Node_Parent`, `Query_Node_Child_Count`, and `Query_Node_Child_At` use the
non-mutating node boundary for adapters that already hold semantic identity and
need tree navigation without native object materialization; this is tracked by
`native.boundary.node_tree_call`.
Indexed child lookup validates the requested index against the provider child
count and rejects invalid child identities, so native backends never receive
`No_Node` as a successful child target.
Parent, child-count, and indexed-child queries accept dispatcher cancellation
tokens and return `Cancelled` before provider invocation. The conformance
identifier is `native.boundary.tree_cancellation`.

`A11y.Native_Component_Calls` applies the same rule to geometry-driven native
requests. Contains-point and hit-test calls use logical desktop coordinates,
dispatch through the geometry-query path, query bounds through
`A11y.Nodes.Bounds_Safely`, and return stable `Node_Id` values for semantic
hits. A miss is represented explicitly as a successful no-target result with
`No_Node`. `Query_Node_Contains_Point` and `Query_Node_Hit_Test`
use the same non-mutating node boundary for adapters that already hold semantic
identity, so existing-node component queries do not materialize native objects
as a side effect; this is tracked by `native.boundary.node_component_call`.
Both calls accept dispatcher cancellation tokens and return `Cancelled` before
provider invocation. The conformance identifier is
`native.boundary.component_cancellation`.

`A11y.Native_Focus_Calls` makes native focus operations explicit without moving
focus ownership into a backend. Focused-state queries read the derived
effective semantic state set through `A11y.Nodes.Contract_Snapshot_Safely` and
the dispatcher, while focus requests invoke the platform-neutral `Set_Focus`
action and wait for ordinary semantic state-change events to describe the
result. Unsupported focus actions remain structured `Unsupported_Action`
results; the native boundary does not fabricate focus support.
The object-backed dispatcher path is tracked by `native.boundary.focus_call`.
`Query_Node_Focused` and `Request_Node_Focus` use the same admission and dispatch
rules for adapters that already hold semantic identity; this is tracked by
`native.boundary.node_focus_call`.
Focused-state queries and set-focus requests accept dispatcher cancellation
tokens and return `Cancelled` before provider invocation. The conformance
identifier is `native.boundary.focus_cancellation`.
`A11y.Sessions.Semantic_Session` also owns a portable focused-node slot for the
central semantic tree. `Set_Focus` accepts only live attached nodes, commits the
new focused `Node_Id` before publishing `Focus_Changed`, suppresses events for
unchanged focus, and rejects queue overflow before changing focus. Destroying a
focused node or focused subtree clears that slot and emits `Focus_Changed`
before the final `Node_Destroyed` event. This invariant is tracked as
`core.focus.session`.

`A11y.Native_Relation_Calls` exposes relation-derived native queries without
turning backend objects into relation owners. Active-descendant requests resolve
the source native object, read the semantic relation graph through the
dispatcher, and return stable `Node_Id` targets or an explicit no-target result.
Because active descendant is singular, multiple active-descendant targets are
reported as `Invalid_State` instead of being silently collapsed to the first
target.
Active-descendant queries also accept the same resource-limit configuration as
general relation queries. Invalid limit configurations are rejected before a
native callback is pinned, and a configured `Relation_Targets_Returned` bound
smaller than the observed target set returns `Resource_Limit` with no target,
preserving the rule that native adapters never expose partial relation
semantics.
Multi-target relation queries are bounded by `Relation_Targets_Returned`. If
the complete target set exceeds that bound, the boundary returns
`Resource_Limit` with no partial target prefix, so native adapters cannot expose
an incomplete relation set as authoritative semantics.
The object-backed dispatcher path is tracked by `native.boundary.relation_call`.
`Query_Node_Active_Descendant` and `Query_Node_Relation_Targets` use the
existing-node boundary for adapters that already hold semantic identity; this is
tracked by `native.boundary.node_relation_call`.
Active-descendant and multi-target relation queries accept dispatcher
cancellation tokens and return `Cancelled` before relation graph traversal. The
conformance identifier is `native.boundary.relation_cancellation`.
At the semantic session layer, `Active_Descendant` is treated as a singular
relation: adding a different target replaces the previous target atomically and
publishes `Active_Descendant_Changed`; adding the same target is a no-op. The
target must be a descendant of the source, and the source cannot target itself.
This prevents new session-owned state from becoming ambiguous or detached from
the semantic tree before native queries observe it.
General relation-target requests use the same boundary path and apply the
central `Relation_Targets_Returned` resource limit before returning targets to a
native protocol layer. Invalid shared limit configurations are rejected with
`Invalid_Argument` before opening a native boundary call or dispatching provider
work; native request routers use the same validation before normalizing relation
queries for AT-SPI `GetRelationSet`, UI Automation, and NSAccessibility.
AT-SPI relation-set materialization compares each relation target count against
the remaining budget before adding it to the running total.
The semantic `A11y.Relations.Relation_Graph` also uses that shared limit as a
configurable per-source/per-kind target capacity. Additions preflight both the
canonical and inverse relation lists, so overflow returns `Resource_Limit`
without committing a one-sided relation update. Shrinking below an existing
target list returns `Invalid_State`.
`A11y.Sessions.Semantic_Session` owns the relation graph for application-facing
semantic mutations. `Add_Relation` and `Remove_Relation` validate that source
and target nodes are still available, commit canonical and inverse relation
state before emitting `Relation_Added` or `Relation_Removed`, and reject queue
overflow before partial mutation. Duplicate additions and absent removals are
idempotent no-ops and do not publish semantic events. Destroying a node removes relations sourced
from that node and removes it from other target lists before the tombstone is
published, so dangling relation targets never remain observable through the
session. Surviving sources that lose the destroyed node as a target receive
`Relation_Targets_Changed` after the relation graph is committed and before the
final `Node_Destroyed` event; those notifications are included in event-capacity
preflight. Surviving owners that lose the destroyed node as
`Active_Descendant` receive `Active_Descendant_Changed` instead of a generic
relation-target event, keeping active-descendant semantics authoritative for
native focus and virtual-control mappings. This is tracked by
`relations.session_ownership`.
Relation declarations may outlive temporary detach/reattach cycles, but
`Relation_Targets` exposes only currently attached sources and attached targets.
Detached nodes therefore cannot leak through session-visible relation queries,
while stable relations can become visible again after reattachment.
Dynamic provider relation queries use `Relation_Targets_Safely`, which rejects
duplicate target identities in addition to invalid identities and resource-limit
overflow, so native relation arrays remain a set-shaped semantic projection.

`A11y.Backends.Native_Backends` is the common backend-contract implementation
for current native scaffolds. It owns `A11y.Native_Runtimes`, publishes
target-specific conformance declarations, records structured diagnostics, and
returns `Backend_Unavailable` during `Start` until a real Linux D-Bus transport,
Windows COM provider, or macOS Objective-C bridge is connected. Platform
adapters admit that connection through an internal transport-admission hook; an
admitted backend then keeps the shared runtime running and prepares semantic
events into native object-cache entries. `Transport_Status` returns the
adapter-facing admission snapshot: the typed transport state, whether a native
transport has been admitted, whether that admitted transport is currently
running, a monotonic generation for detecting changed transport observations,
the last structured transport failure, and which native target family the
backend represents. This boundary is tracked as
`backend.native.transport_status`; the generation contract is tracked as
`backend.native.transport_generation`. The adapter-facing
`Admit_Transport_With_Report`, `Record_Transport_Failure_With_Report`, and
`Stop_With_Report` operations return a `Transport_Transition_Report` containing
the operation, before and after snapshots, requested status, final status, and
whether admission, running state, typed state, or generation changed; this is
tracked as `backend.native.transport_transition_report`. These records are used by platform
adapters and tests to observe the admission boundary without exposing D-Bus,
COM, or Objective-C handles through the public semantic API. Native adapters may call
`Record_Transport_Failure` before startup or after shutdown to clear admission,
store the structured failure status, and emit
`backend.native.transport_failed` diagnostics; attempting to report success as a
failure or mutate a running transport is rejected. `Prepare_Publication` exposes
that prepared event/object record to platform adapters, while `Publish` remains
the generic backend-contract entrypoint. This keeps native backend selection
honest while still exercising lifecycle, publication, stale-node rejection, and
shutdown behavior through the shared runtime. `Stop` clears transport admission,
stops the shared runtime, releases native object-cache state, and records a
structured `backend.native.deterministic_shutdown` diagnostic so adapter tests
can prove the shutdown boundary without inspecting backend-private handles.
`Prepare_Publication_With_Report` adds native backend publication evidence:
event-envelope validity, transport snapshots before and after, transport
admission at entry, whether runtime preparation ran, the nested runtime
preparation report, prepared object flags, and final structured status.
Runtime publication failures after
transport admission are recorded as structured diagnostics using centralized
status-to-category mapping, the event sequence, and a stable `status` field.
All backend implementations expose `Configure_Limits`, which accepts the
platform-neutral `A11y.Resource_Limits.Resource_Limit_Config`. The current
implementation applies `Diagnostic_Trace_Size` to backend-owned diagnostic logs;
future backend-owned caches, callback accounting, and native materialization
limits should use the same hook.

`A11y.Backends.Default.Create_Default` is the application constructor: it
returns the native backend selected for the current host only when
`A11y.Backends.Selection.Native_Available` reports usable transport. Otherwise
it falls back to the validating Null backend while preserving the selection
status as `Backend_Unavailable` and `Fallback = True`. Explicit `native`
overrides may still select staged native scaffolds on supported targets.
`Create_Null` returns the validating Null backend exactly for deterministic
conformance tests. `Create_Platform_Default` is retained as a target-aware
compatibility alias for code that adopted the staged constructor name.

The current registry uses `A11y.Node_Ids.Max_Node_Ids`, a fixed bound of 65,536
entries. Exceeding that bound returns `No_Node` during allocation; later phases
should convert that into a structured allocation result.
`Node_Id` validity follows the same bound: zero and fabricated values above
`Max_Node_Ids` are invalid, and backend identity helpers reject them before
deriving D-Bus object paths, UIA runtime-id components, or macOS element
identifiers. Public identity `Image` helpers return stable trimmed decimal
strings, or `none` for null identities, and `Event_Sequence_Image` applies the
same trimmed decimal rule for event diagnostics. Diagnostics and generated
metadata do not inherit Ada's leading-space numeric image format.

## Resource Limits

`A11y.Resource_Limits` is the portable configuration record for externally
triggered work and bounded storage. It declares stable limit kinds for event
queues, native object caches, tombstone retention, relation and selection
materialization, text returned per request, traversal depth, native array and
string sizes, outstanding callbacks, callback and shutdown durations,
diagnostic trace size, event coalescing windows, and virtual-node realization.
Each kind has stable metadata carrying the protocol-safe limit name and default
value used by generated reports and release checks.

`Default_Config` mirrors the bounds currently enforced by the implemented
containers where those containers already exist. `Validate` rejects zero-sized
bounds, `Set_Limit` returns `Invalid_Argument` for invalid values, and
`Exceeded` gives backends and future provider dispatchers one common check
before materializing client-requested data. The package is intentionally
platform-neutral; backend-specific codecs may use matching defaults without
making semantic packages depend on D-Bus, COM, or Objective-C types.

`A11y.Results` owns stable status identifiers and records whether a status is a
successful result and whether it represents an expected rejection or an internal
fault. Native protocol boundaries translate these structured statuses into
D-Bus errors, HRESULT-style values, or Objective-C reply categories without
exposing native error codes through the public semantic API.

## Lifecycle And Stale References

The semantic lifecycle states are:

Created, Attached, Active, Removing, Defunct, Removed.

`A11y.Nodes` owns stable lifecycle metadata for these states, including whether
a state is externally live and whether provider access is permitted. The same
package owns stable exposure-policy metadata describing whether a policy exposes
the node, descendants, both, or neither. Backends and native runtimes consume
that committed semantic metadata rather than inventing lifecycle or exposure
policy locally.
`A11y.Trees.Exposure_Views` applies those policies to a structural semantic
tree: exposed children are returned in deterministic reading order, flattened
or descendants-only nodes are skipped while their exposed descendants remain
visible, hidden subtrees are pruned, and projected parent lookup skips
non-exposed ancestors. The helper enforces traversal and materialized-array
resource limits and reports structured failures instead of falling back to a
backend-specific projection rule.

`A11y.Nodes.Contract_Snapshot_Safely` captures the role, raw state set,
capability set, and exposure policy from an `Accessible_Node` without allowing
provider exceptions to escape. It delegates to `Validate_Contract`, which
centralizes the first provider contract checks that would otherwise diverge per
backend. It validates the derived effective state set, rejects hidden-subtree
nodes that still claim externally visible active/focused/showing state,
enforces editable-text capability dependencies,
and verifies required role-to-capability relationships for action, text, value,
table, document, image, and surface roles. Live-region capability metadata is
advertised through the same immutable `Capability_Set` even though no single
role is forced to carry it. It also uses `A11y.Roles` selection metadata to
reject multi-selection state on non-container roles and
selected/selectable state on non-item roles before any backend maps those
states. Session exposure projection also uses that contract snapshot, so
invalid provider contracts are hidden before relation, parent, or child
exposure views can publish them. `A11y.Sessions.Create_Node`
uses the safe contract snapshot before registration. `Basic_Snapshot_Safely`
does the same for core name, description, and bounds retrieval, applying
`Native_String_Size` to text properties before backend projection. Native
query callbacks use the safe basic snapshot for core name, description, and
bounds requests, so provider exceptions and malformed limits become structured
results before D-Bus, UI Automation, or NSAccessibility mapping. Session
creation applies contract validation before registry registration and before
publishing `Node_Created`; provider exceptions during validation are contained
as structured `Internal_Error` results. The conformance identifier is
`core.provider.contract`; native backends declare it as internal support because
the validation occurs before D-Bus, UI Automation, or NSAccessibility
projection.

Removed and defunct entries become tombstones. Lookups for tombstoned nodes
return `Node_Unavailable` and do not expose provider pointers.
`A11y.Nodes.Validate_Transition` owns legal lifecycle transitions. The registry
uses it to reject rollback and resurrection attempts, so tombstoned nodes cannot
be moved back into a provider-accessible state.
Registry snapshots also record the currently committed tree parent. Session
attach, detach, move, and destroy operations keep this metadata synchronized
with the semantic tree so native stale-reference handling can inspect attachment
state without dereferencing application providers.

The registry supports explicit pin/unpin operations for native callback windows.
Pinned callback windows are bounded by
`A11y.Resource_Limits.Outstanding_Callbacks`; overflow returns
`Resource_Limit`, and shrinking the configured bound below already-pinned
entries returns `Invalid_State` without changing the current bound.
Provider callbacks must not be invoked while holding registry locks.

## Semantic Session

`A11y.Sessions.Semantic_Session` coordinates the registry, tree, and event queue.
It is the first central semantic mutation surface. Session operations commit
state before queueing observable events:

* `Create_Node` registers a provider entry and queues `Node_Created`;
* `Attach_Root` commits root ownership and active lifecycle before
  `Node_Attached`;
* `Attach` commits child ownership and lifecycle before `Child_Added` and
  `Node_Attached`;
* `Detach` commits parent removal, subtree detachment, descendant lifecycle
  changes, and focus clearing before `Focus_Changed`, `Child_Removed`, and
  ordered `Node_Detached` events;
* `Move` commits parent metadata before publishing `Child_Removed`,
  `Child_Added`, and `Children_Reordered` for cross-parent moves, or just
  `Children_Reordered` for same-parent reorders;
* `Destroy` removes provider access, leaves a tombstone, and then queues
  `Node_Destroyed`.

Tree mutation details are validated through `Validate_Tree_Event_Payload`.
Child add/remove events carry the stable parent `Node_Id`, child `Node_Id`, and
one-based sibling index for the committed mutation. Aggregate reorders and
subtree rebuilds may carry only the parent when no single child/index is
authoritative. Omitted child identities must carry `No_Node`, omitted indexes
must carry `Positive'First`, and validation rejects child or index fields that
contradict those absence flags or are marked present on aggregate tree events.
AT-SPI, UIA, and
NSAccessibility mappers retain this validated neutral payload for later native
structure notifications instead of deriving child identity from native object
slots. The conformance identifier is `events.tree.payload`.

Destroying an attached node first detaches the whole exposed subtree. The
destroyed node becomes a tombstone; surviving descendants remain live but
non-exposed until the application explicitly reattaches or destroys them.
Destroying the root clears the exposed root instead of leaving a stale tree
entry.
Explicit `Detach` follows the same exposed-subtree rule without tombstoning the
detached nodes: the detached node and descendants remain live but non-exposed,
registry parent metadata is cleared, and any focus inside the subtree is cleared
before detach events are published. Detach validates that the requested node is
currently exposed before checking event capacity, so detached or stale nodes
return `Node_Unavailable` even if the event queue is full.
Attachment operations validate root ownership, parent exposure, self-parenting,
and duplicate attachment before event-capacity preflight, so invalid tree
requests are not masked by `Resource_Limit`. This contract is tracked under
the `tree.attachment.validation` conformance feature.
Move validates root, attachment, and cycle constraints with bounded tree
metadata checks before event-capacity preflight, so invalid moves return their
semantic tree error instead of being masked by resource pressure.
Destroying an attached non-root node preflights capacity for every lifecycle
event it must publish, then emits `Child_Removed`, `Node_Detached` for the
destroyed node, `Node_Detached` for each surviving descendant, and finally
`Node_Destroyed` for the destroyed node. Destroying an attached root emits the
same subtree detach events without a parent `Child_Removed`. If the event queue
cannot hold the full ordered set, the operation returns `Resource_Limit` before
detaching, tombstoning, or publishing a partial event sequence.
These ordered tree mutation guarantees are tracked under the
`tree.mutation.event_order` conformance feature.

Operations against destroyed nodes return `Node_Unavailable`.
Session-owned event storage is configured through
`A11y.Sessions.Configure_Limits`, which forwards
`A11y.Resource_Limits.Event_Queue_Size` to the underlying event queue.
The same session configuration applies `Relation_Targets_Returned` to the
session-owned relation graph and `Outstanding_Callbacks` to the protected
registry, keeping semantic mutation limits and native callback pinning under
one resource configuration.
Mutation preflight uses the configured capacity, so a multi-event operation
returns `Resource_Limit` before committing partial semantic state when there is
not enough event capacity.

## Semantic Tree

`A11y.Trees.Semantic_Tree` owns accessibility tree relationships by stable
`Node_Id`, not by child position or provider address. It enforces:

* exactly one root;
* one parent per attached non-root node;
* deterministic child order;
* no duplicate attachment of a node;
* cycle rejection during moves;
* detachment from exposure without changing identity.

Tree validation also rejects duplicate child entries within a parent list, stale
child references, parent/child mismatches, excessive parent-chain depth, and
invalid shared traversal-limit configuration.
Single-node `Detach` is leaf-only; non-leaf exposure removal uses
`Detach_Subtree` or the session lifecycle operations so descendants cannot be
left attached beneath a detached parent.
`A11y.Trees.Exposure_Views` is the central exposed-tree projection layer for
backends. It keeps the raw semantic ownership tree separate from native
hierarchy flattening, applies `Flatten_Node`, `Hide_Node_And_Subtree`, and
`Expose_Descendants_Only` consistently, and bounds projected child
materialization through `Native_Array_Size`. This contract is tracked under
the `tree.exposure.projection` conformance feature.
`A11y.Sessions.Exposed_Children_Of` and `Exposed_Parent_Of` apply the same
projection through registry-owned provider metadata and the session's
configured resource limits. Session relation queries use that projection too:
relations whose source is hidden, flattened, detached, or destroyed are not
externally observable, and hidden relation targets are filtered out.
Native hierarchy, core property/attribute, value, text, selection, relation,
hit-test, table cell/span, image metadata, document metadata, and surface/window
metadata mappers use the same projection layer so backend-specific protocol
shapes cannot expose nodes hidden from the authoritative semantic tree.
Native-facing query families that perform their own final projection checks are
tracked separately as `native.projection.property`,
`native.projection.action`, `native.request.action_payload`,
`native.projection.relation`, and `native.projection.event_source`.

Large virtual child sets will need later indexed/lazy provider hooks. The
current tree is a bounded in-memory structure suitable for the first semantic
conformance slice.

## Event Queue

`A11y.Event_Queues.Event_Queue` assigns strictly increasing semantic event
sequence numbers and nondecreasing committed timestamps. It defaults to 1,024
events and can be configured from
`A11y.Resource_Limits.Event_Queue_Size`; overflow reports `Resource_Limit`
without appending or consuming a sequence number, and the rejected event record
is returned with `No_Event`. The conformance identifier for timestamp ordering
is `events.timestamp_order`.
Invalid event sources are rejected before coalescing or sequence assignment:
`No_Node` and other invalid identities return `Node_Unavailable`, leave the
queue unchanged, and do not consume an event sequence.
Session lifecycle and tree operations preflight the bounded event queue before
mutating semantic state. If there is not enough capacity for the required
committed events, the operation returns `Resource_Limit` before allocating,
attaching, detaching, moving, or destroying nodes.
Provider-owned semantic updates that do not change session-owned lifecycle,
tree, focus, or relation state use `A11y.Sessions.Notify_Node_Event` after the
provider has committed its own state. The session validates that the source node
is live and attached, rejects lifecycle/tree/focus/relation notifications that
belong to dedicated session APIs, preflights one event slot, and then publishes
the typed event with the next semantic revision. The conformance identifier is
`events.session.notification`.

The queue currently coalesces only repeated adjacent events for the same source
and kind when the envelope is sufficient to prove that intermediate values are
not independently observable. The currently coalescible kinds are:

* `Bounds_Changed`;
* `Value_Changed`.

Payload-sensitive events such as property, state, relation-target, cell,
live-region, caret, text-selection, and text-attribute changes are deliberately
not coalesced by the envelope-only queue. They can only become coalescible once
the queue carries typed payload keys for the semantic item that changed. Text
mutation events are never coalesced.

`A11y.Backends.Event_Pumps` is the common session-to-backend delivery helper.
It peeks the next committed semantic event, validates the event envelope,
publishes it through the backend contract, and acknowledges the queue entry only
after the backend returns success. If a backend rejects the event, the event
remains pending so callers can retry, switch backend policy, or shut down
deterministically without silently dropping committed semantic state.
`Pump_One_With_Report` returns `Pump_One_Report`, recording before/after
pending counts, queue capacity, event identity, validation, publication,
acknowledgement, delivered count, and every structured status involved in the
single delivery attempt. `Pump_All_With_Report` returns `Pump_All_Report`,
recording bounded aggregate attempts, delivered count, last event sequence,
stop reason, final pending count, and final status. Compatibility `Pump_One`
and `Pump_All` delegate to the report variants. The conformance identifier is
`events.backend_pump_report`.
Bulk pumping is bounded by the session's configured event capacity, so the
delivery helper follows the same `Event_Queue_Size` policy as semantic mutation
and cannot silently loop beyond the configured queue bound.

`A11y.Event_Subscriptions.Subscription_Set` is the first backend fan-out layer.
It gives native backends bounded listener records, event-kind filters,
delivered/drop accounting, deterministic unsubscribe behavior, and rejection of
invalid event envelopes. It does not emit native notifications itself; native
backends consume this layer before translating to AT-SPI signals, UIA events, or
NSAccessibility notifications.
Subscription fan-out also rejects duplicate `Node_Destroyed` events and any
later event for the destroyed source before native notification mapping.
`No_Events` is an invalid subscription filter: empty filters are rejected with
`Invalid_Argument` before an identifier is allocated, while `Has_Events` exposes
the same predicate for tests and backend admission checks.
The set defaults to `Max_Subscriptions` and can be configured from the common
resource-limit record; until a dedicated listener limit exists, it uses
`Outstanding_Callbacks` as the closest backend-admission bound. Capacity changes
cannot shrink below the active subscriber count.

## Dispatcher

`A11y.Dispatchers.Immediate_Dispatcher` is a test and bootstrap dispatcher. It
does not provide native thread integration, but it defines the expected failure
shape for backend-to-provider calls:

* shutdown rejects new callbacks with `Shutting_Down`;
* reentrant callbacks are rejected with `Busy`;
* explicit already-on-dispatch-thread callbacks can run inline when adapter
  code has already entered the dispatch context and chooses the fast path;
* token-aware inline callbacks preserve the same pre-invocation `Cancelled`
  result for cancellable calls;
* callback exceptions are contained and converted to `Internal_Error`;
* outstanding callback count returns to zero after completion.

Each `Call_Kind` also has stable metadata for backend/native boundary mapping.
The metadata exposes a stable name and the resource-limit kind used for
timeout accounting. Shutdown calls use `Shutdown_Duration_MS`; other current
provider calls use `Callback_Duration_MS`. The conformance identifier is
`dispatcher.call.metadata`. `Has_Timed_Out` centralizes elapsed-millisecond
classification against those per-kind limits so hostkit-backed dispatchers can
use platform monotonic clocks while preserving the common timeout policy. The
conformance identifier is `dispatcher.timeout.classification`.

The immediate dispatcher records per-kind accepted callback entries, rejected
callbacks, and callback exceptions. This lets native boundary tests and future
diagnostics distinguish a busy tree-navigation rejection from a shutdown-time
action rejection without exposing native callback details through public
semantic APIs. The conformance identifier is `dispatcher.call.accounting`.
It also exposes `Cancellation_Token` values and per-kind cancellability
metadata. A token cancelled before dispatch rejects cancellable provider calls
with structured `Cancelled` before invoking application code; shutdown calls
are intentionally non-cancellable and remain governed by shutdown policy. The
conformance identifier is `dispatcher.cancellation`.

GUI toolkit adapters and hostkit-backed main-thread dispatchers should preserve
these result categories.

## Actions

`A11y.Actions` defines stable semantic action identifiers and an immutable
`Action_Set` for discovery. `Preferred_Default_Action` records the central
role-to-action preference, and `Default_Action` applies that preference to a
node's discovered action set without relying on native platform constants.

`Invoke_Safely` enforces expected action failure behavior:

* invalid `Node_Id` values return `Node_Unavailable`;
* unsupported actions return `Unsupported_Action`;
* provider exceptions are contained and converted to `Internal_Error`.

The overload that receives a committed `State_Set` is the backend-facing action
gate. It performs the same identity and support checks, then applies central
preconditions before entering provider code; unsupported actions return
`Unsupported_Action` before disabled, busy, read-only, or defunct state
failures are considered.

`A11y.Actions.Check_Preconditions` centralizes state-based action rejection
before providers are invoked. Precondition metadata has stable names and maps
live-node, enabled, not-busy, and writable requirements to `Node_Unavailable`,
`Disabled`, `Busy`, and `Read_Only`. Enabled actions reject busy nodes; mutable
increment/decrement actions additionally reject read-only nodes. The contract is
tracked under `actions.preconditions`.
`Validate_Request` combines immutable action-set discovery with those
preconditions, returning `Unsupported_Action` before dispatch for actions not in
the node's semantic action set and otherwise applying the central state checks.

Actions do not mutate backend-owned semantic state. Providers perform their own
application operation and publish resulting state changes through the normal
semantic update path.
Native mappers expose only operations that have a defensible platform
projection: UIA maps activate/press, toggle, expand/collapse, show-menu/dismiss,
selection-item, scroll-item, and close operations; NSAccessibility maps
activate/press/toggle, show-menu, open, dismiss/close, increment/decrement,
select, and set-focus. Unsupported semantic actions remain explicit
`Unsupported_Action` results. Backend request routers can carry an optional
action-node exposure context; when present, UIA pattern discovery and action
mapping, and NSAccessibility action discovery and action mapping, reject hidden
source nodes before advertising native operations. Native method routers and
request routers that stage action invocation preserve the neutral `Action_Id`
for provider dispatch; this contract is tracked as
`native.request.action_payload`.

## Values

`A11y.Values` represents semantic values without forcing them into
`Long_Float`. Supported value forms currently include:

* unknown and indeterminate;
* integer;
* exact decimal, represented as scaled integer units;
* floating point;
* boolean;
* enumerated index.

`Value_Metadata` carries current/minimum/maximum values, small and large
increments, read-only versus writable mode, units, and precision.
`Current_Metadata_Safely` validates provider metadata before backend projection
and normalizes invalid or exceptional value metadata to read-only unknown
values, so native mappers do not project contradictory ranges or increments.
Floating-point conversion is explicit: `To_Long_Float` is available for callers
that accept approximation, while native backend query paths use
`To_Long_Float_Lossless` and return `Native_Failure` when an integer or exact
decimal would lose precision in the platform floating-point representation.
Unknown, indeterminate, boolean, and enumerated values do not fabricate numeric values.
Value kinds and access modes have stable metadata names plus numeric/known and
mutable classification, so backend pattern/property mappers share the same value
policy.
`Validate` centralizes value metadata checks before native exposure. It bounds
unit strings with the shared `Text_Returned` limit, rejects nonnumeric range
bounds and increments with `Invalid_Argument`, requires known numeric
current/bound/increment fields to use one semantic numeric kind, requires known
increments to be strictly positive, requires a known large increment to be at
least the known small increment, and rejects contradictory or out-of-range
numeric metadata with `Invalid_Range`. Linux AT-SPI, Windows UIA, and macOS
NSAccessibility value query layers route through this validator and declare
`value.resource_limit` as `Internal_Only` evidence.
The Linux AT-SPI method router plus the Windows and macOS request routers pass
their configured resource-limit bundles into property/attribute projection,
fragment/hierarchy navigation, selection traversal, table traversal, Linux
surface traversal, Windows/macOS surface traversal/string replies, text, value,
image, and document query layers, so fixture and backend adapters can tighten
traversal, native-string, and text-return bounds without relying on process
defaults.

## Selection

`A11y.Selection.Selection_Set` keeps selection separate from focus, activation,
and current item. The first implementation uses a bounded explicit `Node_Id`
list and supports:

* none, single, multiple, contiguous multiple, and extended modes;
* selection-required policy;
* deterministic selected-item order;
* membership tests;
* indexed selected-item lookup;
* toggle, deselect, and clear operations;
* anchor and current item metadata;
* explicit current-item clearing without changing selected members.

The current representation is intentionally simple. Later virtual collections
can add range, interval, sparse bitmap, or lazy predicate representations behind
the same semantic concepts.
Selection modes have stable metadata names and central flags for whether they
allow selection, multiple selected items, and range-shaped selection.
Current item identity is validated when present, but it is not required to be a
selected item because current item, focus, active descendant, activation, and
selection remain distinct semantics.
The materialized selected-item capacity defaults to `Max_Selected_Items` and can
be configured through `A11y.Resource_Limits.Selection_Items_Materialized`.
Shrinking below already materialized selections is rejected, and configured
overflow reports `Resource_Limit` without mutating the current selection.
`A11y.Selection.Validate` checks snapshot invariants before native selection
adapters answer queries, including required empty selections, nonselectable
required modes, invalid selected identities, duplicate selected identities, and
anchor membership.

## Text

`A11y.Text` uses opaque positions and ranges instead of UTF-8 byte offsets or
native UTF-16 code-unit offsets. The first implementation stores code-point
indices internally and exposes helper functions for:

* range construction and validation;
* bounded plain-text slice retrieval;
* protected text redaction;
* typed edit request validation;
* UTF-16 code-unit counting for Windows and macOS mapper work.

`Protected_Text` returns `Permission_Denied` and no text. Text retrieval is
bounded by `Max_Text_Returned` by default, and range construction plus slicing
can be configured with `A11y.Resource_Limits.Text_Returned`; values above
`Max_Text_Returned` are rejected as invalid configurations.
Protected-text policies have stable metadata names and an `Exposes_Text` flag.
The slice operation and native text mappers use that policy as a mandatory
security boundary. Current native text mappers also deny protected text counts,
native offset conversion, and caret offsets rather than exposing length or
cursor metadata.
Native property mappers must apply the same boundary for value-style text. The
Windows UIA and macOS NSAccessibility mappers reject `Value_Text` for password
roles and for snapshots explicitly marked as protected value text, returning
`Permission_Denied` without exposing the supplied string.
Those mappers also apply `Native_String_Size` to every string property reply
before the provider boundary copies the value into native containers, returning
`Resource_Limit` instead of handing oversized strings to ABI adaptation code.

Editable text operations are represented as typed `Text_Edit_Request` values
for insert, delete, replace, and whole-text set operations. Validation enforces
protected-text policy, read-only state, neutral range validity, and the
configured text-size limit before a backend forwards the request to provider
dispatch. Whole-text set requests must use the explicit no-range encoding
(`Start = 0`, `Count = 0`) so malformed native range arguments are not silently
ignored. Validation does not mutate semantic text state; provider updates must
return through the normal semantic update and event path.

`Bounded_Code_Point_Range` is the central entry point for native or protocol
offset/count inputs. It validates code-point ranges against the known content
length and the configured text-return limit before text slicing or UTF-16 unit
conversion.
`Text_Range_Safely` also validates provider output after dispatch. If a
provider returns more code points than the requested range, the common boundary
returns `Invalid_State` with no text instead of allowing a native backend to
project an oversized or wrong-range reply.
`Is_Valid`, `Last`, `Slice`, and `UTF_16_Units` perform overflow-safe range
validation for directly constructed ranges and handle strings whose lower bound
is not 1.

## Live Regions

`A11y.Live_Regions` defines neutral live-region priority and relevance metadata
for semantic announcements. `Off`, `Polite`, and `Assertive` have stable names
and explicit flags for whether they are externally announced and interruptive.
Relevant change metadata is stable for additions, removals, and text updates.
The central helpers expose both a count and a stable space-separated relevance
name list so backends do not derive native relevance strings independently.

Inactive live regions must not declare relevant changes, and announced live
regions must declare at least one relevant change; contradictory metadata
returns `Invalid_State`. Announcement text is constructed through
`Create_Announcement`, which rejects protected text with `Permission_Denied`,
rejects empty announcement text with `Invalid_Argument`, uses the shared
`Text_Returned` resource limit to bound native-facing strings, and returns
`Resource_Limit` without retaining text when the request is too large. Dynamic
live-region controls implement `Live_Region_Provider` and are
queried through `Current_Metadata_Safely`, which validates relevance policy and
normalizes invalid or exceptional provider metadata to inactive semantics with
structured failures. `Validate_Live_Region_Event_Payload` binds committed
live-region metadata to `Live_Region_Changed` and announcement text to
`Announcement_Requested` events. Announcement events must carry non-empty
announcement text created through the live-region framework, and live-region
change events must not mark announcement text present because the changed
subtree is the authoritative source. Record-shaped payload validation rechecks
announcement length against `Text_Returned` so manually constructed public
records cannot bypass the bound. Backend-private live-region query mappers for
AT-SPI, UIA, and NSAccessibility validate supplied resource-limit
configurations before object-path resolution or native-facing replies, validate
the same neutral metadata, bound native-facing string replies, reject defunct
snapshots, and report setting, relevance, atomicity, assertive/interruption,
and external-announcement policy without owning semantic state. AT-SPI, UIA,
and NSAccessibility event mappers
retain the validated neutral payload so announcement text and live-region policy
are not re-derived at native notification time. The live-region contract is
tracked by `events.live_region`; typed payload validation is tracked by
`events.live_region.payload`; mapper coverage is tracked by
`live_region.metadata`, `live_region.relevance`, and
`live_region.backend_routing`.

## Tables

`A11y.Tables.Table_Snapshot` models table semantics without requiring every
logical cell to be materialized. It separates logical row/column counts from the
bounded set of currently known cells.

Each exposed cell has a stable `Node_Id` and logical coordinates. Merged cells
are represented once with row and column spans, and materialized cell span
rectangles must not overlap. Reverse lookup by `Node_Id` is available for
backend mappers and conformance checks.

Materialized cells are capacity-bounded. A fresh snapshot keeps the historical
hard capacity `Max_Materialized_Cells`; callers that need tighter fixture,
backend, or virtualization bounds can apply `Configure_Limits`, which uses the
shared `Virtual_Node_Realization` limit. Adding beyond the configured capacity
returns `Resource_Limit`, invalid zero or impossible limits return
`Invalid_Argument`, and shrinking below already materialized cells returns
`Invalid_State` without changing the active capacity.

`Resolve_Cell` centralizes bounds validation and sparse-cell handling for
backend mappers. Out-of-range coordinates return `Invalid_Range`; in-range but
unmaterialized sparse cells return `Node_Unavailable`.
`Validate` rechecks provider table snapshots at the common boundary before
native projection, including displayed and visible ranges, capacity,
materialized cell identity, span fit, overlap, current-cell metadata, and sort
key consistency. `Current_Table_Safely` returns an empty snapshot with the
structured failure instead of allowing malformed provider table state into
AT-SPI, UIA, or NSAccessibility mappers.
Table mutation event details are validated through
`Validate_Table_Event_Payload`. Row and column insertion/removal events carry
the stable table node and logical row or column index. Cell changes carry the
stable table node, stable cell `Node_Id`, and logical row/column coordinates,
so cell identity remains node-based rather than derived from coordinates. The
cell `Node_Id` must be distinct from the table `Node_Id`.
Absent item, row, and column metadata must carry `No_Node` or zero before native
mapping, and metadata marked present for the wrong table event family or
contradicting an absence flag is rejected before native mapping. AT-SPI, UIA,
and NSAccessibility event mappers retain this validated neutral payload for
later native table notifications. The conformance identifier is
`events.table.payload`.
Linux AT-SPI, Windows UIA, and macOS NSAccessibility mapper declarations expose
`table.resource_limit` rows for this bounded materialization behavior. These
rows remain `Internal_Only` until OS integration clients provide production
evidence.

Coordinate spaces and header scopes have stable metadata names plus central
classification flags for logical versus presentation-based lookup and row versus
column header applicability. Native table mappers use these classifications
instead of deriving header or coordinate behavior independently.

## Documents, Images, And Surfaces

`A11y.Documents` models document semantics as metadata for ordinary accessible
nodes. It includes document roles, heading levels, language, title, author,
subject, version, revision, creation/modification metadata, pagination, and
landmark metadata without importing HTML, PDF, Markdown, or EPUB-specific
concepts. Document roles have stable metadata names and role-derived landmark
classification, so backend mappers do not independently decide which semantic
document roles behave as landmarks.

Document metadata validation is centralized. `Validate` checks heading-level
range, requires nonzero heading levels to belong only to semantic `Heading`
roles, checks that `Current_Page` is either absent or within `1 .. Page_Count`,
and bounds language, title, author, subject, version, revision,
creation/modification, and landmark strings with the shared `Text_Returned`
limit before those fields are returned through native document interfaces.
Invalid resource configurations return `Invalid_Argument`, out-of-range
headings or pagination return `Invalid_Range`, heading levels on non-heading
roles return `Invalid_State`, and oversized metadata text returns
`Resource_Limit`.
`Current_Metadata_Safely` preserves those structured failures while returning
empty document metadata, so invalid provider data cannot be projected by a
native backend that needs a defensive neutral fallback.

Document lifecycle event details are validated through
`Validate_Document_Event_Payload`. `Document_Loaded` and `Document_Closed`
payloads carry the stable document `Node_Id` and may carry the containing
semantic surface `Node_Id`. The payload deliberately avoids format-specific
concepts and does not derive document identity from native windows, file names,
titles, or localized labels. Absent surface references must carry `No_Node`,
and a containing surface must not be the document node itself. AT-SPI, UIA, and
NSAccessibility event mappers retain the validated neutral payload for native
document notifications. The conformance identifier is `events.document.payload`.

`A11y.Images` keeps semantic image metadata separate from image buffers and
rendering formats. Decorative images are normally hidden from exposure, while
informative images can carry alternative text, long descriptions, captions, and
optional intrinsic dimensions. Image kinds have stable metadata names and
default exposure/structured-content classification, and `Is_Structured`
centralizes chart/diagram/map/canvas classification for backend mappers; OCR
and automatic image description remain outside a11y. `Validate` bounds
alternative text, long
descriptions, and captions with the shared `Text_Returned` limit before native
image interfaces expose those strings. Decorative images that carry alternative
text, long descriptions, or captions return `Invalid_State` because those nodes
are intended to be omitted from native exposure. If intrinsic dimensions are
declared, both width and height must be positive; zero-sized metadata should be
represented by leaving `Has_Intrinsic_Size` false. Oversized image metadata text
returns `Resource_Limit`, invalid intrinsic dimensions return `Invalid_Range`,
and invalid shared resource configurations return `Invalid_Argument`.
`Current_Metadata_Safely` preserves those structured failures while returning
decorative, non-exposed metadata, so invalid provider image data cannot leak
alternative text or captions into native image interfaces.

`A11y.Windows` models semantic surfaces independently from native window
objects. Surface kind, modality, visibility, activation, and window operation
capabilities are represented without exposing HWND, NSWindow, or other native
handles. Surface kinds have stable metadata names plus top-level and
modal-by-kind classification used by backend mappers and native window
projection. Surface state flags also have stable metadata names, with close,
resize, and move classified as operation capabilities rather than ordinary
presentation state. `Has_State` and `Set_State` centralize flag access for
backend mappers. `Validate` rejects contradictory surface states before native
projection; active hidden surfaces, active minimized surfaces, and minimized
surfaces that are also maximized or fullscreen return `Invalid_State`.
`Current_Surface_Safely` preserves that structured failure while returning a
hidden embedded surface, so invalid provider surface state is not projected as
a native window.

Window and surface lifecycle event details are validated through
`Validate_Window_Event_Payload`. Window opened, closed, activated, and
deactivated payloads carry the stable semantic surface `Node_Id`, the neutral
surface kind, and an optional owner surface `Node_Id`. Owner identity is
validated separately from native window ownership and self-ownership is
rejected, so backend mappers do not infer semantic ownership from HWND,
NSWindow, D-Bus object paths, or native parent chains. Absent owner references
must carry `No_Node`, and AT-SPI, UIA, and NSAccessibility event mappers retain
the validated neutral payload for native window notifications. The conformance
identifier is `events.window.payload`.

## Conformance

`A11y.Conformance` provides the first data model for support claims:

* each feature has a stable dotted identifier;
* backend declarations use `Exact`, `Equivalent`, `Approximate`,
  `Internal_Only`, or `Unsupported`;
* declarations can include a native mapping string and test identifier;
* missing declarations resolve to `Unsupported`.

The current declarations are intentionally small and cover the semantic
foundation implemented so far. Future native backends should not advertise a
feature until a matching declaration and native conformance test exist.

The child crate builds `Capability_Matrix`, an Ada tool that emits current
declarations as a deterministic Markdown table. It reports Null validation,
Disabled fallback, and the current Linux AT-SPI, Windows UIA, and macOS
NSAccessibility mapper/scaffold rows. Native mapper rows are currently
`Internal_Only`: they document implemented translation layers and compile-time
evidence, but they are not production support claims. A backend row should move
to `Exact`, `Equivalent`, or `Approximate` only after matching native
integration client evidence exists. `backend.diagnostics.bounded` records the
backend-level diagnostic snapshot behavior shared by Null, Disabled, and native
backend scaffolds.

## Linux AT-SPI Cache

`A11y.Linux.ATSPi_Object_Registry` is the session-local AT-SPI registry that
binds stable D-Bus object paths to `A11y.Native_Object_Caches` records. It
materializes a native object id for a semantic `Node_Id`, derives the stable
object path from the backend session and node identity, and resolves incoming
D-Bus paths back through the cache before method routing. Malformed paths,
cross-session paths, stale defunct nodes, and released objects return structured
`Node_Unavailable` or `Invalid_Argument` results without touching provider
state. The registry enforces `Native_Object_Cache_Size` and
`Tombstone_Retention`, preserves tombstones for stale-reference handling, and
offers `Drained` plus `Reset_When_Drained` for deterministic shutdown. Its
conformance identifier is `linux.atspi.object_registry`, and the same
implementation also provides the common `native.object_cache.identity`
identity guarantee.
`Export_Descriptor` resolves an existing native object id into the stable
session/node/object-path metadata that a future D-Bus object server can publish,
without deriving identity from addresses or materializing new objects.
The registry also owns bounded native-call admission for incoming D-Bus work.
`Begin_Native_Call` and `End_Native_Call` use the shared native callback gate,
report `Outstanding_Calls` in registry snapshots, and keep reset/drained
shutdown from clearing object state while a method call is pinned.
`A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call` is the adapter-facing
bridge for the future live transport path: it resolves an incoming object path
through the registry, pins the native object for the duration of method
routing, releases the pin before returning, and rejects unregistered, stale, or
cross-session paths before dispatch.

`A11y.Linux.ATSPi_Cache` builds backend-private cached-node projections from
semantic snapshots. A cached node contains stable object paths derived from
`Node_Id`, mapped role, name, description, child count, and an interface set
derived only from semantic capabilities. It rejects invalid sessions and
defunct snapshots, validates object paths through the D-Bus codec, and does not
traverse descendants or call providers. The configured `Native_Object_Path` and
`Native_String_Size` limits apply to generated object paths and projected cache
text before the cached node is returned. Cache projection validates supplied
resource-limit configurations before session checks, object-path construction,
or cached text/interface projection.
Release evidence marker: Cache projection validates supplied resource-limit
configuration before projection.

`A11y.Linux.ATSPi_Application` is the first Application interface method layer.
It validates session/object-path identity and defunct state before returning
bounded D-Bus-compatible replies for application ID, toolkit name, version, and
locale metadata. String replies use the configured `Native_String_Size` limit
when routed through `A11y.Linux.ATSPi_Method_Router`. Unknown methods return
structured unsupported-capability errors, and no Ada exception crosses the
method boundary.
The Application method layer validates supplied resource-limit configurations
before object-path resolution or native-facing ID and metadata replies.

`A11y.Linux.ATSPi_Method_Router` is a typed routing scaffold for incoming
interface/method calls. It does not parse raw D-Bus messages or run a transport;
instead it accepts an already-decoded request containing session, object path,
interface, method, and typed arguments, dispatches to the relevant
backend-private method layer, and normalizes the reply family/status. This is
the staging point behind `A11y.Linux.ATSPi_DBus_Boundary`, which validates
bounded strings, admits the object path through `A11y.Native_Identity`, rejects
malformed, cross-session, and out-of-range paths before interface routing,
then applies the common resource-limit configuration to bounded Application,
Accessible string/relation, Component and Selection traversal, Action, Value,
Text, Table traversal, Image, and Document calls. It encodes structured
reply/error families without letting Ada exceptions escape. The D-Bus boundary
introspection helper validates resource-limit configurations before XML payload
construction. The D-Bus message
envelope validates both header and decoded call-body strings before comparing
them for coherence, and decoded string arguments are bounded at the method
Release evidence marker: boundary introspection helper validates resource-limit
configuration before XML construction.
boundary too. Document attribute names and editable-text replacement payloads
therefore cannot force unbounded allocation before semantic routing.
`A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet` composes the same
bounded packet decoder and reply queue with `Dispatch_Registered_Call`, giving
the future live transport loop a packet-level entry point that requires
materialized registry objects and releases native-call pins before queuing the
reply.
`A11y.Linux.ATSPi_Startup.Pump_Registered_One` and
`Pump_Registered_Bounded` lift that same registered packet path to the staged
startup/event-loop owner, preserving pump readiness checks and bounded
iteration counts while enforcing object-registry admission for future live
provider dispatch.

## Windows And macOS Notifications

`A11y.Windows_Backend.UIA_Events` and
`A11y.MacOS_Backend.NSAccessibility_Events` classify committed semantic events
into backend-private notification categories. Both packages reject unsequenced
events and invalid source nodes before creating a publishable emission, retain
semantic sequence/revision metadata, and expose no COM, HWND, Objective-C, or
AppKit types. The same `native.event.validation` conformance feature also
covers the AT-SPI signal scaffold, which rejects unsequenced events, invalid
source nodes, and invalid backend sessions before deriving an object path or
signal name. The AT-SPI signal context overload can also carry semantic tree
projection metadata; hidden event sources return `Node_Unavailable` before a
D-Bus object path or signal detail is built. `native.event.exhaustive_map`
requires the current UIA and
NSAccessibility mappers to produce a deterministic native event/notification for
every semantic event kind before any future ABI bridge posts it.

The event records also carry bounded backend-private detail classifications.
UIA emissions distinguish property, structure, and window change families such
as value changes, child insertion, and window activation. NSAccessibility
emissions distinguish affected accessibility attributes and window lifecycle
families such as selected children, hierarchy changes, and main-window changes.
The macOS platform provider currently consumes these records for the
compatibility publication path after the AppKit process-root host is installed:
it posts root notifications through the installed native host, creates
transient virtual NSAccessibility elements for non-root event sources from the
stable backend element registry, releases those objects after posting, and
acknowledges the semantic event only after a successful native post. Other
native emitters can consume these records after semantic state has already been
committed and published through the common event path.
Linux AT-SPI, Windows UIA, and macOS NSAccessibility also expose
backend-private `Posting_Interest` snapshots for their prepared or outgoing
event queues. These snapshots report length, capacity, overflow, and a next
posting operation so future D-Bus socket adapters, COM drainers, and
Objective-C drainers can decide whether to post, back off, or idle without
duplicating queue policy. Windows and macOS `Dequeue_For_Posting` helpers are
the bridge-facing admission points: overflow back pressure returns
`Resource_Limit` without draining pending native event emissions, and explicit
queue clearing starts a recovery epoch. The conformance identifier is
`native.event.posting_interest`.

## Windows UIA Fragments

`A11y.Windows_Backend.UIA_Fragments` is the first SDK-free fragment provider
projection. It resolves `Parent`, `First_Child`, `Last_Child`, `Next_Sibling`,
and `Previous_Sibling` from `A11y.Trees.Semantic_Tree`, and builds stable
runtime identifier components from backend session identity, fragment-root
identity, and node identity. It rejects defunct snapshots, invalid sessions,
invalid nodes, detached nodes, and nodes hidden by the central exposure
projection before returning native-facing data, including runtime identifiers.
Fragment navigation uses
`A11y.Trees.Exposure_Views`, so flattened semantic nodes do not become native
fragment parents and hidden subtrees are not reachable through sibling or child
navigation. The package does not implement COM; a later ABI layer can wrap
these records inside `IRawElementProviderFragment` methods without owning
semantic state.

`A11y.Windows_Backend.UIA_Request_Router` also gates pattern discovery and
action mapping with the same exposure view when an action-node context is
provided. Hidden semantic nodes therefore cannot advertise UIA patterns or map
semantic actions into native operations even if their immutable action set is
otherwise populated. Relation queries use a separate relation exposure context:
hidden relation sources return `Node_Unavailable`, and hidden relation targets
are filtered before target-count bounds and native relation replies are chosen.
Event-emission routing carries an event-source exposure context too, so hidden
semantic sources cannot produce native UIA notifications after internal semantic
event publication. Property, fragment/hierarchy, selection, table, and surface
routes receive the router bundle's current resource limits for exposure
traversal instead of relying on stale mapper snapshot defaults. These router
gates are declared under
`native.projection.action`, `native.projection.relation`, and
`native.projection.event_source`; core property projection is declared under
`native.projection.property`.

`A11y.Windows_Backend.UIA_Provider_Boundary` can admit an incoming native
runtime-id node component before dispatching to the router. The component is
decoded through `A11y.Native_Identity`, checked against the active fragment
session, and compared with the request's primary semantic node. Malformed,
cross-session, mismatched, or unavailable identities return
`UIA_E_ELEMENTNOTAVAILABLE` without invoking provider routing.

## macOS NSAccessibility Hierarchy

`A11y.MacOS_Backend.NSAccessibility_Hierarchy` is the Objective-C-free virtual
element hierarchy projection. It derives parent, child list, indexed child, and
stable element identity components from the semantic tree, backend session, and
`Node_Id` values. It rejects invalid sessions, detached nodes, and defunct
snapshots before returning native-facing data. Parent, child, indexed-child, and
element-identity queries use `A11y.Trees.Exposure_Views`; hidden current nodes
return `Node_Unavailable`, flattened nodes are skipped as parents, and hidden
subtrees are not materialized as virtual elements. A later Objective-C bridge can
translate these records into `NSAccessibilityParentAttribute`,
`NSAccessibilityChildrenAttribute`, and virtual element identity bookkeeping
without owning provider state.

`A11y.MacOS_Backend.NSAccessibility_Request_Router` applies the same optional
action-node exposure context to action-set discovery and action mapping. Hidden
semantic nodes do not produce native action lists or native action mappings for
the Objective-C bridge. Relation attribute routing also carries its own
tree exposure context so hidden sources fail safely and hidden targets are not
materialized as native relation attribute values. Notification routing gates the
semantic event source through the central exposure view before building a
native-shaped NSAccessibility notification record. These gates share the same
`native.projection.*` conformance identifiers as UIA.

`A11y.MacOS_Backend.NSAccessibility_Provider_Boundary` performs the same
optional native identity admission for virtual element ids. Incoming element
components are decoded through `A11y.Native_Identity`, checked against the
active hierarchy session, and matched to the request's primary semantic node.
Malformed, cross-session, mismatched, or unavailable identities return
`Native_Element_Unavailable` before selector-shaped routing begins.

## Linux AT-SPI Accessible Projection

`A11y.Linux.ATSPi_Accessible` keeps the protocol-facing `GetChildCount` method
compatible with precomputed child-count snapshots, `GetChildAtIndex` returns
stable semantic child identities for indexed traversal, `GetChildren` returns
the bounded object-reference array for the same projected child list,
`GetParent` returns the nearest exposed semantic ancestor, and
`GetIndexInParent` computes a signed index in that projected parent. Snapshots
may also carry a semantic tree plus exposure metadata. When tree projection is
enabled, these methods use
`A11y.Trees.Exposure_Views` and the configured resource limits to expose only
externally visible traversal targets. Hidden current nodes return a structured
AT-SPI object-unavailable error, flattened descendants
contribute to the exposed child list, and hidden subtrees do not affect counts
or indexed lookups. `GetRelationSet` uses the same predicate when projection is
enabled, so detached or hidden targets are not externally observable through
AT-SPI relation arrays. The D-Bus layer still receives only typed replies and
structured failures; it does not own semantic exposure policy. The indexed
lookup is tracked as `linux.atspi.accessible.child_at` and
`linux.atspi.accessible.children`.

For external traversal beyond a single root object, prepared Accessible
snapshots may carry an `A11y.Semantic_Snapshots.Semantic_Snapshot`. That sparse
metadata view records per-node role, name, description, state, capability, and
exposure information keyed by stable `Node_Id`. AT-SPI object paths still derive
only from backend session identity plus `Node_Id`; the protocol object does not
own application semantics. If a child path is queried without corresponding
metadata, the Accessible layer returns a structured node-unavailable result
rather than falling back to stale root metadata.

Accessible interface listing is likewise semantic-first. `GetInterfaces`
returns the base Accessible and Component interfaces, adds Application for the
semantic application root role, and adds optional AT-SPI interfaces only from
the immutable neutral capability set. The conformance identifier is
`linux.atspi.accessible.interfaces`.

Accessible role-name methods are intentionally derived from
`A11y.Roles.Stable_Name`. `GetRoleName` and the current
`GetLocalizedRoleName` implementation therefore report the authoritative
platform-neutral semantic role name, with localized wording reserved for a
future catalog-backed role-description layer.

`GetApplication` is an object-reference method over the same stable identity
space as child and parent traversal. It returns the semantic application root
from the snapshot and lets the D-Bus reply builder encode that `Node_Id` as a
session-scoped AT-SPI object path; missing roots are structured
node-unavailable failures.

## Diagnostics

`A11y.Diagnostics` stores structured diagnostic records with stable identifiers,
severity, subsystem category, optional `Node_Id`, event sequence context,
diagnostic timestamp, optional conformance feature identifier, bounded
structured key/value fields, and redaction status. Diagnostic categories have
stable metadata names and default severities so tooling and reports do not
depend on localized or free-form text. Field keys must be non-empty, field
counts are capped, and field key/value text is bounded by diagnostic maxima and
can be tightened with `A11y.Resource_Limits.Native_String_Size`.
`A11y.Localization` is the catalog-backed rendering boundary for user-visible
diagnostic category and result status labels. It uses the repository `messages`
crate through the Alire-resolved `messages.gpr`; stable diagnostic records
continue to store identifiers, categories, and structured fields rather than
localized prose.
The conformance identifier is `diagnostics.localization`.
Diagnostic append also requires a non-empty stable identifier and bounds both
the identifier and optional feature identifier before retaining the record. The
append path revalidates field keys and values as well, so direct public record
aggregates cannot bypass the configured diagnostic string bounds.
`A11y.Diagnostics.Has_Field` provides bounded structured key and key/value
lookup for tooling that needs to classify diagnostic context without parsing
free-form text. The conformance identifier is `diagnostics.field_bounds`.
`Diagnostic_Log` defaults to `Max_Diagnostics`, can be configured directly or
from `A11y.Resource_Limits.Diagnostic_Trace_Size`, reports `Resource_Limit` on
overflow or overlong retained metadata, and rate-limits repeated adjacent
diagnostics without losing the count of dropped records. Null, disabled, and
native backend scaffolds store
diagnostics through this log and expose compatibility snapshots through the
common backend API.
Null Backend event validation diagnostics include the safe `Node_Id`, stable
event-kind name, and event sequence when available, so conformance tooling can
classify stale-reference, lifecycle, and ordering failures without parsing
localized text.
Disabled backend ignored-event diagnostics and native backend publication
diagnostics use the same safe event context for validated semantic events,
including the `Node_Id`, event kind, sequence, and structured result status
where relevant. They do not include native handles or provider pointers.
`A11y.Diagnostics.Category_For_Status` and `Severity_For_Status` centralize how
structured `A11y.Results` statuses become diagnostic categories and severities,
so native backends classify timeouts, stale native references, unsupported
capabilities, resource limits, shutdown, allocation, and ABI-boundary failures
consistently. The conformance identifier is `diagnostics.result_mapping`.

Free-form text is not the primary representation, and redaction metadata is
kept with every record.

## Fixture

The child test crate includes `A11y_Test_Fixtures`, a deterministic semantic
fixture model. It uses stable predefined `Node_Id` values and includes
representative application, window, dialog, group, text, button, toggle,
checkbox, radio, text field, password field, slider, progress, spin button,
list, tree, table row/column/cell, combo box, search field, menu, tab,
tooltip, status/live region, document heading/content/link, informative image,
decorative image, validation alert, popup, and modal surface nodes.

The fixture also defines a scripted command vocabulary for focus movement,
activation, toggling, expand/collapse, selection, menu show/dismiss,
text/value/property/relation changes, caret movement, node insertion/removal
and reordering, window open/close, announcements, node destruction, and
shutdown. It is portable test data; native integration client processes are
still future work.

## Relation Graph

`A11y.Relations.Relation_Graph` stores relation targets by `Node_Id` and derives
inverse relations automatically. Removing a node deletes relations sourced from
that node and removes it from other target lists, preventing dangling relation
targets from becoming observable.

`A11y.Relations` also owns stable relation identifiers and inverse-pair
metadata. Backend mappers translate these committed relation kinds into native
relation properties or attributes, and relation graph operations use the same
metadata to derive inverse edges.
Allowed relation cycles remain observable to validators through
`Has_Cycle` and `Has_Any_Cycle`; these diagnostics do not reject or rewrite the
semantic graph, and inverse-pair edges are not collapsed into false same-kind
cycles.

## Null Backend

The Null backend is a first-class backend, not a discard sink. Its current
checks include:

* backend lifecycle ordering;
* strictly increasing event sequence numbers;
* nondecreasing event timestamps for direct publication and replay;
* nondecreasing semantic revisions for direct publication and replay;
* valid event source identities;
* bounded per-node event lifecycle tracking for create, attach, detach, and
  destroy ordering;
* rejection of non-lifecycle events for nodes that are created but not yet
  attached, or already detached;
* bounded event history configured by
  `A11y.Resource_Limits.Event_Queue_Size`;
* shared resource-limit validation before reconfiguration, preserving the
  previous event-history capacity on invalid configurations;
* rejection of duplicate `Node_Destroyed` events;
* rejection of events after `Node_Destroyed`;
* structured diagnostics for conformance failures and overflow, including
  stable node and event context for event-validation failures.

Future phases should extend it into the canonical semantic conformance backend
before native backend support is advertised.

Backends expose machine-readable support declarations through
`A11y.Backends.Support_Declarations`. The Null backend returns generated
`Internal_Only` declarations for all current portable features.
`tests/bin/capability_matrix` renders those declarations as Markdown by
default and as JSON with `--json`. The JSON report schema identifier is
`org.a11y.capability_matrix.v1`; each declaration record contains the dotted
feature identifier, backend name, support level, native mapping note, and test
identifier. `tests/bin/release_check` consumes the same declarations as an
Ada release gate: it rejects duplicate backend/feature claims, empty mapping or
test evidence, malformed feature identifiers, missing native projection claims,
stale generated capability JSON, and unexpected Disabled-backend support beyond
the documented diagnostic and event-envelope exceptions. Both tools render
through `A11y_Tool_Reports`, so release validation covers the same report body
that the matrix tool prints. The release gate also validates capability JSON
field completeness, support-level vocabulary, backend-family coverage, and
disabled-backend unsupported evidence.

`tests/bin/release_qualification` emits the manual assistive-technology smoke
test checklist in Markdown by default and as JSON with `--json`. Its schema is
`org.a11y.release_qualification.v3`, and each scenario records the platform,
assistive technology, OS version, assistive-technology version, fixture
scenario, exact steps, expected behavior, observed behavior, evidence location,
native probe command, linked conformance feature identifier, known-limitation
field, and machine-readable `qualification_status`. This keeps
initial Orca, Linux
accessibility-inspector, NVDA, Narrator, VoiceOver, Switch Control, Voice
Control, and macOS Accessibility Inspector qualification evidence in Ada
tooling. `tests/bin/release_check` validates this report's schema, scenario
count, stable first scenario, tree-traversal coverage, protected-text coverage,
and Linux, Windows, macOS, Orca, NVDA, Narrator, VoiceOver, Switch Control, and
Voice Control coverage. It also checks that every scenario carries non-empty
version, native probe command, and a conformance feature identifier that exists
in the generated capability matrix,
steps, expected behavior, observed behavior, evidence, and known-limitation
fields, and that the current scaffold reports all manual qualification
evidence as pending rather than captured through both coverage counts and
per-scenario status. The JSON coverage summary also carries Linux, Windows,
and macOS pending/captured evidence counts, and the Linux AT-SPI evidence
template exposes the current gate status plus required and captured scenario
counts for the `linux_atspi_automated_native_qualification`
readiness blocker. Windows UIA and macOS NSAccessibility evidence templates are
also generated by Ada tooling and release-gated; their required probe flags
include public-client traversal of the exported native object tree, so they
remain pending until real UIA and AX clients observe those trees.

The same release gate validates the current documentation set: README,
architecture, quickstart, security, testing, conformance, backend authoring,
Linux/Windows/macOS backend guides, provider implementation, tree/lifecycle,
threading/dispatcher, events, relations, actions, and the text, value,
selection, table, document/image, window/surface, and resource-limit framework
guides, diagnostics, troubleshooting, contributor and release guides, API
reference, toolkit adapters, and AI-usable implementation notes. Each document
is checked for required section markers so release tooling fails before
essential guidance silently disappears.
`tests/bin/documentation_report` renders the same coverage as Markdown by
default and as JSON with schema
`org.a11y.documentation_report.v1` when invoked with `--json`.

`A11y.Backends` owns stable metadata for backend lifecycle states and backend
kinds. State metadata records whether a backend accepts semantic events and
whether the state is terminal; kind metadata records whether the selection
requires a native transport. Backend selection, diagnostics, and release reports
use those identifiers instead of backend-local strings.

## Backend Selection

`A11y.Backends.Selection` parses runtime override names for `default`, `native`,
`null`, `disabled`, and `off`. Native providers are not advertised as available
yet, so `default` preserves the current platform's native backend kind when the
host has a known backend family, while still returning `Backend_Unavailable`
until a real OS transport is connected. Unsupported hosts resolve `default` to
the validating Null backend with the same structured unavailable status.
Explicit `native` requests follow the same target-preserving rule for supported
hosts. This makes fallback explicit without silently claiming OS provider
support.

`A11y.Backends.Disabled_Backends` is distinct from Null. It has deterministic
lifecycle behavior, rejects publication with `Backend_Unavailable`, records
structured diagnostics, and declares all features `Unsupported`. Publish still
validates the semantic event envelope before recording the ignored-event
diagnostic, so malformed events fail with the same structured results as other
backends. It models an intentional accessibility-off mode rather than a
validating conformance backend.

## Native Backend Status

Linux AT-SPI2, Windows UI Automation, and macOS NSAccessibility bodies still
return unavailable by default when no live OS transport has been admitted.
`A11y.Backends.Native_Backends.Target_For_Current_Platform` maps hostkit's
platform classification to the native backend family, and `Create` constructs a
target-specific scaffold with common runtime lifecycle, diagnostics, and
conformance declarations. The native scaffolds remain live-transport
placeholders until their common semantics, Null backend validation, conformance
identifiers, resource bounds, and native integration tests exist. Their publish
boundary validates event envelopes before unavailable-transport rejection; after
adapter-facing transport admission it uses the common runtime event-preparation
path and can return prepared native-publication metadata without claiming native
client interoperability.
