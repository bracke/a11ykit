package body A11y.Windows_Backend.UIA_Events is
   use type A11y.Events.Event_Kind;
   use type A11y.Native_Object_Caches.Native_Object_Id;
   use type A11y.Results.Status_Code;

   function Empty_Emission
     (Status : A11y.Results.Status_Code)
      return UIA_Event_Emission is
     ((Publishable => False, Status => Status));

   function Has_Native_Object
     (Emission : UIA_Event_Emission)
      return Boolean is
   begin
      if not Emission.Publishable then
         return False;
      end if;

      return Emission.Native_Object /= A11y.Native_Object_Caches.No_Object;
   end Has_Native_Object;

   procedure Finish_Report
     (Event                  : A11y.Events.Event;
      Prepared_Input         : Boolean;
      Prepared_Has_Object    : Boolean;
      Prepared_Destroys_Node : Boolean;
      Emission               : UIA_Event_Emission;
      Report                 : out Event_Build_Report)
   is
      Envelope_Result : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
   begin
      Report :=
        (Source                  => Event.Source,
         Sequence                => Event.Sequence,
         Revision                => Event.Revision,
         Envelope_Valid          => not A11y.Results.Failed (Envelope_Result),
         Prepared_Input          => Prepared_Input,
         Prepared_Has_Object     => Prepared_Has_Object,
         Prepared_Destroys_Node  => Prepared_Destroys_Node,
         Native_Object_Resolved  =>
           Prepared_Input and then Has_Native_Object (Emission),
         Publishable             => Emission.Publishable,
         Status                  => Emission.Status);
   end Finish_Report;

   function Queue_Length (Queue : Event_Emission_Queue) return Natural is
     (Natural (Queue.Items.Length));

   function Queue_Capacity (Queue : Event_Emission_Queue) return Natural is
     (Queue.Limit);

   function Queue_Overflowed (Queue : Event_Emission_Queue) return Boolean is
     (Queue.Had_Overflow);

   function Posting_Interest
     (Queue : Event_Emission_Queue)
      return Queue_Posting_Interest
   is
      Length : constant Natural := Queue_Length (Queue);
      Capacity : constant Natural := Queue_Capacity (Queue);
      Overflowed : constant Boolean := Queue_Overflowed (Queue);
      Operation : Queue_Posting_Operation := No_Posting_Operation;
   begin
      if Overflowed then
         Operation := Back_Pressure;
      elsif Length /= 0 then
         Operation := Post_Next_Event;
      end if;

      return
        (Can_Post       => Length /= 0 and then not Overflowed,
         Has_Pending    => Length /= 0,
         Overflowed     => Overflowed,
         Length         => Length,
         Capacity       => Capacity,
         Next_Operation => Operation);
   exception
      when others =>
         return (others => <>);
   end Posting_Interest;

   procedure Configure_Queue
     (Queue  : in out Event_Emission_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      end if;

      Set_Queue_Capacity
        (Queue,
         Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Native_Array_Size)),
         Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Configure_Queue;

   procedure Set_Queue_Capacity
     (Queue    : in out Event_Emission_Queue;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Capacity = 0 or else Capacity > Max_Queued_Events then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Capacity < Natural (Queue.Items.Length) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Queue.Limit := Capacity;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Set_Queue_Capacity;

   procedure Enqueue
     (Queue    : in out Event_Emission_Queue;
      Emission : UIA_Event_Emission;
      Result   : out A11y.Results.Result)
   is
   begin
      if not Emission.Publishable then
         Result := (Status => Emission.Status);
      elsif Natural (Queue.Items.Length) >= Queue.Limit then
         Queue.Had_Overflow := True;
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Queue.Items.Append (Emission);
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Enqueue;

   procedure Enqueue_Prepared_Event
     (Queue    : in out Event_Emission_Queue;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Report : Prepared_Enqueue_Report;
   begin
      Enqueue_Prepared_Event_With_Report
        (Queue, Prepared, Report, Result);
   end Enqueue_Prepared_Event;

   procedure Enqueue_Prepared_Event_With_Report
     (Queue    : in out Event_Emission_Queue;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Report   : out Prepared_Enqueue_Report;
      Result   : out A11y.Results.Result)
   is
      Emission : UIA_Event_Emission :=
        Empty_Emission (Prepared.Status);
      Validation : constant A11y.Results.Result :=
        A11y.Native_Runtimes.Validate_Prepared_Event (Prepared);
      Before : constant Natural := Queue_Length (Queue);
   begin
      Report :=
        (Source                 => Prepared.Event.Source,
         Sequence               => Prepared.Event.Sequence,
         Revision               => Prepared.Event.Revision,
         Length_Before          => Before,
         Length_After           => Before,
         Capacity               => Queue_Capacity (Queue),
         Had_Overflow           => Queue_Overflowed (Queue),
         Prepared_Status        => Prepared.Status,
         Prepared_Validation_Status => Validation.Status,
         Prepared_Has_Object    => Prepared.Has_Object,
         Prepared_Destroys_Node => Prepared.Destroys_Node,
         Build_Publishable      => False,
         Native_Object_Resolved => False,
         Enqueued               => False,
         Status                 => Validation.Status);

      if A11y.Results.Failed (Validation) then
         Result := Validation;
         Report.Status := Result.Status;
         return;
      end if;

      Emission := Build_Prepared_Event (Prepared);
      Report.Build_Publishable := Emission.Publishable;
      Report.Native_Object_Resolved := Has_Native_Object (Emission);
      Report.Status := Emission.Status;

      if not Emission.Publishable then
         Result := (Status => Emission.Status);
         return;
      end if;

      Enqueue (Queue, Emission, Result);
      Report.Length_After := Queue_Length (Queue);
      Report.Had_Overflow := Queue_Overflowed (Queue);
      Report.Enqueued := A11y.Results.Succeeded (Result);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
   end Enqueue_Prepared_Event_With_Report;

   procedure Peek
     (Queue    : Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Result   : out A11y.Results.Result)
   is
   begin
      if Queue.Items.Is_Empty then
         Emission := Empty_Emission (A11y.Results.Node_Unavailable);
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Emission := Queue.Items.First_Element;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Emission := Empty_Emission (A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Peek;

   procedure Dequeue
     (Queue    : in out Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Result   : out A11y.Results.Result)
   is
   begin
      if Queue.Items.Is_Empty then
         Emission := Empty_Emission (A11y.Results.Node_Unavailable);
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Emission := Queue.Items.First_Element;
         Queue.Items.Delete_First;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Emission := Empty_Emission (A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Dequeue;

   function Posting_Rejection
     (Interest : Queue_Posting_Interest)
      return A11y.Results.Status_Code
   is
   begin
      if Interest.Overflowed then
         return A11y.Results.Resource_Limit;
      elsif not Interest.Has_Pending then
         return A11y.Results.Node_Unavailable;
      else
         return A11y.Results.Invalid_State;
      end if;
   end Posting_Rejection;

   procedure Dequeue_For_Posting
     (Queue    : in out Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Result   : out A11y.Results.Result)
   is
      Report : Posting_Attempt_Report;
   begin
      Dequeue_For_Posting_With_Report (Queue, Emission, Report, Result);
   end Dequeue_For_Posting;

   procedure Dequeue_For_Posting_With_Report
     (Queue    : in out Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Report   : out Posting_Attempt_Report;
      Result   : out A11y.Results.Result)
   is
      Interest : constant Queue_Posting_Interest := Posting_Interest (Queue);
   begin
      Report :=
        (Source         => A11y.Node_Ids.No_Node,
         Sequence       => A11y.No_Event,
         Revision       => A11y.Initial_Revision,
         Length_Before  => Interest.Length,
         Length_After   => Interest.Length,
         Capacity       => Interest.Capacity,
         Had_Pending    => Interest.Has_Pending,
         Had_Overflow   => Interest.Overflowed,
         Admitted       => Interest.Can_Post,
         Emission_Taken => False,
         Next_Operation => Interest.Next_Operation,
         Status         => A11y.Results.Node_Unavailable);

      if not Interest.Can_Post then
         Report.Status := Posting_Rejection (Interest);
         Emission := Empty_Emission (Report.Status);
         Result := (Status => Report.Status);
         return;
      end if;

      Dequeue (Queue, Emission, Result);
      Report.Emission_Taken := A11y.Results.Succeeded (Result);
      if Report.Emission_Taken and then Emission.Publishable then
         Report.Source := Emission.Source;
         Report.Sequence := Emission.Sequence;
         Report.Revision := Emission.Revision;
      end if;
      Report.Length_After := Queue_Length (Queue);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Emission := Empty_Emission (A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := A11y.Results.Internal_Error;
   end Dequeue_For_Posting_With_Report;

   procedure Drain_For_Posting_Bounded
     (Queue        : in out Event_Emission_Queue;
      Max_Attempts : Natural;
      Poster       : not null access procedure
        (Emission : UIA_Event_Emission;
         Result   : out A11y.Results.Result);
      Report       : out Posting_Drain_Report;
      Result       : out A11y.Results.Result)
   is
      Initial_Interest : constant Queue_Posting_Interest :=
        Posting_Interest (Queue);
      Interest         : Queue_Posting_Interest := Initial_Interest;
      Emission         : UIA_Event_Emission;
      Attempt          : Posting_Attempt_Report;
      Callback_Result  : A11y.Results.Result;
   begin
      Report :=
        (Last_Source   => A11y.Node_Ids.No_Node,
         Last_Sequence => A11y.No_Event,
         Last_Revision => A11y.Initial_Revision,
         Attempt_Limit => Max_Attempts,
         Attempts      => 0,
         Posted        => 0,
         Length_Before => Initial_Interest.Length,
         Length_After  => Initial_Interest.Length,
         Capacity      => Initial_Interest.Capacity,
         Had_Overflow  => Initial_Interest.Overflowed,
         Stop_Reason   => Not_Stopped,
         Last_Status   => A11y.Results.Node_Unavailable);

      if Max_Attempts = 0 then
         Report.Stop_Reason := Invalid_Request;
         Report.Last_Status := A11y.Results.Invalid_Argument;
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      while Report.Attempts < Max_Attempts loop
         Interest := Posting_Interest (Queue);

         if not Interest.Can_Post then
            Report.Length_After := Interest.Length;
            Report.Had_Overflow :=
              Report.Had_Overflow or else Interest.Overflowed;
            if Interest.Overflowed then
               Report.Stop_Reason := Back_Pressure;
               Report.Last_Status := A11y.Results.Resource_Limit;
               Result := (Status => A11y.Results.Resource_Limit);
            else
               Report.Stop_Reason := No_Pending;
               Report.Last_Status := A11y.Results.Success;
               Result := A11y.Results.Ok;
            end if;
            return;
         end if;

         Dequeue_For_Posting_With_Report
           (Queue, Emission, Attempt, Result);
         Report.Length_After := Attempt.Length_After;
         Report.Had_Overflow :=
           Report.Had_Overflow or else Attempt.Had_Overflow;

         if A11y.Results.Failed (Result) then
            Report.Stop_Reason :=
              (if Result.Status = A11y.Results.Resource_Limit
               then Back_Pressure
               else Callback_Failed);
            Report.Last_Status := Result.Status;
            return;
         end if;

         Report.Attempts := Report.Attempts + 1;
         if Attempt.Emission_Taken then
            Report.Last_Source := Attempt.Source;
            Report.Last_Sequence := Attempt.Sequence;
            Report.Last_Revision := Attempt.Revision;
         end if;

         begin
            Poster.all (Emission, Callback_Result);
         exception
            when others =>
               Callback_Result :=
                 (Status => A11y.Results.Internal_Error);
         end;

         if A11y.Results.Failed (Callback_Result) then
            Report.Stop_Reason := Callback_Failed;
            Report.Last_Status := Callback_Result.Status;
            Result := Callback_Result;
            return;
         end if;

         Report.Posted := Report.Posted + 1;
         Report.Last_Status := A11y.Results.Success;
      end loop;

      Interest := Posting_Interest (Queue);
      Report.Length_After := Interest.Length;
      Report.Had_Overflow :=
        Report.Had_Overflow or else Interest.Overflowed;
      if Interest.Has_Pending then
         Report.Stop_Reason := Iteration_Limit_Reached;
      else
         Report.Stop_Reason := No_Pending;
      end if;
      Report.Last_Status := A11y.Results.Success;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Report := (others => <>);
         Report.Stop_Reason := Callback_Failed;
         Report.Last_Status := A11y.Results.Internal_Error;
         Result := (Status => A11y.Results.Internal_Error);
   end Drain_For_Posting_Bounded;

   procedure Clear (Queue : in out Event_Emission_Queue) is
   begin
      Queue.Items.Clear;
      Queue.Had_Overflow := False;
   end Clear;

   function Validate_For_Posting
     (Emission : UIA_Event_Emission)
      return A11y.Results.Result
   is
      Is_Destruction : constant Boolean :=
        Emission.Publishable
        and then Emission.Kind = Automation_Structure_Changed
        and then Emission.Structure = Child_Removed_Event;
   begin
      if not Emission.Publishable then
         return (Status => Emission.Status);
      elsif not A11y.Node_Ids.Is_Valid (Emission.Source)
        or else Emission.Sequence = A11y.No_Event
      then
         return (Status => A11y.Results.Invalid_Argument);
      elsif not Is_Destruction
        and then not A11y.Native_Object_Caches.Is_Valid
          (Emission.Native_Object)
      then
         return (Status => A11y.Results.Node_Unavailable);
      elsif Emission.Kind = Automation_Property_Changed
        and then Emission.Property = No_Property_Event
      then
         return (Status => A11y.Results.Unsupported_Property);
      elsif Emission.Kind = Automation_Structure_Changed
        and then Emission.Structure = No_Structure_Event
      then
         return (Status => A11y.Results.Unsupported_Property);
      elsif Emission.Kind in Automation_Window_Opened |
          Automation_Window_Closed
        and then Emission.Window = No_Window_Event
      then
         return (Status => A11y.Results.Unsupported_Property);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Validate_For_Posting;

   function Map_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Event_Kind is
     (case Kind is
        when A11y.Events.Focus_Changed =>
          Automation_Focus_Changed,
        when A11y.Events.Property_Changed |
             A11y.Events.State_Changed |
             A11y.Events.Value_Changed |
             A11y.Events.Range_Changed |
             A11y.Events.Bounds_Changed |
             A11y.Events.Current_Item_Changed |
             A11y.Events.Active_Descendant_Changed |
             A11y.Events.Relation_Added |
             A11y.Events.Relation_Removed |
             A11y.Events.Relation_Targets_Changed =>
          Automation_Property_Changed,
        when A11y.Events.Node_Created |
             A11y.Events.Node_Destroyed |
             A11y.Events.Node_Attached |
             A11y.Events.Node_Detached |
             A11y.Events.Child_Added |
             A11y.Events.Child_Removed |
             A11y.Events.Children_Reordered |
             A11y.Events.Subtree_Rebuilt |
             A11y.Events.Row_Inserted |
             A11y.Events.Row_Removed |
             A11y.Events.Column_Inserted |
             A11y.Events.Column_Removed |
             A11y.Events.Cell_Changed |
             A11y.Events.Document_Loaded |
             A11y.Events.Document_Closed =>
          Automation_Structure_Changed,
        when A11y.Events.Selection_Changed =>
          Automation_Selection_Invalidated,
        when A11y.Events.Text_Inserted |
             A11y.Events.Text_Removed |
             A11y.Events.Text_Replaced |
             A11y.Events.Text_Attributes_Changed =>
          Automation_Text_Changed,
        when A11y.Events.Caret_Moved |
             A11y.Events.Text_Selection_Changed =>
          Automation_Text_Selection_Changed,
        when A11y.Events.Live_Region_Changed =>
          Automation_Live_Region_Changed,
        when A11y.Events.Announcement_Requested =>
          Automation_Notification,
        when A11y.Events.Window_Opened =>
          Automation_Window_Opened,
        when A11y.Events.Window_Closed =>
          Automation_Window_Closed,
        when A11y.Events.Window_Activated |
             A11y.Events.Window_Deactivated =>
          Automation_Layout_Invalidated);

   function Map_Property_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Property_Event is
     (case Kind is
        when A11y.Events.Property_Changed =>
          Name_Property,
        when A11y.Events.State_Changed =>
          Is_Enabled_Property,
        when A11y.Events.Focus_Changed =>
          Has_Keyboard_Focus_Property,
        when A11y.Events.Bounds_Changed =>
          Bounding_Rectangle_Property,
        when A11y.Events.Value_Changed =>
          Value_Property,
        when A11y.Events.Range_Changed =>
          Range_Value_Property,
        when A11y.Events.Selection_Changed |
             A11y.Events.Current_Item_Changed =>
          Selection_Property,
        when A11y.Events.Active_Descendant_Changed =>
          Active_Descendant_Property,
        when A11y.Events.Relation_Added |
             A11y.Events.Relation_Removed |
             A11y.Events.Relation_Targets_Changed =>
          Relation_Property,
        when A11y.Events.Live_Region_Changed =>
          Live_Setting_Property,
        when others =>
          No_Property_Event);

   function Map_Property_Event
     (Property : A11y.Properties.Property_Id)
      return UIA_Property_Event is
     (case Property is
        when A11y.Properties.Accessible_Name |
             A11y.Properties.Visible_Title =>
          Name_Property,
        when A11y.Properties.Description =>
          Description_Property,
        when A11y.Properties.Help_Text =>
          Help_Text_Property,
        when A11y.Properties.Placeholder =>
          Placeholder_Property,
        when A11y.Properties.Value_Text =>
          Value_Property,
        when A11y.Properties.Keyboard_Shortcut =>
          Help_Text_Property,
        when A11y.Properties.Semantic_Identifier =>
          Automation_Id_Property,
        when A11y.Properties.Locale =>
          No_Property_Event,
        when A11y.Properties.Bounds =>
          Bounding_Rectangle_Property,
        when A11y.Properties.Orientation =>
          Orientation_Property,
        when A11y.Properties.Set_Position =>
          Position_In_Set_Property,
        when A11y.Properties.Set_Size =>
          Size_Of_Set_Property,
        when A11y.Properties.Hierarchical_Level =>
          Level_Property,
        when A11y.Properties.Heading_Level =>
          Heading_Level_Property,
        when A11y.Properties.Landmark =>
          Landmark_Type_Property,
        when A11y.Properties.Role_Property =>
          Localized_Control_Type_Property,
        when A11y.Properties.State_Property =>
          Is_Enabled_Property);

   function Map_State_Event
     (State : A11y.States.State_Flag)
      return UIA_Property_Event is
     (case State is
        when A11y.States.Enabled |
             A11y.States.Sensitive =>
          Is_Enabled_Property,
        when A11y.States.Focused =>
          Has_Keyboard_Focus_Property,
        when A11y.States.Focusable =>
          Is_Keyboard_Focusable_Property,
        when A11y.States.Visible |
             A11y.States.Showing |
             A11y.States.Offscreen =>
          Is_Offscreen_Property,
        when A11y.States.Selected |
             A11y.States.Selectable |
             A11y.States.Multi_Selectable =>
          Selection_Property,
        when A11y.States.Checked |
             A11y.States.Indeterminate |
             A11y.States.Pressed =>
          Value_Property,
        when A11y.States.Expanded |
             A11y.States.Expandable =>
          Value_Property,
        when A11y.States.Read_Only |
             A11y.States.Editable =>
          Value_Property,
        when A11y.States.Required =>
          Is_Required_For_Form_Property,
        when A11y.States.Invalid |
             A11y.States.Busy |
             A11y.States.Modal |
             A11y.States.Multi_Line |
             A11y.States.Visited |
             A11y.States.Defunct |
             A11y.States.Active =>
          No_Property_Event);

   function Map_Structure_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Structure_Event is
     (case Kind is
        when A11y.Events.Node_Created |
             A11y.Events.Node_Attached |
             A11y.Events.Child_Added =>
          Child_Added_Event,
        when A11y.Events.Node_Destroyed |
             A11y.Events.Node_Detached |
             A11y.Events.Child_Removed =>
          Child_Removed_Event,
        when A11y.Events.Children_Reordered =>
          Children_Reordered_Event,
        when A11y.Events.Subtree_Rebuilt =>
          Subtree_Rebuilt_Event,
        when A11y.Events.Row_Inserted =>
          Row_Inserted_Event,
        when A11y.Events.Row_Removed =>
          Row_Removed_Event,
        when A11y.Events.Column_Inserted =>
          Column_Inserted_Event,
        when A11y.Events.Column_Removed =>
          Column_Removed_Event,
        when A11y.Events.Cell_Changed =>
          Cell_Changed_Event,
        when A11y.Events.Document_Loaded =>
          Document_Loaded_Event,
        when A11y.Events.Document_Closed =>
          Document_Closed_Event,
        when others =>
          No_Structure_Event);

   function Map_Window_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Window_Event is
     (case Kind is
        when A11y.Events.Window_Opened =>
          Window_Opened_Event,
        when A11y.Events.Window_Closed =>
          Window_Closed_Event,
        when A11y.Events.Window_Activated =>
          Window_Activated_Event,
        when A11y.Events.Window_Deactivated =>
          Window_Deactivated_Event,
        when others =>
          No_Window_Event);

   function Build_Event
     (Event : A11y.Events.Event)
      return UIA_Event_Emission is
      Result : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
   begin
      if A11y.Results.Failed (Result) then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Event.Source,
         Native_Object => A11y.Native_Object_Caches.No_Object,
         Kind        => Map_Event (Event.Kind),
         Property    => Map_Property_Event (Event.Kind),
         Structure   => Map_Structure_Event (Event.Kind),
         Window      => Map_Window_Event (Event.Kind),
         Relation    => A11y.Windows_Backend.UIA_Mappings.Unsupported_Relation,
         Has_Bounds_Payload => False,
         Old_Bounds => A11y.Geometry.Empty_Rectangle,
         New_Bounds => A11y.Geometry.Empty_Rectangle,
         Has_Focus_Payload => False,
         Old_Focus => A11y.Node_Ids.No_Node,
         New_Focus => A11y.Node_Ids.No_Node,
         Has_Node_Reference_Payload => False,
         Old_Reference => A11y.Node_Ids.No_Node,
         New_Reference => A11y.Node_Ids.No_Node,
         Has_Value_Payload => False,
         Old_Value => (Kind => A11y.Values.Unknown),
         New_Value => (Kind => A11y.Values.Unknown),
         Has_Selection_Payload => False,
         Selection_Node => A11y.Node_Ids.No_Node,
         Selection_Has_Node => False,
         Selection_Old_Selected => False,
         Selection_New_Selected => False,
         Selection_Required => False,
         Has_Live_Region_Payload => False,
         Live_Region_Payload => <>,
         Has_Tree_Payload => False,
         Tree_Payload => <>,
         Has_Table_Payload => False,
         Table_Payload => <>,
         Has_Document_Payload => False,
         Document_Payload => <>,
         Has_Window_Payload => False,
         Window_Payload => <>,

         Sequence    => Event.Sequence,
         Revision    => Event.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Prepared_Event
     (Prepared : A11y.Native_Runtimes.Prepared_Event)
      return UIA_Event_Emission
   is
      Validation : constant A11y.Results.Result :=
        A11y.Native_Runtimes.Validate_Prepared_Event (Prepared);
      Emission : UIA_Event_Emission;
   begin
      if A11y.Results.Failed (Validation) then
         return
           (Publishable => False,
            Status      => Validation.Status);
      end if;

      if Prepared.Has_Property_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Property_Payload);
      elsif Prepared.Has_State_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.State_Payload);
      elsif Prepared.Has_Bounds_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Bounds_Payload);
      elsif Prepared.Has_Value_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Value_Payload);
      elsif Prepared.Has_Selection_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Selection_Payload);
      elsif Prepared.Has_Relation_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Relation_Payload);
      elsif Prepared.Has_Focus_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Focus_Payload);
      elsif Prepared.Has_Node_Reference_Payload then
         Emission :=
           Build_Event (Prepared.Event, Prepared.Node_Reference_Payload);
      elsif Prepared.Has_Live_Region_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Live_Region_Payload);
      elsif Prepared.Has_Tree_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Tree_Payload);
      elsif Prepared.Has_Table_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Table_Payload);
      elsif Prepared.Has_Document_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Document_Payload);
      elsif Prepared.Has_Window_Payload then
         Emission := Build_Event (Prepared.Event, Prepared.Window_Payload);
      else
         Emission := Build_Event (Prepared.Event);
      end if;
      if Emission.Publishable and then Prepared.Has_Object then
         Emission.Native_Object := Prepared.Object;
      end if;
      return Emission;
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Prepared_Event;

   procedure Build_Event_With_Report
     (Event    : A11y.Events.Event;
      Emission : out UIA_Event_Emission;
      Report   : out Event_Build_Report) is
   begin
      Emission := Build_Event (Event);
      Finish_Report
        (Event                  => Event,
         Prepared_Input         => False,
         Prepared_Has_Object    => False,
         Prepared_Destroys_Node => False,
         Emission               => Emission,
         Report                 => Report);
   end Build_Event_With_Report;

   procedure Build_Prepared_Event_With_Report
     (Prepared : A11y.Native_Runtimes.Prepared_Event;
      Emission : out UIA_Event_Emission;
      Report   : out Event_Build_Report) is
   begin
      Emission := Build_Prepared_Event (Prepared);
      Finish_Report
        (Event                  => Prepared.Event,
         Prepared_Input         => True,
         Prepared_Has_Object    => Prepared.Has_Object,
         Prepared_Destroys_Node => Prepared.Destroys_Node,
         Emission               => Emission,
         Report                 => Report);
   end Build_Prepared_Event_With_Report;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Property_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result := A11y.Results.Ok;
      Validated_Payload : A11y.Events.Property_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated_Payload := A11y.Events.Validate_Property_Event_Payload
        (Kind    => Event.Kind,
         Payload => Payload,
         Result  => Result);

      if Result.Status /= A11y.Results.Success then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      declare
         Property : constant UIA_Property_Event :=
           Map_Property_Event (Validated_Payload.Property);
      begin
         if Property = No_Property_Event then
            return
              (Publishable => False,
               Status      => A11y.Results.Unsupported_Property);
         end if;

         return
           (Publishable => True,
            Status      => A11y.Results.Success,
            Source      => Emission.Source,
            Native_Object => Emission.Native_Object,
            Kind        => Emission.Kind,
            Property    => Property,
            Structure   => Emission.Structure,
            Window      => Emission.Window,
            Relation    => Emission.Relation,
            Has_Bounds_Payload => Emission.Has_Bounds_Payload,
            Old_Bounds => Emission.Old_Bounds,
            New_Bounds => Emission.New_Bounds,
            Has_Focus_Payload => Emission.Has_Focus_Payload,
            Old_Focus => Emission.Old_Focus,
            New_Focus => Emission.New_Focus,
            Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
            Old_Reference => Emission.Old_Reference,
            New_Reference => Emission.New_Reference,
            Has_Value_Payload => Emission.Has_Value_Payload,
            Old_Value => Emission.Old_Value,
            New_Value => Emission.New_Value,
            Has_Selection_Payload => Emission.Has_Selection_Payload,
            Selection_Node => Emission.Selection_Node,
            Selection_Has_Node => Emission.Selection_Has_Node,
            Selection_Old_Selected => Emission.Selection_Old_Selected,
            Selection_New_Selected => Emission.Selection_New_Selected,
            Selection_Required => Emission.Selection_Required,
            Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
            Live_Region_Payload => Emission.Live_Region_Payload,
            Has_Tree_Payload => Emission.Has_Tree_Payload,
            Tree_Payload => Emission.Tree_Payload,
            Has_Table_Payload => Emission.Has_Table_Payload,
            Table_Payload => Emission.Table_Payload,
            Has_Document_Payload => Emission.Has_Document_Payload,
            Document_Payload => Emission.Document_Payload,
            Has_Window_Payload => Emission.Has_Window_Payload,
            Window_Payload => Emission.Window_Payload,
            Sequence    => Emission.Sequence,
            Revision    => Emission.Revision);
      end;
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.State_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result := A11y.Results.Ok;
      Validated_Payload : A11y.Events.State_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated_Payload := A11y.Events.Validate_State_Event_Payload
        (Kind    => Event.Kind,
         Payload => Payload,
         Result  => Result);

      if Result.Status /= A11y.Results.Success then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Map_State_Event (Validated_Payload.State),
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Relation_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Relation_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Relation_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return (Publishable => False, Status => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Relation_Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => A11y.Windows_Backend.UIA_Mappings.Map_Relation
           (Validated.Relation),
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Bounds_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Bounds_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Bounds_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return (Publishable => False, Status => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Bounding_Rectangle_Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => True,
         Old_Bounds => Validated.Old_Bounds,
         New_Bounds => Validated.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Focus_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Focus_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Focus_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return (Publishable => False, Status => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Automation_Focus_Changed,
         Property    => Has_Keyboard_Focus_Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => True,
         Old_Focus => Validated.Old_Focus,
         New_Focus => Validated.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Node_Reference_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Node_Reference_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Node_Reference_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return (Publishable => False, Status => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Map_Property_Event (Event.Kind),
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => True,
         Old_Reference => Validated.Old_Node,
         New_Reference => Validated.New_Node,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Value_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result := A11y.Results.Ok;
      Validated_Payload : A11y.Events.Value_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated_Payload := A11y.Events.Validate_Value_Event_Payload
        (Kind    => Event.Kind,
         Payload => Payload,
         Result  => Result);

      if Result.Status /= A11y.Results.Success then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Map_Property_Event (Event.Kind),
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => True,
         Old_Value => Validated_Payload.Old_Value,
         New_Value => Validated_Payload.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Selection_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Selection_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Selection_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return (Publishable => False, Status => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Emission.Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => True,
         Selection_Node => Validated.Changed_Node,
         Selection_Has_Node => Validated.Has_Changed_Node,
         Selection_Old_Selected => Validated.Old_Selected,
         Selection_New_Selected => Validated.New_Selected,
         Selection_Required => Validated.Requires_Selection,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Live_Region_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Live_Region_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Live_Region_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return (Publishable => False, Status => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Emission.Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => True,
         Live_Region_Payload => Validated,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Tree_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Tree_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Tree_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Emission.Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => True,
         Tree_Payload => Validated,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Table_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Table_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Table_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Emission.Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => True,
         Table_Payload => Validated,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Document_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Document_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Document_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Emission.Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => True,
         Document_Payload => Validated,
         Has_Window_Payload => Emission.Has_Window_Payload,
         Window_Payload => Emission.Window_Payload,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Window_Event_Payload)
      return UIA_Event_Emission
   is
      Emission : constant UIA_Event_Emission := Build_Event (Event);
      Result : A11y.Results.Result;
      Validated : A11y.Events.Window_Event_Payload;
   begin
      if not Emission.Publishable then
         return Emission;
      end if;

      Validated := A11y.Events.Validate_Window_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         return
           (Publishable => False,
            Status      => Result.Status);
      end if;

      return
        (Publishable => True,
         Status      => A11y.Results.Success,
         Source      => Emission.Source,
         Native_Object => Emission.Native_Object,
         Kind        => Emission.Kind,
         Property    => Emission.Property,
         Structure   => Emission.Structure,
         Window      => Emission.Window,
         Relation    => Emission.Relation,
         Has_Bounds_Payload => Emission.Has_Bounds_Payload,
         Old_Bounds => Emission.Old_Bounds,
         New_Bounds => Emission.New_Bounds,
         Has_Focus_Payload => Emission.Has_Focus_Payload,
         Old_Focus => Emission.Old_Focus,
         New_Focus => Emission.New_Focus,
         Has_Node_Reference_Payload => Emission.Has_Node_Reference_Payload,
         Old_Reference => Emission.Old_Reference,
         New_Reference => Emission.New_Reference,
         Has_Value_Payload => Emission.Has_Value_Payload,
         Old_Value => Emission.Old_Value,
         New_Value => Emission.New_Value,
         Has_Selection_Payload => Emission.Has_Selection_Payload,
         Selection_Node => Emission.Selection_Node,
         Selection_Has_Node => Emission.Selection_Has_Node,
         Selection_Old_Selected => Emission.Selection_Old_Selected,
         Selection_New_Selected => Emission.Selection_New_Selected,
         Selection_Required => Emission.Selection_Required,
         Has_Live_Region_Payload => Emission.Has_Live_Region_Payload,
         Live_Region_Payload => Emission.Live_Region_Payload,
         Has_Tree_Payload => Emission.Has_Tree_Payload,
         Tree_Payload => Emission.Tree_Payload,
         Has_Table_Payload => Emission.Has_Table_Payload,
         Table_Payload => Emission.Table_Payload,
         Has_Document_Payload => Emission.Has_Document_Payload,
         Document_Payload => Emission.Document_Payload,
         Has_Window_Payload => True,
         Window_Payload => Validated,
         Sequence    => Emission.Sequence,
         Revision    => Emission.Revision);
   exception
      when others =>
         return
           (Publishable => False,
            Status      => A11y.Results.Internal_Error);
   end Build_Event;

end A11y.Windows_Backend.UIA_Events;
