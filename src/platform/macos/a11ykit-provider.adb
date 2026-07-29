package body A11ykit.Provider is

   --  macOS VoiceOver speaks the NSAccessibility protocol. A working provider
   --  bridges to Objective-C, exposing NSAccessibilityElement objects built from
   --  the A11ykit.Tree and posting NSAccessibility notifications on Publish. Not
   --  implemented yet: Available is False and the operations are no-ops rather
   --  than a fake that cannot be verified against VoiceOver.

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
      return "NSAccessibility";
   end Backend_Name;

end A11ykit.Provider;
