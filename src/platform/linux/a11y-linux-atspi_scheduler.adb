package body A11y.Linux.ATSPi_Scheduler is

   use type A11y.Results.Status_Code;
   use type A11y.Linux.ATSPi_Startup.Event_Loop_Operation;

   procedure Configure
     (Item   : in out Scheduler;
      Config : Scheduler_Config;
      Result : out A11y.Results.Result)
   is
   begin
      if Item.Current_State = Running
        or else Item.Current_State = Stopping
      then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      if Config.Max_Iterations_Per_Run = 0
        or else Config.Read_Timeout_MS < 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Item.Config := Config;
      Item.Has_Config := True;
      Item.Current_State := Configured;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Item.Current_State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
   end Configure;

   procedure Run_Once
     (Item      : in out Scheduler;
      Session   : in out A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Scheduler_Run_Report;
      Result    : out A11y.Results.Result)
   is
      Session_View :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
   begin
      Report := (others => <>);
      Report.State_Before := Item.Current_State;
      Report.Configured := Item.Has_Config;

      if not Item.Has_Config then
         Result := (Status => A11y.Results.Invalid_Argument);
         Report.State_After := Item.Current_State;
         Report.Status := Result.Status;
         return;
      end if;

      if Item.Current_State = Stopping
        or else Item.Current_State = Stopped
      then
         Result := (Status => A11y.Results.Shutting_Down);
         Report.State_After := Item.Current_State;
         Report.Status := Result.Status;
         return;
      elsif Item.Current_State = Failed then
         Result := (Status => A11y.Results.Internal_Error);
         Report.State_After := Item.Current_State;
         Report.Status := Result.Status;
         return;
      end if;

      Item.Current_State := Running;
      Report.Run_Attempted := True;

      A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
        (Session,
         Snapshots,
         Item.Config.Max_Iterations_Per_Run,
         Item.Config.Read_Timeout_MS,
         Report.Bounded_Loop,
         Result);

      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Session, Session_View);
      Report.Session_Had_Cached_Report :=
        Session_View.Has_Event_Loop_Report;
      Report.Session_Cached_Status :=
        Session_View.Last_Event_Loop.Status;
      Report.Status := Result.Status;

      if Result.Status = A11y.Results.Internal_Error then
         Item.Current_State := Failed;
      else
         Item.Current_State := Configured;
      end if;
      Report.State_After := Item.Current_State;
   exception
      when others =>
         Item.Current_State := Failed;
         Report.State_After := Item.Current_State;
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Run_Once;

   procedure Run_One_Transport_Cycle
     (Item      : in out Scheduler;
      Session   : in out A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Transport_Cycle_Run_Report;
      Result    : out A11y.Results.Result)
   is
      Flushed : Natural := 0;
   begin
      Report := (others => <>);
      Report.State_Before := Item.Current_State;
      Report.Configured := Item.Has_Config;

      if not Item.Has_Config then
         Result := (Status => A11y.Results.Invalid_Argument);
         Report.State_After := Item.Current_State;
         Report.Status := Result.Status;
         return;
      end if;

      if Item.Current_State = Stopping
        or else Item.Current_State = Stopped
      then
         Result := (Status => A11y.Results.Shutting_Down);
         Report.State_After := Item.Current_State;
         Report.Status := Result.Status;
         return;
      elsif Item.Current_State = Failed then
         Result := (Status => A11y.Results.Internal_Error);
         Report.State_After := Item.Current_State;
         Report.Status := Result.Status;
         return;
      end if;

      Item.Current_State := Running;
      Report.Run_Attempted := True;

      Report.Interest_Before :=
        A11y.Linux.ATSPi_Backend_Sessions.Startup_Interest (Session);

      if Report.Interest_Before.Next_Operation =
        A11y.Linux.ATSPi_Startup.Wait_For_Transport
        or else Report.Interest_Before.Next_Operation =
          A11y.Linux.ATSPi_Startup.Transport_Failed
      then
         Result := (Status => Report.Interest_Before.Pump_Status);
         Report.Wait_Status := Result.Status;
      elsif Report.Interest_Before.Next_Operation =
        A11y.Linux.ATSPi_Startup.Write_Outgoing
      then
         Report.Write_Wait_Attempted := True;
         A11y.Linux.ATSPi_Backend_Sessions.Wait_Writable
           (Session, Item.Config.Read_Timeout_MS, Result);
         Report.Write_Wait_Status := Result.Status;
         Report.Wait_Status := Result.Status;
         if Result.Status = A11y.Results.Timed_Out then
            Report.Write_Wait_Timed_Out := True;
         elsif A11y.Results.Succeeded (Result) then
            Report.Write_Wait_Ready := True;
            Report.Cycle.Write_Attempted := True;
            A11y.Linux.ATSPi_Backend_Sessions.Flush_Bounded_Outgoing
              (Session,
               Item.Config.Max_Iterations_Per_Run,
               Flushed,
               Result);
            Report.Flushed := Flushed;
            Report.Wait_Status := Result.Status;
            Report.Cycle.Reply_Written := A11y.Results.Succeeded (Result);
         end if;
      else
         Report.Wait_Attempted := True;
         A11y.Linux.ATSPi_Backend_Sessions.Wait_Readable
           (Session, Item.Config.Read_Timeout_MS, Result);
         Report.Wait_Status := Result.Status;
         if Result.Status = A11y.Results.Timed_Out then
            Report.Wait_Timed_Out := True;
         elsif A11y.Results.Succeeded (Result) then
            Report.Wait_Readable := True;
            A11y.Linux.ATSPi_Backend_Sessions.Serve_One_Transport_Cycle
              (Session, Snapshots, Report.Cycle, Result);
         end if;
      end if;
      Report.Interest_After :=
        A11y.Linux.ATSPi_Backend_Sessions.Startup_Interest (Session);
      Report.Status := Result.Status;

      if Result.Status = A11y.Results.Internal_Error then
         Item.Current_State := Failed;
      else
         Item.Current_State := Configured;
      end if;
      Report.State_After := Item.Current_State;
   exception
      when others =>
         Item.Current_State := Failed;
         Report.State_After := Item.Current_State;
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Run_One_Transport_Cycle;

   procedure Stop
     (Item   : in out Scheduler;
      Result : out A11y.Results.Result)
   is
   begin
      if Item.Current_State = Running then
         Item.Current_State := Stopping;
      end if;

      Item.Current_State := Stopped;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Item.Current_State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
   end Stop;

   function State (Item : Scheduler) return Scheduler_State is
     (Item.Current_State);

   function Configuration (Item : Scheduler) return Scheduler_Config is
     (Item.Config);

end A11y.Linux.ATSPi_Scheduler;
