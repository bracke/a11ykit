# Windows UI Automation Backend

The Windows backend projects the semantic model to unmanaged Microsoft UI
Automation provider concepts. It does not depend on .NET, Windows Forms, WPF,
WinUI, ATL, or MFC.

## Provider Boundary

UIA provider-boundary scaffolds resolve native calls through stable `Node_Id`
identity, validate lifecycle and exposure, and map structured semantic results
to UIA-facing outcomes. Ada exceptions must not cross a COM boundary.
When a native call supplies a runtime-id node component, the boundary decodes it
through `A11y.Native_Identity`, verifies the active backend session, and rejects
cross-session, malformed, mismatched, or unavailable identities as
`UIA_E_ELEMENTNOTAVAILABLE` before ordinary provider routing.
Editable-text replacement payloads are checked against `Native_String_Size` at
this boundary and rejected as `E_OUTOFMEMORY` with structured
`Resource_Limit` before they become semantic text edit requests.
The direct native callback entry point, `Dispatch_Native_Request`, applies the
same checks: missing identities fail as `E_INVALIDARG`, mismatched or malformed
runtime identifiers fail as `UIA_E_ELEMENTNOTAVAILABLE`, and oversized text edit
payloads fail before the routed request reaches semantic providers.
The same backend-private boundary owns the symbolic-to-numeric HRESULT table
used by the native COM ABI bridge: `S_OK`, `S_FALSE`,
`UIA_E_ELEMENTNOTAVAILABLE`,
`UIA_E_ELEMENTNOTENABLED`, `UIA_E_INVALIDOPERATION`, `E_INVALIDARG`,
`E_ACCESSDENIED`, `E_OUTOFMEMORY`, and `E_FAIL`. This table is tracked by the
`windows.uia.hresult_map` conformance identifier.
The inverse HRESULT table maps native return classes back to representative
common statuses and is tracked by `windows.uia.hresult_inverse_map`; grouped
native codes use stable representatives such as `Unsupported_Capability` for
`S_FALSE`, `Invalid_State` for invalid operations, and `Internal_Error` for
generic failures.
`windows.uia.hresult_diagnostic` covers the bounded diagnostic helper that
records the symbolic HRESULT name, numeric HRESULT code, and normalized
structured status as non-redacted diagnostic fields.
COM provider scaffolds now produce a transient native-call context from the
stored session/root/node identity before boundary dispatch. Unsupported
interfaces and defunct or destroyed providers fail with structured statuses
without exposing COM pointers or application provider state.
They also provide an SDK-free export descriptor with stable session/root/node
identity, runtime-id node component, supported-interface flags, and host-window
binding metadata. Reading this descriptor does not AddRef the provider and does
not expose native handles.
Outstanding native calls are counted explicitly. `Begin_Native_Call` admits a
supported interface and increments the provider call count; `End_Native_Call`
releases the exact context. A final COM release marks the provider defunct while
calls are outstanding and completes destruction only after the last admitted
call returns, preventing stale calls from draining unrelated state or
dereferencing freed application objects.
Each admitted and successfully released native call also advances a
backend-private call generation. Active call snapshots carry the admitted
generation, and stale copied contexts are rejected without advancing it, giving
COM diagnostics a monotonic observation point for copied or out-of-order call
contexts.
Each admitted call receives a backend-private monotonic token. `End_Native_Call`
validates that token before decrementing the outstanding-call count, so copied
or repeated stale contexts cannot drain a different call while another native
callback is still active. Token accounting is compact and bounded; provider
registry records do not contain per-call heap or table state.
`Drained` exposes the same zero-outstanding-call predicate COM shutdown code
uses before releasing bridge-owned provider state.
The session-local provider registry assigns stable provider ids for
`Node_Id`/fragment-root pairs, returns the same id for repeat lookups, enforces
the native-object cache limit, and leaves released ids as tombstones until the
registry is reset. Provider ids are not addresses and are not reused while a
registry session is active. Registry-level `Drained` becomes true only after all
admitted provider calls have returned. `Reset_When_Drained` rejects reset with
structured `Busy` while native calls are still outstanding. Checked
reset clears provider records and node indexes deterministically without
materializing a temporary full registry table. After a successful drained reset,
both node lookup and stale provider-id resolution return structured
`Node_Unavailable` instead of exposing a cleared provider slot. Registry snapshots expose
`Outstanding_Calls` for shutdown diagnostics. They also expose a
backend-private registry generation that advances only on successful
configuration, first provider creation, defunct marking, release, and reset;
idempotent lookup, native-call admission, stale resolution, rejected reset, and
capacity rejection leave it unchanged. Provider record snapshots carry the
registry generation they were resolved under. This registry
satisfies the Windows-specific `windows.uia.provider_registry` row and the
common `native.object_cache.identity` conformance row.
`Begin_Native_Call_With_Report` and `End_Native_Call_With_Report` wrap the same
call pinning path with deterministic mutation reports. Reports capture
before/after registry generation, before/after outstanding-call counts,
provider id, session id, stable node identity, requested provider interface,
the provider-call snapshot, and whether generation or outstanding-call counts
changed. Failed admission returns an inactive rejected call context and records
no outstanding-call mutation, so the COM ABI bridge can log or diagnose
malformed, stale, or defunct callbacks without fabricating state.
Bare `Reset` is also drained-aware: while provider calls are pinned it leaves
tombstones, call counts, and the registry generation unchanged.
Fragment-root providers can bind one normalized host-window component for the
future HWND/root-provider bridge. Binding is root-only, idempotent for the same
component, rejects conflicting host roots, and remains backend-private.
Fragment navigation and runtime-id helpers validate supplied resource-limit
configurations before resolving native-visible tree state, so malformed backend
policy is reported as a structured invalid-argument failure instead of being
masked by defunct or unavailable fragment nodes.
`IRawElementProviderSimple.get_ProviderOptions` is routed through the same
SDK-free ABI frame and returns the server-side-provider option as
backend-private native metadata. It does not query or mutate application
semantics and remains internal evidence until observed through the Windows UIA
runtime by a public client.
`IRawElementProviderSimple.get_HostRawElementProvider` is also routed through
the SDK-free frame path. Virtual providers return an explicit empty host
provider result rather than fabricating a native handle. HWND-backed callback
providers bind their host window in backend-private state and, after semantic
admission succeeds, return `UiaHostProviderFromHwnd` as the native host
provider. The native client probe records this as
`windows_uia_callback_provider_host_raw_element_provider_returned_host`.
`IRawElementProviderFragment.GetEmbeddedFragmentRoots` is routed as a
fragment-interface frame and currently returns an explicit empty embedded-root
collection. That keeps ordinary semantic fragments dispatchable without
inventing secondary native root ownership.

