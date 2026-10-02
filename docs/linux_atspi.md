# Linux AT-SPI Backend

The Linux backend projects the semantic model to AT-SPI2 over D-Bus. It does
not depend on GTK, Qt, ATK, or a toolkit accessibility layer.

## Bus Lifecycle

`A11y.Linux.ATSPi_Bus` validates accessibility-bus addresses and stages a
backend session. It does not open a socket itself. Registration returns
`Backend_Unavailable` until a future hostkit-backed transport layer marks the
context connected; after that admission, application registration advances the
staged state deterministically.
`A11y.Linux.ATSPi_Backend_Sessions.Backend_Session` owns the native backend
scaffold, startup controller, object registry, and application root identity as
one lifecycle unit. `Stop` closes startup transport, resets the registry only
when native calls are drained, stops the native backend scaffold, and then
clears the stored application `Node_Id` so stopped reports cannot expose a stale
application root after native objects have been made defunct.
`tests/bin/native_client_atspi` preserves that deterministic static
observation output by default. For live qualification it also supports an
explicit `--probe-address=unix:path=...` mode, with optional `--probe-uid=...`,
that exercises the hostkit-backed local-channel startup path through
authentication, Hello, and application registration before emitting structured
probe JSON. The `--probe-env-address=unix:path=...` variant takes the same
startup path through the backend-private `AT_SPI_BUS_ADDRESS` value parser, so
environment-derived accessibility bus addresses are tested without reading
process environment implicitly. The `--probe-host-env` variant reads host
environment values through `Hostkit.Process.Environment_Value`, reports
redacted source booleans for `AT_SPI_BUS_ADDRESS` and
`DBUS_SESSION_BUS_ADDRESS`, and records `host_discovery_source` as the
normalized source selected for the attempt. It prefers the direct
`AT_SPI_BUS_ADDRESS` parser; when that value is absent, it uses
`DBUS_SESSION_BUS_ADDRESS` to run the staged `org.a11y.Bus.GetAddress`
session-bus discovery path before preparing the application AT-SPI bus. A
deterministic `--probe-boundary` mode
exercises the
session-scoped object-path builder, registered object registry, native-call
pin/drain path, `Accessible.GetRole`, and Action count/name/invocation dispatch
through the registered D-Bus method boundary without depending on a user's
desktop accessibility bus. It reports completion and drained registry state
separately, and includes registered-boundary resolved/admitted/completed flags
plus begin/end outstanding-call counts from the report-producing boundary. The
aggregate native observation report lists this as
`native_client_atspi --probe-boundary` in the
`registered_boundary_probe_command` field.
Incoming D-Bus method-call validation checks supplied resource-limit
configurations before resolving backend session identity, so malformed boundary
policy is reported as a structured invalid-argument failure instead of being
masked by stale or cross-session calls.
D-Bus signal envelope building applies the same policy before checking whether
the semantic signal is publishable, so invalid backend limits cannot be hidden
behind stale or unavailable signal state.

The
deterministic `--probe-fixture-root` mode uses the fixture application
`Node_Id`, materializes a matching AT-SPI object path, dispatches
`Accessible.GetName` through the registered boundary, verifies the fixture root
name payload, reports completion and drained registry state, and emits
`org.a11y.native_client_atspi_fixture_root.v1` JSON. The
`--probe-session-dispatch` mode exercises the backend-session decoded-call
entry point directly and records that unregistered sessions reject object-path
calls without materializing native objects, including session-boundary
resolved/admitted/completed/drained flags and the final structured status. A
deterministic `--probe-serving-packet` mode
exercises the same fixture root through encoded D-Bus method-call and
method-return packets for `Accessible.GetName`, `Application.GetID`,
`Accessible.GetRole`, `Accessible.GetState`, `Accessible.GetChildCount`, and
`Accessible.GetInterfaces`, `Accessible.GetChildAtIndex`, `Accessible.GetChildren`,
`Accessible.GetAttributes`, `Accessible.GetRelationSet`, `Accessible.GetParent`,
`Accessible.GetIndexInParent`, `Action.GetNActions`,
`Action.GetName`, `Action.DoAction`, `Component.GetExtents`,
`Component.Contains`, `Component.GetAccessibleAtPoint`,
`Component.GrabFocus`, `Value.GetCurrentValue`, `Value.GetMinimumValue`,
`Value.GetMaximumValue`,
`Value.GetMinimumIncrement`, `Value.SetCurrentValue`,
`Selection.GetNSelectedChildren`, `Selection.GetSelectedChild`,
`Selection.IsChildSelected`, `Selection.SelectChild`,
`Selection.DeselectChild`, `Selection.SelectAll`,
`Selection.ClearSelection`,
`Text.GetCharacterCount`, `Text.GetCaretOffset`, `Text.GetText`,
`EditableText.InsertText`, `EditableText.DeleteText`,
`EditableText.ReplaceText`, `EditableText.SetTextContents`,
`Image.GetImageDescription`, `Image.GetImageCaption`, and
`Image.GetImageKind`, `Image.GetImageSize`, `Table.GetNRows`,
`Table.GetNColumns`, `Table.GetAccessibleAt`, `Table.GetRowExtentAt`, and
`Table.GetColumnExtentAt`, `Table.GetCurrentCell`, `Table.GetSortOrder`,
`Table.GetSortKey`, `Document.GetLocale`, `Document.IsLandmark`, and
`Document.GetAttributeValue("title")`,
reporting `serving_path_completed` only after registry pins, queued replies,
serialized terminal replies, decoded semantic payloads, no new reply in-flight
work, and final bookkeeping drain have all completed. The `Text.GetText`
packet uses a typed D-Bus `uu` start/end
range body, separate from coordinate-style `ii` component and table requests.
The same release evidence is summarized by
`has_linux_atspi_serving_packet_core_observations`,
`has_linux_atspi_serving_packet_tree_traversal_observation`,
`has_linux_atspi_serving_packet_property_observation`,
`has_linux_atspi_serving_packet_interaction_observations`,
`has_linux_atspi_component_focus_observation`,
`has_linux_atspi_selection_deselect_observation`,
`has_linux_atspi_selection_select_all_observation`,
`has_linux_atspi_selection_clear_observation`,
`has_linux_atspi_serving_packet_content_observations`,
`has_linux_atspi_serving_packet_stale_error_observation`,
`has_linux_atspi_serving_packet_stale_error_queued_observation`,
`has_linux_atspi_serving_packet_stale_error_serialized_observation`,
`has_linux_atspi_serving_packet_stale_error_decoded_observation`,
`has_linux_atspi_serving_packet_stale_error_drained_observation`,
`has_linux_atspi_serving_packet_unsupported_interface_observation`,
`has_linux_atspi_serving_packet_unsupported_interface_queued_observation`,
`has_linux_atspi_serving_packet_unsupported_interface_serialized_observation`,
`has_linux_atspi_serving_packet_unsupported_interface_decoded_observation`,
`has_linux_atspi_serving_packet_unsupported_interface_drained_observation`,
`has_linux_atspi_serving_packet_malformed_packet_observation`,
`has_linux_atspi_serving_packet_text_payload_limit_observation`, and
`has_linux_atspi_serving_packet_full_observations` so packet-level regressions
do not hide behind one aggregate status.
The raw serving-packet JSON also emits
`property_name_method_call_encoded`, `property_name_packet_dispatched`,
`property_name_reply_queued`, `property_name_reply_serialized`,
`property_name_reply_decoded`, and
`property_name_reply_bookkeeping_drained` for the D-Bus
`Properties.Get(Accessible.Name)` `ss` request and variant string reply.
The same raw JSON emits
`property_map_method_call_encoded`, `property_map_packet_dispatched`,
`property_map_reply_queued`, `property_map_reply_serialized`,
`property_map_reply_decoded`, and
`property_map_reply_bookkeeping_drained` for the D-Bus
`Properties.GetAll(Accessible)` `s` request and `a{sv}` property-map reply.
It emits
`accessible_tree_traversal_completed` after the child-count, indexed-child,
children-list, parent, and index-in-parent calls have decoded replies and
drained outgoing bookkeeping. The `reply_in_flight`,
`stale_error_in_flight`, and `unsupported_interface_error_in_flight` fields
prove that successful method returns and structured error returns enter
outgoing serial tracking before `Complete_Outgoing` drains them.
The stale-error observation sends a valid call to an unregistered object path
and requires the stable AT-SPI `NoSuchObject` error while keeping the registry
and outgoing bookkeeping drained.
The phase-specific conformance identifiers
`linux.atspi.serving_packet.stale_error.queued`,
`linux.atspi.serving_packet.stale_error.serialized`,
`linux.atspi.serving_packet.stale_error.decoded`, and
`linux.atspi.serving_packet.stale_error.drained` keep queueing, serialization,
decode, and final bookkeeping evidence independently visible.
The unsupported-interface observation sends a valid registered object-path call
through an unknown AT-SPI interface and requires the stable `NotSupported`
error while keeping registry and outgoing bookkeeping drained.
The phase-specific conformance identifiers
`linux.atspi.serving_packet.unsupported_interface.queued`,
`linux.atspi.serving_packet.unsupported_interface.serialized`,
`linux.atspi.serving_packet.unsupported_interface.decoded`, and
`linux.atspi.serving_packet.unsupported_interface.drained` keep that
unsupported-interface error path independently auditable from queueing through
client decode and drain.
The malformed-packet observation sends invalid packet bytes and requires
classification to fail with `Invalid_Argument` before semantic dispatch,
without queuing a reply or leaving outgoing packets in flight.
The text-payload-limit observation sends an `EditableText.InsertText` packet
whose string argument exceeds a constrained `Native_String_Size`; packet serving
must return `Resource_Limit` before semantic dispatch, without queuing a reply
or leaving outgoing packets in flight.
through an unknown interface and requires stable AT-SPI `NotSupported` while
keeping the registry and outgoing bookkeeping drained.
The `Application.GetID` packet proves that the registered application root is
served through the AT-SPI Application interface over the same encoded packet
path as ordinary Accessible methods.
The `EditableText.InsertText` packet uses a typed D-Bus `uus`
range/replacement body and returns the same boolean request-accepted shape as
other mutating AT-SPI requests. `EditableText.DeleteText` uses the typed
D-Bus `uu` range body and the same boolean reply shape. `ReplaceText` uses the
typed `uus` range/replacement body, while `SetTextContents` uses a typed `s`
replacement body; both return the same boolean reply shape.
`Accessible.GetAttributes` decodes a bounded `a{ss}` payload and
`Accessible.GetRelationSet` decodes bounded `a(uao)` relation entries back to
session-scoped semantic `Node_Id` targets.
Release gate evidence: registered relation-set boundary preservation.
A live
`--probe-session-bus-address=unix:path=...` mode starts one step earlier: it
authenticates to the supplied session bus, completes D-Bus Hello, calls
`org.a11y.Bus.GetAddress`, prepares the discovered accessibility bus address,
and then attempts the same application registration sequence.

