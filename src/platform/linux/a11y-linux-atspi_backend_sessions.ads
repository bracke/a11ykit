with Ada.Strings.Unbounded;

with A11y.Backends.Native_Backends;
with A11y.Linux.ATSPi_Backend_Adapter;
with A11y.Linux.ATSPi_Bus;
with A11y.Linux.ATSPi_DBus_Boundary;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Object_Registry;
with A11y.Linux.ATSPi_Objects;
with A11y.Linux.ATSPi_Startup;
with A11y.Linux.DBus_Messages;
with A11y.Linux.DBus_Auth;
with A11y.Events;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Backend_Sessions is

   type Backend_Session is limited private;

   procedure Configure
     (Session : in out Backend_Session;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Start_From_Address
     (Session          : in out Backend_Session;
      Address          : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result);

   type Startup_Source is
     (Direct_Address,
      Environment_Value,
      Host_AT_SPI_Bus_Address,
      Host_Session_Bus_Address,
      Host_Environment_Missing,
      Session_Bus_Address);

   function Startup_Source_Name (Source : Startup_Source) return String;

   type Session_Startup_Report is record
      Source                   : Startup_Source := Direct_Address;
      Host_AT_SPI_Address_Present : Boolean := False;
      Host_Session_Bus_Address_Present : Boolean := False;
      Discovery_Attempted      : Boolean := False;
      Discovery                : A11y.Linux.ATSPi_Startup
        .Address_Discovery_Startup_Report;
      Prepared                 : Boolean := False;
      Registration             : A11y.Linux.ATSPi_Startup
        .Registration_Startup_Report;
      Backend_Synchronized     : Boolean := False;
      Backend_Synchronization  : A11y.Linux.ATSPi_Backend_Adapter
        .Startup_Synchronization_Report;
      Application_Root_Ensured : Boolean := False;
      Status                   : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Start_From_Address_With_Report
     (Session          : in out Backend_Session;
      Address          : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Report           : out Session_Startup_Report;
      Result           : out A11y.Results.Result);

   procedure Start_From_Environment_Value
     (Session          : in out Backend_Session;
      Value            : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result);

   procedure Start_From_Environment_Value_With_Report
     (Session          : in out Backend_Session;
      Value            : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Report           : out Session_Startup_Report;
      Result           : out A11y.Results.Result);

   procedure Start_From_Host_Environment
     (Session          : in out Backend_Session;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result);

   procedure Start_From_Host_Environment_With_Report
     (Session          : in out Backend_Session;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Report           : out Session_Startup_Report;
      Result           : out A11y.Results.Result);

   procedure Start_From_Session_Bus_Address
     (Session             : in out Backend_Session;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node    : A11y.Node_Ids.Node_Id;
      Result              : out A11y.Results.Result);

   procedure Start_From_Session_Bus_Address_With_Report
     (Session             : in out Backend_Session;
      Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node    : A11y.Node_Ids.Node_Id;
      Report              : out Session_Startup_Report;
      Result              : out A11y.Results.Result);

   procedure Pump_Registered_Bounded
     (Session        : in out Backend_Session;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Result         : out A11y.Results.Result);

   procedure Flush_One_Outgoing
     (Session : in out Backend_Session;
      Result  : out A11y.Results.Result);

   procedure Flush_Bounded_Outgoing
     (Session        : in out Backend_Session;
      Max_Iterations : Natural;
      Flushed        : out Natural;
      Result         : out A11y.Results.Result);

   procedure Wait_Writable
     (Session    : in out Backend_Session;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result);

   procedure Complete_Outgoing
     (Session : in out Backend_Session;
      Serial  : Natural;
      Result  : out A11y.Results.Result);

   type Event_Loop_Step_Report is record
      Interest_Before : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Operation       : A11y.Linux.ATSPi_Startup.Event_Loop_Operation :=
        A11y.Linux.ATSPi_Startup.Wait_For_Transport;
      Wait_Attempted  : Boolean := False;
      Wait_Timed_Out  : Boolean := False;
      Wait_Readable   : Boolean := False;
      Write_Wait_Attempted : Boolean := False;
      Pump            : A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Pump_Attempted  : Boolean := False;
      Flush_Attempted : Boolean := False;
      Write_Ready     : Boolean := False;
      Write_Timed_Out : Boolean := False;
      Write_Wait_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Flushed         : Natural := 0;
      Interest_After  : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Stop_Reason     : A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason :=
        A11y.Linux.ATSPi_Startup.Not_Stopped;
      Status          : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Drive_One_Event_Loop_Step
     (Session   : in out Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Event_Loop_Step_Report;
      Result    : out A11y.Results.Result);

   procedure Drive_One_Event_Loop_Step
     (Session         : in out Backend_Session;
      Snapshots       : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Read_Timeout_MS : Integer;
      Report          : out Event_Loop_Step_Report;
      Result          : out A11y.Results.Result);

   type Event_Loop_Bounded_Report is record
      Steps_Attempted : Natural := 0;
      Steps_Completed : Natural := 0;
      Wait_Attempts   : Natural := 0;
      Wait_Timeouts   : Natural := 0;
      Wait_Readable    : Natural := 0;
      Write_Wait_Attempts : Natural := 0;
      Write_Attempts  : Natural := 0;
      Write_Ready     : Natural := 0;
      Write_Timeouts  : Natural := 0;
      Last_Write_Wait_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Flushed         : Natural := 0;
      Last_Operation  : A11y.Linux.ATSPi_Startup.Event_Loop_Operation :=
        A11y.Linux.ATSPi_Startup.Wait_For_Transport;
      Last_Step_Status : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Last_Step_Stop_Reason :
        A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason :=
          A11y.Linux.ATSPi_Startup.Not_Stopped;
      Last_Interest_Before : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Last_Interest_After  : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Pump            : A11y.Linux.ATSPi_Startup.Pump_Bounded_Report;
      Stop_Reason     : A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason :=
        A11y.Linux.ATSPi_Startup.Not_Stopped;
      Status          : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Drive_Bounded_Event_Loop
     (Session        : in out Backend_Session;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations : Natural;
      Report         : out Event_Loop_Bounded_Report;
      Result         : out A11y.Results.Result);

   procedure Drive_Bounded_Event_Loop
     (Session         : in out Backend_Session;
      Snapshots       : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Max_Iterations  : Natural;
      Read_Timeout_MS : Integer;
      Report          : out Event_Loop_Bounded_Report;
      Result          : out A11y.Results.Result);

   procedure Serve_Registered_Packet
     (Session   : in out Backend_Session;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result);

   subtype Transport_Serve_Cycle_Report is
     A11y.Linux.ATSPi_Startup.Transport_Serve_Cycle_Report;

   procedure Serve_One_Transport_Cycle
     (Session   : in out Backend_Session;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out Transport_Serve_Cycle_Report;
      Result    : out A11y.Results.Result);

   procedure Queue_Event_Signal
     (Session : in out Backend_Session;
      Event   : A11y.Events.Event;
      Result  : out A11y.Results.Result);

   type Prepared_Signal_Queue_Report is record
      Registered             : Boolean := False;
      Pending_Outgoing_Before : Natural := 0;
      Pending_Outgoing_After  : Natural := 0;
      Source                 : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Sequence               : A11y.Event_Sequence := A11y.No_Event;
      Revision               : A11y.Semantic_Revision :=
        A11y.Initial_Revision;
      Event_Valid            : Boolean := False;
      Prepared_Status        : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Validation_Status : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Has_Object    : Boolean := False;
      Prepared_Destroys_Node : Boolean := False;
      Signal_Built           : Boolean := False;
      Signal_Publishable     : Boolean := False;
      Signal_Status          : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Enqueued               : Boolean := False;
      Status                 : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   type Event_Signal_Queue_Report is record
      Event_Valid                 : Boolean := False;
      Source                      : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Sequence                    : A11y.Event_Sequence := A11y.No_Event;
      Revision                    : A11y.Semantic_Revision :=
        A11y.Initial_Revision;
      Prepared_Publication_Status : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Available         : Boolean := False;
      Prepared_Status            : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Queue             : Prepared_Signal_Queue_Report;
      Status                     : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Queue_Event_Signal_With_Report
     (Session : in out Backend_Session;
      Event   : A11y.Events.Event;
      Report  : out Event_Signal_Queue_Report;
      Result  : out A11y.Results.Result);

   procedure Queue_Prepared_Event_Signal
     (Session  : in out Backend_Session;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Queue_Prepared_Event_Signal_With_Report
     (Session  : in out Backend_Session;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Report   : out Prepared_Signal_Queue_Report;
      Result   : out A11y.Results.Result);

   type Session_Stop_Report is record
      Startup_Interest_Before : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Startup_Interest_After  : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Registry_Before         : A11y.Linux.ATSPi_Object_Registry
        .Registry_Snapshot;
      Registry_After          : A11y.Linux.ATSPi_Object_Registry
        .Registry_Snapshot;
      Backend_Before          : A11y.Backends.Native_Backends
        .Transport_Snapshot;
      Backend_After           : A11y.Backends.Native_Backends
        .Transport_Snapshot;
      Application_Node_Before : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Application_Node_After  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Startup_Stop_Attempted  : Boolean := False;
      Startup_Stopped         : Boolean := False;
      Startup_Status          : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Registry_Reset_Attempted : Boolean := False;
      Registry_Reset          : Boolean := False;
      Registry_Status         : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Backend_Stop_Attempted  : Boolean := False;
      Backend_Stopped         : Boolean := False;
      Backend_Status          : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Application_Node_Cleared : Boolean := False;
      Status                  : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Stop
     (Session : in out Backend_Session;
      Result  : out A11y.Results.Result);

   procedure Stop_With_Report
     (Session : in out Backend_Session;
      Report  : out Session_Stop_Report;
      Result  : out A11y.Results.Result);

   function Backend_Status
     (Session : Backend_Session)
      return A11y.Backends.Native_Backends.Transport_Snapshot;

   type Session_Report is record
      Transport              : A11y.Backends.Native_Backends.Transport_Snapshot;
      Interest               : A11y.Linux.ATSPi_Startup.Event_Loop_Interest;
      Startup_State          : A11y.Linux.ATSPi_Bus.Connection_State :=
        A11y.Linux.ATSPi_Bus.Disconnected;
      Registered             : Boolean := False;
      Application_Node       : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Has_Application_Node   : Boolean := False;
      Application            : A11y.Linux.ATSPi_Object_Registry
        .Object_Export_Descriptor;
      Application_Exportable : Boolean := False;
      Application_Status     : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Registry               : A11y.Linux.ATSPi_Object_Registry
        .Registry_Snapshot;
      Last_Event_Loop        : Event_Loop_Bounded_Report;
      Has_Event_Loop_Report  : Boolean := False;
      Status                 : A11y.Results.Status_Code :=
        A11y.Results.Success;
   end record;

   procedure Capture_Report
     (Session : in out Backend_Session;
      Report  : out Session_Report);

   function Startup_Interest
     (Session : Backend_Session)
      return A11y.Linux.ATSPi_Startup.Event_Loop_Interest;

   procedure Wait_Readable
     (Session    : Backend_Session;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result);

   function Startup_State
     (Session : Backend_Session)
      return A11y.Linux.ATSPi_Bus.Connection_State;

   function Registered (Session : Backend_Session) return Boolean;
   function Unique_Name (Session : Backend_Session) return String;

   procedure Application_Descriptor
     (Session    : in out Backend_Session;
      Descriptor : out A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor);

   procedure Node_Descriptor
     (Session    : in out Backend_Session;
      Node        : A11y.Node_Ids.Node_Id;
      Descriptor : out A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor);

   function Dispatch_Application_Root_Method
     (Session        : in out Backend_Session;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;

   function Dispatch_Application_Root_Method
     (Session        : in out Backend_Session;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Index          : Natural;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;

   function Dispatch_Node_Method
     (Session        : in out Backend_Session;
      Node           : A11y.Node_Ids.Node_Id;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;

   function Dispatch_Node_Method
     (Session        : in out Backend_Session;
      Node           : A11y.Node_Ids.Node_Id;
      Interface_Item : A11y.Linux.ATSPi_Objects.ATSPI_Interface;
      Method         : String;
      Index          : Natural;
      Snapshots      : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;

   function Dispatch_Registered_Call
     (Session   : in out Backend_Session;
      Call      : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;

   function Dispatch_Registered_Call_With_Report
     (Session   : in out Backend_Session;
      Call      : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Report    : out A11y.Linux.ATSPi_DBus_Boundary
        .Registered_Call_Boundary_Report)
      return A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;

   function Registry_Snapshot
     (Session : Backend_Session)
      return A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;

private
   type Backend_Session is limited record
      Backend : A11y.Backends.Native_Backends.Native_Backend
        (A11y.Backends.Native_Backends.Linux_ATSPI);
      Startup  : A11y.Linux.ATSPi_Startup.Startup_Context;
      Registry : A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Application_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Last_Event_Loop       : Event_Loop_Bounded_Report;
      Has_Event_Loop_Report : Boolean := False;
   end record;

end A11y.Linux.ATSPi_Backend_Sessions;
