package body A11ykit.Provider is

   --  Linux screen readers (Orca) speak AT-SPI2 over D-Bus. A working provider
   --  here is a substantial, from-scratch effort, and none of it exists in this
   --  workspace yet, so this body is an honest placeholder: Available is False
   --  and the operations are no-ops. It is left unimplemented rather than faked
   --  because a half-working provider that cannot be verified against a live bus
   --  is worse than an explicit "not available".
   --
   --  What a real implementation needs, roughly in order:
   --
   --    1. A D-Bus binding. There is no Ada D-Bus in the workspace, so this
   --       means FFI to libdbus-1 (connect, method call, receive, register an
   --       object path) or a pure-Ada D-Bus client.
   --    2. Reach the accessibility bus: connect to the session bus, call
   --       org.a11y.Bus.GetAddress to get the a11y bus address, connect to it.
   --       (Available should report whether this succeeds.)
   --    3. Register the application's root accessible with the registry
   --       (org.a11y.atspi.Socket.Embed), so Orca can discover it.
   --    4. Serve the AT-SPI2 interfaces as a D-Bus object server, mapping the
   --       A11ykit.Tree onto them: org.a11y.atspi.Accessible (role, name,
   --       description, parent/child relations from the tree), .Component
   --       (bounds from each node's Rectangle), .Action (default action ->
   --       activate), and .Value/.Text where they apply.
   --    5. Emit change events on Publish (object:state-changed:focused,
   --       object:children-changed, ...) by diffing against the last tree, and
   --       pump the D-Bus connection from the host event loop.
   --
   --  Only steps 4-5 are large; steps 1-3 are a bounded first milestone that
   --  would already let Available answer truthfully.

   function Available return Boolean is
   begin
      --  No AT-SPI provider yet; see the header comment for what it would take.
      return False;
   end Available;

   procedure Start is
   begin
      --  Nothing to register with until a real AT-SPI provider is in place.
      null;
   end Start;

   procedure Stop is
   begin
      null;
   end Stop;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
      pragma Unreferenced (Tree);
   begin
      --  Nothing is listening until a real AT-SPI provider is in place.
      null;
   end Publish;

   function Backend_Name return String is
   begin
      return "AT-SPI";
   end Backend_Name;

end A11ykit.Provider;
