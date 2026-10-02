with A11y.Event_Queues.Classification;

package body A11y.Event_Queues is
   use type Ada.Calendar.Time;
   use type A11y.Event_Sequence;

   function Next_Timestamp (Self : in out Event_Queue) return A11y.Timestamp is
      Now : constant A11y.Timestamp := Ada.Calendar.Clock;
   begin
      if Now < Self.Last_Timestamp then
         return Self.Last_Timestamp;
      end if;

      Self.Last_Timestamp := Now;
      return Now;
   end Next_Timestamp;

   function Length (Self : Event_Queue) return Natural is
     (Natural (Self.Items.Length));

   function Overflowed (Self : Event_Queue) return Boolean is
     (Self.Had_Overflow);

   function Capacity (Self : Event_Queue) return Natural is
     (Self.Limit);

   function Available_Capacity (Self : Event_Queue) return Natural is
      Current_Length : constant Natural := Natural (Self.Items.Length);
   begin
      return Available_Slots (Current_Length, Self.Limit);
   end Available_Capacity;

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (A11y.Event_Queues.Classification.Valid_Capacity (Capacity))
   with SPARK_Mode => On;

   function Can_Set_Capacity
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean is
     (A11y.Event_Queues.Classification.Can_Set_Capacity
        (Current_Length, Capacity))
   with SPARK_Mode => On;

   function Available_Slots
     (Current_Length : Natural;
      Capacity       : Natural)
      return Natural is
     (A11y.Event_Queues.Classification.Available_Slots
        (Current_Length, Capacity))
   with SPARK_Mode => On;

   function Can_Coalesce
     (Previous_Source : A11y.Node_Ids.Node_Id;
      New_Source      : A11y.Node_Ids.Node_Id;
      Previous_Kind   : A11y.Events.Event_Kind;
      New_Kind        : A11y.Events.Event_Kind)
     return Boolean is
     (A11y.Event_Queues.Classification.Can_Coalesce
        (Previous_Source, New_Source, Previous_Kind, New_Kind))
   with SPARK_Mode => On;

   function Rejects_Destroyed_Source
     (Already_Destroyed : Boolean;
      Kind              : A11y.Events.Event_Kind)
      return Boolean is
     (A11y.Event_Queues.Classification.Rejects_Destroyed_Source
        (Already_Destroyed, Kind))
   with SPARK_Mode => On;

   function Destroyed_Source_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code is
     (A11y.Event_Queues.Classification.Destroyed_Source_Status (Kind))
   with SPARK_Mode => On;

   function Can_Append
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean is
     (A11y.Event_Queues.Classification.Can_Append
        (Current_Length, Capacity))
   with SPARK_Mode => On;

   function Overflows_On_Append
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean is
     (A11y.Event_Queues.Classification.Overflows_On_Append
        (Current_Length, Capacity))
   with SPARK_Mode => On;

   function Can_Advance_Sequence
     (Sequence : A11y.Event_Sequence)
      return Boolean is
     (A11y.Event_Queues.Classification.Can_Advance_Sequence (Sequence))
   with SPARK_Mode => On;

   function Is_Destroyed
     (Self : Event_Queue;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Index : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      return Index in Self.Destroyed'Range and then Self.Destroyed (Index);
   end Is_Destroyed;

   procedure Mark_Destroyed
     (Self : in out Event_Queue;
      Node : A11y.Node_Ids.Node_Id)
   is
      Index : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      if Index in Self.Destroyed'Range then
         Self.Destroyed (Index) := True;
      end if;
   end Mark_Destroyed;

   procedure Configure
     (Self   : in out Event_Queue;
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

      Set_Capacity
        (Self,
         Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Event_Queue_Size)),
         Result);
   end Configure;

   procedure Can_Configure
     (Self   : Event_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Capacity : Natural;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      end if;

      Capacity := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Event_Queue_Size));
      if Can_Set_Capacity
        (Natural (Self.Items.Length), Capacity)
      then
         Result := A11y.Results.Ok;
      elsif Valid_Capacity (Capacity) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Result := (Status => A11y.Results.Invalid_Argument);
      end if;
   end Can_Configure;

   procedure Set_Capacity
     (Self     : in out Event_Queue;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Can_Set_Capacity
        (Natural (Self.Items.Length), Capacity)
      then
         Self.Limit := Capacity;
         Result := A11y.Results.Ok;
      elsif Valid_Capacity (Capacity) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Result := (Status => A11y.Results.Invalid_Argument);
      end if;
   end Set_Capacity;

   procedure Enqueue
     (Self     : in out Event_Queue;
      Source   : A11y.Node_Ids.Node_Id;
      Kind     : A11y.Events.Event_Kind;
      Revision : A11y.Semantic_Revision;
      Event    : out A11y.Events.Event;
      Result   : out A11y.Results.Result)
   is
      Last_Index : Positive;
      Timestamp : constant A11y.Timestamp := Next_Timestamp (Self);
   begin
      Event :=
        (Sequence  => Self.Next_Sequence,
         Timestamp => Timestamp,
         Source    => Source,
         Kind      => Kind,
         Revision  => Revision);

      Result := A11y.Events.Validate_Event (Event);
      if A11y.Results.Failed (Result) then
         Event.Sequence := A11y.No_Event;
         return;
      elsif Rejects_Destroyed_Source
        (Is_Destroyed (Self, Source), Kind)
      then
         Event.Sequence := A11y.No_Event;
         Result :=
           (Status =>
              Destroyed_Source_Status (Kind));
         return;
      end if;

      if A11y.Events.Is_Coalescible (Kind)
        and then not Self.Items.Is_Empty
      then
         Last_Index := Self.Items.Last_Index;
         if Can_Coalesce
           (Self.Items (Last_Index).Source,
            Source,
            Self.Items (Last_Index).Kind,
            Kind)
         then
            Event.Sequence := Self.Items (Last_Index).Sequence;
            Self.Items.Replace_Element (Last_Index, Event);
            Result := A11y.Results.Ok;
            return;
         end if;
      end if;

      if Overflows_On_Append
        (Natural (Self.Items.Length), Self.Limit)
      then
         Self.Had_Overflow := True;
         Event.Sequence := A11y.No_Event;
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      if not Can_Advance_Sequence
        (Self.Next_Sequence)
      then
         Self.Had_Overflow := True;
         Event.Sequence := A11y.No_Event;
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Self.Items.Append (Event);
      if Kind = A11y.Events.Node_Destroyed then
         Mark_Destroyed (Self, Source);
      end if;
      Self.Next_Sequence := Self.Next_Sequence + 1;
      Result := A11y.Results.Ok;
   end Enqueue;

   procedure Dequeue
     (Self   : in out Event_Queue;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result)
   is
   begin
      if Self.Items.Is_Empty then
         Event :=
           (Sequence  => A11y.No_Event,
            Timestamp => Ada.Calendar.Clock,
            Source    => A11y.Node_Ids.No_Node,
            Kind      => A11y.Events.Node_Created,
            Revision  => A11y.Initial_Revision);
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Event := Self.Items.First_Element;
         Self.Items.Delete_First;
         Result := A11y.Results.Ok;
      end if;
   end Dequeue;

   procedure Peek
     (Self   : Event_Queue;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result)
   is
   begin
      if Self.Items.Is_Empty then
         Event :=
           (Sequence  => A11y.No_Event,
            Timestamp => Ada.Calendar.Clock,
            Source    => A11y.Node_Ids.No_Node,
            Kind      => A11y.Events.Node_Created,
            Revision  => A11y.Initial_Revision);
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Event := Self.Items.First_Element;
         Result := A11y.Results.Ok;
      end if;
   end Peek;

   procedure Acknowledge
     (Self     : in out Event_Queue;
      Sequence : A11y.Event_Sequence;
      Result   : out A11y.Results.Result)
   is
   begin
      if Self.Items.Is_Empty then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif Sequence = A11y.No_Event
        or else Self.Items.First_Element.Sequence /= Sequence
      then
         Result := (Status => A11y.Results.Invalid_Argument);
      else
         Self.Items.Delete_First;
         Result := A11y.Results.Ok;
      end if;
   end Acknowledge;

   procedure Clear (Self : in out Event_Queue) is
   begin
      Self.Items.Clear;
      Self.Had_Overflow := False;
      Self.Destroyed := [others => False];
   end Clear;

end A11y.Event_Queues;