## Runtime Identity

Runtime identifiers are derived from backend session identity, fragment-root
identity, and `Node_Id`. Memory addresses and COM pointer values are not stable
semantic identity and must not be used.

## Public Client Runtime Probe

The native bridge contains a Windows-only client-runtime smoke probe used by
`native_client_uia --probe-external-client`. The probe initializes COM for the
calling thread where needed, creates `IUIAutomation` through
`uiautomationcore.dll`, obtains the desktop root element, and records HRESULTs
for each stage. The non-Windows bridge implementation is an explicit unavailable
stub so portable builds can still compile and report the missing runtime
honestly. The report includes `native_bridge_compiled_for_windows` and
`native_bridge_stub_runtime`; a Linux build must report the stub runtime, while
a Windows guest run must report that the bridge was compiled for Windows before
any public UIA traversal can count as native evidence.

This probe is an ABI and environment check, not a provider conformance claim.
The required production evidence remains a public UI Automation client
discovering an a11y-exported fragment root through the Windows UIA runtime,
traversing the fragment tree, and observing the protected-text and action
boundaries through public UIA calls.

The same external-client command also runs a host-window handshake probe on
Windows. It registers a hidden test window, sends `WM_GETOBJECT` with
`UiaRootObjectId`, calls `UiaReturnRawElementProvider` with a null provider,
and records whether Windows routes that request through the expected UIA
window path. The JSON fields are
`windows_uia_host_window_handshake_available`,
`windows_uia_host_window_wm_getobject_sent`,
`windows_uia_host_window_root_object_id_matched`,
`windows_uia_host_window_return_provider_called`,
`windows_uia_host_window_null_provider_returned_zero`, and
`windows_uia_host_window_return_provider_lresult`. This is still not provider
conformance evidence: it proves host-window/UIA message plumbing only. Provider
conformance evidence requires returning an a11y-backed `IRawElementProvider*`
from this path and traversing it through a public `IUIAutomation` client.

The bridge also contains a staged minimal-provider host-window probe. That
Windows-only helper allocates a native C object whose first interface is
`IRawElementProviderSimple`, implements `IUnknown` `QueryInterface`, `AddRef`,
and `Release`, returns `ProviderOptions_ServerSideProvider`, and exposes no
semantic properties or patterns. The probe returns that object from
`WM_GETOBJECT` through `UiaReturnRawElementProvider` and records
`windows_uia_minimal_provider_*` fields including COM lifetime callbacks,
provider-options calls, `ElementFromHandle` status, and final reference count.
This is native runtime progress, but it is intentionally still not an a11y
provider claim because the object is not backed by the Ada semantic registry.
The Ada-owned provider descriptor and provider-boundary routing are covered by
the callback-provider path and by the Windows compatibility facade's
`Export_Public_Root` publication path.

The following staged probe is `windows_uia_callback_provider_*`. It uses a
native COM object that exposes `IRawElementProviderSimple`,
`IRawElementProviderFragment`, and `IRawElementProviderFragmentRoot`.
Every method on those vtables now crosses into an Ada C-convention callback.
The legacy callback records the stable session id, provider id, and UIA ABI
method code. The full-frame callback additionally carries the stable object
token, interface code, method code, and navigation/action direction so the
native object identity is routed through Ada instead of being implied by a COM
pointer. The C bridge records whether each callback was called, the identity
and method values it passed, each callback HRESULT, and the native provider
reference count after release.

Production-side Ada routing for that same six-field native frame is implemented
by `A11y.Windows_Backend.UIA_Native_Callbacks`. Its C-convention callback
unwraps the native frame, resolves the callback context's object table and
provider registry, and delegates to `UIA_COM_Live_Exports.Dispatch_Interface_Frame`.
That gives the COM bridge a real native-to-Ada dispatch entry whose semantic
reply path is the existing provider boundary rather than a C test callback.
The native Windows probe still uses a small native COM object as the vtable
host, but after the external-client fixture exports its public root, that host
passes the production callback and context. Public `IUIAutomation` traversal of
that provider through the operating-system runtime is still required before
public UIA conformance is claimed.

## Properties And Patterns

