with A11y.Linux.ATSPi_Bus;
with A11y.Linux.DBus_Auth;
with A11y.Linux.DBus_Messages;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

with Ada.Strings.Unbounded;

with Hostkit.Local_Channel;

package A11y.Linux.ATSPi_Local_Channel is

   type Channel is limited private;

   function Is_Open (Item : Channel) return Boolean;

   procedure Wait_Readable
     (Item       : Channel;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result);

   procedure Wait_Writable
     (Item       : Channel;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result);

   function Unix_Path
     (Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result)
      return String;

   function Unix_Abstract_Name
     (Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result)
      return String;

   procedure Connect
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      Result  : out A11y.Results.Result);

   procedure Connect_Authenticated
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result);

   procedure Connect_Authenticated_And_Hello
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result);

   procedure Connect_Authenticated_And_Hello
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Connect_Authenticated_Hello_And_Discover_Accessibility_Bus
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Address : out A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result);

   procedure Connect_Authenticated_Hello_And_Discover_Accessibility_Bus
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Address : out A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result);

   type Address_Discovery_Startup_Report is record
      Address_Resolved        : Boolean := False;
      Address_Transport       : A11y.Linux.ATSPi_Bus.Transport_Kind :=
        A11y.Linux.ATSPi_Bus.Other_Transport;
      Address_Field_Count     : Natural := 0;
      Address_Uses_Path       : Boolean := False;
      Address_Uses_Abstract   : Boolean := False;
      Raw_Connect_Attempted   : Boolean := False;
      Raw_Connect_Status      : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Raw_Connected           : Boolean := False;
      Auth_Sent               : Boolean := False;
      Auth_Response_Status    : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Auth_Accepted           : Boolean := False;
      Begin_Sent              : Boolean := False;
      Transport_Admitted      : Boolean := False;
      Hello_Queued            : Boolean := False;
      Hello_Sent              : Boolean := False;
      Hello_Reply_Received    : Boolean := False;
      Hello_Reply_Serial      : Natural := 0;
      Hello_Reply_Status      : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Hello_Completed         : Boolean := False;
      Unique_Name_Received    : Boolean := False;
      Unique_Name_Length      : Natural := 0;
      Unique_Name_Has_Bus_Prefix : Boolean := False;
      Get_Address_Queued      : Boolean := False;
      Get_Address_Sent        : Boolean := False;
      Get_Address_Reply_Received : Boolean := False;
      Get_Address_Reply_Serial   : Natural := 0;
      Get_Address_Reply_Error_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Get_Address_Reply_Status   : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Get_Address_Completed   : Boolean := False;
      Accessibility_Address_State : A11y.Linux.ATSPi_Bus.Address_State :=
        A11y.Linux.ATSPi_Bus.Address_Unavailable;
      Accessibility_Address_Transport : A11y.Linux.ATSPi_Bus.Transport_Kind :=
        A11y.Linux.ATSPi_Bus.Other_Transport;
      Accessibility_Address_Field_Count : Natural := 0;
      Pending_Outgoing        : Natural := 0;
      In_Flight_Outgoing      : Natural := 0;
      Status                  : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Connect_Authenticated_Hello_And_Discover_With_Report
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Address : out A11y.Linux.ATSPi_Bus.Bus_Address;
      Report  : out Address_Discovery_Startup_Report;
      Result  : out A11y.Results.Result);

   procedure Connect_Authenticated_Hello_And_Register
     (Context          : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item             : out Channel;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result);

   procedure Connect_Authenticated_Hello_And_Register
     (Context          : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item             : out Channel;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result);

   type Registration_Startup_Report is record
      Address_Resolved        : Boolean := False;
      Address_Transport       : A11y.Linux.ATSPi_Bus.Transport_Kind :=
        A11y.Linux.ATSPi_Bus.Other_Transport;
      Address_Field_Count     : Natural := 0;
      Address_Uses_Path       : Boolean := False;
      Address_Uses_Abstract   : Boolean := False;
      Raw_Connect_Attempted   : Boolean := False;
      Raw_Connect_Status      : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Raw_Connected           : Boolean := False;
      Auth_Sent               : Boolean := False;
      Auth_Response_Status    : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Auth_Accepted           : Boolean := False;
      Begin_Sent              : Boolean := False;
      Transport_Admitted      : Boolean := False;
      Hello_Queued            : Boolean := False;
      Hello_Sent              : Boolean := False;
      Hello_Reply_Received    : Boolean := False;
      Hello_Reply_Serial      : Natural := 0;
      Hello_Reply_Status      : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Hello_Completed         : Boolean := False;
      Unique_Name_Received    : Boolean := False;
      Unique_Name_Length      : Natural := 0;
      Unique_Name_Has_Bus_Prefix : Boolean := False;
      Application_Object_Path_Available : Boolean := False;
      Application_Object_Path_Length    : Natural := 0;
      Application_Object_Path_Has_Session_Prefix : Boolean := False;
      Application_Object_Path_Has_Node_Suffix    : Boolean := False;
      Registration_Queued     : Boolean := False;
      Registration_Sent       : Boolean := False;
      Registration_Reply_Received : Boolean := False;
      Registration_Reply_Serial   : Natural := 0;
      Registration_Reply_Was_Error_Return : Boolean := False;
      Registration_Reply_Error_Name : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Registration_Reply_Body_Signature :
        Ada.Strings.Unbounded.Unbounded_String :=
          Ada.Strings.Unbounded.Null_Unbounded_String;
      Registration_Reply_Body_Bytes : Natural := 0;
      Registration_Reply_Bus_Name_Length : Natural := 0;
      Registration_Reply_Object_Path_Length : Natural := 0;
      Registration_Reply_Status   : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
      Registration_Completed  : Boolean := False;
      Transport_Registration_Observed : Boolean := False;
      Registered              : Boolean := False;
      Pending_Outgoing        : Natural := 0;
      In_Flight_Outgoing      : Natural := 0;
      Status                  : A11y.Results.Status_Code :=
        A11y.Results.Backend_Unavailable;
   end record;

   procedure Connect_Authenticated_Hello_And_Register_With_Report
     (Context          : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item             : out Channel;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Report           : out Registration_Startup_Report;
      Result           : out A11y.Results.Result);

   procedure Send_External_Auth
     (Item    : in out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result);

   procedure Receive_Auth_Response
     (Item   : in out Channel;
      Result : out A11y.Results.Result);

   procedure Send_Begin
     (Item   : in out Channel;
      Result : out A11y.Results.Result);

   procedure Send_Next_Packet
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : in out Channel;
      Result  : out A11y.Results.Result);

   procedure Send_Packet
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : in out Channel;
      Packet  : A11y.Linux.DBus_Messages.Transport_Packet;
      Result  : out A11y.Results.Result);

   procedure Receive_Next_Packet
     (Item   : in out Channel;
      Packet : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result : out A11y.Results.Result);

   procedure Receive_Next_Packet
     (Item   : in out Channel;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Packet : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result : out A11y.Results.Result);

   procedure Close (Item : in out Channel);

private

   type Channel is limited record
      Native : Hostkit.Local_Channel.Channel;
   end record;

end A11y.Linux.ATSPi_Local_Channel;
