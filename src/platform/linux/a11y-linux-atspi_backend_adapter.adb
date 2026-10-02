with A11y.Backends;

package body A11y.Linux.ATSPi_Backend_Adapter is
   use type A11y.Backends.Backend_State;
   use type A11y.Backends.Native_Backends.Native_Target;
   use type A11y.Linux.ATSPi_Startup.Event_Loop_Operation;

   function Is_Linux_Backend
     (Backend : A11y.Backends.Native_Backends.Native_Backend)
      return Boolean is
     (Backend.Target = A11y.Backends.Native_Backends.Linux_ATSPI);

   procedure Apply_Startup_Result
     (Backend        : in out A11y.Backends.Native_Backends.Native_Backend;
      Startup_Result : A11y.Results.Result;
      Result         : out A11y.Results.Result)
   is
   begin
      if not Is_Linux_Backend (Backend) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if A11y.Results.Succeeded (Startup_Result) then
         Result := A11y.Results.Ok;
         return;
      end if;

      A11y.Backends.Native_Backends.Record_Transport_Failure
        (Backend, Startup_Result.Status, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Apply_Startup_Result;

   procedure Synchronize_Startup
     (Backend : in out A11y.Backends.Native_Backends.Native_Backend;
      Startup : A11y.Linux.ATSPi_Startup.Startup_Context;
      Result  : out A11y.Results.Result)
   is
      Report : Startup_Synchronization_Report;
   begin
      Synchronize_Startup_With_Report (Backend, Startup, Report, Result);
   end Synchronize_Startup;

   procedure Synchronize_Startup_With_Report
     (Backend : in out A11y.Backends.Native_Backends.Native_Backend;
      Startup : A11y.Linux.ATSPi_Startup.Startup_Context;
      Report  : out Startup_Synchronization_Report;
      Result  : out A11y.Results.Result)
   is
      Interest : constant A11y.Linux.ATSPi_Startup.Event_Loop_Interest :=
        A11y.Linux.ATSPi_Startup.Interest (Startup);
   begin
      Report :=
        (Interest => Interest,
         Backend_Before => Backend.Transport_Status,
         Backend_After => Backend.Transport_Status,
         Failure_Record_Attempted => False,
         Transport_Admission_Attempted => False,
         Backend_Start_Attempted => False,
         Status => A11y.Results.Backend_Unavailable);

      if not Is_Linux_Backend (Backend) then
         Result := (Status => A11y.Results.Invalid_Argument);
         Report.Status := Result.Status;
         Report.Backend_After := Backend.Transport_Status;
         return;
      end if;

      if Interest.Next_Operation =
        A11y.Linux.ATSPi_Startup.Transport_Failed
      then
         Report.Failure_Record_Attempted := True;
         A11y.Backends.Native_Backends.Record_Transport_Failure
           (Backend, Interest.Pump_Status, Result);
         Report.Status := Result.Status;
         Report.Backend_After := Backend.Transport_Status;
         return;
      end if;

      if A11y.Linux.ATSPi_Startup.Can_Pump (Startup) then
         Report.Transport_Admission_Attempted := True;
         A11y.Backends.Native_Backends.Admit_Transport (Backend, Result);
         if A11y.Results.Failed (Result) then
            Report.Status := Result.Status;
            Report.Backend_After := Backend.Transport_Status;
            return;
         end if;

         if Backend.State /= A11y.Backends.Running then
            Report.Backend_Start_Attempted := True;
            Result := Backend.Start;
         else
            Result := A11y.Results.Ok;
         end if;
         Report.Status := Result.Status;
         Report.Backend_After := Backend.Transport_Status;
         return;
      end if;

      Result := (Status => Interest.Pump_Status);
      Report.Status := Result.Status;
      Report.Backend_After := Backend.Transport_Status;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
         Report.Backend_After := Backend.Transport_Status;
   end Synchronize_Startup_With_Report;

end A11y.Linux.ATSPi_Backend_Adapter;
