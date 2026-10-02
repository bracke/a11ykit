with A11y.Linux.ATSPi_Signals;
with A11y.Native_Identity;

package body A11y.Linux.ATSPi_Backend_Sessions is
   use Ada.Strings.Unbounded;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Linux.ATSPi_Startup.Event_Loop_Operation;
   use type A11y.Results.Status_Code;

   procedure Ensure_Application_Root
     (Session          : in out Backend_Session;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
      Snapshot :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
   begin
      if not A11y.Linux.ATSPi_Startup.Registered (Session.Startup) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      Session.Application_Node := Application_Node;
      A11y.Linux.ATSPi_Object_Registry.Ensure_Object
        (Session.Registry,
         A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup),
         Application_Node,
         Snapshot,
         Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Ensure_Application_Root;

   function Startup_Source_Name (Source : Startup_Source) return String is
     (case Source is
        when Direct_Address => "direct_address",
        when Environment_Value => "environment_value",
        when Host_AT_SPI_Bus_Address => "at_spi_bus_address",
        when Host_Session_Bus_Address => "dbus_session_bus_address",
        when Host_Environment_Missing => "missing_host_environment",
        when Session_Bus_Address => "session_bus_address");

   procedure Configure
     (Session : in out Backend_Session;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
   begin
      Result := Session.Backend.Configure_Limits (Limits);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.ATSPi_Object_Registry.Configure
        (Session.Registry, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Session.Limits := Limits;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Configure;

   procedure Start_From_Address
     (Session          : in out Backend_Session;
      Address          : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
      Report : Session_Startup_Report;
   begin
      Start_From_Address_With_Report
        (Session, Address, User_Id, Application_Node, Report, Result);
   end Start_From_Address;

   procedure Start_From_Address_With_Report
     (Session          : in out Backend_Session;
      Address          : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Report           : out Session_Startup_Report;
      Result           : out A11y.Results.Result)
   is
      Startup_Result : A11y.Results.Result;
   begin
      Report := (others => <>);
      Report.Source := Direct_Address;

      A11y.Linux.ATSPi_Startup.Prepare
        (Session.Startup, Address, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;
      Report.Prepared := True;

      A11y.Linux.ATSPi_Startup.Start_With_Report
        (Session.Startup, User_Id, Application_Node, Session.Limits,
         Report.Registration, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Backend_Adapter.Synchronize_Startup_With_Report
        (Session.Backend, Session.Startup, Report.Backend_Synchronization,
         Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;
      Report.Backend_Synchronized := True;

      Ensure_Application_Root (Session, Application_Node, Result);
      Report.Application_Root_Ensured := A11y.Results.Succeeded (Result);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Start_From_Address_With_Report;

   procedure Start_From_Environment_Value
     (Session          : in out Backend_Session;
      Value            : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
      Report : Session_Startup_Report;
   begin
      Start_From_Environment_Value_With_Report
        (Session, Value, User_Id, Application_Node, Report, Result);
   end Start_From_Environment_Value;

   procedure Start_From_Environment_Value_With_Report
     (Session          : in out Backend_Session;
      Value            : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Report           : out Session_Startup_Report;
      Result           : out A11y.Results.Result)
   is
      Startup_Result : A11y.Results.Result;
   begin
      Report := (others => <>);
      Report.Source := Environment_Value;

      A11y.Linux.ATSPi_Startup.Prepare_From_Environment_Value
        (Session.Startup, Value, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;
      Report.Prepared := True;

      A11y.Linux.ATSPi_Startup.Start_With_Report
        (Session.Startup, User_Id, Application_Node, Session.Limits,
         Report.Registration, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Backend_Adapter.Synchronize_Startup_With_Report
        (Session.Backend, Session.Startup, Report.Backend_Synchronization,
         Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;
      Report.Backend_Synchronized := True;

      Ensure_Application_Root (Session, Application_Node, Result);
      Report.Application_Root_Ensured := A11y.Results.Succeeded (Result);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Start_From_Environment_Value_With_Report;

   procedure Start_From_Host_Environment
     (Session          : in out Backend_Session;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
      Report : Session_Startup_Report;
   begin
      Start_From_Host_Environment_With_Report
        (Session, User_Id, Application_Node, Report, Result);
   end Start_From_Host_Environment;

   procedure Start_From_Host_Environment_With_Report
     (Session          : in out Backend_Session;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Report           : out Session_Startup_Report;
      Result           : out A11y.Results.Result)
   is
      Startup_Result : A11y.Results.Result;
      Host_Report : A11y.Linux.ATSPi_Startup
        .Host_Environment_Startup_Report;
   begin
      Report := (others => <>);

      A11y.Linux.ATSPi_Startup.Prepare_From_Host_Environment_With_Report
        (Session.Startup, User_Id, Session.Limits, Host_Report,
         Startup_Result);

      Report.Host_AT_SPI_Address_Present :=
        Host_Report.AT_SPI_Address_Present;
      Report.Host_Session_Bus_Address_Present :=
        Host_Report.Session_Bus_Address_Present;
      Report.Discovery_Attempted := Host_Report.Discovery_Attempted;
      Report.Discovery := Host_Report.Discovery;
      Report.Source :=
        (if Report.Host_AT_SPI_Address_Present
         then Host_AT_SPI_Bus_Address
         elsif Report.Host_Session_Bus_Address_Present
         then Host_Session_Bus_Address
         else Host_Environment_Missing);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;
      Report.Prepared := True;

      A11y.Linux.ATSPi_Startup.Start_With_Report
        (Session.Startup, User_Id, Application_Node, Session.Limits,
         Report.Registration, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Backend_Adapter.Synchronize_Startup_With_Report
        (Session.Backend, Session.Startup, Report.Backend_Synchronization,
         Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;
      Report.Backend_Synchronized := True;

      Ensure_Application_Root (Session, Application_Node, Result);
      Report.Application_Root_Ensured := A11y.Results.Succeeded (Result);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Start_From_Host_Environment_With_Report;

   procedure Start_From_Session_Bus_Address
     (Session             : in out Backend_Session;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node    : A11y.Node_Ids.Node_Id;
      Result              : out A11y.Results.Result)
   is
      Report : Session_Startup_Report;
   begin
      Start_From_Session_Bus_Address_With_Report
        (Session, Session_Bus_Address, User_Id, Application_Node, Report,
         Result);
   end Start_From_Session_Bus_Address;

   procedure Start_From_Session_Bus_Address_With_Report
     (Session             : in out Backend_Session;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node    : A11y.Node_Ids.Node_Id;
      Report              : out Session_Startup_Report;
      Result              : out A11y.Results.Result)
   is
      Startup_Result : A11y.Results.Result;
   begin
      Report := (others => <>);
      Report.Source :=
        A11y.Linux.ATSPi_Backend_Sessions.Session_Bus_Address;

      Report.Discovery_Attempted := True;
      A11y.Linux.ATSPi_Startup.Prepare_From_Session_Bus_Address_With_Report
        (Session.Startup, Session_Bus_Address, User_Id, Session.Limits,
         Report.Discovery, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;
      Report.Prepared := True;

      A11y.Linux.ATSPi_Startup.Start_With_Report
        (Session.Startup, User_Id, Application_Node, Session.Limits,
         Report.Registration, Startup_Result);
      if A11y.Results.Failed (Startup_Result) then
         A11y.Linux.ATSPi_Backend_Adapter.Apply_Startup_Result
           (Session.Backend, Startup_Result, Result);
         Report.Status := Startup_Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Backend_Adapter.Synchronize_Startup_With_Report
        (Session.Backend, Session.Startup, Report.Backend_Synchronization,
         Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;
      Report.Backend_Synchronized := True;

      Ensure_Application_Root (Session, Application_Node, Result);
      Report.Application_Root_Ensured := A11y.Results.Succeeded (Result);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Start_From_Session_Bus_Address_With_Report;

   procedure Pump_Registered_Bounded
     (Session        : in out Backend_Session;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Result         : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Pump_Registered_Bounded_With_Report
        (Session.Startup, Session.Registry, Snapshots, Session.Limits,
         Max_Iterations, Report, Result);
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
   end Pump_Registered_Bounded;

   procedure Flush_One_Outgoing
     (Session : in out Backend_Session;
      Result  : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Flush_One_Outgoing
        (Session.Startup, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Flush_One_Outgoing;

   procedure Flush_Bounded_Outgoing
     (Session        : in out Backend_Session;
      Max_Iterations : Natural;
      Flushed        : out Natural;
      Result         : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Flush_Bounded_Outgoing
        (Session.Startup, Max_Iterations, Flushed, Result);
   exception
      when others =>
         Flushed := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Flush_Bounded_Outgoing;

   procedure Wait_Writable
     (Session    : in out Backend_Session;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Wait_Writable
        (Session.Startup, Timeout_MS, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Wait_Writable;

   procedure Complete_Outgoing
     (Session : in out Backend_Session;
      Serial  : Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Complete_Outgoing
        (Session.Startup, Serial, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Outgoing;

   procedure Drive_One_Event_Loop_Step
     (Session   : in out Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Event_Loop_Step_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      Drive_One_Event_Loop_Step
        (Session, Snapshots, 0, Report, Result);
   end Drive_One_Event_Loop_Step;

   procedure Drive_One_Event_Loop_Step
     (Session         : in out Backend_Session;
      Snapshots       : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Read_Timeout_MS : Integer;
      Report          : out Event_Loop_Step_Report;
      Result          : out A11y.Results.Result)
   is
      Flushed : Natural := 0;
      Pump_Report : A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Wait_Result : A11y.Results.Result;
   begin
      Report := (others => <>);
      Report.Interest_Before :=
        A11y.Linux.ATSPi_Startup.Interest (Session.Startup);
      Report.Operation := Report.Interest_Before.Next_Operation;

      if Report.Operation = A11y.Linux.ATSPi_Startup.No_Operation
        and then Read_Timeout_MS > 0
      then
         Report.Wait_Attempted := True;
         A11y.Linux.ATSPi_Startup.Wait_Readable
           (Session.Startup, Read_Timeout_MS, Wait_Result);
         if A11y.Results.Succeeded (Wait_Result) then
            Report.Wait_Readable := True;
            Report.Interest_Before :=
              A11y.Linux.ATSPi_Startup.Interest (Session.Startup);
            Report.Operation := Report.Interest_Before.Next_Operation;
         elsif Wait_Result.Status = A11y.Results.Timed_Out then
            Report.Wait_Timed_Out := True;
            Report.Stop_Reason :=
              A11y.Linux.ATSPi_Startup.No_Readable_Packet;
         else
            Result := Wait_Result;
            Report.Stop_Reason :=
              A11y.Linux.ATSPi_Startup.Readiness_Failed;
            Report.Interest_After :=
              A11y.Linux.ATSPi_Startup.Interest (Session.Startup);
            Report.Status := Result.Status;
            return;
         end if;
      end if;

      case Report.Operation is
         when A11y.Linux.ATSPi_Startup.Write_Outgoing =>
            Report.Write_Wait_Attempted := True;
            Wait_Writable (Session, Read_Timeout_MS, Wait_Result);
            Report.Write_Wait_Status := Wait_Result.Status;
            if A11y.Results.Succeeded (Wait_Result) then
               Report.Write_Ready := True;
               Report.Flush_Attempted := True;
               Flush_Bounded_Outgoing (Session, 1, Flushed, Result);
               Report.Flushed := Flushed;
               if A11y.Results.Failed (Result) then
                  Report.Stop_Reason :=
                    A11y.Linux.ATSPi_Startup.Readiness_Failed;
               else
                  Report.Stop_Reason :=
                    A11y.Linux.ATSPi_Startup.Not_Stopped;
               end if;
            elsif Wait_Result.Status = A11y.Results.Timed_Out then
               Result := Wait_Result;
               Report.Write_Timed_Out := True;
               Report.Stop_Reason :=
                 A11y.Linux.ATSPi_Startup.No_Readable_Packet;
            else
               Result := Wait_Result;
               Report.Stop_Reason :=
                 A11y.Linux.ATSPi_Startup.Readiness_Failed;
            end if;

         when A11y.Linux.ATSPi_Startup.Read_And_Dispatch =>
            Report.Pump_Attempted := True;
            Pump_Registered_Bounded
              (Session, Snapshots, 1, Pump_Report, Result);
            Report.Pump := Pump_Report;
            Report.Stop_Reason := Pump_Report.Stop_Reason;

         when A11y.Linux.ATSPi_Startup.No_Operation =>
            Result := (Status => Report.Interest_Before.Pump_Status);
            Report.Stop_Reason :=
              A11y.Linux.ATSPi_Startup.No_Readable_Packet;

         when A11y.Linux.ATSPi_Startup.Wait_For_Transport |
              A11y.Linux.ATSPi_Startup.Transport_Failed =>
            Result := (Status => Report.Interest_Before.Pump_Status);
            Report.Stop_Reason :=
              A11y.Linux.ATSPi_Startup.Readiness_Failed;
      end case;

      Report.Interest_After :=
        A11y.Linux.ATSPi_Startup.Interest (Session.Startup);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Stop_Reason := A11y.Linux.ATSPi_Startup.Iteration_Failed;
         Report.Status := Result.Status;
   end Drive_One_Event_Loop_Step;

   procedure Accumulate_Event_Loop_Pump
     (Total : in out A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Step  : A11y.Linux.ATSPi_Startup.Pump_Bounded_Report)
   is
   begin
      Total.Iterations_Attempted :=
        Total.Iterations_Attempted + Step.Iterations_Attempted;
      Total.Iterations_Completed :=
        Total.Iterations_Completed + Step.Iterations_Completed;
      Total.Reads_Attempted := Total.Reads_Attempted + Step.Reads_Attempted;
      Total.Packets_Received :=
        Total.Packets_Received + Step.Packets_Received;
      Total.Packets_Dispatched :=
        Total.Packets_Dispatched + Step.Packets_Dispatched;
      Total.Replies_Written :=
        Total.Replies_Written + Step.Replies_Written;
      Total.Registered_Method_Calls :=
        Total.Registered_Method_Calls + Step.Registered_Method_Calls;
      Total.Registered_Replies :=
        Total.Registered_Replies + Step.Registered_Replies;
      Total.Registered_Replies_In_Flight :=
        Total.Registered_Replies_In_Flight
        + Step.Registered_Replies_In_Flight;
      Total.Registered_Drained_Calls :=
        Total.Registered_Drained_Calls + Step.Registered_Drained_Calls;
      Total.Registered_Boundary_Resolved_Calls :=
        Total.Registered_Boundary_Resolved_Calls
        + Step.Registered_Boundary_Resolved_Calls;
      Total.Registered_Boundary_Admitted_Calls :=
        Total.Registered_Boundary_Admitted_Calls
        + Step.Registered_Boundary_Admitted_Calls;
      Total.Registered_Boundary_Completed_Calls :=
        Total.Registered_Boundary_Completed_Calls
        + Step.Registered_Boundary_Completed_Calls;

      if Step.Last_Registered_Reply_Serial /= 0 then
         Total.Last_Registered_Reply_Serial :=
           Step.Last_Registered_Reply_Serial;
         Total.Last_Registered_Reply_In_Flight :=
           Step.Last_Registered_Reply_In_Flight;
      end if;

      if Step.Registered_Method_Calls /= 0 then
         Total.Last_Registered_Boundary_Status :=
           Step.Last_Registered_Boundary_Status;
         Total.Last_Registered_Begin_Outstanding_Before :=
           Step.Last_Registered_Begin_Outstanding_Before;
         Total.Last_Registered_Begin_Outstanding_After :=
           Step.Last_Registered_Begin_Outstanding_After;
         Total.Last_Registered_End_Outstanding_Before :=
           Step.Last_Registered_End_Outstanding_Before;
         Total.Last_Registered_End_Outstanding_After :=
           Step.Last_Registered_End_Outstanding_After;
      end if;

      Total.Pending_Outgoing := Step.Pending_Outgoing;
      Total.In_Flight_Outgoing := Step.In_Flight_Outgoing;
      Total.Stop_Reason := Step.Stop_Reason;
      Total.Status := Step.Status;
   end Accumulate_Event_Loop_Pump;

   procedure Drive_Bounded_Event_Loop
     (Session        : in out Backend_Session;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out Event_Loop_Bounded_Report;
      Result         : out A11y.Results.Result)
   is
   begin
      Drive_Bounded_Event_Loop
        (Session, Snapshots, Max_Iterations, 0, Report, Result);
   end Drive_Bounded_Event_Loop;

   procedure Drive_Bounded_Event_Loop
     (Session         : in out Backend_Session;
      Snapshots       : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations  : Natural;
      Read_Timeout_MS : Integer;
      Report          : out Event_Loop_Bounded_Report;
      Result          : out A11y.Results.Result)
   is
      Step_Report : Event_Loop_Step_Report;
      Step_Result : A11y.Results.Result;
   begin
      Report := (others => <>);

      if Max_Iterations = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         Report.Stop_Reason := A11y.Linux.ATSPi_Startup.Invalid_Limit;
         Report.Status := Result.Status;
         Report.Pump.Status := Result.Status;
         Report.Pump.Stop_Reason := A11y.Linux.ATSPi_Startup.Invalid_Limit;
         Session.Last_Event_Loop := Report;
         Session.Has_Event_Loop_Report := True;
         return;
      end if;

      for Iteration in 1 .. Max_Iterations loop
         Report.Steps_Attempted := Report.Steps_Attempted + 1;
         Drive_One_Event_Loop_Step
         (Session, Snapshots, Read_Timeout_MS, Step_Report, Step_Result);
         Report.Last_Operation := Step_Report.Operation;
         Report.Last_Step_Status := Step_Report.Status;
         Report.Last_Step_Stop_Reason := Step_Report.Stop_Reason;
         Report.Last_Interest_Before := Step_Report.Interest_Before;
         Report.Last_Interest_After := Step_Report.Interest_After;
         Report.Last_Write_Wait_Status := Step_Report.Write_Wait_Status;
         if Step_Report.Wait_Attempted then
            Report.Wait_Attempts := Report.Wait_Attempts + 1;
         end if;
         if Step_Report.Wait_Timed_Out then
            Report.Wait_Timeouts := Report.Wait_Timeouts + 1;
         end if;
         if Step_Report.Wait_Readable then
            Report.Wait_Readable := Report.Wait_Readable + 1;
         end if;
         if Step_Report.Write_Wait_Attempted then
            Report.Write_Wait_Attempts := Report.Write_Wait_Attempts + 1;
         end if;
         if Step_Report.Flush_Attempted then
            Report.Write_Attempts := Report.Write_Attempts + 1;
         end if;
         if Step_Report.Write_Ready then
            Report.Write_Ready := Report.Write_Ready + 1;
         end if;
         if Step_Report.Write_Timed_Out then
            Report.Write_Timeouts := Report.Write_Timeouts + 1;
         end if;
         Report.Flushed := Report.Flushed + Step_Report.Flushed;

         if Step_Report.Pump_Attempted then
            Accumulate_Event_Loop_Pump (Report.Pump, Step_Report.Pump);
            Report.Stop_Reason := Step_Report.Pump.Stop_Reason;
         elsif Step_Report.Operation =
           A11y.Linux.ATSPi_Startup.No_Operation
         then
            Report.Stop_Reason :=
              A11y.Linux.ATSPi_Startup.No_Readable_Packet;
            Report.Pump.Stop_Reason := Report.Stop_Reason;
         elsif Step_Report.Operation =
           A11y.Linux.ATSPi_Startup.Write_Outgoing
         then
            Report.Stop_Reason := A11y.Linux.ATSPi_Startup.Not_Stopped;
            Report.Pump.Stop_Reason := Report.Stop_Reason;
            Report.Pump.Pending_Outgoing :=
              Step_Report.Interest_After.Pending_Outgoing;
            Report.Pump.In_Flight_Outgoing :=
              Step_Report.Interest_After.In_Flight_Outgoing;
         else
            Report.Stop_Reason :=
              A11y.Linux.ATSPi_Startup.Readiness_Failed;
            Report.Pump.Stop_Reason := Report.Stop_Reason;
         end if;

         Report.Status := Step_Result.Status;
         Report.Pump.Status := Step_Result.Status;
         Result := Step_Result;
         if A11y.Results.Failed (Step_Result) then
            Session.Last_Event_Loop := Report;
            Session.Has_Event_Loop_Report := True;
            return;
         end if;

         Report.Steps_Completed := Report.Steps_Completed + 1;
         exit when Step_Report.Operation =
           A11y.Linux.ATSPi_Startup.No_Operation;
      end loop;

      if Report.Steps_Completed = Max_Iterations
        and then Report.Last_Operation /=
          A11y.Linux.ATSPi_Startup.No_Operation
      then
         Report.Stop_Reason :=
           A11y.Linux.ATSPi_Startup.Iteration_Limit_Reached;
         Report.Pump.Stop_Reason := Report.Stop_Reason;
      end if;

      Result := A11y.Results.Ok;
      Report.Status := Result.Status;
      Report.Pump.Status := Result.Status;
      Session.Last_Event_Loop := Report;
      Session.Has_Event_Loop_Report := True;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
         Report.Pump.Status := Result.Status;
         Report.Stop_Reason := A11y.Linux.ATSPi_Startup.Iteration_Failed;
         Report.Pump.Stop_Reason := Report.Stop_Reason;
         Session.Last_Event_Loop := Report;
         Session.Has_Event_Loop_Report := True;
   end Drive_Bounded_Event_Loop;

   procedure Serve_Registered_Packet
     (Session   : in out Backend_Session;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Serve_Registered_Packet
        (Session.Startup, Session.Registry, Bytes, Snapshots, Session.Limits,
         Packet, Report, Result);
   exception
      when others =>
         Packet :=
           (Metadata =>
              (Kind               => A11y.Linux.DBus_Messages.Error_Return,
               Serial             => 0,
               Reply_Serial       => 0,
               Header_Field_Count => 0,
               Body_Field_Count   => 0,
               Header_Text_Bytes  => 0,
               Body_Text_Bytes    => 0,
               Estimated_Bytes    => 0),
            Bytes => Null_Unbounded_String);
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Serve_Registered_Packet;

   procedure Serve_One_Transport_Cycle
     (Session   : in out Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Transport_Serve_Cycle_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Serve_One_Transport_Cycle_With_Report
        (Session.Startup, Session.Registry, Snapshots, Session.Limits,
         Report, Result);
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Serve_One_Transport_Cycle;

   procedure Queue_Event_Signal
     (Session : in out Backend_Session;
      Event   : A11y.Events.Event;
      Result  : out A11y.Results.Result)
   is
      Report : Event_Signal_Queue_Report;
   begin
      Queue_Event_Signal_With_Report (Session, Event, Report, Result);
   end Queue_Event_Signal;

   procedure Queue_Event_Signal_With_Report
     (Session : in out Backend_Session;
      Event   : A11y.Events.Event;
      Report  : out Event_Signal_Queue_Report;
      Result  : out A11y.Results.Result)
   is
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Prepared_Report : Prepared_Signal_Queue_Report;
      Validation : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
   begin
      Report :=
        (Event_Valid                 => A11y.Results.Succeeded (Validation),
         Source                      => Event.Source,
         Sequence                    => Event.Sequence,
         Revision                    => Event.Revision,
         Prepared_Publication_Status => A11y.Results.Node_Unavailable,
         Prepared_Available          => False,
         Prepared_Status             => A11y.Results.Node_Unavailable,
         Prepared_Queue              => <>,
         Status                      => A11y.Results.Node_Unavailable);

      if A11y.Results.Failed (Validation) then
         Result := Validation;
         Report.Prepared_Publication_Status := Result.Status;
         Report.Prepared_Status := Result.Status;
         Report.Status := Result.Status;
         return;
      end if;

      A11y.Backends.Native_Backends.Prepare_Publication
        (Session.Backend, Event, Prepared, Result);
      Report.Prepared_Publication_Status := Result.Status;
      Report.Prepared_Status := Prepared.Status;
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;

      Report.Prepared_Available := True;
      Queue_Prepared_Event_Signal_With_Report
        (Session, Prepared, Prepared_Report, Result);
      Report.Prepared_Queue := Prepared_Report;
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Event_Signal_With_Report;

   procedure Queue_Prepared_Event_Signal
     (Session  : in out Backend_Session;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result   : out A11y.Results.Result)
   is
      Report : Prepared_Signal_Queue_Report;
   begin
      Queue_Prepared_Event_Signal_With_Report
        (Session, Prepared, Report, Result);
   end Queue_Prepared_Event_Signal;

   procedure Queue_Prepared_Event_Signal_With_Report
     (Session  : in out Backend_Session;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Report   : out Prepared_Signal_Queue_Report;
      Result   : out A11y.Results.Result)
   is
      Signal : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Registered : constant Boolean :=
        A11y.Linux.ATSPi_Startup.Registered (Session.Startup);
      Pending_Before : constant Natural :=
        A11y.Linux.ATSPi_Startup.Pending_Outgoing_Count (Session.Startup);
      Validation : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Prepared.Event);
      Prepared_Validation : constant A11y.Results.Result :=
        A11y.Native_Runtimes.Validate_Prepared_Event (Prepared);
   begin
      Report :=
        (Registered              => Registered,
         Pending_Outgoing_Before => Pending_Before,
         Pending_Outgoing_After  => Pending_Before,
         Source                  => Prepared.Event.Source,
         Sequence                => Prepared.Event.Sequence,
         Revision                => Prepared.Event.Revision,
         Event_Valid             => A11y.Results.Succeeded (Validation),
         Prepared_Status         => Prepared.Status,
         Prepared_Validation_Status => Prepared_Validation.Status,
         Prepared_Has_Object     => Prepared.Has_Object,
         Prepared_Destroys_Node  => Prepared.Destroys_Node,
         Signal_Built            => False,
         Signal_Publishable      => False,
         Signal_Status           => A11y.Results.Node_Unavailable,
         Enqueued                => False,
         Status                  => A11y.Results.Node_Unavailable);

      if A11y.Results.Failed (Validation) then
         Result := Validation;
         Report.Status := Result.Status;
         return;
      elsif not Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         Report.Status := Result.Status;
         return;
      elsif A11y.Results.Failed (Prepared_Validation) then
         Result := Prepared_Validation;
         Report.Status := Result.Status;
         return;
      end if;

      Signal := A11y.Linux.ATSPi_Signals.Build_Signal
        (A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup), Prepared);
      Report.Signal_Built := True;
      Report.Signal_Publishable := Signal.Publishable;
      Report.Signal_Status := Signal.Status;
      if not Signal.Publishable then
         Result := (Status => Signal.Status);
         Report.Status := Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Startup.Queue_Signal
        (Session.Startup, Signal, Session.Limits, Result);
      Report.Pending_Outgoing_After :=
        A11y.Linux.ATSPi_Startup.Pending_Outgoing_Count (Session.Startup);
      Report.Enqueued := A11y.Results.Succeeded (Result);
      Report.Status := Result.Status;
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Prepared_Event_Signal_With_Report;

   procedure Stop
     (Session : in out Backend_Session;
      Result  : out A11y.Results.Result)
   is
      Report : Session_Stop_Report;
   begin
      Stop_With_Report (Session, Report, Result);
   end Stop;

   procedure Stop_With_Report
     (Session : in out Backend_Session;
      Report  : out Session_Stop_Report;
      Result  : out A11y.Results.Result)
   is
      Startup_Result : A11y.Results.Result;
      Registry_Result : A11y.Results.Result;
      Backend_Result : A11y.Results.Result;
      Backend_Report : A11y.Backends.Native_Backends.Transport_Transition_Report;
      Application_Object :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Application_Find_Result : A11y.Results.Result;
      Application_Defunct_Result : A11y.Results.Result;
      Application_Release_Result : A11y.Results.Result;
   begin
      Report :=
        (Startup_Interest_Before =>
           A11y.Linux.ATSPi_Startup.Interest (Session.Startup),
         Startup_Interest_After  =>
           A11y.Linux.ATSPi_Startup.Interest (Session.Startup),
         Registry_Before         =>
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Session.Registry),
         Registry_After          =>
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Session.Registry),
         Backend_Before          => Session.Backend.Transport_Status,
         Backend_After           => Session.Backend.Transport_Status,
         Application_Node_Before => Session.Application_Node,
         Application_Node_After  => Session.Application_Node,
         Startup_Stop_Attempted  => False,
         Startup_Stopped         => False,
         Startup_Status          => A11y.Results.Backend_Unavailable,
         Registry_Reset_Attempted => False,
         Registry_Reset          => False,
         Registry_Status         => A11y.Results.Backend_Unavailable,
         Backend_Stop_Attempted  => False,
         Backend_Stopped         => False,
         Backend_Status          => A11y.Results.Backend_Unavailable,
         Application_Node_Cleared => False,
         Status                  => A11y.Results.Backend_Unavailable);

      if A11y.Node_Ids.Is_Valid (Session.Application_Node) then
         A11y.Linux.ATSPi_Object_Registry.Find_Object
           (Session.Registry,
            A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup),
            Session.Application_Node,
            Application_Object,
            Application_Find_Result);

         if A11y.Results.Succeeded (Application_Find_Result) then
            A11y.Linux.ATSPi_Object_Registry.Mark_Defunct
              (Session.Registry,
               A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup),
               Session.Application_Node,
               Application_Defunct_Result);

            if A11y.Results.Succeeded (Application_Defunct_Result) then
               A11y.Linux.ATSPi_Object_Registry.Release
                 (Session.Registry,
                  A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup),
                  Application_Object.Object,
                  Application_Release_Result);
            end if;
         end if;
      end if;

      Report.Startup_Stop_Attempted := True;
      A11y.Linux.ATSPi_Startup.Stop (Session.Startup, Startup_Result);
      Report.Startup_Interest_After :=
        A11y.Linux.ATSPi_Startup.Interest (Session.Startup);
      Report.Startup_Stopped := A11y.Results.Succeeded (Startup_Result);
      Report.Startup_Status := Startup_Result.Status;

      Report.Registry_Reset_Attempted := True;
      A11y.Linux.ATSPi_Object_Registry.Reset (Session.Registry);
      Registry_Result :=
        (if A11y.Linux.ATSPi_Object_Registry.Drained (Session.Registry)
         then A11y.Results.Ok
         else (Status => A11y.Results.Busy));
      Report.Registry_After :=
        A11y.Linux.ATSPi_Object_Registry.Snapshot (Session.Registry);
      Report.Registry_Reset := A11y.Results.Succeeded (Registry_Result);
      Report.Registry_Status := Registry_Result.Status;

      Report.Backend_Stop_Attempted := True;
      A11y.Backends.Native_Backends.Stop_With_Report
        (Session.Backend, Backend_Report, Backend_Result);
      Report.Backend_After := Session.Backend.Transport_Status;
      Report.Backend_Stopped := A11y.Results.Succeeded (Backend_Result);
      Report.Backend_Status := Backend_Result.Status;

      if A11y.Results.Failed (Startup_Result) then
         Result := Startup_Result;
      elsif A11y.Results.Failed (Registry_Result) then
         Result := Registry_Result;
      else
         if A11y.Results.Succeeded (Backend_Result) then
            Session.Application_Node := A11y.Node_Ids.No_Node;
         end if;
         Result := Backend_Result;
      end if;
      Report.Application_Node_After := Session.Application_Node;
      Report.Application_Node_Cleared :=
        A11y.Node_Ids.Is_Valid (Report.Application_Node_Before)
        and then not A11y.Node_Ids.Is_Valid (Report.Application_Node_After);
      Report.Status := Result.Status;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Stop_With_Report;

   function Backend_Status
     (Session : Backend_Session)
      return A11y.Backends.Native_Backends.Transport_Snapshot is
     (Session.Backend.Transport_Status);

   procedure Capture_Report
     (Session : in out Backend_Session;
      Report  : out Session_Report)
   is
      Descriptor :
        A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor;
   begin
      Report.Transport := Session.Backend.Transport_Status;
      Report.Interest :=
        A11y.Linux.ATSPi_Startup.Interest (Session.Startup);
      Report.Startup_State :=
        A11y.Linux.ATSPi_Startup.State (Session.Startup);
      Report.Registered :=
        A11y.Linux.ATSPi_Startup.Registered (Session.Startup);
      Report.Application_Node := Session.Application_Node;
      Report.Has_Application_Node :=
        A11y.Node_Ids.Is_Valid (Session.Application_Node);
      Report.Registry :=
        A11y.Linux.ATSPi_Object_Registry.Snapshot (Session.Registry);
      Report.Last_Event_Loop := Session.Last_Event_Loop;
      Report.Has_Event_Loop_Report := Session.Has_Event_Loop_Report;

      Application_Descriptor (Session, Descriptor);
      Report.Application := Descriptor;
      Report.Application_Exportable := Descriptor.Exportable;
      Report.Application_Status := Descriptor.Status;
      Report.Status := A11y.Results.Success;
   exception
      when others =>
         Report := (others => <>);
         Report.Status := A11y.Results.Internal_Error;
   end Capture_Report;

   function Startup_Interest
     (Session : Backend_Session)
      return A11y.Linux.ATSPi_Startup.Event_Loop_Interest is
     (A11y.Linux.ATSPi_Startup.Interest (Session.Startup));

   procedure Wait_Readable
     (Session    : Backend_Session;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Startup.Wait_Readable
        (Session.Startup, Timeout_MS, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Wait_Readable;

   function Startup_State
     (Session : Backend_Session)
      return A11y.Linux.ATSPi_Bus.Connection_State is
     (A11y.Linux.ATSPi_Startup.State (Session.Startup));

   function Registered (Session : Backend_Session) return Boolean is
     (A11y.Linux.ATSPi_Startup.Registered (Session.Startup));

   function Unique_Name (Session : Backend_Session) return String is
   begin
      return A11y.Linux.ATSPi_Startup.Unique_Name (Session.Startup);
   exception
      when others =>
         return "";
   end Unique_Name;

   procedure Application_Descriptor
     (Session    : in out Backend_Session;
      Descriptor : out A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor)
   is
   begin
      Node_Descriptor (Session, Session.Application_Node, Descriptor);
   end Application_Descriptor;

   procedure Node_Descriptor
     (Session    : in out Backend_Session;
      Node        : A11y.Node_Ids.Node_Id;
      Descriptor : out A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor)
   is
      Snapshot :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Result : A11y.Results.Result;
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         Descriptor := (others => <>);
         Descriptor.Status := A11y.Results.Node_Unavailable;
         return;
      elsif not A11y.Linux.ATSPi_Startup.Registered (Session.Startup) then
         Descriptor := (others => <>);
         Descriptor.Status := A11y.Results.Backend_Unavailable;
         return;
      end if;

      A11y.Linux.ATSPi_Object_Registry.Ensure_Object
        (Session.Registry,
         A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup),
         Node,
         Snapshot,
         Result);
      if A11y.Results.Failed (Result) then
         Descriptor := (others => <>);
         Descriptor.Status := Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Object_Registry.Export_Descriptor
        (Session.Registry,
         Snapshot.Session,
         Snapshot.Object,
         Descriptor);
   exception
      when others =>
         Descriptor := (others => <>);
         Descriptor.Status := A11y.Results.Internal_Error;
   end Node_Descriptor;

   function Boundary_Error
     (Status : A11y.Results.Status_Code)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply is
     (Kind       => A11y.Linux.ATSPi_DBus_Boundary.Error_Reply,
      Status     => Status,
      Error_Name => To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Error_Name (Status)));

   function Dispatch_Application_Root_Method
     (Session        : in out Backend_Session;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply
   is
   begin
      if not A11y.Linux.ATSPi_Startup.Registered (Session.Startup) then
         return Boundary_Error (A11y.Results.Backend_Unavailable);
      end if;

      return Dispatch_Node_Method
        (Session, Session.Application_Node, Interface_Item, Method, Snapshots);
   end Dispatch_Application_Root_Method;

   function Dispatch_Application_Root_Method
     (Session        : in out Backend_Session;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Index          : Natural;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply
   is
   begin
      if not A11y.Linux.ATSPi_Startup.Registered (Session.Startup) then
         return Boundary_Error (A11y.Results.Backend_Unavailable);
      end if;

      return Dispatch_Node_Method
        (Session, Session.Application_Node, Interface_Item, Method, Index,
         Snapshots);
   end Dispatch_Application_Root_Method;

   function Dispatch_Node_Method
     (Session        : in out Backend_Session;
      Node           : A11y.Node_Ids.Node_Id;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply
   is
   begin
      return Dispatch_Node_Method
        (Session, Node, Interface_Item, Method, 0, Snapshots);
   end Dispatch_Node_Method;

   function Dispatch_Node_Method
     (Session        : in out Backend_Session;
      Node           : A11y.Node_Ids.Node_Id;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Index          : Natural;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply
   is
      Descriptor :
        A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor;
      Call : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
   begin
      Node_Descriptor (Session, Node, Descriptor);
      if not Descriptor.Exportable then
         return Boundary_Error (Descriptor.Status);
      end if;

      Call.Session := Descriptor.Session;
      Call.Object_Path := Descriptor.Path;
      Call.Interface_Name := To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Interface_Name (Interface_Item));
      Call.Method_Name := To_Unbounded_String (Method);
      Call.Index := Index;

      return A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
        (Session.Registry, Call, Snapshots);
   exception
      when others =>
         return Boundary_Error (A11y.Results.Internal_Error);
   end Dispatch_Node_Method;

   function Dispatch_Registered_Call
     (Session   : in out Backend_Session;
      Call      : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply
   is
      Report :
        A11y.Linux.ATSPi_DBus_Boundary.Registered_Call_Boundary_Report;
   begin
      return Dispatch_Registered_Call_With_Report
        (Session, Call, Snapshots, Report);
   end Dispatch_Registered_Call;

   function Dispatch_Registered_Call_With_Report
     (Session   : in out Backend_Session;
      Call      : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out A11y.Linux.ATSPi_DBus_Boundary
        .Registered_Call_Boundary_Report)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply
   is
      Expected_Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Linux.ATSPi_Startup.Session_Id (Session.Startup);
   begin
      Report := (others => <>);
      if not A11y.Linux.ATSPi_Startup.Registered (Session.Startup) then
         Report.Final_Status := A11y.Results.Backend_Unavailable;
         return Boundary_Error (A11y.Results.Backend_Unavailable);
      elsif Call.Session /= Expected_Session then
         Report.Final_Status := A11y.Results.Node_Unavailable;
         return Boundary_Error (A11y.Results.Node_Unavailable);
      end if;

      return A11y.Linux.ATSPi_DBus_Boundary
        .Dispatch_Registered_Call_With_Report
          (Session.Registry, Call, Snapshots, Report);
   exception
      when others =>
         Report.Final_Status := A11y.Results.Internal_Error;
         return Boundary_Error (A11y.Results.Internal_Error);
   end Dispatch_Registered_Call_With_Report;

   function Registry_Snapshot
     (Session : Backend_Session)
      return A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot is
     (A11y.Linux.ATSPi_Object_Registry.Snapshot (Session.Registry));

end A11y.Linux.ATSPi_Backend_Sessions;
