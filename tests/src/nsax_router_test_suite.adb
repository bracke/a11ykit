with Ada.Calendar;
with Ada.Command_Line;
with Interfaces.C;
with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Text_IO;

with A11y.Actions;
with A11y.Capabilities;
with A11y.Diagnostics;
with A11y.Documents;
with A11y.Events;
with A11y.Geometry;
with A11y.Images;
with A11y.Live_Regions;
with A11y.MacOS_Backend.NSAccessibility_Actions;
with A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
with A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;
with A11y.MacOS_Backend.NSAccessibility_Document;
with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Elements;
with A11y.MacOS_Backend.NSAccessibility_Events;
with A11y.MacOS_Backend.NSAccessibility_Hierarchy;
with A11y.MacOS_Backend.NSAccessibility_Image;
with A11y.MacOS_Backend.NSAccessibility_Live_Regions;
with A11y.MacOS_Backend.NSAccessibility_Mappings;
with A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
with A11y.MacOS_Backend.NSAccessibility_Native_Values;
with A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
with A11y.MacOS_Backend.NSAccessibility_Properties;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.MacOS_Backend.NSAccessibility_Selection;
with A11y.MacOS_Backend.NSAccessibility_Surfaces;
with A11y.MacOS_Backend.NSAccessibility_Table;
with A11y.MacOS_Backend.NSAccessibility_Text;
with A11y.MacOS_Backend.NSAccessibility_Values;
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

