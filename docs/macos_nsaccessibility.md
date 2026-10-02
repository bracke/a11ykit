# macOS NSAccessibility Backend

The macOS backend projects the semantic model to method-based
NSAccessibility, AppKit, and virtual accessibility element concepts.
The minimal Objective-C bridge includes `a11y_nsax_bridge_is_macos`, an
ABI-only target-runtime probe used to distinguish a real macOS bridge build
from SDK-free stub runs in portable release logs.

## Main Thread

AppKit-facing operations must execute on the required main-thread context.
Backend-owned tasks that call Foundation or AppKit need appropriate native
runtime setup before live transport support is claimed.

## Element Identity

Native elements resolve to stable `Node_Id` values and backend session state.
Objective-C object addresses are not semantic identity, and stale elements must
become safely defunct without dereferencing application provider state.
Provider-boundary requests that carry a virtual element id are decoded through
`A11y.Native_Identity`, checked against the active hierarchy session, and
rejected as unavailable when the id is malformed, cross-session, mismatched, or
stale before attribute/action routing begins.
`Dispatch_Request` remains the backend-private routing entry point for mapper
tests and already-decoded internal requests. ABI-facing Objective-C selector
callbacks should enter through `Dispatch_Native_Request`, which requires a
native runtime identifier component before dispatching and returns
`Native_Invalid_Argument` with `Invalid_Argument` when a call arrives without
native identity. The deterministic NSAccessibility native-client probes use
this strict entry point, so fixture-root and runtime probe evidence exercises
the same identity-admission rule used by the Objective-C bridge.
`Dispatch_Registered_Native_Request` is the Objective-C-facing registry wrapper
for element ids that already came from the session-local element registry. It
resolves the stable element id, derives the runtime identifier component from
the element's `Node_Id`, admits the selector callback, dispatches through
`Dispatch_Native_Request`, and drains the element call before returning both
successful replies and structured routed errors. If an unexpected exception
occurs after admission, it still attempts to end the native call before
returning `Native_Failed`, so unsupported selector requests cannot leave
shutdown-visible call accounting pinned.
`Dispatch_Registered_Native_Request_With_Report` preserves that behavior while
returning a `Registered_Native_Request_Report` with method-family admission,
element resolution, native identity preparation, begin/end native-call mutation
reports, reply status, and final status. Objective-C bridge tests use this
report to prove unsupported selector families are rejected before admission and
admitted calls are always drained. The registered element boundary validates
the prepared element runtime identity against the semantic snapshot before
begin-call admission; mismatches return `Native_Element_Unavailable` without
pinning the element or dispatching to the provider.
The deterministic native client exposes the same path through
`native_client_nsax --probe-registered-boundary`. The probe creates a
session-local element, invokes a supported action through the registered
boundary, and reports `registered_boundary_report_complete`,
`registered_boundary_method_family_supported`,
`registered_boundary_method_family`, `registered_boundary_request_kind`,
`registered_boundary_resolved_node`, `registered_boundary_resolved_root`,
`registered_boundary_native_node_component`,
`registered_boundary_begin_outstanding_before`,
`registered_boundary_begin_outstanding_after`,
`registered_boundary_end_outstanding_before`, and
`registered_boundary_end_outstanding_after` so release tooling can prove
exact method-family/request routing, stable native identity preparation,
admission, and cleanup without relying on Objective-C-private object
inspection.
The blocked external-client probe additionally initializes the same
native-facing property snapshot used by the NSAccessibility attribute mapper.
It records `metadata_label_preserved`, `metadata_identifier_preserved`,
`metadata_help_preserved`, `metadata_placeholder_preserved`, and
`metadata_detail_preserved`, summarized by `metadata_group_preserved`.
It also sets a protected value-text sentinel and
requires the NSAccessibility `Value_Text` attribute mapper to return a
structured permission-denied result, reported as `protected_value_suppressed`,
with `privacy_boundary_observed` proving that the protected value is suppressed
without mutating semantic state. The same probe reports
`element_chain_observed` for the AppKit bridge, registered element, hierarchy
dispatch, element-id dispatch, release mutation report, tombstone accounting,
direct released-element resolve rejection, and registered-boundary
released-element rejection chain while still reporting
`transport_status = blocked_transport_unavailable`; these fields are mapper
boundary evidence, not a live AX-client support claim.
The same blocked probe now exercises the Objective-C-facing value callback
used by virtual elements. It reports `value_callback_attribute_names_copied`,
`value_callback_title_copied`, `value_callback_frame_copied`, and
`value_callback_action_names_copied` after copying bounded attribute arrays, a
semantic title string, a neutral logical rectangle for `AXFrame`, and bounded
action arrays from the registered native boundary into ABI buffers. These
fields prove that `accessibilityAttributeNames`,
`accessibilityAttributeValue:`, and `accessibilityActionNames` have a real
Ada-backed value path instead of only a dispatch-only selector path. They
remain internal bridge evidence until a public macOS AX client traverses the
exported element tree.
The same probe reports `value_callback_relation_attribute_advertised` when an
exposed semantic relation causes the value callback to advertise its matching
NSAccessibility relation attribute, such as `AXTitleUIElement`, in
`accessibilityAttributeNames`.
The blocked probe also reports `object_callback_children_copied`,
`object_callback_child_at_index_copied`,
`object_callback_relation_targets_copied`,
`object_callback_hit_test_copied`, and
`object_callback_focused_element_copied`. These fields prove that hierarchy,
relation, and identity selectors can route through the registered native
boundary, ensure stable session-local element ids for routed `Node_Id` values,
bind returned elements for main-thread selector dispatch, and copy those
element ids back to the Objective-C shim. The shim turns those ids into virtual
`A11yNSAXElement` objects; it still does not own tree policy, relation policy,
focus policy, hit-test policy, or semantic state.
The derived `internal_native_export_chain_ready` flag combines that element
chain, value-callback marshalling, hierarchy object marshalling, metadata
group, and protected-value privacy boundary so release reports can distinguish
an internally ready bridge from the still-missing external AX client traversal.
The external-client artifact also reports
`macos_nsax_virtual_element_bridge_audited`, which is true only when the
Objective-C virtual-element creation and stable identity matching helpers are
covered by the bridge audit. This is ABI/readiness evidence for
`A11yNSAXElement` plumbing; it is not a substitute for public AX traversal on
macOS.
The same artifact reserves `macos_nsax_virtual_element_runtime_available`,
`macos_nsax_virtual_element_runtime_probe_mask`, and
`macos_nsax_virtual_element_runtime_probe_observed` for a macOS run of the
native runtime probe. The availability bit proves the selected wrapper reached
the real macOS bridge rather than the unsupported stub. The mask uses
backend-private named bits for element creation, identity matching, selector
dispatch, notification dispatch, and release cleanup; Linux stub artifacts
report unavailable, zero, and false.
Accepted artifacts also carry `required_scenario_count`,
`captured_scenario_count`, `pending_scenario_count`, and the nine macOS
scenario booleans used by the release evidence template. Those booleans remain
false until a real public AX client traversal is observed, even when the
backend-private export chain is ready.
The artifact separately reports
`macos_nsax_public_ax_client_runtime_available`,
`macos_nsax_public_ax_client_process_id_available`,
`macos_nsax_public_ax_client_probe_mask`, and
`macos_nsax_public_ax_client_probe_observed`. The public AX probe uses
ApplicationServices AX client calls against the hostkit-provided process id.
Before that client probe runs on macOS, the runtime probe installs a minimal
AppKit process root host: an `NSWindow`/`NSView` shell whose child is an
Ada-backed `A11yNSAXElement`. The Objective-C host contains no role, tree,
action, exposure, or event policy; it only gives the public AX client a native
process/window/view path to the Ada-backed element. The public client probe then
attempts application attribute discovery, application role lookup, window
lookup, window-child lookup, and root-role lookup before cleanup. In the full
external-client artifact, that completed probe is combined with the AppKit
export-chain, metadata, stale-reference, and protected-text checks before the
artifact may report `public_ax_client_traversal_observed = true`.
Run `tests/bin/native_client_nsax --probe-public-ax-client` on macOS to emit
only this smoke result. The full completion artifact still comes from
`tests/bin/native_client_nsax --probe-external-client` or the capture command.
`A11y_NSAX_Native_Runtime_Probes` is the a11y_tests-side wrapper that provides
a no-op unsupported body for non-macOS builds and a macOS body that calls the
audited bridge helper. `tests/nsax_router_tests.gpr` selects the macOS body,
Objective-C source, and AppKit/Foundation/ApplicationServices linkage only for
macOS.
`A11y.MacOS_Backend.NSAccessibility_Public_Roots.Export_Public_Root` is the
backend-private public-root export path used by the blocked external-client
probe. It ensures the semantic root has a registered NSAccessibility element,
binds that element to the AppKit main-thread gate, resolves it back through the
element registry, and builds children, indexed-child, attribute-value, and
action selector frames through the backend-private ABI surface. The probe
reports `macos_nsax_public_root_export_path_observed`,
`macos_nsax_public_root_element_ensured`,
`macos_nsax_public_root_main_thread_bound`,
`macos_nsax_public_root_element_resolved`,
`macos_nsax_public_root_native_node_component_stable`,
`macos_nsax_public_root_children_frame_built`,
`macos_nsax_public_root_child_at_index_frame_built`,
`macos_nsax_public_root_attribute_frame_built`,
`macos_nsax_public_root_attribute_settable_frame_built`, and
`macos_nsax_public_root_action_frame_built`. These fields prove the
Objective-C-free AppKit-facing root export is wired to selector frames; they
also prove the exported element's native node component is derived from the
stable neutral runtime identifier rather than an Objective-C object address.
They do not claim live NSAccessibility support until a public AX client process
traverses the exported element tree through macOS.
The same probe releases the registered element, verifies the release mutation
advanced the registry generation while moving one live element into tombstones,
verifies a direct `Resolve_Element` call returns `Node_Unavailable` for that
tombstoned id, and then retries a native
registered-boundary request. It reports `registered_boundary_element_released`,
`registered_boundary_released_rejected`,
`registered_boundary_released_resolved`,
`registered_boundary_released_admitted`,
`registered_boundary_released_completed`,
`registered_boundary_released_reply_status`, and
`registered_boundary_released_final_status`, proving a released
NSAccessibility element id is rejected before native identity preparation,
call admission, or provider dispatch.
The method descriptor also admits `accessibilityHitTest:` and
`accessibilityFocusedUIElement` through `Copy_Element_Id`. Hit testing carries
the incoming `NSPoint` through the private object callback ABI as bounded
signed coordinates, consults backend-private per-node semantic bounds, and
returns the deepest exposed node whose bounds contain the point. Sibling
conflicts are resolved deterministically in reverse sibling order, matching the
backend's topmost-last projection rule. If no exposed bounded node contains
the point, the callback returns no native object.
Focused-element projection consults the backend-private focused `Node_Id` in
the hierarchy snapshot, verifies that it is attached and externally exposed,
and returns a stable virtual element for that node. If there is no focused
semantic node, the callback returns an empty native object result rather than
falling back to the root or current element.
Editable-text replacement payloads are checked against `Native_String_Size` at
this boundary and rejected as native out-of-resources with structured
`Resource_Limit` before they become semantic text edit requests.
The direct native callback entry point, `Dispatch_Native_Request`, applies the
same checks: missing identities fail as `Native_Invalid_Argument`, mismatched
or malformed native node components fail as `Native_Element_Unavailable`, and
oversized text edit payloads fail before the routed request reaches semantic
providers.
Element scaffolds produce transient native-call contexts from stored
session/root/node identity. AppKit-required calls can demand prior main-thread
binding, and defunct or destroyed elements fail before the future Objective-C
bridge reaches selector-shaped provider routing.
They also provide an Objective-C-free export descriptor with stable
session/root/node identity, native node component, main-thread binding, and
native-view binding metadata. Reading this descriptor does not retain the
element and does not expose AppKit or Foundation objects.
Outstanding native calls are counted explicitly. `Begin_Native_Call` admits a
selector callback and increments the element call count; `End_Native_Call`
validates that the context still belongs to the same session/root/node before
releasing it. A final `Release` while callbacks are still active marks the
element defunct and defers destruction until the last admitted native call
returns, so stale AppKit objects never outlive their safe tombstone state by
dereferencing provider state.
Each admitted selector callback receives a backend-private monotonic token.
`End_Native_Call` validates that token before decrementing the outstanding-call
count, so copied or repeated stale contexts cannot drain a different active
callback. Token accounting keeps an exact backend-private active-token set,
bounded by `Max_Tracked_Native_Calls`, so multi-callback stale releases are
rejected without relying on aggregate counters alone.
Each admitted and successfully released selector callback also advances a
backend-private call generation. Element call snapshots carry the admitted
generation, and stale copied contexts are rejected without advancing it, giving
Objective-C bridge diagnostics a monotonic observation point for copied or
out-of-order callback contexts.
`Drained` exposes the same zero-outstanding-call predicate future AppKit
shutdown code must use before releasing bridge-owned element state.
The session-local element registry assigns stable element ids for
`Node_Id`/semantic-root pairs, returns the same id for repeat lookups, enforces
the native-object cache limit, and leaves released ids as tombstones until the
registry is reset. Element ids are not Objective-C object addresses and are not
reused while a registry session is active. Registry-level `Drained` becomes
true only after all admitted element calls have returned. `Reset_When_Drained`
rejects reset with structured `Busy` while native calls are still
outstanding. Checked reset clears element records and node indexes
deterministically without materializing a temporary full registry table. After
a successful drained reset, both node lookup and stale element-id resolution
return structured `Node_Unavailable` instead of exposing a cleared element slot.
Registry snapshots expose `Outstanding_Calls` for shutdown diagnostics. They
also expose a backend-private registry generation that advances only on
successful configuration, first element creation, defunct marking, release, and
reset; idempotent lookup, native-call admission, stale resolution, rejected
reset, and capacity rejection leave it unchanged. Element record snapshots
carry the registry generation they were resolved under. This
registry satisfies the macOS-specific
`macos.nsaccessibility.element_registry` row and the common
`native.object_cache.identity` conformance row.
Bare `Reset` is also drained-aware: while element calls are pinned it leaves
tombstones, call counts, and the registry generation unchanged.
`Begin_Native_Call_With_Report` and `End_Native_Call_With_Report` wrap the same
callback pinning path with deterministic mutation reports. Reports capture the
before/after registry generation, before/after outstanding-call counts, element
id, backend session, stable node identity, `Require_Main_Thread`, the
element-call snapshot, and whether generation or outstanding-call
counts changed. Failed admission returns an inactive rejected call context and
records no outstanding-call mutation, so shutdown and hostile-callback tests can
distinguish stale elements from leaked native calls.
When an active-looking copied context is rejected as stale, the backend marks
that copied context inactive and clears its native-call token so bridge callers
cannot retry the same stale token indefinitely.
Native-view integration is represented by a backend-private normalized view
component. Elements may bind it only after main-thread binding; rebinding the
same component is idempotent, conflicting components are rejected, and no AppKit
type leaks into the public semantic API.
Hierarchy helpers validate supplied resource-limit configurations before
resolving native-visible parent, child-list, indexed-child, or element-id state,
so malformed backend policy is reported as a structured invalid-argument failure
instead of being masked by defunct or unavailable elements.

