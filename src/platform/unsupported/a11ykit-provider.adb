with A11y.Platforms;
with A11ykit.Provider_Runtime;

package body A11ykit.Provider is

   --  A host this crate has no native provider for: Available is False, while
   --  Publish still delegates to the shared default-backend validation path.

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
   begin
      A11ykit.Provider_Runtime.Publish (Tree);
   end Publish;

   function Last_Publish_Status return A11y.Results.Status_Code is
     (A11ykit.Provider_Runtime.Last_Publish_Status);

   function Last_Published_Event_Count return Natural is
     (A11ykit.Provider_Runtime.Last_Published_Event_Count);

   function Last_Publish_Backend_Name return String is
     (A11ykit.Provider_Runtime.Last_Publish_Backend_Name);

   function Last_Publish_Used_Fallback return Boolean is
     (A11ykit.Provider_Runtime.Last_Publish_Used_Fallback);

   function Last_Publish_Selection_Status return A11y.Results.Status_Code is
     (A11ykit.Provider_Runtime.Last_Publish_Selection_Status);

   function Backend_Name return String is
   begin
      return A11y.Platforms.Native_Backend_Name;
   end Backend_Name;

end A11ykit.Provider;
