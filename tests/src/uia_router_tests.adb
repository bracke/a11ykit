with Ada.Calendar;
with Ada.Command_Line;
with Interfaces;
with Interfaces.C;
with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Text_IO;

with A11y.Actions;
with A11y.Capabilities;
with A11y.Documents;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Geometry;
with A11y.Images;
with A11y.Live_Regions;
with A11y.Native_Identity;
with A11y.Native_Boundary_Calls;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.Semantic_Snapshots;
with A11y.Selection;
with A11y.States;
with A11y.Tables;
with A11y.Text;
with A11y.Trees;
with A11y.Values;
with A11y.Windows;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_COM_Exports;
with A11y.Windows_Backend.UIA_COM_Live_Exports;
with A11y.Windows_Backend.UIA_COM_Object_Exports;
with A11y.Windows_Backend.UIA_COM_VTables;
with A11y.Windows_Backend.UIA_Actions;
with A11y.Windows_Backend.UIA_Document;
with A11y.Windows_Backend.UIA_Events;
with A11y.Windows_Backend.UIA_Fragments;
with A11y.Windows_Backend.UIA_Image;
with A11y.Windows_Backend.UIA_Live_Regions;
with A11y.Windows_Backend.UIA_Mappings;
with A11y.Windows_Backend.UIA_Native_Bridge;
with A11y.Windows_Backend.UIA_Native_Callbacks;
with A11y.Windows_Backend.UIA_Native_Values;
with A11y.Windows_Backend.UIA_Provider_Boundary;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Properties;
with A11y.Windows_Backend.UIA_Request_Router;
with A11y.Windows_Backend.UIA_Selection;
with A11y.Windows_Backend.UIA_Surfaces;
with A11y.Windows_Backend.UIA_Table;
with A11y.Windows_Backend.UIA_Text;
with A11y.Windows_Backend.UIA_Values;
with A11y.Windows_Backend.UIA_Bridge_Audit;

