with Ada.Strings.Unbounded;

package body A11y.Events is
   use Ada.Strings.Unbounded;
   use Ada.Strings.Wide_Wide_Unbounded;
   use type A11y.Geometry.Rectangle;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Properties.Property_Status;
   use type A11y.Properties.Property_Value_Kind;
   use type A11y.Relations.Relation_Kind;
   use type A11y.States.State_Source;
   use type A11y.Tables.Logical_Index;
   use type A11y.Text.Protected_Text_Policy;
   use type A11y.Values.Value_Kind;

   Node_Created_Name               : aliased constant String := "node.created";
   Node_Destroyed_Name             : aliased constant String := "node.destroyed";
   Node_Attached_Name              : aliased constant String := "node.attached";
   Node_Detached_Name              : aliased constant String := "node.detached";
   Child_Added_Name                : aliased constant String := "child.added";
   Child_Removed_Name              : aliased constant String := "child.removed";
   Children_Reordered_Name         : aliased constant String := "children.reordered";
   Subtree_Rebuilt_Name            : aliased constant String := "subtree.rebuilt";
   Property_Changed_Name           : aliased constant String := "property.changed";
   State_Changed_Name              : aliased constant String := "state.changed";
   Bounds_Changed_Name             : aliased constant String := "bounds.changed";
   Focus_Changed_Name              : aliased constant String := "focus.changed";
   Active_Descendant_Changed_Name  : aliased constant String :=
     "active-descendant.changed";
   Selection_Changed_Name          : aliased constant String := "selection.changed";
   Current_Item_Changed_Name       : aliased constant String :=
     "current-item.changed";
   Value_Changed_Name              : aliased constant String := "value.changed";
   Range_Changed_Name              : aliased constant String := "range.changed";
   Text_Inserted_Name              : aliased constant String := "text.inserted";
   Text_Removed_Name               : aliased constant String := "text.removed";
   Text_Replaced_Name              : aliased constant String := "text.replaced";
   Caret_Moved_Name                : aliased constant String := "caret.moved";
   Text_Selection_Changed_Name     : aliased constant String :=
     "text-selection.changed";
   Text_Attributes_Changed_Name    : aliased constant String :=
     "text-attributes.changed";
   Row_Inserted_Name               : aliased constant String := "row.inserted";
   Row_Removed_Name                : aliased constant String := "row.removed";
   Column_Inserted_Name            : aliased constant String := "column.inserted";
   Column_Removed_Name             : aliased constant String := "column.removed";
   Cell_Changed_Name               : aliased constant String := "cell.changed";
   Window_Opened_Name              : aliased constant String := "window.opened";
   Window_Closed_Name              : aliased constant String := "window.closed";
   Window_Activated_Name           : aliased constant String := "window.activated";
   Window_Deactivated_Name         : aliased constant String :=
     "window.deactivated";
   Document_Loaded_Name            : aliased constant String := "document.loaded";
   Document_Closed_Name            : aliased constant String := "document.closed";
   Announcement_Requested_Name     : aliased constant String :=
     "announcement.requested";
   Live_Region_Changed_Name        : aliased constant String :=
     "live-region.changed";
   Relation_Added_Name             : aliased constant String := "relation.added";
   Relation_Removed_Name           : aliased constant String := "relation.removed";
   Relation_Targets_Changed_Name   : aliased constant String :=
     "relation-targets.changed";

   function Metadata (Kind : Event_Kind) return Event_Metadata is
     (case Kind is
        when Node_Created =>
          (Stable_Name => Node_Created_Name'Access, Coalescible => False),
        when Node_Destroyed =>
          (Stable_Name => Node_Destroyed_Name'Access, Coalescible => False),
        when Node_Attached =>
          (Stable_Name => Node_Attached_Name'Access, Coalescible => False),
        when Node_Detached =>
          (Stable_Name => Node_Detached_Name'Access, Coalescible => False),
        when Child_Added =>
          (Stable_Name => Child_Added_Name'Access, Coalescible => False),
        when Child_Removed =>
          (Stable_Name => Child_Removed_Name'Access, Coalescible => False),
        when Children_Reordered =>
          (Stable_Name => Children_Reordered_Name'Access, Coalescible => False),
        when Subtree_Rebuilt =>
          (Stable_Name => Subtree_Rebuilt_Name'Access, Coalescible => False),
        when Property_Changed =>
          (Stable_Name => Property_Changed_Name'Access, Coalescible => False),
        when State_Changed =>
          (Stable_Name => State_Changed_Name'Access, Coalescible => False),
        when Bounds_Changed =>
          (Stable_Name => Bounds_Changed_Name'Access, Coalescible => True),
        when Focus_Changed =>
          (Stable_Name => Focus_Changed_Name'Access, Coalescible => False),
        when Active_Descendant_Changed =>
          (Stable_Name => Active_Descendant_Changed_Name'Access,
           Coalescible => False),
        when Selection_Changed =>
          (Stable_Name => Selection_Changed_Name'Access, Coalescible => False),
        when Current_Item_Changed =>
          (Stable_Name => Current_Item_Changed_Name'Access, Coalescible => False),
        when Value_Changed =>
          (Stable_Name => Value_Changed_Name'Access, Coalescible => True),
        when Range_Changed =>
          (Stable_Name => Range_Changed_Name'Access, Coalescible => False),
        when Text_Inserted =>
          (Stable_Name => Text_Inserted_Name'Access, Coalescible => False),
        when Text_Removed =>
          (Stable_Name => Text_Removed_Name'Access, Coalescible => False),
        when Text_Replaced =>
          (Stable_Name => Text_Replaced_Name'Access, Coalescible => False),
        when Caret_Moved =>
          (Stable_Name => Caret_Moved_Name'Access, Coalescible => False),
        when Text_Selection_Changed =>
          (Stable_Name => Text_Selection_Changed_Name'Access,
           Coalescible => False),
        when Text_Attributes_Changed =>
          (Stable_Name => Text_Attributes_Changed_Name'Access,
           Coalescible => False),
        when Row_Inserted =>
          (Stable_Name => Row_Inserted_Name'Access, Coalescible => False),
        when Row_Removed =>
          (Stable_Name => Row_Removed_Name'Access, Coalescible => False),
        when Column_Inserted =>
          (Stable_Name => Column_Inserted_Name'Access, Coalescible => False),
        when Column_Removed =>
          (Stable_Name => Column_Removed_Name'Access, Coalescible => False),
        when Cell_Changed =>
          (Stable_Name => Cell_Changed_Name'Access, Coalescible => False),
        when Window_Opened =>
          (Stable_Name => Window_Opened_Name'Access, Coalescible => False),
        when Window_Closed =>
          (Stable_Name => Window_Closed_Name'Access, Coalescible => False),
        when Window_Activated =>
          (Stable_Name => Window_Activated_Name'Access, Coalescible => False),
        when Window_Deactivated =>
          (Stable_Name => Window_Deactivated_Name'Access, Coalescible => False),
        when Document_Loaded =>
          (Stable_Name => Document_Loaded_Name'Access, Coalescible => False),
        when Document_Closed =>
          (Stable_Name => Document_Closed_Name'Access, Coalescible => False),
        when Announcement_Requested =>
          (Stable_Name => Announcement_Requested_Name'Access,
           Coalescible => False),
        when Live_Region_Changed =>
          (Stable_Name => Live_Region_Changed_Name'Access,
           Coalescible => False),
        when Relation_Added =>
          (Stable_Name => Relation_Added_Name'Access, Coalescible => False),
        when Relation_Removed =>
          (Stable_Name => Relation_Removed_Name'Access, Coalescible => False),
        when Relation_Targets_Changed =>
          (Stable_Name => Relation_Targets_Changed_Name'Access,
           Coalescible => False));

   function Stable_Name (Kind : Event_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Is_Coalescible (Kind : Event_Kind) return Boolean is
     (Kind in Bounds_Changed | Value_Changed)
   with SPARK_Mode => On;

   function Validate_Event
     (Item : Event)
      return A11y.Results.Result
   with SPARK_Mode => On
   is
   begin
      if Item.Sequence = A11y.No_Event then
         return (Status => A11y.Results.Invalid_Argument);
      elsif not A11y.Node_Ids.Is_Valid (Item.Source) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      return A11y.Results.Ok;
   end Validate_Event;

   function Is_Text_Event (Kind : Event_Kind) return Boolean is
     (Kind in Text_Inserted | Text_Removed | Text_Replaced | Caret_Moved
      | Text_Selection_Changed | Text_Attributes_Changed)
   with SPARK_Mode => On;

   function Is_Property_Event (Kind : Event_Kind) return Boolean is
     (Kind in Property_Changed | Bounds_Changed)
   with SPARK_Mode => On;

   function Is_State_Event (Kind : Event_Kind) return Boolean is
     (Kind in State_Changed | Focus_Changed | Active_Descendant_Changed)
   with SPARK_Mode => On;

   function Is_Value_Event (Kind : Event_Kind) return Boolean is
     (Kind in Value_Changed | Range_Changed)
   with SPARK_Mode => On;

   function Is_Selection_Event (Kind : Event_Kind) return Boolean is
     (Kind in Selection_Changed | Current_Item_Changed
      | Text_Selection_Changed)
   with SPARK_Mode => On;

   function Is_Focus_Event (Kind : Event_Kind) return Boolean is
     (Kind in Focus_Changed | Active_Descendant_Changed
      | Current_Item_Changed)
   with SPARK_Mode => On;

   function Is_Live_Region_Event (Kind : Event_Kind) return Boolean is
     (Kind in Announcement_Requested
            | Live_Region_Changed)
   with SPARK_Mode => On;

   function Is_Lifecycle_Event (Kind : Event_Kind) return Boolean is
     (Kind in Node_Created | Node_Destroyed | Node_Attached | Node_Detached)
   with SPARK_Mode => On;

   function Is_Tree_Event (Kind : Event_Kind) return Boolean is
     (Kind in Node_Created | Node_Destroyed | Node_Attached | Node_Detached
      | Child_Added | Child_Removed | Children_Reordered | Subtree_Rebuilt)
   with SPARK_Mode => On;

   function Is_Table_Event (Kind : Event_Kind) return Boolean is
     (Kind in Row_Inserted | Row_Removed | Column_Inserted | Column_Removed
      | Cell_Changed)
   with SPARK_Mode => On;

   function Is_Document_Event (Kind : Event_Kind) return Boolean is
     (Kind in Document_Loaded | Document_Closed)
   with SPARK_Mode => On;

   function Is_Relation_Event (Kind : Event_Kind) return Boolean is
     (Kind in Active_Descendant_Changed | Relation_Added | Relation_Removed
      | Relation_Targets_Changed)
   with SPARK_Mode => On;

   function Is_Window_Event (Kind : Event_Kind) return Boolean is
     (Kind in Window_Opened | Window_Closed | Window_Activated
      | Window_Deactivated)
   with SPARK_Mode => On;

   function Must_Preserve_Individual_Order
     (Kind : Event_Kind)
      return Boolean is
     (Is_Text_Event (Kind) or else Is_Lifecycle_Event (Kind)
      or else Is_Relation_Event (Kind))
   with SPARK_Mode => On;

   function Empty_Text_Payload return Text_Event_Payload is
     (Span         => A11y.Text.Empty_Range,
      Text         => Null_Unbounded_Wide_Wide_String,
      Carries_Text => False);

   function Empty_Property_Payload return Property_Event_Payload is
     (Property   => A11y.Properties.Accessible_Name,
      Value_Kind => A11y.Properties.String_Value,
      Old_Status => A11y.Properties.Unsupported,
      New_Status => A11y.Properties.Unsupported)
   with SPARK_Mode => On;

   function Empty_State_Payload return State_Event_Payload is
     (State     => A11y.States.Enabled,
      Source    => A11y.States.Application_Provided,
      Old_Value => False,
      New_Value => False)
   with SPARK_Mode => On;

   function Empty_Relation_Payload return Relation_Event_Payload is
     (Relation   => A11y.Relations.Labelled_By,
      Inverse    => A11y.Relations.Label_For,
      Target     => A11y.Node_Ids.No_Node,
      Has_Target => False)
   with SPARK_Mode => On;

   function Empty_Bounds_Payload return Bounds_Event_Payload is
     (Old_Bounds => A11y.Geometry.Empty_Rectangle,
      New_Bounds => A11y.Geometry.Empty_Rectangle)
   with SPARK_Mode => On;

   function Empty_Focus_Payload return Focus_Event_Payload is
     (Old_Focus => A11y.Node_Ids.No_Node,
      New_Focus => A11y.Node_Ids.No_Node)
   with SPARK_Mode => On;

   function Empty_Node_Reference_Payload
      return Node_Reference_Event_Payload is
     (Old_Node => A11y.Node_Ids.No_Node,
      New_Node => A11y.Node_Ids.No_Node)
   with SPARK_Mode => On;

   function Empty_Value_Payload return Value_Event_Payload is
     (Old_Value => (Kind => A11y.Values.Unknown),
      New_Value => (Kind => A11y.Values.Unknown),
      Old_Kind  => A11y.Values.Unknown,
      New_Kind  => A11y.Values.Unknown)
   with SPARK_Mode => On;

   function Empty_Selection_Payload return Selection_Event_Payload is
     (Changed_Node       => A11y.Node_Ids.No_Node,
      Has_Changed_Node   => False,
      Old_Selected       => False,
      New_Selected       => False,
      Requires_Selection => False)
   with SPARK_Mode => On;

   function Empty_Live_Region_Payload return Live_Region_Event_Payload is
     (Metadata         => (Setting  => A11y.Live_Regions.Off,
                           Atomic   => False,
                           Relevant =>
                             A11y.Live_Regions.Empty_Relevant_Change_Set),
      Announcement     => (Text => Null_Unbounded_String),
      Has_Announcement => False);

   function Empty_Tree_Payload return Tree_Event_Payload is
     (Parent    => A11y.Node_Ids.No_Node,
      Child     => A11y.Node_Ids.No_Node,
      Has_Child => False,
      Index     => Positive'First,
      Has_Index => False)
   with SPARK_Mode => On;

   function Empty_Table_Payload return Table_Event_Payload is
     (Table      => A11y.Node_Ids.No_Node,
      Item       => A11y.Node_Ids.No_Node,
      Has_Item   => False,
      Row        => 0,
      Has_Row    => False,
      Column     => 0,
      Has_Column => False)
   with SPARK_Mode => On;

   function Empty_Document_Payload return Document_Event_Payload is
     (Document    => A11y.Node_Ids.No_Node,
      Surface     => A11y.Node_Ids.No_Node,
      Has_Surface => False)
   with SPARK_Mode => On;

   function Empty_Window_Payload return Window_Event_Payload is
     (Surface   => A11y.Node_Ids.No_Node,
      Kind      => A11y.Windows.Window,
      Owner     => A11y.Node_Ids.No_Node,
      Has_Owner => False)
   with SPARK_Mode => On;

   function Allows_Absent_Node (Node : A11y.Node_Ids.Node_Id) return Boolean is
     (Node = A11y.Node_Ids.No_Node or else A11y.Node_Ids.Is_Valid (Node))
   with SPARK_Mode => On;

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Text           : Wide_Wide_String;
      Policy         : A11y.Text.Protected_Text_Policy;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload
   is
      Span : A11y.Text.Text_Range;
   begin
      if not Is_Text_Event (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Text_Payload;
      end if;

      if Policy = A11y.Text.Protected_Text
        and then Kind in Text_Inserted | Text_Removed | Text_Replaced
      then
         Result := (Status => A11y.Results.Permission_Denied);
         return Empty_Text_Payload;
      end if;

      case Kind is
         when Text_Inserted =>
            if Count /= 0 then
               Result := (Status => A11y.Results.Invalid_Range);
               return Empty_Text_Payload;
            end if;
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content_Length, Start, 0, Limits, Result);
         when Text_Removed =>
            if Count = 0 then
               Result := (Status => A11y.Results.Invalid_Range);
               return Empty_Text_Payload;
            end if;
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content_Length, Start, Count, Limits, Result);
         when Text_Replaced =>
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content_Length, Start, Count, Limits, Result);
         when Caret_Moved =>
            if Count /= 0 or else Text'Length /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Text_Payload;
            end if;
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content_Length, Start, 0, Limits, Result);
         when Text_Selection_Changed | Text_Attributes_Changed =>
            if Text'Length /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Text_Payload;
            end if;
            Span := A11y.Text.Bounded_Code_Point_Range
              (Content_Length, Start, Count, Limits, Result);
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return Empty_Text_Payload;
      end case;

      if A11y.Results.Failed (Result) then
         return Empty_Text_Payload;
      end if;

      if Kind in Text_Inserted | Text_Replaced then
         declare
            Request : constant A11y.Text.Text_Edit_Request :=
              A11y.Text.Validate_Edit_Request
                (Content_Length,
                 (if Kind = Text_Inserted
                  then A11y.Text.Insert_Text
                  else A11y.Text.Replace_Text),
                 Start,
                 Count,
                 Text,
                 Policy,
                 Read_Only => False,
                 Limits    => Limits,
                 Result    => Result);
         begin
            if A11y.Results.Failed (Result) then
               return Empty_Text_Payload;
            end if;

            Result := A11y.Results.Ok;
            return
              (Span         => Span,
               Text         => Request.Text,
               Carries_Text => Length (Request.Text) > 0);
         end;
      end if;

      Result := A11y.Results.Ok;
      return
        (Span         => Span,
         Text         => Null_Unbounded_Wide_Wide_String,
         Carries_Text => False);
   end Validate_Text_Event_Payload;

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Text           : Wide_Wide_String;
      Policy         : A11y.Text.Protected_Text_Policy;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload is
     (Validate_Text_Event_Payload
        (Kind,
         Content_Length,
         Start,
         Count,
         Text,
         Policy,
         A11y.Resource_Limits.Default_Config,
         Result));

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Payload        : Text_Event_Payload;
      Policy         : A11y.Text.Protected_Text_Policy;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload
   is
      Text_Length : constant Natural := Length (Payload.Text);
   begin
      if not A11y.Text.Is_Valid (Payload.Span) then
         Result := (Status => A11y.Results.Invalid_Range);
         return Empty_Text_Payload;
      elsif Payload.Carries_Text /= (Text_Length > 0) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Text_Payload;
      elsif Kind not in Text_Inserted | Text_Replaced
        and then Text_Length > 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Text_Payload;
      end if;

      return Validate_Text_Event_Payload
        (Kind           => Kind,
         Content_Length => Content_Length,
         Start          => A11y.Text.Index (A11y.Text.First (Payload.Span)),
         Count          => A11y.Text.Length (Payload.Span),
         Text           => To_Wide_Wide_String (Payload.Text),
         Policy         => Policy,
         Limits         => Limits,
         Result         => Result);
   end Validate_Text_Event_Payload;

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Payload        : Text_Event_Payload;
      Policy         : A11y.Text.Protected_Text_Policy;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload is
     (Validate_Text_Event_Payload
        (Kind,
         Content_Length,
         Payload,
         Policy,
         A11y.Resource_Limits.Default_Config,
         Result));

   function Validate_Property_Event_Payload
     (Kind       : Event_Kind;
      Property   : A11y.Properties.Property_Id;
      Old_Status : A11y.Properties.Property_Status;
      New_Status : A11y.Properties.Property_Status;
      Result     : out A11y.Results.Result)
      return Property_Event_Payload
   is
   begin
      if Kind /= Property_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Property_Payload;
      end if;

      if Old_Status = A11y.Properties.Node_Unavailable
        or else New_Status = A11y.Properties.Node_Unavailable
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return Empty_Property_Payload;
      elsif Old_Status = A11y.Properties.Unsupported
        and then New_Status = A11y.Properties.Unsupported
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Property_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Property   => Property,
         Value_Kind => A11y.Properties.Metadata (Property).Value_Kind,
         Old_Status => Old_Status,
         New_Status => New_Status);
   end Validate_Property_Event_Payload;

   function Validate_Property_Event_Payload
     (Kind    : Event_Kind;
      Payload : Property_Event_Payload;
      Result  : out A11y.Results.Result)
      return Property_Event_Payload
   is
   begin
      if Payload.Value_Kind /=
        A11y.Properties.Metadata (Payload.Property).Value_Kind
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Property_Payload;
      end if;

      return Validate_Property_Event_Payload
        (Kind       => Kind,
         Property   => Payload.Property,
         Old_Status => Payload.Old_Status,
         New_Status => Payload.New_Status,
         Result     => Result);
   end Validate_Property_Event_Payload;

   function Validate_State_Event_Payload
     (Kind      : Event_Kind;
      State     : A11y.States.State_Flag;
      Old_Value : Boolean;
      New_Value : Boolean;
      Result    : out A11y.Results.Result)
      return State_Event_Payload
   is
   begin
      if Kind /= State_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_State_Payload;
      elsif Old_Value = New_Value then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_State_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (State     => State,
         Source    => A11y.States.Source (State),
         Old_Value => Old_Value,
         New_Value => New_Value);
   end Validate_State_Event_Payload;

   function Validate_State_Event_Payload
     (Kind    : Event_Kind;
      Payload : State_Event_Payload;
      Result  : out A11y.Results.Result)
      return State_Event_Payload
   is
   begin
      if Payload.Source /= A11y.States.Source (Payload.State) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_State_Payload;
      end if;

      return Validate_State_Event_Payload
        (Kind      => Kind,
         State     => Payload.State,
         Old_Value => Payload.Old_Value,
         New_Value => Payload.New_Value,
         Result    => Result);
   end Validate_State_Event_Payload;

   function Validate_Relation_Event_Payload
     (Kind       : Event_Kind;
      Relation   : A11y.Relations.Relation_Kind;
      Target     : A11y.Node_Ids.Node_Id;
      Has_Target : Boolean;
      Result     : out A11y.Results.Result)
      return Relation_Event_Payload
   is
   begin
      if not Is_Relation_Event (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Relation_Payload;
      elsif Kind in Relation_Added | Relation_Removed
        and then (not Has_Target
                  or else not A11y.Node_Ids.Is_Valid (Target))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Relation_Payload;
      elsif not Has_Target and then Target /= A11y.Node_Ids.No_Node then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Relation_Payload;
      elsif Has_Target and then not A11y.Node_Ids.Is_Valid (Target) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Relation_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Relation   => Relation,
         Inverse    => A11y.Relations.Inverse (Relation),
         Target     => (if Has_Target then Target else A11y.Node_Ids.No_Node),
         Has_Target => Has_Target);
   end Validate_Relation_Event_Payload;

   function Validate_Relation_Event_Payload
     (Kind    : Event_Kind;
      Payload : Relation_Event_Payload;
      Result  : out A11y.Results.Result)
      return Relation_Event_Payload
   is
   begin
      if Payload.Inverse /= A11y.Relations.Inverse (Payload.Relation) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Relation_Payload;
      end if;

      return Validate_Relation_Event_Payload
        (Kind       => Kind,
         Relation   => Payload.Relation,
         Target     => Payload.Target,
         Has_Target => Payload.Has_Target,
         Result     => Result);
   end Validate_Relation_Event_Payload;

   function Validate_Bounds_Event_Payload
     (Kind       : Event_Kind;
      Old_Bounds : A11y.Geometry.Rectangle;
      New_Bounds : A11y.Geometry.Rectangle;
      Result     : out A11y.Results.Result)
      return Bounds_Event_Payload
   is
   begin
      if Kind /= Bounds_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Bounds_Payload;
      elsif Old_Bounds = New_Bounds then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Bounds_Payload;
      end if;

      Result := A11y.Results.Ok;
      return (Old_Bounds => Old_Bounds, New_Bounds => New_Bounds);
   end Validate_Bounds_Event_Payload;

   function Validate_Bounds_Event_Payload
     (Kind    : Event_Kind;
      Payload : Bounds_Event_Payload;
      Result  : out A11y.Results.Result)
      return Bounds_Event_Payload is
     (Validate_Bounds_Event_Payload
        (Kind       => Kind,
         Old_Bounds => Payload.Old_Bounds,
         New_Bounds => Payload.New_Bounds,
         Result     => Result));

   function Validate_Focus_Event_Payload
     (Kind      : Event_Kind;
      Old_Focus : A11y.Node_Ids.Node_Id;
      New_Focus : A11y.Node_Ids.Node_Id;
      Result    : out A11y.Results.Result)
      return Focus_Event_Payload
   is
   begin
      if Kind /= Focus_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Focus_Payload;
      elsif Old_Focus = New_Focus then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Focus_Payload;
      elsif not Allows_Absent_Node (Old_Focus)
        or else not Allows_Absent_Node (New_Focus)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Focus_Payload;
      elsif (not A11y.Node_Ids.Is_Valid (Old_Focus))
        and then (not A11y.Node_Ids.Is_Valid (New_Focus))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Focus_Payload;
      end if;

      Result := A11y.Results.Ok;
      return (Old_Focus => Old_Focus, New_Focus => New_Focus);
   end Validate_Focus_Event_Payload;

   function Validate_Focus_Event_Payload
     (Kind    : Event_Kind;
      Payload : Focus_Event_Payload;
      Result  : out A11y.Results.Result)
      return Focus_Event_Payload is
     (Validate_Focus_Event_Payload
        (Kind      => Kind,
         Old_Focus => Payload.Old_Focus,
         New_Focus => Payload.New_Focus,
         Result    => Result));

   function Validate_Node_Reference_Event_Payload
     (Kind     : Event_Kind;
      Old_Node : A11y.Node_Ids.Node_Id;
      New_Node : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
      return Node_Reference_Event_Payload
   is
   begin
      if Kind not in Active_Descendant_Changed | Current_Item_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Node_Reference_Payload;
      elsif Old_Node = New_Node then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Node_Reference_Payload;
      elsif not Allows_Absent_Node (Old_Node)
        or else not Allows_Absent_Node (New_Node)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Node_Reference_Payload;
      elsif (not A11y.Node_Ids.Is_Valid (Old_Node))
        and then (not A11y.Node_Ids.Is_Valid (New_Node))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Node_Reference_Payload;
      end if;

      Result := A11y.Results.Ok;
      return (Old_Node => Old_Node, New_Node => New_Node);
   end Validate_Node_Reference_Event_Payload;

   function Validate_Node_Reference_Event_Payload
     (Kind    : Event_Kind;
      Payload : Node_Reference_Event_Payload;
      Result  : out A11y.Results.Result)
      return Node_Reference_Event_Payload is
     (Validate_Node_Reference_Event_Payload
        (Kind     => Kind,
         Old_Node => Payload.Old_Node,
         New_Node => Payload.New_Node,
         Result   => Result));

   function Validate_Value_Event_Payload
     (Kind      : Event_Kind;
      Old_Value : A11y.Values.Semantic_Value;
      New_Value : A11y.Values.Semantic_Value;
      Result    : out A11y.Results.Result)
      return Value_Event_Payload
   is
   begin
      if Kind not in Value_Changed | Range_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Value_Payload;
      elsif A11y.Values.Equal (Old_Value, New_Value) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Value_Payload;
      elsif Kind = Range_Changed
        and then ((A11y.Values.Is_Known (Old_Value)
                   and then not A11y.Values.Is_Numeric (Old_Value))
                  or else (A11y.Values.Is_Known (New_Value)
                            and then not A11y.Values.Is_Numeric (New_Value)))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Value_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Old_Value => Old_Value,
         New_Value => New_Value,
         Old_Kind  => Old_Value.Kind,
         New_Kind  => New_Value.Kind);
   end Validate_Value_Event_Payload;

   function Validate_Value_Event_Payload
     (Kind    : Event_Kind;
      Payload : Value_Event_Payload;
      Result  : out A11y.Results.Result)
      return Value_Event_Payload
   is
   begin
      if Payload.Old_Kind /= Payload.Old_Value.Kind
        or else Payload.New_Kind /= Payload.New_Value.Kind
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Value_Payload;
      end if;

      return Validate_Value_Event_Payload
        (Kind      => Kind,
         Old_Value => Payload.Old_Value,
         New_Value => Payload.New_Value,
         Result    => Result);
   end Validate_Value_Event_Payload;

   function Validate_Selection_Event_Payload
     (Kind               : Event_Kind;
      Changed_Node       : A11y.Node_Ids.Node_Id;
      Has_Changed_Node   : Boolean;
      Old_Selected       : Boolean;
      New_Selected       : Boolean;
      Requires_Selection : Boolean;
      Result             : out A11y.Results.Result)
      return Selection_Event_Payload
   is
   begin
      if Kind /= Selection_Changed then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Selection_Payload;
      elsif Has_Changed_Node
        and then not A11y.Node_Ids.Is_Valid (Changed_Node)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Selection_Payload;
      elsif not Has_Changed_Node
        and then Changed_Node /= A11y.Node_Ids.No_Node
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Selection_Payload;
      elsif Has_Changed_Node and then Old_Selected = New_Selected then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Selection_Payload;
      elsif not Has_Changed_Node
        and then (Old_Selected or else New_Selected)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Selection_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Changed_Node       =>
           (if Has_Changed_Node
            then Changed_Node
            else A11y.Node_Ids.No_Node),
         Has_Changed_Node   => Has_Changed_Node,
         Old_Selected       => Old_Selected,
         New_Selected       => New_Selected,
         Requires_Selection => Requires_Selection);
   end Validate_Selection_Event_Payload;

   function Validate_Selection_Event_Payload
     (Kind    : Event_Kind;
      Payload : Selection_Event_Payload;
      Result  : out A11y.Results.Result)
      return Selection_Event_Payload is
     (Validate_Selection_Event_Payload
        (Kind               => Kind,
         Changed_Node       => Payload.Changed_Node,
         Has_Changed_Node   => Payload.Has_Changed_Node,
         Old_Selected       => Payload.Old_Selected,
         New_Selected       => Payload.New_Selected,
         Requires_Selection => Payload.Requires_Selection,
         Result             => Result));

   function Validate_Live_Region_Event_Payload
     (Kind             : Event_Kind;
      Metadata         : A11y.Live_Regions.Live_Region_Metadata;
      Announcement     : A11y.Live_Regions.Announcement;
      Has_Announcement : Boolean;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
      return Live_Region_Event_Payload
   is
      Metadata_Result : constant A11y.Results.Result :=
        A11y.Live_Regions.Validate (Metadata);
   begin
      if not Is_Live_Region_Event (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Live_Region_Payload;
      end if;

      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Empty_Live_Region_Payload;
      elsif A11y.Results.Failed (Metadata_Result) then
         Result := Metadata_Result;
         return Empty_Live_Region_Payload;
      elsif Kind = Announcement_Requested and then not Has_Announcement then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Live_Region_Payload;
      elsif Kind = Live_Region_Changed and then Has_Announcement then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Live_Region_Payload;
      elsif not Has_Announcement and then Length (Announcement.Text) > 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Live_Region_Payload;
      elsif Has_Announcement and then Length (Announcement.Text) = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Live_Region_Payload;
      elsif Has_Announcement
        and then A11y.Resource_Limits.Exceeded
          (Limits,
           A11y.Resource_Limits.Text_Returned,
           Length (Announcement.Text))
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Live_Region_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Metadata         => Metadata,
         Announcement     =>
           (if Kind = Announcement_Requested
            then Announcement
            else A11y.Live_Regions.Announcement'
              (Text => Null_Unbounded_String)),
         Has_Announcement =>
           Kind = Announcement_Requested and then Has_Announcement);
   end Validate_Live_Region_Event_Payload;

   function Validate_Live_Region_Event_Payload
     (Kind             : Event_Kind;
      Metadata         : A11y.Live_Regions.Live_Region_Metadata;
      Announcement     : A11y.Live_Regions.Announcement;
      Has_Announcement : Boolean;
      Result           : out A11y.Results.Result)
      return Live_Region_Event_Payload is
     (Validate_Live_Region_Event_Payload
        (Kind,
         Metadata,
         Announcement,
         Has_Announcement,
         A11y.Resource_Limits.Default_Config,
         Result));

   function Validate_Live_Region_Event_Payload
     (Kind    : Event_Kind;
      Payload : Live_Region_Event_Payload;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Live_Region_Event_Payload is
     (Validate_Live_Region_Event_Payload
        (Kind             => Kind,
         Metadata         => Payload.Metadata,
         Announcement     => Payload.Announcement,
         Has_Announcement => Payload.Has_Announcement,
         Limits           => Limits,
         Result           => Result));

   function Validate_Live_Region_Event_Payload
     (Kind    : Event_Kind;
      Payload : Live_Region_Event_Payload;
      Result  : out A11y.Results.Result)
      return Live_Region_Event_Payload is
     (Validate_Live_Region_Event_Payload
        (Kind,
         Payload,
         A11y.Resource_Limits.Default_Config,
         Result));

   function Validate_Tree_Event_Payload
     (Kind      : Event_Kind;
      Parent    : A11y.Node_Ids.Node_Id;
      Child     : A11y.Node_Ids.Node_Id;
      Has_Child : Boolean;
      Index     : Positive;
      Has_Index : Boolean;
      Result    : out A11y.Results.Result)
      return Tree_Event_Payload
   is
   begin
      if Kind not in Child_Added | Child_Removed |
                     Children_Reordered | Subtree_Rebuilt
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Tree_Payload;
      elsif not A11y.Node_Ids.Is_Valid (Parent) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Tree_Payload;
      elsif Kind in Child_Added | Child_Removed then
         if not Has_Child
           or else not A11y.Node_Ids.Is_Valid (Child)
           or else not Has_Index
           or else Child = Parent
         then
            Result := (Status => A11y.Results.Invalid_Argument);
            return Empty_Tree_Payload;
         end if;
      elsif Has_Child or else Has_Index then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Tree_Payload;
      elsif Child /= A11y.Node_Ids.No_Node
        or else Index /= Positive'First
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Tree_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Parent    => Parent,
         Child     => (if Has_Child then Child else A11y.Node_Ids.No_Node),
         Has_Child => Has_Child,
         Index     => (if Has_Index then Index else Positive'First),
         Has_Index => Has_Index);
   end Validate_Tree_Event_Payload;

   function Validate_Tree_Event_Payload
     (Kind    : Event_Kind;
      Payload : Tree_Event_Payload;
      Result  : out A11y.Results.Result)
      return Tree_Event_Payload is
     (Validate_Tree_Event_Payload
        (Kind      => Kind,
         Parent    => Payload.Parent,
         Child     => Payload.Child,
         Has_Child => Payload.Has_Child,
         Index     => Payload.Index,
         Has_Index => Payload.Has_Index,
         Result    => Result));

   function Validate_Table_Event_Payload
     (Kind       : Event_Kind;
      Table      : A11y.Node_Ids.Node_Id;
      Item       : A11y.Node_Ids.Node_Id;
      Has_Item   : Boolean;
      Row        : A11y.Tables.Logical_Index;
      Has_Row    : Boolean;
      Column     : A11y.Tables.Logical_Index;
      Has_Column : Boolean;
      Result     : out A11y.Results.Result)
      return Table_Event_Payload
   is
   begin
      if not Is_Table_Event (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif not A11y.Node_Ids.Is_Valid (Table) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif Has_Item and then not A11y.Node_Ids.Is_Valid (Item) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif Has_Item and then Item = Table then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif not Has_Item and then Item /= A11y.Node_Ids.No_Node then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif not Has_Row and then Row /= 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif not Has_Column and then Column /= 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Table_Payload;
      elsif Kind in Row_Inserted | Row_Removed then
         if not Has_Row or else Has_Item or else Has_Column then
            Result := (Status => A11y.Results.Invalid_Argument);
            return Empty_Table_Payload;
         end if;
      elsif Kind in Column_Inserted | Column_Removed then
         if not Has_Column or else Has_Item or else Has_Row then
            Result := (Status => A11y.Results.Invalid_Argument);
            return Empty_Table_Payload;
         end if;
      elsif Kind = Cell_Changed then
         if not Has_Item or else not Has_Row or else not Has_Column then
            Result := (Status => A11y.Results.Invalid_Argument);
            return Empty_Table_Payload;
         end if;
      end if;

      Result := A11y.Results.Ok;
      return
        (Table      => Table,
         Item       => (if Has_Item then Item else A11y.Node_Ids.No_Node),
         Has_Item   => Has_Item,
         Row        => (if Has_Row then Row else 0),
         Has_Row    => Has_Row,
         Column     => (if Has_Column then Column else 0),
         Has_Column => Has_Column);
   end Validate_Table_Event_Payload;

   function Validate_Table_Event_Payload
     (Kind    : Event_Kind;
      Payload : Table_Event_Payload;
      Result  : out A11y.Results.Result)
      return Table_Event_Payload is
     (Validate_Table_Event_Payload
        (Kind       => Kind,
         Table      => Payload.Table,
         Item       => Payload.Item,
         Has_Item   => Payload.Has_Item,
         Row        => Payload.Row,
         Has_Row    => Payload.Has_Row,
         Column     => Payload.Column,
         Has_Column => Payload.Has_Column,
         Result     => Result));

   function Validate_Document_Event_Payload
     (Kind        : Event_Kind;
      Document    : A11y.Node_Ids.Node_Id;
      Surface     : A11y.Node_Ids.Node_Id;
      Has_Surface : Boolean;
      Result      : out A11y.Results.Result)
      return Document_Event_Payload
   is
   begin
      if not Is_Document_Event (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Document_Payload;
      elsif not A11y.Node_Ids.Is_Valid (Document) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Document_Payload;
      elsif Has_Surface and then not A11y.Node_Ids.Is_Valid (Surface) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Document_Payload;
      elsif not Has_Surface and then Surface /= A11y.Node_Ids.No_Node then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Document_Payload;
      elsif Has_Surface and then Surface = Document then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Document_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Document    => Document,
         Surface     =>
           (if Has_Surface then Surface else A11y.Node_Ids.No_Node),
         Has_Surface => Has_Surface);
   end Validate_Document_Event_Payload;

   function Validate_Document_Event_Payload
     (Kind    : Event_Kind;
      Payload : Document_Event_Payload;
      Result  : out A11y.Results.Result)
      return Document_Event_Payload is
     (Validate_Document_Event_Payload
        (Kind        => Kind,
         Document    => Payload.Document,
         Surface     => Payload.Surface,
         Has_Surface => Payload.Has_Surface,
         Result      => Result));

   function Validate_Window_Event_Payload
     (Kind         : Event_Kind;
      Surface      : A11y.Node_Ids.Node_Id;
      Surface_Kind : A11y.Windows.Surface_Kind;
      Owner        : A11y.Node_Ids.Node_Id;
      Has_Owner    : Boolean;
      Result       : out A11y.Results.Result)
      return Window_Event_Payload
   is
   begin
      if not Is_Window_Event (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Window_Payload;
      elsif not A11y.Node_Ids.Is_Valid (Surface) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Window_Payload;
      elsif Has_Owner and then not A11y.Node_Ids.Is_Valid (Owner) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Window_Payload;
      elsif not Has_Owner and then Owner /= A11y.Node_Ids.No_Node then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Window_Payload;
      elsif Has_Owner and then Owner = Surface then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Window_Payload;
      end if;

      Result := A11y.Results.Ok;
      return
        (Surface   => Surface,
         Kind      => Surface_Kind,
         Owner     => (if Has_Owner then Owner else A11y.Node_Ids.No_Node),
         Has_Owner => Has_Owner);
   end Validate_Window_Event_Payload;

   function Validate_Window_Event_Payload
     (Kind    : Event_Kind;
      Payload : Window_Event_Payload;
      Result  : out A11y.Results.Result)
      return Window_Event_Payload is
     (Validate_Window_Event_Payload
        (Kind         => Kind,
         Surface      => Payload.Surface,
         Surface_Kind => Payload.Kind,
         Owner        => Payload.Owner,
         Has_Owner    => Payload.Has_Owner,
         Result       => Result));

end A11y.Events;