Backend-private property and pattern mappers translate committed semantic roles,
states, properties, capabilities, actions, values, selection, text, tables,
documents, images, and surfaces into UIA-facing concepts. Unsupported semantic
features return native not-supported outcomes rather than fabricated empty
values. Live-region and notification events carry the validated neutral payload,
so inactive regions with relevant-change metadata are rejected consistently with
the common semantic model.
Core property query routing includes bounded property strings, visible-title
metadata, orientation metadata, heading and landmark metadata, structural
integers, booleans, and rectangles without exposing COM types through public
semantic packages. The UIA property mapper validates supplied resource-limit
configurations before native-facing property replies, including integer,
boolean, rectangle, and control-type replies that do not otherwise allocate
native strings.
UIA structural integer properties apply `Native_Array_Size` and `Traversal_Depth` before native projection: set position and set size use the native-array ceiling, while hierarchical level and heading level use the traversal-depth ceiling.
The UIA live-region mapper exposes setting names, stable relevance names,
atomicity, and external-announcement policy from committed semantic metadata,
validates supplied resource-limit configurations before all replies, uses
common native string bounds, and rejects defunct or contradictory snapshots
before any COM-facing conversion. The request router and provider
boundary carry those live-region string/boolean replies without exposing COM
types to the semantic model, and the live-region snapshot keeps the stable
`Node_Id` used by native identity admission.
Value and text mappers also validate supplied resource-limit configurations at
entry, before resolving hidden, defunct, or unavailable semantic nodes, for both
queries and staged mutation requests.
The backend-private request router preserves successful reply payloads instead
of reducing them to reply kinds: property strings, integers, booleans,
rectangles, control types, locale strings, capability-derived pattern-provider
sets, values, staged value-set requests, selection counts, selection mutation
request kinds and `Node_Id` targets, staged action request identifiers, text
counts and neutral wide-text ranges, text edit requests, table counts and cell
ids, relation target replies with the selected UIA relation property, image
descriptions and intrinsic sizes, document metadata, live-region metadata, and surface
metadata. Only final COM/BSTR/SAFEARRAY conversion remains for the
future ABI bridge. The provider boundary keeps that full backend-private routed
payload alongside the legacy routed-kind field, so a future COM bridge can
consume the already-dispatched value without asking the semantic provider again.
For relation target requests, that preserved payload includes the selected UIA
relation property.
Release gate evidence: relation target replies with the selected UIA relation property.
Release gate evidence: preserved payload includes the selected UIA relation property.
Release gate evidence: relation target native-property preservation.
The deterministic UIA runtime probe now exercises table current-cell,
sort-order, and sort-key requests through that provider boundary and verifies
the stable `Node_Id` and neutral sort-order payloads before the native call is
drained. It also dispatches document, image, live-region, and surface metadata
queries through the same boundary, preserving document title and heading level,
image alternative text and intrinsic size, live-region setting and atomicity,
and surface kind and active-state payloads. Surface metadata routing validates
supplied resource-limit configurations before native-facing replies.
The runtime probe also builds the COM export table into a vtable descriptor and
records `com_vtable_descriptor_built`,
`com_vtable_query_interface_planned`, and `com_vtable_frame_planned`, proving
that a root provider can expose the planned UIA interfaces and provider-method
callback frame before live COM export exists.
It now also exports, resolves, releases, and re-exports an opaque object token,
recording `com_object_token_exported`, `com_object_token_resolved`,
`com_object_token_released`, and `com_object_token_not_reused` as release
evidence for the COM object export table.
The same runtime probe then resolves the live token into an interface reference
and exercises SDK-free reference lifetime before dispatching
`IRawElementProviderSimple.get_PropertyValue` through that reference, recording
`com_live_interface_queried`, `com_live_interface_retained`,
`com_live_interface_released`, `com_live_released_interface_rejected`, and
`com_live_interface_dispatched`.
It also dispatches an ABI interface frame from the same live reference and
records `com_live_interface_frame_dispatched`. Fragment interface dispatch now
includes a direction-coded `Navigate` frame and a `GetRuntimeId` frame,
recording `com_live_fragment_navigate_dispatched` and
`com_live_fragment_runtime_id_dispatched` when the live reference resolves
through the fragment boundary and returns stable `Node_Id`/runtime-id payloads.
Hostile live-export paths are checked in the same probe: malformed interface
frame codes record
`com_live_invalid_interface_frame_rejected`, malformed method frame codes
record `com_live_invalid_method_frame_rejected`, and attempting to dispatch a
Simple-provider method through a Fragment interface reference records
`com_live_interface_method_mismatch_rejected`. These checks prove the current
COM live-export surface rejects released, malformed, or cross-interface calls
before any semantic provider state is queried.
The registered provider-boundary probe also records
`registered_routed_error_status` when a routed semantic error is drained into
the native-call report, proving reply and final statuses stay synchronized for
expected native failures.
`native_client_uia --probe-external-client` now performs the same
transport-facing COM sequence from the external-client side of the test tool:
export object, query the Fragment interface, dispatch `Navigate`, dispatch
`Navigate(LastChild)` through an ABI interface frame, dispatch
`GetRuntimeId`, dispatch a `Simple.GetPropertyValue` ABI interface frame,
dispatch `Simple.GetPatternProvider` through the same ABI interface-frame
path, dispatch `Fragment.get_BoundingRectangle` through an ABI interface
frame,
dispatch a Fragment `SetFocus` ABI interface frame that preserves the neutral
`Set_Focus` action payload, release the interface, verify
a stale Fragment call is
rejected, release the exported COM object token, and verify the tombstoned
object token no longer resolves. It records `provider_export_observed`,
`fragment_interface_queried`, `fragment_navigate_dispatched`,
`fragment_last_child_frame_dispatched`, `fragment_runtime_id_dispatched`,
`bounding_rectangle_frame_dispatched`,
`pattern_provider_frame_dispatched`, `simple_property_frame_dispatched`,
`fragment_action_frame_dispatched`, `fragment_action_frame_status`,
`fragment_action_frame_routed`, `fragment_set_focus_payload_preserved`,
`released_interface_rejected`,
`object_token_released`, `released_object_token_rejected`, and
`com_live_chain_observed` as a single summary for the provider export,
Fragment dispatch, runtime-id dispatch, bounding-rectangle frame dispatch,
last-child frame dispatch, pattern-provider frame dispatch,
simple property frame dispatch, SetFocus action status/routing and payload
dispatch, stale-interface
rejection, and stale-object-token
rejection chain.
The native callback-provider bridge also supplies
`Copy_Property_Value_Callback` as the value-copy side of
`IRawElementProviderSimple.GetPropertyValue`: after the checked
interface-frame dispatch succeeds, the callback copies the routed semantic
string property into a bounded UTF-8 buffer for the C shim, which converts it
to an owned BSTR before returning the COM `VARIANT`. If the callback reports a
byte count larger than the provided buffer, the bridge fails the native call
instead of returning a misleading empty value.
`Copy_Runtime_Id_Callback` performs the corresponding
`IRawElementProviderFragment.GetRuntimeId` value-copy path: it dispatches the
same checked interface frame and copies the semantic session/root/node runtime
identifier components into a bounded UInt32 buffer, which the C shim converts
to an owned `SAFEARRAY(VT_I4)`.
`Copy_Bounding_Rectangle_Callback` dispatches
`IRawElementProviderFragment.get_BoundingRectangle` through the same checked
frame path and copies neutral logical desktop bounds into the native `UiaRect`
result.
`IRawElementProviderSimple.GetPatternProvider` now returns the first native
pattern objects in this staged bridge. When the routed semantic pattern set
contains `Invoke`, the C COM provider returns an `IInvokeProvider` whose
`Invoke` method crosses back through the encoded ABI frame
`IInvokeProvider.Invoke`. When the pattern set contains `Toggle`, the bridge
returns an `IToggleProvider` whose `Toggle` method crosses back through
`IToggleProvider.Toggle`. When committed semantic value metadata exposes a
writable numeric range, `GetPatternProvider(UIA_RangeValuePatternId)` returns
an `IRangeValueProvider` whose `SetValue` method dispatches the requested
neutral value through `IRangeValueProvider.SetValue`. Its `get_Value`,
`get_IsReadOnly`, `get_Maximum`, `get_Minimum`, `get_LargeChange`, and
`get_SmallChange` methods dispatch through the same checked native identity
frame and copy values from committed neutral `A11y.Values` metadata. The Ada
ABI surface prepares those frames as neutral `Activate`, `Toggle`, range-value
set, and range-value query requests, so native pattern invocation still uses
the common provider-boundary path instead of mutating state in COM glue.
When the routed pattern set contains `Window`, the bridge returns an
`IWindowProvider` whose `Close` method dispatches the neutral `Close` action.
Its `get_CanMaximize`, `get_CanMinimize`, `get_IsModal`,
`get_WindowVisualState`, and `get_WindowInteractionState` methods also cross
the checked native identity frame and copy values from committed neutral
surface metadata. `SetVisualState`, `WaitForInputIdle`, and `get_IsTopmost`
remain deliberately conservative until matching neutral semantics exist.
The same blocked probe also verifies that the UIA property
mapper preserves semantic metadata before OS-client traversal is available:
`metadata_name_preserved`, `metadata_identifier_preserved`,
`metadata_help_preserved`, `metadata_placeholder_preserved`, and
`metadata_detail_preserved`, summarized by `metadata_group_preserved`.
It also sets a protected value-text sentinel and
requires the UIA `Value_Text` property mapper to return a structured
permission-denied result, reported as `protected_value_suppressed` and
`privacy_boundary_observed`. The probe
still reports
`transport_status = blocked_transport_unavailable` and
`external_client_traversal_observed = false` until a real Windows UI Automation
client process traverses the exported provider through the OS UIA runtime.
The derived `internal_native_export_chain_ready` flag is internal evidence
only: it requires the SDK-free COM live chain, metadata group, and protected
value privacy boundary to pass, and it also requires the fragment action frame
to dispatch through the same ABI path. It is not a live UIA client support
claim.
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
target native-property preservation for the selected UIA
relation property.
It also binds the provider as a virtual fragment root to a deterministic
host-window root binding and reports `host_window_bound` plus
`host_window_component` in the runtime probe JSON.
The external-client smoke probe separately verifies that a Windows host window
can receive a UIA root-object request through `WM_GETOBJECT`; that check is
reported as host-window handshake evidence and does not claim that the Ada
provider object has been exported as a live COM pointer.
The minimal-provider smoke path goes one step further by returning a native
`IRawElementProviderSimple` object with real COM reference counting from the
same host-window path. It still contains no application semantics and is used
only to validate the ABI shape that the Ada-backed provider object must occupy.
The callback-provider smoke path then verifies all native Simple-provider
vtable methods can call back into Ada with stable provider identity. The
current Windows compatibility facade uses the production Ada callback wrappers,
request-router snapshots, and a bridge-owned live callback-provider host window
when the real Windows bridge is present. The host handle is retained until
`A11ykit.Provider.Stop`, which releases the COM provider, clears the hidden
window's `WM_GETOBJECT` context, destroys the window, and uninitializes COM
only when the bridge initialized it for that host. The native smoke command
remains the repeatable evidence path for checking the COM ABI, host-window
handshake, and callback identity frames.
After the live host is created, the facade drains committed semantic events by
mapping each backend-private `UIA_Event_Emission` kind to the matching Microsoft
UI Automation event identifier and calling the bridge-owned
`UiaRaiseAutomationEvent` wrapper. Events are acknowledged in the semantic
session only after the native call returns success. This first native drain is
root-provider scoped; precise per-node event provider objects and
property-specific old/new `VARIANT` payloads remain separate hardening work
before full Windows UIA event conformance can be claimed.
`A11y.Windows_Backend.UIA_Public_Roots.Export_Public_Root` is the
backend-private public-root export path used by both the compatibility facade
and the external-client probe. It ensures and initializes the root provider,
builds the COM export
table and object descriptor, exports the root object, and verifies that
Fragment, Simple, and FragmentRoot queries resolve through the same stable
`Node_Id`-owned provider state. The probe reports
`windows_uia_public_root_export_path_observed`,
`windows_uia_public_root_provider_ensured`,
`windows_uia_public_root_provider_initialized`,
`windows_uia_public_root_object_exported`,
`windows_uia_public_root_native_node_component_stable`,
`windows_uia_public_root_fragment_queryable`,
`windows_uia_public_root_simple_queryable`, and
`windows_uia_public_root_fragment_root_queryable`. These fields prove that
the SDK-free COM export chain reaches a public fragment root and that its
native node component matches the stable neutral runtime identifier rather than
an address-derived value; they still stop short of claiming live UI Automation
support until a Windows UIA client process traverses that root through the
operating-system runtime.
The same probe now preserves native-call lifecycle evidence as data, reporting
`native_call_token`, `native_call_start_generation`,
`native_call_final_generation`, and
`native_call_active_after_completion` after the boundary call drains.
It also routes a focused-state query and a set-focus action through
`A11y.Native_Focus_Calls`, reporting `native_focus_query_dispatched`,
`native_focus_query_payload_preserved`, `native_set_focus_dispatched`, and
`native_set_focus_payload_preserved` without adding UIA types to the common
focus API.
The normalized native-client report exposes the same boundary evidence through
`has_windows_uia_native_focus_query_observation`,
`has_windows_uia_native_set_focus_observation`,
`has_windows_uia_selection_select_all_observation`, and
`has_windows_uia_selection_clear_observation`.
Registered provider dispatch includes COM provider-interface request admission:
fragment navigation and runtime-id requests are rejected when they arrive
through the simple provider interface, before a provider call is pinned or any
semantic provider is queried. This is tracked as
`native.boundary.request_admission`.
Text query routing now includes central grapheme-cluster counts from
`A11y.Text.Grapheme_Cluster_Count`, keeping UIA text provider scaffolds aligned
with the common Unicode model before native UTF-16 text-range conversion.
Cluster-based range routing uses `Slice_Grapheme_Clusters`, so a future UIA
TextRange bridge can request grapheme-indexed snapshot text without duplicating
Unicode boundary policy in COM-facing code.
Backend-private grapheme edit helpers use
`Validate_Grapheme_Edit_Request` to preserve the neutral `Text_Edit_Request`
payload for future TextRange mutation paths without backend-owned semantic
mutation.
Pattern discovery is tracked as `windows.uia.pattern.discovery` and is derived
from the neutral action set rather than from native object state. Provider
boundary admission for `GetPatternProvider` validates the action snapshot
`Node_Id`, matching the node used by the router to derive the immutable pattern
set.
The live COM evidence id `windows.uia.com_live.pattern_provider_frame` covers
the same request after it has passed through an encoded
`IRawElementProviderSimple.GetPatternProvider` interface frame.
Action-map queries also preserve the selected backend-private UIA pattern and
operation, so a COM bridge can dispatch the already validated native provider
operation without recomputing action policy.
The current native bridge consumes that action-map result for `Invoke` and
`Toggle`: `GetPatternProvider(UIA_InvokePatternId)` returns a COM
`IInvokeProvider` whose `Invoke` dispatches the neutral `Activate` request, and
`GetPatternProvider(UIA_TogglePatternId)` returns a COM `IToggleProvider` whose
`Toggle` dispatches the neutral `Toggle` request. The same native bridge now
consumes value-map results for `UIA_RangeValuePatternId`: it returns
`IRangeValueProvider` only when the semantic mapper advertises the pattern, and
its `SetValue` and getter methods route to the checked provider boundary with
the stable session, provider, object-token, interface, and method frame. Other
UIA patterns remain unadvertised by the native bridge until their provider
objects and native methods are routed through the same checked path.
The bridge also consumes surface-map results for `UIA_WindowPatternId`: window
close dispatches the neutral close action, maximize capability uses the neutral
resizable operation metadata, minimize capability is limited to top-level
semantic surfaces, modal state uses the neutral modal rule, visual state is
derived from maximized/minimized surface state, and interaction state reports
ready only for active surfaces. The bridge does not infer topmost or wait-idle
state from HWND details because those concepts are not yet present in the
common semantic model.

