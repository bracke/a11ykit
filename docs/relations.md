# Relations Guide

Relations form a first-class graph layered over the accessibility tree.
Relations use stable `Node_Id` targets and do not change tree ownership.

## Canonical Directions

Relation metadata defines canonical directions and inverse pairs such as
labelled-by/label-for, described-by/description-for, controlled-by/controller,
details/details-for, and error-message/error-for.

## Target Validity

Dangling relation targets must not become externally observable. Removing a
node deletes relations sourced from that node and removes it from other target
lists before backend projection.
When the removed target is an active descendant, surviving owners receive the
typed `Active_Descendant_Changed` event instead of a generic relation-target
change, so native focus and active-descendant projections do not have to infer
that distinction from relation graph deltas.
Native relation calls also validate every returned target against runtime
lifecycle state. If a target is stale or defunct, projection fails without
returning a partial relation list.

Relation event payloads are internally consistent before projection:
single-target add/remove payloads must carry a valid target, while aggregate
relation-change payloads with `Has_Target = False` must carry `No_Node` rather
than an ignored stale target.

## Provider Contract

Controls with dynamic relation semantics can implement
`A11y.Relations.Relation_Provider`. Native backends and toolkit adapters query
providers through `Relation_Targets_Safely`, which applies the configured
returned-target resource limit, rejects invalid or duplicate `Node_Id` targets,
and contains provider exceptions as structured `Internal_Error` results with an
empty target list.

The provider contract reports semantic targets only. Backend object references,
D-Bus paths, COM providers, Objective-C objects, and other native identity
details remain backend-private projections of the stable `Node_Id` values.

## Atomic Updates

Tree and relation updates should be applied atomically during semantic batches
so backends never observe half-applied ownership or relation changes.

## Cycles

Relation graph cycles are allowed when semantically meaningful. Suspicious
cycles can produce diagnostics, but not every relation cycle is invalid.
`A11y.Relations.Has_Cycle` reports same-kind cycles for one relation kind, and
`A11y.Relations.Has_Any_Cycle` scans all relation kinds. Derived inverse pairs
such as `Labelled_By`/`Label_For` are stored as separate relation kinds, so they
do not become same-kind cycles merely because the inverse edge exists.

## Native Projection

Backends map committed semantic relations to AT-SPI relations, UIA relation
properties, or NSAccessibility attributes after exposure filtering.
