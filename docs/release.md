# Release Guide

Release readiness is enforced by Ada tooling in the `a11y_tests` child crate
and by recorded manual assistive-technology evidence.

## Required Commands

Run the pinned toolchain commands from the repository root:

```sh
alr build
alr exec -- gnatprove -P a11ykit_proof.gpr --checks-as-errors=on
cd tests && alr build
alr exec -- gprbuild -q -P tests/all_tests.gpr
tests/bin/a11ykit_tests
tests/bin/uia_router_tests
tests/bin/nsax_router_tests
tests/bin/fixture_application --json
tests/bin/fixture_report --json
tests/bin/native_client_atspi
tests/bin/native_client_uia
tests/bin/native_client_nsax
tests/bin/native_observation_report --json
tests/bin/native_observation_report --require-native-conformance
tests/bin/capability_matrix --json
tests/bin/documentation_report --json
tests/bin/public_surface_audit --json
tests/bin/release_qualification --json
tests/bin/release_qualification --require-project-completion
tests/bin/release_qualification --native-client-artifact-status
tests/bin/release_qualification --linux-atspi-evidence-template
tests/bin/release_qualification --linux-atspi-host-evidence
tests/bin/release_qualification --linux-atspi-captured-evidence /path/to/linux-atspi-captured-evidence.json
tests/bin/release_qualification --windows-uia-evidence-template
tests/bin/release_qualification --windows-uia-captured-evidence /path/to/windows-uia-captured-evidence.json
tests/bin/release_qualification --macos-nsaccessibility-evidence-template
tests/bin/release_qualification --macos-nsaccessibility-captured-evidence /path/to/macos-nsaccessibility-captured-evidence.json
tests/bin/release_qualification --macos-nsaccessibility-native-client-artifact-status
tests/bin/release_qualification --captured-evidence-summary /path/to/linux-atspi-captured-evidence.json /path/to/windows-uia-captured-evidence.json /path/to/macos-nsaccessibility-captured-evidence.json
tests/bin/release_check
```

`tests/bin/nsax_router_tests` runs the large NSAccessibility suite through its Ada task-stack wrapper, so release runs invoke the binary directly and do not
depend on shell-specific stack setup.

`tests/bin/release_qualification --json` includes both
`conformance_feature_id` and `readiness_evidence_id` for each manual
assistive-technology scenario. The conformance id identifies the semantic or
native feature under test; the readiness evidence id identifies the native
observation blocker that the captured evidence would satisfy. Linux scenarios
must point at `linux_atspi_automated_native_qualification` after
the live AT-SPI vertical slice is observed.
`tests/bin/release_qualification --linux-atspi-evidence-template` emits the
Linux evidence record shape for that readiness id, including the required live
probe flags and the Orca/accessibility-inspector scenario rows that must be
filled from release-machine observations.
`tests/bin/release_qualification --linux-atspi-host-evidence` emits the Linux
host evidence supplement for that readiness id. It records OS-release, Orca
binary, busctl binary, host AT-SPI/session-bus environment availability, the
selected discovery source, and required native-probe facts. The required live
probe is `tests/bin/native_client_atspi --probe-external-client-host-env`,
which resolves `AT_SPI_BUS_ADDRESS` or `DBUS_SESSION_BUS_ADDRESS` through
hostkit and then exercises AT-SPI bus discovery through the real user session
bus. A sandbox denial on the session-bus socket is recorded as an
execution-environment condition, not as native backend evidence.
`tests/bin/release_qualification --linux-atspi-captured-evidence PATH` ingests
the captured Linux AT-SPI summary and emits
`org.a11y.linux_atspi_captured_evidence_status.v1`. The input must use schema
`org.a11y.linux_atspi_captured_evidence.v1`, readiness evidence id
`linux_atspi_automated_native_qualification`, `platform = Linux`,
`native_api = AT-SPI2`, and boolean fields for
`fixture_readiness_captured`, `tree_traversal_captured`,
`protected_text_captured`, `window_lifecycle_captured`,
`relations_captured`, `live_announcement_captured`, and
`action_requests_captured`. The status counts required, captured, and pending
Linux scenarios and allows the Linux native conformance claim only when all
seven required scenarios are captured. The command does not verify evidence
authenticity; it makes release-machine evidence accounting deterministic.
`tests/bin/release_qualification --windows-uia-evidence-template` and
`tests/bin/release_qualification --macos-nsaccessibility-evidence-template`
emit the corresponding public-client traversal evidence shapes. Their required
probe flags include `external_client_traversal_observed = true`; the Windows
template also requires `fragment_action_frame_status = SUCCESS`,
`fragment_action_frame_routed = ACTION_REQUEST`, and
`fragment_set_focus_payload_preserved = true`, while the macOS template
requires `element_id_dispatched = true` before AX traversal evidence can be
accepted. The current blocked probes intentionally report public traversal as
false until a real UIA or AX client process traverses the exported provider
tree.
`tests/bin/release_qualification --windows-uia-captured-evidence PATH` and
`tests/bin/release_qualification --macos-nsaccessibility-captured-evidence
PATH` ingest the captured public-client evidence summaries once those OS runs
exist. Windows input uses schema `org.a11y.windows_uia_captured_evidence.v1`
with readiness evidence id `external_uia_client_traverses_com_fragment_root`,
`platform = Windows`, `native_api = UI Automation`, and seven boolean scenario
fields: `tree_traversal_captured`, `focus_and_activation_captured`,
`protected_text_captured`, `relations_captured`,
`live_announcement_captured`, `window_lifecycle_captured`, and
`action_requests_captured`. macOS input uses schema
`org.a11y.macos_nsaccessibility_captured_evidence.v1` with readiness evidence
id `external_ax_client_traverses_appkit_element_tree`, `platform = macOS`,
`native_api = NSAccessibility`, the same seven common scenario booleans, plus
`switch_access_captured` and `voice_control_captured`. The normalized status
JSON marks the platform native conformance claim as allowed only when every
required scenario for that platform is captured.
`tests/bin/release_qualification --captured-evidence-summary LINUX WINDOWS
MACOS` combines those three status documents into
`org.a11y.captured_evidence_summary.v1`. A full native release claim requires
23 captured scenarios: 7 Linux, 7 Windows, and 9 macOS. Partial or invalid
platform evidence leaves the aggregate `native_conformance_claim_allowed`
false and preserves the pending count.

The release gate treats the Alire manifest and lockfile as authoritative for
the toolchain package pin: both the root crate and `a11y_tests` must resolve
`gnat_native = "=15.2.1"` and the lockfiles must provide `gnat=15.2.1`.
The upstream GNAT executable banner may print its compiler version separately
from the Alire package release.