## Native Values

BSTR and SAFEARRAY scaffolds enforce common native-value resource limits,
including UInt32 representability for scalar property ids and every SAFEARRAY
item, and own cleanup deterministically. Router tests cover oversized values,
invalid limits, and unsupported value representations.
The bridge audit exposes the same hard allocation ceilings as the native-value
scaffolds: 65,536 UTF-16 units for BSTR values and 4,096 UInt32 items for
SAFEARRAY values. Callback-reported property text that exceeds the bridge copy
buffer fails the COM call instead of producing an empty successful VARIANT.
Image metadata routing validates supplied resource-limit configurations before
returning descriptions, captions, categories, or intrinsic sizes.
Document metadata routing validates supplied resource-limit configurations
before returning document attributes or pagination metadata.
UIA value-setting routes are staged as semantic set requests. The mapper first
validates lifecycle, exposure, committed value metadata, resource limits,
numeric type compatibility, range constraints, and read-only policy through the
common `A11y.Values.Validate_Numeric_Set_Request` helper. A successful route
records the requested neutral value for the native `IRangeValueProvider.SetValue`
method; it does not mutate semantic state directly. Rejections return
structured statuses such as `Read_Only`, `Invalid_Argument`, `Resource_Limit`,
or `Node_Unavailable`.
RangeValue getters use the same value mapper for `Current_Value`,
`Minimum_Value`, `Maximum_Value`, `Small_Increment`, `Large_Increment`, and
`Is_Read_Only`, preserving the neutral distinction between unsupported,
unavailable, read-only, and ordinary numeric replies before converting to UIA
`double` or `BOOL` outputs.

