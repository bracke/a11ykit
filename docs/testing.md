# Testing Guide

The child crate `a11y_tests` owns repository test and release tooling. Tooling
is implemented in Ada and built with the pinned Alire toolchain. Its
`tests/alire.toml` manifest declares `project-files = ["all_tests.gpr"]`, so
`cd tests && alr build` builds the child crate through the same pinned
toolchain contract.

## Build And Test Commands

```sh
alr build
alr exec -- gnatprove -P a11ykit_proof.gpr --checks-as-errors=on
cd tests && alr build
alr exec -- gprbuild -q -P tests/all_tests.gpr
tests/bin/a11ykit_tests
tests/bin/uia_router_tests
tests/bin/nsax_router_tests
tests/bin/fixture_application --ready
tests/bin/fixture_application --json
tests/bin/fixture_application --atspi-address=unix:path=/path/to/bus
tests/bin/fixture_application --atspi-env-address=unix:path=/path/to/bus
tests/bin/fixture_application --atspi-host-env
tests/bin/fixture_application --atspi-serve-address=unix:path=/path/to/bus --atspi-serve-iterations=16 --atspi-serve-timeout-ms=250
tests/bin/fixture_application --atspi-serve-host-env --atspi-serve-iterations=16 --atspi-serve-timeout-ms=250
tests/bin/fixture_report --json
tests/bin/native_client_atspi
tests/bin/native_client_atspi --probe-env-address=unix:path=/path/to/bus
tests/bin/native_client_atspi --probe-host-env
tests/bin/native_client_atspi --probe-fixture-root
tests/bin/native_client_atspi --probe-serving-packet
tests/bin/native_client_atspi --probe-session-dispatch
tests/bin/native_client_atspi --probe-external-client-host-env
tests/bin/native_client_atspi --probe-external-client-session-bus-address=unix:path=/path/to/session-bus
tests/bin/native_client_uia
tests/bin/native_client_uia --probe-runtime
tests/bin/native_client_uia --probe-fixture-root
tests/bin/native_client_nsax
tests/bin/native_client_nsax --probe-runtime
tests/bin/native_client_nsax --probe-fixture-root
tests/bin/native_observation_report --json
tests/bin/native_observation_report --require-native-conformance
tests/bin/capability_matrix --json
tests/bin/documentation_report --json
tests/bin/public_surface_audit --json
tests/bin/release_qualification --json
tests/bin/release_qualification --require-project-completion
tests/bin/release_qualification --native-client-artifact-status
tests/bin/release_qualification --linux-atspi-evidence-template
tests/bin/release_qualification --windows-uia-evidence-template
tests/bin/release_qualification --macos-nsaccessibility-evidence-template
tests/bin/release_qualification --linux-atspi-captured-evidence /path/to/linux-atspi-captured-evidence.json
tests/bin/release_qualification --windows-uia-captured-evidence /path/to/windows-uia-captured-evidence.json
tests/bin/release_qualification --macos-nsaccessibility-captured-evidence /path/to/macos-nsaccessibility-captured-evidence.json
tests/bin/release_qualification --macos-nsaccessibility-native-client-artifact-status
tests/bin/release_qualification --captured-evidence-summary /path/to/linux-atspi-captured-evidence.json /path/to/windows-uia-captured-evidence.json /path/to/macos-nsaccessibility-captured-evidence.json
tests/bin/release_check
examples/bin/platform_neutral_provider_demo
```

`tests/bin/nsax_router_tests` is a small task-stack wrapper around the larger
`NSAX_Router_Test_Suite.Run` body. Run the binary directly as listed above; it
does not require shell-side stack changes such as `ulimit`.

Linux AT-SPI live probes and fixture startup default the EXTERNAL auth UID from
`Hostkit.Process.Current_User_Id`. Use `--atspi-uid=UID` or `--probe-uid=UID`
only when release qualification intentionally needs to override that hostkit
process identity.

The AT-SPI startup probes include event-loop readiness fields such as
`event_loop_next_operation`, `event_loop_pump_status`, and bounded outgoing
queue counters. Release checks require these fields so host event-loop
integration failures remain machine-readable.

The Windows UIA and macOS NSAccessibility `--probe-runtime` commands emit
`probe_status` and `failure_stage` fields for runtime, event-preparation,
native-object resolution, boundary query, root semantic identifier query,
action discovery, action request, payload preservation, and native call drain
classification.
They also report Windows host-window root binding and macOS
main-thread and native-view binding so presentation integration assumptions
remain visible.

## Semantic Tests

`tests/bin/a11ykit_tests` covers the portable semantic model, registry,
lifecycle, event queues, relations, actions, values, selection, text, tables,
documents, images, surfaces, diagnostics, typed property status mapping, Null
backend validation, and Linux AT-SPI mapper/method scaffolds.
The Null backend lifecycle tests reject non-lifecycle semantic events for
nodes that have only been created and for nodes that have been detached, so
only attached active nodes can publish ordinary semantic changes.
The Null backend event-order tests also reject stale semantic revisions without
advancing recorded history, lifecycle state, timestamp state, or sequence state.
It also verifies that the registered AT-SPI serving path round-trips semantic data through encoded D-Bus packets: a method-call packet is decoded, resolved
through the object registry, dispatched against semantic snapshots, queued as a
method-return packet, decoded again, and drained from outgoing bookkeeping.

## SPARK Proof Slice

`a11ykit_proof.gpr` is the current GNATprove entry point. It deliberately
selects only the proof-ready platform-neutral primitive slice so generated
localization tables, dispatchers, containers, and native boundary packages do
not hide useful proof results behind irrelevant proof noise. Run it with:

```sh
alr exec -- gnatprove -P a11ykit_proof.gpr --checks-as-errors=on
```

The current slice proves `A11y`, `A11y.Node_Ids`,
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
`A11y.Documents`, `A11y.Images`,
`A11y.Resource_Limits`, `A11y.Properties`,
`A11y.Properties.Classification`, `A11y.Results`,
`A11y.Results.Classification`, `A11y.Relations`,
`A11y.Relations.Classification`,
`A11y.Selection`, `A11y.Selection.Classification`,
`A11y.Tables.Classification`, `A11y.Text`, `A11y.Text.Classification`,
`A11y.Trees.Classification`,
`A11y.Values`, `A11y.Values.Classification`, `A11y.Windows`,
`A11y.Windows.Classification`, and the proof harness. The baseline report
proves 2,077 checks with no unproved checks: 479
data-dependency checks, 6 initialization checks, 154 run-time checks, 412
assertions, 498 functional contracts, and 528 termination checks. This is not
full-library SPARK coverage;
it is a clean proof gate and should be expanded package by package as semantic
primitives gain contracts.

## Native Router Tests

`tests/bin/uia_router_tests` and `tests/bin/nsax_router_tests` exercise
backend-private request routers, provider-boundary scaffolds, stale/hidden
node handling, protected text, bounded native values, and lifetime scaffolds
without claiming live OS provider registration.
Their text-edit cases check insert, replace, and set-text requests at both the
native request-router and provider-boundary layers, keeping neutral
`Text_Edit_Request` payload preservation visible before live OS transport
exists.
Native observation reports expose object-cache resource-limit evidence and
native-value resource-limit evidence separately, so BSTR/SAFEARRAY and
NSString/NSArray bounds remain visible in release qualification.

## Release Gates