The GNATprove release command currently gates the proof-ready primitive slice
through `a11ykit_proof.gpr`. That project excludes generated localization data
and native backend packages so the report is stable and actionable. A passing
release proof run must use `--checks-as-errors=on` and currently proves 2,077
checks with zero unproved checks across `A11y`, `A11y.Node_Ids`,
`A11y.Actions`, `A11y.Actions.Classification`,
`A11y.Backends.Classification`,
`A11y.Backends.Default_Classification`,
`A11y.Backends.Selection`,
`A11y.Backends.Selection.Classification`,
`A11y.Backends.Transport_Classification`,
`A11y.Capabilities`, `A11y.Roles`,
`A11y.Conformance.Classification`, `A11y.Diagnostics.Classification`,
`A11y.Dispatchers`, `A11y.Dispatchers.Classification`,
`A11y.Documents`, `A11y.Documents.Classification`,
`A11y.Images`, `A11y.Images.Classification`, `A11y.Event_Queues`,
`A11y.Event_Queues.Classification`,
`A11y.Event_Subscriptions`,
`A11y.Event_Subscriptions.Classification`,
`A11y.Events.Classification`, `A11y.Live_Regions`,
`A11y.Live_Regions.Classification`,
`A11y.Native_Boundary_Calls`,
`A11y.Native_Boundary_Calls.Classification`,
`A11y.Native_Callbacks`, `A11y.Native_Callbacks.Classification`,
`A11y.Native_Identity`, `A11y.Native_Identity.Classification`,
`A11y.Native_Object_Caches`, `A11y.Native_Object_Caches.Classification`,
`A11y.Native_Runtimes`,
`A11y.Native_Runtimes.Classification`,
`A11y.Nodes.Classification`,
`A11y.Platforms.Classification`,
`A11y.States`, `A11y.Geometry`,
`A11y.Resource_Limits`, `A11y.Properties`,
`A11y.Properties.Classification`, `A11y.Results`,
`A11y.Results.Classification`, `A11y.Relations`,
`A11y.Relations.Classification`,
`A11y.Selection`, `A11y.Selection.Classification`,
`A11y.Tables.Classification`,
`A11y.Text`, `A11y.Text.Classification`,
`A11y.Trees.Classification`,
`A11y.Values`, `A11y.Values.Classification`,
`A11y.Windows`, `A11y.Windows.Classification`, and
`A11y_Proof_Harness`. Broader SPARK coverage remains a future hardening task;
do not describe the full library as formally proved.

On Linux machines with a dedicated accessibility bus available, run the
optional live AT-SPI probe with an explicit address:

```sh
tests/bin/native_client_atspi --probe-boundary
tests/bin/native_client_atspi --probe-fixture-root
tests/bin/native_client_atspi --probe-serving-packet
tests/bin/native_client_atspi --probe-session-dispatch
tests/bin/native_client_atspi --probe-external-client-host-env
tests/bin/native_client_atspi --probe-external-client-session-bus-address=unix:path=/path/to/session-bus
tests/bin/fixture_application --atspi-address=unix:path=/path/to/bus
tests/bin/fixture_application --atspi-env-address=unix:path=/path/to/bus
tests/bin/fixture_application --atspi-host-env
tests/bin/fixture_application --atspi-serve-address=unix:path=/path/to/bus --atspi-serve-iterations=16 --atspi-serve-timeout-ms=250
tests/bin/fixture_application --atspi-serve-host-env --atspi-serve-iterations=16 --atspi-serve-timeout-ms=250
tests/bin/native_client_atspi --probe-session-bus-address=unix:path=/path/to/session-bus
tests/bin/native_client_atspi --probe-address=unix:path=/path/to/bus
tests/bin/native_client_atspi --probe-env-address=unix:path=/path/to/bus
tests/bin/native_client_atspi --probe-host-env
```

If no desktop accessibility bus is available, start a temporary local D-Bus
session bus and run the same session-bus discovery and external-client path
against it:

```sh
dbus-daemon --session --nofork --print-address --address=unix:path=/tmp/a11ykit-atspi-test-bus
tests/bin/native_client_atspi --probe-session-bus-address=unix:path=/tmp/a11ykit-atspi-test-bus
DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/a11ykit-atspi-test-bus tests/bin/native_client_atspi --probe-external-client-host-env
```

The external-client JSON must include `status = SUCCESS`,
`failure_stage = none`, `provider_registered = true`,
`provider_registration_auth_response_status = SUCCESS`,
`client_hello_completed = true`, `external_traversal_completed = true`,
`external_protected_value_suppressed = true`,
`event_loop_registered_method_calls` greater than zero, matching
`event_loop_registered_replies`, and `stop_status = SUCCESS`. Restricted
automation environments may require explicit permission for local Unix socket
access before these probes can connect.

These AT-SPI commands default the EXTERNAL authentication user id from
`Hostkit.Process.Current_User_Id`. Add `--atspi-uid=UID` or `--probe-uid=UID`
only when the qualification environment requires an explicit override.
`--probe-host-env` reads host environment values through hostkit. It reports
exact `startup_source` values, redacted
`host_at_spi_bus_address_present` and `host_session_bus_address_present`
booleans, and `host_discovery_source` as `at_spi_bus_address`,
`dbus_session_bus_address`, or `missing_host_environment`. When
`AT_SPI_BUS_ADDRESS` is absent but `DBUS_SESSION_BUS_ADDRESS` is present, the
probe uses the staged `org.a11y.Bus.GetAddress` session-bus discovery path
before attempting AT-SPI application-bus admission. The probe also reports
registration queue and reply fields such as `registration_hello_queued`,
`registration_hello_reply_received`, `registration_application_queued`, and
`registration_application_reply_status`. These fields are carried by
`Session_Startup_Report`, so fixture and client processes consume the same
backend startup evidence.

The direct and environment AT-SPI probes emit `startup_prepared`,
`startup_backend_synchronized`, `registration_raw_connected`,
`registration_transport_admitted`, `registration_hello_reply_status`,
`registration_application_reply_status`, `registration_pending_outgoing`,
`registration_in_flight_outgoing`, `registration_stage_status`,
`event_loop_next_operation`, `event_loop_pump_status`, and bounded
event-loop queue counters so release
evidence can distinguish invalid addresses, missing sockets, auth failures,
partial `Hello`, and failed application admission without reading backend
private state.
They also emit `startup_backend_sync_status`,
`startup_backend_sync_before_state`, `startup_backend_sync_after_state`,
`startup_backend_sync_transport_admission_attempted`, and
`startup_backend_sync_start_attempted` so unavailable startup evidence proves
that the common native backend was not falsely admitted or started.