## Object Paths

`A11y.Linux.ATSPi_Objects` maps stable `Node_Id` values to valid session-scoped
D-Bus object paths. Paths are not based on Ada addresses and are not reused
within a session.
The AT-SPI object registry wraps those paths with backend-private native
object ids and exposes a monotonic registry generation tracked by
`native.object_registry.generation`. The generation advances on successful
configuration, first object creation, defunct marking, release, and drained
reset. It does not advance for idempotent lookup, descriptor export, path
resolution, stale or cross-session calls, capacity rejection, or rejected
resets. Object and export snapshots carry the generation they were resolved
under so D-Bus boundary diagnostics can identify stale observations without
retaining application provider state.
Incoming D-Bus method handling can pin a resolved object through
`Begin_Native_Call` and `End_Native_Call`. The registry uses the shared
`A11y.Native_Callbacks` gate and the common `Outstanding_Callbacks` resource
limit, so externally triggered D-Bus work is bounded. The gate tracks exact
active callback tokens; copied or replayed D-Bus call contexts are rejected
without draining another call, and the rejected stale context is marked
inactive in the registry report. Pinned calls do not
advance the registry generation, but they do appear in registry snapshots as
`Outstanding_Calls`; checked reset and drained shutdown wait until the calls
complete. A released or defunct object can therefore remain safely represented
as a stale native context without exposing freed provider state.
Bare `Reset` is also drained-aware: while D-Bus object calls are pinned it
leaves tombstones, call counts, and the registry generation unchanged.
`A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call` is the
adapter-facing wrapper for this staged live-backend path: it resolves the
incoming object path through the registry, validates bounded D-Bus interface
and method metadata, then pins the native object for the duration of method
routing. It always releases the pin before returning, rejects unregistered,
stale, or cross-session paths before method dispatch, and rejects unsupported
registered interfaces before native-call admission.
`Dispatch_Registered_Call_With_Report` keeps that compatible reply behavior
while also recording path-resolution status, native-call
admission/completion status, and the begin/end native-call mutation reports
that prove pre-admission protocol rejections never increment outstanding D-Bus
object calls while routed errors still drain admitted calls.
The `native_client_atspi --probe-session-dispatch` JSON surfaces the
backend-session variant of that pre-registration boundary behavior with
`session_boundary_resolved`, `session_boundary_admitted`,
`session_boundary_completed`, `session_boundary_drained`, and
`session_boundary_final_status`. It also performs one bounded event-loop drive
after the rejected call and reports the cached session-level outcome through
`session_event_loop_report_captured`, `session_event_loop_status`,
`session_event_loop_stop_reason`, and `session_event_loop_last_operation`.

## Method Routing

