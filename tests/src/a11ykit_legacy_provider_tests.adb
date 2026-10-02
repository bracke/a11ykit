with Ada.Strings.Unbounded;

with A11ykit;
with A11ykit.Provider;
with A11ykit.Tree;

with A11y.Platforms;
with A11y.Results;

with A11ykit_Test_Support;

package body A11ykit_Legacy_Provider_Tests is
   use Ada.Strings.Unbounded;
   use A11ykit;
   use A11ykit.Tree;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   function Publication_Tree return Accessibility_Tree is
      Flat : Node_Vectors.Vector;
      Item : Node;
   begin
      Item.Node_Role := Role_Window;
      Item.Bounds := (X => 0, Y => 0, Width => 100, Height => 100);
      Item.Name := To_Unbounded_String ("window");
      Flat.Append (Item);

      Item.Node_Role := Role_Toolbar;
      Item.Bounds := (X => 0, Y => 0, Width => 100, Height => 20);
      Item.Name := To_Unbounded_String ("toolbar");
      Flat.Append (Item);

      Item.Node_Role := Role_Button;
      Item.Bounds := (X => 0, Y => 0, Width => 20, Height => 20);
      Item.Name := To_Unbounded_String ("button");
      Item.Node_State.Focused := True;
      Flat.Append (Item);

      Item.Node_Role := Role_List;
      Item.Bounds := (X => 0, Y => 20, Width => 100, Height => 80);
      Item.Name := To_Unbounded_String ("list");
      Item.Node_State.Focused := False;
      Flat.Append (Item);

      return Build (Flat);
   end Publication_Tree;

   function Reading_Order_Tree return Accessibility_Tree is
      Flat : Node_Vectors.Vector;
      Item : Node;
   begin
      Item.Node_Role := Role_Window;
      Item.Bounds := (X => 0, Y => 0, Width => 100, Height => 100);
      Item.Name := To_Unbounded_String ("window");
      Flat.Append (Item);

      --  A draw list preserves reading order, which need not put containers
      --  first. Build infers that the later toolbar contains this button.
      Item.Node_Role := Role_Button;
      Item.Bounds := (X => 0, Y => 0, Width => 20, Height => 20);
      Item.Name := To_Unbounded_String ("active view");
      Item.Node_State.Selected := True;
      Flat.Append (Item);

      Item.Node_Role := Role_Toolbar;
      Item.Bounds := (X => 0, Y => 0, Width => 100, Height => 20);
      Item.Name := To_Unbounded_String ("toolbar");
      Item.Node_State.Selected := False;
      Flat.Append (Item);

      return Build (Flat);
   end Reading_Order_Tree;

   procedure Run is
   begin
      --  Provider contract: the legacy facade may attempt native registration
      --  on platforms with a live transport, but it must preserve target
      --  platform naming and fall back to Null validation when registration is
      --  unavailable.
      Check
        (not A11ykit.Provider.Available,
         "legacy provider facade remains unavailable until native provider registration exists");
      A11ykit.Provider.Start;
      A11ykit.Provider.Publish (Publication_Tree);
      Check
        (A11ykit.Provider.Last_Publish_Status = A11y.Results.Success
         and then A11ykit.Provider.Last_Published_Event_Count = 12,
         "legacy provider facade validates and pumps semantic publication events");
      Check
        ((A11ykit.Provider.Available
          and then A11ykit.Provider.Last_Publish_Backend_Name =
            A11ykit.Provider.Backend_Name
          and then not A11ykit.Provider.Last_Publish_Used_Fallback
          and then A11ykit.Provider.Last_Publish_Selection_Status =
            A11y.Results.Success)
         or else
           (not A11ykit.Provider.Available
            and then A11ykit.Provider.Last_Publish_Backend_Name = "Null"
            and then A11ykit.Provider.Last_Publish_Used_Fallback
            and then A11ykit.Provider.Last_Publish_Selection_Status =
              A11y.Results.Backend_Unavailable),
         "legacy provider facade records native publication or its target-aware default fallback");
      A11ykit.Provider.Publish (Reading_Order_Tree);
      Check
        (A11ykit.Provider.Last_Publish_Status = A11y.Results.Success
         and then A11ykit.Provider.Last_Published_Event_Count = 8,
         "legacy publication attaches parents before earlier children and maps selected buttons to pressed state");
      declare
         Empty : Accessibility_Tree;
      begin
         A11ykit.Provider.Publish (Empty);
         Check
           (A11ykit.Provider.Last_Publish_Status = A11y.Results.Invalid_State
            and then A11ykit.Provider.Last_Published_Event_Count = 0,
            "legacy provider facade records invalid semantic publication failures");
      end;
      A11ykit.Provider.Stop;
      Check
        (A11ykit.Provider.Backend_Name = A11y.Platforms.Native_Backend_Name,
         "legacy provider facade uses hostkit-backed native backend naming");
   end Run;
end A11ykit_Legacy_Provider_Tests;
