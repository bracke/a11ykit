# AI-Usable Implementation Notes

This document gives implementation-oriented landmarks for agents and tooling
that need to work on the repository without re-deriving the architecture.

## Build Rule

Use Alire for build and test commands. `alr build` and
`alr exec -- gprbuild -q -P tests/all_tests.gpr` are authoritative root build
checks. The child crate is also an Alire crate: `cd tests && alr build` must
build `a11y_tests` through `tests/all_tests.gpr`.

## Source Layout

Portable semantic packages live under `src/`. Backend-private packages live
under `src/platform/linux`, `src/platform/windows`, and `src/platform/macos`.
Test and release-tool mains live under `tests/src`.

## Release Tools

Generated reports are Ada executables: `fixture_application`,
`fixture_report`, `native_client_atspi`, `native_client_uia`,
`native_client_nsax`, `native_observation_report`, `capability_matrix`,
`documentation_report`, `public_surface_audit`, and `release_qualification`.
`release_check` validates the report bodies and release invariants, including
native-client identity projection, stale-reference resolution evidence, the
child-crate Alire manifest project-file binding, and the public-surface audit
that prevents common semantic specs from exposing native platform tokens.
Native readiness can be queried without release-scenario detail with
`tests/bin/native_observation_report --summary-json`; strict native-readiness
jobs can use `tests/bin/native_observation_report --require-native-conformance`,
which emits the same summary JSON and exits successfully only when all native
client traversals are complete.

The project completion gate is:

```sh
tests/bin/release_qualification --project-completion-gate

tests/bin/release_qualification --require-project-completion
```

It reads the canonical native artifacts under `vm/`. To test the same gate
against explicit artifact paths, use:

```sh
tests/bin/release_qualification --native-client-artifact-status

tests/bin/release_qualification --require-native-client-artifacts
```

The first command emits the Linux, Windows, and macOS canonical artifact
states. The second emits the same JSON and exits successfully only when all
three are complete. To test the same project gate against explicit artifact
paths, use:

```sh
tests/bin/release_qualification \
  --project-completion-gate-from-artifacts \
  vm/linux-atspi-native-client.txt \
  vm/windows11/a11y-windows-native-client.txt \
  vm/macos-nsax-native-client.txt
```

On macOS, produce the canonical NSAccessibility artifact with:

```sh
tests/bin/native_client_nsax --capture-external-client-artifact
```

Validate that artifact with:

```sh
tests/bin/release_qualification \
  --macos-nsaccessibility-native-client-artifact-status

tests/bin/release_qualification \
  --macos-nsaccessibility-native-client-artifact \
  vm/macos-nsax-native-client.txt
```

The no-argument status command checks the canonical `vm/macos-nsax-native-client.txt`
path and reports whether it is `missing`, `incomplete_or_invalid`, or
`complete`. Strict CI jobs can use
`tests/bin/release_qualification --require-macos-nsaccessibility-native-client-artifact`,
which emits the same JSON and exits successfully only for a complete artifact.
The macOS artifact validator reports
`project_completion_gate_accepts_artifact`, `missing_required_field_count`, and
`missing_required_fields`. A Linux stub artifact is expected to fail this
validator; only a real AppKit/NSAccessibility run may satisfy the macOS gate.
Accepted artifacts must include
`macos_nsax_virtual_element_runtime_available = true`,
`macos_nsax_virtual_element_runtime_probe_observed = true`, and
`public_ax_client_traversal_observed = true`; the runtime probe proves the
Objective-C method bridge ran, while the public AX traversal bit proves an
ApplicationServices AX client reached the exported process/window/view path to
an Ada-backed `A11yNSAXElement`. Accepted artifacts must also set
`macos_nsax_public_ax_client_probe_observed = true` with runtime and process-id
availability. The full artifact combines that public client probe with the
AppKit process-root host, export-chain, metadata, stale-reference, and
protected-text checks before it may set the nine macOS scenario booleans as
true, `captured_scenario_count = 9`, and
`pending_scenario_count = 0` before the original-scope completion gate can pass.
On macOS, `tests/bin/native_client_nsax --probe-public-ax-client` emits only
the ApplicationServices public AX smoke probe; it is useful diagnostics by
itself, while `--capture-external-client-artifact` records the completion
evidence consumed by the release gate.

## Safe Editing

Keep platform-specific types out of public semantic packages. Add conformance
identifiers, Null/backend validation, docs, and release-gate updates with any
new semantic or backend feature.

## Known Gaps

