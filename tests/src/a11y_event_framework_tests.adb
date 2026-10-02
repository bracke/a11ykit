with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;

with A11y;
with A11y.Events;
with A11y.Events.Classification;
with A11y.Geometry;
with A11y.Live_Regions;
with A11y.Node_Ids;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Relations;
with A11y.States;
with A11y.Tables;
with A11y.Text;
with A11y.Values;
with A11y.Windows;

with A11y_Node_Provider_Fixtures;
with A11ykit_Test_Support;

package body A11y_Event_Framework_Tests is
   use type A11y.Events.Event_Kind;
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Length;
   use type A11y.Geometry.Rectangle;
   use type A11y.Live_Regions.Live_Setting;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Properties.Property_Id;
   use type A11y.Properties.Property_Status;
   use type A11y.Properties.Property_Value_Kind;
   use type A11y.Relations.Relation_Kind;
   use type A11y.Results.Status_Code;
   use type A11y.States.State_Flag;
   use type A11y.States.State_Source;
   use type A11y.Tables.Logical_Index;
   use type A11y.Values.Value_Kind;
   use type A11y.Windows.Surface_Kind;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run_Metadata_Tests is
   begin
      Check
        (A11y.Events.Stable_Name (A11y.Events.Focus_Changed)
         = "focus.changed"
         and then A11y.Events.Is_Coalescible (A11y.Events.Bounds_Changed)
         and then not A11y.Events.Is_Coalescible
           (A11y.Events.Text_Inserted)
         and then not A11y.Events.Is_Coalescible
           (A11y.Events.Node_Destroyed),
         "event framework exposes stable event metadata");
      Check
        (A11y.Events.Classification.Is_Coalescible
           (A11y.Events.Bounds_Changed)
         and then not A11y.Events.Classification.Is_Coalescible
           (A11y.Events.Text_Inserted)
         and then A11y.Events.Classification.Is_Text_Event
           (A11y.Events.Text_Replaced)
         and then A11y.Events.Classification.Is_Property_Event
           (A11y.Events.Property_Changed)
         and then A11y.Events.Classification.Is_State_Event
           (A11y.Events.Active_Descendant_Changed)
         and then A11y.Events.Classification.Is_Value_Event
           (A11y.Events.Range_Changed)
         and then A11y.Events.Classification.Is_Selection_Event
           (A11y.Events.Current_Item_Changed)
         and then A11y.Events.Classification.Is_Focus_Event
           (A11y.Events.Focus_Changed)
         and then A11y.Events.Classification.Is_Lifecycle_Event
           (A11y.Events.Node_Destroyed)
         and then A11y.Events.Classification.Is_Tree_Event
           (A11y.Events.Child_Added)
         and then A11y.Events.Classification.Is_Table_Event
           (A11y.Events.Cell_Changed)
         and then A11y.Events.Classification.Is_Document_Event
           (A11y.Events.Document_Loaded)
         and then A11y.Events.Classification.Is_Relation_Event
           (A11y.Events.Relation_Targets_Changed)
         and then A11y.Events.Classification.Is_Window_Event
           (A11y.Events.Window_Activated)
         and then A11y.Events.Classification.Must_Preserve_Individual_Order
           (A11y.Events.Text_Removed)
         and then not
           A11y.Events.Classification.Must_Preserve_Individual_Order
             (A11y.Events.Value_Changed),
         "event classification exposes coalescing and ordering policy");
   end Run_Metadata_Tests;

   procedure Run_Classification_Tests is
   begin
      Check
        (A11y.Events.Is_Text_Event (A11y.Events.Text_Replaced)
         and then A11y.Events.Is_Text_Event (A11y.Events.Caret_Moved)
         and then not A11y.Events.Is_Text_Event
           (A11y.Events.Focus_Changed),
         "event framework classifies text payload events");

      Check
        (A11y.Events.Is_Lifecycle_Event (A11y.Events.Node_Created)
         and then A11y.Events.Is_Lifecycle_Event
           (A11y.Events.Node_Destroyed)
         and then not A11y.Events.Is_Lifecycle_Event
           (A11y.Events.Child_Added)
         and then A11y.Events.Is_Tree_Event (A11y.Events.Child_Added)
         and then A11y.Events.Is_Table_Event (A11y.Events.Row_Inserted)
         and then A11y.Events.Is_Table_Event (A11y.Events.Cell_Changed)
         and then not A11y.Events.Is_Table_Event
           (A11y.Events.Document_Loaded)
         and then A11y.Events.Is_Document_Event
           (A11y.Events.Document_Loaded)
         and then A11y.Events.Is_Document_Event
           (A11y.Events.Document_Closed)
         and then not A11y.Events.Is_Document_Event
           (A11y.Events.Window_Opened)
         and then A11y.Events.Is_Relation_Event
           (A11y.Events.Active_Descendant_Changed)
         and then A11y.Events.Is_Relation_Event
           (A11y.Events.Relation_Targets_Changed)
         and then not A11y.Events.Is_Relation_Event
           (A11y.Events.Selection_Changed)
         and then A11y.Events.Is_Window_Event
           (A11y.Events.Window_Activated)
         and then not A11y.Events.Is_Window_Event
           (A11y.Events.Document_Loaded),
         "event framework classifies lifecycle tree table document relation and window events");

      Check
        (A11y.Events.Is_Property_Event (A11y.Events.Property_Changed)
         and then A11y.Events.Is_Property_Event
           (A11y.Events.Bounds_Changed)
         and then not A11y.Events.Is_Property_Event
           (A11y.Events.State_Changed)
         and then A11y.Events.Is_State_Event (A11y.Events.State_Changed)
         and then A11y.Events.Is_State_Event (A11y.Events.Focus_Changed)
         and then A11y.Events.Is_Value_Event (A11y.Events.Value_Changed)
         and then A11y.Events.Is_Value_Event (A11y.Events.Range_Changed)
         and then not A11y.Events.Is_Value_Event
           (A11y.Events.Selection_Changed),
         "event framework classifies property state and value events");

      Check
        (A11y.Events.Is_Selection_Event
           (A11y.Events.Selection_Changed)
         and then A11y.Events.Is_Selection_Event
           (A11y.Events.Current_Item_Changed)
         and then A11y.Events.Is_Selection_Event
           (A11y.Events.Text_Selection_Changed)
         and then not A11y.Events.Is_Selection_Event
           (A11y.Events.Value_Changed)
         and then A11y.Events.Is_Focus_Event (A11y.Events.Focus_Changed)
         and then A11y.Events.Is_Focus_Event
           (A11y.Events.Active_Descendant_Changed)
         and then not A11y.Events.Is_Focus_Event
           (A11y.Events.Selection_Changed),
         "event framework classifies selection and focus events");

      Check
        (A11y.Events.Is_Live_Region_Event
           (A11y.Events.Live_Region_Changed)
         and then A11y.Events.Is_Live_Region_Event
           (A11y.Events.Announcement_Requested)
         and then not A11y.Events.Is_Live_Region_Event
           (A11y.Events.Property_Changed),
         "event framework classifies live-region events");
   end Run_Classification_Tests;

   procedure Run_Envelope_Tests is
      Event : A11y.Events.Event;
      Result : A11y.Results.Result;
   begin
      Event.Sequence := 1;
      Event.Source := A11y.Node_Ids.From_Natural (42);
      Event.Kind := A11y.Events.Node_Created;
      Result := A11y.Events.Validate_Event (Event);
      Check
        (A11y.Results.Succeeded (Result),
         "event framework validates event envelopes");

      Event.Sequence := A11y.No_Event;
      Result := A11y.Events.Validate_Event (Event);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event framework rejects unsequenced event envelopes");

      Event.Sequence := 2;
      Event.Source := A11y.Node_Ids.No_Node;
      Result := A11y.Events.Validate_Event (Event);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "event framework rejects unavailable event envelope sources");
   end Run_Envelope_Tests;

   procedure Run_Tree_Payload_Tests is
      Tree_Payload : A11y.Events.Tree_Event_Payload;
      Result : A11y.Results.Result;
   begin
      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Child_Added,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.From_Natural (61),
         Has_Child => True,
         Index     => 3,
         Has_Index => True,
         Result    => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Tree_Payload.Parent = A11y.Node_Ids.From_Natural (60)
         and then Tree_Payload.Child = A11y.Node_Ids.From_Natural (61)
         and then Tree_Payload.Has_Child
         and then Tree_Payload.Index = 3
         and then Tree_Payload.Has_Index,
         "event framework validates child tree payload metadata");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Subtree_Rebuilt,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.No_Node,
         Has_Child => False,
         Index     => Positive'First,
         Has_Index => False,
         Result    => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Tree_Payload.Parent = A11y.Node_Ids.From_Natural (60)
         and then not Tree_Payload.Has_Child
         and then Tree_Payload.Child = A11y.Node_Ids.No_Node
         and then not Tree_Payload.Has_Index,
         "event framework validates aggregate tree payload metadata");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Subtree_Rebuilt,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.From_Natural (61),
         Has_Child => False,
         Index     => 9,
         Has_Index => False,
         Result    => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Tree_Payload.Child = A11y.Node_Ids.No_Node
         and then Tree_Payload.Index = Positive'First,
         "event framework rejects contradictory aggregate tree payload metadata");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Subtree_Rebuilt,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.From_Natural (61),
         Has_Child => True,
         Index     => 9,
         Has_Index => False,
         Result    => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Tree_Payload.Parent = A11y.Node_Ids.No_Node,
         "event framework rejects child metadata on aggregate tree events");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Children_Reordered,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.No_Node,
         Has_Child => False,
         Index     => 9,
         Has_Index => True,
         Result    => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Tree_Payload.Parent = A11y.Node_Ids.No_Node,
         "event framework rejects index metadata on aggregate tree events");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Subtree_Rebuilt,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.No_Node,
         Has_Child => False,
         Index     => Positive'First,
         Has_Index => False,
         Result    => Result);

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Subtree_Rebuilt,
         Tree_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Tree_Payload.Parent = A11y.Node_Ids.From_Natural (60),
         "event framework validates tree payload records");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Child_Removed,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.No_Node,
         Has_Child => False,
         Index     => 1,
         Has_Index => True,
         Result    => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Tree_Payload.Parent = A11y.Node_Ids.No_Node,
         "event framework rejects child tree payloads without child ids");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Child_Added,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.From_Natural (60),
         Has_Child => True,
         Index     => 1,
         Has_Index => True,
         Result    => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Tree_Payload.Parent = A11y.Node_Ids.No_Node,
         "event framework rejects self-parent child tree payloads");

      Tree_Payload := A11y.Events.Validate_Tree_Event_Payload
        (A11y.Events.Focus_Changed,
         Parent    => A11y.Node_Ids.From_Natural (60),
         Child     => A11y.Node_Ids.From_Natural (61),
         Has_Child => True,
         Index     => 1,
         Has_Index => True,
         Result    => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Tree_Payload.Parent = A11y.Node_Ids.No_Node,
         "event framework rejects tree payloads for other events");
   end Run_Tree_Payload_Tests;

   procedure Run_Table_Payload_Tests is
      Table_Payload : A11y.Events.Table_Event_Payload;
      Result : A11y.Results.Result;
   begin
      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Row_Inserted,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.No_Node,
         Has_Item   => False,
         Row        => 10,
         Has_Row    => True,
         Column     => 0,
         Has_Column => False,
         Result     => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Table_Payload.Table = A11y.Node_Ids.From_Natural (70)
         and then Table_Payload.Row = 10
         and then Table_Payload.Has_Row
         and then Table_Payload.Item = A11y.Node_Ids.No_Node
         and then Table_Payload.Column = 0
         and then not Table_Payload.Has_Item,
         "event framework validates row table payload metadata");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Row_Inserted,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.From_Natural (71),
         Has_Item   => True,
         Row        => 10,
         Has_Row    => True,
         Column     => 4,
         Has_Column => False,
         Result     => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Table_Payload.Table = A11y.Node_Ids.No_Node,
         "event framework rejects cell metadata on row table events");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Column_Removed,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.No_Node,
         Has_Item   => False,
         Row        => 10,
         Has_Row    => True,
         Column     => 4,
         Has_Column => True,
         Result     => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Table_Payload.Table = A11y.Node_Ids.No_Node,
         "event framework rejects row metadata on column table events");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Cell_Changed,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.From_Natural (71),
         Has_Item   => True,
         Row        => 3,
         Has_Row    => True,
         Column     => 4,
         Has_Column => True,
         Result     => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Table_Payload.Item = A11y.Node_Ids.From_Natural (71)
         and then Table_Payload.Row = 3
         and then Table_Payload.Column = 4,
         "event framework validates cell table payload metadata");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Cell_Changed,
         Table_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Table_Payload.Item = A11y.Node_Ids.From_Natural (71),
         "event framework validates table payload records");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Cell_Changed,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.No_Node,
         Has_Item   => False,
         Row        => 3,
         Has_Row    => True,
         Column     => 4,
         Has_Column => True,
         Result     => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Table_Payload.Table = A11y.Node_Ids.No_Node,
         "event framework rejects cell table payloads without stable cells");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Cell_Changed,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.From_Natural (70),
         Has_Item   => True,
         Row        => 3,
         Has_Row    => True,
         Column     => 4,
         Has_Column => True,
         Result     => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Table_Payload.Table = A11y.Node_Ids.No_Node,
         "event framework rejects table-as-cell payloads");

      Table_Payload := A11y.Events.Validate_Table_Event_Payload
        (A11y.Events.Focus_Changed,
         Table      => A11y.Node_Ids.From_Natural (70),
         Item       => A11y.Node_Ids.No_Node,
         Has_Item   => False,
         Row        => 3,
         Has_Row    => True,
         Column     => 4,
         Has_Column => True,
         Result     => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Table_Payload.Table = A11y.Node_Ids.No_Node,
         "event framework rejects table payloads for other events");
   end Run_Table_Payload_Tests;

   procedure Run_Document_Window_Payload_Tests is
      Document_Payload : A11y.Events.Document_Event_Payload;
      Window_Payload : A11y.Events.Window_Event_Payload;
      Result : A11y.Results.Result;
   begin
      Document_Payload := A11y.Events.Validate_Document_Event_Payload
        (A11y.Events.Document_Loaded,
         Document    => A11y.Node_Ids.From_Natural (80),
         Surface     => A11y.Node_Ids.From_Natural (81),
         Has_Surface => True,
         Result      => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Document_Payload.Document =
           A11y.Node_Ids.From_Natural (80)
         and then Document_Payload.Surface =
           A11y.Node_Ids.From_Natural (81)
         and then Document_Payload.Has_Surface,
         "event framework validates document lifecycle payload metadata");

      Document_Payload := A11y.Events.Validate_Document_Event_Payload
        (A11y.Events.Document_Loaded,
         Document    => A11y.Node_Ids.From_Natural (80),
         Surface     => A11y.Node_Ids.From_Natural (81),
         Has_Surface => False,
         Result      => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Document_Payload.Has_Surface
         and then Document_Payload.Surface = A11y.Node_Ids.No_Node,
         "event framework rejects contradictory absent document surface payloads");

      Document_Payload := A11y.Events.Validate_Document_Event_Payload
        (A11y.Events.Document_Loaded,
         (Document    => A11y.Node_Ids.From_Natural (80),
          Surface     => A11y.Node_Ids.No_Node,
          Has_Surface => False),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Document_Payload.Document =
           A11y.Node_Ids.From_Natural (80),
         "event framework validates document payload records");

      Document_Payload := A11y.Events.Validate_Document_Event_Payload
        (A11y.Events.Document_Closed,
         Document    => A11y.Node_Ids.No_Node,
         Surface     => A11y.Node_Ids.No_Node,
         Has_Surface => False,
         Result      => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Document_Payload.Document = A11y.Node_Ids.No_Node,
         "event framework rejects document payloads without stable documents");

      Document_Payload := A11y.Events.Validate_Document_Event_Payload
        (A11y.Events.Document_Loaded,
         Document    => A11y.Node_Ids.From_Natural (80),
         Surface     => A11y.Node_Ids.From_Natural (80),
         Has_Surface => True,
         Result      => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Document_Payload.Document = A11y.Node_Ids.No_Node,
         "event framework rejects document payloads whose surface is the document");

      Document_Payload := A11y.Events.Validate_Document_Event_Payload
        (A11y.Events.Focus_Changed,
         Document    => A11y.Node_Ids.From_Natural (80),
         Surface     => A11y.Node_Ids.From_Natural (81),
         Has_Surface => True,
         Result      => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Document_Payload.Document = A11y.Node_Ids.No_Node,
         "event framework rejects document payloads for other events");

      Window_Payload := A11y.Events.Validate_Window_Event_Payload
        (A11y.Events.Window_Opened,
         Surface      => A11y.Node_Ids.From_Natural (90),
         Surface_Kind => A11y.Windows.Modal_Dialog,
         Owner        => A11y.Node_Ids.From_Natural (91),
         Has_Owner    => True,
         Result       => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Window_Payload.Surface = A11y.Node_Ids.From_Natural (90)
         and then Window_Payload.Kind = A11y.Windows.Modal_Dialog
         and then Window_Payload.Owner = A11y.Node_Ids.From_Natural (91)
         and then Window_Payload.Has_Owner,
         "event framework validates window surface payload metadata");

      Window_Payload := A11y.Events.Validate_Window_Event_Payload
        (A11y.Events.Window_Opened,
         Surface      => A11y.Node_Ids.From_Natural (90),
         Surface_Kind => A11y.Windows.Modal_Dialog,
         Owner        => A11y.Node_Ids.From_Natural (91),
         Has_Owner    => False,
         Result       => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Window_Payload.Has_Owner
         and then Window_Payload.Owner = A11y.Node_Ids.No_Node,
         "event framework rejects contradictory absent window owner payloads");

      Window_Payload := A11y.Events.Validate_Window_Event_Payload
        (A11y.Events.Window_Opened,
         (Surface   => A11y.Node_Ids.From_Natural (90),
          Kind      => A11y.Windows.Modal_Dialog,
          Owner     => A11y.Node_Ids.No_Node,
          Has_Owner => False),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Window_Payload.Surface = A11y.Node_Ids.From_Natural (90),
         "event framework validates window payload records");

      Window_Payload := A11y.Events.Validate_Window_Event_Payload
        (A11y.Events.Window_Activated,
         Surface      => A11y.Node_Ids.No_Node,
         Surface_Kind => A11y.Windows.Window,
         Owner        => A11y.Node_Ids.No_Node,
         Has_Owner    => False,
         Result       => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Window_Payload.Surface = A11y.Node_Ids.No_Node,
         "event framework rejects window payloads without stable surfaces");

      Window_Payload := A11y.Events.Validate_Window_Event_Payload
        (A11y.Events.Window_Closed,
         Surface      => A11y.Node_Ids.From_Natural (90),
         Surface_Kind => A11y.Windows.Window,
         Owner        => A11y.Node_Ids.From_Natural (90),
         Has_Owner    => True,
         Result       => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Window_Payload.Surface = A11y.Node_Ids.No_Node,
         "event framework rejects self-owned window payloads");

      Window_Payload := A11y.Events.Validate_Window_Event_Payload
        (A11y.Events.Focus_Changed,
         Surface      => A11y.Node_Ids.From_Natural (90),
         Surface_Kind => A11y.Windows.Window,
         Owner        => A11y.Node_Ids.No_Node,
         Has_Owner    => False,
         Result       => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Window_Payload.Surface = A11y.Node_Ids.No_Node,
         "event framework rejects window payloads for other events");
   end Run_Document_Window_Payload_Tests;

   procedure Run_Text_Payload_Tests is
      use Ada.Strings.Wide_Wide_Unbounded;

      Payload : A11y.Events.Text_Event_Payload;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Result : A11y.Results.Result;
   begin
      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Inserted,
         Content_Length => 3,
         Start => 1,
         Count => 0,
         Text => "X",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Payload.Carries_Text
         and then A11y.Text.Index (A11y.Text.First (Payload.Span)) = 1
         and then A11y.Text.Length (Payload.Span) = 0
         and then To_Wide_Wide_String (Payload.Text) = "X",
         "event framework validates inserted text payloads");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Removed,
         Content_Length => 3,
         Start => 1,
         Count => 2,
         Text => "",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not Payload.Carries_Text
         and then A11y.Text.Length (Payload.Span) = 2,
         "event framework validates removed text payloads without text");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Replaced,
         Content_Length => 3,
         Start => 1,
         Count => 1,
         Text => "YZ",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Payload.Carries_Text
         and then A11y.Text.Length (Payload.Span) = 1
         and then To_Wide_Wide_String (Payload.Text) = "YZ",
         "event framework validates replaced text payloads");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Replaced,
         Content_Length => 3,
         Payload =>
           (Span => A11y.Text.Make_Range
              (A11y.Text.Code_Point_Position (1), 1),
            Text => To_Unbounded_Wide_Wide_String ("YZ"),
            Carries_Text => True),
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Payload.Carries_Text
         and then A11y.Text.Length (Payload.Span) = 1
         and then To_Wide_Wide_String (Payload.Text) = "YZ",
         "event framework validates text payload records");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Removed,
         Content_Length => 3,
         Payload =>
           (Span => A11y.Text.Make_Range
              (A11y.Text.Code_Point_Position (1), 1),
            Text => To_Unbounded_Wide_Wide_String ("hidden"),
            Carries_Text => False),
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Payload.Carries_Text,
         "event framework rejects hidden text in payload records");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Inserted,
         Content_Length => 3,
         Payload =>
           (Span => A11y.Text.Make_Range
              (A11y.Text.Code_Point_Position (1), 0),
            Text => To_Unbounded_Wide_Wide_String ("secret"),
            Carries_Text => True),
         Policy => A11y.Text.Protected_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Permission_Denied
         and then not Payload.Carries_Text,
         "event framework rejects protected text payload records");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Removed,
         Content_Length => 3,
         Payload =>
           (Span => A11y.Text.Make_Range
              (A11y.Text.Code_Point_Position (1), 1),
            Text => To_Unbounded_Wide_Wide_String (""),
            Carries_Text => False),
         Policy => A11y.Text.Protected_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Permission_Denied
         and then not Payload.Carries_Text,
         "event framework rejects protected removed-text payload records");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Caret_Moved,
         Content_Length => 3,
         Start => 2,
         Count => 0,
         Text => "",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Text.Index (A11y.Text.First (Payload.Span)) = 2,
         "event framework validates caret payload positions");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Focus_Changed,
         Content_Length => 3,
         Start => 0,
         Count => 0,
         Text => "",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Payload.Carries_Text,
         "event framework rejects text payloads for non-text events");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Inserted,
         Content_Length => 3,
         Start => 0,
         Count => 0,
         Text => "secret",
         Policy => A11y.Text.Protected_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Permission_Denied
         and then not Payload.Carries_Text,
         "event framework rejects protected inserted text payloads");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Removed,
         Content_Length => 3,
         Start => 0,
         Count => 1,
         Text => "",
         Policy => A11y.Text.Protected_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Permission_Denied
         and then not Payload.Carries_Text,
         "event framework rejects protected removed text payloads");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Inserted,
         Content_Length => 3,
         Start => 0,
         Count => 0,
         Text => "",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Payload.Carries_Text,
         "event framework rejects empty inserted text payloads");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Replaced,
         Content_Length => 3,
         Start => 1,
         Count => 1,
         Text => "",
         Policy => A11y.Text.Plain_Text,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Payload.Carries_Text,
         "event framework rejects empty replaced text payloads");

      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Text_Returned, 1, Result);
      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Inserted,
         Content_Length => 3,
         Start => 0,
         Count => 0,
         Text => "XY",
         Policy => A11y.Text.Plain_Text,
         Limits => Limits,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not Payload.Carries_Text,
         "event framework bounds inserted text payloads");

      Payload := A11y.Events.Validate_Text_Event_Payload
        (A11y.Events.Text_Inserted,
         Content_Length => 3,
         Payload =>
           (Span => A11y.Text.Make_Range
              (A11y.Text.Code_Point_Position (0), 0),
            Text => To_Unbounded_Wide_Wide_String ("XY"),
            Carries_Text => True),
         Policy => A11y.Text.Plain_Text,
         Limits => Limits,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not Payload.Carries_Text,
         "event framework bounds text payload records");
   end Run_Text_Payload_Tests;

   procedure Run_Property_State_Relation_Payload_Tests is
      Property_Payload : A11y.Events.Property_Event_Payload;
      State_Payload : A11y.Events.State_Event_Payload;
      Relation_Payload : A11y.Events.Relation_Event_Payload;
      Result : A11y.Results.Result;
   begin
      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Properties.Placeholder,
         A11y.Properties.Unsupported,
         A11y.Properties.Present,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Property_Payload.Property = A11y.Properties.Placeholder
         and then Property_Payload.Value_Kind =
           A11y.Properties.String_Value
         and then Property_Payload.Old_Status =
           A11y.Properties.Unsupported
         and then Property_Payload.New_Status = A11y.Properties.Present,
         "event framework validates textual property payload metadata");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Properties.Bounds,
         A11y.Properties.Present,
         A11y.Properties.Temporarily_Unavailable,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Property_Payload.Property = A11y.Properties.Bounds
         and then Property_Payload.Value_Kind =
           A11y.Properties.Rectangle_Value
         and then Property_Payload.New_Status =
           A11y.Properties.Temporarily_Unavailable,
         "event framework derives property payload value kinds");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         Property_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Property_Payload.Property = A11y.Properties.Bounds
         and then Property_Payload.Value_Kind =
           A11y.Properties.Rectangle_Value,
         "event framework validates property payload records");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         (Property   => A11y.Properties.Bounds,
          Value_Kind => A11y.Properties.String_Value,
          Old_Status => A11y.Properties.Present,
          New_Status => A11y.Properties.Present),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Property_Payload.Value_Kind =
           A11y.Properties.String_Value,
         "event framework rejects inconsistent property payload records");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Properties.Accessible_Name,
         A11y.Properties.Present,
         A11y.Properties.Present,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Property_Payload.Property =
           A11y.Properties.Accessible_Name
         and then Property_Payload.Old_Status = A11y.Properties.Present
         and then Property_Payload.New_Status = A11y.Properties.Present,
         "event framework allows supported property value-change payloads");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.State_Changed,
         A11y.Properties.Accessible_Name,
         A11y.Properties.Present,
         A11y.Properties.Present,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Property_Payload.Property =
           A11y.Properties.Accessible_Name
         and then Property_Payload.Value_Kind =
           A11y.Properties.String_Value,
         "event framework rejects property payloads for non-property events");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Properties.Accessible_Name,
         A11y.Properties.Unsupported,
         A11y.Properties.Unsupported,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Property_Payload.Old_Status =
           A11y.Properties.Unsupported
         and then Property_Payload.New_Status =
           A11y.Properties.Unsupported,
         "event framework rejects no-op property payloads");

      Property_Payload := A11y.Events.Validate_Property_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Properties.Accessible_Name,
         A11y.Properties.Present,
         A11y.Properties.Node_Unavailable,
         Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Property_Payload.Old_Status =
           A11y.Properties.Unsupported
         and then Property_Payload.New_Status =
           A11y.Properties.Unsupported,
         "event framework rejects unavailable-node property payloads");

      State_Payload := A11y.Events.Validate_State_Event_Payload
        (A11y.Events.State_Changed,
         A11y.States.Focused,
         Old_Value => False,
         New_Value => True,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then State_Payload.State = A11y.States.Focused
         and then State_Payload.Source = A11y.States.Application_Provided
         and then not State_Payload.Old_Value
         and then State_Payload.New_Value,
         "event framework validates state payload metadata");

      State_Payload := A11y.Events.Validate_State_Event_Payload
        (A11y.Events.State_Changed,
         A11y.States.Offscreen,
         Old_Value => False,
         New_Value => True,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then State_Payload.Source = A11y.States.Centrally_Derived,
         "event framework records centrally derived state payloads");

      State_Payload := A11y.Events.Validate_State_Event_Payload
        (A11y.Events.State_Changed,
         State_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then State_Payload.Source = A11y.States.Centrally_Derived,
         "event framework validates state payload records");

      State_Payload := A11y.Events.Validate_State_Event_Payload
        (A11y.Events.State_Changed,
         (State     => A11y.States.Offscreen,
          Source    => A11y.States.Application_Provided,
          Old_Value => False,
          New_Value => True),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then State_Payload.State = A11y.States.Enabled,
         "event framework rejects inconsistent state payload records");

      State_Payload := A11y.Events.Validate_State_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.States.Enabled,
         Old_Value => False,
         New_Value => True,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then State_Payload.State = A11y.States.Enabled,
         "event framework rejects state payloads for non-state events");

      State_Payload := A11y.Events.Validate_State_Event_Payload
        (A11y.Events.State_Changed,
         A11y.States.Enabled,
         Old_Value => True,
         New_Value => True,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not State_Payload.Old_Value
         and then not State_Payload.New_Value,
         "event framework rejects no-op state payloads");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Added,
         A11y.Relations.Labelled_By,
         A11y.Node_Ids.From_Natural (44),
         Has_Target => True,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Relation_Payload.Relation = A11y.Relations.Labelled_By
         and then Relation_Payload.Inverse = A11y.Relations.Label_For
         and then Relation_Payload.Has_Target
         and then Relation_Payload.Target = A11y.Node_Ids.From_Natural (44),
         "event framework validates relation payload metadata");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Targets_Changed,
         A11y.Relations.Described_By,
         A11y.Node_Ids.No_Node,
         Has_Target => False,
         Result => Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Relation_Payload.Relation = A11y.Relations.Described_By
         and then Relation_Payload.Inverse =
           A11y.Relations.Description_For
         and then Relation_Payload.Target = A11y.Node_Ids.No_Node
         and then not Relation_Payload.Has_Target,
         "event framework validates aggregate relation payloads");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Targets_Changed,
         A11y.Relations.Described_By,
         A11y.Node_Ids.From_Natural (44),
         Has_Target => False,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Relation_Payload.Target = A11y.Node_Ids.No_Node
         and then not Relation_Payload.Has_Target,
         "event framework rejects contradictory absent relation targets");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Targets_Changed,
         (Relation   => A11y.Relations.Described_By,
          Inverse    => A11y.Relations.Description_For,
          Target     => A11y.Node_Ids.No_Node,
          Has_Target => False),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Relation_Payload.Relation = A11y.Relations.Described_By
         and then Relation_Payload.Inverse =
           A11y.Relations.Description_For,
         "event framework validates relation payload records");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Targets_Changed,
         (Relation   => A11y.Relations.Described_By,
          Inverse    => A11y.Relations.Label_For,
          Target     => A11y.Node_Ids.No_Node,
          Has_Target => False),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Relation_Payload.Relation = A11y.Relations.Labelled_By
         and then Relation_Payload.Inverse = A11y.Relations.Label_For,
         "event framework rejects inconsistent relation payload records");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Targets_Changed,
         (Relation   => A11y.Relations.Described_By,
          Inverse    => A11y.Relations.Description_For,
          Target     => A11y.Node_Ids.From_Natural (44),
          Has_Target => False),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Relation_Payload.Target = A11y.Node_Ids.No_Node
         and then not Relation_Payload.Has_Target,
         "event framework rejects contradictory relation payload records");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Relation_Removed,
         A11y.Relations.Labelled_By,
         A11y.Node_Ids.No_Node,
         Has_Target => False,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Relation_Payload.Has_Target,
         "event framework rejects missing relation add/remove targets");

      Relation_Payload := A11y.Events.Validate_Relation_Event_Payload
        (A11y.Events.Focus_Changed,
         A11y.Relations.Labelled_By,
         A11y.Node_Ids.From_Natural (44),
         Has_Target => True,
         Result => Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Relation_Payload.Relation = A11y.Relations.Labelled_By,
         "event framework rejects relation payloads for non-relation events");
   end Run_Property_State_Relation_Payload_Tests;

   procedure Run_Bounds_Focus_Node_Reference_Payload_Tests is
      Bounds_Payload : A11y.Events.Bounds_Event_Payload;
      Focus_Payload : A11y.Events.Focus_Event_Payload;
      Node_Reference_Payload : A11y.Events.Node_Reference_Event_Payload;
      Result : A11y.Results.Result;
   begin
      Bounds_Payload := A11y.Events.Validate_Bounds_Event_Payload
        (A11y.Events.Bounds_Changed,
         A11y.Geometry.Empty_Rectangle,
         (Origin => (X => 10, Y => 20),
          Extent => (Width => 30, Height => 40)),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Bounds_Payload.Old_Bounds =
           A11y.Geometry.Empty_Rectangle
         and then Bounds_Payload.New_Bounds.Origin.X = 10
         and then Bounds_Payload.New_Bounds.Extent.Width = 30,
         "event framework validates bounds payload metadata");

      Bounds_Payload := A11y.Events.Validate_Bounds_Event_Payload
        (A11y.Events.Bounds_Changed,
         Bounds_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Bounds_Payload.New_Bounds.Origin.X = 10,
         "event framework validates bounds payload records");

      Bounds_Payload := A11y.Events.Validate_Bounds_Event_Payload
        (A11y.Events.Bounds_Changed,
         A11y.Geometry.Empty_Rectangle,
         A11y.Geometry.Empty_Rectangle,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Bounds_Payload.Old_Bounds =
           A11y.Geometry.Empty_Rectangle,
         "event framework rejects no-op bounds payloads");

      Bounds_Payload := A11y.Events.Validate_Bounds_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Geometry.Empty_Rectangle,
         (Origin => (X => 1, Y => 2), Extent => (Width => 3, Height => 4)),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Bounds_Payload.New_Bounds =
           A11y.Geometry.Empty_Rectangle,
         "event framework rejects bounds payloads for non-bounds events");

      Focus_Payload := A11y.Events.Validate_Focus_Event_Payload
        (A11y.Events.Focus_Changed,
         A11y.Node_Ids.No_Node,
         A11y.Node_Ids.From_Natural (55),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Focus_Payload.Old_Focus = A11y.Node_Ids.No_Node
         and then Focus_Payload.New_Focus = A11y.Node_Ids.From_Natural (55),
         "event framework validates focus payload metadata");

      Focus_Payload := A11y.Events.Validate_Focus_Event_Payload
        (A11y.Events.Focus_Changed,
         A11y.Node_Ids.From_Natural (55),
         A11y.Node_Ids.No_Node,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Focus_Payload.Old_Focus = A11y.Node_Ids.From_Natural (55)
         and then Focus_Payload.New_Focus = A11y.Node_Ids.No_Node,
         "event framework validates focus-clear payload metadata");

      Focus_Payload := A11y.Events.Validate_Focus_Event_Payload
        (A11y.Events.Focus_Changed,
         Focus_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Focus_Payload.Old_Focus =
           A11y.Node_Ids.From_Natural (55),
         "event framework validates focus payload records");

      Focus_Payload := A11y.Events.Validate_Focus_Event_Payload
        (A11y.Events.Focus_Changed,
         A11y.Node_Ids.From_Natural (55),
         A11y.Node_Ids.From_Natural (55),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Focus_Payload.Old_Focus = A11y.Node_Ids.No_Node,
         "event framework rejects no-op focus payloads");

      Focus_Payload := A11y.Events.Validate_Focus_Event_Payload
        (A11y.Events.State_Changed,
         A11y.Node_Ids.No_Node,
         A11y.Node_Ids.From_Natural (55),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Focus_Payload.New_Focus = A11y.Node_Ids.No_Node,
         "event framework rejects focus payloads for non-focus events");

      Focus_Payload := A11y.Events.Validate_Focus_Event_Payload
        (A11y.Events.Focus_Changed,
         A11y.Node_Ids.From_Natural (A11y.Node_Ids.Max_Node_Ids + 1),
         A11y.Node_Ids.From_Natural (55),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Focus_Payload.Old_Focus = A11y.Node_Ids.No_Node
         and then Focus_Payload.New_Focus = A11y.Node_Ids.No_Node,
         "event framework rejects malformed focus node identifiers");

      Node_Reference_Payload :=
        A11y.Events.Validate_Node_Reference_Event_Payload
          (A11y.Events.Active_Descendant_Changed,
           A11y.Node_Ids.No_Node,
           A11y.Node_Ids.From_Natural (56),
           Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Node_Reference_Payload.Old_Node = A11y.Node_Ids.No_Node
         and then Node_Reference_Payload.New_Node =
           A11y.Node_Ids.From_Natural (56),
         "event framework validates active-descendant reference payloads");

      Node_Reference_Payload :=
        A11y.Events.Validate_Node_Reference_Event_Payload
          (A11y.Events.Current_Item_Changed,
           A11y.Node_Ids.From_Natural (56),
           A11y.Node_Ids.From_Natural (57),
           Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Node_Reference_Payload.Old_Node =
           A11y.Node_Ids.From_Natural (56)
         and then Node_Reference_Payload.New_Node =
           A11y.Node_Ids.From_Natural (57),
         "event framework validates current-item reference payloads");

      Node_Reference_Payload :=
        A11y.Events.Validate_Node_Reference_Event_Payload
          (A11y.Events.Current_Item_Changed,
           Node_Reference_Payload,
           Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Node_Reference_Payload.New_Node =
           A11y.Node_Ids.From_Natural (57),
         "event framework validates node-reference payload records");

      Node_Reference_Payload :=
        A11y.Events.Validate_Node_Reference_Event_Payload
          (A11y.Events.Current_Item_Changed,
           A11y.Node_Ids.From_Natural (56),
           A11y.Node_Ids.From_Natural (56),
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Node_Reference_Payload.Old_Node = A11y.Node_Ids.No_Node,
         "event framework rejects no-op node-reference payloads");

      Node_Reference_Payload :=
        A11y.Events.Validate_Node_Reference_Event_Payload
          (A11y.Events.Focus_Changed,
           A11y.Node_Ids.No_Node,
           A11y.Node_Ids.From_Natural (56),
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Node_Reference_Payload.New_Node = A11y.Node_Ids.No_Node,
         "event framework rejects node-reference payloads for other events");

      Node_Reference_Payload :=
        A11y.Events.Validate_Node_Reference_Event_Payload
          (A11y.Events.Current_Item_Changed,
           A11y.Node_Ids.From_Natural (56),
           A11y.Node_Ids.From_Natural (A11y.Node_Ids.Max_Node_Ids + 1),
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Node_Reference_Payload.Old_Node = A11y.Node_Ids.No_Node
         and then Node_Reference_Payload.New_Node = A11y.Node_Ids.No_Node,
         "event framework rejects malformed node-reference identifiers");
   end Run_Bounds_Focus_Node_Reference_Payload_Tests;

   procedure Run_Value_Selection_Payload_Tests is
      Value_Payload : A11y.Events.Value_Event_Payload;
      Selection_Payload : A11y.Events.Selection_Event_Payload;
      Result : A11y.Results.Result;
   begin
      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Value_Changed,
         A11y.Values.Integer (1),
         A11y.Values.Exact_Decimal (125, 2),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Value_Payload.Old_Kind = A11y.Values.Integer_Value
         and then Value_Payload.New_Kind = A11y.Values.Decimal_Value
         and then Value_Payload.New_Value.Decimal_Item.Units = 125
         and then Value_Payload.New_Value.Decimal_Item.Scale = 2,
         "event framework validates value payload metadata");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Range_Changed,
         (Kind => A11y.Values.Unknown),
         A11y.Values.Floating (2.5),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Value_Payload.Old_Kind = A11y.Values.Unknown
         and then Value_Payload.New_Kind = A11y.Values.Floating_Value,
         "event framework validates range payload metadata");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Range_Changed,
         Value_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Value_Payload.New_Kind = A11y.Values.Floating_Value,
         "event framework validates value payload records");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Range_Changed,
         A11y.Values.Boolean (False),
         A11y.Values.Boolean (True),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Value_Payload.Old_Kind = A11y.Values.Unknown,
         "event framework rejects nonnumeric range payload values");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Value_Changed,
         A11y.Values.Boolean (False),
         A11y.Values.Boolean (True),
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Value_Payload.New_Kind = A11y.Values.Boolean_Value,
         "event framework allows nonnumeric ordinary value payloads");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Value_Changed,
         (Old_Value => A11y.Values.Integer (1),
          New_Value => A11y.Values.Integer (2),
          Old_Kind  => A11y.Values.Floating_Value,
          New_Kind  => A11y.Values.Integer_Value),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Value_Payload.Old_Kind = A11y.Values.Unknown,
         "event framework rejects inconsistent value payload records");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           A11y.Node_Ids.From_Natural (58),
           True,
           False,
           True,
           True,
           Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Selection_Payload.Has_Changed_Node
         and then Selection_Payload.Changed_Node =
           A11y.Node_Ids.From_Natural (58)
         and then not Selection_Payload.Old_Selected
         and then Selection_Payload.New_Selected
         and then Selection_Payload.Requires_Selection,
         "event framework validates item-level selection payloads");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           A11y.Node_Ids.No_Node,
           False,
           False,
           False,
           False,
           Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not Selection_Payload.Has_Changed_Node
         and then Selection_Payload.Changed_Node = A11y.Node_Ids.No_Node,
         "event framework validates full-selection invalidation payloads");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           A11y.Node_Ids.From_Natural (58),
           False,
           False,
           False,
           False,
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Selection_Payload.Has_Changed_Node
         and then Selection_Payload.Changed_Node = A11y.Node_Ids.No_Node,
         "event framework rejects contradictory absent selection change nodes");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           (Changed_Node       => A11y.Node_Ids.No_Node,
            Has_Changed_Node   => False,
            Old_Selected       => False,
            New_Selected       => False,
            Requires_Selection => False),
           Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not Selection_Payload.Has_Changed_Node,
         "event framework validates selection payload records");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           A11y.Node_Ids.From_Natural (58),
           False,
           False,
           True,
           False,
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Selection_Payload.Changed_Node = A11y.Node_Ids.No_Node,
         "event framework rejects item state on selection invalidations");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           A11y.Node_Ids.No_Node,
           True,
           False,
           True,
           False,
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Selection_Payload.Has_Changed_Node,
         "event framework rejects invalid selection target payloads");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Selection_Changed,
           A11y.Node_Ids.From_Natural (58),
           True,
           True,
           True,
           False,
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Selection_Payload.Changed_Node = A11y.Node_Ids.No_Node,
         "event framework rejects no-op item-level selection payloads");

      Selection_Payload :=
        A11y.Events.Validate_Selection_Event_Payload
          (A11y.Events.Focus_Changed,
           A11y.Node_Ids.From_Natural (58),
           True,
           False,
           True,
           False,
           Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Selection_Payload.Changed_Node = A11y.Node_Ids.No_Node,
         "event framework rejects selection payloads for other events");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Value_Changed,
         A11y.Values.Integer (1),
         A11y.Values.Integer (1),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Value_Payload.Old_Kind = A11y.Values.Unknown,
         "event framework rejects no-op value payloads");

      Value_Payload := A11y.Events.Validate_Value_Event_Payload
        (A11y.Events.Property_Changed,
         A11y.Values.Integer (1),
         A11y.Values.Integer (2),
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Value_Payload.New_Kind = A11y.Values.Unknown,
         "event framework rejects value payloads for other events");
   end Run_Value_Selection_Payload_Tests;

   procedure Run_Live_Region_Payload_Tests is
      use Ada.Strings.Unbounded;

      Metadata : A11y.Live_Regions.Live_Region_Metadata;
      Announcement : A11y.Live_Regions.Announcement;
      Live_Payload : A11y.Events.Live_Region_Event_Payload;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Result : A11y.Results.Result;
   begin
      Check
        (A11y.Live_Regions.Stable_Name (A11y.Live_Regions.Polite)
         = "polite"
         and then A11y.Live_Regions.Metadata
           (A11y.Live_Regions.Assertive).Interruptive
         and then A11y.Live_Regions.Stable_Name
           (A11y.Live_Regions.Text) = "text",
         "live-region framework exposes stable metadata");
      Check
        (not A11y.Live_Regions.Has_Relevant_Changes (Metadata.Relevant)
         and then A11y.Live_Regions.Relevant_Count (Metadata.Relevant) = 0
         and then A11y.Live_Regions.Relevant_Names (Metadata.Relevant) = "",
         "live-region framework exposes empty relevance metadata centrally");
      Check
        (A11y.Results.Succeeded (A11y.Live_Regions.Validate (Metadata)),
         "live-region framework accepts inactive regions without relevance");
      Metadata.Relevant :=
        A11y.Live_Regions.With_Change
          (Metadata.Relevant, A11y.Live_Regions.Text);
      Check
        (A11y.Live_Regions.Validate (Metadata).Status =
         A11y.Results.Invalid_State,
         "live-region framework rejects inactive regions with relevance");
      Metadata.Relevant := A11y.Live_Regions.Empty_Relevant_Change_Set;
      Metadata.Setting := A11y.Live_Regions.Polite;
      Check
        (A11y.Live_Regions.Validate (Metadata).Status =
         A11y.Results.Invalid_State,
         "live-region framework requires relevance for announced regions");
      Metadata.Relevant :=
        A11y.Live_Regions.With_Change
          (Metadata.Relevant, A11y.Live_Regions.Text);
      Check
        (A11y.Live_Regions.Has_Relevant_Changes (Metadata.Relevant)
         and then A11y.Live_Regions.Relevant_Count (Metadata.Relevant) = 1
         and then A11y.Live_Regions.Relevant_Names (Metadata.Relevant) =
           "text",
         "live-region framework exposes relevance names centrally");
      Check
        (A11y.Results.Succeeded (A11y.Live_Regions.Validate (Metadata)),
         "live-region framework validates announced region relevance");

      declare
         Provider : A11y_Node_Provider_Fixtures.Test_Live_Region_Provider :=
           (Metadata => Metadata, Raise_On_Query => False);
         Provider_Metadata : A11y.Live_Regions.Live_Region_Metadata;
      begin
         Provider_Metadata :=
           A11y.Live_Regions.Current_Metadata_Safely (Provider, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Provider_Metadata.Setting = A11y.Live_Regions.Polite
            and then Provider_Metadata.Relevant (A11y.Live_Regions.Text),
            "live-region provider safely returns validated metadata");

         Provider.Metadata.Setting := A11y.Live_Regions.Off;
         Provider_Metadata :=
           A11y.Live_Regions.Current_Metadata_Safely (Provider, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Provider_Metadata.Setting = A11y.Live_Regions.Off
            and then not A11y.Live_Regions.Has_Relevant_Changes
              (Provider_Metadata.Relevant),
            "live-region provider normalizes invalid metadata");

         Provider.Metadata := Metadata;
         Provider.Raise_On_Query := True;
         Provider_Metadata :=
           A11y.Live_Regions.Current_Metadata_Safely (Provider, Result);
         Check
           (Result.Status = A11y.Results.Internal_Error
            and then Provider_Metadata.Setting = A11y.Live_Regions.Off
            and then not A11y.Live_Regions.Has_Relevant_Changes
              (Provider_Metadata.Relevant),
            "live-region provider contains query exceptions as inactive metadata");
      end;

      A11y.Live_Regions.Create_Announcement
        ("ready", False, Limits, Announcement, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then To_String (Announcement.Text) = "ready",
         "live-region framework creates bounded announcements");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Announcement_Requested,
         Metadata,
         Announcement,
         True,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Live_Payload.Metadata.Setting = A11y.Live_Regions.Polite
         and then Live_Payload.Has_Announcement
         and then To_String (Live_Payload.Announcement.Text) = "ready",
         "event framework validates announcement payload metadata");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Live_Region_Changed,
         Metadata,
         (Text => Null_Unbounded_String),
         False,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not Live_Payload.Has_Announcement
         and then Live_Payload.Metadata.Relevant (A11y.Live_Regions.Text),
         "event framework validates live-region change payload metadata");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Live_Region_Changed,
         Metadata,
         Announcement,
         False,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Live_Payload.Has_Announcement
         and then Length (Live_Payload.Announcement.Text) = 0,
         "event framework rejects contradictory absent live-region announcements");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Live_Region_Changed,
         Metadata,
         Announcement,
         True,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Live_Payload.Has_Announcement
         and then Length (Live_Payload.Announcement.Text) = 0,
         "event framework rejects announcements on live-region changes");
      Live_Payload :=
        (Metadata         => Metadata,
         Announcement     => (Text => Null_Unbounded_String),
         Has_Announcement => False);
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Live_Region_Changed,
         Live_Payload,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not Live_Payload.Has_Announcement,
         "event framework validates live-region payload records");
      Live_Payload :=
        (Metadata         => Metadata,
         Announcement     => (Text => To_Unbounded_String ("toolong")),
         Has_Announcement => True);
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "event framework configures live-region payload text limit");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Announcement_Requested,
         Live_Payload,
         Limits,
         Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not Live_Payload.Has_Announcement
         and then Length (Live_Payload.Announcement.Text) = 0,
         "event framework bounds record-shaped live-region payload text");
      Limits := A11y.Resource_Limits.Default_Config;
      Live_Payload :=
        (Metadata         => Metadata,
         Announcement     =>
           (Text =>
              To_Unbounded_String
                ([1 .. Natural
                    (A11y.Resource_Limits.Value
                       (A11y.Resource_Limits.Default_Config,
                        A11y.Resource_Limits.Text_Returned)) + 1 =>
                   'x'])),
         Has_Announcement => True);
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Announcement_Requested,
         Live_Payload,
         Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not Live_Payload.Has_Announcement,
         "event framework applies default bounds to record-shaped live-region payload text");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Property_Changed,
         Metadata,
         Announcement,
         True,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Live_Payload.Has_Announcement,
         "event framework rejects live-region payloads for other events");
      Live_Payload := A11y.Events.Validate_Live_Region_Event_Payload
        (A11y.Events.Announcement_Requested,
         Metadata,
         Announcement,
         False,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not Live_Payload.Has_Announcement,
         "event framework rejects announcement payloads without text");
      A11y.Live_Regions.Create_Announcement
        ("", False, Limits, Announcement, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Length (Announcement.Text) = 0,
         "live-region framework rejects empty announcement text");
      A11y.Live_Regions.Create_Announcement
        ("secret", True, Limits, Announcement, Result);
      Check
        (Result.Status = A11y.Results.Permission_Denied
         and then Length (Announcement.Text) = 0,
         "live-region framework rejects protected announcement text");
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Text_Returned, 4, Result);
      A11y.Live_Regions.Create_Announcement
        ("ready", False, Limits, Announcement, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Length (Announcement.Text) = 0,
         "live-region framework bounds announcement text");
   end Run_Live_Region_Payload_Tests;

   procedure Run is
   begin
      Run_Metadata_Tests;
      Run_Classification_Tests;
      Run_Envelope_Tests;
      Run_Tree_Payload_Tests;
      Run_Table_Payload_Tests;
      Run_Document_Window_Payload_Tests;
      Run_Text_Payload_Tests;
      Run_Property_State_Relation_Payload_Tests;
      Run_Bounds_Focus_Node_Reference_Payload_Tests;
      Run_Value_Selection_Payload_Tests;
      Run_Live_Region_Payload_Tests;
   end Run;
end A11y_Event_Framework_Tests;