The D-Bus boundary validates object path, interface, method, and payload
fields before producing typed method requests. Backend-private method layers
handle Accessible, Application, Component, Action, Value, Selection, Text,
Table, Image, Document, Surface, Cache, and signal scaffolds.
Accessible and Text method layers validate supplied resource-limit
configurations before object-path resolution or native-facing semantic replies,
including cheap role/character-count queries that would otherwise not allocate
native payloads.
The Application method layer follows the same rule for `Application.GetID`,
toolkit name, version, and locale replies.
Registered semantic object paths also answer
`org.freedesktop.DBus.Introspectable.Introspect` after the same object-registry
resolution and native-call pinning used for AT-SPI methods. The reply is a
bounded D-Bus string containing standard introspection XML for the
backend-private D-Bus introspection interface plus the AT-SPI interfaces
supported by the current immutable semantic role and capability snapshot.
The introspection helper validates the shared resource-limit configuration
before XML construction, so malformed limit state cannot produce native-facing
introspection payloads.
They also answer `org.freedesktop.DBus.Peer.Ping` with a successful empty
method return after the same registry resolution and native-call pinning, so
standard D-Bus liveness probes do not fail before a client reaches AT-SPI
semantic interfaces. `org.freedesktop.DBus.Peer.GetMachineId` returns a
bounded 32-character lowercase hexadecimal backend-session identifier through
the same registered path; it is backend-private compatibility evidence, not a
claim that hostkit has exposed the operating system's global D-Bus machine-id.
Registered objects also implement a bounded
`org.freedesktop.DBus.Properties.Get` slice. The method uses a typed D-Bus
`ss` interface/property request body and returns a typed D-Bus variant. The
current slice exposes `Accessible.Name`, `Accessible.Description`,
`Accessible.Role`, `Accessible.ChildCount`, and application-root
`Application.Id`, `Application.ToolkitName`, `Application.Version`, and
`Application.Locale`. Unknown properties and incompatible interfaces return
structured unsupported-property or unsupported-capability errors instead of
falling back to empty strings or fabricated values.
The same registered path also implements
`org.freedesktop.DBus.Properties.GetAll` for the supported Accessible and
Application property sets. It accepts the standard single-interface `s`
request body and returns a bounded `a{sv}` dictionary whose entries preserve
native variant signatures (`s` for strings and `u` for unsigned integer
properties) rather than flattening the property map into text.
The current serving-path evidence covers a registered object receiving an
encoded method-call packet, resolving it through the object registry, routing
it against the committed semantic snapshot, and carrying the semantic result
from that encoded method-call packet to a queued and serialized method-return packet.
That test decodes the returned packet and verifies the semantic string payload
plus drained reply bookkeeping; it is still a bounded in-process transport-path
test, not a live accessibility-bus qualification claim.
The live external-client slice is exercised by
`native_client_atspi --probe-external-client-host-env`. That probe resolves
`AT_SPI_BUS_ADDRESS` or `DBUS_SESSION_BUS_ADDRESS` through hostkit; when neither
is present, it reports `failure_stage` = `session_address_missing` instead of
hiding the qualification problem behind a generic provider-registration
failure. When an address is present, the probe starts a provider through the
session-bus `org.a11y.Bus.GetAddress` path,
opens a separate client connection to the discovered accessibility bus, sends
`Accessible.GetName`, `Accessible.GetRole`, `Accessible.GetChildCount`, and
`Accessible.GetChildAtIndex` to the provider's unique bus name and application
object path, follows the returned main-window child object path, then sends
child `Accessible.GetName`, `Accessible.GetRole`, `Accessible.GetDescription`,
and `Accessible.GetAttributes`. The first attributes call verifies help text,
placeholder text, exposed value text, visible title, keyboard shortcut,
semantic identifier, locale, orientation, and landmark from the child semantic
metadata. The
probe then calls `Component.GetExtents`, `Component.Contains`,
`Component.GetAccessibleAtPoint`, `Action.GetNActions`, `Action.GetName`, and
`Action.DoAction` on the same child object path. It also calls
`Value.GetCurrentValue`, `Value.GetMinimumValue`, `Value.GetMaximumValue`,
`Value.GetMinimumIncrement`, and `Value.SetCurrentValue` against the same
exported semantic value metadata. The same live sequence calls
`Selection.GetNSelectedChildren`, `Selection.GetSelectedChild`,
`Selection.IsChildSelected`, `Selection.SelectChild`,
`Selection.DeselectChild`, `Selection.SelectAll`, and
`Selection.ClearSelection` against the application root's selected child
and `Text.GetCharacterCount`, `Text.GetCaretOffset`, and `Text.GetText`
against the child text metadata. The same live path now calls
`Accessible.GetRelationSet` on the exported child object, decodes the native
`a(uao)` relation-set reply, and verifies that the `Labelled_By` target
resolves back to the stable application-root `Node_Id` through the backend
session object-path mapping. The relation source is resolved from the incoming
registered object path, not from the default accessible snapshot id, so virtual
children expose their own relations while sharing one committed semantic
snapshot bundle. It also calls `Image.GetImageDescription`,
`Image.GetImageCaption`, `Image.GetImageKind`, and `Image.GetImageSize`
against the child image metadata. The image method layer validates supplied
resource-limit configurations before resolving object paths or returning image
metadata. It also calls `Document.GetLocale`,
`Document.IsLandmark`, and `Document.GetAttributeValue("title")` against the
child document metadata. The document method layer validates supplied
resource-limit configurations before resolving object paths or returning
document metadata. It also calls `Table.GetNRows`, `Table.GetNColumns`,
`Table.GetAccessibleAt`, `Table.GetRowExtentAt`, `Table.GetColumnExtentAt`,
`Table.GetCurrentCell`, `Table.GetSortOrder`, and `Table.GetSortKey` against
the child table metadata. It also calls `GetSurfaceKind`, `GetSurfaceRole`,
`IsTopLevel`, `IsModal`, `IsVisible`, `IsActive`, and `CanClose` against the
child surface metadata. It also calls `GetLiveSetting`, `GetLiveRelevant`,
`IsLiveAtomic`, `IsLiveAssertive`, and `IsLiveExternallyAnnounced` against the
child live-region metadata. The live-region method layer validates supplied
resource-limit configurations before resolving object paths or returning
live-region metadata. It then
requires a second
`Accessible.GetAttributes`
reply to keep placeholder text while omitting `accessible-value`. It preserves
the incoming D-Bus sender as the method-return destination and requires
`has_linux_atspi_live_registered_external_client_observation` in generated
native observation reports when provider startup also records
`registration_transport_registration_observed`,
`external_traversal_completed`, `client_reply_name_matched`,
`external_role_matched`, `external_child_count_matched`,
`external_child_at_index_matched`, `external_child_name_matched`,
`external_child_role_matched`, `external_child_description_matched`,
`external_child_attributes_matched`, the per-attribute child flags for help
text, placeholder, value text, visible title, keyboard shortcut, semantic
identifier, locale, orientation, and landmark,
`external_child_relations_matched`,
`external_protected_value_suppressed`, and
`stop_status` = `SUCCESS` in the
`org.a11y.native_client_atspi_external_client_probe.v1` report. The stop report
captures registry live/outstanding counts before and after shutdown to prove
exported native roots and child objects are released before registry reset.

For release hosts that do not already expose a desktop accessibility bus, the
same live path can be qualified against a temporary local D-Bus session bus:

```sh
dbus-daemon --session --nofork --print-address --address=unix:path=/tmp/a11ykit-atspi-test-bus
tests/bin/native_client_atspi --probe-session-bus-address=unix:path=/tmp/a11ykit-atspi-test-bus
DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/a11ykit-atspi-test-bus tests/bin/native_client_atspi --probe-external-client-host-env
```