Without `--probe-address`, `native_client_atspi` emits the deterministic
portable observation report used by CI. With `--probe-boundary`, it creates a
session-scoped AT-SPI object path, materializes that object in the registered
object registry, dispatches an `Accessible.GetRole` request through the
registered D-Bus method boundary, and emits
`org.a11y.native_client_atspi_boundary_probe.v1` JSON. The same boundary probe
also dispatches Action count and Action name requests through the registered
D-Bus method boundary, proving action discovery can cross object-registry
admission before live bus transport is complete. It also dispatches an
`Action.DoAction` request and verifies the neutral action payload preserved by
the D-Bus boundary while reporting native-call completion and drained registry
state separately. With
`--probe-fixture-root`, it uses the deterministic fixture application
`Node_Id` as the native AT-SPI object, dispatches `Accessible.GetName`
through the same registered boundary, verifies the fixture root name payload,
then dispatches `Accessible.GetChildCount` and `Accessible.GetChildAtIndex`
to prove the deterministic main-window child is reachable from the root, then
registers that child as its own native AT-SPI object and dispatches child
`Accessible.GetName` and `Accessible.GetRole` queries through the same
boundary.
It reports native-call completion and drained registry state, and emits
`org.a11y.native_client_atspi_fixture_root.v1` JSON.
With `--probe-serving-packet`, it exercises the fixture root through the
registered packet-serving path and emits
`org.a11y.native_client_atspi_serving_packet_probe.v1` JSON after the encoded
method-call, registered dispatch, queued reply, serialized reply, decoded
payload, and outgoing bookkeeping drain have completed. The serving-packet
evidence is also summarized in native-client reports with
`has_linux_atspi_serving_packet_core_observations`,
`has_linux_atspi_serving_packet_tree_traversal_observation`,
`has_linux_atspi_serving_packet_interaction_observations`,
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
`has_linux_atspi_serving_packet_text_payload_limit_observation`, and the aggregate
`has_linux_atspi_serving_packet_full_observations`. It also records
the malformed-packet and text-payload-limit booleans as true only on the AT-SPI
row in the aggregate native observation JSON, so hostile Linux D-Bus client
evidence cannot be counted for UIA or NSAccessibility rows. It also records
`has_linux_atspi_serving_packet_property_observation` for the D-Bus
`Properties.Get(Accessible.Name)` request and variant string reply. The same
registered packet-serving layer now also covers
`Properties.GetAll(Accessible)` with the standard `a{sv}` property-map reply
and records `has_linux_atspi_serving_packet_property_map_observation` from
the raw `property_map_reply_decoded` and
`property_map_reply_bookkeeping_drained` probe phases.
The probe verifies
the raw `accessible_tree_traversal_completed` marker after child-count,
indexed-child, children-list, parent, and index-in-parent replies decode and
their outgoing bookkeeping drains. It also verifies
`Accessible.GetName`, `Application.GetID`, `Properties.Get(Accessible.Name)`,
`Properties.GetAll(Accessible)`,
`Accessible.GetRole`,
`Accessible.GetState`, `Accessible.GetChildCount`,
`Accessible.GetInterfaces`, `Accessible.GetChildAtIndex`, `Accessible.GetChildren`,
`Accessible.GetAttributes`, `Accessible.GetRelationSet`, `Accessible.GetParent`,
`Accessible.GetIndexInParent`, `Action.GetNActions`,
`Action.GetName`, `Action.DoAction`, `Component.GetExtents`,
`Component.Contains`, `Component.GetAccessibleAtPoint`,
`Value.GetCurrentValue`, `Value.GetMinimumValue`, `Value.GetMaximumValue`,
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
`Table.GetSortKey`, `Document.GetLocale`, and `Document.IsLandmark`
as separate encoded method-call packets, plus
`Document.GetAttributeValue("title")` as an encoded string-argument packet,
and an unregistered object-path call that must decode as the stable AT-SPI
`NoSuchObject` error, plus a registered object call through an unsupported
interface that must decode as stable AT-SPI `NotSupported`, with outgoing
bookkeeping drained.
`Text.GetText` is encoded with a D-Bus `uu` start/end range body rather than
the coordinate `ii` form used for component hit testing and table coordinates.
`EditableText.InsertText` is encoded with a D-Bus `uus` range/replacement body
and returns a boolean accepted/rejected method reply.
`Accessible.GetAttributes` and `Accessible.GetRelationSet` are decoded from
bounded `a{ss}` and `a(uao)` method-return payloads, with relation object paths
resolved back to session-scoped semantic node identities.
`EditableText.DeleteText` is encoded with a D-Bus `uu` range body and returns
the same boolean accepted/rejected method reply.
`EditableText.ReplaceText` is encoded with the D-Bus `uus` range/replacement
body and `EditableText.SetTextContents` is encoded with the D-Bus `s`
replacement body; both return the same boolean accepted/rejected method reply.
With `--probe-session-dispatch`, it emits
`org.a11y.native_client_atspi_session_dispatch_probe.v1` JSON and verifies that
the backend-session decoded-call entry point rejects pre-registration object
path calls without materializing native objects. The probe also records the
session-boundary report fields (`session_boundary_resolved`,
`session_boundary_admitted`, `session_boundary_completed`,
`session_boundary_drained`, and `session_boundary_final_status`) so release
checks can prove that rejected pre-registration calls leave no outstanding
native-call bookkeeping. The aggregate native observation report carries the
same evidence as
`has_linux_atspi_session_dispatch_boundary_drain_observation`. The same probe
also records `session_event_loop_report_captured` and the cached
`session_event_loop_status`, `session_event_loop_stop_reason`, and
`session_event_loop_last_operation` fields; aggregate reports expose this as
`has_linux_atspi_session_dispatch_loop_report_observation`.
The portable semantic suite also exercises the registered AT-SPI serving
packet path: an encoded D-Bus method-call packet resolves through the object
registry, dispatches against semantic snapshots, queues a method-return packet,
serializes it for transport, decodes it again, and drains outgoing reply
bookkeeping. This is backend-private serving-path evidence, not a replacement
for live accessibility-bus qualification.
With
`fixture_application --atspi-address=...`, the deterministic fixture process
starts the owned Linux AT-SPI backend session against the supplied
accessibility bus address, using the fixture application `Node_Id` as the
application root, and emits `org.a11y.fixture_atspi_startup.v1` JSON. This is
the native-qualification fixture startup path; it keeps normal `--ready` and
`--json` fixture modes portable and backend-free.
The serve mode is driven through the session-level bounded event-loop API, so
read, dispatch, reply, and registered boundary counters are reported from the
same primitive intended for host event-loop integration.
The startup JSON includes stage booleans for preparation, backend
synchronization, application-root export, raw connection, EXTERNAL auth,
Hello, and application registration. Controlled failures such as an invalid
address or a missing Unix socket must show the exact failed stage instead of a
single generic unavailable result.
`fixture_application --atspi-env-address=...` exercises the same backend
session path through the `AT_SPI_BUS_ADDRESS` value parser and reports
`startup_source` as `environment_value`.
`fixture_application --atspi-host-env` exercises the fixture startup path
through hostkit environment discovery and emits the same redacted startup
source fields as the AT-SPI host-env probe.
`native_client_atspi --probe-host-env` exercises the hostkit-backed live
environment path, records which host environment source was selected without
logging address values, and records the
`linux.dbus.host_environment_startup` conformance evidence.
With `fixture_application --atspi-serve-address=...`, the same fixture starts
the owned backend session, materializes the application root after registration,
verifies root role plus deterministic root child traversal readiness, then runs
bounded `Drive_One_Event_Loop_Step` calls over the fixture root snapshots and
emits `org.a11y.fixture_atspi_serve.v1` JSON with event-loop step counts,
aggregate pump counts, `event_loop_can_read`, `event_loop_can_write`,
`event_loop_can_dispatch`, `event_loop_has_outgoing_work`, the configured
`read_timeout_ms`, the last-step `event_loop_after_next_operation` and
`event_loop_after_*` readiness fields, `event_loop_step_status`,
`last_event_loop_stop_reason`, and shutdown status.
`fixture_application --atspi-serve-host-env` follows the hostkit environment
startup path before running the same bounded serve report. Use it on native
release hosts where `AT_SPI_BUS_ADDRESS` or `DBUS_SESSION_BUS_ADDRESS` should
remain an environment concern rather than a command-line value.
`native_observation_report` records this as
`fixture_host_env_serve_command`, and records
`native_client_atspi --probe-host-env` as `host_environment_probe_command`,
keeping the release checklist and generated evidence aligned.
The timeout lets a release harness start the fixture before an external AT-SPI
client sends the first method call, while keeping the server bounded.
With
`--probe-session-bus-address`, it connects to a supplied D-Bus session bus,
authenticates, sends Hello, calls `org.a11y.Bus.GetAddress`, prepares the
returned accessibility bus address, then attempts application registration and
emits `org.a11y.native_client_atspi_session_probe.v1` JSON. The session probe
also reports the same startup and registration stage fields, including reply
serial/status and pending/in-flight outgoing counts, so failures before
`GetAddress` are distinguishable from failures after the accessibility-bus
address has been prepared.
With `--probe-external-client-host-env`, the native client resolves
`AT_SPI_BUS_ADDRESS` or `DBUS_SESSION_BUS_ADDRESS` through hostkit, starts a
provider from that bus, opens a separate client connection to the discovered
accessibility bus, sends external `Accessible.GetName`,
`Accessible.GetRole`, `Accessible.GetChildCount`, and
`Accessible.GetChildAtIndex` method calls to the provider's unique bus name and
application object path, follows the returned main-window child object path for
child `Accessible.GetName` and `Accessible.GetRole`, drives the registered
provider loop, and emits
`org.a11y.native_client_atspi_external_client_probe.v1` JSON. The release
evidence requires `external_traversal_completed`,
`provider_dispatched_external_request`, `provider_wrote_external_reply`,
`client_reply_name_matched`, `external_role_matched`,
`external_child_count_matched`, `external_child_at_index_matched`,
`external_child_name_matched`, `external_child_role_matched`, and `stop_status`
= `SUCCESS` to distinguish
this live bus-routed traversal from the deterministic in-process serving-packet
probe. Failed runs include `failure_stage` to identify the blocked layer:
provider startup, provider registration, accessibility-bus discovery, client
connection, hello, external method call encoding or send, provider event-loop
dispatch, reply handling, or semantic traversal.
The native observation summary separates this from manual assistive-technology
qualification: when the live AT-SPI core/interaction/content/surface/live-region
slice rows are present it emits `native_vertical_slice_observed = true` and
sets the Linux `next_required_evidence` to
`linux_atspi_automated_native_qualification`.
path and to prove shutdown released exported native roots and children. With
`--probe-address`, it attempts the hostkit-backed local-channel startup path
against a supplied accessibility bus address, authenticates, sends Hello,
registers the application root, and emits
`org.a11y.native_client_atspi_probe.v1` JSON with `prepared`, `started`,
`registered`, connection `state`, and structured status fields.

