with Ada.Calendar;
with Ada.Strings.Unbounded;

with A11y.Backends;
with A11y.Backends.Default;
with A11y.Backends.Native_Backends;
with A11y.Backends.Selection;
with A11y.Conformance;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Linux.ATSPi_Backend_Adapter;
with A11y.Linux.ATSPi_Startup;
with A11y.Native_Identity;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Native_Backend_Tests is
   use Ada.Strings.Unbounded;
   use type Ada.Calendar.Time;
   use type A11y.Backends.Backend_State;
   use type A11y.Backends.Native_Backends.Native_Target;
   use type A11y.Backends.Native_Backends.Native_Transport_State;
   use type A11y.Backends.Native_Backends.Transport_Transition_Kind;
   use type A11y.Conformance.Support_Level;
   use type A11y.Diagnostics.Category;
   use type A11y.Event_Sequence;
   use type A11y.Linux.ATSPi_Startup.Event_Loop_Operation;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Platforms.Platform_Kind;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Test_Unavailable_Startup is
      Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.Windows_UIA);
      Result : A11y.Results.Result;
      Runtime_View : A11y.Native_Runtimes.Runtime_Snapshot;
      Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      Declarations : A11y.Conformance.Declaration_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Event : constant A11y.Events.Event :=
        (Sequence  => 11,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (89),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Bad_Event : A11y.Events.Event := Event;
   begin
      Check
        (Backend.Name = "UI Automation",
         "Native backend scaffold reports its native target");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_Object_Cache_Size,
         2,
         Result);
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Tombstone_Retention,
         2,
         Result);
      Result := Backend.Configure_Limits (Limits);
      Runtime_View := Backend.Runtime_Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then Runtime_View.Object_Capacity = 2
         and then Runtime_View.Tombstone_Capacity = 2,
         "Native backend scaffold applies resource limits to runtime state");

      Result := Backend.Start;
      Runtime_View := Backend.Runtime_Snapshot;
      declare
         Transport_View : constant
           A11y.Backends.Native_Backends.Transport_Snapshot :=
             Backend.Transport_Status;
      begin
         Check
           (Transport_View.State =
              A11y.Backends.Native_Backends.Transport_Unavailable
            and then Transport_View.Last_Status =
              A11y.Results.Backend_Unavailable
            and then Transport_View.Generation = 1
            and then A11y.Backends.Native_Backends.Name
              (Transport_View.State) = "unavailable",
            "Native backend transport status records unavailable startup");
      end;
      Check
        (Result.Status = A11y.Results.Backend_Unavailable
         and then Backend.State = A11y.Backends.Stopped
         and then Runtime_View.State = A11y.Backends.Stopped
         and then Runtime_View.Live_Objects = 0
         and then Runtime_View.Object_Capacity = 2,
         "Native backend scaffold starts runtime and falls back when transport is absent");

      Diagnostics := Backend.Diagnostics;
      Check
        (not Diagnostics.Is_Empty,
         "Native backend scaffold records unavailable transport diagnostics");
      Check
        (To_String (Diagnostics.Last_Element.Feature) = "backend.native.scaffold"
         and then Diagnostics.Last_Element.Timestamp <= Ada.Calendar.Clock,
         "Native backend diagnostics retain feature identifiers");
      Check
        (Natural (Diagnostics.Last_Element.Fields.Length) = 1
         and then To_String (Diagnostics.Last_Element.Fields.First_Element.Key)
           = "backend"
         and then To_String (Diagnostics.Last_Element.Fields.First_Element.Value)
           = "UI Automation",
         "Native backend diagnostics retain structured fields");

      Result := Backend.Publish (Event);
      Check
        (Result.Status = A11y.Results.Backend_Unavailable,
         "Native backend scaffold rejects publication until transport exists");

      Bad_Event.Source := A11y.Node_Ids.No_Node;
      Result := Backend.Publish (Bad_Event);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "Native backend scaffold rejects unavailable event sources");

      Bad_Event := Event;
      Bad_Event.Sequence := A11y.No_Event;
      Result := Backend.Publish (Bad_Event);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "Native backend scaffold rejects unsequenced events");

      for Index in 1 .. 10 loop
         Result := Backend.Publish (Event);
      end loop;
      Diagnostics := Backend.Diagnostics;
      Check
        (Natural (Diagnostics.Length) = 2,
         "Native backend scaffold uses bounded diagnostic-log snapshots");

      Declarations := Backend.Support_Declarations;
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Windows_UIA_Provider_Boundary,
            "UIA") = A11y.Conformance.Internal_Only
         and then A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Scaffold,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes target-specific support declarations");
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Target_Resolution,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes target-specific support declarations");
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Transport_Admission,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes transport-admission declarations");
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Transport_Status,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes transport-status declarations");
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Transport_Generation,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes transport-generation declarations");
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Transport_Transition_Report,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes transport-transition-report declarations");
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Backend_Native_Deterministic_Shutdown,
            "UIA") = A11y.Conformance.Internal_Only,
         "Native backend scaffold exposes deterministic-shutdown declarations");
   end Test_Unavailable_Startup;

   procedure Test_Limit_Atomicity is
      Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.Windows_UIA);
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Bad_Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Event_1 : constant A11y.Events.Event :=
        (Sequence  => 31,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (91),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Event_2 : constant A11y.Events.Event :=
        (Sequence  => 32,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (92),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Event_3 : constant A11y.Events.Event :=
        (Sequence  => 33,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (93),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Runtime_View : A11y.Native_Runtimes.Runtime_Snapshot;
      Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      Result : A11y.Results.Result;
   begin
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Native_Object_Cache_Size, 2, Result);
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Tombstone_Retention, 2, Result);
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Diagnostic_Trace_Size, 3, Result);
      Result := Backend.Configure_Limits (Limits);
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend limit-atomicity fixture configures limits");
      A11y.Backends.Native_Backends.Admit_Transport (Backend, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend limit-atomicity fixture admits transport");
      Result := Backend.Start;
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend limit-atomicity fixture starts backend");
      Result := Backend.Publish (Event_1);
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend limit-atomicity fixture publishes first event");
      Result := Backend.Publish (Event_2);
      Runtime_View := Backend.Runtime_Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then Runtime_View.Live_Objects = 2
         and then Runtime_View.Object_Capacity = 2,
         "Native backend limit-atomicity fixture fills runtime cache");

      Bad_Limits := Limits;
      A11y.Resource_Limits.Set_Limit
        (Bad_Limits,
         A11y.Resource_Limits.Native_Object_Cache_Size,
         1,
         Result);
      A11y.Resource_Limits.Set_Limit
        (Bad_Limits,
         A11y.Resource_Limits.Diagnostic_Trace_Size,
         1,
         Result);
      Result := Backend.Configure_Limits (Bad_Limits);
      Runtime_View := Backend.Runtime_Snapshot;
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Runtime_View.Object_Capacity = 2,
         "Native backend rejects runtime limit shrink without mutation");

      Result := Backend.Stop;
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend limit-atomicity fixture stops backend");
      Result := Backend.Publish (Event_2);
      Check
        (Result.Status = A11y.Results.Backend_Unavailable,
         "Native backend limit-atomicity fixture records first rejection");
      Result := Backend.Publish (Event_3);
      Diagnostics := Backend.Diagnostics;
      Check
        (Natural (Diagnostics.Length) = 3,
         "Native backend preserves diagnostic limits after runtime limit failure");

      Bad_Limits := Limits;
      A11y.Resource_Limits.Set_Limit
        (Bad_Limits,
         A11y.Resource_Limits.Native_Object_Cache_Size,
         1,
         Result);
      A11y.Resource_Limits.Set_Limit
        (Bad_Limits,
         A11y.Resource_Limits.Tombstone_Retention,
         1,
         Result);
      A11y.Resource_Limits.Set_Limit
        (Bad_Limits,
         A11y.Resource_Limits.Diagnostic_Trace_Size,
         1,
         Result);
      Result := Backend.Configure_Limits (Bad_Limits);
      Runtime_View := Backend.Runtime_Snapshot;
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Runtime_View.Object_Capacity = 2
         and then Runtime_View.Tombstone_Capacity = 2,
         "Native backend rejects diagnostic limit shrink without runtime mutation");
   end Test_Limit_Atomicity;

   procedure Test_Transport_Admission is
      Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.Linux_ATSPI);
      Result : A11y.Results.Result;
      Runtime_View : A11y.Native_Runtimes.Runtime_Snapshot;
      Transport_View : A11y.Backends.Native_Backends.Transport_Snapshot;
      Transition_Report :
        A11y.Backends.Native_Backends.Transport_Transition_Report;
      Generation_After_Admit : Natural := 0;
      Generation_After_Start : Natural := 0;
      Generation_Before_Stop : Natural := 0;
      Event : constant A11y.Events.Event :=
        (Sequence  => 21,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (90),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Destroy_Event : constant A11y.Events.Event :=
        (Sequence  => 22,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (90),
         Kind      => A11y.Events.Node_Destroyed,
         Revision  => 2);
      Stale_Event : constant A11y.Events.Event :=
        (Sequence  => 23,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (90),
         Kind      => A11y.Events.State_Changed,
         Revision  => 3);
      Time_Back_Event : constant A11y.Events.Event :=
        (Sequence  => 22,
         Timestamp => Ada.Calendar."-" (Event.Timestamp, 1.0),
         Source    => A11y.Node_Ids.From_Natural (90),
         Kind      => A11y.Events.State_Changed,
         Revision  => 2);
      Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
   begin
      Transport_View := Backend.Transport_Status;
      Check
        (not Transport_View.Admitted
         and then not Transport_View.Running
         and then Transport_View.State =
           A11y.Backends.Native_Backends.Transport_Not_Admitted
         and then Transport_View.Last_Status = A11y.Results.Success
         and then Transport_View.Target =
           A11y.Backends.Native_Backends.Linux_ATSPI
         and then Transport_View.Generation = 0,
         "Native backend transport snapshot starts disconnected");

      A11y.Backends.Native_Backends.Admit_Transport_With_Report
        (Backend, Transition_Report, Result);
      Transport_View := Backend.Transport_Status;
      Generation_After_Admit := Transport_View.Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Transition_Report.Operation =
           A11y.Backends.Native_Backends.Transport_Admission
         and then Transition_Report.Before.State =
           A11y.Backends.Native_Backends.Transport_Not_Admitted
         and then Transition_Report.After.State =
           A11y.Backends.Native_Backends.Transport_Admitted
         and then Transition_Report.Requested_Status =
           A11y.Results.Success
         and then Transition_Report.Status = A11y.Results.Success
         and then Transition_Report.Generation_Advanced
         and then Transition_Report.Admission_Changed
         and then not Transition_Report.Running_Changed
         and then Transition_Report.State_Changed
         and then Transport_View.Admitted
         and then not Transport_View.Running
         and then Transport_View.State =
           A11y.Backends.Native_Backends.Transport_Admitted
         and then Transport_View.Last_Status = A11y.Results.Success
         and then Transport_View.Target =
           A11y.Backends.Native_Backends.Linux_ATSPI
         and then Transport_View.Generation = 1,
         "Native backend reports adapter-facing transport admission before start");

      A11y.Backends.Native_Backends.Admit_Transport_With_Report
        (Backend, Transition_Report, Result);
      Transport_View := Backend.Transport_Status;
      Check
        (A11y.Results.Succeeded (Result)
         and then Transition_Report.Operation =
           A11y.Backends.Native_Backends.Transport_Admission
         and then Transition_Report.Before.State =
           A11y.Backends.Native_Backends.Transport_Admitted
         and then Transition_Report.After.State =
           A11y.Backends.Native_Backends.Transport_Admitted
         and then not Transition_Report.Generation_Advanced
         and then not Transition_Report.Admission_Changed
         and then not Transition_Report.Running_Changed
         and then not Transition_Report.State_Changed
         and then Transport_View.Admitted
         and then not Transport_View.Running
         and then Transport_View.State =
           A11y.Backends.Native_Backends.Transport_Admitted
         and then Transport_View.Generation = Generation_After_Admit,
         "Native backend treats repeated transport admission as idempotent before start");

      Result := Backend.Start;
      Runtime_View := Backend.Runtime_Snapshot;
      Transport_View := Backend.Transport_Status;
      Generation_After_Start := Transport_View.Generation;
      Check
        (A11y.Results.Succeeded (Result)
         and then Backend.State = A11y.Backends.Running
         and then Runtime_View.State = A11y.Backends.Running
         and then A11y.Native_Identity.Is_Valid (Runtime_View.Session)
         and then Transport_View.Admitted
         and then Transport_View.Running
         and then Transport_View.State =
           A11y.Backends.Native_Backends.Transport_Running
         and then A11y.Backends.Native_Backends.Name
           (Transport_View.State) = "running"
         and then Transport_View.Generation > Generation_After_Admit,
         "Native backend keeps runtime running after admitted transport startup");

      Result := Backend.Publish (Event);
      Runtime_View := Backend.Runtime_Snapshot;
      Transport_View := Backend.Transport_Status;
      Check
        (A11y.Results.Succeeded (Result)
         and then Runtime_View.Last_Event = Event.Sequence
         and then Runtime_View.Live_Objects = 1
         and then Transport_View.Last_Status = A11y.Results.Success
         and then Transport_View.Generation = Generation_After_Start,
         "Native backend prepares semantic events after transport admission");

      Result := Backend.Publish (Event);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Backend.Transport_Status.State =
           A11y.Backends.Native_Backends.Transport_Running
         and then Backend.Transport_Status.Last_Status =
           A11y.Results.Invalid_Argument,
         "Native backend preserves runtime event ordering after admission");

      Result := Backend.Publish (Time_Back_Event);
      Runtime_View := Backend.Runtime_Snapshot;
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Runtime_View.Last_Event = Event.Sequence,
         "Native backend rejects nonmonotonic event timestamps without commit");

      Result := Backend.Publish (Destroy_Event);
      Runtime_View := Backend.Runtime_Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then Runtime_View.Last_Event = Destroy_Event.Sequence
         and then Runtime_View.Destroyed_Nodes = 1,
         "Native backend records destruction through admitted event publication");

      Result := Backend.Publish (Stale_Event);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "Native backend rejects stale events after node destruction");
      Diagnostics := Backend.Diagnostics;
      Check
        (not Diagnostics.Is_Empty
         and then To_String (Diagnostics.Last_Element.Identifier)
           = "backend.native.event_rejected_runtime"
         and then Diagnostics.Last_Element.Class =
           A11y.Diagnostics.Stale_Native_Query
         and then Diagnostics.Last_Element.Node = Stale_Event.Source
         and then Diagnostics.Last_Element.Sequence = Stale_Event.Sequence
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element,
            "node_id",
            A11y.Node_Ids.Image (Stale_Event.Source))
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element,
            "event_kind",
            A11y.Events.Stable_Name (Stale_Event.Kind))
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element, "status", "node-unavailable"),
         "Native backend records structured runtime publication failures");

      Diagnostics := Backend.Diagnostics;
      Check
        (not Diagnostics.Is_Empty
         and then To_String (Diagnostics.First_Element.Identifier)
           = "backend.native.transport_connected",
         "Native backend records connected-transport diagnostics");

      Generation_Before_Stop := Backend.Transport_Status.Generation;
      A11y.Backends.Native_Backends.Stop_With_Report
        (Backend, Transition_Report, Result);
      Transport_View := Backend.Transport_Status;
      Diagnostics := Backend.Diagnostics;
      Check
        (A11y.Results.Succeeded (Result)
         and then Transition_Report.Operation =
           A11y.Backends.Native_Backends.Transport_Stop
         and then Transition_Report.Before.State =
           A11y.Backends.Native_Backends.Transport_Running
         and then Transition_Report.After.State =
           A11y.Backends.Native_Backends.Transport_Not_Admitted
         and then Transition_Report.Status = A11y.Results.Success
         and then Transition_Report.Generation_Advanced
         and then Transition_Report.Admission_Changed
         and then Transition_Report.Running_Changed
         and then Transition_Report.State_Changed
         and then Backend.State = A11y.Backends.Stopped
         and then not Transport_View.Admitted
         and then not Transport_View.Running
         and then Transport_View.Generation > Generation_Before_Stop,
         "Native backend reports cleared admitted transport state on stop");
      Check
        (not Diagnostics.Is_Empty
         and then To_String (Diagnostics.Last_Element.Identifier)
           = "backend.native.transport_disconnected"
         and then Diagnostics.Last_Element.Class =
           A11y.Diagnostics.Shutdown_Anomaly
         and then To_String (Diagnostics.Last_Element.Feature)
           = "backend.native.deterministic_shutdown",
         "Native backend records deterministic transport shutdown diagnostics");

      Result := Backend.Publish (Stale_Event);
      Check
        (Result.Status = A11y.Results.Backend_Unavailable
         and then Backend.Transport_Status.Generation >
           Transport_View.Generation,
         "Native backend returns unavailable publication after stopped transport");

      A11y.Backends.Native_Backends.Admit_Transport (Backend, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend accepts transport admission after deterministic stop");
   end Test_Transport_Admission;

   procedure Test_Transport_Failure is
      Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.MacOS_NSAccessibility);
      Result : A11y.Results.Result;
      Transport_View : A11y.Backends.Native_Backends.Transport_Snapshot;
      Transition_Report :
        A11y.Backends.Native_Backends.Transport_Transition_Report;
      Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
   begin
      A11y.Backends.Native_Backends.Record_Transport_Failure_With_Report
        (Backend, A11y.Results.Protocol_Failure, Transition_Report, Result);
      Transport_View := Backend.Transport_Status;
      Diagnostics := Backend.Diagnostics;
      Check
        (A11y.Results.Succeeded (Result)
         and then Transition_Report.Operation =
           A11y.Backends.Native_Backends.Transport_Failure_Record
         and then Transition_Report.Before.State =
           A11y.Backends.Native_Backends.Transport_Not_Admitted
         and then Transition_Report.After.State =
           A11y.Backends.Native_Backends.Transport_Failed
         and then Transition_Report.Requested_Status =
           A11y.Results.Protocol_Failure
         and then Transition_Report.Status = A11y.Results.Success
         and then Transition_Report.Generation_Advanced
         and then not Transition_Report.Admission_Changed
         and then not Transition_Report.Running_Changed
         and then Transition_Report.State_Changed
         and then not Transport_View.Admitted
         and then not Transport_View.Running
         and then Transport_View.State =
           A11y.Backends.Native_Backends.Transport_Failed
         and then Transport_View.Last_Status = A11y.Results.Protocol_Failure
         and then Transport_View.Generation = 1
         and then A11y.Backends.Native_Backends.Name
           (Transport_View.State) = "failed"
         and then Transport_View.Target =
           A11y.Backends.Native_Backends.MacOS_NSAccessibility,
         "Native backend reports adapter-reported transport failure");
      Check
        (not Diagnostics.Is_Empty
         and then To_String (Diagnostics.Last_Element.Identifier)
           = "backend.native.transport_failed"
         and then Diagnostics.Last_Element.Class =
           A11y.Diagnostics.Native_Runtime_Connection
         and then To_String (Diagnostics.Last_Element.Feature)
           = "backend.native.transport_status"
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element, "status", "protocol-failure"),
         "Native backend records structured transport failure diagnostics");

      A11y.Backends.Native_Backends.Record_Transport_Failure_With_Report
        (Backend, A11y.Results.Success, Transition_Report, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Transition_Report.Operation =
           A11y.Backends.Native_Backends.Transport_Failure_Record
         and then Transition_Report.Requested_Status =
           A11y.Results.Success
         and then Transition_Report.Status = A11y.Results.Invalid_Argument
         and then not Transition_Report.Generation_Advanced
         and then not Transition_Report.Admission_Changed
         and then not Transition_Report.Running_Changed
         and then not Transition_Report.State_Changed
         and then Backend.Transport_Status.State =
           A11y.Backends.Native_Backends.Transport_Failed
         and then Backend.Transport_Status.Generation =
           Transport_View.Generation,
         "Native backend rejects successful status as transport failure");

      A11y.Backends.Native_Backends.Admit_Transport (Backend, Result);
      Result := Backend.Start;
      Check
        (A11y.Results.Succeeded (Result),
         "Native backend transport-failure fixture starts after admission");
      A11y.Backends.Native_Backends.Record_Transport_Failure_With_Report
        (Backend, A11y.Results.Native_Failure, Transition_Report, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Transition_Report.Operation =
           A11y.Backends.Native_Backends.Transport_Failure_Record
         and then Transition_Report.Requested_Status =
           A11y.Results.Native_Failure
         and then Transition_Report.Status = A11y.Results.Invalid_State
         and then not Transition_Report.Generation_Advanced
         and then not Transition_Report.Admission_Changed
         and then not Transition_Report.Running_Changed
         and then not Transition_Report.State_Changed
         and then Backend.Transport_Status.State =
           A11y.Backends.Native_Backends.Transport_Running,
         "Native backend rejects transport failure mutation while running");
   end Test_Transport_Failure;

   procedure Test_Linux_Adapter is
      Linux_Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.Linux_ATSPI);
      Windows_Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.Windows_UIA);
      Startup : A11y.Linux.ATSPi_Startup.Startup_Context;
      Result : A11y.Results.Result;
      Startup_Result : A11y.Results.Result;
      Transport_View : A11y.Backends.Native_Backends.Transport_Snapshot;
      Sync_Report :
        A11y.Linux.ATSPi_Backend_Adapter.Startup_Synchronization_Report;
   begin
      Startup_Result := (Status => A11y.Results.Protocol_Failure);
      A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
        (Windows_Backend, Startup_Result, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "Linux AT-SPI backend adapter rejects non-Linux native targets");

      A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
        (Linux_Backend, Startup_Result, Result);
      Transport_View := Linux_Backend.Transport_Status;
      Check
        (A11y.Results.Succeeded (Result)
         and then Transport_View.State =
           A11y.Backends.Native_Backends.Transport_Failed
         and then Transport_View.Last_Status =
           A11y.Results.Protocol_Failure,
         "Linux AT-SPI backend adapter records startup transport failures");

      Startup_Result := A11y.Results.Ok;
      A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
        (Linux_Backend, Startup_Result, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Linux_Backend.Transport_Status.State =
           A11y.Backends.Native_Backends.Transport_Failed,
         "Linux AT-SPI backend adapter treats successful startup result as no-op");

      A11y.Linux.ATSPi_Backend_Adapter.Synchronize_Startup
        (Linux_Backend, Startup, Result);
      Check
        (Result.Status = A11y.Results.Backend_Unavailable
         and then Linux_Backend.Transport_Status.State =
           A11y.Backends.Native_Backends.Transport_Failed,
         "Linux AT-SPI backend adapter does not fake unavailable startup admission");

      A11y.Linux.ATSPi_Backend_Adapter.Synchronize_Startup_With_Report
        (Linux_Backend, Startup, Sync_Report, Result);
      Check
        (Result.Status = A11y.Results.Backend_Unavailable
         and then Sync_Report.Status = A11y.Results.Backend_Unavailable
         and then Sync_Report.Interest.Next_Operation =
           A11y.Linux.ATSPi_Startup.Wait_For_Transport
         and then not Sync_Report.Failure_Record_Attempted
         and then not Sync_Report.Transport_Admission_Attempted
         and then not Sync_Report.Backend_Start_Attempted
         and then Sync_Report.Backend_Before.State =
           A11y.Backends.Native_Backends.Transport_Failed
         and then Sync_Report.Backend_After.State =
           A11y.Backends.Native_Backends.Transport_Failed,
         "Linux AT-SPI backend adapter reports startup synchronization without fake transport admission");
   end Test_Linux_Adapter;

   procedure Test_Construction_And_Defaults is
      Created : constant A11y.Backends.Native_Backends.Native_Backend :=
        A11y.Backends.Native_Backends.Create
          (A11y.Backends.Native_Backends.MacOS_NSAccessibility);
      Target : constant A11y.Backends.Native_Backends.Native_Target_Result :=
        A11y.Backends.Native_Backends.Target_For_Current_Platform;
   begin
      Check
        (Created.Name = "NSAccessibility",
         "Native backend constructor preserves the requested target");
      Check
        (A11y.Backends.Native_Backends.Name
           (A11y.Backends.Native_Backends.Linux_ATSPI) = "AT-SPI"
         and then A11y.Backends.Native_Backends.Name
           (A11y.Backends.Native_Backends.Windows_UIA) = "UI Automation"
         and then A11y.Backends.Native_Backends.Name
           (A11y.Backends.Native_Backends.MacOS_NSAccessibility)
           = "NSAccessibility",
         "Native backend target names are stable");
      Check
        ((if A11y.Platforms.Current = A11y.Platforms.Unsupported
          then not Target.Supported
          else Target.Supported
            and then A11y.Backends.Native_Backends.Name (Target.Target)
              = A11y.Platforms.Native_Backend_Name),
         "Native backend resolves the current platform target");
   end Test_Construction_And_Defaults;

   procedure Test_Default_Backend_Fallback is
      Backend : A11y.Backends.Backend'Class :=
        A11y.Backends.Default.Create_Default;
      Target : constant A11y.Backends.Native_Backends.Native_Target_Result :=
        A11y.Backends.Native_Backends.Target_For_Current_Platform;
   begin
      Check
        ((if Target.Supported and then A11y.Backends.Selection.Native_Available
          then Backend.Name = A11y.Backends.Native_Backends.Name (Target.Target)
          else Backend.Name = "Null"),
         "Create_Default falls back until native transport is available");
   end Test_Default_Backend_Fallback;

   procedure Test_Platform_Default_Backend_Fallback is
      Backend : A11y.Backends.Backend'Class :=
        A11y.Backends.Default.Create_Platform_Default;
      Target : constant A11y.Backends.Native_Backends.Native_Target_Result :=
        A11y.Backends.Native_Backends.Target_For_Current_Platform;
   begin
      Check
        ((if Target.Supported and then A11y.Backends.Selection.Native_Available
          then Backend.Name = A11y.Backends.Native_Backends.Name (Target.Target)
          else Backend.Name = "Null"),
         "Create_Platform_Default mirrors default native-transport fallback");
   end Test_Platform_Default_Backend_Fallback;

   procedure Run is
   begin
      Test_Unavailable_Startup;
      Test_Limit_Atomicity;
      Test_Transport_Admission;
      Test_Transport_Failure;
      Test_Linux_Adapter;
      Test_Construction_And_Defaults;
      Test_Default_Backend_Fallback;
      Test_Platform_Default_Backend_Fallback;
   end Run;
end A11y_Native_Backend_Tests;
