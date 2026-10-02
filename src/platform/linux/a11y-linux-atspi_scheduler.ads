with A11y.Linux.ATSPi_Backend_Sessions;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Startup;
with A11y.Results;

package A11y.Linux.ATSPi_Scheduler is

   type Scheduler is limited private;

   type Scheduler_State is
     (Created,
      Configured,
      Running,
      Stopping,
      Stopped,
      Failed);

   type Scheduler_Config is record
      Max_Iterations_Per_Run : Natural := 1;
      Read_Timeout_MS        : Integer := 0;
   end record;

   type Scheduler_Run_Report is record
      State_Before              : Scheduler_State := Created;
      State_After               : Scheduler_State := Created;
      Configured                : Boolean := False;
      Run_Attempted             : Boolean := False;
      Bounded_Loop              :
        A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;
      Session_Had_Cached_Report : Boolean := False;
      Session_Cached_Status     : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Status                    : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   type Transport_Cycle_Run_Report is record
      State_Before   : Scheduler_State := Created;
      State_After    : Scheduler_State := Created;
      Configured     : Boolean := False;
      Run_Attempted  : Boolean := False;
      Interest_Before : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Interest_After  : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Wait_Attempted : Boolean := False;
      Wait_Timed_Out : Boolean := False;
      Wait_Readable  : Boolean := False;
      Wait_Status    : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Write_Wait_Attempted : Boolean := False;
      Write_Wait_Timed_Out : Boolean := False;
      Write_Wait_Ready     : Boolean := False;
      Write_Wait_Status    : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Flushed        : Natural := 0;
      Cycle          :
        A11y.Linux.ATSPi_Backend_Sessions.Transport_Serve_Cycle_Report;
      Status         : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Configure
     (Item   : in out Scheduler;
      Config : Scheduler_Config;
      Result : out A11y.Results.Result);

   procedure Run_Once
     (Item      : in out Scheduler;
      Session   : in out A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Scheduler_Run_Report;
      Result    : out A11y.Results.Result);

   procedure Run_One_Transport_Cycle
     (Item      : in out Scheduler;
      Session   : in out A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Transport_Cycle_Run_Report;
      Result    : out A11y.Results.Result);

   procedure Stop
     (Item   : in out Scheduler;
      Result : out A11y.Results.Result);

   function State (Item : Scheduler) return Scheduler_State;

   function Configuration (Item : Scheduler) return Scheduler_Config;

private

   type Scheduler is limited record
      Current_State : Scheduler_State := Created;
      Config        : Scheduler_Config := (Max_Iterations_Per_Run => 1,
                                           Read_Timeout_MS => 0);
      Has_Config    : Boolean := False;
   end record;

end A11y.Linux.ATSPi_Scheduler;
