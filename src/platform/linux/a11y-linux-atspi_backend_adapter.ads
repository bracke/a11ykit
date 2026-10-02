with A11y.Backends.Native_Backends;
with A11y.Linux.ATSPi_Startup;
with A11y.Results;

package A11y.Linux.ATSPi_Backend_Adapter is

   type Startup_Synchronization_Report is record
      Interest :
        A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Backend_Before :
        A11y.Backends.Native_Backends.Transport_Snapshot;
      Backend_After :
        A11y.Backends.Native_Backends.Transport_Snapshot;
      Failure_Record_Attempted : Boolean := False;
      Transport_Admission_Attempted : Boolean := False;
      Backend_Start_Attempted : Boolean := False;
      Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Apply_Startup_Result
     (Backend        : in out A11y.Backends.Native_Backends.Native_Backend;
      Startup_Result : A11y.Results.Result;
      Result         : out A11y.Results.Result);

   procedure Synchronize_Startup
     (Backend : in out A11y.Backends.Native_Backends.Native_Backend;
      Startup : A11y.Linux.ATSPi_Startup.Startup_Context;
      Result  : out A11y.Results.Result);

   procedure Synchronize_Startup_With_Report
     (Backend : in out A11y.Backends.Native_Backends.Native_Backend;
      Startup : A11y.Linux.ATSPi_Startup.Startup_Context;
      Report  : out Startup_Synchronization_Report;
      Result  : out A11y.Results.Result);

end A11y.Linux.ATSPi_Backend_Adapter;