`tests/bin/release_check` validates conformance declarations, generated
capability JSON, fixture JSON, release-qualification JSON, documentation
markers, public-surface native API leak checks, and release-tooling
availability. The documentation report includes top-level count and completion
markers in addition to per-document rows, and the gate checks both views.

## Public Surface Audit

`tests/bin/public_surface_audit` scans platform-neutral public package
specifications for native accessibility API terms and reports schema
`org.a11y.public_surface_audit.v1` with `--json`. The release gate requires
the audit to be complete and leak-free before native backend details may be
claimed as isolated. The audit resolves public specs from either the repository
root or the `tests/` child crate working directory, so release tooling can run
it consistently alongside the other test binaries.

## Examples

`examples/platform_neutral_provider_demo.adb` implements the public
`A11y.Nodes.Accessible_Node` interface, builds a small application/window/button
tree with stable `Node_Id` values, validates it through `A11y.Trees`, and runs
unchanged behind the platform-selected backend sources. The child aggregate
project includes `examples/a11y_examples.gpr`, so `cd tests && alr build`
compiles the example with the pinned Alire toolchain. Passing `--json` emits
schema `org.a11y.example.platform_neutral_provider.v1` with `tree_valid` and
`backend_neutral` markers for release tooling.

## Fixture Report

`tests/bin/fixture_report` renders the deterministic fixture's stable node
identities, roles, protected-text sentinel, image/document/surface metadata,
and scripted commands. Passing `--json` emits schema
`org.a11y.fixture_report.v1` so native integration clients and release tooling
can consume the same fixture inventory.

`tests/bin/fixture_application` emits a deterministic readiness line followed
by accepted command results for the fixture script. Passing `--json` emits
schema `org.a11y.fixture_application.v1`; this is the portable process shape
future native integration clients can launch before live OS provider transport
is connected.

## Native Qualification

`tests/bin/release_qualification` emits the manual assistive-technology smoke
test checklist. Release evidence must record OS versions, assistive-technology
versions, fixture scenario, steps, expected behavior, observed behavior, and
known limitations. Each scenario also carries the deterministic native probe
command that must accompany the manual evidence for that platform and the
conformance feature identifier that the evidence is meant to support. The
same scenario row also includes `readiness_evidence_id`, which links the
manual qualification row to the native observation summary's current next
required evidence. For Linux this is
`linux_atspi_automated_native_qualification`; for Windows and macOS
it remains the missing public-client traversal evidence id until those OS
client bridges are live.
`tests/bin/release_qualification --linux-atspi-evidence-template` emits the
Linux-specific record template for that evidence id. It includes the required
live AT-SPI probe command, the live-probe flags that must already be true, and
one record row per Linux Orca/accessibility-inspector scenario. The template
also exposes `qualification_gate_status`, `required_scenario_count`, and
`captured_scenario_count` so Linux release readiness can be checked without
parsing the scenario array. `required_scenario_count` is the stable number of
required records for the platform; it does not decrease when some evidence is
captured.
`tests/bin/release_qualification --linux-atspi-host-evidence` emits the
machine-checkable Linux host evidence supplement for the same readiness id. It
records the OS release label, Orca binary presence, busctl binary presence, and
required live AT-SPI probe command, but it explicitly does not claim that Orca
or an inspector observed the fixture behavior. The report also records
`host_at_spi_bus_address_present`, `host_session_bus_address_present`,
`host_discovery_source`, and `host_transport_probe_command`. When only
`DBUS_SESSION_BUS_ADDRESS` is present, the required live probe is emitted with
that concrete session-bus address so the host accessibility-bus discovery path
can be repeated without guessing which environment variable was used. In
sandboxed automation, access to `/run/user/.../bus` may be denied; the evidence
keeps that separate from a real AT-SPI backend failure.
On Linux hosts without an existing desktop accessibility bus, run the live
external-client checks against a temporary local D-Bus session bus:

```sh
dbus-daemon --session --nofork --print-address --address=unix:path=/tmp/a11ykit-atspi-test-bus
tests/bin/native_client_atspi --probe-session-bus-address=unix:path=/tmp/a11ykit-atspi-test-bus
DBUS_SESSION_BUS_ADDRESS=unix:path=/tmp/a11ykit-atspi-test-bus tests/bin/native_client_atspi --probe-external-client-host-env
```

The external-client report is acceptable only when it carries
`status = SUCCESS`, `failure_stage = none`,
`external_traversal_completed = true`,
`external_protected_value_suppressed = true`, and a nonzero
`event_loop_registered_method_calls` value matched by
`event_loop_registered_replies`.
`tests/bin/release_qualification --linux-atspi-captured-evidence PATH` ingests
a flat captured-evidence summary for the same readiness id and emits
`org.a11y.linux_atspi_captured_evidence_status.v1`. The input schema is
`org.a11y.linux_atspi_captured_evidence.v1` and must carry `platform =
Linux`, `native_api = AT-SPI2`,
`readiness_evidence_id =
linux_atspi_automated_native_qualification`, and these seven
boolean scenario fields: `fixture_readiness_captured`,
`tree_traversal_captured`, `protected_text_captured`,
`window_lifecycle_captured`, `relations_captured`,
`live_announcement_captured`, and `action_requests_captured`. The normalized
status reports captured, pending, and required scenario counts. It marks
`native_conformance_claim_allowed` true only when all seven required Linux
scenarios are captured; it also marks `does_not_verify_evidence_authenticity`
because the command counts a release-machine record but does not prove the
record was truthfully observed.
`tests/bin/release_qualification --windows-uia-evidence-template` and
`tests/bin/release_qualification --macos-nsaccessibility-evidence-template`
emit the equivalent Windows and macOS record shapes. Those templates require
`external_client_traversal_observed = true`. The Windows template also
requires the `SetFocus` ABI action frame to report `SUCCESS`,
`ACTION_REQUEST`, and preserved neutral payload; the macOS template requires
`element_id_dispatched = true` before public AX traversal evidence can be
accepted. The current SDK-free blocked probes are not sufficient evidence
until public UIA and AX clients traverse the exported native object trees.
`tests/bin/release_qualification --windows-uia-captured-evidence PATH`
ingests schema `org.a11y.windows_uia_captured_evidence.v1` and requires
`platform = Windows`, `native_api = UI Automation`, readiness evidence id
`external_uia_client_traverses_com_fragment_root`, and boolean fields for
`tree_traversal_captured`, `focus_and_activation_captured`,
`protected_text_captured`, `relations_captured`,
`live_announcement_captured`, `window_lifecycle_captured`, and
`action_requests_captured`.
`tests/bin/release_qualification --macos-nsaccessibility-captured-evidence
PATH` ingests schema `org.a11y.macos_nsaccessibility_captured_evidence.v1`
and requires `platform = macOS`, `native_api = NSAccessibility`, readiness
evidence id `external_ax_client_traverses_appkit_element_tree`, the same
seven common scenario booleans, plus `switch_access_captured` and
`voice_control_captured`. Both commands emit normalized status JSON and set
`native_conformance_claim_allowed` only when all required platform scenarios
are captured. They count release records; they do not verify the authenticity
of the recorded observations.
`tests/bin/release_qualification --captured-evidence-summary LINUX WINDOWS
MACOS` reads the three captured-evidence summaries together and emits
`org.a11y.captured_evidence_summary.v1`. The aggregate status reports total
required, captured, and pending scenario counts across the 23 required
platform scenarios. It sets `native_conformance_claim_allowed` true only when
the Linux, Windows, and macOS platform-specific ingesters all accept complete
evidence.
The
generated checklist includes Orca, Linux accessibility inspection, NVDA,
Narrator, VoiceOver, Switch Control, Voice Control, and native platform
inspectors where those tools apply. Window/surface lifecycle, tree traversal,
protected-text, relation, live-announcement, and action-request scenarios are
required for Linux, Windows, and macOS. The JSON report includes a coverage
summary so the release gate rejects stale manual qualification checklists
before evidence is collected. The release gate also verifies every linked
conformance feature identifier against the generated capability matrix. Native
client normalized observations are stricter: each observation `conformance_id`
must resolve to a non-`Unsupported` row for at least one native backend
(`AT-SPI`, `UIA`, or `NSAccessibility`). A Null or Disabled declaration alone
does not satisfy native evidence. The same
coverage summary also reports `evidence_pending_count`,
`evidence_captured_count`, platform-specific required, pending, and captured
counts, and `all_evidence_pending`; each scenario also carries machine-readable
`qualification_status`. Current scaffolding must report every scenario as
`pending` until live native assistive-technology runs have recorded concrete
observed behavior, evidence locations, native probe output, and matching
conformance evidence.
`tests/bin/release_qualification --platform-evidence-summary` emits the
normalized per-platform evidence array directly. Each Linux, Windows, and macOS
entry carries the native API name, readiness evidence id, qualification gate
status, native boundary stage, stable required count, pending count, and
captured count, so release
automation can check backend readiness without parsing scenario rows.
The release gate cross-checks those readiness evidence ids against
`tests/bin/native_observation_report --summary-json`, which prevents the manual
qualification checklist from drifting away from the backend readiness blockers.
The summary also carries
`macos_nsaccessibility_native_client_artifact_path`,
`macos_nsaccessibility_native_client_artifact_state`, and
`macos_nsaccessibility_native_client_artifact_complete`. The state is `missing`
when no captured artifact exists, `incomplete_or_invalid` for a stub or partial
artifact, and `complete` only when the captured `native_client_nsax` JSON passes
the same public AX client traversal predicate used by the release gate.

