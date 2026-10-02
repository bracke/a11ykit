# Backend Authoring

Backends translate the platform-neutral semantic model into a native protocol
or ABI. They do not own application state and must not invent semantics that
are absent from the committed model.

## Dependency Direction

Backend code sits below public semantics and above native protocol layers:
semantic packages, internal semantic implementation, backend contract, backend
semantic mapper, native protocol or ABI layer, operating-system runtime.

Normal application-facing packages must not depend on backend-private packages
or native types.

## Provider Calls

Native requests resolve a stable `Node_Id`, validate lifecycle/exposure, and
enter application provider code only through the configured dispatcher. Backend
or registry locks must not be held while invoking application callbacks.

## Native Identity

Native identities are derived from backend session identity and stable
`Node_Id` values. Backends must not derive identity from addresses, COM
pointers, Objective-C object addresses, object-cache slots, or child indexes.

## Native Transport

Platform adapters should use `Admit_Transport_With_Report`,
`Record_Transport_Failure_With_Report`, and `Stop_With_Report` at transport
mutation boundaries. `Transport_Transition_Report` records before and after
transport snapshots, requested status, final status, generation advancement,
and admission/running/state changes without exposing D-Bus, COM, or
Objective-C handles.
Use `A11y.Native_Runtimes.Initialize_With_Report`, `Start_With_Report`, and
`Stop_With_Report` when bridge setup or teardown needs lifecycle evidence. The
runtime report records before/after snapshots, status, state/session changes,
cache reset, and event-order reset.

## Error Mapping

Expected failures return structured results. Native boundary packages map those
results into backend-neutral return classes before D-Bus errors,
HRESULT-style outcomes, or NSAccessibility failures are produced by the
platform-private layer. Ada exceptions are contained at every native boundary.
After a provider operation completes, record its structured status on the active
native boundary context before ending the call. Successful callback release must
preserve that status so each native ABI maps the same semantic outcome. Use the
common `Complete_Call` helper for wrappers that expose a single structured
status field.
When a bridge needs begin-call diagnostics, use
`Begin_Object_Call_With_Report` or `Begin_Node_Call_With_Report`. Their
`Boundary_Call_Admission_Report` records requested identity, resolved identity,
runtime/cache generations, callback admission, defunct state, structured
status, and return class before backend-private state is released.
Use `Complete_Call_With_Report` when native return mapping needs proof that the
provider status was recorded and the callback token was released. Its
`Boundary_Call_Completion_Report` keeps before/after snapshots, requested
status, final status, status-recording result, release result, and return
class.
Use `End_Call_With_Report` for direct callback release paths, especially
exception cleanup paths that do not have a provider status to complete. Its
`Boundary_Call_Release_Report` records before/after snapshots, preserved
status, callback-release result, release state, and return class.
Use native object-cache `_With_Report` operations when a backend bridge needs
cache evidence for identity allocation, defunct marking, release, or reset; the
shared conformance row is `native.object_cache.mutation_report`.
Use platform-native registry `_With_Report` operations when a bridge needs
object/provider/element evidence for ensure, defunct marking, callback-aware
release, or drained reset; the shared conformance row is
`native.object_registry.mutation_report`.

## Event Pumping

Use `A11y.Backends.Event_Pumps.Pump_One_With_Report` or
`Pump_All_With_Report` when adapting the common semantic event queue into a
backend. Reports prove that events are acknowledged only after successful
publication and that rejected events remain pending for retry or deterministic
shutdown.

## Resource Limits

Backend limit reconfiguration should validate every affected runtime, cache, and
diagnostic bound before mutating any subsystem. A failed bound must leave all
previous limits intact.

## Conformance

Every backend support claim needs a dotted feature identifier, a support level,
native mapping notes, and test evidence. A backend must not advertise a native
interface, pattern, action, property, or notification until the common
semantics and Null Backend validation exist.
