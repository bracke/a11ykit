with Ada.Strings.Unbounded;

with A11y.Linux.ATSPi_DBus_Boundary;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Object_Registry;
with A11y.Linux.ATSPi_Signals;
with A11y.Linux.DBus_Messages;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Bus is

   Max_Address_Length : constant Natural := 4_096;
   Max_Address_Fields : constant Natural := 32;

   type Transport_Kind is
     (Unix_Transport,
      Tcp_Transport,
      Launchd_Transport,
      Other_Transport);

   type Address_State is
     (Address_Unavailable,
      Address_Valid,
      Address_Invalid);

   type Connection_State is
     (Disconnected,
      Address_Resolved,
      Connected,
      Registered,
      Failed);

   type Bus_Address is record
      State      : Address_State := Address_Unavailable;
      Transport  : Transport_Kind := Other_Transport;
      Text       : Ada.Strings.Unbounded.Unbounded_String;
      Field_Count : Natural := 0;
   end record;

   type Connection_Context is record
      State   : Connection_State := Disconnected;
      Address : Bus_Address;
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Unique_Name : Ada.Strings.Unbounded.Unbounded_String;
      Last_Serial : Natural := 0;
      Outgoing : A11y.Linux.DBus_Messages.Outgoing_Queue;
      In_Flight : A11y.Linux.DBus_Messages.Outgoing_Tracker;
   end record;

   function Parse_Address
     (Address : String;
      Result  : out A11y.Results.Result)
      return Bus_Address;

   function Transport_Name (Transport : Transport_Kind) return String;

   procedure Prepare_Connection
     (Context : in out Connection_Context;
      Address : String;
      Result  : out A11y.Results.Result);

   procedure Mark_Transport_Connected
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result);

   procedure Register_Application
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result);

   function Next_Outgoing_Serial
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result)
      return Natural;

   function Pending_Outgoing_Count
     (Context : Connection_Context)
      return Natural;

   function Pending_Outgoing_Capacity
     (Context : Connection_Context)
      return Natural;

   function Pending_Outgoing_Overflowed
     (Context : Connection_Context)
      return Boolean;

   function Posting_Interest
     (Context : Connection_Context)
      return A11y.Linux.DBus_Messages.Queue_Posting_Interest;

   function In_Flight_Outgoing_Count
     (Context : Connection_Context)
      return Natural;

   function In_Flight_Outgoing_Capacity
     (Context : Connection_Context)
      return Natural;

   procedure Configure_Outgoing_Queue
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Clear_Outgoing_Queue (Context : in out Connection_Context);

   procedure Queue_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result);

   procedure Queue_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result);

   procedure Queue_Bus_Hello
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result);

   procedure Queue_Bus_Hello
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Complete_Bus_Hello
     (Context : in out Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result);

   procedure Complete_Bus_Hello
     (Context  : in out Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result);

   procedure Complete_Application_Registration
     (Context  : in out Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result);

   type Incoming_Packet_Classification is record
      Status       : A11y.Results.Status_Code := A11y.Results.Success;
      Kind         : A11y.Linux.DBus_Messages.Message_Kind :=
        A11y.Linux.DBus_Messages.Error_Return;
      Serial       : Natural := 0;
      Reply_Serial : Natural := 0;
      Reply_Tracked : Boolean := False;
   end record;

   function Classify_Incoming_Packet
     (Context : Connection_Context;
      Bytes   : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return Incoming_Packet_Classification;

   function Classify_Incoming_Packet
     (Context : Connection_Context;
      Bytes   : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Incoming_Packet_Classification;

   procedure Queue_Method_Reply
     (Context  : in out Connection_Context;
      Original : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Result   : out A11y.Results.Result);

   procedure Queue_Method_Reply
     (Context  : in out Connection_Context;
      Original : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result);

   procedure Handle_Incoming_Packet
     (Context   : in out Connection_Context;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result);

   procedure Handle_Incoming_Packet
     (Context   : in out Connection_Context;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result);

   procedure Handle_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result);

   procedure Handle_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result);

   type Registered_Packet_Serve_Report is record
      Packet_Classified     : Boolean := False;
      Incoming_Kind         : A11y.Linux.DBus_Messages.Message_Kind :=
        A11y.Linux.DBus_Messages.Error_Return;
      Incoming_Method_Call  : Boolean := False;
      Incoming_Serial       : Natural := 0;
      Incoming_Reply_Serial : Natural := 0;
      Reply_Queued          : Boolean := False;
      Reply_Serialized      : Boolean := False;
      Reply_Kind            : A11y.Linux.DBus_Messages.Message_Kind :=
        A11y.Linux.DBus_Messages.Error_Return;
      Reply_Serial          : Natural := 0;
      Reply_Reply_Serial    : Natural := 0;
      Reply_Estimated_Bytes : Natural := 0;
      Reply_In_Flight       : Boolean := False;
      Registry_Drained      : Boolean := False;
      Boundary_Resolved     : Boolean := False;
      Boundary_Admitted     : Boolean := False;
      Boundary_Completed    : Boolean := False;
      Boundary_Status       : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Native_Call_Begin_Outstanding_Before : Natural := 0;
      Native_Call_Begin_Outstanding_After  : Natural := 0;
      Native_Call_End_Outstanding_Before   : Natural := 0;
      Native_Call_End_Outstanding_After    : Natural := 0;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Serve_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result);

   procedure Serve_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Ada.Strings.Unbounded.Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result);

   procedure Queue_Signal
     (Context : in out Connection_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Result  : out A11y.Results.Result);

   procedure Queue_Signal
     (Context : in out Connection_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Dequeue_Outgoing
     (Context : in out Connection_Context;
      Message : out A11y.Linux.DBus_Messages.Outgoing_Message;
      Result  : out A11y.Results.Result);

   procedure Send_Next_Outgoing
     (Context : in out Connection_Context;
      Message : out A11y.Linux.DBus_Messages.Outgoing_Message;
      Result  : out A11y.Results.Result);

   procedure Send_Next_Transport_Envelope
     (Context  : in out Connection_Context;
      Envelope : out A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result);

   procedure Send_Next_Transport_Frame
     (Context : in out Connection_Context;
      Frame   : out A11y.Linux.DBus_Messages.Transport_Frame;
      Result  : out A11y.Results.Result);

   procedure Send_Next_Transport_Frame
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Frame   : out A11y.Linux.DBus_Messages.Transport_Frame;
      Result  : out A11y.Results.Result);

   procedure Send_Next_Transport_Packet
     (Context : in out Connection_Context;
      Packet  : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result  : out A11y.Results.Result);

   procedure Send_Next_Transport_Packet
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Packet  : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result  : out A11y.Results.Result);

   procedure Complete_Outgoing
     (Context : in out Connection_Context;
      Serial  : Natural;
      Result  : out A11y.Results.Result);

   function Build_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message;

   function Build_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message;

   function Build_Application_Registration
     (Context          : Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Serial           : Natural;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message;

   function Build_Application_Registration
     (Context          : Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Serial           : Natural;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message;

   procedure Disconnect
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result);

end A11y.Linux.ATSPi_Bus;