## Transport Status

Full public-client traversal through the operating-system UIA runtime is not
yet implemented. The common native backend has an adapter-facing
transport-admission path, so an admitted UIA scaffold can keep the shared
runtime running and prepare semantic events for native object-cache
publication through `Prepare_Publication`. The UIA event mapper accepts those
prepared records, requires and carries native object-cache identity for normal
events, and preserves destruction events without recreating provider objects.
`A11y.Windows_Backend.UIA_ABI_Surface` defines the SDK-free COM method surface
contract for future bridge code. It maps audited provider methods such as
`IRawElementProviderSimple.GetPropertyValue`,
`IRawElementProviderFragment.GetRuntimeId`,
`IRawElementProviderFragment.get_BoundingRectangle`, and fragment-root focus
callbacks to existing provider-boundary request kinds, requires stable native
identity where appropriate, rejects unimplemented advise-event callbacks, and
enforces root-only fragment-root admission before a bridge can dispatch. Its
conformance identifier is `windows.uia.abi_surface`.

`A11y.Windows_Backend.UIA_Bridge_Audit` records the finite native COM bridge
operation set. The corresponding `native/windows/a11y_uia_bridge.c` shim is ABI
adaptation only: IUnknown callback entry, provider-method callback entry,
provider-frame callback entry, full provider-interface-frame callback entry,
bounded property-string-to-BSTR marshalling, bounded SAFEARRAY allocation
for runtime identifiers, `IRangeValueProvider.SetValue` and RangeValue getter
callback routing, and `IWindowProvider` getter callback routing,
cleanup helpers, and HRESULT
pass-through. It does not implement control types, properties, patterns,
fragment navigation, event policy, provider dispatch, or application
accessibility semantics. Ada callbacks must contain expected failures before
returning to the C ABI, and provider-method callbacks are marked as requiring
the provider COM apartment. `a11ykit.gpr` includes `native/windows` and enables
C compilation only for Windows target builds. Each audited operation also records
machine-readable calling-convention, nullability, lifetime, and representation
rules, including ephemeral callback frames, nullable native handles, destroyed
BSTR/SAFEARRAY values, and stable HRESULT code representation.
`A11y.Windows_Backend.UIA_Native_Bridge` is the Ada-side import contract for
those symbols. It exposes only backend-private scalar ABI types, callback
profiles, opaque addresses, and imported entry points, so semantic packages
never depend on COM pointers, BSTR, SAFEARRAY, or HRESULT values.
`A11y.Windows_Backend.UIA_COM_Exports.Bridge_Entry` ties each export callback
slot to the audited bridge operation and imported symbol name before COM object
export. QueryInterface/AddRef/Release stay lifetime-only, while the provider
method slot is the only entry marked as dispatching provider methods.

