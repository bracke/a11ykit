# Conformance

Conformance is tracked with stable dotted feature identifiers in
`A11y.Conformance`. Each backend declares a support level and evidence fields
for every feature it claims.

## Support Levels

Support levels are `Exact`, `Equivalent`, `Approximate`, `Internal_Only`, and
`Unsupported`. Native backend scaffolds use `Internal_Only` for tested
mapper/router/provider-boundary behavior that is not yet observed through a
live native client.
`Exact`, `Equivalent`, and `Approximate` are production support claims. Release
tooling rejects those levels for AT-SPI, UIA, and NSAccessibility while native
client evidence is incomplete. Linux AT-SPI now has live external-client
evidence for its first native slice and the corresponding
`linux.atspi.live_external_client.*` declarations are `Exact`; Windows UIA now
has native client traversal evidence through its public-client probe. macOS
NSAccessibility remains `blocked_transport_unavailable` until a real macOS
public AX client traverses the exported AppKit element tree through
`native_client_nsax --probe-external-client`. Those probe artifacts are tracked
as central `Internal_Only` feature identifiers. The external-client
probe identifiers are
`windows.uia.external_client.blocked_probe` and
`macos.nsaccessibility.external_client.blocked_probe`. Their ordered
failure-stage identifiers are
`windows.uia.external_client.failure_stage` and
`macos.nsaccessibility.external_client.failure_stage`. The native clients also
record boundary-side traversal fields before the real OS transport is
connected. Windows records COM export, Fragment interface, Fragment navigation,
runtime identifier, and released-interface rejection fields; macOS records
element registration, hierarchy children, child-at-index, element id, and
released-element rejection fields. These fields
improve blocker diagnostics but do not upgrade the conformance status until
real external native clients traverse the OS accessibility APIs. The capability
matrix JSON includes a `summary` object with total declarations, production
claims, `Internal_Only` rows, unsupported rows, native production claims, and
per-native-backend production claim counts. Release checks compare those
counters against `A11y.Conformance.All_Declarations` and require Windows UIA
and macOS NSAccessibility production counts to remain zero until public
native-client traversal is available. The native observation report keeps this
machine-readable through `readiness` and
`native_conformance_ready`; Linux slice evidence alone must not set
`native_conformance_ready` to true while the other native transports and
assistive-technology qualification remain incomplete. It also emits
`readiness_blockers` with the
exact missing native boundary and next required external-client evidence:
`live_atspi_dbus_transport_registration_observed`,
`live_uia_com_provider_export`, and
`live_nsaccessibility_objc_appkit_bridge`.

## Capability Matrix

`tests/bin/capability_matrix` renders declarations as Markdown by default and
JSON with schema `org.a11y.capability_matrix.v1` when invoked with `--json`.
The report includes feature identifier, backend, support level, native mapping,
and test identifier.
Native-client observation evidence is tied to this matrix by release tooling:
each observed `conformance_id` must have a non-`Unsupported` row for at least
one native backend (`AT-SPI`, `UIA`, or `NSAccessibility`). Null Backend
validation rows and Disabled rows document portable behavior, but they cannot
stand in for native backend evidence.

Every public state flag has a corresponding `core.state.*` identifier. The
aggregate rows `core.state.metadata`, `core.state.derivation`, and
`core.state.validation` document the common state framework; per-state rows such
as `core.state.enabled`, `core.state.focused`, `core.state.offscreen`, and
`core.state.defunct` document native projection coverage for individual states.

Every public capability flag has a corresponding `core.capability.*`
identifier. The aggregate `core.capability.metadata` row documents the common
capability vocabulary, while rows such as `core.capability.action`,
`core.capability.text`, `core.capability.selection`, and
`core.capability.surface` document backend interface, pattern, attribute, or
action exposure driven by the central semantic capability set.

Every public value kind and access mode has a corresponding `value.kind.*` or
`value.access.*` identifier. Aggregate rows such as `value.metadata`,
`value.range`, `value.resource_limit`, and `value.precision_loss` document the
common Value Framework; per-kind rows document backend conversion coverage for
unknown, indeterminate, integer, decimal, floating, Boolean, and enumerated
semantic values without collapsing them all to a floating-point representation.

