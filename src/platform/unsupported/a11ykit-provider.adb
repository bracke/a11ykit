package body A11ykit.Provider is

   --  A host this crate has no provider for: there is no accessibility service
   --  to talk to, so Available is False and every operation is a no-op.

   function Available return Boolean is
   begin
      return False;
   end Available;

   procedure Start is
   begin
      null;
   end Start;

   procedure Stop is
   begin
      null;
   end Stop;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
      pragma Unreferenced (Tree);
   begin
      null;
   end Publish;

   function Backend_Name return String is
   begin
      return "none";
   end Backend_Name;

end A11ykit.Provider;
