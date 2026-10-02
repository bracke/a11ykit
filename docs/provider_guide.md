# Provider Implementation Guide

Application and toolkit adapters expose semantics through the platform-neutral
`A11y` model. Provider objects remain application-owned; the runtime owns
registries, snapshots, event queues, backend state, native object caches, and
tombstones.

## Core Node Contract

Every accessible node supplies stable identity, role, state set, parent and
child lookup, basic properties, capability discovery, and lifecycle
availability. Providers should keep the core contract small and implement
optional capabilities only for semantics the node actually supports.
`A11y.Nodes.Contract_Snapshot_Safely` captures the role, state, capability, and
exposure portion of the core contract, validates it centrally, and normalizes
invalid or exceptional provider responses before a session registers the node.
`A11y.Nodes.Basic_Snapshot_Safely` captures the core name, description, and
bounds queries with shared native string limits, so backends and toolkit
adapters do not need to duplicate exception containment or string-bound checks.

## Capability Providers

Action, text, editable text, value, selection, table, document, image,
relation, live-region, and surface behavior live in capability-oriented
providers. A node should not advertise a capability unless all required
operations can answer within documented resource and lifecycle rules.

Textual optional properties such as visible title, help text, placeholder,
value text, keyboard shortcut, semantic identifier, locale, orientation, and
landmark use `A11y.Properties.Textual_Property_Provider`. Toolkit adapters and
backends should query them through `Textual_Property_Safely` so native string
limits and provider exceptions are handled consistently before projection.
The safe wrapper also clears string payloads for unavailable statuses and
normalizes present empty strings to the explicit `Empty` status, so native
backends cannot accidentally project hidden text from unsupported,
temporarily unavailable, denied, or empty properties.
Structural optional properties such as set position, set size, hierarchical
level, and heading level use `A11y.Properties.Structural_Property_Provider`;
`Structural_Property_Safely` rejects negative structural integers and contains
provider exceptions before backend-specific mappers convert the values. The
limit-aware overload applies `Native_Array_Size` to set position/size and
`Traversal_Depth` to hierarchy/heading levels. It also clears integer payloads for non-present statuses and resource-limited statuses before native projection.
Live-region controls implement `A11y.Live_Regions.Live_Region_Provider`;
`Current_Metadata_Safely` validates relevance policy and normalizes invalid or
exceptional provider responses to inactive metadata with structured failures.

## Ownership

Native objects must not retain durable raw pointers to application widgets or
providers. Native calls resolve through `Node_Id`, pin a registry/session
entry, and dispatch into provider code only while the node is available.

## Virtual Nodes

Virtual controls use stable application keys mapped through `A11y.Node_Keys`.
Do not identify virtual rows, cells, or list items solely by current position.

## Updates

Applications commit semantic state first, then publish typed events through the
ordinary semantic update path. Backends translate those events; they do not
mutate provider state directly.