## Attributes And Actions

Backend-private mappers translate committed semantic roles, states, properties,
relations, actions, values, selection, text, tables, documents, images, and
surfaces into NSAccessibility attributes, actions, hierarchy, and notification
scaffolds. Live-region and announcement notifications carry the validated
neutral payload, so inactive regions with relevant-change metadata are rejected
consistently with the common semantic model.
Core attribute query routing includes bounded attribute strings, visible-title
metadata, orientation metadata, heading and landmark metadata, structural
integers, booleans, and rectangles without exposing Objective-C types through
public semantic packages. The NSAccessibility property mapper validates
supplied resource-limit configurations before native-facing attribute replies
and attribute-name lists, including integer, boolean, rectangle, and role
replies that do not otherwise allocate native strings.
NSAccessibility structural integer attributes apply `Native_Array_Size` and `Traversal_Depth` before native projection: set position and set size use the native-array ceiling, while hierarchical level and heading level use the traversal-depth ceiling.
The NSAccessibility live-region mapper exposes setting names, stable relevance
names, atomicity, and external-announcement policy from committed semantic
metadata, validates supplied resource-limit configurations before all replies,
uses common native string bounds, and rejects defunct or contradictory
snapshots before any Objective-C-facing conversion. The request router and
provider boundary carry those live-region string/boolean replies without
exposing Objective-C types to the semantic model, and the live-region snapshot
keeps the stable `Node_Id` used by native identity admission.
Value and text mappers also validate supplied resource-limit configurations at
entry, before resolving hidden, defunct, or unavailable semantic nodes, for both
queries and staged mutation requests.
The backend-private request router preserves successful reply payloads instead
of reducing them to reply kinds: attribute strings, integers, booleans, frames,
roles, locale strings, values, staged value-set requests, selection counts, selection mutation request
kinds and `Node_Id` targets, staged action request identifiers, text counts and
neutral wide-text ranges, text edit requests, table counts and cell ids,
relation target replies with the selected NSAccessibility relation attribute,
image descriptions and intrinsic sizes, document metadata, live-region
metadata, and surface metadata. The provider boundary keeps that full
backend-private routed payload alongside the legacy routed-kind field, so the
AppKit bridge can consume the already-dispatched value without asking the
semantic provider again. `NSAccessibility_Native_Callbacks.Copy_Value_Callback`
uses that payload to copy bounded UInt32 arrays for attribute/action names,
UTF-8 for string attributes, scalar booleans/integers, and role codes for the
Objective-C shim. For relation target requests, that preserved payload includes
the selected NSAccessibility relation attribute.
`NSAccessibility_Native_Callbacks.Copy_Object_Callback` uses the hierarchy
payloads to return registered element ids for parent, children, and indexed
child selectors. It does not return Ada addresses or Objective-C object
pointers from Ada; the Objective-C shim receives only bounded UInt64 element id
arrays and creates virtual elements that carry the same session-local callback
context.
Release gate evidence: relation target replies with the selected NSAccessibility relation attribute.
Release gate evidence: preserved payload includes the selected NSAccessibility relation attribute.
Release gate evidence: relation target native-attribute preservation.
Release gate evidence: `Dispatch_Request` remains the backend-private routing entry point.
Release gate evidence: `Dispatch_Native_Request`, which requires a native identity.
Release gate evidence: `Native_Invalid_Argument` with `Invalid_Argument`.
Release gate evidence: `Dispatch_Registered_Native_Request` is the Objective-C-facing registry wrapper.
Release gate evidence: structured routed errors.
Release gate evidence: shutdown-visible call accounting pinned.
Registered element dispatch includes method-family request admission: hierarchy
requests are rejected when they arrive through the attribute method family,
before an element call is pinned or any semantic provider is queried. This is
tracked as `native.boundary.request_admission`.
The deterministic NSAccessibility runtime probe now exercises
table current-cell, sort-order, and sort-key requests through that provider
boundary and verifies the stable `Node_Id` and neutral sort-order payloads
before the native call is drained. It also dispatches document, image,
live-region, and surface metadata queries through the same boundary, preserving
document title and heading level, image alternative text and intrinsic size,
live-region setting and atomicity, and surface kind and active-state payloads.
Surface metadata routing validates supplied resource-limit configurations
before native-facing replies.
The runtime probe also covers value and selection provider-boundary routing:
current values and staged value-set requests preserve neutral `Semantic_Value`
payloads, while selection counts, selected item identities, and staged
selection requests preserve stable `Node_Id` targets. The selection write path
now covers item toggle, select-all, and clear-selection requests, with
`selection_request_payload_preserved`,
`selection_select_all_payload_preserved`, and
`selection_clear_payload_preserved` recorded in the runtime probe JSON. It also
validates resource-limit configurations before selection queries or staged
selection requests can produce native-facing replies. It also records relation
target native-attribute preservation for the selected
NSAccessibility relation attribute.
It also proves main-thread and native-view binding by binding the element to
the required main-thread state, binding a deterministic native-view component,
and reporting `main_thread_bound`, `native_view_bound`, and
`native_view_component` in the runtime probe JSON.
The same runtime probe now exercises selector admission directly through
`A11y.MacOS_Backend.NSAccessibility_ABI_Surface`: successful attribute-value
selector preparation is reported as `selector_attribute_value_prepared`,
unsupported selector rejection is reported as `selector_unsupported_rejected`,
and main-thread selector gating is reported as `selector_main_thread_gated`.
It also routes a registered hierarchy request through the attribute method
family and reports `registered_method_family_mismatch_rejected`, proving that
Objective-C-facing method-family mismatches fail before element call admission
or semantic provider dispatch.
The registered provider-boundary probe also records
`registered_routed_error_status` after a routed semantic error drains, proving
the reply status and final native-call status remain synchronized for expected
NSAccessibility-facing failures.
The same probe preserves native-call lifecycle evidence as data, reporting
`native_call_token`, `native_call_start_generation`,
`native_call_final_generation`, and
`native_call_active_after_completion` after the boundary call drains.
It also routes a focused-state query and a set-focus action through
`A11y.Native_Focus_Calls`, reporting `native_focus_query_dispatched`,
`native_focus_query_payload_preserved`, `native_set_focus_dispatched`, and
`native_set_focus_payload_preserved` without adding NSAccessibility types to
the common focus API.
The normalized native-client report exposes the same boundary evidence through
`has_macos_nsax_native_focus_query_observation`,
`has_macos_nsax_native_set_focus_observation`,
`has_macos_nsax_selection_select_all_observation`, and
`has_macos_nsax_selection_clear_observation`.
Text query routing now includes central grapheme-cluster counts
from `A11y.Text.Grapheme_Cluster_Count`, keeping NSAccessibility text-element
scaffolds aligned with the common Unicode model before native UTF-16 and text
marker conversion. Cluster-based range routing uses `Slice_Grapheme_Clusters`,
so a future AppKit text marker bridge can request grapheme-indexed snapshot
text without duplicating Unicode boundary policy in Objective-C-facing code.
Backend-private grapheme edit helpers use
`Validate_Grapheme_Edit_Request` to preserve the neutral `Text_Edit_Request`
payload for future settable text marker paths without backend-owned semantic
mutation.
Provider boundary admission for action-name discovery validates
the action snapshot `Node_Id`, matching the node used by the router to derive
the immutable NSAccessibility action set.

