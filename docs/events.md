# Event Architecture Guide

Semantic events are typed, ordered records describing committed changes to the
authoritative accessibility model.

## Event Envelope

Every event carries a strictly increasing sequence number, monotonic timestamp,
source `Node_Id`, event kind, typed payload, and revision/context metadata
where needed.

Typed payload optional fields are validated consistently: when a `Has_*` flag
is false, the associated `Node_Id`, text, index, row, or column field must carry
the neutral empty value. Contradictory payloads are rejected before backend
projection instead of being silently normalized.
For node-reference payloads, `No_Node` is the only valid absent-node sentinel.
Out-of-range `Node_Id` values are malformed even when the other side of a
transition is valid.
Payloads that are defined as changes reject no-op old/new pairs centrally.
Property payloads reject unsupported-to-unsupported status pairs, but allow
supported-to-supported status pairs because the event payload records status and
value kind rather than the changed property value itself. State changes, bounds
changes, focus changes, value/range changes, and node-reference changes reject
equivalent old/new payload values.
Tree child add/remove payloads also reject self-parent edges before backend
projection, so no native backend can observe a node as its own child.

`A11y.Event_Queues.Event_Queue` enforces nondecreasing committed timestamps
when events are enqueued. The timestamp type is currently backed by
`Ada.Calendar.Time`; the queue clamps committed event timestamps against its
last committed timestamp so exposed event order does not move backward. The
validating Null Backend also rejects directly published or replayed events
whose timestamps move backward, without advancing sequence or lifecycle state.
The conformance identifier is `events.timestamp_order`.

The validating Null Backend also rejects stale semantic revisions: a directly
published or replayed event may reuse the current committed revision for a
batch, but it may not carry a revision lower than the last accepted event.
Rejected stale revisions do not advance sequence, timestamp, lifecycle, or
recorded history. The conformance identifier is `events.revision_order`.

The queue also keeps a bounded destroyed-node ledger. Once a
`Node_Destroyed` event has been accepted for a `Node_Id`, a second destroy
event is rejected as `Invalid_State` and every later event for that source is
rejected as `Node_Unavailable`. Clearing the queue resets this ledger for a new
test or session scope; ordinary dequeue and acknowledge operations do not.

## Commit Order

State is committed before an event is published. Native notifications are
emitted only after semantic event publication, using old and new values from
the semantic payload where native APIs require them.
For relation cleanup caused by node destruction, the relation graph is
committed before publication. Ordinary surviving relation sources receive
`Relation_Targets_Changed`; surviving owners of a destroyed active descendant
receive `Active_Descendant_Changed`, preserving the stronger semantic event.

## Coalescing

Central coalescing may merge repeated bounds changes or value changes where
intermediate values are not semantically observable. Text mutations, node
destruction, action requests, and ordering-sensitive events are not coalesced.

## Subscriptions

Backends subscribe through bounded filters. Event fan-out is bounded, and
overflow must produce diagnostics or safe invalidation rather than silent
semantic corruption.
Subscription fan-out keeps the same kind of bounded destroyed-node ledger as
the committed event queue. Duplicate `Node_Destroyed` events are rejected before
delivery, and later events for the destroyed source are rejected as unavailable
instead of reaching native notification mapping.

## Shutdown

Shutdown stops accepting new semantic events, drains or rejects callbacks by
policy, flushes required final events, marks native objects defunct, and
disconnects native runtime scaffolds deterministically.
