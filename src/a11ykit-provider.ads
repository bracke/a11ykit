with A11ykit.Tree;

--  The per-OS seam that publishes an accessibility tree to the host's
--  screen-reader service. Each host has its own body (AT-SPI over D-Bus on
--  Linux, UI Automation on Windows, NSAccessibility on macOS); the spec is
--  shared so a consumer talks to one API regardless of host.
--
--  IMPLEMENTATION STATUS: none of the host providers are implemented yet, so
--  Available answers False on every platform today -- the tree is built and can
--  be published, but nothing is listening. A consumer must treat False as "not
--  consumed", never as an error, and keep working exactly as it does now. Adding
--  a real provider is per-host work that slots in behind this unchanged API.
package A11ykit.Provider is

   --  Is a host screen-reader service reachable and has a provider registered
   --  with it? False when no accessibility service is running, or -- as on every
   --  host today -- when this crate has no provider for the host yet.
   function Available return Boolean;

   --  Register the application with the host accessibility service so a screen
   --  reader can discover it. Idempotent; a no-op where Available is False.
   procedure Start;

   --  Unregister and release the host connection. Idempotent.
   procedure Stop;

   --  Make Tree the application's current published accessibility tree. A real
   --  provider diffs it against the previously published tree and emits the
   --  change events the host service expects. A no-op where Available is False.
   --
   --  @param Tree The accessibility tree to publish.
   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree);

   --  The host accessibility technology this platform's provider targets
   --  ("AT-SPI", "UI Automation", "NSAccessibility", or "none" on a host with no
   --  provider). Diagnostics only; Available is the truth about whether it works.
   function Backend_Name return String;

end A11ykit.Provider;
