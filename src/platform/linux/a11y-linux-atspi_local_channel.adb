with Ada.Streams;
with Ada.Strings.Fixed;

with A11y.Linux.ATSPi_Address_Discovery;
with A11y.Linux.ATSPi_Objects;
with Hostkit.Process;

package body A11y.Linux.ATSPi_Local_Channel is
   use Ada.Strings.Unbounded;
   use type Ada.Streams.Stream_Element;
   use type Ada.Streams.Stream_Element_Offset;
   use type A11y.Linux.ATSPi_Bus.Address_State;
   use type A11y.Linux.ATSPi_Bus.Connection_State;
   use type A11y.Linux.ATSPi_Bus.Transport_Kind;
   use type A11y.Linux.DBus_Auth.Auth_Response_Kind;
   use type A11y.Linux.DBus_Messages.Message_Kind;
   use type A11y.Results.Status_Code;

   Path_Key : constant String := "path=";
   Abstract_Key : constant String := "abstract=";
   Fixed_Header_Length : constant Natural := 16;
   Max_Auth_Line_Length : constant Natural := 4_096;

   function Is_Open (Item : Channel) return Boolean is
     (Hostkit.Local_Channel.Is_Open (Item.Native));

   procedure Wait_Readable
     (Item       : Channel;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
      Outcome : constant Hostkit.Process.Wait_Outcome :=
        Hostkit.Local_Channel.Wait_Readable (Item.Native, Timeout_MS);
   begin
      case Outcome is
         when Hostkit.Process.Wait_Ready =>
            Result := A11y.Results.Ok;
         when Hostkit.Process.Wait_Timed_Out =>
            Result := (Status => A11y.Results.Timed_Out);
         when Hostkit.Process.Wait_Error =>
            Result := (Status => A11y.Results.Native_Failure);
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Wait_Readable;

   procedure Wait_Writable
     (Item       : Channel;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
      Outcome : constant Hostkit.Process.Wait_Outcome :=
        Hostkit.Local_Channel.Wait_Writable (Item.Native, Timeout_MS);
   begin
      case Outcome is
         when Hostkit.Process.Wait_Ready =>
            Result := A11y.Results.Ok;
         when Hostkit.Process.Wait_Timed_Out =>
            Result := (Status => A11y.Results.Timed_Out);
         when Hostkit.Process.Wait_Error =>
            Result := (Status => A11y.Results.Native_Failure);
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Wait_Writable;

   function Empty_Packet
     (Kind : A11y.Linux.DBus_Messages.Message_Kind :=
        A11y.Linux.DBus_Messages.Error_Return)
      return A11y.Linux.DBus_Messages.Transport_Packet is
     ((Metadata =>
         (Kind               => Kind,
          Serial             => 0,
          Reply_Serial       => 0,
          Header_Field_Count => 0,
          Body_Field_Count   => 0,
          Header_Text_Bytes  => 0,
          Body_Text_Bytes    => 0,
          Estimated_Bytes    => 0),
       Bytes => Null_Unbounded_String));

   function Decode_Startup_Method_Return
     (Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Transport_Envelope
   is
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Error_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Error_Result : A11y.Results.Result;
   begin
      Envelope := A11y.Linux.DBus_Messages.Decode_Method_Return
        (Packet.Bytes, Limits, Result);
      if A11y.Results.Succeeded (Result) then
         return Envelope;
      end if;

      Error_Envelope := A11y.Linux.DBus_Messages.Decode_Error_Return
        (Packet.Bytes, Limits, Error_Result);
      if A11y.Results.Succeeded (Error_Result) then
         Result := A11y.Results.Ok;
         return Error_Envelope;
      end if;

      return Envelope;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
            Serial                    => 0,
            Reply_Serial              => 0,
            Status                    => A11y.Results.Internal_Error,
            Object_Path               => Null_Unbounded_String,
            Interface_Name            => Null_Unbounded_String,
            Member_Name               => Null_Unbounded_String,
            Error_Name                => Null_Unbounded_String,
            Sender_Name               => Null_Unbounded_String,
            Body_Signature            => Null_Unbounded_String,
            Body_Bytes                => Null_Unbounded_String,
            Body_Object_Path_Argument => Null_Unbounded_String,
            Body_String_Argument      => Null_Unbounded_String,
            Body_String_Argument_2    => Null_Unbounded_String,
            Body_UInt32_Argument      => 0,
            Body_UInt32_Argument_2    => 0,
            Body_Point_Argument       => (X => 0, Y => 0),
            Body_Float_Argument       => 0.0);
   end Decode_Startup_Method_Return;

   procedure Receive_Startup_Method_Reply
     (Item     : in out Channel;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Packet   : out A11y.Linux.DBus_Messages.Transport_Packet;
      Envelope : out A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result)
   is
      Max_Interleaved_Packets : constant Positive := 16;
      Candidate : A11y.Linux.DBus_Messages.Transport_Packet;
   begin
      Packet := Empty_Packet;
      Envelope :=
        (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
         Serial                    => 0,
         Reply_Serial              => 0,
         Status                    => A11y.Results.Timed_Out,
         Object_Path               => Null_Unbounded_String,
         Interface_Name            => Null_Unbounded_String,
         Member_Name               => Null_Unbounded_String,
         Error_Name                => Null_Unbounded_String,
         Sender_Name               => Null_Unbounded_String,
         Body_Signature            => Null_Unbounded_String,
         Body_Bytes                => Null_Unbounded_String,
         Body_Object_Path_Argument => Null_Unbounded_String,
         Body_String_Argument      => Null_Unbounded_String,
         Body_String_Argument_2    => Null_Unbounded_String,
         Body_UInt32_Argument      => 0,
         Body_UInt32_Argument_2    => 0,
         Body_Point_Argument       => (X => 0, Y => 0),
         Body_Float_Argument       => 0.0);

      for Attempt in 1 .. Max_Interleaved_Packets loop
         pragma Unreferenced (Attempt);
         Receive_Next_Packet (Item, Limits, Candidate, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         if Candidate.Metadata.Kind =
           A11y.Linux.DBus_Messages.Method_Return
           or else Candidate.Metadata.Kind =
             A11y.Linux.DBus_Messages.Error_Return
         then
            Packet := Candidate;
            Envelope := Decode_Startup_Method_Return
              (Packet, Limits, Result);
            return;
         end if;
      end loop;

      Result := (Status => A11y.Results.Timed_Out);
   exception
      when others =>
         Packet := Empty_Packet;
         Result := (Status => A11y.Results.Internal_Error);
   end Receive_Startup_Method_Reply;

   function Metadata_From_Header
     (Header : A11y.Linux.DBus_Messages.Transport_Packet_Header)
      return A11y.Linux.DBus_Messages.Transport_Frame_Metadata is
     ((Kind               => Header.Kind,
       Serial             => Header.Serial,
       Reply_Serial       => 0,
       Header_Field_Count => 0,
       Body_Field_Count   => 0,
       Header_Text_Bytes  => 0,
       Body_Text_Bytes    => 0,
       Estimated_Bytes    => Header.Packet_Length));

   function Hex_Value (Ch : Character) return Integer is
   begin
      if Ch in '0' .. '9' then
         return Character'Pos (Ch) - Character'Pos ('0');
      elsif Ch in 'A' .. 'F' then
         return Character'Pos (Ch) - Character'Pos ('A') + 10;
      elsif Ch in 'a' .. 'f' then
         return Character'Pos (Ch) - Character'Pos ('a') + 10;
      else
         return -1;
      end if;
   end Hex_Value;

   function Decode_Address_Field
     (Value  : String;
      Result : out A11y.Results.Result)
      return String
   is
      Decoded : Unbounded_String := Null_Unbounded_String;
      Index   : Natural := Value'First;
      High    : Integer;
      Low     : Integer;
      Code    : Natural;
   begin
      while Index <= Value'Last loop
         if Value (Index) /= '%' then
            Append (Decoded, Value (Index));
            Index := Index + 1;
         else
            if Index + 2 > Value'Last then
               Result := (Status => A11y.Results.Invalid_Argument);
               return "";
            end if;

            High := Hex_Value (Value (Index + 1));
            Low := Hex_Value (Value (Index + 2));
            if High < 0 or else Low < 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return "";
            end if;

            Code := Natural (High * 16 + Low);
            if Code = 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return "";
            end if;

            Append (Decoded, Character'Val (Code));
            Index := Index + 3;
         end if;
      end loop;

      Result := A11y.Results.Ok;
      return To_String (Decoded);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return "";
   end Decode_Address_Field;

   function To_Bytes
     (Data : Ada.Streams.Stream_Element_Array)
      return Unbounded_String
   is
      Result : Unbounded_String := Null_Unbounded_String;
   begin
      for Item of Data loop
         Append (Result, Character'Val (Natural (Item)));
      end loop;
      return Result;
   end To_Bytes;

   function To_Stream
     (Text : Unbounded_String)
      return Ada.Streams.Stream_Element_Array
   is
      Raw : constant String := To_String (Text);
      Data : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Raw'Length));
   begin
      for Index in Raw'Range loop
         Data (Ada.Streams.Stream_Element_Offset (Index - Raw'First + 1)) :=
           Ada.Streams.Stream_Element (Character'Pos (Raw (Index)));
      end loop;
      return Data;
   end To_Stream;

   function Startup_Timeout_MS
     (Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Integer
   is
      Value : constant A11y.Resource_Limits.Limit_Value :=
        A11y.Resource_Limits.Value
          (Limits, A11y.Resource_Limits.Callback_Duration_MS);
   begin
      return Integer (Value);
   end Startup_Timeout_MS;

   procedure Receive_Exact_Bounded
     (Item       : in out Channel;
      Data       : out Ada.Streams.Stream_Element_Array;
      Timeout_MS : Integer;
      Result     : out A11y.Results.Result)
   is
      Into : Ada.Streams.Stream_Element_Offset := Data'First;
      Got  : Natural;
   begin
      Data := [Data'Range => 0];

      if not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      while Into <= Data'Last loop
         Wait_Readable (Item, Timeout_MS, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Got :=
           Hostkit.Local_Channel.Receive_Some
             (Item.Native, Data (Into .. Data'Last));
         if Got = 0 then
            Result := (Status => A11y.Results.Native_Failure);
            return;
         end if;

         Into := Into + Ada.Streams.Stream_Element_Offset (Got);
      end loop;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Receive_Exact_Bounded;

   function Receive_Auth_Line
     (Item   : in out Channel;
      Timeout_MS : Integer;
      Result : out A11y.Results.Result)
      return String
   is
      Chunk : Ada.Streams.Stream_Element_Array (1 .. 1);
      Line  : Unbounded_String := Null_Unbounded_String;
   begin
      if not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return "";
      end if;

      loop
         if Length (Line) >= Max_Auth_Line_Length then
            Result := (Status => A11y.Results.Resource_Limit);
            return "";
         end if;

         Receive_Exact_Bounded (Item, Chunk, Timeout_MS, Result);
         if A11y.Results.Failed (Result) then
            return "";
         end if;

         Append (Line, Character'Val (Natural (Chunk (1))));
         exit when Chunk (1) = 10;
      end loop;

      Result := A11y.Results.Ok;
      return To_String (Line);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return "";
   end Receive_Auth_Line;

   procedure Connect_Raw
     (Context : A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      Result  : out A11y.Results.Result)
   is
      Path : Unbounded_String := Null_Unbounded_String;
      Abstract_Name : Unbounded_String := Null_Unbounded_String;
   begin
      Hostkit.Local_Channel.Close (Item.Native);

      if Context.State /= A11y.Linux.ATSPi_Bus.Address_Resolved then
         if Context.Address.State /= A11y.Linux.ATSPi_Bus.Address_Valid
           or else Context.Address.Transport /=
             A11y.Linux.ATSPi_Bus.Unix_Transport
         then
            Result := (Status => A11y.Results.Unsupported_Capability);
         else
            Result := (Status => A11y.Results.Invalid_State);
         end if;
         return;
      end if;

      Path := To_Unbounded_String (Unix_Path (Context.Address, Result));
      if A11y.Results.Succeeded (Result) then
         if not Hostkit.Local_Channel.Connect (To_String (Path), Item.Native)
         then
            Result := (Status => A11y.Results.Backend_Unavailable);
            return;
         end if;
      elsif Result.Status = A11y.Results.Unsupported_Capability then
         Abstract_Name :=
           To_Unbounded_String
             (Unix_Abstract_Name (Context.Address, Result));
         if A11y.Results.Failed (Result) then
            return;
         elsif not Hostkit.Local_Channel.Connect_Abstract
           (To_String (Abstract_Name), Item.Native)
         then
            Result := (Status => A11y.Results.Backend_Unavailable);
            return;
         end if;
      else
         return;
      end if;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Hostkit.Local_Channel.Close (Item.Native);
         Result := (Status => A11y.Results.Internal_Error);
   end Connect_Raw;

   function Unix_Path
     (Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result)
      return String
   is
      Text : constant String := To_String (Address.Text);
      Prefix : constant String := "unix:";
      Start : Natural;
      Stop  : Natural;
   begin
      if Address.State /= A11y.Linux.ATSPi_Bus.Address_Valid
        or else Address.Transport /= A11y.Linux.ATSPi_Bus.Unix_Transport
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return "";
      elsif Text'Length <= Prefix'Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return "";
      end if;

      Start := Ada.Strings.Fixed.Index (Text, Path_Key);
      if Start = 0 then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return "";
      end if;

      Start := Start + Path_Key'Length;
      Stop := Text'Last;
      for Index in Start .. Text'Last loop
         if Text (Index) = ',' or else Text (Index) = ';' then
            Stop := Index - 1;
            exit;
         end if;
      end loop;

      if Start > Stop then
         Result := (Status => A11y.Results.Invalid_Argument);
         return "";
      end if;

      return Decode_Address_Field (Text (Start .. Stop), Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return "";
   end Unix_Path;

   function Unix_Abstract_Name
     (Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result)
      return String
   is
      Text : constant String := To_String (Address.Text);
      Prefix : constant String := "unix:";
      Start : Natural;
      Stop  : Natural;
   begin
      if Address.State /= A11y.Linux.ATSPi_Bus.Address_Valid
        or else Address.Transport /= A11y.Linux.ATSPi_Bus.Unix_Transport
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return "";
      elsif Text'Length <= Prefix'Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return "";
      end if;

      Start := Ada.Strings.Fixed.Index (Text, Abstract_Key);
      if Start = 0 then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return "";
      end if;

      Start := Start + Abstract_Key'Length;
      Stop := Text'Last;
      for Index in Start .. Text'Last loop
         if Text (Index) = ',' or else Text (Index) = ';' then
            Stop := Index - 1;
            exit;
         end if;
      end loop;

      if Start > Stop then
         Result := (Status => A11y.Results.Invalid_Argument);
         return "";
      end if;

      return Decode_Address_Field (Text (Start .. Stop), Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return "";
   end Unix_Abstract_Name;

   procedure Connect
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      Result  : out A11y.Results.Result)
   is
   begin
      Connect_Raw (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.ATSPi_Bus.Mark_Transport_Connected (Context, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
      end if;
   exception
      when others =>
         Hostkit.Local_Channel.Close (Item.Native);
         Result := (Status => A11y.Results.Internal_Error);
   end Connect;

   procedure Connect_Authenticated
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result)
   is
   begin
      Connect_Raw (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Send_External_Auth (Item, User_Id, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         return;
      end if;

      Receive_Auth_Response (Item, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         return;
      end if;

      Send_Begin (Item, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         return;
      end if;

      A11y.Linux.ATSPi_Bus.Mark_Transport_Connected (Context, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
      end if;
   exception
      when others =>
         Hostkit.Local_Channel.Close (Item.Native);
         Result := (Status => A11y.Results.Internal_Error);
   end Connect_Authenticated;

   procedure Connect_Authenticated_And_Hello
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result)
   is
   begin
      Connect_Authenticated_And_Hello
        (Context, Item, User_Id, A11y.Resource_Limits.Default_Config,
         Result);
   end Connect_Authenticated_And_Hello;

   procedure Connect_Authenticated_And_Hello
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
      Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;

      procedure Cleanup_After_Admission is
         Cleanup_Result : A11y.Results.Result;
      begin
         Hostkit.Local_Channel.Close (Item.Native);
         if Context.State in A11y.Linux.ATSPi_Bus.Connected |
           A11y.Linux.ATSPi_Bus.Registered
         then
            A11y.Linux.ATSPi_Bus.Disconnect (Context, Cleanup_Result);
         end if;
      end Cleanup_After_Admission;
   begin
      Connect_Authenticated (Context, Item, User_Id, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.ATSPi_Bus.Queue_Bus_Hello (Context, Limits, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         return;
      end if;

      Send_Next_Packet (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         return;
      end if;

      Receive_Startup_Method_Reply
        (Item, Limits, Packet, Envelope, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         return;
      end if;

      A11y.Linux.ATSPi_Bus.Complete_Bus_Hello
        (Context, Envelope, Limits, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
      end if;
   exception
      when others =>
         Cleanup_After_Admission;
         Result := (Status => A11y.Results.Internal_Error);
   end Connect_Authenticated_And_Hello;

   procedure Connect_Authenticated_Hello_And_Discover_Accessibility_Bus
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Address : out A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result)
   is
   begin
      Connect_Authenticated_Hello_And_Discover_Accessibility_Bus
        (Context, Item, User_Id, A11y.Resource_Limits.Default_Config,
         Address, Result);
   end Connect_Authenticated_Hello_And_Discover_Accessibility_Bus;

   procedure Connect_Authenticated_Hello_And_Discover_Accessibility_Bus
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Address : out A11y.Linux.ATSPi_Bus.Bus_Address;
      Result  : out A11y.Results.Result)
   is
      Report : Address_Discovery_Startup_Report;
   begin
      Connect_Authenticated_Hello_And_Discover_With_Report
        (Context, Item, User_Id, Limits, Address, Report, Result);
   end Connect_Authenticated_Hello_And_Discover_Accessibility_Bus;

   procedure Connect_Authenticated_Hello_And_Discover_With_Report
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Address : out A11y.Linux.ATSPi_Bus.Bus_Address;
      Report  : out Address_Discovery_Startup_Report;
      Result  : out A11y.Results.Result)
   is
      Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;

      procedure Capture_Address_Report is
         Text : constant String := To_String (Context.Address.Text);
      begin
         Report.Address_Resolved :=
           Context.State = A11y.Linux.ATSPi_Bus.Address_Resolved;
         Report.Address_Transport := Context.Address.Transport;
         Report.Address_Field_Count := Context.Address.Field_Count;
         Report.Address_Uses_Path :=
           Context.Address.State = A11y.Linux.ATSPi_Bus.Address_Valid
           and then Context.Address.Transport =
             A11y.Linux.ATSPi_Bus.Unix_Transport
           and then Ada.Strings.Fixed.Index (Text, Path_Key) /= 0;
         Report.Address_Uses_Abstract :=
           Context.Address.State = A11y.Linux.ATSPi_Bus.Address_Valid
           and then Context.Address.Transport =
             A11y.Linux.ATSPi_Bus.Unix_Transport
           and then Ada.Strings.Fixed.Index (Text, Abstract_Key) /= 0;
      exception
         when others =>
            Report.Address_Transport :=
              A11y.Linux.ATSPi_Bus.Other_Transport;
            Report.Address_Field_Count := 0;
            Report.Address_Uses_Path := False;
            Report.Address_Uses_Abstract := False;
      end Capture_Address_Report;

      procedure Refresh_Report (Status : A11y.Results.Status_Code) is
         Unique : constant String := To_String (Context.Unique_Name);
      begin
         Report.Unique_Name_Received := Unique'Length /= 0;
         Report.Unique_Name_Length := Unique'Length;
         Report.Unique_Name_Has_Bus_Prefix :=
           Unique'Length /= 0 and then Unique (Unique'First) = ':';
         Report.Accessibility_Address_State := Address.State;
         Report.Accessibility_Address_Transport := Address.Transport;
         Report.Accessibility_Address_Field_Count := Address.Field_Count;
         Report.Pending_Outgoing :=
           A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count (Context);
         Report.In_Flight_Outgoing :=
           A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count (Context);
         Report.Status := Status;
      exception
         when others =>
            Report.Pending_Outgoing := 0;
            Report.In_Flight_Outgoing := 0;
            Report.Status := A11y.Results.Internal_Error;
      end Refresh_Report;

      procedure Cleanup_After_Admission is
         Cleanup_Result : A11y.Results.Result;
      begin
         Hostkit.Local_Channel.Close (Item.Native);
         if Context.State in A11y.Linux.ATSPi_Bus.Connected |
           A11y.Linux.ATSPi_Bus.Registered
         then
            A11y.Linux.ATSPi_Bus.Disconnect (Context, Cleanup_Result);
         end if;
      end Cleanup_After_Admission;
   begin
      Report := (others => <>);
      Address :=
        (State       => A11y.Linux.ATSPi_Bus.Address_Unavailable,
         Transport   => A11y.Linux.ATSPi_Bus.Other_Transport,
         Text        => Null_Unbounded_String,
         Field_Count => 0);
      Capture_Address_Report;

      Report.Raw_Connect_Attempted := True;
      Connect_Raw (Context, Item, Result);
      Report.Raw_Connect_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Raw_Connected := True;

      Send_External_Auth (Item, User_Id, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Auth_Sent := True;

      Receive_Auth_Response (Item, Result);
      Report.Auth_Response_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Auth_Accepted := True;

      Send_Begin (Item, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Begin_Sent := True;

      A11y.Linux.ATSPi_Bus.Mark_Transport_Connected (Context, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Transport_Admitted := True;

      A11y.Linux.ATSPi_Bus.Queue_Bus_Hello (Context, Limits, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Queued := True;

      Send_Next_Packet (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Sent := True;

      Receive_Startup_Method_Reply
        (Item, Limits, Packet, Envelope, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Reply_Received := True;
      Report.Hello_Reply_Serial := Packet.Metadata.Reply_Serial;
      Report.Hello_Reply_Status := A11y.Results.Success;

      A11y.Linux.ATSPi_Bus.Complete_Bus_Hello
        (Context, Envelope, Limits, Result);
      Report.Hello_Reply_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Completed := True;

      A11y.Linux.ATSPi_Address_Discovery
        .Queue_Accessibility_Bus_Address_Request
          (Context, Limits, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Get_Address_Queued := True;

      Send_Next_Packet (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Get_Address_Sent := True;

      Receive_Startup_Method_Reply
        (Item, Limits, Packet, Envelope, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Get_Address_Reply_Received := True;
      Report.Get_Address_Reply_Serial := Packet.Metadata.Reply_Serial;
      Report.Get_Address_Reply_Error_Name := Envelope.Error_Name;
      Report.Get_Address_Reply_Status := A11y.Results.Success;

      Address :=
        A11y.Linux.ATSPi_Address_Discovery
          .Complete_Accessibility_Bus_Address_Request
            (Context, Envelope, Limits, Result);
      Report.Get_Address_Reply_Status := Result.Status;
      Report.Get_Address_Completed := A11y.Results.Succeeded (Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
      end if;
      Refresh_Report (Result.Status);
   exception
      when others =>
         Cleanup_After_Admission;
         Address :=
           (State       => A11y.Linux.ATSPi_Bus.Address_Invalid,
            Transport   => A11y.Linux.ATSPi_Bus.Other_Transport,
            Text        => Null_Unbounded_String,
            Field_Count => 0);
         Result := (Status => A11y.Results.Internal_Error);
         Report := (others => <>);
         Report.Status := Result.Status;
   end Connect_Authenticated_Hello_And_Discover_With_Report;

   procedure Connect_Authenticated_Hello_And_Register
     (Context          : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item             : out Channel;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
   begin
      Connect_Authenticated_Hello_And_Register
        (Context, Item, User_Id, Application_Node,
         A11y.Resource_Limits.Default_Config, Result);
   end Connect_Authenticated_Hello_And_Register;

   procedure Connect_Authenticated_Hello_And_Register
     (Context          : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item             : out Channel;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
   is
      Report : Registration_Startup_Report;
   begin
      Connect_Authenticated_Hello_And_Register_With_Report
        (Context, Item, User_Id, Application_Node, Limits, Report, Result);
   end Connect_Authenticated_Hello_And_Register;

   procedure Connect_Authenticated_Hello_And_Register_With_Report
     (Context          : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item             : out Channel;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Report           : out Registration_Startup_Report;
      Result           : out A11y.Results.Result)
   is
      Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;

      procedure Capture_Address_Report is
         Text : constant String := To_String (Context.Address.Text);
      begin
         Report.Address_Resolved :=
           Context.State = A11y.Linux.ATSPi_Bus.Address_Resolved;
         Report.Address_Transport := Context.Address.Transport;
         Report.Address_Field_Count := Context.Address.Field_Count;
         Report.Address_Uses_Path :=
           Context.Address.State = A11y.Linux.ATSPi_Bus.Address_Valid
           and then Context.Address.Transport =
             A11y.Linux.ATSPi_Bus.Unix_Transport
           and then Ada.Strings.Fixed.Index (Text, Path_Key) /= 0;
         Report.Address_Uses_Abstract :=
           Context.Address.State = A11y.Linux.ATSPi_Bus.Address_Valid
           and then Context.Address.Transport =
             A11y.Linux.ATSPi_Bus.Unix_Transport
           and then Ada.Strings.Fixed.Index (Text, Abstract_Key) /= 0;
      exception
         when others =>
            Report.Address_Transport :=
              A11y.Linux.ATSPi_Bus.Other_Transport;
            Report.Address_Field_Count := 0;
            Report.Address_Uses_Path := False;
            Report.Address_Uses_Abstract := False;
      end Capture_Address_Report;

      procedure Refresh_Report (Status : A11y.Results.Status_Code) is
         Unique : constant String := To_String (Context.Unique_Name);
         Path_Result : A11y.Results.Result;
         Path : constant String :=
           To_String
             (A11y.Linux.ATSPi_Objects.Object_Path
                (Context.Session, Application_Node, Path_Result));
         Session_Marker : constant String := "/session/";
         Node_Marker : constant String := "/node/";
      begin
         Report.Unique_Name_Received := Unique'Length /= 0;
         Report.Unique_Name_Length := Unique'Length;
         Report.Unique_Name_Has_Bus_Prefix :=
           Unique'Length /= 0 and then Unique (Unique'First) = ':';
         Report.Application_Object_Path_Available :=
           A11y.Results.Succeeded (Path_Result) and then Path'Length /= 0;
         Report.Application_Object_Path_Length :=
           (if Report.Application_Object_Path_Available then Path'Length else 0);
         Report.Application_Object_Path_Has_Session_Prefix :=
           Report.Application_Object_Path_Available
           and then Ada.Strings.Fixed.Index (Path, Session_Marker) /= 0;
         Report.Application_Object_Path_Has_Node_Suffix :=
           Report.Application_Object_Path_Available
           and then Ada.Strings.Fixed.Index (Path, Node_Marker) /= 0;
         Report.Registered :=
           Context.State = A11y.Linux.ATSPi_Bus.Registered;
         Report.Transport_Registration_Observed :=
           Report.Registration_Completed
           and then Report.Registered
           and then A11y.Results.Succeeded ((Status => Status))
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context) = 0;
         Report.Pending_Outgoing :=
           A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count (Context);
         Report.In_Flight_Outgoing :=
           A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count (Context);
         Report.Status := Status;
      exception
         when others =>
            Report.Pending_Outgoing := 0;
            Report.In_Flight_Outgoing := 0;
            Report.Status := A11y.Results.Internal_Error;
      end Refresh_Report;

      procedure Cleanup_After_Admission is
         Cleanup_Result : A11y.Results.Result;
      begin
         Hostkit.Local_Channel.Close (Item.Native);
         if Context.State in A11y.Linux.ATSPi_Bus.Connected |
           A11y.Linux.ATSPi_Bus.Registered
         then
            A11y.Linux.ATSPi_Bus.Disconnect (Context, Cleanup_Result);
         end if;
      end Cleanup_After_Admission;
   begin
      Report := (others => <>);
      Capture_Address_Report;

      Report.Raw_Connect_Attempted := True;
      Connect_Raw (Context, Item, Result);
      Report.Raw_Connect_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Raw_Connected := True;

      Send_External_Auth (Item, User_Id, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Auth_Sent := True;

      Receive_Auth_Response (Item, Result);
      Report.Auth_Response_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Auth_Accepted := True;

      Send_Begin (Item, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Begin_Sent := True;

      A11y.Linux.ATSPi_Bus.Mark_Transport_Connected (Context, Result);
      if A11y.Results.Failed (Result) then
         Hostkit.Local_Channel.Close (Item.Native);
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Transport_Admitted := True;

      A11y.Linux.ATSPi_Bus.Queue_Bus_Hello (Context, Limits, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Queued := True;

      Send_Next_Packet (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Sent := True;

      Receive_Startup_Method_Reply
        (Item, Limits, Packet, Envelope, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Reply_Received := True;
      Report.Hello_Reply_Serial := Packet.Metadata.Reply_Serial;
      Report.Hello_Reply_Status := A11y.Results.Success;

      A11y.Linux.ATSPi_Bus.Complete_Bus_Hello
        (Context, Envelope, Limits, Result);
      Report.Hello_Reply_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Hello_Completed := True;

      declare
         Path_Result : A11y.Results.Result;
         Path : constant Unbounded_String :=
           A11y.Linux.ATSPi_Objects.Object_Path
             (Context.Session, Application_Node, Path_Result);
         pragma Unreferenced (Path);
      begin
         if A11y.Results.Failed (Path_Result) then
            Cleanup_After_Admission;
            Refresh_Report (Path_Result.Status);
            Result := Path_Result;
            return;
         end if;
      end;

      A11y.Linux.ATSPi_Bus.Queue_Application_Registration
        (Context, Application_Node, Limits, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Registration_Queued := True;

      Send_Next_Packet (Context, Item, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Registration_Sent := True;

      Receive_Startup_Method_Reply
        (Item, Limits, Packet, Envelope, Result);
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Registration_Reply_Received := True;
      Report.Registration_Reply_Serial := Packet.Metadata.Reply_Serial;
      Report.Registration_Reply_Was_Error_Return :=
        Envelope.Kind = A11y.Linux.DBus_Messages.Error_Return;
      Report.Registration_Reply_Error_Name := Envelope.Error_Name;
      Report.Registration_Reply_Body_Signature := Envelope.Body_Signature;
      Report.Registration_Reply_Body_Bytes := Length (Envelope.Body_Bytes);
      Report.Registration_Reply_Bus_Name_Length :=
        Length (Envelope.Body_String_Argument);
      Report.Registration_Reply_Object_Path_Length :=
        Length (Envelope.Body_Object_Path_Argument);
      Report.Registration_Reply_Status := A11y.Results.Success;

      A11y.Linux.ATSPi_Bus.Complete_Application_Registration
        (Context, Envelope, Result);
      Report.Registration_Reply_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Cleanup_After_Admission;
         Refresh_Report (Result.Status);
         return;
      end if;
      Report.Registration_Completed := True;
      Refresh_Report (Result.Status);
   exception
      when others =>
         Cleanup_After_Admission;
         Report := (others => <>);
         Result := (Status => A11y.Results.Internal_Error);
         Report.Status := Result.Status;
   end Connect_Authenticated_Hello_And_Register_With_Report;

   procedure Send_External_Auth
     (Item    : in out Channel;
      User_Id : A11y.Linux.DBus_Auth.External_User_Id;
      Result  : out A11y.Results.Result)
   is
      Command : constant Unbounded_String :=
        A11y.Linux.DBus_Auth.Auth_External_Command (User_Id, Result);
   begin
      if A11y.Results.Failed (Result) then
         return;
      elsif not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      declare
         Data : constant Ada.Streams.Stream_Element_Array :=
           To_Stream (Command);
      begin
         Wait_Writable (Item, 0, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         if Hostkit.Local_Channel.Send (Item.Native, Data) then
            Result := A11y.Results.Ok;
         else
            Result := (Status => A11y.Results.Native_Failure);
         end if;
      end;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Send_External_Auth;

   procedure Receive_Auth_Response
     (Item   : in out Channel;
      Result : out A11y.Results.Result)
   is
      Line : constant String :=
        Receive_Auth_Line
          (Item,
           Startup_Timeout_MS (A11y.Resource_Limits.Default_Config),
           Result);
      Response : A11y.Linux.DBus_Auth.Auth_Response;
   begin
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Response := A11y.Linux.DBus_Auth.Decode_Response (Line, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif Response.Kind = A11y.Linux.DBus_Auth.Auth_Ok then
         Result := A11y.Results.Ok;
      elsif Response.Kind = A11y.Linux.DBus_Auth.Auth_Rejected then
         Result := (Status => A11y.Results.Permission_Denied);
      else
         Result := (Status => A11y.Results.Protocol_Failure);
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Receive_Auth_Response;

   procedure Send_Begin
     (Item   : in out Channel;
      Result : out A11y.Results.Result)
   is
      Command : constant Unbounded_String :=
        A11y.Linux.DBus_Auth.Begin_Command;
   begin
      if not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      declare
         Data : constant Ada.Streams.Stream_Element_Array :=
           To_Stream (Command);
      begin
         Wait_Writable (Item, 0, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         if Hostkit.Local_Channel.Send (Item.Native, Data) then
            Result := A11y.Results.Ok;
         else
            Result := (Status => A11y.Results.Native_Failure);
         end if;
      end;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Send_Begin;

   procedure Send_Next_Packet
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : in out Channel;
      Result  : out A11y.Results.Result)
   is
      Packet : A11y.Linux.DBus_Messages.Transport_Packet;
   begin
      if not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
        (Context, Packet, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Send_Packet (Context, Item, Packet, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Send_Next_Packet;

   procedure Send_Packet
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Item    : in out Channel;
      Packet  : A11y.Linux.DBus_Messages.Transport_Packet;
      Result  : out A11y.Results.Result)
   is
      procedure Reject_Tracked_Packet
        (Status : A11y.Results.Status_Code)
      is
         Cleanup : A11y.Results.Result;
      begin
         if Packet.Metadata.Serial /= 0 then
            A11y.Linux.ATSPi_Bus.Complete_Outgoing
              (Context, Packet.Metadata.Serial, Cleanup);
         end if;
         Result := (Status => Status);
      end Reject_Tracked_Packet;
   begin
      if not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Reject_Tracked_Packet (A11y.Results.Backend_Unavailable);
         return;
      elsif Packet.Metadata.Serial = 0
        or else Length (Packet.Bytes) = 0
      then
         Reject_Tracked_Packet (A11y.Results.Invalid_Argument);
         return;
      end if;

      Wait_Writable (Item, 0, Result);
      if A11y.Results.Failed (Result) then
         Reject_Tracked_Packet (Result.Status);
         return;
      end if;

      declare
         Text : constant String := To_String (Packet.Bytes);
         Data : Ada.Streams.Stream_Element_Array
           (1 .. Ada.Streams.Stream_Element_Offset (Text'Length));
      begin
         for Index in Text'Range loop
            Data (Ada.Streams.Stream_Element_Offset (Index - Text'First + 1)) :=
              Ada.Streams.Stream_Element (Character'Pos (Text (Index)));
         end loop;

         if Hostkit.Local_Channel.Send (Item.Native, Data) then
            Result := A11y.Results.Ok;
         else
            A11y.Linux.ATSPi_Bus.Complete_Outgoing
              (Context, Packet.Metadata.Serial, Result);
            Result := (Status => A11y.Results.Native_Failure);
         end if;
      end;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Send_Packet;

   procedure Receive_Next_Packet
     (Item   : in out Channel;
      Packet : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result : out A11y.Results.Result)
   is
   begin
      Receive_Next_Packet
        (Item, A11y.Resource_Limits.Default_Config, Packet, Result);
   end Receive_Next_Packet;

   procedure Receive_Next_Packet
     (Item   : in out Channel;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Packet : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Header : Ada.Streams.Stream_Element_Array
        (1 .. Ada.Streams.Stream_Element_Offset (Fixed_Header_Length));
      Header_Bytes : Unbounded_String;
      Fixed : A11y.Linux.DBus_Messages.Transport_Packet_Header;
      Packet_Length : Natural;
   begin
      Packet := Empty_Packet;
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      elsif not Hostkit.Local_Channel.Is_Open (Item.Native) then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      Receive_Exact_Bounded
        (Item, Header, Startup_Timeout_MS (Limits), Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Header_Bytes := To_Bytes (Header);
      Fixed := A11y.Linux.DBus_Messages.Decode_Transport_Fixed_Header
        (Header_Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Packet_Length := Fixed.Packet_Length;
      if A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Packet_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      declare
         Remaining_Length : constant Natural :=
           Packet_Length - Fixed_Header_Length;
         Remaining : Ada.Streams.Stream_Element_Array
           (1 .. Ada.Streams.Stream_Element_Offset (Remaining_Length));
         Bytes : Unbounded_String := Header_Bytes;
         Decoded : A11y.Linux.DBus_Messages.Transport_Packet_Header;
      begin
         if Remaining_Length > 0 then
            Receive_Exact_Bounded
              (Item, Remaining, Startup_Timeout_MS (Limits), Result);
            if A11y.Results.Failed (Result) then
               Packet := Empty_Packet;
               return;
            end if;

            Append (Bytes, To_Bytes (Remaining));
         end if;

         Decoded := A11y.Linux.DBus_Messages.Decode_Transport_Packet_Header
           (Bytes, Limits, Result);
         if A11y.Results.Failed (Result) then
            Packet := Empty_Packet (Decoded.Kind);
            return;
         end if;

         Packet :=
           (Metadata => Metadata_From_Header (Decoded),
            Bytes => Bytes);
         Result := A11y.Results.Ok;
      end;
   exception
      when others =>
         Packet := Empty_Packet;
         Result := (Status => A11y.Results.Internal_Error);
   end Receive_Next_Packet;

   procedure Close (Item : in out Channel) is
   begin
      Hostkit.Local_Channel.Close (Item.Native);
   exception
      when others =>
         null;
   end Close;

end A11y.Linux.ATSPi_Local_Channel;