The successful external-client run must report `status` = `SUCCESS`,
`failure_stage` = `none`, `provider_registered` = `true`,
`client_hello_completed` = `true`, `external_traversal_completed` = `true`,
`external_core_slice_completed` = `true`,
`external_interaction_slice_completed` = `true`,
`external_content_slice_completed` = `true`,
`external_surface_slice_completed` = `true`,
`external_live_region_slice_completed` = `true`,
`external_protected_value_suppressed` = `true`,
`event_loop_registered_method_calls` greater than zero, matching
`event_loop_registered_replies`, and `stop_status` = `SUCCESS`. Restricted
runners that mediate Unix sockets may report `BACKEND_UNAVAILABLE` for the same
commands unless local socket access is explicitly allowed.
Accessible `GetAttributes` projects bounded semantic attribute strings and
structural integers, including help text, placeholder text, exposed value text,
keyboard shortcut, semantic identifier, visible title, locale, orientation,
set position, set size, hierarchical level, heading level, and landmark
metadata.
Password and protected value text remain omitted, unsupported
metadata is omitted instead of fabricated as empty values, and invalid negative
structural integers return structured AT-SPI errors.
Accessible `GetRoleName` and `GetLocalizedRoleName` are routed through the
central semantic role vocabulary. The current localized-role result is the same
stable semantic role name; native localized wording remains a documented future
catalog-backed refinement rather than a production localization claim.
Accessible `GetApplication` returns the stable semantic application root as a
session-scoped AT-SPI object reference. Missing roots fail with a structured
node-unavailable result rather than fabricating a native application object.
Accessible `GetInterfaces` returns bounded D-Bus string arrays containing the
base AT-SPI object interfaces plus interfaces derived from the node's semantic
capability set. Backends do not advertise Action, Text, Value, Selection, Table,
Document, Image, LiveRegion, Surface, or EditableText unless the neutral
capability is present. This support is tracked by
`linux.atspi.accessible.interfaces`.
The cache projection follows the same rule and additionally includes the
Application interface for cached nodes whose neutral role is `Application`;
that role-derived entry is not treated as an optional capability.
Accessible `GetChildCount`, `GetChildAtIndex`, `GetChildren`, `GetParent`, and
`GetIndexInParent` share the central semantic exposure projection. Direct
snapshots may carry explicit parent and child identities plus a signed
parent-index sentinel for roots. Tree-projected snapshots flatten exposed
descendants, omit hidden subtrees, and return stable `Node_Id` targets that the
D-Bus reply builder serializes as session-scoped AT-SPI object paths or bounded
object-path arrays. This support is tracked by
`linux.atspi.accessible.child_count`, `linux.atspi.accessible.child_at`,
`linux.atspi.accessible.children`, `linux.atspi.accessible.parent`, and
`linux.atspi.accessible.index_in_parent`.
Surface routing covers stable kind names, role, AT-SPI state-set, top-level,
modal, visible, active, minimized/maximized/fullscreen, and operation-capability
queries from semantic surface metadata. Surface method routing uses the
method router's configured traversal limits before exposure projection and
validates supplied resource-limit configurations before native-facing surface
metadata replies; invalid, hidden, over-limit, and defunct surfaces return
structured failures rather than fabricated native values.
Live-region method routing resolves stable object paths back to `Node_Id`,
validates supplied resource-limit configurations and neutral live-region
metadata, and returns bounded setting/relevance strings plus atomic, assertive,
and external-announcement flags. Defunct, cross-session, contradictory, invalid
limit, and oversized replies fail with structured AT-SPI errors. The method
router and D-Bus boundary carry those replies as explicit live-region
string/boolean routed kinds before final D-Bus serialization.
The Action method layer validates `DoAction` against the committed semantic
action state snapshot before returning an invocation request, so disabled,
busy, read-only, defunct, or unsupported actions fail with structured AT-SPI
errors instead of entering provider code. Component, Action, and Value method
layers validate supplied resource-limit configurations before resolving object
paths or returning native-facing replies, including geometry, action counts,
and numeric value queries.
The Selection method layer validates `SelectChild` and `DeselectChild` against
the committed semantic selection snapshot before returning a request, so
unsupported selection modes, required-selection preconditions, hidden targets,
and defunct nodes fail without backend-owned selection mutation. It also
validates resource-limit configurations before count, direction, child lookup,
or mutation methods can produce native-facing replies.
Selection mutation replies retain the neutral request kind and stable target
node through method routing and D-Bus reply construction; serialized AT-SPI
replies remain native booleans or object references as required by the protocol.
Action `DoAction` calls resolve native indexes to stable semantic `Action_Id`
values and retain that neutral action internally through method routing and
D-Bus reply construction, while serialized AT-SPI replies expose the native
boolean result.
The Text method layer keeps range and caret semantics in the neutral text
model. Successful `GetText` replies are UTF-8 encoded by the method router
before D-Bus string payload construction, while protected text, hidden nodes,
and invalid ranges fail before any text bytes are exposed. EditableText method
calls retain the validated neutral `Text_Edit_Request` through the method
router, D-Bus boundary, and outgoing D-Bus reply builder; serialized AT-SPI
replies still expose only the native success/failure shape.
Backend-private grapheme helpers use the same object-path, lifecycle,
exposure, protected-text, and edit-precondition checks as the protocol-shaped
Text and EditableText methods. They are fixture/mapper entry points for common
Unicode semantics and do not advertise non-standard AT-SPI method names.
Value `SetCurrentValue` calls follow the same provider-boundary rule: the
neutral requested `Semantic_Value` is retained internally through method
routing and D-Bus reply construction, while the serialized AT-SPI method return
stays a native boolean.
The Table method layer routes logical dimensions, cell lookup, spans, current
cell, sort order, and sort key from the committed `Table_Snapshot`. Node-valued
table metadata (`GetAccessibleAt`, `GetCurrentCell`, and `GetSortKey`) is
filtered through the central exposure projection before returning a stable
`Node_Id`; hidden or missing targets fail with structured node-unavailable
errors rather than fabricated native references. The method layer validates the
configured resource limits before constructing native-facing replies, including
dimension replies that do not otherwise need traversal.
Every public structured `Status_Code` maps to a stable AT-SPI/D-Bus error
name in `A11y.Linux.ATSPi_Objects`; expected conditions such as disabled,
read-only, busy, cancelled, resource-limit, timeout, native-failure, and
internal-failure results do not fall through to Ada exception names or a
generic catch-all. This table is tracked by the `linux.atspi.error_name_map`
conformance identifier.
Incoming AT-SPI/D-Bus error names are mapped back to common structured status
codes by the inverse table tracked as `linux.atspi.error_name_inverse_map`.
Grouped native names use a documented representative status, such as
`Unsupported_Capability` for native not-supported errors and
`Invalid_Argument` for D-Bus invalid-argument errors. Unknown native error
names remain `Protocol_Failure`.
`linux.atspi.error_name_diagnostic` covers the bounded diagnostic helper that
records the native error name, whether it is known to the table, and the
normalized structured status as non-redacted diagnostic fields.
The D-Bus codec also exposes an explicit unsupported-value sentinel tracked by
`linux.dbus.unsupported_value`; unsupported optional native values therefore do
not collapse into empty strings, empty object paths, or fabricated scalar
payloads.
`linux.dbus.uint32_array_value` covers bounded `au` values for transport-level
state, role, and enum-list payloads; array length uses the shared native
resource-limit configuration.
`linux.dbus.state_set_uint32_array` verifies AT-SPI state-set method returns
pass through that bounded `au` validation before method-return bytes are
emitted.
`linux.dbus.string_array_value` covers bounded `as` values for transport-level
attribute, interface, and identifier lists; array length and every item string
use the shared native resource-limit configuration.
`linux.dbus.attribute_string_array` verifies AT-SPI attribute-set method
returns pass key/value strings through that bounded `as` validation before
dictionary payload bytes are emitted.
`linux.dbus.cache_interface_string_array` verifies AT-SPI cache interface
names pass through the same bounded `as` validation before cached node
projections are accepted.
AT-SPI cache projection validates supplied resource-limit configurations before
session checks, object-path construction, or cached text/interface projection.
`linux.dbus.object_path_array_value` covers bounded `ao` values for
transport-level native reference lists and validates every object path before it
can be emitted.
`linux.dbus.relation_target_object_path_array` verifies AT-SPI relation-set
method returns pass relation target references through that bounded `ao`
validation before tuple payload bytes are emitted.

## Exposure Policy

AT-SPI projections use the central exposure view before returning properties,
children, relations, actions, hit-test targets, text, values, or signals.
Hidden source nodes return structured unavailable results.

## Transport Status