package body NSAX_Router_Test_Suite is

   procedure Run is
   use type A11y.Event_Sequence;
   use type Interfaces.Unsigned_32;
   use type A11y.Actions.Action_Id;
   use type A11y.Diagnostics.Category;
   use type A11y.Results.Status_Code;
   use type A11y.Semantic_Revision;
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
   use type A11y.Windows.Surface_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Actions.NSAX_Action;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Bridge_Operation;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
     .Calling_Convention_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
     .Exception_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Lifetime_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Nullability_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Ownership_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
     .Representation_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Thread_Rule;
   use type A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
   use type A11y.MacOS_Backend.NSAccessibility_Element_Registry
     .Native_Call_Mutation_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Element_Registry
     .Registry_Mutation_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Elements.Element_State;
   use type A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Attribute_Event;
   use type A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Notification;
   use type A11y.MacOS_Backend.NSAccessibility_Events.Posting_Drain_Stop_Reason;
   use type A11y.MacOS_Backend.NSAccessibility_Events.Queue_Posting_Operation;
   use type A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Window_Event;
   use type A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Relation_Attribute;
   use type A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Role;
   use type A11y.MacOS_Backend.NSAccessibility_Native_Values.Native_Value_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Request_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Document.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Image.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Live_Regions.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Properties.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Selection.Reply_Kind;
   use type A11y.Selection.Selection_Direction;
   use type A11y.MacOS_Backend.NSAccessibility_Surfaces.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Table.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Text.Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Values.Reply_Kind;
   use type A11y.Values.Value_Kind;
   use type
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_ABI_Surface.NSAX_Selector;
   use type
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Native_Method_Family;
   use type
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Native_Request_Kind;
   use type A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Status;

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

   use A11y.MacOS_Backend.NSAccessibility_Request_Router;

   type Snapshot_Access is access Snapshot_Bundle;
   type Request_Access is access Request;
   type Boundary_Request_Access is access
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request;
   type Boundary_Reply_Access is access
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
   type Registered_Boundary_Report_Access is access
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Registered_Native_Request_Report;

   Session : constant A11y.Native_Identity.Backend_Session_Id :=
     A11y.Native_Identity.Create_Session;
   Root : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (710);
   Child : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (711);
   Snapshots : constant Snapshot_Access := new Snapshot_Bundle;
   Result : A11y.Results.Result;
   Request_Item_Storage : constant Request_Access :=
     new Request'
       (Kind        => Attribute_Query,
        Attribute   => A11y.MacOS_Backend.NSAccessibility_Properties.Title,
        Action      => A11y.Actions.Press,
        Child_Index => 1,
        Relation    => A11y.Relations.Labelled_By,
        Value       => A11y.MacOS_Backend.NSAccessibility_Values.Value,
        Requested_Value => (Kind => A11y.Values.Unknown),
        Selection   =>
          A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count,
        Selection_Request =>
          A11y.MacOS_Backend.NSAccessibility_Selection.Select_Item,
        Selection_Target => A11y.Node_Ids.No_Node,
        Text        => A11y.MacOS_Backend.NSAccessibility_Text.Character_Count,
        Text_Edit   => A11y.Text.Insert_Text,
        Table       => A11y.MacOS_Backend.NSAccessibility_Table.Row_Count,
        Image       => A11y.MacOS_Backend.NSAccessibility_Image.Description,
        Document    => A11y.MacOS_Backend.NSAccessibility_Document.Locale,
        Live_Region =>
          A11y.MacOS_Backend.NSAccessibility_Live_Regions.Setting_Name,
        Surface     => A11y.MacOS_Backend.NSAccessibility_Surfaces.Kind_Name,
        Index       => 1,
        Count       => 0,
        Replacement =>
          Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String,
        Row         => 0,
        Column      => 0,
        Event       =>
          (Sequence  => 11,
           Timestamp => Ada.Calendar.Clock,
           Source    => Root,
           Kind      => A11y.Events.Focus_Changed,
           Revision  => 4),
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
   Request_Item : Request renames Request_Item_Storage.all;
   Routed : Routed_Reply;
   Boundary_Request_Storage : constant Boundary_Request_Access :=
       new A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
         .Boundary_Request;
   Boundary_Request :
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Request
       renames Boundary_Request_Storage.all;
   Boundary_Reply_Storage : constant Boundary_Reply_Access :=
       new A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply;
   Boundary_Reply :
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Boundary_Reply
       renames Boundary_Reply_Storage.all;
   Registered_Boundary_Report_Storage : constant
     Registered_Boundary_Report_Access :=
         new A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Registered_Native_Request_Report;
   Registered_Boundary_Report :
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Registered_Native_Request_Report
         renames Registered_Boundary_Report_Storage.all;
   Emission : A11y.MacOS_Backend.NSAccessibility_Events.NSAX_Event_Emission;
begin
   A11y.Trees.Set_Root (Snapshots.Hierarchy.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Hierarchy.Tree, Root, Child, Result);

   Snapshots.Properties.Id := Root;
   Snapshots.Properties.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Properties.Tree, Root, Result);
   Snapshots.Properties.Role := A11y.Roles.Button;
   Snapshots.Properties.Bounds :=
     (Origin => (X => -20, Y => 30), Extent => (Width => 90, Height => 26));
   Snapshots.Properties.Title := A11y.Properties.Present ("Press");
   Snapshots.Properties.Label := A11y.Properties.Present ("Primary action");
   Snapshots.Properties.Identifier :=
     A11y.Properties.Present ("primary-action");
   Snapshots.Properties.Description :=
     A11y.Properties.Present ("Submits the current dialog");
   Snapshots.Properties.Help := A11y.Properties.Present ("Press to continue");
   Snapshots.Properties.Placeholder :=
     A11y.Properties.Present ("Type a value");
   Snapshots.Properties.Value_Text := A11y.Properties.Present ("Ready");
   Snapshots.Properties.Keyboard_Shortcut :=
     A11y.Properties.Present ("Command+Return");
   Snapshots.Properties.Locale := A11y.Properties.Present ("da-DK");
   Snapshots.Properties.Orientation := A11y.Properties.Present ("vertical");
   Snapshots.Properties.Position_In_Set := A11y.Properties.Present (2);
   Snapshots.Properties.Size_Of_Set := A11y.Properties.Present (5);
   Snapshots.Properties.Hierarchical_Level := A11y.Properties.Present (3);
   Snapshots.Properties.Heading_Level := A11y.Properties.Present (2);
   Snapshots.Properties.Landmark := A11y.Properties.Present ("main");
   Snapshots.Actions (A11y.Actions.Press) := True;
   Snapshots.Actions (A11y.Actions.Expand) := True;
   Snapshots.Actions (A11y.Actions.Scroll_Into_View) := True;
   Snapshots.Actions (A11y.Actions.Close) := True;
   Snapshots.Action_Node := Child;
   Snapshots.Action_Root := Root;
   A11y.Trees.Set_Root (Snapshots.Action_Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Action_Tree, Root, Child, Result);
   Snapshots.Hierarchy.Session := Session;
   Snapshots.Hierarchy.Root := Root;
   Snapshots.Hierarchy.Node := Root;
   Snapshots.Relation_Source := Root;
   Snapshots.Relation_Root := Root;
   A11y.Trees.Set_Root (Snapshots.Relation_Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Relation_Tree, Root, Child, Result);
   Snapshots.Value.Id := Child;
   Snapshots.Value.Root := Root;
   A11y.Trees.Set_Root (Snapshots.Value.Tree, Root, Result);
   A11y.Trees.Attach (Snapshots.Value.Tree, Root, Child, Result);
   Snapshots.Value.Metadata.Current := A11y.Values.Exact_Decimal
     (Units => 125, Scale => 1);
   Snapshots.Value.Metadata.Minimum :=
     A11y.Values.Exact_Decimal (Units => 0, Scale => 1);
   Snapshots.Value.Metadata.Maximum :=
     A11y.Values.Exact_Decimal (Units => 200, Scale => 1);
   Snapshots.Value.Metadata.Small_Increment :=
     A11y.Values.Exact_Decimal (Units => 10, Scale => 1);
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
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Press",
      "macOS NSAccessibility request router dispatches attribute queries");
   Check
     (A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Label)
      = A11y.Properties.Accessible_Name,
      "macOS NSAccessibility label attribute maps to the neutral accessible name");
   Check
     (A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Title)
      = A11y.Properties.Visible_Title,
      "macOS NSAccessibility title attribute maps to the neutral visible title");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Press",
      "macOS NSAccessibility request router dispatches visible-title attributes");

   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Placeholder;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Type a value",
      "macOS NSAccessibility request router dispatches placeholder attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Ready",
      "macOS NSAccessibility request router dispatches value-text attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Identifier;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "primary-action",
      "macOS NSAccessibility request router dispatches identifier attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Description;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "Submits the current dialog",
      "macOS NSAccessibility request router dispatches description attributes");

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
         Description  => "Metadata-backed NSAccessibility window",
         Help_Text    => A11y.Properties.Present ("Metadata help"),
         Placeholder  => A11y.Properties.Present ("Metadata placeholder"),
         Value_Text   => A11y.Properties.Present ("Metadata value"),
         Protected_Value_Text => False,
         Bounds       =>
           A11y.Properties.Present
             ((Origin => (X => 121, Y => 232),
               Extent => (Width => 343, Height => 54))),
         Semantic_Identifier => A11y.Properties.Present ("metadata-nsax-id"),
         Visible_Title => A11y.Properties.Present ("Metadata NSAX Title"),
         Keyboard_Shortcut => A11y.Properties.Present ("Command+M"),
         Locale       => A11y.Properties.Present ("fr-CA"),
         Orientation  => A11y.Properties.Present ("horizontal"),
         Landmark     => A11y.Properties.Present ("main"),
         States       => A11y.States.Empty_State_Set,
         Capabilities => Caps,
         Exposure     => A11y.Nodes.Expose_Node,
         Result       => Result);
      Check
        (Result.Status = A11y.Results.Unsupported_Capability,
         "macOS NSAccessibility metadata fixture rejects role-incompatible metadata");

      Caps (A11y.Capabilities.Surface) := True;
      A11y.Semantic_Snapshots.Set_Node
        (Snapshot     => Metadata_Snapshot.Properties.Nodes,
         Node         => Child,
         Role         => A11y.Roles.Window,
         Name         => "Metadata Window",
         Description  => "Metadata-backed NSAccessibility window",
         Help_Text    => A11y.Properties.Present ("Metadata help"),
         Placeholder  => A11y.Properties.Present ("Metadata placeholder"),
         Value_Text   => A11y.Properties.Present ("Metadata value"),
         Protected_Value_Text => False,
         Bounds       =>
           A11y.Properties.Present
             ((Origin => (X => 121, Y => 232),
               Extent => (Width => 343, Height => 54))),
         Semantic_Identifier => A11y.Properties.Present ("metadata-nsax-id"),
         Visible_Title => A11y.Properties.Present ("Metadata NSAX Title"),
         Keyboard_Shortcut => A11y.Properties.Present ("Command+M"),
         Locale       => A11y.Properties.Present ("fr-CA"),
         Orientation  => A11y.Properties.Present ("horizontal"),
         Landmark     => A11y.Properties.Present ("main"),
         States       => A11y.States.Empty_State_Set,
         Capabilities => Caps,
         Exposure     => A11y.Nodes.Expose_Node,
         Result       => Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility metadata fixture stores per-node semantic metadata");
      declare
         Metadata : constant A11y.Semantic_Snapshots.Node_Metadata :=
           A11y.Semantic_Snapshots.Metadata
             (Metadata_Snapshot.Properties.Nodes, Child);
      begin
         Check
           (Metadata.Bounds.Status = A11y.Properties.Present
            and then Metadata.Bounds.Value.Origin.X = 121
            and then Metadata.Semantic_Identifier.Status =
              A11y.Properties.Present
            and then Metadata.Visible_Title.Status = A11y.Properties.Present
            and then Metadata.Keyboard_Shortcut.Status =
              A11y.Properties.Present
            and then Metadata.Locale.Status = A11y.Properties.Present
            and then Metadata.Orientation.Status = A11y.Properties.Present
            and then Metadata.Landmark.Status = A11y.Properties.Present,
            "macOS NSAccessibility metadata fixture stores per-node title, shortcut, locale, orientation, landmark, bounds, and identifier metadata");
      end;

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Label;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata Window",
         "macOS NSAccessibility request router resolves labels from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Role;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_Role
         and then Routed.Role =
           A11y.MacOS_Backend.NSAccessibility_Mappings.Window,
         "macOS NSAccessibility request router resolves roles from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Frame;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      declare
         Attribute_Reply : constant
           A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
             A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
               (Metadata_Snapshot.Properties,
                A11y.MacOS_Backend.NSAccessibility_Properties.Frame);
      begin
         Check
           (Attribute_Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Properties.Rectangle_Reply,
            "macOS NSAccessibility property mapper returns a rectangle for metadata frames");
         Check
           (Attribute_Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Properties.Rectangle_Reply
            and then Attribute_Reply.Bounds.Origin.X = 121
           and then Attribute_Reply.Bounds.Origin.Y = 232
           and then Attribute_Reply.Bounds.Extent.Width = 343
           and then Attribute_Reply.Bounds.Extent.Height = 54,
            "macOS NSAccessibility property mapper resolves frames from semantic metadata snapshots");
      end;

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Help;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata help",
         "macOS NSAccessibility request router resolves help text from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Identifier;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "metadata-nsax-id",
         "macOS NSAccessibility request router resolves identifiers from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Title;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata NSAX Title",
         "macOS NSAccessibility request router resolves visible titles from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Keyboard_Shortcut;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Command+M",
         "macOS NSAccessibility request router resolves keyboard shortcuts from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Locale;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) = "fr-CA",
         "macOS NSAccessibility request router resolves locales from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Orientation;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) =
           "horizontal",
         "macOS NSAccessibility request router resolves orientations from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Landmark;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text) = "main",
         "macOS NSAccessibility request router resolves landmarks from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Placeholder;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata placeholder",
         "macOS NSAccessibility request router resolves placeholders from semantic metadata snapshots");

      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Attribute_String
         and then Ada.Strings.Unbounded.To_String (Routed.Text)
           = "Metadata value",
         "macOS NSAccessibility request router resolves value text from semantic metadata snapshots");

      A11y.Semantic_Snapshots.Set_Node
        (Snapshot     => Metadata_Snapshot.Properties.Nodes,
         Node         => Child,
         Role         => A11y.Roles.Window,
         Name         => "Metadata Window",
         Description  => "Metadata-backed NSAccessibility window",
         Help_Text    => A11y.Properties.Present ("Metadata help"),
         Placeholder  => A11y.Properties.Present ("Metadata placeholder"),
         Value_Text   => A11y.Properties.Present ("Secret metadata value"),
         Protected_Value_Text => True,
         Bounds       =>
           A11y.Properties.Present
             ((Origin => (X => 121, Y => 232),
               Extent => (Width => 343, Height => 54))),
         Semantic_Identifier => A11y.Properties.Present ("metadata-nsax-id"),
         Visible_Title => A11y.Properties.Present ("Metadata NSAX Title"),
         Keyboard_Shortcut => A11y.Properties.Present ("Command+M"),
         Locale       => A11y.Properties.Present ("fr-CA"),
         Orientation  => A11y.Properties.Present ("horizontal"),
         Landmark     => A11y.Properties.Present ("main"),
         States       => A11y.States.Empty_State_Set,
         Capabilities => Caps,
         Exposure     => A11y.Nodes.Expose_Node,
         Result       => Result);
      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (A11y.Results.Succeeded (Result)
         and then Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Permission_Denied,
         "macOS NSAccessibility request router enforces protected value text from semantic metadata snapshots");

      A11y.Semantic_Snapshots.Clear_Node
        (Metadata_Snapshot.Properties.Nodes, Child, Result);
      Request_Item.Attribute :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Label;
      Routed := Dispatch (Request_Item, Metadata_Snapshot);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility request router rejects metadata-mode nodes without semantic metadata");
   end;
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Locale;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "da-DK",
      "macOS NSAccessibility request router dispatches locale attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Orientation;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "vertical",
      "macOS NSAccessibility request router dispatches orientation attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Position_In_Set;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_Integer
      and then Routed.Integer_Item = 2,
      "macOS NSAccessibility request router dispatches set-position attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Size_Of_Set;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_Integer
      and then Routed.Integer_Item = 5,
      "macOS NSAccessibility request router dispatches set-size attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Hierarchical_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_Integer
      and then Routed.Integer_Item = 3,
      "macOS NSAccessibility request router dispatches hierarchical-level attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Heading_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_Integer
      and then Routed.Integer_Item = 2,
      "macOS NSAccessibility request router dispatches heading-level attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Landmark;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "main",
      "macOS NSAccessibility request router dispatches landmark attributes");
   Check
     (A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Placeholder)
      = A11y.Properties.Placeholder
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text)
      = A11y.Properties.Value_Text
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Identifier)
      = A11y.Properties.Semantic_Identifier
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Description)
      = A11y.Properties.Description
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Locale)
      = A11y.Properties.Locale
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Orientation)
      = A11y.Properties.Orientation
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Position_In_Set)
      = A11y.Properties.Set_Position
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Size_Of_Set)
      = A11y.Properties.Set_Size
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Hierarchical_Level)
      = A11y.Properties.Hierarchical_Level
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Heading_Level)
      = A11y.Properties.Heading_Level
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Landmark)
      = A11y.Properties.Landmark
      and then A11y.MacOS_Backend.NSAccessibility_Properties.Neutral_Property
        (A11y.MacOS_Backend.NSAccessibility_Properties.Frame)
      = A11y.Properties.Bounds,
      "macOS NSAccessibility attributes map back to neutral property identifiers");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Label);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "Primary action",
         "macOS NSAccessibility property mapper preserves accessible names");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Title);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "Press",
         "macOS NSAccessibility property mapper preserves visible titles");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Orientation);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "vertical",
         "macOS NSAccessibility property mapper preserves orientation attributes");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "Ready",
         "macOS NSAccessibility property mapper preserves value text");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Description);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "Submits the current dialog",
         "macOS NSAccessibility property mapper preserves descriptions");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Locale);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "da-DK",
         "macOS NSAccessibility property mapper preserves locale properties");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Position_In_Set);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Integer_Reply
         and then Attribute_Reply.Integer_Item = 2,
         "macOS NSAccessibility property mapper preserves set-position attributes");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Heading_Level);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Integer_Reply
         and then Attribute_Reply.Integer_Item = 2,
         "macOS NSAccessibility property mapper preserves heading-level attributes");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Landmark);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "main",
         "macOS NSAccessibility property mapper preserves landmark attributes");
   end;

   declare
      Invalid_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Attribute_Reply :
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply;
   begin
      Invalid_Snapshot.Hierarchical_Level := A11y.Properties.Present (-1);
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Invalid_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Hierarchical_Level);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Invalid_Range,
         "macOS NSAccessibility property mapper rejects negative structural metadata");

      Invalid_Snapshot := Snapshots.Properties;
      Invalid_Snapshot.Heading_Level := A11y.Properties.Present (-1);
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Invalid_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Heading_Level);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Invalid_Range,
         "macOS NSAccessibility property mapper rejects negative heading levels");
   end;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Identifier);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.String_Reply
         and then Ada.Strings.Unbounded.To_String (Attribute_Reply.Text)
           = "primary-action",
         "macOS NSAccessibility property mapper preserves identifiers");
   end;

   declare
      Limited_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Attribute_Reply :
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply;
   begin
      A11y.Resource_Limits.Set_Limit
        (Limited_Snapshot.Limits,
         A11y.Resource_Limits.Native_String_Size,
         3,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility property mapper configures native string limit");

      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Limited_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Resource_Limit,
         "macOS NSAccessibility property mapper bounds native string replies");

      Limited_Snapshot := Snapshots.Properties;
      A11y.Resource_Limits.Set_Limit
        (Limited_Snapshot.Limits,
         A11y.Resource_Limits.Native_Array_Size,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility property mapper configures native array limit");

      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Limited_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Position_In_Set);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Resource_Limit,
         "macOS NSAccessibility property mapper bounds structural set-position attributes");

      Limited_Snapshot := Snapshots.Properties;
      A11y.Resource_Limits.Set_Limit
        (Limited_Snapshot.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility property mapper configures traversal-depth limit");

      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Limited_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Heading_Level);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Resource_Limit,
         "macOS NSAccessibility property mapper bounds structural heading-level attributes");

      Limited_Snapshot := Snapshots.Properties;
      Limited_Snapshot.Limits.Limits
        (A11y.Resource_Limits.Native_String_Size) := 0;
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Limited_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Heading_Level);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility property mapper rejects invalid limit configs before native attributes");

      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute_Names
          (Limited_Snapshot);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility property mapper rejects invalid limit configs before attribute lists");
   end;

   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Native_String_Size, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router applies configured attribute string limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   declare
      Attribute_Reply :
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply;
   begin
      declare
         Deep_Property : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (723);
      begin
         Snapshots.Properties.Use_Tree_Projection := True;
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
         Request_Item.Attribute :=
           A11y.MacOS_Backend.NSAccessibility_Properties.Title;
         Routed := Dispatch (Request_Item, Snapshots.all);
         Check
           (Routed.Kind = Routed_Error
            and then Routed.Status = A11y.Results.Node_Unavailable,
            "macOS NSAccessibility request router applies configured Attribute traversal limits");
         Snapshots.Limits := A11y.Resource_Limits.Default_Config;
         Snapshots.Properties.Id := Root;
      end;

      Snapshots.Properties.Use_Tree_Projection := True;
      Snapshots.Properties.Exposure
        (A11y.Node_Ids.To_Natural (Root)) :=
           A11y.Nodes.Hide_Node_And_Subtree;
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Snapshots.Properties,
           A11y.MacOS_Backend.NSAccessibility_Properties.Title);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility property mapper rejects hidden attribute nodes");
      Snapshots.Properties.Exposure
        (A11y.Node_Ids.To_Natural (Root)) := A11y.Nodes.Expose_Node;
      Snapshots.Properties.Use_Tree_Projection := False;
   end;

   declare
      Derived_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Attribute_Reply :
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply;
   begin
      Derived_Snapshot.Role := A11y.Roles.Text_Field;
      Derived_Snapshot.States := A11y.States.Empty_State_Set;
      Derived_Snapshot.Capabilities :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set, A11y.Capabilities.Text);
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Derived_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Enabled);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Boolean_Reply,
         "macOS NSAccessibility property mapper accepts derived state snapshots");
   end;

   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Frame;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_Rectangle
      and then Routed.Bounds = Snapshots.Properties.Bounds,
      "macOS NSAccessibility request router dispatches frame attributes");
   Request_Item.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;

   declare
      Attribute_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
            (Snapshots.Properties,
             A11y.MacOS_Backend.NSAccessibility_Properties.Frame);
   begin
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Rectangle_Reply
         and then Attribute_Reply.Bounds.Origin.X = -20
         and then Attribute_Reply.Bounds.Origin.Y = 30
         and then Attribute_Reply.Bounds.Extent.Width = 90
         and then Attribute_Reply.Bounds.Extent.Height = 26,
         "macOS NSAccessibility property mapper returns neutral logical frames");
   end;

   Check
     (A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Role
        (A11y.Roles.Password_Field)
      = A11y.MacOS_Backend.NSAccessibility_Mappings.Secure_Text_Field,
      "macOS NSAccessibility mapper marks password fields as secure text fields");

   Check
     (A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Role
        (A11y.Roles.Heading)
      = A11y.MacOS_Backend.NSAccessibility_Mappings.Heading,
      "macOS NSAccessibility mapper preserves semantic heading roles");

   declare
      Protected_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Attribute_Reply :
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply;
   begin
      Protected_Snapshot.Role := A11y.Roles.Password_Field;
      Protected_Snapshot.Value_Text := A11y.Properties.Present ("secret");
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Protected_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Permission_Denied,
         "macOS NSAccessibility property mapper blocks password value text");

      Protected_Snapshot.Role := A11y.Roles.Text_Field;
      Protected_Snapshot.Protected_Value_Text := True;
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Protected_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Value_Text);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Permission_Denied,
         "macOS NSAccessibility property mapper blocks protected value text");
   end;

   declare
      Invalid_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Properties.Property_Snapshot :=
          Snapshots.Properties;
      Attribute_Reply :
        A11y.MacOS_Backend.NSAccessibility_Properties.Attribute_Reply;
   begin
      Invalid_Snapshot.Role := A11y.Roles.Custom;
      Invalid_Snapshot.States := A11y.States.With_State
        (A11y.States.Empty_State_Set, A11y.States.Focused);
      Attribute_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Properties.Query_Attribute
          (Invalid_Snapshot,
           A11y.MacOS_Backend.NSAccessibility_Properties.Focused);
      Check
        (Attribute_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Properties.Error_Reply
         and then Attribute_Reply.Status = A11y.Results.Invalid_State,
         "macOS NSAccessibility property mapper rejects invalid state snapshots");
   end;

   Request_Item.Kind := Attribute_Names_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Attribute_Set
      and then Routed.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Role)
      and then Routed.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Title)
      and then Routed.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Frame)
      and then Routed.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Enabled),
      "macOS NSAccessibility request router dispatches attribute-name sets");

   Request_Item.Kind := Action_Set_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Action_Set
      and then Routed.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Press)
      and then Routed.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Expand)
      and then Routed.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Scroll_To_Visible)
      and then Routed.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Cancel)
      and then not Routed.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Show_Menu),
      "macOS NSAccessibility request router dispatches semantic action sets");

   Request_Item.Kind := Action_Map_Query;
   Request_Item.Action := A11y.Actions.Press;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Action_Mapping
      and then Routed.Mapping.Supported
      and then Routed.Mapping.Native =
        A11y.MacOS_Backend.NSAccessibility_Actions.Press,
      "macOS NSAccessibility request router dispatches action mapping payloads");

   Request_Item.Kind := Action_Request_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Action_Request
      and then Routed.Requested_Action = A11y.Actions.Press,
      "macOS NSAccessibility request router stages action requests");

   Snapshots.Action_States (A11y.States.Busy) := True;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Busy,
      "macOS NSAccessibility request router applies action state preconditions");
   Snapshots.Action_States (A11y.States.Busy) := False;

   Snapshots.Action_Use_Tree_Projection := True;
   Snapshots.Action_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility action routing rejects hidden action nodes");
   Request_Item.Kind := Action_Set_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility action discovery rejects hidden action nodes");
   Snapshots.Action_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Action_Use_Tree_Projection := False;
   Request_Item.Kind := Action_Map_Query;

   declare
      Actions : A11y.Actions.Action_Set := Snapshots.Actions;
      Action_Set : A11y.MacOS_Backend.NSAccessibility_Actions.NSAX_Action_Set;
      Mapping : A11y.MacOS_Backend.NSAccessibility_Actions.Action_Mapping;
      States : A11y.States.State_Set := A11y.States.Empty_State_Set;
   begin
      Actions (A11y.Actions.Toggle) := True;
      Actions (A11y.Actions.Expand) := True;
      Actions (A11y.Actions.Collapse) := True;
      Actions (A11y.Actions.Show_Menu) := True;
      Actions (A11y.Actions.Dismiss) := True;
      Actions (A11y.Actions.Open) := True;
      Actions (A11y.Actions.Close) := True;
      Actions (A11y.Actions.Set_Focus) := True;
      Actions (A11y.Actions.Scroll_Into_View) := True;
      Action_Set := A11y.MacOS_Backend.NSAccessibility_Actions.Action_Set
        (Actions);
      Check
        (Action_Set (A11y.MacOS_Backend.NSAccessibility_Actions.Expand),
         "macOS NSAccessibility action discovery exposes expand");
      Check
        (Action_Set (A11y.MacOS_Backend.NSAccessibility_Actions.Collapse),
         "macOS NSAccessibility action discovery exposes collapse");
      Check
        (Action_Set (A11y.MacOS_Backend.NSAccessibility_Actions.Show_Menu),
         "macOS NSAccessibility action discovery exposes show-menu");
      Check
        (Action_Set (A11y.MacOS_Backend.NSAccessibility_Actions.Confirm),
         "macOS NSAccessibility action discovery exposes open");
      Check
        (Action_Set (A11y.MacOS_Backend.NSAccessibility_Actions.Cancel),
         "macOS NSAccessibility action discovery exposes dismiss and close");
      Check
        (Action_Set (A11y.MacOS_Backend.NSAccessibility_Actions.Raise_Item),
         "macOS NSAccessibility action discovery exposes set-focus");
      Check
        (Action_Set
           (A11y.MacOS_Backend.NSAccessibility_Actions.Scroll_To_Visible),
         "macOS NSAccessibility action discovery exposes scroll-into-view");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Toggle);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Press,
         "macOS NSAccessibility action mapper exposes toggle through press");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Expand);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Expand,
         "macOS NSAccessibility action mapper exposes expand");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Collapse);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Collapse,
         "macOS NSAccessibility action mapper exposes collapse");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Show_Menu);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Show_Menu,
         "macOS NSAccessibility action mapper exposes show-menu");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Dismiss);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Cancel,
         "macOS NSAccessibility action mapper exposes dismiss through cancel");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Open);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Confirm,
         "macOS NSAccessibility action mapper exposes open through confirm");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Close);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Cancel,
         "macOS NSAccessibility action mapper exposes close through cancel");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Set_Focus);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Raise_Item,
         "macOS NSAccessibility action mapper exposes set-focus through raise");

      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Scroll_Into_View);
      Check
        (Mapping.Supported
         and then Mapping.Native =
           A11y.MacOS_Backend.NSAccessibility_Actions.Scroll_To_Visible,
         "macOS NSAccessibility action mapper exposes scroll-into-view");

      States (A11y.States.Enabled) := True;
      States (A11y.States.Busy) := True;
      Mapping := A11y.MacOS_Backend.NSAccessibility_Actions.Map_Action
        (Actions, A11y.Actions.Toggle, States);
      Check
        (not Mapping.Supported
         and then Mapping.Status = A11y.Results.Busy,
         "macOS NSAccessibility action mapper applies state preconditions");
   end;

   Request_Item.Kind := Children_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Hierarchy_Children,
      "macOS NSAccessibility request router dispatches children queries");
   Check
     (Routed.Kind = Hierarchy_Children
      and then not Routed.Children.Is_Empty
      and then Routed.Children (Routed.Children.First_Index) = Child,
      "macOS NSAccessibility request router preserves children query payloads");

   Request_Item.Kind := Child_At_Query;
   Request_Item.Child_Index := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Hierarchy_Node
      and then Routed.Node = Child,
      "macOS NSAccessibility request router dispatches indexed child queries with target identity");

   Request_Item.Kind := Parent_Query;
   Snapshots.Hierarchy.Node := Child;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Hierarchy_Node
      and then Routed.Node = Root,
      "macOS NSAccessibility request router dispatches parent queries with target identity");

   declare
      Deep_Hierarchy : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (724);
   begin
      A11y.Trees.Attach
        (Snapshots.Hierarchy.Tree, Child, Deep_Hierarchy, Result);
      Snapshots.Hierarchy.Node := Deep_Hierarchy;
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility request router applies configured Hierarchy traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Snapshots.Hierarchy.Node := Child;
   end;

   declare
      subtype Hierarchy_Snapshot is
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Hierarchy_Snapshot;
      subtype Children_Reply_Type is
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Children_Reply;
      subtype Node_Reply_Type is
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Node_Reply;
      Snapshot : Hierarchy_Snapshot;
      Flattened : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (712);
      Button : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (713);
      Hidden : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (714);
      Hidden_Button : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (715);
      Trailing : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (716);
      Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Children_Reply : Children_Reply_Type;
      Node_Reply : Node_Reply_Type;
      Element_Reply :
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Element_Id_Reply;
   begin
      Invalid_Limits.Limits
        (A11y.Resource_Limits.Native_Array_Size) := 0;

      Snapshot.Session := Session;
      Snapshot.Root := Root;
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

      Children_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Children (Snapshot);
      Check
        (Children_Reply.Available
         and then Natural (Children_Reply.Children.Length) = 2
         and then Children_Reply.Children (1) = Button
         and then Children_Reply.Children (2) = Trailing,
         "macOS NSAccessibility hierarchy flattens and hides children");

      Node_Reply := A11y.MacOS_Backend.NSAccessibility_Hierarchy.Child_At
        (Snapshot, 1);
      Check
        (Node_Reply.Found and then Node_Reply.Node = Button,
         "macOS NSAccessibility hierarchy indexes exposed children");

      Snapshot.Node := Button;
      Node_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Parent (Snapshot);
      Check
        (Node_Reply.Found and then Node_Reply.Node = Root,
         "macOS NSAccessibility hierarchy skips flattened parents");

      Snapshot.Node := Hidden_Button;
      Node_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Parent (Snapshot);
      Check
        (not Node_Reply.Found
         and then Node_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility hierarchy rejects hidden native nodes");

      Children_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Children (Snapshot);
      Check
        (not Children_Reply.Available
         and then Children_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility hierarchy rejects hidden child queries");

      Snapshot.Defunct := True;
      Node_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Parent
          (Snapshot, Invalid_Limits);
      Check
        (not Node_Reply.Found
         and then Node_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility hierarchy mapper rejects invalid limit configs before parent queries");

      Children_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Children
          (Snapshot, Invalid_Limits);
      Check
        (not Children_Reply.Available
         and then Children_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility hierarchy mapper rejects invalid limit configs before child lists");

      Node_Reply := A11y.MacOS_Backend.NSAccessibility_Hierarchy.Child_At
        (Snapshot, 1, Invalid_Limits);
      Check
        (not Node_Reply.Found
         and then Node_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility hierarchy mapper rejects invalid limit configs before indexed children");

      Element_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Build_Element_Id
          (Snapshot, Invalid_Limits);
      Check
        (not Element_Reply.Available
         and then Element_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility hierarchy mapper rejects invalid limit configs before element ids");
   end;

   Request_Item.Kind := Element_Id_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
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
         and then Routed.Kind = Element_Id
         and then Routed.Id.Session_Component =
           A11y.Native_Identity.To_Natural (Session)
         and then Routed.Id.Root_Component = Root_Component
         and then Routed.Id.Node_Component = Node_Component,
         "macOS NSAccessibility request router dispatches element identity queries with stable payload");
   end;

   Snapshots.Hierarchy.Node := Child;
   Snapshots.Hierarchy.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility element identities reject hidden native nodes");
   Snapshots.Hierarchy.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Expose_Node;
   Snapshots.Hierarchy.Node := Root;

   Request_Item.Kind := Relation_Query;
   Request_Item.Relation := A11y.Relations.Labelled_By;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Targets,
      "macOS NSAccessibility request router dispatches relation target queries");
   Check
     (Routed.Relation_Attribute =
        A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element,
      "macOS NSAccessibility relation target replies preserve the native relation attribute");

   Snapshots.Relation_Use_Tree_Projection := True;
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Empty,
      "macOS NSAccessibility relation routing filters hidden targets");
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility relation routing rejects hidden source nodes");
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Relation_Exposure (A11y.Node_Ids.To_Natural (Child)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Relation_Use_Tree_Projection := False;

   Request_Item.Relation := A11y.Relations.Embedded_By;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Not_Supported
      and then Routed.Status = A11y.Results.Unsupported_Capability,
      "macOS NSAccessibility request router preserves unsupported relation mappings");

   Request_Item.Relation := A11y.Relations.Details;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Relation_Empty,
      "macOS NSAccessibility request router reports empty relation targets");

   A11y.Relations.Add
     (Snapshots.Relations,
      Root,
      A11y.Relations.Details,
      A11y.Node_Ids.From_Natural (712),
      Result);
   A11y.Relations.Add
     (Snapshots.Relations,
      Root,
      A11y.Relations.Details,
      A11y.Node_Ids.From_Natural (713),
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
      "macOS NSAccessibility request router bounds relation targets");
   Snapshots.Limits.Limits
     (A11y.Resource_Limits.Relation_Targets_Returned) := 0;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Argument,
      "macOS NSAccessibility request router rejects invalid relation limits");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits,
      A11y.Resource_Limits.Relation_Targets_Returned,
      4_096,
      Result);

   Request_Item.Kind := Value_Query;
   Request_Item.Value := A11y.MacOS_Backend.NSAccessibility_Values.Value;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Float
      and then Routed.Float_Item = 12.5,
      "macOS NSAccessibility request router dispatches value queries");

   Request_Item.Value := A11y.MacOS_Backend.NSAccessibility_Values.Is_Read_Only;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Boolean
      and then not Routed.Boolean_Item,
      "macOS NSAccessibility request router dispatches read-only value queries");

   Request_Item.Kind := Value_Set_Query;
   Request_Item.Requested_Value :=
     A11y.Values.Exact_Decimal (Units => 150, Scale => 1);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Set_Request
      and then A11y.Values.Equal
        (Routed.Requested_Value,
         A11y.Values.Exact_Decimal (Units => 150, Scale => 1)),
      "macOS NSAccessibility request router validates value set requests");

   Request_Item.Requested_Value := A11y.Values.Boolean (False);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Argument,
      "macOS NSAccessibility request router rejects nonnumeric value set requests");

   Request_Item.Requested_Value :=
     A11y.Values.Exact_Decimal (Units => 150, Scale => 1);
   Snapshots.Value.Metadata.Mode := A11y.Values.Read_Only;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Read_Only,
      "macOS NSAccessibility request router rejects read-only value set requests");
   Snapshots.Value.Metadata.Mode := A11y.Values.Writable;

   Request_Item.Kind := Value_Query;
   Request_Item.Value := A11y.MacOS_Backend.NSAccessibility_Values.Value;
   Snapshots.Value.Metadata.Minimum := A11y.Values.Boolean (False);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Argument,
      "macOS NSAccessibility request router validates value metadata");
   Snapshots.Value.Metadata.Minimum :=
     A11y.Values.Exact_Decimal (Units => 0, Scale => 1);

   Snapshots.Value.Metadata.Units :=
     Ada.Strings.Unbounded.To_Unbounded_String ("12345");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router applies configured value text limits");
   Snapshots.Value.Metadata.Units :=
     Ada.Strings.Unbounded.To_Unbounded_String ("px");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Value := A11y.MacOS_Backend.NSAccessibility_Values.Increment;
   Snapshots.Value.Metadata.Small_Increment := (Kind => A11y.Values.Unknown);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Value_Not_Applicable
      and then Routed.Status = A11y.Results.Unsupported_Property,
      "macOS NSAccessibility request router preserves absent value metadata");
   Snapshots.Value.Metadata.Small_Increment :=
     A11y.Values.Exact_Decimal (Units => 10, Scale => 1);

   Snapshots.Value.Use_Tree_Projection := True;
   Snapshots.Value.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Hide_Node_And_Subtree;
   Request_Item.Value := A11y.MacOS_Backend.NSAccessibility_Values.Value;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility value mapper rejects hidden value nodes");
   Request_Item.Kind := Value_Set_Query;
   Request_Item.Requested_Value :=
     A11y.Values.Exact_Decimal (Units => 150, Scale => 1);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility value mapper rejects hidden value set requests");
   Snapshots.Value.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Expose_Node;
   Snapshots.Value.Use_Tree_Projection := False;

   declare
      Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Value_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Values.Value_Snapshot :=
          Snapshots.Value;
      Value_Reply : A11y.MacOS_Backend.NSAccessibility_Values.Value_Reply;
   begin
      Invalid_Limits.Limits (A11y.Resource_Limits.Text_Returned) := 0;
      Value_Snapshot.Defunct := True;

      Value_Reply := A11y.MacOS_Backend.NSAccessibility_Values.Query_Value
        (Value_Snapshot,
         A11y.MacOS_Backend.NSAccessibility_Values.Value,
         Invalid_Limits);
      Check
        (Value_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Values.Error_Reply
         and then Value_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility value mapper rejects invalid limit configs before value queries");

      Value_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Values.Request_Value_Set
          (Value_Snapshot,
           A11y.Values.Exact_Decimal (Units => 160, Scale => 1),
           Invalid_Limits);
      Check
        (Value_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Values.Error_Reply
         and then Value_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility value mapper rejects invalid limit configs before value set requests");
   end;

   Request_Item.Kind := Selection_Query;
   Request_Item.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_UInt32
      and then Routed.UInt32 = 1,
      "macOS NSAccessibility request router dispatches selected-count queries");

   Request_Item.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Item;
   Request_Item.Index := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Node
      and then Routed.Node = Child,
      "macOS NSAccessibility request router dispatches selected-item queries");

   Request_Item.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Is_Item_Selected;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Boolean
      and then Routed.Boolean_Item,
      "macOS NSAccessibility request router dispatches selection membership queries");

   Request_Item.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Anchor_Item;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Node
      and then Routed.Node = Child,
      "macOS NSAccessibility request router dispatches selection anchor queries");

   Request_Item.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Direction;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Direction
      and then Routed.Direction = A11y.Selection.No_Direction,
      "macOS NSAccessibility request router dispatches selection direction queries");

   declare
      Exposed : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (717);
      Hidden : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (718);
      Hidden_Item : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (719);
      Deep_Item : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (720);
      Selection_Reply :
        A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Reply;
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
      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Direction);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Direction_Reply
         and then Selection_Reply.Direction = A11y.Selection.Backward,
         "macOS NSAccessibility selection routing exposes semantic range direction");

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

      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.UInt32_Reply
         and then Selection_Reply.UInt32 = 1,
         "macOS NSAccessibility selection routing counts exposed selections");

      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_Array_Size) := 0;
         Selection_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
             (Snapshots.Selection,
              A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count,
              Invalid_Limits);
         Check
           (Selection_Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Selection.Error_Reply
            and then Selection_Reply.Status = A11y.Results.Invalid_Argument,
            "macOS NSAccessibility selection mapper rejects invalid query limits");

         Selection_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Selection.Request_Selection
             (Snapshots.Selection,
              A11y.MacOS_Backend.NSAccessibility_Selection.Select_All,
              A11y.Node_Ids.No_Node,
              Invalid_Limits);
         Check
           (Selection_Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Selection.Error_Reply
            and then Selection_Reply.Status = A11y.Results.Invalid_Argument,
            "macOS NSAccessibility selection mapper rejects invalid request limits");
      end;

      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Item,
           1);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Node_Reply
         and then Selection_Reply.Node = Exposed,
         "macOS NSAccessibility selection routing returns exposed selections");

      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Is_Item_Selected);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Boolean_Reply
         and then not Selection_Reply.Boolean_Item,
         "macOS NSAccessibility selection routing hides selected hidden items");

      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Current_Item);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Nil_Reply,
         "macOS NSAccessibility selection routing omits hidden current items");

      Snapshots.Selection.Item := Exposed;
      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Query_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Is_Item_Selected);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Boolean_Reply
         and then Selection_Reply.Boolean_Item,
         "macOS NSAccessibility selection routing keeps exposed selected items");

      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Request_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item,
           Exposed);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Request_Reply
         and then Selection_Reply.Node = Exposed,
         "macOS NSAccessibility selection routing stages exposed selection requests");

      Selection_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Request_Selection
          (Snapshots.Selection,
           A11y.MacOS_Backend.NSAccessibility_Selection.Select_Item,
           Hidden_Item);
      Check
        (Selection_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Selection.Error_Reply
         and then Selection_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility selection routing rejects hidden selection requests");

      A11y.Trees.Attach
        (Snapshots.Selection.Tree, Exposed, Deep_Item, Result);
      A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
      A11y.Selection.Select_Item
        (Snapshots.Selection.Selection, Deep_Item, Result);
      Request_Item.Kind := Selection_Query;
      Request_Item.Selection :=
        A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Item;
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
         "macOS NSAccessibility request router applies configured Selection traversal limits");
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
     A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item;
   Request_Item.Selection_Target := Child;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Request_Reply
      and then Routed.Selection_Target = Child
      and then Routed.Selection_Request =
        A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item,
      "macOS NSAccessibility request router preserves selection request payloads");

   Request_Item.Selection_Request :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Select_All;
   Request_Item.Selection_Target := A11y.Node_Ids.No_Node;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Selection_Request_Reply
      and then Routed.Selection_Target = A11y.Node_Ids.No_Node
      and then Routed.Selection_Request =
        A11y.MacOS_Backend.NSAccessibility_Selection.Select_All,
      "macOS NSAccessibility request router preserves select-all request payloads");

   A11y.Selection.Configure
     (Snapshots.Selection.Selection,
      A11y.Selection.Multiple);
   A11y.Selection.Clear (Snapshots.Selection.Selection, Result);
   A11y.Selection.Configure
     (Snapshots.Selection.Selection,
      A11y.Selection.Multiple,
      Requires_Selection => True);
   Request_Item.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "macOS NSAccessibility request router rejects invalid selection snapshots");
   Request_Item.Kind := Selection_Request_Query;
   Request_Item.Selection_Request :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Clear_Selection;
   Request_Item.Selection_Target := A11y.Node_Ids.No_Node;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "macOS NSAccessibility request router rejects invalid selection requests");
   A11y.Selection.Configure
     (Snapshots.Selection.Selection, A11y.Selection.Multiple);
   A11y.Selection.Select_Item
     (Snapshots.Selection.Selection, Child, Result);
   A11y.Selection.Set_Current_Item
     (Snapshots.Selection.Selection, Child, Result);
   Request_Item.Kind := Selection_Query;

   Request_Item.Kind := Text_Query;
   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Character_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 3,
      "macOS NSAccessibility request router dispatches text character counts");

   declare
      Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Text_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Text.Text_Snapshot :=
          Snapshots.Text;
      Text_Reply : A11y.MacOS_Backend.NSAccessibility_Text.Text_Reply;
   begin
      Invalid_Limits.Limits (A11y.Resource_Limits.Text_Returned) := 0;
      Text_Snapshot.Defunct := True;

      Text_Reply := A11y.MacOS_Backend.NSAccessibility_Text.Query_Text
        (Text_Snapshot,
         A11y.MacOS_Backend.NSAccessibility_Text.Character_Count,
         Invalid_Limits);
      Check
        (Text_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Text.Error_Reply
         and then Text_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility text mapper rejects invalid limit configs before text queries");

      Text_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Text.Request_Text_Edit
          (Text_Snapshot,
           A11y.Text.Insert_Text,
           Invalid_Limits,
           Replacement => "x");
      Check
        (Text_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Text.Error_Reply
         and then Text_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility text mapper rejects invalid limit configs before text edit requests");

      Text_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Text.Request_Grapheme_Text_Edit
          (Text_Snapshot,
           A11y.Text.Insert_Text,
           Invalid_Limits,
           Replacement => "x");
      Check
        (Text_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Text.Error_Reply
         and then Text_Reply.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility text mapper rejects invalid limit configs before grapheme text edits");
   end;

   Snapshots.Text.Content :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
       (Wide_Wide_String'("Ae")
        & Wide_Wide_Character'Val (16#0301#)
        & Wide_Wide_String'("B"));
   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Grapheme_Cluster_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 3,
      "macOS NSAccessibility request router dispatches grapheme cluster counts");
   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Grapheme_Text_Range;
   Request_Item.Index := 2;
   Request_Item.Count := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Wide_Text
      and then
        Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
          (Routed.Wide_Text)
          = Wide_Wide_String'("e") & Wide_Wide_Character'Val (16#0301#),
      "macOS NSAccessibility request router dispatches grapheme text ranges");
   declare
      Text_Reply : constant
        A11y.MacOS_Backend.NSAccessibility_Text.Text_Reply :=
          A11y.MacOS_Backend.NSAccessibility_Text.Request_Grapheme_Text_Edit
            (Snapshots.Text,
             A11y.Text.Delete_Text,
             Start => 1,
             Count => 1,
             Replacement => "");
   begin
      Check
        (Text_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Text.Edit_Request_Reply
         and then Text_Reply.Requested_Edit.Kind = A11y.Text.Delete_Text
         and then A11y.Text.Index
           (A11y.Text.First (Text_Reply.Requested_Edit.Span)) = 1
         and then A11y.Text.Length (Text_Reply.Requested_Edit.Span) = 2,
         "macOS NSAccessibility text layer validates grapheme-indexed edit requests");
   end;
   Snapshots.Text.Content :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
       (Wide_Wide_String'("A")
        & Wide_Wide_Character'Val (16#1F600#)
        & Wide_Wide_String'("B"));

   Request_Item.Text := A11y.MacOS_Backend.NSAccessibility_Text.Text_Range;
   Request_Item.Index := 2;
   Request_Item.Count := 2;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_Wide_Text
      and then
        Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
          (Routed.Wide_Text)
          = Wide_Wide_Character'Val (16#1F600#) & Wide_Wide_String'("B"),
      "macOS NSAccessibility request router dispatches neutral text range payloads");

   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 1, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router applies configured text range limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.UTF16_Unit_Count;
   Request_Item.Index := 2;
   Request_Item.Count := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 2,
      "macOS NSAccessibility request router dispatches UTF-16 unit counts");

   Request_Item.Text := A11y.MacOS_Backend.NSAccessibility_Text.Caret_Offset;
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (3);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Text_UInt32
      and then Routed.UInt32 = 3,
      "macOS NSAccessibility request router dispatches caret offsets at text end");
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (4);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Range,
      "macOS NSAccessibility request router rejects caret offsets outside content");
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (2);

   Snapshots.Text.Policy := A11y.Text.Protected_Text;
   Request_Item.Text := A11y.MacOS_Backend.NSAccessibility_Text.Text_Range;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "macOS NSAccessibility request router blocks protected text ranges");

   Request_Item.Index := Natural'Last;
   Request_Item.Count := 1;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "macOS NSAccessibility request router blocks protected text ranges before offset validation");

   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.UTF16_Unit_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "macOS NSAccessibility request router blocks protected UTF-16 offset conversion");

   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Character_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "macOS NSAccessibility request router blocks protected text character counts");

   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Grapheme_Cluster_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "macOS NSAccessibility request router blocks protected grapheme cluster counts");

   Request_Item.Text := A11y.MacOS_Backend.NSAccessibility_Text.Caret_Offset;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Permission_Denied,
      "macOS NSAccessibility request router blocks protected caret offsets");

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
      "macOS NSAccessibility request router dispatches text edit requests");

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
      "macOS NSAccessibility request router dispatches replace text requests");

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
      "macOS NSAccessibility request router dispatches set text requests");

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
      "macOS NSAccessibility request router blocks protected text edits");
   Snapshots.Text.Policy := A11y.Text.Plain_Text;

   Snapshots.Text.Read_Only := True;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Read_Only,
      "macOS NSAccessibility request router blocks read-only text edits");
   Snapshots.Text.Read_Only := False;

   Snapshots.Text.Use_Tree_Projection := True;
   Snapshots.Text.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility text mapper rejects hidden text edit nodes");
   Request_Item.Kind := Text_Query;
   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Character_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility text mapper rejects hidden text nodes");
   Snapshots.Text.Exposure
     (A11y.Node_Ids.To_Natural (Child)) := A11y.Nodes.Expose_Node;
   Snapshots.Text.Use_Tree_Projection := False;

   Request_Item.Kind := Text_Query;
   Request_Item.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Character_Count;
   Request_Item.Index := 1;
   Request_Item.Count := 0;
   Request_Item.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String;

   Request_Item.Kind := Table_Query;
   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Row_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 4,
      "macOS NSAccessibility request router dispatches table row counts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Displayed_Row_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 3,
      "macOS NSAccessibility request router dispatches displayed table row counts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Displayed_Column_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 4,
      "macOS NSAccessibility request router dispatches displayed table column counts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Visible_Row_Start;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 1,
      "macOS NSAccessibility request router dispatches visible table row starts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Visible_Row_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 2,
      "macOS NSAccessibility request router dispatches visible table row counts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Visible_Column_Start;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 1,
      "macOS NSAccessibility request router dispatches visible table column starts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Visible_Column_Count;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 2,
      "macOS NSAccessibility request router dispatches visible table column counts");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Current_Cell;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_Node
      and then Routed.Node = Child,
      "macOS NSAccessibility request router dispatches current table cells");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Sort_Order;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = A11y.Tables.Sort_Order'Pos
        (A11y.Tables.Ascending),
      "macOS NSAccessibility request router dispatches table sort order");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Sort_Key;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_Node
      and then Routed.Node = Child,
      "macOS NSAccessibility request router dispatches table sort keys");

   Request_Item.Table := A11y.MacOS_Backend.NSAccessibility_Table.Cell_At;
   Request_Item.Row := 1;
   Request_Item.Column := 2;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_Node
      and then Routed.Node = Child,
      "macOS NSAccessibility request router dispatches table cell lookups");

   Request_Item.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Column_Span;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Table_UInt32
      and then Routed.UInt32 = 3,
      "macOS NSAccessibility request router dispatches table span lookups");

   Request_Item.Row := 99;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Range,
      "macOS NSAccessibility request router rejects invalid table coordinates");
   Request_Item.Row := 0;
   Request_Item.Column := 0;

   declare
      Deep_Cell : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (721);
      Direct_Reply :
        A11y.MacOS_Backend.NSAccessibility_Table.Table_Reply;
   begin
      Snapshots.Table.Use_Tree_Projection := True;
      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
          (Snapshots.Table,
           A11y.MacOS_Backend.NSAccessibility_Table.Current_Cell);
      Check
        (Direct_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility table mapper hides projected current cells");

      Direct_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
          (Snapshots.Table,
           A11y.MacOS_Backend.NSAccessibility_Table.Sort_Key);
      Check
        (Direct_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility table mapper hides projected sort keys");

      Direct_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
          (Snapshots.Table,
           A11y.MacOS_Backend.NSAccessibility_Table.Cell_At,
           1,
           2);
      Check
        (Direct_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility table mapper hides projected cells");

      Direct_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
          (Snapshots.Table,
           A11y.MacOS_Backend.NSAccessibility_Table.Row_Span,
           1,
           2);
      Check
        (Direct_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility table mapper hides projected cell spans");

      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Root)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
          (Snapshots.Table,
           A11y.MacOS_Backend.NSAccessibility_Table.Row_Count);
      Check
        (Direct_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply
         and then Direct_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility table mapper rejects hidden table nodes");

      Snapshots.Table.Exposure
        (A11y.Node_Ids.To_Natural (Root)) :=
          A11y.Nodes.Expose_Node;
      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_Array_Size) := 0;
         Direct_Reply :=
           A11y.MacOS_Backend.NSAccessibility_Table.Query_Table
             (Snapshots.Table,
              A11y.MacOS_Backend.NSAccessibility_Table.Row_Count,
              Invalid_Limits);
         Check
           (Direct_Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Table.Error_Reply
            and then Direct_Reply.Status = A11y.Results.Invalid_Argument,
            "macOS NSAccessibility table mapper rejects invalid limit configs");
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
      Request_Item.Table :=
        A11y.MacOS_Backend.NSAccessibility_Table.Cell_At;
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
         "macOS NSAccessibility request router applies configured Table traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Request_Item.Row := 0;
      Request_Item.Column := 0;
      Snapshots.Table.Use_Tree_Projection := False;
   end;

   Request_Item.Kind := Image_Query;
   Request_Item.Image :=
     A11y.MacOS_Backend.NSAccessibility_Image.Description;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text)
        = "Revenue chart",
      "macOS NSAccessibility request router dispatches image descriptions");

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
      "macOS NSAccessibility request router bounds image description text");

   Snapshots.Image.Metadata.Alternative_Text :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Revenue chart");

   Request_Item.Image :=
     A11y.MacOS_Backend.NSAccessibility_Image.Caption;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Q1 revenue",
      "macOS NSAccessibility request router dispatches image captions");

   Snapshots.Image.Metadata.Kind := A11y.Images.Chart;
   Request_Item.Image :=
     A11y.MacOS_Backend.NSAccessibility_Image.Kind_Name;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "chart",
      "macOS NSAccessibility request router dispatches image categories");
   Snapshots.Image.Metadata.Kind := A11y.Images.Informative;
   Request_Item.Image :=
     A11y.MacOS_Backend.NSAccessibility_Image.Description;

   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router applies configured image text limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Image :=
     A11y.MacOS_Backend.NSAccessibility_Image.Intrinsic_Size;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Image_Size
      and then Routed.Size.Width = 640
      and then Routed.Size.Height = 480,
      "macOS NSAccessibility request router dispatches image sizes");

   declare
      Direct_Image :
        A11y.MacOS_Backend.NSAccessibility_Image.Image_Reply;
   begin
      Snapshots.Image.Use_Tree_Projection := True;
      Snapshots.Image.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Image :=
        A11y.MacOS_Backend.NSAccessibility_Image.Query_Image
          (Snapshots.Image,
           A11y.MacOS_Backend.NSAccessibility_Image.Description);
      Check
        (Direct_Image.Kind =
           A11y.MacOS_Backend.NSAccessibility_Image.Error_Reply
         and then Direct_Image.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility image mapper rejects hidden image nodes");

      Snapshots.Image.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      Snapshots.Image.Use_Tree_Projection := False;

      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
         Direct_Image :=
           A11y.MacOS_Backend.NSAccessibility_Image.Query_Image
             (Snapshots.Image,
              A11y.MacOS_Backend.NSAccessibility_Image.Intrinsic_Size,
              Invalid_Limits);
         Check
           (Direct_Image.Kind =
              A11y.MacOS_Backend.NSAccessibility_Image.Error_Reply
            and then Direct_Image.Status = A11y.Results.Invalid_Argument,
            "macOS NSAccessibility image mapper rejects invalid limit configs");
      end;
   end;

   Snapshots.Image.Metadata.Kind := A11y.Images.Decorative;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility request router omits decorative images");
   Snapshots.Image.Metadata.Kind := A11y.Images.Informative;

   Request_Item.Kind := Document_Query;
   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Role;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "heading",
      "macOS NSAccessibility request router dispatches document role metadata");

   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Locale;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "en-US",
      "macOS NSAccessibility request router dispatches document locale metadata");

   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Author;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "Ada Team",
      "macOS NSAccessibility request router dispatches document author metadata");

   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Current_Page;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_UInt32
      and then Routed.UInt32 = 4,
      "macOS NSAccessibility request router dispatches document current pages");

   Snapshots.Document.Metadata.Title :=
     Ada.Strings.Unbounded.To_Unbounded_String
       (String'
          (1 .. Natural
            (A11y.Resource_Limits.Value
               (A11y.Resource_Limits.Default_Config,
                A11y.Resource_Limits.Text_Returned)) + 1 => 'x'));
   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Title;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router bounds document metadata text");

   Snapshots.Document.Metadata.Title :=
     Ada.Strings.Unbounded.To_Unbounded_String ("Overview");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router applies configured document text limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Heading_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_UInt32
      and then Routed.UInt32 = 2,
      "macOS NSAccessibility request router dispatches document heading levels");

   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Is_Landmark;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Document_Boolean
      and then Routed.Boolean_Item,
      "macOS NSAccessibility request router dispatches document landmark state");

   declare
      Direct_Document :
        A11y.MacOS_Backend.NSAccessibility_Document.Document_Reply;
   begin
      Snapshots.Document.Use_Tree_Projection := True;
      Snapshots.Document.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Document :=
        A11y.MacOS_Backend.NSAccessibility_Document.Query_Document
          (Snapshots.Document,
           A11y.MacOS_Backend.NSAccessibility_Document.Locale);
      Check
        (Direct_Document.Kind =
           A11y.MacOS_Backend.NSAccessibility_Document.Error_Reply
         and then Direct_Document.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility document mapper rejects hidden document nodes");

      Snapshots.Document.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      Snapshots.Document.Use_Tree_Projection := False;

      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
         Direct_Document :=
           A11y.MacOS_Backend.NSAccessibility_Document.Query_Document
             (Snapshots.Document,
              A11y.MacOS_Backend.NSAccessibility_Document.Is_Landmark,
              Invalid_Limits);
         Check
           (Direct_Document.Kind =
              A11y.MacOS_Backend.NSAccessibility_Document.Error_Reply
            and then Direct_Document.Status = A11y.Results.Invalid_Argument,
            "macOS NSAccessibility document mapper rejects invalid limit configs");
      end;
   end;

   Snapshots.Document.Metadata.Heading_Level := 99;
   Request_Item.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Heading_Level;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_Range,
      "macOS NSAccessibility request router validates document heading levels");
   Snapshots.Document.Metadata.Heading_Level := 2;

   Request_Item.Kind := Live_Region_Query;
   Request_Item.Live_Region :=
     A11y.MacOS_Backend.NSAccessibility_Live_Regions.Relevant_Names;
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
      "macOS NSAccessibility request router dispatches live-region relevance queries");

   Request_Item.Live_Region :=
     A11y.MacOS_Backend.NSAccessibility_Live_Regions.Is_Atomic;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Live_Boolean
      and then Routed.Boolean_Item,
      "macOS NSAccessibility request router dispatches live-region boolean queries");

   Request_Item.Kind := Surface_Query;
   Request_Item.Surface :=
     A11y.MacOS_Backend.NSAccessibility_Surfaces.Kind_Name;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Surface_String
      and then Ada.Strings.Unbounded.To_String (Routed.Text) = "modal-dialog",
      "macOS NSAccessibility request router dispatches surface kind metadata");

   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Native_String_Size, 4, Result);
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility request router applies configured surface string limits");
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;

   Request_Item.Surface :=
     A11y.MacOS_Backend.NSAccessibility_Surfaces.Is_Modal;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Surface_Boolean
      and then Routed.Boolean_Item,
      "macOS NSAccessibility request router dispatches surface modality");

   Request_Item.Surface :=
     A11y.MacOS_Backend.NSAccessibility_Surfaces.Can_Resize;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Surface_Boolean
      and then not Routed.Boolean_Item,
      "macOS NSAccessibility request router dispatches surface operation capabilities");

   declare
      Deep_Surface : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (722);
      Direct_Surface :
        A11y.MacOS_Backend.NSAccessibility_Surfaces.Surface_Reply;
   begin
      Snapshots.Surface.Use_Tree_Projection := True;
      Snapshots.Surface.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Hide_Node_And_Subtree;
      Direct_Surface :=
        A11y.MacOS_Backend.NSAccessibility_Surfaces.Query_Surface
          (Snapshots.Surface,
           A11y.MacOS_Backend.NSAccessibility_Surfaces.Kind_Name);
      Check
        (Direct_Surface.Kind =
           A11y.MacOS_Backend.NSAccessibility_Surfaces.Error_Reply
         and then Direct_Surface.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility surface mapper rejects hidden surface nodes");

      Snapshots.Surface.Exposure
        (A11y.Node_Ids.To_Natural (Child)) :=
          A11y.Nodes.Expose_Node;
      declare
         Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         Invalid_Limits.Limits
           (A11y.Resource_Limits.Native_String_Size) := 0;
         Direct_Surface :=
           A11y.MacOS_Backend.NSAccessibility_Surfaces.Query_Surface
             (Snapshots.Surface,
              A11y.MacOS_Backend.NSAccessibility_Surfaces.Is_Modal,
              Invalid_Limits);
         Check
           (Direct_Surface.Kind =
              A11y.MacOS_Backend.NSAccessibility_Surfaces.Error_Reply
            and then Direct_Surface.Status = A11y.Results.Invalid_Argument,
            "macOS NSAccessibility surface mapper rejects invalid limit configs");
      end;

      Snapshots.Surface.Id := Deep_Surface;
      A11y.Trees.Attach (Snapshots.Surface.Tree, Child, Deep_Surface, Result);
      A11y.Resource_Limits.Set_Limit
        (Snapshots.Limits,
         A11y.Resource_Limits.Traversal_Depth,
         1,
         Result);
      Request_Item.Kind := Surface_Query;
      Request_Item.Surface :=
        A11y.MacOS_Backend.NSAccessibility_Surfaces.Kind_Name;
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (Routed.Kind = Routed_Error
         and then Routed.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility request router applies configured Surface traversal limits");
      Snapshots.Limits := A11y.Resource_Limits.Default_Config;
      Snapshots.Surface.Id := Child;
      Snapshots.Surface.Use_Tree_Projection := False;
   end;

   Snapshots.Surface.Metadata.State.Visible := False;
   Request_Item.Surface :=
     A11y.MacOS_Backend.NSAccessibility_Surfaces.Is_Active;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "macOS NSAccessibility request router validates surface state");
   Snapshots.Surface.Metadata.State.Visible := True;
   Snapshots.Surface.Metadata.State.Minimized := True;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Invalid_State,
      "macOS NSAccessibility request router rejects active minimized surfaces");
   Snapshots.Surface.Metadata.State.Minimized := False;

   Request_Item.Kind := Notification_Query;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Notification
      and then Routed.Native_Object = A11y.Native_Object_Caches.No_Object,
      "macOS NSAccessibility request router dispatches notification queries");

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
         and then Routed.Kind = Notification
         and then Routed.Native_Object = Prepared.Object,
         "macOS NSAccessibility request router dispatches prepared notifications");

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
         "macOS NSAccessibility request router rejects unbacked prepared notifications");

      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Destroy_Event, Prepared, Result);
      Request_Item.Prepared_Event := Prepared;
      Routed := Dispatch (Request_Item, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Routed.Kind = Notification
         and then Routed.Native_Object = A11y.Native_Object_Caches.No_Object,
         "macOS NSAccessibility request router posts prepared destruction notifications without native objects");

      Request_Item.Use_Prepared_Event := False;
   end;

   Snapshots.Event_Use_Tree_Projection := True;
   Snapshots.Event_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Hide_Node_And_Subtree;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility notification routing rejects hidden source nodes");
   Snapshots.Event_Exposure (A11y.Node_Ids.To_Natural (Root)) :=
     A11y.Nodes.Expose_Node;
   Snapshots.Event_Use_Tree_Projection := False;

   Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
     ((Sequence  => 15,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Selection_Changed,
       Revision  => 5));
   Check
     (Emission.Publishable
      and then Emission.Notification =
        A11y.MacOS_Backend.NSAccessibility_Events.Selected_Children_Changed
      and then Emission.Attribute =
        A11y.MacOS_Backend.NSAccessibility_Events.Selected_Children_Attribute
      and then Emission.Window =
        A11y.MacOS_Backend.NSAccessibility_Events.No_Window_Event,
      "macOS NSAccessibility event mapper annotates selection notifications");

   declare
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Report : A11y.MacOS_Backend.NSAccessibility_Events.Event_Build_Report;
      Prepared_Event : constant A11y.Events.Event :=
        (Sequence  => 16,
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
        (Sequence  => 17,
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
        (Sequence  => 18,
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
        (Sequence  => 19,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Bounds_Changed,
         Revision  => 9);
      Bounds_Payload : constant A11y.Events.Bounds_Event_Payload :=
        (Old_Bounds => A11y.Geometry.Empty_Rectangle,
         New_Bounds =>
           ((X => 11, Y => 21),
            (Width => 31, Height => 41)));
      Value_Event : constant A11y.Events.Event :=
        (Sequence  => 20,
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
        (Sequence  => 21,
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
        (Sequence  => 22,
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
        (Sequence  => 23,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 13);
      Relation_Event : constant A11y.Events.Event :=
        (Sequence  => 24,
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
        (Sequence  => 25,
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
        (Sequence  => 26,
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
        (Sequence  => 27,
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
        (Sequence  => 28,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Document_Loaded,
         Revision  => 18);
      Document_Payload : constant A11y.Events.Document_Event_Payload :=
        (Document    => Child,
         Surface     => Root,
         Has_Surface => True);
      Window_Event : constant A11y.Events.Event :=
        (Sequence  => 29,
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
        (Sequence  => 30,
         Timestamp => Ada.Calendar.Clock,
         Source    => Child,
         Kind      => A11y.Events.Node_Destroyed,
         Revision  => 20);
   begin
      A11y.Native_Runtimes.Start (Runtime, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility prepared-event fixture starts native runtime");

      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Prepared_Event, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Emission.Publishable
         and then Emission.Source = Child
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Focused_UI_Element_Changed,
         "macOS NSAccessibility event mapper accepts prepared native publications");
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
         "macOS NSAccessibility event mapper reports prepared native publication builds");
      Check
        (A11y.Results.Succeeded
           (A11y.MacOS_Backend.NSAccessibility_Events.Validate_For_Posting
              (Emission)),
         "macOS NSAccessibility event mapper validates prepared native publications for posting");

      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => State_Event,
         Object        => Prepared.Object,
         Has_Object    => True,
         Destroys_Node => False,
         Has_Property_Payload => True,
         Property_Payload => Property_Payload,
         Has_State_Payload => True,
         State_Payload => State_Payload,
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
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Native_Runtimes.Validate_Prepared_Event (Prepared).Status =
           A11y.Results.Invalid_Argument,
         "macOS NSAccessibility fixture rejects prepared events with conflicting payload flags centrally");
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument
         and then Report.Prepared_Input
         and then Report.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects conflicting prepared payload flags");

      A11y.Native_Runtimes.Prepare_Property_Event
        (Runtime, Property_Event, Property_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Property_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Title_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Title_Attribute,
         "macOS NSAccessibility prepared property events preserve property payload identities");

      A11y.Native_Runtimes.Prepare_State_Event
        (Runtime, State_Event, State_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_State_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Focused_Attribute,
         "macOS NSAccessibility prepared state events preserve state payload identities");

      A11y.Native_Runtimes.Prepare_Bounds_Event
        (Runtime, Bounds_Event, Bounds_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Bounds_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Window_Moved
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Attribute
         and then Emission.Has_Bounds_Payload
         and then Emission.Old_Bounds = A11y.Geometry.Empty_Rectangle
         and then Emission.New_Bounds.Origin.X = 11
         and then Emission.New_Bounds.Extent.Height = 41,
         "macOS NSAccessibility prepared bounds events preserve bounds payload rectangles");

      A11y.Native_Runtimes.Prepare_Value_Event
        (Runtime, Value_Event, Value_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Value_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Attribute
         and then Emission.Has_Value_Payload
         and then Emission.Old_Value.Kind = A11y.Values.Integer_Value
         and then Emission.New_Value.Kind = A11y.Values.Decimal_Value
         and then Emission.New_Value.Decimal_Item.Units = 125,
         "macOS NSAccessibility prepared value events preserve value payload identities");

      A11y.Native_Runtimes.Prepare_Selection_Event
        (Runtime, Selection_Event, Selection_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Selection_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Selected_Children_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Selected_Children_Attribute
         and then Emission.Has_Selection_Payload
         and then Emission.Selection_Node = Root
         and then Emission.Selection_Has_Node
         and then not Emission.Selection_Old_Selected
         and then Emission.Selection_New_Selected
         and then Emission.Selection_Required,
         "macOS NSAccessibility prepared selection events preserve selection payload identities");

      A11y.Native_Runtimes.Prepare_Node_Reference_Event
        (Runtime, Node_Reference_Event, Node_Reference_Payload,
         Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Node_Reference_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Attribute
         and then Emission.Has_Node_Reference_Payload
         and then Emission.Old_Reference = Root
         and then Emission.New_Reference = Child,
         "macOS NSAccessibility prepared node-reference events preserve node-reference payload identities");

      A11y.Native_Runtimes.Prepare_Focus_Event
        (Runtime, Focus_Event, Focus_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Focus_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Focused_UI_Element_Changed
         and then Emission.Has_Focus_Payload
         and then Emission.Old_Focus = Root
         and then Emission.New_Focus = Child,
         "macOS NSAccessibility prepared focus events preserve focus payload identities");

      A11y.Native_Runtimes.Prepare_Relation_Event
        (Runtime, Relation_Event, Relation_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Relation_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Relation_Attribute
         and then Emission.Relation =
           A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element,
         "macOS NSAccessibility prepared relation events preserve native relation attributes");
      Check
        (Report.Prepared_Input
         and then Report.Prepared_Has_Object
         and then Report.Native_Object_Resolved
         and then Report.Publishable
         and then Report.Status = A11y.Results.Success,
         "macOS NSAccessibility event mapper reports prepared relation publications");

      A11y.Native_Runtimes.Prepare_Live_Region_Event
        (Runtime, Live_Region_Event, Live_Region_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Live_Region_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Announcement_Requested
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Live_Region_Attribute
         and then Emission.Has_Live_Region_Payload
         and then Emission.Live_Region_Payload.Metadata.Setting =
           A11y.Live_Regions.Polite
         and then Emission.Live_Region_Payload.Metadata.Atomic
         and then Emission.Live_Region_Payload.Has_Announcement
         and then Ada.Strings.Unbounded.To_String
           (Emission.Live_Region_Payload.Announcement.Text) = "ready",
         "macOS NSAccessibility prepared live-region events preserve live-region payload identities");

      A11y.Native_Runtimes.Prepare_Tree_Event
        (Runtime, Tree_Event, Tree_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Tree_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Children_Attribute
         and then Emission.Has_Tree_Payload
         and then Emission.Tree_Payload.Parent = Child
         and then Emission.Tree_Payload.Child = Root
         and then Emission.Tree_Payload.Index = 2,
         "macOS NSAccessibility prepared tree events preserve tree payload identities");

      A11y.Native_Runtimes.Prepare_Table_Event
        (Runtime, Table_Event, Table_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Table_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Row_Count_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Row_Count_Attribute
         and then Emission.Has_Table_Payload
         and then Emission.Table_Payload.Table = Child
         and then not Emission.Table_Payload.Has_Item
         and then Emission.Table_Payload.Row = 4,
         "macOS NSAccessibility prepared table events preserve table payload identities");

      A11y.Native_Runtimes.Prepare_Document_Event
        (Runtime, Document_Event, Document_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Document_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Children_Attribute
         and then Emission.Has_Document_Payload
         and then Emission.Document_Payload.Document = Child
         and then Emission.Document_Payload.Surface = Root
         and then Emission.Document_Payload.Has_Surface,
         "macOS NSAccessibility prepared document events preserve document payload identities");

      A11y.Native_Runtimes.Prepare_Window_Event
        (Runtime, Window_Event, Window_Payload, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Prepared.Has_Window_Payload
         and then Emission.Publishable
         and then Emission.Native_Object = Prepared.Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Window_Created
         and then Emission.Has_Window_Payload
         and then Emission.Window_Payload.Surface = Child
         and then Emission.Window_Payload.Kind = A11y.Windows.Modal_Dialog
         and then Emission.Window_Payload.Owner = Root
         and then Emission.Window_Payload.Has_Owner,
         "macOS NSAccessibility prepared window events preserve window payload identities");

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
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility event mapper rejects unbacked prepared publications");
      Check
        (Report.Prepared_Input
         and then not Report.Prepared_Has_Object
         and then not Report.Native_Object_Resolved
         and then not Report.Publishable
         and then Report.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility event mapper reports unbacked prepared publication rejections");
      Check
        (A11y.MacOS_Backend.NSAccessibility_Events.Validate_For_Posting
           (Emission).Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility event mapper rejects unbacked publications before posting");

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
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects invalid prepared event envelopes before native object resolution");
      Check
        (Report.Prepared_Input
         and then not Report.Envelope_Valid
         and then not Report.Native_Object_Resolved
         and then not Report.Publishable
         and then Report.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper reports invalid prepared event envelope rejections before native object resolution");

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
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Timed_Out,
         "macOS NSAccessibility event mapper preserves failed prepared publication status");
      Check
        (Report.Prepared_Input
         and then Report.Envelope_Valid
         and then not Report.Publishable
         and then Report.Status = A11y.Results.Timed_Out,
         "macOS NSAccessibility event mapper reports failed prepared publication status");
      Check
        (A11y.MacOS_Backend.NSAccessibility_Events.Validate_For_Posting
           (Emission).Status = A11y.Results.Timed_Out,
         "macOS NSAccessibility posting validation preserves failed prepared publication status");

      A11y.Native_Runtimes.Prepare_Event
        (Runtime, Destroy_Event, Prepared, Result);
      A11y.MacOS_Backend.NSAccessibility_Events
        .Build_Prepared_Event_With_Report
          (Prepared, Emission, Report);
      Check
        (A11y.Results.Succeeded (Result)
         and then Emission.Publishable
         and then Emission.Native_Object =
           A11y.Native_Object_Caches.No_Object
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.UI_Element_Destroyed,
         "macOS NSAccessibility event mapper accepts prepared destruction publications");
      Check
        (Report.Source = Child
         and then Report.Prepared_Input
         and then not Report.Prepared_Has_Object
         and then Report.Prepared_Destroys_Node
         and then not Report.Native_Object_Resolved
         and then Report.Publishable
         and then Report.Status = A11y.Results.Success,
         "macOS NSAccessibility event mapper reports prepared destruction publications");
      Check
        (A11y.Results.Succeeded
           (A11y.MacOS_Backend.NSAccessibility_Events.Validate_For_Posting
              (Emission)),
         "macOS NSAccessibility event mapper validates destruction publications without native objects");
   end;

   declare
      package Events renames A11y.MacOS_Backend.NSAccessibility_Events;
      Queue     : Events.Event_Emission_Queue;
      First     : Events.NSAX_Event_Emission;
      Second    : Events.NSAX_Event_Emission;
      Dequeued  : Events.NSAX_Event_Emission;
      Bad       : Events.NSAX_Event_Emission;
      Report    : Events.Posting_Attempt_Report;
      Drain     : Events.Posting_Drain_Report;
      Prepared_Report : Events.Prepared_Enqueue_Report;
      Posted    : Natural := 0;
      Runtime   : A11y.Native_Runtimes.Native_Runtime;
      Prepared  : A11y.Native_Runtimes.Prepared_Event;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;

      procedure Post_Success
        (Emission : Events.NSAX_Event_Emission;
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
        (Emission : Events.NSAX_Event_Emission;
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
         "macOS NSAccessibility event queue adopts native array resource limit");
      Check
        (not Events.Posting_Interest (Queue).Can_Post
         and then not Events.Posting_Interest (Queue).Has_Pending
         and then Events.Posting_Interest (Queue).Capacity = 2
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.No_Posting_Operation,
         "macOS NSAccessibility event queue interest reports empty queues");

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
         "macOS NSAccessibility event queue accepts a publishable emission");
      Check
        (Events.Posting_Interest (Queue).Can_Post
         and then Events.Posting_Interest (Queue).Has_Pending
         and then Events.Posting_Interest (Queue).Length = 1
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.Post_Next_Event,
         "macOS NSAccessibility event queue interest admits pending events");
      Check
        (Events.Validate_For_Posting (First).Status =
           A11y.Results.Node_Unavailable,
         "macOS NSAccessibility event queue requires native objects before posting ordinary emissions");

      Events.Enqueue (Queue, Second, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Length (Queue) = 2,
         "macOS NSAccessibility event queue fills to configured capacity");

      Events.Set_Queue_Capacity (Queue, 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "macOS NSAccessibility event queue rejects shrinking below queued length");

      Events.Enqueue (Queue, First, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Events.Queue_Overflowed (Queue),
         "macOS NSAccessibility event queue reports bounded overflow");
      Check
        (not Events.Posting_Interest (Queue).Can_Post
         and then Events.Posting_Interest (Queue).Has_Pending
         and then Events.Posting_Interest (Queue).Overflowed
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.Back_Pressure,
         "macOS NSAccessibility event queue interest reports back pressure after overflow");

      Events.Dequeue_For_Posting (Queue, Dequeued, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not Dequeued.Publishable
         and then Events.Queue_Length (Queue) = 2,
         "macOS NSAccessibility event queue posting admission rejects overflow without drain");
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
         "macOS NSAccessibility event queue posting report records overflow rejection without drain");
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
         "macOS NSAccessibility bounded posting drain reports overflow back pressure without consumption");

      Events.Peek (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Sequence = First.Sequence,
         "macOS NSAccessibility event queue peek preserves FIFO head");

      Events.Dequeue (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Sequence = First.Sequence
         and then Events.Queue_Length (Queue) = 1,
         "macOS NSAccessibility event queue dequeues FIFO head");

      Bad := (Publishable => False, Status => A11y.Results.Node_Unavailable);
      Events.Enqueue (Queue, Bad, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Events.Queue_Length (Queue) = 1,
         "macOS NSAccessibility event queue rejects non-publishable emissions");

      Events.Dequeue (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Sequence = Second.Sequence
         and then Events.Queue_Length (Queue) = 0,
         "macOS NSAccessibility event queue preserves FIFO order through drain");

      Events.Peek (Queue, Dequeued, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then not Dequeued.Publishable,
         "macOS NSAccessibility event queue reports empty peek as node unavailable");

      Events.Clear (Queue);
      Check
        (Events.Queue_Length (Queue) = 0
         and then not Events.Queue_Overflowed (Queue),
         "macOS NSAccessibility event queue clear resets overflow state");
      Check
        (not Events.Posting_Interest (Queue).Can_Post
         and then not Events.Posting_Interest (Queue).Has_Pending
         and then not Events.Posting_Interest (Queue).Overflowed
         and then Events.Posting_Interest (Queue).Next_Operation =
           Events.No_Posting_Operation,
         "macOS NSAccessibility event queue interest resets after clear");

      A11y.Native_Runtimes.Start (Runtime, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility event queue prepared-enqueue fixture starts native runtime");
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
         "macOS NSAccessibility event queue reports prepared native publication enqueue");
      Events.Peek (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Dequeued.Publishable
         and then Dequeued.Native_Object = Prepared.Object
         and then Dequeued.Sequence = 120,
         "macOS NSAccessibility event queue preserves prepared native object metadata");
      Events.Dequeue (Queue, Dequeued, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Events.Queue_Length (Queue) = 0,
         "macOS NSAccessibility event queue drains prepared native publications");
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
         "macOS NSAccessibility event queue validates conflicting prepared payloads before native emission build");
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
         "macOS NSAccessibility event queue validates failed prepared statuses before native emission build");

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
         "macOS NSAccessibility event queue posting report drains after overflow reset");

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
         "macOS NSAccessibility bounded posting drain rejects zero attempt limits");

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
         "macOS NSAccessibility bounded posting drain stops at the iteration limit");

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
         "macOS NSAccessibility bounded posting drain reports completion when the queue empties");

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
         "macOS NSAccessibility bounded posting drain retains attempted identity after callback failure");
   end;

   declare
      Payload : A11y.Events.Property_Event_Payload :=
        (Property   => A11y.Properties.Placeholder,
         Value_Kind => A11y.Properties.String_Value,
         Old_Status => A11y.Properties.Unsupported,
         New_Status => A11y.Properties.Present);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 121,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 21),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Placeholder_Attribute,
         "macOS NSAccessibility event mapper uses property payload identifiers");

      Payload.Property := A11y.Properties.Bounds;
      Payload.Value_Kind := A11y.Properties.Rectangle_Value;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 122,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 22),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Attribute,
         "macOS NSAccessibility event mapper maps property payload value categories");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 123,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 23),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects property payloads on other events");
   end;

   declare
      Payload : A11y.Events.State_Event_Payload :=
        (State     => A11y.States.Selected,
         Source    => A11y.States.Application_Provided,
         Old_Value => False,
         New_Value => True);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 124,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 24),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Selected_Attribute,
         "macOS NSAccessibility event mapper uses state payload identifiers");

      Payload.State := A11y.States.Offscreen;
      Payload.Source := A11y.States.Centrally_Derived;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 125,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 25),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Attribute,
         "macOS NSAccessibility event mapper maps derived state payloads");

      Payload.Old_Value := True;
      Payload.New_Value := True;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 126,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 26),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects no-op state payloads");
   end;

   declare
      Payload : A11y.Events.Relation_Event_Payload :=
        (Relation   => A11y.Relations.Labelled_By,
         Inverse    => A11y.Relations.Label_For,
         Target     => Root,
         Has_Target => True);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 127,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Relation_Added,
          Revision  => 27),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Relation_Attribute
         and then Emission.Relation =
           A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element,
         "macOS NSAccessibility event mapper uses relation payload identifiers");

      Payload.Relation := A11y.Relations.Described_By;
      Payload.Inverse := A11y.Relations.Description_For;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 128,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Relation_Targets_Changed,
          Revision  => 28),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Relation =
           A11y.MacOS_Backend.NSAccessibility_Mappings.Unsupported_Relation,
         "macOS NSAccessibility event mapper keeps unsupported relation details explicit");

      Payload.Target := A11y.Node_Ids.No_Node;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 129,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Relation_Removed,
          Revision  => 29),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects invalid relation payload targets");
   end;

   declare
      Payload : constant A11y.Events.Bounds_Event_Payload :=
        (Old_Bounds => A11y.Geometry.Empty_Rectangle,
         New_Bounds =>
           (Origin => (X => 30, Y => 40),
            Extent => (Width => 50, Height => 60)));
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 130,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Bounds_Changed,
          Revision  => 30),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Attribute
         and then Emission.Has_Bounds_Payload
         and then Emission.Old_Bounds = A11y.Geometry.Empty_Rectangle
         and then Emission.New_Bounds.Origin.Y = 40
         and then Emission.New_Bounds.Extent.Width = 50,
         "macOS NSAccessibility event mapper carries bounds payload rectangles");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 131,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 31),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects bounds payloads on other events");
   end;

   declare
      Payload : constant A11y.Events.Focus_Event_Payload :=
        (Old_Focus => A11y.Node_Ids.No_Node,
         New_Focus => Root);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 132,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 32),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Focused_UI_Element_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Focused_Attribute
         and then Emission.Has_Focus_Payload
         and then Emission.Old_Focus = A11y.Node_Ids.No_Node
         and then Emission.New_Focus = Root,
         "macOS NSAccessibility event mapper carries focus payload identities");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 133,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.State_Changed,
          Revision  => 33),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects focus payloads on other events");
   end;

   declare
      Payload : constant A11y.Events.Node_Reference_Event_Payload :=
        (Old_Node => A11y.Node_Ids.No_Node,
         New_Node => Root);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 134,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Active_Descendant_Changed,
          Revision  => 34),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Attribute
         and then Emission.Has_Node_Reference_Payload
         and then Emission.Old_Reference = A11y.Node_Ids.No_Node
         and then Emission.New_Reference = Root,
         "macOS NSAccessibility event mapper carries node-reference payload identities");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 135,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 35),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects node-reference payloads on other events");
   end;

   declare
      Payload : constant A11y.Events.Value_Event_Payload :=
        (Old_Value => A11y.Values.Integer (1),
         New_Value => A11y.Values.Exact_Decimal (125, 2),
         Old_Kind  => A11y.Values.Integer_Value,
         New_Kind  => A11y.Values.Decimal_Value);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 136,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Value_Changed,
          Revision  => 36),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Value_Attribute
         and then Emission.Has_Value_Payload
         and then Emission.Old_Value.Kind = A11y.Values.Integer_Value
         and then Emission.New_Value.Kind = A11y.Values.Decimal_Value
         and then Emission.New_Value.Decimal_Item.Units = 125,
         "macOS NSAccessibility event mapper carries semantic value payloads");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 137,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Property_Changed,
          Revision  => 37),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects value payloads on other events");
   end;

   declare
      Payload : A11y.Events.Selection_Event_Payload :=
        (Changed_Node       => Child,
         Has_Changed_Node   => True,
         Old_Selected       => False,
         New_Selected       => True,
         Requires_Selection => True);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 138,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 38),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Selected_Children_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Selected_Children_Attribute
         and then Emission.Has_Selection_Payload
         and then Emission.Selection_Node = Child
         and then Emission.Selection_Has_Node
         and then not Emission.Selection_Old_Selected
         and then Emission.Selection_New_Selected
         and then Emission.Selection_Required,
         "macOS NSAccessibility event mapper carries semantic selection payloads");

      Payload.Has_Changed_Node := False;
      Payload.Changed_Node := A11y.Node_Ids.No_Node;
      Payload.Old_Selected := False;
      Payload.New_Selected := False;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
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
         "macOS NSAccessibility event mapper carries selection invalidation payloads");

      Payload.Changed_Node := Child;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 140,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 40),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects contradictory absent selection change nodes");

      Payload.Changed_Node := A11y.Node_Ids.No_Node;
      Payload.New_Selected := True;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 141,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Selection_Changed,
          Revision  => 41),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects selected-state flags on "
         & "selection invalidations");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 142,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 41),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects selection payloads on other events");
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

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 140,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Announcement_Requested,
          Revision  => 40),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Announcement_Requested
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Live_Region_Attribute
         and then Emission.Has_Live_Region_Payload
         and then Emission.Live_Region_Payload.Metadata.Setting =
           A11y.Live_Regions.Polite
         and then Emission.Live_Region_Payload.Metadata.Atomic
         and then Emission.Live_Region_Payload.Has_Announcement
         and then Ada.Strings.Unbounded.To_String
           (Emission.Live_Region_Payload.Announcement.Text) = "ready",
         "macOS NSAccessibility event mapper carries live-region announcement payloads");

      Payload.Has_Announcement := False;
      Payload.Announcement.Text := Ada.Strings.Unbounded.Null_Unbounded_String;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 141,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Live_Region_Changed,
          Revision  => 41),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Live_Region_Changed
         and then Emission.Has_Live_Region_Payload
         and then not Emission.Live_Region_Payload.Has_Announcement
         and then Ada.Strings.Unbounded.Length
           (Emission.Live_Region_Payload.Announcement.Text) = 0,
         "macOS NSAccessibility event mapper carries live-region change payloads");

      Payload.Metadata.Setting := A11y.Live_Regions.Off;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 142,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Live_Region_Changed,
          Revision  => 42),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_State,
         "macOS NSAccessibility event mapper rejects inactive live-region relevance");

      Payload.Metadata.Setting := A11y.Live_Regions.Polite;
      Payload.Has_Announcement := True;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 143,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Live_Region_Changed,
          Revision  => 43),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects announcements on "
         & "live-region changes");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 144,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 44),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects live-region payloads on other events");

      declare
         Snapshot :
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Live_Snapshot :=
             (Id => Root, Metadata => Metadata, Defunct => False);
         Reply :
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Live_Reply;
         Externally_Announced : constant
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Live_Query :=
             A11y.MacOS_Backend.NSAccessibility_Live_Regions.Is_Externally_Announced;
         Live_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
         Limit_Result : A11y.Results.Result;
      begin
         Payload.Has_Announcement := False;
         Payload.Metadata.Setting := A11y.Live_Regions.Polite;
         Snapshot.Metadata := Payload.Metadata;

         Reply :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
             (Snapshot,
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Setting_Name,
              Live_Limits);
         Check
           (Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.String_Reply
            and then Ada.Strings.Unbounded.To_String (Reply.Text) =
              "polite",
            "macOS NSAccessibility live-region mapper returns setting names");

         Reply :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
             (Snapshot,
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Relevant_Names,
              Live_Limits);
         Check
           (Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.String_Reply
            and then Ada.Strings.Unbounded.To_String (Reply.Text) = "text",
            "macOS NSAccessibility live-region mapper returns relevance names");

         Reply :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
             (Snapshot,
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Is_Atomic,
              Live_Limits);
         Check
           (Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Boolean_Reply
            and then Reply.Boolean_Item,
            "macOS NSAccessibility live-region mapper returns atomicity");

         Reply :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
             (Snapshot, Externally_Announced, Live_Limits);
         Check
           (Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Boolean_Reply
            and then Reply.Boolean_Item,
            "macOS NSAccessibility live-region mapper returns announcement policy");

         A11y.Resource_Limits.Set_Limit
           (Live_Limits,
            A11y.Resource_Limits.Native_String_Size,
            4,
            Limit_Result);
         Reply :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
             (Snapshot,
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Setting_Name,
              Live_Limits);
         Check
           (Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Error_Reply
            and then Reply.Status = A11y.Results.Resource_Limit,
            "macOS NSAccessibility live-region mapper bounds setting names");

         declare
            Invalid_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
              A11y.Resource_Limits.Default_Config;
         begin
            Invalid_Limits.Limits
              (A11y.Resource_Limits.Native_String_Size) := 0;
            Reply :=
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
                (Snapshot,
                 A11y.MacOS_Backend.NSAccessibility_Live_Regions.Is_Atomic,
                 Invalid_Limits);
            Check
              (Reply.Kind =
                 A11y.MacOS_Backend.NSAccessibility_Live_Regions.Error_Reply
               and then Reply.Status = A11y.Results.Invalid_Argument,
               "macOS NSAccessibility live-region mapper rejects invalid limit configs");
         end;

         Snapshot.Metadata.Setting := A11y.Live_Regions.Off;
         Reply :=
           A11y.MacOS_Backend.NSAccessibility_Live_Regions.Query_Live_Region
             (Snapshot,
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Is_Atomic,
              A11y.Resource_Limits.Default_Config);
         Check
           (Reply.Kind =
              A11y.MacOS_Backend.NSAccessibility_Live_Regions.Error_Reply
            and then Reply.Status = A11y.Results.Invalid_State,
            "macOS NSAccessibility live-region mapper validates metadata");
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
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 143,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Child_Added,
          Revision  => 43),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Notification =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Changed
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Children_Attribute
         and then Emission.Has_Tree_Payload
         and then Emission.Tree_Payload.Parent = Root
         and then Emission.Tree_Payload.Child = Child
         and then Emission.Tree_Payload.Index = 2,
         "macOS NSAccessibility event mapper carries child tree payloads");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 144,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 44),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects tree payloads on other events");
   end;

   declare
      Payload : A11y.Events.Tree_Event_Payload :=
        (Parent    => Root,
         Child     => A11y.Node_Ids.No_Node,
         Has_Child => False,
         Index     => Positive'First,
         Has_Index => False);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 145,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Subtree_Rebuilt,
          Revision  => 45),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Children_Attribute
         and then Emission.Has_Tree_Payload
         and then not Emission.Tree_Payload.Has_Child,
         "macOS NSAccessibility event mapper carries aggregate tree payloads");

      Payload.Child := Child;
      Payload.Index := 7;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 146,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Subtree_Rebuilt,
          Revision  => 46),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects contradictory aggregate tree payloads");

      Payload.Has_Child := True;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 147,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Subtree_Rebuilt,
          Revision  => 47),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects child metadata on "
         & "aggregate tree payloads");
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
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 146,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Row_Inserted,
          Revision  => 46),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Row_Count_Attribute
         and then Emission.Has_Table_Payload
         and then Emission.Table_Payload.Table = Root
         and then Emission.Table_Payload.Row = 3
         and then not Emission.Table_Payload.Has_Item,
         "macOS NSAccessibility event mapper carries row table payloads");

      Payload.Item := Child;
      Payload.Column := 2;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 147,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Row_Inserted,
          Revision  => 47),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects contradictory row table payloads");

      Payload.Has_Item := True;
      Payload.Column := 0;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 148,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Row_Inserted,
          Revision  => 48),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects cell metadata on row "
         & "table payloads");
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
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 148,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Cell_Changed,
          Revision  => 48),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Layout_Attribute
         and then Emission.Has_Table_Payload
         and then Emission.Table_Payload.Item = Child
         and then Emission.Table_Payload.Row = 1
         and then Emission.Table_Payload.Column = 2,
         "macOS NSAccessibility event mapper carries cell table payloads");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 149,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 49),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects table payloads on other events");
   end;

   declare
      Payload : A11y.Events.Document_Event_Payload :=
        (Document    => Root,
         Surface     => Child,
         Has_Surface => True);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 149,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Document_Loaded,
          Revision  => 49),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Attribute =
           A11y.MacOS_Backend.NSAccessibility_Events.Children_Attribute
         and then Emission.Has_Document_Payload
         and then Emission.Document_Payload.Document = Root
         and then Emission.Document_Payload.Surface = Child
         and then Emission.Document_Payload.Has_Surface,
         "macOS NSAccessibility event mapper carries document payloads");

      Payload.Has_Surface := False;
      Payload.Surface := Child;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 150,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Document_Loaded,
          Revision  => 50),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects contradictory absent document surface payloads");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 151,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 51),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects document payloads on other events");
   end;

   declare
      Payload : A11y.Events.Window_Event_Payload :=
        (Surface   => Root,
         Kind      => A11y.Windows.Modal_Dialog,
         Owner     => Child,
         Has_Owner => True);
   begin
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 151,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Window_Opened,
          Revision  => 51),
         Payload);
      Check
        (Emission.Publishable
         and then Emission.Window =
           A11y.MacOS_Backend.NSAccessibility_Events.Window_Created_Event
         and then Emission.Has_Window_Payload
         and then Emission.Window_Payload.Surface = Root
         and then Emission.Window_Payload.Kind = A11y.Windows.Modal_Dialog
         and then Emission.Window_Payload.Owner = Child
         and then Emission.Window_Payload.Has_Owner,
         "macOS NSAccessibility event mapper carries window payloads");

      Payload.Has_Owner := False;
      Payload.Owner := Child;
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 153,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Window_Opened,
          Revision  => 53),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects contradictory absent window owner payloads");

      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  => 154,
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => A11y.Events.Focus_Changed,
          Revision  => 54),
         Payload);
      Check
        (not Emission.Publishable
         and then Emission.Status = A11y.Results.Invalid_Argument,
         "macOS NSAccessibility event mapper rejects window payloads on other events");
   end;

   Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
     ((Sequence  => 16,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Child_Added,
       Revision  => 6));
   Check
     (Emission.Publishable
      and then Emission.Notification =
        A11y.MacOS_Backend.NSAccessibility_Events.Layout_Changed
      and then Emission.Attribute =
        A11y.MacOS_Backend.NSAccessibility_Events.Children_Attribute,
      "macOS NSAccessibility event mapper annotates hierarchy notifications");

   Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
     ((Sequence  => 17,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Window_Activated,
       Revision  => 7));
   Check
     (Emission.Publishable
      and then Emission.Window =
        A11y.MacOS_Backend.NSAccessibility_Events.Window_Activated_Event,
      "macOS NSAccessibility event mapper annotates window notifications");

   for Kind in A11y.Events.Event_Kind loop
      Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
        ((Sequence  =>
            A11y.Event_Sequence (120 + A11y.Events.Event_Kind'Pos (Kind)),
          Timestamp => Ada.Calendar.Clock,
          Source    => Root,
          Kind      => Kind,
          Revision  => 9));
      Check
        (Emission.Publishable
         and then Emission.Sequence =
           A11y.Event_Sequence (120 + A11y.Events.Event_Kind'Pos (Kind)),
         "macOS NSAccessibility event mapper covers every semantic event kind");
   end loop;

   Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
     ((Sequence  => A11y.No_Event,
       Timestamp => Ada.Calendar.Clock,
       Source    => Root,
       Kind      => A11y.Events.Focus_Changed,
       Revision  => 8));
   Check
     (not Emission.Publishable
      and then Emission.Status = A11y.Results.Invalid_Argument,
      "macOS NSAccessibility event mapper rejects unsequenced notifications");

   Emission := A11y.MacOS_Backend.NSAccessibility_Events.Build_Event
     ((Sequence  => 18,
       Timestamp => Ada.Calendar.Clock,
       Source    => A11y.Node_Ids.No_Node,
       Kind      => A11y.Events.Focus_Changed,
       Revision  => 8));
   Check
     (not Emission.Publishable
      and then Emission.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility event mapper rejects stale notification sources");

   Request_Item.Kind := Action_Map_Query;
   Request_Item.Action := A11y.Actions.Toggle;
   Routed := Dispatch (Request_Item, Snapshots.all);
   Check
     (Routed.Kind = Routed_Error
      and then Routed.Status = A11y.Results.Unsupported_Action,
      "macOS NSAccessibility request router preserves unsupported action errors");

   Check
     (A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Relation
        (A11y.Relations.Labelled_By)
      = A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element
      and then A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Relation
        (A11y.Relations.Active_Descendant)
      = A11y.MacOS_Backend.NSAccessibility_Mappings.Active_Descendant
      and then A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Relation
        (A11y.Relations.Embedded_By)
      = A11y.MacOS_Backend.NSAccessibility_Mappings.Unsupported_Relation,
      "macOS NSAccessibility mapper classifies neutral relation kinds");

   for Role in A11y.Roles.Role loop
      declare
         Mapped : constant
           A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Role :=
             A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Role (Role);
      begin
         Check
           ((Mapped /=
               A11y.MacOS_Backend.NSAccessibility_Mappings.Unknown)
            or else Role = A11y.Roles.Custom,
            "macOS NSAccessibility mapper covers every semantic role explicitly");
      end;
   end loop;

   for Relation in A11y.Relations.Relation_Kind loop
      declare
         Mapped : constant
           A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Relation_Attribute :=
             A11y.MacOS_Backend.NSAccessibility_Mappings.Map_Relation
               (Relation);
         Expected_Unsupported : constant Boolean :=
           Relation in A11y.Relations.Described_By |
                       A11y.Relations.Description_For |
                       A11y.Relations.Embedded_By |
                       A11y.Relations.Embeds;
      begin
         Check
           ((Mapped /=
               A11y.MacOS_Backend.NSAccessibility_Mappings.Unsupported_Relation)
            or else Expected_Unsupported,
            "macOS NSAccessibility mapper covers every semantic relation explicitly");
      end;
   end loop;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Attribute_Value;
   Boundary_Request.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Native_Object =
        A11y.Native_Object_Caches.No_Object,
      "macOS NSAccessibility provider boundary returns native replies");

   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Invalid_Argument
      and then Boundary_Reply.Status = A11y.Results.Invalid_Argument,
      "macOS NSAccessibility native provider boundary rejects calls without native identity");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Attribute_Names;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Attribute_Set
      and then Boundary_Reply.Payload.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Role)
      and then Boundary_Reply.Payload.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Label)
      and then Boundary_Reply.Payload.Attributes
        (A11y.MacOS_Backend.NSAccessibility_Properties.Frame),
      "macOS NSAccessibility provider boundary preserves attribute-name payloads");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Action_Names;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Action_Set
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Press)
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Expand)
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Scroll_To_Visible)
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Cancel),
      "macOS NSAccessibility provider boundary preserves action-name payloads");

   Boundary_Request.Has_Native_Identity := True;
   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Action_Set
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Press)
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Expand),
      "macOS NSAccessibility provider boundary admits action-name action identity");

   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Native_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Action_Set
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Press)
      and then Boundary_Reply.Payload.Actions
        (A11y.MacOS_Backend.NSAccessibility_Actions.Expand),
      "macOS NSAccessibility native provider boundary admits calls with matching native identity");
   Boundary_Request.Has_Native_Identity := False;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Child_At_Index;
   Boundary_Request.Child_Index := 1;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Hierarchy_Node
      and then Boundary_Reply.Payload.Kind = Hierarchy_Node
      and then Boundary_Reply.Payload.Node = Child,
      "macOS NSAccessibility provider boundary preserves hierarchy child identity payloads");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Element_Id;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
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
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
         and then Boundary_Reply.Routed = Element_Id
         and then Boundary_Reply.Payload.Kind = Element_Id
         and then Boundary_Reply.Payload.Id.Session_Component =
           A11y.Native_Identity.To_Natural (Session)
         and then Boundary_Reply.Payload.Id.Root_Component = Root_Component
         and then Boundary_Reply.Payload.Id.Node_Component = Node_Component,
         "macOS NSAccessibility provider boundary preserves element identity payloads");
   end;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Post_Notification;
   Boundary_Request.Event :=
     (Sequence  => 23,
      Timestamp => Ada.Calendar.Clock,
      Source    => Child,
      Kind      => A11y.Events.Focus_Changed,
      Revision  => 8);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Notification
      and then Boundary_Reply.Native_Object =
        A11y.Native_Object_Caches.No_Object,
      "macOS NSAccessibility provider boundary routes raw notifications without native objects");

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
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
         and then Boundary_Reply.Routed = Notification
         and then Boundary_Reply.Native_Object = Prepared.Object,
         "macOS NSAccessibility provider boundary returns prepared notification native objects");

      Boundary_Request.Has_Native_Identity := True;
      Boundary_Request.Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Child, Result);
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
         and then Boundary_Reply.Routed = Notification
         and then Boundary_Reply.Native_Object = Prepared.Object,
         "macOS NSAccessibility provider boundary admits prepared notification source identity");

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
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (A11y.Results.Succeeded (Result)
         and then Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility provider boundary rejects raw notification identity for prepared notifications");
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
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility provider boundary rejects unbacked prepared notifications");

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
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Busy
         and then Boundary_Reply.Status = A11y.Results.Timed_Out,
         "macOS NSAccessibility provider boundary preserves failed prepared notification status");

      Boundary_Request.Use_Prepared_Event := False;
   end;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Attribute_Value;
   Boundary_Request.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;

   Boundary_Request.Has_Native_Identity := True;
   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Root, Result);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success,
      "macOS NSAccessibility provider boundary admits matching native identity");

   declare
      Other_Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
   begin
      Boundary_Request.Native_Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Other_Session, Root, Result);
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
          (Boundary_Request, Snapshots.all);
      Check
        (Result.Status = A11y.Results.Success
         and then Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
         "macOS NSAccessibility provider boundary rejects cross-session native identity");
   end;

   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Result.Status = A11y.Results.Success
      and then Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility provider boundary rejects mismatched native identity");

   Boundary_Request.Native_Node_Component := 0;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility provider boundary rejects malformed native identity");

   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Dispatch_Native_Request
         (Boundary_Request, Snapshots.all);
   Check
     (A11y.Results.Succeeded (Result)
      and then Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Native_Element_Unavailable
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility native callback boundary rejects mismatched native identity");

   Boundary_Request.Native_Node_Component := 0;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Dispatch_Native_Request
         (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Native_Element_Unavailable
      and then Boundary_Reply.Status = A11y.Results.Node_Unavailable,
      "macOS NSAccessibility native callback boundary rejects malformed native identity");
   Boundary_Request.Has_Native_Identity := False;

   Boundary_Request.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Frame;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Attribute_Rectangle
      and then Boundary_Reply.Payload.Kind = Attribute_Rectangle
      and then Boundary_Reply.Payload.Bounds = Snapshots.Properties.Bounds,
      "macOS NSAccessibility provider boundary routes frame requests");
   Boundary_Request.Attribute :=
     A11y.MacOS_Backend.NSAccessibility_Properties.Title;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Perform_Action;
   Boundary_Request.Action := A11y.Actions.Press;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action = A11y.Actions.Press,
      "macOS NSAccessibility provider boundary routes action requests");

   Boundary_Request.Action := A11y.Actions.Scroll_Into_View;
   Snapshots.Actions (A11y.Actions.Scroll_Into_View) := True;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Action_Request
      and then Boundary_Reply.Payload.Kind = Action_Request
      and then Boundary_Reply.Payload.Requested_Action =
        A11y.Actions.Scroll_Into_View,
      "macOS NSAccessibility provider boundary routes scroll action requests");

   Boundary_Request.Action := A11y.Actions.Toggle;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Nil
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Not_Applicable,
      "macOS NSAccessibility provider boundary maps unsupported actions to nil");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Relation_Targets;
   Boundary_Request.Relation := A11y.Relations.Labelled_By;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Relation_Targets
      and then Boundary_Reply.Payload.Relation_Attribute =
        A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element,
      "macOS NSAccessibility provider boundary routes relation target requests");
   Check
     (Boundary_Reply.Payload.Relation_Attribute =
        A11y.MacOS_Backend.NSAccessibility_Mappings.Title_UI_Element,
      "macOS NSAccessibility provider boundary preserves relation target native attributes");

   Boundary_Request.Relation := A11y.Relations.Embedded_By;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Nil
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Not_Applicable
      and then Boundary_Reply.Routed = Relation_Not_Supported,
      "macOS NSAccessibility provider boundary maps unsupported relations to nil");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Value;
   Boundary_Request.Value := A11y.MacOS_Backend.NSAccessibility_Values.Value;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
  Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Value_Float
      and then Boundary_Reply.Payload.Kind = Value_Float
      and then Boundary_Reply.Payload.Float_Item = 12.5,
      "macOS NSAccessibility provider boundary routes value requests");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Set_Value;
   Boundary_Request.Requested_Value :=
     A11y.Values.Exact_Decimal (Units => 150, Scale => 1);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Value_Set_Request
      and then Boundary_Reply.Payload.Kind = Value_Set_Request
      and then A11y.Values.Equal
        (Boundary_Reply.Payload.Requested_Value,
         A11y.Values.Exact_Decimal (Units => 150, Scale => 1)),
      "macOS NSAccessibility provider boundary routes value set requests");

   Snapshots.Value.Metadata.Mode := A11y.Values.Read_Only;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Busy
      and then Boundary_Reply.Status = A11y.Results.Read_Only,
      "macOS NSAccessibility provider boundary rejects read-only value set requests");
   Snapshots.Value.Metadata.Mode := A11y.Values.Writable;
   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Value;

   Snapshots.Value.Metadata.Current :=
     A11y.Values.Exact_Decimal (Units => 1_234, Scale => 2);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Failed
      and then Boundary_Reply.Status = A11y.Results.Native_Failure,
      "macOS NSAccessibility provider boundary rejects inexact native value conversion");
   Snapshots.Value.Metadata.Current :=
     A11y.Values.Exact_Decimal (Units => 125, Scale => 1);

   Snapshots.Value.Metadata.Small_Increment := (Kind => A11y.Values.Unknown);
   Boundary_Request.Value := A11y.MacOS_Backend.NSAccessibility_Values.Increment;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Routed = Value_Not_Applicable,
      "macOS NSAccessibility provider boundary preserves absent value metadata");
   Snapshots.Value.Metadata.Small_Increment :=
     A11y.Values.Exact_Decimal (Units => 10, Scale => 1);

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Selection;
   Boundary_Request.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Selection_UInt32
      and then Boundary_Reply.Payload.Kind = Selection_UInt32
      and then Boundary_Reply.Payload.UInt32 = 1,
      "macOS NSAccessibility provider boundary routes selection requests");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Set_Selection;
   Boundary_Request.Selection_Request :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item;
   Boundary_Request.Selection_Target := Child;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Selection_Request_Reply
      and then Boundary_Reply.Payload.Kind = Selection_Request_Reply
      and then Boundary_Reply.Payload.Selection_Target = Child
      and then Boundary_Reply.Payload.Selection_Request =
        A11y.MacOS_Backend.NSAccessibility_Selection.Toggle_Item,
      "macOS NSAccessibility provider boundary preserves selection change requests");

   Boundary_Request.Selection_Request :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Clear_Selection;
   Boundary_Request.Selection_Target := A11y.Node_Ids.No_Node;
   A11y.Selection.Configure
     (Snapshots.Selection.Selection,
      A11y.Selection.Multiple,
      Requires_Selection => True);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Busy,
      "macOS NSAccessibility provider boundary maps invalid selection changes");
   A11y.Selection.Configure
     (Snapshots.Selection.Selection, A11y.Selection.Multiple);
   A11y.Selection.Select_Item
     (Snapshots.Selection.Selection, Child, Result);
   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Selection;

   Boundary_Request.Selection :=
     A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Item;
   Boundary_Request.Index := 9;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Invalid_Argument,
      "macOS NSAccessibility provider boundary maps invalid selection indexes");
   Boundary_Request.Index := 1;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Text;
   Boundary_Request.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Character_Count;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Text_UInt32
      and then Boundary_Reply.Payload.Kind = Text_UInt32
      and then Boundary_Reply.Payload.UInt32 = 3,
      "macOS NSAccessibility provider boundary routes text requests");

   Boundary_Request.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Text_Range;
   Boundary_Request.Index := 99;
   Boundary_Request.Count := 1;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Invalid_Argument,
      "macOS NSAccessibility provider boundary maps invalid text ranges");
   Boundary_Request.Text :=
     A11y.MacOS_Backend.NSAccessibility_Text.Caret_Offset;
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (4);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Invalid_Argument,
      "macOS NSAccessibility provider boundary maps invalid caret offsets");
   Snapshots.Text.Caret := A11y.Text.Code_Point_Position (2);
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Edit_Text;
   Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("X");
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Text_Edit_Request
      and then Boundary_Reply.Payload.Kind = Text_Edit_Request
      and then Boundary_Reply.Payload.Requested_Edit.Kind =
        A11y.Text.Insert_Text
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Boundary_Reply.Payload.Requested_Edit.Text) =
          Wide_Wide_String'("X"),
      "macOS NSAccessibility provider boundary routes text edit requests");

   Boundary_Request.Text_Edit := A11y.Text.Replace_Text;
   Boundary_Request.Index := 2;
   Boundary_Request.Count := 2;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("YZ");
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
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
      "macOS NSAccessibility provider boundary routes replace text requests");

   Boundary_Request.Text_Edit := A11y.Text.Set_Text;
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("Reset");
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Text_Edit_Request
      and then Boundary_Reply.Payload.Kind = Text_Edit_Request
      and then Boundary_Reply.Payload.Requested_Edit.Kind =
        A11y.Text.Set_Text
      and then Ada.Strings.Wide_Wide_Unbounded.To_Wide_Wide_String
        (Boundary_Reply.Payload.Requested_Edit.Text) =
          Wide_Wide_String'("Reset"),
      "macOS NSAccessibility provider boundary routes set text requests");

   Boundary_Request.Text_Edit := A11y.Text.Insert_Text;
   Boundary_Request.Index := 1;
   Boundary_Request.Count := 0;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("X");
   A11y.Resource_Limits.Set_Limit
     (Snapshots.Limits, A11y.Resource_Limits.Native_String_Size, 1, Result);
   Check (A11y.Results.Succeeded (Result),
          "macOS NSAccessibility test configures native string limit");
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String ("XX");
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Out_Of_Resources
      and then Boundary_Reply.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility provider boundary bounds text edit replacement payloads");
   Boundary_Request.Has_Native_Identity := True;
   Boundary_Request.Native_Node_Component :=
     A11y.Native_Identity.Runtime_Identifier_Component
       (Session, Child, Result);
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
       .Dispatch_Native_Request
         (Boundary_Request, Snapshots.all);
   Check
     (A11y.Results.Succeeded (Result)
      and then Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Native_Out_Of_Resources
      and then Boundary_Reply.Status = A11y.Results.Resource_Limit,
      "macOS NSAccessibility native callback boundary bounds text edit replacement payloads");
   Boundary_Request.Has_Native_Identity := False;
   Snapshots.Limits := A11y.Resource_Limits.Default_Config;
   Boundary_Request.Replacement :=
     Ada.Strings.Wide_Wide_Unbounded.Null_Unbounded_Wide_Wide_String;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Table;
   Boundary_Request.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Row_Count;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
      and then Boundary_Reply.Routed = Table_UInt32
      and then Boundary_Reply.Payload.Kind = Table_UInt32
      and then Boundary_Reply.Payload.UInt32 = 4,
      "macOS NSAccessibility provider boundary routes table requests");

   Boundary_Request.Table :=
     A11y.MacOS_Backend.NSAccessibility_Table.Cell_At;
   Boundary_Request.Row := 99;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Invalid_Argument,
      "macOS NSAccessibility provider boundary maps invalid table coordinates");
   Boundary_Request.Row := 0;
   Boundary_Request.Column := 0;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Image;
   Boundary_Request.Image :=
     A11y.MacOS_Backend.NSAccessibility_Image.Description;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Routed = Image_String
      and then Boundary_Reply.Payload.Kind = Image_String
      and then Ada.Strings.Unbounded.To_String (Boundary_Reply.Payload.Text)
        = "Revenue chart",
      "macOS NSAccessibility provider boundary routes image requests");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Document;
   Boundary_Request.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Heading_Level;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Routed = Document_UInt32
      and then Boundary_Reply.Payload.Kind = Document_UInt32
      and then Boundary_Reply.Payload.UInt32 = 2,
      "macOS NSAccessibility provider boundary routes document requests");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Live_Region;
   Boundary_Request.Live_Region :=
     A11y.MacOS_Backend.NSAccessibility_Live_Regions.Relevant_Names;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Routed = Live_String
      and then Boundary_Reply.Payload.Kind = Live_String
      and then Ada.Strings.Unbounded.To_String (Boundary_Reply.Payload.Text)
        = "text",
      "macOS NSAccessibility provider boundary routes live-region requests");

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Document;
   Boundary_Request.Document :=
     A11y.MacOS_Backend.NSAccessibility_Document.Heading_Level;
   Snapshots.Document.Metadata.Heading_Level := 99;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Invalid_Argument,
      "macOS NSAccessibility provider boundary maps invalid document metadata");
   Snapshots.Document.Metadata.Heading_Level := 2;

   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Surface;
   Boundary_Request.Surface :=
     A11y.MacOS_Backend.NSAccessibility_Surfaces.Is_Modal;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
      and then Boundary_Reply.Routed = Surface_Boolean
      and then Boundary_Reply.Payload.Kind = Surface_Boolean
      and then Boundary_Reply.Payload.Boolean_Item,
      "macOS NSAccessibility provider boundary routes surface requests");

   Snapshots.Surface.Defunct := True;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable,
      "macOS NSAccessibility provider boundary maps defunct surface metadata");
   Snapshots.Surface.Defunct := False;

   Snapshots.Properties.Defunct := True;
   Boundary_Request.Kind :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Attribute_Value;
   Boundary_Reply :=
     A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Dispatch_Request
       (Boundary_Request, Snapshots.all);
   Check
     (Boundary_Reply.Kind =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
      and then Boundary_Reply.Native_Result =
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Element_Unavailable,
      "macOS NSAccessibility provider boundary maps defunct nodes to native errors");
   Snapshots.Properties.Defunct := False;

   Check
     (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Status_For
        (A11y.Results.Permission_Denied) =
          A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Permission_Denied
      and then
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Status_For
          (A11y.Results.Out_Of_Resources) =
            A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Out_Of_Resources,
      "macOS NSAccessibility provider boundary maps structured errors");

   declare
      function Class_Expected
        (Status : A11y.Results.Status_Code)
         return Boolean is
        (case A11y.Native_Boundary_Calls.Return_Class (Status) is
            when A11y.Native_Boundary_Calls.Return_Success =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Success,
            when A11y.Native_Boundary_Calls.Return_Unsupported =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Not_Applicable,
            when A11y.Native_Boundary_Calls.Return_Unavailable |
                 A11y.Native_Boundary_Calls.Return_Shutting_Down =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Element_Unavailable,
            when A11y.Native_Boundary_Calls.Return_Invalid_Argument =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Invalid_Argument,
            when A11y.Native_Boundary_Calls.Return_Permission_Denied =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Permission_Denied,
            when A11y.Native_Boundary_Calls.Return_Resource_Limit =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Out_Of_Resources,
            when A11y.Native_Boundary_Calls.Return_Disabled |
                 A11y.Native_Boundary_Calls.Return_Invalid_State |
                 A11y.Native_Boundary_Calls.Return_Read_Only |
                 A11y.Native_Boundary_Calls.Return_Busy |
                 A11y.Native_Boundary_Calls.Return_Timed_Out |
                 A11y.Native_Boundary_Calls.Return_Cancelled =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Busy,
            when A11y.Native_Boundary_Calls.Return_Protocol_Failure |
                 A11y.Native_Boundary_Calls.Return_Native_Failure |
                 A11y.Native_Boundary_Calls.Return_Internal_Error =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Status_For (Status) =
                  A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                    .Native_Failed);

      function Expected
        (Status : A11y.Results.Status_Code)
         return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status is
        (case Status is
            when A11y.Results.Success |
                 A11y.Results.Accepted_Asynchronous =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Success,
            when A11y.Results.Unsupported_Property |
                 A11y.Results.Unsupported_Capability |
                 A11y.Results.Unsupported_Action =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Not_Applicable,
            when A11y.Results.Node_Unavailable |
                 A11y.Results.Backend_Unavailable |
                 A11y.Results.Accessibility_Service_Unavailable |
                 A11y.Results.Shutting_Down =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Element_Unavailable,
            when A11y.Results.Invalid_Argument |
                 A11y.Results.Invalid_Range =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Invalid_Argument,
            when A11y.Results.Permission_Denied =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Permission_Denied,
            when A11y.Results.Out_Of_Resources |
                 A11y.Results.Resource_Limit =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Out_Of_Resources,
            when A11y.Results.Disabled |
                 A11y.Results.Invalid_State |
                 A11y.Results.Read_Only |
                 A11y.Results.Busy |
                 A11y.Results.Timed_Out |
                 A11y.Results.Cancelled =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Busy,
            when A11y.Results.Protocol_Failure |
                 A11y.Results.Native_Failure |
                 A11y.Results.Internal_Error =>
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Failed);

      Complete : Boolean := True;
   begin
      for Status in A11y.Results.Status_Code loop
         Complete := Complete
           and then
             A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Status_For (Status) = Expected (Status)
           and then Class_Expected (Status);
      end loop;
      Check
        (Complete,
         "macOS NSAccessibility provider boundary maps every structured status through return classes");
      Check
        (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Success) = "success"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Not_Applicable) = "not-applicable"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_No_Value) = "no-value"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Element_Unavailable) = "element-unavailable"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Invalid_Argument) = "invalid-argument"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Permission_Denied) = "permission-denied"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Out_Of_Resources) = "out-of-resources"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Busy) = "busy"
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Native_Status_Name
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Failed) = "failed",
         "macOS NSAccessibility provider boundary exposes stable native status names");
      Check
        (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Success) = A11y.Results.Success
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Not_Applicable) =
                  A11y.Results.Unsupported_Capability
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_No_Value) = A11y.Results.Unsupported_Property
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Element_Unavailable) = A11y.Results.Node_Unavailable
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Invalid_Argument) = A11y.Results.Invalid_Argument
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Permission_Denied) = A11y.Results.Permission_Denied
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Out_Of_Resources) = A11y.Results.Resource_Limit
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Busy) = A11y.Results.Busy
         and then A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
           .Status_For_Native_Status
             (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Failed) = A11y.Results.Internal_Error,
         "macOS NSAccessibility provider boundary maps native statuses to structured statuses");
   end;

   declare
      Result : A11y.Results.Result;
      Diagnostic : constant A11y.Diagnostics.Diagnostic :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Diagnostic_For_Native_Status
            (A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
               .Native_Element_Unavailable,
             Result);
   begin
      Check
        (A11y.Results.Succeeded (Result)
         and then Diagnostic.Class = A11y.Diagnostics.Stale_Native_Query
         and then A11y.Diagnostics.Has_Field
           (Diagnostic, "native_status_name", "element-unavailable")
         and then A11y.Diagnostics.Has_Field
           (Diagnostic, "native_status", "NATIVE_ELEMENT_UNAVAILABLE")
         and then A11y.Diagnostics.Has_Field
           (Diagnostic, "structured_status", "node-unavailable"),
         "macOS NSAccessibility provider boundary creates structured native-status diagnostics");
   end;

   declare
      Invalid_Element :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Element : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Snapshot : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      Export :
        A11y.MacOS_Backend.NSAccessibility_Elements
          .Element_Export_Descriptor;
      Call : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Call_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      Retains : Natural;
   begin
      A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
        (Invalid_Element,
         A11y.Native_Identity.No_Session,
         Root,
         Child,
         Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot
          (Invalid_Element);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Snapshot.State =
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Created
         and then Snapshot.Retains = 0
         and then Snapshot.Node = A11y.Node_Ids.No_Node,
         "macOS NSAccessibility element scaffold rejects invalid identity initialization");

      A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
        (Element, Session, Root, Child, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.State =
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Live
         and then Snapshot.Retains = 1
         and then Snapshot.Active_Calls = 0
         and then A11y.MacOS_Backend.NSAccessibility_Elements.Drained
           (Element)
         and then not Snapshot.Native_View_Bound
         and then Snapshot.Root = Root
         and then Snapshot.Node = Child,
         "macOS NSAccessibility element scaffold initializes stable identity");

      Export :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Export_Descriptor
          (Element);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Export.Exportable
         and then Export.Status = A11y.Results.Success
         and then Export.Session = Session
         and then Export.Root = Root
         and then Export.Node = Child
         and then Export.Native_Node_Component =
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Child, Result)
         and then not Export.Main_Thread_Bound
         and then not Export.Native_View_Bound
         and then Export.Native_View_Component = 0
         and then Snapshot.Retains = 1,
         "macOS NSAccessibility element scaffold exports Objective-C-free descriptors without retain");

      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call, Result);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      Check
        (A11y.Results.Succeeded (Result)
         and then Call_Snapshot.Active
         and then Call_Snapshot.Root = Root
         and then Call_Snapshot.Node = Child
         and then not Call_Snapshot.Main_Thread_Bound
         and then Call_Snapshot.Native_Call_Token /= 0
         and then Call_Snapshot.Native_Node_Component =
           A11y.Native_Identity.Runtime_Identifier_Component
             (Session, Child, Result),
         "macOS NSAccessibility element scaffold begins native calls with stable identity");
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Snapshot.Active_Calls = 1
         and then not A11y.MacOS_Backend.NSAccessibility_Elements.Drained
           (Element),
         "macOS NSAccessibility element scaffold records outstanding native calls");

      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call, Result);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
         (A11y.Results.Succeeded (Result)
         and then not Call_Snapshot.Active
         and then Call_Snapshot.Native_Call_Token = 0
         and then Snapshot.Active_Calls = 0
         and then A11y.MacOS_Backend.NSAccessibility_Elements.Drained
           (Element),
         "macOS NSAccessibility element scaffold releases native call admissions");

      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call, Result, Require_Main_Thread => True);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then not Call_Snapshot.Active,
         "macOS NSAccessibility element scaffold rejects main-thread calls before binding");

      A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Native_View
        (Element, 23, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then not Snapshot.Native_View_Bound
         and then Snapshot.Native_View_Component = 0,
         "macOS NSAccessibility element scaffold rejects native-view binding before main-thread binding without mutation");

      A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Main_Thread
        (Element, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Main_Thread_Bound,
         "macOS NSAccessibility element scaffold records main-thread binding");

      A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Native_View
        (Element, 23, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Native_View_Bound
         and then Snapshot.Native_View_Component = 23,
         "macOS NSAccessibility element scaffold binds native views after main-thread binding");
      Export :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Export_Descriptor
          (Element);
      Check
        (Export.Exportable
         and then Export.Main_Thread_Bound
         and then Export.Native_View_Bound
         and then Export.Native_View_Component = 23,
         "macOS NSAccessibility element scaffold includes view binding in export descriptors");

      declare
         package ABI renames A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
         package Boundary renames
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;

         ABI_Descriptor : ABI.Selector_Descriptor;
         ABI_Request : Boundary.Boundary_Request;
         Decoded_Selector : ABI.NSAX_Selector;
      begin
         for Selector in ABI.NSAX_Selector loop
            Decoded_Selector :=
              ABI.Selector_From_Code
                (ABI.Selector_Code (Selector), Result);
            Check
              (A11y.Results.Succeeded (Result)
               and then Decoded_Selector = Selector,
               "macOS NSAccessibility ABI surface round-trips selector callback codes");
         end loop;

         Decoded_Selector := ABI.Selector_From_Code (99, Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument
            and then Decoded_Selector = ABI.Accessibility_Attribute_Value,
            "macOS NSAccessibility ABI surface rejects malformed selector callback codes");

         ABI_Descriptor := ABI.Descriptor (ABI.Accessibility_Attribute_Value);
         ABI_Request := ABI.Prepare_Request
           (Export, ABI.Accessibility_Attribute_Value, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then ABI.Selector_Name (ABI.Accessibility_Attribute_Value)
              = "accessibilityAttributeValue:"
            and then ABI_Descriptor.Method_Family =
              Boundary.Attribute_Method
            and then ABI_Descriptor.Request_Kind =
              Boundary.Copy_Attribute_Value
            and then ABI_Descriptor.Requires_Main_Thread
            and then ABI_Request.Kind = Boundary.Copy_Attribute_Value
            and then ABI_Request.Has_Native_Identity
            and then ABI_Request.Native_Node_Component =
              Export.Native_Node_Component,
            "macOS NSAccessibility ABI surface prepares selector callbacks through native identity");

         ABI_Descriptor := ABI.Descriptor (ABI.Accessibility_Hit_Test);
         ABI_Request := ABI.Prepare_Request
           (Export, ABI.Accessibility_Hit_Test, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then ABI.Selector_Name (ABI.Accessibility_Hit_Test)
              = "accessibilityHitTest:"
            and then ABI.Can_Dispatch (Export, ABI.Accessibility_Hit_Test)
            and then ABI_Descriptor.Supported
            and then ABI_Descriptor.Method_Family =
              Boundary.Hierarchy_Method
            and then ABI_Descriptor.Request_Kind = Boundary.Copy_Element_Id
            and then ABI_Descriptor.Requires_Main_Thread
            and then ABI_Request.Kind = Boundary.Copy_Element_Id
            and then ABI_Request.Has_Native_Identity
            and then ABI_Request.Native_Node_Component =
              Export.Native_Node_Component,
            "macOS NSAccessibility ABI surface prepares hit-test selectors through native identity");

         ABI_Descriptor :=
           ABI.Descriptor (ABI.Accessibility_Focused_UI_Element);
         ABI_Request := ABI.Prepare_Request
           (Export, ABI.Accessibility_Focused_UI_Element, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then ABI.Selector_Name
              (ABI.Accessibility_Focused_UI_Element)
              = "accessibilityFocusedUIElement"
            and then ABI.Can_Dispatch
              (Export, ABI.Accessibility_Focused_UI_Element)
            and then ABI_Descriptor.Supported
            and then ABI_Descriptor.Method_Family =
              Boundary.Hierarchy_Method
            and then ABI_Descriptor.Request_Kind = Boundary.Copy_Element_Id
            and then ABI_Descriptor.Requires_Main_Thread
            and then ABI_Request.Kind = Boundary.Copy_Element_Id
            and then ABI_Request.Has_Native_Identity
            and then ABI_Request.Native_Node_Component =
              Export.Native_Node_Component,
            "macOS NSAccessibility ABI surface prepares focused-element selectors through native identity");

         ABI_Request := ABI.Prepare_Request
           (Export, ABI.Accessibility_Attribute_Names, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then ABI.Selector_Name (ABI.Accessibility_Attribute_Names)
              = "accessibilityAttributeNames"
            and then ABI.Descriptor
              (ABI.Accessibility_Attribute_Names).Supported
            and then ABI.Descriptor
              (ABI.Accessibility_Attribute_Names).Method_Family =
                Boundary.Attribute_Method
            and then ABI.Descriptor
              (ABI.Accessibility_Attribute_Names).Request_Kind =
                Boundary.Copy_Attribute_Names
            and then ABI_Request.Kind = Boundary.Copy_Attribute_Names
            and then ABI_Request.Has_Native_Identity
            and then ABI_Request.Native_Node_Component =
              Export.Native_Node_Component,
            "macOS NSAccessibility ABI surface prepares attribute-name selectors through native identity");
      end;

      declare
         package ABI renames A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
         package Boundary renames
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;

         Unbound_Element :
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
         Unbound_Export :
           A11y.MacOS_Backend.NSAccessibility_Elements
             .Element_Export_Descriptor;
         ABI_Request : Boundary.Boundary_Request;
      begin
         A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
           (Unbound_Element, Session, Root, Child, Result);
         Unbound_Export :=
           A11y.MacOS_Backend.NSAccessibility_Elements.Export_Descriptor
             (Unbound_Element);
         ABI_Request := ABI.Prepare_Request
           (Unbound_Export, ABI.Accessibility_Perform_Action, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then not ABI_Request.Has_Native_Identity,
            "macOS NSAccessibility ABI surface requires main-thread binding before selector dispatch");
      end;

      declare
         package ABI renames A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
         package Boundary renames
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
         package Registry renames
           A11y.MacOS_Backend.NSAccessibility_Element_Registry;
         package Router renames
           A11y.MacOS_Backend.NSAccessibility_Request_Router;

         Registered : Registry.Element_Registry;
         Element_Id : Registry.Element_Id := Registry.No_Element;
         Snapshots : Router.Snapshot_Bundle;
         Frame : ABI.Selector_Frame;
         Frame_Report : ABI.Selector_Frame_Report;
         Frame_Reply : Boundary.Boundary_Reply;
      begin
         Registry.Ensure_Element
           (Registered, Session, Root, Root, Element_Id, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Registry.Is_Valid (Element_Id)
            and then Registry.From_Natural
              (Registry.To_Natural (Element_Id)) = Element_Id,
            "macOS NSAccessibility element registry decodes stable element ids for ABI frames");

         Registry.Bind_Main_Thread
           (Registered, Session, Element_Id, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "macOS NSAccessibility selector-frame fixture binds registered elements to the main thread");

         A11y.Trees.Set_Root (Snapshots.Hierarchy.Tree, Root, Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Trees.Attach (Snapshots.Hierarchy.Tree, Root, Child, Result);
         end if;
         Snapshots.Hierarchy.Session := Session;
         Snapshots.Hierarchy.Root := Root;
         Snapshots.Hierarchy.Node := Root;

         Frame := ABI.Build_Selector_Frame
           (Session, Element_Id, ABI.Accessibility_Children);
         Frame_Reply := ABI.Dispatch_Selector_Frame
           (Registered, Frame, Snapshots, Frame_Report);
         Check
           (A11y.Results.Succeeded (Result)
            and then Frame_Report.Session_Code_Valid
            and then Frame_Report.Element_Code_Valid
            and then Frame_Report.Selector_Code_Valid
            and then Frame_Report.Request_Prepared
            and then Frame_Report.Dispatch.Native_Admitted
            and then Frame_Report.Dispatch.Native_Completed
            and then Frame_Reply.Kind = Boundary.Native_Reply
            and then Frame_Reply.Native_Result = Boundary.Native_Success
            and then Frame_Reply.Routed = Router.Hierarchy_Children
            and then not Frame_Reply.Payload.Children.Is_Empty
            and then Frame_Reply.Payload.Children
              (Frame_Reply.Payload.Children.First_Index) = Child,
            "macOS NSAccessibility selector frames dispatch hierarchy children through registered native calls");

         Frame := ABI.Build_Selector_Frame
           (Session, Element_Id, ABI.Accessibility_Child_At_Index, 1);
         Frame_Reply := ABI.Dispatch_Selector_Frame
           (Registered, Frame, Snapshots, Frame_Report);
         Check
           (Frame_Report.Request_Prepared
            and then Frame_Report.Dispatch.Native_Admitted
            and then Frame_Report.Dispatch.Native_Completed
            and then Frame_Reply.Kind = Boundary.Native_Reply
            and then Frame_Reply.Routed = Router.Hierarchy_Node
            and then Frame_Reply.Payload.Node = Child,
            "macOS NSAccessibility selector frames preserve indexed child queries");

         Frame := ABI.Build_Callback_Frame
           (Frame.Session_Code,
            Frame.Element_Code,
            ABI.Selector_Code (ABI.Accessibility_Child_At_Index),
            Operand_Code => 1);
         Frame_Reply := ABI.Dispatch_Callback
           (Registered,
            Frame.Session_Code,
            Frame.Element_Code,
            ABI.Selector_Code (ABI.Accessibility_Child_At_Index),
            Operand_Code => 1,
            Snapshots => Snapshots,
            Report => Frame_Report);
         Check
           (Frame.Child_Index_Code = 1
            and then Frame.Operand_Code = 0
            and then Frame_Report.Request_Prepared
            and then Frame_Report.Dispatch.Native_Admitted
            and then Frame_Report.Dispatch.Native_Completed
            and then Frame_Reply.Kind = Boundary.Native_Reply
            and then Frame_Reply.Routed = Router.Hierarchy_Node
            and then Frame_Reply.Payload.Node = Child,
            "macOS NSAccessibility raw callback frames map child-index operands");

         Snapshots.Actions (A11y.Actions.Expand) := True;
         Snapshots.Action_Node := Root;
         Snapshots.Action_Root := Root;
         Frame := ABI.Build_Selector_Frame
           (Session,
            Element_Id,
            ABI.Accessibility_Perform_Action,
            Operand_Code => ABI.Action_Code (A11y.Actions.Expand));
         Frame_Reply := ABI.Dispatch_Selector_Frame
           (Registered, Frame, Snapshots, Frame_Report);
         Check
           (Frame.Operand_Code = ABI.Action_Code (A11y.Actions.Expand)
            and then Frame_Report.Request_Prepared
            and then Frame_Report.Dispatch.Native_Admitted
            and then Frame_Report.Dispatch.Native_Completed
            and then Frame_Reply.Kind = Boundary.Native_Reply
            and then Frame_Reply.Routed = Router.Action_Request
            and then Frame_Reply.Payload.Requested_Action =
              A11y.Actions.Expand,
            "macOS NSAccessibility selector frames preserve native action operands");

         Frame := ABI.Build_Callback_Frame
           (Frame.Session_Code,
            Frame.Element_Code,
            ABI.Selector_Code (ABI.Accessibility_Post_Notification),
            Operand_Code => 13);
         Check
           (Frame.Selector_Code =
              ABI.Selector_Code (ABI.Accessibility_Post_Notification)
            and then Frame.Child_Index_Code = 1
            and then Frame.Operand_Code = 13,
            "macOS NSAccessibility raw callback frames preserve notification operands");

         Frame := ABI.Build_Selector_Frame
           (Session,
            Element_Id,
            ABI.Accessibility_Attribute_Value,
            Operand_Code => 999);
         Frame_Reply := ABI.Dispatch_Selector_Frame
           (Registered, Frame, Snapshots, Frame_Report);
         Check
           (Frame_Report.Selector_Code_Valid
            and then not Frame_Report.Request_Prepared
            and then Frame_Report.Status = A11y.Results.Invalid_Argument
            and then Frame_Reply.Kind = Boundary.Native_Error
            and then Frame_Reply.Native_Result =
              Boundary.Native_Invalid_Argument,
            "macOS NSAccessibility selector frames reject malformed attribute operands before provider dispatch");

         Frame.Selector_Code := 99;
         Frame_Reply := ABI.Dispatch_Selector_Frame
           (Registered, Frame, Snapshots, Frame_Report);
         Check
           (not Frame_Report.Selector_Code_Valid
            and then not Frame_Report.Request_Prepared
            and then Frame_Report.Status = A11y.Results.Invalid_Argument
            and then Frame_Reply.Kind = Boundary.Native_Error
            and then Frame_Reply.Native_Result =
              Boundary.Native_Invalid_Argument,
            "macOS NSAccessibility selector frames reject malformed selectors before provider dispatch");

         Frame := ABI.Build_Selector_Frame
           (Session, Element_Id, ABI.Accessibility_Children);
         Frame.Element_Code := 0;
         Frame_Reply := ABI.Dispatch_Selector_Frame
           (Registered, Frame, Snapshots, Frame_Report);
         Check
           (not Frame_Report.Element_Code_Valid
            and then not Frame_Report.Request_Prepared
            and then Frame_Report.Status = A11y.Results.Invalid_Argument
            and then Frame_Reply.Kind = Boundary.Native_Error
            and then Frame_Reply.Native_Result =
              Boundary.Native_Invalid_Argument,
            "macOS NSAccessibility selector frames reject malformed element ids before provider dispatch");
      end;

      A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Native_View
        (Element, 23, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility element scaffold treats native-view rebinding as idempotent");

      A11y.MacOS_Backend.NSAccessibility_Elements.Bind_Native_View
        (Element, 24, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Native_View_Component = 23,
         "macOS NSAccessibility element scaffold rejects conflicting native-view bindings");

      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call, Result, Require_Main_Thread => True);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      Check
        (A11y.Results.Succeeded (Result)
         and then Call_Snapshot.Active
         and then Call_Snapshot.Main_Thread_Bound,
         "macOS NSAccessibility element scaffold admits main-thread native calls after binding");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Active_Calls = 0,
         "macOS NSAccessibility element scaffold releases main-thread call admissions");

      A11y.MacOS_Backend.NSAccessibility_Elements.Retain
        (Element, Retains, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Retains = 2,
         "macOS NSAccessibility element scaffold retains live elements");

      A11y.MacOS_Backend.NSAccessibility_Elements.Mark_Defunct
        (Element, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call, Result);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then not Call_Snapshot.Active
         and then Call_Snapshot.Defunct,
         "macOS NSAccessibility element scaffold rejects native calls after defunct");
      Export :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Export_Descriptor
          (Element);
      Check
        (not Export.Exportable
         and then Export.Status = A11y.Results.Node_Unavailable
         and then Export.Defunct,
         "macOS NSAccessibility element scaffold rejects defunct export descriptors");

      A11y.MacOS_Backend.NSAccessibility_Elements.Retain
        (Element, Retains, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Retains = 2
         and then Snapshot.Retains = 2,
         "macOS NSAccessibility element scaffold rejects retain after defunct without mutation");

      A11y.MacOS_Backend.NSAccessibility_Elements.Release
        (Element, Retains, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Release
        (Element, Retains, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Retains = 0
         and then Snapshot.State =
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Destroyed
         and then Snapshot.Defunct,
         "macOS NSAccessibility element scaffold destroys exactly at final Release");

      A11y.MacOS_Backend.NSAccessibility_Elements.Release
        (Element, Retains, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Retains = 0
         and then Snapshot.State =
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Destroyed
         and then Snapshot.Defunct,
         "macOS NSAccessibility element scaffold rejects release after destruction");
   end;

   declare
      Element : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      Call : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Stale_Call :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Other_Call :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Call_Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      Retains : Natural;
      Generation_After_Two_Calls : Natural := 0;
      Generation_After_First_Release : Natural := 0;
   begin
      A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
        (Element, Session, Root, Child, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call, Result);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Call_Generation = 1
         and then Call_Snapshot.Native_Call_Generation =
           Snapshot.Call_Generation,
         "macOS NSAccessibility element scaffold records native call generations");
      Stale_Call := Call;
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Other_Call, Result);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Other_Call);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Generation_After_Two_Calls := Snapshot.Call_Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Active_Calls = 2
         and then Snapshot.Call_Generation = 2
         and then Call_Snapshot.Native_Call_Generation =
           Snapshot.Call_Generation,
         "macOS NSAccessibility element scaffold tracks concurrent native call tokens");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Generation_After_First_Release := Snapshot.Call_Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Call_Generation > Generation_After_Two_Calls,
         "macOS NSAccessibility element scaffold advances generation on native call release");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Stale_Call, Result);
      Call_Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Stale_Call);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Active_Calls = 1
         and then Snapshot.Call_Generation = Generation_After_First_Release
         and then not Call_Snapshot.Active
         and then Call_Snapshot.Native_Call_Token = 0,
         "macOS NSAccessibility element scaffold rejects stale copied native call contexts");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Other_Call, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility element scaffold releases the remaining native call after stale rejection");
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Release
        (Element, Retains, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Retains = 0
         and then Snapshot.State =
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Defunct
         and then Snapshot.Active_Calls = 1
         and then not A11y.MacOS_Backend.NSAccessibility_Elements.Drained
           (Element),
         "macOS NSAccessibility element scaffold defers destruction during native calls");

      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.State =
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Destroyed
         and then Snapshot.Active_Calls = 0
         and then A11y.MacOS_Backend.NSAccessibility_Elements.Drained
           (Element),
         "macOS NSAccessibility element scaffold destroys after final native call returns");

      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "macOS NSAccessibility element scaffold rejects duplicate native call release");
   end;

   declare
      Element : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Call_1 : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Call_2 : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Call_3 : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Call_4 : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Stale_Call_2 :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      Generation_After_Release : Natural := 0;
   begin
      A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
        (Element, Session, Root, Child, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call_1, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call_2, Result);
      Stale_Call_2 := Call_2;
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call_3, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.Begin_Native_Call
        (Element, Call_4, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Active_Calls = 4,
         "macOS NSAccessibility element scaffold tracks four active native call tokens");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call_2, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Generation_After_Release := Snapshot.Call_Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Active_Calls = 3,
         "macOS NSAccessibility element scaffold releases one token while peers remain active");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Stale_Call_2, Result);
      declare
         Stale_View : constant
           A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot :=
             A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot
               (Stale_Call_2);
      begin
         Check
           (not Stale_View.Active
            and then Stale_View.Native_Call_Token = 0
            and then Stale_View.Status = A11y.Results.Invalid_State,
            "macOS NSAccessibility element scaffold poisons stale middle native call tokens");
      end;
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Active_Calls = 3
         and then Snapshot.Call_Generation = Generation_After_Release,
         "macOS NSAccessibility element scaffold rejects stale middle native call tokens");
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call_1, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call_3, Result);
      A11y.MacOS_Backend.NSAccessibility_Elements.End_Native_Call
        (Element, Call_4, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Element);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Active_Calls = 0,
         "macOS NSAccessibility element scaffold drains after stale middle-token rejection");
   end;

   declare
      Element : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
      Retains : Natural;
   begin
      A11y.MacOS_Backend.NSAccessibility_Elements.Initialize
        (Element, Session, Root, Child, Result);
      for Index in 2 .. A11y.MacOS_Backend.NSAccessibility_Elements.Max_Retain_Count loop
         A11y.MacOS_Backend.NSAccessibility_Elements.Retain
           (Element, Retains, Result);
      end loop;
      A11y.MacOS_Backend.NSAccessibility_Elements.Retain
        (Element, Retains, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Retains =
           A11y.MacOS_Backend.NSAccessibility_Elements.Max_Retain_Count,
         "macOS NSAccessibility element scaffold bounds retain overflow");
   end;

   declare
      package Registry_API renames
        A11y.MacOS_Backend.NSAccessibility_Element_Registry;
      Registry : Registry_API.Element_Registry;
      Id : Registry_API.Element_Id;
      Again : Registry_API.Element_Id;
      Other : Registry_API.Element_Id;
      View : Registry_API.Registry_Snapshot;
      Element_View : Registry_API.Element_Record_Snapshot;
      Call : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Call_View :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
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
         "macOS NSAccessibility element registry accepts native-object resource limits");
      Generation_After_Configure := View.Generation;

      Registry_API.Ensure_Element_With_Report
        (Registry, Session, Root, Child, Id, Report, Result);
      Registry_API.Ensure_Element
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
         "macOS NSAccessibility element registry returns stable ids for semantic nodes");
      Check
        (Report.Operation = Registry_API.Registry_Ensure_Element
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
         and then Report.Element_Returned,
         "macOS NSAccessibility element registry reports element creation mutation details");
      Generation_After_Ensure := View.Generation;

      Registry_API.Find_Element
        (Registry, Session, Child, Element_View, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Element_View.Id = Id
         and then Element_View.Registry_Generation = View.Generation
         and then Element_View.Element.Node = Child
         and then Element_View.Element.Root = Root,
         "macOS NSAccessibility element registry finds elements by stable Node_Id");

      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Perform_Action;
      Boundary_Request.Action := A11y.Actions.Press;
      Boundary_Request.Has_Native_Identity := False;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
            (Registry,
             Session,
             Id,
             Boundary_Request,
             Snapshots.all,
             Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "macOS NSAccessibility registered native boundary dispatches and drains successful element calls");
      Check
        (Registered_Boundary_Report.Method_Family_Supported
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
         "macOS NSAccessibility registered native boundary reports begin and end call lifecycle");

      Snapshots.Action_Node := Root;
      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Perform_Action;
      Boundary_Request.Action := A11y.Actions.Press;
      Boundary_Request.Has_Native_Identity := False;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
            (Registry,
             Session,
             Id,
             Boundary_Request,
             Snapshots.all,
             Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Native_Element_Unavailable
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "macOS NSAccessibility registered native boundary rejects identity mismatches before element admission");
      Check
        (Registered_Boundary_Report.Method_Family_Supported
         and then Registered_Boundary_Report.Resolved
         and then Registered_Boundary_Report.Native_Identity_Prepared
         and then not Registered_Boundary_Report.Native_Admitted
         and then not Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Node_Unavailable
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Node_Unavailable,
         "macOS NSAccessibility registered native boundary reports identity mismatch rejection before begin-call");
      Snapshots.Action_Node := Child;

      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Parent;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
            (Registry,
             Session,
             Id,
             Boundary_Request,
             Snapshots.all,
             Registered_Boundary_Report,
             Method_Family =>
               A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                 .Attribute_Method);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Nil
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Native_Not_Applicable
         and then Boundary_Reply.Status =
           A11y.Results.Unsupported_Capability
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "macOS NSAccessibility registered native boundary rejects hierarchy calls through the attribute method family");
      Check
        (not Registered_Boundary_Report.Method_Family_Supported
         and then not Registered_Boundary_Report.Resolved
         and then not Registered_Boundary_Report.Native_Admitted
         and then not Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Unsupported_Capability
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Unsupported_Capability,
         "macOS NSAccessibility registered native boundary reports unsupported method-family rejection before admission");

      Snapshots.Hierarchy.Node := Child;
      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Parent;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request
            (Registry,
             Session,
             Id,
             Boundary_Request,
             Snapshots.all);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Reply
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Success
         and then Boundary_Reply.Routed = Hierarchy_Node
         and then Boundary_Reply.Payload.Kind = Hierarchy_Node
         and then Boundary_Reply.Payload.Node = Root
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "macOS NSAccessibility registered native boundary preserves hierarchy parent payloads");

      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Element_Id;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request
            (Registry,
             Session,
             Id,
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
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Reply
            and then Boundary_Reply.Native_Result =
              A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
                .Native_Success
            and then Boundary_Reply.Routed = Element_Id
            and then Boundary_Reply.Payload.Kind = Element_Id
            and then Boundary_Reply.Payload.Id.Session_Component =
              A11y.Native_Identity.To_Natural (Session)
            and then Boundary_Reply.Payload.Id.Root_Component =
              Root_Component
            and then Boundary_Reply.Payload.Id.Node_Component =
              Node_Component
            and then View.Outstanding_Calls = 0
            and then View.Generation = Generation_After_Ensure,
            "macOS NSAccessibility registered native boundary preserves element identity payloads");
      end;
      Snapshots.Hierarchy.Node := Root;

      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Perform_Action;
      Boundary_Request.Action := A11y.Actions.Select_Item;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
            (Registry,
             Session,
             Id,
             Boundary_Request,
             Snapshots.all,
             Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Nil
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Native_Not_Applicable
         and then Boundary_Reply.Status = A11y.Results.Unsupported_Action
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Ensure,
         "macOS NSAccessibility registered native boundary drains element calls after routed errors");
      Check
        (Registered_Boundary_Report.Method_Family_Supported
         and then Registered_Boundary_Report.Resolved
         and then Registered_Boundary_Report.Native_Admitted
         and then Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Unsupported_Action
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Unsupported_Action,
         "macOS NSAccessibility registered native boundary reports routed-error statuses after drain");

      Registry_API.Begin_Native_Call_With_Report
        (Registry, Session, Id, Call, Call_Report, Result);
      Call_View :=
        A11y.MacOS_Backend.NSAccessibility_Elements.Snapshot (Call);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then Call_View.Active
         and then Call_View.Node = Child
         and then View.Outstanding_Calls = 1
         and then View.Generation = Generation_After_Ensure
         and then not Registry_API.Drained (Registry),
         "macOS NSAccessibility element registry admits native calls through element ids");
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
         and then not Call_Report.Require_Main_Thread
         and then Call_Report.Context.Active
         and then Call_Report.Call_Active
         and then Call_Report.Status = A11y.Results.Success,
         "macOS NSAccessibility element registry reports native-call admission details");

      Registry_API.Release_With_Report (Registry, Session, Id, Report, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (A11y.Results.Succeeded (Result)
         and then View.Live_Count = 0
         and then View.Tombstones = 1
         and then View.Outstanding_Calls = 1
         and then View.Generation > Generation_After_Ensure
         and then not Registry_API.Drained (Registry),
         "macOS NSAccessibility element registry defers released elements while calls drain");
      Check
        (Report.Operation = Registry_API.Registry_Release_Element
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
         and then Report.Element_Returned,
         "macOS NSAccessibility element registry reports element release mutation details");
      Generation_After_Release := View.Generation;

      Boundary_Request.Kind :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Copy_Parent;
      Boundary_Reply :=
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Dispatch_Registered_Native_Request_With_Report
            (Registry,
             Session,
             Id,
             Boundary_Request,
             Snapshots.all,
             Registered_Boundary_Report);
      View := Registry_API.Snapshot (Registry);
      Check
        (Boundary_Reply.Kind =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Error
         and then Boundary_Reply.Native_Result =
           A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
             .Native_Element_Unavailable
         and then Boundary_Reply.Status = A11y.Results.Node_Unavailable
         and then View.Outstanding_Calls = 1
         and then View.Generation = Generation_After_Release,
         "macOS NSAccessibility registered native boundary rejects released elements before admission");
      Check
        (Registered_Boundary_Report.Method_Family_Supported
         and then not Registered_Boundary_Report.Resolved
         and then not Registered_Boundary_Report.Native_Identity_Prepared
         and then not Registered_Boundary_Report.Native_Admitted
         and then not Registered_Boundary_Report.Native_Completed
         and then Registered_Boundary_Report.Reply_Status =
           A11y.Results.Node_Unavailable
         and then Registered_Boundary_Report.Final_Status =
           A11y.Results.Node_Unavailable,
         "macOS NSAccessibility registered native boundary reports released-element rejection before provider dispatch");

      Registry_API.Reset_When_Drained_With_Report (Registry, Report, Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (Result.Status = A11y.Results.Busy
         and then View.Tombstones = 1
         and then View.Generation = Generation_After_Release
         and then not Registry_API.Drained (Registry),
         "macOS NSAccessibility element registry rejects checked reset while calls drain");
      Check
        (Report.Operation = Registry_API.Registry_Reset
         and then Report.Generation_Before = Generation_After_Release
         and then Report.Generation_After = Generation_After_Release
         and then Report.Status = A11y.Results.Busy
         and then not Report.Generation_Advanced,
         "macOS NSAccessibility element registry reports busy checked reset without mutation");

      Registry_API.Reset (Registry);
      View := Registry_API.Snapshot (Registry);
      Check
        (View.Tombstones = 1
         and then View.Outstanding_Calls = 1
         and then View.Generation = Generation_After_Release
         and then not Registry_API.Drained (Registry),
         "macOS NSAccessibility element registry bare reset preserves pinned calls");

      Registry_API.End_Native_Call_With_Report
        (Registry, Session, Id, Call, Call_Report, Result);
      View := Registry_API.Snapshot (Registry);
      Registry_API.Resolve_Element
        (Registry, Session, Id, Element_View, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then View.Outstanding_Calls = 0
         and then View.Generation = Generation_After_Release,
         "macOS NSAccessibility element registry rejects stale element ids after release");
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
         "macOS NSAccessibility element registry reports native-call release details");
      Check
        (Registry_API.Drained (Registry),
         "macOS NSAccessibility element registry reports drained after native calls return");

      Registry_API.Ensure_Element
        (Registry, Session, Root, Root, Other, Result);
      Registry_API.Bind_Main_Thread (Registry, Session, Other, Result);
      Registry_API.Bind_Native_View (Registry, Session, Other, 99, Result);
      Registry_API.Resolve_Element
        (Registry, Session, Other, Element_View, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Registry_API.To_Natural (Other) = 2
         and then Element_View.Element.Main_Thread_Bound
         and then Element_View.Element.Native_View_Bound
         and then Element_View.Element.Native_View_Component = 99,
         "macOS NSAccessibility element registry does not reuse ids and preserves bindings");
      View := Registry_API.Snapshot (Registry);
      Generation_After_Ensure := View.Generation;

      Registry_API.Ensure_Element
        (Registry, Session, Root, A11y.Node_Ids.From_Natural (777), Again,
         Result);
      View := Registry_API.Snapshot (Registry);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then View.Generation = Generation_After_Ensure,
         "macOS NSAccessibility element registry enforces configured element capacity");

      Registry_API.Mark_Defunct (Registry, Session, Root, Result);
      View := Registry_API.Snapshot (Registry);
      Generation_After_Defunct := View.Generation;
      Registry_API.Begin_Native_Call_With_Report
        (Registry, Session, Other, Call, Call_Report, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then View.Generation > Generation_After_Ensure
         and then Call_Report.Operation = Registry_API.Registry_Begin_Native_Call
         and then Call_Report.Status = A11y.Results.Node_Unavailable
         and then not Call_Report.Call_Active
         and then not Call_Report.Outstanding_Changed,
         "macOS NSAccessibility element registry rejects native calls after defunct");

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
         "macOS NSAccessibility element registry checked reset clears drained session ids");
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
         and then not Report.Element_Returned,
         "macOS NSAccessibility element registry reports drained reset mutation details");
      Registry_API.Find_Element
        (Registry, Session, Root, Element_View, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Element_View.Id = Registry_API.No_Element,
         "macOS NSAccessibility element registry rejects node lookup after drained reset");
      Registry_API.Resolve_Element
        (Registry, Session, Other, Element_View, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Element_View.Id = Registry_API.No_Element,
         "macOS NSAccessibility element registry rejects stale element ids after drained reset");
   end;

   declare
      Value : A11y.MacOS_Backend.NSAccessibility_Native_Values.Native_Value;
      Snapshot :
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Native_Value_Snapshot;
      Items :
        A11y.MacOS_Backend.NSAccessibility_Native_Values.UInt32_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      Value := A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
        ("Title", Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSString_Value
         and then Snapshot.Owned
         and then Snapshot.Length = 5
         and then
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSString_Text
             (Value) = "Title",
         "macOS NSAccessibility native value scaffold owns bounded NSString text");

      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
          ("", Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSString_Value
         and then Snapshot.Owned
         and then Snapshot.Length = 0
         and then
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSString_Text
             (Value) = "",
         "macOS NSAccessibility native value scaffold distinguishes supported empty NSString text");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_String_Size,
         4,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility native value fixture sets NSString resource limit");
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
          ("Name", Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSString_Value
         and then Snapshot.Length = 4,
         "macOS NSAccessibility native value scaffold accepts configured-limit NSString text");
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
          ("Names", Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
         and then Snapshot.Length = 0,
         "macOS NSAccessibility native value scaffold enforces configured NSString limits");

      Limits.Limits (A11y.Resource_Limits.Native_String_Size) :=
        A11y.Resource_Limits.Limit_Value
          (A11y.MacOS_Backend.NSAccessibility_Native_Values.Max_NSString_Length
           + 1);
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
          ("x", Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
         and then Snapshot.Length = 0,
         "macOS NSAccessibility native value scaffold rejects impossible NSString limits");
      Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
          ("x", Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value,
         "macOS NSAccessibility native value scaffold rejects invalid NSString limit configs");
      Limits := A11y.Resource_Limits.Default_Config;

      declare
         Max_Length : constant Natural :=
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Max_NSString_Length;
         Oversized_Text : constant String
           (1 .. Max_Length + 1) :=
             [others => 'x'];
      begin
         Value :=
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSString
             (Oversized_Text, Result);
         Snapshot :=
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then Snapshot.Kind =
              A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
            and then not Snapshot.Owned
            and then Snapshot.Length = 0,
            "macOS NSAccessibility native value scaffold rejects oversized NSString text");
      end;

      A11y.MacOS_Backend.NSAccessibility_Native_Values.Clear (Value, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
         and then not Snapshot.Owned
         and then Snapshot.Length = 0,
         "macOS NSAccessibility native value scaffold clears owned NSString text");

      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_UInt32 (42);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.UInt32_Value
         and then Snapshot.Status = A11y.Results.Success
         and then Snapshot.UInt32_Item = 42,
         "macOS NSAccessibility native value scaffold accepts representable UInt32 values");

      declare
         function Max_UInt32 return Long_Long_Integer is (4_294_967_295);
         pragma No_Inline (Max_UInt32);
      begin
         if Long_Long_Integer (Natural'Last) > Max_UInt32 then
            Value :=
              A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_UInt32
                (Natural (Max_UInt32 + 1));
            Snapshot :=
              A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot
                (Value);
            Check
              (Snapshot.Kind =
                 A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
               and then Snapshot.Status = A11y.Results.Resource_Limit,
               "macOS NSAccessibility native value scaffold rejects oversized UInt32 values");
         end if;
      end;

      Items.Clear;
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSArray_UInt32
          (Items, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSArray_UInt32_Value
         and then Snapshot.Owned
         and then Snapshot.Count = 0
         and then
           Natural
             (A11y.MacOS_Backend.NSAccessibility_Native_Values.NSArray_Items
                (Value).Length) = 0,
         "macOS NSAccessibility native value scaffold distinguishes supported empty NSArray data");

      Items.Append (A11y.Node_Ids.To_Natural (Root));
      Items.Append (A11y.Node_Ids.To_Natural (Child));
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSArray_UInt32
          (Items, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.NSArray_UInt32_Value
         and then Snapshot.Owned
         and then Snapshot.Count = 2
         and then
           Natural
             (A11y.MacOS_Backend.NSAccessibility_Native_Values.NSArray_Items
                (Value).Length) = 2,
         "macOS NSAccessibility native value scaffold owns bounded NSArray data");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_Array_Size,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "macOS NSAccessibility native value fixture sets NSArray resource limit");
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSArray_UInt32
          (Items, Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
         and then Snapshot.Count = 0,
         "macOS NSAccessibility native value scaffold enforces configured NSArray limits");

      Limits.Limits (A11y.Resource_Limits.Native_Array_Size) :=
        A11y.Resource_Limits.Limit_Value
          (A11y.MacOS_Backend.NSAccessibility_Native_Values.Max_NSArray_Length
           + 1);
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSArray_UInt32
          (Items, Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
         and then Snapshot.Count = 0,
         "macOS NSAccessibility native value scaffold rejects impossible NSArray limits");
      Limits.Limits (A11y.Resource_Limits.Native_Array_Size) := 0;
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSArray_UInt32
          (Items, Limits, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value,
         "macOS NSAccessibility native value scaffold rejects invalid NSArray limit configs");
      Limits := A11y.Resource_Limits.Default_Config;

      Items.Clear;
      for Index in 1 ..
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Max_NSArray_Length + 1
      loop
         Items.Append (Index);
      end loop;
      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_NSArray_UInt32
          (Items, Result);
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
         and then not Snapshot.Owned
         and then Snapshot.Count = 0,
         "macOS NSAccessibility native value scaffold rejects oversized NSArray data");

      declare
         function Max_UInt32 return Long_Long_Integer is (4_294_967_295);
         pragma No_Inline (Max_UInt32);
      begin
         if Long_Long_Integer (Natural'Last) > Max_UInt32 then
            Items.Clear;
            Items.Append (Natural (Max_UInt32 + 1));
            Value :=
              A11y.MacOS_Backend.NSAccessibility_Native_Values
                .Make_NSArray_UInt32
                  (Items, Result);
            Snapshot :=
              A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot
                (Value);
            Check
              (Result.Status = A11y.Results.Resource_Limit
               and then Snapshot.Kind =
                 A11y.MacOS_Backend.NSAccessibility_Native_Values.Nil_Value
               and then not Snapshot.Owned
               and then Snapshot.Count = 0,
               "macOS NSAccessibility native value scaffold rejects oversized NSArray UInt32 items");
         end if;
      end;

      Value :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Make_Not_Applicable;
      Snapshot :=
        A11y.MacOS_Backend.NSAccessibility_Native_Values.Snapshot (Value);
      Check
        (Snapshot.Kind =
           A11y.MacOS_Backend.NSAccessibility_Native_Values.Not_Applicable_Value
         and then Snapshot.Status = A11y.Results.Unsupported_Property
         and then not Snapshot.Owned,
         "macOS NSAccessibility native value scaffold distinguishes not-applicable values");
   end;

   declare
      package Bridge renames
        A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;

      Pool_Create : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Create_Autorelease_Pool);
      Bridge_Target : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Bridge_Target_Probe);
      Pool_Drain : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Drain_Autorelease_Pool);
      Retain : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Retain_Object);
      Copy_String : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Copy_UTF8_String);
      Copy_Array : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Copy_UInt32_Array);
      Virtual_Element_Create : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Create_Virtual_Element);
      Virtual_Element_Match : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Virtual_Element_Matches);
      Virtual_Element_Probe : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Probe_Virtual_Element_Bridge);
      Public_AX_Client_Probe : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Probe_Public_AX_Client_For_PID);
      Selector_Callback : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Dispatch_Selector_Callback);
      Selector_Frame_Callback : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Dispatch_Selector_Frame_Callback);
      Notification_Callback : constant Bridge.Operation_Contract :=
        Bridge.Contract (Bridge.Post_Notification_Callback);
      Children_Entry : constant
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Native_Bridge_Entry :=
          A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Bridge_Entry
            (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
               .Accessibility_Children);
      Notification_Entry : constant
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Native_Bridge_Entry :=
          A11y.MacOS_Backend.NSAccessibility_ABI_Surface.Bridge_Entry
            (A11y.MacOS_Backend.NSAccessibility_ABI_Surface
               .Accessibility_Post_Notification);

      function Runtime_Size (Value : Natural) return Natural is
      begin
         return Value;
      end Runtime_Size;

      function Runtime_UInt32
        (Value : Interfaces.Unsigned_32)
         return Interfaces.Unsigned_32
      is
      begin
         return Value;
      end Runtime_UInt32;
   begin
      Check
        (Runtime_Size
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Native_Status'Size) = Runtime_Size (Interfaces.C.int'Size)
         and then
           Runtime_Size
             (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                .Native_UInt32'Size) = 32
         and then
           Runtime_Size
             (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
                .Native_UInt64'Size) = 64,
         "macOS NSAccessibility native bridge binding preserves Objective-C ABI scalar sizes");
      Check
        (Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Probe_Element_Created) = 2#0000_0000_0001#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Probe_Identity_Matched) = 2#0000_0000_0010#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Probe_Notification_Dispatched) = 2#1000_0000_0000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Probe_Released) = 2#1_0000_0000_0000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Probe_All_Required) = 2#1_1111_1111_1111#,
         "macOS NSAccessibility native bridge binding names virtual element probe bits");
      Check
        (Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Trust_Checked) = 2#0000_0001#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Application_Created) = 2#0000_0010#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Attribute_Names_Attempted) = 2#0000_0100#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Role_Attempted) = 2#0000_1000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Windows_Attempted) = 2#0001_0000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Window_Children_Attempted) = 2#0010_0000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Root_Role_Attempted) = 2#0100_0000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_Released) = 2#1000_0000#
         and then Runtime_UInt32
           (A11y.MacOS_Backend.NSAccessibility_Native_Bridge
              .Public_AX_Probe_All_Required) = 2#1111_1111#,
         "macOS NSAccessibility native bridge binding names public AX client probe bits");
      Check
        (Bridge.All_Operations_Audited,
         "macOS NSAccessibility Objective-C bridge audit covers every ABI operation");
      Check
        (Bridge_Target.Allowed
         and then Bridge_Target.Exception_Behavior =
           Bridge.No_Exception_Boundary
         and then Bridge_Target.Calling_Convention =
           Bridge.Objective_C_ABI_Helper
         and then Bridge_Target.Nullability = Bridge.No_Null_Values
         and then Bridge.Operation_Name (Bridge.Bridge_Target_Probe) =
           "a11y_nsax_bridge_is_macos",
         "macOS NSAccessibility Objective-C bridge audit constrains target-runtime probe");
      Check
        (Children_Entry.ABI_Only
         and then Children_Entry.Operation =
           Bridge.Dispatch_Selector_Frame_Callback
         and then Bridge.Operation_Name (Children_Entry.Operation) =
           "a11y_nsax_dispatch_selector_frame"
         and then Children_Entry.Requires_Main_Thread
         and then not Children_Entry.Dispatches_Notification
         and then Notification_Entry.ABI_Only
         and then Notification_Entry.Operation = Bridge.Post_Notification_Callback
         and then Bridge.Operation_Name (Notification_Entry.Operation) =
           "a11y_nsax_post_notification"
         and then Notification_Entry.Requires_Main_Thread
         and then Notification_Entry.Dispatches_Notification,
         "macOS NSAccessibility ABI surface records native bridge entry symbols");
      Check
        (Bridge.Operation_Name (Bridge.Copy_UTF8_String) =
           "a11y_nsax_copy_utf8_string"
         and then Bridge.Operation_Name (Bridge.Copy_UInt32_Array) =
           "a11y_nsax_copy_uint32_array"
         and then Bridge.Operation_Name (Bridge.Create_Virtual_Element) =
           "a11y_nsax_create_virtual_element"
         and then Bridge.Operation_Name (Bridge.Virtual_Element_Matches) =
           "a11y_nsax_virtual_element_matches"
         and then Bridge.Operation_Name (Bridge.Probe_Virtual_Element_Bridge) =
           "a11y_nsax_probe_virtual_element_bridge"
         and then
           Bridge.Operation_Name (Bridge.Probe_Public_AX_Client_For_PID) =
             "a11y_nsax_probe_public_ax_client_for_pid",
         "macOS NSAccessibility Objective-C bridge audit names native conversion helpers");
      Check
        (Bridge.Bounded_Limit (Bridge.Copy_UTF8_String) =
           A11y.MacOS_Backend.NSAccessibility_Native_Values
             .Max_NSString_Length
         and then Bridge.Bounded_Limit (Bridge.Copy_UInt32_Array) =
           A11y.MacOS_Backend.NSAccessibility_Native_Values
             .Max_NSArray_Length
         and then Bridge.Bounded_Limit (Bridge.Retain_Object) = 0,
         "macOS NSAccessibility Objective-C bridge audit exposes native conversion limits");
      Check
        (Bridge.Operation_Name (Bridge.Dispatch_Selector_Frame_Callback) =
           "a11y_nsax_dispatch_selector_frame",
         "macOS NSAccessibility Objective-C bridge audit names selector-frame callbacks");
      Check
        (Pool_Create.Allowed
         and then Pool_Create.Ownership = Bridge.Caller_Owns_Return
         and then Pool_Create.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Pool_Create.Calling_Convention =
           Bridge.Objective_C_ABI_Helper
         and then Pool_Create.Nullability =
           Bridge.Nullable_Return_On_Failure
         and then Pool_Create.Lifetime =
           Bridge.Native_Object_Must_Be_Released
         and then not Pool_Create.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains autorelease-pool creation");
      Check
        (Pool_Drain.Allowed
         and then Pool_Drain.Ownership = Bridge.Callee_Consumes_Argument
         and then Pool_Drain.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Pool_Drain.Nullability = Bridge.Nullable_Native_Object
         and then Pool_Drain.Lifetime =
           Bridge.Native_Object_Must_Be_Released
         and then not Pool_Drain.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains autorelease-pool drain");
      Check
        (Retain.Allowed
         and then Retain.Ownership = Bridge.Balanced_Retain_Release
         and then Retain.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Retain.Lifetime =
           Bridge.Balanced_Retain_Release_Lifetime
         and then Retain.Representation = Bridge.Opaque_Object_Reference
         and then not Retain.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains retain-release helpers");
      Check
        (Copy_String.Ownership = Bridge.Caller_Owns_Return
         and then Copy_String.Nullability = Bridge.Nullable_Return_On_Failure
         and then Copy_String.Lifetime =
           Bridge.Native_Object_Must_Be_Released
         and then Copy_String.Representation = Bridge.Bounded_UTF8_Value
         and then Copy_Array.Ownership = Bridge.Caller_Owns_Return
         and then Copy_Array.Representation = Bridge.Bounded_UInt32_Array,
         "macOS NSAccessibility Objective-C bridge audit records Foundation value assumptions");
      Check
        (Virtual_Element_Create.Allowed
         and then Virtual_Element_Create.Ownership =
           Bridge.Caller_Owns_Return
         and then Virtual_Element_Create.Threading =
           Bridge.Main_Thread_Required
         and then Virtual_Element_Create.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Virtual_Element_Create.Nullability =
           Bridge.Nullable_Return_On_Failure
         and then Virtual_Element_Create.Lifetime =
           Bridge.Native_Object_Must_Be_Released
         and then Virtual_Element_Create.Representation =
           Bridge.Opaque_Object_Reference
         and then not Virtual_Element_Create.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains virtual element creation");
      Check
        (Virtual_Element_Match.Allowed
         and then Virtual_Element_Match.Ownership =
           Bridge.No_Ownership_Transfer
         and then Virtual_Element_Match.Threading = Bridge.Any_Thread
         and then Virtual_Element_Match.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Virtual_Element_Match.Nullability =
           Bridge.Nullable_Native_Object
         and then Virtual_Element_Match.Lifetime = Bridge.No_Durable_State
         and then Virtual_Element_Match.Representation =
           Bridge.Opaque_Object_Reference
         and then not Virtual_Element_Match.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains virtual element identity matching");
      Check
        (Virtual_Element_Probe.Allowed
         and then Virtual_Element_Probe.Ownership =
           Bridge.No_Ownership_Transfer
         and then Virtual_Element_Probe.Threading = Bridge.Main_Thread_Required
         and then Virtual_Element_Probe.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Virtual_Element_Probe.Calling_Convention =
           Bridge.Objective_C_ABI_Helper
         and then Virtual_Element_Probe.Nullability =
           Bridge.Nullable_Native_Object
         and then Virtual_Element_Probe.Lifetime =
           Bridge.Callback_Frame_Ephemeral
         and then Virtual_Element_Probe.Representation =
           Bridge.Opaque_Object_Reference
         and then not Virtual_Element_Probe.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains virtual element runtime probing");
      Check
        (Public_AX_Client_Probe.Allowed
         and then Public_AX_Client_Probe.Ownership =
           Bridge.No_Ownership_Transfer
         and then Public_AX_Client_Probe.Threading =
           Bridge.Main_Thread_Required
         and then Public_AX_Client_Probe.Exception_Behavior =
           Bridge.Contain_Objective_C_Exception
         and then Public_AX_Client_Probe.Calling_Convention =
           Bridge.Objective_C_ABI_Helper
         and then Public_AX_Client_Probe.Nullability =
           Bridge.No_Null_Values
         and then Public_AX_Client_Probe.Lifetime =
           Bridge.Callback_Frame_Ephemeral
         and then Public_AX_Client_Probe.Representation =
           Bridge.Opaque_Object_Reference
         and then not Public_AX_Client_Probe.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains public AX client probing");
      Check
        (Selector_Callback.Allowed
         and then Selector_Callback.Threading = Bridge.Main_Thread_Required
         and then Selector_Callback.Exception_Behavior =
           Bridge.Contain_Ada_Exception
         and then Selector_Callback.Calling_Convention =
           Bridge.Objective_C_ABI_Callback
         and then Selector_Callback.Lifetime =
           Bridge.Callback_Frame_Ephemeral
         and then not Selector_Callback.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains selector callbacks");
      Check
        (Selector_Frame_Callback.Allowed
         and then Selector_Frame_Callback.Threading =
           Bridge.Main_Thread_Required
         and then Selector_Frame_Callback.Exception_Behavior =
           Bridge.Contain_Ada_Exception
         and then Selector_Frame_Callback.Calling_Convention =
           Bridge.Objective_C_ABI_Callback
         and then Selector_Frame_Callback.Lifetime =
           Bridge.Callback_Frame_Ephemeral
         and then Selector_Frame_Callback.Representation =
           Bridge.Opaque_Object_Reference
         and then not Selector_Frame_Callback.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains selector-frame callbacks");
      Check
        (Notification_Callback.Allowed
         and then Notification_Callback.Threading = Bridge.Main_Thread_Required
         and then Notification_Callback.Exception_Behavior =
           Bridge.Contain_Ada_Exception
         and then Notification_Callback.Nullability =
           Bridge.Nullable_Native_Object
         and then Notification_Callback.Representation =
           Bridge.Opaque_Object_Reference
         and then not Notification_Callback.Accessibility_Policy,
         "macOS NSAccessibility Objective-C bridge audit constrains notification callbacks");
   end;

   if Failures = 0 then
      Ada.Text_IO.Put_Line ("All NSAccessibility router tests passed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
   else
      Ada.Text_IO.Put_Line
        (Natural'Image (Failures) & " NSAccessibility router test(s) failed.");
      Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
   end if;
   end Run;

end NSAX_Router_Test_Suite;