Common action identifiers such as `actions.activate`, `actions.press`,
`actions.toggle`, `actions.expand`, `actions.collapse`, `actions.show_menu`,
`actions.dismiss`, `actions.increment`, `actions.decrement`, `actions.select`,
`actions.deselect`, `actions.clear_selection`, `actions.open`,
`actions.close`, `actions.scroll_into_view`, and `actions.set_focus` are declared
separately from backend mechanism identifiers. This keeps semantic action
coverage visible even when a backend maps the operation through AT-SPI
`DoAction`, a UIA pattern, or an NSAccessibility selector. Native action
request payload retention is tracked separately as
`native.request.action_payload`, proving the backend-private request path keeps
the neutral `Action_Id` instead of recovering semantics from native method
names.
Prepared native event handoff is tracked by
`native.event.prepared_status`, which proves failed event preparation statuses
survive the handoff to AT-SPI, UIA, and NSAccessibility mappers before native
object metadata is interpreted.
Linux D-Bus method-return receive typing is tracked by
`linux.dbus.method_return_decode`, which proves startup reply packets are
decoded as method returns before Hello, accessibility-bus address discovery, or
application-registration completion.
Linux D-Bus error-return receive typing is tracked by
`linux.dbus.error_return_decode`, which proves startup failure packets preserve
bounded native error names and optional message payloads before they are mapped
to common structured results.
Linux D-Bus error-return diagnostics are tracked by
`linux.dbus.error_return_diagnostic`, which proves those native error details
are retained as bounded structured diagnostic fields while optional native
message payloads remain redacted.
Linux D-Bus startup error completion is tracked by
`linux.dbus.startup_error_completion`, which proves decoded error-return
envelopes reach the Hello, GetAddress, or Socket.Embed completion
boundary, consume only matching tracked reply serials, and leave startup state
incomplete on failure.
Linux D-Bus incoming packet classification is tracked by
`linux.dbus.incoming_packet_classification`, which records bounded receive
classification before any tracked reply is completed or method call is
dispatched. The AT-SPI bus handlers use that classification to keep valid
signal, method-return, and error-return packets on a no-dispatch path; only
method-call packets enter provider-facing method routing.
That no-dispatch path is tracked separately by
`linux.dbus.incoming_packet_no_dispatch`, so valid non-method traffic cannot
regress into provider callbacks or fabricated D-Bus replies while ordinary
method-call dispatch remains covered by `linux.dbus.incoming_packet_dispatch`.
Linux D-Bus outgoing back pressure is tracked by
`linux.dbus.outgoing_back_pressure`, which proves overflowed outgoing queues
block all send-admission helpers until an adapter starts an explicit recovery
epoch.
Linux D-Bus transport envelope decoding is tracked by
`linux.dbus.transport_envelope_decode`, which proves received transport packets
are decoded into bounded typed envelopes before startup completion or method
routing observes them.
Linux D-Bus incoming method calls are tracked by
`linux.dbus.incoming_call_decode`, which proves method-call envelopes preserve
interface, member, object path, serial, sender, and bounded body metadata before
they enter the AT-SPI method router.
Linux D-Bus signal envelopes are tracked by `linux.dbus.signal_envelope`, and
prepared outgoing signal envelopes are tracked by
`linux.dbus.prepared_signal_envelope`; together they prove native event
publication uses typed, bounded D-Bus envelopes after semantic events have been
committed. AT-SPI signal build reports are tracked by
`linux.atspi.signal.build_report`, proving the signal layer exposes a bounded
backend-private validation record for envelope validity, source exposure,
prepared-publication metadata, object-path resolution, publishability, and
structured status without leaking native protocol types into common APIs.
Linux D-Bus method dispatch boundaries are tracked by
`linux.dbus.method_boundary`, which proves incoming AT-SPI calls are routed
through the backend-private boundary layer with structured errors and bounded
request payloads.
Linux AT-SPI/D-Bus inverse error-name mapping is tracked by
`linux.atspi.error_name_inverse_map`, which proves known native startup error
returns become the closest common structured `Status_Code` and unknown native
names remain protocol failures.
`linux.atspi.error_name_diagnostic` records those normalized native error names
as bounded diagnostics with explicit native error name, known-name flag, and
common structured status fields.
`linux.dbus.unsupported_value` proves the D-Bus codec has a distinct
unsupported-value sentinel rather than using empty strings, empty object paths,
or fabricated scalar payloads.
`linux.dbus.uint32_array_value` proves unsigned integer array payloads are
bounded by the common native-array resource limit.
`linux.dbus.state_set_uint32_array` proves AT-SPI state-set method returns use
that bounded array validation before D-Bus method-return bytes are produced.
`linux.dbus.string_array_value` proves the D-Bus codec can represent bounded
string-array payloads without unbounded allocation or collapsing them into a
single string.
`linux.dbus.attribute_string_array` proves attribute-set method returns apply
that bounded string-array validation to key/value pairs before byte encoding.
`linux.dbus.cache_interface_string_array` proves cached AT-SPI interface-name
lists apply bounded string-array validation before node projections are
accepted.
`linux.dbus.object_path_array_value` proves object-path array payloads are
bounded and each path is validated before transport encoding.
`linux.dbus.relation_target_object_path_array` proves relation-set method
returns apply that bounded object-path-array validation to target references.
`linux.dbus.startup_pump_report` tracks the Linux startup pump activity report,
which records bounded read/dispatch/write accounting and final outgoing counts
for future hostkit event-loop integration.
`linux.dbus.startup_pump_bounded_report` tracks aggregate bounded pump
accounting, including attempted and completed iterations, per-operation counts,
stop reason, final queue depths, and structured status.
`linux.atspi.live_external_client.failure_stage` tracks the external-client
probe's deterministic failure-stage field. It is diagnostic evidence for
blocked or incomplete live runs and does not claim successful traversal by
itself. The probe records `session_address_supplied` and reports
`session_address_missing` before provider registration when the qualification
environment did not provide a session bus address.
`linux.atspi.live_external_client.registered_transport` tracks the combined
Linux boundary evidence that a live external-client traversal is paired with a
provider startup report whose D-Bus transport registration was observed.
`linux.atspi.live_external_client.component` tracks live external D-Bus client
coverage for `Component.GetExtents`, `Component.Contains`, and
`Component.GetAccessibleAtPoint` against exported semantic nodes.
The same live external-client core slice covers `Accessible.GetRelationSet`:
the probe decodes the native `a(uao)` relation-set reply and verifies a
`Labelled_By` target resolves through the session object-path mapping to the
stable semantic application root.
`linux.atspi.live_external_client.action` tracks live external D-Bus client
coverage for `Action.GetNActions`, `Action.GetName`, and `Action.DoAction`
against exported semantic nodes.
`linux.atspi.live_external_client.value` tracks live external D-Bus client
coverage for `Value.GetCurrentValue`, `Value.GetMinimumValue`,
`Value.GetMaximumValue`, `Value.GetMinimumIncrement`, and
`Value.SetCurrentValue` against exported semantic nodes.
`linux.atspi.live_external_client.selection` tracks live external D-Bus client
coverage for `Selection.GetNSelectedChildren`, `Selection.GetSelectedChild`,
`Selection.IsChildSelected`, `Selection.SelectChild`,
`Selection.DeselectChild`, `Selection.SelectAll`, and
`Selection.ClearSelection` against exported semantic nodes.
`linux.atspi.live_external_client.text` tracks live external D-Bus client
coverage for `Text.GetCharacterCount`, `Text.GetCaretOffset`, and
`Text.GetText` against exported semantic text nodes.
`linux.atspi.live_external_client.image` tracks live external D-Bus client
coverage for `Image.GetImageDescription`, `Image.GetImageCaption`,
`Image.GetImageKind`, and `Image.GetImageSize` against exported semantic image
metadata.
`linux.atspi.live_external_client.document` tracks live external D-Bus client
coverage for `Document.GetLocale`, `Document.IsLandmark`, and
`Document.GetAttributeValue("title")` against exported semantic document
metadata.
`linux.atspi.live_external_client.table` tracks live external D-Bus client
coverage for `Table.GetNRows`, `Table.GetNColumns`, `Table.GetAccessibleAt`,
`Table.GetRowExtentAt`, `Table.GetColumnExtentAt`, `Table.GetCurrentCell`,
`Table.GetSortOrder`, and `Table.GetSortKey` against exported semantic table
metadata.
`linux.atspi.live_external_client.surface` tracks live external D-Bus client
coverage for surface kind, role, top-level/modal, visible, active, and close
capability queries against exported semantic surface metadata.
`linux.atspi.live_external_client.live_region` tracks live external D-Bus
client coverage for live setting, relevant changes, atomic behavior,
assertiveness, and external announcement policy.
Windows UI Automation inverse HRESULT mapping is tracked by
`windows.uia.hresult_inverse_map`, which proves backend-private HRESULT return
classes can be normalized back to common structured statuses without exposing
native error codes through public semantic APIs.
`windows.uia.hresult_diagnostic` records the same native return class as a
bounded, redacted diagnostic with explicit HRESULT name, HRESULT code, and
common structured status fields.
`windows.uia.bridge_audit` tracks the SDK-free C bridge audit contract for
calling convention, nullability, lifetime, and representation rules, including
ephemeral callback frames, nullable native handles, bounded BSTR/SAFEARRAY
values, and stable HRESULT code representation. This is ABI-boundary evidence
only; it does not claim live UIA client traversal.
`windows.uia.native_bridge_binding` tracks the Ada import contract for the
audited C bridge symbols and verifies backend-private ABI scalar sizes without
exposing COM, BSTR, SAFEARRAY, or HRESULT types through common packages.
`windows.uia.com_live.provider_options`,
`windows.uia.com_live.host_raw_element_provider`,
`windows.uia.com_live.embedded_fragment_roots`,
`windows.uia.com_live.fragment_root`,
`windows.uia.com_live.fragment_root_point`, and
`windows.uia.com_live.fragment_root_focus` track SDK-free COM frame dispatch
for `IRawElementProviderSimple.get_ProviderOptions`,
`IRawElementProviderSimple.get_HostRawElementProvider`,
`IRawElementProviderFragment.GetEmbeddedFragmentRoots`,
`IRawElementProviderFragment.get_FragmentRoot`,
`IRawElementProviderFragmentRoot.ElementProviderFromPoint`, and
`IRawElementProviderFragmentRoot.GetFocus`. These are internal-only evidence
until a public UI Automation client observes the same calls through the Windows
UIA runtime.
macOS NSAccessibility inverse native-status mapping is tracked by
`macos.nsaccessibility.native_status_inverse_map`, which proves native
provider-boundary result categories can be normalized back to common
structured statuses without leaking Objective-C or AppKit concepts.
`macos.nsaccessibility.native_status_diagnostic` records those native result
categories as bounded, redacted diagnostics with stable native-status name,
native status token, and common structured status fields.
`macos.nsaccessibility.bridge_audit` tracks the Objective-C bridge audit
contract for calling convention, nullability, lifetime, and representation
rules, including ephemeral selector callback frames, nullable native objects,
released Foundation values, balanced retain/release lifetimes, and bounded
UTF-8/UInt32 Foundation value representations. It also covers the
virtual-element runtime probe used to exercise Objective-C element method
plumbing on macOS. This is ABI-boundary evidence only; it does not claim live
AppKit/AX client traversal.
`macos.nsaccessibility.native_bridge_binding` tracks the Ada import contract for
the audited Objective-C bridge symbols and verifies backend-private ABI scalar
sizes without exposing Foundation, AppKit, Objective-C, or NSAccessibility types
through common packages.
The associated ABI surface also covers bounded selector-frame decoding for
session, element, selector, and indexed-child fields before dispatching through
the registered NSAccessibility element boundary.
`native.runtime.lifecycle_report` tracks the backend-neutral report returned by
native runtime initialize/start/stop report variants: before/after snapshots,
structured status, generation advancement, state/session changes, cache reset,
and event-order reset.
`native.runtime.event_preparation_report` tracks the backend-neutral report
returned by `Prepare_Event_With_Report`: state/generation snapshots, last-event
progress, source and kind, object handoff, defunct state, admission, commit,
and structured status.
`native.runtime.probe_failure_stage` tracks deterministic native client runtime
probe classification for event preparation, native object resolution, boundary
query dispatch, action discovery, action request, payload preservation, and
native call drain stages.
`native.readiness.boundary_stage` tracks the aggregate native observation
report's current boundary-stage classifier. It distinguishes observed live
AT-SPI transport from the current Windows SDK-free COM export chain and macOS
element/AppKit bridge chain that still require public native-client traversal.
`native.readiness.remaining_evidence` tracks the aggregate readiness blocker
classifier emitted by the native observation report. It remains `Internal_Only`
until a platform has live native transport, public client traversal,
vertical-slice coverage, and required assistive-technology qualification
evidence.
`windows.uia.host_window_root_binding` tracks the Windows UIA runtime probe's
deterministic host-window root binding evidence before any live UI Automation
client claim is made. `macos.nsaccessibility.main_thread_binding` and
`macos.nsaccessibility.native_view_binding` track the macOS NSAccessibility
runtime probe's main-thread and native-view binding evidence. These remain
transport-only scaffold evidence while aggregate readiness remains incomplete.
`native.boundary.admission_report` tracks the backend-neutral report returned
by begin-call report variants: requested identity, resolved object and node,
runtime/cache generations, call kind, callback admission, defunct state,
structured status, and return class.
`native.boundary.completion_report` tracks the backend-neutral report returned
by `Complete_Call_With_Report`: before/after snapshots, requested provider
status, final status, status-recording result, callback-release result, release
state, and return class.
`native.boundary.release_report` tracks the backend-neutral report returned by
`End_Call_With_Report`: direct release before/after snapshots, preserved
provider status, callback-release result, release state, and return class.
`native.boundary.request_admission` tracks backend-private rejection of native
entry points that do not match the requested semantic operation before native
objects are pinned or semantic providers are called. UIA currently uses this
for COM provider-interface request admission; NSAccessibility uses it for
method-family request admission.
`events.backend_pump_report` tracks the common event-pump reports returned by
`Pump_One_With_Report` and `Pump_All_With_Report`, including pending counts,
capacity, event identity, validation, publication, acknowledgement, delivery
counts, stop reason, and structured status.
`linux.atspi.serving_packet.stale_error.queued`,
`linux.atspi.serving_packet.stale_error.serialized`,
`linux.atspi.serving_packet.stale_error.decoded`, and
`linux.atspi.serving_packet.stale_error.drained` track the registered
serving-packet stale-object path from native error queueing through serialized
D-Bus output, decoded client observation, and final in-flight bookkeeping
drain.
`linux.atspi.serving_packet.unsupported_interface.queued`,
`linux.atspi.serving_packet.unsupported_interface.serialized`,
`linux.atspi.serving_packet.unsupported_interface.decoded`, and
`linux.atspi.serving_packet.unsupported_interface.drained` provide the same
phase evidence for registered calls that target an unsupported AT-SPI
interface.
`linux.atspi.session_dispatch.boundary_drained` tracks the backend-session
decoded-call entry point's pre-registration rejection path. It proves that a
decoded object-path call is rejected before object resolution/admission and
leaves no outstanding native-call bookkeeping.
`native.fixture_child.parent_navigation` tracks deterministic fixture-child
reverse tree traversal through each backend's native boundary: AT-SPI
`Accessible.GetParent`, UIA fragment parent navigation, and NSAccessibility
parent hierarchy lookup.
`native.fixture_root.second_child` tracks deterministic indexed traversal from
the fixture application root to a second top-level semantic child through
AT-SPI `Accessible.GetChildAtIndex`, UIA fragment last-child navigation, and
NSAccessibility indexed child lookup.
`native.fixture_root.child_count` tracks exact root child-count evidence
through AT-SPI `Accessible.GetChildCount`, UIA first/last child plus
end-of-sibling navigation, and NSAccessibility ordered child collection length.
`native.fixture_child.native_identity` tracks deterministic child native
identity projection through a reversible AT-SPI object path, a UIA runtime id,
and an NSAccessibility element id derived from the same stable semantic
`Node_Id`.
`native.fixture_second_child.parent_navigation` tracks reverse traversal from
the deterministic second top-level fixture child back to the application root
through AT-SPI `Accessible.GetParent`, UIA fragment parent navigation, and
NSAccessibility parent hierarchy lookup.
`native.fixture_second_child.native_identity` tracks deterministic native
identity projection for that second top-level fixture child through a
reversible AT-SPI object path, a UIA runtime id, and an NSAccessibility element
id derived from its stable semantic `Node_Id`.
`native.fixture.sibling_order` tracks deterministic sibling order through each
backend's natural hierarchy mechanism: AT-SPI `GetIndexInParent`, UIA next and
previous fragment sibling navigation, and NSAccessibility ordered children.
Bridge-facing event posting admission is tracked separately from event
preparation. `windows.uia.event_posting_admission` and
`macos.nsaccessibility.event_posting_admission` prove that future native
notification drainers must enter through the bounded queue admission helper,
receive structured `Resource_Limit` during overflow back pressure, and leave
pending events intact until an explicit recovery clear.
`windows.uia.event_posting_report` and
`macos.nsaccessibility.event_posting_report` track the bridge-facing admission
reports, including before/after queue length, capacity, pending and overflow
state, admission and consumption flags, next operation, and structured status.
`windows.uia.event_posting_drain_bounded` and
`macos.nsaccessibility.event_posting_drain_bounded` track the callback-based
bounded drain helpers, including attempt limits, posted counts, stop reasons,
overflow preservation, and empty-queue completion.
`windows.uia.native_callback.hostile_admission` and
`macos.nsaccessibility.native_callback.hostile_admission` track direct native
callback admission probes that reject missing, mismatched, and malformed native
identity before semantic provider routing.
The split rows `windows.uia.native_callback.missing_identity`,
`windows.uia.native_callback.mismatched_identity`,
`windows.uia.native_callback.malformed_identity`,
`macos.nsaccessibility.native_callback.missing_identity`,
`macos.nsaccessibility.native_callback.mismatched_identity`, and
`macos.nsaccessibility.native_callback.malformed_identity` keep those identity
rejection variants independently visible in release evidence.
`windows.uia.native_callback.text_payload_limit` and
`macos.nsaccessibility.native_callback.text_payload_limit` separately track
oversized native text-edit payload rejection at the same boundary before
semantic provider routing.
`windows.uia.event.build_report` and
`macos.nsaccessibility.event.build_report` track backend-private event and
notification build reports, proving raw and prepared semantic events preserve
envelope validity, prepared-publication state, native object resolution,
publishability, and structured status before any native notification is posted.