`tests/bin/fixture_application --atspi-address=...` emits
`org.a11y.fixture_atspi_startup.v1` JSON for Linux startup attempts. The
report includes stage fields such as `startup_prepared`,
`registration_raw_connect_attempted`, `registration_raw_connect_status`,
`registration_raw_connected`, `registration_auth_sent`,
`registration_hello_queued`, and `registration_application_queued`; release
checks require controlled invalid-address and missing-socket failures to stop
at the expected stage.
Live AT-SPI registration qualification must show the registration method call
progressing through `registration_application_sent`,
`registration_application_reply_received`, and
`registration_application_completed`; the provider is not considered registered
when only the application object path can be built locally. The external client
probe repeats those provider-side fields with a `provider_registration_`
prefix so failed live runs show whether discovery, authentication, Hello, or
application registration stopped the run before semantic traversal began.
`tests/bin/fixture_application --atspi-host-env` runs the same fixture startup
through the hostkit-backed host environment path and reports redacted
`host_at_spi_bus_address_present`, `host_session_bus_address_present`, and
`startup_source` fields from the backend session report. When startup falls
back through the D-Bus session bus, the same report includes
`startup_discovery_attempted`,
`startup_discovery_raw_connect_attempted`,
`startup_discovery_raw_connect_status`,
`startup_discovery_get_address_reply_status`,
`startup_discovery_get_address_reply_error_name`, and
`startup_discovery_get_address_completed`, so host-environment failures keep
the AT-SPI GetAddress discovery result separate from later application-bus
registration failures.
`tests/bin/fixture_application --atspi-serve-host-env` uses that same host
environment startup path and then runs the bounded event-loop serve report, so
release hosts can qualify the fixture without copying native bus addresses into
the command line. The report includes `event_loop_can_read`,
`event_loop_can_write`, `event_loop_can_dispatch`, and
`event_loop_has_outgoing_work` so harnesses can distinguish a registered idle
server from an unavailable transport. The `event_loop_after_next_operation`
and `event_loop_after_*` fields capture the final bounded-loop step interest
after waiting, dispatch, or flushing, while `event_loop_step_status` and
`last_event_loop_stop_reason` record the final scheduler step result and why
that step stopped. Write-side counters
`event_loop_write_attempts`, `event_loop_write_ready`, and
`event_loop_write_timeouts` distinguish actual bounded outgoing flush attempts
from idle waits and read dispatch. Registered serve counters
`registered_replies_in_flight` and `last_registered_reply_in_flight` show that
serialized method replies remain terminal outgoing packets instead of creating
new in-flight calls while the local channel adapter reports them written or
rejected. The
`scheduler_transport_cycle_*` fields expose the one-shot scheduler adapter over
the registered transport-cycle path, including whether it was configured,
whether it attempted a cycle, the startup interest operation observed before
and after the cycle, wait status, write-wait status, flushed packet count,
whether read/serve/write stages ran, and whether a registered method call or
reply serialization was observed. On unavailable startup
`scheduler_transport_cycle_interest_before` must be
`WAIT_FOR_TRANSPORT`, wait/read/serve/write and write-wait fields must remain
false, and statuses must remain `BACKEND_UNAVAILABLE`, proving that fixture
tooling did not reach private transport or registry state after failed
registration.
The native observation report only marks
`linux.dbus.backend_session_event_loop_step` observed when both the bounded
scheduler step and its final-step status evidence are present. Its
`linux.dbus.backend_session_transport_cycle_scheduler` evidence also requires
the one-shot scheduler cycle, status, write-wait, after-interest, and flushed
count rows. The fixture and native session-dispatch probe also expose
incoming and reply packet kind, serial, reply-serial, and estimated byte counts
from the transport-cycle report, and the normalized native observation report
tracks that packet-metadata evidence as part of the same transport-cycle
scheduler feature.
`tests/bin/native_client_atspi --probe-session-bus-address=...` emits the same
stage fields for session-bus discovery, including registration reply
serial/status, `discovery_get_address_reply_error_name`,
`registration_application_reply_error_name`, and pending/in-flight outgoing
counts. Controlled invalid or
unavailable session buses must leave `startup_prepared` false, proving that
application-bus admission was not attempted before `GetAddress` succeeded.
`tests/bin/native_client_atspi --probe-external-client-host-env`
uses the same session-bus discovery and provider startup path, then opens a
separate AT-SPI client connection and sends `Accessible.GetName`,
`Accessible.GetRole`, `Accessible.GetChildCount`, and
`Accessible.GetChildAtIndex` to the registered provider over the accessibility
bus, then follows the returned main-window child path for child
`Accessible.GetName` and `Accessible.GetRole`. Its JSON schema is
`org.a11y.native_client_atspi_external_client_probe.v1`; a successful run sets
`provider_registration_auth_response_status` = `SUCCESS`,
`external_traversal_completed`, `provider_dispatched_external_request`,
`provider_wrote_external_reply`, `client_reply_name_matched`,
`external_role_matched`, `external_child_count_matched`,
`external_child_at_index_matched`, `external_child_name_matched`,
`external_child_role_matched`, and `stop_status` = `SUCCESS`. The stop report
also records registry live/outstanding counts before and after shutdown so
clean release of exported native roots and children is auditable. Failed runs
also include `failure_stage` so release artifacts distinguish provider startup,
registration, address discovery, client connection, request dispatch, reply
handling, and semantic traversal failures without inferring from many booleans.

