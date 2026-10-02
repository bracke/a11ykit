with A11y.Native_Runtimes.Classification;

package body A11y.Native_Runtimes is
   use type Ada.Calendar.Time;
   use type A11y.Native_Object_Caches.Native_Object_Id;

   function Snapshot (Runtime : Native_Runtime) return Runtime_Snapshot is
     (State        => Runtime.Current_State,
      Generation   => Runtime.Generation,
      Session      => Runtime.Current_Session,
      Live_Objects => Runtime.Cache.Live_Count,
      Tombstones   => Runtime.Cache.Tombstone_Count,
      Object_Cache_Generation => Runtime.Cache.Generation,
      Object_Capacity => Runtime.Cache.Object_Capacity,
      Tombstone_Capacity => Runtime.Cache.Tombstone_Capacity,
      Last_Event   => Runtime.Last_Sequence,
      Destroyed_Nodes => Runtime.Destroyed_Count);

   function Can_Initialize
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Can_Initialize (State))
   with SPARK_Mode => On;

   function Needs_Initialize_Before_Start
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Needs_Initialize_Before_Start
        (State))
   with SPARK_Mode => On;

   function Can_Enter_Running
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Can_Enter_Running (State))
   with SPARK_Mode => On;

   function Accepts_Object_Work
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Accepts_Object_Work (State))
   with SPARK_Mode => On;

   function Accepts_Event_Work
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Accepts_Event_Work (State))
   with SPARK_Mode => On;

   function Accepts_Defunct_Mark
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Accepts_Defunct_Mark (State))
   with SPARK_Mode => On;

   function Stop_Is_Idempotent
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Stop_Is_Idempotent (State))
   with SPARK_Mode => On;

   function Can_Advance_Generation (Generation : Natural) return Boolean is
     (A11y.Native_Runtimes.Classification.Can_Advance_Generation
        (Generation))
   with SPARK_Mode => On;

   function Drained
     (Live_Objects    : Natural;
      Tombstones      : Natural;
      Destroyed_Nodes : Natural)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Drained
        (Live_Objects, Tombstones, Destroyed_Nodes))
   with SPARK_Mode => On;

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Generation_Changed
        (Before, After))
   with SPARK_Mode => On;

   function State_Changed
     (Before : A11y.Backends.Backend_State;
      After  : A11y.Backends.Backend_State)
      return Boolean is
     (A11y.Native_Runtimes.Classification.State_Changed (Before, After))
   with SPARK_Mode => On;

   function Session_Changed
     (Before : A11y.Native_Identity.Backend_Session_Id;
      After  : A11y.Native_Identity.Backend_Session_Id)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Session_Changed (Before, After))
   with SPARK_Mode => On;

   function Cache_Reset
     (Before_Live       : Natural;
      Before_Tombstones : Natural;
      After_Live        : Natural;
      After_Tombstones  : Natural)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Cache_Reset
        (Before_Live, Before_Tombstones, After_Live, After_Tombstones))
   with SPARK_Mode => On;

   function Event_Order_Reset
     (Before : A11y.Event_Sequence;
      After  : A11y.Event_Sequence)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Event_Order_Reset
        (Before, After))
   with SPARK_Mode => On;

   function Valid_Node_Slot (Slot : Natural) return Boolean is
     (A11y.Native_Runtimes.Classification.Valid_Node_Slot (Slot))
   with SPARK_Mode => On;

   function Sequence_Advances
     (Previous : A11y.Event_Sequence;
      Current  : A11y.Event_Sequence)
      return Boolean is
     (A11y.Native_Runtimes.Classification.Sequence_Advances
        (Previous, Current))
   with SPARK_Mode => On;

   function Destroyed_Node_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code is
     (A11y.Native_Runtimes.Classification.Destroyed_Node_Status (Kind))
   with SPARK_Mode => On;

   function Defunct_Mark_Cache_Failure_Blocks
     (Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Native_Runtimes.Classification
        .Defunct_Mark_Cache_Failure_Blocks (Status))
   with SPARK_Mode => On;

   procedure Advance_Generation (Runtime : in out Native_Runtime) is
   begin
      if Can_Advance_Generation (Runtime.Generation)
      then
         Runtime.Generation := Runtime.Generation + 1;
      end if;
   end Advance_Generation;

   procedure Complete_Lifecycle_Report
     (Report : in out Runtime_Lifecycle_Report;
      Result : A11y.Results.Result)
   is
   begin
      Report.Status := Result.Status;
      Report.Generation_Advanced :=
        Generation_Changed
          (Report.Before.Generation, Report.After.Generation);
      Report.State_Changed :=
        State_Changed
          (Report.Before.State, Report.After.State);
      Report.Session_Changed :=
        Session_Changed
          (Report.Before.Session, Report.After.Session);
      Report.Cache_Reset :=
        Cache_Reset
          (Report.Before.Live_Objects,
           Report.Before.Tombstones,
           Report.After.Live_Objects,
           Report.After.Tombstones);
      Report.Event_Order_Reset :=
        Event_Order_Reset
          (Report.Before.Last_Event, Report.After.Last_Event);
   end Complete_Lifecycle_Report;

   function State
     (Runtime : Native_Runtime)
      return A11y.Backends.Backend_State is
     (Runtime.Current_State);

   function Session
     (Runtime : Native_Runtime)
      return A11y.Native_Identity.Backend_Session_Id is
     (Runtime.Current_Session);

   function Node_Defunct
     (Runtime : Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      return Slot in 1 .. A11y.Node_Ids.Max_Node_Ids
        and then Runtime.Destroyed (Slot);
   end Node_Defunct;

   function Drained (Runtime : Native_Runtime) return Boolean is
     (Drained
        (Runtime.Cache.Live_Count,
         Runtime.Cache.Tombstone_Count,
         Runtime.Destroyed_Count));

   procedure Validate_Event_Admission
     (Runtime : Native_Runtime;
      Event   : A11y.Events.Event;
      Slot    : out Natural;
      Result  : out A11y.Results.Result)
   is
      Envelope_Result : A11y.Results.Result;
   begin
      Slot := 0;
      if not Accepts_Event_Work
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Shutting_Down);
         return;
      end if;

      Envelope_Result := A11y.Events.Validate_Event (Event);
      if A11y.Results.Failed (Envelope_Result) then
         Result := Envelope_Result;
         return;
      end if;

      Slot := A11y.Node_Ids.To_Natural (Event.Source);
      if not Valid_Node_Slot (Slot) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if not Sequence_Advances
          (Runtime.Last_Sequence, Event.Sequence)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if Event.Timestamp < Runtime.Last_Timestamp then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      if Runtime.Destroyed (Slot) then
         Result :=
           (Status =>
              Destroyed_Node_Status
                (Event.Kind));
         return;
      end if;

      Result := A11y.Results.Ok;
   end Validate_Event_Admission;

   procedure Commit_Event_Order
     (Runtime : in out Native_Runtime;
      Event   : A11y.Events.Event)
   is
   begin
      Runtime.Last_Sequence := Event.Sequence;
      Runtime.Last_Timestamp := Event.Timestamp;
   end Commit_Event_Order;

   procedure Configure_Limits
     (Runtime : in out Native_Runtime;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
   begin
      Runtime.Cache.Configure (Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Configure_Limits;

   procedure Can_Configure_Limits
     (Runtime : in out Native_Runtime;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
   begin
      Runtime.Cache.Can_Configure (Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Can_Configure_Limits;

   procedure Initialize
     (Runtime : in out Native_Runtime;
      Result  : out A11y.Results.Result)
   is
      Report : Runtime_Lifecycle_Report;
   begin
      Initialize_With_Report (Runtime, Report, Result);
   end Initialize;

   procedure Initialize_With_Report
     (Runtime : in out Native_Runtime;
      Report  : out Runtime_Lifecycle_Report;
      Result  : out A11y.Results.Result)
   is
   begin
      Report :=
        (Operation           => Runtime_Initialize,
         Before             => Snapshot (Runtime),
         After              => Snapshot (Runtime),
         Status             => A11y.Results.Success,
         Generation_Advanced => False,
         State_Changed      => False,
         Session_Changed    => False,
         Cache_Reset        => False,
         Event_Order_Reset  => False);

      if not Can_Initialize
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Invalid_State);
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
         return;
      end if;

      Runtime.Current_Session := A11y.Native_Identity.Create_Session;
      if not A11y.Native_Identity.Is_Valid (Runtime.Current_Session) then
         Runtime.Current_State := A11y.Backends.Failed;
         Result := (Status => A11y.Results.Resource_Limit);
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
         return;
      end if;

      Runtime.Cache.Reset;
      Runtime.Destroyed := [others => False];
      Runtime.Destroyed_Count := 0;
      Runtime.Last_Sequence := A11y.No_Event;
      Runtime.Last_Timestamp := Ada.Calendar.Time_Of (1901, 1, 1);
      Advance_Generation (Runtime);
      Runtime.Current_State := A11y.Backends.Initialized;
      Result := A11y.Results.Ok;
      Report.After := Snapshot (Runtime);
      Complete_Lifecycle_Report (Report, Result);
   exception
      when others =>
         Runtime.Current_State := A11y.Backends.Failed;
         Result := (Status => A11y.Results.Internal_Error);
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
   end Initialize_With_Report;

   procedure Start
     (Runtime : in out Native_Runtime;
      Result  : out A11y.Results.Result)
   is
      Report : Runtime_Lifecycle_Report;
   begin
      Start_With_Report (Runtime, Report, Result);
   end Start;

   procedure Start_With_Report
     (Runtime : in out Native_Runtime;
      Report  : out Runtime_Lifecycle_Report;
      Result  : out A11y.Results.Result)
   is
   begin
      Report :=
        (Operation           => Runtime_Start,
         Before             => Snapshot (Runtime),
         After              => Snapshot (Runtime),
         Status             => A11y.Results.Success,
         Generation_Advanced => False,
         State_Changed      => False,
         Session_Changed    => False,
         Cache_Reset        => False,
         Event_Order_Reset  => False);

      if Needs_Initialize_Before_Start
          (Runtime.Current_State)
      then
         Initialize (Runtime, Result);
         if A11y.Results.Failed (Result) then
            Report.After := Snapshot (Runtime);
            Complete_Lifecycle_Report (Report, Result);
            return;
         end if;
      end if;

      if not Can_Enter_Running
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Invalid_State);
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
         return;
      end if;

      Advance_Generation (Runtime);
      Runtime.Current_State := A11y.Backends.Running;
      Result := A11y.Results.Ok;
      Report.After := Snapshot (Runtime);
      Complete_Lifecycle_Report (Report, Result);
   exception
      when others =>
         Runtime.Current_State := A11y.Backends.Failed;
         Result := (Status => A11y.Results.Internal_Error);
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
   end Start_With_Report;

   procedure Stop
     (Runtime : in out Native_Runtime;
      Result  : out A11y.Results.Result)
   is
      Report : Runtime_Lifecycle_Report;
   begin
      Stop_With_Report (Runtime, Report, Result);
   end Stop;

   procedure Stop_With_Report
     (Runtime : in out Native_Runtime;
      Report  : out Runtime_Lifecycle_Report;
      Result  : out A11y.Results.Result)
   is
   begin
      Report :=
        (Operation           => Runtime_Stop,
         Before             => Snapshot (Runtime),
         After              => Snapshot (Runtime),
         Status             => A11y.Results.Success,
         Generation_Advanced => False,
         State_Changed      => False,
         Session_Changed    => False,
         Cache_Reset        => False,
         Event_Order_Reset  => False);

      if Stop_Is_Idempotent
          (Runtime.Current_State)
      then
         Result := A11y.Results.Ok;
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
         return;
      end if;

      Runtime.Current_State := A11y.Backends.Stopping;
      Runtime.Cache.Reset;
      Runtime.Destroyed := [others => False];
      Runtime.Destroyed_Count := 0;
      Runtime.Current_Session := A11y.Native_Identity.No_Session;
      Runtime.Last_Sequence := A11y.No_Event;
      Runtime.Last_Timestamp := Ada.Calendar.Time_Of (1901, 1, 1);
      Advance_Generation (Runtime);
      Runtime.Current_State := A11y.Backends.Stopped;
      Result := A11y.Results.Ok;
      Report.After := Snapshot (Runtime);
      Complete_Lifecycle_Report (Report, Result);
   exception
      when others =>
         Runtime.Current_State := A11y.Backends.Failed;
         Result := (Status => A11y.Results.Internal_Error);
         Report.After := Snapshot (Runtime);
         Complete_Lifecycle_Report (Report, Result);
   end Stop_With_Report;

   procedure Ensure_Object
     (Runtime : in out Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Object  : out A11y.Native_Object_Caches.Native_Object_Id;
      Result  : out A11y.Results.Result)
   is
   begin
      Object := A11y.Native_Object_Caches.No_Object;
      if not Accepts_Object_Work
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Shutting_Down);
         return;
      end if;

      if Node_Defunct (Runtime, Node) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Runtime.Cache.Ensure_Object
        (Runtime.Current_Session, Node, Object, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Ensure_Object;

   procedure Resolve_Object
     (Runtime : in out Native_Runtime;
      Object  : A11y.Native_Object_Caches.Native_Object_Id;
      Item    : out A11y.Native_Object_Caches.Object_Snapshot;
      Result  : out A11y.Results.Result)
   is
   begin
      Item := (others => <>);
      if not Accepts_Object_Work
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Shutting_Down);
         return;
      end if;

      Runtime.Cache.Resolve
        (Runtime.Current_Session, Object, Item, Result);
   exception
      when others =>
         Item := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
   end Resolve_Object;

   procedure Find_Object
     (Runtime : in out Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Item    : out A11y.Native_Object_Caches.Object_Snapshot;
      Result  : out A11y.Results.Result)
   is
   begin
      Item := (others => <>);
      if not Accepts_Object_Work
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Shutting_Down);
         return;
      end if;

      Runtime.Cache.Find_Object
        (Runtime.Current_Session, Node, Item, Result);
   exception
      when others =>
         Item := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
   end Find_Object;

   function Validate_Prepared_Event
     (Prepared : Prepared_Event)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Payload_Count : Natural := 0;

      procedure Count (Present : Boolean) is
      begin
         if Present then
            Payload_Count := Payload_Count + 1;
         end if;
      end Count;
   begin
      if A11y.Results.Failed ((Status => Prepared.Status)) then
         return (Status => Prepared.Status);
      end if;

      Result := A11y.Events.Validate_Event (Prepared.Event);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      if Prepared.Event.Kind = A11y.Events.Node_Destroyed then
         if not Prepared.Destroys_Node or else Prepared.Has_Object then
            return (Status => A11y.Results.Invalid_Argument);
         end if;
      elsif Prepared.Destroys_Node
        or else not Prepared.Has_Object
        or else Prepared.Object = A11y.Native_Object_Caches.No_Object
      then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      Count (Prepared.Has_Property_Payload);
      Count (Prepared.Has_State_Payload);
      Count (Prepared.Has_Bounds_Payload);
      Count (Prepared.Has_Value_Payload);
      Count (Prepared.Has_Selection_Payload);
      Count (Prepared.Has_Relation_Payload);
      Count (Prepared.Has_Focus_Payload);
      Count (Prepared.Has_Node_Reference_Payload);
      Count (Prepared.Has_Live_Region_Payload);
      Count (Prepared.Has_Tree_Payload);
      Count (Prepared.Has_Table_Payload);
      Count (Prepared.Has_Document_Payload);
      Count (Prepared.Has_Window_Payload);

      if Payload_Count > 1 then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      if Prepared.Has_Property_Payload then
         declare
            Validated : constant A11y.Events.Property_Event_Payload :=
              A11y.Events.Validate_Property_Event_Payload
                (Prepared.Event.Kind, Prepared.Property_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_State_Payload then
         declare
            Validated : constant A11y.Events.State_Event_Payload :=
              A11y.Events.Validate_State_Event_Payload
                (Prepared.Event.Kind, Prepared.State_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Bounds_Payload then
         declare
            Validated : constant A11y.Events.Bounds_Event_Payload :=
              A11y.Events.Validate_Bounds_Event_Payload
                (Prepared.Event.Kind, Prepared.Bounds_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Value_Payload then
         declare
            Validated : constant A11y.Events.Value_Event_Payload :=
              A11y.Events.Validate_Value_Event_Payload
                (Prepared.Event.Kind, Prepared.Value_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Selection_Payload then
         declare
            Validated : constant A11y.Events.Selection_Event_Payload :=
              A11y.Events.Validate_Selection_Event_Payload
                (Prepared.Event.Kind, Prepared.Selection_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Relation_Payload then
         declare
            Validated : constant A11y.Events.Relation_Event_Payload :=
              A11y.Events.Validate_Relation_Event_Payload
                (Prepared.Event.Kind, Prepared.Relation_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Focus_Payload then
         declare
            Validated : constant A11y.Events.Focus_Event_Payload :=
              A11y.Events.Validate_Focus_Event_Payload
                (Prepared.Event.Kind, Prepared.Focus_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Node_Reference_Payload then
         declare
            Validated : constant A11y.Events.Node_Reference_Event_Payload :=
              A11y.Events.Validate_Node_Reference_Event_Payload
                (Prepared.Event.Kind,
                 Prepared.Node_Reference_Payload,
                 Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Live_Region_Payload then
         declare
            Validated : constant A11y.Events.Live_Region_Event_Payload :=
              A11y.Events.Validate_Live_Region_Event_Payload
                (Prepared.Event.Kind, Prepared.Live_Region_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Tree_Payload then
         declare
            Validated : constant A11y.Events.Tree_Event_Payload :=
              A11y.Events.Validate_Tree_Event_Payload
                (Prepared.Event.Kind, Prepared.Tree_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Table_Payload then
         declare
            Validated : constant A11y.Events.Table_Event_Payload :=
              A11y.Events.Validate_Table_Event_Payload
                (Prepared.Event.Kind, Prepared.Table_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Document_Payload then
         declare
            Validated : constant A11y.Events.Document_Event_Payload :=
              A11y.Events.Validate_Document_Event_Payload
                (Prepared.Event.Kind, Prepared.Document_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      elsif Prepared.Has_Window_Payload then
         declare
            Validated : constant A11y.Events.Window_Event_Payload :=
              A11y.Events.Validate_Window_Event_Payload
                (Prepared.Event.Kind, Prepared.Window_Payload, Result);
            pragma Unreferenced (Validated);
         begin
            return Result;
         end;
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Validate_Prepared_Event;

   procedure Mark_Node_Defunct
     (Runtime : in out Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result)
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
      Cache_Result : A11y.Results.Result;
   begin
      if not Accepts_Defunct_Mark
          (Runtime.Current_State)
      then
         Result := (Status => A11y.Results.Shutting_Down);
         return;
      end if;

      if not Valid_Node_Slot (Slot) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if Runtime.Destroyed (Slot) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Runtime.Cache.Mark_Defunct (Node, Cache_Result);
      if Defunct_Mark_Cache_Failure_Blocks (Cache_Result.Status)
      then
         Result := Cache_Result;
         return;
      end if;

      Runtime.Destroyed (Slot) := True;
      Runtime.Destroyed_Count := Runtime.Destroyed_Count + 1;
      Advance_Generation (Runtime);
      Result := A11y.Results.Ok;
   exception
      when others =>
      Result := (Status => A11y.Results.Internal_Error);
   end Mark_Node_Defunct;

   procedure Apply_Event
     (Runtime : in out Native_Runtime;
      Event   : A11y.Events.Event;
      Result  : out A11y.Results.Result)
   is
      Defunct_Result : A11y.Results.Result;
      Slot : Natural;
   begin
      Validate_Event_Admission (Runtime, Event, Slot, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if Event.Kind = A11y.Events.Node_Destroyed then
         Mark_Node_Defunct (Runtime, Event.Source, Defunct_Result);
         if A11y.Results.Failed (Defunct_Result) then
            Result := Defunct_Result;
            return;
         end if;
      end if;

      Commit_Event_Order (Runtime, Event);
      Result := A11y.Results.Ok;
   exception
      when others =>
      Result := (Status => A11y.Results.Internal_Error);
   end Apply_Event;

   procedure Prepare_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Report : Event_Preparation_Report;
   begin
      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
   end Prepare_Event;

   procedure Prepare_Event_With_Report
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Prepared : out Prepared_Event;
      Report   : out Event_Preparation_Report;
      Result   : out A11y.Results.Result)
   is
      Object : A11y.Native_Object_Caches.Native_Object_Id;
      Slot : Natural;
      Initial : constant Runtime_Snapshot := Snapshot (Runtime);
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
      Report :=
        (State_Before      => Initial.State,
         State_After       => Initial.State,
         Generation_Before => Initial.Generation,
         Generation_After  => Initial.Generation,
         Last_Event_Before => Initial.Last_Event,
         Last_Event_After  => Initial.Last_Event,
         Source            => Event.Source,
         Kind              => Event.Kind,
         Object            => A11y.Native_Object_Caches.No_Object,
         Has_Object        => False,
         Destroys_Node     => Event.Kind = A11y.Events.Node_Destroyed,
         Was_Defunct       => Node_Defunct (Runtime, Event.Source),
         Is_Defunct        => Node_Defunct (Runtime, Event.Source),
         Admitted          => False,
         Committed         => False,
         Status            => A11y.Results.Node_Unavailable);

      Validate_Event_Admission (Runtime, Event, Slot, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         Report.Status := Result.Status;
         Report.State_After := Runtime.Current_State;
         Report.Generation_After := Runtime.Generation;
         Report.Last_Event_After := Runtime.Last_Sequence;
         Report.Is_Defunct := Node_Defunct (Runtime, Event.Source);
         return;
      end if;
      Report.Admitted := True;

      if Event.Kind = A11y.Events.Node_Destroyed then
         Mark_Node_Defunct (Runtime, Event.Source, Result);
         if A11y.Results.Failed (Result) then
            Prepared.Status := Result.Status;
            Report.Status := Result.Status;
            Report.State_After := Runtime.Current_State;
            Report.Generation_After := Runtime.Generation;
            Report.Last_Event_After := Runtime.Last_Sequence;
            Report.Is_Defunct := Node_Defunct (Runtime, Event.Source);
            return;
         end if;

         Commit_Event_Order (Runtime, Event);
         Prepared.Status := A11y.Results.Success;
         Report.Committed := True;
         Report.Status := A11y.Results.Success;
         Report.State_After := Runtime.Current_State;
         Report.Generation_After := Runtime.Generation;
         Report.Last_Event_After := Runtime.Last_Sequence;
         Report.Is_Defunct := Node_Defunct (Runtime, Event.Source);
         Result := A11y.Results.Ok;
         return;
      end if;

      Ensure_Object (Runtime, Event.Source, Object, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         Report.Status := Result.Status;
         Report.State_After := Runtime.Current_State;
         Report.Generation_After := Runtime.Generation;
         Report.Last_Event_After := Runtime.Last_Sequence;
         Report.Is_Defunct := Node_Defunct (Runtime, Event.Source);
         return;
      end if;

      Commit_Event_Order (Runtime, Event);
         Prepared.Status := A11y.Results.Success;
         Prepared.Object := Object;
         Prepared.Has_Object := True;
      Report.Committed := True;
      Report.Status := A11y.Results.Success;
      Report.State_After := Runtime.Current_State;
      Report.Generation_After := Runtime.Generation;
      Report.Last_Event_After := Runtime.Last_Sequence;
      Report.Object := Object;
      Report.Has_Object := True;
      Report.Is_Defunct := Node_Defunct (Runtime, Event.Source);
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Report := (others => <>);
         Report.Source := Event.Source;
         Report.Kind := Event.Kind;
         Report.Status := A11y.Results.Internal_Error;
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Event_With_Report;

   procedure Prepare_Property_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Property_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Property_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Property_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Property_Payload := True;
         Prepared.Property_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Property_Event;

   procedure Prepare_State_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.State_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.State_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_State_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_State_Payload := True;
         Prepared.State_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_State_Event;

   procedure Prepare_Bounds_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Bounds_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Bounds_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Bounds_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Bounds_Payload := True;
         Prepared.Bounds_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Bounds_Event;

   procedure Prepare_Value_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Value_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Value_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Value_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Value_Payload := True;
         Prepared.Value_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Value_Event;

   procedure Prepare_Selection_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Selection_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Selection_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Selection_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Selection_Payload := True;
         Prepared.Selection_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Selection_Event;

   procedure Prepare_Relation_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Relation_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Relation_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Relation_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Relation_Payload := True;
         Prepared.Relation_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Relation_Event;

   procedure Prepare_Focus_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Focus_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Focus_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Focus_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Focus_Payload := True;
         Prepared.Focus_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Focus_Event;

   procedure Prepare_Node_Reference_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Node_Reference_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Node_Reference_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Node_Reference_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Node_Reference_Payload := True;
         Prepared.Node_Reference_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Node_Reference_Event;

   procedure Prepare_Live_Region_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Live_Region_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Live_Region_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Live_Region_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Live_Region_Payload := True;
         Prepared.Live_Region_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Live_Region_Event;

   procedure Prepare_Tree_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Tree_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Tree_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Tree_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Tree_Payload := True;
         Prepared.Tree_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Tree_Event;

   procedure Prepare_Table_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Table_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Table_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Table_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Table_Payload := True;
         Prepared.Table_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Table_Event;

   procedure Prepare_Document_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Document_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Document_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Document_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Document_Payload := True;
         Prepared.Document_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Document_Event;

   procedure Prepare_Window_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Window_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Validated : A11y.Events.Window_Event_Payload;
      Report    : Event_Preparation_Report;
   begin
      Prepared :=
        (Status        => A11y.Results.Success,
         Event         => Event,
         Object        => A11y.Native_Object_Caches.No_Object,
         Has_Object    => False,
         Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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

      Validated := A11y.Events.Validate_Window_Event_Payload
        (Event.Kind, Payload, Result);
      if A11y.Results.Failed (Result) then
         Prepared.Status := Result.Status;
         return;
      end if;

      Prepare_Event_With_Report (Runtime, Event, Prepared, Report, Result);
      if A11y.Results.Succeeded (Result) then
         Prepared.Has_Window_Payload := True;
         Prepared.Window_Payload := Validated;
      end if;
   exception
      when others =>
         Prepared :=
           (Status        => A11y.Results.Internal_Error,
            Event         => Event,
            Object        => A11y.Native_Object_Caches.No_Object,
            Has_Object    => False,
            Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
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
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Window_Event;

end A11y.Native_Runtimes;