Live D-Bus socket management, listener integration, and native client
integration tests remain future work. The Linux backend now has a
backend-private `A11y.Linux.ATSPi_Backend_Sessions.Backend_Session` owner that
keeps the common `Native_Backend`, AT-SPI startup context, object registry, and
resource limits alive together. Startup through either a direct accessibility
bus address or a discovered session-bus address records failures into the common
transport snapshot; a registered pump uses the same owned startup context and
registry, and shutdown closes startup state, drains the registry, and stops the
common runtime deterministically. After successful application registration the
session materializes the semantic application root in the AT-SPI object
registry, so subsequent registered D-Bus calls resolve through the stable
session-scoped object path instead of a parallel startup-only cache.
`Stop_With_Report` exposes the backend-private shutdown ordering without
changing plain `Stop`: it records startup interest before and after stop,
registry snapshots before and after drained reset, transport snapshots before
and after common backend stop, stage status codes, and whether successful
shutdown clears the stored application `Node_Id`.
The owned session also exposes backend-private node export and dispatch helpers.
`Node_Descriptor` materializes a native object descriptor from a stable
`Node_Id` only after registration has completed; before transport admission it
returns `Backend_Unavailable` without allocating an object, and invalid
identities return `Node_Unavailable` before any transport check. The
application-root descriptor and dispatcher are now thin wrappers over that
generic node path. After registration, `Dispatch_Node_Method` routes any
exported semantic node through the same registered D-Bus boundary and
native-call pinning used by the transport pump.
For already-decoded D-Bus method calls, `Dispatch_Registered_Call` is the
session-owned entry point: it rejects calls before registration, verifies that
the decoded call belongs to the session identity assigned during startup, and
then delegates to the registered-call boundary that resolves the object path and
validates bounded D-Bus interface and method metadata before pinning the native
object while the provider query runs. unsupported registered interfaces before native-call admission
return structured D-Bus errors without changing outstanding-call accounting.
`Dispatch_Registered_Call_With_Report` preserves that behavior while carrying
the registered-boundary report through the backend-session guard layer, so
release tooling can distinguish pre-registration rejection from object-path
resolution, native-call admission, routed reply, and final drain status.
The registered boundary drains that native-call pin for both successful routed
method replies and structured routed errors. If an unexpected exception occurs
after admission, it still attempts to end the native call before returning a
structured internal D-Bus error, so malformed or unsupported calls cannot leave
shutdown-visible callback accounting pinned.
The common native backend also has an adapter-facing transport-admission path,
so an admitted AT-SPI scaffold can keep the shared runtime running and prepare
semantic events for native object-cache publication through `Prepare_Publication`.
The signal layer accepts those
prepared records, validates that normal events carry native object-cache
identity, and preserves destruction events without recreating native objects.
`Prepared_Event.Status` carries event-admission and runtime preparation
failures through this handoff, and the AT-SPI signal layer rejects failed
prepared records before interpreting native object metadata.
Release gate evidence: prepared relation-signal detail preservation.
Release gate evidence: prepared focus-signal payload preservation.
Release gate evidence: prepared property-signal detail preservation.
Release gate evidence: prepared state-signal detail preservation.
Release gate evidence: prepared bounds-signal rectangle preservation.
Release gate evidence: prepared value-signal payload preservation.
Release gate evidence: prepared selection-signal payload preservation.
Release gate evidence: prepared node-reference-signal payload preservation.
Release gate evidence: prepared live-region-signal payload preservation.
Release gate evidence: prepared tree-signal payload preservation.
Release gate evidence: prepared table-signal payload preservation.
Release gate evidence: prepared document-signal payload preservation.
Release gate evidence: prepared window-signal payload preservation.
`A11y.Linux.ATSPi_Backend_Adapter` bridges the Linux startup controller to the
common native backend transport snapshot: startup failures are recorded through
`Record_Transport_Failure`, unavailable startup interest does not fake
admission, and a future registered pump-ready startup can admit and start the
shared native runtime without exposing D-Bus handles through public APIs.
`Startup_Synchronization_Report` records the startup interest snapshot, common
native transport state before and after synchronization, whether failure
recording, transport admission, or backend start was attempted, and the final
structured status. `Session_Startup_Report` carries that backend
synchronization report beside the registration-stage report.
This is tracked by `linux.dbus.startup_backend_adapter`.
The `A11y.Linux.ATSPi_Object_Registry` layer binds stable AT-SPI object paths
to the shared native object cache, rejects malformed and cross-session D-Bus
paths, and keeps defunct nodes stale until the drained registry can be reset.
It also exposes an SDK-free object export descriptor for existing native object
ids, carrying the stable session, node, object path, defunct, and released
metadata a future D-Bus object server needs without creating new objects.
Checked reset delegates to the shared native cache, which clears object records
and node indexes deterministically without materializing a temporary full cache
table.
It satisfies the Linux-specific `linux.atspi.object_registry` row and the
common `native.object_cache.identity` conformance row.
The D-Bus message layer can turn publishable signal emissions into bounded
outgoing signal envelopes with stable serials, object paths, and event names;
it can also compose that envelope directly from the runtime's prepared
publication record. The AT-SPI signal layer also provides
`Build_Signal_With_Report`, a backend-private validation path tracked by
`linux.atspi.signal.build_report` that records envelope validity, source
exposure, prepared-publication flags, object-path resolution, publishability,
and structured status while keeping D-Bus details out of public semantic APIs.
It also builds bounded outgoing method-call envelopes and validates the shared resource-limit configuration before accepting outgoing method-call metadata,
including a staged AT-SPI `org.a11y.atspi.Socket.Embed` call carrying the stable
application object reference `(so)`. The staged bus context owns deterministic outgoing
serial allocation after transport admission; serials are nonzero, monotonic
within the context, reset on disconnect, and fail without mutation at overflow.
Registration-call composition can draw from this allocator after first
validating the bounded D-Bus envelope, so malformed or oversized registration
messages do not consume serial numbers. Outgoing D-Bus envelopes can then be
staged in a bounded FIFO queue governed by the shared `Native_Array_Size` limit;
overflow is reported without dropping or reordering already queued messages.
The bus context owns this queue and exposes explicit capacity, overflow,
enqueue, and dequeue operations for registration traffic so a future socket
writer can drain validated messages without reaching back into semantic state.
Before a queued message is handed to the transport writer, the message layer
normalizes it into a bounded transport envelope and revalidates object paths,
interface names, member names, error names, and body signatures under the
configured native string limits. If malformed data is ever found at that
boundary, `Send_Next_Outgoing` fails without marking the serial in flight or
removing the queued message, leaving the adapter free to diagnose, drop, or
retry according to its transport policy.
Method-reply construction also maps local validation failures, object-path
payload failures, and bounded error-reply failures to stable AT-SPI D-Bus error
names, so a hostile or malformed caller does not receive a nameless native
error envelope.
Transport adapters can use
`Send_Next_Outgoing` to peek the next queued message, mark its serial in the
bounded in-flight tracker, and dequeue only after that tracker accepts it.
`A11y.Linux.ATSPi_Local_Channel` is the first hostkit-backed adapter for this
boundary: it extracts and percent-decodes `unix:path=` D-Bus addresses and
Linux `unix:abstract=` D-Bus socket names, rejects malformed or
NUL-containing endpoint escapes, connects through `Hostkit.Local_Channel`
or `Hostkit.Local_Channel.Connect_Abstract`, writes already-built D-Bus packet
bytes, and reads bounded packet bytes for the existing incoming-packet
dispatcher without owning any semantic mapping or D-Bus method policy. Packet
and authentication reads are assembled from hostkit `Receive_Some` calls after
readability waits. They use the shared callback-duration limit, so a live but
silent or partial D-Bus peer returns a structured timeout instead of blocking provider startup indefinitely.
`A11y.Linux.DBus_Auth` stages the D-Bus `EXTERNAL` authentication exchange:
it hex-encodes the decimal user identifier, builds `AUTH EXTERNAL` and `BEGIN`
commands, and classifies CRLF-framed `OK`, `REJECTED`, `ERROR`, and `DATA`
responses. The decoder rejects bare or LF-only response lines, treats `OK`
challenges as mandatory 32-character hex server GUIDs, and treats `DATA`
payloads as bounded even-length hex text; malformed framing or payloads are
rejected before startup state advances. The local-channel adapter composes these steps
with hostkit socket connection and
only marks the transport connected after auth and `BEGIN` succeed. Startup
reports expose the structured `auth_response_status` so rejected credentials,
malformed auth framing, timeouts, and missing transports remain distinguishable
in fixture and native-client evidence. The test
fixture and native probe default their EXTERNAL authentication user id from
`Hostkit.Process.Current_User_Id`; `--atspi-uid=...` and `--probe-uid=...`
remain explicit qualification overrides. a11y does not import `getuid`
directly. The typed boundary matches the 32-bit uid value range used by the
Linux D-Bus `EXTERNAL` mechanism and keeps process-identity acquisition outside
the AT-SPI protocol layer.
After authenticated transport admission, the bus layer can queue
`org.freedesktop.DBus.Hello`, route it through the same bounded outgoing queue,
and complete the matching method-return by checking the in-flight reply serial
before decoding the unique bus name string. Application registration is
attempted only after the unique name is valid. The local-channel adapter also
offers a composed authenticated-connect-through-Hello operation for the future
live backend startup path; failures after transport admission close the channel
and reset the bus context rather than leaving partial `Hello` state exposed.
Live application admission does not call the legacy registry-side
application-registration method. On current AT-SPI services the
`org.a11y.atspi.Registry` object is an event-listener registry; application
admission is performed through `org.a11y.atspi.Socket.Embed` on
`/org/a11y/atspi/accessible/root`. The live startup path marks the application
registered only after the accessibility bus accepts `Hello`, returns a unique
bus name, queues and sends the `(so)` application object reference, and receives
the matching `Socket.Embed` method return.
Outgoing D-Bus method-call frames now include backend-private destination headers
for the live bus-routing calls used during startup:
`org.freedesktop.DBus` for `Hello` and `org.a11y.Bus` for `GetAddress`.
The destination header is encoded only in the Linux D-Bus transport layer and
remains absent from public semantic APIs.
Incoming D-Bus frames also accept backend-private sender headers from real bus
peers. The sender value is bounded and validated by the transport decoder, then
discarded so native peer names do not become part of common semantic state.
The same receive boundary accepts the standard `UNIX_FDS` header only when the
count is zero. Nonzero file-descriptor passing remains unsupported and is
rejected before any semantic dispatch.
`Registration_Startup_Report` records the same composed path stage by stage:
address resolution, selected transport kind, parsed address field count,
filesystem-path versus abstract Unix endpoint class, raw hostkit connection,
EXTERNAL auth send and acceptance, `BEGIN`, transport admission, `Hello`
queue/send/completion, redacted D-Bus unique-name evidence, application
object-path evidence, `Socket.Embed` reply status/error name, application admission completion, final registered
state, pending outgoing work, in-flight outgoing work, and
structured status. This gives live startup
qualification deterministic failure evidence without pretending an unavailable
socket is a registered accessibility bus.
The unique-name evidence records only whether the `Hello` return produced a
name, its bounded length, and whether it has the required `:` bus-name prefix;
the actual `:1.x` value is not copied into fixture, native-client, or diagnostic
output.
The application object-path evidence is similarly redacted: reports expose only
whether a stable path can be built for the application node, its bounded length,
and whether it has the session and node components required by the
Node_Id-derived AT-SPI path scheme. The concrete object path is not copied into
fixture or native-client output.
The report records whether the `Hello` reply was received from the native
socket, the reply serial observed in the decoded packet header, and the neutral
completion status. Application registration is a real D-Bus startup step:
`registration_application_queued`, `registration_application_sent`,
`registration_application_reply_received`,
`registration_application_reply_serial`,
`registration_application_reply_was_error_return`,
`registration_application_reply_status`, and
`registration_application_completed` describe the AT-SPI registration method
call and reply. The error-return flag is the stable primary classification for
a native rejection; the native error name remains bounded diagnostic detail.
The context is marked registered only after
`Complete_Application_Registration` accepts that reply. A live startup failure
can therefore distinguish absent transport, unreadable socket, malformed reply
bytes, mismatched in-flight serials, native registration rejection, and semantic
admission rejection.
The same report records `registration_transport_registration_observed` only
after the Socket.Embed reply is accepted, the bus state is `Registered`, and
startup outgoing bookkeeping is drained. Its conformance identifier is
`linux.atspi.live_transport.registration_observed`.
`Start_With_Report` exposes that report at the startup-controller layer, and
`Session_Startup_Report` carries it through `Start_From_Address_With_Report`,
`Start_From_Environment_Value_With_Report`, and
`Start_From_Host_Environment_With_Report`, and
`Start_From_Session_Bus_Address_With_Report` with backend synchronization and
application-root export flags. Backend synchronization includes before/after
native transport snapshots and admission/start/failure-attempt flags so release
qualification can distinguish a real registered startup from an unavailable
startup that correctly avoided fake transport admission. The session report also records the normalized
startup source (`direct_address`, `environment_value`, `at_spi_bus_address`,
`dbus_session_bus_address`, `missing_host_environment`, or
`session_bus_address`) and redacted host-environment presence booleans. A
failed live transport therefore remains visible as a prepared address plus
failed registration path, while missing or malformed environment values and
session-bus discovery failures remain distinct pre-registration failures rather
than invented application roots. For the session-bus fallback, the report also
carries `startup_discovery_attempted`,
`startup_discovery_get_address_reply_status`,
`startup_discovery_get_address_reply_error_name`, and
`startup_discovery_get_address_completed` before any application-bus
registration fields.
Address discovery is staged as a backend-private normalization step for the
`AT_SPI_BUS_ADDRESS` value. `A11y.Linux.ATSPi_Address_Discovery` validates the
value with the common D-Bus address parser and preserves the distinction between
missing, malformed, and resource-limited address sources. `A11y.Linux.
ATSPi_Startup.Prepare_From_Environment_Value` prepares from that normalized
source, and the compatibility `Prepare_From_Host_Environment` entrypoint reads
the live `AT_SPI_BUS_ADDRESS` value through
`Hostkit.Process.Environment_Value` before using the same parser. The
session-aware overload first tries `AT_SPI_BUS_ADDRESS`; when it is absent, it
reads `DBUS_SESSION_BUS_ADDRESS` through hostkit and performs the staged
`org.a11y.Bus.GetAddress` discovery sequence before preparing the application
AT-SPI bus. a11y does not import `Ada.Environment_Variables` in production
backend code. The conformance identifiers are
`linux.dbus.address_discovery` for value normalization and
`linux.dbus.host_environment_startup` for the hostkit-backed live environment
entrypoint. The same package also stages the session-bus
fallback: after a caller has connected to the D-Bus session bus, it queues
`org.a11y.Bus.GetAddress` on `/org/a11y/bus`, tracks the call in the ordinary
outgoing/in-flight machinery, and completes the string reply into a validated
AT-SPI bus address. Unknown reply serials are rejected before body decoding, and
malformed address replies complete the transport call and return a structured
invalid-address result rather than leaving stale in-flight state. The
conformance identifier is `linux.dbus.a11y_bus_get_address`.
`A11y.Linux.ATSPi_Local_Channel` composes the live session-bus side of that
sequence through authenticated connect, D-Bus `Hello`, `GetAddress`, reply
decode, and deterministic cleanup under
`linux.dbus.authenticated_get_address`; it still expects a caller-supplied
session-bus address when used directly outside the host-environment overload.
`A11y.Linux.ATSPi_Startup.Prepare_From_Session_Bus_Address` uses that composed
operation as a temporary discovery connection, closes the session channel, and
prepares the real AT-SPI application-bus context from the discovered address.
The conformance identifier is `linux.dbus.startup_session_discovery`.
The `native_client_atspi --probe-session-bus-address=...` fixture reports the
same stage fields as direct startup. If the supplied session bus is invalid or
unavailable, `startup_prepared` remains false and all application-bus
registration stages remain false; once discovery succeeds, the report can show
which later registration step failed, including reply serial/status and
pending/in-flight outgoing counts. Raw transport evidence is split into
`discovery_raw_connect_attempted`, `discovery_raw_connect_status`, and
`discovery_raw_connected`, so qualification output distinguishes an attempted
local-channel connection failure from a path that never reached raw transport.
The same probe records
`discovery_get_address_reply_error_name` when the session bus returns a D-Bus
error for `org.a11y.Bus.GetAddress`, so release evidence can distinguish a
missing accessibility-bus service from malformed replies or local transport
failure without exposing native error codes through public semantic APIs.
`A11y.Linux.ATSPi_Startup` is the backend-private owner for this staged startup
lifecycle. It holds the D-Bus bus context and hostkit local channel together,
prepares validated bus addresses, runs the authenticated startup/registration
sequence, exposes only normalized startup state to Linux backend code, and
stops by closing the channel and resetting the bus context.
`Start_With_Report` and the backend-session `_With_Report` startup entry
points expose bounded stage evidence for preparation, raw connection, EXTERNAL
authentication, `Hello`, application registration, backend synchronization,
and application-root export. Fixture startup JSON carries those fields so
failed live attempts can identify the exact native boundary stage without
logging protocol payloads.
It also provides a one-iteration pump for the future live backend loop: after
registration has completed, it receives one bounded D-Bus packet, routes it
through `Handle_Incoming_Packet`, and writes the queued reply through the same
transport path. The pump rejects unregistered contexts before reading from the
channel. `Can_Pump` and `Check_Pump_Ready` expose the same readiness rule for
future hostkit event-loop adapters without performing I/O. The conformance
identifier is `linux.dbus.startup_pump_readiness`.
`Pump_Registered_One` and `Pump_Registered_Bounded` mirror that loop for the
future live provider path, but route decoded packets through
`Handle_Incoming_Registered_Packet` so materialized object identity and
registry call pinning are enforced at startup-pump scope.
`Pump_One_With_Report` and `Pump_Registered_One_With_Report` expose the same
one-iteration operations with a bounded `Pump_Activity_Report`. The report
records whether a read was attempted, whether a packet was received and
dispatched, whether an outgoing reply was written, the final pending and
in-flight outgoing counts, and the structured status. Failed readiness checks
leave all activity flags false, so event-loop adapters can record deterministic
no-work outcomes without comparing queue lengths. The conformance identifier is
`linux.dbus.startup_pump_report`.
For the registered provider path, the activity report also preserves the
packet-serving result details needed by a live event-loop adapter:
whether the incoming packet was a method call, whether a method-return packet
was serialized, whether the object registry drained after dispatch, and the
serialized reply serial plus whether that terminal reply avoided new outgoing
in-flight tracking. It also carries the registered-boundary resolution,
native-call admission, native-call completion, boundary status, and begin/end
outstanding-call counts.
`Pump_Bounded_With_Report` and `Pump_Registered_Bounded_With_Report` aggregate
those one-iteration reports across a caller-supplied limit. The
`Pump_Bounded_Report` records attempted and completed iterations, read,
receive, dispatch, and reply-write counts. For registered provider pumps it
also records registered method-call count, serialized registered replies,
serialized replies that remained terminal outgoing messages, registry-drained
calls, registered-boundary resolved/admitted/completed counts, the last
registered incoming/reply packet metadata, reply serial and in-flight state,
and the last registered-boundary status and outstanding-call counters. The report also
records final outgoing queue depths, a structured status, and a stop reason
(`Invalid_Limit`, `Readiness_Failed`, `No_Readable_Packet`,
`Iteration_Failed`, or `Iteration_Limit_Reached`). A registered pump asks
hostkit whether the local channel is readable before attempting a packet read;
an idle transport therefore stops with `No_Readable_Packet` and success instead
of entering a blocking receive. Existing `Pump_Bounded`
operations delegate to the report-producing variants and preserve their
delivered-count compatibility surface. The conformance identifier is
`linux.dbus.startup_pump_bounded_report`.
`Pump_Bounded` repeats that primitive only up to a caller-supplied
iteration limit and reports how many packets completed, so backend code can
drive small batches without introducing unbounded work. Startup also exposes
pending and in-flight outgoing counts plus `Has_Outgoing_Work`, so an event-loop
adapter can decide whether another bounded pump or write pass is useful without
accessing the private bus context. The conformance identifier is
`linux.dbus.startup_outgoing_work`. `Interest` returns the same bounded
read/write/dispatch snapshot in one record for future hostkit event-loop
adapters and includes the structured readiness status that `Check_Pump_Ready`
would return, plus bounded outgoing capacity and overflow state. It derives
read readiness from a zero-timeout hostkit channel-readability check, so an
open but idle AT-SPI socket reports dispatch capability without claiming that a
packet can be read immediately. It derives write readiness from the bus-level
`Posting_Interest` snapshot, so an overflowed outgoing D-Bus queue reports back
pressure instead of writable readiness. Its conformance identifier is
`linux.dbus.startup_event_loop_interest`. The same snapshot carries a
backend-private next-operation classification (`Wait_For_Transport`,
`Transport_Failed`, `Write_Outgoing`, `Read_And_Dispatch`, or `No_Operation`)
so adapters do not duplicate the readiness and queue policy. Its conformance
identifier is `linux.dbus.startup_event_loop_operation`. It is not yet a
scheduler or host event-loop integration.
`Wait_Writable` gives live event-loop adapters a startup-level hostkit
writable-readiness probe before packet bytes are sent. `Flush_One_Outgoing`
then gives write-ready adapters a startup-level wrapper around the packet
writer. It uses the same bus-level `Posting_Interest` back-pressure guard as the startup interest
snapshot and the local-channel adapter checks hostkit
writability again before handing bytes to the native channel.
`Flush_Bounded_Outgoing` drains at most a caller-supplied number of queued
packets and treats an empty queue as a successful no-op, so adapters can make
bounded opportunistic write passes without reaching into the private bus or
channel records. The conformance identifier is
`linux.dbus.startup_outgoing_flush`.
`A11y.Linux.ATSPi_Backend_Sessions.Wait_Writable`,
`Flush_One_Outgoing`, and `Flush_Bounded_Outgoing` expose that same write-ready
behavior at the backend session boundary. This keeps the same write-ready behavior at the backend
session boundary, next to `Pump_Registered_Bounded`, so
a future hostkit event-loop adapter can drive registered reads and bounded
outgoing writes without accessing private startup, bus, channel, or registry
records.
`Drive_One_Event_Loop_Step` is the first session-level scheduler primitive for
that future adapter: it captures startup interest, performs at most one selected
operation (`Wait_Writable` followed by `Flush_Bounded_Outgoing` with a limit of
one for write readiness, or `Pump_Registered_Bounded` with a limit of one for
read readiness), and returns an `Event_Loop_Step_Report` with before/after
interest, operation, pump report, flush count, write-wait status, write-ready
and write-timeout flags, step stop reason, and
structured status. Idle, back-pressure, unavailable transport, timed-out write
readiness, and
native-failure states are reported without reaching into private bus, channel,
or registry records. The conformance identifier is
`linux.dbus.backend_session_event_loop_step`.
`Drive_Bounded_Event_Loop` builds on the same single-step primitive and gives
fixture applications and future host event-loop adapters one bounded session API
for repeated work. `A11y.Linux.ATSPi_Scheduler` is the backend-private
scheduler adapter over that primitive: it owns the configured iteration and
read-timeout policy, rejects unconfigured or invalid runs, records
`Scheduler_Run_Report`, and leaves the session registry untouched when transport
readiness fails. Its conformance identifier is
`linux.dbus.backend_session_scheduler`. The scheduler also exposes
`Run_One_Transport_Cycle`, a one-shot adapter for future hostkit callbacks that
want the registered dispatch/write report without entering the aggregate
bounded event-loop driver. The scheduler first captures startup interest and
only calls `Serve_One_Transport_Cycle` after the session is registered and
readable. It uses the same scheduler state machine and records
`Transport_Cycle_Run_Report`, including `Interest_Before`, read wait status,
`Interest_After`, read wait status, write wait status, flushed packet count,
and whether a selected wait became readable or writable.
Before startup registration it returns
`Backend_Unavailable` with `Interest_Before.Next_Operation =
Wait_For_Transport`, without read, write, or registry mutation. Its conformance
identifier is
`linux.dbus.backend_session_transport_cycle_scheduler`. The underlying
`Event_Loop_Bounded_Report` aggregates attempted and
completed steps, wait attempts, wait timeouts, readable-wait completions,
write-wait attempts, write attempts, write-ready completions, write timeouts,
flushed packets, the last selected operation, and the full registered pump
report, including terminal registered-reply tracking, registered boundary
admission/completion, and native outstanding-call counters. Invalid iteration
limits fail before I/O, and
readiness failures stop without mutating the AT-SPI object registry. The
bounded report preserves the final scheduler step's status and stop reason
and `Session_Report` exposes the last bounded event-loop report through
`Last_Event_Loop` plus `Has_Event_Loop_Report`, so host adapters and native
client probes can inspect the latest bounded dispatch outcome after a failed
or partial drive without reaching into private startup state.
separately from the aggregate status and stop reason so adapters can explain
why the last step stopped without deriving it from operation/status pairs.
`Serve_Registered_Packet` exposes the same encoded packet serving boundary at
the backend-session level for adapters that already own received D-Bus bytes.
It checks startup registration and channel readiness before packet
classification, so malformed or hostile traffic cannot reach the method router
or object registry until the session has completed native registration. After a
live registered startup, it delegates to the bus-level serializer and returns
the same `Registered_Packet_Serve_Report` used by the startup pump. That report
preserves incoming and reply packet kind, serial, reply-serial, and estimated
reply size so native qualification can prove the exact D-Bus request/reply pair
without inspecting private buffers.
`Serve_One_Transport_Cycle` is the next transport-facing boundary for adapters
that own the session but not the private startup/channel records. It captures
before/after `Event_Loop_Interest`, checks readiness, receives one bounded
packet from the hostkit local channel, dispatches it through registered
object-path serving, serializes the reply, and writes that reply through the
same native channel path. Its `Transport_Serve_Cycle_Report` records which
stages were attempted, captures bounded incoming and reply packet metadata,
embeds the registered packet report, and fails before read, write, or registry
mutation when startup registration has not completed.
The conformance identifier is `linux.dbus.transport_serve_cycle`.
`Complete_Outgoing` is also exposed at the startup and backend-session
boundaries. A live adapter calls it after a served reply packet has either been
written or failed in a way that requires releasing the in-flight serial. Before
transport admission it returns `Backend_Unavailable` and does not mutate the
object registry; after admission it preserves the bus layer's exact serial
completion rules.
`Queue_Event_Signal` is the session-level semantic publication path: it prepares
the event through the native backend, maps the prepared event into one AT-SPI
signal, and queues that signal through startup/bus only after transport
admission. Before admission it rejects with no pending outgoing work.
`Queue_Event_Signal_With_Report` records event-envelope validation, native
semantic source identity, event sequence and revision, native
prepared-publication status, prepared availability/status, the nested
prepared-signal queue report when available, and the final structured status.
Invalid event envelopes are rejected before native publication preparation and
do not add outgoing D-Bus work.
`Queue_Prepared_Event_Signal` is the corresponding payload-preserving path for
events that have already passed the common native-runtime preparation step. It
uses `A11y.Native_Runtimes.Validate_Prepared_Event` during signal building,
validates the embedded event envelope before backend-session registration
checks, and rejects malformed object handoff or conflicting typed payload flags
before resolving AT-SPI object paths, mapping signal details, or adding D-Bus
outgoing work.
`Queue_Prepared_Event_Signal_With_Report` records backend-session registration,
pending outgoing counts before and after, semantic source identity, event
sequence and revision, event-envelope validity, raw prepared status, central
prepared-validation status, object flags, signal build/publishability state,
enqueue admission, and final structured status without exposing D-Bus message
internals.
Adapters that are ready to write bytes should prefer
`Send_Next_Transport_Envelope`, which performs the same ordering checks but
returns the normalized transport envelope directly. `Build_Transport_Frame_Metadata`
then validates the normalized envelope shape and records header field count,
body field count, text byte counts, and a bounded estimated frame size for the
byte-level encoder. `Build_Transport_Frame` serializes the current staged
message shapes into bounded little-endian D-Bus header/body byte strings,
including method calls, method returns, error returns, signals, reply serials,
object-path call-body arguments, and routed method-return payload bodies. It
still stops short of owning a socket or integrating with the live accessibility
bus.
The lower-level `Send_Next_Outgoing` helper follows the same admission rule.
All send helpers first consult the bus-level `Posting_Interest` snapshot; when
the outgoing queue has overflowed, they return `Resource_Limit` and preserve
pending messages until the adapter explicitly calls `Clear_Outgoing_Queue` for
a new recovery epoch. This is tracked by
`linux.dbus.outgoing_back_pressure`. After a message is marked in flight,
dequeue failures or serial mismatches release the admitted serial before
returning a structured failure.
`Send_Next_Transport_Frame` performs the queue peek, envelope validation, frame
byte construction, in-flight admission, and dequeue as one ordered bus-layer
operation. If frame construction exceeds resource limits, the message remains
queued and is not marked in flight. If an internal dequeue consistency failure
occurs after in-flight admission, the bus layer releases the admitted serial
before returning the structured failure so reply tracking cannot retain an
orphaned in-flight message.
`Build_Transport_Packet` and `Send_Next_Transport_Packet` concatenate validated
header and body bytes into the exact bounded packet a future socket writer will
submit. Packet construction does not change queue state by itself; the bus
operation performs packet handoff only after the same ordered send admission,
and any post-admission packet construction failure releases the admitted serial
before returning.
`Send_Next_Packet` is the hostkit local-channel write boundary. It waits for
hostkit channel writability before sending packet bytes. If readiness times out
or hostkit reports a native write failure after the packet has been admitted in
flight, the adapter releases that packet serial through `Complete_Outgoing`
before returning `Timed_Out` or `Native_Failure`, preventing shutdown or reply
tracking from retaining a stranded in-flight serial.
`Decode_Transport_Fixed_Header` provides the first receive-side packet
admission boundary. It validates the exact 16-byte little-endian D-Bus fixed
header, message type, protocol version, serial, body length, header-field byte
length, alignment, and configured packet size before a live local-channel
adapter reads or allocates the variable-length header/body section.
`Receive_Next_Packet` uses that decoder immediately after the exact Hostkit
header read, then `Decode_Transport_Packet_Header` reuses the same fixed-header
path after the remaining bytes arrive so socket traffic and fixture packet
decoding share one admission policy before provider work can be dispatched.
`Decode_Transport_Envelope` then parses the staged header fields emitted by the
current encoder: object path, interface, member, error name, reply serial, body
signature, and object-path body arguments. It rejects duplicate, malformed, or
unsupported fields and revalidates the normalized envelope before it can be
translated into a method-router request.
`Decode_Incoming_Call` is the next receive-side boundary: it accepts only
method-call packets, attaches the current backend session, copies the decoded
object path/interface/member into the AT-SPI method boundary record, preserves
the staged object-path body argument in the decoded argument field, and reuses
the ordinary method-call validator before any dispatcher or provider callback
can run.
`Handle_Incoming_Packet` connects that staged receive boundary to the existing
AT-SPI method router and bounded outgoing reply queue. It requires a connected
or registered transport context, rejects malformed packets before dispatch,
routes only method-call packets through `ATSPi_DBus_Boundary.Dispatch_Call`,
and queues either a method return or structured D-Bus error reply using the
same monotonic serial allocation path as other outgoing messages. Valid signal,
method-return, and error-return packets are accepted as no-dispatch traffic:
they do not call providers, fabricate replies, allocate serials, or complete
tracked outgoing sends.
This valid non-method packet path is tracked by
`linux.dbus.incoming_packet_no_dispatch`.
`Handle_Incoming_Registered_Packet` is the corresponding live-adapter path:
after decoding the same bounded packet format, it routes through
`Dispatch_Registered_Call` so only materialized, session-scoped AT-SPI objects
can be dispatched and every accepted method call is pinned through the object
registry until the queued reply has been prepared. Unsupported methods and
other structured router errors are still drained through the same registered
boundary before the D-Bus error reply is queued.
`Serve_Incoming_Registered_Packet` carries that boundary evidence in its
serve report: the report records path resolution, native-call admission,
native-call completion, boundary status, and the begin/end outstanding-call
counts used by startup pumping to prove a serialized reply did not leave an
object pinned.
`Classify_Incoming_Packet` gives future event-loop adapters a no-mutation
receive classifier: it decodes the bounded D-Bus envelope, reports method-call,
method-return, error-return, or signal packet shape plus serial metadata, and
reports whether a reply serial is currently tracked, while leaving in-flight
reply tracking untouched. The conformance identifier is
`linux.dbus.incoming_packet_classification`.
`Complete_Outgoing` releases that exact serial when a socket write or matching
native reply completes; unknown or duplicate completions fail without mutating
the tracker.
Incoming D-Bus method replies use the same path: `Queue_Method_Reply` validates
the original call and reply envelope, allocates the outgoing serial only after
validation, and stages either a method return or a structured D-Bus error reply
in the bounded queue.
Method-return payload typing is centralized by
`Method_Return_Body_Signature`, which maps each staged AT-SPI routed reply kind
to its D-Bus body signature. `Method_Return_Payload_Bytes` serializes the
current staged scalar, string, object-path, rectangle, size, floating-point,
and state-set reply payload classes with configured array/string bounds.
Relation-set return bodies are encoded as bounded relation-type and stable
object-path target arrays derived from the routed `Node_Id` targets and backend
session.
Incoming method-return packets use `Decode_Method_Return`, which reuses the
transport envelope decoder and then rejects non-return packets, missing
reply-serial metadata, and call/signal/error header fields before live startup
completion code observes the reply body.
Common scalar reply bodies are decoded through bounded helpers:
`Decode_UInt32_Body` and `Decode_Boolean_Body` validate the exact D-Bus body
shape instead of requiring startup or native-client code to parse raw bytes.
Incoming error-return packets use `Decode_Error_Return`, which preserves the
bounded D-Bus error name, reply serial, and optional string message body while
rejecting non-error packets and unexpected call/signal fields before startup
completion code maps the failure to a structured result.
`Diagnostic_For_Error_Return` converts the typed error return into a bounded
structured diagnostic with a stable identifier, reply serial, native error
name, and a redacted optional message field. The diagnostic feature identifier
is `linux.dbus.error_return_diagnostic`.
The local-channel startup path uses an error-aware method-return helper for
Hello and GetAddress replies, so a real D-Bus error return is classified as a
typed error envelope rather than as an untyped malformed method return.
That helper preserves a decoded D-Bus error return as a typed envelope with an
initial successful decode result; the specific Hello or GetAddress completion
boundary then consumes the tracked reply serial and maps the error name to the
final structured status.
Hello completion also consumes matching D-Bus error returns through the
in-flight tracker and maps the bounded error name back to a common structured
status without marking startup state complete. GetAddress completion consumes
matching D-Bus error replies the same way and returns an invalid discovered
address with the mapped common status. Application registration completion
consumes matching registration error returns through the in-flight tracker for
both live startup and the backend-private registration-message builder tests.
The conformance feature identifier for this completion behavior is
`linux.dbus.startup_error_completion`.
Committed semantic events use `Queue_Signal`, which validates the AT-SPI signal
envelope, allocates the outgoing serial only after validation, and stages the
signal for the same adapter-facing send/complete lifecycle.
`Posting_Interest` exposes a no-I/O outgoing-queue snapshot with pending length,
capacity, overflow state, and the next transport operation
(`Send_Next_Message`, `Back_Pressure`, or `No_Posting_Operation`) so socket
adapters can reuse the same bounded queue policy instead of duplicating it.
The D-Bus message envelope validates both header and decoded call-body strings
against the configured native string limit before coherence checks. The incoming
method boundary also validates object paths, interface names, method names, and
decoded string arguments such as document attribute names and editable-text
replacement payloads before routing. Empty method interfaces, method names, and
signal names are rejected as malformed protocol shape rather than accepted as
bounded-but-meaningless strings. Socket writes and bus listener delivery remain
outside this stage.
Current declarations still claim tested mapper/router/bus-lifecycle and
scaffold behavior only, not live D-Bus interoperability.