Windows and macOS client-process probes can exercise the native runtime,
backend-private event publication boundary, native provider/element lifecycle,
admitted native-call path, and a provider-boundary property or attribute query
without requiring a live COM or AppKit provider session:

```sh
tests/bin/native_client_uia --probe-runtime
tests/bin/native_client_uia --probe-fixture-root
tests/bin/native_client_nsax --probe-runtime
tests/bin/native_client_nsax --probe-fixture-root
```

The `--probe-runtime` commands emit `org.a11y.native_client_uia_probe.v1` and
`org.a11y.native_client_nsax_probe.v1` JSON. They prove that the client process
starts the common native runtime, prepares a semantic event, resolves the
backend native object, builds a publishable UIA or NSAccessibility event
envelope, creates the native provider or element object, admits and completes a
native call until the provider or element is drained, verifies Windows
host-window root binding and macOS main-thread and native-view binding,
dispatches a name/title query plus root
AutomationId/NSAccessibilityIdentifier query through the provider boundary,
and dispatches
action discovery plus one native action request while preserving the
backend-private pattern/action payload and neutral semantic `Action_Id`. The
same runtime probes now dispatch a native-boundary text range query and text
insert, delete, replace, and set-text edit requests, preserving the neutral
text fragment and `Text_Edit_Request` payloads before the native call drains.
The Windows UIA and macOS NSAccessibility runtime probes also dispatch table
current-cell, sort-order, and sort-key queries through their provider
boundaries and preserve the stable `Node_Id` and neutral sort-order payloads.
The same probes now dispatch document, image, live-region, and surface metadata
queries, preserving document title and heading level, image alternative text
and intrinsic size, live-region setting and atomicity, and surface kind and
active-state payloads.
They also dispatch current-value queries, staged value-set requests, selection
counts, selected-item queries, and staged selection requests, preserving neutral
`Semantic_Value` payloads and stable selection `Node_Id` targets. The Windows
UIA and macOS NSAccessibility runtime probes now exercise item toggle,
select-all, and clear-selection writes and report
`selection_request_payload_preserved`,
`selection_select_all_payload_preserved`, and
`selection_clear_payload_preserved`.
Registered UIA and NSAccessibility boundary tests also reject runtime identity
mismatches before begin-call admission, proving stale or cross-snapshot native
references cannot pin a provider or element before the semantic identity check.
The aggregate native observation report mirrors those presentation-integration
assumptions through
`has_windows_uia_host_window_root_binding_observation`,
`has_windows_uia_metadata_property_observation`,
`has_windows_uia_protected_value_observation`,
`has_windows_uia_selection_select_all_observation`,
`has_windows_uia_selection_clear_observation`,
`has_macos_nsax_main_thread_binding_observation`,
`has_macos_nsax_native_view_binding_observation`,
`has_macos_nsax_metadata_attribute_observation`,
`has_macos_nsax_protected_value_observation`,
`has_macos_nsax_selection_select_all_observation`, and
`has_macos_nsax_selection_clear_observation`, while still keeping
`native_conformance_ready` false until live OS transports and native clients
are qualified.
The same aggregate report records `runtime_probe_command` for the UIA and
NSAccessibility clients so release logs identify the direct probe executable
that produced this scaffold evidence.
The same runtime probes now exercise hostile direct native-callback admission:
missing identities, mismatched identities, malformed identities, and oversized
text edit payloads must be rejected before semantic provider routing.
The corresponding conformance rows are
`windows.uia.native_callback.hostile_admission` and
`macos.nsaccessibility.native_callback.hostile_admission` for identity
admission, `windows.uia.native_callback.missing_identity`,
`windows.uia.native_callback.mismatched_identity`,
`windows.uia.native_callback.malformed_identity`,
`macos.nsaccessibility.native_callback.missing_identity`,
`macos.nsaccessibility.native_callback.mismatched_identity`, and
`macos.nsaccessibility.native_callback.malformed_identity` for the individual
identity variants, and `windows.uia.native_callback.text_payload_limit` and
`macos.nsaccessibility.native_callback.text_payload_limit` for text payload
limits. The native client report JSON exposes
`has_windows_uia_host_window_root_binding_observation`,
`has_windows_uia_hostile_callback_admission_observation`,
`has_windows_uia_missing_identity_observation`,
`has_windows_uia_mismatched_identity_observation`,
`has_windows_uia_malformed_identity_observation`,
`has_windows_uia_text_payload_limit_observation`,
`has_macos_nsax_main_thread_binding_observation`,
`has_macos_nsax_native_view_binding_observation`,
`has_macos_nsax_hostile_callback_admission_observation`,
`has_macos_nsax_missing_identity_observation`,
`has_macos_nsax_mismatched_identity_observation`,
`has_macos_nsax_malformed_identity_observation`, and
`has_macos_nsax_text_payload_limit_observation`.
They also emit
`probe_status` and `failure_stage` so release logs identify the exact
runtime probe stage that failed before platform-native client qualification is
available.
The Windows and macOS `--probe-fixture-root` variants emit
`org.a11y.native_client_uia_fixture_root.v1` and
`org.a11y.native_client_nsax_fixture_root.v1` JSON using the deterministic
fixture application `Node_Id` as the provider or element root, then dispatch a
fixture-root name/title query through the same native boundary scaffolds. They
also dispatch deterministic first-child traversal through UIA fragment
navigation and NSAccessibility hierarchy child lookup, then materialize the
child provider/element in the native registry. The child is queried through its
own native-boundary name/title and role/control-type paths and then resolves
its parent through native hierarchy navigation before proving the native
provider or element call drains after completion. They also exercise the
native registry drained-reset path and report that both post-reset node lookup
plus root and child stale native id resolution are rejected with structured node
unavailable results.
The aggregate native observation JSON exposes these as distinct registry reset node-rejection and stale-id rejection fields for Linux, Windows, and macOS evidence.
All fixture-root probes additionally emit `probe_status`, `failure_stage`,
`fixture_root_child_count_dispatched`, `fixture_root_second_child_dispatched`,
and
`fixture_child_native_identity_dispatched`, and
`fixture_second_child_parent_dispatched` and
`fixture_second_child_native_identity_dispatched` and
`fixture_sibling_order_dispatched` fields so release logs can identify the
exact lifecycle stage that failed and prove indexed multi-child root
traversal, second-child reverse traversal, sibling ordering, and stable
native-identity projection before platform-native qualification is available.
The Windows and macOS root probes also record `native_call_token`,
`native_call_start_generation`, `native_call_final_generation`, and
`native_call_active_after_completion`, so release logs retain concrete
boundary-call generation evidence instead of only boolean drain status.
The Windows and macOS runtime probes additionally record native focus query
and set-focus dispatch evidence through `native_focus_query_dispatched`,
`native_focus_query_payload_preserved`, `native_set_focus_dispatched`, and
`native_set_focus_payload_preserved`. The normalized native-client report
promotes that evidence to
`has_windows_uia_native_focus_query_observation`,
`has_windows_uia_native_set_focus_observation`,
`has_macos_nsax_native_focus_query_observation`, and
`has_macos_nsax_native_set_focus_observation`.
These probes do not replace the manual/live UI Automation or Accessibility
Inspector qualification evidence required for release.