`tests/bin/native_observation_report` records the planned native client
families for Linux AT-SPI2, Windows UI Automation, and macOS NSAccessibility.
Linux now records the live external AT-SPI client traversal command and
evidence-backed `Exact` conformance rows for the first native slice, including
`has_linux_atspi_live_external_client_attribute_observation` and
`has_linux_atspi_live_external_client_protected_value_observation` for the
child `Accessible.GetAttributes` textual metadata, locale, orientation,
landmark, per-attribute match flags, and protected-value checks, plus
`has_linux_atspi_live_external_client_attribute_detail_observations` for the
stable report rows backing those flags, plus
`has_linux_atspi_live_external_client_component_observation` for live
`Component.GetExtents`, `Component.Contains`, and
`Component.GetAccessibleAtPoint` calls and
`has_linux_atspi_live_external_client_action_observation` for live
`Action.GetNActions`, `Action.GetName`, and `Action.DoAction` calls, plus
`has_linux_atspi_live_external_client_value_observation` for live
`Value.GetCurrentValue`, `Value.GetMinimumValue`, `Value.GetMaximumValue`,
`Value.GetMinimumIncrement`, and `Value.SetCurrentValue` calls, and
`has_linux_atspi_live_external_client_selection_observation` for live
`Selection.GetNSelectedChildren`, `Selection.GetSelectedChild`,
`Selection.IsChildSelected`, `Selection.SelectChild`,
`Selection.DeselectChild`, `Selection.SelectAll`, and
`Selection.ClearSelection` calls, and
`has_linux_atspi_live_external_client_text_observation` for live
`Text.GetCharacterCount`, `Text.GetCaretOffset`, and `Text.GetText` calls, and
`has_linux_atspi_live_external_client_image_observation` for live
`Image.GetImageDescription`, `Image.GetImageCaption`, `Image.GetImageKind`,
and `Image.GetImageSize` calls, and
`has_linux_atspi_live_external_client_document_observation` for live
`Document.GetLocale`, `Document.IsLandmark`, and
`Document.GetAttributeValue("title")` calls, and
`has_linux_atspi_live_external_client_table_observation` for live
`Table.GetNRows`, `Table.GetNColumns`, `Table.GetAccessibleAt`,
`Table.GetRowExtentAt`, `Table.GetColumnExtentAt`, `Table.GetCurrentCell`,
`Table.GetSortOrder`, and `Table.GetSortKey` calls, and
`has_linux_atspi_live_external_client_surface_observation` for live surface
kind, role, top-level/modal, visible, active, and close capability calls, and
`has_linux_atspi_live_external_client_live_region_observation` for live
setting, relevant changes, atomic, assertive, and external announcement calls.
The aggregate report also exposes
`has_linux_atspi_live_external_client_vertical_slice_observations` for the
core, interaction, content, surface, and live-region groups derived from the
external-client probe's `external_*_slice_completed` booleans.
It emits `has_linux_atspi_live_registered_external_client_observation` when the
same evidence set also includes provider startup's observed live transport
registration.
In the native observation summary this appears as
`native_vertical_slice_observed = true` for Linux. Once that field is true, the
Linux next required evidence is no longer generic vertical-slice completion;
it becomes `linux_atspi_automated_native_qualification`, meaning the
automated native client evidence is sufficient for the release gate.
Orca/inspector qualification may still be recorded as optional field evidence.
Readiness blocker entries also include `remaining_evidence`. Linux uses
`optional_assistive_technology_field_qualification` once the live AT-SPI
vertical slice is observed. Windows UIA now records native client traversal
evidence through its public-client probe. macOS uses
`live_nsaccessibility_appkit_bridge_and_public_ax_client_traversal_required`
while its SDK-free internal export chain is ready but public AX client
traversal remains missing.
macOS NSAccessibility remains `blocked_transport_unavailable` on non-macOS
hosts and until a real macOS public AX client traversal artifact is captured.
The native clients expose external-client probes with stable JSON schemas:
`tests/bin/native_client_uia --probe-external-client` and
`tests/bin/native_client_nsax --probe-external-client`.
The Windows blocked external-client probe is no longer an empty stub: it records
`native_bridge_compiled_for_windows`,
`native_bridge_stub_runtime`,
`windows_uia_client_runtime_probed`,
`windows_uia_client_runtime_available`,
`windows_uia_client_coinitialized`,
`windows_uia_client_automation_created`,
`windows_uia_client_root_element_obtained`,
`windows_uia_client_root_name_obtained`, and the corresponding HRESULT fields
for the public UI Automation client-runtime smoke probe. Those fields establish
whether a Windows run can create `IUIAutomation` and obtain the desktop root;
they do not replace the required public traversal of an a11y COM fragment root.
The macOS blocked external-client probe records the same bridge-target split
through `native_bridge_compiled_for_macos` and `native_bridge_stub_runtime`,
so release logs distinguish a Linux SDK-free stub run from a macOS AppKit
bridge run before the required public AX traversal is accepted.
The macOS artifact also includes
`macos_nsax_virtual_element_bridge_audited`; it must be true for accepted
artifacts and proves the Objective-C virtual-element creation and identity
matching helpers are documented in the bridge audit.
Accepted macOS artifacts must also report
`macos_nsax_virtual_element_runtime_available = true` and
`macos_nsax_virtual_element_runtime_probe_observed = true`; these are separate
from `public_ax_client_traversal_observed` and prove the Objective-C
`A11yNSAXElement` method plumbing ran under the native runtime. The
`A11y_NSAX_Native_Runtime_Probes` wrapper is platform-selected by
`tests/nsax_router_tests.gpr`, so Linux reports the unsupported stub while
macOS links AppKit/Foundation/ApplicationServices and executes the bridge
helper.
The native-client artifact now mirrors the nine macOS scenario booleans and
scenario counts from the captured-evidence schema. They are accepted only when
`public_ax_client_traversal_observed = true`, so internal export readiness
cannot claim VoiceOver, Switch Control, Voice Control, or inspector coverage.
It also reports `macos_nsax_public_ax_client_probe_observed`, plus runtime and
process-id availability fields, for the ApplicationServices public AX client
smoke probe. That probe is required for accepted artifacts, and the full
external-client artifact combines it with the AppKit export-chain checks before
claiming traversal. On macOS, `tests/bin/native_client_nsax
--probe-public-ax-client` emits just this smoke probe result.
It also records a host-window handshake smoke probe:
`windows_uia_host_window_probed`,
`windows_uia_host_window_handshake_available`,
`windows_uia_host_window_class_registered`,
`windows_uia_host_window_created`,
`windows_uia_host_window_wm_getobject_sent`,
`windows_uia_host_window_root_object_id_matched`,
`windows_uia_host_window_return_provider_called`,
`windows_uia_host_window_null_provider_returned_zero`,
`windows_uia_host_window_destroyed`,
`windows_uia_host_window_register_error`,
`windows_uia_host_window_create_error`, and
`windows_uia_host_window_return_provider_lresult`. That probe intentionally
uses a null provider pointer; it verifies the Windows `WM_GETOBJECT` and
`UiaReturnRawElementProvider` route only, not public traversal of an a11y COM
fragment provider.
The same external-client report also includes
`windows_uia_minimal_provider_*` fields. On Windows these fields come from a
native C `IRawElementProviderSimple` smoke object returned from a hidden host
window. The object implements only COM identity/lifetime and provider-options
plumbing, reports whether `ElementFromHandle` reached the provider path, and
has no accessibility semantics. The fields are release-useful ABI evidence but
do not satisfy `external_uia_client_traverses_com_fragment_root`; that gate
requires the Ada-backed fragment root and semantic provider boundary.
The `windows_uia_callback_provider_*` fields extend that smoke path by routing
the native `IRawElementProviderSimple`, `IRawElementProviderFragment`, and
`IRawElementProviderFragmentRoot` vtable methods into a C-convention Ada
callback. The report records whether each callback was reached, whether it
returned `S_OK`, and whether session/provider/method codes were preserved for
each call. It also records aggregate full-frame callback evidence for Simple,
Fragment, and FragmentRoot calls, including the last widened interface, method,
and direction fields observed by the native bridge. This is a live
native-to-Ada COM provider method bridge, but it is still a test callback and
still does not satisfy public UIA semantic traversal.
The same report also records
`provider_export_observed`, `fragment_interface_queried`,
`fragment_navigate_dispatched`, `fragment_last_child_frame_dispatched`,
`fragment_runtime_id_dispatched`,
`pattern_provider_frame_dispatched`, `bounding_rectangle_frame_dispatched`,
`simple_property_frame_dispatched`,
`fragment_action_frame_dispatched`, `fragment_action_frame_status`,
`fragment_action_frame_routed`, `fragment_set_focus_payload_preserved`,
`released_interface_rejected`,
`object_token_released`,
`released_object_token_rejected`, `boundary_status`,
`metadata_name_preserved`, `metadata_identifier_preserved`,
`metadata_help_preserved`, `metadata_placeholder_preserved`, and
`metadata_detail_preserved`, plus `com_live_chain_observed`,
`metadata_group_preserved`, `protected_value_suppressed`, and
`privacy_boundary_observed` for the SDK-free COM provider boundary. The
derived `internal_native_export_chain_ready` field is true only when that
COM live chain, embedded fragment roots frame, provider options frame, host raw
element provider frame, fragment root frame, fragment root point frame,
fragment root focus frame, pattern provider frame, bounding rectangle frame,
simple property frame, fragment last-child frame, action frame, metadata group,
and privacy boundary all pass;
it remains internal boundary evidence
and keeps
`external_client_traversal_observed = false` until a real UI Automation client
process traverses the fragment root through the OS UIA runtime.
The normalized native client report mirrors this as
`windows.uia.external_client.com_live_chain`,
`windows.uia.external_client.provider_options_frame`,
`windows.uia.external_client.host_raw_element_provider_frame`,
`windows.uia.external_client.embedded_fragment_roots_frame`,
`windows.uia.external_client.fragment_last_child_frame`,
`windows.uia.external_client.pattern_provider_frame`,
`windows.uia.external_client.bounding_rectangle_frame`,
`windows.uia.external_client.simple_property_frame`,
`windows.uia.external_client.fragment_action_frame` with successful
`ACTION_REQUEST` routing and preserved `Set_Focus` payload,
`windows.uia.external_client.fragment_root_frame`,
`windows.uia.external_client.fragment_root_point_frame`,
`windows.uia.external_client.fragment_root_focus_frame`,
`windows.uia.external_client.metadata` and
`windows.uia.external_client.protected_value`, tied to
`windows.uia.com_live_export`,
`windows.uia.com_live.provider_options`,
`windows.uia.com_live.host_raw_element_provider`,
`windows.uia.com_live.embedded_fragment_roots`,
`windows.uia.com_live.fragment_last_child_frame`,
`windows.uia.com_live.pattern_provider_frame`,
`windows.uia.com_live.bounding_rectangle_frame`,
`windows.uia.com_live.simple_property_frame`,
`windows.uia.com_live.fragment_action_frame`,
`windows.uia.com_live.fragment_root`,
`windows.uia.com_live.fragment_root_point`,
`windows.uia.com_live.fragment_root_focus`,
`windows.uia.metadata_properties`, and `windows.uia.protected_value_text`, so
report consumers can distinguish the SDK-free COM export chain, frame-dispatch
evidence, metadata mapper evidence, and protected-value mapper evidence from
the still-missing live UIA traversal. The generated JSON also exposes
`has_windows_uia_com_live_simple_property_frame_observation`,
`has_windows_uia_com_live_fragment_last_child_frame_observation`,
`has_windows_uia_com_live_pattern_provider_frame_observation`,
`has_windows_uia_com_live_bounding_rectangle_frame_observation`,
`has_windows_uia_com_live_fragment_action_frame_observation`,
`has_windows_uia_external_client_embedded_fragment_roots_observation`,
`has_windows_uia_external_client_provider_options_observation`,
`has_windows_uia_external_client_host_raw_element_provider_observation`,
`has_windows_uia_external_client_fragment_root_observation`,
`has_windows_uia_external_client_fragment_root_point_observation`,
`has_windows_uia_external_client_fragment_root_focus_observation`,
`has_windows_uia_external_client_fragment_last_child_frame_observation`,
`has_windows_uia_external_client_pattern_provider_frame_observation`,
`has_windows_uia_external_client_bounding_rectangle_frame_observation`,
`has_windows_uia_external_client_simple_property_frame_observation`,
`has_windows_uia_external_client_action_frame_observation`,
`has_windows_uia_external_client_metadata_group_observation` and
`has_windows_uia_external_client_privacy_boundary_observation` as aggregate
probe checks, plus `has_windows_uia_internal_native_export_chain_ready` for
the derived internal-readiness marker.
The macOS blocked external-client probe similarly records
`appkit_bridge_observed`, `element_registered`,
`hierarchy_children_dispatched`, `hierarchy_children_frame_dispatched`,
`hierarchy_child_at_index_dispatched`,
`hierarchy_child_at_index_frame_dispatched`,
`element_id_dispatched`, `attribute_value_frame_dispatched`,
`attribute_settable_frame_dispatched`,
`action_frame_dispatched`,
`element_release_reported`,
`element_release_tombstone_recorded`,
`released_element_resolve_rejected`, `released_element_rejected`,
`boundary_status`,
`metadata_label_preserved`, `metadata_identifier_preserved`,
`metadata_help_preserved`, `metadata_placeholder_preserved`, and
`metadata_detail_preserved`, plus `element_chain_observed`,
`metadata_group_preserved`, `protected_value_suppressed`, and
`privacy_boundary_observed` for the registered NSAccessibility element
boundary. The derived `internal_native_export_chain_ready` field is true only
when that element chain, main-thread binding, native-view binding, attribute
settable frame, action frame, metadata group, children frame,
child-at-index frame, and privacy boundary all pass; it keeps
`external_client_traversal_observed = false` and
`public_ax_client_traversal_observed = false` until a real AX client traverses
the AppKit element tree.
The normalized native client report mirrors this as
`macos.nsax.external_client.element_chain`,
`macos.nsax.main_thread_binding`,
`macos.nsax.native_view_binding`,
`macos.nsax.external_client.children_frame`,
`macos.nsax.external_client.child_at_index_frame`,
`macos.nsax.external_client.attribute_value_frame`,
`macos.nsax.external_client.attribute_settable_frame`,
`macos.nsax.external_client.action_frame`,
`macos.nsax.external_client.metadata` and
`macos.nsax.external_client.protected_value`, tied to
`macos.nsaccessibility.hierarchy`,
`macos.nsaccessibility.main_thread_binding`,
`macos.nsaccessibility.native_view_binding`,
`macos.nsaccessibility.selector.children_frame`,
`macos.nsaccessibility.selector.child_at_index_frame`,
`macos.nsaccessibility.selector.attribute_value_frame`,
`macos.nsaccessibility.selector.attribute_settable_frame`,
`macos.nsaccessibility.selector.action_frame`,
`macos.nsaccessibility.metadata_attributes`, and
`macos.nsaccessibility.protected_value_text`, again as boundary evidence only.
The generated JSON also exposes
`has_macos_nsax_selector_attribute_value_frame_observation`,
`has_macos_nsax_selector_children_frame_observation`,
`has_macos_nsax_selector_child_at_index_frame_observation`,
`has_macos_nsax_selector_attribute_settable_frame_observation`,
`has_macos_nsax_selector_action_frame_observation`,
`has_macos_nsax_external_client_children_frame_observation`,
`has_macos_nsax_external_client_main_thread_binding_observation`,
`has_macos_nsax_external_client_native_view_binding_observation`,
`has_macos_nsax_external_client_child_at_index_frame_observation`,
`has_macos_nsax_external_client_attribute_settable_frame_observation`,
`has_macos_nsax_external_client_metadata_group_observation` and
`has_macos_nsax_external_client_privacy_boundary_observation` as aggregate
probe checks,
`has_macos_nsax_virtual_element_bridge_observation` for the bridge-audit
observation, plus `has_macos_nsax_internal_native_export_chain_ready` for the
derived internal-readiness marker.
The release gate rejects accidental native support claims without observation
evidence. The report also exposes `readiness` and `native_conformance_ready`
fields so tooling can distinguish scaffold evidence, partial live native
evidence, and complete native conformance evidence. Current cross-platform
readiness remains `incomplete_native_evidence` and
`native_conformance_ready = false`. Readiness blocker rows also split
`internal_native_export_chain_ready` from
`public_client_traversal_observed`, so Windows and macOS can show internally
validated export chains while still failing the public OS-client traversal
gate. Each aggregate client row records the UIA
and NSAccessibility runtime probe command, fixture-root probe command, Linux
serving-packet probe command, Linux session-bus probe command, each backend's
external client probe command, and Linux
session-dispatch probe command where they apply, so release artifacts point at
the direct native-client entry points used for evidence.
The compact status form is `tests/bin/native_observation_report --summary-json`;
it emits only readiness, blocker, and per-platform evidence-count fields for
fast release dashboards and status checks.
The Linux row also
records `has_linux_atspi_session_dispatch_boundary_drain_observation` so the
pre-registration backend-session boundary-drain contract is tracked separately
from the broader session-dispatch probe marker. It also records
`has_linux_atspi_live_transport_registration_observed_observation` for the
post-registration AT-SPI transport observation, distinct from generic
application-registration request construction. It also records
`has_linux_atspi_session_dispatch_loop_report_observation` from the cached
session event-loop report fields emitted by `--probe-session-dispatch`, so
host event-loop adapter diagnostics stay visible through native-client reports.
Each aggregate client row
also carries the detailed observation count plus native-registry,
Windows host-window root binding, macOS main-thread binding, macOS native-view
binding, registry-generation, registry-reset, cache-tombstone, cache
session-scope, cache-generation, transport-generation, boundary-generation,
focus-, property-change-, name-, description-,
help-text-, placeholder-, value-text-, keyboard-shortcut-,
semantic-identifier-, locale-, set-position-property-, set-size-property-,
hierarchical-level-property-, heading-level-, landmark-, bounds-property-,
state-change-,
action-, action-payload-, value-, selection-,
active-descendant-, current-item-, text-range-, text-mutation-, text-set-,
bounds-, hit-test-, tree-change-,
window-event-, serving-packet-probe-, session-dispatch-probe-, surface-, and lifecycle-evidence markers so native object
registry, registry generations, drained registry reset, cache tombstones,
cache session scoping, cache generations, transport generations, boundary
generations, focus, property-change,
name, description, help text, placeholder, value text, keyboard shortcut,
semantic identifier, locale, structural integer properties, heading level,
landmark, bounds property, state-change, action, value,
action-payload, selection, active-descendant, text range, text mutation,
set-text edit request,
current-item, bounds,
hit-test, tree-change, window/surface, and stale-reference coverage cannot
silently disappear from the native-client qualification path.
Linux surface routing additionally covers stable surface kind names, bounded
surface strings, and operation-capability booleans from central metadata.
Live-region mapper tests cover stable setting and relevance names, atomicity,
announcement policy, metadata validation, defunct rejection where native object
paths are involved, and native string bounds for AT-SPI, UIA, and
NSAccessibility.

