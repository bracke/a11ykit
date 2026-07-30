# a11ykit

a11ykit is the per-OS seam that publishes an accessibility tree to the host's
screen-reader service: AT-SPI over D-Bus on Linux, UI Automation on Windows,
NSAccessibility on macOS. The specification is shared so a consumer talks to
one API whichever host it is on, and the semantic UI tree it publishes is
described once rather than per platform. The host providers are not implemented
yet; the shared surface is what exists today.

## Packages

* `A11ykit.Provider` — The per-OS seam that publishes an accessibility tree to
  the host's screen-reader service.
* `A11ykit.Tree` — The accessibility tree a consumer builds and hands to
  A11ykit.Provider.
* `A11ykit` — Accessibility backend for applications that draw their own UI
  (Vulkan, OpenGL, a custom toolkit) and therefore have no OS-recognised widget
  objects for a screen reader to inspect.

## Licence

MIT.
