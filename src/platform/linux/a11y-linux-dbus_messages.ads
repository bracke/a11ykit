with Ada.Strings.Unbounded;
with Ada.Containers.Vectors;

with A11y.Actions;
with A11y.Diagnostics;
with A11y.Geometry;
with A11y.Linux.ATSPi_Accessible;
with A11y.Linux.ATSPi_DBus_Boundary;
with A11y.Linux.ATSPi_Mappings;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Selection;
with A11y.Linux.ATSPi_Signals;
with A11y.Linux.DBus_Codec;
with A11y.Native_Identity;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Text;
with A11y.Trees;
with A11y.Values;

package A11y.Linux.DBus_Messages is

   type Message_Kind is
     (Method_Call,
      Method_Return,
      Signal_Message,
      Error_Return);

   type Message_Header is record
      Kind           : Message_Kind := Method_Call;
      Serial         : Natural := 0;
      Reply_Serial   : Natural := 0;
      Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Error_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Sender_Name    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Incoming_Call is record
      Header : Message_Header;
      Call   : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
   end record;

   type Outgoing_Message (Kind : Message_Kind := Error_Return) is record
      Serial       : Natural := 0;
      Reply_Serial : Natural := 0;
      Status       : A11y.Results.Status_Code := A11y.Results.Success;
      Object_Path  : Ada.Strings.Unbounded.Unbounded_String;
      case Kind is
         when Method_Return =>
            Routed_Kind :
              A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind :=
                A11y.Linux.ATSPi_Method_Router.Routed_Error;
            Payload_Text : Ada.Strings.Unbounded.Unbounded_String;
            Payload_UInt32 : Natural := 0;
            Payload_Int32 : Integer := 0;
            Payload_Boolean : Boolean := False;
            Payload_Float : Long_Float := 0.0;
            Payload_Object_Path : Ada.Strings.Unbounded.Unbounded_String;
            Payload_Nodes : A11y.Trees.Child_Vectors.Vector;
            Payload_Strings : A11y.Linux.DBus_Codec.String_Vectors.Vector;
            Payload_Bounds : A11y.Geometry.Rectangle :=
              A11y.Geometry.Empty_Rectangle;
            Payload_Size : A11y.Geometry.Size := (Width => 0, Height => 0);
            Payload_State_Set :
              A11y.Linux.ATSPi_Mappings.ATSPI_State_Set :=
                A11y.Linux.ATSPi_Mappings.Empty_ATSPI_State_Set;
            Payload_Session : A11y.Native_Identity.Backend_Session_Id :=
              A11y.Native_Identity.No_Session;
            Payload_Attributes :
              A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
            Payload_Relations :
              A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
            Payload_Action : A11y.Actions.Action_Id := A11y.Actions.Activate;
            Payload_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
            Payload_Selection_Request :
              A11y.Linux.ATSPi_Selection.Selection_Request_Kind :=
                A11y.Linux.ATSPi_Selection.Select_Child;
            Payload_Text_Edit : A11y.Text.Text_Edit_Request;
         when Error_Return =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
         when Signal_Message =>
            Event_Name  : Ada.Strings.Unbounded.Unbounded_String;
         when Method_Call =>
            Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
            Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
            Has_Object_Path_Argument : Boolean := False;
            Object_Path_Argument :
              Ada.Strings.Unbounded.Unbounded_String;
            Has_String_Argument : Boolean := False;
            String_Argument :
              Ada.Strings.Unbounded.Unbounded_String;
            Has_String_Pair_Argument : Boolean := False;
            String_Argument_2 :
              Ada.Strings.Unbounded.Unbounded_String;
            Has_Object_Reference_Argument : Boolean := False;
            Has_UInt32_Argument : Boolean := False;
            UInt32_Argument : Natural := 0;
            Has_UInt32_Pair_Argument : Boolean := False;
            UInt32_Argument_2 : Natural := 0;
            Has_Point_Argument : Boolean := False;
            Point_Argument : A11y.Geometry.Point := (X => 0, Y => 0);
            Has_Float_Argument : Boolean := False;
            Float_Argument : Long_Float := 0.0;
      end case;
   end record;

   type Transport_Envelope is record
      Kind                      : Message_Kind := Error_Return;
      Serial                    : Natural := 0;
      Reply_Serial              : Natural := 0;
      Status                    : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Object_Path               : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name            : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Error_Name                : Ada.Strings.Unbounded.Unbounded_String;
      Sender_Name               : Ada.Strings.Unbounded.Unbounded_String;
      Body_Signature            : Ada.Strings.Unbounded.Unbounded_String;
      Body_Bytes                : Ada.Strings.Unbounded.Unbounded_String;
      Body_Object_Path_Argument :
        Ada.Strings.Unbounded.Unbounded_String;
      Body_String_Argument      :
        Ada.Strings.Unbounded.Unbounded_String;
      Body_String_Argument_2    :
        Ada.Strings.Unbounded.Unbounded_String;
      Body_UInt32_Argument     : Natural := 0;
      Body_UInt32_Argument_2   : Natural := 0;
      Body_Point_Argument      : A11y.Geometry.Point := (X => 0, Y => 0);
      Body_Float_Argument      : Long_Float := 0.0;
   end record;

   type Transport_Frame_Metadata is record
      Kind             : Message_Kind := Error_Return;
      Serial           : Natural := 0;
      Reply_Serial     : Natural := 0;
      Header_Field_Count : Natural := 0;
      Body_Field_Count   : Natural := 0;
      Header_Text_Bytes  : Natural := 0;
      Body_Text_Bytes    : Natural := 0;
      Estimated_Bytes    : Natural := 0;
   end record;

   type Transport_Frame is record
      Metadata     : Transport_Frame_Metadata;
      Header_Bytes : Ada.Strings.Unbounded.Unbounded_String;
      Body_Bytes   : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Transport_Packet is record
      Metadata : Transport_Frame_Metadata;
      Bytes    : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   type Transport_Packet_Header is record
      Kind                : Message_Kind := Error_Return;
      Serial              : Natural := 0;
      Body_Length         : Natural := 0;
      Header_Fields_Bytes : Natural := 0;
      Header_Length       : Natural := 0;
      Packet_Length       : Natural := 0;
   end record;

   Max_Queued_Messages : constant Natural := 1_024;

   type Outgoing_Queue is private;
   type Outgoing_Tracker is private;

   function Queue_Length (Queue : Outgoing_Queue) return Natural;
   function Queue_Capacity (Queue : Outgoing_Queue) return Natural;
   function Queue_Overflowed (Queue : Outgoing_Queue) return Boolean;

   type Queue_Posting_Operation is
     (No_Posting_Operation,
      Send_Next_Message,
      Back_Pressure);

   type Queue_Posting_Interest is record
      Can_Send       : Boolean := False;
      Has_Pending    : Boolean := False;
      Overflowed     : Boolean := False;
      Length         : Natural := 0;
      Capacity       : Natural := 0;
      Next_Operation : Queue_Posting_Operation := No_Posting_Operation;
   end record;

   function Posting_Interest
     (Queue : Outgoing_Queue)
      return Queue_Posting_Interest;

   procedure Configure_Queue
     (Queue  : in out Outgoing_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Set_Queue_Capacity
     (Queue    : in out Outgoing_Queue;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Enqueue
     (Queue   : in out Outgoing_Queue;
      Message : Outgoing_Message;
      Result  : out A11y.Results.Result);

   procedure Peek
     (Queue   : Outgoing_Queue;
      Message : out Outgoing_Message;
      Result  : out A11y.Results.Result);

   procedure Dequeue
     (Queue   : in out Outgoing_Queue;
      Message : out Outgoing_Message;
      Result  : out A11y.Results.Result);

   procedure Clear (Queue : in out Outgoing_Queue);

   function Tracker_Count (Tracker : Outgoing_Tracker) return Natural;
   function Tracker_Capacity (Tracker : Outgoing_Tracker) return Natural;
   function Tracker_Has_Serial
     (Tracker : Outgoing_Tracker;
      Serial  : Natural)
      return Boolean;

   procedure Configure_Tracker
     (Tracker : in out Outgoing_Tracker;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Set_Tracker_Capacity
     (Tracker  : in out Outgoing_Tracker;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Mark_Sent
     (Tracker : in out Outgoing_Tracker;
      Message : Outgoing_Message;
      Result  : out A11y.Results.Result);

   procedure Complete_Sent
     (Tracker : in out Outgoing_Tracker;
      Serial  : Natural;
      Result  : out A11y.Results.Result);

   procedure Clear (Tracker : in out Outgoing_Tracker);

   function Build_Transport_Envelope
     (Message : Outgoing_Message;
      Result  : out A11y.Results.Result)
      return Transport_Envelope;

   function Build_Transport_Envelope
     (Message : Outgoing_Message;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Transport_Envelope;

   function Build_Transport_Frame_Metadata
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return Transport_Frame_Metadata;

   function Build_Transport_Frame_Metadata
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Transport_Frame_Metadata;

   function Build_Transport_Frame
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return Transport_Frame;

   function Build_Transport_Frame
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Transport_Frame;

   function Build_Transport_Packet
     (Frame  : Transport_Frame;
      Result : out A11y.Results.Result)
      return Transport_Packet;

   function Build_Transport_Packet
     (Frame  : Transport_Frame;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Packet;

   function Build_Transport_Packet
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return Transport_Packet;

   function Build_Transport_Packet
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Transport_Packet;

   function Decode_Transport_Fixed_Header
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header;

   function Decode_Transport_Fixed_Header
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header;

   function Decode_Transport_Packet_Header
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header;

   function Decode_Transport_Packet_Header
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header;

   function Decode_Transport_Envelope
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Envelope;

   function Decode_Transport_Envelope
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Envelope;

   function Decode_Method_Return
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Envelope;

   function Decode_Method_Return
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Envelope;

   function Decode_Error_Return
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Envelope;

   function Decode_Error_Return
     (Bytes  : Ada.Strings.Unbounded.Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Envelope;

   function Diagnostic_For_Error_Return
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Diagnostic_For_Error_Return
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Decode_String_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Decode_String_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Decode_UInt32_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return Natural;

   function Decode_UInt32_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Natural;

   function Decode_Int32_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return Integer;

   function Decode_Int32_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Integer;

   function Decode_UInt32_Array_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.UInt32_Vectors.Vector;

   function Decode_UInt32_Array_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.UInt32_Vectors.Vector;

   function Decode_Object_Path_Array_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector;

   function Decode_Object_Path_Array_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector;

   function Decode_String_Array_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector;

   function Decode_String_Array_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector;

   function Decode_Attribute_Set_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;

   function Decode_Attribute_Set_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;

   function Decode_Relation_Set_Body
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;

   function Decode_Relation_Set_Body
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;

   function Decode_Boolean_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return Boolean;

   function Decode_Boolean_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Boolean;

   function Decode_Rectangle_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Rectangle;

   function Decode_Rectangle_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Rectangle;

   function Decode_Size_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Size;

   function Decode_Size_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Size;

   function Decode_Float_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return Long_Float;

   function Decode_Float_Body
     (Payload : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Long_Float;

   function Decode_Incoming_Call
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Bytes   : Ada.Strings.Unbounded.Unbounded_String;
      Result  : out A11y.Results.Result)
      return Incoming_Call;

   function Decode_Incoming_Call
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Bytes   : Ada.Strings.Unbounded.Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Incoming_Call;

   function Method_Return_Body_Signature
     (Routed_Kind : A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind)
      return String;

   function Method_Return_Payload_Bytes
     (Message : Outgoing_Message;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Method_Return_Payload_Bytes
     (Message : Outgoing_Message;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Validate_Call
     (Message : Incoming_Call)
      return A11y.Results.Result;

   function Validate_Call
     (Message : Incoming_Call;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Build_Reply
     (Original : Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Serial   : Natural;
      Result   : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Reply
     (Original : Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Serial   : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_UInt32
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Natural;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_UInt32_Pair
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument : Natural;
      Second_Argument : Natural;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_UInt32_Pair_String
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Natural;
      Second_Argument : Natural;
      Text_Argument   : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Result          : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_Point
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : A11y.Geometry.Point;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_Float
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Long_Float;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call
     (Object_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Path_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial               : Natural;
      Result               : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_String
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_String_Pair
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Ada.Strings.Unbounded.Unbounded_String;
      Second_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Result          : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_Object_Reference
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Bus_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Reference_Path  : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Result          : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_UInt32
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Natural;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_UInt32_Pair
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument : Natural;
      Second_Argument : Natural;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_UInt32_Pair_String
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Natural;
      Second_Argument : Natural;
      Text_Argument   : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config;
      Result          : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_Point
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : A11y.Geometry.Point;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_Float
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Long_Float;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call
     (Object_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Path_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial               : Natural;
      Limits               : A11y.Resource_Limits.Resource_Limit_Config;
      Result               : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_String
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_String_Pair
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Ada.Strings.Unbounded.Unbounded_String;
      Second_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config;
      Result          : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Method_Call_Object_Reference
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Bus_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Reference_Path  : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config;
      Result          : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Signal
     (Signal : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial : Natural;
      Result : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Signal
     (Signal : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial : Natural;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Outgoing_Message;

   type Signal_Envelope_Build_Report is record
      Source                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Sequence                : A11y.Event_Sequence := A11y.No_Event;
      Revision                : A11y.Semantic_Revision :=
        A11y.Initial_Revision;
      Serial                  : Natural := 0;
      Prepared_Input          : Boolean := False;
      Prepared_Has_Object     : Boolean := False;
      Prepared_Destroys_Node  : Boolean := False;
      Signal_Publishable      : Boolean := False;
      Object_Path_Validated   : Boolean := False;
      Event_Name_Validated    : Boolean := False;
      Output_Signal_Message   : Boolean := False;
      Status                  : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Build_Signal_With_Report
     (Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial  : Natural;
      Message : out Outgoing_Message;
      Report  : out Signal_Envelope_Build_Report);

   procedure Build_Signal_With_Report
     (Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial  : Natural;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Message : out Outgoing_Message;
      Report  : out Signal_Envelope_Build_Report);

   function Build_Signal
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Result   : out A11y.Results.Result)
      return Outgoing_Message;

   function Build_Signal
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Outgoing_Message;

   procedure Build_Signal_With_Report
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Message  : out Outgoing_Message;
      Report   : out Signal_Envelope_Build_Report);

   procedure Build_Signal_With_Report
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Message  : out Outgoing_Message;
      Report   : out Signal_Envelope_Build_Report);

private

   package Outgoing_Message_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Outgoing_Message);

   type Outgoing_Queue is record
      Items        : Outgoing_Message_Vectors.Vector;
      Limit        : Natural := Max_Queued_Messages;
      Had_Overflow : Boolean := False;
   end record;

   package Serial_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Natural);

   type Outgoing_Tracker is record
      Serials : Serial_Vectors.Vector;
      Limit   : Natural := Max_Queued_Messages;
   end record;

end A11y.Linux.DBus_Messages;