## Release Gate

`tests/bin/release_check` validates conformance declarations, fixture
application JSON, fixture report JSON, native observation JSON, capability JSON,
documentation JSON, qualification JSON, native projection claims, and
project_tools JSON availability. It also validates root and child Alire
manifests, including the `a11y_tests` project-file binding to `all_tests.gpr`,
the shared `gnat_native = "=15.2.1"` toolchain pin, the matching root and child
Alire lockfile resolution with `gnat=15.2.1`, and checks that the child
aggregate GPR still includes the portable/UIA and macOS router test projects.
It also verifies that the root project links the sibling `hostkit` crate for
general platform facilities and that the test/tool project links
`project_tools`.
The public-surface audit check keeps common
semantic public APIs from exposing native accessibility tokens. The gate
validates the typed native-client report predicates before checking emitted
JSON, so blocked transport evidence, protected-text redaction, stale-reference
coverage, and semantic-node identity projection cannot be weakened by changing
report text alone.
The emitted native observation JSON must also preserve grouped AT-SPI, UIA, and
NSAccessibility coverage booleans so backend-family evidence is machine
readable at the aggregate report level.
Backend-specific release checks also pin the common
`native.object_cache.identity`, `native.object_export_descriptor`,
`native.object_cache.node_index`, `native.object_cache.tombstone`, and
`native.object_cache.session_scope` rows for AT-SPI, UIA, and NSAccessibility;
native action-payload retention, native runtime lifecycle, native runtime event
application and preparation, native property/action/relation/event-source
projection, native event validation, posting-boundary validation, exhaustive
native event/role/relation mapping, deterministic native shutdown, and diagnostic evidence
rows; the AT-SPI
object registry; AT-SPI native cache/lifetime/value resource limits; hostile
identity rejection; malformed request mapping; UIA
provider registry; UIA COM lifetime; UIA native-value ownership; macOS
NSAccessibility element registry; macOS element lifetime; macOS native-value
ownership; prepared-status handoff; and native lifetime/value resource-limit
conformance rows; distinct native-value resource-limit observation evidence;
and the Linux D-Bus method-return decode boundary, so stable
conformance rows; and the Linux D-Bus error-return decode boundary, so stable
native-object registry, runtime, shutdown, prepared-event failure propagation,
startup reply/error typing, inverse native error-name mapping, Linux
error-name diagnostics, Linux AT-SPI role/state/object-path mapping, method
routing, application metadata, Accessible core methods, Component geometry and
hit testing, Action discovery/invocation, Value current/range/set requests, and
Selection count/child/request methods, Text range/caret/protected/edit methods,
Table dimension/cell/span methods, Image description/caption/category/size/
decorative omission,
Document locale/attribute/heading/landmark/author/subject/version/revision/
pagination methods, Surface metadata/routing,
AT-SPI focus/text/lifecycle/prepared-publication signals, Cache node projection,
Windows UIA core/text/bounds properties, action map/request routing,
set-focus/open/scroll/close routing, event map/details, prepared-event
emission/routing/boundary, fragment navigation, runtime-id, relation routing,
Windows UIA value/selection/text/table/image/document/surface routing,
Linux AT-SPI surface stable kind names and operation-capability routing,
AT-SPI/UIA/NSAccessibility live-region metadata, relevance, and bounded mapper
routing, Linux AT-SPI live-region D-Bus method routing,
UIA/NSAccessibility live-region request-router/provider-boundary routing,
AT-SPI/UIA/NSAccessibility structural integer property routing,
request-router/provider-boundary coverage, provider registry, COM lifetime,
COM export descriptor, native-value ownership, bridge-audit contracts,
Linux D-Bus
unsupported-value handling, Linux D-Bus
UInt32-array handling, Linux D-Bus state-set UInt32-array validation, Linux
D-Bus string-array handling, Linux D-Bus attribute string-array validation,
Linux D-Bus cache interface string-array validation, Linux D-Bus
object-path-array handling, Linux D-Bus relation-target
object-path-array validation, Linux D-Bus connection lifecycle, local-channel
adapter, local-channel receive, startup controller, startup pump, pump bounds,
bus-address validation, EXTERNAL auth, auth exchange, authenticated connect,
Hello, authenticated Hello, registration completion, authenticated
registration, staged registration reporting, backend session startup reporting
for direct, environment, and session-bus startup,
application registration, address discovery, GetAddress,
authenticated GetAddress, startup session discovery, transport frame metadata, frame-byte
encoding, frame send, packet construction, packet send, packet decode,
startup event-loop interest, codec
basic coverage, resource-limit validation, message envelope construction,
method-call envelope construction, transport envelope decode, incoming-call
decode, signal envelope construction, prepared-signal envelope construction,
method-boundary routing,
inverse HRESULT mapping, HRESULT diagnostics,
inverse macOS native-status mapping, macOS
native-status diagnostics, macOS NSAccessibility core/text/frame attributes,
action map/request routing, open/close/set-focus/scroll-to-visible routing,
event map/details, prepared-event emission/routing/boundary, hierarchy,
element-id, relation routing, macOS NSAccessibility
value/selection/text/table/image/document/surface routing,
request-router/provider-boundary coverage, element registry, element lifetime,
element export descriptor, native-value ownership, bridge-audit contracts,
error-return diagnostics, and ownership coverage
cannot disappear behind a still-valid aggregate matrix count.