Common role identifiers include `core.role.button`, `core.role.text_field`,
`core.role.region`, `core.role.tool_bar`, `core.role.slider`,
`core.role.scroll_bar`, `core.role.separator`, `core.role.canvas`,
`core.role.custom`, `core.role.image`, `core.role.status`, and
`core.role.decorative_image`. The image/status rows keep initial-slice role
evidence visible in the capability matrix; decorative-image support records the
semantic omission policy separately from informative image alternative text.
Relation identifiers mirror the public relation graph, including canonical and
inverse directions such as `relations.labelled_by`, `relations.label_for`,
`relations.described_by`, `relations.description_for`,
`relations.controlled_by`, `relations.controller_for`, `relations.flows_to`,
`relations.flows_from`, `relations.member_of`, `relations.details`,
`relations.details_for`, `relations.error_message`, `relations.error_for`,
`relations.embedded_by`, `relations.embeds`, `relations.popup_for`, and
`relations.popup_controlled_by`.
Image metadata uses separate common identifiers for `image.caption` and
`image.category`, so backend routing for captions and stable image-kind names
can be claimed without folding those semantics into generic image text.
Surface metadata similarly exposes `window.surface.kind_name` for stable
neutral surface names independently from native window roles.
Live-region metadata uses `live_region.metadata`,
`live_region.relevance`, and `live_region.backend_routing` to track stable
setting/policy metadata, central relevance-name conversion, and backend-private
native query routing separately from live-region event delivery.

