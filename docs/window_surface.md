# Window And Surface Guide

Surfaces describe semantic presentation containers independently from native
operating-system window implementation.

## Surface Kinds

Surface kinds include window, dialog, modal dialog, sheet, popup, popover,
menu, context menu, tooltip, palette, inspector, splash, notification, utility
window, and embedded surface.

## Activation And Focus

Application activation, active window, focused node, focus chain, current item,
and active descendant are distinct semantic concepts. Backends project them
through native window and focus APIs where supported.

## Ownership And Modality

Surfaces may own transient surfaces and define modal scope. Not every semantic
surface is a native OS window, and not every native window must be independently
exposed as a semantic accessibility window.

## Window Operations

Closable, resizable, movable, minimized, maximized, fullscreen, visible, modal,
attention request, and lifecycle state are semantic metadata or actions that
providers expose explicitly.

Surface validation rejects contradictory committed states: active surfaces must
be visible and non-minimized, and minimized surfaces must not also be maximized
or fullscreen. Maximized and fullscreen are mutually exclusive presentation
states in the neutral model.
Surface-owning controls implement `A11y.Windows.Surface_Provider`. Its safe
query validates committed surface metadata and contains provider exceptions as
hidden embedded-surface metadata with a structured `Internal_Error` result.
Invalid provider surface metadata is also normalized to hidden embedded-surface
metadata before native projection, while preserving the structured validation
failure.

## Native Projection

Backends map committed surface metadata and events to AT-SPI window signals,
UIA Window/Transform patterns where supported, or NSAccessibility window/menu
notifications after semantic state is committed.
