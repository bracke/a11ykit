with A11y.Linux.ATSPi_Address_Discovery;
with Hostkit.Process;

package body A11y.Linux.ATSPi_Startup is
   use Ada.Strings.Unbounded;
   use type A11y.Linux.ATSPi_Bus.Address_State;
   use type A11y.Linux.ATSPi_Bus.Connection_State;
   use type A11y.Linux.DBus_Messages.Queue_Posting_Operation;
   use type A11y.Results.Status_Code;

   procedure Prepare
     (Context : in out Startup_Context;
      Address : String;
      Result  : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
      A11y.Linux.ATSPi_Bus.Prepare_Connection
        (Context.Bus, Address, Result);
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare;

   procedure Prepare_From_Environment_Value
     (Context : in out Startup_Context;
      Value   : String;
      Result  : out A11y.Results.Result)
   is
      Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Source_Result : A11y.Results.Result;
   begin
      A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
      Address :=
        A11y.Linux.ATSPi_Address_Discovery.Discover_From_Environment_Value
          (Value, Result);
      if A11y.Results.Failed (Result) then
         Source_Result := Result;
         A11y.Linux.ATSPi_Bus.Disconnect (Context.Bus, Result);
         if Address.State = A11y.Linux.ATSPi_Bus.Address_Invalid then
            Context.Bus.State := A11y.Linux.ATSPi_Bus.Failed;
            Context.Bus.Address := Address;
         end if;
         Result := Source_Result;
         return;
      end if;

      Prepare (Context, To_String (Address.Text), Result);
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_From_Environment_Value;

   procedure Prepare_From_Host_Environment
     (Context : in out Startup_Context;
      Result  : out A11y.Results.Result)
   is
      Value : Hostkit.UString;
   begin
      if Hostkit.Process.Environment_Value
        (A11y.Linux.ATSPi_Address_Discovery.AT_SPI_Bus_Address_Variable,
         Value)
      then
         Prepare_From_Environment_Value (Context, To_String (Value), Result);
      else
         Prepare_From_Environment_Value (Context, "", Result);
      end if;
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_From_Host_Environment;

   procedure Prepare_From_Host_Environment
     (Context : in out Startup_Context;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result)
   is
   begin
      Prepare_From_Host_Environment
        (Context, User_Id, A11y.Resource_Limits.Default_Config, Result);
   end Prepare_From_Host_Environment;

   procedure Prepare_From_Host_Environment
     (Context : in out Startup_Context;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
      Report : Host_Environment_Startup_Report;
   begin
      Prepare_From_Host_Environment_With_Report
        (Context, User_Id, Limits, Report, Result);
   end Prepare_From_Host_Environment;

   procedure Prepare_From_Host_Environment_With_Report
     (Context : in out Startup_Context;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Report  : out Host_Environment_Startup_Report;
      Result  : out A11y.Results.Result)
   is
      Value : Hostkit.UString;
   begin
      Report := (others => <>);
      Report.AT_SPI_Address_Present := Hostkit.Process.Environment_Value
        (A11y.Linux.ATSPi_Address_Discovery.AT_SPI_Bus_Address_Variable,
         Value);

      if Report.AT_SPI_Address_Present then
         Prepare_From_Environment_Value (Context, To_String (Value), Result);
      else
         Report.Session_Bus_Address_Present := Hostkit.Process.Environment_Value
        (A11y.Linux.ATSPi_Address_Discovery
           .DBus_Session_Bus_Address_Variable,
         Value);

         if Report.Session_Bus_Address_Present then
            Report.Discovery_Attempted := True;
            Prepare_From_Session_Bus_Address_With_Report
              (Context, To_String (Value), User_Id, Limits, Report.Discovery,
               Result);
         else
            Prepare_From_Environment_Value (Context, "", Result);
         end if;
      end if;

      Report.Status := Result.Status;
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Result := (Status => A11y.Results.Internal_Error);
         Report := (others => <>);
         Report.Status := Result.Status;
   end Prepare_From_Host_Environment_With_Report;

   procedure Prepare_From_Session_Bus_Address
     (Context             : in out Startup_Context;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Result              : out A11y.Results.Result)
   is
   begin
      Prepare_From_Session_Bus_Address
        (Context, Session_Bus_Address, User_Id,
         A11y.Resource_Limits.Default_Config, Result);
   end Prepare_From_Session_Bus_Address;

   procedure Prepare_From_Session_Bus_Address
     (Context             : in out Startup_Context;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Limits              : A11y.Resource_Limits.Resource_Limit_Config;
      Result              : out A11y.Results.Result)
   is
   begin
      declare
         Report : Address_Discovery_Startup_Report;
      begin
         Prepare_From_Session_Bus_Address_With_Report
           (Context, Session_Bus_Address, User_Id, Limits, Report, Result);
      end;
   end Prepare_From_Session_Bus_Address;

   procedure Prepare_From_Session_Bus_Address_With_Report
     (Context             : in out Startup_Context;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Limits              : A11y.Resource_Limits.Resource_Limit_Config;
      Report              : out Address_Discovery_Startup_Report;
      Result              : out A11y.Results.Result)
   is
      Session_Context : A11y.Linux.ATSPi_Bus.Connection_Context;
      Session_Channel : A11y.Linux.ATSPi_Local_Channel.Channel;
      Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Discovery_Result : A11y.Results.Result;
      Cleanup_Result : A11y.Results.Result;
   begin
      Report := (others => <>);
      A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
      A11y.Linux.ATSPi_Bus.Prepare_Connection
        (Session_Context, Session_Bus_Address, Result);
      if A11y.Results.Failed (Result) then
         A11y.Linux.ATSPi_Bus.Disconnect (Context.Bus, Cleanup_Result);
         Report.Status := Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Local_Channel
        .Connect_Authenticated_Hello_And_Discover_With_Report
          (Session_Context, Session_Channel, User_Id, Limits, Address,
           Report, Result);
      Discovery_Result := Result;
      A11y.Linux.ATSPi_Local_Channel.Close (Session_Channel);
      A11y.Linux.ATSPi_Bus.Disconnect (Session_Context, Cleanup_Result);
      if A11y.Results.Failed (Discovery_Result) then
         Result := Discovery_Result;
         return;
      end if;

      Prepare (Context, To_String (Address.Text), Result);
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Session_Channel);
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Prepare_From_Session_Bus_Address_With_Report;

   procedure Start
     (Context          : in out Startup_Context;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
   begin
      Start
        (Context, User_Id, Application_Node,
         A11y.Resource_Limits.Default_Config, Result);
   end Start;

   procedure Start
     (Context          : in out Startup_Context;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
   is
      Report : Registration_Startup_Report;
   begin
      Start_With_Report
        (Context, User_Id, Application_Node, Limits, Report, Result);
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Result := (Status => A11y.Results.Internal_Error);
   end Start;

   procedure Start_With_Report
     (Context          : in out Startup_Context;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Report           : out Registration_Startup_Report;
      Result           : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Local_Channel
        .Connect_Authenticated_Hello_And_Register_With_Report
          (Context.Bus, Context.Channel, User_Id, Application_Node, Limits,
           Report, Result);
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Start_With_Report;

   procedure Stop
     (Context : in out Startup_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
      A11y.Linux.ATSPi_Bus.Disconnect (Context.Bus, Result);
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Context.Channel);
         Result := (Status => A11y.Results.Internal_Error);
   end Stop;

   function Can_Pump (Context : Startup_Context) return Boolean is
     (Context.Bus.State = A11y.Linux.ATSPi_Bus.Registered
      and then A11y.Linux.ATSPi_Local_Channel.Is_Open (Context.Channel));

   function Pending_Outgoing_Count (Context : Startup_Context) return Natural is
     (A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count (Context.Bus));

   function In_Flight_Outgoing_Count
     (Context : Startup_Context)
      return Natural is
     (A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count (Context.Bus));

   function In_Flight_Outgoing_Capacity
     (Context : Startup_Context)
      return Natural is
     (A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Capacity (Context.Bus));

   function Has_Outgoing_Work (Context : Startup_Context) return Boolean is
     (Pending_Outgoing_Count (Context) /= 0
      or else In_Flight_Outgoing_Count (Context) /= 0);

   function Interest
     (Context : Startup_Context)
      return Event_Loop_Interest
   is
      Ready : constant Boolean := Can_Pump (Context);
      Posting : constant A11y.Linux.DBus_Messages.Queue_Posting_Interest :=
        A11y.Linux.ATSPi_Bus.Posting_Interest (Context.Bus);
      In_Flight : constant Natural := In_Flight_Outgoing_Count (Context);
      In_Flight_Capacity : constant Natural :=
        In_Flight_Outgoing_Capacity (Context);
      Work : constant Boolean := Posting.Has_Pending or else In_Flight /= 0;
      Readable : Boolean := False;
      Readiness_Result : A11y.Results.Result := A11y.Results.Ok;
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      Operation : Event_Loop_Operation := No_Operation;
   begin
      if Context.Bus.State /= A11y.Linux.ATSPi_Bus.Registered then
         Status := A11y.Results.Backend_Unavailable;
         Operation := Wait_For_Transport;
      elsif not A11y.Linux.ATSPi_Local_Channel.Is_Open (Context.Channel) then
         Status := A11y.Results.Native_Failure;
         Operation := Transport_Failed;
      elsif Posting.Next_Operation =
        A11y.Linux.DBus_Messages.Send_Next_Message
      then
         Operation := Write_Outgoing;
      elsif Posting.Next_Operation = A11y.Linux.DBus_Messages.Back_Pressure
      then
         Status := A11y.Results.Resource_Limit;
         Operation := No_Operation;
      else
         A11y.Linux.ATSPi_Local_Channel.Wait_Readable
           (Context.Channel, 0, Readiness_Result);
         if A11y.Results.Succeeded (Readiness_Result) then
            Readable := True;
            Operation := Read_And_Dispatch;
         elsif Readiness_Result.Status = A11y.Results.Timed_Out then
            Operation := No_Operation;
         else
            Status := Readiness_Result.Status;
            Operation := Transport_Failed;
         end if;
      end if;

      return
        (Can_Read           => Ready and then Readable,
         Can_Write          => Ready and then Posting.Can_Send,
         Can_Dispatch       => Ready,
         Has_Outgoing_Work  => Work,
         Next_Operation     => Operation,
         Pump_Status        => Status,
         Pending_Outgoing   => Posting.Length,
         Pending_Capacity   => Posting.Capacity,
         Pending_Overflowed => Posting.Overflowed,
         In_Flight_Outgoing => In_Flight,
         In_Flight_Capacity => In_Flight_Capacity);
   exception
      when others =>
         return (others => <>);
   end Interest;

   procedure Check_Pump_Ready
     (Context : Startup_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      if Context.Bus.State /= A11y.Linux.ATSPi_Bus.Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
      elsif not A11y.Linux.ATSPi_Local_Channel.Is_Open (Context.Channel) then
         Result := (Status => A11y.Results.Native_Failure);
      else
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Check_Pump_Ready;

   procedure Wait_Readable
     (Context    : Startup_Context;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
   begin
      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.ATSPi_Local_Channel.Wait_Readable
        (Context.Channel, Timeout_MS, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Wait_Readable;

   procedure Wait_Writable
     (Context    : Startup_Context;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
   begin
      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.ATSPi_Local_Channel.Wait_Writable
        (Context.Channel, Timeout_MS, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Wait_Writable;

   procedure Flush_One_Outgoing
     (Context : in out Startup_Context;
      Result  : out A11y.Results.Result)
   is
      Posting : A11y.Linux.DBus_Messages.Queue_Posting_Interest;
   begin
      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Posting := A11y.Linux.ATSPi_Bus.Posting_Interest (Context.Bus);
      if Posting.Overflowed then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      elsif not Posting.Can_Send then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      A11y.Linux.ATSPi_Local_Channel.Send_Next_Packet
        (Context.Bus, Context.Channel, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Flush_One_Outgoing;

   procedure Flush_Bounded_Outgoing
     (Context        : in out Startup_Context;
      Max_Iterations : Natural;
      Flushed        : out Natural;
      Result         : out A11y.Results.Result)
   is
   begin
      Flushed := 0;
      if Max_Iterations = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      while Flushed < Max_Iterations
        and then Pending_Outgoing_Count (Context) /= 0
      loop
         Flush_One_Outgoing (Context, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
         Flushed := Flushed + 1;
      end loop;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Flushed := 0;
      Result := (Status => A11y.Results.Internal_Error);
   end Flush_Bounded_Outgoing;

   procedure Complete_Outgoing
     (Context : in out Startup_Context;
      Serial  : Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Bus.Complete_Outgoing
        (Context.Bus, Serial, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Outgoing;

   procedure Queue_Signal
     (Context : in out Startup_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Result  : out A11y.Results.Result)
   is
   begin
      Queue_Signal
        (Context, Signal, A11y.Resource_Limits.Default_Config, Result);
   end Queue_Signal;

   procedure Queue_Signal
     (Context : in out Startup_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
   begin
      A11y.Linux.ATSPi_Bus.Queue_Signal
        (Context.Bus, Signal, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Signal;

   procedure Finalize_Report
     (Context : Startup_Context;
      Report  : in out Pump_Activity_Report;
      Status  : A11y.Results.Status_Code)
   is
   begin
      Report.Pending_Outgoing := Pending_Outgoing_Count (Context);
      Report.In_Flight_Outgoing := In_Flight_Outgoing_Count (Context);
      Report.Status := Status;
   exception
      when others =>
         Report.Pending_Outgoing := 0;
         Report.In_Flight_Outgoing := 0;
      Report.Status := A11y.Results.Internal_Error;
   end Finalize_Report;

   procedure Finalize_Bounded_Report
     (Context : Startup_Context;
      Report  : in out Pump_Bounded_Report;
      Reason  : Pump_Bounded_Stop_Reason;
      Status  : A11y.Results.Status_Code)
   is
   begin
      Report.Pending_Outgoing := Pending_Outgoing_Count (Context);
      Report.In_Flight_Outgoing := In_Flight_Outgoing_Count (Context);
      Report.Stop_Reason := Reason;
      Report.Status := Status;
   exception
      when others =>
         Report.Pending_Outgoing := 0;
         Report.In_Flight_Outgoing := 0;
         Report.Stop_Reason := Iteration_Failed;
         Report.Status := A11y.Results.Internal_Error;
   end Finalize_Bounded_Report;

   procedure Accumulate_Bounded_Report
     (Report    : in out Pump_Bounded_Report;
      Iteration : Pump_Activity_Report)
   is
   begin
      if Iteration.Read_Attempted then
         Report.Reads_Attempted := Report.Reads_Attempted + 1;
      end if;
      if Iteration.Packet_Received then
         Report.Packets_Received := Report.Packets_Received + 1;
      end if;
      if Iteration.Packet_Dispatched then
         Report.Packets_Dispatched := Report.Packets_Dispatched + 1;
      end if;
      if Iteration.Reply_Written then
         Report.Replies_Written := Report.Replies_Written + 1;
      end if;
      if Iteration.Registered_Incoming_Method_Call then
         Report.Registered_Method_Calls :=
           Report.Registered_Method_Calls + 1;
         Report.Last_Registered_Incoming_Kind :=
           Iteration.Registered_Incoming_Kind;
         Report.Last_Registered_Incoming_Serial :=
           Iteration.Registered_Incoming_Serial;
         Report.Last_Registered_Incoming_Reply_Serial :=
           Iteration.Registered_Incoming_Reply_Serial;
      end if;
      if Iteration.Registered_Reply_Serialized then
         Report.Registered_Replies := Report.Registered_Replies + 1;
         Report.Last_Registered_Reply_Kind :=
           Iteration.Registered_Reply_Kind;
         Report.Last_Registered_Reply_Serial :=
           Iteration.Registered_Reply_Serial;
         Report.Last_Registered_Reply_Reply_Serial :=
           Iteration.Registered_Reply_Reply_Serial;
         Report.Last_Registered_Reply_Estimated_Bytes :=
           Iteration.Registered_Reply_Estimated_Bytes;
         Report.Last_Registered_Reply_In_Flight :=
           Iteration.Registered_Reply_In_Flight;
      end if;
      if Iteration.Registered_Reply_In_Flight then
         Report.Registered_Replies_In_Flight :=
           Report.Registered_Replies_In_Flight + 1;
      end if;
      if Iteration.Registered_Registry_Drained then
         Report.Registered_Drained_Calls :=
           Report.Registered_Drained_Calls + 1;
      end if;
      if Iteration.Registered_Boundary_Resolved then
         Report.Registered_Boundary_Resolved_Calls :=
           Report.Registered_Boundary_Resolved_Calls + 1;
      end if;
      if Iteration.Registered_Boundary_Admitted then
         Report.Registered_Boundary_Admitted_Calls :=
           Report.Registered_Boundary_Admitted_Calls + 1;
      end if;
      if Iteration.Registered_Boundary_Completed then
         Report.Registered_Boundary_Completed_Calls :=
           Report.Registered_Boundary_Completed_Calls + 1;
      end if;
      if Iteration.Registered_Incoming_Method_Call then
         Report.Last_Registered_Boundary_Status :=
           Iteration.Registered_Boundary_Status;
         Report.Last_Registered_Begin_Outstanding_Before :=
           Iteration.Registered_Begin_Outstanding_Before;
         Report.Last_Registered_Begin_Outstanding_After :=
           Iteration.Registered_Begin_Outstanding_After;
         Report.Last_Registered_End_Outstanding_Before :=
           Iteration.Registered_End_Outstanding_Before;
         Report.Last_Registered_End_Outstanding_After :=
           Iteration.Registered_End_Outstanding_After;
      end if;
   end Accumulate_Bounded_Report;

   procedure Finalize_Transport_Serve_Report
     (Context : Startup_Context;
      Report  : in out Transport_Serve_Cycle_Report;
      Status  : A11y.Results.Status_Code)
   is
   begin
      Report.Interest_After := Interest (Context);
      Report.Status := Status;
   exception
      when others =>
         Report.Status := A11y.Results.Internal_Error;
   end Finalize_Transport_Serve_Report;

   procedure Serve_One_Transport_Cycle_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Report    : out Transport_Serve_Cycle_Report;
      Result    : out A11y.Results.Result)
   is
      Incoming_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Reply_Packet    : A11y.Linux.DBus_Messages.Transport_Packet;
   begin
      Report := (others => <>);
      Report.Interest_Before := Interest (Context);

      Report.Ready_Checked := True;
      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         Report.Registered.Status := Result.Status;
         Finalize_Transport_Serve_Report (Context, Report, Result.Status);
         return;
      end if;

      Report.Read_Attempted := True;
      A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
        (Context.Channel, Limits, Incoming_Packet, Result);
      if A11y.Results.Failed (Result) then
         Report.Registered.Status := Result.Status;
         Finalize_Transport_Serve_Report (Context, Report, Result.Status);
         return;
      end if;
      Report.Packet_Received := True;
      Report.Incoming_Packet_Kind := Incoming_Packet.Metadata.Kind;
      Report.Incoming_Serial := Incoming_Packet.Metadata.Serial;
      Report.Incoming_Reply_Serial := Incoming_Packet.Metadata.Reply_Serial;
      Report.Incoming_Estimated_Bytes :=
        Incoming_Packet.Metadata.Estimated_Bytes;

      Report.Serve_Attempted := True;
      A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
        (Context.Bus, Registry, Incoming_Packet.Bytes, Snapshots, Limits,
         Reply_Packet, Report.Registered, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Transport_Serve_Report (Context, Report, Result.Status);
         return;
      end if;
      Report.Reply_Serialized := Report.Registered.Reply_Serialized;
      if Report.Reply_Serialized then
         Report.Reply_Packet_Kind := Reply_Packet.Metadata.Kind;
         Report.Reply_Serial := Reply_Packet.Metadata.Serial;
         Report.Reply_Reply_Serial := Reply_Packet.Metadata.Reply_Serial;
         Report.Reply_Estimated_Bytes :=
           Reply_Packet.Metadata.Estimated_Bytes;
      end if;

      if Report.Registered.Reply_Serialized then
         Report.Write_Attempted := True;
         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Context.Bus, Context.Channel, Reply_Packet, Result);
         if A11y.Results.Failed (Result) then
            Finalize_Transport_Serve_Report
              (Context, Report, Result.Status);
            return;
         end if;
         Report.Reply_Written := True;
      else
         Result := A11y.Results.Ok;
      end if;

      Finalize_Transport_Serve_Report (Context, Report, Result.Status);
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Finalize_Transport_Serve_Report (Context, Report, Result.Status);
   end Serve_One_Transport_Cycle_With_Report;

   procedure Serve_One_Transport_Cycle_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Transport_Serve_Cycle_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      Serve_One_Transport_Cycle_With_Report
        (Context, Registry, Snapshots, A11y.Resource_Limits.Default_Config,
         Report, Result);
   end Serve_One_Transport_Cycle_With_Report;

   procedure Pump_One_With_Report
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      Pump_One_With_Report
        (Context, Snapshots, A11y.Resource_Limits.Default_Config, Report,
         Result);
   end Pump_One_With_Report;

   procedure Pump_One_With_Report
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result)
   is
      Packet : A11y.Linux.DBus_Messages.Transport_Packet;
   begin
      Report := (others => <>);
      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Report (Context, Report, Result.Status);
         return;
      end if;

      Report.Read_Attempted := True;
      A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
        (Context.Channel, Limits, Packet, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Report (Context, Report, Result.Status);
         return;
      end if;
      Report.Packet_Received := True;

      A11y.Linux.ATSPi_Bus.Handle_Incoming_Packet
        (Context.Bus, Packet.Bytes, Snapshots, Limits, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Report (Context, Report, Result.Status);
         return;
      end if;
      Report.Packet_Dispatched := True;

      if Pending_Outgoing_Count (Context) /= 0 then
         A11y.Linux.ATSPi_Local_Channel.Send_Next_Packet
           (Context.Bus, Context.Channel, Result);
         if A11y.Results.Failed (Result) then
            Finalize_Report (Context, Report, Result.Status);
            return;
         end if;
         Report.Reply_Written := True;
      else
         Result := A11y.Results.Ok;
      end if;

      Finalize_Report (Context, Report, Result.Status);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report := (others => <>);
         Finalize_Report (Context, Report, Result.Status);
   end Pump_One_With_Report;

   procedure Pump_One
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
      Report : Pump_Activity_Report;
   begin
      Pump_One_With_Report
        (Context, Snapshots, A11y.Resource_Limits.Default_Config, Report,
         Result);
   end Pump_One;

   procedure Pump_One
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result)
   is
      Report : Pump_Activity_Report;
   begin
      Pump_One_With_Report (Context, Snapshots, Limits, Report, Result);
   end Pump_One;

   procedure Pump_Registered_One
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
      Report : Pump_Activity_Report;
   begin
      Pump_Registered_One_With_Report
        (Context, Registry, Snapshots, A11y.Resource_Limits.Default_Config,
         Report, Result);
   end Pump_Registered_One;

   procedure Pump_Registered_One
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result)
   is
      Report : Pump_Activity_Report;
   begin
      Pump_Registered_One_With_Report
        (Context, Registry, Snapshots, Limits, Report, Result);
   end Pump_Registered_One;

   procedure Pump_Registered_One_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      Pump_Registered_One_With_Report
        (Context, Registry, Snapshots, A11y.Resource_Limits.Default_Config,
         Report, Result);
   end Pump_Registered_One_With_Report;

   procedure Pump_Registered_One_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result)
   is
      Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Serve_Report : A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
   begin
      Report := (others => <>);
      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Report (Context, Report, Result.Status);
         return;
      end if;

      Report.Read_Attempted := True;
      A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
        (Context.Channel, Limits, Packet, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Report (Context, Report, Result.Status);
         return;
      end if;
      Report.Packet_Received := True;

      A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
        (Context.Bus, Registry, Packet.Bytes, Snapshots, Limits,
         Reply_Packet, Serve_Report, Result);
      if A11y.Results.Failed (Result) then
         Finalize_Report (Context, Report, Result.Status);
         return;
      end if;
      Report.Packet_Dispatched := Serve_Report.Packet_Classified;
      Report.Registered_Incoming_Kind := Serve_Report.Incoming_Kind;
      Report.Registered_Incoming_Method_Call :=
        Serve_Report.Incoming_Method_Call;
      Report.Registered_Incoming_Serial := Serve_Report.Incoming_Serial;
      Report.Registered_Incoming_Reply_Serial :=
        Serve_Report.Incoming_Reply_Serial;
      Report.Registered_Reply_Serialized := Serve_Report.Reply_Serialized;
      Report.Registered_Reply_Kind := Serve_Report.Reply_Kind;
      Report.Registered_Reply_In_Flight := Serve_Report.Reply_In_Flight;
      Report.Registered_Registry_Drained := Serve_Report.Registry_Drained;
      Report.Registered_Reply_Serial := Serve_Report.Reply_Serial;
      Report.Registered_Reply_Reply_Serial :=
        Serve_Report.Reply_Reply_Serial;
      Report.Registered_Reply_Estimated_Bytes :=
        Serve_Report.Reply_Estimated_Bytes;
      Report.Registered_Boundary_Resolved :=
        Serve_Report.Boundary_Resolved;
      Report.Registered_Boundary_Admitted :=
        Serve_Report.Boundary_Admitted;
      Report.Registered_Boundary_Completed :=
        Serve_Report.Boundary_Completed;
      Report.Registered_Boundary_Status := Serve_Report.Boundary_Status;
      Report.Registered_Begin_Outstanding_Before :=
        Serve_Report.Native_Call_Begin_Outstanding_Before;
      Report.Registered_Begin_Outstanding_After :=
        Serve_Report.Native_Call_Begin_Outstanding_After;
      Report.Registered_End_Outstanding_Before :=
        Serve_Report.Native_Call_End_Outstanding_Before;
      Report.Registered_End_Outstanding_After :=
        Serve_Report.Native_Call_End_Outstanding_After;

      if Serve_Report.Reply_Serialized then
         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Context.Bus, Context.Channel, Reply_Packet, Result);
         if A11y.Results.Failed (Result) then
            Finalize_Report (Context, Report, Result.Status);
            return;
         end if;
         Report.Reply_Written := True;
      else
         Result := A11y.Results.Ok;
      end if;

      Finalize_Report (Context, Report, Result.Status);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Report := (others => <>);
         Finalize_Report (Context, Report, Result.Status);
   end Pump_Registered_One_With_Report;

   procedure Pump_Bounded
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result)
   is
      Report : Pump_Bounded_Report;
   begin
      Pump_Bounded_With_Report
        (Context, Snapshots, A11y.Resource_Limits.Default_Config,
         Max_Iterations, Report, Result);
      Delivered := Report.Iterations_Completed;
   end Pump_Bounded;

   procedure Pump_Bounded
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result)
   is
      Report : Pump_Bounded_Report;
   begin
      Pump_Bounded_With_Report
        (Context, Snapshots, Limits, Max_Iterations, Report, Result);
      Delivered := Report.Iterations_Completed;
   end Pump_Bounded;

   procedure Pump_Bounded_With_Report
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result)
   is
   begin
      Pump_Bounded_With_Report
        (Context, Snapshots, A11y.Resource_Limits.Default_Config,
         Max_Iterations, Report, Result);
   end Pump_Bounded_With_Report;

   procedure Pump_Bounded_With_Report
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result)
   is
      Iteration : Pump_Activity_Report;
   begin
      Report := (others => <>);
      if Max_Iterations = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         Finalize_Bounded_Report
           (Context, Report, Invalid_Limit, Result.Status);
         return;
      end if;

      while Report.Iterations_Completed < Max_Iterations loop
         Report.Iterations_Attempted := Report.Iterations_Attempted + 1;
         Check_Pump_Ready (Context, Result);
         if A11y.Results.Failed (Result) then
            Finalize_Bounded_Report
              (Context, Report, Readiness_Failed, Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Wait_Readable
           (Context.Channel, 0, Result);
         if Result.Status = A11y.Results.Timed_Out then
            Result := A11y.Results.Ok;
            Finalize_Bounded_Report
              (Context, Report, No_Readable_Packet, Result.Status);
            return;
         elsif A11y.Results.Failed (Result) then
            Finalize_Bounded_Report
              (Context, Report, Readiness_Failed, Result.Status);
            return;
         end if;

         Pump_One_With_Report
           (Context, Snapshots, Limits, Iteration, Result);
         Accumulate_Bounded_Report (Report, Iteration);
         if A11y.Results.Failed (Result) then
            if not Iteration.Read_Attempted then
               Finalize_Bounded_Report
                 (Context, Report, Readiness_Failed, Result.Status);
            else
               Finalize_Bounded_Report
                 (Context, Report, Iteration_Failed, Result.Status);
            end if;
            return;
         end if;
         Report.Iterations_Completed := Report.Iterations_Completed + 1;
      end loop;

      Result := A11y.Results.Ok;
      Finalize_Bounded_Report
        (Context, Report, Iteration_Limit_Reached, Result.Status);
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Finalize_Bounded_Report
           (Context, Report, Iteration_Failed, Result.Status);
   end Pump_Bounded_With_Report;

   procedure Pump_Registered_Bounded
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result)
   is
      Report : Pump_Bounded_Report;
   begin
      Pump_Registered_Bounded_With_Report
        (Context, Registry, Snapshots, A11y.Resource_Limits.Default_Config,
         Max_Iterations, Report, Result);
      Delivered := Report.Iterations_Completed;
   end Pump_Registered_Bounded;

   procedure Pump_Registered_Bounded
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result)
   is
      Report : Pump_Bounded_Report;
   begin
      Pump_Registered_Bounded_With_Report
        (Context, Registry, Snapshots, Limits, Max_Iterations, Report,
         Result);
      Delivered := Report.Iterations_Completed;
   end Pump_Registered_Bounded;

   procedure Pump_Registered_Bounded_With_Report
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result)
   is
   begin
      Pump_Registered_Bounded_With_Report
        (Context, Registry, Snapshots, A11y.Resource_Limits.Default_Config,
         Max_Iterations, Report, Result);
   end Pump_Registered_Bounded_With_Report;

   procedure Pump_Registered_Bounded_With_Report
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result)
   is
      Iteration : Pump_Activity_Report;
   begin
      Report := (others => <>);
      if Max_Iterations = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         Finalize_Bounded_Report
           (Context, Report, Invalid_Limit, Result.Status);
         return;
      end if;

      while Report.Iterations_Completed < Max_Iterations loop
         Report.Iterations_Attempted := Report.Iterations_Attempted + 1;
         Check_Pump_Ready (Context, Result);
         if A11y.Results.Failed (Result) then
            Finalize_Bounded_Report
              (Context, Report, Readiness_Failed, Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Wait_Readable
           (Context.Channel, 0, Result);
         if Result.Status = A11y.Results.Timed_Out then
            Result := A11y.Results.Ok;
            Finalize_Bounded_Report
              (Context, Report, No_Readable_Packet, Result.Status);
            return;
         elsif A11y.Results.Failed (Result) then
            Finalize_Bounded_Report
              (Context, Report, Readiness_Failed, Result.Status);
            return;
         end if;

         Pump_Registered_One_With_Report
           (Context, Registry, Snapshots, Limits, Iteration, Result);
         Accumulate_Bounded_Report (Report, Iteration);
         if A11y.Results.Failed (Result) then
            if not Iteration.Read_Attempted then
               Finalize_Bounded_Report
                 (Context, Report, Readiness_Failed, Result.Status);
            else
               Finalize_Bounded_Report
                 (Context, Report, Iteration_Failed, Result.Status);
            end if;
            return;
         end if;
         Report.Iterations_Completed := Report.Iterations_Completed + 1;
      end loop;

      Result := A11y.Results.Ok;
      Finalize_Bounded_Report
        (Context, Report, Iteration_Limit_Reached, Result.Status);
   exception
      when others =>
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Finalize_Bounded_Report
         (Context, Report, Iteration_Failed, Result.Status);
   end Pump_Registered_Bounded_With_Report;

   procedure Serve_Registered_Packet
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result)
   is
   begin
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

      Check_Pump_Ready (Context, Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;

      A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
        (Context.Bus, Registry, Bytes, Snapshots, Limits, Packet, Report,
         Result);
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

   function State
     (Context : Startup_Context)
      return A11y.Linux.ATSPi_Bus.Connection_State is
     (Context.Bus.State);

   function Registered (Context : Startup_Context) return Boolean is
     (Context.Bus.State = A11y.Linux.ATSPi_Bus.Registered);

   function Unique_Name (Context : Startup_Context) return String is
     (To_String (Context.Bus.Unique_Name));

   function Session_Id
     (Context : Startup_Context)
      return A11y.Native_Identity.Backend_Session_Id is
     (Context.Bus.Session);

end A11y.Linux.ATSPi_Startup;