Linux has staged D-Bus packet encode/decode, incoming method dispatch, and
transport-frame method-return payload serialization for scalar, string,
object-path, rectangle, size, floating-point, state-set, and relation-set reply
classes, plus a hostkit-backed Unix local-channel adapter for writing prepared
packets and receiving bounded packet bytes. D-Bus EXTERNAL auth command and
response classification are staged, and the local channel now composes
connection, EXTERNAL auth, BEGIN, and transport admission. D-Bus Hello request
queueing and unique-name reply completion are staged behind the same bounded
outgoing/in-flight tracking, with a composed authenticated-connect-through-Hello
operation ready for the live startup path. AT-SPI `Socket.Embed` now has
a method-return completion boundary, and the local channel has a composed
authenticated-connect-through-registration operation. `A11y.Linux.ATSPi_Startup`
wraps that sequence in a backend-private prepare/start/stop controller and a
one-iteration receive/dispatch/reply pump plus a readiness check and bounded
batch helper. It now exposes a no-I/O event-loop interest snapshot, including
structured pump-readiness status plus outgoing capacity and overflow metadata,
backend-private next-operation classification, and startup-level bounded
outgoing flush wrappers for future hostkit read/write scheduling adapters. Linux
AT-SPI address discovery now has a backend-private `AT_SPI_BUS_ADDRESS` value
normalizer, startup prepare helper, and staged `org.a11y.Bus.GetAddress`
request/reply completion path for the session-bus fallback. The local channel
now composes authenticated session-bus connect through `Hello` and `GetAddress`
completion, and startup can prepare from a caller-supplied session-bus address
by using a temporary discovery connection. Startup can also prepare from live
`AT_SPI_BUS_ADDRESS` through `Hostkit.Process.Environment_Value`, and test
entrypoints default the EXTERNAL auth uid through
`Hostkit.Process.Current_User_Id`. The matching conformance identifiers are
`linux.dbus.address_discovery` and `linux.dbus.host_environment_startup`.
Linux now has a backend-private bounded scheduler adapter over the AT-SPI
session event-loop driver plus a one-shot transport-cycle scheduler entrypoint
for future hostkit read-ready callbacks. Hostkit event-loop ownership and live
D-Bus object serving remain incomplete.
Linux has a tested SDK-free D-Bus object export descriptor, Windows has a
tested SDK-free COM provider export descriptor, COM method-surface contract,
and compatibility-facade path that exports a public root before entering the
bridge-owned live native callback provider host on Windows, and macOS has a tested
Objective-C-free element export descriptor plus AppKit process-root host path.
Windows publication now drains semantic events through a bridge-owned
`UiaRaiseAutomationEvent` wrapper after creating that live host; the current
drain is root-provider scoped and does not yet emit property-specific old/new
`VARIANT` payloads. macOS publication drains semantic events into AppKit
notifications. Live D-Bus object serving, durable public UIA client traversal
of the compatibility facade, and macOS public AX client traversal remain the
native evidence boundaries for production claims.
Prepared native event handoff is staged across all three native mappers:
failed `Prepared_Event.Status` values are preserved before native object
metadata is inspected, and the aggregate native observation report exposes the
transport-only `native.event.prepared_status` evidence row for release tooling.
`Prepare_Event_With_Report` adds
`native.runtime.event_preparation_report`, recording admission, commit, object
handoff, defunct state, runtime generation, and last-event progress before
backend-specific mappers inspect prepared event data.
Native runtime lifecycle transitions now expose
`native.runtime.lifecycle_report` through initialize/start/stop report variants,
recording before/after runtime snapshots, status, generation advancement,
state/session changes, cache reset, and event-order reset.
Native callback entry now has report variants tracked as
`native.boundary.admission_report`, recording requested identity, resolved
object/node identity, runtime/cache generations, callback admission, defunct
state, structured status, and return class before protocol-specific error
mapping.
Native object-cache `_With_Report` operations are tracked as
`native.object_cache.mutation_report` and capture before/after cache
generation, live counts, tombstones, object/node identity, status, and change
flags.
Platform-native registry `_With_Report` operations are tracked as
`native.object_registry.mutation_report` and capture before/after registry
generation, live counts, tombstones, outstanding callbacks, stable native
object/provider/element identity, node/session identity, status, and change
flags.
`native.boundary.completion_report` records completion before/after snapshots,
requested and final provider status, status-recording result, callback-release
result, release state, and return class before protocol-specific native return
mapping.
`native.boundary.release_report` records direct release before/after snapshots,
preserved provider status, callback-release result, release state, and return
class for native cleanup paths that do not go through completion.
Common semantic event pumping now exposes `events.backend_pump_report` through
`Pump_One_With_Report` and `Pump_All_With_Report`, recording pending counts,
capacity, event identity, validation, publication, acknowledgement, delivery
counts, stop reason, and structured status before backend-specific native
notification layers consume events.
Common native transport mutation now exposes
`backend.native.transport_transition_report` through admission, failure, and
stop report variants, recording before/after transport snapshots, requested
status, final status, generation advancement, and typed admission/running/state
changes for platform adapters.
Linux D-Bus startup replies now pass through `Decode_Method_Return`, a
method-return-specific receive boundary tracked by
`linux.dbus.method_return_decode`, before Hello, GetAddress, or registration
completion consumes reply payloads.
Startup error replies now pass through `Decode_Error_Return`, tracked by
`linux.dbus.error_return_decode`, preserving bounded native error names and
optional native message payloads before `linux.atspi.error_name_inverse_map`
maps known names back to structured results.
`Diagnostic_For_Error_Return` records those startup failures as structured
redacted diagnostics under `linux.dbus.error_return_diagnostic`.
Tracked startup requests now also complete valid D-Bus `Error_Return` envelopes
through the same Hello, GetAddress, and Socket.Embed completion
boundaries under `linux.dbus.startup_error_completion`, while unknown reply
serials remain non-mutating. `Classify_Incoming_Packet` provides the
no-mutation receive classifier tracked as
`linux.dbus.incoming_packet_classification`; the bus handlers then keep valid
signal, method-return, and error-return packets on the separate no-dispatch
path tracked as `linux.dbus.incoming_packet_no_dispatch`.
Outgoing D-Bus send admission now uses the same bus-level posting snapshot for
raw messages, normalized envelopes, and frames; overflow back pressure is
tracked as `linux.dbus.outgoing_back_pressure` and requires explicit queue
clearing before recovery.
Windows and macOS native event queues expose
`windows.uia.event_posting_admission` and
`macos.nsaccessibility.event_posting_admission`. Bridge-facing drainers use
`Dequeue_For_Posting`, which refuses overflow back pressure without consuming
pending notifications and resumes draining only after an explicit recovery
clear.
`Dequeue_For_Posting_With_Report` adds
`windows.uia.event_posting_report` and
`macos.nsaccessibility.event_posting_report`, carrying before/after queue
length, capacity, pending/overflow state, admission and consumption flags, next
operation, and structured status.
`Drain_For_Posting_Bounded` adds
`windows.uia.event_posting_drain_bounded` and
`macos.nsaccessibility.event_posting_drain_bounded`; it invokes a native bridge
poster callback only for admitted emissions and stops on empty queues, overflow
back pressure, callback failure, invalid attempt limits, or the configured
attempt bound.
The macOS provider facade also drains the current compatibility session during
`Publish` when the real AppKit bridge is present: it maps committed semantic
events to NSAccessibility notification codes, posts root events through the
installed process-root host, creates transient virtual elements for non-root
event sources from stable element-registry ids, releases those transient
objects after posting, and acknowledges each event only after a successful
native post. That path is production provider code; live public AX traversal
remains the remaining macOS transport evidence boundary.
Linux startup pumps now expose `linux.dbus.startup_pump_report` through
`Pump_One_With_Report` and `Pump_Registered_One_With_Report`. The report gives
future hostkit event-loop adapters bounded accounting for read attempts,
received packets, dispatch, reply writes, final outgoing counts, and structured
failure status.
Bounded Linux startup pumps also expose
`linux.dbus.startup_pump_bounded_report` through report-producing bounded
variants. The aggregate report records attempted and completed iterations,
operation counts, stop reason, final outgoing counts, and structured status
while existing bounded calls keep their delivered-count compatibility behavior.

The current project-completion blocker is the real macOS native public-client
artifact. Linux AT-SPI and Windows UI Automation automated native evidence are
captured. macOS mapper/router/probe logic is locally testable on non-macOS
hosts, but the final `vm/macos-nsax-native-client.txt` must be captured on
macOS and accepted by the artifact validator before the original scope can be
claimed complete.
The macOS artifact validator now requires the public-root export path, stable
native identity, children, child-at-index, attribute, attribute-settable, and
action, hit-test, focused-element, and notification selector-frame evidence in
addition to the real AppKit bridge, non-stub runtime, external client
traversal, protected-text suppression, and successful final status.