## Native Values

NSString and NSArray scaffolds enforce common native-value resource limits,
including UInt32 representability for scalar attribute ids and every NSArray
item, and own cleanup deterministically. Router tests cover oversized values,
invalid limits, unavailable nodes, and not-applicable values.
The Objective-C bridge mirrors those bounds at the ABI edge: UTF-8 strings
without a terminator within 65,536 bytes fail before `NSString` allocation, and
UInt32 arrays over 4,096 items fail before `NSArray` allocation.
Virtual NSAccessibility elements can now be created with both a selector
admission callback and a value callback. The selector callback performs
lifecycle and main-thread admission; the value callback returns the already
routed semantic payload for attribute names, scalar attribute values, and
action names. The Objective-C shim converts those bounded payloads to
`NSArray`, `NSString`, `NSNumber`, and `NSValue` rectangle values without
owning semantic policy. Rectangle marshalling is bounded to signed 32-bit
coordinate components at the ABI edge and fails rather than truncating
out-of-range neutral geometry.
Virtual elements can also be created with an object callback for hierarchy and
identity selectors. `accessibilityChildren`, `accessibilityChildAtIndex:`,
relation attributes such as `AXTitleUIElement`, `accessibilityHitTest:`, and
`accessibilityFocusedUIElement` now return virtual elements backed by
registered element ids. Text markers, broader relation attribute coverage,
complete multi-surface coordinate conversion, and global focused-element
discovery remain separate native marshalling work.
Image metadata routing validates supplied resource-limit configurations before
returning descriptions, captions, categories, or intrinsic sizes.
Document metadata routing validates supplied resource-limit configurations
before returning document attributes or pagination metadata.
NSAccessibility value-setting routes are staged as semantic set requests. The
mapper first validates lifecycle, exposure, committed value metadata, resource
limits, numeric type compatibility, range constraints, and read-only policy
through the common `A11y.Values.Validate_Numeric_Set_Request` helper. A
successful route records the requested neutral value for the future
settable-attribute selector path; it does not mutate semantic state directly.
Rejections return structured statuses such as `Read_Only`, `Invalid_Argument`,
`Resource_Limit`, or `Node_Unavailable`.

