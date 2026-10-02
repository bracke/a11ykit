with Ada.Calendar;
with Ada.Strings.Unbounded;
with A11y.Native_Object_Caches;
with A11y.Node_Ids;
with A11y.Platforms;

package body A11y.Backends.Native_Backends is
   use Ada.Strings.Unbounded;
   use type A11y.Events.Event_Kind;

   procedure Add_Diagnostic
     (Self       : in out Native_Backend;
      Identifier : String;
      Level      : A11y.Diagnostics.Severity;
      Class      : A11y.Diagnostics.Category;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Source     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Kind       : A11y.Events.Event_Kind := A11y.Events.Node_Created;
      Has_Event  : Boolean := False;
      Feature    : String := "";
      Status     : A11y.Results.Status_Code := A11y.Results.Success)
   is
      Item : A11y.Diagnostics.Diagnostic;
      Append_Result : A11y.Results.Result;
      Field_Result : A11y.Results.Result;
   begin
      Item.Identifier := To_Unbounded_String (Identifier);
      Item.Level := Level;
      Item.Class := Class;
      Item.Node := Source;
      Item.Sequence := Sequence;
      Item.Timestamp := Ada.Calendar.Clock;
      Item.Feature := To_Unbounded_String (Feature);
      A11y.Diagnostics.Add_Field
        (Item, "backend", Name (Self.Target), Field_Result);
      if A11y.Node_Ids.Is_Valid (Source) then
         A11y.Diagnostics.Add_Field
           (Item, "node_id", A11y.Node_Ids.Image (Source), Field_Result);
      end if;
      if Has_Event then
         A11y.Diagnostics.Add_Field
           (Item, "event_kind", A11y.Events.Stable_Name (Kind), Field_Result);
      end if;
      if Sequence /= A11y.No_Event then
         A11y.Diagnostics.Add_Field
           (Item, "event_sequence", A11y.Event_Sequence_Image (Sequence),
            Field_Result);
      end if;
      if Status /= A11y.Results.Success then
         A11y.Diagnostics.Add_Field
           (Item, "status", A11y.Results.Stable_Name (Status), Field_Result);
      end if;
      A11y.Diagnostics.Append (Self.Notes, Item, Append_Result);
   end Add_Diagnostic;

   procedure Advance_Transport_Generation (Self : in out Native_Backend) is
   begin
      if Self.Transport_Generation < Natural'Last then
         Self.Transport_Generation := Self.Transport_Generation + 1;
      end if;
   end Advance_Transport_Generation;

   procedure Complete_Transition_Report
     (Report : in out Transport_Transition_Report;
      Result : A11y.Results.Result)
   is
   begin
      Report.Status := Result.Status;
      Report.Generation_Advanced :=
        A11y.Backends.Generation_Changed
          (Report.Before.Generation, Report.After.Generation);
      Report.Admission_Changed :=
        A11y.Backends.Flag_Changed
          (Report.Before.Admitted, Report.After.Admitted);
      Report.Running_Changed :=
        A11y.Backends.Flag_Changed
          (Report.Before.Running, Report.After.Running);
      Report.State_Changed := Report.After.State /= Report.Before.State;
   end Complete_Transition_Report;

   function Target_For_Current_Platform return Native_Target_Result is
   begin
      case A11y.Platforms.Current is
         when A11y.Platforms.Linux =>
            return (Supported => True, Target => Linux_ATSPI);
         when A11y.Platforms.Windows =>
            return (Supported => True, Target => Windows_UIA);
         when A11y.Platforms.MacOS =>
            return (Supported => True, Target => MacOS_NSAccessibility);
         when A11y.Platforms.Unsupported =>
            return (Supported => False, Target => Linux_ATSPI);
      end case;
   end Target_For_Current_Platform;

   function Create (Target : Native_Target) return Native_Backend is
   begin
      return Result : Native_Backend (Target) do
         null;
      end return;
   end Create;

   function Name (Target : Native_Target) return String is
     (case Target is
        when Linux_ATSPI => "AT-SPI",
        when Windows_UIA => "UI Automation",
        when MacOS_NSAccessibility => "NSAccessibility");

   function Name (State : Native_Transport_State) return String is
     (case State is
        when Transport_Not_Admitted => "not-admitted",
        when Transport_Admitted => "admitted",
        when Transport_Running => "running",
        when Transport_Unavailable => "unavailable",
        when Transport_Failed => "failed");

   overriding function Name (Self : Native_Backend) return String is
     (Name (Self.Target));

   overriding function State
     (Self : Native_Backend)
      return A11y.Backends.Backend_State is
     (A11y.Native_Runtimes.State (Self.Runtime));

   overriding function Configure_Limits
     (Self   : in out Native_Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
   begin
      A11y.Native_Runtimes.Can_Configure_Limits (Self.Runtime, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      A11y.Diagnostics.Can_Configure (Self.Notes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      A11y.Native_Runtimes.Configure_Limits (Self.Runtime, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      A11y.Diagnostics.Configure (Self.Notes, Limits, Result);
      return Result;
   end Configure_Limits;

   overriding function Initialize
     (Self : in out Native_Backend)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
   begin
      A11y.Native_Runtimes.Initialize (Self.Runtime, Result);
      if A11y.Results.Succeeded (Result) then
         Add_Diagnostic
           (Self,
            "backend.native.runtime_initialized",
            A11y.Diagnostics.Info,
            A11y.Diagnostics.Backend_Initialization,
            Feature => "backend.native.scaffold");
      end if;
      return Result;
   end Initialize;

   overriding function Start
     (Self : in out Native_Backend)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Stop_Result : A11y.Results.Result;
   begin
      A11y.Native_Runtimes.Start (Self.Runtime, Result);
      if A11y.Results.Failed (Result) then
         Add_Diagnostic
           (Self,
            "backend.native.runtime_start_failed",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Backend_Initialization,
            Feature => "backend.native.scaffold");
         return Result;
      end if;

      if Self.Transport_Admitted then
         if A11y.Backends.Should_Advance_On_Start_Connected
              (Self.Transport_Admitted)
         then
            Advance_Transport_Generation (Self);
         end if;
         Self.Transport_Last_Status := A11y.Results.Success;
         Add_Diagnostic
           (Self,
            "backend.native.transport_connected",
            A11y.Diagnostics.Info,
            A11y.Diagnostics.Native_Runtime_Connection,
            Feature => "backend.native.scaffold");
         return A11y.Results.Ok;
      end if;

      Add_Diagnostic
        (Self,
         "backend.native.transport_unavailable",
         A11y.Diagnostics.Warning,
         A11y.Diagnostics.Native_Runtime_Connection,
         Feature => "backend.native.scaffold");
      if A11y.Backends.Should_Advance_On_Start_Unavailable
           (Self.Transport_Last_Status)
      then
         Advance_Transport_Generation (Self);
      end if;
      Self.Transport_Last_Status := A11y.Results.Backend_Unavailable;
      A11y.Native_Runtimes.Stop (Self.Runtime, Stop_Result);
      return (Status => A11y.Results.Backend_Unavailable);
   end Start;

   procedure Admit_Transport
     (Self   : in out Native_Backend;
      Result : out A11y.Results.Result)
   is
      Report : Transport_Transition_Report;
   begin
      Admit_Transport_With_Report (Self, Report, Result);
   end Admit_Transport;

   procedure Admit_Transport_With_Report
     (Self   : in out Native_Backend;
      Report : out Transport_Transition_Report;
      Result : out A11y.Results.Result)
   is
   begin
      Report :=
        (Operation          => Transport_Admission,
         Before            => Transport_Status (Self),
         After             => Transport_Status (Self),
         Requested_Status  => A11y.Results.Success,
         Status            => A11y.Results.Success,
         Generation_Advanced => False,
         Admission_Changed => False,
         Running_Changed   => False,
         State_Changed     => False);

      if not A11y.Backends.Can_Mutate_Transport
        (A11y.Native_Runtimes.State (Self.Runtime))
      then
         Result := (Status => A11y.Results.Invalid_State);
         Report.After := Transport_Status (Self);
         Complete_Transition_Report (Report, Result);
         return;
      end if;

      if A11y.Backends.Should_Advance_On_Admission
        (Self.Transport_Admitted, Self.Transport_Last_Status)
      then
         Advance_Transport_Generation (Self);
         Self.Transport_Admitted := True;
         Self.Transport_Last_Status := A11y.Results.Success;
      end if;
      Result := A11y.Results.Ok;
      Report.After := Transport_Status (Self);
      Complete_Transition_Report (Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report.After := Transport_Status (Self);
         Complete_Transition_Report (Report, Result);
   end Admit_Transport_With_Report;

   procedure Record_Transport_Failure
     (Self   : in out Native_Backend;
      Status : A11y.Results.Status_Code;
      Result : out A11y.Results.Result)
   is
      Report : Transport_Transition_Report;
   begin
      Record_Transport_Failure_With_Report (Self, Status, Report, Result);
   end Record_Transport_Failure;

   procedure Record_Transport_Failure_With_Report
     (Self   : in out Native_Backend;
      Status : A11y.Results.Status_Code;
      Report : out Transport_Transition_Report;
      Result : out A11y.Results.Result)
   is
   begin
      Report :=
        (Operation          => Transport_Failure_Record,
         Before            => Transport_Status (Self),
         After             => Transport_Status (Self),
         Requested_Status  => Status,
         Status            => A11y.Results.Success,
         Generation_Advanced => False,
         Admission_Changed => False,
         Running_Changed   => False,
         State_Changed     => False);

      if not A11y.Backends.Failure_Status_Allowed
        (Status)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         Report.After := Transport_Status (Self);
         Complete_Transition_Report (Report, Result);
         return;
      end if;

      if not A11y.Backends.Can_Mutate_Transport
        (A11y.Native_Runtimes.State (Self.Runtime))
      then
         Result := (Status => A11y.Results.Invalid_State);
         Report.After := Transport_Status (Self);
         Complete_Transition_Report (Report, Result);
         return;
      end if;

      if A11y.Backends.Should_Advance_On_Failure
        (Self.Transport_Admitted, Self.Transport_Last_Status, Status)
      then
         Advance_Transport_Generation (Self);
         Self.Transport_Admitted := False;
         Self.Transport_Last_Status := Status;
      end if;
      Add_Diagnostic
        (Self,
         "backend.native.transport_failed",
         A11y.Diagnostics.Severity_For_Status (Status),
         A11y.Diagnostics.Native_Runtime_Connection,
         Feature => "backend.native.transport_status",
         Status  => Status);
      Result := A11y.Results.Ok;
      Report.After := Transport_Status (Self);
      Complete_Transition_Report (Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report.After := Transport_Status (Self);
         Complete_Transition_Report (Report, Result);
   end Record_Transport_Failure_With_Report;

   overriding function Stop
     (Self : in out Native_Backend)
      return A11y.Results.Result
   is
      Report : Transport_Transition_Report;
      Result : A11y.Results.Result;
   begin
      Stop_With_Report (Self, Report, Result);
      return Result;
   end Stop;

   procedure Stop_With_Report
     (Self   : in out Native_Backend;
      Report : out Transport_Transition_Report;
      Result : out A11y.Results.Result)
   is
      Was_Admitted : constant Boolean := Self.Transport_Admitted;
      Was_Running : constant Boolean :=
        Self.Transport_Admitted
        and then A11y.Native_Runtimes.State (Self.Runtime) =
          A11y.Backends.Running;
   begin
      Report :=
        (Operation          => Transport_Stop,
         Before            => Transport_Status (Self),
         After             => Transport_Status (Self),
         Requested_Status  => A11y.Results.Success,
         Status            => A11y.Results.Success,
         Generation_Advanced => False,
         Admission_Changed => False,
         Running_Changed   => False,
         State_Changed     => False);

      Self.Transport_Admitted := False;
      A11y.Native_Runtimes.Stop (Self.Runtime, Result);
      if A11y.Results.Succeeded (Result) then
         if A11y.Backends.Should_Advance_On_Stop
           (Was_Admitted,
            Was_Running,
            Self.Transport_Last_Status,
            A11y.Results.Success)
         then
            Advance_Transport_Generation (Self);
         end if;
         Self.Transport_Last_Status := A11y.Results.Success;
         Add_Diagnostic
           (Self,
            "backend.native.transport_disconnected",
            A11y.Diagnostics.Info,
            A11y.Diagnostics.Shutdown_Anomaly,
            Feature => "backend.native.deterministic_shutdown");
      else
         if A11y.Backends.Should_Advance_On_Stop
           (Was_Admitted,
            Was_Running,
            Self.Transport_Last_Status,
            Result.Status)
         then
            Advance_Transport_Generation (Self);
         end if;
         Self.Transport_Last_Status := Result.Status;
         Add_Diagnostic
           (Self,
            "backend.native.stop_failed",
            A11y.Diagnostics.Severity_For_Status (Result.Status),
            A11y.Diagnostics.Shutdown_Anomaly,
            Feature => "backend.native.deterministic_shutdown",
            Status  => Result.Status);
      end if;
      Report.After := Transport_Status (Self);
      Complete_Transition_Report (Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report.After := Transport_Status (Self);
         Complete_Transition_Report (Report, Result);
   end Stop_With_Report;

   overriding function Publish
     (Self  : in out Native_Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result
   is
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result : A11y.Results.Result;
   begin
      Prepare_Publication (Self, Event, Prepared, Result);
      return Result;
   end Publish;

   procedure Prepare_Publication
     (Self     : in out Native_Backend;
      Event    : A11y.Events.Event;
      Prepared : out A11y.Native_Runtimes.Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Report : Publication_Preparation_Report;
   begin
      Prepare_Publication_With_Report
        (Self, Event, Prepared, Report, Result);
   end Prepare_Publication;

   procedure Finish_Publication_Report
     (Self     : Native_Backend;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result   : A11y.Results.Result;
      Report   : in out Publication_Preparation_Report)
   is
   begin
      Report.Transport_After := Transport_Status (Self);
      Report.Prepared_Status := Prepared.Status;
      Report.Prepared_Has_Object := Prepared.Has_Object;
      Report.Prepared_Destroys_Node := Prepared.Destroys_Node;
      Report.Status := Result.Status;
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
   end Finish_Publication_Report;

   procedure Prepare_Publication_With_Report
     (Self     : in out Native_Backend;
      Event    : A11y.Events.Event;
      Prepared : out A11y.Native_Runtimes.Prepared_Event;
      Report   : out Publication_Preparation_Report;
      Result   : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
      Runtime_Report : A11y.Native_Runtimes.Event_Preparation_Report;
   begin
      Report :=
        (Transport_Before => Transport_Status (Self),
         Transport_After  => Transport_Status (Self),
         Event_Valid      => A11y.Results.Succeeded (Validation),
         Transport_Admitted_Before => Self.Transport_Admitted,
         Runtime_Preparation_Available => False,
         Runtime_Preparation => <>,
         Prepared_Status        => A11y.Results.Node_Unavailable,
         Prepared_Has_Object    => False,
         Prepared_Destroys_Node => Event.Kind = A11y.Events.Node_Destroyed,
         Status                 => A11y.Results.Node_Unavailable);

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

      if A11y.Results.Failed (Validation) then
         Result := Validation;
         Prepared.Status := Result.Status;
         Finish_Publication_Report (Self, Prepared, Result, Report);
         return;
      end if;

      if not A11y.Backends.Can_Prepare_Publication
        (Self.Transport_Admitted)
      then
         Add_Diagnostic
           (Self,
            "backend.native.event_rejected_unavailable",
            A11y.Diagnostics.Trace,
            A11y.Diagnostics.Backend_Initialization,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.native.scaffold");
         Result := (Status => A11y.Results.Backend_Unavailable);
         Prepared.Status := Result.Status;
         if A11y.Backends.Should_Advance_On_Publication_Status
              (Self.Transport_Last_Status, Result.Status)
         then
            Advance_Transport_Generation (Self);
         end if;
         Self.Transport_Last_Status := Result.Status;
         Finish_Publication_Report (Self, Prepared, Result, Report);
         return;
      end if;

      A11y.Native_Runtimes.Prepare_Event_With_Report
        (Self.Runtime, Event, Prepared, Runtime_Report, Result);
      Report.Runtime_Preparation_Available := True;
      Report.Runtime_Preparation := Runtime_Report;
      if A11y.Results.Failed (Result) then
         if A11y.Backends.Should_Advance_On_Publication_Status
              (Self.Transport_Last_Status, Result.Status)
         then
            Advance_Transport_Generation (Self);
         end if;
         Self.Transport_Last_Status := Result.Status;
         Add_Diagnostic
           (Self,
            "backend.native.event_rejected_runtime",
            A11y.Diagnostics.Severity_For_Status (Result.Status),
            A11y.Diagnostics.Category_For_Status (Result.Status),
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.native.scaffold",
            Status  => Result.Status);
         Finish_Publication_Report (Self, Prepared, Result, Report);
         return;
      end if;

      Add_Diagnostic
        (Self,
         "backend.native.event_prepared",
         A11y.Diagnostics.Trace,
         A11y.Diagnostics.Native_Runtime_Connection,
         Event.Sequence,
         Event.Source,
         Event.Kind,
         Has_Event => True,
         Feature => "backend.native.scaffold");
      if A11y.Backends.Should_Advance_On_Publication_Status
           (Self.Transport_Last_Status, A11y.Results.Success)
      then
         Advance_Transport_Generation (Self);
      end if;
      Self.Transport_Last_Status := A11y.Results.Success;
      Result := A11y.Results.Ok;
      Finish_Publication_Report (Self, Prepared, Result, Report);
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
         Report := (others => <>);
         Finish_Publication_Report (Self, Prepared, Result, Report);
   end Prepare_Publication_With_Report;

   overriding function Diagnostics
     (Self : Native_Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector is
     (A11y.Diagnostics.Snapshot (Self.Notes));

   overriding function Support_Declarations
     (Self : Native_Backend)
      return A11y.Conformance.Declaration_Vectors.Vector is
     (case Self.Target is
        when Linux_ATSPI =>
          A11y.Conformance.Linux_ATSPI_Declarations,
        when Windows_UIA =>
          A11y.Conformance.Windows_UIA_Declarations,
        when MacOS_NSAccessibility =>
          A11y.Conformance.MacOS_NSAccessibility_Declarations);

   function Runtime_Snapshot
     (Self : Native_Backend)
      return A11y.Native_Runtimes.Runtime_Snapshot is
     (A11y.Native_Runtimes.Snapshot (Self.Runtime));

   function Transport_Status
     (Self : Native_Backend)
      return Transport_Snapshot is
      Runtime_State : constant A11y.Backends.Backend_State :=
        A11y.Native_Runtimes.State (Self.Runtime);
      Running : constant Boolean :=
        Self.Transport_Admitted
        and then Runtime_State = A11y.Backends.Running;
      State : constant Native_Transport_State :=
        (if Running then Transport_Running
         elsif Self.Transport_Admitted then Transport_Admitted
         elsif Self.Transport_Last_Status = A11y.Results.Backend_Unavailable
         then Transport_Unavailable
         elsif Self.Transport_Last_Status /= A11y.Results.Success
         then Transport_Failed
         else Transport_Not_Admitted);
   begin
      return
         (Admitted    => Self.Transport_Admitted,
         Running     => Running,
         State       => State,
         Generation  => Self.Transport_Generation,
         Target      => Self.Target,
         Last_Status => Self.Transport_Last_Status);
   end Transport_Status;

end A11y.Backends.Native_Backends;
