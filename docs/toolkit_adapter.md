# Toolkit Adapter Guide

Toolkit adapters translate widget or scene-graph state into the platform-neutral
semantic tree. They should not expose toolkit internals as native accessibility
objects directly.

## Semantic Mapping

Adapters choose roles, states, properties, capabilities, relations, geometry,
and events from application semantics rather than native widget class names
alone.

## Stable Keys

Use `A11y.Node_Keys` to map toolkit model keys to stable `Node_Id` values for
virtualized lists, tables, trees, and custom-drawn controls.

## Dispatcher Integration

Adapters provide dispatchers that run provider callbacks on the toolkit's
required UI/main thread and reject or defer calls during shutdown.

## Exposure Policy

Adapters decide whether nodes are exposed, flattened, hidden, or
descendants-only. Decorative rendering nodes and layout-only containers should
not become accessible objects unless they carry semantics.

## Events

Adapters publish typed semantic events after toolkit state is committed.
Backends consume those events; adapters do not call native backend internals.
