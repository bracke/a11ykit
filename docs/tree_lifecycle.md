# Tree And Lifecycle Guide

The accessibility tree is a semantic ownership tree. It is independent of
widget hierarchy, rendering hierarchy, layout hierarchy, and native
accessibility object hierarchy.

## Tree Invariants

There is exactly one application root. Every attached non-root node has exactly
one parent, sibling order is deterministic, cycles are invalid, duplicate child
appearance is rejected, detached nodes are not exposed, and destroyed nodes do
not return from tree queries. Child add/remove event payload validation rejects
self-parent edges before the event can be projected to a native backend.

## Lifecycle States

Nodes move through created, attached, active, removing, defunct, and removed
lifecycle states. `Node_Destroyed` is the final semantic event for a node; no
semantic event may be published for that node afterward.

## Removal

Removal blocks new mutable operations as appropriate, cleans tree and relation
references, marks native objects defunct, records tombstones for stale native
calls, and prevents access to application provider state after removal.
Native runtime defunct marking also records the stable `Node_Id` in the
destroyed-node ledger, so an uncached native object cannot be created for a node
after removal has begun.
If native tombstone retention is full, older tombstone metadata may be evicted,
but the stale native id still resolves as unavailable. The native object cache
also retains a defunct-node index outside the tombstone records, and the
destroyed-node ledger continues to reject native object creation for the
removed node.

## Exposure Policy

Exposure policy distinguishes exposed nodes, flattened nodes with exposed
descendants, hidden subtrees, and descendants-only projection. Backends use
central exposure views instead of independently deriving accessibility from
native view or widget classes.

## Snapshots

Native tree queries should use coherent semantic snapshots. Very large virtual
subtrees should answer counts and indexed lookups without materializing all
children.
Native projection validates returned parent and child identities against the
runtime lifecycle ledger before exposing them. A defunct target is reported as
unavailable rather than returned as a stale native reference.