## Transport Status

The minimal Objective-C bridge exists under `native/macos` and is included only
in macOS builds. Its runtime probes exercise virtual `NSAccessibilityElement`
method dispatch and public ApplicationServices AX client calls against the
current process. The process-root host path now installs a minimal AppKit
window/view root, and `A11yNSAXElement` posts AppKit accessibility
notifications only after the Ada notification boundary admits the native
selector callback. `A11ykit.Provider.Publish` now drains committed semantic
session events after installing that host: it maps each event through
`A11y.MacOS_Backend.NSAccessibility_Events`, posts root events through the
installed AppKit process-root host, creates transient retained virtual
`A11yNSAXElement` objects for non-root event sources from stable element
registry ids, releases those transient objects after posting, and acknowledges
the semantic event only after the native post succeeds. Live public AX traversal
of that hosted tree remains the transport hardening and evidence boundary. The
common native backend has an adapter-facing
transport-admission path, so an admitted
NSAccessibility scaffold can keep the shared runtime running and prepare
semantic events for native object-cache publication through
`Prepare_Publication`. The NSAccessibility event mapper accepts those prepared
records, requires and carries native object-cache identity for normal
notifications, and preserves destruction notifications without recreating native
elements. Current declarations claim tested mapper/router/provider-boundary,
native-call-context, export-descriptor, and element-lifetime scaffolds only, not live
NSAccessibility interoperability. The request router keeps the legacy raw-event
`A11y.MacOS_Backend.NSAccessibility_ABI_Surface` defines the Objective-C-free
selector surface contract for future bridge code. It maps method-based
selectors such as `accessibilityAttributeValue:`,
`accessibilityPerformAction:`, and `accessibilityChildren` to existing
provider-boundary request kinds and method families, requires stable native
identity, rejects unimplemented selector families, and enforces main-thread
binding before selector dispatch. Its conformance identifier is
`macos.nsaccessibility.abi_surface`.
The same surface defines stable numeric selector callback codes through
`Selector_Code` and `Selector_From_Code`; malformed selector codes return
structured `Invalid_Argument` before any provider dispatch, so the Objective-C
bridge does not own selector policy.
`Selector_Frame` and `Dispatch_Selector_Frame` provide the bounded frame shape
for bridge-facing selector calls. They decode session, element, selector, and
indexed-child fields, reject malformed numeric values before provider dispatch,
and then reuse the registered element boundary so native callbacks still pass
through main-thread admission, stable identity checks, lifecycle pinning, and
ordinary semantic request routing. The blocked external-client probe dispatches
`accessibilityChildren` through this frame and records
`hierarchy_children_frame_dispatched` when the selector returns the semantic
child list through the registered native boundary. It also dispatches
`accessibilityChildAtIndex:` through this frame and records
`hierarchy_child_at_index_frame_dispatched` when the indexed selector returns
the same stable child `Node_Id` as the registered child-at-index request. It
dispatches
`accessibilityAttributeValue:` through this frame and records
`attribute_value_frame_dispatched` when the selector returns the semantic title
through the registered native boundary. It also dispatches
`accessibilityIsAttributeSettable:` through a selector frame and records
`attribute_settable_frame_dispatched` when the selector returns the
conservative read-only result used until editable attribute mutation semantics
are surfaced. The bridge then dispatches
`accessibilityPerformAction:` through a selector frame and records
`action_frame_dispatched` when the selector reaches the semantic action route.
The blocked probe's internal export-chain readiness requires this action frame
and the children selector frame in addition to element-chain, metadata, and
protected-value privacy evidence.