`tests/bin/native_client_atspi`, `tests/bin/native_client_uia`, and
`tests/bin/native_client_nsax` are separate client-process entry points. They
currently emit structured blocked observations rather than backend-private
inspection, and provide the stable CLI surface that future live native client
implementations must preserve. Each client reports normalized observations for
the application root, main window, focus target, property-change target,
accessible-name property target, description property target, help-text property target, placeholder property target, value-text property
target, keyboard-shortcut property target, semantic-identifier property target,
locale property target,
visible-title property target,
orientation property target,
heading-level property target, landmark property target,
bounds property target,
state-change target, default action target, slider value,
list selection,
active descendant, current item, bounds change, semantic hit test, tree change,
window event, explicit role rows for the initial vertical slice,
extended fixture role rows for table/document/image/surface-adjacent controls,
including dedicated status-role, image-role, and decorative-image-role
predicates, text field range, table cell, informative image alternative text, document
heading, protected password field, live region, validation alert, modal
surface, a destroyed list item, native object registry staging, native export
descriptor staging, native node-index staging, native action-payload staging,
native prepared-status handoff, native runtime lifecycle, native runtime event
application and preparation, native property/action/relation/event-source
projection, native event validation, posting-boundary validation, exhaustive
native event/role/relation mapping, and deterministic
shutdown, diagnostic bounds, diagnostic result mapping, diagnostic field
bounds, native resource-limit handling, hostile identity rejection, malformed
request mapping, and transport status. The Windows UIA and macOS
NSAccessibility runtime probes also report provider-boundary action discovery,
native action-request dispatch, native-call completion/draining, and whether
the backend-private native pattern/action payload and neutral semantic
`Action_Id` survive the native-call admission path. Their report JSON exposes
`has_windows_uia_missing_identity_observation`,
`has_windows_uia_mismatched_identity_observation`,
`has_windows_uia_malformed_identity_observation`,
`has_macos_nsax_missing_identity_observation`,
`has_macos_nsax_mismatched_identity_observation`,
`has_macos_nsax_malformed_identity_observation`,
`has_windows_uia_text_payload_limit_observation`, and
`has_macos_nsax_text_payload_limit_observation` for identity and oversized
text-edit payload rejection before semantic provider routing. The Linux AT-SPI
registered-boundary probe reports
Accessible role dispatch plus Action count/name/invocation dispatch through
the object registry and D-Bus method boundary, with native-call completion and
drained registry state reported separately. It also emits
registered-boundary resolved/admitted/completed flags and begin/end
outstanding-call counters from the report-producing boundary path.
The Linux `tests/bin/native_client_atspi --probe-serving-packet` mode reports
the registered packet-serving path from encoded method-call packet through
queued, serialized, decoded, and drained method-return packet for
`Accessible.GetName`, `Application.GetID`,
`Properties.Get(Accessible.Name)`, `Properties.GetAll(Accessible)`,
the `a{sv}` D-Bus property-map reply, and the raw
`property_map_reply_decoded` / `property_map_reply_bookkeeping_drained`
probe phases, `Accessible.GetRole`,
`Accessible.GetState`, and the
interface-discovery method `Accessible.GetInterfaces`, the tree-navigation methods `Accessible.GetChildCount` and
`Accessible.GetChildAtIndex`, plus the child-array method
`Accessible.GetChildren`, attribute-set method `Accessible.GetAttributes`,
relation-set method `Accessible.GetRelationSet`, and the reverse-navigation methods
`Accessible.GetParent` and `Accessible.GetIndexInParent`, plus
`Action.GetNActions`, `Action.GetName`, `Action.DoAction`,
`Component.GetExtents`, `Component.Contains`, and
`Component.GetAccessibleAtPoint`, `Component.GrabFocus`, plus `Value.GetCurrentValue`,
`Value.GetMinimumValue`, `Value.GetMaximumValue`,
`Value.GetMinimumIncrement`, `Value.SetCurrentValue`,
`Selection.GetNSelectedChildren`, `Selection.GetSelectedChild`,
`Selection.IsChildSelected`, `Selection.SelectChild`,
`Selection.DeselectChild`, `Selection.SelectAll`,
`Selection.ClearSelection`,
`Text.GetCharacterCount`, `Text.GetCaretOffset`, `Text.GetText`,
`EditableText.InsertText`, `EditableText.DeleteText`,
`EditableText.ReplaceText`, `EditableText.SetTextContents`,
`Image.GetImageDescription`, `Image.GetImageCaption`, and
the native-client evidence summary fields
`has_linux_atspi_serving_packet_core_observations`,
`has_linux_atspi_serving_packet_tree_traversal_observation`,
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
`has_linux_atspi_serving_packet_full_observations`.
In the aggregate native observation JSON, the malformed-packet and
text-payload-limit booleans are true only on the AT-SPI row and remain false on
the UIA and NSAccessibility rows.
The raw `--probe-serving-packet` JSON also emits
`accessible_tree_traversal_completed` after child-count, indexed-child,
children-list, parent, and index-in-parent AT-SPI calls decode and drain
bookkeeping.
`Image.GetImageKind`, `Image.GetImageSize`, `Table.GetNRows`,
`Table.GetNColumns`, `Table.GetAccessibleAt`, `Table.GetRowExtentAt`, and
`Table.GetColumnExtentAt`, `Document.GetLocale`, `Document.IsLandmark`, and
`Document.GetAttributeValue("title")`.
The same probe also sends a well-formed method call to an unregistered object
path and requires a decoded AT-SPI `NoSuchObject` error with in-flight
bookkeeping drained, then sends a registered object-path call through an
unsupported interface and requires a decoded AT-SPI `NotSupported` error with
in-flight bookkeeping drained.
The phase-specific conformance rows
`linux.atspi.serving_packet.stale_error.queued`,
`linux.atspi.serving_packet.stale_error.serialized`,
`linux.atspi.serving_packet.stale_error.decoded`, and
`linux.atspi.serving_packet.stale_error.drained` make the stale-reference
serving path auditable beyond the aggregate stale-error flag.
`linux.atspi.serving_packet.unsupported_interface.queued`,
`linux.atspi.serving_packet.unsupported_interface.serialized`,
`linux.atspi.serving_packet.unsupported_interface.decoded`, and
`linux.atspi.serving_packet.unsupported_interface.drained` provide the same
stepwise evidence for unsupported-interface errors.
It also sends invalid packet bytes and requires `malformed_packet_rejected`
with `Invalid_Argument` before semantic dispatch, without queuing a reply or
leaving outgoing packets in flight.
The same receive-boundary check constrains `Native_String_Size` for an
`EditableText.InsertText` packet and requires
`oversized_text_payload_rejected` with `Resource_Limit`, again without queuing a
reply or leaving outgoing packets in flight.
The `Text.GetText` serving packet is built with a typed D-Bus `uu` start/end
range body so text offsets are not routed through coordinate arguments.
The `EditableText.InsertText` serving packet is built with a typed D-Bus `uus`
range/replacement body and is decoded back into a neutral text edit request.
The `EditableText.DeleteText` serving packet is built with the typed D-Bus
`uu` range body and is decoded through the same neutral text edit request path.
`EditableText.ReplaceText` uses the typed `uus` range/replacement body and
`EditableText.SetTextContents` uses the typed `s` replacement body; both are
decoded through the same neutral text edit request path and return boolean
request-accepted replies.
The attribute and relation packets decode bounded `a{ss}` and `a(uao)`
method-return payloads, preserving user-visible attribute metadata and stable
relation target node identities without native object addresses.
The Linux AT-SPI, Windows UIA, and macOS NSAccessibility fixture-root probes
also report native-call completion and drained object/provider/element state
for the deterministic fixture application root query, then exercise drained
registry reset and report post-reset rejection of both node lookup and stale
native ids. Each fixture-root probe also emits a `probe_status` summary and an
ordered `failure_stage` value for deterministic failure classification before
live native qualification is available. The same fixture-root probes verify
second-child indexed root traversal with
`fixture_root_second_child_dispatched`, exact root child-count evidence with
`fixture_root_child_count_dispatched`, and child-to-parent native tree
navigation with `fixture_child_parent_dispatched`. They also verify child
native identity projection with `fixture_child_native_identity_dispatched` and
second-child native identity projection with
`fixture_second_child_native_identity_dispatched`, and sibling ordering with
`fixture_sibling_order_dispatched`, so
single-child traversal cannot mask missing sibling/indexed, reverse hierarchy,
second-child reverse traversal, or stable native-identity semantics.
The Windows UIA and macOS NSAccessibility runtime probes additionally dispatch
native-boundary text range queries and text insert/delete/replace/set edit
requests, preserving the neutral text fragment and `Text_Edit_Request` payloads
while still proving native call drain classification. They also dispatch table
current-cell and sort metadata plus document, image, live-region, and surface
metadata queries, preserving stable node references and typed semantic payloads
before the native call drains. They also prove root semantic identifier
projection through UIA AutomationId and NSAccessibilityIdentifier boundary
queries. Value and selection runtime checks cover current
value queries, staged value-set requests, selection counts, selected items, and
staged item toggle, select-all, and clear-selection requests without allowing
the backend to mutate application state directly. Their runtime JSON includes
`selection_request_payload_preserved`,
`selection_select_all_payload_preserved`, and
`selection_clear_payload_preserved`.
The aggregate native observation report keeps those as separate
`has_native_registry_reset_node_rejection_observation` and
`has_native_registry_reset_stale_id_rejection_observation` fields so reset
coverage cannot be confused with stale-reference safety.
Each observation carries a stable dotted `conformance_id` so native evidence
can be matched to semantic support declarations. Semantic-node observations
also carry platform-shaped identity projections: Linux D-Bus object paths,
Windows UI Automation runtime-id components, and macOS NSAccessibility
element-id components. The `privacy` field records
public, protected redacted, lifecycle-only, and transport-only observations.
`native_resolution` records whether the native observation resolves to
available semantic state, `node_unavailable` stale-reference handling, or
unavailable transport.
Because the aggregate report keeps many scaffold and shared semantic markers on
each client row, consumers must use the row-scoped fields for native attribution:
`native_evidence_scope`, `row_scopes_atspi`, `row_scopes_uia`, and
`row_scopes_nsaccessibility`. Release checks require those fields to be
mutually exclusive for the Linux AT-SPI, Windows UIA, and macOS
NSAccessibility client rows. Platform-specific native transport and export-chain
booleans are also scoped to their owning row: UIA COM/export and blocked
external-client evidence is true only on the UIA row, NSAccessibility
element/selector and blocked external-client evidence is true only on the
NSAccessibility row, and live AT-SPI serving/external-client evidence is true
only on the AT-SPI row.

