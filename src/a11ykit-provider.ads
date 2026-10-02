with A11ykit.Tree;
with A11y.Results;

--  Legacy compatibility seam that publishes an A11ykit.Tree accessibility
--  tree through the new A11y session/backend model. Each host has its own body
--  (AT-SPI over D-Bus on Linux, UI Automation on Windows, NSAccessibility on
--  macOS); the spec is shared so a consumer talks to one API regardless of
--  host.
--
--  IMPLEMENTATION STATUS: Publish now validates a legacy A11ykit.Tree through
--  the new A11y session model and pumps its semantic events through the
--  target-aware default backend selector. On Linux, Publish first attempts
--  hostkit-backed AT-SPI startup, application-root registration, semantic
--  signal queueing, and a bounded serve cycle. If a native transport is
--  unavailable or incomplete, the default selector falls back to the validating
--  Null backend and records that fallback. A consumer must treat Available
--  False as "not registered with a native host service", never as proof that
--  semantic validation is disabled.
package A11ykit.Provider is

   --  Is a host screen-reader service reachable and has a provider registered
   --  with it? False when no accessibility service is running or native
   --  registration has not completed.
   function Available return Boolean;

   --  Register the application with the host accessibility service so a screen
   --  reader can discover it. Idempotent. Platform bodies may defer actual
   --  registration until Publish has a root node to expose.
   procedure Start;

   --  Unregister and release the host connection. Idempotent.
   procedure Stop;

   --  Make Tree the application's current published accessibility tree. The
   --  compatibility facade validates and pumps the semantic session events
   --  through the target-aware default backend selector. Linux attempts native
   --  AT-SPI registration before recording a structured fallback to the
   --  validating Null backend when the transport is unavailable.
   --
   --  @param Tree The accessibility tree to publish.
   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree);

   --  Result of the most recent compatibility publication attempt. This is
   --  semantic/backend validation state, not proof that a native host provider
   --  is registered; Available remains the native-registration truth.
   function Last_Publish_Status return A11y.Results.Status_Code;

   --  Number of semantic events delivered to the validating backend by the most
   --  recent Publish call.
   function Last_Published_Event_Count return Natural;

   --  Backend that consumed events during the most recent Publish call.
   function Last_Publish_Backend_Name return String;

   --  True when the target-aware default selection used a fallback backend.
   function Last_Publish_Used_Fallback return Boolean;

   --  Status reported by backend selection before the most recent Publish call.
   function Last_Publish_Selection_Status return A11y.Results.Status_Code;

   --  The host accessibility technology this platform's provider targets,
   --  using the same hostkit-backed naming as A11y.Platforms.Native_Backend_Name.
   --  Diagnostics only; Available is the truth about whether it works.
   function Backend_Name return String;

end A11ykit.Provider;