`A11y.MacOS_Backend.NSAccessibility_Bridge_Audit` records the finite native
Objective-C bridge operation set. The corresponding
`native/macos/a11y_nsaccessibility_bridge.m` shim is ABI adaptation only:
autorelease-pool creation/drain, retain/release, bounded Foundation value
construction, creation of a minimal `A11yNSAXElement` subclass, virtual-element
identity matching, creation of a minimal AppKit process-root host for public AX
client discovery, virtual-element runtime probing, selector callback entry,
selector-frame callback entry, and notification callback entry. The
`A11yNSAXElement` object stores only stable
session/node identity and the callback context needed to re-enter Ada; its
NSAccessibility methods do not contain role, attribute, action, tree, exposure,
event-coalescing, or provider-dispatch policy. Objective-C exceptions are
contained in the shim, and callbacks re-enter only through Ada bridge-facing
operations that already require main-thread admission and stable native
identity. `a11ykit.gpr` includes `native/macos` and enables Objective-C
compilation for that bridge translation unit only on macOS target builds. The
same macOS branch links AppKit, Foundation, and ApplicationServices for the
bridge. Each audited operation also records machine-readable
calling-convention, nullability, lifetime, and representation rules, including
ephemeral selector callback
frames, nullable native objects, released Foundation values, balanced
retain/release lifetimes, bounded UTF-8/UInt32 Foundation value representations,
caller-owned virtual NSAccessibility elements, and caller-owned AppKit
process-root host objects.
The runtime probe only proves Objective-C element construction, identity
matching, selector method dispatch, notification method dispatch, and release
cleanup inside the bridge; it does not satisfy the separate public AX-client
traversal gate.
`A11y.MacOS_Backend.NSAccessibility_Native_Bridge` is the Ada-side import
contract for those symbols. It exposes only backend-private scalar ABI types,
callback profiles, opaque object addresses, and imported entry points, so common
semantic packages never depend on Objective-C, Foundation, AppKit, or
NSAccessibility types.
`A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Bridge_Entry` ties each
selector to the audited Objective-C bridge operation and imported symbol name
before selector-frame dispatch. Ordinary selectors use the selector-frame
callback entry, while notification posting is explicitly marked as the
notification callback path. The Objective-C method translates backend-private
notification codes to AppKit notification names and calls
`NSAccessibilityPostNotification` only after that callback succeeds.
query path and also accepts prepared records for publication handoff; prepared
notification replies carry the private native object-cache id needed by the
Objective-C notification-posting layer. Attribute, hierarchy, selection,
table, and surface routes receive the request bundle's configured traversal
limits before exposure projection. Selection changes are routed as validated
semantic requests with the neutral request kind and stable target preserved for
provider dispatch; the NSAccessibility backend does not mutate selection
membership itself. Surface routes also reject contradictory committed surface
states through the shared `A11y.Windows` validator. Attribute
and surface string replies are bounded by `Native_String_Size`, so fixture
adapters can tighten native callback bounds without editing mapper snapshots.
Action-name discovery is tracked as
`macos.nsaccessibility.action.discovery`; the routed payload is derived from the
neutral action set and preserved by the provider boundary for the future
Objective-C bridge.
Action-map queries also preserve the selected backend-private NSAccessibility
action name, so selector plumbing can consume the validated native action
without reinterpreting application semantics.
The provider boundary now preserves full routed reply payloads for ordinary
provider replies and preserves the private native object id only for prepared
notification publication replies; raw notification queries remain object-free.
`Prepared_Event.Status` carries event-admission and runtime preparation
failures through the notification handoff, and the NSAccessibility mapper
rejects failed prepared records before interpreting native object metadata.
Successfully prepared records still validate their embedded semantic event
envelope before native object resolution, so malformed prepared notifications
return structured `Invalid_Argument` failures instead of falling through to
object-unavailable classification. `Prepare_Event_With_Report` adds
`native.runtime.event_preparation_report` evidence for this handoff, including
admission, commit, object identity, defunct state, and last-event accounting.
`Build_Event_With_Report` and
`Build_Prepared_Event_With_Report` add
`macos.nsaccessibility.event.build_report` evidence for envelope validation,
prepared-publication flags, native-object resolution, publishability, and
structured status without exposing Objective-C or AppKit types through common
APIs.
`Enqueue_Prepared_Event` is the payload-preserving notification queue handoff
for prepared native publications: it validates the prepared record before
building the NSAccessibility event emission, rejects failed, malformed, or
unbacked prepared records without queue mutation, and otherwise enters the
bounded native notification queue with the prepared native object id intact.
Prepared event mapping uses
`A11y.Native_Runtimes.Validate_Prepared_Event`, so failed prepared statuses,
invalid object/destruction handoff, and conflicting typed payload flags are
rejected before NSAccessibility notification mapping.
`Enqueue_Prepared_Event_With_Report` records queue length before and after,
capacity, overflow state, prepared source `Node_Id`, semantic event sequence,
semantic revision, raw prepared status, central prepared-validation status,
native-object resolution, publishability, enqueue admission, and final
structured status for diagnostics and release evidence.
Release gate evidence: prepared relation-event native-attribute preservation.
Release gate evidence: prepared focus-event payload preservation.
Release gate evidence: prepared property-event native-attribute preservation.
Release gate evidence: prepared state-event native-attribute preservation.
Release gate evidence: prepared bounds-event rectangle preservation.
Release gate evidence: prepared value-event payload preservation.
Release gate evidence: prepared selection-event payload preservation.
Release gate evidence: prepared node-reference-event payload preservation.
Release gate evidence: prepared live-region-event payload preservation.
Release gate evidence: prepared tree-event payload preservation.
Release gate evidence: prepared table-event payload preservation.
Release gate evidence: prepared document-event payload preservation.
Release gate evidence: prepared window-event payload preservation.
The NSAccessibility boundary declarations also include
`native.boundary.admission_report` for begin-call report variants that preserve
requested native element id, resolved object/node identity, callback admission,
defunct state, structured status, and return class before selector-result
mapping.
`native.boundary.completion_report` records completion before/after snapshots,
requested and final provider status, status-recording result, callback-release
result, release state, and return class before selector-result mapping.
`native.boundary.release_report` records direct release before/after snapshots,
preserved provider status, callback-release result, release state, and return
class before selector-result mapping on cleanup-only paths.
When a prepared notification is supplied, native identity admission is checked
against the prepared event source; a matching prepared-source identity is
admitted, while a mismatched raw request event cannot substitute a different
source object. Native action calls route through a
separate staged action-request reply after common action precondition
validation, and the routed payload preserves the requested neutral `Action_Id`
for provider dispatch; action-name discovery remains a read-only mapping query.
`accessibilityAttributeNames` follows the same method-based path: the ABI
surface prepares `Copy_Attribute_Names` with stable native identity, the
provider boundary routes it as an attribute-family request, and the router
returns a backend-private `Core_Attribute_Set` instead of Objective-C objects.
Protected and password nodes omit the value-text attribute from that advertised
set so secure text is not exposed through later attribute-value calls. The
portable observation evidence is recorded under
`macos.nsaccessibility.attribute_names`.
`Scroll_Into_View` maps to a backend-private scroll-to-visible action so virtual
elements can request exposure without inventing native state.
`Open`, `Close`, and `Set_Focus` map to the backend-private confirm, cancel,
and raise actions, respectively, while ordinary semantic action requests remain
authoritative.
Structured provider-boundary failures are
grouped through the common `native.boundary.return_class` classifier before
NSAccessibility native reply categories are selected, keeping macOS error
mapping aligned with other native backends. The same backend-private boundary
owns stable native status names for future Objective-C glue and diagnostics:
`success`, `not-applicable`, `no-value`, `element-unavailable`,
`invalid-argument`, `permission-denied`, `out-of-resources`, `busy`, and
`failed`. This table is tracked by the
`macos.nsaccessibility.native_status_map` conformance identifier.
The runtime probe also queries the root `NSAccessibilityIdentifier` through the
same admitted native-boundary path and verifies the payload preserves the
neutral semantic identifier rather than deriving identity from an element
address.
The inverse table is tracked by
`macos.nsaccessibility.native_status_inverse_map` and maps native result
categories back to representative common statuses without exposing Objective-C
or AppKit details through the public semantic API.
`macos.nsaccessibility.native_status_diagnostic` covers the bounded diagnostic
helper that records the stable native status name, Ada-native status token, and
normalized structured status as non-redacted diagnostic fields.
Prepared NSAccessibility notifications can be staged in a backend-private
bounded FIFO queue before the Objective-C notification-posting layer drains
them. The queue accepts only publishable emissions, is configured from
`Native_Array_Size`, reports `Resource_Limit` and records overflow when full,
rejects capacity shrinkage below the current queued length, and clears overflow
state only when explicitly cleared. `Posting_Interest` exposes a no-side-effect
bridge-facing snapshot of length, capacity, overflow, and the next posting
operation (`Post_Next_Event`, `Back_Pressure`, or `No_Posting_Operation`) so
Objective-C notification drainers do not duplicate queue policy.
`Dequeue_For_Posting` is the bridge-facing admission operation: it refuses
overflow back pressure with `Resource_Limit` and preserves pending events until
the bridge explicitly clears the queue for recovery. The behavior is tracked by
`macos.nsaccessibility.event_posting_admission`.
`Dequeue_For_Posting_With_Report` preserves that behavior and adds a bounded
`Posting_Attempt_Report` with length before/after, capacity, pending/overflow
state, admission and consumption flags, next operation, semantic source
`Node_Id`, semantic event sequence, semantic revision, and structured status
for the emission admitted to the native poster. Rejected posting attempts keep
empty semantic identity. The behavior is tracked by
`macos.nsaccessibility.event_posting_report`. The
`Drain_For_Posting_Bounded` helper repeats that admission path only up to a
caller-supplied attempt limit and calls a bridge-provided poster for each
dequeued emission. Its `Posting_Drain_Report` records attempts, posted count,
before/after queue length, capacity, overflow state, stop reason, last attempted semantic source
`Node_Id`, last semantic event sequence, last semantic revision, and last structured
status. Callback failures keep the last attempted semantic identity in the
report. The behavior is tracked by
`macos.nsaccessibility.event_posting_drain_bounded`. The
bridge-facing posting
validator rejects nonpublishable emissions, missing source or sequence identity,
and normal notifications that do not carry a prepared native object-cache id;
destruction notifications may post through the tombstone path without recreating
a native object. The platform provider also has a direct publication drain for
the current `A11ykit.Tree` compatibility path: after the AppKit process-root
host is installed, it maps pending semantic session events to NSAccessibility
notification codes and posts them through
`a11y_nsax_post_notification_for_object`. Root events use the installed host;
non-root events create a bounded transient virtual element for the source node
and release it immediately after the notification post. The provider falls back
to validation if native posting fails.
Direct native-callback admission is also gated before semantic provider
routing. Runtime probes cover missing, mismatched, and malformed element
identity. The conformance row is
`macos.nsaccessibility.native_callback.hostile_admission`; the individual
identity variants are also tracked as
`macos.nsaccessibility.native_callback.missing_identity`,
`macos.nsaccessibility.native_callback.mismatched_identity`, and
`macos.nsaccessibility.native_callback.malformed_identity`. Oversized text-edit
payloads are checked separately at the same boundary and tracked by
`macos.nsaccessibility.native_callback.text_payload_limit`.