The native-client report package exposes typed completeness predicates in
addition to JSON emission. `release_check` requires every native client report
to remain complete, with 417 normalized
observations: one focus observation, one property-change
observation, property-event projection observations for orientation,
set position, set size, and hierarchical level, one role property
observation, one state-set property observation, one accessible-name property observation, one description property observation, one help-text property observation, one placeholder-property
observation, one value-text property observation, one keyboard-shortcut
property observation, one semantic-identifier property observation, one locale
property observation, one visible-title property observation, one orientation
property observation, structural property observations for set position, set
size, and hierarchical level, one heading-level property observation, one
landmark property observation, one bounds property observation, one state-change
observation, action observations for activate,
press, toggle, expand, collapse, show-menu, dismiss, open, close,
scroll-into-view, and set-focus, one action-payload observation, one value observation, one
selection observation, one select-all observation, one selection-event observation, one
active-descendant observation, one active-descendant event observation, one
current-item observation, one current-item event observation, one bounds
observation, one hit-test observation, one
tree-change observation, one window-event observation, explicit role
observations for the initial vertical slice, dedicated status-role, image-role,
and decorative-image-role observations, extended fixture role observations for
remaining fixture controls, one text-range observation, text
insert/remove/replace observations, one caret observation, one table-cell
observation, table row-insert and cell-change event observations, one image
observation, one document-heading observation, one document-load event
observation, one live-region observation, one relation observation, one
relation-event observation, exactly one protected observation, one
stale-reference
observation, transport-only observations for native object registry staging,
Windows host-window root binding, macOS main-thread binding, macOS native-view
binding, native cache tombstones, native cache session scoping, native runtime
lifecycle, native runtime event application and preparation, native cache
generation, native registry generation, native registry drained reset, native
boundary runtime generation,
property/action/relation/event-source projection, unavailable transport, event
staging, prepared-status handoff, event validation, posting-boundary
validation, exhaustive event/role/relation mapping,
method-return payloads, method-return decode, error-return decode, error-return diagnostics, incoming packet dispatch,
startup pump readiness, deterministic shutdown, diagnostic bounds, diagnostic result mapping,
diagnostic field bounds, native resource-limit handling, hostile identity
rejection, malformed request mapping, Linux AT-SPI error-name mapping, Linux
AT-SPI inverse error-name mapping, Linux AT-SPI error-name diagnostics,
Linux AT-SPI role/state/object-path mapping, method routing, application ID
and metadata, encoded Application.GetID packet serving, and Accessible
role/state/name/description/child-count/relation
methods, Component extents/contains/hit-test methods, Action count/name/invoke
methods, Value current/range/set-request methods, and Selection
count/selected-child/request methods, Text character-count/range/caret/protected
text/edit-request methods, Table dimension/cell/span methods, and Image
description/caption/category/size/decorative-omission methods, Document locale/attribute/heading
level/landmark/author/subject/version/revision/pagination methods, Surface
metadata/routing, AT-SPI focus/text/lifecycle
and prepared-publication signals, and Cache node projection,
Linux D-Bus unsupported-value handling, Linux D-Bus UInt32-array value
handling, Linux D-Bus state-set UInt32-array validation, Linux D-Bus
string-array value handling, Linux D-Bus attribute string-array validation,
Linux D-Bus cache interface string-array validation, Linux D-Bus
object-path-array handling, Linux D-Bus relation-target
object-path-array validation, Linux D-Bus connection lifecycle, local-channel
adapter, local-channel receive, startup controller, startup pump, pump bounds,
registered startup pump,
bus-address validation, EXTERNAL auth, auth exchange, authenticated connect,
Hello, authenticated Hello, registration completion, authenticated
registration, staged registration reporting, backend session startup reporting
for direct, environment, and session-bus startup,
application registration, address discovery, GetAddress,
authenticated GetAddress, startup session discovery, transport frame metadata, frame-byte
encoding, frame send, packet construction, packet send, packet decode,
startup event-loop interest, bounded backend-session event-loop driving,
backend-session encoded packet serving admission, codec
basic coverage, resource-limit validation, message envelope construction,
method-call envelope construction, transport envelope decode, incoming-call
decode, signal envelope construction, prepared-signal envelope construction,
and method-boundary routing,
Windows UIA HRESULT
mapping, Windows UIA inverse HRESULT mapping, Windows UIA HRESULT diagnostics,
Windows UIA core/text/bounds properties, action map/request routing,
set-focus/open/scroll/close routing, event map/details, prepared-event
emission/routing/boundary, fragment navigation, runtime-id, relation routing,
metadata-backed property projection and protected value-text suppression,
Windows UIA value/selection/text/table/image/document/surface routing,
request-router/provider-boundary coverage, provider registry, COM lifetime,
COM export descriptor, native-value ownership,
macOS NSAccessibility metadata-backed attribute projection and protected
value-text suppression,
NSAccessibility native-status mapping, macOS NSAccessibility inverse
native-status mapping, macOS NSAccessibility native-status diagnostics,
macOS NSAccessibility core/text/frame attributes, action map/request routing,
open/close/set-focus/scroll-to-visible routing, event map/details,
prepared-event emission/routing/boundary, hierarchy, element-id, relation
routing, macOS NSAccessibility value/selection/text/table/image/document/surface
routing, request-router/provider-boundary coverage, element registry, element
lifetime, element export descriptor, native-value ownership, and runtime
backend override resolution, plus identity projections for every
semantic node. The
same gate requires `has_fixture_command_coverage`, which
proves the native-client report is bound to the full deterministic fixture
script and that `fixture_command_results` matches the fixture application.
The aggregate native observation JSON also exposes grouped backend coverage
booleans for AT-SPI method families, UIA routing families, and NSAccessibility
routing families so report consumers can distinguish backend slices without
recounting individual observation rows.
Future live
transport clients must update those Ada predicates and the JSON checks together
instead of changing report text alone.
Open, close, and scroll-into-view have dedicated typed predicates in addition
to the aggregate action evidence because they map to distinct native concepts
on UIA and NSAccessibility.
The aggregate native observation report emits those action markers, the
property-event projection markers, prepared-status handoff markers,
method-return decode markers, error-return decode markers, error-return
diagnostic markers, Linux error-name, Linux inverse error-name, Windows
diagnostic markers, Linux error-name, Linux inverse error-name, Linux
error-name diagnostic, Linux D-Bus unsupported-value, Linux D-Bus UInt32-array
value, Linux D-Bus state-set UInt32-array validation, Linux D-Bus string-array
value, Linux D-Bus attribute string-array validation, Linux D-Bus
cache interface string-array validation, Linux D-Bus object-path-array value,
Linux D-Bus relation-target object-path-array
validation, Windows HRESULT, Windows inverse HRESULT, Windows HRESULT
diagnostic, macOS native-status, macOS
inverse native-status map, and macOS native-status diagnostic markers for each
client row so `release_check` can
detect stale report wiring.
