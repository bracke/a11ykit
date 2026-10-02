# Selection Framework Guide

The Selection Framework models selection independently from focus, current
item, active descendant, and activation.

## Selection Modes

Selection may be none, single, multiple, contiguous multiple, extended, or
selection-required. Providers should expose the narrowest mode matching the
application semantics.

## Stable Identity

Selection membership uses stable `Node_Id` values rather than indexes or
visual positions. Selections can survive sorting, filtering, grouping, and
layout changes when the application model permits.

## Lazy Selection

Large selections should use bounded lookup, membership checks, lazy iteration,
ranges, interval structures, bitsets, sparse bitmaps, or predicates instead of
unbounded materialization.

## Requests

Select, deselect, toggle, clear, select all, range select, anchor, and current
item requests are validated and dispatched through provider semantics.
Controls with selection semantics implement `A11y.Selection.Selection_Provider`.
The safe provider wrappers read `Current_Selection`, validate a candidate
`Selection_Set` mutation, and only then call the provider mutation operation.
Provider exceptions are contained as structured failures, and query exceptions
produce an empty nonselectable selection snapshot.
`Select_Range` accepts an ordered vector of stable `Node_Id` values for
contiguous or extended modes. It validates range support, identity validity,
duplicate identities, and materialization capacity before changing selection
state, so oversized or malformed native range requests cannot create partial
selection mutations. Range selection also records explicit anchor-to-current
direction. Direction may be forward, backward, unknown, or absent, and remains
separate from focus, active descendant, and the current-item marker.
`Select_All` accepts the bounded selectable identity set for a container and
replaces the current selection only after validating mode compatibility,
identity validity, duplicate identities, and materialization capacity.
Required selections reject clear requests even when the current snapshot is
already empty, because an empty required selection is not a coherent semantic
state.
Current item may be cleared independently from selection membership.
Switching a selection set to `None` clears membership, anchor, and current-item
state so nonselectable snapshots cannot retain stale current items.
Native backends may stage select, deselect, toggle, select-all, or clear
operations only after validating lifecycle, exposure, resource limits, and
selection-mode rules against the semantic snapshot. A successful native request
reply is an application/provider request, not a backend-owned state mutation.

## Native Projection

Backends convert native index-shaped queries into stable semantic identities
and filter hidden or defunct selected nodes before exposing results. Native
request paths must similarly reject hidden or defunct targets instead of
creating platform-private selection state.