procedure UIA_Router_Tests is
   procedure Raise_Main_Stack_Limit is
      use Interfaces.C;

      RLIMIT_STACK : constant int := 3;
      Target_Stack : constant unsigned_long := 512 * 1024 * 1024;
      RLIM_INFINITY : constant unsigned_long := unsigned_long'Last;

      type Rlimit is record
         Cur : unsigned_long;
         Max : unsigned_long;
      end record
        with Convention => C;

      function Getrlimit
        (Resource : int;
         Limit    : access Rlimit)
         return int
        with Import, Convention => C, External_Name => "getrlimit";

      function Setrlimit
        (Resource : int;
         Limit    : access constant Rlimit)
         return int
        with Import, Convention => C, External_Name => "setrlimit";

      Limit : aliased Rlimit;
      Ignored : int;
   begin
      if Getrlimit (RLIMIT_STACK, Limit'Access) = 0
        and then Limit.Cur < Target_Stack
      then
         if Limit.Max = RLIM_INFINITY or else Limit.Max >= Target_Stack then
            Limit.Cur := Target_Stack;
         else
            Limit.Cur := Limit.Max;
         end if;

         Ignored := Setrlimit (RLIMIT_STACK, Limit'Access);
      end if;
   end Raise_Main_Stack_Limit;

   procedure Run is
   use type A11y.Event_Sequence;
   use type A11y.Actions.Action_Id;
   use type A11y.Results.Status_Code;
   use type A11y.Semantic_Revision;
   use type A11y.Diagnostics.Category;
   use type A11y.Properties.Property_Id;
   use type A11y.Properties.Property_Status;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Length;
   use type A11y.Geometry.Rectangle;
   use type A11y.Live_Regions.Live_Setting;
   use type A11y.Native_Boundary_Calls.Boundary_Return_Class;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Native_Object_Caches.Native_Object_Id;
   use type A11y.Roles.Role;
   use type A11y.Tables.Logical_Index;
   use type A11y.Tables.Sort_Order;
   use type A11y.Text.Text_Edit_Kind;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.UIA_Request_Kind;
   use type A11y.Windows.Surface_Kind;
   use type A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
   use type A11y.Windows_Backend.UIA_Com_Providers.Provider_State;
   use type A11y.Windows_Backend.UIA_COM_Exports.Callback_Slot;
   use type A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
   use type A11y.Windows_Backend.UIA_Actions.UIA_Action;
   use type A11y.Windows_Backend.UIA_Actions.UIA_Pattern;
   use type A11y.Windows_Backend.UIA_Events.UIA_Event_Kind;
   use type A11y.Windows_Backend.UIA_Events.UIA_Property_Event;
   use type A11y.Windows_Backend.UIA_Events.Posting_Drain_Stop_Reason;
   use type A11y.Windows_Backend.UIA_Provider_Registry
     .Native_Call_Mutation_Kind;
   use type A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
   use type A11y.Windows_Backend.UIA_Provider_Registry.Registry_Mutation_Kind;
   use type A11y.Windows_Backend.UIA_Events.Queue_Posting_Operation;
   use type A11y.Windows_Backend.UIA_Events.UIA_Structure_Event;
   use type A11y.Windows_Backend.UIA_Events.UIA_Window_Event;
   use type A11y.Windows_Backend.UIA_Mappings.UIA_Control_Type;
   use type A11y.Windows_Backend.UIA_Mappings.UIA_Relation_Property;
   use type A11y.Windows_Backend.UIA_Native_Values.Native_Value_Kind;
   use type A11y.Windows_Backend.UIA_Selection.Selection_Request_Kind;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply_Kind;
   use type A11y.Windows_Backend.UIA_Provider_Boundary.HRESULT_Status;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Exception_Rule;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Bridge_Operation;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Calling_Convention_Rule;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Lifetime_Rule;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Nullability_Rule;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Ownership_Rule;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Representation_Rule;
   use type A11y.Windows_Backend.UIA_Bridge_Audit.Thread_Rule;
   use type Interfaces.Integer_32;
   use type Interfaces.C.char;
   use type Interfaces.C.double;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;
   use type A11y.Windows_Backend.UIA_Document.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Image.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Live_Regions.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Properties.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Selection.Reply_Kind;
   use type A11y.Selection.Selection_Direction;
   use type A11y.Windows_Backend.UIA_Surfaces.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Table.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Text.Reply_Kind;
   use type A11y.Windows_Backend.UIA_Values.Reply_Kind;
   use type A11y.Values.Value_Kind;

   Failures : Natural := 0;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Ada.Text_IO.Put_Line ("ok   " & Message);
      else
         Ada.Text_IO.Put_Line ("FAIL " & Message);
         Failures := Failures + 1;
      end if;
   end Check;

   use A11y.Windows_Backend.UIA_Request_Router;

   type Snapshot_Access is access Snapshot_Bundle;

   Session : constant A11y.Native_Identity.Backend_Session_Id :=
     A11y.Native_Identity.Create_Session;
   Root : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (610);
   Child : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (611);
   Snapshots : constant Snapshot_Access := new Snapshot_Bundle;
   Result : A11y.Results.Result;
   Request_Item : Request :=
     (Kind      => Property_Query,
      Property  => A11y.Windows_Backend.UIA_Properties.Name,
      Action    => A11y.Actions.Press,
      Direction => A11y.Windows_Backend.UIA_Fragments.First_Child,
      Relation  => A11y.Relations.Labelled_By,
      Value     => A11y.Windows_Backend.UIA_Values.Current_Value,
      Requested_Value => (Kind => A11y.Values.Unknown),
      Selection => A11y.Windows_Backend.UIA_Selection.Selected_Count,
      Selection_Request => A11y.Windows_Backend.UIA_Selection.Select_Item,
      Selection_Target => A11y.Node_Ids.No_Node,
      Text      => A11y.Windows_Backend.UIA_Text.Character_Count,
      Text_Edit => A11y.Text.Insert_Text,
      Table     => A11y.Windows_Backend.UIA_Table.Row_Count,
      Image     => A11y.Windows_Backend.UIA_Image.Description,
      Document  => A11y.Windows_Backend.UIA_Document.Locale,
      Live_Region =>
        A11y.Windows_Backend.UIA_Live_Regions.Setting_Name,
      Surface   => A11y.Windows_Backend.UIA_Surfaces.Kind_Name,
      Index     => 1,
      Count     => 0,
      Replacement =>
        Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String,
      Row       => 0,
      Column    => 0,
      Event     =>
        (Sequence  => 9,
         Timestamp => Ada.Calendar.Clock,
         Source    => Root,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 3),
      Use_Prepared_Event => False,
      Prepared_Event =>
        (Status => A11y.Results.Success,
         Event =>
           (Sequence  => 0,
            Timestamp => Ada.Calendar.Clock,
            Source    => A11y.Node_Ids.No_Node,
            Kind      => A11y.Events.Node_Created,
            Revision  => A11y.Initial_Revision),
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>));
   Routed : Routed_Reply;
   Boundary_Request :
     A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request;
   Boundary_Reply :
     A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;
   Registered_Boundary_Report :
     A11y.Windows_Backend.UIA_Provider_Boundary
       .Registered_Native_Request_Report;
   Emission : A11y.Windows_Backend.UIA_Events.UIA_Event_Emission;
begin
   A11y.Trees.Set_Root (Snapshots.Fragment.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Fragment.Tree, Root, Child, Result);

   Snapshots.Properties.Id := Root;
   Snapshots.Properties.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Properties.Tree, Root, Result);
   Snapshots.Properties.Role := A11y.Roles.Button;
   Snapshots.Properties.Bounds :=
     (Origin => (X => -10, Y => 20), Extent => (Width => 80, Height => 24));
   Snapshots.Properties.Name := A11y.Properties.Present ("Press");
   Snapshots.Properties.Visible_Title :=
     A11y.Properties.Present ("Primary action");
   Snapshots.Properties.Automation_Id :=
     A11y.Properties.Present ("primary-action");
   Snapshots.Properties.Description :=
     A11y.Properties.Present ("Submits the current dialog");
   Snapshots.Properties.Help_Text :=
     A11y.Properties.Present ("Press to continue");
   Snapshots.Properties.Placeholder :=
     A11y.Properties.Present ("Type a value");
   Snapshots.Properties.Value_Text := A11y.Properties.Present ("42%");
   Snapshots.Properties.Keyboard_Shortcut :=
     A11y.Properties.Present ("Alt+P");
   Snapshots.Properties.Locale := A11y.Properties.Present ("da-DK");
   Snapshots.Properties.Orientation := A11y.Properties.Present ("vertical");
   Snapshots.Properties.Position_In_Set := A11y.Properties.Present (2);
   Snapshots.Properties.Size_Of_Set := A11y.Properties.Present (5);
   Snapshots.Properties.Hierarchical_Level := A11y.Properties.Present (3);
   Snapshots.Properties.Heading_Level := A11y.Properties.Present (2);
   Snapshots.Properties.Landmark := A11y.Properties.Present ("main");
   Snapshots.Actions (A11y.Actions.Press) := True;
   Snapshots.Actions (A11y.Actions.Toggle) := True;
   Snapshots.Actions (A11y.Actions.Expand) := True;
   Snapshots.Actions (A11y.Actions.Scroll_Into_View) := True;
   Snapshots.Actions (A11y.Actions.Close) := True;
   Snapshots.Action_Node := Child;
   Snapshots.Action_Root := Root;
   A11y.Trees.Set_Root (Snapshots.Action_Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Action_Tree, Root, Child, Result);
   Snapshots.Fragment.Session := Session;
   Snapshots.Fragment.Fragment_Root := Root;
   Snapshots.Fragment.Node := Root;
   Snapshots.Fragment.Focused_Node := Child;
   Snapshots.Fragment.Hit_Test_Point := (X => 25, Y => 35);
   Snapshots.Fragment.Bounds (A11y.Node_Ids.To_Natural (Root)) :=
     (Origin => (X => 10, Y => 20), Extent => (Width => 300, Height => 200));
   Snapshots.Fragment.Bounds (A11y.Node_Ids.To_Natural (Child)) :=
     (Origin => (X => 20, Y => 30), Extent => (Width => 40, Height => 40));
   A11y.Trees.Set_Root (Snapshots.Fragment.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Fragment.Tree, Root, Child, Result);
   Snapshots.Relation_Source := Root;
   Snapshots.Relation_Root := Root;
   A11y.Trees.Set_Root (Snapshots.Relation_Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Relation_Tree, Root, Child, Result);
   Snapshots.Value.Id := Child;
   Snapshots.Value.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Value.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Value.Tree, Root, Child, Result);
   Snapshots.Value.Metadata.Current := A11y.Values.Integer (5);
   Snapshots.Value.Metadata.Minimum := A11y.Values.Integer (0);
   Snapshots.Value.Metadata.Maximum := A11y.Values.Integer (10);
   Snapshots.Value.Metadata.Small_Increment := A11y.Values.Integer (1);
   Snapshots.Value.Metadata.Mode := A11y.Values.Writable;
   A11y.Selection.Configure
     (Snapshots.Selection.Selection, A11y.Selection.Multiple);
   A11y.Selection.Select_Item (Snapshots.Selection.Selection, Child, Result);
   A11y.Selection.Set_Current_Item
     (Snapshots.Selection.Selection, Child, Result);
   Snapshots.Selection.Item := Child;
   Snapshots.Selection.Items.Append (Child);
   Snapshots.Text.Content :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
       (Wide_Wide_String'("A")
        & Wide_Wide_Character'Val (16#1F600#)
        & Wide_Wide_String'("B"));
   Snapshots.Text.Id := Child;
   Snapshots.Text.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Text.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Text.Tree, Root, Child, Result);
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (2);
   A11y.Tables.Configure (Snapshots.Table.Table, Rows => 4, Columns => 5);
   A11y.Tables.Configure_Displayed
     (Snapshots.Table.Table, Rows => 3, Columns => 4, Result => Result);
   A11y.Tables.Configure_Visible
     (Snapshots.Table.Table,
      Rows => (First => 1, Count => 2),
      Columns => (First => 1, Count => 2),
      Result => Result);
   A11y.Tables.Add_Cell
     (Snapshots.Table.Table,
      Child,
      Row => 1,
      Column => 2,
      Row_Span => 2,
      Column_Span => 3,
      Result => Result);
   A11y.Tables.Set_Current_Cell (Snapshots.Table.Table, Child, Result);
   A11y.Tables.Set_Sort
     (Snapshots.Table.Table, Child, A11y.Tables.Ascending, Result);
   Snapshots.Table.Id := Root;
   Snapshots.Table.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Table.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Table.Tree, Root, Child, Result);
   Snapshots.Image.Metadata.Kind := A11y.Images.Informative;
   Snapshots.Image.Metadata.Alternative_Text :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Revenue chart");
   Snapshots.Image.Metadata.Caption :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Q1 revenue");
   Snapshots.Image.Metadata.Intrinsic_Dimensions :=
     (Width => 640, Height => 480);
   Snapshots.Image.Metadata.Has_Intrinsic_Size := True;
   Snapshots.Image.Id := Child;
   Snapshots.Image.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Image.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Image.Tree, Root, Child, Result);
   Snapshots.Document.Metadata.Role := A11y.Documents.Heading;
   Snapshots.Document.Metadata.Heading_Level := 2;
   Snapshots.Document.Metadata.Language :=
     Ada.Strings.Unbounded.To_Unbounded_String ("en-US");
   Snapshots.Document.Metadata.Title :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Overview");
   Snapshots.Document.Metadata.Author :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Ada Team");
   Snapshots.Document.Metadata.Subject :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Accessibility");
   Snapshots.Document.Metadata.Version :=
     Ada.Strings.Unbounded.To_Unbounded_String ("1.0");
   Snapshots.Document.Metadata.Revision :=
     Ada.Strings.Unbounded.To_Unbounded_String ("draft");
   Snapshots.Document.Metadata.Creation_Metadata :=
     Ada.Strings.Unbounded.To_Unbounded_String ("created");
   Snapshots.Document.Metadata.Modification_Metadata :=
     Ada.Strings.Unbounded.To_Unbounded_String ("modified");
   Snapshots.Document.Metadata.Landmark :=
     Ada.Strings.Unbounded.To_Unbounded_String ("main");
   Snapshots.Document.Metadata.Page_Count := 12;
   Snapshots.Document.Metadata.Current_Page := 4;
   Snapshots.Document.Id := Child;
   Snapshots.Document.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Document.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Document.Tree, Root, Child, Result);
   Snapshots.Live_Region.Id := Child;
   Snapshots.Surface.Metadata.Kind := A11y.Windows.Modal_Dialog;
   Snapshots.Surface.Metadata.State.Visible := True;
   Snapshots.Surface.Metadata.State.Active := True;
   Snapshots.Surface.Metadata.State.Modal := True;
   Snapshots.Surface.Metadata.State.Closable := True;
   Snapshots.Surface.Metadata.State.Resizable := False;
   Snapshots.Surface.Metadata.State.Movable := True;
   Snapshots.Surface.Id := Child;
   Snapshots.Surface.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Surface.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Surface.Tree, Root, Child, Result);
   Snapshots.Event_Root := Root;
   A11y.Trees.Set_Root (Snapshots.Event_Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Event_Tree, Root, Child, Result);
   A11y.Relations.Add
     (Snapshots.Relations,
      Root,
      A11y.Relations.Labelled_By,
      Child,
      Result);

   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Press",
      "Windows UIA request router dispatches property queries");
   Check
     (A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Name)
      = A11y.Properties.Accessible_Name,
      "Windows UIA name property maps to the neutral accessible name");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Visible_Title;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "Primary action",
      "Windows UIA request router dispatches visible-title properties");

   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Placeholder;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Type a value",
      "Windows UIA request router dispatches placeholder properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Value_Text;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "42%",
      "Windows UIA request router dispatches value-text properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Automation_Id;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "primary-action",
      "Windows UIA request router dispatches semantic identifier properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Description;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "Submits the current dialog",
      "Windows UIA request router dispatches description properties");

   declare
      Metadata_Snapshot_Ref : constant Snapshot_Access :=
        new Snapshot_Bundle'(Snapshots.all);
      Metadata_Snapshot : Snapshot_Bundle renames Metadata_Snapshot_Ref.all;
      Caps : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
   begin
      Metadata_Snapshot.Properties.Id := Child;
      Metadata_Snapshot.Properties.Use_Node_Metadata := True;
      A11y.Semantic_Snapshots.Set_Node
        (Snapshot     => Metadata_Snapshot.Properties.Nodes,
         Node         => Child,
         Role         => A11y.Roles.Window,
         Name         => "Metadata Window",
         Description  => "Metadata-backed UIA window",
         Help_Text    => A11y.Properties.Present ("Metadata help"),
         Placeholder  => A11y.Properties.Present ("Metadata placeholder"),
         Value_Text   => A11y.Properties.Present ("Metadata value"),
         Protected_Value_Text => False,
         Bounds       =>
           A11y.Properties.Present
             ((Origin => (X => 111, Y => 222),
               Extent => (Width => 333, Height => 44))),
         Semantic_Identifier => A11y.Properties.Present ("metadata-uia-id"),
         Visible_Title => A11y.Properties.Present ("Metadata UIA Title"),
         Keyboard_Shortcut => A11y.Properties.Present ("Alt+M"),
         Locale       => A11y.Properties.Present ("fr-CA"),
         Orientation  => A11y.Properties.Present ("horizontal"),
         Landmark     => A11y.Properties.Present ("main"),
         States       => A11y.States.Empty_State_Set,
         Capabilities => Caps,
         Exposure     => A11y.Nodes.Expose_Node,
         Result       => Result);
      Check
        (Result.Status = A11y.Results.Unsupported_Capability,
         "Windows UIA metadata fixture rejects role-incompatible metadata");

      Caps (A11y.Capabilities.Surface) := True;
      A11y.Semantic_Snapshots.Set_Node
        (Snapshot     => Metadata_Snapshot.Properties.Nodes,
         Node         => Child,
         Role         => A11y.Roles.Window,
         Name         => "Metadata Window",
         Description  => "Metadata-backed UIA window",
         Help_Text    => A11y.Properties.Present ("Metadata help"),
         Placeholder  => A11y.Properties.Present ("Metadata placeholder"),
         Value_Text   => A11y.Properties.Present ("Metadata value"),
         Protected_Value_Text => False,
         Bounds       =>
           A11y.Properties.Present
             ((Origin => (X => 111, Y => 222),
               Extent => (Width => 333, Height => 44))),
         Semantic_Identifier => A11y.Properties.Present ("metadata-uia-id"),
         Visible_Title => A11y.Properties.Present ("Metadata UIA Title"),
         Keyboard_Shortcut => A11y.Properties.Present ("Alt+M"),
         Locale       => A11y.Properties.Present ("fr-CA"),
         Orientation  => A11y.Properties.Present ("horizontal"),
         Landmark     => A11y.Properties.Present ("main"),
         States       => A11y.States.Empty_State_Set,
         Capabilities => Caps,
         Exposure     => A11y.Nodes.Expose_Node,
         Result       => Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA metadata fixture stores per-node semantic metadata");
      declare
         Metadata : constant A11y.Semantic_Snapshots.Node_Metadata :=
           A11y.Semantic_Snapshots.Metadata
             (Metadata_Snapshot.Properties.Nodes, Child);
      begin
         Check
           (Metadata.Bounds.Status = A11y.Properties.Present
            and then Metadata.Bounds.Value.Origin.X = 111
            and then Metadata.Semantic_Identifier.Status =
              A11y.Properties.Present
            and then Metadata.Visible_Title.Status = A11y.Properties.Present
            and then Metadata.Keyboard_Shortcut.Status =
              A11y.Properties.Present
            and then Metadata.Locale.Status = A11y.Properties.Present
            and then Metadata.Orientation.Status = A11y.Properties.Present
            and then Metadata.Landmark.Status = A11y.Properties.Present,
            "Windows UIA metadata fixture stores per-node title, shortcut, locale, orientation, landmark, bounds, and identifier metadata");
      end;

      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Name;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata Window",
         "Windows UIA request router resolves names from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Control_Type;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_Control_Type
         and then Routed.Control_Type =
           A11y.Windows_Backend.UIA_Mappings.Window,
         "Windows UIA request router resolves control types from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      declare
         Property_Reply : constant
           A11y.Windows_Backend.UIA_Properties.Property_Reply :=
             A11y.Windows_Backend.UIA_Properties.Query_Property
               (Metadata_Snapshot.Properties,
                A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle);
      begin
         Check
           (Property_Reply.Kind =
              A11y.Windows_Backend.UIA_Properties.Rectangle_Reply,
            "Windows UIA property mapper returns a rectangle for metadata bounds");
         Check
           (Property_Reply.Kind =
              A11y.Windows_Backend.UIA_Properties.Rectangle_Reply
            and then Property_Reply.Bounds.Origin.X = 111
           and then Property_Reply.Bounds.Origin.Y = 222
           and then Property_Reply.Bounds.Extent.Width = 333
           and then Property_Reply.Bounds.Extent.Height = 44,
            "Windows UIA property mapper resolves bounds from semantic metadata snapshots");
      end;

      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Help_Text;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata help",
         "Windows UIA request router resolves help text from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Automation_Id;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "metadata-uia-id",
         "Windows UIA request router resolves automation identifiers from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Visible_Title;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata UIA Title",
         "Windows UIA request router resolves visible titles from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Keyboard_Shortcut;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Alt+M",
         "Windows UIA request router resolves keyboard shortcuts from semantic metadata snapshots");

      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Locale;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) = "fr-CA",
         "Windows UIA request router resolves locales from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Orientation;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) =
           "horizontal",
         "Windows UIA request router resolves orientations from semantic metadata snapshots");

      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Landmark;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) = "main",
         "Windows UIA request router resolves landmarks from semantic metadata snapshots");

      Request_Item.Property :=
        A11y.Windows_Backend.UIA_Properties.Placeholder;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata placeholder",
         "Windows UIA request router resolves placeholders from semantic metadata snapshots");

      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Value_Text;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Property_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata value",
         "Windows UIA request router resolves value text from semantic metadata snapshots");

      A11y.Semantic_Snapshots.Set_Node
        (Snapshot     => Metadata_Snapshot.Properties.Nodes,
         Node         => Child,
         Role         => A11y.Roles.Window,
         Name         => "Metadata Window",
         Description  => "Metadata-backed UIA window",
         Help_Text    => A11y.Properties.Present ("Metadata help"),
         Placeholder  => A11y.Properties.Present ("Metadata placeholder"),
         Value_Text   => A11y.Properties.Present ("Secret metadata value"),
         Protected_Value_Text => True,
         Bounds       =>
           A11y.Properties.Present
             ((Origin => (X => 111, Y => 222),
               Extent => (Width => 333, Height => 44))),
         Semantic_Identifier => A11y.Properties.Present ("metadata-uia-id"),
         Visible_Title => A11y.Properties.Present ("Metadata UIA Title"),
         Keyboard_Shortcut => A11y.Properties.Present ("Alt+M"),
         Locale       => A11y.Properties.Present ("fr-CA"),
         Orientation  => A11y.Properties.Present ("horizontal"),
         Landmark     => A11y.Properties.Present ("main"),
         States       => A11y.States.Empty_State_Set,
         Capabilities => Caps,
         Exposure     => A11y.Nodes.Expose_Node,
         Result       => Result);
      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Value_Text;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (A11y.Results.Succeeded (Result)
         and then Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Permission_Denied,
         "Windows UIA request router enforces protected value text from semantic metadata snapshots");

      A11y.Semantic_Snapshots.Clear_Node
        (Metadata_Snapshot.Properties.Nodes, Child, Result);
      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Name;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "Windows UIA request router rejects metadata-mode nodes without semantic metadata");
   end;
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Locale;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "da-DK",
      "Windows UIA request router dispatches locale properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Orientation;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "vertical",
      "Windows UIA request router dispatches orientation properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Position_In_Set;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_Integer
      and then Routed.Integer_Item = 2,
      "Windows UIA request router dispatches set-position properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Size_Of_Set;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_Integer
      and then Routed.Integer_Item = 5,
      "Windows UIA request router dispatches set-size properties");
   Request_Item.Property :=
     A11y.Windows_Backend.UIA_Properties.Hierarchical_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_Integer
      and then Routed.Integer_Item = 3,
      "Windows UIA request router dispatches hierarchical-level properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Heading_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_Integer
      and then Routed.Integer_Item = 2,
      "Windows UIA request router dispatches heading-level properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Landmark;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "main",
      "Windows UIA request router dispatches landmark properties");
   Check
     (A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Placeholder)
      = A11y.Properties.Placeholder
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Value_Text)
      = A11y.Properties.Value_Text
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Visible_Title)
      = A11y.Properties.Visible_Title
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Automation_Id)
      = A11y.Properties.Semantic_Identifier
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Description)
      = A11y.Properties.Description
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Locale)
      = A11y.Properties.Locale
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Orientation)
      = A11y.Properties.Orientation
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Position_In_Set)
      = A11y.Properties.Set_Position
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Size_Of_Set)
      = A11y.Properties.Set_Size
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Hierarchical_Level)
      = A11y.Properties.Hierarchical_Level
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Heading_Level)
      = A11y.Properties.Heading_Level
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Landmark)
      = A11y.Properties.Landmark
      and then A11y.Windows_Backend.UIA_Properties.Neutral_Property
        (A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle)
      = A11y.Properties.Bounds,
      "Windows UIA properties map back to neutral property identifiers");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Name;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Name);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "Press",
         "Windows UIA property mapper preserves accessible names");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Visible_Title);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "Primary action",
         "Windows UIA property mapper preserves visible titles");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Keyboard_Shortcut);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "Alt+P",
         "Windows UIA property mapper preserves shortcut text");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Description);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "Submits the current dialog",
         "Windows UIA property mapper preserves descriptions");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Locale);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "da-DK",
         "Windows UIA property mapper preserves locale properties");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Orientation);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "vertical",
         "Windows UIA property mapper preserves orientation properties");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Position_In_Set);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Integer_Reply
         and then Property_Reply.Integer_Item = 2,
         "Windows UIA property mapper preserves set-position properties");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Heading_Level);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Integer_Reply
         and then Property_Reply.Integer_Item = 2,
         "Windows UIA property mapper preserves heading-level properties");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Landmark);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "main",
         "Windows UIA property mapper preserves landmark properties");
   end;

   declare
      Invalid_Snapshot :
        A11y.Windows_Backend.UIA_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Property_Reply : A11y.Windows_Backend.UIA_Properties.Property_Reply;
   begin
      Invalid_Snapshot.Hierarchical_Level := A11y.Properties.Present (-1);
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Invalid_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Hierarchical_Level);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Invalid_Range,
         "Windows UIA property mapper rejects negative structural metadata");

      Invalid_Snapshot := Snapshots.Properties;
      Invalid_Snapshot.Heading_Level := A11y.Properties.Present (-1);
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Invalid_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Heading_Level);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Invalid_Range,
         "Windows UIA property mapper rejects negative heading levels");
   end;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Automation_Id);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "primary-action",
         "Windows UIA property mapper preserves semantic identifiers");
   end;

   declare
      Limited_Snapshot :
        A11y.Windows_Backend.UIA_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Property_Reply : A11y.Windows_Backend.UIA_Properties.Property_Reply;
   begin
      A11y.Resource_Limits.Set_Limit
        (Limited_Snapshot.Limits,
         A11y.Resource_Limits.Native_String_Size,
         3,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA property mapper configures native string limit");

      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Limited_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Keyboard_Shortcut);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Resource_Limit,
         "Windows UIA property mapper bounds native string replies");

      Limited_Snapshot := Snapshots.Properties;
      A11y.Resource_Limits.Set_Limit
        (Limited_Snapshot.Limits,
         A11y.Resource_Limits.Native_Array_Size,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA property mapper configures native array limit");

      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Limited_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Position_In_Set);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Resource_Limit,
         "Windows UIA property mapper bounds structural set-position replies");

      Limited_Snapshot := Snapshots.Properties;
      A11y.Resource_Limits.Set_Limit
        (Limited_Snapshot.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA property mapper configures traversal-depth limit");

      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Limited_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Heading_Level);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Resource_Limit,
         "Windows UIA property mapper bounds structural heading-level replies");

      Limited_Snapshot := Snapshots.Properties;
      Limited_Snapshot.Limits.Limits
        (A11y.Resource_Limits.Native_String_Size) := 0;
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Limited_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Heading_Level);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA property mapper rejects invalid limit configs before native properties");
   end;

   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Name;
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Native_String_Size, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router applies configured property string limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Value_Text);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Property_Reply.Text)
           = "42%",
         "Windows UIA property mapper exposes ordinary value text");
   end;

   declare
      Deep_Property : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (623);
      Property_Reply : A11y.Windows_Backend.UIA_Properties.Property_Reply;
   begin
      Snapshots.Properties.Use_Tree_Projection := True;
      Snapshots.Properties.Exposure
        (A11y.Node_Ids.To_Natural (Root)) :=
           A11y.Nodes.Hide_Node_And_Subtree;
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Snapshots.Properties, A11y.Windows_Backend.UIA_Properties.Name);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA property mapper rejects hidden property nodes");
      Snapshots.Properties.Exposure
        (A11y.Node_Ids.To_Natural (Root)) := A11y.Nodes.Expose_Node;
      Snapshots.Properties.Id := Deep_Property;
      A11y.Trees.Attach
        (Snapshots.Properties.Tree, Root, Child, Result);
      A11y.Trees.Attach
        (Snapshots.Properties.Tree, Child, Deep_Property, Result);
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Name;
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "Windows UIA request router applies configured Property traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Snapshots.Properties.Id := Root;
      Snapshots.Properties.Use_Tree_Projection := False;
   end;

   declare
      Derived_Snapshot :
        A11y.Windows_Backend.UIA_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Property_Reply : A11y.Windows_Backend.UIA_Properties.Property_Reply;
   begin
      Derived_Snapshot.Role := A11y.Roles.Text_Field;
      Derived_Snapshot.States := A11y.States.Empty_State_Set;
      Derived_Snapshot.Capabilities :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set, A11y.Capabilities.Text);
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Derived_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Is_Keyboard_Focusable);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Boolean_Reply
         and then Property_Reply.Boolean_Item,
         "Windows UIA property mapper exposes derived focusability");
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Derived_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Is_Enabled);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Boolean_Reply,
         "Windows UIA property mapper accepts capability-derived state snapshots");
   end;

   Request_Item.Property :=
     A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Property_Rectangle
      and then Routed.Bounds = Snapshots.Properties.Bounds,
      "Windows UIA request router dispatches bounding rectangle properties");
   Request_Item.Property := A11y.Windows_Backend.UIA_Properties.Name;

   declare
      Property_Reply : constant
        A11y.Windows_Backend.UIA_Properties.Property_Reply :=
          A11y.Windows_Backend.UIA_Properties.Query_Property
            (Snapshots.Properties,
             A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle);
   begin
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Rectangle_Reply
         and then Property_Reply.Bounds.Origin.X = -10
         and then Property_Reply.Bounds.Origin.Y = 20
         and then Property_Reply.Bounds.Extent.Width = 80
         and then Property_Reply.Bounds.Extent.Height = 24,
         "Windows UIA property mapper returns neutral logical bounds");
   end;

   declare
      Password_Snapshot :
        A11y.Windows_Backend.UIA_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Property_Reply : A11y.Windows_Backend.UIA_Properties.Property_Reply;
   begin
      Password_Snapshot.Role := A11y.Roles.Password_Field;
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Password_Snapshot, A11y.Windows_Backend.UIA_Properties.Is_Password);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Boolean_Reply
         and then Property_Reply.Boolean_Item,
         "Windows UIA property mapper marks password fields as password");

      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Password_Snapshot, A11y.Windows_Backend.UIA_Properties.Value_Text);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Permission_Denied,
         "Windows UIA property mapper blocks password value text");

      Password_Snapshot.Role := A11y.Roles.Text_Field;
      Password_Snapshot.Protected_Value_Text := True;
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Password_Snapshot, A11y.Windows_Backend.UIA_Properties.Value_Text);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Permission_Denied,
         "Windows UIA property mapper blocks protected value text");

      Password_Snapshot.Role := A11y.Roles.Custom;
      Password_Snapshot.States := A11y.States.With_State
        (A11y.States.Empty_State_Set, A11y.States.Focused);
      Property_Reply := A11y.Windows_Backend.UIA_Properties.Query_Property
        (Password_Snapshot,
         A11y.Windows_Backend.UIA_Properties.Has_Keyboard_Focus);
      Check
        (Property_Reply.Kind =
           A11y.Windows_Backend.UIA_Properties.Error_Reply
         and then Property_Reply.Status = A11y.Results.Invalid_State,
         "Windows UIA property mapper rejects invalid state snapshots");
   end;

   Request_Item.Kind := Pattern_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Pattern_Set
      and then Routed.Patterns (A11y.Windows_Backend.UIA_Actions.Invoke)
      and then Routed.Patterns (A11y.Windows_Backend.UIA_Actions.Toggle)
      and then Routed.Patterns
        (A11y.Windows_Backend.UIA_Actions.Expand_Collapse)
      and then Routed.Patterns
        (A11y.Windows_Backend.UIA_Actions.Scroll_Item)
      and then Routed.Patterns (A11y.Windows_Backend.UIA_Actions.Window)
      and then Routed.Patterns (A11y.Windows_Backend.UIA_Actions.Value)
      and then Routed.Patterns (A11y.Windows_Backend.UIA_Actions.Range_Value)
      and then not Routed.Patterns
        (A11y.Windows_Backend.UIA_Actions.Selection_Item),
      "Windows UIA request router dispatches semantic and value pattern sets");

   Request_Item.Kind := Action_Map_Query;
   Request_Item.Action := A11y.Actions.Press;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Action_Mapping
      and then Routed.Mapping.Supported
      and then Routed.Mapping.Pattern =
        A11y.Windows_Backend.UIA_Actions.Invoke
      and then Routed.Mapping.Operation =
        A11y.Windows_Backend.UIA_Actions.Invoke_Invoke,
      "Windows UIA request router dispatches action mapping payloads");

   Request_Item.Kind := Action_Request_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Action_Request
      and then Routed.Requested_Action = A11y.Actions.Press,
      "Windows UIA request router stages action requests");

   Snapshots.Action_States (A11y.States.Enabled) := False;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Disabled,
      "Windows UIA request router applies action state preconditions");
   Snapshots.Action_States (A11y.States.Enabled) := True;

   Snapshots.Action_Use_Tree_Projection := True;
   Snapshots.Action_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA action routing rejects hidden action nodes");
   Request_Item.Kind := Pattern_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA pattern discovery rejects hidden action nodes");
   Snapshots.Action_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Action_Use_Tree_Projection := False;
   Request_Item.Kind := Action_Map_Query;

   declare
      Actions : A11y.Actions.Action_Set := Snapshots.Actions;
      Focus_Actions : A11y.Actions.Action_Set :=
        A11y.Actions.Empty_Action_Set;
      Patterns : A11y.Windows_Backend.UIA_Actions.UIA_Pattern_Set;
      Mapping : A11y.Windows_Backend.UIA_Actions.Action_Mapping;
      States : A11y.States.State_Set := A11y.States.Empty_State_Set;
   begin
      Actions (A11y.Actions.Expand) := True;
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Expand);
      Check
        (Mapping.Supported
         and then Mapping.Pattern =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse_Expand,
         "Windows UIA action mapper exposes expand through ExpandCollapse");

      Actions (A11y.Actions.Collapse) := True;
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Collapse);
      Check
        (Mapping.Supported
         and then Mapping.Pattern =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse_Collapse,
         "Windows UIA action mapper exposes collapse through ExpandCollapse");

      Actions (A11y.Actions.Show_Menu) := True;
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Show_Menu);
      Check
        (Mapping.Supported
         and then Mapping.Pattern =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse_Expand,
         "Windows UIA action mapper exposes show-menu through ExpandCollapse");

      Actions (A11y.Actions.Dismiss) := True;
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Dismiss);
      Check
        (Mapping.Supported
         and then Mapping.Pattern =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Expand_Collapse_Collapse,
         "Windows UIA action mapper exposes dismiss through ExpandCollapse");

      Actions (A11y.Actions.Set_Focus) := True;
      Focus_Actions (A11y.Actions.Set_Focus) := True;
      Patterns := A11y.Windows_Backend.UIA_Actions.Pattern_Set
        (Focus_Actions);
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Focus_Actions, A11y.Actions.Set_Focus);
      Check
        (Mapping.Supported
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Fragment_Set_Focus
         and then not Patterns (A11y.Windows_Backend.UIA_Actions.Invoke),
         "Windows UIA action mapper stages set-focus without advertising a pattern");

      Actions (A11y.Actions.Open) := True;
      Actions (A11y.Actions.Scroll_Into_View) := True;
      Actions (A11y.Actions.Close) := True;
      Patterns := A11y.Windows_Backend.UIA_Actions.Pattern_Set (Actions);
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Open);
      Check
        (Mapping.Supported
         and then Mapping.Pattern = A11y.Windows_Backend.UIA_Actions.Invoke
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Invoke_Invoke
         and then Patterns (A11y.Windows_Backend.UIA_Actions.Invoke),
         "Windows UIA action mapper exposes open through Invoke");

      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Scroll_Into_View);
      Check
        (Mapping.Supported
         and then Mapping.Pattern =
           A11y.Windows_Backend.UIA_Actions.Scroll_Item
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Scroll_Item_Scroll_Into_View
         and then Patterns (A11y.Windows_Backend.UIA_Actions.Scroll_Item),
         "Windows UIA action mapper exposes scroll-into-view through ScrollItem");

      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Close);
      Check
        (Mapping.Supported
         and then Mapping.Pattern =
           A11y.Windows_Backend.UIA_Actions.Window
         and then Mapping.Operation =
           A11y.Windows_Backend.UIA_Actions.Window_Close
         and then Patterns (A11y.Windows_Backend.UIA_Actions.Window),
         "Windows UIA action mapper exposes close through Window");

      States (A11y.States.Enabled) := False;
      Mapping := A11y.Windows_Backend.UIA_Actions.Map_Action
        (Actions, A11y.Actions.Show_Menu, States);
      Check
        (not Mapping.Supported
         and then Mapping.Status = A11y.Results.Disabled,
         "Windows UIA action mapper applies state preconditions");
   end;

   Request_Item.Kind := Fragment_Navigation_Query;
   Request_Item.Direction := A11y.Windows_Backend.UIA_Fragments.First_Child;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Fragment_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches fragment navigation queries with target identity");

   Request_Item.Kind := Fragment_Root_Focus_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Fragment_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches semantic fragment-root focus queries");

   Snapshots.Fragment.Focused_Node := A11y.Node_Ids.No_Node;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Fragment_Empty,
      "Windows UIA request router reports empty fragment-root focus without falling back to the root");
   Snapshots.Fragment.Focused_Node := Child;

   Request_Item.Kind := Fragment_Root_Point_Query;
   Snapshots.Fragment.Hit_Test_Point := (X => 25, Y => 35);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Fragment_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches semantic fragment-root point queries");

   Snapshots.Fragment.Hit_Test_Point := (X => 2_000, Y => 2_000);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Fragment_Empty,
      "Windows UIA request router reports empty fragment-root point queries outside semantic bounds");
   Snapshots.Fragment.Hit_Test_Point := (X => 25, Y => 35);

   Snapshots.Fragment.Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Fragment_Node
      and then Routed.Node = Root,
      "Windows UIA fragment-root point queries hide semantic child subtrees");
   Request_Item.Kind := Fragment_Root_Focus_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA fragment-root focus rejects hidden focused nodes");
   Snapshots.Fragment.Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Expose_Node;

   declare
      Deep_Fragment : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (624);
   begin
      A11y.Trees.Attach
        (Snapshots.Fragment.Tree, Child, Deep_Fragment, Result);
      Snapshots.Fragment.Node := Deep_Fragment;
      Request_Item.Direction := A11y.Windows_Backend.UIA_Fragments.Parent;
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "Windows UIA request router applies configured Fragment traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Snapshots.Fragment.Node := Root;
      Request_Item.Direction := A11y.Windows_Backend.UIA_Fragments.First_Child;
   end;

   declare
      Snapshot : A11y.Windows_Backend.UIA_Fragments.Fragment_Snapshot;
      Flattened : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (612);
      Button : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (613);
      Hidden : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (614);
      Hidden_Button : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (615);
      Trailing : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (616);
      Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Reply : A11y.Windows_Backend.UIA_Fragments.Fragment_Reply;
      Runtime_Reply : A11y.Windows_Backend.UIA_Fragments.Runtime_Id_Reply;
   begin
      Invalid_Limits.Limits
        (A11y.Resource_Limits.Native_Array_Size) := 0;

      Snapshot.Session := Session;
      Snapshot.Fragment_Root := Root;
      Snapshot.Node := Root;
      A11y.Trees.Set_Root (Snapshot.Tree, Root, Result);
      A11y.Trees.Attach (Snapshot.Tree, Root, Flattened, Result);
      A11y.Trees.Attach (Snapshot.Tree, Flattened, Button, Result);
      A11y.Trees.Attach (Snapshot.Tree, Root, Hidden, Result);
      A11y.Trees.Attach (Snapshot.Tree, Hidden, Hidden_Button, Result);
      A11y.Trees.Attach (Snapshot.Tree, Root, Trailing, Result);
      Snapshot.Exposure
        (A11y.Node_Ids.To_Natural (Flattened)) := A11y.Nodes.Flatten_Node;
      Snapshot.Exposure
        (A11y.Node_Ids.To_Natural (Hidden)) :=
           A11y.Nodes.Hide_Node_And_Subtree;

      Reply := A11y.Windows_Backend.UIA_Fragments.Navigate
        (Snapshot, A11y.Windows_Backend.UIA_Fragments.First_Child);
      Check
        (Reply.Found and then Reply.Node = Button,
         "Windows UIA fragment navigation flattens exposed children");

      Snapshot.Node := Button;
      Reply := A11y.Windows_Backend.UIA_Fragments.Navigate
        (Snapshot, A11y.Windows_Backend.UIA_Fragments.Parent);
      Check
        (Reply.Found and then Reply.Node = Root,
         "Windows UIA fragment navigation skips flattened parents");

      Reply := A11y.Windows_Backend.UIA_Fragments.Navigate
        (Snapshot, A11y.Windows_Backend.UIA_Fragments.Next_Sibling);
      Check
        (Reply.Found and then Reply.Node = Trailing,
         "Windows UIA fragment navigation omits hidden sibling subtrees");

      Snapshot.Node := Hidden_Button;
      Reply := A11y.Windows_Backend.UIA_Fragments.Navigate
        (Snapshot, A11y.Windows_Backend.UIA_Fragments.Parent);
      Check
        (not Reply.Found
         and then Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA fragment navigation rejects hidden native nodes");

      Snapshot.Defunct := True;
      Reply := A11y.Windows_Backend.UIA_Fragments.Navigate
        (Snapshot,
         A11y.Windows_Backend.UIA_Fragments.Parent,
         Invalid_Limits);
      Check
        (not Reply.Found
         and then Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA fragment mapper rejects invalid limit configs before navigation");

      Runtime_Reply := A11y.Windows_Backend.UIA_Fragments.Build_Runtime_Id
        (Snapshot, Invalid_Limits);
      Check
        (not Runtime_Reply.Available
         and then Runtime_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA fragment mapper rejects invalid limit configs before runtime ids");
   end;

   Request_Item.Kind := Runtime_Id_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   declare
      Root_Result : A11y.Results.Result;
      Node_Result : A11y.Results.Result;
      Root_Component : constant Natural :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Root, Root_Result);
      Node_Component : constant Natural :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Root, Node_Result);
   begin
      Check
        (A11y.Results.Succeeded (Root_Result)
         and then A11y.Results.Succeeded (Node_Result)
         and then Routed.Kind = Runtime_Id
         and then Routed.Id.Session_Component =
           A11y.Native_Identity.To_Natural (Session)
         and then Routed.Id.Root_Component = Root_Component
         and then Routed.Id.Node_Component = Node_Component,
         "Windows UIA request router dispatches runtime identifier queries with stable payload");
   end;

   Snapshots.Fragment.Node := Child;
   Snapshots.Fragment.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA runtime identifiers reject hidden native nodes");
   Snapshots.Fragment.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Expose_Node;
   Snapshots.Fragment.Node := Root;

   Request_Item.Kind := Relation_Query;
   Request_Item.Relation := A11y.Relations.Labelled_By;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Targets,
      "Windows UIA request router dispatches relation target queries");
   Check
     (Routed.Relation_Property =
        A11y.Windows_Backend.UIA_Mappings.Labeled_By,
      "Windows UIA relation target replies preserve the native relation property");

   Snapshots.Relation_Use_Tree_Projection := True;
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Empty,
      "Windows UIA relation routing filters hidden targets");
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA relation routing rejects hidden source nodes");
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Relation_Use_Tree_Projection := False;

   Request_Item.Relation := A11y.Relations.Error_Message;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Not_Supported
      and then Routed.Status = A11y.Results.Unsupported_Capability,
      "Windows UIA request router preserves unsupported relation mappings");

   Request_Item.Relation := A11y.Relations.Described_By;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Empty,
      "Windows UIA request router reports empty relation targets");

   A11y.Relations.Add
     (Snapshots.Relations,
      Root,
      A11y.Relations.Described_By,
      A11y.Node_Ids.From_Natural (612),
      Result);
   A11y.Relations.Add
     (Snapshots.Relations,
      Root,
      A11y.Relations.Described_By,
      A11y.Node_Ids.From_Natural (613),
      Result);
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits,
      A11y.Resource_Limits.Relation_Targets_Returned,
      1,
      Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router bounds relation target materialization");
   Snapshots.Limits.Limits
     (A11y.Resource_Limits.Relation_Targets_Returned) := 0;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Argument,
      "Windows UIA request router rejects invalid relation limits");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits,
      A11y.Resource_Limits.Relation_Targets_Returned,
      4_096,
      Result);

   Request_Item.Kind := Value_Query;
   Request_Item.Value := A11y.Windows_Backend.UIA_Values.Current_Value;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Float
      and then Routed.Float_Item = 5.0,
      "Windows UIA request router dispatches current value queries");

   Request_Item.Value := A11y.Windows_Backend.UIA_Values.Is_Read_Only;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Boolean
      and then not Routed.Boolean_Item,
      "Windows UIA request router dispatches read-only value queries");

   Request_Item.Kind := Value_Set_Query;
   Request_Item.Requested_Value := A11y.Values.Integer (7);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Set_Request
      and then A11y.Values.Equal
        (Routed.Requested_Value, A11y.Values.Integer (7)),
      "Windows UIA request router validates value set requests");

   Request_Item.Requested_Value := A11y.Values.Boolean (False);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Argument,
      "Windows UIA request router rejects nonnumeric value set requests");

   Request_Item.Requested_Value := A11y.Values.Integer (7);
   Snapshots.Value.Metadata.Mode := A11y.Values.Read_Only;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Read_Only,
      "Windows UIA request router rejects read-only value set requests");
   Snapshots.Value.Metadata.Mode := A11y.Values.Writable;

   Request_Item.Kind := Value_Query;
   Request_Item.Value := A11y.Windows_Backend.UIA_Values.Current_Value;
   Snapshots.Value.Metadata.Minimum := A11y.Values.Boolean (False);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Argument,
      "Windows UIA request router validates value metadata");
   Snapshots.Value.Metadata.Minimum := A11y.Values.Integer (0);

   Snapshots.Value.Metadata.Units :=
     Ada.Strings.Unbounded.To_Unbounded_String ("12345");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
   Request_Item.Value := A11y.Windows_Backend.UIA_Values.Current_Value;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router applies configured value text limits");
   Snapshots.Value.Metadata.Units :=
     Ada.Strings.Unbounded.To_Unbounded_String ("px");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Value := A11y.Windows_Backend.UIA_Values.Large_Increment;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Not_Supported
      and then Routed.Status = A11y.Results.Unsupported_Property,
      "Windows UIA request router preserves absent value metadata");

   Snapshots.Value.Use_Tree_Projection := True;
   Snapshots.Value.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Hide_Node_And_Subtree;
   Request_Item.Value := A11y.Windows_Backend.UIA_Values.Current_Value;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA value mapper rejects hidden value nodes");
   Request_Item.Kind := Value_Set_Query;
   Request_Item.Requested_Value := A11y.Values.Integer (6);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA value mapper rejects hidden value set requests");
   Snapshots.Value.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Expose_Node;
   Snapshots.Value.Use_Tree_Projection := False;

   declare
      Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Value_Snapshot : A11y.Windows_Backend.UIA_Values.Value_Snapshot :=
        Snapshots.Value;
      Value_Reply : A11y.Windows_Backend.UIA_Values.Value_Reply;
   begin
      Invalid_Limits.Limits (A11y.Resource_Limits.Text_Returned) := 0;
      Value_Snapshot.Defunct := True;

      Value_Reply := A11y.Windows_Backend.UIA_Values.Query_Value
        (Value_Snapshot,
         A11y.Windows_Backend.UIA_Values.Current_Value,
         Invalid_Limits);
      Check
        (Value_Reply.Kind = A11y.Windows_Backend.UIA_Values.Error_Reply
         and then Value_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA value mapper rejects invalid limit configs before value queries");

      Value_Reply := A11y.Windows_Backend.UIA_Values.Request_Value_Set
        (Value_Snapshot, A11y.Values.Integer (8), Invalid_Limits);
      Check
        (Value_Reply.Kind = A11y.Windows_Backend.UIA_Values.Error_Reply
         and then Value_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA value mapper rejects invalid limit configs before value set requests");
   end;

   Request_Item.Kind := Selection_Query;
   Request_Item.Selection := A11y.Windows_Backend.UIA_Selection.Selected_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_UInt32
      and then Routed.UInt32 = 1,
      "Windows UIA request router dispatches selected-count queries");

   Request_Item.Selection := A11y.Windows_Backend.UIA_Selection.Selected_Item;
   Request_Item.Index := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches selected-item queries");

   Request_Item.Selection :=
     A11y.Windows_Backend.UIA_Selection.Is_Item_Selected;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Boolean
      and then Routed.Boolean_Item,
      "Windows UIA request router dispatches selection membership queries");

   Request_Item.Selection := A11y.Windows_Backend.UIA_Selection.Anchor_Item;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches selection anchor queries");

   Request_Item.Selection :=
     A11y.Windows_Backend.UIA_Selection.Selection_Direction;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Direction
      and then Routed.Direction = A11y.Selection.No_Direction,
      "Windows UIA request router dispatches selection direction queries");

   declare
      Exposed : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (617);
      Hidden : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (618);
      Hidden_Item : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (619);
      Deep_Item : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (620);
      Selection_Reply : A11y.Windows_Backend.UIA_Selection.Selection_Reply;
      Range_Nodes : A11y.Selection.Node_Vectors.Vector;
   begin
      A11y.Selection.Configure
        (Snapshots.Selection.Selection, A11y.Selection.Extended);
      A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
      Range_Nodes.Append (Exposed);
      Range_Nodes.Append (Hidden_Item);
      A11y.Selection.Select_Range
        (Snapshots.Selection.Selection,
         Range_Nodes,
         Result,
         Direction => A11y.Selection.Backward);
      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Query_Selection
        (Snapshots.Selection,
         A11y.Windows_Backend.UIA_Selection.Selection_Direction);
      Check
        (Selection_Reply.Kind =
           A11y.Windows_Backend.UIA_Selection.Direction_Reply
         and then Selection_Reply.Direction = A11y.Selection.Backward,
         "Windows UIA selection routing exposes semantic range direction");

      Snapshots.Selection.Root := Root;
      Snapshots.Selection.Use_Tree_Projection := True;
      A11y.Trees.Set_Root (Snapshots.Selection.Tree, Root, Result);
      A11y.Trees.Attach (Snapshots.Selection.Tree, Root, Hidden, Result);
      A11y.Trees.Attach
        (Snapshots.Selection.Tree, Hidden, Hidden_Item, Result);
      A11y.Trees.Attach (Snapshots.Selection.Tree, Root, Exposed, Result);
      Snapshots.Selection.Exposure
        (A11y.Node_Ids.To_Natural (Hidden)) :=
           A11y.Nodes.Hide_Node_And_Subtree;
      A11y.Selection.Configure
        (Snapshots.Selection.Selection, A11y.Selection.Multiple);
      A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
      A11y.Selection.Select_Item
        (Snapshots.Selection.Selection, Hidden_Item, Result);
      A11y.Selection.Select_Item
        (Snapshots.Selection.Selection, Exposed, Result);
      A11y.Selection.Set_Current_Item
        (Snapshots.Selection.Selection, Hidden_Item, Result);
      Snapshots.Selection.Item := Hidden_Item;

      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Query_Selection
        (Snapshots.Selection, A11y.Windows_Backend.UIA_Selection.Selected_Count);
      Check
        (Selection_Reply.Kind = A11y.Windows_Backend.UIA_Selection.UInt32_Reply
         and then Selection_Reply.UInt32 = 1,
         "Windows UIA selection routing counts exposed selections");

      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_Array_Size) := 0;
         Selection_Reply :=
           A11y.Windows_Backend.UIA_Selection.Query_Selection
             (Snapshots.Selection,
              A11y.Windows_Backend.UIA_Selection.Selected_Count,
              Invalid_Limits);
         Check
           (Selection_Reply.Kind =
              A11y.Windows_Backend.UIA_Selection.Error_Reply
            and then Selection_Reply.Status = A11y.Results.Invalid_Argument,
            "Windows UIA selection mapper rejects invalid query limits");

         Selection_Reply :=
           A11y.Windows_Backend.UIA_Selection.Request_Selection
             (Snapshots.Selection,
              A11y.Windows_Backend.UIA_Selection.Select_All,
              A11y.Node_Ids.No_Node,
              Invalid_Limits);
         Check
           (Selection_Reply.Kind =
              A11y.Windows_Backend.UIA_Selection.Error_Reply
            and then Selection_Reply.Status = A11y.Results.Invalid_Argument,
            "Windows UIA selection mapper rejects invalid request limits");
      end;

      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Query_Selection
        (Snapshots.Selection,
         A11y.Windows_Backend.UIA_Selection.Selected_Item,
         1);
      Check
        (Selection_Reply.Kind = A11y.Windows_Backend.UIA_Selection.Node_Reply
         and then Selection_Reply.Node = Exposed,
         "Windows UIA selection routing returns exposed selections");

      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Query_Selection
        (Snapshots.Selection,
         A11y.Windows_Backend.UIA_Selection.Is_Item_Selected);
      Check
        (Selection_Reply.Kind =
           A11y.Windows_Backend.UIA_Selection.Boolean_Reply
         and then not Selection_Reply.Boolean_Item,
         "Windows UIA selection routing hides selected hidden items");

      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Query_Selection
        (Snapshots.Selection, A11y.Windows_Backend.UIA_Selection.Current_Item);
      Check
        (Selection_Reply.Kind = A11y.Windows_Backend.UIA_Selection.Empty_Reply,
         "Windows UIA selection routing omits hidden current items");

      Snapshots.Selection.Item := Exposed;
      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Query_Selection
        (Snapshots.Selection,
         A11y.Windows_Backend.UIA_Selection.Is_Item_Selected);
      Check
        (Selection_Reply.Kind =
           A11y.Windows_Backend.UIA_Selection.Boolean_Reply
         and then Selection_Reply.Boolean_Item,
         "Windows UIA selection routing keeps exposed selected items");

      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Request_Selection
        (Snapshots.Selection,
         A11y.Windows_Backend.UIA_Selection.Toggle_Item,
         Exposed);
      Check
        (Selection_Reply.Kind =
           A11y.Windows_Backend.UIA_Selection.Selection_Request_Reply
         and then Selection_Reply.Node = Exposed,
         "Windows UIA selection routing stages exposed selection requests");

      Selection_Reply := A11y.Windows_Backend.UIA_Selection.Request_Selection
        (Snapshots.Selection,
         A11y.Windows_Backend.UIA_Selection.Select_Item,
         Hidden_Item);
      Check
        (Selection_Reply.Kind = A11y.Windows_Backend.UIA_Selection.Error_Reply
         and then Selection_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA selection routing rejects hidden selection requests");

      A11y.Trees.Attach
        (Snapshots.Selection.Tree, Exposed, Deep_Item, Result);
      A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
      A11y.Selection.Select_Item
        (Snapshots.Selection.Selection, Deep_Item, Result);
      Request_Item.Kind := Selection_Query;
      Request_Item.Selection :=
        A11y.Windows_Backend.UIA_Selection.Selected_Item;
      Request_Item.Index := 1;
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Invalid_Argument,
         "Windows UIA request router applies configured Selection traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;

      Snapshots.Selection.Use_Tree_Projection := False;
      A11y.Selection.Configure
        (Snapshots.Selection.Selection, A11y.Selection.Multiple);
      A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
      A11y.Selection.Select_Item
        (Snapshots.Selection.Selection, Child, Result);
      A11y.Selection.Set_Current_Item
        (Snapshots.Selection.Selection, Child, Result);
      Snapshots.Selection.Item := Child;
   end;

   Request_Item.Kind := Selection_Request_Query;
   Request_Item.Selection_Request :=
     A11y.Windows_Backend.UIA_Selection.Toggle_Item;
   Request_Item.Selection_Target := Child;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Request_Reply
      and then Routed.Selection_Target = Child
      and then Routed.Selection_Request =
        A11y.Windows_Backend.UIA_Selection.Toggle_Item,
      "Windows UIA request router preserves selection request payloads");

   Request_Item.Selection_Request :=
     A11y.Windows_Backend.UIA_Selection.Select_All;
   Request_Item.Selection_Target := A11y.Node_Ids.No_Node;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Request_Reply
      and then Routed.Selection_Target = A11y.Node_Ids.No_Node
      and then Routed.Selection_Request =
        A11y.Windows_Backend.UIA_Selection.Select_All,
      "Windows UIA request router preserves select-all request payloads");

   A11y.Selection.Configure
     (Snapshots.Selection.Selection,
      A11y.Selection.Multiple);
   A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
   A11y.Selection.Configure
     (Snapshots.Selection.Selection,
      A11y.Selection.Multiple,
      Requires_Selection => True);
   Request_Item.Selection := A11y.Windows_Backend.UIA_Selection.Selected_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "Windows UIA request router rejects invalid selection snapshots");
   Request_Item.Kind := Selection_Request_Query;
   Request_Item.Selection_Request :=
     A11y.Windows_Backend.UIA_Selection.Clear_Selection;
   Request_Item.Selection_Target := A11y.Node_Ids.No_Node;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "Windows UIA request router rejects invalid selection requests");
   A11y.Selection.Configure
     (Snapshots.Selection.Selection, A11y.Selection.Multiple);
   A11y.Selection.Select_Item
     (Snapshots.Selection.Selection, Child, Result);
   A11y.Selection.Set_Current_Item
     (Snapshots.Selection.Selection, Child, Result);
   Request_Item.Kind := Selection_Query;

   Request_Item.Kind := Text_Query;
   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Character_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 3,
     "Windows UIA request router dispatches text character counts");

   declare
      Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Text_Snapshot : A11y.Windows_Backend.UIA_Text.Text_Snapshot :=
        Snapshots.Text;
      Text_Reply : A11y.Windows_Backend.UIA_Text.Text_Reply;
   begin
      Invalid_Limits.Limits (A11y.Resource_Limits.Text_Returned) := 0;
      Text_Snapshot.Defunct := True;

      Text_Reply := A11y.Windows_Backend.UIA_Text.Query_Text
        (Text_Snapshot,
         A11y.Windows_Backend.UIA_Text.Character_Count,
         Invalid_Limits);
      Check
        (Text_Reply.Kind = A11y.Windows_Backend.UIA_Text.Error_Reply
         and then Text_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA text mapper rejects invalid limit configs before text queries");

      Text_Reply := A11y.Windows_Backend.UIA_Text.Request_Text_Edit
        (Text_Snapshot,
         A11y.Text.Insert_Text,
         Invalid_Limits,
         Replacement => "x");
      Check
        (Text_Reply.Kind = A11y.Windows_Backend.UIA_Text.Error_Reply
         and then Text_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA text mapper rejects invalid limit configs before text edit requests");

      Text_Reply := A11y.Windows_Backend.UIA_Text.Request_Grapheme_Text_Edit
        (Text_Snapshot,
         A11y.Text.Insert_Text,
         Invalid_Limits,
         Replacement => "x");
      Check
        (Text_Reply.Kind = A11y.Windows_Backend.UIA_Text.Error_Reply
         and then Text_Reply.Status = A11y.Results.Invalid_Argument,
         "Windows UIA text mapper rejects invalid limit configs before grapheme text edits");
   end;

   Snapshots.Text.Content :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
       (Wide_Wide_String'("Ae")
        & Wide_Wide_Character'Val (16#0301#)
        & Wide_Wide_String'("B"));
   Request_Item.Text :=
     A11y.Windows_Backend.UIA_Text.Grapheme_Cluster_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 3,
      "Windows UIA request router dispatches grapheme cluster counts");
   Request_Item.Text :=
     A11y.Windows_Backend.UIA_Text.Grapheme_Text_Range;
   Request_Item.Index := 2;
   Request_Item.Count := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Wide_Text
      and then
        Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
          (Routed.Wide_Text)
          = Wide_Wide_String'("e") & Wide_Wide_Character'Val (16#0301#),
      "Windows UIA request router dispatches grapheme text ranges");
   declare
      Text_Reply : constant A11y.Windows_Backend.UIA_Text.Text_Reply :=
        A11y.Windows_Backend.UIA_Text.Request_Grapheme_Text_Edit
          (Snapshots.Text,
           A11y.Text.Delete_Text,
           Start => 1,
           Count => 1,
           Replacement => "");
   begin
      Check
        (Text_Reply.Kind =
           A11y.Windows_Backend.UIA_Text.Edit_Request_Reply
         and then Text_Reply.Requested_Edit.Kind = A11y.Text.Delete_Text
         and then A11y.Text.Index
           (A11y.Text.First (Text_Reply.Requested_Edit.Span)) = 1
         and then A11y.Text.Length (Text_Reply.Requested_Edit.Span) = 2,
         "Windows UIA text layer validates grapheme-indexed edit requests");
   end;
   Snapshots.Text.Content :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
       (Wide_Wide_String'("A")
        & Wide_Wide_Character'Val (16#1F600#)
        & Wide_Wide_String'("B"));

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Text_Range;
   Request_Item.Index := 2;
   Request_Item.Count := 2;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Wide_Text
      and then
        Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
          (Routed.Wide_Text)
          = Wide_Wide_Character'Val (16#1F600#) & Wide_Wide_String'("B"),
      "Windows UIA request router dispatches neutral text range payloads");

   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 1, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router applies configured text range limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.UTF16_Unit_Count;
   Request_Item.Index := 2;
   Request_Item.Count := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 2,
      "Windows UIA request router dispatches UTF-16 unit counts");

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Caret_Offset;
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (3);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 3,
      "Windows UIA request router dispatches caret offsets at text end");
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (4);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Range,
      "Windows UIA request router rejects caret offsets outside content");
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (2);

   Snapshots.Text.Policy := A11y.Text.Protected_Text;
   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Text_Range;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected text ranges");

   Request_Item.Index := Natural'Last;
   Request_Item.Count := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected text ranges before offset validation");

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.UTF16_Unit_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected UTF-16 offset conversion");

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Character_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected text character counts");

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Grapheme_Cluster_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected grapheme cluster counts");

   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Caret_Offset;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected caret offsets");

   Snapshots.Text.Policy := A11y.Text.Plain_Text;
   Request_Item.Index := 1;
   Request_Item.Count := 0;

   Request_Item.Kind := Text_Edit_Query;
   Request_Item.Text_Edit := A11y.Text.Insert_Text;
   Request_Item.Index := 2;
   Request_Item.Count := 0;
   Request_Item.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("X");
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Edit_Request
      and then Routed.Requested_Edit.Kind = A11y.Text.Insert_Text
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Routed.Requested_Edit.Text) = Wide_Wide_String'("X"),
      "Windows UIA request router dispatches text edit requests");

   Request_Item.Text_Edit := A11y.Text.Replace_Text;
   Request_Item.Index := 2;
   Request_Item.Count := 2;
   Request_Item.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("YZ");
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Edit_Request
      and then Routed.Requested_Edit.Kind = A11y.Text.Replace_Text
      and then A11y.Text.Index
        (A11y.Text.First (Routed.Requested_Edit.Span)) = 1
      and then A11y.Text.Length (Routed.Requested_Edit.Span) = 2
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Routed.Requested_Edit.Text) = Wide_Wide_String'("YZ"),
      "Windows UIA request router dispatches replace text requests");

   Request_Item.Text_Edit := A11y.Text.Set_Text;
   Request_Item.Index := 1;
   Request_Item.Count := 0;
   Request_Item.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("Reset");
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Edit_Request
      and then Routed.Requested_Edit.Kind = A11y.Text.Set_Text
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Routed.Requested_Edit.Text) = Wide_Wide_String'("Reset"),
      "Windows UIA request router dispatches set text requests");

   Snapshots.Text.Policy := A11y.Text.Protected_Text;
   Request_Item.Text_Edit := A11y.Text.Insert_Text;
   Request_Item.Index := 2;
   Request_Item.Count := 0;
   Request_Item.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("X");
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "Windows UIA request router blocks protected text edits");
   Snapshots.Text.Policy := A11y.Text.Plain_Text;

   Snapshots.Text.Read_Only := True;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Read_Only,
      "Windows UIA request router blocks read-only text edits");
   Snapshots.Text.Read_Only := False;

   Snapshots.Text.Use_Tree_Projection := True;
   Snapshots.Text.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA text mapper rejects hidden text edit nodes");
   Request_Item.Kind := Text_Query;
   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Character_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA text mapper rejects hidden text nodes");
   Snapshots.Text.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Expose_Node;
   Snapshots.Text.Use_Tree_Projection := False;

   Request_Item.Kind := Text_Query;
   Request_Item.Text := A11y.Windows_Backend.UIA_Text.Character_Count;
   Request_Item.Index := 1;
   Request_Item.Count := 0;
   Request_Item.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String;

   Request_Item.Kind := Table_Query;
   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Row_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 4,
      "Windows UIA request router dispatches table row counts");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Displayed_Row_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 3,
      "Windows UIA request router dispatches displayed table row counts");

   Request_Item.Table :=
     A11y.Windows_Backend.UIA_Table.Displayed_Column_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 4,
      "Windows UIA request router dispatches displayed table column counts");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Visible_Row_Start;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 1,
      "Windows UIA request router dispatches visible table row starts");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Visible_Row_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 2,
      "Windows UIA request router dispatches visible table row counts");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Visible_Column_Start;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 1,
      "Windows UIA request router dispatches visible table column starts");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Visible_Column_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 2,
      "Windows UIA request router dispatches visible table column counts");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Current_Cell;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches current table cells");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Sort_Order;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = A11y.Tables.Sort_Order'Pos
        (A11y.Tables.Ascending),
      "Windows UIA request router dispatches table sort order");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Sort_Key;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches table sort keys");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Cell_At;
   Request_Item.Row := 1;
   Request_Item.Column := 2;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_Node
      and then Routed.Node = Child,
      "Windows UIA request router dispatches table cell lookups");

   Request_Item.Table := A11y.Windows_Backend.UIA_Table.Column_Span;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 3,
      "Windows UIA request router dispatches table span lookups");

   Request_Item.Row := 99;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Range,
      "Windows UIA request router rejects invalid table coordinates");
   Request_Item.Row := 0;
   Request_Item.Column := 0;

   declare
      Deep_Cell : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (621);
      Direct_Reply : A11y.Windows_Backend.UIA_Table.Table_Reply;
   begin
      Snapshots.Table.Use_Tree_Projection := True;
      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Reply := A11y.Windows_Backend.UIA_Table.Query_Table
        (Snapshots.Table, A11y.Windows_Backend.UIA_Table.Current_Cell);
      Check
        (Direct_Reply.Kind = A11y.Windows_Backend.UIA_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA table mapper hides projected current cells");

      Direct_Reply := A11y.Windows_Backend.UIA_Table.Query_Table
        (Snapshots.Table, A11y.Windows_Backend.UIA_Table.Sort_Key);
      Check
        (Direct_Reply.Kind = A11y.Windows_Backend.UIA_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA table mapper hides projected sort keys");

      Direct_Reply := A11y.Windows_Backend.UIA_Table.Query_Table
        (Snapshots.Table, A11y.Windows_Backend.UIA_Table.Cell_At, 1, 2);
      Check
        (Direct_Reply.Kind = A11y.Windows_Backend.UIA_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA table mapper hides projected cells");

      Direct_Reply := A11y.Windows_Backend.UIA_Table.Query_Table
        (Snapshots.Table, A11y.Windows_Backend.UIA_Table.Row_Span, 1, 2);
      Check
        (Direct_Reply.Kind = A11y.Windows_Backend.UIA_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA table mapper hides projected cell spans");

      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Root)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Reply := A11y.Windows_Backend.UIA_Table.Query_Table
        (Snapshots.Table, A11y.Windows_Backend.UIA_Table.Row_Count);
      Check
        (Direct_Reply.Kind = A11y.Windows_Backend.UIA_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA table mapper rejects hidden table nodes");

      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Root)) :=
          A11y.Nodes.Expose_Node;
      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_Array_Size) := 0;
         Direct_Reply := A11y.Windows_Backend.UIA_Table.Query_Table
           (Snapshots.Table,
            A11y.Windows_Backend.UIA_Table.Row_Count,
            Invalid_Limits);
         Check
           (Direct_Reply.Kind = A11y.Windows_Backend.UIA_Table.Error_Reply
            and then Direct_Reply.Status = A11y.Results.Invalid_Argument,
            "Windows UIA table mapper rejects invalid limit configs");
      end;
      A11y.Tables.Add_Cell
        (Snapshots.Table.Table,
         Deep_Cell,
         Row => 2,
         Column => 3,
         Row_Span => 1,
         Column_Span => 1,
         Result => Result);
      A11y.Trees.Attach (Snapshots.Table.Tree, Child, Deep_Cell, Result);
      Request_Item.Kind := Table_Query;
      Request_Item.Table := A11y.Windows_Backend.UIA_Table.Cell_At;
      Request_Item.Row := 2;
      Request_Item.Column := 3;
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "Windows UIA request router applies configured Table traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Request_Item.Row := 0;
      Request_Item.Column := 0;
      Snapshots.Table.Use_Tree_Projection := False;
   end;

   Request_Item.Kind := Image_Query;
   Request_Item.Image := A11y.Windows_Backend.UIA_Image.Description;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "Revenue chart",
      "Windows UIA request router dispatches image descriptions");

   Snapshots.Image.Metadata.Alternative_Text :=
     Ada.Strings.Unbounded.To_Unbounded_String
       (String'
          (1 .. Natural
            (A11y.Resource_Limits.Value
               (A11y.Resource_Limits.Default_Config,
                A11y.Resource_Limits.Text_Returned)) + 1 => 'x'));
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router bounds image description text");

   Snapshots.Image.Metadata.Alternative_Text :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Revenue chart");

   Request_Item.Image := A11y.Windows_Backend.UIA_Image.Caption;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Q1 revenue",
      "Windows UIA request router dispatches image captions");

   Snapshots.Image.Metadata.Kind := A11y.Images.Chart;
   Request_Item.Image := A11y.Windows_Backend.UIA_Image.Kind_Name;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "chart",
      "Windows UIA request router dispatches image categories");
   Snapshots.Image.Metadata.Kind := A11y.Images.Informative;
   Request_Item.Image := A11y.Windows_Backend.UIA_Image.Description;

   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router applies configured image text limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Image := A11y.Windows_Backend.UIA_Image.Intrinsic_Size;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_Size
      and then Routed.Size.Width = 640
      and then Routed.Size.Height = 480,
      "Windows UIA request router dispatches image sizes");

   declare
      Direct_Image : A11y.Windows_Backend.UIA_Image.Image_Reply;
   begin
      Snapshots.Image.Use_Tree_Projection := True;
      Snapshots.Image.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Image := A11y.Windows_Backend.UIA_Image.Query_Image
        (Snapshots.Image, A11y.Windows_Backend.UIA_Image.Description);
      Check
        (Direct_Image.Kind = A11y.Windows_Backend.UIA_Image.Error_Reply
         and then Direct_Image.Status = A11y.Results.Node_Unavailable,
         "Windows UIA image mapper rejects hidden image nodes");

      Snapshots.Image.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      Snapshots.Image.Use_Tree_Projection := False;

      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
         Direct_Image := A11y.Windows_Backend.UIA_Image.Query_Image
           (Snapshots.Image,
            A11y.Windows_Backend.UIA_Image.Intrinsic_Size,
            Invalid_Limits);
         Check
           (Direct_Image.Kind = A11y.Windows_Backend.UIA_Image.Error_Reply
            and then Direct_Image.Status = A11y.Results.Invalid_Argument,
            "Windows UIA image mapper rejects invalid limit configs");
      end;
   end;

   Snapshots.Image.Metadata.Kind := A11y.Images.Decorative;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA request router omits decorative images");
   Snapshots.Image.Metadata.Kind := A11y.Images.Informative;

   Request_Item.Kind := Document_Query;
   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Role;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "heading",
      "Windows UIA request router dispatches document role metadata");

   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Locale;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "en-US",
      "Windows UIA request router dispatches document locale metadata");

   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Author;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Ada Team",
      "Windows UIA request router dispatches document author metadata");

   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Current_Page;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_UInt32
      and then Routed.UInt32 = 4,
      "Windows UIA request router dispatches document current pages");

   Snapshots.Document.Metadata.Title :=
     Ada.Strings.Unbounded.To_Unbounded_String
       (String'
          (1 .. Natural
            (A11y.Resource_Limits.Value
               (A11y.Resource_Limits.Default_Config,
                A11y.Resource_Limits.Text_Returned)) + 1 => 'x'));
   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Title;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router bounds document metadata text");

   Snapshots.Document.Metadata.Title :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Overview");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router applies configured document text limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Heading_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_UInt32
      and then Routed.UInt32 = 2,
      "Windows UIA request router dispatches document heading levels");

   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Is_Landmark;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_Boolean
      and then Routed.Boolean_Item,
      "Windows UIA request router dispatches document landmark state");

   declare
      Direct_Document : A11y.Windows_Backend.UIA_Document.Document_Reply;
   begin
      Snapshots.Document.Use_Tree_Projection := True;
      Snapshots.Document.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Document := A11y.Windows_Backend.UIA_Document.Query_Document
        (Snapshots.Document, A11y.Windows_Backend.UIA_Document.Locale);
      Check
        (Direct_Document.Kind =
           A11y.Windows_Backend.UIA_Document.Error_Reply
         and then Direct_Document.Status = A11y.Results.Node_Unavailable,
         "Windows UIA document mapper rejects hidden document nodes");

      Snapshots.Document.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      Snapshots.Document.Use_Tree_Projection := False;

      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
         Direct_Document := A11y.Windows_Backend.UIA_Document.Query_Document
           (Snapshots.Document,
            A11y.Windows_Backend.UIA_Document.Is_Landmark,
            Invalid_Limits);
         Check
           (Direct_Document.Kind =
              A11y.Windows_Backend.UIA_Document.Error_Reply
            and then Direct_Document.Status = A11y.Results.Invalid_Argument,
            "Windows UIA document mapper rejects invalid limit configs");
      end;
   end;

   Snapshots.Document.Metadata.Heading_Level := 99;
   Request_Item.Document := A11y.Windows_Backend.UIA_Document.Heading_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Range,
      "Windows UIA request router validates document heading levels");
   Snapshots.Document.Metadata.Heading_Level := 2;

   Request_Item.Kind := Live_Region_Query;
   Request_Item.Live_Region :=
     A11y.Windows_Backend.UIA_Live_Regions.Relevant_Names;
   Snapshots.Live_Region.Metadata.Setting := A11y.Live_Regions.Polite;
   Snapshots.Live_Region.Metadata.Atomic := True;
   Snapshots.Live_Region.Metadata.Relevant :=
     A11y.Live_Regions.With_Change
       (A11y.Live_Regions.Empty_Relevant_Change_Set,
        A11y.Live_Regions.Text);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Live_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "text",
      "Windows UIA request router dispatches live-region relevance queries");

   Request_Item.Live_Region :=
     A11y.Windows_Backend.UIA_Live_Regions.Is_Atomic;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Live_Boolean
      and then Routed.Boolean_Item,
      "Windows UIA request router dispatches live-region boolean queries");

   Request_Item.Kind := Surface_Query;
   Request_Item.Surface := A11y.Windows_Backend.UIA_Surfaces.Kind_Name;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Surface_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "modal-dialog",
      "Windows UIA request router dispatches surface kind metadata");

   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Native_String_Size, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "Windows UIA request router applies configured surface string limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Modal;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Surface_Boolean
      and then Routed.Boolean_Item,
      "Windows UIA request router dispatches surface modality");

   Request_Item.Surface := A11y.Windows_Backend.UIA_Surfaces.Can_Resize;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Surface_Boolean
      and then not Routed.Boolean_Item,
      "Windows UIA request router dispatches surface operation capabilities");

   declare
      Deep_Surface : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (622);
      Direct_Surface : A11y.Windows_Backend.UIA_Surfaces.Surface_Reply;
   begin
      Snapshots.Surface.Use_Tree_Projection := True;
      Snapshots.Surface.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Surface := A11y.Windows_Backend.UIA_Surfaces.Query_Surface
        (Snapshots.Surface, A11y.Windows_Backend.UIA_Surfaces.Kind_Name);
      Check
        (Direct_Surface.Kind =
           A11y.Windows_Backend.UIA_Surfaces.Error_Reply
         and then Direct_Surface.Status = A11y.Results.Node_Unavailable,
         "Windows UIA surface mapper rejects hidden surface nodes");

      Snapshots.Surface.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits
           (A11y.Resource_Limits.Native_String_Size) := 0;
         Direct_Surface := A11y.Windows_Backend.UIA_Surfaces.Query_Surface
           (Snapshots.Surface,
            A11y.Windows_Backend.UIA_Surfaces.Is_Modal,
            Invalid_Limits);
         Check
           (Direct_Surface.Kind =
              A11y.Windows_Backend.UIA_Surfaces.Error_Reply
            and then Direct_Surface.Status = A11y.Results.Invalid_Argument,
            "Windows UIA surface mapper rejects invalid limit configs");
      end;

      Snapshots.Surface.Id := Deep_Surface;
      A11y.Trees.Attach (Snapshots.Surface.Tree, Child, Deep_Surface, Result);
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Request_Item.Kind := Surface_Query;
      Request_Item.Surface := A11y.Windows_Backend.UIA_Surfaces.Kind_Name;
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "Windows UIA request router applies configured Surface traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Snapshots.Surface.Id := Child;
      Snapshots.Surface.Use_Tree_Projection := False;
   end;

   Snapshots.Surface.Metadata.State.Visible := False;
   Request_Item.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Active;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "Windows UIA request router validates surface state");
   Snapshots.Surface.Metadata.State.Visible := True;
   Snapshots.Surface.Metadata.State.Minimized := True;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "Windows UIA request router rejects active minimized surfaces");
   Snapshots.Surface.Metadata.State.Minimized := False;

   Request_Item.Kind := Event_Emission_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Event_Emission
      and then Routed.Native_Object = A11y.Native_Object_Caches.No_Object,
      "Windows UIA request router dispatches event emission queries");

   declare
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Prepared_Event : constant A11y.Events.Event :=
        (Sequence  => 7,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 6);
      Destroy_Event : constant A11y.Events.Event :=
        (Sequence  => 8,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Node_Destroyed,
         Revision  => 7);
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result : A11y.Results.Result;
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Prepared_Event, Prepared, Result);
      Request_Item.Use_Prepared_Event := True;
      Request_Item.Prepared_Event := Prepared;
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Routed.Kind = Event_Emission
         and then Routed.Native_Object = Prepared.Object,
         "Windows UIA request router dispatches prepared event emissions");

      Request_Item.Prepared_Event :=
        (Status        => A11y.Results.Success,
         Event         => Prepared_Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "Windows UIA request router rejects unbacked prepared event emissions");

      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Destroy_Event, Prepared, Result);
      Request_Item.Prepared_Event := Prepared;
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Routed.Kind = Event_Emission
         and then Routed.Native_Object = A11y.Native_Object_Caches.No_Object,
         "Windows UIA request router posts prepared destruction events without native objects");

      Request_Item.Use_Prepared_Event := False;
   end;

   Snapshots.Event_Use_Tree_Projection := True;
   Snapshots.Event_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "Windows UIA event routing rejects hidden source nodes");
   Snapshots.Event_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Event_Use_Tree_Projection := False;

   Emission := A11y.Windows_Backend.UIA_Events.Build_Event
     ((Sequence  => 12,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Value_Changed,
       Revision  => 5));
   Check
     (Emission.Publishable
      and then Emission.Kind =
        A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
      and then Emission.Property =
        A11y.Windows_Backend.UIA_Events.Value_Property
      and then Emission.Structure =
        A11y.Windows_Backend.UIA_Events.No_Structure_Event
      and then Emission.Window =
        A11y.Windows_Backend.UIA_Events.No_Window_Event,
      "Windows UIA event mapper annotates value property notifications");

   declare
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Report : A11y.Windows_Backend.UIA_Events.Event_Build_Report;
      Prepared_Event : constant A11y.Events.Event :=
        (Sequence  => 13,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 6);
      Invalid_Prepared_Event : constant A11y.Events.Event :=
        (Sequence  => A11y.No_Event,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 6);
      Property_Event : constant A11y.Events.Event :=
        (Sequence  => 14,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Property_Changed,
         Revision  => 7);
      Property_Payload : constant A11y.Events.Property_Event_Payload :=
        (Property   => A11y.Properties.Accessible_Name,
         Value_Kind => A11y.Properties.String_Value,
         Old_Status => A11y.Properties.Present,
         New_Status => A11y.Properties.Present);
      State_Event : constant A11y.Events.Event :=
        (Sequence  => 15,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.State_Changed,
         Revision  => 8);
      State_Payload : constant A11y.Events.State_Event_Payload :=
        (State     => A11y.States.Focused,
         Source    => A11y.States.Application_Provided,
         Old_Value => False,
         New_Value => True);
      Bounds_Event : constant A11y.Events.Event :=
        (Sequence  => 16,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Bounds_Changed,
         Revision  => 9);
      Bounds_Payload : constant A11y.Events.Bounds_Event_Payload :=
        (Old_Bounds => A11y.Geometry.Empty_Rectangle,
         New_Bounds =>
           ((X => 10, Y => 20),
            (Width => 30, Height => 40)));
      Value_Event : constant A11y.Events.Event :=
        (Sequence  => 17,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Value_Changed,
         Revision  => 10);
      Value_Payload : constant A11y.Events.Value_Event_Payload :=
        (Old_Value => A11y.Values.Integer (1),
         New_Value => A11y.Values.Exact_Decimal (125, 2),
         Old_Kind  => A11y.Values.Integer_Value,
         New_Kind  => A11y.Values.Decimal_Value);
      Selection_Event : constant A11y.Events.Event :=
        (Sequence  => 18,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Selection_Changed,
         Revision  => 11);
      Selection_Payload : constant A11y.Events.Selection_Event_Payload :=
        (Changed_Node       => Root,
         Has_Changed_Node   => True,
         Old_Selected       => False,
         New_Selected       => True,
         Requires_Selection => True);
      Node_Reference_Event : constant A11y.Events.Event :=
        (Sequence  => 19,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Active_Descendant_Changed,
         Revision  => 12);
      Node_Reference_Payload :
        constant A11y.Events.Node_Reference_Event_Payload :=
          (Old_Node => Root,
           New_Node => Child);
      Focus_Payload : constant A11y.Events.Focus_Event_Payload :=
        (Old_Focus => Root,
         New_Focus => Child);
      Focus_Event : constant A11y.Events.Event :=
        (Sequence  => 20,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 13);
      Relation_Event : constant A11y.Events.Event :=
        (Sequence  => 21,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Relation_Added,
         Revision  => 14);
      Relation_Payload : constant A11y.Events.Relation_Event_Payload :=
        (Relation   => A11y.Relations.Labelled_By,
         Inverse    => A11y.Relations.Label_For,
         Target     => Root,
         Has_Target => True);
      Live_Region_Event : constant A11y.Events.Event :=
        (Sequence  => 22,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Announcement_Requested,
         Revision  => 15);
      Live_Region_Metadata : constant
        A11y.Live_Regions.Live_Region_Metadata :=
          (Setting  => A11y.Live_Regions.Polite,
           Atomic   => True,
           Relevant =>
             A11y.Live_Regions.With_Change
               (A11y.Live_Regions.Empty_Relevant_Change_Set,
                A11y.Live_Regions.Text));
      Live_Region_Payload : constant
        A11y.Events.Live_Region_Event_Payload :=
          (Metadata         => Live_Region_Metadata,
           Announcement     =>
             (Text => Ada.Strings.Unbounded.To_Unbounded_String ("ready")),
           Has_Announcement => True);
      Tree_Event : constant A11y.Events.Event :=
        (Sequence  => 23,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Child_Added,
         Revision  => 16);
      Tree_Payload : constant A11y.Events.Tree_Event_Payload :=
        (Parent    => Child,
         Child     => Root,
         Has_Child => True,
         Index     => 2,
         Has_Index => True);
      Table_Event : constant A11y.Events.Event :=
        (Sequence  => 24,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Row_Inserted,
         Revision  => 17);
      Table_Payload : constant A11y.Events.Table_Event_Payload :=
        (Table      => Child,
         Item       => A11y.Node_Ids.No_Node,
         Has_Item   => False,
         Row        => 4,
         Has_Row    => True,
         Column     => 0,
         Has_Column => False);
      Document_Event : constant A11y.Events.Event :=
        (Sequence  => 25,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Document_Loaded,
         Revision  => 18);
      Document_Payload : constant A11y.Events.Document_Event_Payload :=
        (Document    => Child,
         Surface     => Root,
         Has_Surface => True);
      Window_Event : constant A11y.Events.Event :=
        (Sequence  => 26,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Window_Opened,
         Revision  => 19);
      Window_Payload : constant A11y.Events.Window_Event_Payload :=
        (Surface   => Child,
         Kind      => A11y.Windows.Modal_Dialog,
         Owner     => Root,
         Has_Owner => True);
      Destroy_Event : constant A11y.Events.Event :=
        (Sequence  => 27,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Node_Destroyed,
         Revision  => 20);
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA prepared-event fixture starts native runtime");

      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Prepared_Event, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Emission.Publishable
         and then Emission.Source = Child
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Focus_Changed,
         "Windows UIA event mapper accepts prepared native publications");
      Check
        (Report.Source = Child
         and then Report.Sequence = Prepared_Event.Sequence
         and then Report.Revision = Prepared_Event.Revision
         and then Report.Envelope_Valid
         and then Report.Prepared_Input
         and then Report.Prepared_Has_Object
         and then not Report.Prepared_Destroys_Node
         and then Report.Native_Object_Resolved
         and then Report.Publishable
         and then Report.Status = A11y.Results.Success,
         "Windows UIA event mapper reports prepared native publication builds");
      Check
        (A11y.Results.Succeeded
           (A11y.Windows_Backend.UIA_Events.Validate_For_Posting
              (Emission)),
         "Windows UIA event mapper validates prepared native publications for posting");

      A11y.Native_Runtimes.Prepare_Property_Event
        (Runtime, Property_Event, Property_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Property_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Name_Property,
         "Windows UIA prepared property events preserve property payload identities");

      A11y.Native_Runtimes.Prepare_State_Event
        (Runtime, State_Event, State_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_State_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Has_Keyboard_Focus_Property,
         "Windows UIA prepared state events preserve state payload identities");

      A11y.Native_Runtimes.Prepare_Bounds_Event
        (Runtime, Bounds_Event, Bounds_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Bounds_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Bounding_Rectangle_Property
         and then Emission.Has_Bounds_Payload
         and then Emission.Old_Bounds = A11y.Geometry.Empty_Rectangle
         and then Emission.New_Bounds.Origin.X = 10
         and then Emission.New_Bounds.Extent.Height = 40,
         "Windows UIA prepared bounds events preserve bounds payload rectangles");

      A11y.Native_Runtimes.Prepare_Value_Event
        (Runtime, Value_Event, Value_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Value_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Value_Property
         and then Emission.Has_Value_Payload
         and then Emission.Old_Value.Kind = A11y.Values.Integer_Value
         and then Emission.New_Value.Kind = A11y.Values.Decimal_Value
         and then Emission.New_Value.Decimal_Item.Units = 125,
         "Windows UIA prepared value events preserve value payload identities");

      A11y.Native_Runtimes.Prepare_Selection_Event
        (Runtime, Selection_Event, Selection_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Selection_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Selection_Invalidated
         and then Emission.Has_Selection_Payload
         and then Emission.Selection_Node = Root
         and then Emission.Selection_Has_Node
         and then not Emission.Selection_Old_Selected
         and then Emission.Selection_New_Selected
         and then Emission.Selection_Required,
         "Windows UIA prepared selection events preserve selection payload identities");

      A11y.Native_Runtimes.Prepare_Node_Reference_Event
        (Runtime, Node_Reference_Event, Node_Reference_Payload,
         Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Node_Reference_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Active_Descendant_Property
         and then Emission.Has_Node_Reference_Payload
         and then Emission.Old_Reference = Root
         and then Emission.New_Reference = Child,
         "Windows UIA prepared node-reference events preserve node-reference payload identities");

      A11y.Native_Runtimes.Prepare_Focus_Event
        (Runtime, Focus_Event, Focus_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Focus_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Focus_Changed
         and then Emission.Has_Focus_Payload
         and then Emission.Old_Focus = Root
         and then Emission.New_Focus = Child,
         "Windows UIA prepared focus events preserve focus payload identities");

      A11y.Native_Runtimes.Prepare_Relation_Event
        (Runtime, Relation_Event, Relation_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Relation_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Property_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Relation_Property
         and then Emission.Relation =
           A11y.Windows_Backend.UIA_Mappings.Labeled_By,
         "Windows UIA prepared relation events preserve native relation properties");
      Check
        (Report.Prepared_Input
         and then Report.Prepared_Has_Object
         and then Report.Native_Object_Resolved
         and then Report.Publishable
         and then Report.Status = A11y.Results.Success,
         "Windows UIA event mapper reports prepared relation publications");

      A11y.Native_Runtimes.Prepare_Live_Region_Event
        (Runtime, Live_Region_Event, Live_Region_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Live_Region_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Notification
         and then Emission.Has_Live_Region_Payload
         and then Emission.Live_Region_Payload.Metadata.Setting =
           A11y.Live_Regions.Polite
         and then Emission.Live_Region_Payload.Metadata.Atomic
         and then Emission.Live_Region_Payload.Has_Announcement
         and then Ada.Strings.Unbounded.To_String
           (Emission.Live_Region_Payload.Announcement.Text) = "ready",
         "Windows UIA prepared live-region events preserve live-region payload identities");

      A11y.Native_Runtimes.Prepare_Tree_Event
        (Runtime, Tree_Event, Tree_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Tree_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Structure_Changed
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Child_Added_Event
         and then Emission.Has_Tree_Payload
         and then Emission.Tree_Payload.Parent = Child
         and then Emission.Tree_Payload.Child = Root
         and then Emission.Tree_Payload.Index = 2,
         "Windows UIA prepared tree events preserve tree payload identities");

      A11y.Native_Runtimes.Prepare_Table_Event
        (Runtime, Table_Event, Table_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Table_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Structure_Changed
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Row_Inserted_Event
         and then Emission.Has_Table_Payload
         and then Emission.Table_Payload.Table = Child
         and then not Emission.Table_Payload.Has_Item
         and then Emission.Table_Payload.Row = 4,
         "Windows UIA prepared table events preserve table payload identities");

      A11y.Native_Runtimes.Prepare_Document_Event
        (Runtime, Document_Event, Document_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Document_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Structure_Changed
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Document_Loaded_Event
         and then Emission.Has_Document_Payload
         and then Emission.Document_Payload.Document = Child
         and then Emission.Document_Payload.Surface = Root
         and then Emission.Document_Payload.Has_Surface,
         "Windows UIA prepared document events preserve document payload identities");

      A11y.Native_Runtimes.Prepare_Window_Event
        (Runtime, Window_Event, Window_Payload, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Window_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Window_Opened
         and then Emission.Window =
           A11y.Windows_Backend.UIA_Events.Window_Opened_Event
         and then Emission.Has_Window_Payload
         and then Emission.Window_Payload.Surface = Child
         and then Emission.Window_Payload.Kind = A11y.Windows.Modal_Dialog
         and then Emission.Window_Payload.Owner = Root
         and then Emission.Window_Payload.Has_Owner,
         "Windows UIA prepared window events preserve window payload identities");

      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Prepared_Event,
         Object        => <>,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Node_Unavailable,
         "Windows UIA event mapper rejects unbacked prepared publications");
      Check
        (Report.Prepared_Input
         and then not Report.Prepared_Has_Object
         and then not Report.Native_Object_Resolved
         and then not Report.Publishable
         and then Report.Status = A11y.Results.Node_Unavailable,
         "Windows UIA event mapper reports unbacked prepared publication rejections");
      Check
        (A11y.Windows_Backend.UIA_Events.Validate_For_Posting
           (Emission).Status = A11y.Results.Node_Unavailable,
         "Windows UIA event mapper rejects unbacked publications before posting");

      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Invalid_Prepared_Event,
         Object        => <>,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects invalid prepared event envelopes before native object resolution");
      Check
        (Report.Prepared_Input
         and then not Report.Envelope_Valid
         and then not Report.Native_Object_Resolved
         and then not Report.Publishable
         and then Report.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper reports invalid prepared event envelope rejections before native object resolution");

      Prepared :=
        (Status        => A11y.Results.Timed_Out,
         Event         => Prepared_Event,
         Object        => <>,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Timed_Out,
         "Windows UIA event mapper preserves failed prepared publication status");
      Check
        (Report.Prepared_Input
         and then Report.Envelope_Valid
         and then not Report.Publishable
         and then Report.Status = A11y.Results.Timed_Out,
         "Windows UIA event mapper reports failed prepared publication status");
      Check
        (A11y.Windows_Backend.UIA_Events.Validate_For_Posting
           (Emission).Status = A11y.Results.Timed_Out,
         "Windows UIA posting validation preserves failed prepared publication status");

      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Destroy_Event, Prepared, Result);
      A11y.Windows_Backend.UIA_Events.Build_Prepared_Event_With_Report
        (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Emission.Publishable
         and then Emission.Native_Object =
           A11y.Native_Object_Caches.No_Object
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Child_Removed_Event,
         "Windows UIA event mapper accepts prepared destruction publications");
      Check
        (Report.Source = Child
         and then Report.Prepared_Input
         and then not Report.Prepared_Has_Object
         and then Report.Prepared_Destroys_Node
         and then not Report.Native_Object_Resolved
         and then Report.Publishable
         and then Report.Status = A11y.Results.Success,
         "Windows UIA event mapper reports prepared destruction publications");
      Check
        (A11y.Results.Succeeded
           (A11y.Windows_Backend.UIA_Events.Validate_For_Posting
              (Emission)),
         "Windows UIA event mapper validates destruction publications without native objects");
   end;

   declare
      package Events renames A11y.Windows_Backend.UIA_Events;
      Queue     : Events.Event_Emission_Queue;
      First     : Events.UIA_Event_Emission;
      Second    : Events.UIA_Event_Emission;
      Dequeued  : Events.UIA_Event_Emission;
      Bad       : Events.UIA_Event_Emission;
      Report    : Events.Posting_Attempt_Report;
      Drain     : Events.Posting_Drain_Report;
      Prepared_Report : Events.Prepared_Enqueue_Report;
      Posted    : Natural := 0;
      Runtime   : A11y.Native_Runtimes.Native_Runtime;
      Prepared  : A11y.Native_Runtimes.Prepared_Event;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;

      procedure Post_Success
        (Emission : Events.UIA_Event_Emission;
         Result   : out A11y.Results.Result)
      is
      begin
         if Emission.Publishable then
            Posted := Posted + 1;
            Result := A11y.Results.Ok;
         else
            Result := (Status => A11y.Results.Invalid_Argument);
         end if;
      end Post_Success;

      procedure Post_Failure
        (Emission : Events.UIA_Event_Emission;
         Result   : out A11y.Results.Result)
      is
         pragma Unreferenced (Emission);
      begin
         Result := (Status => A11y.Results.Native_Failure);
      end Post_Failure;
   begin
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Native_Array_Size, 2, Result);
      Events.Configure_Queue (Queue, Limits, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Capacity (Queue) = 2
         and then Events.Queue_Length (Queue) = 0,
         "Windows UIA event queue adopts native array resource limit");
      Check
        (not Events.Posting_Interest (Queue).Can_Post
         and then not Events.Posting_Interest (Queue).Has_Pending
         and then Events.Posting_Interest (Queue).Capacity = 2
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.No_Posting_Operation,
         "Windows UIA event queue interest reports empty queues");

      First := Events.Build_Event
        ((Sequence  => 18,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 8));
      Second := Events.Build_Event
        ((Sequence  => 19,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Window_Opened,
          Revision  => 9));

      Events.Enqueue (Queue, First, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Length (Queue) = 1,
         "Windows UIA event queue accepts a publishable emission");
      Check
        (Events.Posting_Interest (Queue).Can_Post
         and then Events.Posting_Interest (Queue).Has_Pending
         and then Events.Posting_Interest (Queue).Length = 1
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.Post_Next_Event,
         "Windows UIA event queue interest admits pending events");
      Check
        (Events.Validate_For_Posting (First).Status =
           A11y.Results.Node_Unavailable,
         "Windows UIA event queue requires native objects before posting ordinary emissions");

      Events.Enqueue (Queue, Second, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Length (Queue) = 2,
         "Windows UIA event queue fills to configured capacity");

      Events.Set_Queue_Capacity (Queue, 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "Windows UIA event queue rejects shrinking below queued length");

      Events.Enqueue (Queue, First, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Events.Queue_Overflowed (Queue),
         "Windows UIA event queue reports bounded overflow");
      Check
        (not Events.Posting_Interest (Queue).Can_Post
         and then Events.Posting_Interest (Queue).Has_Pending
         and then Events.Posting_Interest (Queue).Overflowed
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.Back_Pressure,
         "Windows UIA event queue interest reports back pressure after overflow");

      Events.Dequeue_For_Posting (Queue, Dequeued, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not Dequeued.Publishable
         and then Events.Queue_Length (Queue) = 2,
         "Windows UIA event queue posting admission rejects overflow without drain");
      Events.Dequeue_For_Posting_With_Report (Queue, Dequeued, Report, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Report.Status = A11y.Results.Resource_Limit
         and then Report.Length_Before = 2
         and then Report.Length_After = 2
         and then Report.Capacity = 2
         and then Report.Source = A11y.Node_Ids.No_Node
         and then Report.Sequence = A11y.No_Event
         and then Report.Revision = A11y.Initial_Revision
         and then Report.Had_Pending
         and then Report.Had_Overflow
         and then not Report.Admitted
         and then not Report.Emission_Taken
         and then Report.Next_Operation = Events.Back_Pressure
         and then not Dequeued.Publishable
         and then Events.Queue_Length (Queue) = 2,
         "Windows UIA event queue posting report records overflow rejection without drain");
      Events.Drain_For_Posting_Bounded
        (Queue, 1, Post_Success'Access, Drain, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Drain.Stop_Reason = Events.Back_Pressure
         and then Drain.Attempt_Limit = 1
         and then Drain.Attempts = 0
         and then Drain.Posted = 0
         and then Drain.Length_Before = 2
         and then Drain.Length_After = 2
         and then Drain.Last_Source = A11y.Node_Ids.No_Node
         and then Drain.Last_Sequence = A11y.No_Event
         and then Drain.Last_Revision = A11y.Initial_Revision
         and then Drain.Had_Overflow
         and then Posted = 0
         and then Events.Queue_Length (Queue) = 2,
         "Windows UIA bounded posting drain reports overflow back pressure without consumption");

      Events.Peek (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Sequence = First.Sequence,
         "Windows UIA event queue peek preserves FIFO head");

      Events.Dequeue (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Sequence = First.Sequence
         and then Events.Queue_Length (Queue) = 1,
         "Windows UIA event queue dequeues FIFO head");

      Bad := (Publishable => False, Status => A11y.Results.Node_Unavailable);
      Events.Enqueue (Queue, Bad, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Events.Queue_Length (Queue) = 1,
         "Windows UIA event queue rejects non-publishable emissions");

      Events.Dequeue (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Sequence = Second.Sequence
         and then Events.Queue_Length (Queue) = 0,
         "Windows UIA event queue preserves FIFO order through drain");

      Events.Peek (Queue, Dequeued, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then not Dequeued.Publishable,
         "Windows UIA event queue reports empty peek as node unavailable");

      Events.Clear (Queue);
      Check
        (Events.Queue_Length (Queue) = 0
         and then not Events.Queue_Overflowed (Queue),
         "Windows UIA event queue clear resets overflow state");
      Check
        (not Events.Posting_Interest (Queue).Can_Post
         and then not Events.Posting_Interest (Queue).Has_Pending
         and then not Events.Posting_Interest (Queue).Overflowed
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.No_Posting_Operation,
         "Windows UIA event queue interest resets after clear");

      A11y.Native_Runtimes.Start (Runtime, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA event queue prepared-enqueue fixture starts native runtime");
      A11y.Native_Runtimes.Prepare_Event
        (Runtime,
         (Sequence  => 120,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 20),
         Prepared,
         Result);
      Events.Enqueue_Prepared_Event_With_Report
        (Queue, Prepared, Prepared_Report, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Length (Queue) = 1
         and then Prepared_Report.Source = Root
         and then Prepared_Report.Sequence = 120
         and then Prepared_Report.Revision = 20
         and then Prepared_Report.Length_Before = 0
         and then Prepared_Report.Length_After = 1
         and then Prepared_Report.Capacity = 2
         and then Prepared_Report.Prepared_Status = A11y.Results.Success
         and then Prepared_Report.Prepared_Validation_Status =
           A11y.Results.Success
         and then Prepared_Report.Prepared_Has_Object
         and then not Prepared_Report.Prepared_Destroys_Node
         and then Prepared_Report.Build_Publishable
         and then Prepared_Report.Native_Object_Resolved
         and then Prepared_Report.Enqueued
         and then Prepared_Report.Status = A11y.Results.Success,
         "Windows UIA event queue reports prepared native publication enqueue");
      Events.Peek (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Native_Object = Prepared.Object
         and then Dequeued.Sequence = 120,
         "Windows UIA event queue preserves prepared native object metadata");
      Events.Dequeue (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Length (Queue) = 0,
         "Windows UIA event queue drains prepared native publications");
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         =>
           (Sequence  => 121,
            Timestamp => Ada.Calendar.Clock,
            Source    => Root,
            Kind      => A11y.Events.Focus_Changed,
            Revision  => 21),
         Object        => Prepared.Object,
         Has_Object    => True,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => True,
         Focus_Payload => (Old_Focus => Child, New_Focus => Root),
         Has_Node_Reference_Payload => True,
         Node_Reference_Payload => (Old_Node => Child, New_Node => Root),
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      Events.Enqueue_Prepared_Event_With_Report
        (Queue, Prepared, Prepared_Report, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Events.Queue_Length (Queue) = 0
         and then Prepared_Report.Prepared_Status = A11y.Results.Success
         and then Prepared_Report.Prepared_Validation_Status =
           A11y.Results.Invalid_Argument
         and then not Prepared_Report.Build_Publishable
         and then not Prepared_Report.Native_Object_Resolved
         and then not Prepared_Report.Enqueued
         and then Prepared_Report.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event queue validates conflicting prepared payloads before native emission build");
      Prepared :=
        (Status        => A11y.Results.Invalid_State,
         Event         =>
           (Sequence  => 122,
            Timestamp => Ada.Calendar.Clock,
            Source    => Root,
            Kind      => A11y.Events.Focus_Changed,
            Revision  => 22),
         others       => <>);
      Events.Enqueue_Prepared_Event_With_Report
        (Queue, Prepared, Prepared_Report, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Events.Queue_Length (Queue) = 0
         and then Prepared_Report.Source = Root
         and then Prepared_Report.Sequence = 122
         and then Prepared_Report.Revision = 22
         and then Prepared_Report.Length_Before = 0
         and then Prepared_Report.Length_After = 0
         and then Prepared_Report.Prepared_Status = A11y.Results.Invalid_State
         and then Prepared_Report.Prepared_Validation_Status =
           A11y.Results.Invalid_State
         and then not Prepared_Report.Build_Publishable
         and then not Prepared_Report.Native_Object_Resolved
         and then not Prepared_Report.Enqueued
         and then Prepared_Report.Status = A11y.Results.Invalid_State,
         "Windows UIA event queue validates failed prepared statuses before native emission build");

      Events.Enqueue (Queue, First, Result);
      Events.Dequeue_For_Posting_With_Report
        (Queue, Dequeued, Report, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Report.Status = A11y.Results.Success
         and then Report.Length_Before = 1
         and then Report.Length_After = 0
         and then Report.Capacity = 2
         and then Report.Had_Pending
         and then not Report.Had_Overflow
         and then Report.Admitted
         and then Report.Emission_Taken
         and then Report.Source = First.Source
         and then Report.Sequence = First.Sequence
         and then Report.Revision = First.Revision
         and then Report.Next_Operation = Events.Post_Next_Event
         and then Dequeued.Publishable
         and then Dequeued.Sequence = First.Sequence
         and then Events.Queue_Length (Queue) = 0,
         "Windows UIA event queue posting report drains after overflow reset");

      Events.Enqueue (Queue, First, Result);
      Events.Enqueue (Queue, Second, Result);
      Events.Drain_For_Posting_Bounded
        (Queue, 0, Post_Success'Access, Drain, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Drain.Stop_Reason = Events.Invalid_Request
         and then Drain.Attempts = 0
         and then Drain.Posted = 0
         and then Drain.Last_Source = A11y.Node_Ids.No_Node
         and then Drain.Last_Sequence = A11y.No_Event
         and then Drain.Last_Revision = A11y.Initial_Revision
         and then Events.Queue_Length (Queue) = 2,
         "Windows UIA bounded posting drain rejects zero attempt limits");

      Events.Drain_For_Posting_Bounded
        (Queue, 1, Post_Success'Access, Drain, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Drain.Stop_Reason = Events.Iteration_Limit_Reached
         and then Drain.Attempt_Limit = 1
         and then Drain.Attempts = 1
         and then Drain.Posted = 1
         and then Drain.Length_Before = 2
         and then Drain.Length_After = 1
         and then Drain.Last_Source = First.Source
         and then Drain.Last_Sequence = First.Sequence
         and then Drain.Last_Revision = First.Revision
         and then Posted = 1
         and then Events.Queue_Length (Queue) = 1,
         "Windows UIA bounded posting drain stops at the iteration limit");

      Events.Drain_For_Posting_Bounded
        (Queue, 4, Post_Success'Access, Drain, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Drain.Stop_Reason = Events.No_Pending
         and then Drain.Attempts = 1
         and then Drain.Posted = 1
         and then Drain.Length_Before = 1
         and then Drain.Length_After = 0
         and then Drain.Last_Source = Second.Source
         and then Drain.Last_Sequence = Second.Sequence
         and then Drain.Last_Revision = Second.Revision
         and then Posted = 2
         and then Events.Queue_Length (Queue) = 0,
         "Windows UIA bounded posting drain reports completion when the queue empties");

      Events.Enqueue (Queue, First, Result);
      Events.Drain_For_Posting_Bounded
        (Queue, 1, Post_Failure'Access, Drain, Result);
      Check
        (Result.Status = A11y.Results.Native_Failure
         and then Drain.Stop_Reason = Events.Callback_Failed
         and then Drain.Attempt_Limit = 1
         and then Drain.Attempts = 1
         and then Drain.Posted = 0
         and then Drain.Length_Before = 1
         and then Drain.Length_After = 0
         and then Drain.Last_Source = First.Source
         and then Drain.Last_Sequence = First.Sequence
         and then Drain.Last_Revision = First.Revision
         and then Drain.Last_Status = A11y.Results.Native_Failure
         and then Posted = 2
         and then Events.Queue_Length (Queue) = 0,
         "Windows UIA bounded posting drain retains attempted identity after callback failure");
   end;

   declare
      Payload : A11y.Events.Property_Event_Payload :=
        (Property   => A11y.Properties.Placeholder,
         Value_Kind => A11y.Properties.String_Value,
         Old_Status => A11y.Properties.Unsupported,
         New_Status => A11y.Properties.Present);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 121,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 21),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Placeholder_Property,
         "Windows UIA event mapper uses property payload identifiers");

      Payload.Property := A11y.Properties.Bounds;
      Payload.Value_Kind := A11y.Properties.Rectangle_Value;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 122,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 22),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Bounding_Rectangle_Property,
         "Windows UIA event mapper maps property payload value categories");

      Payload.Property := A11y.Properties.Locale;
      Payload.Value_Kind := A11y.Properties.String_Value;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 123,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 23),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Unsupported_Property,
         "Windows UIA event mapper rejects unmapped property payloads");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 124,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 24),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects property payloads on other events");
   end;

   declare
      Payload : A11y.Events.State_Event_Payload :=
        (State     => A11y.States.Focused,
         Source    => A11y.States.Application_Provided,
         Old_Value => False,
         New_Value => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 124,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 24),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Has_Keyboard_Focus_Property,
         "Windows UIA event mapper uses state payload identifiers");

      Payload.State := A11y.States.Offscreen;
      Payload.Source := A11y.States.Centrally_Derived;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 125,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 25),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Is_Offscreen_Property,
         "Windows UIA event mapper maps derived state payloads");

      Payload.Source := A11y.States.Application_Provided;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 126,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 26),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects inconsistent state payload sources");
   end;

   declare
      Payload : A11y.Events.Relation_Event_Payload :=
        (Relation   => A11y.Relations.Labelled_By,
         Inverse    => A11y.Relations.Label_For,
         Target     => Root,
         Has_Target => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 127,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Relation_Added,
          Revision  => 27),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Relation_Property
         and then Emission.Relation =
           A11y.Windows_Backend.UIA_Mappings.Labeled_By,
         "Windows UIA event mapper uses relation payload identifiers");

      Payload.Relation := A11y.Relations.Error_Message;
      Payload.Inverse := A11y.Relations.Error_For;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 128,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Relation_Targets_Changed,
          Revision  => 28),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Relation =
           A11y.Windows_Backend.UIA_Mappings.Unsupported_Relation,
         "Windows UIA event mapper keeps unsupported relation details explicit");

      Payload.Target := A11y.Node_Ids.No_Node;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 129,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Relation_Removed,
          Revision  => 29),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects invalid relation payload targets");
   end;

   declare
      Payload : constant A11y.Events.Bounds_Event_Payload :=
        (Old_Bounds => A11y.Geometry.Empty_Rectangle,
         New_Bounds =>
           (Origin => (X => 30, Y => 40),
            Extent => (Width => 50, Height => 60)));
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 130,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Bounds_Changed,
          Revision  => 30),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Bounding_Rectangle_Property
         and then Emission.Has_Bounds_Payload
         and then Emission.Old_Bounds = A11y.Geometry.Empty_Rectangle
         and then Emission.New_Bounds.Origin.X = 30
         and then Emission.New_Bounds.Extent.Height = 60,
         "Windows UIA event mapper carries bounds payload rectangles");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 131,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 31),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects bounds payloads on other events");
   end;

   declare
      Payload : constant A11y.Events.Focus_Event_Payload :=
        (Old_Focus => A11y.Node_Ids.No_Node,
         New_Focus => Root);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 132,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 32),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Focus_Changed
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Has_Keyboard_Focus_Property
         and then Emission.Has_Focus_Payload
         and then Emission.Old_Focus = A11y.Node_Ids.No_Node
         and then Emission.New_Focus = Root,
         "Windows UIA event mapper carries focus payload identities");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 133,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 33),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects focus payloads on other events");
   end;

   declare
      Payload : constant A11y.Events.Node_Reference_Event_Payload :=
        (Old_Node => A11y.Node_Ids.No_Node,
         New_Node => Root);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 134,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Active_Descendant_Changed,
          Revision  => 34),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Active_Descendant_Property
         and then Emission.Has_Node_Reference_Payload
         and then Emission.Old_Reference = A11y.Node_Ids.No_Node
         and then Emission.New_Reference = Root,
         "Windows UIA event mapper carries node-reference payload identities");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 135,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 35),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects node-reference payloads on other events");
   end;

   declare
      Payload : constant A11y.Events.Value_Event_Payload :=
        (Old_Value => A11y.Values.Integer (1),
         New_Value => A11y.Values.Exact_Decimal (125, 2),
         Old_Kind  => A11y.Values.Integer_Value,
         New_Kind  => A11y.Values.Decimal_Value);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 136,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Value_Changed,
          Revision  => 36),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Property =
           A11y.Windows_Backend.UIA_Events.Value_Property
         and then Emission.Has_Value_Payload
         and then Emission.Old_Value.Kind = A11y.Values.Integer_Value
         and then Emission.New_Value.Kind = A11y.Values.Decimal_Value
         and then Emission.New_Value.Decimal_Item.Units = 125,
         "Windows UIA event mapper carries semantic value payloads");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 137,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 37),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects value payloads on other events");
   end;

   declare
      Payload : A11y.Events.Selection_Event_Payload :=
        (Changed_Node       => Child,
         Has_Changed_Node   => True,
         Old_Selected       => False,
         New_Selected       => True,
         Requires_Selection => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 138,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 38),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Selection_Invalidated
         and then Emission.Has_Selection_Payload
         and then Emission.Selection_Node = Child
         and then Emission.Selection_Has_Node
         and then not Emission.Selection_Old_Selected
         and then Emission.Selection_New_Selected
         and then Emission.Selection_Required,
         "Windows UIA event mapper carries semantic selection payloads");

      Payload.Has_Changed_Node := False;
      Payload.Changed_Node := A11y.Node_Ids.No_Node;
      Payload.Old_Selected := False;
      Payload.New_Selected := False;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 139,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 39),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Has_Selection_Payload
         and then not Emission.Selection_Has_Node
         and then Emission.Selection_Node = A11y.Node_Ids.No_Node,
         "Windows UIA event mapper carries selection invalidation payloads");

      Payload.Changed_Node := Child;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 140,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 40),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects contradictory absent selection change nodes");

      Payload.Changed_Node := A11y.Node_Ids.No_Node;
      Payload.New_Selected := True;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 141,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 41),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects selected-state flags on "
         & "selection invalidations");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 142,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 41),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects selection payloads on other events");
   end;

   declare
      Metadata : A11y.Live_Regions.Live_Region_Metadata :=
        (Setting  => A11y.Live_Regions.Polite,
         Atomic   => True,
         Relevant => A11y.Live_Regions.Empty_Relevant_Change_Set);
      Payload : A11y.Events.Live_Region_Event_Payload;
   begin
      Metadata.Relevant :=
        A11y.Live_Regions.With_Change
          (Metadata.Relevant, A11y.Live_Regions.Text);
      Payload :=
        (Metadata         => Metadata,
         Announcement     =>
           (Text => Ada.Strings.Unbounded.To_Unbounded_String ("ready")),
         Has_Announcement => True);

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 140,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Announcement_Requested,
          Revision  => 40),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Notification
         and then Emission.Has_Live_Region_Payload
         and then Emission.Live_Region_Payload.Metadata.Setting =
           A11y.Live_Regions.Polite
         and then Emission.Live_Region_Payload.Metadata.Atomic
         and then Emission.Live_Region_Payload.Has_Announcement
         and then Ada.Strings.Unbounded.To_String
           (Emission.Live_Region_Payload.Announcement.Text) = "ready",
         "Windows UIA event mapper carries live-region announcement payloads");

      Payload.Has_Announcement := False;
      Payload.Announcement.Text := Ada.Strings.Unbounded.Null_Unbounded_String;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 141,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Live_Region_Changed,
          Revision  => 41),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Live_Region_Changed
         and then Emission.Has_Live_Region_Payload
         and then not Emission.Live_Region_Payload.Has_Announcement
         and then Ada.Strings.Unbounded.Length
           (Emission.Live_Region_Payload.Announcement.Text) = 0,
         "Windows UIA event mapper carries live-region change payloads");

      Payload.Metadata.Setting := A11y.Live_Regions.Off;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 142,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Live_Region_Changed,
          Revision  => 42),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_State,
         "Windows UIA event mapper rejects inactive live-region relevance");

      Payload.Metadata.Setting := A11y.Live_Regions.Polite;
      Payload.Has_Announcement := True;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 143,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Live_Region_Changed,
          Revision  => 43),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects announcements on live-region "
         & "changes");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 144,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 44),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects live-region payloads on other events");

      declare
         Snapshot : A11y.Windows_Backend.UIA_Live_Regions.Live_Snapshot :=
           (Id => Root, Metadata => Metadata, Defunct => False);
         Reply : A11y.Windows_Backend.UIA_Live_Regions.Live_Reply;
         Live_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
         Limit_Result : A11y.Results.Result;
      begin
         Payload.Has_Announcement := False;
         Payload.Metadata.Setting := A11y.Live_Regions.Polite;
         Snapshot.Metadata := Payload.Metadata;

         Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
           (Snapshot,
            A11y.Windows_Backend.UIA_Live_Regions.Setting_Name,
            Live_Limits);
         Check
           (Reply.Kind =
              A11y.Windows_Backend.UIA_Live_Regions.String_Reply
            and then Ada.Strings.Unbounded.To_String (Reply.Text) =
              "polite",
            "Windows UIA live-region mapper returns setting names");

         Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
           (Snapshot,
            A11y.Windows_Backend.UIA_Live_Regions.Relevant_Names,
            Live_Limits);
         Check
           (Reply.Kind =
              A11y.Windows_Backend.UIA_Live_Regions.String_Reply
            and then Ada.Strings.Unbounded.To_String (Reply.Text) = "text",
            "Windows UIA live-region mapper returns relevance names");

         Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
           (Snapshot,
            A11y.Windows_Backend.UIA_Live_Regions.Is_Atomic,
            Live_Limits);
         Check
           (Reply.Kind =
              A11y.Windows_Backend.UIA_Live_Regions.Boolean_Reply
            and then Reply.Boolean_Item,
            "Windows UIA live-region mapper returns atomicity");

         Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
           (Snapshot,
            A11y.Windows_Backend.UIA_Live_Regions.Is_Externally_Announced,
            Live_Limits);
         Check
           (Reply.Kind =
              A11y.Windows_Backend.UIA_Live_Regions.Boolean_Reply
            and then Reply.Boolean_Item,
            "Windows UIA live-region mapper returns announcement policy");

         A11y.Resource_Limits.Set_Limit
           (Live_Limits,
            A11y.Resource_Limits.Native_String_Size,
            4,
            Limit_Result);
         Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
           (Snapshot,
            A11y.Windows_Backend.UIA_Live_Regions.Setting_Name,
            Live_Limits);
         Check
           (Reply.Kind = A11y.Windows_Backend.UIA_Live_Regions.Error_Reply
            and then Reply.Status = A11y.Results.Resource_Limit,
            "Windows UIA live-region mapper bounds setting names");

         declare
            Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
              A11y.Resource_Limits.Default_Config;
         begin
            Invalid_Limits.Limits
              (A11y.Resource_Limits.Native_String_Size) := 0;
            Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
              (Snapshot,
               A11y.Windows_Backend.UIA_Live_Regions.Is_Atomic,
               Invalid_Limits);
            Check
              (Reply.Kind =
                 A11y.Windows_Backend.UIA_Live_Regions.Error_Reply
               and then Reply.Status = A11y.Results.Invalid_Argument,
               "Windows UIA live-region mapper rejects invalid limit configs");
         end;

         Snapshot.Metadata.Setting := A11y.Live_Regions.Off;
         Reply := A11y.Windows_Backend.UIA_Live_Regions.Query_Live_Region
           (Snapshot,
            A11y.Windows_Backend.UIA_Live_Regions.Is_Atomic,
            A11y.Resource_Limits.Default_Config);
         Check
           (Reply.Kind = A11y.Windows_Backend.UIA_Live_Regions.Error_Reply
            and then Reply.Status = A11y.Results.Invalid_State,
            "Windows UIA live-region mapper validates metadata");
      end;
   end;

   declare
      Payload : constant A11y.Events.Tree_Event_Payload :=
        (Parent    => Root,
         Child     => Child,
         Has_Child => True,
         Index     => 2,
         Has_Index => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 143,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Child_Added,
          Revision  => 43),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Kind =
           A11y.Windows_Backend.UIA_Events.Automation_Structure_Changed
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Child_Added_Event
         and then Emission.Has_Tree_Payload
         and then Emission.Tree_Payload.Parent = Root
         and then Emission.Tree_Payload.Child = Child
         and then Emission.Tree_Payload.Index = 2,
         "Windows UIA event mapper carries child tree payloads");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 144,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 44),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects tree payloads on other events");
   end;

   declare
      Payload : A11y.Events.Tree_Event_Payload :=
        (Parent    => Root,
         Child     => A11y.Node_Ids.No_Node,
         Has_Child => False,
         Index     => Positive'First,
         Has_Index => False);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 145,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Subtree_Rebuilt,
          Revision  => 45),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Subtree_Rebuilt_Event
         and then Emission.Has_Tree_Payload
         and then not Emission.Tree_Payload.Has_Child,
         "Windows UIA event mapper carries aggregate tree payloads");

      Payload.Child := Child;
      Payload.Index := 7;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 146,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Subtree_Rebuilt,
          Revision  => 46),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects contradictory aggregate tree payloads");

      Payload.Has_Child := True;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 147,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Subtree_Rebuilt,
          Revision  => 47),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects child metadata on aggregate "
         & "tree payloads");
   end;

   declare
      Payload : A11y.Events.Table_Event_Payload :=
        (Table      => Root,
         Item       => A11y.Node_Ids.No_Node,
         Has_Item   => False,
         Row        => 3,
         Has_Row    => True,
         Column     => 0,
         Has_Column => False);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 146,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Row_Inserted,
          Revision  => 46),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Row_Inserted_Event
         and then Emission.Has_Table_Payload
         and then Emission.Table_Payload.Table = Root
         and then Emission.Table_Payload.Row = 3
         and then not Emission.Table_Payload.Has_Item,
         "Windows UIA event mapper carries row table payloads");

      Payload.Item := Child;
      Payload.Column := 2;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 147,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Row_Inserted,
          Revision  => 47),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects contradictory row table payloads");

      Payload.Has_Item := True;
      Payload.Column := 0;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 148,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Row_Inserted,
          Revision  => 48),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects cell metadata on row table "
         & "payloads");
   end;

   declare
      Payload : constant A11y.Events.Table_Event_Payload :=
        (Table      => Root,
         Item       => Child,
         Has_Item   => True,
         Row        => 1,
         Has_Row    => True,
         Column     => 2,
         Has_Column => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 148,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Cell_Changed,
          Revision  => 48),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Cell_Changed_Event
         and then Emission.Has_Table_Payload
         and then Emission.Table_Payload.Item = Child
         and then Emission.Table_Payload.Row = 1
         and then Emission.Table_Payload.Column = 2,
         "Windows UIA event mapper carries cell table payloads");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 149,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 49),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects table payloads on other events");
   end;

   declare
      Payload : A11y.Events.Document_Event_Payload :=
        (Document    => Root,
         Surface     => Child,
         Has_Surface => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 149,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Document_Loaded,
          Revision  => 49),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Structure =
           A11y.Windows_Backend.UIA_Events.Document_Loaded_Event
         and then Emission.Has_Document_Payload
         and then Emission.Document_Payload.Document = Root
         and then Emission.Document_Payload.Surface = Child
         and then Emission.Document_Payload.Has_Surface,
         "Windows UIA event mapper carries document payloads");

      Payload.Has_Surface := False;
      Payload.Surface := Child;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 150,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Document_Loaded,
          Revision  => 50),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects contradictory absent document surface payloads");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 151,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 51),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects document payloads on other events");
   end;

   declare
      Payload : A11y.Events.Window_Event_Payload :=
        (Surface   => Root,
         Kind      => A11y.Windows.Modal_Dialog,
         Owner     => Child,
         Has_Owner => True);
   begin
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 151,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Window_Opened,
          Revision  => 51),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Window =
           A11y.Windows_Backend.UIA_Events.Window_Opened_Event
         and then Emission.Has_Window_Payload
         and then Emission.Window_Payload.Surface = Root
         and then Emission.Window_Payload.Kind = A11y.Windows.Modal_Dialog
         and then Emission.Window_Payload.Owner = Child
         and then Emission.Window_Payload.Has_Owner,
         "Windows UIA event mapper carries window payloads");

      Payload.Has_Owner := False;
      Payload.Owner := Child;
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 153,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Window_Opened,
          Revision  => 53),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects contradictory absent window owner payloads");

      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  => 154,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 54),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "Windows UIA event mapper rejects window payloads on other events");
   end;

   Emission := A11y.Windows_Backend.UIA_Events.Build_Event
     ((Sequence  => 13,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Child_Added,
       Revision  => 6));
   Check
     (Emission.Publishable
      and then Emission.Kind =
        A11y.Windows_Backend.UIA_Events.Automation_Structure_Changed
      and then Emission.Structure =
        A11y.Windows_Backend.UIA_Events.Child_Added_Event,
      "Windows UIA event mapper annotates structure notifications");

   Emission := A11y.Windows_Backend.UIA_Events.Build_Event
     ((Sequence  => 14,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Window_Activated,
       Revision  => 7));
   Check
     (Emission.Publishable
      and then Emission.Window =
        A11y.Windows_Backend.UIA_Events.Window_Activated_Event,
      "Windows UIA event mapper annotates window notifications");

   for Kind in A11y.Events.Event_Kind loop
      Emission := A11y.Windows_Backend.UIA_Events.Build_Event
        ((Sequence  =>
            A11y.Event_Sequence (100 + A11y.Events.Event_Kind'Pos (Kind)),
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => Kind,
          Revision  => 9));
      Check
        (Emission.Publishable
         and then Emission.Sequence =
           A11y.Event_Sequence (100 + A11y.Events.Event_Kind'Pos (Kind)),
         "Windows UIA event mapper covers every semantic event kind");
   end loop;

   Emission := A11y.Windows_Backend.UIA_Events.Build_Event
     ((Sequence  => A11y.No_Event,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Focus_Changed,
       Revision  => 8));
   Check
     (not Emission.Publishable
      and then Emission.Status = A11y.Results.Invalid_Argument,
      "Windows UIA event mapper rejects unsequenced notifications");

   Emission := A11y.Windows_Backend.UIA_Events.Build_Event
     ((Sequence  => 15,
       Timestamp => Ada.Calendar.Clock,
       Source    => A11y.Node_Ids.No_Node,
       Kind      => A11y.Events.Focus_Changed,
       Revision  => 8));
   Check
     (not Emission.Publishable
      and then Emission.Status = A11y.Results.Node_Unavailable,
      "Windows UIA event mapper rejects stale notification sources");

   Request_Item.Kind := Action_Map_Query;
   Request_Item.Action := A11y.Actions.Dismiss;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Unsupported_Action,
      "Windows UIA request router preserves unsupported action errors");

   Check
     (A11y.Windows_Backend.UIA_Mappings.Map_Relation
        (A11y.Relations.Labelled_By)
      = A11y.Windows_Backend.UIA_Mappings.Labeled_By
      and then A11y.Windows_Backend.UIA_Mappings.Map_Relation
        (A11y.Relations.Described_By)
      = A11y.Windows_Backend.UIA_Mappings.Described_By
      and then A11y.Windows_Backend.UIA_Mappings.Map_Relation
        (A11y.Relations.Error_Message)
      = A11y.Windows_Backend.UIA_Mappings.Unsupported_Relation,
      "Windows UIA mapper classifies neutral relation kinds");

   Check
     (A11y.Windows_Backend.UIA_Mappings.Map_Role (A11y.Roles.Application)
      = A11y.Windows_Backend.UIA_Mappings.Pane,
      "Windows UIA mapper explicitly maps application role");

   for Role in A11y.Roles.Role loop
      declare
         Mapped : constant A11y.Windows_Backend.UIA_Mappings.UIA_Control_Type :=
           A11y.Windows_Backend.UIA_Mappings.Map_Role (Role);
         Expected_Custom : constant Boolean :=
           Role in A11y.Roles.Row |
                   A11y.Roles.Column |
                   A11y.Roles.Cell |
                   A11y.Roles.Custom;
      begin
         Check
           ((Mapped /= A11y.Windows_Backend.UIA_Mappings.Custom)
            or else Expected_Custom,
            "Windows UIA mapper covers every semantic role explicitly");
      end;
   end loop;

   for Relation in A11y.Relations.Relation_Kind loop
      declare
         Mapped : constant
           A11y.Windows_Backend.UIA_Mappings.UIA_Relation_Property :=
             A11y.Windows_Backend.UIA_Mappings.Map_Relation (Relation);
         Expected_Unsupported : constant Boolean :=
           Relation not in A11y.Relations.Labelled_By |
                           A11y.Relations.Controller_For |
                           A11y.Relations.Described_By |
                           A11y.Relations.Flows_To;
      begin
         Check
           ((Mapped /=
                A11y.Windows_Backend.UIA_Mappings.Unsupported_Relation)
            or else Expected_Unsupported,
            "Windows UIA mapper covers every semantic relation explicitly");
      end;
   end loop;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
   Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Native_Object =
        A11y.Native_Object_Caches.No_Object,
      "Windows UIA provider boundary returns S_OK for successful requests");

   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG
      and then Boundary_Reply.Status = A11y.Results.Invalid_Argument,
      "Windows UIA native provider boundary rejects calls without native identity");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Pattern_Provider;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Pattern_Set
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Invoke)
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Toggle)
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Expand_Collapse)
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Scroll_Item)
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Window),
      "Windows UIA provider boundary preserves pattern-provider payloads");

   Boundary_Request.Has_Native_Identity := True;
   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Pattern_Set
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Invoke)
      and then Boundary_Reply.Payload.Patterns
        (A11y.Windows_Backend.UIA_Actions.Toggle),
      "Windows UIA provider boundary admits pattern-provider action identity");
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Pattern_Set,
      "Windows UIA native provider boundary admits calls with matching native identity");
   Boundary_Request.Has_Native_Identity := False;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
   Boundary_Request.Direction :=
     A11y.Windows_Backend.UIA_Fragments.First_Child;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Fragment_Node
      and then Boundary_Reply.Payload.Kind = Fragment_Node
      and then Boundary_Reply.Payload.Node = Child,
      "Windows UIA provider boundary preserves fragment navigation identity payloads");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Runtime_Id;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   declare
      Root_Result : A11y.Results.Result;
      Node_Result : A11y.Results.Result;
      Root_Component : constant Natural :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Root, Root_Result);
      Node_Component : constant Natural :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Root, Node_Result);
   begin
      Check
        (A11y.Results.Succeeded (Root_Result)
         and then A11y.Results.Succeeded (Node_Result)
         and then Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Boundary_Reply.Routed = Runtime_Id
         and then Boundary_Reply.Payload.Kind = Runtime_Id
         and then Boundary_Reply.Payload.Id.Session_Component =
           A11y.Native_Identity.To_Natural (Session)
         and then Boundary_Reply.Payload.Id.Root_Component = Root_Component
         and then Boundary_Reply.Payload.Id.Node_Component = Node_Component,
         "Windows UIA provider boundary preserves runtime identifier payloads");
   end;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Raise_Event;
   Boundary_Request.Event :=
     (Sequence  => 21,
      Timestamp => Ada.Calendar.Clock,
      Source    => Child,
      Kind      => A11y.Events.Focus_Changed,
      Revision  => 7);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Event_Emission
      and then Boundary_Reply.Native_Object =
        A11y.Native_Object_Caches.No_Object,
      "Windows UIA provider boundary routes raw event emissions without native objects");

   declare
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Boundary_Request.Event, Prepared, Result);
      Boundary_Request.Use_Prepared_Event := True;
      Boundary_Request.Prepared_Event := Prepared;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Boundary_Reply.Routed = Event_Emission
         and then Boundary_Reply.Native_Object = Prepared.Object,
         "Windows UIA provider boundary returns prepared event native objects");

      Boundary_Request.Has_Native_Identity := True;
      Boundary_Request.Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Child, Result);
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Boundary_Reply.Routed = Event_Emission
         and then Boundary_Reply.Native_Object = Prepared.Object,
         "Windows UIA provider boundary admits prepared event source identity");

      Boundary_Request.Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Root, Result);
      Boundary_Request.Event :=
        (Sequence  => Boundary_Request.Event.Sequence,
         Timestamp => Boundary_Request.Event.Timestamp,
         Source    => Root,
         Kind      => Boundary_Request.Event.Kind,
         Revision  => Boundary_Request.Event.Revision);
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA provider boundary rejects raw event identity for prepared events");
      Boundary_Request.Has_Native_Identity := False;
      Boundary_Request.Event := Prepared.Event;

      Boundary_Request.Prepared_Event :=
        (Status        => A11y.Results.Success,
         Event         => Boundary_Request.Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA provider boundary rejects unbacked prepared event emissions");

      Boundary_Request.Prepared_Event :=
        (Status        => A11y.Results.Timed_Out,
         Event         => Boundary_Request.Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => False,
         Has_Property_Payload => False,
         Property_Payload => <>,
         Has_State_Payload => False,
         State_Payload => <>,
         Has_Bounds_Payload => False,
         Bounds_Payload => <>,
         Has_Value_Payload => False,
         Value_Payload => <>,
         Has_Selection_Payload => False,
         Selection_Payload => <>,
         Has_Relation_Payload => False,
         Relation_Payload => <>,
         Has_Focus_Payload => False,
         Focus_Payload => <>,
         Has_Node_Reference_Payload => False,
         Node_Reference_Payload => <>,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>);
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_INVALIDOPERATION
         and then Boundary_Reply.Status = A11y.Results.Timed_Out,
         "Windows UIA provider boundary preserves failed prepared event status");

      Boundary_Request.Use_Prepared_Event := False;
   end;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
   Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;

   Boundary_Request.Has_Native_Identity := True;
   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Root, Result);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK,
      "Windows UIA provider boundary admits matching native identity");

   declare
      Other_Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
   begin
      Boundary_Request.Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Other_Session, Root, Result);
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (Result.Status = A11y.Results.Success
         and then Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
         "Windows UIA provider boundary rejects cross-session native identity");
   end;

   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "Windows UIA provider boundary rejects mismatched native identity");

   Boundary_Request.Native_Node_Component := 0;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "Windows UIA provider boundary rejects malformed native identity");

   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (A11y.Results.Succeeded (Result)
      and then Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "Windows UIA native callback boundary rejects mismatched native identity");

   Boundary_Request.Native_Node_Component := 0;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "Windows UIA native callback boundary rejects malformed native identity");
   Boundary_Request.Has_Native_Identity := False;

   Boundary_Request.Property :=
     A11y.Windows_Backend.UIA_Properties.Bounding_Rectangle;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Property_Rectangle
      and then Boundary_Reply.Payload.Kind = Property_Rectangle
      and then Boundary_Reply.Payload.Bounds = Snapshots.Properties.Bounds,
      "Windows UIA provider boundary routes bounding rectangle requests");
   Boundary_Request.Property := A11y.Windows_Backend.UIA_Properties.Name;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action;
   Boundary_Request.Action := A11y.Actions.Press;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action = A11y.Actions.Press,
      "Windows UIA provider boundary routes action requests");

   Boundary_Request.Action := A11y.Actions.Set_Focus;
   Snapshots.Actions (A11y.Actions.Set_Focus) := True;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action =
        A11y.Actions.Set_Focus,
      "Windows UIA provider boundary routes set-focus requests");

   Boundary_Request.Action := A11y.Actions.Open;
   Snapshots.Actions (A11y.Actions.Open) := True;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action = A11y.Actions.Open,
      "Windows UIA provider boundary routes open requests");

   Boundary_Request.Action := A11y.Actions.Scroll_Into_View;
   Snapshots.Actions (A11y.Actions.Scroll_Into_View) := True;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action =
        A11y.Actions.Scroll_Into_View,
      "Windows UIA provider boundary routes scroll-into-view requests");

   Boundary_Request.Action := A11y.Actions.Close;
   Snapshots.Actions (A11y.Actions.Close) := True;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action = A11y.Actions.Close,
      "Windows UIA provider boundary routes close requests");

   Boundary_Request.Action := A11y.Actions.Dismiss;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE,
      "Windows UIA provider boundary maps unsupported actions to S_FALSE");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Relation_Targets;
   Boundary_Request.Relation := A11y.Relations.Labelled_By;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Relation_Targets
      and then Boundary_Reply.Payload.Relation_Property =
        A11y.Windows_Backend.UIA_Mappings.Labeled_By,
      "Windows UIA provider boundary routes relation target requests");
   Check
     (Boundary_Reply.Payload.Relation_Property =
        A11y.Windows_Backend.UIA_Mappings.Labeled_By,
      "Windows UIA provider boundary preserves relation target native properties");

   Boundary_Request.Relation := A11y.Relations.Error_Message;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE
      and then Boundary_Reply.Routed = Relation_Not_Supported,
      "Windows UIA provider boundary maps unsupported relations to S_FALSE");

   Boundary_Request.Kind := A11y.Windows_Backend.UIA_Provider_Boundary.Get_Value;
   Boundary_Request.Value := A11y.Windows_Backend.UIA_Values.Current_Value;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
  Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Value_Float
      and then Boundary_Reply.Payload.Kind = Value_Float
      and then Boundary_Reply.Payload.Float_Item = 5.0,
      "Windows UIA provider boundary routes value requests");

   Boundary_Request.Kind := A11y.Windows_Backend.UIA_Provider_Boundary.Set_Value;
   Boundary_Request.Requested_Value := A11y.Values.Integer (7);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Value_Set_Request
      and then Boundary_Reply.Payload.Kind = Value_Set_Request
      and then A11y.Values.Equal
        (Boundary_Reply.Payload.Requested_Value, A11y.Values.Integer (7)),
      "Windows UIA provider boundary routes value set requests");

   Snapshots.Value.Metadata.Mode := A11y.Values.Read_Only;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_INVALIDOPERATION
      and then Boundary_Reply.Status = A11y.Results.Read_Only,
      "Windows UIA provider boundary rejects read-only value set requests");
   Snapshots.Value.Metadata.Mode := A11y.Values.Writable;
   Boundary_Request.Kind := A11y.Windows_Backend.UIA_Provider_Boundary.Get_Value;

   Snapshots.Value.Metadata.Current :=
     A11y.Values.Exact_Decimal (Units => 999, Scale => 2);
   Snapshots.Value.Metadata.Minimum :=
     A11y.Values.Exact_Decimal (Units => 0, Scale => 2);
   Snapshots.Value.Metadata.Maximum :=
     A11y.Values.Exact_Decimal (Units => 1_000, Scale => 2);
   Snapshots.Value.Metadata.Small_Increment :=
     A11y.Values.Exact_Decimal (Units => 1, Scale => 2);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_FAIL
      and then Boundary_Reply.Status = A11y.Results.Native_Failure,
      "Windows UIA provider boundary rejects inexact native value conversion");
   Snapshots.Value.Metadata.Current := A11y.Values.Integer (5);
   Snapshots.Value.Metadata.Minimum := A11y.Values.Integer (0);
   Snapshots.Value.Metadata.Maximum := A11y.Values.Integer (10);
   Snapshots.Value.Metadata.Small_Increment := A11y.Values.Integer (1);

   Boundary_Request.Value := A11y.Windows_Backend.UIA_Values.Large_Increment;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.Routed = Value_Not_Supported,
      "Windows UIA provider boundary preserves absent value metadata");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Selection;
   Boundary_Request.Selection :=
     A11y.Windows_Backend.UIA_Selection.Selected_Count;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Selection_UInt32
      and then Boundary_Reply.Payload.Kind = Selection_UInt32
      and then Boundary_Reply.Payload.UInt32 = 1,
      "Windows UIA provider boundary routes selection requests");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Set_Selection;
   Boundary_Request.Selection_Request :=
     A11y.Windows_Backend.UIA_Selection.Toggle_Item;
   Boundary_Request.Selection_Target := Child;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Selection_Request_Reply
      and then Boundary_Reply.Payload.Kind = Selection_Request_Reply
      and then Boundary_Reply.Payload.Selection_Target = Child
      and then Boundary_Reply.Payload.Selection_Request =
        A11y.Windows_Backend.UIA_Selection.Toggle_Item,
      "Windows UIA provider boundary preserves selection change requests");

   Boundary_Request.Selection_Request :=
     A11y.Windows_Backend.UIA_Selection.Clear_Selection;
   Boundary_Request.Selection_Target := A11y.Node_Ids.No_Node;
   A11y.Selection.Configure
     (Snapshots.Selection.Selection,
      A11y.Selection.Multiple,
      Requires_Selection => True);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_INVALIDOPERATION,
      "Windows UIA provider boundary maps invalid selection changes");
   A11y.Selection.Configure
     (Snapshots.Selection.Selection, A11y.Selection.Multiple);
   A11y.Selection.Select_Item
     (Snapshots.Selection.Selection, Child, Result);
   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Selection;

   Boundary_Request.Selection :=
     A11y.Windows_Backend.UIA_Selection.Selected_Item;
   Boundary_Request.Index := 9;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
      "Windows UIA provider boundary maps invalid selection indexes");
   Boundary_Request.Index := 1;

   Boundary_Request.Kind := A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text;
   Boundary_Request.Text := A11y.Windows_Backend.UIA_Text.Character_Count;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Text_UInt32
      and then Boundary_Reply.Payload.Kind = Text_UInt32
      and then Boundary_Reply.Payload.UInt32 = 3,
      "Windows UIA provider boundary routes text requests");

   Boundary_Request.Text := A11y.Windows_Backend.UIA_Text.Text_Range;
   Boundary_Request.Index := 99;
   Boundary_Request.Count := 1;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
      "Windows UIA provider boundary maps invalid text ranges");
   Boundary_Request.Text := A11y.Windows_Backend.UIA_Text.Caret_Offset;
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (4);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
      "Windows UIA provider boundary maps invalid caret offsets");
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (2);
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Text_Edit;
   Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("X");
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Text_Edit_Request
      and then Boundary_Reply.Payload.Kind = Text_Edit_Request
      and then Boundary_Reply.Payload.Requested_Edit.Kind =
        A11y.Text.Insert_Text
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Boundary_Reply.Payload.Requested_Edit.Text) =
          Wide_Wide_String'("X"),
      "Windows UIA provider boundary routes text edit requests");

   Boundary_Request.Text_Edit := A11y.Text.Replace_Text;
   Boundary_Request.Index := 2;
   Boundary_Request.Count := 2;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("YZ");
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Text_Edit_Request
      and then Boundary_Reply.Payload.Kind = Text_Edit_Request
      and then Boundary_Reply.Payload.Requested_Edit.Kind =
        A11y.Text.Replace_Text
      and then A11y.Text.Index
        (A11y.Text.First (Boundary_Reply.Payload.Requested_Edit.Span)) = 1
      and then A11y.Text.Length
        (Boundary_Reply.Payload.Requested_Edit.Span) = 2
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Boundary_Reply.Payload.Requested_Edit.Text) =
          Wide_Wide_String'("YZ"),
      "Windows UIA provider boundary routes replace text requests");

   Boundary_Request.Text_Edit := A11y.Text.Set_Text;
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("Reset");
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Text_Edit_Request
      and then Boundary_Reply.Payload.Kind = Text_Edit_Request
      and then Boundary_Reply.Payload.Requested_Edit.Kind =
        A11y.Text.Set_Text
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Boundary_Reply.Payload.Requested_Edit.Text) =
          Wide_Wide_String'("Reset"),
      "Windows UIA provider boundary routes set text requests");

   Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("X");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Native_String_Size, 1, Result);
   Check (A11y.Results.Succeeded (Result),
          "Windows UIA test configures native string limit");
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("XX");
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_OUTOFMEMORY
      and then Boundary_Reply.Status = A11y.Results.Resource_Limit,
      "Windows UIA provider boundary bounds text edit replacement payloads");
   Boundary_Request.Has_Native_Identity := True;
   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (A11y.Results.Succeeded (Result)
      and then Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_OUTOFMEMORY
      and then Boundary_Reply.Status = A11y.Results.Resource_Limit,
      "Windows UIA native callback boundary bounds text edit replacement payloads");
   Boundary_Request.Has_Native_Identity := False;
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Table;
   Boundary_Request.Table := A11y.Windows_Backend.UIA_Table.Row_Count;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
      and then Boundary_Reply.Routed = Table_UInt32
      and then Boundary_Reply.Payload.Kind = Table_UInt32
      and then Boundary_Reply.Payload.UInt32 = 4,
      "Windows UIA provider boundary routes table requests");

   Boundary_Request.Table := A11y.Windows_Backend.UIA_Table.Cell_At;
   Boundary_Request.Row := 99;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
      "Windows UIA provider boundary maps invalid table coordinates");
   Boundary_Request.Row := 0;
   Boundary_Request.Column := 0;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Image;
   Boundary_Request.Image := A11y.Windows_Backend.UIA_Image.Description;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.Routed = Image_String
      and then Boundary_Reply.Payload.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Boundary_Reply.Payload.Text)
        = "Revenue chart",
      "Windows UIA provider boundary routes image requests");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Document;
   Boundary_Request.Document := A11y.Windows_Backend.UIA_Document.Heading_Level;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.Routed = Document_UInt32
      and then Boundary_Reply.Payload.Kind = Document_UInt32
      and then Boundary_Reply.Payload.UInt32 = 2,
      "Windows UIA provider boundary routes document requests");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Live_Region;
   Boundary_Request.Live_Region :=
     A11y.Windows_Backend.UIA_Live_Regions.Relevant_Names;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.Routed = Live_String
      and then Boundary_Reply.Payload.Kind = Live_String
      and then Ada.Strings.Unbounded.To_String (Boundary_Reply.Payload.Text)
        = "text",
      "Windows UIA provider boundary routes live-region requests");

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Document;
   Boundary_Request.Document := A11y.Windows_Backend.UIA_Document.Heading_Level;
   Snapshots.Document.Metadata.Heading_Level := 99;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
      "Windows UIA provider boundary maps invalid document metadata");
   Snapshots.Document.Metadata.Heading_Level := 2;

   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Surface;
   Boundary_Request.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Modal;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
      and then Boundary_Reply.Routed = Surface_Boolean
      and then Boundary_Reply.Payload.Kind = Surface_Boolean
      and then Boundary_Reply.Payload.Boolean_Item,
      "Windows UIA provider boundary routes surface requests");

   Snapshots.Surface.Defunct := True;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE,
      "Windows UIA provider boundary maps defunct surface metadata");
   Snapshots.Surface.Defunct := False;

   Snapshots.Properties.Defunct := True;
   Boundary_Request.Kind :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
   Boundary_Reply :=
     A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
      and then Boundary_Reply.HResult =
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_E_ELEMENTNOTAVAILABLE,
      "Windows UIA provider boundary maps unavailable nodes to UIA errors");
   Snapshots.Properties.Defunct := False;

   Check
     (A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
        (A11y.Results.Permission_Denied) =
          A11y.Windows_Backend.UIA_Provider_Boundary.E_ACCESSDENIED
      and then A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
        (A11y.Results.Out_Of_Resources) =
          A11y.Windows_Backend.UIA_Provider_Boundary.E_OUTOFMEMORY,
      "Windows UIA provider boundary maps structured errors to HRESULTs");

   declare
      function Class_Expected
        (Status : A11y.Results.Status_Code)
         return Boolean is
        (case A11y.Native_Boundary_Calls.Return_Class (Status) is
            when A11y.Native_Boundary_Calls.Return_Success =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary.S_OK,
            when A11y.Native_Boundary_Calls.Return_Unsupported =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE,
            when A11y.Native_Boundary_Calls.Return_Unavailable |
                 A11y.Native_Boundary_Calls.Return_Shutting_Down =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary
                    .UIA_E_ELEMENTNOTAVAILABLE,
            when A11y.Native_Boundary_Calls.Return_Disabled =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary
                    .UIA_E_ELEMENTNOTENABLED,
            when A11y.Native_Boundary_Calls.Return_Invalid_Argument =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
            when A11y.Native_Boundary_Calls.Return_Permission_Denied =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary.E_ACCESSDENIED,
            when A11y.Native_Boundary_Calls.Return_Resource_Limit =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary.E_OUTOFMEMORY,
            when A11y.Native_Boundary_Calls.Return_Invalid_State |
                 A11y.Native_Boundary_Calls.Return_Read_Only |
                 A11y.Native_Boundary_Calls.Return_Busy |
                 A11y.Native_Boundary_Calls.Return_Timed_Out |
                 A11y.Native_Boundary_Calls.Return_Cancelled =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary
                    .UIA_E_INVALIDOPERATION,
            when A11y.Native_Boundary_Calls.Return_Protocol_Failure |
                 A11y.Native_Boundary_Calls.Return_Native_Failure |
                 A11y.Native_Boundary_Calls.Return_Internal_Error =>
              A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
                (Status) =
                  A11y.Windows_Backend.UIA_Provider_Boundary.E_FAIL);

      function Expected
        (Status : A11y.Results.Status_Code)
         return A11y.Windows_Backend.UIA_Provider_Boundary.HRESULT_Status is
        (case Status is
            when A11y.Results.Success |
                 A11y.Results.Accepted_Asynchronous =>
              A11y.Windows_Backend.UIA_Provider_Boundary.S_OK,
            when A11y.Results.Unsupported_Property |
                 A11y.Results.Unsupported_Capability |
                 A11y.Results.Unsupported_Action =>
              A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE,
            when A11y.Results.Node_Unavailable |
                 A11y.Results.Backend_Unavailable |
                 A11y.Results.Accessibility_Service_Unavailable |
                 A11y.Results.Shutting_Down =>
              A11y.Windows_Backend.UIA_Provider_Boundary
                .UIA_E_ELEMENTNOTAVAILABLE,
            when A11y.Results.Disabled =>
              A11y.Windows_Backend.UIA_Provider_Boundary
                .UIA_E_ELEMENTNOTENABLED,
            when A11y.Results.Invalid_Argument |
                 A11y.Results.Invalid_Range =>
              A11y.Windows_Backend.UIA_Provider_Boundary.E_INVALIDARG,
            when A11y.Results.Permission_Denied =>
              A11y.Windows_Backend.UIA_Provider_Boundary.E_ACCESSDENIED,
            when A11y.Results.Out_Of_Resources |
                 A11y.Results.Resource_Limit =>
              A11y.Windows_Backend.UIA_Provider_Boundary.E_OUTOFMEMORY,
            when A11y.Results.Invalid_State |
                 A11y.Results.Read_Only |
                 A11y.Results.Busy |
                 A11y.Results.Timed_Out |
                 A11y.Results.Cancelled =>
              A11y.Windows_Backend.UIA_Provider_Boundary
                .UIA_E_INVALIDOPERATION,
            when A11y.Results.Protocol_Failure |
                 A11y.Results.Native_Failure |
                 A11y.Results.Internal_Error =>
              A11y.Windows_Backend.UIA_Provider_Boundary.E_FAIL);

      Complete : Boolean := True;
   begin
      for Status in A11y.Results.Status_Code loop
         Complete := Complete
           and then
             A11y.Windows_Backend.UIA_Provider_Boundary.HResult_For
               (Status) = Expected (Status)
           and then Class_Expected (Status);
      end loop;
      Check
        (Complete,
         "Windows UIA provider boundary maps every structured status through return classes");
   end;

   declare
      Result : A11y.Results.Result;
      Diagnostic : constant A11y.Diagnostics.Diagnostic :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Diagnostic_For_HResult
          (A11y.Windows_Backend.UIA_Provider_Boundary
             .UIA_E_ELEMENTNOTAVAILABLE,
           Result);
   begin
      Check
        (A11y.Results.Succeeded (Result)
         and then Diagnostic.Class = A11y.Diagnostics.Stale_Native_Query
         and then A11y.Diagnostics.Has_Field
           (Diagnostic, "hresult_name", "UIA_E_ELEMENTNOTAVAILABLE")
         and then A11y.Diagnostics.Has_Field
           (Diagnostic, "hresult_code", "0x80040201")
         and then A11y.Diagnostics.Has_Field
           (Diagnostic, "structured_status", "node-unavailable"),
         "Windows UIA provider boundary creates structured HRESULT diagnostics");
   end;

   declare
      Invalid_Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Snapshot : A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
      Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Query : A11y.Windows_Backend.UIA_Com_Providers.Interface_Query;
      Call : A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Call_Snapshot :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot;
      Count : Natural;
   begin
      A11y.Windows_Backend.UIA_Com_Providers.Initialize
        (Invalid_Provider,
         A11y.Native_Identity.No_Session,
         Root,
         Root,
         Result);
      Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Invalid_Provider);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Snapshot.State =
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Created
         and then Snapshot.References = 0
         and then Snapshot.Node = A11y.Node_Ids.No_Node,
         "Windows UIA COM provider scaffold rejects invalid identity initialization");

      A11y.Windows_Backend.UIA_Com_Providers.Initialize
        (Provider, Session, Root, Root, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.State =
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Alive
         and then Snapshot.References = 1
         and then A11y.Windows_Backend.UIA_Com_Providers.Drained (Provider)
         and then not Snapshot.Host_Window_Bound
         and then Snapshot.Node = Root
         and then Snapshot.Root = Root,
         "Windows UIA COM provider scaffold initializes stable identity");

      Export :=
        A11y.Windows_Backend.UIA_Com_Providers.Export_Descriptor (Provider);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Export.Exportable
         and then Export.Status = A11y.Results.Success
         and then Export.Session = Session
         and then Export.Root = Root
         and then Export.Node = Root
         and then Export.Native_Node_Component =
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Root, Result)
         and then Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers.IUnknown_Interface)
         and then Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers
              .Raw_Element_Provider_Simple)
         and then Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers
              .Raw_Element_Provider_Fragment)
         and then Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers
              .Raw_Element_Provider_Fragment_Root)
         and then Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers
              .Raw_Element_Provider_Advise_Events)
         and then not Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface)
         and then Snapshot.References = 1,
         "Windows UIA COM provider scaffold exports SDK-free descriptors without AddRef");

      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
         Call,
         Result);
      Call_Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Call);
      Check
        (A11y.Results.Succeeded (Result)
         and then Call_Snapshot.Active
         and then Call_Snapshot.Node = Root
         and then Call_Snapshot.Root = Root
         and then Call_Snapshot.Native_Call_Token /= 0
         and then Call_Snapshot.Native_Node_Component =
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Root, Result),
         "Windows UIA COM provider scaffold begins native calls with stable identity");
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Snapshot.Active_Calls = 1
         and then not A11y.Windows_Backend.UIA_Com_Providers.Drained
           (Provider),
         "Windows UIA COM provider scaffold records outstanding native calls");

      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Provider, Call, Result);
      Call_Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Call);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
         (A11y.Results.Succeeded (Result)
         and then not Call_Snapshot.Active
         and then Call_Snapshot.Native_Call_Token = 0
         and then Snapshot.Active_Calls = 0
         and then A11y.Windows_Backend.UIA_Com_Providers.Drained (Provider),
         "Windows UIA COM provider scaffold releases native call admissions");

      A11y.Windows_Backend.UIA_Com_Providers.Query_Interface
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Fragment,
         Query);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Query.Supported
         and then Query.Status = A11y.Results.Success
         and then Snapshot.References = 2,
         "Windows UIA COM provider scaffold AddRefs supported interfaces");

      A11y.Windows_Backend.UIA_Com_Providers.Query_Interface
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Fragment_Root,
         Query);
      Check
        (Query.Supported,
         "Windows UIA COM provider scaffold supports fragment roots only at roots");

      A11y.Windows_Backend.UIA_Com_Providers.Bind_Host_Window_Root
        (Provider, 17, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Host_Window_Bound
         and then Snapshot.Host_Window_Component = 17,
         "Windows UIA COM provider scaffold binds host windows to fragment roots");
      Export :=
        A11y.Windows_Backend.UIA_Com_Providers.Export_Descriptor (Provider);
      Check
        (Export.Exportable
         and then Export.Host_Window_Bound
         and then Export.Host_Window_Component = 17,
         "Windows UIA COM provider scaffold includes host-window binding in export descriptors");

      A11y.Windows_Backend.UIA_Com_Providers.Bind_Host_Window_Root
        (Provider, 17, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA COM provider scaffold treats host-window rebinding as idempotent");

      A11y.Windows_Backend.UIA_Com_Providers.Bind_Host_Window_Root
        (Provider, 18, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Host_Window_Component = 17,
         "Windows UIA COM provider scaffold rejects conflicting host-window roots");

      A11y.Windows_Backend.UIA_Com_Providers.Query_Interface
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Advise_Events,
         Query);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Query.Supported
         and then Query.Status = A11y.Results.Success
         and then Snapshot.References = 4,
         "Windows UIA COM provider scaffold AddRefs advise-event interfaces");

      A11y.Windows_Backend.UIA_Com_Providers.Query_Interface
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface,
         Query);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (not Query.Supported
         and then Query.Status = A11y.Results.Unsupported_Capability
         and then Snapshot.References = 4,
         "Windows UIA COM provider scaffold rejects unsupported interfaces without AddRef");

      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface,
         Call,
         Result);
      Call_Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Call);
      Check
        (Result.Status = A11y.Results.Unsupported_Capability
         and then not Call_Snapshot.Active
         and then Call_Snapshot.Defunct,
         "Windows UIA COM provider scaffold rejects unsupported native calls");

      A11y.Windows_Backend.UIA_Com_Providers.Mark_Defunct (Provider, Result);
      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
         Call,
         Result);
      Call_Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Call);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then not Call_Snapshot.Active
         and then Call_Snapshot.Defunct,
         "Windows UIA COM provider scaffold rejects native calls after defunct");
      Export :=
        A11y.Windows_Backend.UIA_Com_Providers.Export_Descriptor (Provider);
      Check
        (not Export.Exportable
         and then Export.Status = A11y.Results.Node_Unavailable
         and then Export.Defunct,
         "Windows UIA COM provider scaffold rejects defunct export descriptors");

      A11y.Windows_Backend.UIA_Com_Providers.Query_Interface
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.IUnknown_Interface,
         Query);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (not Query.Supported
         and then Query.Status = A11y.Results.Node_Unavailable
         and then Snapshot.References = 4,
         "Windows UIA COM provider scaffold rejects queries after defunct without AddRef");

      A11y.Windows_Backend.UIA_Com_Providers.Release (Provider, Count, Result);
      A11y.Windows_Backend.UIA_Com_Providers.Release (Provider, Count, Result);
      A11y.Windows_Backend.UIA_Com_Providers.Release (Provider, Count, Result);
      A11y.Windows_Backend.UIA_Com_Providers.Release (Provider, Count, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (A11y.Results.Succeeded (Result)
         and then Count = 0
         and then Snapshot.State =
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Destroyed
         and then Snapshot.Defunct,
         "Windows UIA COM provider scaffold destroys exactly at final Release");

      A11y.Windows_Backend.UIA_Com_Providers.Release (Provider, Count, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Count = 0
         and then Snapshot.State =
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Destroyed
         and then Snapshot.Defunct,
         "Windows UIA COM provider scaffold rejects release after destruction");
   end;

   declare
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
   begin
      A11y.Windows_Backend.UIA_Com_Providers.Initialize
        (Provider, Session, Root, Child, Result);
      Export :=
        A11y.Windows_Backend.UIA_Com_Providers.Export_Descriptor (Provider);
      Check
        (Export.Exportable
         and then not Export.Interfaces
           (A11y.Windows_Backend.UIA_Com_Providers
              .Raw_Element_Provider_Fragment_Root),
         "Windows UIA COM provider scaffold omits fragment-root export on non-root fragments");
      A11y.Windows_Backend.UIA_Com_Providers.Bind_Host_Window_Root
        (Provider, 19, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "Windows UIA COM provider scaffold rejects host-window binding on non-root fragments");
   end;

   declare
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Snapshot : A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
      Call : A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Stale_Call : A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Other_Call : A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Call_Snapshot :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot;
      Count : Natural;
      Generation_After_Two_Calls : Natural := 0;
      Generation_After_First_Release : Natural := 0;
   begin
      A11y.Windows_Backend.UIA_Com_Providers.Initialize
        (Provider, Session, Root, Root, Result);
      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
         (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
         Call,
         Result);
      Call_Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Call);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Call_Generation = 1
         and then Call_Snapshot.Native_Call_Generation =
           Snapshot.Call_Generation,
         "Windows UIA COM provider scaffold records native call generations");
      Stale_Call := Call;
      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Fragment,
         Other_Call,
         Result);
      Call_Snapshot :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Other_Call);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Generation_After_Two_Calls := Snapshot.Call_Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Active_Calls = 2
         and then Snapshot.Call_Generation = 2
         and then Call_Snapshot.Native_Call_Generation =
           Snapshot.Call_Generation,
         "Windows UIA COM provider scaffold tracks concurrent native call tokens");
      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Provider, Call, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Generation_After_First_Release := Snapshot.Call_Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Call_Generation > Generation_After_Two_Calls,
         "Windows UIA COM provider scaffold advances generation on native call release");
      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Provider, Stale_Call, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Active_Calls = 1
         and then Snapshot.Call_Generation = Generation_After_First_Release,
         "Windows UIA COM provider scaffold rejects stale copied native call contexts");
      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Provider, Other_Call, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA COM provider scaffold releases the remaining native call after stale rejection");
      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
        (Provider,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
         Call,
         Result);
      A11y.Windows_Backend.UIA_Com_Providers.Release
        (Provider, Count, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (A11y.Results.Succeeded (Result)
         and then Count = 0
         and then Snapshot.State =
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Defunct
         and then Snapshot.Active_Calls = 1
         and then not A11y.Windows_Backend.UIA_Com_Providers.Drained
           (Provider),
         "Windows UIA COM provider scaffold defers destruction during native calls");

      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Provider, Call, Result);
      Snapshot := A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Provider);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.State =
           A11y.Windows_Backend.UIA_Com_Providers.Provider_Destroyed
         and then Snapshot.Active_Calls = 0
         and then A11y.Windows_Backend.UIA_Com_Providers.Drained (Provider),
         "Windows UIA COM provider scaffold destroys after final native call returns");

      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Provider, Call, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "Windows UIA COM provider scaffold rejects duplicate native call release");
   end;

   declare
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
      Count : Natural;
   begin
      A11y.Windows_Backend.UIA_Com_Providers.Initialize
        (Provider, Session, Root, Root, Result);
      for Index in 2 .. A11y.Windows_Backend.UIA_Com_Providers.Max_Reference_Count loop
         A11y.Windows_Backend.UIA_Com_Providers.Add_Ref
           (Provider, Count, Result);
      end loop;
      A11y.Windows_Backend.UIA_Com_Providers.Add_Ref
        (Provider, Count, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Count =
           A11y.Windows_Backend.UIA_Com_Providers.Max_Reference_Count,
         "Windows UIA COM provider scaffold bounds AddRef overflow");
   end;

   declare
      package Registry_API renames
        A11y.Windows_Backend.UIA_Provider_Registry;
      Registry :
        Registry_API.Provider_Registry;
      Id : Registry_API.Provider_Id;
      Again : Registry_API.Provider_Id;
      Other : Registry_API.Provider_Id;
      View :
        Registry_API.Registry_Snapshot;
      Provider_View :
        Registry_API.Provider_Record_Snapshot;
      Call : A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Call_View :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot;
      Report : Registry_API.Registry_Mutation_Report;
      Call_Report : Registry_API.Native_Call_Mutation_Report;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Generation_After_Configure : Natural := 0;
      Generation_After_Ensure : Natural := 0;
      Generation_After_Release : Natural := 0;
      Generation_After_Defunct : Natural := 0;
   begin
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Native_Object_Cache_Size, 2, Result);
      Registry_API.Configure (Registry, Limits, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then View.Capacity = 2
         and then View.Live_Count = 0
         and then View.Generation = 1
         and then View.Outstanding_Calls = 0,
         "Windows UIA provider registry accepts native-object resource limits");
      Generation_After_Configure := View.Generation;

      Registry_API.Ensure_Provider_With_Report
        (Registry, Session, Root, Child, Id, Report, Result);
      Registry_API.Ensure_Provider
        (Registry, Session, Root, Child, Again, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then Registry_API.Is_Valid (Id)
         and then Id = Again
         and then Registry_API.Image (Id) = "1"
         and then View.Live_Count = 1
         and then View.Generation > Generation_After_Configure
         and then View.Outstanding_Calls = 0,
         "Windows UIA provider registry returns stable ids for semantic nodes");
      Check
        (Report.Operation = Registry_API.Registry_Ensure_Provider
         and then Report.Generation_Before = Generation_After_Configure
         and then Report.Generation_After = View.Generation
         and then Report.Live_Before = 0
         and then Report.Live_After = 1
         and then Report.Id = Id
         and then Report.Session = Session
         and then Report.Node = Child
         and then Report.Status = A11y.Results.Success
         and then Report.Generation_Advanced
         and then Report.Live_Changed
         and then not Report.Tombstone_Changed
         and then Report.Provider_Returned,
         "Windows UIA provider registry reports provider creation mutation details");
      Generation_After_Ensure := View.Generation;

      Registry_API.Find_Provider
        (Registry, Session, Child, Provider_View, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Provider_View.Id = Id
         and then Provider_View.Registry_Generation = View.Generation
         and then Provider_View.Provider.Node = Child
         and then Provider_View.Provider.Root = Root,
         "Windows UIA provider registry finds providers by stable Node_Id");

      Boundary_Request.Kind :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action;
      Boundary_Request.Action := A11y.Actions.Press;
      Boundary_Request.Has_Native_Identity := False;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
          (Registry,
           Session,
           Id,
           A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
           Boundary_Request,
           Snapshots.all,
           Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "Windows UIA registered native boundary dispatches and drains successful provider calls");
      Check
        (Registered_Boundary_Report.Interface_Supported
         and then Registered_Boundary_Report.Resolved
         and then Registered_Boundary_Report.Native_Identity_Prepared
         and then Registered_Boundary_Report.Native_Admitted
         and then Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Begin_Report.Operation =
           Registry_API.Registry_Begin_Native_Call
         and then Registered_Boundary_Report.Begin_Report
           .Outstanding_Before = 0
         and then Registered_Boundary_Report.Begin_Report
           .Outstanding_After = 1
         and then Registered_Boundary_Report.End_Report.Operation =
           Registry_API.Registry_End_Native_Call
         and then Registered_Boundary_Report.End_Report.Outstanding_Before = 1
         and then Registered_Boundary_Report.End_Report.Outstanding_After = 0
         and then not Registered_Boundary_Report.End_Report.Call_Active
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Success
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Success,
         "Windows UIA registered native boundary reports begin and end call lifecycle");

      Snapshots.Action_Node := Root;
      Boundary_Request.Kind :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action;
      Boundary_Request.Action := A11y.Actions.Press;
      Boundary_Request.Has_Native_Identity := False;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
          (Registry,
           Session,
           Id,
           A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
           Boundary_Request,
           Snapshots.all,
           Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary
             .UIA_E_ELEMENTNOTAVAILABLE
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "Windows UIA registered native boundary rejects identity mismatches before provider admission");
      Check
        (Registered_Boundary_Report.Interface_Supported
         and then Registered_Boundary_Report.Resolved
         and then Registered_Boundary_Report.Native_Identity_Prepared
         and then not Registered_Boundary_Report.Native_Admitted
         and then not Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Node_Unavailable
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Node_Unavailable,
         "Windows UIA registered native boundary reports identity mismatch rejection before begin-call");
      Snapshots.Action_Node := Child;

      Boundary_Request.Kind :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
      Boundary_Request.Direction :=
        A11y.Windows_Backend.UIA_Fragments.Parent;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
          (Registry,
           Session,
           Id,
           A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
           Boundary_Request,
           Snapshots.all,
           Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE
         and then Boundary_Reply.Status =
           A11y.Results.Unsupported_Capability
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "Windows UIA registered native boundary rejects fragment calls through the simple interface");
      Check
        (not Registered_Boundary_Report.Interface_Supported
         and then not Registered_Boundary_Report.Resolved
         and then not Registered_Boundary_Report.Native_Admitted
         and then not Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Unsupported_Capability
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Unsupported_Capability,
         "Windows UIA registered native boundary reports unsupported interface rejection before admission");

      Snapshots.Fragment.Node := Child;
      Boundary_Request.Kind :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Navigate_Fragment;
      Boundary_Request.Direction :=
        A11y.Windows_Backend.UIA_Fragments.Parent;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Registered_Native_Request
          (Registry,
           Session,
           Id,
           A11y.Windows_Backend.UIA_Com_Providers
             .Raw_Element_Provider_Fragment,
           Boundary_Request,
           Snapshots.all);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Boundary_Reply.Routed = Fragment_Node
         and then Boundary_Reply.Payload.Kind = Fragment_Node
         and then Boundary_Reply.Payload.Node = Root
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "Windows UIA registered native boundary preserves fragment navigation payloads");

      Boundary_Request.Kind :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Get_Runtime_Id;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Dispatch_Registered_Native_Request
          (Registry,
           Session,
           Id,
           A11y.Windows_Backend.UIA_Com_Providers
             .Raw_Element_Provider_Fragment,
           Boundary_Request,
           Snapshots.all);
      View := Registry_API.Snapshot (Registry);
      declare
         Root_Result : A11y.Results.Result;
         Node_Result : A11y.Results.Result;
         Root_Component : constant Natural :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Root, Root_Result);
         Node_Component : constant Natural :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Child, Node_Result);
      begin
         Check
           (A11y.Results.Succeeded (Root_Result)
            and then A11y.Results.Succeeded (Node_Result)
            and then Boundary_Reply.Kind =
              A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
            and then Boundary_Reply.HResult =
              A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
            and then Boundary_Reply.Routed = Runtime_Id
            and then Boundary_Reply.Payload.Kind = Runtime_Id
            and then Boundary_Reply.Payload.Id.Session_Component =
              A11y.Native_Identity.To_Natural (Session)
            and then Boundary_Reply.Payload.Id.Root_Component =
              Root_Component
            and then Boundary_Reply.Payload.Id.Node_Component =
              Node_Component
            and then View.Outstanding_Calls = 0
            and then View.Generation = Generation_After_Ensure,
            "Windows UIA registered native boundary preserves runtime identifier payloads");
      end;
      Snapshots.Fragment.Node := Root;

      Boundary_Request.Kind :=
        A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action;
      Boundary_Request.Action := A11y.Actions.Select_Item;
      Boundary_Reply :=
        A11y.Windows_Backend.UIA_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
          (Registry,
           Session,
           Id,
           A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
           Boundary_Request,
           Snapshots.all,
           Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
         and then Boundary_Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE
         and then Boundary_Reply.Status = A11y.Results.Unsupported_Action
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "Windows UIA registered native boundary drains provider calls after routed errors");
      Check
        (Registered_Boundary_Report.Interface_Supported
         and then Registered_Boundary_Report.Resolved
         and then Registered_Boundary_Report.Native_Admitted
         and then Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Unsupported_Action
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Unsupported_Action,
         "Windows UIA registered native boundary reports routed-error statuses after drain");

      Registry_API.Begin_Native_Call_With_Report
        (Registry,
         Session,
         Id,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
         Call,
         Call_Report,
         Result);
      Call_View :=
        A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Call);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then Call_View.Active
         and then Call_View.Node = Child
         and then View.Outstanding_Calls = 1
         and then View.Generation = Generation_After_Ensure
         and then not Registry_API.Drained (Registry),
         "Windows UIA provider registry admits native calls through provider ids");
      Check
        (Call_Report.Operation = Registry_API.Registry_Begin_Native_Call
         and then Call_Report.Generation_Before = Generation_After_Ensure
         and then Call_Report.Generation_After = Generation_After_Ensure
         and then Call_Report.Outstanding_Before = 0
         and then Call_Report.Outstanding_After = 1
         and then Call_Report.Outstanding_Changed
         and then not Call_Report.Generation_Changed
         and then Call_Report.Id = Id
         and then Call_Report.Session = Session
         and then Call_Report.Node = Child
         and then Call_Report.Requested =
           A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple
         and then Call_Report.Context.Active
         and then Call_Report.Call_Active
         and then Call_Report.Status = A11y.Results.Success,
         "Windows UIA provider registry reports native-call admission details");

      Registry_API.Release_With_Report (Registry, Session, Id, Report, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then View.Live_Count = 0
         and then View.Tombstones = 1
         and then View.Outstanding_Calls = 1
         and then View.Generation > Generation_After_Ensure
         and then not Registry_API.Drained (Registry),
         "Windows UIA provider registry defers released providers while calls drain");
      Check
        (Report.Operation = Registry_API.Registry_Release_Provider
         and then Report.Generation_Before = Generation_After_Ensure
         and then Report.Generation_After = View.Generation
         and then Report.Live_Before = 1
         and then Report.Live_After = 0
         and then Report.Tombstones_Before = 0
         and then Report.Tombstones_After = 1
         and then Report.Outstanding_Before = 1
         and then Report.Outstanding_After = 1
         and then Report.Id = Id
         and then Report.Node = Child
         and then Report.Status = A11y.Results.Success
         and then Report.Generation_Advanced
         and then Report.Live_Changed
         and then Report.Tombstone_Changed
         and then not Report.Outstanding_Changed
         and then Report.Provider_Returned,
         "Windows UIA provider registry reports provider release mutation details");
      Generation_After_Release := View.Generation;

      Registry_API.Reset_When_Drained_With_Report (Registry, Report, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (Result.Status = A11y.Results.Busy
         and then View.Tombstones = 1
         and then View.Generation = Generation_After_Release
         and then not Registry_API.Drained (Registry),
         "Windows UIA provider registry rejects checked reset while calls drain");
      Check
        (Report.Operation = Registry_API.Registry_Reset
         and then Report.Generation_Before = Generation_After_Release
         and then Report.Generation_After = Generation_After_Release
         and then Report.Status = A11y.Results.Busy
         and then not Report.Generation_Advanced,
         "Windows UIA provider registry reports busy checked reset without mutation");

      Registry_API.Reset (Registry);
      View := Registry_API.Snapshot (Registry);
      Check
        (View.Tombstones = 1
         and then View.Outstanding_Calls = 1
         and then View.Generation = Generation_After_Release
         and then not Registry_API.Drained (Registry),
         "Windows UIA provider registry bare reset preserves pinned calls");

      Registry_API.End_Native_Call_With_Report
        (Registry, Session, Id, Call, Call_Report, Result);
      View := Registry_API.Snapshot (Registry);
      Registry_API.Resolve_Provider
        (Registry, Session, Id, Provider_View, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Release,
         "Windows UIA provider registry rejects stale provider ids after release");
      Check
        (Call_Report.Operation = Registry_API.Registry_End_Native_Call
         and then Call_Report.Generation_Before = Generation_After_Release
         and then Call_Report.Generation_After = Generation_After_Release
         and then Call_Report.Outstanding_Before = 1
         and then Call_Report.Outstanding_After = 0
         and then Call_Report.Outstanding_Changed
         and then not Call_Report.Generation_Changed
         and then Call_Report.Id = Id
         and then Call_Report.Session = Session
         and then Call_Report.Node = Child
         and then not Call_Report.Context.Active
         and then not Call_Report.Call_Active
         and then Call_Report.Status = A11y.Results.Success,
         "Windows UIA provider registry reports native-call release details");
      Check
        (Registry_API.Drained (Registry),
         "Windows UIA provider registry reports drained after native calls return");

      Registry_API.Ensure_Provider
        (Registry, Session, Root, Root, Other, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Registry_API.To_Natural (Other) = 2,
         "Windows UIA provider registry does not reuse released ids");
      View := Registry_API.Snapshot (Registry);
      Generation_After_Ensure := View.Generation;

      Registry_API.Ensure_Provider
        (Registry, Session, Root, A11y.Node_Ids.From_Natural (777), Again,
         Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then View.Generation = Generation_After_Ensure,
         "Windows UIA provider registry enforces configured provider capacity");

      Registry_API.Mark_Defunct (Registry, Session, Root, Result);
      View := Registry_API.Snapshot (Registry);
      Generation_After_Defunct := View.Generation;
      Registry_API.Begin_Native_Call_With_Report
        (Registry,
         Session,
         Other,
         A11y.Windows_Backend.UIA_Com_Providers.Raw_Element_Provider_Simple,
         Call,
         Call_Report,
         Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then View.Generation > Generation_After_Ensure
         and then Call_Report.Operation = Registry_API.Registry_Begin_Native_Call
         and then Call_Report.Status = A11y.Results.Node_Unavailable
         and then not Call_Report.Call_Active
         and then not Call_Report.Outstanding_Changed,
         "Windows UIA provider registry rejects native calls after defunct");

      Registry_API.Reset_When_Drained_With_Report (Registry, Report, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then View.Live_Count = 0
         and then View.Tombstones = 0
         and then View.Outstanding_Calls = 0
         and then View.Next_Id = 1
         and then View.Generation > Generation_After_Defunct
         and then Registry_API.Drained (Registry),
         "Windows UIA provider registry checked reset clears drained session ids");
      Check
        (Report.Operation = Registry_API.Registry_Reset
         and then Report.Generation_Before = Generation_After_Defunct
         and then Report.Generation_After = View.Generation
         and then Report.Live_Before = 0
         and then Report.Live_After = 0
         and then Report.Tombstones_Before = 2
         and then Report.Tombstones_After = 0
         and then Report.Status = A11y.Results.Success
         and then Report.Generation_Advanced
         and then Report.Tombstone_Changed
         and then not Report.Provider_Returned,
         "Windows UIA provider registry reports drained reset mutation details");
      Registry_API.Find_Provider
        (Registry, Session, Root, Provider_View, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Provider_View.Id = Registry_API.No_Provider,
         "Windows UIA provider registry rejects node lookup after drained reset");
      Registry_API.Resolve_Provider
        (Registry, Session, Other, Provider_View, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Provider_View.Id = Registry_API.No_Provider,
         "Windows UIA provider registry rejects stale provider ids after drained reset");
   end;

   declare
      Value : A11y.Windows_Backend.UIA_Native_Values.Native_Value;
      Snapshot : A11y.Windows_Backend.UIA_Native_Values.Native_Value_Snapshot;
      Items : A11y.Windows_Backend.UIA_Native_Values.UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
        ("provider name", Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.BSTR_Value
         and then Snapshot.Owned
         and then Snapshot.Length = 13
         and then A11y.Windows_Backend.UIA_Native_Values.BSTR_Text (Value) =
           "provider name",
         "Windows UIA native value scaffold owns bounded BSTR text");

      Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
        ("", Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.BSTR_Value
         and then Snapshot.Owned
         and then Snapshot.Length = 0
         and then A11y.Windows_Backend.UIA_Native_Values.BSTR_Text (Value) =
           "",
         "Windows UIA native value scaffold distinguishes supported empty BSTR text");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_String_Size,
         4,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA native value fixture sets BSTR resource limit");
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
        ("name", Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.BSTR_Value
         and then Snapshot.Length = 4,
         "Windows UIA native value scaffold accepts configured-limit BSTR text");
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
        ("names", Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value
         and then Snapshot.Length = 0,
         "Windows UIA native value scaffold enforces configured BSTR limits");

      Limits.Limits (A11y.Resource_Limits.Native_String_Size) :=
        A11y.Resource_Limits.Limit_Value
          (A11y.Windows_Backend.UIA_Native_Values.Max_BSTR_Length + 1);
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
        ("x", Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value
         and then Snapshot.Length = 0,
         "Windows UIA native value scaffold rejects impossible BSTR limits");
      Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
        ("x", Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value,
         "Windows UIA native value scaffold rejects invalid BSTR limit configs");
      Limits := A11y.Resource_Limits.Default_Config;

      declare
         Oversized_Text : constant String
           (1 .. A11y.Windows_Backend.UIA_Native_Values.Max_BSTR_Length + 1) :=
             [others => 'x'];
      begin
         Value := A11y.Windows_Backend.UIA_Native_Values.Make_BSTR
           (Oversized_Text, Result);
         Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then Snapshot.Kind =
              A11y.Windows_Backend.UIA_Native_Values.Empty_Value
            and then not Snapshot.Owned
            and then Snapshot.Length = 0,
            "Windows UIA native value scaffold rejects oversized BSTR text");
      end;

      A11y.Windows_Backend.UIA_Native_Values.Clear (Value, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value
         and then not Snapshot.Owned
         and then Snapshot.Length = 0,
         "Windows UIA native value scaffold clears owned BSTR text");

      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32 (42);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.UInt32_Value
         and then Snapshot.Status = A11y.Results.Success
         and then Snapshot.UInt32_Item = 42,
         "Windows UIA native value scaffold accepts representable UInt32 values");

      declare
         function Max_UInt32 return Long_Long_Integer is (4_294_967_295);
         pragma No_Inline (Max_UInt32);
      begin
         if Long_Long_Integer (Natural'Last) > Max_UInt32 then
            Value :=
              A11y.Windows_Backend.UIA_Native_Values.Make_UInt32
                (Natural (Max_UInt32 + 1));
            Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
            Check
              (Snapshot.Kind =
                 A11y.Windows_Backend.UIA_Native_Values.Empty_Value
               and then Snapshot.Status = A11y.Results.Resource_Limit,
               "Windows UIA native value scaffold rejects oversized UInt32 values");
         end if;
      end;

      Items.Clear;
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
        (Items, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.UInt32_SAFEARRAY_Value
         and then Snapshot.Owned
         and then Snapshot.Count = 0
         and then
           Natural
             (A11y.Windows_Backend.UIA_Native_Values.SAFEARRAY_Items
                (Value).Length) = 0,
         "Windows UIA native value scaffold distinguishes supported empty SAFEARRAY data");

      Items.Append (42);
      Items.Append (A11y.Node_Ids.To_Natural (Root));
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
        (Items, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.UInt32_SAFEARRAY_Value
         and then Snapshot.Owned
         and then Snapshot.Count = 2
         and then
           Natural
             (A11y.Windows_Backend.UIA_Native_Values.SAFEARRAY_Items
                (Value).Length) = 2,
         "Windows UIA native value scaffold owns bounded SAFEARRAY data");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_Array_Size,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Windows UIA native value fixture sets SAFEARRAY resource limit");
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
        (Items, Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value
         and then Snapshot.Count = 0,
         "Windows UIA native value scaffold enforces configured SAFEARRAY limits");

      Limits.Limits (A11y.Resource_Limits.Native_Array_Size) :=
        A11y.Resource_Limits.Limit_Value
          (A11y.Windows_Backend.UIA_Native_Values.Max_SAFEARRAY_Length + 1);
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
        (Items, Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value
         and then Snapshot.Count = 0,
         "Windows UIA native value scaffold rejects impossible SAFEARRAY limits");
      Limits.Limits (A11y.Resource_Limits.Native_Array_Size) := 0;
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
        (Items, Limits, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value,
         "Windows UIA native value scaffold rejects invalid SAFEARRAY limit configs");
      Limits := A11y.Resource_Limits.Default_Config;

      Items.Clear;
      for Index in 1 ..
        A11y.Windows_Backend.UIA_Native_Values.Max_SAFEARRAY_Length + 1
      loop
         Items.Append (Index);
      end loop;
      Value := A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
        (Items, Result);
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Empty_Value
         and then not Snapshot.Owned
         and then Snapshot.Count = 0,
         "Windows UIA native value scaffold rejects oversized SAFEARRAY data");

      declare
         function Max_UInt32 return Long_Long_Integer is (4_294_967_295);
         pragma No_Inline (Max_UInt32);
      begin
         if Long_Long_Integer (Natural'Last) > Max_UInt32 then
            Items.Clear;
            Items.Append (Natural (Max_UInt32 + 1));
            Value :=
              A11y.Windows_Backend.UIA_Native_Values.Make_UInt32_SAFEARRAY
                (Items, Result);
            Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
            Check
              (Result.Status = A11y.Results.Resource_Limit
               and then Snapshot.Kind =
                 A11y.Windows_Backend.UIA_Native_Values.Empty_Value
               and then not Snapshot.Owned
               and then Snapshot.Count = 0,
               "Windows UIA native value scaffold rejects oversized SAFEARRAY UInt32 items");
         end if;
      end;

      Value := A11y.Windows_Backend.UIA_Native_Values.Make_Not_Supported;
      Snapshot := A11y.Windows_Backend.UIA_Native_Values.Snapshot (Value);
      Check
        (Snapshot.Kind =
           A11y.Windows_Backend.UIA_Native_Values.Not_Supported_Value
         and then Snapshot.Status = A11y.Results.Unsupported_Property
         and then not Snapshot.Owned,
         "Windows UIA native value scaffold distinguishes not-supported values");
   end;

   declare
      package Bridge renames A11y.Windows_Backend.UIA_Bridge_Audit;

      Query : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Query_Interface_Callback);
      Add_Ref : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Add_Ref_Callback);
      Method : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Provider_Method_Callback);
      Frame_Method : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Provider_Method_Frame_Callback);
      Full_Frame_Method : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Provider_Method_Full_Frame_Callback);
      BSTR_Copy : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Copy_BSTR);
      BSTR_Destroy : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Destroy_BSTR);
      Array_Copy : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Copy_UInt32_SAFEARRAY);
      Array_Destroy : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Destroy_SAFEARRAY);
      HRESULT_Map : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Translate_HResult);
      Bridge_Target : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Bridge_Target_Probe);
      Client_Runtime_Probe : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Client_Runtime_Probe);
      Host_Window_Probe : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Host_Window_Handshake_Probe);
      Minimal_Provider_Probe : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Minimal_Provider_Host_Window_Probe);
      Callback_Provider_Probe : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Callback_Provider_Host_Window_Probe);
      Query_Entry : constant
        A11y.Windows_Backend.UIA_COM_Exports.Native_Bridge_Entry :=
          A11y.Windows_Backend.UIA_COM_Exports.Bridge_Entry
            (A11y.Windows_Backend.UIA_COM_Exports.Query_Interface_Slot);
      Method_Entry : constant
        A11y.Windows_Backend.UIA_COM_Exports.Native_Bridge_Entry :=
          A11y.Windows_Backend.UIA_COM_Exports.Bridge_Entry
            (A11y.Windows_Backend.UIA_COM_Exports.Provider_Method_Slot);

      function Runtime_Size (Value : Natural) return Natural is
      begin
         return Value;
      end Runtime_Size;

      function Runtime_Int32
        (Value : Interfaces.Integer_32)
         return Interfaces.Integer_32 is
      begin
         return Value;
      end Runtime_Int32;
   begin
      Check
        (Runtime_Size
           (A11y.Windows_Backend.UIA_Native_Bridge.Native_HResult'Size) = 32
         and then Runtime_Size
           (A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32'Size) = 32
         and then Runtime_Size
           (A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64'Size) = 64
         and then
           Runtime_Size
             (A11y.Windows_Backend.UIA_Native_Bridge
                .Native_UTF16_Unit'Size) = 16
         and then
           Runtime_Int32
             (Interfaces.Integer_32
                (A11y.Windows_Backend.UIA_Native_Bridge.E_Fail)) =
                  -2_147_467_259,
         "Windows UIA native bridge binding preserves C ABI scalar sizes");
      Check
        (Bridge.All_Operations_Audited,
         "Windows UIA COM bridge audit covers every ABI operation");
      Check
        (Query_Entry.ABI_Only
         and then Query_Entry.Operation = Bridge.Query_Interface_Callback
         and then Bridge.Operation_Name (Query_Entry.Symbol) =
           "a11y_uia_query_interface"
         and then not Query_Entry.Dispatches_Provider_Method
         and then Method_Entry.ABI_Only
         and then Method_Entry.Operation = Bridge.Provider_Method_Callback
         and then Bridge.Operation_Name (Method_Entry.Symbol) =
           "a11y_uia_dispatch_provider_method"
         and then Method_Entry.Dispatches_Provider_Method,
         "Windows UIA COM export table records native bridge entry symbols");
      Check
        (Bridge.Operation_Name (Bridge.Provider_Method_Callback) =
           "a11y_uia_dispatch_provider_method"
         and then Bridge.Operation_Name
           (Bridge.Provider_Method_Frame_Callback) =
             "a11y_uia_dispatch_provider_frame"
         and then Bridge.Operation_Name
           (Bridge.Provider_Method_Full_Frame_Callback) =
             "a11y_uia_dispatch_provider_full_frame"
         and then Bridge.Operation_Name (Bridge.Copy_UInt32_SAFEARRAY) =
           "a11y_uia_copy_uint32_safearray"
         and then Bridge.Operation_Name (Bridge.Bridge_Target_Probe) =
           "a11y_uia_bridge_is_windows"
         and then Bridge.Operation_Name (Bridge.Client_Runtime_Probe) =
           "a11y_uia_probe_client_runtime"
         and then Bridge.Operation_Name
           (Bridge.Minimal_Provider_Host_Window_Probe) =
             "a11y_uia_probe_minimal_provider_host_window"
         and then Bridge.Operation_Name
           (Bridge.Callback_Provider_Host_Window_Probe) =
             "a11y_uia_probe_callback_provider_host_window",
         "Windows UIA COM bridge audit names native callback and SAFEARRAY helpers");
      Check
        (Bridge.Bounded_Limit (Bridge.Copy_BSTR) =
           A11y.Windows_Backend.UIA_Native_Values.Max_BSTR_Length
         and then Bridge.Bounded_Limit (Bridge.Copy_UInt32_SAFEARRAY) =
           A11y.Windows_Backend.UIA_Native_Values.Max_SAFEARRAY_Length
         and then Bridge.Bounded_Limit (Bridge.Query_Interface_Callback) = 0,
         "Windows UIA COM bridge audit exposes native conversion limits");
      Check
        (Query.Allowed
         and then Query.Ownership = Bridge.No_Ownership_Transfer
         and then Query.Exception_Behavior = Bridge.Contain_Ada_Exception
         and then Query.Calling_Convention = Bridge.C_ABI_Callback
         and then Query.Nullability = Bridge.Nullable_Native_Handle
         and then Query.Lifetime = Bridge.Callback_Frame_Ephemeral
         and then Query.Representation = Bridge.Opaque_Integer_Handles
         and then not Query.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains QueryInterface callbacks");
      Check
        (Add_Ref.Allowed
         and then Add_Ref.Ownership = Bridge.Balanced_AddRef_Release
         and then Add_Ref.Exception_Behavior = Bridge.Contain_Ada_Exception
         and then Add_Ref.Calling_Convention = Bridge.C_ABI_Callback
         and then Add_Ref.Lifetime = Bridge.Balanced_Reference_Lifetime
         and then not Add_Ref.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains AddRef and Release callbacks");
      Check
        (Method.Allowed
         and then Method.Threading = Bridge.Provider_Apartment_Required
         and then Method.Exception_Behavior = Bridge.Contain_Ada_Exception
         and then Method.Calling_Convention = Bridge.C_ABI_Callback
         and then Method.Lifetime = Bridge.Callback_Frame_Ephemeral
         and then not Method.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains provider method callbacks");
      Check
        (Frame_Method.Allowed
         and then Frame_Method.Threading = Bridge.Provider_Apartment_Required
         and then Frame_Method.Exception_Behavior = Bridge.Contain_Ada_Exception
         and then Frame_Method.Calling_Convention = Bridge.C_ABI_Callback
         and then Frame_Method.Lifetime = Bridge.Callback_Frame_Ephemeral
         and then not Frame_Method.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains provider frame callbacks");
      Check
        (Full_Frame_Method.Allowed
         and then Full_Frame_Method.Threading =
           Bridge.Provider_Apartment_Required
         and then Full_Frame_Method.Exception_Behavior =
           Bridge.Contain_Ada_Exception
         and then Full_Frame_Method.Calling_Convention = Bridge.C_ABI_Callback
         and then Full_Frame_Method.Lifetime =
           Bridge.Callback_Frame_Ephemeral
         and then Full_Frame_Method.Representation =
           Bridge.Opaque_Integer_Handles
         and then not Full_Frame_Method.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains full provider frame callbacks");
      Check
        (BSTR_Copy.Allowed
         and then BSTR_Copy.Ownership = Bridge.Caller_Owns_Return
         and then BSTR_Copy.Exception_Behavior = Bridge.No_Exception_Boundary
         and then BSTR_Copy.Calling_Convention = Bridge.C_ABI_Helper
         and then BSTR_Copy.Nullability = Bridge.Nullable_Return_On_Failure
         and then BSTR_Copy.Lifetime = Bridge.Native_Value_Must_Be_Destroyed
         and then BSTR_Copy.Representation = Bridge.Bounded_UTF16_Value
         and then not BSTR_Copy.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains BSTR creation helpers");
      Check
        (BSTR_Destroy.Allowed
         and then BSTR_Destroy.Ownership = Bridge.Callee_Consumes_Argument
         and then BSTR_Destroy.Exception_Behavior = Bridge.No_Exception_Boundary
         and then BSTR_Destroy.Nullability = Bridge.Nullable_Native_Handle
         and then BSTR_Destroy.Lifetime = Bridge.Native_Value_Must_Be_Destroyed
         and then BSTR_Destroy.Representation = Bridge.Bounded_UTF16_Value
         and then not BSTR_Destroy.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains BSTR destruction helpers");
      Check
        (Array_Copy.Allowed
         and then Array_Copy.Ownership = Bridge.Caller_Owns_Return
         and then Array_Copy.Nullability = Bridge.Nullable_Return_On_Failure
         and then Array_Copy.Lifetime = Bridge.Native_Value_Must_Be_Destroyed
         and then Array_Copy.Representation = Bridge.Bounded_UInt32_Array
         and then Array_Destroy.Ownership = Bridge.Callee_Consumes_Argument
         and then Array_Destroy.Lifetime =
           Bridge.Native_Value_Must_Be_Destroyed,
         "Windows UIA COM bridge audit records SAFEARRAY lifetime assumptions");
      Check
        (HRESULT_Map.Allowed
         and then HRESULT_Map.Ownership = Bridge.No_Ownership_Transfer
         and then HRESULT_Map.Exception_Behavior = Bridge.No_Exception_Boundary
         and then HRESULT_Map.Calling_Convention = Bridge.C_ABI_Helper
         and then HRESULT_Map.Nullability = Bridge.No_Null_Values
         and then HRESULT_Map.Lifetime = Bridge.No_Durable_State
         and then HRESULT_Map.Representation = Bridge.Stable_HResult_Code
         and then not HRESULT_Map.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains HRESULT translation helpers");
      Check
        (Bridge_Target.Allowed
         and then Bridge_Target.Ownership = Bridge.No_Ownership_Transfer
         and then Bridge_Target.Exception_Behavior =
           Bridge.No_Exception_Boundary
         and then Bridge_Target.Calling_Convention = Bridge.C_ABI_Helper
         and then Bridge_Target.Nullability = Bridge.No_Null_Values
         and then Bridge_Target.Lifetime = Bridge.No_Durable_State
         and then Bridge_Target.Representation = Bridge.Stable_HResult_Code
         and then not Bridge_Target.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains target-runtime probe");
      Check
        (Client_Runtime_Probe.Allowed
         and then Client_Runtime_Probe.Ownership =
           Bridge.No_Ownership_Transfer
         and then Client_Runtime_Probe.Threading = Bridge.Any_COM_Apartment
         and then Client_Runtime_Probe.Exception_Behavior =
           Bridge.No_Exception_Boundary
         and then Client_Runtime_Probe.Calling_Convention =
           Bridge.C_ABI_Helper
         and then Client_Runtime_Probe.Lifetime = Bridge.No_Durable_State
         and then not Client_Runtime_Probe.Accessibility_Policy
         and then Host_Window_Probe.Allowed
         and then Host_Window_Probe.Lifetime = Bridge.No_Durable_State
         and then not Host_Window_Probe.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains runtime smoke probes");
      Check
        (Minimal_Provider_Probe.Allowed
         and then Minimal_Provider_Probe.Threading =
           Bridge.Any_COM_Apartment
         and then Minimal_Provider_Probe.Exception_Behavior =
           Bridge.No_Exception_Boundary
         and then Minimal_Provider_Probe.Calling_Convention =
           Bridge.C_ABI_Helper
         and then Minimal_Provider_Probe.Lifetime =
           Bridge.Balanced_Reference_Lifetime
         and then Minimal_Provider_Probe.Representation =
           Bridge.Opaque_Integer_Handles
         and then not Minimal_Provider_Probe.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains minimal provider smoke probe");
      Check
        (Callback_Provider_Probe.Allowed
         and then Callback_Provider_Probe.Threading =
           Bridge.Any_COM_Apartment
         and then Callback_Provider_Probe.Exception_Behavior =
           Bridge.No_Exception_Boundary
         and then Callback_Provider_Probe.Calling_Convention =
           Bridge.C_ABI_Helper
         and then Callback_Provider_Probe.Lifetime =
           Bridge.Balanced_Reference_Lifetime
         and then Callback_Provider_Probe.Representation =
           Bridge.Opaque_Integer_Handles
         and then not Callback_Provider_Probe.Accessibility_Policy,
         "Windows UIA COM bridge audit constrains callback provider smoke probe");
   end;

   declare
      package ABI renames A11y.Windows_Backend.UIA_ABI_Surface;
      package Bridge renames A11y.Windows_Backend.UIA_Bridge_Audit;
      package COM renames A11y.Windows_Backend.UIA_Com_Providers;
      package Exports renames A11y.Windows_Backend.UIA_COM_Exports;
      package Live renames A11y.Windows_Backend.UIA_COM_Live_Exports;
      package Native_Callbacks renames
        A11y.Windows_Backend.UIA_Native_Callbacks;
      package Native_Bridge renames A11y.Windows_Backend.UIA_Native_Bridge;
      package Registry renames A11y.Windows_Backend.UIA_Provider_Registry;

      type Native_Frame_Buffer is
        array (Natural range 0 .. 7) of aliased Native_Bridge.Native_UInt64;

      Registry_Object : aliased Registry.Provider_Registry;
      Provider : COM.Provider_Object;
      Child_Provider : COM.Provider_Object;
      Export : COM.Provider_Export_Descriptor;
      Table : Exports.COM_Export_Table;
      Root_Table : Exports.COM_Export_Table;
      Invalid_Table : Exports.COM_Export_Table;
      Reply : A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;
      Invoke_Report : Exports.Method_Invoke_Report;
      Frame : Exports.ABI_Callback_Frame;
      Frame_Report : Exports.ABI_Callback_Report;
      Object : A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
      Child_Object :
        A11y.Windows_Backend.UIA_COM_VTables.COM_Object_Descriptor;
      Interface_Slot :
        A11y.Windows_Backend.UIA_COM_VTables.Interface_Slot_Descriptor;
      Query_Plan :
        A11y.Windows_Backend.UIA_COM_VTables.Interface_Query_Plan;
      Frame_Plan :
        A11y.Windows_Backend.UIA_COM_VTables.Callback_Frame_Plan;
      Object_Exports : aliased
        A11y.Windows_Backend.UIA_COM_Object_Exports
          .COM_Object_Export_Table;
      Object_Export_Report :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Export_Report;
      Object_Resolve_Report :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Resolve_Report;
      Object_Release_Report :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Release_Report;
      Object_Table_Snapshot :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Export_Table_Snapshot;
      Released_Object_Token :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token :=
          A11y.Windows_Backend.UIA_COM_Object_Exports.No_COM_Object;
      Live_Object_Token :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token :=
          A11y.Windows_Backend.UIA_COM_Object_Exports.No_COM_Object;
      Interface_Query : Live.Interface_Query_Report;
      Unsupported_Interface_Query : Live.Interface_Query_Report;
      Released_Interface_Query : Live.Interface_Query_Report;
      Simple_Interface : Live.UIA_Interface_Reference;
      Released_Simple_Interface : Live.UIA_Interface_Reference;
      Fragment_Interface : Live.UIA_Interface_Reference;
      Add_Ref_Report : Live.Interface_Lifetime_Report;
      First_Release_Report : Live.Interface_Lifetime_Report;
      Second_Release_Report : Live.Interface_Lifetime_Report;
      Third_Release_Report : Live.Interface_Lifetime_Report;
      Released_Interface_Dispatch_Report : Live.Interface_Dispatch_Report;
      Live_Dispatch_Report : Live.Interface_Dispatch_Report;
      Rejected_Live_Dispatch_Report : Live.Interface_Dispatch_Report;
      Live_Frame : Live.ABI_Interface_Frame;
      Live_Frame_Report : Live.ABI_Interface_Frame_Report;
      Rejected_Live_Frame_Report : Live.ABI_Interface_Frame_Report;
      Native_Callback_Context : aliased Native_Callbacks.Callback_Context;
      Native_Frame : Native_Frame_Buffer := [others => 0];
      Native_Frame_Result : Native_Bridge.Native_UInt32 := 0;
      Id : Registry.Provider_Id := Registry.No_Provider;
      Child_Id : Registry.Provider_Id := Registry.No_Provider;
      Result : A11y.Results.Result;
   begin
      Registry.Ensure_Provider
        (Registry_Object, Session, Root, Root, Id, Result);
      COM.Initialize (Provider, Session, Root, Root, Result);
      Export := COM.Export_Descriptor (Provider);
      Table := Exports.Build_Export_Table (Id, Export);
      Check
        (Table.Exportable
         and then Table.Status = A11y.Results.Success
         and then Table.Provider = Id
         and then Table.Session = Session
         and then Table.Root = Root
         and then Table.Node = Root
         and then Table.Native_Node_Component = Export.Native_Node_Component
         and then Table.Dispatchable_Methods > 0,
         "Windows UIA COM export table preserves stable provider identity");
      Check
        (Exports.Can_Invoke_Callback
           (Table, Exports.Query_Interface_Slot)
         and then Exports.Can_Invoke_Callback (Table, Exports.Add_Ref_Slot)
         and then Exports.Can_Invoke_Callback (Table, Exports.Release_Slot)
         and then Exports.Can_Invoke_Callback
           (Table, Exports.Provider_Method_Slot)
         and then Exports.All_Callbacks_Audited (Table),
         "Windows UIA COM export table exposes only audited bridge callbacks");
      Check
        (Exports.Callback_Name (Exports.Query_Interface_Slot) =
           "a11y_uia_query_interface"
         and then Exports.Required_Bridge_Operation
           (Exports.Provider_Method_Slot) =
             Bridge.Provider_Method_Callback,
         "Windows UIA COM export table names bridge callback slots");
      Check
        (Exports.Can_Dispatch_Method
           (Table, ABI.IUnknown_Query_Interface)
         and then Exports.Can_Dispatch_Method
           (Table, ABI.Simple_Get_Property_Value)
         and then Exports.Can_Dispatch_Method
         (Table, ABI.Fragment_Get_Runtime_Id)
         and then Exports.Can_Dispatch_Method
           (Table, ABI.Advise_Events_Advise)
         and then Exports.Can_Dispatch_Method
           (Table, ABI.Expand_Collapse_Provider_Expand)
         and then Exports.Can_Dispatch_Method
           (Table, ABI.Selection_Item_Provider_Select)
         and then Exports.Can_Dispatch_Method
           (Table, ABI.Range_Value_Provider_Set_Value)
         and then not Exports.Can_Dispatch_Method
           (Table, ABI.Value_Provider_Set_Value),
         "Windows UIA COM export table exposes dispatchable ABI methods only");

      Object :=
        A11y.Windows_Backend.UIA_COM_VTables.Build_Object_Descriptor (Table);
      Check
        (Object.Exportable
         and then Object.Controlling_IUnknown_Stable
         and then Object.Provider = Id
         and then Object.Session = Session
         and then Object.Native_Node_Component = Table.Native_Node_Component
         and then Object.Interface_Count >= 4
         and then Object.VTable_Method_Count >= Table.Dispatchable_Methods
         and then Object.Provider_Frame_Count = Table.Dispatchable_Methods - 3,
         "Windows UIA COM vtable descriptor preserves stable object identity");
      Check
        (A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
           (Object, COM.IUnknown_Interface)
         and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
           (Object, COM.Raw_Element_Provider_Simple)
         and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
           (Object, COM.Raw_Element_Provider_Fragment)
         and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
           (Object, COM.Raw_Element_Provider_Fragment_Root)
         and then A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
           (Object, COM.Raw_Element_Provider_Advise_Events),
         "Windows UIA COM vtable descriptor exposes only supported provider interfaces");
      Interface_Slot :=
        A11y.Windows_Backend.UIA_COM_VTables.Interface_Slot
          (Object, COM.Raw_Element_Provider_Fragment_Root);
      Check
        (Interface_Slot.Supported
         and then Interface_Slot.Requires_Root
         and then Interface_Slot.Method_Count =
           A11y.Windows_Backend.UIA_COM_VTables.Interface_Method_Count
             (COM.Raw_Element_Provider_Fragment_Root)
         and then Interface_Slot.Callback_Slot =
           Exports.Provider_Method_Slot,
         "Windows UIA COM vtable descriptor records root-only interface slots");
      Query_Plan :=
        A11y.Windows_Backend.UIA_COM_VTables.Query_Interface
          (Object, COM.Raw_Element_Provider_Simple);
      Check
        (Query_Plan.Supported
         and then Query_Plan.Status = A11y.Results.Success
         and then Query_Plan.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA COM vtable descriptor plans supported QueryInterface results");
      Query_Plan :=
        A11y.Windows_Backend.UIA_COM_VTables.Query_Interface
          (Object, COM.Raw_Element_Provider_Advise_Events);
      Check
        (Query_Plan.Supported
         and then Query_Plan.Status = A11y.Results.Success
         and then Query_Plan.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA COM vtable descriptor plans advise-event QueryInterface results");
      Query_Plan :=
        A11y.Windows_Backend.UIA_COM_VTables.Query_Interface
          (Object, COM.Unsupported_Interface);
      Check
        (not Query_Plan.Supported
         and then Query_Plan.Status = A11y.Results.Unsupported_Capability
         and then Query_Plan.ABI_HResult_Code = 16#0000_0001#,
         "Windows UIA COM vtable descriptor rejects unsupported QueryInterface results");
      Frame_Plan :=
        A11y.Windows_Backend.UIA_COM_VTables.Frame_For
          (Object, ABI.Simple_Get_Property_Value);
      Check
        (Frame_Plan.Supported
         and then Frame_Plan.Status = A11y.Results.Success
         and then Frame_Plan.Frame.Session_Code =
           Interfaces.Unsigned_64
             (A11y.Native_Identity.To_Natural (Session))
         and then Frame_Plan.Frame.Provider_Code =
           Interfaces.Unsigned_64 (Registry.To_Natural (Id))
         and then Frame_Plan.Frame.Method_Code =
           Exports.Method_Code (ABI.Simple_Get_Property_Value),
         "Windows UIA COM vtable descriptor builds checked provider callback frames");
      Frame_Plan :=
        A11y.Windows_Backend.UIA_COM_VTables.Frame_For
          (Object, ABI.IUnknown_Add_Ref);
      Check
        (not Frame_Plan.Supported
         and then Frame_Plan.Status = A11y.Results.Unsupported_Capability,
         "Windows UIA COM vtable descriptor keeps IUnknown outside provider frames");

      A11y.Windows_Backend.UIA_COM_Object_Exports.Export_Object
        (Object_Exports, Object, Object_Export_Report);
      Check
        (Object_Export_Report.Exported
         and then Object_Export_Report.Status = A11y.Results.Success
         and then A11y.Windows_Backend.UIA_COM_Object_Exports.Is_Valid
           (Object_Export_Report.Token)
         and then Object_Export_Report.Generation_After >
           Object_Export_Report.Generation_Before,
         "Windows UIA COM object export table returns stable opaque object tokens");
      A11y.Windows_Backend.UIA_COM_Object_Exports.Resolve_Object
        (Object_Exports,
         Object_Export_Report.Token,
         Session,
         Id,
         Object_Resolve_Report);
      Check
        (Object_Resolve_Report.Found
         and then Object_Resolve_Report.Status = A11y.Results.Success
         and then Object_Resolve_Report.Descriptor.Provider = Id
         and then Object_Resolve_Report.Descriptor.Session = Session
         and then not Object_Resolve_Report.Stale,
         "Windows UIA COM object export table resolves tokens through stable identity");
      A11y.Windows_Backend.UIA_COM_Object_Exports.Resolve_Object
        (Object_Exports,
         Object_Export_Report.Token,
         A11y.Native_Identity.Create_Session,
         Id,
         Object_Resolve_Report);
      Check
        (not Object_Resolve_Report.Found
         and then Object_Resolve_Report.Status =
           A11y.Results.Node_Unavailable
         and then Object_Resolve_Report.Stale,
         "Windows UIA COM object export table rejects stale cross-session tokens");
      A11y.Windows_Backend.UIA_COM_Object_Exports.Release_Object
        (Object_Exports,
         Object_Export_Report.Token,
         Object_Release_Report);
      Released_Object_Token := Object_Export_Report.Token;
      Check
        (Object_Release_Report.Released
         and then Object_Release_Report.Status = A11y.Results.Success
         and then Object_Release_Report.Tombstone_Added,
         "Windows UIA COM object export table tombstones released tokens");
      A11y.Windows_Backend.UIA_COM_Object_Exports.Resolve_Object
        (Object_Exports,
         Object_Export_Report.Token,
         Session,
         Id,
         Object_Resolve_Report);
      Check
        (not Object_Resolve_Report.Found
         and then Object_Resolve_Report.Released
         and then Object_Resolve_Report.Status =
           A11y.Results.Node_Unavailable,
         "Windows UIA COM object export table rejects released object tokens");
      A11y.Windows_Backend.UIA_COM_Object_Exports.Export_Object
        (Object_Exports, Object, Object_Export_Report);
      Object_Table_Snapshot :=
        A11y.Windows_Backend.UIA_COM_Object_Exports.Snapshot
          (Object_Exports);
      Check
        (Object_Export_Report.Exported
         and then A11y.Windows_Backend.UIA_COM_Object_Exports.To_Natural
           (Object_Export_Report.Token) = 2
         and then Object_Table_Snapshot.Live_Count = 1
         and then Object_Table_Snapshot.Tombstones = 1,
         "Windows UIA COM object export table does not reuse released tokens");
      Live_Object_Token := Object_Export_Report.Token;

      Registry.Ensure_Provider
        (Registry_Object, Session, Root, Child, Child_Id, Result);
      COM.Initialize (Child_Provider, Session, Root, Child, Result);
      Export := COM.Export_Descriptor (Child_Provider);
      Root_Table := Exports.Build_Export_Table (Child_Id, Export);
      Child_Object :=
        A11y.Windows_Backend.UIA_COM_VTables.Build_Object_Descriptor
          (Root_Table);
      Check
        (Root_Table.Exportable
         and then not Exports.Can_Dispatch_Method
           (Root_Table, ABI.Fragment_Root_Get_Focus),
         "Windows UIA COM export table keeps fragment-root methods root-only");
      Check
        (Child_Object.Exportable
         and then not A11y.Windows_Backend.UIA_COM_VTables.Interface_Supported
           (Child_Object, COM.Raw_Element_Provider_Fragment_Root)
         and then not A11y.Windows_Backend.UIA_COM_VTables.Method_Supported
           (Child_Object, ABI.Fragment_Root_Get_Focus),
         "Windows UIA COM vtable descriptor keeps non-root fragment providers out of fragment-root slots");

      Invalid_Table := Exports.Build_Export_Table (Registry.No_Provider, Export);
      Check
        (not Invalid_Table.Exportable
         and then Invalid_Table.Status = A11y.Results.Node_Unavailable,
         "Windows UIA COM export table rejects invalid provider ids");
      Check
        (not A11y.Windows_Backend.UIA_COM_VTables
           .Build_Object_Descriptor (Invalid_Table).Exportable,
         "Windows UIA COM vtable descriptor rejects invalid export tables");
      A11y.Windows_Backend.UIA_COM_Object_Exports.Export_Object
        (Object_Exports,
         A11y.Windows_Backend.UIA_COM_VTables
           .Build_Object_Descriptor (Invalid_Table),
         Object_Export_Report);
      Check
        (not Object_Export_Report.Exported
         and then Object_Export_Report.Status =
           A11y.Results.Node_Unavailable,
         "Windows UIA COM object export table rejects invalid descriptors");

      Check
        (Exports.HRESULT_Code
           (A11y.Windows_Backend.UIA_Provider_Boundary.S_OK) = 16#0000_0000#
         and then Exports.HRESULT_Code
           (A11y.Windows_Backend.UIA_Provider_Boundary
              .UIA_E_ELEMENTNOTAVAILABLE) = 16#8004_0201#
         and then Exports.HRESULT_Code
           (A11y.Windows_Backend.UIA_Provider_Boundary.E_FAIL) =
             16#8000_4005#,
         "Windows UIA COM export table translates HRESULTs to ABI codes");
      Check
        (Exports.Method_Code (ABI.Simple_Get_Property_Value) = 12
         and then ABI.Method_Code (ABI.Simple_Get_Property_Value) = 12
         and then Exports.Method_From_Code (12, Result) =
           ABI.Simple_Get_Property_Value
         and then A11y.Results.Succeeded (Result),
         "Windows UIA COM export table delegates ABI method codes");
      for Method in ABI.UIA_ABI_Method loop
         declare
            Code : constant Interfaces.Unsigned_32 :=
              ABI.Method_Code (Method);
            Roundtrip : constant ABI.UIA_ABI_Method :=
              ABI.Method_From_Code (Code, Result);
         begin
            Check
              (A11y.Results.Succeeded (Result)
               and then Roundtrip = Method
               and then Exports.Method_Code (Method) = Code
               and then Exports.Method_From_Code (Code, Result) = Method
               and then A11y.Results.Succeeded (Result),
               "Windows UIA ABI surface round-trips every method code");
         end;
      end loop;
      declare
         Invalid_Method : constant ABI.UIA_ABI_Method :=
           ABI.Method_From_Code (999, Result);
      begin
         Check
           (Invalid_Method = ABI.IUnknown_Query_Interface
            and then Result.Status = A11y.Results.Invalid_Argument,
            "Windows UIA ABI surface rejects unknown method codes");
      end;
      declare
         Prepared : constant
           A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request :=
             ABI.Prepare_Request
               (Export, ABI.Fragment_Set_Focus, Result);
      begin
         Check
           (A11y.Results.Succeeded (Result)
            and then Prepared.Kind =
              A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action
            and then Prepared.Has_Native_Identity
            and then Prepared.Native_Node_Component =
              Export.Native_Node_Component
            and then Prepared.Action = A11y.Actions.Set_Focus,
            "Windows UIA ABI surface prepares Fragment SetFocus with semantic set-focus action");
      end;
      declare
         Prepared : constant
           A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request :=
             ABI.Prepare_Request
               (Export, ABI.Invoke_Provider_Invoke, Result);
      begin
         Check
           (A11y.Results.Succeeded (Result)
            and then Prepared.Kind =
              A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action
            and then Prepared.Has_Native_Identity
            and then Prepared.Native_Node_Component =
              Export.Native_Node_Component
            and then Prepared.Action = A11y.Actions.Activate,
            "Windows UIA ABI surface prepares InvokeProvider Invoke with semantic activate action");
      end;
      declare
         Prepared : constant
           A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request :=
             ABI.Prepare_Request
               (Export, ABI.Toggle_Provider_Toggle, Result);
      begin
         Check
           (A11y.Results.Succeeded (Result)
            and then Prepared.Kind =
              A11y.Windows_Backend.UIA_Provider_Boundary.Invoke_Action
            and then Prepared.Has_Native_Identity
            and then Prepared.Native_Node_Component =
              Export.Native_Node_Component
            and then Prepared.Action = A11y.Actions.Toggle,
            "Windows UIA ABI surface prepares ToggleProvider Toggle with semantic toggle action");
      end;

      Snapshots.Properties.Id := Root;
      Snapshots.Properties.Root := Root;
      Snapshots.Properties.Role := A11y.Roles.Button;
      Snapshots.Properties.Name := A11y.Properties.Present ("Exported");
      Snapshots.Properties.Defunct := False;
      Snapshots.Properties.Exposure := [others => A11y.Nodes.Expose_Node];
      Snapshots.Fragment.Session := Session;
      A11y.Trees.Set_Root (Snapshots.Properties.Tree, Root, Result);

      Live.Query_Interface
        (Object_Exports,
         Live_Object_Token,
         Session,
         Id,
         COM.Raw_Element_Provider_Simple,
         Interface_Query);
      Simple_Interface := Interface_Query.Reference;
      Check
        (Interface_Query.Object_Resolved
         and then Interface_Query.Query.Supported
         and then Interface_Query.Reference.Present
         and then Interface_Query.Reference.Kind =
           COM.Raw_Element_Provider_Simple
         and then Interface_Query.Reference.Provider = Id
         and then Interface_Query.Reference.Node = Root
         and then Interface_Query.Reference.Method_Count =
           A11y.Windows_Backend.UIA_COM_VTables.Interface_Method_Count
             (COM.Raw_Element_Provider_Simple)
         and then Interface_Query.Reference.Reference_Count = 1
         and then not Interface_Query.Reference.Released
         and then Interface_Query.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA live COM export surface returns stable interface references");

      Live.Add_Ref (Simple_Interface, Add_Ref_Report);
      Check
        (Add_Ref_Report.Reference_Present
         and then not Add_Ref_Report.Reference_Released_Before
         and then not Add_Ref_Report.Reference_Released_After
         and then Add_Ref_Report.Count_Before = 1
         and then Add_Ref_Report.Count_After = 2
         and then Add_Ref_Report.Status = A11y.Results.Success
         and then Simple_Interface.Reference_Count = 2
         and then not Simple_Interface.Released,
         "Windows UIA live COM export surface retains queried interface references");

      declare
         Overflow_Interface : Live.UIA_Interface_Reference := Simple_Interface;
         Overflow_Report : Live.Interface_Lifetime_Report;
      begin
         Overflow_Interface.Reference_Count := Natural'Last;
         Live.Add_Ref (Overflow_Interface, Overflow_Report);
         Check
           (Overflow_Report.Reference_Present
            and then not Overflow_Report.Reference_Released_Before
            and then not Overflow_Report.Reference_Released_After
            and then Overflow_Report.Count_Before = Natural'Last
            and then Overflow_Report.Count_After = Natural'Last
            and then Overflow_Report.Status = A11y.Results.Resource_Limit
            and then Overflow_Interface.Reference_Count = Natural'Last
            and then not Overflow_Interface.Released,
            "Windows UIA live COM export surface bounds interface AddRef overflow");
      end;

      Released_Simple_Interface := Simple_Interface;
      Live.Release (Released_Simple_Interface, First_Release_Report);
      Live.Release (Released_Simple_Interface, Second_Release_Report);
      Live.Release (Released_Simple_Interface, Third_Release_Report);
      Check
        (First_Release_Report.Reference_Present
         and then First_Release_Report.Count_Before = 2
         and then First_Release_Report.Count_After = 1
         and then not First_Release_Report.Reference_Released_After
         and then Second_Release_Report.Reference_Present
         and then Second_Release_Report.Count_Before = 1
         and then Second_Release_Report.Count_After = 0
         and then Second_Release_Report.Reference_Released_After
         and then Released_Simple_Interface.Released
         and then Released_Simple_Interface.Reference_Count = 0,
         "Windows UIA live COM export surface releases interface references deterministically");
      Check
        (Third_Release_Report.Reference_Present
         and then Third_Release_Report.Reference_Released_Before
         and then Third_Release_Report.Reference_Released_After
         and then Third_Release_Report.Count_Before = 0
         and then Third_Release_Report.Count_After = 0
         and then Third_Release_Report.Status = A11y.Results.Node_Unavailable
         and then Released_Simple_Interface.Released
         and then Released_Simple_Interface.Reference_Count = 0,
         "Windows UIA live COM export surface rejects already released interface references");

      Live.Query_Interface
        (Object_Exports,
         Live_Object_Token,
         Session,
         Id,
         COM.Unsupported_Interface,
         Unsupported_Interface_Query);
      Check
        (Unsupported_Interface_Query.Object_Resolved
         and then not Unsupported_Interface_Query.Query.Supported
         and then not Unsupported_Interface_Query.Reference.Present
         and then Unsupported_Interface_Query.Status =
           A11y.Results.Unsupported_Capability
         and then Unsupported_Interface_Query.ABI_HResult_Code = 16#0000_0001#,
         "Windows UIA live COM export surface rejects unsupported interfaces");

      Live.Query_Interface
        (Object_Exports,
         Released_Object_Token,
         Session,
         Id,
         COM.Raw_Element_Provider_Simple,
         Released_Interface_Query);
      Check
        (not Released_Interface_Query.Object_Resolved
         and then Released_Interface_Query.Object_Report.Released
         and then Released_Interface_Query.Status =
           A11y.Results.Node_Unavailable,
         "Windows UIA live COM export surface rejects released object tokens");

      Reply :=
        Live.Dispatch_Interface_Method
          (Object_Exports,
           Simple_Interface,
           ABI.Simple_Get_Property_Value,
           Registry_Object,
           Snapshots.all,
           Live_Dispatch_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Live_Dispatch_Report.Object_Resolved
         and then Live_Dispatch_Report.Interface_Accepted
         and then Live_Dispatch_Report.Method_Allowed_For_Interface
         and then Live_Dispatch_Report.Frame_Prepared
         and then Live_Dispatch_Report.Callback_Dispatched
         and then Live_Dispatch_Report.Callback.Invoke.Registered_Dispatched
         and then Live_Dispatch_Report.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA live COM export surface dispatches provider methods from interface references");

      Reply :=
        Live.Dispatch_Interface_Method
          (Object_Exports,
           Released_Simple_Interface,
           ABI.Simple_Get_Property_Value,
           Registry_Object,
           Snapshots.all,
           Released_Interface_Dispatch_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Error
         and then Reply.Status = A11y.Results.Node_Unavailable
         and then not Released_Interface_Dispatch_Report.Object_Resolved
         and then not Released_Interface_Dispatch_Report.Callback_Dispatched,
         "Windows UIA live COM export surface rejects released interface references");

      Live_Frame :=
        Live.Build_Interface_Frame
          (Simple_Interface, ABI.Simple_Get_Property_Value);
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Live_Frame_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Live_Frame.Session_Code =
           Interfaces.Unsigned_64
             (A11y.Native_Identity.To_Natural (Session))
         and then Live_Frame.Provider_Code =
           Interfaces.Unsigned_64 (Registry.To_Natural (Id))
         and then Live_Frame.Object_Token_Code =
           Interfaces.Unsigned_64
             (A11y.Windows_Backend.UIA_COM_Object_Exports.To_Natural
                (Live_Object_Token))
         and then Live_Frame.Interface_Code =
           Live.Interface_Code (COM.Raw_Element_Provider_Simple)
         and then Live_Frame.Method_Code =
           Exports.Method_Code (ABI.Simple_Get_Property_Value)
         and then Live_Frame_Report.Session_Code_Valid
         and then Live_Frame_Report.Provider_Code_Valid
         and then Live_Frame_Report.Object_Token_Valid
         and then Live_Frame_Report.Interface_Code_Valid
         and then Live_Frame_Report.Method_Code_Valid
         and then Live_Frame_Report.Reference_Queried
         and then Live_Frame_Report.Dispatch.Callback_Dispatched
         and then Live_Frame_Report.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA live COM export surface dispatches ABI interface frames");

      Native_Callback_Context.Object_Table := Object_Exports'Unchecked_Access;
      Native_Callback_Context.Registry := Registry_Object'Unchecked_Access;
      Native_Callback_Context.Snapshots := Snapshots.all'Unchecked_Access;
      Native_Frame (0) := Native_Bridge.Native_UInt64
        (Live_Frame.Session_Code);
      Native_Frame (1) := Native_Bridge.Native_UInt64
        (Live_Frame.Provider_Code);
      Native_Frame (2) := Native_Bridge.Native_UInt64
        (Live_Frame.Object_Token_Code);
      Native_Frame (3) := Native_Bridge.Native_UInt64
        (Live_Frame.Interface_Code);
      Native_Frame (4) := Native_Bridge.Native_UInt64
        (Live_Frame.Method_Code);
      Native_Frame (5) := Native_Bridge.Native_UInt64
        (Live_Frame.Direction_Code);
      Native_Frame_Result :=
        Native_Callbacks.Dispatch_Interface_Frame_Callback
          (Native_Frame (0)'Access,
           Native_Callback_Context'Address);
      Check
        (Native_Frame_Result = 16#0000_0000#
         and then Native_Callback_Context.Dispatched
         and then Native_Callback_Context.Last_Status =
           A11y.Results.Success
         and then Native_Callback_Context.Last_HResult_Code =
           16#0000_0000#
         and then Native_Callback_Context.Last_Report.Session_Code_Valid
         and then Native_Callback_Context.Last_Report.Provider_Code_Valid
         and then Native_Callback_Context.Last_Report.Object_Token_Valid
         and then Native_Callback_Context.Last_Report.Interface_Code_Valid
         and then Native_Callback_Context.Last_Report.Method_Code_Valid
         and then Native_Callback_Context.Last_Report.Reference_Queried
         and then Native_Callback_Context.Last_Report.Dispatch
           .Callback_Dispatched,
         "Windows UIA native callback wrapper dispatches full interface frames");

      declare
         Previous_Value_Node : constant A11y.Node_Ids.Node_Id :=
           Snapshots.Value.Id;
         Range_Set_Result : Native_Bridge.Native_UInt32 := 0;
      begin
         Snapshots.Value.Id := Root;
         Live_Frame :=
           Live.Build_Interface_Frame
             (Simple_Interface, ABI.Range_Value_Provider_Set_Value);
         Native_Frame (0) := Native_Bridge.Native_UInt64
           (Live_Frame.Session_Code);
         Native_Frame (1) := Native_Bridge.Native_UInt64
           (Live_Frame.Provider_Code);
         Native_Frame (2) := Native_Bridge.Native_UInt64
           (Live_Frame.Object_Token_Code);
         Native_Frame (3) := Native_Bridge.Native_UInt64
           (Live_Frame.Interface_Code);
         Native_Frame (4) := Native_Bridge.Native_UInt64
           (Live_Frame.Method_Code);
         Native_Frame (5) := Native_Bridge.Native_UInt64
           (Live_Frame.Direction_Code);
         Native_Callback_Context.Dispatched := False;
         Range_Set_Result :=
           Native_Callbacks.Dispatch_Range_Value_Set_Callback
             (Native_Frame (0)'Access,
              Interfaces.C.double (6.0),
              Native_Callback_Context'Address);
         Check
           (Range_Set_Result = 16#0000_0000#,
            "Windows UIA native range-value set returns S_OK");
         Check
           (Native_Callback_Context.Dispatched,
            "Windows UIA native range-value set reaches the boundary");
         Check
           (Native_Callback_Context.Last_Status = A11y.Results.Success,
            "Windows UIA native range-value set preserves semantic success");
         Check
           (Range_Set_Result = 16#0000_0000#
            and then Native_Callback_Context.Dispatched
            and then Native_Callback_Context.Last_Status =
              A11y.Results.Success
            and then Native_Callback_Context.Last_HResult_Code =
              16#0000_0000#,
            "Windows UIA native callback wrapper dispatches range-value set payloads");
         Snapshots.Value.Id := Previous_Value_Node;
      end;

      Live_Frame :=
        Live.Build_Interface_Frame
          (Simple_Interface, ABI.Simple_Get_Property_Value);
      Native_Frame (0) := Native_Bridge.Native_UInt64
        (Live_Frame.Session_Code);
      Native_Frame (1) := Native_Bridge.Native_UInt64
        (Live_Frame.Provider_Code);
      Native_Frame (2) := Native_Bridge.Native_UInt64
        (Live_Frame.Object_Token_Code);
      Native_Frame (3) := Native_Bridge.Native_UInt64
        (Live_Frame.Interface_Code);
      Native_Frame (4) := Native_Bridge.Native_UInt64
        (Live_Frame.Method_Code);
      Native_Frame (5) := Native_Bridge.Native_UInt64
        (Live_Frame.Direction_Code);

      declare
         type Native_UTF8_Buffer is
           array (Natural range 0 .. 31) of aliased Interfaces.C.char
         with Convention => C;

         Buffer : Native_UTF8_Buffer := [others => Interfaces.C.nul];
         Value_Kind : aliased Native_Bridge.Native_UInt32 := 0;
         Bytes_Used : aliased Native_Bridge.Native_UInt32 := 0;
         Copy_Result : Native_Bridge.Native_UInt32 := 0;
      begin
         Native_Callback_Context.Dispatched := False;
         Copy_Result :=
           Native_Callbacks.Copy_Property_Value_Callback
             (Native_Frame (0)'Access,
              30_005,
              Value_Kind'Access,
              Buffer (0)'Address,
              Native_Bridge.Native_UInt32 (Buffer'Length),
              Bytes_Used'Access,
              Native_Callback_Context'Address);
         Check
           (Copy_Result = 16#0000_0000#
            and then Native_Callback_Context.Dispatched
            and then Native_Callback_Context.Last_Status =
              A11y.Results.Success
            and then Value_Kind = 1
            and then Bytes_Used = 8
            and then Buffer (0) = Interfaces.C.char'Val
              (Character'Pos ('E'))
            and then Buffer (7) = Interfaces.C.char'Val
              (Character'Pos ('d')),
            "Windows UIA native callback wrapper copies property strings for BSTR marshalling");
      end;

      Live_Frame.Interface_Code := 99;
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Rejected_Live_Frame_Report);
      Check
        (Reply.Status = A11y.Results.Invalid_Argument
         and then Rejected_Live_Frame_Report.Session_Code_Valid
         and then Rejected_Live_Frame_Report.Provider_Code_Valid
         and then Rejected_Live_Frame_Report.Object_Token_Valid
         and then not Rejected_Live_Frame_Report.Interface_Code_Valid
         and then not Rejected_Live_Frame_Report.Reference_Queried,
         "Windows UIA live COM export surface rejects malformed interface frame codes");

      Live_Frame :=
        Live.Build_Interface_Frame
          (Simple_Interface, ABI.Simple_Get_Property_Value);
      Live_Frame.Method_Code := 999;
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Rejected_Live_Frame_Report);
      Check
        (Reply.Status = A11y.Results.Invalid_Argument
         and then Rejected_Live_Frame_Report.Interface_Code_Valid
         and then not Rejected_Live_Frame_Report.Method_Code_Valid
         and then not Rejected_Live_Frame_Report.Reference_Queried,
         "Windows UIA live COM export surface rejects malformed method frame codes");

      Live_Frame :=
        Live.Build_Interface_Frame
          (Simple_Interface, ABI.Simple_Get_Property_Value);
      Live_Frame.Session_Code := Interfaces.Unsigned_64'Last;
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Rejected_Live_Frame_Report);
      Check
        (Reply.Status = A11y.Results.Invalid_Argument
         and then not Rejected_Live_Frame_Report.Session_Code_Valid
         and then not Rejected_Live_Frame_Report.Reference_Queried,
         "Windows UIA live COM export surface rejects oversized session frame codes");

      Live_Frame :=
        Live.Build_Interface_Frame
          (Simple_Interface, ABI.Simple_Get_Property_Value);
      Live_Frame.Provider_Code := Interfaces.Unsigned_64'Last;
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Rejected_Live_Frame_Report);
      Check
        (Reply.Status = A11y.Results.Invalid_Argument
         and then Rejected_Live_Frame_Report.Session_Code_Valid
         and then not Rejected_Live_Frame_Report.Provider_Code_Valid
         and then not Rejected_Live_Frame_Report.Reference_Queried,
         "Windows UIA live COM export surface rejects oversized provider frame codes");

      Live_Frame :=
        Live.Build_Interface_Frame
          (Simple_Interface, ABI.Simple_Get_Property_Value);
      Live_Frame.Object_Token_Code := Interfaces.Unsigned_64'Last;
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Rejected_Live_Frame_Report);
      Check
        (Reply.Status = A11y.Results.Invalid_Argument
         and then Rejected_Live_Frame_Report.Session_Code_Valid
         and then Rejected_Live_Frame_Report.Provider_Code_Valid
         and then not Rejected_Live_Frame_Report.Object_Token_Valid
         and then not Rejected_Live_Frame_Report.Reference_Queried,
         "Windows UIA live COM export surface rejects oversized object-token frame codes");

      Live.Query_Interface
        (Object_Exports,
         Live_Object_Token,
         Session,
         Id,
         COM.Raw_Element_Provider_Fragment,
         Interface_Query);
      Fragment_Interface := Interface_Query.Reference;
      Reply :=
        Live.Dispatch_Interface_Method
          (Object_Exports,
           Fragment_Interface,
           ABI.Fragment_Navigate,
           Registry_Object,
           Snapshots.all,
           Live_Dispatch_Report,
           A11y.Windows_Backend.UIA_Fragments.First_Child);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Reply.Routed =
           A11y.Windows_Backend.UIA_Request_Router.Fragment_Node
         and then Reply.Payload.Node = Child
         and then Live_Dispatch_Report.Object_Resolved
         and then Live_Dispatch_Report.Interface_Accepted
         and then Live_Dispatch_Report.Method_Allowed_For_Interface
         and then Live_Dispatch_Report.Frame_Prepared
         and then Live_Dispatch_Report.Callback_Dispatched
         and then Live_Dispatch_Report.Callback.Invoke.Registered_Dispatched,
         "Windows UIA live COM export surface dispatches Fragment navigation");

      Live_Frame :=
        Live.Build_Interface_Frame
          (Fragment_Interface, ABI.Fragment_Get_Runtime_Id);
      Reply :=
        Live.Dispatch_Interface_Frame
          (Object_Exports,
           Live_Frame,
           Registry_Object,
           Snapshots.all,
           Live_Frame_Report);
      declare
         Root_Result : A11y.Results.Result;
         Node_Result : A11y.Results.Result;
         Root_Component : constant Natural :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Root, Root_Result);
         Node_Component : constant Natural :=
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Root, Node_Result);
         type Native_UInt32_Buffer is
           array (Natural range 0 .. 7)
             of aliased Native_Bridge.Native_UInt32
         with Convention => C;
         Runtime_Id_Buffer : Native_UInt32_Buffer := [others => 0];
         Runtime_Value_Kind : aliased Native_Bridge.Native_UInt32 := 0;
         Runtime_Values_Used : aliased Native_Bridge.Native_UInt32 := 0;
         Runtime_Copy_Result : Native_Bridge.Native_UInt32 := 0;
      begin
         Check
           (A11y.Results.Succeeded (Root_Result)
            and then A11y.Results.Succeeded (Node_Result)
            and then Reply.Kind =
              A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
            and then Reply.HResult =
              A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
            and then Reply.Routed =
              A11y.Windows_Backend.UIA_Request_Router.Runtime_Id
            and then Reply.Payload.Id.Session_Component =
              A11y.Native_Identity.To_Natural (Session)
            and then Reply.Payload.Id.Root_Component = Root_Component
            and then Reply.Payload.Id.Node_Component = Node_Component
            and then Live_Frame_Report.Session_Code_Valid
            and then Live_Frame_Report.Provider_Code_Valid
            and then Live_Frame_Report.Object_Token_Valid
            and then Live_Frame_Report.Interface_Code_Valid
            and then Live_Frame_Report.Method_Code_Valid
            and then Live_Frame_Report.Direction_Code_Valid
            and then Live_Frame_Report.Reference_Queried
            and then Live_Frame_Report.Dispatch.Callback_Dispatched
            and then Live_Frame_Report.ABI_HResult_Code = 16#0000_0000#,
            "Windows UIA live COM export surface dispatches Fragment runtime identifiers");

         Native_Frame (0) := Native_Bridge.Native_UInt64
           (Live_Frame.Session_Code);
         Native_Frame (1) := Native_Bridge.Native_UInt64
           (Live_Frame.Provider_Code);
         Native_Frame (2) := Native_Bridge.Native_UInt64
           (Live_Frame.Object_Token_Code);
         Native_Frame (3) := Native_Bridge.Native_UInt64
           (Live_Frame.Interface_Code);
         Native_Frame (4) := Native_Bridge.Native_UInt64
           (Live_Frame.Method_Code);
         Native_Frame (5) := Native_Bridge.Native_UInt64
           (Live_Frame.Direction_Code);
         Native_Callback_Context.Dispatched := False;
         Runtime_Copy_Result :=
           Native_Callbacks.Copy_Runtime_Id_Callback
             (Native_Frame (0)'Access,
              Runtime_Value_Kind'Access,
              Runtime_Id_Buffer (0)'Address,
              Native_Bridge.Native_UInt32 (Runtime_Id_Buffer'Length),
              Runtime_Values_Used'Access,
              Native_Callback_Context'Address);
         Check
           (Runtime_Copy_Result = 16#0000_0000#
            and then Native_Callback_Context.Dispatched
            and then Runtime_Value_Kind = 2
            and then Runtime_Values_Used = 3
            and then Runtime_Id_Buffer (0) =
              Native_Bridge.Native_UInt32
                (A11y.Native_Identity.To_Natural (Session))
            and then Runtime_Id_Buffer (1) =
              Native_Bridge.Native_UInt32 (Root_Component)
            and then Runtime_Id_Buffer (2) =
              Native_Bridge.Native_UInt32 (Node_Component),
            "Windows UIA native callback wrapper copies runtime ids for SAFEARRAY marshalling");
      end;

      Live_Frame :=
        Live.Build_Interface_Frame
          (Fragment_Interface, ABI.Fragment_Get_Bounding_Rectangle);
      declare
         Left : aliased Interfaces.C.double := 0.0;
         Top : aliased Interfaces.C.double := 0.0;
         Width : aliased Interfaces.C.double := 0.0;
         Height : aliased Interfaces.C.double := 0.0;
         Rectangle_Copy_Result : Native_Bridge.Native_UInt32 := 0;
      begin
         Native_Frame (0) := Native_Bridge.Native_UInt64
           (Live_Frame.Session_Code);
         Native_Frame (1) := Native_Bridge.Native_UInt64
           (Live_Frame.Provider_Code);
         Native_Frame (2) := Native_Bridge.Native_UInt64
           (Live_Frame.Object_Token_Code);
         Native_Frame (3) := Native_Bridge.Native_UInt64
           (Live_Frame.Interface_Code);
         Native_Frame (4) := Native_Bridge.Native_UInt64
           (Live_Frame.Method_Code);
         Native_Frame (5) := Native_Bridge.Native_UInt64
           (Live_Frame.Direction_Code);
         Native_Callback_Context.Dispatched := False;
         Rectangle_Copy_Result :=
           Native_Callbacks.Copy_Bounding_Rectangle_Callback
             (Native_Frame (0)'Access,
              Left'Access,
              Top'Access,
              Width'Access,
              Height'Access,
              Native_Callback_Context'Address);
         Check
           (Rectangle_Copy_Result = 16#0000_0000#
            and then Native_Callback_Context.Dispatched
            and then Left = Interfaces.C.double
              (Snapshots.Properties.Bounds.Origin.X)
            and then Top = Interfaces.C.double
              (Snapshots.Properties.Bounds.Origin.Y)
            and then Width = Interfaces.C.double
              (Snapshots.Properties.Bounds.Extent.Width)
            and then Height = Interfaces.C.double
              (Snapshots.Properties.Bounds.Extent.Height),
            "Windows UIA native callback wrapper copies bounding rectangles for UiaRect marshalling");
      end;

      Reply :=
        Live.Dispatch_Interface_Method
          (Object_Exports,
           Fragment_Interface,
           ABI.Simple_Get_Property_Value,
           Registry_Object,
           Snapshots.all,
           Rejected_Live_Dispatch_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
         and then Rejected_Live_Dispatch_Report.Object_Resolved
         and then Rejected_Live_Dispatch_Report.Interface_Accepted
         and then not Rejected_Live_Dispatch_Report
           .Method_Allowed_For_Interface
         and then not Rejected_Live_Dispatch_Report.Callback_Dispatched,
         "Windows UIA live COM export surface rejects methods outside the queried interface");

      Reply :=
        Exports.Invoke_Provider_Method
          (Table,
           ABI.Simple_Get_Property_Value,
           Registry_Object,
           Snapshots.all,
           Invoke_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_OK
         and then Invoke_Report.Callback_Allowed
         and then Invoke_Report.Method_Dispatchable
         and then Invoke_Report.Request_Prepared
         and then Invoke_Report.Registered_Dispatched
         and then Invoke_Report.Boundary_Report.Native_Admitted
         and then Invoke_Report.Boundary_Report.Native_Completed
         and then Invoke_Report.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA COM export table invokes registered provider methods");

      Frame :=
        Exports.Build_Callback_Frame (Table, ABI.Simple_Get_Property_Value);
      Reply :=
        Exports.Invoke_Callback_Frame
          (Table,
           Frame,
           Registry_Object,
           Snapshots.all,
           Frame_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Reply
         and then Frame_Report.Frame_Matches_Export
         and then Frame_Report.Method_Code_Valid
         and then Frame_Report.Method = ABI.Simple_Get_Property_Value
         and then Frame_Report.Invoke.Registered_Dispatched
         and then Frame_Report.ABI_HResult_Code = 16#0000_0000#,
         "Windows UIA COM export table invokes raw ABI callback frames");

      Frame.Provider_Code := Frame.Provider_Code + 1;
      Reply :=
        Exports.Invoke_Callback_Frame
          (Table,
           Frame,
           Registry_Object,
           Snapshots.all,
           Frame_Report);
      Check
        (Reply.Status = A11y.Results.Node_Unavailable
         and then not Frame_Report.Frame_Matches_Export
         and then not Frame_Report.Method_Code_Valid,
         "Windows UIA COM export table rejects stale raw provider frames");

      Frame := Exports.Build_Callback_Frame (Table, ABI.Simple_Get_Property_Value);
      Frame.Method_Code := 999;
      Reply :=
        Exports.Invoke_Callback_Frame
          (Table,
           Frame,
           Registry_Object,
           Snapshots.all,
           Frame_Report);
      Check
        (Reply.Status = A11y.Results.Invalid_Argument
         and then Frame_Report.Frame_Matches_Export
         and then not Frame_Report.Method_Code_Valid,
         "Windows UIA COM export table rejects malformed raw method codes");

      Reply :=
        Exports.Invoke_Provider_Method
          (Table,
           ABI.IUnknown_Add_Ref,
           Registry_Object,
           Snapshots.all,
           Invoke_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
         and then Reply.HResult =
           A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE
         and then Invoke_Report.Callback_Allowed
         and then not Invoke_Report.Method_Dispatchable
         and then not Invoke_Report.Registered_Dispatched,
         "Windows UIA COM export table keeps lifetime callbacks out of provider-method dispatch");

      Reply :=
        Exports.Invoke_Provider_Method
          (Root_Table,
           ABI.Fragment_Root_Get_Focus,
           Registry_Object,
           Snapshots.all,
           Invoke_Report);
      Check
        (Reply.Kind =
           A11y.Windows_Backend.UIA_Provider_Boundary.Provider_Not_Supported
         and then not Invoke_Report.Request_Prepared
         and then not Invoke_Report.Registered_Dispatched,
         "Windows UIA COM export table rejects root-only methods before native dispatch");
   end;

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("All UIA router tests passed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line
        (Natural'Image (Failures) & " UIA router test(s) failed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   end Run;
begin
   Raise_Main_Stack_Limit;
   Run;
end UIA_Router_Tests;
