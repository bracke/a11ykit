with A11y.Conformance;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Native_Runtimes;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Backends.Native_Backends is

   type Native_Target is
     (Linux_ATSPI,
      Windows_UIA,
      MacOS_NSAccessibility);

   type Native_Target_Result is record
      Supported : Boolean := False;
      Target    : Native_Target := Linux_ATSPI;
   end record;

   type Native_Transport_State is
     (Transport_Not_Admitted,
      Transport_Admitted,
      Transport_Running,
      Transport_Unavailable,
      Transport_Failed);

   type Transport_Snapshot is record
      Admitted : Boolean := False;
      Running  : Boolean := False;
      State    : Native_Transport_State := Transport_Not_Admitted;
      Generation : Natural := 0;
      Target   : Native_Target := Linux_ATSPI;
      Last_Status : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

   type Transport_Transition_Kind is
     (Transport_Admission,
      Transport_Failure_Record,
      Transport_Stop);

   type Transport_Transition_Report is record
      Operation : Transport_Transition_Kind := Transport_Admission;
      Before    : Transport_Snapshot;
      After     : Transport_Snapshot;
      Requested_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Status    : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Advanced : Boolean := False;
      Admission_Changed   : Boolean := False;
      Running_Changed     : Boolean := False;
      State_Changed       : Boolean := False;
   end record;

   type Publication_Preparation_Report is record
      Transport_Before : Transport_Snapshot;
      Transport_After  : Transport_Snapshot;
      Event_Valid      : Boolean := False;
      Transport_Admitted_Before : Boolean := False;
      Runtime_Preparation_Available : Boolean := False;
      Runtime_Preparation :
        A11y.Native_Runtimes.Event_Preparation_Report;
      Prepared_Status        : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Has_Object    : Boolean := False;
      Prepared_Destroys_Node : Boolean := False;
      Status                 : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   type Native_Backend
     (Target : Native_Target)
   is limited new A11y.Backends.Backend with private;

   function Target_For_Current_Platform return Native_Target_Result;
   function Name (Target : Native_Target) return String;
   function Name (State : Native_Transport_State) return String;
   function Create (Target : Native_Target) return Native_Backend;

   overriding function Name (Self : Native_Backend) return String;
   overriding function State
     (Self : Native_Backend)
      return A11y.Backends.Backend_State;
   overriding function Configure_Limits
     (Self   : in out Native_Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;
   overriding function Initialize
     (Self : in out Native_Backend)
      return A11y.Results.Result;
   overriding function Start
     (Self : in out Native_Backend)
      return A11y.Results.Result;
   procedure Admit_Transport
     (Self   : in out Native_Backend;
      Result : out A11y.Results.Result);
   procedure Admit_Transport_With_Report
     (Self   : in out Native_Backend;
      Report : out Transport_Transition_Report;
      Result : out A11y.Results.Result);
   procedure Record_Transport_Failure
     (Self   : in out Native_Backend;
      Status : A11y.Results.Status_Code;
      Result : out A11y.Results.Result);
   procedure Record_Transport_Failure_With_Report
     (Self   : in out Native_Backend;
      Status : A11y.Results.Status_Code;
      Report : out Transport_Transition_Report;
      Result : out A11y.Results.Result);
   overriding function Stop
     (Self : in out Native_Backend)
      return A11y.Results.Result;
   procedure Stop_With_Report
     (Self   : in out Native_Backend;
      Report : out Transport_Transition_Report;
      Result : out A11y.Results.Result);
   overriding function Publish
     (Self  : in out Native_Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result;
   procedure Prepare_Publication
     (Self     : in out Native_Backend;
      Event    : A11y.Events.Event;
      Prepared : out A11y.Native_Runtimes.Prepared_Event;
      Result   : out A11y.Results.Result);
   procedure Prepare_Publication_With_Report
     (Self     : in out Native_Backend;
      Event    : A11y.Events.Event;
      Prepared : out A11y.Native_Runtimes.Prepared_Event;
      Report   : out Publication_Preparation_Report;
      Result   : out A11y.Results.Result);
   overriding function Diagnostics
     (Self : Native_Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector;
   overriding function Support_Declarations
     (Self : Native_Backend)
      return A11y.Conformance.Declaration_Vectors.Vector;

   function Runtime_Snapshot
     (Self : Native_Backend)
      return A11y.Native_Runtimes.Runtime_Snapshot;

   function Transport_Status
     (Self : Native_Backend)
      return Transport_Snapshot;

private
   type Native_Backend
     (Target : Native_Target)
   is limited new A11y.Backends.Backend with record
      Runtime : A11y.Native_Runtimes.Native_Runtime;
      Notes   : A11y.Diagnostics.Diagnostic_Log;
      Transport_Admitted : Boolean := False;
      Transport_Last_Status : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Transport_Generation : Natural := 0;
   end record;

end A11y.Backends.Native_Backends;