## Qualification Evidence

Manual evidence must record operating-system versions, assistive-technology
versions, fixture scenario, steps, expected behavior, observed behavior, and
known limitations. The generated checklist includes Orca, NVDA, Narrator,
VoiceOver, Switch Control, Voice Control, and native inspection tools; the
release gate rejects stale qualification JSON when those fields or tool
families are missing. The JSON coverage summary also reports pending and
captured evidence counts overall and required, pending, and captured evidence
counts per platform. The required count is stable and does not shrink as
scenario evidence is captured. Every scenario records `qualification_status`,
so the current checklist cannot be mistaken for completed native
assistive-technology evidence. Window/surface lifecycle and fixture tree
traversal qualification are required on Linux, Windows, and macOS so surface
and hierarchy coverage are not limited to one native API.
`tests/bin/release_qualification --platform-evidence-summary` exposes the same
per-platform evidence summary as a standalone JSON array for release automation:
native API, readiness evidence id, qualification gate status, native boundary
stage, stable required scenario count, pending count, and captured count. The release gate cross-checks
those readiness evidence ids against `tests/bin/native_observation_report
--summary-json`, so checklist evidence cannot drift away from the backend
readiness blockers. The native observation summary includes the captured macOS
artifact path, state, and completion flag. Release tooling must treat
`incomplete_or_invalid` as a blocker; only `complete` means the
`vm/macos-nsax-native-client.txt` artifact satisfied the public
NSAccessibility client traversal gate.
Protected-text qualification is also required on all three platforms, and the
JSON coverage summary must prove that every platform has at least one
assistive-technology scenario before release evidence is accepted. Explicit
action-request qualification is required on Linux, Windows, and macOS for
activate, press, toggle, expand, collapse, show-menu, dismiss, open, close,
scroll-into-view, and set-focus mappings. Relation projection
and live-announcement qualification are also required on Linux, Windows, and
macOS so assistive-technology checks cover semantic cross-links and live
updates, not only static tree traversal.

## Failure Policy

Release fails on protected-text exposure, stale identity reuse, dangling
relations, event order violations, unbounded external work, native ownership
leaks, unsupported advertised native features, stale generated reports, or
missing documentation.

## Native Status

