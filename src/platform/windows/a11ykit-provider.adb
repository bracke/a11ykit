package body A11ykit.Provider is

   --  Windows screen readers (Narrator, NVDA, JAWS) speak UI Automation. A
   --  working provider is a COM UIA provider (IRawElementProviderSimple and the
   --  pattern interfaces) mapping the A11ykit.Tree onto UIA elements, plus
   --  UiaRaiseAutomationEvent on Publish. Not implemented yet: Available is
   --  False and the operations are no-ops rather than a fake that cannot be
   --  verified against a screen reader.

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
      return "UI Automation";
   end Backend_Name;

end A11ykit.Provider;