`A11y.Windows_Backend.UIA_COM_Exports` turns a validated provider export
descriptor into the backend-private table consumed by future COM objects and
the C bridge. The table carries the stable provider id, backend session,
root/node identity, runtime-id component, audited callback slots, and the
subset of `A11y.Windows_Backend.UIA_ABI_Surface` methods dispatchable for that
provider. Fragment-root methods remain root-only, unsupported advise-event
methods stay unavailable, invalid provider ids are rejected before callback
invocation, and HRESULT values are converted to stable 32-bit ABI codes in one
place. `Invoke_Provider_Method` is the Ada entry point for a future COM method
callback: it requires the audited provider-method callback slot, prepares the
ABI request, enters the registered-provider boundary, pins the provider through
the registry, dispatches through the normal semantic router, records begin/end
native-call reports, and returns both the structured reply and ABI HRESULT code.
The registered-provider boundary validates the prepared runtime identifier
against the current semantic snapshot before pinning; identity mismatches return
`UIA_E_ELEMENTNOTAVAILABLE` with no begin-call admission or provider dispatch.
IUnknown lifetime callbacks remain separate audited slots and are not routed as
semantic provider methods.
The same package also defines `ABI_Callback_Frame`, the SDK-free raw callback
shape corresponding to the C bridge arguments: numeric backend session, numeric
provider id, and numeric method id. `Build_Callback_Frame` and
`Invoke_Callback_Frame` provide the checked handoff from those raw values back
to the typed export table. A frame is rejected before provider dispatch if the
session/provider pair does not match the table or if the method code is not one
of the stable UIA ABI method codes. The C shim exposes
`a11y_uia_dispatch_provider_frame` for this exact frame-shaped handoff; it only
unpacks the three raw fields and calls the Ada callback.
`A11y.Windows_Backend.UIA_COM_VTables` builds the next SDK-free layer from that
export table: a backend-private COM object descriptor with stable controlling
IUnknown evidence, the supported provider-interface slots, the method entries
available in each vtable, and the subset of methods that may enter the raw
provider callback frame. QueryInterface planning is kept typed and bounded:
unsupported interfaces return a structured unsupported result and an S_FALSE
ABI code, while root-only fragment-root slots are exposed only for the root
provider object. IUnknown AddRef/Release remain lifetime callbacks and are not
admitted through the provider-method frame.
`A11y.Windows_Backend.UIA_COM_Object_Exports` then stages native export without
using COM pointers: exportable descriptors receive opaque `COM_Object_Token`
values that are session/provider-bound, checked on resolve, tombstoned on
release, and never reused during the process session. This is the token table
that a future real COM bridge can use before handing back actual interface
pointers.
`A11y.Windows_Backend.UIA_COM_Live_Exports` is the next SDK-free export layer:
it resolves an object token into a stable `UIA_Interface_Reference`, answers
typed QueryInterface requests, rejects released and unsupported references, and
dispatches provider methods only through the interface that was actually
queried. The returned reference is still opaque Ada backend state, not a COM
pointer; the native bridge remains responsible only for ABI adaptation.
Interface `AddRef` is bounded before mutation: a reference already at
`Natural'Last` is rejected with structured `Resource_Limit`, keeps its reference
count unchanged, and never falls through to an Ada overflow exception at the
native boundary.
Interface `Release` remains deterministic after the final reference is dropped:
a repeated release on the same interface reference returns structured
`Node_Unavailable`, keeps the count at zero, and leaves the released marker set.
The SDK-free frame path now also routes
`IRawElementProviderFragment.get_FragmentRoot`,
`IRawElementProviderFragmentRoot.ElementProviderFromPoint`, and
`IRawElementProviderFragmentRoot.GetFocus` to stable `Node_Id` payloads through
registered provider calls. This proves the fragment-root call contracts before
the real COM bridge exposes them to Windows UI Automation clients. The C bridge
now turns successful `ElementProviderFromPoint` and `GetFocus` dispatches into
returned fragment interface pointers and records
`windows_uia_callback_provider_root_from_point_returned_fragment` and
`windows_uia_callback_provider_root_get_focus_returned_fragment` in the native
client probe.
The same package defines `ABI_Interface_Frame`, `Build_Interface_Frame`, and
`Dispatch_Interface_Frame`, giving the native bridge a fixed-width frame that
validates session, provider, object token, interface, and method codes before
provider routing. The runtime probe records
`com_live_interface_frame_dispatched` when that decoded frame reaches the same
checked provider path as a queried interface reference.
Stable UIA ABI method codes are owned by `UIA_ABI_Surface`; the older COM
export helper functions delegate to that table for compatibility. This keeps
the C bridge, live COM frame dispatch, and Ada request router on one
method-code vocabulary.
The C shim also exposes `a11y_uia_dispatch_provider_full_frame`, which forwards
the fixed-width frame pointer to Ada without unpacking or interpreting it. That
helper exists for the live COM interface-frame path where Ada must decode all
six fields, including object token, interface code, method code, and navigation
direction, before any provider callback is admitted.
Oversized 64-bit session, provider, and object-token frame fields are rejected
before conversion to Ada `Natural` values, so hostile COM frames return
structured `Invalid_Argument` failures instead of falling through to internal
exception handling.
`Prepared_Event.Status` carries event-admission and runtime preparation
failures through this handoff, and the UIA mapper rejects failed prepared
records before interpreting native object metadata. Successfully prepared
records still validate their embedded semantic event envelope before native
object resolution, so malformed prepared events return structured
`Invalid_Argument` failures instead of falling through to object-unavailable
classification. Prepared event mapping also uses
`A11y.Native_Runtimes.Validate_Prepared_Event` to reject conflicting typed
payload flags before choosing a UIA property, structure, focus, or window event
category. `Prepare_Event_With_Report` adds
`native.runtime.event_preparation_report` evidence for this handoff, including
admission, commit, object identity, defunct state, and last-event accounting.
`Build_Event_With_Report` and
`Build_Prepared_Event_With_Report` add `windows.uia.event.build_report`
evidence for envelope validation, prepared-publication flags, native-object
resolution, publishability, and structured status without exposing COM or UIA
types through common APIs.
`Enqueue_Prepared_Event` is the payload-preserving queue handoff for prepared
native publications: it validates the prepared record before building the UIA event emission, rejects failed, malformed, or unbacked prepared records without
queue mutation, and otherwise enters the bounded native event queue with the
prepared native object id intact.
`Enqueue_Prepared_Event_With_Report` records queue length before and after,
capacity, overflow state, raw prepared status, central prepared-validation
status, native-object resolution, publishability, enqueue admission, and final
structured status so diagnostics can distinguish runtime preparation failures
from malformed prepared-record shape.
capacity, overflow state, prepared source `Node_Id`, semantic event sequence,
semantic revision, prepared status, native-object resolution, publishability,
enqueue admission, and final structured status for diagnostics and release
evidence.
Release gate evidence: prepared relation-event native-property preservation.
Release gate evidence: prepared focus-event payload preservation.
Release gate evidence: prepared property-event native-property preservation.
Release gate evidence: prepared state-event native-property preservation.
Release gate evidence: prepared bounds-event rectangle preservation.
Release gate evidence: prepared value-event payload preservation.
Release gate evidence: prepared selection-event payload preservation.
Release gate evidence: prepared node-reference-event payload preservation.
Release gate evidence: prepared live-region-event payload preservation.
Release gate evidence: prepared tree-event payload preservation.
Release gate evidence: prepared table-event payload preservation.
Release gate evidence: prepared document-event payload preservation.
Release gate evidence: prepared window-event payload preservation.
The UIA boundary declarations also include
`native.boundary.admission_report` for begin-call report variants that preserve
requested runtime id, resolved object/node identity, callback admission,
defunct state, structured status, and return class before HRESULT mapping.
`native.boundary.completion_report` records completion before/after snapshots,
requested and final provider status, status-recording result, callback-release
result, release state, and return class before HRESULT mapping.
`native.boundary.release_report` records direct release before/after snapshots,
preserved provider status, callback-release result, release state, and return
class before HRESULT mapping on cleanup-only paths.
Property payloads that have no UIA property event mapping are rejected with
`Unsupported_Property` rather than emitted as generic property changes.
Current declarations claim tested mapper/router/provider-boundary,
native-call-context, export-descriptor, and lifetime scaffolds only, not live UI
Automation provider interoperability. The request router keeps the legacy raw-event query path and
also accepts prepared records for publication handoff; prepared event replies
carry the private native object-cache id needed by the future COM event-posting
layer. Property, fragment navigation, selection, table, and surface routes
receive the request bundle's configured traversal limits before exposure
projection. Selection change calls are routed as validated semantic requests
with the neutral request kind and stable target preserved for provider
dispatch; the UIA backend does not mutate selection membership itself. Surface routes also
reject contradictory committed surface states
through the shared `A11y.Windows` validator. Property and surface string replies
are bounded by `Native_String_Size`, so fixture adapters can tighten native
callback bounds without editing mapper snapshots. The provider boundary now
preserves full routed reply payloads for ordinary provider replies and preserves
the private native object id only for prepared event publication replies; raw
event queries remain object-free. When a prepared event is supplied, native identity admission
is checked against the prepared event source; a matching prepared-source
identity is admitted, while a mismatched raw request event cannot substitute a
different source object. Native action calls route through a
separate staged action-request reply after common action precondition
validation, and the routed payload preserves the requested neutral `Action_Id`
for provider dispatch; pattern discovery remains a read-only mapping query.
`Set_Focus` routes as a staged fragment focus request without advertising an
extra UIA control pattern. `Open` maps to the same Invoke request path for roles
whose semantic default action opens content. `Scroll_Into_View` and `Close`
map to the ScrollItem and Window request paths. Structured provider-boundary
failures are grouped through the common `native.boundary.return_class`
classifier before UIA HRESULT-style results are selected, keeping UIA error
mapping aligned with other native backends.
`Dispatch_Request` remains the backend-private routing entry point for mapper
tests and already-decoded internal requests. ABI-facing provider calls should
enter through `Dispatch_Native_Request`, which requires a native runtime
identifier component before dispatching and returns `E_INVALIDARG` with
`Invalid_Argument` when a call arrives without native identity. The deterministic
UIA native-client probes use this strict entry point, so fixture-root and runtime
probe evidence exercises the same identity-admission rule intended for the
future COM bridge. The runtime probe also queries the root `AutomationId`
through that admitted native-boundary path and verifies the payload preserves
the neutral semantic identifier rather than deriving identity from a provider
address.
`Dispatch_Registered_Native_Request` is the COM-facing registry wrapper for
provider ids that already came from the session-local provider registry. It
resolves the stable provider id, derives the runtime identifier component from
the provider's `Node_Id`, admits the requested provider interface, dispatches
through `Dispatch_Native_Request`, and drains the provider call before
returning both successful replies and structured routed errors. If an
unexpected exception occurs after admission, it still attempts to end the
native call before returning `E_FAIL`, so unsupported provider methods cannot
leave shutdown-visible call accounting pinned.
`Dispatch_Registered_Native_Request_With_Report` preserves that behavior while
returning a `Registered_Native_Request_Report` with interface admission,
provider resolution, native identity preparation, begin/end native-call
mutation reports, reply status, and final status. COM bridge tests use this
report to prove unsupported interfaces are rejected before admission and
admitted calls are always drained.
The deterministic native client exposes the same path through
`native_client_uia --probe-registered-boundary`. The probe creates a
session-local provider, invokes a supported action through the registered
boundary, and reports `registered_boundary_report_complete`,
`registered_boundary_interface_supported`,
`registered_boundary_requested_interface`,
`registered_boundary_request_kind`, `registered_boundary_resolved_node`,
`registered_boundary_resolved_root`,
`registered_boundary_native_node_component`,
`registered_boundary_begin_outstanding_before`,
`registered_boundary_begin_outstanding_after`,
`registered_boundary_end_outstanding_before`, and
`registered_boundary_end_outstanding_after` so release tooling can prove
exact interface/request routing, stable native identity preparation, admission,
and cleanup without relying on COM-private object inspection.
Prepared UIA event emissions can be staged in a backend-private bounded FIFO
queue before the future COM event-posting layer drains them. The queue accepts
only publishable emissions, is configured from `Native_Array_Size`, reports
`Resource_Limit` and records overflow when full, rejects capacity shrinkage
below the current queued length, and clears overflow state only when explicitly
cleared. `Posting_Interest` exposes a no-side-effect bridge-facing snapshot of
length, capacity, overflow, and the next posting operation (`Post_Next_Event`,
`Back_Pressure`, or `No_Posting_Operation`) so future COM event drainers do not
duplicate queue policy. `Dequeue_For_Posting` is the bridge-facing admission
operation: it refuses overflow back pressure with `Resource_Limit` and preserves
pending events until the bridge explicitly clears the queue for recovery. The
behavior is tracked by `windows.uia.event_posting_admission`.
`Dequeue_For_Posting_With_Report` preserves that behavior and adds a bounded
`Posting_Attempt_Report` with length before/after, capacity, pending/overflow
state, admission and consumption flags, next operation, semantic source
`Node_Id`, semantic event sequence, semantic revision, and structured status
for the emission admitted to the native poster. Rejected posting attempts keep
empty semantic identity. The behavior is tracked by
`windows.uia.event_posting_report`. The
`Drain_For_Posting_Bounded` helper repeats that admission path only up to a
caller-supplied attempt limit and calls a bridge-provided poster for each
dequeued emission. Its `Posting_Drain_Report` records attempts, posted count,
before/after queue length, capacity, overflow state, stop reason, last attempted semantic source
`Node_Id`, last semantic event sequence, last semantic revision, and last structured
status. Callback failures keep the last attempted semantic identity in the
report. The behavior is tracked by
`windows.uia.event_posting_drain_bounded`. The
bridge-facing posting validator rejects nonpublishable emissions, missing
source or sequence identity, and normal notifications that do not carry a
prepared native object-cache id; destruction notifications may post through the
tombstone path without recreating a native object.
Direct native-callback admission is also gated before semantic provider
routing. Runtime probes cover missing, mismatched, and malformed runtime
identity. The conformance row is
`windows.uia.native_callback.hostile_admission`; the individual identity
variants are also tracked as
`windows.uia.native_callback.missing_identity`,
`windows.uia.native_callback.mismatched_identity`, and
`windows.uia.native_callback.malformed_identity`. Oversized text-edit payloads
are checked separately at the same boundary and tracked by
`windows.uia.native_callback.text_payload_limit`.