Do not claim production native provider support until live Linux, Windows, and
macOS native integration clients pass the same semantic scenarios.
The release check enforces this with
`Native_Production_Claims_Require_Evidence`: AT-SPI, UIA, and
NSAccessibility declarations may remain `Internal_Only` during scaffold work,
but `Exact`, `Equivalent`, or `Approximate` native declarations require matching
native client evidence. Linux AT-SPI currently records the first live
external-client slice as evidence-backed `Exact` conformance rows, with separate
generated markers for live child attribute projection and protected value
suppression plus live Component, Action, Value, Selection, Text, and Image method
coverage plus Document metadata, Table structure, and Surface metadata coverage
plus Live Region metadata coverage. Windows UIA now records native client
traversal evidence through its public-client probe. macOS NSAccessibility
remains `blocked_transport_unavailable` until a real macOS public AX client
traverses the exported AppKit element tree. Its client tool still provides a
deterministic external-client probe,
`native_client_nsax --probe-external-client`, so release artifacts record the
missing public AX traversal explicitly.
The root project file now admits the minimal native bridge translation units
only on their target platforms: `native/windows/a11y_uia_bridge.c` for Windows
UIA and `native/macos/a11y_nsaccessibility_bridge.m` for macOS
NSAccessibility. Linux release builds remain Ada-only with respect to those
non-target bridges. The macOS branch declares Objective-C language support and
links AppKit, Foundation, and ApplicationServices so the bridge can build
against the SDK without making Linux or Windows parse Apple framework
dependencies.
The Windows blocked probe also records the transport-facing COM boundary
sequence that exists before real OS-client traversal. Its ordered
`failure_stage` values distinguish `com_provider_export`,
`fragment_interface_query`, `fragment_navigation`, `runtime_identifier`,
`fragment_last_child_frame`, `pattern_provider_frame`, `bounding_rectangle_frame`,
`simple_property_frame`, `fragment_action_frame`,
`stale_interface_rejection`,
`com_object_token_release`,
`stale_object_token_rejection`, and the still-missing `external_uia_client`
stage. The detailed booleans include
`provider_export_observed`, `fragment_interface_queried`,
`metadata_name_preserved`, `metadata_identifier_preserved`,
`metadata_help_preserved`, `metadata_placeholder_preserved`,
`metadata_detail_preserved`, `protected_value_suppressed`,
`fragment_navigate_dispatched`, `fragment_runtime_id_dispatched`,
`fragment_last_child_frame_dispatched`, `pattern_provider_frame_dispatched`,
`bounding_rectangle_frame_dispatched`,
`simple_property_frame_dispatched`, `fragment_action_frame_dispatched`,
`fragment_action_frame_status`, `fragment_action_frame_routed`,
`fragment_set_focus_payload_preserved`,
`released_interface_rejected`,
`object_token_released`,
`released_object_token_rejected`, and `boundary_status`. These fields are evidence
for the live export boundary only; they do not satisfy
`external_uia_client_traverses_com_fragment_root` until a separate UI
Automation client process observes the exported fragment root through Windows.
The aggregate `internal_native_export_chain_ready` flag additionally requires
`embedded_fragment_roots_dispatched`, `provider_options_dispatched`,
`host_raw_element_provider_dispatched`, `fragment_root_dispatched`,
`root_point_dispatched`, `root_focus_dispatched`,
`fragment_last_child_frame_dispatched`, `pattern_provider_frame_dispatched`,
`bounding_rectangle_frame_dispatched`, `simple_property_frame_dispatched`, and
`fragment_action_frame_dispatched`, so the blocked probe must prove root
discovery, host-provider export, directed traversal, pattern discovery,
geometry, property retrieval, and successful SetFocus `ACTION_REQUEST` routing
with preserved neutral action payload as well as
traversal, metadata, and privacy-boundary preservation before it can count as
internally ready.
The macOS blocked probe records the equivalent registered element-boundary
sequence. Its ordered `failure_stage` values distinguish `appkit_bridge`,
`element_registration`, `hierarchy_children`, `hierarchy_children_frame`,
`hierarchy_child_at_index`, `hierarchy_child_at_index_frame`,
`element_identifier`, `attribute_value_frame`,
`attribute_settable_frame`,
`action_frame`,
`element_release_report`,
`element_release_tombstone`,
`released_element_resolve`, `stale_element_rejection`, and the still-missing
`external_ax_client` stage. The detailed booleans remain
`appkit_bridge_observed`,
`macos_nsax_virtual_element_bridge_audited`, `element_registered`,
`hierarchy_children_dispatched`, `hierarchy_children_frame_dispatched`,
`hierarchy_child_at_index_dispatched`,
`hierarchy_child_at_index_frame_dispatched`,
`element_id_dispatched`, `attribute_value_frame_dispatched`,
`attribute_settable_frame_dispatched`,
`action_frame_dispatched`,
`element_release_reported`,
`element_release_tombstone_recorded`,
`released_element_resolve_rejected`, `released_element_rejected`,
`metadata_label_preserved`, `metadata_identifier_preserved`,
`metadata_help_preserved`, `metadata_placeholder_preserved`,
`metadata_detail_preserved`, `protected_value_suppressed`, and
`action_frame_dispatched`; the aggregate `internal_native_export_chain_ready`
flag requires main-thread binding, native-view binding, the children and
child-at-index selector frames, and both attribute/action selector frames
together with element-chain, metadata, and privacy-boundary evidence.
`boundary_status`.
Those fields are evidence for the NSAccessibility boundary only; they do not
satisfy `external_ax_client_traverses_appkit_element_tree` until a separate AX
client process observes the exported AppKit element hierarchy. The artifact
therefore carries `public_ax_client_traversal_observed` as the explicit
public-client evidence bit; internal bridge readiness alone cannot set the
release-completion gate. It also carries
`macos_nsax_virtual_element_runtime_available` and
`macos_nsax_virtual_element_runtime_probe_observed`, which must both be true
before the completion gate accepts macOS native evidence but still do not
replace public AX-client traversal.
The normalized native client report must also include
`windows.uia.external_client.metadata`,
`windows.uia.external_client.embedded_fragment_roots_frame`,
`windows.uia.external_client.provider_options_frame`,
`windows.uia.external_client.host_raw_element_provider_frame`,
`windows.uia.external_client.fragment_root_frame`,
`windows.uia.external_client.fragment_root_point_frame`,
`windows.uia.external_client.fragment_root_focus_frame`,
`windows.uia.external_client.fragment_last_child_frame`,
`windows.uia.external_client.pattern_provider_frame`,
`windows.uia.external_client.bounding_rectangle_frame`,
`windows.uia.external_client.simple_property_frame`,
`windows.uia.external_client.fragment_action_frame` with successful
`ACTION_REQUEST` routing and preserved `Set_Focus` payload,
`windows.uia.external_client.protected_value`,
`macos.nsax.external_client.children_frame`,
`macos.nsax.external_client.child_at_index_frame`,
`macos.nsax.external_client.attribute_value_frame`,
`macos.nsax.external_client.attribute_settable_frame`,
`macos.nsax.external_client.action_frame`,
`macos.nsax.external_client.metadata`, and
`macos.nsax.external_client.protected_value` rows. These rows prove that the
blocked external probes preserved mapper-visible metadata and denied protected
value text; they are not native-client support claims and must remain paired
with `blocked_transport_unavailable` until OS clients traverse the exported
objects.
`native_observation_report` must also keep
`native_conformance_ready = false` until live OS transports and native client
observations prove the exported accessibility trees. Its readiness blocker rows
must expose both `internal_native_export_chain_ready` and
`public_client_traversal_observed`, because internal SDK-free export-chain
evidence is not equivalent to public UIA or AX client traversal. Each blocker
also exposes `remaining_evidence`, with stable values such as
`optional_assistive_technology_field_qualification`,
`external_uia_client_traversal_required`, and
`live_nsaccessibility_appkit_bridge_and_public_ax_client_traversal_required`,
so release tooling can distinguish internally ready blocked probes from the
external evidence still required. The report must expose
`has_windows_uia_external_client_failure_stage_observation` and
`has_macos_nsax_external_client_failure_stage_observation` so Windows and macOS
blocked external-client probes keep their precise missing OS-client stage in
aggregate release artifacts. Release checks also verify every normalized native
client observation `conformance_id` against the generated capability matrix and
require a non-`Unsupported` `AT-SPI`, `UIA`, or `NSAccessibility` declaration
for that identifier. Null and Disabled declarations do not satisfy native
client evidence. The report must
also preserve row-scoped native attribution through `native_evidence_scope`,
`row_scopes_atspi`, `row_scopes_uia`, and `row_scopes_nsaccessibility`; the
Linux, Windows, and macOS rows must each name exactly one native evidence
scope. The report must
also expose
fixture-root child traversal, fixture-child query dispatch, fixture-child
native object creation, fixture-child parent navigation, and fixture-child
stale identity rejection as separate columns and JSON booleans so root-only
probes cannot stand in for subtree coverage. Linux live-client reports must also
expose `has_linux_atspi_live_external_client_attribute_observation` and
`has_linux_atspi_live_external_client_protected_value_observation` so traversal
evidence cannot mask missing metadata or protected-text checks. The live AT-SPI
JSON report must also expose per-attribute child match flags for help text,
placeholder, value text, visible title, keyboard shortcut, semantic identifier,
locale, orientation, and landmark. The native client report must expose
`has_linux_atspi_live_external_client_attribute_detail_observations` and stable
`linux.atspi.live_external_client.attribute.*` rows for those fields. They must
also
expose `has_linux_atspi_live_external_client_component_observation` so live
client traversal cannot stand in for Component extents, contains, and hit-test
coverage. They must also expose
`has_linux_atspi_live_external_client_action_observation` so live client
traversal cannot stand in for Action count, name, and invocation coverage.
They must also expose `has_linux_atspi_live_external_client_value_observation`,
`has_linux_atspi_live_external_client_selection_observation`, and
`has_linux_atspi_live_external_client_text_observation` so live client
traversal cannot stand in for Value range/set, Selection mutation, or Text
range/caret coverage.
They must also expose `has_linux_atspi_live_external_client_image_observation`
so live client traversal cannot stand in for Image text alternative, caption,
kind, and size coverage.
They must also expose
`has_linux_atspi_live_external_client_document_observation` so live client
traversal cannot stand in for Document locale, landmark, and title metadata
coverage.
They must also expose `has_linux_atspi_live_external_client_table_observation`
so live client traversal cannot stand in for Table dimensions, cell lookup,
span, current-cell, and sort metadata coverage.
They must also expose `has_linux_atspi_live_external_client_surface_observation`
so live client traversal cannot stand in for Surface kind, role, visibility,
activation, modality, and operation-capability coverage.
They must also expose
`has_linux_atspi_live_external_client_live_region_observation` so live client
traversal cannot stand in for Live Region setting, relevance, atomic,
assertive, and external-announcement coverage.