Common property identifiers include `core.property.role`,
`core.property.state_set`, `core.property.name`,
`core.property.visible_title`, `core.property.description`,
`core.property.help_text`, `core.property.placeholder`,
`core.property.value_text`, `core.property.keyboard_shortcut`,
`core.property.semantic_identifier`, `core.property.locale`,
`core.property.set_position`, `core.property.set_size`,
`core.property.hierarchical_level`, `core.property.heading_level`,
`core.property.landmark`, and `core.property.bounds`.
`core.property.typed_results` tracks the common typed
result records for string, integer, boolean, rectangle, role, and state-set
properties. `core.property.status_mapping` tracks the common classification
from structured result status codes into property availability statuses,
including the distinct `resource-limited` property status used when bounded
retrieval rejects otherwise supported content and `permission-denied` when
security policy blocks semantic exposure.
Diagnostic metadata is tracked by `diagnostics.metadata`,
`diagnostics.result_mapping`, `diagnostics.field_bounds`, and
`diagnostics.localization`. The localization feature covers the catalog-backed
rendering boundary for user-visible diagnostic category and result status
labels; retained diagnostic records remain stable structured data.
Textual property support is tracked
separately from property-change events so release evidence can prove native
projection of semantic property values, not just event-envelope handling.
Backend-private metadata projection for the Windows and macOS router slices is
tracked with central feature identifiers:
`windows.uia.metadata_properties`, `windows.uia.protected_value_text`,
`macos.nsaccessibility.metadata_attributes`, and
`macos.nsaccessibility.protected_value_text`. These rows remain
`Internal_Only`; they document semantic-to-native mapper behavior and protected
value denial without claiming live native client support.
Backend-private native generation and reset evidence is split between
`backend.native.transport_generation`, `native.object_cache.generation`,
`native.object_cache.mutation_report`, `native.object_registry.generation`,
`native.object_registry.drained_reset`,
`native.object_registry.mutation_report`,
`native.boundary.native_call_report`,
`native.fixture_root.failure_stage`, `native.runtime.generation`, and
`native.callback.generation`, so transport, cache mutation reports, cache,
registry, drained shutdown reset, registry mutation reports, native-call
mutation reports, fixture-root probe classification, runtime boundary, and callback gate
observations cannot mask each other.
Property-event projection identifiers such as
`events.property.orientation`, `events.property.set_position`,
`events.property.set_size`, and `events.property.hierarchical_level` are
separate from `core.property.*` query support. The current backend-private
query mappers expose `core.property.orientation`,
`core.property.visible_title`,
`core.property.heading_level`, `core.property.landmark`, and structural integer
metadata for AT-SPI Accessible
attributes, UIA properties, and NSAccessibility attributes without making the
native tokens part of the public semantic API.
Event-kind identifiers mirror the public `A11y.Events.Event_Kind` vocabulary,
for example `events.node.created`, `events.property.changed`,
`events.text.inserted`, `events.window.opened`,
`events.document.loaded`, and `events.relation.targets_changed`. These rows
record event-kind validation and native mapper coverage separately from
payload-family rows such as `events.tree.payload` and
`events.relation.payload`.

## Release Gate

`tests/bin/release_check` rejects duplicate declarations, malformed feature
identifiers, missing mapping/test evidence, invalid support-level strings,
stale capability JSON, missing backend families, missing common action rows,
public-surface native API leaks, and native projection claim drift.

## Native Claims

A backend must not claim production native support until common semantics,
Null Backend validation, conformance identifiers, resource/security behavior,
and native integration evidence exist for that feature.
`A11y.Conformance.Native_Production_Claims_Require_Evidence` is the typed
release-gate predicate for this rule: native `Exact`, `Equivalent`, and
`Approximate` declarations require live native evidence; `Internal_Only`
declarations remain valid for bounded scaffolds and mapper/router evidence.

Native scaffold identifiers such as `backend.native.transport_admission` are
`Internal_Only`: they document and test adapter-facing backend boundaries, not
end-user assistive-technology support.
`backend.native.transport_transition_report` records the same layer with
before/after transport snapshots and transition facts for admission, failure,
and stop operations.
`backend.native.deterministic_shutdown` covers the same internal layer: the
shared native backend must clear admitted transport state, stop the native
runtime, and record structured shutdown diagnostics.
