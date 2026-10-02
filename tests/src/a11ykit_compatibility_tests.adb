with Ada.Strings.Unbounded;

with A11ykit;
with A11ykit.Compatibility;
with A11ykit.Tree;

with A11y.Capabilities;
with A11y.Geometry;
with A11y.Node_Ids;
with A11y.Properties;
with A11y.Registry;
with A11y.Results;
with A11y.Roles;
with A11y.Semantic_Snapshots;
with A11y.Sessions;
with A11y.States;

with A11ykit_Test_Support;

package body A11ykit_Compatibility_Tests is
   use Ada.Strings.Unbounded;
   use A11ykit;
   use A11ykit.Tree;
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Length;
   use type A11y.Geometry.Rectangle;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Properties.Property_Status;
   use type A11y.Results.Status_Code;
   use type A11y.Roles.Role;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   function Make
     (Item_Role : Role;
      X, Y, W, H : Natural;
      Name       : String;
      Focused    : Boolean := False)
      return Node
   is
      Result : Node;
   begin
      Result.Node_Role := Item_Role;
      Result.Bounds := (X => X, Y => Y, Width => W, Height => H);
      Result.Name := To_Unbounded_String (Name);
      Result.Node_State.Focused := Focused;
      return Result;
   end Make;

   procedure Run is
      Flat : Node_Vectors.Vector;
      Tree : Accessibility_Tree;
   begin
      --  A window enclosing a toolbar (which holds a button) and a list. The
      --  button sits inside both the window and the toolbar, so the tightest
      --  container -- the toolbar -- must win.
      Flat.Append (Make (Role_Window, 0, 0, 100, 100, "window"));
      Flat.Append (Make (Role_Toolbar, 0, 0, 100, 20, "toolbar"));
      Flat.Append
        (Make (Role_Button, 0, 0, 20, 20, "button", Focused => True));
      Flat.Append (Make (Role_List, 0, 20, 100, 80, "list"));

      Tree := Build (Flat);

      Check
        (Tree.Nodes (1).Parent = 0, "the outermost node (window) is the root");
      Check (Tree.Nodes (2).Parent = 1, "the toolbar nests under the window");
      Check
        (Tree.Nodes (3).Parent = 2,
         "the button nests under the tightest container (toolbar), not the window");
      Check
        (Tree.Nodes (4).Parent = 1,
         "the list nests under the window, not the toolbar");
      Check (Tree.Focused = 3, "the focused node is located");

      Check
        (Natural (Children_Of (Tree, 0).Length) = 1,
         "there is one root node");
      Check
        (Natural (Children_Of (Tree, 1).Length) = 2,
         "the window has two children");
      Check
        (Natural (Children_Of (Tree, 2).Length) = 1,
         "the toolbar has one child");
      Check
        (Natural (Children_Of (Tree, 3).Length) = 0,
         "the button is a leaf");
      Check
        (A11ykit.Compatibility.To_Semantic_Role (Role_Button) =
           A11y.Roles.Button
         and then A11ykit.Compatibility.To_Semantic_Role (Role_Window) =
           A11y.Roles.Window
         and then A11ykit.Compatibility.To_Semantic_Role (Role_Text_Input) =
           A11y.Roles.Text_Field
         and then A11ykit.Compatibility.To_Semantic_Role (Role_Unknown) =
           A11y.Roles.Custom,
         "compatibility maps legacy roles to semantic roles");
      Check
        (A11ykit.Compatibility.To_Semantic_Bounds
           ((X => 1, Y => 2, Width => 3, Height => 4)) =
           (Origin => (X => 1, Y => 2),
            Extent => (Width => 3, Height => 4)),
         "compatibility maps legacy rectangles to logical desktop bounds");
      Check
        (A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Enabled)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Sensitive)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Visible)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Showing)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Selected)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Focused)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Focusable)
         and then A11ykit.Compatibility.To_Semantic_States
           ((Enabled => True, Selected => True, Focused => True),
            Role_List_Item) (A11y.States.Selectable),
         "compatibility maps legacy state flags with derived basic exposure states");
      Check
        (A11ykit.Compatibility.Node_Id_For_Index (Tree, 3) =
           A11y.Node_Ids.From_Natural (3)
         and then A11ykit.Compatibility.Parent_Id (Tree, 3) =
           A11y.Node_Ids.From_Natural (2)
         and then A11ykit.Compatibility.Parent_Id (Tree, 1) =
           A11y.Node_Ids.No_Node
         and then A11ykit.Compatibility.Focused_Node (Tree) =
           A11y.Node_Ids.From_Natural (3)
         and then A11ykit.Compatibility.Node_Id_For_Index (Tree, 99) =
           A11y.Node_Ids.No_Node,
         "compatibility maps legacy tree indexes to snapshot node references");
      Check
        (A11y.Results.Succeeded (A11ykit.Compatibility.Validate_Tree (Tree)),
         "compatibility validates a built legacy tree");

      declare
         Result : A11y.Results.Result;
         Snapshot : constant A11y.Semantic_Snapshots.Semantic_Snapshot :=
           A11ykit.Compatibility.To_Semantic_Snapshot (Tree, Result);
         Button_Metadata : constant A11y.Semantic_Snapshots.Node_Metadata :=
           A11y.Semantic_Snapshots.Metadata
             (Snapshot, A11y.Node_Ids.From_Natural (3));
         Window_Metadata : constant A11y.Semantic_Snapshots.Node_Metadata :=
           A11y.Semantic_Snapshots.Metadata
             (Snapshot, A11y.Node_Ids.From_Natural (1));
      begin
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Semantic_Snapshots.Node_Count (Snapshot) = 4
            and then A11y.Semantic_Snapshots.Has_Node
              (Snapshot, A11y.Node_Ids.From_Natural (3)),
            "compatibility projects legacy trees into semantic snapshots");
         Check
           (Button_Metadata.Present
            and then Button_Metadata.Role = A11y.Roles.Button
            and then Button_Metadata.Name.Status = A11y.Properties.Present
            and then To_String (Button_Metadata.Name.Value) = "button"
            and then Button_Metadata.Description.Status = A11y.Properties.Empty
            and then Button_Metadata.Bounds.Status = A11y.Properties.Present
            and then Button_Metadata.Bounds.Value.Origin.X = 0
            and then Button_Metadata.Bounds.Value.Origin.Y = 0
            and then Button_Metadata.Bounds.Value.Extent.Width = 20
            and then Button_Metadata.Bounds.Value.Extent.Height = 20
            and then Button_Metadata.States (A11y.States.Focused)
            and then Button_Metadata.States (A11y.States.Focusable)
            and then Button_Metadata.Capabilities (A11y.Capabilities.Action),
            "compatibility snapshot preserves legacy button semantics");
         Check
           (Window_Metadata.Present
            and then Window_Metadata.Role = A11y.Roles.Window
            and then Window_Metadata.Capabilities (A11y.Capabilities.Surface),
            "compatibility snapshot derives surface capabilities for legacy windows");
      end;

      declare
         Session : A11y.Sessions.Semantic_Session;
         Result : A11y.Results.Result;
         Root_Id : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (1);
         Toolbar_Id : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (2);
         Button_Id : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (3);
         List_Id : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (4);
         Item : A11y.Registry.Entry_Snapshot;
      begin
         A11ykit.Compatibility.Populate_Session (Tree, Session, Result);
         A11y.Sessions.Registry_Snapshot (Session, Button_Id, Item, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Sessions.Is_Attached (Session, Root_Id)
            and then A11y.Sessions.Parent_Of (Session, Root_Id) =
              A11y.Node_Ids.No_Node
            and then A11y.Sessions.Parent_Of (Session, Toolbar_Id) = Root_Id
            and then A11y.Sessions.Parent_Of (Session, Button_Id) = Toolbar_Id
            and then A11y.Sessions.Parent_Of (Session, List_Id) = Root_Id
            and then A11y.Sessions.Focused_Node (Session) = Button_Id
            and then Item.Capabilities (A11y.Capabilities.Action)
            and then A11y.Results.Succeeded
              (A11y.Sessions.Validate_Tree (Session)),
            "compatibility populates semantic sessions from legacy trees");
         Check
           (A11y.Sessions.Pending_Event_Count (Session) = 12,
            "compatibility session population emits lifecycle tree and focus events");
      end;

      declare
         Empty : Accessibility_Tree;
         Bad   : Accessibility_Tree := Tree;

         procedure Set_Parent
           (Item   : in out Accessibility_Tree;
            Index  : Positive;
            Parent : Natural)
         is
            Updated : Node := Item.Nodes (Index);
         begin
            Updated.Parent := Parent;
            Item.Nodes.Replace_Element (Index, Updated);
         end Set_Parent;
      begin
         Check
           (A11ykit.Compatibility.Validate_Tree (Empty).Status =
              A11y.Results.Invalid_State,
            "compatibility rejects empty legacy trees");

         Set_Parent (Bad, 2, 0);
         Check
           (A11ykit.Compatibility.Validate_Tree (Bad).Status =
              A11y.Results.Invalid_State,
            "compatibility rejects legacy trees with multiple roots");

         Bad := Tree;
         Set_Parent (Bad, 2, 99);
         Check
           (A11ykit.Compatibility.Validate_Tree (Bad).Status =
              A11y.Results.Node_Unavailable,
            "compatibility rejects legacy trees with dangling parents");

         Bad := Tree;
         Set_Parent (Bad, 2, 2);
         Check
           (A11ykit.Compatibility.Validate_Tree (Bad).Status =
              A11y.Results.Invalid_State,
            "compatibility rejects legacy trees with self-parent links");

         Bad := Tree;
         Set_Parent (Bad, 1, 2);
         Set_Parent (Bad, 2, 1);
         Check
           (A11ykit.Compatibility.Validate_Tree (Bad).Status =
              A11y.Results.Invalid_State,
            "compatibility rejects legacy tree cycles");

         Bad := Tree;
         Bad.Focused := 99;
         Check
           (A11ykit.Compatibility.Validate_Tree (Bad).Status =
              A11y.Results.Node_Unavailable,
            "compatibility rejects legacy trees with dangling focus");

         declare
            Result : A11y.Results.Result;
            Session : A11y.Sessions.Semantic_Session;
            Snapshot : constant A11y.Semantic_Snapshots.Semantic_Snapshot :=
              A11ykit.Compatibility.To_Semantic_Snapshot (Bad, Result);
         begin
            Check
              (Result.Status = A11y.Results.Node_Unavailable
               and then A11y.Semantic_Snapshots.Node_Count (Snapshot) = 0,
               "compatibility refuses invalid legacy trees before semantic projection");
            A11ykit.Compatibility.Populate_Session (Bad, Session, Result);
            Check
              (Result.Status = A11y.Results.Node_Unavailable
               and then A11y.Sessions.Pending_Event_Count (Session) = 0,
               "compatibility refuses invalid legacy trees before session mutation");
         end;
      end;
   end Run;
end A11ykit_Compatibility_Tests;