## Project Completion Gate

`release_qualification --project-completion-gate` is the machine-readable gate
for the original three-backend scope. It uses automated native-client
conformance evidence, not manual screen-reader notes. Linux is satisfied by
`vm/linux-atspi-native-client.txt`; Windows is satisfied by
`vm/windows11/a11y-windows-native-client.txt`; macOS is satisfied only by
`vm/macos-nsax-native-client.txt`.

For the strict release gate, run:

```sh
tests/bin/release_qualification --require-project-completion
```

It emits the same JSON as `--project-completion-gate` and exits successfully
only when `original_scope_complete` is true.

For CI output that summarizes all canonical native artifacts without failing
the job, run:

```sh
tests/bin/release_qualification --native-client-artifact-status
```

For a strict gate that exits successfully only when all three canonical
artifacts are complete, run:

```sh
tests/bin/release_qualification --require-native-client-artifacts
```

The macOS artifact must be produced on macOS by the NSAccessibility native
client probe and must report a real AppKit bridge, no stub runtime,
`transport_status = native_client_available`, registered/main-thread-bound
elements, a public-root export path, stable public-root native identity,
children/child-at-index/attribute/action/hit-test/focused-element/notification
selector frames, preserved metadata, protected-value suppression,
privacy-boundary observation, external client traversal,
`native_conformance_ready = true`, `boundary_status = SUCCESS`, and final
`status = success`. Without that file, the completion gate must keep
`original_scope_complete = false` and name `macOS NSAccessibility` as the
missing backend.

Validate the captured macOS native-client artifact with:

```sh
tests/bin/release_qualification \
  --macos-nsaccessibility-native-client-artifact-status

tests/bin/release_qualification \
  --macos-nsaccessibility-native-client-artifact \
  vm/macos-nsax-native-client.txt
```

The no-argument status command checks the canonical
`vm/macos-nsax-native-client.txt` path and reports `artifact_state` as
`missing`, `incomplete_or_invalid`, or `complete` without requiring callers to
read or preflight the file themselves.
Strict release jobs that must fail until the canonical macOS artifact is
complete should run:

```sh
tests/bin/release_qualification \
  --require-macos-nsaccessibility-native-client-artifact
```

That command emits the same JSON as the status command and exits successfully
only when the artifact satisfies the public NSAccessibility client traversal
gate.

On a macOS worker, produce the canonical artifact with:

```sh
tests/bin/native_client_nsax --capture-external-client-artifact
```

The capture command writes the artifact and reports
`project_completion_gate_accepts_artifact` plus
`validation_missing_required_field_count` in its status JSON. The standalone
artifact validator additionally reports `missing_required_fields`, a stable
array of the exact gate fields that failed.
The macOS artifact includes the same nine scenario booleans as the macOS
captured-evidence schema plus required, captured, and pending scenario counts.
On a non-macOS stub run these scenario fields are false and the validator names
them in `missing_required_fields`; on an accepted run they must all be true
with `captured_scenario_count = 9` and `pending_scenario_count = 0`.
The accepted artifact must also report the public AX client smoke probe fields
as true: `macos_nsax_public_ax_client_runtime_available`,
`macos_nsax_public_ax_client_process_id_available`, and
`macos_nsax_public_ax_client_probe_observed`. These fields prove the
ApplicationServices client boundary was entered for a real process id and that
the client attempted application window, window-child, and root-role traversal
after the probe installed the AppKit process-root host. The full external-client
artifact combines those public AX probe fields with the AppKit export-chain,
metadata, stale-reference, and protected-text checks before it may set
`public_ax_client_traversal_observed = true`. The smoke probe can be run
directly with `tests/bin/native_client_nsax --probe-public-ax-client`; release
completion still requires the full external client artifact.

The validator and the project completion gate share the same required-field
predicate. A stub-runtime probe, a blocked transport probe, or a report missing
the completed evidence marker is rejected.

To test the complete gate against explicit artifact files without installing
them at the canonical `vm/` paths, run:

```sh
tests/bin/release_qualification \
  --project-completion-gate-from-artifacts \
  vm/linux-atspi-native-client.txt \
  vm/windows11/a11y-windows-native-client.txt \
  vm/macos-nsax-native-client.txt
```
