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

   procedure Publish_Valid (Tree : A11ykit.Tree.Accessibility_Tree) is
   begin
      A11ykit.Provider_Runtime.Publish (Tree);
   end Publish_Valid;

   --  The tree's text made valid UTF-8 first: what the host is sent must be.
   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
   begin
      Publish_Valid (A11ykit.Tree.With_Valid_Text (Tree));
   end Publish;

   --  Queries reach this host's provider through the window system's own
   --  message loop, which the application already pumps.
   --  The bus reaches the tree without a window.
   procedure Attach_Window (Window : System.Address; Top_Level : Positive := 1) is null;

   procedure Service is null;

   --  This host's window system tells its screen reader about activation.
   procedure Set_Active (Active : Boolean) is null;

   --  Requests from this host's screen reader are not routed back yet.
   function Next_Request (Item : out Request) return Boolean is
   begin
      Item := (others => <>);
      return False;
   end Next_Request;

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
