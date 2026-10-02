with Ada.Strings.Unbounded;

with A11y.Linux.ATSPi_Bus;
with A11y.Linux.ATSPi_Local_Channel;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Object_Registry;
with A11y.Linux.ATSPi_Signals;
with A11y.Linux.DBus_Auth;
with A11y.Linux.DBus_Messages;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Startup is

   type Startup_Context is limited private;

   procedure Prepare
     (Context : in out Startup_Context;
      Address : String;
      Result  : out A11y.Results.Result);

   procedure Prepare_From_Environment_Value
     (Context : in out Startup_Context;
      Value   : String;
      Result  : out A11y.Results.Result);

   procedure Prepare_From_Host_Environment
     (Context : in out Startup_Context;
      Result  : out A11y.Results.Result);

   procedure Prepare_From_Host_Environment
     (Context : in out Startup_Context;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result);

   procedure Prepare_From_Host_Environment
     (Context : in out Startup_Context;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   subtype Address_Discovery_Startup_Report is
     A11y.Linux.ATSPi_Local_Channel.Address_Discovery_Startup_Report;

   type Host_Environment_Startup_Report is record
      AT_SPI_Address_Present      : Boolean := False;
      Session_Bus_Address_Present : Boolean := False;
      Discovery_Attempted         : Boolean := False;
      Discovery                   : Address_Discovery_Startup_Report;
      Status                      : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Prepare_From_Host_Environment_With_Report
     (Context : in out Startup_Context;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Report  : out Host_Environment_Startup_Report;
      Result  : out A11y.Results.Result);

   procedure Prepare_From_Session_Bus_Address
     (Context             : in out Startup_Context;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Result              : out A11y.Results.Result);

   procedure Prepare_From_Session_Bus_Address
     (Context             : in out Startup_Context;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Limits              : A11y.Resource_Limits.Resource_Limit_Config;
      Result              : out A11y.Results.Result);

   procedure Prepare_From_Session_Bus_Address_With_Report
     (Context             : in out Startup_Context;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Limits              : A11y.Resource_Limits.Resource_Limit_Config;
      Report              : out Address_Discovery_Startup_Report;
      Result              : out A11y.Results.Result);

   procedure Start
     (Context          : in out Startup_Context;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result);

   procedure Start
     (Context          : in out Startup_Context;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result);

   subtype Registration_Startup_Report is
     A11y.Linux.ATSPi_Local_Channel.Registration_Startup_Report;

   procedure Start_With_Report
     (Context          : in out Startup_Context;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Report           : out Registration_Startup_Report;
      Result           : out A11y.Results.Result);

   procedure Stop
     (Context : in out Startup_Context;
      Result  : out A11y.Results.Result);

   function Can_Pump (Context : Startup_Context) return Boolean;

   function Pending_Outgoing_Count (Context : Startup_Context) return Natural;

   function In_Flight_Outgoing_Count
     (Context : Startup_Context)
      return Natural;

   function Has_Outgoing_Work (Context : Startup_Context) return Boolean;

   type Event_Loop_Operation is
     (No_Operation,
      Read_And_Dispatch,
      Write_Outgoing,
      Wait_For_Transport,
      Transport_Failed);

   type Event_Loop_Interest is record
      Can_Read              : Boolean := False;
      Can_Write             : Boolean := False;
      Can_Dispatch          : Boolean := False;
      Has_Outgoing_Work     : Boolean := False;
      Next_Operation        : Event_Loop_Operation := Wait_For_Transport;
      Pump_Status           : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Pending_Outgoing      : Natural := 0;
      Pending_Capacity      : Natural := 0;
      Pending_Overflowed    : Boolean := False;
      In_Flight_Outgoing    : Natural := 0;
      In_Flight_Capacity    : Natural := 0;
   end record;

   function Interest
     (Context : Startup_Context)
      return Event_Loop_Interest;

   procedure Check_Pump_Ready
     (Context : Startup_Context;
      Result  : out A11y.Results.Result);

   procedure Wait_Readable
     (Context    : Startup_Context;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result);

   procedure Wait_Writable
     (Context    : Startup_Context;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result);

   procedure Flush_One_Outgoing
     (Context : in out Startup_Context;
      Result  : out A11y.Results.Result);

   procedure Flush_Bounded_Outgoing
     (Context        : in out Startup_Context;
      Max_Iterations : Natural;
      Flushed        : out Natural;
      Result         : out A11y.Results.Result);

   procedure Complete_Outgoing
     (Context : in out Startup_Context;
      Serial  : Natural;
      Result  : out A11y.Results.Result);

   procedure Queue_Signal
     (Context : in out Startup_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Result  : out A11y.Results.Result);

   procedure Queue_Signal
     (Context : in out Startup_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   type Pump_Activity_Report is record
      Read_Attempted     : Boolean := False;
      Packet_Received    : Boolean := False;
      Packet_Dispatched  : Boolean := False;
      Reply_Written      : Boolean := False;
      Registered_Incoming_Kind :
        A11y.Linux.DBus_Messages.Message_Kind :=
          A11y.Linux.DBus_Messages.Error_Return;
      Registered_Incoming_Method_Call : Boolean := False;
      Registered_Incoming_Serial       : Natural := 0;
      Registered_Incoming_Reply_Serial : Natural := 0;
      Registered_Reply_Serialized     : Boolean := False;
      Registered_Reply_Kind :
        A11y.Linux.DBus_Messages.Message_Kind :=
          A11y.Linux.DBus_Messages.Error_Return;
      Registered_Reply_In_Flight      : Boolean := False;
      Registered_Registry_Drained     : Boolean := False;
      Registered_Reply_Serial         : Natural := 0;
      Registered_Reply_Reply_Serial   : Natural := 0;
      Registered_Reply_Estimated_Bytes : Natural := 0;
      Registered_Boundary_Resolved    : Boolean := False;
      Registered_Boundary_Admitted    : Boolean := False;
      Registered_Boundary_Completed   : Boolean := False;
      Registered_Boundary_Status      : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Registered_Begin_Outstanding_Before : Natural := 0;
      Registered_Begin_Outstanding_After  : Natural := 0;
      Registered_End_Outstanding_Before   : Natural := 0;
      Registered_End_Outstanding_After    : Natural := 0;
      Pending_Outgoing   : Natural := 0;
      In_Flight_Outgoing : Natural := 0;
      Status             : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   type Pump_Bounded_Stop_Reason is
     (Not_Stopped,
      Invalid_Limit,
      Readiness_Failed,
      No_Readable_Packet,
      Iteration_Failed,
      Iteration_Limit_Reached);

   type Pump_Bounded_Report is record
      Iterations_Attempted : Natural := 0;
      Iterations_Completed : Natural := 0;
      Reads_Attempted      : Natural := 0;
      Packets_Received     : Natural := 0;
      Packets_Dispatched   : Natural := 0;
      Replies_Written      : Natural := 0;
      Registered_Method_Calls  : Natural := 0;
      Registered_Replies       : Natural := 0;
      Registered_Replies_In_Flight : Natural := 0;
      Registered_Drained_Calls : Natural := 0;
      Registered_Boundary_Resolved_Calls  : Natural := 0;
      Registered_Boundary_Admitted_Calls  : Natural := 0;
      Registered_Boundary_Completed_Calls : Natural := 0;
      Last_Registered_Incoming_Kind :
        A11y.Linux.DBus_Messages.Message_Kind :=
          A11y.Linux.DBus_Messages.Error_Return;
      Last_Registered_Incoming_Serial : Natural := 0;
      Last_Registered_Incoming_Reply_Serial : Natural := 0;
      Last_Registered_Reply_Kind :
        A11y.Linux.DBus_Messages.Message_Kind :=
          A11y.Linux.DBus_Messages.Error_Return;
      Last_Registered_Reply_Serial : Natural := 0;
      Last_Registered_Reply_Reply_Serial : Natural := 0;
      Last_Registered_Reply_Estimated_Bytes : Natural := 0;
      Last_Registered_Reply_In_Flight : Boolean := False;
      Last_Registered_Boundary_Status : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Last_Registered_Begin_Outstanding_Before : Natural := 0;
      Last_Registered_Begin_Outstanding_After  : Natural := 0;
      Last_Registered_End_Outstanding_Before   : Natural := 0;
      Last_Registered_End_Outstanding_After    : Natural := 0;
      Pending_Outgoing     : Natural := 0;
      In_Flight_Outgoing   : Natural := 0;
      Stop_Reason          : Pump_Bounded_Stop_Reason := Not_Stopped;
      Status               : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   type Transport_Serve_Cycle_Report is record
      Interest_Before      : Event_Loop_Interest;
      Ready_Checked        : Boolean := False;
      Read_Attempted       : Boolean := False;
      Packet_Received      : Boolean := False;
      Incoming_Packet_Kind : A11y.Linux.DBus_Messages.Message_Kind :=
        A11y.Linux.DBus_Messages.Error_Return;
      Incoming_Serial      : Natural := 0;
      Incoming_Reply_Serial : Natural := 0;
      Incoming_Estimated_Bytes : Natural := 0;
      Serve_Attempted      : Boolean := False;
      Reply_Serialized     : Boolean := False;
      Reply_Packet_Kind    : A11y.Linux.DBus_Messages.Message_Kind :=
        A11y.Linux.DBus_Messages.Error_Return;
      Reply_Serial         : Natural := 0;
      Reply_Reply_Serial   : Natural := 0;
      Reply_Estimated_Bytes : Natural := 0;
      Write_Attempted      : Boolean := False;
      Reply_Written        : Boolean := False;
      Interest_After       : Event_Loop_Interest;
      Registered           : A11y.Linux.ATSPi_Bus
        .Registered_Packet_Serve_Report;
      Status               : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Serve_One_Transport_Cycle_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Report    : out Transport_Serve_Cycle_Report;
      Result    : out A11y.Results.Result);

   procedure Serve_One_Transport_Cycle_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Transport_Serve_Cycle_Report;
      Result    : out A11y.Results.Result);

   procedure Pump_One_With_Report
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result);

   procedure Pump_One_With_Report
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result);

   procedure Pump_One
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result);

   procedure Pump_One
     (Context   : in out Startup_Context;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result);

   procedure Pump_Registered_One
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result);

   procedure Pump_Registered_One
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result);

   procedure Pump_Registered_One_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result);

   procedure Pump_Registered_One_With_Report
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Report    : out Pump_Activity_Report;
      Result    : out A11y.Results.Result);

   procedure Pump_Bounded
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result);

   procedure Pump_Bounded
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result);

   procedure Pump_Bounded_With_Report
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result);

   procedure Pump_Bounded_With_Report
     (Context        : in out Startup_Context;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result);

   procedure Pump_Registered_Bounded
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result);

   procedure Pump_Registered_Bounded
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Delivered      : out Natural;
      Result         : out A11y.Results.Result);

   procedure Pump_Registered_Bounded_With_Report
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result);

   procedure Pump_Registered_Bounded_With_Report
     (Context        : in out Startup_Context;
      Registry       : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Max_Iterations : Natural;
      Report         : out Pump_Bounded_Report;
      Result         : out A11y.Results.Result);

   procedure Serve_Registered_Packet
     (Context   : in out Startup_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result);

   function State
     (Context : Startup_Context)
      return A11y.Linux.ATSPi_Bus.Connection_State;

   function Registered (Context : Startup_Context) return Boolean;
   function Unique_Name (Context : Startup_Context) return String;
   function Session_Id
     (Context : Startup_Context)
      return A11y.Native_Identity.Backend_Session_Id;

private
   type Startup_Context is limited record
      Bus     : A11y.Linux.ATSPi_Bus.Connection_Context;
      Channel : A11y.Linux.ATSPi_Local_Channel.Channel;
   end record;

end A11y.Linux.ATSPi_Startup;
