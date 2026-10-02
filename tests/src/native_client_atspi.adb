with Ada.Command_Line;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;
with Ada.Text_IO;
with Ada.Unchecked_Conversion;

with Interfaces;

with A11y.Actions;
with A11y.Capabilities;
with A11y.Documents;
with A11y.Geometry;
with A11y.Images;
with A11y.Live_Regions;
with A11y.Linux.ATSPi_Accessible;
with A11y.Linux.ATSPi_Bus;
with A11y.Linux.ATSPi_Backend_Sessions;
with A11y.Linux.ATSPi_DBus_Boundary;
with A11y.Linux.ATSPi_Local_Channel;
with A11y.Linux.ATSPi_Mappings;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Object_Registry;
with A11y.Linux.ATSPi_Objects;
with A11y.Linux.ATSPi_Scheduler;
with A11y.Linux.ATSPi_Startup;
with A11y.Linux.DBus_Codec;
with A11y.Linux.DBus_Messages;
with A11y.Linux.DBus_Auth;
with A11y.Backends.Native_Backends;
with A11y.Native_Identity;
with A11y.Native_Object_Caches;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.Semantic_Snapshots;
with A11y.Selection;
with A11y.States;
with A11y.Tables;
with A11y.Text;
with A11y.Values;
with A11y.Windows;

with A11y_Native_Client_Reports;
with A11y_Fixture_Application;
with A11y_Test_Fixtures;
with Hostkit;
with Hostkit.Process;

procedure Native_Client_ATSPI is
   use Ada.Strings.Unbounded;
   use type A11y.Actions.Action_Id;
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Length;
   use type A11y.Geometry.Rectangle;
   use type A11y.Linux.ATSPi_DBus_Boundary.DBus_Reply_Kind;
   use type A11y.Linux.ATSPi_Mappings.ATSPI_Relation;
   use type A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind;
   use type A11y.Linux.ATSPi_Startup.Event_Loop_Operation;
   use type A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason;
   use type A11y.Linux.DBus_Messages.Message_Kind;
   use type A11y.Backends.Native_Backends.Native_Transport_State;
   use type A11y.Native_Object_Caches.Native_Object_Id;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;
   use type Interfaces.Unsigned_64;

   Probe_Address_Prefix : constant String := "--probe-address=";
   Probe_Environment_Address_Prefix : constant String :=
     "--probe-env-address=";
   Probe_Session_Address_Prefix :
     constant String := "--probe-session-bus-address=";
   Probe_UID_Prefix     : constant String := "--probe-uid=";
   Probe_Host_Environment_Arg : constant String := "--probe-host-env";
   Boundary_Probe_Arg   : constant String := "--probe-boundary";
   Fixture_Root_Probe_Arg : constant String := "--probe-fixture-root";
   Serving_Packet_Probe_Arg : constant String := "--probe-serving-packet";
   Session_Dispatch_Probe_Arg : constant String := "--probe-session-dispatch";
   External_Client_Session_Probe_Prefix : constant String :=
     "--probe-external-client-session-bus-address=";
   External_Client_ATSPI_Probe_Prefix : constant String :=
     "--probe-external-client-atspi-address=";
   External_Client_Host_Environment_Arg : constant String :=
     "--probe-external-client-host-env";

   function Trimmed (Text : String) return String is
     (Ada.Strings.Fixed.Trim (Text, Ada.Strings.Both));

   function Q (Text : String) return String is
      Result : Unbounded_String := To_Unbounded_String ("""");
   begin
      for Ch of Text loop
         case Ch is
            when '"' =>
               Append (Result, "\""");
            when '\' =>
               Append (Result, "\\");
            when ASCII.LF =>
               Append (Result, "\n");
            when ASCII.CR =>
               Append (Result, "\r");
            when ASCII.HT =>
               Append (Result, "\t");
            when others =>
               if Character'Pos (Ch) < 32 then
                  Append (Result, " ");
               else
                  Append (Result, Ch);
               end if;
         end case;
      end loop;
      Append (Result, """");
      return To_String (Result);
   end Q;

   function Host_Environment_Value (Name : String) return String is
      Value : Hostkit.UString;
   begin
      if Hostkit.Process.Environment_Value (Name, Value) then
         return To_String (Value);
      end if;

      return "";
   exception
      when others =>
         return "";
   end Host_Environment_Value;

   function Status_Name (Status : A11y.Results.Status_Code) return String is
     (Trimmed (A11y.Results.Status_Code'Image (Status)));

   function State_Name
     (State : A11y.Linux.ATSPi_Bus.Connection_State)
      return String is
     (Trimmed (A11y.Linux.ATSPi_Bus.Connection_State'Image (State)));

   function Address_State_Name
     (State : A11y.Linux.ATSPi_Bus.Address_State)
      return String is
     (Trimmed (A11y.Linux.ATSPi_Bus.Address_State'Image (State)));

   function Operation_Name
     (Operation : A11y.Linux.ATSPi_Startup.Event_Loop_Operation)
      return String is
     (Trimmed (A11y.Linux.ATSPi_Startup.Event_Loop_Operation'Image
        (Operation)));

   function Stop_Reason_Name
     (Reason : A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason)
      return String is
     (Trimmed (A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason'Image
        (Reason)));

   procedure Append_Byte
     (Bytes : in out Unbounded_String;
      Value : Natural) is
   begin
      Append (Bytes, Character'Val (Value mod 256));
   end Append_Byte;

   procedure Append_U32_LE
     (Bytes : in out Unbounded_String;
      Value : Natural)
   is
      Work : Natural := Value;
   begin
      for Part in 1 .. 4 loop
         pragma Unreferenced (Part);
         Append_Byte (Bytes, Work mod 256);
         Work := Work / 256;
      end loop;
   end Append_U32_LE;

   procedure Align
     (Bytes     : in out Unbounded_String;
      Alignment : Positive) is
   begin
      while Length (Bytes) mod Alignment /= 0 loop
         Append_Byte (Bytes, 0);
      end loop;
   end Align;

   procedure Append_Double_LE
     (Bytes : in out Unbounded_String;
      Value : Long_Float)
   is
      function To_Bits is new Ada.Unchecked_Conversion
        (Long_Float, Interfaces.Unsigned_64);
      Work : Interfaces.Unsigned_64;
   begin
      Align (Bytes, 8);
      if Long_Float'Size /= 64 then
         return;
      end if;

      Work := To_Bits (Value);
      for Part in 1 .. 8 loop
         pragma Unreferenced (Part);
         Append_Byte (Bytes, Natural (Work mod Interfaces.Unsigned_64'(256)));
         Work := Work / Interfaces.Unsigned_64'(256);
      end loop;
   end Append_Double_LE;

   procedure Append_DBus_String
     (Bytes : in out Unbounded_String;
      Text  : Unbounded_String) is
   begin
      Align (Bytes, 4);
      Append_U32_LE (Bytes, Length (Text));
      Append (Bytes, Text);
      Append_Byte (Bytes, 0);
   end Append_DBus_String;

   procedure Append_DBus_Signature
     (Bytes : in out Unbounded_String;
      Text  : String) is
   begin
      Append_Byte (Bytes, Text'Length);
      Append (Bytes, Text);
      Append_Byte (Bytes, 0);
   end Append_DBus_Signature;

   procedure Append_Field_Text
     (Fields    : in out Unbounded_String;
      Code      : Natural;
      Signature : String;
      Text      : Unbounded_String) is
   begin
      Align (Fields, 8);
      Append_Byte (Fields, Code);
      Append_DBus_Signature (Fields, Signature);
      Align (Fields, 4);
      Append_DBus_String (Fields, Text);
   end Append_Field_Text;

   function Build_External_Method_Call_Packet
     (Destination    : Unbounded_String;
      Object_Path    : Unbounded_String;
      Interface_Name : Unbounded_String;
      Member_Name    : Unbounded_String;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Transport_Packet
   is
      Header_Data : Unbounded_String := Null_Unbounded_String;
      Header      : Unbounded_String := Null_Unbounded_String;
      Bytes       : Unbounded_String := Null_Unbounded_String;
   begin
      if Serial = 0
        or else Length (Destination) = 0
        or else Length (Object_Path) = 0
        or else Length (Interface_Name) = 0
        or else Length (Member_Name) = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
      end if;

      Append_Field_Text (Header_Data, 1, "o", Object_Path);
      Append_Field_Text (Header_Data, 2, "s", Interface_Name);
      Append_Field_Text (Header_Data, 3, "s", Member_Name);
      Append_Field_Text (Header_Data, 6, "s", Destination);

      Append_Byte (Header, Character'Pos ('l'));
      Append_Byte (Header, 1);
      Append_Byte (Header, 0);
      Append_Byte (Header, 1);
      Append_U32_LE (Header, 0);
      Append_U32_LE (Header, Serial);
      Append_U32_LE (Header, Length (Header_Data));
      Align (Header, 8);
      Append (Header, Header_Data);
      Align (Header, 8);
      Bytes := Header;

      Result := A11y.Results.Ok;
      return
        (Metadata =>
           (Kind => A11y.Linux.DBus_Messages.Method_Call,
            Serial => Serial,
            Reply_Serial => 0,
            Header_Field_Count => 4,
            Body_Field_Count => 0,
            Header_Text_Bytes =>
              Length (Destination) + Length (Object_Path)
              + Length (Interface_Name) + Length (Member_Name),
            Body_Text_Bytes => 0,
            Estimated_Bytes => Length (Bytes)),
         Bytes => Bytes);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
   end Build_External_Method_Call_Packet;

   function Build_External_Method_Call_UInt32_Packet
     (Destination    : Unbounded_String;
      Object_Path    : Unbounded_String;
      Interface_Name : Unbounded_String;
      Member_Name    : Unbounded_String;
      Argument       : Natural;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Transport_Packet
   is
      Header_Data : Unbounded_String := Null_Unbounded_String;
      Header      : Unbounded_String := Null_Unbounded_String;
      Body_Data   : Unbounded_String := Null_Unbounded_String;
      Bytes       : Unbounded_String := Null_Unbounded_String;
   begin
      if Serial = 0
        or else Length (Destination) = 0
        or else Length (Object_Path) = 0
        or else Length (Interface_Name) = 0
        or else Length (Member_Name) = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
      end if;

      Append_U32_LE (Body_Data, Argument);

      Append_Field_Text (Header_Data, 1, "o", Object_Path);
      Append_Field_Text (Header_Data, 2, "s", Interface_Name);
      Append_Field_Text (Header_Data, 3, "s", Member_Name);
      Append_Field_Text (Header_Data, 6, "s", Destination);
      Align (Header_Data, 8);
      Append_Byte (Header_Data, 8);
      Append_DBus_Signature (Header_Data, "g");
      Append_DBus_Signature (Header_Data, "u");

      Append_Byte (Header, Character'Pos ('l'));
      Append_Byte (Header, 1);
      Append_Byte (Header, 0);
      Append_Byte (Header, 1);
      Append_U32_LE (Header, Length (Body_Data));
      Append_U32_LE (Header, Serial);
      Append_U32_LE (Header, Length (Header_Data));
      Align (Header, 8);
      Append (Header, Header_Data);
      Align (Header, 8);
      Bytes := Header;
      Append (Bytes, Body_Data);

      Result := A11y.Results.Ok;
      return
        (Metadata =>
           (Kind => A11y.Linux.DBus_Messages.Method_Call,
            Serial => Serial,
            Reply_Serial => 0,
            Header_Field_Count => 5,
            Body_Field_Count => 1,
            Header_Text_Bytes =>
              Length (Destination) + Length (Object_Path)
              + Length (Interface_Name) + Length (Member_Name) + 1,
            Body_Text_Bytes => 0,
            Estimated_Bytes => Length (Bytes)),
         Bytes => Bytes);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
   end Build_External_Method_Call_UInt32_Packet;

   function Build_External_Method_Call_Float_Packet
     (Destination    : Unbounded_String;
      Object_Path    : Unbounded_String;
      Interface_Name : Unbounded_String;
      Member_Name    : Unbounded_String;
      Argument       : Long_Float;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Transport_Packet
   is
      Header_Data : Unbounded_String := Null_Unbounded_String;
      Header      : Unbounded_String := Null_Unbounded_String;
      Body_Data   : Unbounded_String := Null_Unbounded_String;
      Bytes       : Unbounded_String := Null_Unbounded_String;
   begin
      if Serial = 0
        or else Length (Destination) = 0
        or else Length (Object_Path) = 0
        or else Length (Interface_Name) = 0
        or else Length (Member_Name) = 0
        or else Long_Float'Size /= 64
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
      end if;

      Append_Double_LE (Body_Data, Argument);

      Append_Field_Text (Header_Data, 1, "o", Object_Path);
      Append_Field_Text (Header_Data, 2, "s", Interface_Name);
      Append_Field_Text (Header_Data, 3, "s", Member_Name);
      Append_Field_Text (Header_Data, 6, "s", Destination);
      Align (Header_Data, 8);
      Append_Byte (Header_Data, 8);
      Append_DBus_Signature (Header_Data, "g");
      Append_DBus_Signature (Header_Data, "d");

      Append_Byte (Header, Character'Pos ('l'));
      Append_Byte (Header, 1);
      Append_Byte (Header, 0);
      Append_Byte (Header, 1);
      Append_U32_LE (Header, Length (Body_Data));
      Append_U32_LE (Header, Serial);
      Append_U32_LE (Header, Length (Header_Data));
      Align (Header, 8);
      Append (Header, Header_Data);
      Align (Header, 8);
      Bytes := Header;
      Append (Bytes, Body_Data);

      Result := A11y.Results.Ok;
      return
        (Metadata =>
           (Kind => A11y.Linux.DBus_Messages.Method_Call,
            Serial => Serial,
            Reply_Serial => 0,
            Header_Field_Count => 5,
            Body_Field_Count => 1,
            Header_Text_Bytes =>
              Length (Destination) + Length (Object_Path)
              + Length (Interface_Name) + Length (Member_Name) + 1,
            Body_Text_Bytes => 0,
            Estimated_Bytes => Length (Bytes)),
         Bytes => Bytes);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
   end Build_External_Method_Call_Float_Packet;

   function Build_External_Method_Call_Point_Packet
     (Destination    : Unbounded_String;
      Object_Path    : Unbounded_String;
      Interface_Name : Unbounded_String;
      Member_Name    : Unbounded_String;
      Argument       : A11y.Geometry.Point;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Transport_Packet
   is
      Header_Data : Unbounded_String := Null_Unbounded_String;
      Header      : Unbounded_String := Null_Unbounded_String;
      Body_Data   : Unbounded_String := Null_Unbounded_String;
      Bytes       : Unbounded_String := Null_Unbounded_String;

      function Fits_I32 (Value : A11y.Geometry.Coordinate) return Boolean is
        (Long_Integer (Value) >= Long_Integer (Integer'First)
         and then Long_Integer (Value) <= Long_Integer (Integer'Last));
   begin
      if Serial = 0
        or else Length (Destination) = 0
        or else Length (Object_Path) = 0
        or else Length (Interface_Name) = 0
        or else Length (Member_Name) = 0
        or else not Fits_I32 (Argument.X)
        or else not Fits_I32 (Argument.Y)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
      end if;

      Append_U32_LE (Body_Data, Natural (Argument.X));
      Append_U32_LE (Body_Data, Natural (Argument.Y));

      Append_Field_Text (Header_Data, 1, "o", Object_Path);
      Append_Field_Text (Header_Data, 2, "s", Interface_Name);
      Append_Field_Text (Header_Data, 3, "s", Member_Name);
      Append_Field_Text (Header_Data, 6, "s", Destination);
      Align (Header_Data, 8);
      Append_Byte (Header_Data, 8);
      Append_DBus_Signature (Header_Data, "g");
      Append_DBus_Signature (Header_Data, "ii");

      Append_Byte (Header, Character'Pos ('l'));
      Append_Byte (Header, 1);
      Append_Byte (Header, 0);
      Append_Byte (Header, 1);
      Append_U32_LE (Header, Length (Body_Data));
      Append_U32_LE (Header, Serial);
      Append_U32_LE (Header, Length (Header_Data));
      Align (Header, 8);
      Append (Header, Header_Data);
      Align (Header, 8);
      Bytes := Header;
      Append (Bytes, Body_Data);

      Result := A11y.Results.Ok;
      return
        (Metadata =>
           (Kind => A11y.Linux.DBus_Messages.Method_Call,
            Serial => Serial,
            Reply_Serial => 0,
            Header_Field_Count => 5,
            Body_Field_Count => 2,
            Header_Text_Bytes =>
              Length (Destination) + Length (Object_Path)
              + Length (Interface_Name) + Length (Member_Name) + 2,
            Body_Text_Bytes => 0,
            Estimated_Bytes => Length (Bytes)),
         Bytes => Bytes);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
   end Build_External_Method_Call_Point_Packet;

   function Build_External_Method_Call_String_Packet
     (Destination    : Unbounded_String;
      Object_Path    : Unbounded_String;
      Interface_Name : Unbounded_String;
      Member_Name    : Unbounded_String;
      Argument       : Unbounded_String;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Transport_Packet
   is
      Header_Data : Unbounded_String := Null_Unbounded_String;
      Header      : Unbounded_String := Null_Unbounded_String;
      Body_Data   : Unbounded_String := Null_Unbounded_String;
      Bytes       : Unbounded_String := Null_Unbounded_String;
   begin
      if Serial = 0
        or else Length (Destination) = 0
        or else Length (Object_Path) = 0
        or else Length (Interface_Name) = 0
        or else Length (Member_Name) = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
      end if;

      Append_DBus_String (Body_Data, Argument);

      Append_Field_Text (Header_Data, 1, "o", Object_Path);
      Append_Field_Text (Header_Data, 2, "s", Interface_Name);
      Append_Field_Text (Header_Data, 3, "s", Member_Name);
      Append_Field_Text (Header_Data, 6, "s", Destination);
      Align (Header_Data, 8);
      Append_Byte (Header_Data, 8);
      Append_DBus_Signature (Header_Data, "g");
      Append_DBus_Signature (Header_Data, "s");

      Append_Byte (Header, Character'Pos ('l'));
      Append_Byte (Header, 1);
      Append_Byte (Header, 0);
      Append_Byte (Header, 1);
      Append_U32_LE (Header, Length (Body_Data));
      Append_U32_LE (Header, Serial);
      Append_U32_LE (Header, Length (Header_Data));
      Align (Header, 8);
      Append (Header, Header_Data);
      Align (Header, 8);
      Bytes := Header;
      Append (Bytes, Body_Data);

      Result := A11y.Results.Ok;
      return
        (Metadata =>
           (Kind => A11y.Linux.DBus_Messages.Method_Call,
            Serial => Serial,
            Reply_Serial => 0,
            Header_Field_Count => 5,
            Body_Field_Count => 1,
            Header_Text_Bytes =>
              Length (Destination) + Length (Object_Path)
              + Length (Interface_Name) + Length (Member_Name) + 1,
            Body_Text_Bytes => Length (Argument),
            Estimated_Bytes => Length (Bytes)),
         Bytes => Bytes);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Metadata =>
              (Kind => A11y.Linux.DBus_Messages.Error_Return,
               Serial => 0,
               Reply_Serial => 0,
               Header_Field_Count => 0,
               Body_Field_Count => 0,
               Header_Text_Bytes => 0,
               Body_Text_Bytes => 0,
               Estimated_Bytes => 0),
            Bytes => Null_Unbounded_String);
   end Build_External_Method_Call_String_Packet;

   function Parse_UID
     (Text : String;
      Result : out A11y.Results.Result)
      return A11y.Linux.DBus_Auth.External_User_Id
   is
      Value : Natural;
   begin
      Value := Natural'Value (Text);
      Result := A11y.Results.Ok;
      return A11y.Linux.DBus_Auth.External_User_Id (Value);
   exception
      when others =>
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
   end Parse_UID;

   function Default_User_Id
      return A11y.Linux.DBus_Auth.External_User_Id
   is
      Host_User_Id : Natural := 0;
   begin
      if Hostkit.Process.Current_User_Id (Host_User_Id) then
         return A11y.Linux.DBus_Auth.External_User_Id (Host_User_Id);
      else
         return 0;
      end if;
   exception
      when others =>
         return 0;
   end Default_User_Id;

   procedure Emit_Boundary_Probe is
      type Registry_Access is access all
        A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      type Snapshot_Access is access all
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;

      Root : constant A11y.Node_Ids.Node_Id := A11y.Node_Ids.From_Natural (1);
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Registry : constant Registry_Access :=
        new A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Registered :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Registry_View :
        A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;
      Snapshots : constant Snapshot_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Call : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Reply : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Boundary_Report :
        A11y.Linux.ATSPi_DBus_Boundary.Registered_Call_Boundary_Report;
      Result : A11y.Results.Result;
      Object_Path_Built : Boolean := False;
      Object_Registered : Boolean := False;
      Boundary_Dispatched : Boolean := False;
      Boundary_Resolved : Boolean := False;
      Boundary_Admitted : Boolean := False;
      Boundary_Completed : Boolean := False;
      Boundary_Begin_Outstanding_Before : Natural := 0;
      Boundary_Begin_Outstanding_After : Natural := 0;
      Boundary_End_Outstanding_Before : Natural := 0;
      Boundary_End_Outstanding_After : Natural := 0;
      Native_Call_Completed : Boolean := False;
      Native_Call_Drained : Boolean := False;
      Boundary_Status : A11y.Results.Status_Code := A11y.Results.Internal_Error;
      Action_Count_Dispatched : Boolean := False;
      Action_Name_Dispatched : Boolean := False;
      Action_Invoke_Dispatched : Boolean := False;
      Relation_Set_Dispatched : Boolean := False;
      Relation_Payload_Preserved : Boolean := False;
   begin
      Session := A11y.Native_Identity.Create_Session;
      Call.Session := Session;
      Call.Object_Path :=
        A11y.Linux.ATSPi_Objects.Object_Path (Session, Root, Result);
      Object_Path_Built := A11y.Results.Succeeded (Result);
      Call.Interface_Name := To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Interface_Name
           (A11y.Linux.ATSPi_Objects.Accessible));
      Call.Method_Name := To_Unbounded_String ("GetRole");

      if Object_Path_Built then
         A11y.Linux.ATSPi_Object_Registry.Ensure_Object
           (Registry.all, Session, Root, Registered, Result);
         Object_Registered :=
           A11y.Results.Succeeded (Result)
           and then Registered.Node = Root
           and then Length (Registered.Path) /= 0;
      end if;

      if Object_Registered then
         Snapshots.all.Accessible.Id := Root;
         Snapshots.all.Accessible.Role := A11y.Roles.Button;
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary
             .Dispatch_Registered_Call_With_Report
               (Registry.all, Call, Snapshots.all, Boundary_Report);
         Registry_View :=
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Registry.all);
         Boundary_Status := Reply.Status;
         Boundary_Resolved := Boundary_Report.Resolved;
         Boundary_Admitted := Boundary_Report.Native_Admitted;
         Boundary_Completed := Boundary_Report.Native_Completed;
         Boundary_Begin_Outstanding_Before :=
           Boundary_Report.Begin_Report.Outstanding_Before;
         Boundary_Begin_Outstanding_After :=
           Boundary_Report.Begin_Report.Outstanding_After;
         Boundary_End_Outstanding_Before :=
           Boundary_Report.End_Report.Outstanding_Before;
         Boundary_End_Outstanding_After :=
           Boundary_Report.End_Report.Outstanding_After;
         Boundary_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Role
           and then Boundary_Status = A11y.Results.Success;

         Snapshots.all.Action.Id := Root;
         Snapshots.all.Action.Root := Root;
         Snapshots.all.Action.Supported :=
           A11y.Actions.With_Action
             (A11y.Actions.With_Action
                (A11y.Actions.Empty_Action_Set, A11y.Actions.Press),
              A11y.Actions.Toggle);
         Call.Interface_Name := To_Unbounded_String
           (A11y.Linux.ATSPi_Objects.Interface_Name
              (A11y.Linux.ATSPi_Objects.Action));
         Call.Method_Name := To_Unbounded_String ("GetNActions");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Action_Count_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Action_UInt32
           and then Reply.Status = A11y.Results.Success
           and then Reply.UInt32 = 2;

         Call.Method_Name := To_Unbounded_String ("GetName");
         Call.Index := 0;
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Action_Name_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Action_String
           and then Reply.Status = A11y.Results.Success
           and then To_String (Reply.Text) = A11y.Actions.Stable_Name
             (A11y.Actions.Press);

         Call.Method_Name := To_Unbounded_String ("DoAction");
         Call.Index := 1;
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Action_Invoke_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Action_Invocation
           and then Reply.Status = A11y.Results.Success
           and then Reply.Requested_Action = A11y.Actions.Toggle;

         A11y.Relations.Add
           (Snapshots.all.Accessible.Relations,
            Root,
            A11y.Relations.Labelled_By,
            A11y.Node_Ids.From_Natural (2),
            Result);
         Call.Interface_Name := To_Unbounded_String
           (A11y.Linux.ATSPi_Objects.Interface_Name
              (A11y.Linux.ATSPi_Objects.Accessible));
         Call.Method_Name := To_Unbounded_String ("GetRelationSet");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Relation_Set_Dispatched :=
           A11y.Results.Succeeded (Result)
           and then Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Relation_Set
           and then Reply.Status = A11y.Results.Success
           and then Natural (Reply.Relations.Length) = 1;
         Relation_Payload_Preserved :=
           Relation_Set_Dispatched
           and then Reply.Relations.First_Element.Kind =
             A11y.Linux.ATSPi_Mappings.Labelled_By
           and then Natural
             (Reply.Relations.First_Element.Targets.Length) = 1
           and then Reply.Relations.First_Element.Targets.First_Element =
             A11y.Node_Ids.From_Natural (2);

         Registry_View :=
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Registry.all);
         Native_Call_Drained := Registry_View.Outstanding_Calls = 0;
         Native_Call_Completed :=
           Boundary_Dispatched
           and then Action_Count_Dispatched
           and then Action_Name_Dispatched
           and then Action_Invoke_Dispatched
           and then Relation_Set_Dispatched
           and then Relation_Payload_Preserved
           and then Native_Call_Drained;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_boundary_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Linux_ATSPI))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line
        ("  ""object_path_built"": "
         & (if Object_Path_Built then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_registered"": "
         & (if Object_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_dispatched"": "
         & (if Boundary_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_resolved"": "
         & (if Boundary_Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_admitted"": "
         & (if Boundary_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_completed"": "
         & (if Boundary_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_begin_outstanding_before"": "
         & Trimmed (Natural'Image (Boundary_Begin_Outstanding_Before))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_begin_outstanding_after"": "
         & Trimmed (Natural'Image (Boundary_Begin_Outstanding_After))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_end_outstanding_before"": "
         & Trimmed (Natural'Image (Boundary_End_Outstanding_Before))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_boundary_end_outstanding_after"": "
         & Trimmed (Natural'Image (Boundary_End_Outstanding_After))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_action_count_dispatched"": "
         & (if Action_Count_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_action_name_dispatched"": "
         & (if Action_Name_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_action_invoke_dispatched"": "
         & (if Action_Invoke_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_relation_set_dispatched"": "
         & (if Relation_Set_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered_relation_payload_preserved"": "
         & (if Relation_Payload_Preserved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_completed"": "
         & (if Native_Call_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_drained"": "
         & (if Native_Call_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_status"": " & Q (Status_Name (Boundary_Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_boundary_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line ("  ""object_path_built"": false,");
         Ada.Text_IO.Put_Line ("  ""object_registered"": false,");
         Ada.Text_IO.Put_Line
         ("  ""registered_boundary_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_resolved"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""registered_boundary_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_begin_outstanding_before"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_begin_outstanding_after"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_end_outstanding_before"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_boundary_end_outstanding_after"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registered_action_count_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_action_name_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_action_invoke_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_relation_set_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registered_relation_payload_preserved"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""boundary_status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Boundary_Probe;

   procedure Emit_Session_Dispatch_Probe is
      type Snapshot_Access is access all
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;

      Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Snapshots : constant Snapshot_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Call : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Reply : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Registry_View :
        A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;
      Session_View :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      Loop_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;
      Loop_Result : A11y.Results.Result;
      Scheduler : A11y.Linux.ATSPi_Scheduler.Scheduler;
      Scheduler_Config : constant
        A11y.Linux.ATSPi_Scheduler.Scheduler_Config :=
          (Max_Iterations_Per_Run => 1,
           Read_Timeout_MS        => 0);
      Scheduler_Cycle_Report :
        A11y.Linux.ATSPi_Scheduler.Transport_Cycle_Run_Report;
      Scheduler_Cycle_Result : A11y.Results.Result :=
        (Status => A11y.Results.Backend_Unavailable);
      Scheduler_Cycle_Configured : Boolean := False;
      Call_Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
      Root : constant A11y.Node_Ids.Node_Id := A11y.Node_Ids.From_Natural (1);
      Path_Result : A11y.Results.Result;
      Boundary_Report :
        A11y.Linux.ATSPi_DBus_Boundary.Registered_Call_Boundary_Report;
      Boundary_Resolved : Boolean := False;
      Boundary_Admitted : Boolean := False;
      Boundary_Completed : Boolean := False;
      Boundary_Begin_Outstanding_Before : Natural := 0;
      Boundary_Begin_Outstanding_After : Natural := 0;
      Boundary_End_Outstanding_Before : Natural := 0;
      Boundary_End_Outstanding_After : Natural := 0;
      Boundary_Drained : Boolean := False;
      Boundary_Final_Status : A11y.Results.Status_Code :=
        A11y.Results.Internal_Error;
      Completed : Boolean := False;
   begin
      Call.Session := Call_Session;
      Call.Object_Path :=
        A11y.Linux.ATSPi_Objects.Object_Path
          (Call_Session, Root, Path_Result);
      Call.Interface_Name := To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Interface_Name
           (A11y.Linux.ATSPi_Objects.Accessible));
      Call.Method_Name := To_Unbounded_String ("GetRole");

      Snapshots.all.Accessible.Id := Root;
      Snapshots.all.Accessible.Role := A11y.Roles.Application;

      Reply :=
        A11y.Linux.ATSPi_Backend_Sessions.Dispatch_Registered_Call_With_Report
          (Session, Call, Snapshots.all, Boundary_Report);
      Registry_View :=
        A11y.Linux.ATSPi_Backend_Sessions.Registry_Snapshot (Session);
      Boundary_Resolved := Boundary_Report.Resolved;
      Boundary_Admitted := Boundary_Report.Native_Admitted;
      Boundary_Completed := Boundary_Report.Native_Completed;
      Boundary_Begin_Outstanding_Before :=
        Boundary_Report.Begin_Report.Outstanding_Before;
      Boundary_Begin_Outstanding_After :=
        Boundary_Report.Begin_Report.Outstanding_After;
      Boundary_End_Outstanding_Before :=
        Boundary_Report.End_Report.Outstanding_Before;
      Boundary_End_Outstanding_After :=
        Boundary_Report.End_Report.Outstanding_After;
      Boundary_Drained :=
        (not Boundary_Admitted)
        and then Boundary_Begin_Outstanding_Before = 0
        and then Boundary_Begin_Outstanding_After = 0
        and then Boundary_End_Outstanding_Before = 0
        and then Boundary_End_Outstanding_After = 0
        and then Registry_View.Outstanding_Calls = 0;
      Boundary_Final_Status := Boundary_Report.Final_Status;
      A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
        (Session, Snapshots.all, 1, Loop_Report, Loop_Result);
      A11y.Linux.ATSPi_Scheduler.Configure
        (Scheduler, Scheduler_Config, Scheduler_Cycle_Result);
      Scheduler_Cycle_Configured :=
        A11y.Results.Succeeded (Scheduler_Cycle_Result);
      if Scheduler_Cycle_Configured then
         A11y.Linux.ATSPi_Scheduler.Run_One_Transport_Cycle
           (Scheduler,
            Session,
            Snapshots.all,
            Scheduler_Cycle_Report,
            Scheduler_Cycle_Result);
      end if;
      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Session, Session_View);
      Completed :=
        A11y.Results.Succeeded (Path_Result)
        and then Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Error_Reply
        and then Reply.Status = A11y.Results.Backend_Unavailable
        and then not Boundary_Resolved
        and then not Boundary_Admitted
        and then not Boundary_Completed
        and then Boundary_Drained
        and then Boundary_Final_Status = A11y.Results.Backend_Unavailable
        and then Loop_Result.Status = A11y.Results.Backend_Unavailable
        and then Session_View.Has_Event_Loop_Report
        and then Session_View.Last_Event_Loop.Status =
          A11y.Results.Backend_Unavailable
        and then Session_View.Last_Event_Loop.Stop_Reason =
          A11y.Linux.ATSPi_Startup.Readiness_Failed
        and then Session_View.Last_Event_Loop.Last_Operation =
          A11y.Linux.ATSPi_Startup.Wait_For_Transport
        and then Scheduler_Cycle_Configured
        and then Scheduler_Cycle_Result.Status =
          A11y.Results.Backend_Unavailable
        and then Scheduler_Cycle_Report.Run_Attempted
        and then Scheduler_Cycle_Report.Interest_Before.Next_Operation =
          A11y.Linux.ATSPi_Startup.Wait_For_Transport
        and then Scheduler_Cycle_Report.Wait_Status =
          A11y.Results.Backend_Unavailable
        and then not Scheduler_Cycle_Report.Wait_Attempted
        and then not Scheduler_Cycle_Report.Wait_Timed_Out
        and then not Scheduler_Cycle_Report.Wait_Readable
        and then not Scheduler_Cycle_Report.Cycle.Ready_Checked
        and then not Scheduler_Cycle_Report.Cycle.Read_Attempted
        and then not Scheduler_Cycle_Report.Cycle.Serve_Attempted
        and then not Scheduler_Cycle_Report.Cycle.Write_Attempted
        and then Registry_View.Live_Count = 0
        and then Registry_View.Outstanding_Calls = 0;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_session_dispatch_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Linux_ATSPI))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line
        ("  ""decoded_call_path_built"": "
         & (if A11y.Results.Succeeded (Path_Result) then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_dispatch_rejected_before_registration"": "
         & (if Reply.Status = A11y.Results.Backend_Unavailable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_resolved"": "
         & (if Boundary_Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_admitted"": "
         & (if Boundary_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_completed"": "
         & (if Boundary_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_begin_outstanding_before"": "
         & Trimmed (Natural'Image (Boundary_Begin_Outstanding_Before))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_begin_outstanding_after"": "
         & Trimmed (Natural'Image (Boundary_Begin_Outstanding_After))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_end_outstanding_before"": "
         & Trimmed (Natural'Image (Boundary_End_Outstanding_Before))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_end_outstanding_after"": "
         & Trimmed (Natural'Image (Boundary_End_Outstanding_After))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_drained"": "
         & (if Boundary_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_boundary_final_status"": "
         & Q (Status_Name (Boundary_Final_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_live_count"": "
         & Trimmed (Natural'Image (Registry_View.Live_Count))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_outstanding_calls"": "
         & Trimmed (Natural'Image (Registry_View.Outstanding_Calls))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_event_loop_report_captured"": "
         & (if Session_View.Has_Event_Loop_Report then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_event_loop_status"": "
         & Q (Status_Name (Session_View.Last_Event_Loop.Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_event_loop_stop_reason"": "
         & Q
             (Stop_Reason_Name
                (Session_View.Last_Event_Loop.Stop_Reason))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_event_loop_last_operation"": "
         & Q
             (Operation_Name
                (Session_View.Last_Event_Loop.Last_Operation))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_event_loop_steps_attempted"": "
         & Trimmed
             (Natural'Image
                (Session_View.Last_Event_Loop.Steps_Attempted))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_event_loop_steps_completed"": "
         & Trimmed
             (Natural'Image
                (Session_View.Last_Event_Loop.Steps_Completed))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_configured"": "
         & (if Scheduler_Cycle_Configured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_attempted"": "
         & (if Scheduler_Cycle_Report.Run_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_status"": "
         & Q (Status_Name (Scheduler_Cycle_Result.Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_interest_before"": "
         & Q
             (Operation_Name
                (Scheduler_Cycle_Report.Interest_Before.Next_Operation))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_interest_after"": "
         & Q
             (Operation_Name
                (Scheduler_Cycle_Report.Interest_After.Next_Operation))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_wait_attempted"": "
         & (if Scheduler_Cycle_Report.Wait_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_wait_status"": "
         & Q (Status_Name (Scheduler_Cycle_Report.Wait_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_wait_timed_out"": "
         & (if Scheduler_Cycle_Report.Wait_Timed_Out
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_wait_readable"": "
         & (if Scheduler_Cycle_Report.Wait_Readable
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_write_wait_attempted"": "
         & (if Scheduler_Cycle_Report.Write_Wait_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_write_wait_status"": "
         & Q (Status_Name (Scheduler_Cycle_Report.Write_Wait_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_write_wait_timed_out"": "
         & (if Scheduler_Cycle_Report.Write_Wait_Timed_Out
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_write_wait_ready"": "
         & (if Scheduler_Cycle_Report.Write_Wait_Ready
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_flushed"": "
         & Trimmed (Natural'Image (Scheduler_Cycle_Report.Flushed))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_ready_checked"": "
         & (if Scheduler_Cycle_Report.Cycle.Ready_Checked
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_read_attempted"": "
         & (if Scheduler_Cycle_Report.Cycle.Read_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_incoming_kind"": "
         & Q
             (A11y.Linux.DBus_Messages.Message_Kind'Image
                (Scheduler_Cycle_Report.Cycle.Incoming_Packet_Kind))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_incoming_serial"": "
         & Trimmed
             (Natural'Image
                (Scheduler_Cycle_Report.Cycle.Incoming_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_incoming_reply_serial"": "
         & Trimmed
             (Natural'Image
                (Scheduler_Cycle_Report.Cycle.Incoming_Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_incoming_estimated_bytes"": "
         & Trimmed
             (Natural'Image
                (Scheduler_Cycle_Report.Cycle.Incoming_Estimated_Bytes))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_serve_attempted"": "
         & (if Scheduler_Cycle_Report.Cycle.Serve_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_write_attempted"": "
         & (if Scheduler_Cycle_Report.Cycle.Write_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_reply_kind"": "
         & Q
             (A11y.Linux.DBus_Messages.Message_Kind'Image
                (Scheduler_Cycle_Report.Cycle.Reply_Packet_Kind))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_reply_serial"": "
         & Trimmed
             (Natural'Image (Scheduler_Cycle_Report.Cycle.Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_reply_reply_serial"": "
         & Trimmed
             (Natural'Image
                (Scheduler_Cycle_Report.Cycle.Reply_Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""session_scheduler_transport_cycle_reply_estimated_bytes"": "
         & Trimmed
             (Natural'Image
                (Scheduler_Cycle_Report.Cycle.Reply_Estimated_Bytes))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe_status"": "
         & Q (if Completed then "success" else "incomplete")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": " & Q (Status_Name (Reply.Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_session_dispatch_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line ("  ""decoded_call_path_built"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_dispatch_rejected_before_registration"": false,");
         Ada.Text_IO.Put_Line ("  ""session_boundary_resolved"": false,");
         Ada.Text_IO.Put_Line ("  ""session_boundary_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""session_boundary_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_boundary_begin_outstanding_before"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_boundary_begin_outstanding_after"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_boundary_end_outstanding_before"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_boundary_end_outstanding_after"": 0,");
         Ada.Text_IO.Put_Line ("  ""session_boundary_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_boundary_final_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""registry_live_count"": 0,");
         Ada.Text_IO.Put_Line ("  ""registry_outstanding_calls"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_event_loop_report_captured"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_event_loop_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""session_event_loop_stop_reason"": ""ITERATION_FAILED"",");
         Ada.Text_IO.Put_Line
           ("  ""session_event_loop_last_operation"": ""TRANSPORT_FAILED"",");
         Ada.Text_IO.Put_Line
           ("  ""session_event_loop_steps_attempted"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_event_loop_steps_completed"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_configured"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_interest_before"": ""WAIT_FOR_TRANSPORT"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_interest_after"": ""WAIT_FOR_TRANSPORT"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_wait_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_wait_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_wait_timed_out"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_wait_readable"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_write_wait_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_write_wait_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_write_wait_timed_out"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_write_wait_ready"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_flushed"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_ready_checked"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_read_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_incoming_kind"": ""ERROR_RETURN"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_incoming_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_incoming_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_incoming_estimated_bytes"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_serve_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_write_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_reply_kind"": ""ERROR_RETURN"",");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_reply_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""session_scheduler_transport_cycle_reply_estimated_bytes"": 0,");
         Ada.Text_IO.Put_Line ("  ""probe_status"": ""incomplete"",");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Session_Dispatch_Probe;

   procedure Emit_Fixture_Root_Probe is
      type Registry_Access is access all
        A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      type Snapshot_Access is access all
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;

      Root : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Application_Id;
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Registry : constant Registry_Access :=
        new A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Registered :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Child_Registered :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Second_Child_Registered :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Registry_View :
        A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;
      Registry_Record_View :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Registry_Report :
        A11y.Linux.ATSPi_Object_Registry.Registry_Mutation_Report;
      Snapshots : constant Snapshot_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Call : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Reply : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Result : A11y.Results.Result;
      Object_Path_Built : Boolean := False;
      Object_Registered : Boolean := False;
      Child_Object_Registered : Boolean := False;
      Second_Child_Object_Registered : Boolean := False;
      Native_Call_Completed : Boolean := False;
      Native_Call_Drained : Boolean := False;
      Root_Query_Dispatched : Boolean := False;
      Root_Child_Count_Dispatched : Boolean := False;
      Root_First_Child_Dispatched : Boolean := False;
      Root_Second_Child_Dispatched : Boolean := False;
      Fixture_Child_Query_Dispatched : Boolean := False;
      Fixture_Child_Role_Dispatched : Boolean := False;
      Fixture_Child_Parent_Dispatched : Boolean := False;
      Fixture_Child_Native_Identity_Dispatched : Boolean := False;
      Fixture_Second_Child_Parent_Dispatched : Boolean := False;
      Fixture_Second_Child_Native_Identity_Dispatched : Boolean := False;
      Fixture_Sibling_Order_Dispatched : Boolean := False;
      Registry_Object_Released : Boolean := False;
      Registry_Drained_Reset : Boolean := False;
      Registry_Node_Lookup_Rejected : Boolean := False;
      Registry_Stale_Id_Rejected : Boolean := False;
      Boundary_Status : A11y.Results.Status_Code := A11y.Results.Internal_Error;

      function Probe_Completed return Boolean is
        (Object_Path_Built
         and then Object_Registered
         and then Child_Object_Registered
         and then Second_Child_Object_Registered
         and then Native_Call_Completed
         and then Native_Call_Drained
         and then Root_Query_Dispatched
         and then Root_Child_Count_Dispatched
         and then Root_First_Child_Dispatched
         and then Root_Second_Child_Dispatched
         and then Fixture_Child_Query_Dispatched
         and then Fixture_Child_Role_Dispatched
         and then Fixture_Child_Parent_Dispatched
         and then Fixture_Child_Native_Identity_Dispatched
         and then Fixture_Second_Child_Parent_Dispatched
         and then Fixture_Second_Child_Native_Identity_Dispatched
         and then Fixture_Sibling_Order_Dispatched
         and then Registry_Object_Released
         and then Registry_Drained_Reset
         and then Registry_Node_Lookup_Rejected
         and then Registry_Stale_Id_Rejected
         and then Boundary_Status = A11y.Results.Success);

      function Failure_Stage return String is
      begin
         if not Object_Path_Built then
            return "object_path";
         elsif not Object_Registered then
            return "object_registry";
         elsif not Child_Object_Registered then
            return "fixture_child_registry";
         elsif not Second_Child_Object_Registered then
            return "fixture_second_child_registry";
         elsif not Root_Query_Dispatched then
            return "fixture_root_query";
         elsif not Root_Child_Count_Dispatched then
            return "fixture_root_child_count";
         elsif not Root_First_Child_Dispatched then
            return "fixture_root_first_child";
         elsif not Root_Second_Child_Dispatched then
            return "fixture_root_second_child";
         elsif not Fixture_Child_Query_Dispatched then
            return "fixture_child_query";
         elsif not Fixture_Child_Role_Dispatched then
            return "fixture_child_role";
         elsif not Fixture_Child_Parent_Dispatched then
            return "fixture_child_parent";
         elsif not Fixture_Child_Native_Identity_Dispatched then
            return "fixture_child_native_identity";
         elsif not Fixture_Second_Child_Parent_Dispatched then
            return "fixture_second_child_parent";
         elsif not Fixture_Second_Child_Native_Identity_Dispatched then
            return "fixture_second_child_native_identity";
         elsif not Fixture_Sibling_Order_Dispatched then
            return "fixture_sibling_order";
         elsif not Native_Call_Completed then
            return "native_call_completion";
         elsif not Native_Call_Drained then
            return "native_call_drain";
         elsif not Registry_Object_Released then
            return "registry_release";
         elsif not Registry_Drained_Reset then
            return "registry_reset";
         elsif not Registry_Node_Lookup_Rejected then
            return "reset_node_rejection";
         elsif not Registry_Stale_Id_Rejected then
            return "reset_stale_id_rejection";
         elsif Boundary_Status /= A11y.Results.Success then
            return "boundary_status";
         else
            return "none";
         end if;
      end Failure_Stage;
   begin
      Session := A11y.Native_Identity.Create_Session;
      Call.Session := Session;
      Call.Object_Path :=
        A11y.Linux.ATSPi_Objects.Object_Path (Session, Root, Result);
      Object_Path_Built := A11y.Results.Succeeded (Result);
      Call.Interface_Name := To_Unbounded_String
        (A11y.Linux.ATSPi_Objects.Interface_Name
           (A11y.Linux.ATSPi_Objects.Accessible));
      Call.Method_Name := To_Unbounded_String ("GetName");

      if Object_Path_Built then
         A11y.Linux.ATSPi_Object_Registry.Ensure_Object
           (Registry.all, Session, Root, Registered, Result);
         Object_Registered :=
           A11y.Results.Succeeded (Result)
           and then Registered.Node = Root
           and then Length (Registered.Path) /= 0;
         if Object_Registered then
            A11y.Linux.ATSPi_Object_Registry.Ensure_Object
              (Registry.all,
               Session,
               A11y_Test_Fixtures.Main_Window_Id,
               Child_Registered,
               Result);
            Child_Object_Registered :=
              A11y.Results.Succeeded (Result)
              and then Child_Registered.Node = A11y_Test_Fixtures.Main_Window_Id
              and then Length (Child_Registered.Path) /= 0;
            if Child_Object_Registered then
               A11y.Linux.ATSPi_Object_Registry.Ensure_Object
                 (Registry.all,
                  Session,
                  A11y_Test_Fixtures.Dialog_Id,
                  Second_Child_Registered,
                  Result);
               Second_Child_Object_Registered :=
                 A11y.Results.Succeeded (Result)
                 and then Second_Child_Registered.Node =
                   A11y_Test_Fixtures.Dialog_Id
                 and then Length (Second_Child_Registered.Path) /= 0;
            end if;
         end if;
      end if;

      if Object_Registered
        and then Child_Object_Registered
        and then Second_Child_Object_Registered
      then
         Snapshots.all.Accessible.Id := Root;
         Snapshots.all.Accessible.Role := A11y.Roles.Application;
         Snapshots.all.Accessible.Name :=
           To_Unbounded_String ("Fixture Application");
         Snapshots.all.Accessible.Children.Clear;
         Snapshots.all.Accessible.Children.Append
           (A11y_Test_Fixtures.Main_Window_Id);
         Snapshots.all.Accessible.Children.Append (A11y_Test_Fixtures.Dialog_Id);
         Snapshots.all.Accessible.Child_Count := 2;
         Snapshots.all.Application.Id := Root;
         Snapshots.all.Application.Application_Id :=
           A11y.Node_Ids.To_Natural (Root);
         Snapshots.all.Application.Toolkit_Name :=
           To_Unbounded_String ("a11y_tests");
         Snapshots.all.Application.Version :=
           To_Unbounded_String ("0.1.0-dev");

         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Registry_View :=
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Registry.all);
         Boundary_Status := Reply.Status;
         Root_Query_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_String
           and then Boundary_Status = A11y.Results.Success
           and then To_String (Reply.Text) = "Fixture Application";

         Call.Method_Name := To_Unbounded_String ("GetChildCount");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Root_Child_Count_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_UInt32
           and then Reply.Status = A11y.Results.Success
           and then Reply.UInt32 = 2;

         Call.Method_Name := To_Unbounded_String ("GetChildAtIndex");
         Call.Index := 0;
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Root_First_Child_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Node
           and then Reply.Status = A11y.Results.Success
           and then Reply.Node = A11y_Test_Fixtures.Main_Window_Id;

         Call.Index := 1;
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Root_Second_Child_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Node
           and then Reply.Status = A11y.Results.Success
           and then Reply.Node = A11y_Test_Fixtures.Dialog_Id;

         Snapshots.all.Accessible.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.all.Accessible.Role := A11y.Roles.Window;
         Snapshots.all.Accessible.Name := To_Unbounded_String ("Main Window");
         Snapshots.all.Accessible.Parent := Root;
         Snapshots.all.Accessible.Index_In_Parent := 0;
         Snapshots.all.Accessible.Children.Clear;
         Snapshots.all.Accessible.Child_Count := 0;
         Call.Object_Path := Child_Registered.Path;
         Call.Index := 0;
         Call.Method_Name := To_Unbounded_String ("GetName");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Fixture_Child_Query_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_String
           and then Reply.Status = A11y.Results.Success
           and then To_String (Reply.Text) = "Main Window";

         Call.Method_Name := To_Unbounded_String ("GetRole");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Fixture_Child_Role_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Role
           and then Reply.Status = A11y.Results.Success
           and then Reply.UInt32 =
             A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
               (A11y.Linux.ATSPi_Mappings.Window);
         Call.Method_Name := To_Unbounded_String ("GetParent");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Fixture_Child_Parent_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Node
           and then Reply.Status = A11y.Results.Success
           and then Reply.Node = Root;

         declare
            Decoded_Node : constant A11y.Node_Ids.Node_Id :=
              A11y.Linux.ATSPi_Objects.Node_From_Object_Path
                (To_String (Child_Registered.Path), Session, Result);
         begin
            Fixture_Child_Native_Identity_Dispatched :=
              A11y.Results.Succeeded (Result)
              and then Decoded_Node = A11y_Test_Fixtures.Main_Window_Id;
         end;

         Snapshots.all.Accessible.Id := A11y_Test_Fixtures.Dialog_Id;
         Snapshots.all.Accessible.Role := A11y.Roles.Dialog;
         Snapshots.all.Accessible.Name := To_Unbounded_String ("Dialog");
         Snapshots.all.Accessible.Parent := Root;
         Snapshots.all.Accessible.Index_In_Parent := 1;
         Snapshots.all.Accessible.Children.Clear;
         Snapshots.all.Accessible.Child_Count := 0;
         Call.Object_Path := Second_Child_Registered.Path;
         Call.Method_Name := To_Unbounded_String ("GetParent");
         Reply :=
           A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
             (Registry.all, Call, Snapshots.all);
         Fixture_Second_Child_Parent_Dispatched :=
           Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
           and then Reply.Routed_Kind =
             A11y.Linux.ATSPi_Method_Router.Accessible_Node
           and then Reply.Status = A11y.Results.Success
           and then Reply.Node = Root;

         declare
            Decoded_Node : constant A11y.Node_Ids.Node_Id :=
              A11y.Linux.ATSPi_Objects.Node_From_Object_Path
                (To_String (Second_Child_Registered.Path), Session, Result);
         begin
            Fixture_Second_Child_Native_Identity_Dispatched :=
              A11y.Results.Succeeded (Result)
              and then Decoded_Node = A11y_Test_Fixtures.Dialog_Id;
         end;

         declare
            First_Index : Integer := -1;
            Second_Index : Integer := -1;
         begin
            Snapshots.all.Accessible.Id := A11y_Test_Fixtures.Main_Window_Id;
            Snapshots.all.Accessible.Role := A11y.Roles.Window;
            Snapshots.all.Accessible.Name :=
              To_Unbounded_String ("Main Window");
            Snapshots.all.Accessible.Parent := Root;
            Snapshots.all.Accessible.Index_In_Parent := 0;
            Snapshots.all.Accessible.Children.Clear;
            Snapshots.all.Accessible.Child_Count := 0;
            Call.Object_Path := Child_Registered.Path;
            Call.Method_Name := To_Unbounded_String ("GetIndexInParent");
            Reply :=
              A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
                (Registry.all, Call, Snapshots.all);
            if Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_Int32
              and then Reply.Status = A11y.Results.Success
            then
               First_Index := Reply.Int32;
            end if;

            Snapshots.all.Accessible.Id := A11y_Test_Fixtures.Dialog_Id;
            Snapshots.all.Accessible.Role := A11y.Roles.Dialog;
            Snapshots.all.Accessible.Name := To_Unbounded_String ("Dialog");
            Snapshots.all.Accessible.Parent := Root;
            Snapshots.all.Accessible.Index_In_Parent := 1;
            Snapshots.all.Accessible.Children.Clear;
            Snapshots.all.Accessible.Child_Count := 0;
            Call.Object_Path := Second_Child_Registered.Path;
            Reply :=
              A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
                (Registry.all, Call, Snapshots.all);
            if Reply.Kind = A11y.Linux.ATSPi_DBus_Boundary.Method_Reply
              and then Reply.Routed_Kind =
                A11y.Linux.ATSPi_Method_Router.Accessible_Int32
              and then Reply.Status = A11y.Results.Success
            then
               Second_Index := Reply.Int32;
            end if;

            Fixture_Sibling_Order_Dispatched :=
              First_Index = 0 and then Second_Index = 1;
         end;
         Registry_View :=
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Registry.all);
         Native_Call_Drained := Registry_View.Outstanding_Calls = 0;
         Native_Call_Completed :=
           Root_Query_Dispatched
           and then Root_Child_Count_Dispatched
           and then Root_First_Child_Dispatched
           and then Root_Second_Child_Dispatched
           and then Fixture_Child_Query_Dispatched
           and then Fixture_Child_Role_Dispatched
           and then Fixture_Child_Parent_Dispatched
           and then Fixture_Child_Native_Identity_Dispatched
           and then Fixture_Second_Child_Parent_Dispatched
           and then Fixture_Second_Child_Native_Identity_Dispatched
           and then Fixture_Sibling_Order_Dispatched
           and then Native_Call_Drained;
      end if;

      if Native_Call_Completed then
         A11y.Linux.ATSPi_Object_Registry.Release
           (Registry.all, Session, Child_Registered.Object, Result);
         if A11y.Results.Succeeded (Result) then
            A11y.Linux.ATSPi_Object_Registry.Release
              (Registry.all, Session, Second_Child_Registered.Object, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            A11y.Linux.ATSPi_Object_Registry.Release
              (Registry.all, Session, Registered.Object, Result);
            Registry_Object_Released := A11y.Results.Succeeded (Result);
         end if;
      end if;

      if Registry_Object_Released then
         A11y.Linux.ATSPi_Object_Registry.Reset_When_Drained_With_Report
           (Registry.all, Registry_Report, Result);
         Registry_Drained_Reset :=
           A11y.Results.Succeeded (Result)
           and then Registry_Report.Status = A11y.Results.Success;
      end if;

      if Registry_Drained_Reset then
         A11y.Linux.ATSPi_Object_Registry.Find_Object
           (Registry.all, Session, Root, Registry_Record_View, Result);
         Registry_Node_Lookup_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_Record_View.Object =
             A11y.Native_Object_Caches.No_Object;

         A11y.Linux.ATSPi_Object_Registry.Resolve_Path
           (Registry.all,
            Session,
            To_String (Registered.Path),
            Registry_Record_View,
            Result);
         Registry_Stale_Id_Rejected :=
           Result.Status = A11y.Results.Node_Unavailable
           and then Registry_Record_View.Object =
             A11y.Native_Object_Caches.No_Object;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_fixture_root.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_schema"": " & Q (A11y_Fixture_Application.Schema) & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Linux_ATSPI))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line
        ("  ""application_node"": " & Q (A11y.Node_Ids.Image (Root)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_object_path_built"": "
         & (if Object_Path_Built then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_object_registered"": "
         & (if Object_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_object_registered"": "
         & (if Child_Object_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_second_child_object_registered"": "
         & (if Second_Child_Object_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_completed"": "
         & (if Native_Call_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""native_call_drained"": "
         & (if Native_Call_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_query_dispatched"": "
         & (if Root_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_child_count_dispatched"": "
         & (if Root_Child_Count_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_first_child_dispatched"": "
         & (if Root_First_Child_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_root_second_child_dispatched"": "
         & (if Root_Second_Child_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_query_dispatched"": "
         & (if Fixture_Child_Query_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_role_dispatched"": "
         & (if Fixture_Child_Role_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_parent_dispatched"": "
         & (if Fixture_Child_Parent_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_child_native_identity_dispatched"": "
         & (if Fixture_Child_Native_Identity_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_second_child_parent_dispatched"": "
         & (if Fixture_Second_Child_Parent_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_second_child_native_identity_dispatched"": "
         & (if Fixture_Second_Child_Native_Identity_Dispatched
            then "true"
            else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_sibling_order_dispatched"": "
         & (if Fixture_Sibling_Order_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_object_released"": "
         & (if Registry_Object_Released then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_drained_reset"": "
         & (if Registry_Drained_Reset then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_node_lookup_rejected_after_reset"": "
         & (if Registry_Node_Lookup_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_stale_id_rejected_after_reset"": "
         & (if Registry_Stale_Id_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""probe_status"": "
         & Q (if Probe_Completed then "success" else "incomplete")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""failure_stage"": " & Q (Failure_Stage) & ",");
      Ada.Text_IO.Put_Line
        ("  ""boundary_status"": " & Q (Status_Name (Boundary_Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_fixture_root.v1")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""fixture_schema"": " & Q (A11y_Fixture_Application.Schema) & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line ("  ""application_node"": ""1001"",");
         Ada.Text_IO.Put_Line ("  ""native_object_path_built"": false,");
         Ada.Text_IO.Put_Line ("  ""native_object_registered"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_object_registered"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_second_child_object_registered"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""native_call_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_query_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_child_count_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_first_child_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_root_second_child_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_query_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_role_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_parent_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_child_native_identity_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_second_child_parent_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_second_child_native_identity_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""fixture_sibling_order_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_object_released"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_drained_reset"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_node_lookup_rejected_after_reset"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registry_stale_id_rejected_after_reset"": false,");
         Ada.Text_IO.Put_Line ("  ""probe_status"": ""failed"",");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception"",");
         Ada.Text_IO.Put_Line ("  ""boundary_status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Fixture_Root_Probe;

   procedure Emit_Serving_Packet_Probe is
      type Context_Access is access all
        A11y.Linux.ATSPi_Bus.Connection_Context;
      type Registry_Access is access all
        A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      type Snapshot_Access is access all
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;

      Context : constant Context_Access :=
        new A11y.Linux.ATSPi_Bus.Connection_Context;
      Registry : constant Registry_Access :=
        new A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Snapshots : constant Snapshot_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Registered :
        A11y.Linux.ATSPi_Object_Registry.Object_Record_Snapshot;
      Registry_View :
        A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;
      Application_Node : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Application_Id;
      Child_Node : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Main_Window_Id;
      Second_Child_Node : constant A11y.Node_Ids.Node_Id :=
        A11y_Test_Fixtures.Dialog_Id;
      Table_Cell_Node : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (771);
      Object_Path : Unbounded_String := Null_Unbounded_String;
      Child_Object_Path : Unbounded_String := Null_Unbounded_String;
      Second_Child_Object_Path : Unbounded_String := Null_Unbounded_String;
      Table_Cell_Object_Path : Unbounded_String := Null_Unbounded_String;
      Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Request_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Reply_Text : Unbounded_String := Null_Unbounded_String;
      Application_Id_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Application_Id_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Application_Id_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Application_Id_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Application_Id_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Application_Id_Value : Natural := 0;
      Property_Name_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Property_Name_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Property_Name_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Property_Name_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Property_Name_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Property_Map_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Property_Map_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Property_Map_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Property_Map_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Property_Map_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Role_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Role_Request_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Role_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Role_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Role_Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Role_Value : Natural := 0;
      State_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      State_Request_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      State_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      State_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      State_Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      State_Values : A11y.Linux.DBus_Codec.UInt32_Vectors.Vector;
      Interfaces_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Interfaces_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Interfaces_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Interfaces_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Interfaces_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Interface_Names : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Action_Count_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Action_Count_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Action_Count_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Action_Count_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Action_Count_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Action_Count_Value : Natural := 0;
      Action_Name_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Action_Name_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Action_Name_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Action_Name_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Action_Name_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Action_Name_Text : Unbounded_String := Null_Unbounded_String;
      Action_Invoke_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Action_Invoke_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Action_Invoke_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Action_Invoke_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Action_Invoke_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Action_Invoke_Value : Boolean := False;
      Component_Extents_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Component_Extents_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Extents_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Extents_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Extents_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Extents_Value : A11y.Geometry.Rectangle :=
        A11y.Geometry.Empty_Rectangle;
      Component_Contains_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Component_Contains_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Contains_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Contains_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Contains_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Contains_Value : Boolean := False;
      Component_Hit_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Component_Hit_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Hit_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Hit_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Hit_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Hit_Path : Unbounded_String := Null_Unbounded_String;
      Component_Focus_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Component_Focus_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Focus_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Focus_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Component_Focus_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Component_Focus_Value : Boolean := False;
      Value_Current_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Value_Current_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Current_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Current_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Current_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Current_Float : Long_Float := 0.0;
      Value_Minimum_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Value_Minimum_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Minimum_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Minimum_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Minimum_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Minimum_Float : Long_Float := 0.0;
      Value_Maximum_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Value_Maximum_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Maximum_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Maximum_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Maximum_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Maximum_Float : Long_Float := 0.0;
      Value_Increment_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Value_Increment_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Increment_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Increment_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Increment_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Increment_Float : Long_Float := 0.0;
      Value_Set_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Value_Set_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Set_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Set_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Value_Set_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Value_Set_Boolean : Boolean := False;
      Selection_Count_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Count_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Count_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Count_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Count_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Count_Value : Natural := 0;
      Selection_Selected_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Selected_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Selected_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Selected_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Selected_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Selected_Path : Unbounded_String := Null_Unbounded_String;
      Selection_Is_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Is_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Is_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Is_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Is_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Is_Value : Boolean := False;
      Selection_Select_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Select_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Select_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Select_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Select_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Select_Value : Boolean := False;
      Selection_Deselect_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Deselect_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Deselect_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Deselect_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Deselect_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Deselect_Value : Boolean := False;
      Selection_Select_All_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Select_All_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Select_All_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Select_All_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Select_All_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Select_All_Value : Boolean := False;
      Selection_Clear_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Selection_Clear_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Clear_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Clear_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Selection_Clear_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Selection_Clear_Value : Boolean := False;
      Text_Count_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Count_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Count_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Count_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Count_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Count_Value : Natural := 0;
      Text_Caret_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Caret_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Caret_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Caret_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Caret_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Caret_Value : Natural := 0;
      Text_Range_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Range_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Range_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Range_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Range_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Range_Value : Unbounded_String := Null_Unbounded_String;
      Text_Edit_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Edit_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Edit_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Edit_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Edit_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Edit_Value : Boolean := False;
      Text_Delete_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Delete_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Delete_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Delete_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Delete_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Delete_Value : Boolean := False;
      Text_Replace_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Replace_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Replace_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Replace_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Replace_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Replace_Value : Boolean := False;
      Text_Set_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Text_Set_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Set_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Set_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Text_Set_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Text_Set_Value : Boolean := False;
      Image_Description_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Image_Description_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Description_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Description_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Description_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Description_Value : Unbounded_String := Null_Unbounded_String;
      Image_Caption_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Image_Caption_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Caption_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Caption_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Caption_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Caption_Value : Unbounded_String := Null_Unbounded_String;
      Image_Kind_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Image_Kind_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Kind_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Kind_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Kind_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Kind_Value : Unbounded_String := Null_Unbounded_String;
      Image_Size_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Image_Size_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Size_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Size_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Image_Size_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Image_Size_Value : A11y.Geometry.Size := (Width => 0, Height => 0);
      Table_Row_Count_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Row_Count_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Row_Count_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Row_Count_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Row_Count_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Row_Count_Value : Natural := 0;
      Table_Column_Count_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Column_Count_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Column_Count_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Column_Count_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Column_Count_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Column_Count_Value : Natural := 0;
      Table_Cell_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Cell_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Cell_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Cell_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Cell_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Cell_Path : Unbounded_String := Null_Unbounded_String;
      Table_Row_Extent_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Row_Extent_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Row_Extent_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Row_Extent_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Row_Extent_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Row_Extent_Value : Natural := 0;
      Table_Column_Extent_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Column_Extent_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Column_Extent_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Column_Extent_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Column_Extent_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Column_Extent_Value : Natural := 0;
      Table_Current_Cell_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Current_Cell_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Current_Cell_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Current_Cell_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Current_Cell_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Current_Cell_Path : Unbounded_String := Null_Unbounded_String;
      Table_Sort_Order_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Sort_Order_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Sort_Order_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Sort_Order_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Sort_Order_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Sort_Order_Value : Natural := 0;
      Table_Sort_Key_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Table_Sort_Key_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Sort_Key_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Sort_Key_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Table_Sort_Key_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Table_Sort_Key_Path : Unbounded_String := Null_Unbounded_String;
      Document_Locale_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Document_Locale_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Document_Locale_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Document_Locale_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Document_Locale_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Document_Locale_Value : Unbounded_String := Null_Unbounded_String;
      Document_Landmark_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Document_Landmark_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Document_Landmark_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Document_Landmark_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Document_Landmark_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Document_Landmark_Value : Boolean := False;
      Document_Title_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Document_Title_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Document_Title_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Document_Title_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Document_Title_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Document_Title_Value : Unbounded_String := Null_Unbounded_String;
      Child_Count_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Child_Count_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Child_Count_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Child_Count_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Child_Count_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Child_Count_Value : Natural := 0;
      Child_At_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Child_At_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Child_At_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Child_At_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Child_At_Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Child_At_Path : Unbounded_String := Null_Unbounded_String;
      Children_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Children_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Children_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Children_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Children_Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Children_Paths : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Attributes_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Attributes_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Attributes_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Attributes_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Attributes_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Attribute_Items :
        A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
      Relations_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Relations_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Relations_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Relations_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Relations_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Relation_Items :
        A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
      Parent_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Parent_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Parent_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Parent_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Parent_Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Parent_Path : Unbounded_String := Null_Unbounded_String;
      Index_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Index_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Index_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Index_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Index_Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Index_Value : Integer := -1;
      Stale_Object_Path : Unbounded_String := Null_Unbounded_String;
      Stale_Request_Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Stale_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Stale_Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Stale_Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Stale_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Stale_Serve_Report :
        A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
      Unsupported_Interface_Request_Message :
        A11y.Linux.DBus_Messages.Outgoing_Message;
      Unsupported_Interface_Request_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Unsupported_Interface_Request_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Unsupported_Interface_Reply_Packet :
        A11y.Linux.DBus_Messages.Transport_Packet;
      Unsupported_Interface_Reply_Envelope :
        A11y.Linux.DBus_Messages.Transport_Envelope;
      Unsupported_Interface_Serve_Report :
        A11y.Linux.ATSPi_Bus.Registered_Packet_Serve_Report;
      Result : A11y.Results.Result;
      Final_Status : A11y.Results.Status_Code := A11y.Results.Internal_Error;
      Context_Prepared : Boolean := False;
      Context_Admitted : Boolean := False;
      Context_Registered : Boolean := False;
      Object_Path_Built : Boolean := False;
      Object_Registered : Boolean := False;
      Method_Call_Encoded : Boolean := False;
      Packet_Dispatched : Boolean := False;
      Registry_Drained : Boolean := False;
      Reply_Queued : Boolean := False;
      Reply_Serialized : Boolean := False;
      Reply_In_Flight : Boolean := False;
      Reply_Decoded : Boolean := False;
      Reply_Bookkeeping_Drained : Boolean := False;
      Application_Id_Method_Call_Encoded : Boolean := False;
      Application_Id_Packet_Dispatched : Boolean := False;
      Application_Id_Reply_Queued : Boolean := False;
      Application_Id_Reply_Serialized : Boolean := False;
      Application_Id_Reply_Decoded : Boolean := False;
      Application_Id_Reply_Bookkeeping_Drained : Boolean := False;
      Property_Name_Method_Call_Encoded : Boolean := False;
      Property_Name_Packet_Dispatched : Boolean := False;
      Property_Name_Reply_Queued : Boolean := False;
      Property_Name_Reply_Serialized : Boolean := False;
      Property_Name_Reply_Decoded : Boolean := False;
      Property_Name_Reply_Bookkeeping_Drained : Boolean := False;
      Property_Map_Method_Call_Encoded : Boolean := False;
      Property_Map_Packet_Dispatched : Boolean := False;
      Property_Map_Reply_Queued : Boolean := False;
      Property_Map_Reply_Serialized : Boolean := False;
      Property_Map_Reply_Decoded : Boolean := False;
      Property_Map_Reply_Bookkeeping_Drained : Boolean := False;
      Role_Method_Call_Encoded : Boolean := False;
      Role_Packet_Dispatched : Boolean := False;
      Role_Reply_Queued : Boolean := False;
      Role_Reply_Serialized : Boolean := False;
      Role_Reply_Decoded : Boolean := False;
      Role_Reply_Bookkeeping_Drained : Boolean := False;
      State_Method_Call_Encoded : Boolean := False;
      State_Packet_Dispatched : Boolean := False;
      State_Reply_Queued : Boolean := False;
      State_Reply_Serialized : Boolean := False;
      State_Reply_Decoded : Boolean := False;
      State_Reply_Bookkeeping_Drained : Boolean := False;
      Interfaces_Method_Call_Encoded : Boolean := False;
      Interfaces_Packet_Dispatched : Boolean := False;
      Interfaces_Reply_Queued : Boolean := False;
      Interfaces_Reply_Serialized : Boolean := False;
      Interfaces_Reply_Decoded : Boolean := False;
      Interfaces_Reply_Bookkeeping_Drained : Boolean := False;
      Action_Count_Method_Call_Encoded : Boolean := False;
      Action_Count_Packet_Dispatched : Boolean := False;
      Action_Count_Reply_Queued : Boolean := False;
      Action_Count_Reply_Serialized : Boolean := False;
      Action_Count_Reply_Decoded : Boolean := False;
      Action_Count_Reply_Bookkeeping_Drained : Boolean := False;
      Action_Name_Method_Call_Encoded : Boolean := False;
      Action_Name_Packet_Dispatched : Boolean := False;
      Action_Name_Reply_Queued : Boolean := False;
      Action_Name_Reply_Serialized : Boolean := False;
      Action_Name_Reply_Decoded : Boolean := False;
      Action_Name_Reply_Bookkeeping_Drained : Boolean := False;
      Action_Invoke_Method_Call_Encoded : Boolean := False;
      Action_Invoke_Packet_Dispatched : Boolean := False;
      Action_Invoke_Reply_Queued : Boolean := False;
      Action_Invoke_Reply_Serialized : Boolean := False;
      Action_Invoke_Reply_Decoded : Boolean := False;
      Action_Invoke_Reply_Bookkeeping_Drained : Boolean := False;
      Component_Extents_Method_Call_Encoded : Boolean := False;
      Component_Extents_Packet_Dispatched : Boolean := False;
      Component_Extents_Reply_Queued : Boolean := False;
      Component_Extents_Reply_Serialized : Boolean := False;
      Component_Extents_Reply_Decoded : Boolean := False;
      Component_Extents_Reply_Bookkeeping_Drained : Boolean := False;
      Component_Contains_Method_Call_Encoded : Boolean := False;
      Component_Contains_Packet_Dispatched : Boolean := False;
      Component_Contains_Reply_Queued : Boolean := False;
      Component_Contains_Reply_Serialized : Boolean := False;
      Component_Contains_Reply_Decoded : Boolean := False;
      Component_Contains_Reply_Bookkeeping_Drained : Boolean := False;
      Component_Hit_Method_Call_Encoded : Boolean := False;
      Component_Hit_Packet_Dispatched : Boolean := False;
      Component_Hit_Reply_Queued : Boolean := False;
      Component_Hit_Reply_Serialized : Boolean := False;
      Component_Hit_Reply_Decoded : Boolean := False;
      Component_Hit_Reply_Bookkeeping_Drained : Boolean := False;
      Component_Focus_Method_Call_Encoded : Boolean := False;
      Component_Focus_Packet_Dispatched : Boolean := False;
      Component_Focus_Reply_Queued : Boolean := False;
      Component_Focus_Reply_Serialized : Boolean := False;
      Component_Focus_Reply_Decoded : Boolean := False;
      Component_Focus_Reply_Bookkeeping_Drained : Boolean := False;
      Value_Current_Method_Call_Encoded : Boolean := False;
      Value_Current_Packet_Dispatched : Boolean := False;
      Value_Current_Reply_Queued : Boolean := False;
      Value_Current_Reply_Serialized : Boolean := False;
      Value_Current_Reply_Decoded : Boolean := False;
      Value_Current_Reply_Bookkeeping_Drained : Boolean := False;
      Value_Minimum_Method_Call_Encoded : Boolean := False;
      Value_Minimum_Packet_Dispatched : Boolean := False;
      Value_Minimum_Reply_Queued : Boolean := False;
      Value_Minimum_Reply_Serialized : Boolean := False;
      Value_Minimum_Reply_Decoded : Boolean := False;
      Value_Minimum_Reply_Bookkeeping_Drained : Boolean := False;
      Value_Maximum_Method_Call_Encoded : Boolean := False;
      Value_Maximum_Packet_Dispatched : Boolean := False;
      Value_Maximum_Reply_Queued : Boolean := False;
      Value_Maximum_Reply_Serialized : Boolean := False;
      Value_Maximum_Reply_Decoded : Boolean := False;
      Value_Maximum_Reply_Bookkeeping_Drained : Boolean := False;
      Value_Increment_Method_Call_Encoded : Boolean := False;
      Value_Increment_Packet_Dispatched : Boolean := False;
      Value_Increment_Reply_Queued : Boolean := False;
      Value_Increment_Reply_Serialized : Boolean := False;
      Value_Increment_Reply_Decoded : Boolean := False;
      Value_Increment_Reply_Bookkeeping_Drained : Boolean := False;
      Value_Set_Method_Call_Encoded : Boolean := False;
      Value_Set_Packet_Dispatched : Boolean := False;
      Value_Set_Reply_Queued : Boolean := False;
      Value_Set_Reply_Serialized : Boolean := False;
      Value_Set_Reply_Decoded : Boolean := False;
      Value_Set_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Count_Method_Call_Encoded : Boolean := False;
      Selection_Count_Packet_Dispatched : Boolean := False;
      Selection_Count_Reply_Queued : Boolean := False;
      Selection_Count_Reply_Serialized : Boolean := False;
      Selection_Count_Reply_Decoded : Boolean := False;
      Selection_Count_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Selected_Method_Call_Encoded : Boolean := False;
      Selection_Selected_Packet_Dispatched : Boolean := False;
      Selection_Selected_Reply_Queued : Boolean := False;
      Selection_Selected_Reply_Serialized : Boolean := False;
      Selection_Selected_Reply_Decoded : Boolean := False;
      Selection_Selected_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Is_Method_Call_Encoded : Boolean := False;
      Selection_Is_Packet_Dispatched : Boolean := False;
      Selection_Is_Reply_Queued : Boolean := False;
      Selection_Is_Reply_Serialized : Boolean := False;
      Selection_Is_Reply_Decoded : Boolean := False;
      Selection_Is_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Select_Method_Call_Encoded : Boolean := False;
      Selection_Select_Packet_Dispatched : Boolean := False;
      Selection_Select_Reply_Queued : Boolean := False;
      Selection_Select_Reply_Serialized : Boolean := False;
      Selection_Select_Reply_Decoded : Boolean := False;
      Selection_Select_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Deselect_Method_Call_Encoded : Boolean := False;
      Selection_Deselect_Packet_Dispatched : Boolean := False;
      Selection_Deselect_Reply_Queued : Boolean := False;
      Selection_Deselect_Reply_Serialized : Boolean := False;
      Selection_Deselect_Reply_Decoded : Boolean := False;
      Selection_Deselect_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Select_All_Method_Call_Encoded : Boolean := False;
      Selection_Select_All_Packet_Dispatched : Boolean := False;
      Selection_Select_All_Reply_Queued : Boolean := False;
      Selection_Select_All_Reply_Serialized : Boolean := False;
      Selection_Select_All_Reply_Decoded : Boolean := False;
      Selection_Select_All_Reply_Bookkeeping_Drained : Boolean := False;
      Selection_Clear_Method_Call_Encoded : Boolean := False;
      Selection_Clear_Packet_Dispatched : Boolean := False;
      Selection_Clear_Reply_Queued : Boolean := False;
      Selection_Clear_Reply_Serialized : Boolean := False;
      Selection_Clear_Reply_Decoded : Boolean := False;
      Selection_Clear_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Count_Method_Call_Encoded : Boolean := False;
      Text_Count_Packet_Dispatched : Boolean := False;
      Text_Count_Reply_Queued : Boolean := False;
      Text_Count_Reply_Serialized : Boolean := False;
      Text_Count_Reply_Decoded : Boolean := False;
      Text_Count_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Caret_Method_Call_Encoded : Boolean := False;
      Text_Caret_Packet_Dispatched : Boolean := False;
      Text_Caret_Reply_Queued : Boolean := False;
      Text_Caret_Reply_Serialized : Boolean := False;
      Text_Caret_Reply_Decoded : Boolean := False;
      Text_Caret_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Range_Method_Call_Encoded : Boolean := False;
      Text_Range_Packet_Dispatched : Boolean := False;
      Text_Range_Reply_Queued : Boolean := False;
      Text_Range_Reply_Serialized : Boolean := False;
      Text_Range_Reply_Decoded : Boolean := False;
      Text_Range_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Edit_Method_Call_Encoded : Boolean := False;
      Text_Edit_Packet_Dispatched : Boolean := False;
      Text_Edit_Reply_Queued : Boolean := False;
      Text_Edit_Reply_Serialized : Boolean := False;
      Text_Edit_Reply_Decoded : Boolean := False;
      Text_Edit_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Delete_Method_Call_Encoded : Boolean := False;
      Text_Delete_Packet_Dispatched : Boolean := False;
      Text_Delete_Reply_Queued : Boolean := False;
      Text_Delete_Reply_Serialized : Boolean := False;
      Text_Delete_Reply_Decoded : Boolean := False;
      Text_Delete_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Replace_Method_Call_Encoded : Boolean := False;
      Text_Replace_Packet_Dispatched : Boolean := False;
      Text_Replace_Reply_Queued : Boolean := False;
      Text_Replace_Reply_Serialized : Boolean := False;
      Text_Replace_Reply_Decoded : Boolean := False;
      Text_Replace_Reply_Bookkeeping_Drained : Boolean := False;
      Text_Set_Method_Call_Encoded : Boolean := False;
      Text_Set_Packet_Dispatched : Boolean := False;
      Text_Set_Reply_Queued : Boolean := False;
      Text_Set_Reply_Serialized : Boolean := False;
      Text_Set_Reply_Decoded : Boolean := False;
      Text_Set_Reply_Bookkeeping_Drained : Boolean := False;
      Image_Description_Method_Call_Encoded : Boolean := False;
      Image_Description_Packet_Dispatched : Boolean := False;
      Image_Description_Reply_Queued : Boolean := False;
      Image_Description_Reply_Serialized : Boolean := False;
      Image_Description_Reply_Decoded : Boolean := False;
      Image_Description_Reply_Bookkeeping_Drained : Boolean := False;
      Image_Caption_Method_Call_Encoded : Boolean := False;
      Image_Caption_Packet_Dispatched : Boolean := False;
      Image_Caption_Reply_Queued : Boolean := False;
      Image_Caption_Reply_Serialized : Boolean := False;
      Image_Caption_Reply_Decoded : Boolean := False;
      Image_Caption_Reply_Bookkeeping_Drained : Boolean := False;
      Image_Kind_Method_Call_Encoded : Boolean := False;
      Image_Kind_Packet_Dispatched : Boolean := False;
      Image_Kind_Reply_Queued : Boolean := False;
      Image_Kind_Reply_Serialized : Boolean := False;
      Image_Kind_Reply_Decoded : Boolean := False;
      Image_Kind_Reply_Bookkeeping_Drained : Boolean := False;
      Image_Size_Method_Call_Encoded : Boolean := False;
      Image_Size_Packet_Dispatched : Boolean := False;
      Image_Size_Reply_Queued : Boolean := False;
      Image_Size_Reply_Serialized : Boolean := False;
      Image_Size_Reply_Decoded : Boolean := False;
      Image_Size_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Row_Count_Method_Call_Encoded : Boolean := False;
      Table_Row_Count_Packet_Dispatched : Boolean := False;
      Table_Row_Count_Reply_Queued : Boolean := False;
      Table_Row_Count_Reply_Serialized : Boolean := False;
      Table_Row_Count_Reply_Decoded : Boolean := False;
      Table_Row_Count_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Column_Count_Method_Call_Encoded : Boolean := False;
      Table_Column_Count_Packet_Dispatched : Boolean := False;
      Table_Column_Count_Reply_Queued : Boolean := False;
      Table_Column_Count_Reply_Serialized : Boolean := False;
      Table_Column_Count_Reply_Decoded : Boolean := False;
      Table_Column_Count_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Cell_Method_Call_Encoded : Boolean := False;
      Table_Cell_Packet_Dispatched : Boolean := False;
      Table_Cell_Reply_Queued : Boolean := False;
      Table_Cell_Reply_Serialized : Boolean := False;
      Table_Cell_Reply_Decoded : Boolean := False;
      Table_Cell_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Row_Extent_Method_Call_Encoded : Boolean := False;
      Table_Row_Extent_Packet_Dispatched : Boolean := False;
      Table_Row_Extent_Reply_Queued : Boolean := False;
      Table_Row_Extent_Reply_Serialized : Boolean := False;
      Table_Row_Extent_Reply_Decoded : Boolean := False;
      Table_Row_Extent_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Column_Extent_Method_Call_Encoded : Boolean := False;
      Table_Column_Extent_Packet_Dispatched : Boolean := False;
      Table_Column_Extent_Reply_Queued : Boolean := False;
      Table_Column_Extent_Reply_Serialized : Boolean := False;
      Table_Column_Extent_Reply_Decoded : Boolean := False;
      Table_Column_Extent_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Current_Cell_Method_Call_Encoded : Boolean := False;
      Table_Current_Cell_Packet_Dispatched : Boolean := False;
      Table_Current_Cell_Reply_Queued : Boolean := False;
      Table_Current_Cell_Reply_Serialized : Boolean := False;
      Table_Current_Cell_Reply_Decoded : Boolean := False;
      Table_Current_Cell_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Sort_Order_Method_Call_Encoded : Boolean := False;
      Table_Sort_Order_Packet_Dispatched : Boolean := False;
      Table_Sort_Order_Reply_Queued : Boolean := False;
      Table_Sort_Order_Reply_Serialized : Boolean := False;
      Table_Sort_Order_Reply_Decoded : Boolean := False;
      Table_Sort_Order_Reply_Bookkeeping_Drained : Boolean := False;
      Table_Sort_Key_Method_Call_Encoded : Boolean := False;
      Table_Sort_Key_Packet_Dispatched : Boolean := False;
      Table_Sort_Key_Reply_Queued : Boolean := False;
      Table_Sort_Key_Reply_Serialized : Boolean := False;
      Table_Sort_Key_Reply_Decoded : Boolean := False;
      Table_Sort_Key_Reply_Bookkeeping_Drained : Boolean := False;
      Document_Locale_Method_Call_Encoded : Boolean := False;
      Document_Locale_Packet_Dispatched : Boolean := False;
      Document_Locale_Reply_Queued : Boolean := False;
      Document_Locale_Reply_Serialized : Boolean := False;
      Document_Locale_Reply_Decoded : Boolean := False;
      Document_Locale_Reply_Bookkeeping_Drained : Boolean := False;
      Document_Landmark_Method_Call_Encoded : Boolean := False;
      Document_Landmark_Packet_Dispatched : Boolean := False;
      Document_Landmark_Reply_Queued : Boolean := False;
      Document_Landmark_Reply_Serialized : Boolean := False;
      Document_Landmark_Reply_Decoded : Boolean := False;
      Document_Landmark_Reply_Bookkeeping_Drained : Boolean := False;
      Document_Title_Method_Call_Encoded : Boolean := False;
      Document_Title_Packet_Dispatched : Boolean := False;
      Document_Title_Reply_Queued : Boolean := False;
      Document_Title_Reply_Serialized : Boolean := False;
      Document_Title_Reply_Decoded : Boolean := False;
      Document_Title_Reply_Bookkeeping_Drained : Boolean := False;
      Child_Count_Method_Call_Encoded : Boolean := False;
      Child_Count_Packet_Dispatched : Boolean := False;
      Child_Count_Reply_Queued : Boolean := False;
      Child_Count_Reply_Serialized : Boolean := False;
      Child_Count_Reply_Decoded : Boolean := False;
      Child_Count_Reply_Bookkeeping_Drained : Boolean := False;
      Child_At_Method_Call_Encoded : Boolean := False;
      Child_At_Packet_Dispatched : Boolean := False;
      Child_At_Reply_Queued : Boolean := False;
      Child_At_Reply_Serialized : Boolean := False;
      Child_At_Reply_Decoded : Boolean := False;
      Child_At_Reply_Bookkeeping_Drained : Boolean := False;
      Children_Method_Call_Encoded : Boolean := False;
      Children_Packet_Dispatched : Boolean := False;
      Children_Reply_Queued : Boolean := False;
      Children_Reply_Serialized : Boolean := False;
      Children_Reply_Decoded : Boolean := False;
      Children_Reply_Bookkeeping_Drained : Boolean := False;
      Attributes_Method_Call_Encoded : Boolean := False;
      Attributes_Packet_Dispatched : Boolean := False;
      Attributes_Reply_Queued : Boolean := False;
      Attributes_Reply_Serialized : Boolean := False;
      Attributes_Reply_Decoded : Boolean := False;
      Attributes_Reply_Bookkeeping_Drained : Boolean := False;
      Relations_Method_Call_Encoded : Boolean := False;
      Relations_Packet_Dispatched : Boolean := False;
      Relations_Reply_Queued : Boolean := False;
      Relations_Reply_Serialized : Boolean := False;
      Relations_Reply_Decoded : Boolean := False;
      Relations_Reply_Bookkeeping_Drained : Boolean := False;
      Parent_Method_Call_Encoded : Boolean := False;
      Parent_Packet_Dispatched : Boolean := False;
      Parent_Reply_Queued : Boolean := False;
      Parent_Reply_Serialized : Boolean := False;
      Parent_Reply_Decoded : Boolean := False;
      Parent_Reply_Bookkeeping_Drained : Boolean := False;
      Index_Method_Call_Encoded : Boolean := False;
      Index_Packet_Dispatched : Boolean := False;
      Index_Reply_Queued : Boolean := False;
      Index_Reply_Serialized : Boolean := False;
      Index_Reply_Decoded : Boolean := False;
      Index_Reply_Bookkeeping_Drained : Boolean := False;
      Accessible_Tree_Traversal_Completed : Boolean := False;
      Stale_Path_Built : Boolean := False;
      Stale_Method_Call_Encoded : Boolean := False;
      Stale_Packet_Dispatched : Boolean := False;
      Stale_Error_Queued : Boolean := False;
      Stale_Error_Serialized : Boolean := False;
      Stale_Error_In_Flight : Boolean := False;
      Stale_Error_Decoded : Boolean := False;
      Stale_Error_Bookkeeping_Drained : Boolean := False;
      Unsupported_Interface_Method_Call_Encoded : Boolean := False;
      Unsupported_Interface_Packet_Dispatched : Boolean := False;
      Unsupported_Interface_Error_Queued : Boolean := False;
      Unsupported_Interface_Error_Serialized : Boolean := False;
      Unsupported_Interface_Error_In_Flight : Boolean := False;
      Unsupported_Interface_Error_Decoded : Boolean := False;
      Unsupported_Interface_Error_Bookkeeping_Drained : Boolean := False;
      Malformed_Packet_Rejected : Boolean := False;
      Oversized_Text_Payload_Rejected : Boolean := False;
      Serving_Path_Completed : Boolean := False;

      function Contains_State
        (Items : A11y.Linux.DBus_Codec.UInt32_Vectors.Vector;
         State : A11y.Linux.ATSPi_Mappings.ATSPI_State)
         return Boolean
      is
         Expected : constant Natural :=
           A11y.Linux.ATSPi_Mappings.ATSPI_State'Pos (State);
      begin
         for Item of Items loop
            if Item = Expected then
               return True;
            end if;
         end loop;

         return False;
      end Contains_State;

      function Contains_Text
        (Items : A11y.Linux.DBus_Codec.String_Vectors.Vector;
         Text  : String)
         return Boolean
      is
      begin
         for Item of Items loop
            if To_String (Item) = Text then
               return True;
            end if;
         end loop;

         return False;
      end Contains_Text;

      function Has_Attribute
        (Items : A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
         Key   : String;
         Value : String)
         return Boolean
      is
      begin
         for Item of Items loop
            if To_String (Item.Key) = Key
              and then To_String (Item.Value) = Value
            then
               return True;
            end if;
         end loop;

         return False;
      end Has_Attribute;
   begin
      A11y.Linux.ATSPi_Bus.Prepare_Connection
        (Context.all, "unix:path=/tmp/a11y-serving-packet-probe", Result);
      Context_Prepared := A11y.Results.Succeeded (Result);

      if Context_Prepared then
         A11y.Linux.ATSPi_Bus.Mark_Transport_Connected
           (Context.all, Result);
         Context_Admitted := A11y.Results.Succeeded (Result);
      end if;

      if Context_Admitted then
         A11y.Linux.ATSPi_Bus.Register_Application (Context.all, Result);
         Context_Registered := A11y.Results.Succeeded (Result);
      end if;

      if Context_Registered then
         Object_Path := A11y.Linux.ATSPi_Objects.Object_Path
           (Context.all.Session, Application_Node, Result);
         Object_Path_Built := A11y.Results.Succeeded (Result);
         if Object_Path_Built then
            Child_Object_Path := A11y.Linux.ATSPi_Objects.Object_Path
              (Context.all.Session, Child_Node, Result);
            Object_Path_Built := A11y.Results.Succeeded (Result);
         end if;
         if Object_Path_Built then
            Second_Child_Object_Path :=
              A11y.Linux.ATSPi_Objects.Object_Path
                (Context.all.Session, Second_Child_Node, Result);
            Object_Path_Built := A11y.Results.Succeeded (Result);
         end if;
         if Object_Path_Built then
            Table_Cell_Object_Path :=
              A11y.Linux.ATSPi_Objects.Object_Path
                (Context.all.Session, Table_Cell_Node, Result);
            Object_Path_Built := A11y.Results.Succeeded (Result);
         end if;
      end if;

      if Object_Path_Built then
         A11y.Linux.ATSPi_Object_Registry.Ensure_Object
           (Registry.all, Context.all.Session, Application_Node, Registered,
            Result);
         Object_Registered :=
           A11y.Results.Succeeded (Result)
           and then Registered.Node = Application_Node
           and then Registered.Path = Object_Path;
         if Object_Registered then
            A11y.Linux.ATSPi_Object_Registry.Ensure_Object
              (Registry.all, Context.all.Session, Child_Node, Registered,
               Result);
            Object_Registered :=
              A11y.Results.Succeeded (Result)
              and then Registered.Node = Child_Node
              and then Registered.Path = Child_Object_Path;
         end if;
         if Object_Registered then
            A11y.Linux.ATSPi_Object_Registry.Ensure_Object
              (Registry.all, Context.all.Session, Table_Cell_Node, Registered,
               Result);
            Object_Registered :=
              A11y.Results.Succeeded (Result)
              and then Registered.Node = Table_Cell_Node
              and then Registered.Path = Table_Cell_Object_Path;
         end if;
      end if;

      if Object_Registered then
         Snapshots.all.Accessible.Id := Application_Node;
         Snapshots.all.Accessible.Role := A11y.Roles.Application;
         Snapshots.all.Accessible.Name :=
           To_Unbounded_String ("Fixture Application");
         Snapshots.all.Application.Id := Application_Node;
         Snapshots.all.Application.Application_Id := 42;
         Snapshots.all.Application.Toolkit_Name :=
           To_Unbounded_String ("a11y_tests");
         Snapshots.all.Application.Version :=
           To_Unbounded_String ("0.1.0-dev");
         Snapshots.all.Accessible.Help_Text :=
           A11y.Properties.Present ("Fixture help");
         Snapshots.all.Accessible.Placeholder :=
           A11y.Properties.Present ("Fixture placeholder");
         Snapshots.all.Accessible.States := A11y.States.Empty_State_Set;
         Snapshots.all.Accessible.States (A11y.States.Enabled) := True;
         Snapshots.all.Accessible.States (A11y.States.Focusable) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Action) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Value) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Selection) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Text) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Image) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Table) := True;
         Snapshots.all.Accessible.Capabilities
           (A11y.Capabilities.Document) := True;
         Snapshots.all.Accessible.Child_Count := 2;
         Snapshots.all.Accessible.Children.Append (Child_Node);
         Snapshots.all.Accessible.Children.Append (Second_Child_Node);
         A11y.Relations.Add
           (Snapshots.all.Accessible.Relations,
            Application_Node,
            A11y.Relations.Labelled_By,
            Child_Node,
            Result);
         Snapshots.all.Action.Id := Application_Node;
         Snapshots.all.Action.Root := Application_Node;
         Snapshots.all.Action.Supported :=
           A11y.Actions.With_Action
             (A11y.Actions.With_Action
                (A11y.Actions.Empty_Action_Set, A11y.Actions.Press),
              A11y.Actions.Toggle);
         Snapshots.all.Action.States := Snapshots.all.Accessible.States;
         Snapshots.all.Component.Id := Application_Node;
         Snapshots.all.Component.Root := Application_Node;
         Snapshots.all.Component.Bounds :=
           (Origin => (X => 10, Y => 20),
            Extent => (Width => 300, Height => 200));
         Snapshots.all.Component.Hit_Test_Node := Application_Node;
         Snapshots.all.Component.Focus_Request_Supported := True;
         Snapshots.all.Component.Focus_Request_Status := A11y.Results.Success;
         Snapshots.all.Value.Id := Application_Node;
         Snapshots.all.Value.Root := Application_Node;
         Snapshots.all.Value.Metadata.Current := A11y.Values.Floating (5.0);
         Snapshots.all.Value.Metadata.Minimum := A11y.Values.Floating (0.0);
         Snapshots.all.Value.Metadata.Maximum := A11y.Values.Floating (10.0);
         Snapshots.all.Value.Metadata.Small_Increment :=
           A11y.Values.Floating (1.0);
         Snapshots.all.Value.Metadata.Mode := A11y.Values.Writable;
         Snapshots.all.Selection.Id := Application_Node;
         Snapshots.all.Selection.Root := Application_Node;
         Snapshots.all.Selection.Children.Append (Child_Node);
         Snapshots.all.Selection.Children.Append (Second_Child_Node);
         A11y.Selection.Configure
           (Snapshots.all.Selection.Selection, A11y.Selection.Multiple);
         A11y.Selection.Select_Item
           (Snapshots.all.Selection.Selection, Child_Node, Result);
         Snapshots.all.Text.Id := Application_Node;
         Snapshots.all.Text.Root := Application_Node;
         Snapshots.all.Text.Content :=
           Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
             ("Fixture text");
         Snapshots.all.Text.Policy := A11y.Text.Plain_Text;
         Snapshots.all.Text.Caret := A11y.Text.Code_Point_Position (7);
         Snapshots.all.Image.Id := Application_Node;
         Snapshots.all.Image.Root := Application_Node;
         Snapshots.all.Image.Metadata.Kind := A11y.Images.Chart;
         Snapshots.all.Image.Metadata.Alternative_Text :=
           To_Unbounded_String ("Fixture chart");
         Snapshots.all.Image.Metadata.Caption :=
           To_Unbounded_String ("Quarterly trend");
         Snapshots.all.Image.Metadata.Has_Intrinsic_Size := True;
         Snapshots.all.Image.Metadata.Intrinsic_Dimensions :=
           (Width => 640, Height => 480);
         Snapshots.all.Table.Id := Application_Node;
         Snapshots.all.Table.Root := Application_Node;
         A11y.Tables.Configure
           (Snapshots.all.Table.Table, Rows => 3, Columns => 5);
         A11y.Tables.Add_Cell
           (Snapshots.all.Table.Table, Table_Cell_Node, Row => 1, Column => 2,
            Row_Span => 2, Column_Span => 3,
            Result => Result);
         A11y.Tables.Set_Current_Cell
           (Snapshots.all.Table.Table, Table_Cell_Node, Result);
         A11y.Tables.Set_Sort
           (Snapshots.all.Table.Table,
            Table_Cell_Node,
            A11y.Tables.Descending,
            Result);
         Snapshots.all.Document.Id := Application_Node;
         Snapshots.all.Document.Root := Application_Node;
         Snapshots.all.Document.Metadata.Role := A11y.Documents.Document;
         Snapshots.all.Document.Metadata.Language := To_Unbounded_String ("en-US");
         Snapshots.all.Document.Metadata.Title :=
           To_Unbounded_String ("Fixture Document");
         Snapshots.all.Document.Metadata.Landmark :=
           To_Unbounded_String ("main");

         Request_Message := A11y.Linux.DBus_Messages.Build_Method_Call
           (Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Accessible)),
            Member_Name    => To_Unbounded_String ("GetName"),
            Serial         => 101,
            Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Request_Envelope, Result);
         end if;
         Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Request_Packet.Bytes, Snapshots.all,
            Result);
         Packet_Dispatched := A11y.Results.Succeeded (Result);
         Reply_Queued :=
           Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
         Registry_View :=
           A11y.Linux.ATSPi_Object_Registry.Snapshot (Registry.all);
         Registry_Drained := Registry_View.Outstanding_Calls = 0;
      end if;

      if Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Reply_Packet, Result);
         Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
         Reply_In_Flight := Reply_Serialized;
      end if;

      if Reply_Serialized then
         Reply_Envelope := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Reply_Text := A11y.Linux.DBus_Messages.Decode_String_Body
              (Reply_Envelope.Body_Bytes, Result);
         end if;
         Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply_Envelope.Reply_Serial = 101
           and then Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Reply_Text) = "Fixture Application";
      end if;

      if Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Reply_Packet.Metadata.Serial, Result);
         Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Reply_Bookkeeping_Drained then
         Application_Id_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Application)),
              Member_Name    => To_Unbounded_String ("GetID"),
              Serial         => 150,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Application_Id_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Application_Id_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Application_Id_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Application_Id_Request_Envelope, Result);
         end if;
         Application_Id_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Application_Id_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Application_Id_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Application_Id_Request_Packet.Bytes,
            Snapshots.all, Result);
         Application_Id_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Application_Id_Reply_Queued :=
           Application_Id_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Application_Id_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Application_Id_Reply_Packet, Result);
         Application_Id_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Application_Id_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Application_Id_Reply_Serialized then
         Application_Id_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Application_Id_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Application_Id_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Application_Id_Reply_Envelope.Body_Bytes, Result);
         end if;
         Application_Id_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Application_Id_Reply_Envelope.Reply_Serial = 150
           and then Application_Id_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Application_Id_Value = 42;
      end if;

      if Application_Id_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Application_Id_Reply_Packet.Metadata.Serial, Result);
         Application_Id_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Application_Id_Reply_Bookkeeping_Drained then
         Property_Name_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_String_Pair
             (Object_Path     => Object_Path,
              Interface_Name  =>
                To_Unbounded_String ("org.freedesktop.DBus.Properties"),
              Member_Name     => To_Unbounded_String ("Get"),
              First_Argument  => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Second_Argument => To_Unbounded_String ("Name"),
              Serial          => 151,
              Result          => Result);
         if A11y.Results.Succeeded (Result) then
            Property_Name_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Property_Name_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Property_Name_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Property_Name_Request_Envelope, Result);
         end if;
         Property_Name_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Property_Name_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Property_Name_Request_Envelope.Body_Signature =
             To_Unbounded_String ("ss");
      end if;

      if Property_Name_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Property_Name_Request_Packet.Bytes,
            Snapshots.all, Result);
         Property_Name_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Property_Name_Reply_Queued :=
           Property_Name_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Property_Name_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Property_Name_Reply_Packet, Result);
         Property_Name_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Property_Name_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Property_Name_Reply_Serialized then
         Property_Name_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Property_Name_Reply_Packet.Bytes, Result);
         declare
            Reply_Body : constant String :=
              To_String (Property_Name_Reply_Envelope.Body_Bytes);
         begin
            Property_Name_Reply_Decoded :=
              A11y.Results.Succeeded (Result)
              and then Property_Name_Reply_Envelope.Reply_Serial = 151
              and then Property_Name_Reply_Envelope.Body_Signature =
                To_Unbounded_String ("v")
              and then Reply_Body'Length = 28
              and then Character'Pos (Reply_Body (1)) = 1
              and then Reply_Body (2) = 's'
              and then Character'Pos (Reply_Body (5)) = 19
              and then Reply_Body (9 .. 27) = "Fixture Application";
         end;
      end if;

      if Property_Name_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Property_Name_Reply_Packet.Metadata.Serial, Result);
         Property_Name_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Property_Name_Reply_Bookkeeping_Drained then
         Property_Map_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_String
             (Object_Path    => Object_Path,
              Interface_Name =>
                To_Unbounded_String ("org.freedesktop.DBus.Properties"),
              Member_Name    => To_Unbounded_String ("GetAll"),
              Argument       => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Serial         => 152,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Property_Map_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Property_Map_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Property_Map_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Property_Map_Request_Envelope, Result);
         end if;
         Property_Map_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Property_Map_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Property_Map_Request_Envelope.Body_Signature =
             To_Unbounded_String ("s");
      end if;

      if Property_Map_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Property_Map_Request_Packet.Bytes,
            Snapshots.all, Result);
         Property_Map_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Property_Map_Reply_Queued :=
           Property_Map_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Property_Map_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Property_Map_Reply_Packet, Result);
         Property_Map_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Property_Map_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Property_Map_Reply_Serialized then
         Property_Map_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Property_Map_Reply_Packet.Bytes, Result);
         declare
            Reply_Body : constant String :=
              To_String (Property_Map_Reply_Envelope.Body_Bytes);
         begin
            Property_Map_Reply_Decoded :=
              A11y.Results.Succeeded (Result)
              and then Property_Map_Reply_Envelope.Reply_Serial = 152
              and then Property_Map_Reply_Envelope.Body_Signature =
                To_Unbounded_String ("a{sv}")
              and then Ada.Strings.Fixed.Index (Reply_Body, "Name") /= 0
              and then Ada.Strings.Fixed.Index
                (Reply_Body, "Fixture Application") /= 0
              and then Ada.Strings.Fixed.Index (Reply_Body, "ChildCount") /= 0;
         end;
      end if;

      if Property_Map_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Property_Map_Reply_Packet.Metadata.Serial, Result);
         Property_Map_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Property_Map_Reply_Bookkeeping_Drained then
         Role_Request_Message := A11y.Linux.DBus_Messages.Build_Method_Call
           (Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Accessible)),
            Member_Name    => To_Unbounded_String ("GetRole"),
            Serial         => 102,
            Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Role_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Role_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Role_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Role_Request_Envelope, Result);
         end if;
         Role_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Role_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Role_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Role_Request_Packet.Bytes, Snapshots.all,
            Result);
         Role_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Role_Reply_Queued :=
           Role_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Role_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Role_Reply_Packet, Result);
         Role_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Role_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Role_Reply_Serialized then
         Role_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Role_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Role_Value := A11y.Linux.DBus_Messages.Decode_UInt32_Body
              (Role_Reply_Envelope.Body_Bytes, Result);
         end if;
         Role_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Role_Reply_Envelope.Reply_Serial = 102
           and then Role_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Role_Value =
             A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
               (A11y.Linux.ATSPi_Mappings.Application);
      end if;

      if Role_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Role_Reply_Packet.Metadata.Serial, Result);
         Role_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Role_Reply_Bookkeeping_Drained then
         State_Request_Message := A11y.Linux.DBus_Messages.Build_Method_Call
           (Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Accessible)),
            Member_Name    => To_Unbounded_String ("GetState"),
            Serial         => 103,
            Result         => Result);
         if A11y.Results.Succeeded (Result) then
            State_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (State_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            State_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (State_Request_Envelope, Result);
         end if;
         State_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then State_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if State_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, State_Request_Packet.Bytes,
            Snapshots.all, Result);
         State_Packet_Dispatched := A11y.Results.Succeeded (Result);
         State_Reply_Queued :=
           State_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if State_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, State_Reply_Packet, Result);
         State_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then State_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if State_Reply_Serialized then
         State_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (State_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            State_Values :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Array_Body
                (State_Reply_Envelope.Body_Bytes, Result);
         end if;
         State_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then State_Reply_Envelope.Reply_Serial = 103
           and then State_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("au")
           and then Contains_State
             (State_Values, A11y.Linux.ATSPi_Mappings.Enabled)
           and then Contains_State
             (State_Values, A11y.Linux.ATSPi_Mappings.Focusable);
      end if;

      if State_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, State_Reply_Packet.Metadata.Serial, Result);
         State_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if State_Reply_Bookkeeping_Drained then
         Interfaces_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetInterfaces"),
              Serial         => 104,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Interfaces_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Interfaces_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Interfaces_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Interfaces_Request_Envelope, Result);
         end if;
         Interfaces_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Interfaces_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Interfaces_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Interfaces_Request_Packet.Bytes,
            Snapshots.all, Result);
         Interfaces_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Interfaces_Reply_Queued :=
           Interfaces_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Interfaces_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Interfaces_Reply_Packet, Result);
         Interfaces_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Interfaces_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Interfaces_Reply_Serialized then
         Interfaces_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Interfaces_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Interface_Names :=
              A11y.Linux.DBus_Messages.Decode_String_Array_Body
                (Interfaces_Reply_Envelope.Body_Bytes, Result);
         end if;
         Interfaces_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Interfaces_Reply_Envelope.Reply_Serial = 104
           and then Interfaces_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("as")
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Accessible))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Application))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Component))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Value))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Selection))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Text))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Image))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Table))
           and then Contains_Text
             (Interface_Names,
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Document));
      end if;

      if Interfaces_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Interfaces_Reply_Packet.Metadata.Serial, Result);
         Interfaces_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Interfaces_Reply_Bookkeeping_Drained then
         Action_Count_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Action)),
              Member_Name    => To_Unbounded_String ("GetNActions"),
              Serial         => 105,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Action_Count_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Action_Count_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Action_Count_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Action_Count_Request_Envelope, Result);
         end if;
         Action_Count_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Action_Count_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Action_Count_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Action_Count_Request_Packet.Bytes,
            Snapshots.all, Result);
         Action_Count_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Action_Count_Reply_Queued :=
           Action_Count_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Action_Count_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Action_Count_Reply_Packet, Result);
         Action_Count_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Action_Count_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Action_Count_Reply_Serialized then
         Action_Count_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Action_Count_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Action_Count_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Action_Count_Reply_Envelope.Body_Bytes, Result);
         end if;
         Action_Count_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Action_Count_Reply_Envelope.Reply_Serial = 105
           and then Action_Count_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Action_Count_Value = 2;
      end if;

      if Action_Count_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Action_Count_Reply_Packet.Metadata.Serial, Result);
         Action_Count_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Action_Count_Reply_Bookkeeping_Drained then
         Action_Name_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Action)),
              Member_Name    => To_Unbounded_String ("GetName"),
              Argument       => 0,
              Serial         => 106,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Action_Name_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Action_Name_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Action_Name_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Action_Name_Request_Envelope, Result);
         end if;
         Action_Name_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Action_Name_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Action_Name_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Action_Name_Request_Packet.Bytes,
            Snapshots.all, Result);
         Action_Name_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Action_Name_Reply_Queued :=
           Action_Name_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Action_Name_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Action_Name_Reply_Packet, Result);
         Action_Name_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Action_Name_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Action_Name_Reply_Serialized then
         Action_Name_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Action_Name_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Action_Name_Text :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Action_Name_Reply_Envelope.Body_Bytes, Result);
         end if;
         Action_Name_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Action_Name_Reply_Envelope.Reply_Serial = 106
           and then Action_Name_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Action_Name_Text) =
             A11y.Actions.Stable_Name (A11y.Actions.Press);
      end if;

      if Action_Name_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Action_Name_Reply_Packet.Metadata.Serial, Result);
         Action_Name_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Action_Name_Reply_Bookkeeping_Drained then
         Action_Invoke_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Action)),
              Member_Name    => To_Unbounded_String ("DoAction"),
              Argument       => 1,
              Serial         => 107,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Action_Invoke_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Action_Invoke_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Action_Invoke_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Action_Invoke_Request_Envelope, Result);
         end if;
         Action_Invoke_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Action_Invoke_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Action_Invoke_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Action_Invoke_Request_Packet.Bytes,
            Snapshots.all, Result);
         Action_Invoke_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Action_Invoke_Reply_Queued :=
           Action_Invoke_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Action_Invoke_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Action_Invoke_Reply_Packet, Result);
         Action_Invoke_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Action_Invoke_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Action_Invoke_Reply_Serialized then
         Action_Invoke_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Action_Invoke_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Action_Invoke_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Action_Invoke_Reply_Envelope.Body_Bytes, Result);
         end if;
         Action_Invoke_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Action_Invoke_Reply_Envelope.Reply_Serial = 107
           and then Action_Invoke_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Action_Invoke_Value;
      end if;

      if Action_Invoke_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Action_Invoke_Reply_Packet.Metadata.Serial, Result);
         Action_Invoke_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Action_Invoke_Reply_Bookkeeping_Drained then
         Component_Extents_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Component)),
              Member_Name    => To_Unbounded_String ("GetExtents"),
              Serial         => 108,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Component_Extents_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Component_Extents_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Component_Extents_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Component_Extents_Request_Envelope, Result);
         end if;
         Component_Extents_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Extents_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Component_Extents_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Component_Extents_Request_Packet.Bytes,
            Snapshots.all, Result);
         Component_Extents_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Component_Extents_Reply_Queued :=
           Component_Extents_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Extents_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Component_Extents_Reply_Packet, Result);
         Component_Extents_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Component_Extents_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Extents_Reply_Serialized then
         Component_Extents_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Component_Extents_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Component_Extents_Value :=
              A11y.Linux.DBus_Messages.Decode_Rectangle_Body
                (Component_Extents_Reply_Envelope.Body_Bytes, Result);
         end if;
         Component_Extents_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Extents_Reply_Envelope.Reply_Serial = 108
           and then Component_Extents_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("(iiii)")
           and then Component_Extents_Value.Origin.X = 10
           and then Component_Extents_Value.Origin.Y = 20
           and then Component_Extents_Value.Extent.Width = 300
           and then Component_Extents_Value.Extent.Height = 200;
      end if;

      if Component_Extents_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Component_Extents_Reply_Packet.Metadata.Serial,
            Result);
         Component_Extents_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Component_Extents_Reply_Bookkeeping_Drained then
         Component_Contains_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_Point
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Component)),
              Member_Name    => To_Unbounded_String ("Contains"),
              Argument       => (X => 20, Y => 30),
              Serial         => 109,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Component_Contains_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Component_Contains_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Component_Contains_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Component_Contains_Request_Envelope, Result);
         end if;
         Component_Contains_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Contains_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Component_Contains_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Component_Contains_Request_Packet.Bytes,
            Snapshots.all, Result);
         Component_Contains_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Component_Contains_Reply_Queued :=
           Component_Contains_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Contains_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Component_Contains_Reply_Packet, Result);
         Component_Contains_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Component_Contains_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Contains_Reply_Serialized then
         Component_Contains_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Component_Contains_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Component_Contains_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Component_Contains_Reply_Envelope.Body_Bytes, Result);
         end if;
         Component_Contains_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Contains_Reply_Envelope.Reply_Serial = 109
           and then Component_Contains_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Component_Contains_Value;
      end if;

      if Component_Contains_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Component_Contains_Reply_Packet.Metadata.Serial,
            Result);
         Component_Contains_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Component_Contains_Reply_Bookkeeping_Drained then
         Component_Hit_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_Point
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Component)),
              Member_Name    => To_Unbounded_String ("GetAccessibleAtPoint"),
              Argument       => (X => 20, Y => 30),
              Serial         => 110,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Component_Hit_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Component_Hit_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Component_Hit_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Component_Hit_Request_Envelope, Result);
         end if;
         Component_Hit_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Hit_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Component_Hit_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Component_Hit_Request_Packet.Bytes,
            Snapshots.all, Result);
         Component_Hit_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Component_Hit_Reply_Queued :=
           Component_Hit_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Hit_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Component_Hit_Reply_Packet, Result);
         Component_Hit_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Component_Hit_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Hit_Reply_Serialized then
         Component_Hit_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Component_Hit_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Component_Hit_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Component_Hit_Reply_Envelope.Body_Bytes, Result);
         end if;
         Component_Hit_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Hit_Reply_Envelope.Reply_Serial = 110
           and then Component_Hit_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Component_Hit_Path = Object_Path;
      end if;

      if Component_Hit_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Component_Hit_Reply_Packet.Metadata.Serial, Result);
         Component_Hit_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Component_Hit_Reply_Bookkeeping_Drained then
         Component_Focus_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Component)),
              Member_Name    => To_Unbounded_String ("GrabFocus"),
              Serial         => 160,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Component_Focus_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Component_Focus_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Component_Focus_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Component_Focus_Request_Envelope, Result);
         end if;
         Component_Focus_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Focus_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Component_Focus_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Component_Focus_Request_Packet.Bytes,
            Snapshots.all, Result);
         Component_Focus_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Component_Focus_Reply_Queued :=
           Component_Focus_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Focus_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Component_Focus_Reply_Packet, Result);
         Component_Focus_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Component_Focus_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Component_Focus_Reply_Serialized then
         Component_Focus_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Component_Focus_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Component_Focus_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Component_Focus_Reply_Envelope.Body_Bytes, Result);
         end if;
         Component_Focus_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Component_Focus_Reply_Envelope.Reply_Serial = 160
           and then Component_Focus_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Component_Focus_Value;
      end if;

      if Component_Focus_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Component_Focus_Reply_Packet.Metadata.Serial,
            Result);
         Component_Focus_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Component_Focus_Reply_Bookkeeping_Drained then
         Value_Current_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Value)),
              Member_Name    => To_Unbounded_String ("GetCurrentValue"),
              Serial         => 111,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Value_Current_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Value_Current_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Value_Current_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Value_Current_Request_Envelope, Result);
         end if;
         Value_Current_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Current_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Value_Current_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Value_Current_Request_Packet.Bytes,
            Snapshots.all, Result);
         Value_Current_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Value_Current_Reply_Queued :=
           Value_Current_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Current_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Value_Current_Reply_Packet, Result);
         Value_Current_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Value_Current_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Current_Reply_Serialized then
         Value_Current_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Value_Current_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Value_Current_Float :=
              A11y.Linux.DBus_Messages.Decode_Float_Body
                (Value_Current_Reply_Envelope.Body_Bytes, Result);
         end if;
         Value_Current_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Current_Reply_Envelope.Reply_Serial = 111
           and then Value_Current_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("d")
           and then Value_Current_Float = 5.0;
      end if;

      if Value_Current_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Value_Current_Reply_Packet.Metadata.Serial, Result);
         Value_Current_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Value_Current_Reply_Bookkeeping_Drained then
         Value_Minimum_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Value)),
              Member_Name    => To_Unbounded_String ("GetMinimumValue"),
              Serial         => 112,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Value_Minimum_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Value_Minimum_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Value_Minimum_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Value_Minimum_Request_Envelope, Result);
         end if;
         Value_Minimum_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Minimum_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Value_Minimum_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Value_Minimum_Request_Packet.Bytes,
            Snapshots.all, Result);
         Value_Minimum_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Value_Minimum_Reply_Queued :=
           Value_Minimum_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Minimum_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Value_Minimum_Reply_Packet, Result);
         Value_Minimum_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Value_Minimum_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Minimum_Reply_Serialized then
         Value_Minimum_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Value_Minimum_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Value_Minimum_Float :=
              A11y.Linux.DBus_Messages.Decode_Float_Body
                (Value_Minimum_Reply_Envelope.Body_Bytes, Result);
         end if;
         Value_Minimum_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Minimum_Reply_Envelope.Reply_Serial = 112
           and then Value_Minimum_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("d")
           and then Value_Minimum_Float = 0.0;
      end if;

      if Value_Minimum_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Value_Minimum_Reply_Packet.Metadata.Serial, Result);
         Value_Minimum_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Value_Minimum_Reply_Bookkeeping_Drained then
         Value_Maximum_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Value)),
              Member_Name    => To_Unbounded_String ("GetMaximumValue"),
              Serial         => 113,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Value_Maximum_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Value_Maximum_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Value_Maximum_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Value_Maximum_Request_Envelope, Result);
         end if;
         Value_Maximum_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Maximum_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Value_Maximum_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Value_Maximum_Request_Packet.Bytes,
            Snapshots.all, Result);
         Value_Maximum_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Value_Maximum_Reply_Queued :=
           Value_Maximum_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Maximum_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Value_Maximum_Reply_Packet, Result);
         Value_Maximum_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Value_Maximum_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Maximum_Reply_Serialized then
         Value_Maximum_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Value_Maximum_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Value_Maximum_Float :=
              A11y.Linux.DBus_Messages.Decode_Float_Body
                (Value_Maximum_Reply_Envelope.Body_Bytes, Result);
         end if;
         Value_Maximum_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Maximum_Reply_Envelope.Reply_Serial = 113
           and then Value_Maximum_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("d")
           and then Value_Maximum_Float = 10.0;
      end if;

      if Value_Maximum_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Value_Maximum_Reply_Packet.Metadata.Serial, Result);
         Value_Maximum_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Value_Maximum_Reply_Bookkeeping_Drained then
         Value_Increment_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Value)),
              Member_Name    => To_Unbounded_String ("GetMinimumIncrement"),
              Serial         => 114,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Value_Increment_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Value_Increment_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Value_Increment_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Value_Increment_Request_Envelope, Result);
         end if;
         Value_Increment_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Increment_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Value_Increment_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Value_Increment_Request_Packet.Bytes,
            Snapshots.all, Result);
         Value_Increment_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Value_Increment_Reply_Queued :=
           Value_Increment_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Increment_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Value_Increment_Reply_Packet, Result);
         Value_Increment_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Value_Increment_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Increment_Reply_Serialized then
         Value_Increment_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Value_Increment_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Value_Increment_Float :=
              A11y.Linux.DBus_Messages.Decode_Float_Body
                (Value_Increment_Reply_Envelope.Body_Bytes, Result);
         end if;
         Value_Increment_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Increment_Reply_Envelope.Reply_Serial = 114
           and then Value_Increment_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("d")
           and then Value_Increment_Float = 1.0;
      end if;

      if Value_Increment_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Value_Increment_Reply_Packet.Metadata.Serial, Result);
         Value_Increment_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Value_Increment_Reply_Bookkeeping_Drained then
         Value_Set_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_Float
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Value)),
              Member_Name    => To_Unbounded_String ("SetCurrentValue"),
              Argument       => 6.0,
              Serial         => 115,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Value_Set_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Value_Set_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Value_Set_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Value_Set_Request_Envelope, Result);
         end if;
         Value_Set_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Set_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Value_Set_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Value_Set_Request_Packet.Bytes,
            Snapshots.all, Result);
         Value_Set_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Value_Set_Reply_Queued :=
           Value_Set_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Set_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Value_Set_Reply_Packet, Result);
         Value_Set_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Value_Set_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Value_Set_Reply_Serialized then
         Value_Set_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Value_Set_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Value_Set_Boolean :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Value_Set_Reply_Envelope.Body_Bytes, Result);
         end if;
         Value_Set_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Value_Set_Reply_Envelope.Reply_Serial = 115
           and then Value_Set_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Value_Set_Boolean;
      end if;

      if Value_Set_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Value_Set_Reply_Packet.Metadata.Serial, Result);
         Value_Set_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Value_Set_Reply_Bookkeeping_Drained then
         Selection_Count_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("GetNSelectedChildren"),
              Serial         => 116,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Count_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Count_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Count_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Count_Request_Envelope, Result);
         end if;
         Selection_Count_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Count_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Count_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Selection_Count_Request_Packet.Bytes,
            Snapshots.all, Result);
         Selection_Count_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Selection_Count_Reply_Queued :=
           Selection_Count_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Count_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Count_Reply_Packet, Result);
         Selection_Count_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Count_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Count_Reply_Serialized then
         Selection_Count_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Count_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Count_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Selection_Count_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Count_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Count_Reply_Envelope.Reply_Serial = 116
           and then Selection_Count_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Selection_Count_Value = 1;
      end if;

      if Selection_Count_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Count_Reply_Packet.Metadata.Serial, Result);
         Selection_Count_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Count_Reply_Bookkeeping_Drained then
         Selection_Selected_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("GetSelectedChild"),
              Argument       => 0,
              Serial         => 117,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Selected_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Selected_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Selected_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Selected_Request_Envelope, Result);
         end if;
         Selection_Selected_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Selected_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Selected_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Selection_Selected_Request_Packet.Bytes,
            Snapshots.all, Result);
         Selection_Selected_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Selection_Selected_Reply_Queued :=
           Selection_Selected_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Selected_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Selected_Reply_Packet, Result);
         Selection_Selected_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Selected_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Selected_Reply_Serialized then
         Selection_Selected_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Selected_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Selected_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Selection_Selected_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Selected_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Selected_Reply_Envelope.Reply_Serial = 117
           and then Selection_Selected_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Selection_Selected_Path = Child_Object_Path;
      end if;

      if Selection_Selected_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Selected_Reply_Packet.Metadata.Serial,
            Result);
         Selection_Selected_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Selected_Reply_Bookkeeping_Drained then
         Selection_Is_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("IsChildSelected"),
              Argument       => 0,
              Serial         => 118,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Is_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Is_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Is_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Is_Request_Envelope, Result);
         end if;
         Selection_Is_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Is_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Is_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Selection_Is_Request_Packet.Bytes,
            Snapshots.all, Result);
         Selection_Is_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Selection_Is_Reply_Queued :=
           Selection_Is_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Is_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Is_Reply_Packet, Result);
         Selection_Is_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Is_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Is_Reply_Serialized then
         Selection_Is_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Is_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Is_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Selection_Is_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Is_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Is_Reply_Envelope.Reply_Serial = 118
           and then Selection_Is_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Selection_Is_Value;
      end if;

      if Selection_Is_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Is_Reply_Packet.Metadata.Serial, Result);
         Selection_Is_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Is_Reply_Bookkeeping_Drained then
         Selection_Select_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("SelectChild"),
              Argument       => 0,
              Serial         => 119,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Select_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Select_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Select_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Select_Request_Envelope, Result);
         end if;
         Selection_Select_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Select_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Select_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Selection_Select_Request_Packet.Bytes,
            Snapshots.all, Result);
         Selection_Select_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Selection_Select_Reply_Queued :=
           Selection_Select_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Select_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Select_Reply_Packet, Result);
         Selection_Select_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Select_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Select_Reply_Serialized then
         Selection_Select_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Select_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Select_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Selection_Select_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Select_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Select_Reply_Envelope.Reply_Serial = 119
           and then Selection_Select_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Selection_Select_Value;
      end if;

      if Selection_Select_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Select_Reply_Packet.Metadata.Serial,
            Result);
         Selection_Select_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Select_Reply_Bookkeeping_Drained then
         Selection_Deselect_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("DeselectChild"),
              Argument       => 0,
              Serial         => 156,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Deselect_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Deselect_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Deselect_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Deselect_Request_Envelope, Result);
         end if;
         Selection_Deselect_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Deselect_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Deselect_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Selection_Deselect_Request_Packet.Bytes,
            Snapshots.all, Result);
         Selection_Deselect_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Selection_Deselect_Reply_Queued :=
           Selection_Deselect_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Deselect_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Deselect_Reply_Packet, Result);
         Selection_Deselect_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Deselect_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Deselect_Reply_Serialized then
         Selection_Deselect_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Deselect_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Deselect_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Selection_Deselect_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Deselect_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Deselect_Reply_Envelope.Reply_Serial = 156
           and then Selection_Deselect_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Selection_Deselect_Value;
      end if;

      if Selection_Deselect_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Deselect_Reply_Packet.Metadata.Serial,
            Result);
         Selection_Deselect_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Deselect_Reply_Bookkeeping_Drained then
         Selection_Select_All_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("SelectAll"),
              Serial         => 157,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Select_All_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Select_All_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Select_All_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Select_All_Request_Envelope, Result);
         end if;
         Selection_Select_All_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Select_All_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Select_All_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all,
            Selection_Select_All_Request_Packet.Bytes, Snapshots.all, Result);
         Selection_Select_All_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Selection_Select_All_Reply_Queued :=
           Selection_Select_All_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Select_All_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Select_All_Reply_Packet, Result);
         Selection_Select_All_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Select_All_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Select_All_Reply_Serialized then
         Selection_Select_All_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Select_All_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Select_All_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Selection_Select_All_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Select_All_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Select_All_Reply_Envelope.Reply_Serial = 157
           and then Selection_Select_All_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Selection_Select_All_Value;
      end if;

      if Selection_Select_All_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Select_All_Reply_Packet.Metadata.Serial,
            Result);
         Selection_Select_All_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Select_All_Reply_Bookkeeping_Drained then
         Selection_Clear_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Selection)),
              Member_Name    => To_Unbounded_String ("ClearSelection"),
              Serial         => 158,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Clear_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Selection_Clear_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Selection_Clear_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Selection_Clear_Request_Envelope, Result);
         end if;
         Selection_Clear_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Clear_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Selection_Clear_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Selection_Clear_Request_Packet.Bytes,
            Snapshots.all, Result);
         Selection_Clear_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Selection_Clear_Reply_Queued :=
           Selection_Clear_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Clear_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Selection_Clear_Reply_Packet, Result);
         Selection_Clear_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Selection_Clear_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Selection_Clear_Reply_Serialized then
         Selection_Clear_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Selection_Clear_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Selection_Clear_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Selection_Clear_Reply_Envelope.Body_Bytes, Result);
         end if;
         Selection_Clear_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Selection_Clear_Reply_Envelope.Reply_Serial = 158
           and then Selection_Clear_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Selection_Clear_Value;
      end if;

      if Selection_Clear_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Selection_Clear_Reply_Packet.Metadata.Serial,
            Result);
         Selection_Clear_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Selection_Clear_Reply_Bookkeeping_Drained then
         Text_Count_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Text)),
              Member_Name    => To_Unbounded_String ("GetCharacterCount"),
              Serial         => 120,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Count_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Count_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Count_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Count_Request_Envelope, Result);
         end if;
         Text_Count_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Count_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Text_Count_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Count_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Count_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Count_Reply_Queued :=
           Text_Count_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Count_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Count_Reply_Packet, Result);
         Text_Count_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Count_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Count_Reply_Serialized then
         Text_Count_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Count_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Count_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Text_Count_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Count_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Count_Reply_Envelope.Reply_Serial = 120
           and then Text_Count_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Text_Count_Value = 12;
      end if;

      if Text_Count_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Count_Reply_Packet.Metadata.Serial, Result);
         Text_Count_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Count_Reply_Bookkeeping_Drained then
         Text_Caret_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Text)),
              Member_Name    => To_Unbounded_String ("GetCaretOffset"),
              Serial         => 121,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Caret_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Caret_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Caret_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Caret_Request_Envelope, Result);
         end if;
         Text_Caret_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Caret_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Text_Caret_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Caret_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Caret_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Caret_Reply_Queued :=
           Text_Caret_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Caret_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Caret_Reply_Packet, Result);
         Text_Caret_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Caret_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Caret_Reply_Serialized then
         Text_Caret_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Caret_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Caret_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Text_Caret_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Caret_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Caret_Reply_Envelope.Reply_Serial = 121
           and then Text_Caret_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Text_Caret_Value = 7;
      end if;

      if Text_Caret_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Caret_Reply_Packet.Metadata.Serial, Result);
         Text_Caret_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Caret_Reply_Bookkeeping_Drained then
         Text_Range_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32_Pair
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Text)),
              Member_Name    => To_Unbounded_String ("GetText"),
              First_Argument => 0,
              Second_Argument => 7,
              Serial         => 122,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Range_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Range_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Range_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Range_Request_Envelope, Result);
         end if;
         Text_Range_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Range_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Text_Range_Request_Envelope.Body_Signature =
             To_Unbounded_String ("uu");
      end if;

      if Text_Range_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Range_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Range_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Range_Reply_Queued :=
           Text_Range_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Range_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Range_Reply_Packet, Result);
         Text_Range_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Range_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Range_Reply_Serialized then
         Text_Range_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Range_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Range_Value :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Text_Range_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Range_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Range_Reply_Envelope.Reply_Serial = 122
           and then Text_Range_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Text_Range_Value) = "Fixture";
      end if;

      if Text_Range_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Range_Reply_Packet.Metadata.Serial, Result);
         Text_Range_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Range_Reply_Bookkeeping_Drained then
         Text_Edit_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32_Pair_String
             (Object_Path     => Object_Path,
              Interface_Name  => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Editable_Text)),
              Member_Name     => To_Unbounded_String ("InsertText"),
              First_Argument  => 1,
              Second_Argument => 0,
              Text_Argument   => To_Unbounded_String ("X"),
              Serial          => 140,
              Result          => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Edit_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Edit_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Edit_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Edit_Request_Envelope, Result);
         end if;
         Text_Edit_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Edit_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Text_Edit_Request_Envelope.Body_Signature =
             To_Unbounded_String ("uus");
      end if;

      if Text_Edit_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Edit_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Edit_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Edit_Reply_Queued :=
           Text_Edit_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Edit_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Edit_Reply_Packet, Result);
         Text_Edit_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Edit_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Edit_Reply_Serialized then
         Text_Edit_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Edit_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Edit_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Text_Edit_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Edit_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Edit_Reply_Envelope.Reply_Serial = 140
           and then Text_Edit_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Text_Edit_Value;
      end if;

      if Text_Edit_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Edit_Reply_Packet.Metadata.Serial, Result);
         Text_Edit_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Edit_Reply_Bookkeeping_Drained then
         Text_Delete_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32_Pair
             (Object_Path      => Object_Path,
              Interface_Name   => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Editable_Text)),
              Member_Name      => To_Unbounded_String ("DeleteText"),
              First_Argument   => 1,
              Second_Argument  => 2,
              Serial           => 141,
              Result           => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Delete_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Delete_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Delete_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Delete_Request_Envelope, Result);
         end if;
         Text_Delete_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Delete_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Text_Delete_Request_Envelope.Body_Signature =
             To_Unbounded_String ("uu");
      end if;

      if Text_Delete_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Delete_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Delete_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Delete_Reply_Queued :=
           Text_Delete_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Delete_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Delete_Reply_Packet, Result);
         Text_Delete_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Delete_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Delete_Reply_Serialized then
         Text_Delete_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Delete_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Delete_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Text_Delete_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Delete_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Delete_Reply_Envelope.Reply_Serial = 141
           and then Text_Delete_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Text_Delete_Value;
      end if;

      if Text_Delete_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Delete_Reply_Packet.Metadata.Serial, Result);
         Text_Delete_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Delete_Reply_Bookkeeping_Drained then
         Text_Replace_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32_Pair_String
             (Object_Path      => Object_Path,
              Interface_Name   => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Editable_Text)),
              Member_Name      => To_Unbounded_String ("ReplaceText"),
              First_Argument   => 3,
              Second_Argument  => 2,
              Text_Argument    => To_Unbounded_String ("YZ"),
              Serial           => 142,
              Result           => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Replace_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Replace_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Replace_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Replace_Request_Envelope, Result);
         end if;
         Text_Replace_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Replace_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Text_Replace_Request_Envelope.Body_Signature =
             To_Unbounded_String ("uus");
      end if;

      if Text_Replace_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Replace_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Replace_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Replace_Reply_Queued :=
           Text_Replace_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Replace_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Replace_Reply_Packet, Result);
         Text_Replace_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Replace_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Replace_Reply_Serialized then
         Text_Replace_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Replace_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Replace_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Text_Replace_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Replace_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Replace_Reply_Envelope.Reply_Serial = 142
           and then Text_Replace_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Text_Replace_Value;
      end if;

      if Text_Replace_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Replace_Reply_Packet.Metadata.Serial, Result);
         Text_Replace_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Replace_Reply_Bookkeeping_Drained then
         Text_Set_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_String
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Editable_Text)),
              Member_Name    => To_Unbounded_String ("SetTextContents"),
              Argument       => To_Unbounded_String ("Reset"),
              Serial         => 143,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Text_Set_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Text_Set_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Text_Set_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Text_Set_Request_Envelope, Result);
         end if;
         Text_Set_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Set_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call
           and then Text_Set_Request_Envelope.Body_Signature =
             To_Unbounded_String ("s");
      end if;

      if Text_Set_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Text_Set_Request_Packet.Bytes,
            Snapshots.all, Result);
         Text_Set_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Text_Set_Reply_Queued :=
           Text_Set_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Set_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Text_Set_Reply_Packet, Result);
         Text_Set_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Text_Set_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Text_Set_Reply_Serialized then
         Text_Set_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Text_Set_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Text_Set_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Text_Set_Reply_Envelope.Body_Bytes, Result);
         end if;
         Text_Set_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Text_Set_Reply_Envelope.Reply_Serial = 143
           and then Text_Set_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Text_Set_Value;
      end if;

      if Text_Set_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Text_Set_Reply_Packet.Metadata.Serial, Result);
         Text_Set_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Text_Set_Reply_Bookkeeping_Drained then
         Image_Description_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Image)),
              Member_Name    => To_Unbounded_String ("GetImageDescription"),
              Serial         => 123,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Image_Description_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Image_Description_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Image_Description_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Image_Description_Request_Envelope, Result);
         end if;
         Image_Description_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Description_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Image_Description_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Image_Description_Request_Packet.Bytes,
            Snapshots.all, Result);
         Image_Description_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Image_Description_Reply_Queued :=
           Image_Description_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Description_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Image_Description_Reply_Packet, Result);
         Image_Description_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Image_Description_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Description_Reply_Serialized then
         Image_Description_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Image_Description_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Image_Description_Value :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Image_Description_Reply_Envelope.Body_Bytes, Result);
         end if;
         Image_Description_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Description_Reply_Envelope.Reply_Serial = 123
           and then Image_Description_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Image_Description_Value) = "Fixture chart";
      end if;

      if Image_Description_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all,
            Image_Description_Reply_Packet.Metadata.Serial,
            Result);
         Image_Description_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Image_Description_Reply_Bookkeeping_Drained then
         Image_Caption_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Image)),
              Member_Name    => To_Unbounded_String ("GetImageCaption"),
              Serial         => 124,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Image_Caption_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Image_Caption_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Image_Caption_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Image_Caption_Request_Envelope, Result);
         end if;
         Image_Caption_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Caption_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Image_Caption_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Image_Caption_Request_Packet.Bytes,
            Snapshots.all, Result);
         Image_Caption_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Image_Caption_Reply_Queued :=
           Image_Caption_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Caption_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Image_Caption_Reply_Packet, Result);
         Image_Caption_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Image_Caption_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Caption_Reply_Serialized then
         Image_Caption_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Image_Caption_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Image_Caption_Value :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Image_Caption_Reply_Envelope.Body_Bytes, Result);
         end if;
         Image_Caption_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Caption_Reply_Envelope.Reply_Serial = 124
           and then Image_Caption_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Image_Caption_Value) = "Quarterly trend";
      end if;

      if Image_Caption_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Image_Caption_Reply_Packet.Metadata.Serial, Result);
         Image_Caption_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Image_Caption_Reply_Bookkeeping_Drained then
         Image_Kind_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Image)),
              Member_Name    => To_Unbounded_String ("GetImageKind"),
              Serial         => 125,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Image_Kind_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Image_Kind_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Image_Kind_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Image_Kind_Request_Envelope, Result);
         end if;
         Image_Kind_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Kind_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Image_Kind_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Image_Kind_Request_Packet.Bytes,
            Snapshots.all, Result);
         Image_Kind_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Image_Kind_Reply_Queued :=
           Image_Kind_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Kind_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Image_Kind_Reply_Packet, Result);
         Image_Kind_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Image_Kind_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Kind_Reply_Serialized then
         Image_Kind_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Image_Kind_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Image_Kind_Value :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Image_Kind_Reply_Envelope.Body_Bytes, Result);
         end if;
         Image_Kind_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Kind_Reply_Envelope.Reply_Serial = 125
           and then Image_Kind_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Image_Kind_Value) =
             A11y.Images.Stable_Name (A11y.Images.Chart);
      end if;

      if Image_Kind_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Image_Kind_Reply_Packet.Metadata.Serial, Result);
         Image_Kind_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Image_Kind_Reply_Bookkeeping_Drained then
         Image_Size_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Image)),
              Member_Name    => To_Unbounded_String ("GetImageSize"),
              Serial         => 126,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Image_Size_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Image_Size_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Image_Size_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Image_Size_Request_Envelope, Result);
         end if;
         Image_Size_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Size_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Image_Size_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Image_Size_Request_Packet.Bytes,
            Snapshots.all, Result);
         Image_Size_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Image_Size_Reply_Queued :=
           Image_Size_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Size_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Image_Size_Reply_Packet, Result);
         Image_Size_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Image_Size_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Image_Size_Reply_Serialized then
         Image_Size_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Image_Size_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Image_Size_Value :=
              A11y.Linux.DBus_Messages.Decode_Size_Body
                (Image_Size_Reply_Envelope.Body_Bytes, Result);
         end if;
         Image_Size_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Image_Size_Reply_Envelope.Reply_Serial = 126
           and then Image_Size_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("(ii)")
           and then Image_Size_Value.Width = 640
           and then Image_Size_Value.Height = 480;
      end if;

      if Image_Size_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Image_Size_Reply_Packet.Metadata.Serial, Result);
         Image_Size_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Image_Size_Reply_Bookkeeping_Drained then
         Child_Count_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetChildCount"),
              Serial         => 127,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Child_Count_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Child_Count_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Child_Count_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Child_Count_Request_Envelope, Result);
         end if;
         Child_Count_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Child_Count_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Child_Count_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Child_Count_Request_Packet.Bytes,
            Snapshots.all, Result);
         Child_Count_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Child_Count_Reply_Queued :=
           Child_Count_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Child_Count_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Child_Count_Reply_Packet, Result);
         Child_Count_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Child_Count_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Child_Count_Reply_Serialized then
         Child_Count_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Child_Count_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Child_Count_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Child_Count_Reply_Envelope.Body_Bytes, Result);
         end if;
         Child_Count_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Child_Count_Reply_Envelope.Reply_Serial = 127
           and then Child_Count_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Child_Count_Value = 2;
      end if;

      if Child_Count_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Child_Count_Reply_Packet.Metadata.Serial, Result);
         Child_Count_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Child_Count_Reply_Bookkeeping_Drained then
         Child_At_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_UInt32
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetChildAtIndex"),
              Argument       => 0,
              Serial         => 128,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Child_At_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Child_At_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Child_At_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Child_At_Request_Envelope, Result);
         end if;
         Child_At_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Child_At_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Child_At_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Child_At_Request_Packet.Bytes,
            Snapshots.all, Result);
         Child_At_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Child_At_Reply_Queued :=
           Child_At_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Child_At_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Child_At_Reply_Packet, Result);
         Child_At_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Child_At_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Child_At_Reply_Serialized then
         Child_At_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Child_At_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Child_At_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Child_At_Reply_Envelope.Body_Bytes, Result);
         end if;
         Child_At_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Child_At_Reply_Envelope.Reply_Serial = 128
           and then Child_At_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Child_At_Path = Child_Object_Path;
      end if;

      if Child_At_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Child_At_Reply_Packet.Metadata.Serial, Result);
         Child_At_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Child_At_Reply_Bookkeeping_Drained then
         Children_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetChildren"),
              Serial         => 129,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Children_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Children_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Children_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Children_Request_Envelope, Result);
         end if;
         Children_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Children_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Children_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Children_Request_Packet.Bytes,
            Snapshots.all, Result);
         Children_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Children_Reply_Queued :=
           Children_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Children_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Children_Reply_Packet, Result);
         Children_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Children_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Children_Reply_Serialized then
         Children_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Children_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Children_Paths :=
              A11y.Linux.DBus_Messages.Decode_Object_Path_Array_Body
                (Children_Reply_Envelope.Body_Bytes, Result);
         end if;
         Children_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Children_Reply_Envelope.Reply_Serial = 129
           and then Children_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("ao")
           and then Natural (Children_Paths.Length) = 2
           and then Children_Paths.Element (1) = Child_Object_Path
           and then Children_Paths.Element (2) = Second_Child_Object_Path;
      end if;

      if Children_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Children_Reply_Packet.Metadata.Serial, Result);
         Children_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Children_Reply_Bookkeeping_Drained then
         Attributes_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetAttributes"),
              Serial         => 160,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Attributes_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Attributes_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Attributes_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Attributes_Request_Envelope, Result);
         end if;
         Attributes_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Attributes_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Attributes_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Attributes_Request_Packet.Bytes,
            Snapshots.all, Result);
         Attributes_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Attributes_Reply_Queued :=
           Attributes_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Attributes_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Attributes_Reply_Packet, Result);
         Attributes_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Attributes_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Attributes_Reply_Serialized then
         Attributes_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Attributes_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Attribute_Items :=
              A11y.Linux.DBus_Messages.Decode_Attribute_Set_Body
                (Attributes_Reply_Envelope.Body_Bytes, Result);
         end if;
         Attributes_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Attributes_Reply_Envelope.Reply_Serial = 160
           and then Attributes_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("a{ss}")
           and then Has_Attribute
             (Attribute_Items, "help-text", "Fixture help")
           and then Has_Attribute
             (Attribute_Items, "placeholder-text", "Fixture placeholder");
      end if;

      if Attributes_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Attributes_Reply_Packet.Metadata.Serial, Result);
         Attributes_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Attributes_Reply_Bookkeeping_Drained then
         Relations_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetRelationSet"),
              Serial         => 161,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Relations_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Relations_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Relations_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Relations_Request_Envelope, Result);
         end if;
         Relations_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Relations_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Relations_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Relations_Request_Packet.Bytes,
            Snapshots.all, Result);
         Relations_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Relations_Reply_Queued :=
           Relations_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Relations_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Relations_Reply_Packet, Result);
         Relations_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Relations_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Relations_Reply_Serialized then
         Relations_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Relations_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Relation_Items :=
              A11y.Linux.DBus_Messages.Decode_Relation_Set_Body
                (Context.all.Session,
                 Relations_Reply_Envelope.Body_Bytes,
                 Result);
         end if;
         Relations_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Relations_Reply_Envelope.Reply_Serial = 161
           and then Relations_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("a(uao)")
           and then Natural (Relation_Items.Length) = 1
           and then Relation_Items.First_Element.Kind =
             A11y.Linux.ATSPi_Mappings.Labelled_By
           and then Natural
             (Relation_Items.First_Element.Targets.Length) = 1
           and then Relation_Items.First_Element.Targets.First_Element =
             Child_Node;
      end if;

      if Relations_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Relations_Reply_Packet.Metadata.Serial, Result);
         Relations_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Relations_Reply_Bookkeeping_Drained then
         Snapshots.all.Accessible.Id := Child_Node;
         Snapshots.all.Accessible.Role := A11y.Roles.Window;
         Snapshots.all.Accessible.Name := To_Unbounded_String ("Main Window");
         Snapshots.all.Accessible.Parent := Application_Node;
         Snapshots.all.Accessible.Index_In_Parent := 0;
         Snapshots.all.Accessible.Child_Count := 0;
         Snapshots.all.Accessible.Children.Clear;

         Parent_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Child_Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetParent"),
              Serial         => 130,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Parent_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Parent_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Parent_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Parent_Request_Envelope, Result);
         end if;
         Parent_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Parent_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Parent_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Parent_Request_Packet.Bytes,
            Snapshots.all, Result);
         Parent_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Parent_Reply_Queued :=
           Parent_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Parent_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Parent_Reply_Packet, Result);
         Parent_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Parent_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Parent_Reply_Serialized then
         Parent_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Parent_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Parent_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Parent_Reply_Envelope.Body_Bytes, Result);
         end if;
         Parent_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Parent_Reply_Envelope.Reply_Serial = 130
           and then Parent_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Parent_Path = Object_Path;
      end if;

      if Parent_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Parent_Reply_Packet.Metadata.Serial, Result);
         Parent_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Parent_Reply_Bookkeeping_Drained then
         Index_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Child_Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Accessible)),
              Member_Name    => To_Unbounded_String ("GetIndexInParent"),
              Serial         => 131,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Index_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Index_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Index_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Index_Request_Envelope, Result);
         end if;
         Index_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Index_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Index_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Index_Request_Packet.Bytes,
            Snapshots.all, Result);
         Index_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Index_Reply_Queued :=
           Index_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Index_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Index_Reply_Packet, Result);
         Index_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Index_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Index_Reply_Serialized then
         Index_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Index_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Index_Value :=
              A11y.Linux.DBus_Messages.Decode_Int32_Body
                (Index_Reply_Envelope.Body_Bytes, Result);
         end if;
         Index_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Index_Reply_Envelope.Reply_Serial = 131
           and then Index_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("i")
           and then Index_Value = 0;
      end if;

      if Index_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Index_Reply_Packet.Metadata.Serial, Result);
         Index_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Index_Reply_Bookkeeping_Drained then
         Table_Row_Count_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetNRows"),
              Serial         => 132,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Row_Count_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Row_Count_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Row_Count_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Row_Count_Request_Envelope, Result);
         end if;
         Table_Row_Count_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Row_Count_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Row_Count_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Table_Row_Count_Request_Packet.Bytes,
            Snapshots.all, Result);
         Table_Row_Count_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Table_Row_Count_Reply_Queued :=
           Table_Row_Count_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Row_Count_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Row_Count_Reply_Packet, Result);
         Table_Row_Count_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Row_Count_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Row_Count_Reply_Serialized then
         Table_Row_Count_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Row_Count_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Row_Count_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Table_Row_Count_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Row_Count_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Row_Count_Reply_Envelope.Reply_Serial = 132
           and then Table_Row_Count_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Table_Row_Count_Value = 3;
      end if;

      if Table_Row_Count_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Table_Row_Count_Reply_Packet.Metadata.Serial, Result);
         Table_Row_Count_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Row_Count_Reply_Bookkeeping_Drained then
         Table_Column_Count_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetNColumns"),
              Serial         => 133,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Column_Count_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Column_Count_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Column_Count_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Column_Count_Request_Envelope, Result);
         end if;
         Table_Column_Count_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Column_Count_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Column_Count_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Table_Column_Count_Request_Packet.Bytes,
            Snapshots.all, Result);
         Table_Column_Count_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Table_Column_Count_Reply_Queued :=
           Table_Column_Count_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Column_Count_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Column_Count_Reply_Packet, Result);
         Table_Column_Count_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Column_Count_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Column_Count_Reply_Serialized then
         Table_Column_Count_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Column_Count_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Column_Count_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Table_Column_Count_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Column_Count_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Column_Count_Reply_Envelope.Reply_Serial = 133
           and then Table_Column_Count_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Table_Column_Count_Value = 5;
      end if;

      if Table_Column_Count_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Table_Column_Count_Reply_Packet.Metadata.Serial,
            Result);
         Table_Column_Count_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Column_Count_Reply_Bookkeeping_Drained then
         Table_Cell_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_Point
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetAccessibleAt"),
              Argument       => (X => 1, Y => 2),
              Serial         => 134,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Cell_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Cell_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Cell_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Cell_Request_Envelope, Result);
         end if;
         Table_Cell_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Cell_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Cell_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Table_Cell_Request_Packet.Bytes,
            Snapshots.all, Result);
         Table_Cell_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Table_Cell_Reply_Queued :=
           Table_Cell_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Cell_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Cell_Reply_Packet, Result);
         Table_Cell_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Cell_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Cell_Reply_Serialized then
         Table_Cell_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Cell_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Cell_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Table_Cell_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Cell_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Cell_Reply_Envelope.Reply_Serial = 134
           and then Table_Cell_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Table_Cell_Path = Table_Cell_Object_Path;
      end if;

      if Table_Cell_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Table_Cell_Reply_Packet.Metadata.Serial, Result);
         Table_Cell_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Cell_Reply_Bookkeeping_Drained then
         Table_Row_Extent_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_Point
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetRowExtentAt"),
              Argument       => (X => 1, Y => 2),
              Serial         => 135,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Row_Extent_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Row_Extent_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Row_Extent_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Row_Extent_Request_Envelope, Result);
         end if;
         Table_Row_Extent_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Row_Extent_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Row_Extent_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Table_Row_Extent_Request_Packet.Bytes,
            Snapshots.all, Result);
         Table_Row_Extent_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Table_Row_Extent_Reply_Queued :=
           Table_Row_Extent_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Row_Extent_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Row_Extent_Reply_Packet, Result);
         Table_Row_Extent_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Row_Extent_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Row_Extent_Reply_Serialized then
         Table_Row_Extent_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Row_Extent_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Row_Extent_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Table_Row_Extent_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Row_Extent_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Row_Extent_Reply_Envelope.Reply_Serial = 135
           and then Table_Row_Extent_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Table_Row_Extent_Value = 2;
      end if;

      if Table_Row_Extent_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Table_Row_Extent_Reply_Packet.Metadata.Serial,
            Result);
         Table_Row_Extent_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Row_Extent_Reply_Bookkeeping_Drained then
         Table_Column_Extent_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_Point
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetColumnExtentAt"),
              Argument       => (X => 1, Y => 2),
              Serial         => 136,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Column_Extent_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Column_Extent_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Column_Extent_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Column_Extent_Request_Envelope, Result);
         end if;
         Table_Column_Extent_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Column_Extent_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Column_Extent_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all,
            Table_Column_Extent_Request_Packet.Bytes, Snapshots.all, Result);
         Table_Column_Extent_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Table_Column_Extent_Reply_Queued :=
           Table_Column_Extent_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Column_Extent_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Column_Extent_Reply_Packet, Result);
         Table_Column_Extent_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Column_Extent_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Column_Extent_Reply_Serialized then
         Table_Column_Extent_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Column_Extent_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Column_Extent_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Table_Column_Extent_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Column_Extent_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Column_Extent_Reply_Envelope.Reply_Serial = 136
           and then Table_Column_Extent_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Table_Column_Extent_Value = 3;
      end if;

      if Table_Column_Extent_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Table_Column_Extent_Reply_Packet.Metadata.Serial,
            Result);
         Table_Column_Extent_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Column_Extent_Reply_Bookkeeping_Drained then
         Document_Locale_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Document)),
              Member_Name    => To_Unbounded_String ("GetLocale"),
              Serial         => 137,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Document_Locale_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Document_Locale_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Document_Locale_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Document_Locale_Request_Envelope, Result);
         end if;
         Document_Locale_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Document_Locale_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Document_Locale_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Document_Locale_Request_Packet.Bytes,
            Snapshots.all, Result);
         Document_Locale_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Document_Locale_Reply_Queued :=
           Document_Locale_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Document_Locale_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Document_Locale_Reply_Packet, Result);
         Document_Locale_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Document_Locale_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Document_Locale_Reply_Serialized then
         Document_Locale_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Document_Locale_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Document_Locale_Value :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Document_Locale_Reply_Envelope.Body_Bytes, Result);
         end if;
         Document_Locale_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Document_Locale_Reply_Envelope.Reply_Serial = 137
           and then Document_Locale_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Document_Locale_Value) = "en-US";
      end if;

      if Document_Locale_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Document_Locale_Reply_Packet.Metadata.Serial, Result);
         Document_Locale_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Document_Locale_Reply_Bookkeeping_Drained then
         Document_Landmark_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Document)),
              Member_Name    => To_Unbounded_String ("IsLandmark"),
              Serial         => 138,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Document_Landmark_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Document_Landmark_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Document_Landmark_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Document_Landmark_Request_Envelope, Result);
         end if;
         Document_Landmark_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Document_Landmark_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Document_Landmark_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Document_Landmark_Request_Packet.Bytes,
            Snapshots.all, Result);
         Document_Landmark_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Document_Landmark_Reply_Queued :=
           Document_Landmark_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Document_Landmark_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Document_Landmark_Reply_Packet, Result);
         Document_Landmark_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Document_Landmark_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Document_Landmark_Reply_Serialized then
         Document_Landmark_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Document_Landmark_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Document_Landmark_Value :=
              A11y.Linux.DBus_Messages.Decode_Boolean_Body
                (Document_Landmark_Reply_Envelope.Body_Bytes, Result);
         end if;
         Document_Landmark_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Document_Landmark_Reply_Envelope.Reply_Serial = 138
           and then Document_Landmark_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("b")
           and then Document_Landmark_Value;
      end if;

      if Document_Landmark_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Document_Landmark_Reply_Packet.Metadata.Serial,
            Result);
         Document_Landmark_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Document_Landmark_Reply_Bookkeeping_Drained then
         Document_Title_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call_String
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Document)),
              Member_Name    => To_Unbounded_String ("GetAttributeValue"),
              Argument       => To_Unbounded_String ("title"),
              Serial         => 139,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Document_Title_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Document_Title_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Document_Title_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Document_Title_Request_Envelope, Result);
         end if;
         Document_Title_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Document_Title_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Document_Title_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all, Document_Title_Request_Packet.Bytes,
            Snapshots.all, Result);
         Document_Title_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Document_Title_Reply_Queued :=
           Document_Title_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Document_Title_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Document_Title_Reply_Packet, Result);
         Document_Title_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Document_Title_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Document_Title_Reply_Serialized then
         Document_Title_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Document_Title_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Document_Title_Value :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Document_Title_Reply_Envelope.Body_Bytes, Result);
         end if;
         Document_Title_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Document_Title_Reply_Envelope.Reply_Serial = 139
           and then Document_Title_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("s")
           and then To_String (Document_Title_Value) = "Fixture Document";
      end if;

      if Document_Title_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Document_Title_Reply_Packet.Metadata.Serial, Result);
         Document_Title_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Document_Title_Reply_Bookkeeping_Drained then
         Table_Current_Cell_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetCurrentCell"),
              Serial         => 150,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Current_Cell_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Current_Cell_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Current_Cell_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Current_Cell_Request_Envelope, Result);
         end if;
         Table_Current_Cell_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Current_Cell_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Current_Cell_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all,
            Table_Current_Cell_Request_Packet.Bytes, Snapshots.all, Result);
         Table_Current_Cell_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Table_Current_Cell_Reply_Queued :=
           Table_Current_Cell_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Current_Cell_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Current_Cell_Reply_Packet, Result);
         Table_Current_Cell_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Current_Cell_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Current_Cell_Reply_Serialized then
         Table_Current_Cell_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Current_Cell_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Current_Cell_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Table_Current_Cell_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Current_Cell_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Current_Cell_Reply_Envelope.Reply_Serial = 150
           and then Table_Current_Cell_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Table_Current_Cell_Path = Table_Cell_Object_Path;
      end if;

      if Table_Current_Cell_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all,
            Table_Current_Cell_Reply_Packet.Metadata.Serial,
            Result);
         Table_Current_Cell_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Current_Cell_Reply_Bookkeeping_Drained then
         Table_Sort_Order_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetSortOrder"),
              Serial         => 151,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Sort_Order_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Sort_Order_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Sort_Order_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Sort_Order_Request_Envelope, Result);
         end if;
         Table_Sort_Order_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Sort_Order_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Sort_Order_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all,
            Table_Sort_Order_Request_Packet.Bytes, Snapshots.all, Result);
         Table_Sort_Order_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Table_Sort_Order_Reply_Queued :=
           Table_Sort_Order_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Sort_Order_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Sort_Order_Reply_Packet, Result);
         Table_Sort_Order_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Sort_Order_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Sort_Order_Reply_Serialized then
         Table_Sort_Order_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Sort_Order_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Sort_Order_Value :=
              A11y.Linux.DBus_Messages.Decode_UInt32_Body
                (Table_Sort_Order_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Sort_Order_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Sort_Order_Reply_Envelope.Reply_Serial = 151
           and then Table_Sort_Order_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("u")
           and then Table_Sort_Order_Value = A11y.Tables.Sort_Order'Pos
             (A11y.Tables.Descending);
      end if;

      if Table_Sort_Order_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all,
            Table_Sort_Order_Reply_Packet.Metadata.Serial,
            Result);
         Table_Sort_Order_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Sort_Order_Reply_Bookkeeping_Drained then
         Table_Sort_Key_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name => To_Unbounded_String
                (A11y.Linux.ATSPi_Objects.Interface_Name
                   (A11y.Linux.ATSPi_Objects.Table)),
              Member_Name    => To_Unbounded_String ("GetSortKey"),
              Serial         => 152,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Table_Sort_Key_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Table_Sort_Key_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Table_Sort_Key_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Table_Sort_Key_Request_Envelope, Result);
         end if;
         Table_Sort_Key_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Sort_Key_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Table_Sort_Key_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Handle_Incoming_Registered_Packet
           (Context.all, Registry.all,
            Table_Sort_Key_Request_Packet.Bytes, Snapshots.all, Result);
         Table_Sort_Key_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Table_Sort_Key_Reply_Queued :=
           Table_Sort_Key_Packet_Dispatched
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Sort_Key_Reply_Queued then
         A11y.Linux.ATSPi_Bus.Send_Next_Transport_Packet
           (Context.all, Table_Sort_Key_Reply_Packet, Result);
         Table_Sort_Key_Reply_Serialized :=
           A11y.Results.Succeeded (Result)
           and then Table_Sort_Key_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return
           and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
             (Context.all) = 0
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 1;
      end if;

      if Table_Sort_Key_Reply_Serialized then
         Table_Sort_Key_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Method_Return
             (Table_Sort_Key_Reply_Packet.Bytes, Result);
         if A11y.Results.Succeeded (Result) then
            Table_Sort_Key_Path :=
              A11y.Linux.DBus_Messages.Decode_String_Body
                (Table_Sort_Key_Reply_Envelope.Body_Bytes, Result);
         end if;
         Table_Sort_Key_Reply_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Table_Sort_Key_Reply_Envelope.Reply_Serial = 152
           and then Table_Sort_Key_Reply_Envelope.Body_Signature =
             To_Unbounded_String ("o")
           and then Table_Sort_Key_Path = Table_Cell_Object_Path;
      end if;

      if Table_Sort_Key_Reply_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all,
            Table_Sort_Key_Reply_Packet.Metadata.Serial,
            Result);
         Table_Sort_Key_Reply_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Table_Sort_Key_Reply_Bookkeeping_Drained then
         Stale_Object_Path := Second_Child_Object_Path;
         Stale_Path_Built := Length (Stale_Object_Path) /= 0;
      end if;

      if Stale_Path_Built then
         Stale_Request_Message := A11y.Linux.DBus_Messages.Build_Method_Call
           (Object_Path    => Stale_Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Accessible)),
            Member_Name    => To_Unbounded_String ("GetName"),
            Serial         => 153,
            Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Stale_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Stale_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Stale_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Stale_Request_Envelope, Result);
         end if;
         Stale_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Stale_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Stale_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
           (Context.all,
            Registry.all,
            Stale_Request_Packet.Bytes,
            Snapshots.all,
            Stale_Reply_Packet,
            Stale_Serve_Report,
            Result);
         Stale_Packet_Dispatched := A11y.Results.Succeeded (Result);
         Stale_Error_Queued :=
           Stale_Packet_Dispatched
           and then Stale_Serve_Report.Reply_Queued
           and then Stale_Serve_Report.Registry_Drained
           and then Stale_Serve_Report.Status = A11y.Results.Success;
         Stale_Error_Serialized :=
           Stale_Error_Queued
           and then Stale_Serve_Report.Reply_Serialized
           and then Stale_Serve_Report.Reply_In_Flight
           and then Stale_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Error_Return;
         Stale_Error_In_Flight := Stale_Serve_Report.Reply_In_Flight;
      end if;

      if Stale_Error_Serialized then
         Stale_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Error_Return
             (Stale_Reply_Packet.Bytes, Result);
         Stale_Error_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Stale_Reply_Envelope.Reply_Serial = 153
           and then To_String (Stale_Reply_Envelope.Error_Name) =
             A11y.Linux.ATSPi_Objects.Error_Name
               (A11y.Results.Node_Unavailable)
           and then A11y.Linux.ATSPi_Objects.Status_For_Error_Name
             (To_String (Stale_Reply_Envelope.Error_Name)) =
               A11y.Results.Node_Unavailable;
      end if;

      if Stale_Error_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all, Stale_Reply_Packet.Metadata.Serial, Result);
         Stale_Error_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Stale_Error_Bookkeeping_Drained then
         Unsupported_Interface_Request_Message :=
           A11y.Linux.DBus_Messages.Build_Method_Call
             (Object_Path    => Object_Path,
              Interface_Name =>
                To_Unbounded_String ("org.a11y.atspi.UnknownInterface"),
              Member_Name    => To_Unbounded_String ("GetName"),
              Serial         => 154,
              Result         => Result);
         if A11y.Results.Succeeded (Result) then
            Unsupported_Interface_Request_Envelope :=
              A11y.Linux.DBus_Messages.Build_Transport_Envelope
                (Unsupported_Interface_Request_Message, Result);
         end if;
         if A11y.Results.Succeeded (Result) then
            Unsupported_Interface_Request_Packet :=
              A11y.Linux.DBus_Messages.Build_Transport_Packet
                (Unsupported_Interface_Request_Envelope, Result);
         end if;
         Unsupported_Interface_Method_Call_Encoded :=
           A11y.Results.Succeeded (Result)
           and then Unsupported_Interface_Request_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Call;
      end if;

      if Unsupported_Interface_Method_Call_Encoded then
         A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
           (Context.all,
            Registry.all,
            Unsupported_Interface_Request_Packet.Bytes,
            Snapshots.all,
            Unsupported_Interface_Reply_Packet,
            Unsupported_Interface_Serve_Report,
            Result);
         Unsupported_Interface_Packet_Dispatched :=
           A11y.Results.Succeeded (Result);
         Unsupported_Interface_Error_Queued :=
           Unsupported_Interface_Packet_Dispatched
           and then Unsupported_Interface_Serve_Report.Reply_Queued
           and then Unsupported_Interface_Serve_Report.Registry_Drained
           and then Unsupported_Interface_Serve_Report.Status =
             A11y.Results.Success;
         Unsupported_Interface_Error_Serialized :=
           Unsupported_Interface_Error_Queued
           and then Unsupported_Interface_Serve_Report.Reply_Serialized
           and then Unsupported_Interface_Serve_Report.Reply_In_Flight
           and then Unsupported_Interface_Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Error_Return;
         Unsupported_Interface_Error_In_Flight :=
           Unsupported_Interface_Serve_Report.Reply_In_Flight;
      end if;

      if Unsupported_Interface_Error_Serialized then
         Unsupported_Interface_Reply_Envelope :=
           A11y.Linux.DBus_Messages.Decode_Error_Return
             (Unsupported_Interface_Reply_Packet.Bytes, Result);
         Unsupported_Interface_Error_Decoded :=
           A11y.Results.Succeeded (Result)
           and then Unsupported_Interface_Reply_Envelope.Reply_Serial = 154
           and then To_String
             (Unsupported_Interface_Reply_Envelope.Error_Name) =
               A11y.Linux.ATSPi_Objects.Error_Name
                 (A11y.Results.Unsupported_Capability)
           and then A11y.Linux.ATSPi_Objects.Status_For_Error_Name
             (To_String (Unsupported_Interface_Reply_Envelope.Error_Name)) =
               A11y.Results.Unsupported_Capability;
      end if;

      if Unsupported_Interface_Error_Decoded then
         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context.all,
            Unsupported_Interface_Reply_Packet.Metadata.Serial,
            Result);
         Unsupported_Interface_Error_Bookkeeping_Drained :=
           A11y.Results.Succeeded (Result)
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Unsupported_Interface_Error_Bookkeeping_Drained then
         A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
           (Context.all,
            Registry.all,
            To_Unbounded_String ("malformed"),
            Snapshots.all,
            Unsupported_Interface_Reply_Packet,
            Unsupported_Interface_Serve_Report,
            Result);
         Malformed_Packet_Rejected :=
           A11y.Results.Failed (Result)
           and then Result.Status = A11y.Results.Invalid_Argument
           and then Unsupported_Interface_Serve_Report.Status =
             A11y.Results.Invalid_Argument
           and then not Unsupported_Interface_Serve_Report.Packet_Classified
           and then not Unsupported_Interface_Serve_Report.Incoming_Method_Call
           and then not Unsupported_Interface_Serve_Report.Reply_Queued
           and then not Unsupported_Interface_Serve_Report.Reply_Serialized
           and then not Unsupported_Interface_Serve_Report.Reply_In_Flight
           and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
             (Context.all) = 0;
      end if;

      if Malformed_Packet_Rejected then
         declare
            Constrained_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
              A11y.Resource_Limits.Default_Config;
            Limit_Result : A11y.Results.Result;
         begin
            A11y.Resource_Limits.Set_Limit
              (Constrained_Limits,
               A11y.Resource_Limits.Native_String_Size,
               1,
               Limit_Result);
            if A11y.Results.Succeeded (Limit_Result) then
               Text_Edit_Request_Message :=
                 A11y.Linux.DBus_Messages.Build_Method_Call_UInt32_Pair_String
                   (Object_Path     => Object_Path,
                    Interface_Name  => To_Unbounded_String
                      (A11y.Linux.ATSPi_Objects.Interface_Name
                         (A11y.Linux.ATSPi_Objects.Editable_Text)),
                    Member_Name     => To_Unbounded_String ("InsertText"),
                    First_Argument  => 1,
                    Second_Argument => 0,
                    Text_Argument   => To_Unbounded_String ("XX"),
                    Serial          => 155,
                    Result          => Result);
            end if;
            if A11y.Results.Succeeded (Limit_Result)
              and then A11y.Results.Succeeded (Result)
            then
               Text_Edit_Request_Envelope :=
                 A11y.Linux.DBus_Messages.Build_Transport_Envelope
                   (Text_Edit_Request_Message, Result);
            end if;
            if A11y.Results.Succeeded (Limit_Result)
              and then A11y.Results.Succeeded (Result)
            then
               Text_Edit_Request_Packet :=
                 A11y.Linux.DBus_Messages.Build_Transport_Packet
                   (Text_Edit_Request_Envelope, Result);
            end if;
            if A11y.Results.Succeeded (Limit_Result)
              and then A11y.Results.Succeeded (Result)
            then
               A11y.Linux.ATSPi_Bus.Serve_Incoming_Registered_Packet
                 (Context.all,
                  Registry.all,
                  Text_Edit_Request_Packet.Bytes,
                  Snapshots.all,
                  Constrained_Limits,
                  Text_Edit_Reply_Packet,
                  Unsupported_Interface_Serve_Report,
                  Result);
               Oversized_Text_Payload_Rejected :=
                 A11y.Results.Failed (Result)
                 and then Result.Status = A11y.Results.Resource_Limit
                 and then Unsupported_Interface_Serve_Report.Status =
                   A11y.Results.Resource_Limit
                 and then not Unsupported_Interface_Serve_Report.Reply_Queued
                 and then not Unsupported_Interface_Serve_Report.Reply_Serialized
                 and then not Unsupported_Interface_Serve_Report.Reply_In_Flight
                 and then A11y.Linux.ATSPi_Bus.Pending_Outgoing_Count
                   (Context.all) = 0
                 and then A11y.Linux.ATSPi_Bus.In_Flight_Outgoing_Count
                   (Context.all) = 0;
            end if;
         end;
      end if;

      Accessible_Tree_Traversal_Completed :=
        Child_Count_Method_Call_Encoded
        and then Child_Count_Packet_Dispatched
        and then Child_Count_Reply_Queued
        and then Child_Count_Reply_Serialized
        and then Child_Count_Reply_Decoded
        and then Child_Count_Reply_Bookkeeping_Drained
        and then Child_At_Method_Call_Encoded
        and then Child_At_Packet_Dispatched
        and then Child_At_Reply_Queued
        and then Child_At_Reply_Serialized
        and then Child_At_Reply_Decoded
        and then Child_At_Reply_Bookkeeping_Drained
        and then Children_Method_Call_Encoded
        and then Children_Packet_Dispatched
        and then Children_Reply_Queued
        and then Children_Reply_Serialized
        and then Children_Reply_Decoded
        and then Children_Reply_Bookkeeping_Drained
        and then Parent_Method_Call_Encoded
        and then Parent_Packet_Dispatched
        and then Parent_Reply_Queued
        and then Parent_Reply_Serialized
        and then Parent_Reply_Decoded
        and then Parent_Reply_Bookkeeping_Drained
        and then Index_Method_Call_Encoded
        and then Index_Packet_Dispatched
        and then Index_Reply_Queued
        and then Index_Reply_Serialized
        and then Index_Reply_Decoded
        and then Index_Reply_Bookkeeping_Drained;

      Serving_Path_Completed :=
        Context_Prepared
        and then Context_Admitted
        and then Context_Registered
        and then Object_Path_Built
        and then Object_Registered
        and then Method_Call_Encoded
        and then Packet_Dispatched
        and then Registry_Drained
        and then Reply_Queued
        and then Reply_Serialized
        and then Reply_In_Flight
        and then Reply_Decoded
        and then Reply_Bookkeeping_Drained
        and then Application_Id_Method_Call_Encoded
        and then Application_Id_Packet_Dispatched
        and then Application_Id_Reply_Queued
        and then Application_Id_Reply_Serialized
        and then Application_Id_Reply_Decoded
        and then Application_Id_Reply_Bookkeeping_Drained
        and then Property_Name_Method_Call_Encoded
        and then Property_Name_Packet_Dispatched
        and then Property_Name_Reply_Queued
        and then Property_Name_Reply_Serialized
        and then Property_Name_Reply_Decoded
        and then Property_Name_Reply_Bookkeeping_Drained
        and then Property_Map_Method_Call_Encoded
        and then Property_Map_Packet_Dispatched
        and then Property_Map_Reply_Queued
        and then Property_Map_Reply_Serialized
        and then Property_Map_Reply_Decoded
        and then Property_Map_Reply_Bookkeeping_Drained
        and then Role_Method_Call_Encoded
        and then Role_Packet_Dispatched
        and then Role_Reply_Queued
        and then Role_Reply_Serialized
        and then Role_Reply_Decoded
        and then Role_Reply_Bookkeeping_Drained
        and then State_Method_Call_Encoded
        and then State_Packet_Dispatched
        and then State_Reply_Queued
        and then State_Reply_Serialized
        and then State_Reply_Decoded
        and then State_Reply_Bookkeeping_Drained
        and then Interfaces_Method_Call_Encoded
        and then Interfaces_Packet_Dispatched
        and then Interfaces_Reply_Queued
        and then Interfaces_Reply_Serialized
        and then Interfaces_Reply_Decoded
        and then Interfaces_Reply_Bookkeeping_Drained
        and then Action_Count_Method_Call_Encoded
        and then Action_Count_Packet_Dispatched
        and then Action_Count_Reply_Queued
        and then Action_Count_Reply_Serialized
        and then Action_Count_Reply_Decoded
        and then Action_Count_Reply_Bookkeeping_Drained
        and then Action_Name_Method_Call_Encoded
        and then Action_Name_Packet_Dispatched
        and then Action_Name_Reply_Queued
        and then Action_Name_Reply_Serialized
        and then Action_Name_Reply_Decoded
        and then Action_Name_Reply_Bookkeeping_Drained
        and then Action_Invoke_Method_Call_Encoded
        and then Action_Invoke_Packet_Dispatched
        and then Action_Invoke_Reply_Queued
        and then Action_Invoke_Reply_Serialized
        and then Action_Invoke_Reply_Decoded
        and then Action_Invoke_Reply_Bookkeeping_Drained
        and then Component_Extents_Method_Call_Encoded
        and then Component_Extents_Packet_Dispatched
        and then Component_Extents_Reply_Queued
        and then Component_Extents_Reply_Serialized
        and then Component_Extents_Reply_Decoded
        and then Component_Extents_Reply_Bookkeeping_Drained
        and then Component_Contains_Method_Call_Encoded
        and then Component_Contains_Packet_Dispatched
        and then Component_Contains_Reply_Queued
        and then Component_Contains_Reply_Serialized
        and then Component_Contains_Reply_Decoded
        and then Component_Contains_Reply_Bookkeeping_Drained
        and then Component_Hit_Method_Call_Encoded
        and then Component_Hit_Packet_Dispatched
        and then Component_Hit_Reply_Queued
        and then Component_Hit_Reply_Serialized
        and then Component_Hit_Reply_Decoded
        and then Component_Hit_Reply_Bookkeeping_Drained
        and then Component_Focus_Method_Call_Encoded
        and then Component_Focus_Packet_Dispatched
        and then Component_Focus_Reply_Queued
        and then Component_Focus_Reply_Serialized
        and then Component_Focus_Reply_Decoded
        and then Component_Focus_Reply_Bookkeeping_Drained
        and then Value_Current_Method_Call_Encoded
        and then Value_Current_Packet_Dispatched
        and then Value_Current_Reply_Queued
        and then Value_Current_Reply_Serialized
        and then Value_Current_Reply_Decoded
        and then Value_Current_Reply_Bookkeeping_Drained
        and then Value_Minimum_Method_Call_Encoded
        and then Value_Minimum_Packet_Dispatched
        and then Value_Minimum_Reply_Queued
        and then Value_Minimum_Reply_Serialized
        and then Value_Minimum_Reply_Decoded
        and then Value_Minimum_Reply_Bookkeeping_Drained
        and then Value_Maximum_Method_Call_Encoded
        and then Value_Maximum_Packet_Dispatched
        and then Value_Maximum_Reply_Queued
        and then Value_Maximum_Reply_Serialized
        and then Value_Maximum_Reply_Decoded
        and then Value_Maximum_Reply_Bookkeeping_Drained
        and then Value_Increment_Method_Call_Encoded
        and then Value_Increment_Packet_Dispatched
        and then Value_Increment_Reply_Queued
        and then Value_Increment_Reply_Serialized
        and then Value_Increment_Reply_Decoded
        and then Value_Increment_Reply_Bookkeeping_Drained
        and then Value_Set_Method_Call_Encoded
        and then Value_Set_Packet_Dispatched
        and then Value_Set_Reply_Queued
        and then Value_Set_Reply_Serialized
        and then Value_Set_Reply_Decoded
        and then Value_Set_Reply_Bookkeeping_Drained
        and then Selection_Count_Method_Call_Encoded
        and then Selection_Count_Packet_Dispatched
        and then Selection_Count_Reply_Queued
        and then Selection_Count_Reply_Serialized
        and then Selection_Count_Reply_Decoded
        and then Selection_Count_Reply_Bookkeeping_Drained
        and then Selection_Selected_Method_Call_Encoded
        and then Selection_Selected_Packet_Dispatched
        and then Selection_Selected_Reply_Queued
        and then Selection_Selected_Reply_Serialized
        and then Selection_Selected_Reply_Decoded
        and then Selection_Selected_Reply_Bookkeeping_Drained
        and then Selection_Is_Method_Call_Encoded
        and then Selection_Is_Packet_Dispatched
        and then Selection_Is_Reply_Queued
        and then Selection_Is_Reply_Serialized
        and then Selection_Is_Reply_Decoded
        and then Selection_Is_Reply_Bookkeeping_Drained
        and then Selection_Select_Method_Call_Encoded
        and then Selection_Select_Packet_Dispatched
        and then Selection_Select_Reply_Queued
        and then Selection_Select_Reply_Serialized
        and then Selection_Select_Reply_Decoded
        and then Selection_Select_Reply_Bookkeeping_Drained
        and then Selection_Deselect_Method_Call_Encoded
        and then Selection_Deselect_Packet_Dispatched
        and then Selection_Deselect_Reply_Queued
        and then Selection_Deselect_Reply_Serialized
        and then Selection_Deselect_Reply_Decoded
        and then Selection_Deselect_Reply_Bookkeeping_Drained
        and then Selection_Select_All_Method_Call_Encoded
        and then Selection_Select_All_Packet_Dispatched
        and then Selection_Select_All_Reply_Queued
        and then Selection_Select_All_Reply_Serialized
        and then Selection_Select_All_Reply_Decoded
        and then Selection_Select_All_Reply_Bookkeeping_Drained
        and then Selection_Clear_Method_Call_Encoded
        and then Selection_Clear_Packet_Dispatched
        and then Selection_Clear_Reply_Queued
        and then Selection_Clear_Reply_Serialized
        and then Selection_Clear_Reply_Decoded
        and then Selection_Clear_Reply_Bookkeeping_Drained
        and then Text_Count_Method_Call_Encoded
        and then Text_Count_Packet_Dispatched
        and then Text_Count_Reply_Queued
        and then Text_Count_Reply_Serialized
        and then Text_Count_Reply_Decoded
        and then Text_Count_Reply_Bookkeeping_Drained
        and then Text_Caret_Method_Call_Encoded
        and then Text_Caret_Packet_Dispatched
        and then Text_Caret_Reply_Queued
        and then Text_Caret_Reply_Serialized
        and then Text_Caret_Reply_Decoded
        and then Text_Caret_Reply_Bookkeeping_Drained
        and then Text_Range_Method_Call_Encoded
        and then Text_Range_Packet_Dispatched
        and then Text_Range_Reply_Queued
        and then Text_Range_Reply_Serialized
        and then Text_Range_Reply_Decoded
        and then Text_Range_Reply_Bookkeeping_Drained
        and then Text_Edit_Method_Call_Encoded
        and then Text_Edit_Packet_Dispatched
        and then Text_Edit_Reply_Queued
        and then Text_Edit_Reply_Serialized
        and then Text_Edit_Reply_Decoded
        and then Text_Edit_Reply_Bookkeeping_Drained
        and then Text_Delete_Method_Call_Encoded
        and then Text_Delete_Packet_Dispatched
        and then Text_Delete_Reply_Queued
        and then Text_Delete_Reply_Serialized
        and then Text_Delete_Reply_Decoded
        and then Text_Delete_Reply_Bookkeeping_Drained
        and then Text_Replace_Method_Call_Encoded
        and then Text_Replace_Packet_Dispatched
        and then Text_Replace_Reply_Queued
        and then Text_Replace_Reply_Serialized
        and then Text_Replace_Reply_Decoded
        and then Text_Replace_Reply_Bookkeeping_Drained
        and then Text_Set_Method_Call_Encoded
        and then Text_Set_Packet_Dispatched
        and then Text_Set_Reply_Queued
        and then Text_Set_Reply_Serialized
        and then Text_Set_Reply_Decoded
        and then Text_Set_Reply_Bookkeeping_Drained
        and then Image_Description_Method_Call_Encoded
        and then Image_Description_Packet_Dispatched
        and then Image_Description_Reply_Queued
        and then Image_Description_Reply_Serialized
        and then Image_Description_Reply_Decoded
        and then Image_Description_Reply_Bookkeeping_Drained
        and then Image_Caption_Method_Call_Encoded
        and then Image_Caption_Packet_Dispatched
        and then Image_Caption_Reply_Queued
        and then Image_Caption_Reply_Serialized
        and then Image_Caption_Reply_Decoded
        and then Image_Caption_Reply_Bookkeeping_Drained
        and then Image_Kind_Method_Call_Encoded
        and then Image_Kind_Packet_Dispatched
        and then Image_Kind_Reply_Queued
        and then Image_Kind_Reply_Serialized
        and then Image_Kind_Reply_Decoded
        and then Image_Kind_Reply_Bookkeeping_Drained
        and then Image_Size_Method_Call_Encoded
        and then Image_Size_Packet_Dispatched
        and then Image_Size_Reply_Queued
        and then Image_Size_Reply_Serialized
        and then Image_Size_Reply_Decoded
        and then Image_Size_Reply_Bookkeeping_Drained
        and then Child_Count_Method_Call_Encoded
        and then Child_Count_Packet_Dispatched
        and then Child_Count_Reply_Queued
        and then Child_Count_Reply_Serialized
        and then Child_Count_Reply_Decoded
        and then Child_Count_Reply_Bookkeeping_Drained
        and then Child_At_Method_Call_Encoded
        and then Child_At_Packet_Dispatched
        and then Child_At_Reply_Queued
        and then Child_At_Reply_Serialized
        and then Child_At_Reply_Decoded
        and then Child_At_Reply_Bookkeeping_Drained
        and then Children_Method_Call_Encoded
        and then Children_Packet_Dispatched
        and then Children_Reply_Queued
        and then Children_Reply_Serialized
        and then Children_Reply_Decoded
        and then Children_Reply_Bookkeeping_Drained
        and then Attributes_Method_Call_Encoded
        and then Attributes_Packet_Dispatched
        and then Attributes_Reply_Queued
        and then Attributes_Reply_Serialized
        and then Attributes_Reply_Decoded
        and then Attributes_Reply_Bookkeeping_Drained
        and then Relations_Method_Call_Encoded
        and then Relations_Packet_Dispatched
        and then Relations_Reply_Queued
        and then Relations_Reply_Serialized
        and then Relations_Reply_Decoded
        and then Relations_Reply_Bookkeeping_Drained
        and then Parent_Method_Call_Encoded
        and then Parent_Packet_Dispatched
        and then Parent_Reply_Queued
        and then Parent_Reply_Serialized
        and then Parent_Reply_Decoded
        and then Parent_Reply_Bookkeeping_Drained
        and then Index_Method_Call_Encoded
        and then Index_Packet_Dispatched
        and then Index_Reply_Queued
        and then Index_Reply_Serialized
        and then Index_Reply_Decoded
        and then Index_Reply_Bookkeeping_Drained
        and then Table_Row_Count_Method_Call_Encoded
        and then Table_Row_Count_Packet_Dispatched
        and then Table_Row_Count_Reply_Queued
        and then Table_Row_Count_Reply_Serialized
        and then Table_Row_Count_Reply_Decoded
        and then Table_Row_Count_Reply_Bookkeeping_Drained
        and then Table_Column_Count_Method_Call_Encoded
        and then Table_Column_Count_Packet_Dispatched
        and then Table_Column_Count_Reply_Queued
        and then Table_Column_Count_Reply_Serialized
        and then Table_Column_Count_Reply_Decoded
        and then Table_Column_Count_Reply_Bookkeeping_Drained
        and then Table_Cell_Method_Call_Encoded
        and then Table_Cell_Packet_Dispatched
        and then Table_Cell_Reply_Queued
        and then Table_Cell_Reply_Serialized
        and then Table_Cell_Reply_Decoded
        and then Table_Cell_Reply_Bookkeeping_Drained
        and then Table_Row_Extent_Method_Call_Encoded
        and then Table_Row_Extent_Packet_Dispatched
        and then Table_Row_Extent_Reply_Queued
        and then Table_Row_Extent_Reply_Serialized
        and then Table_Row_Extent_Reply_Decoded
        and then Table_Row_Extent_Reply_Bookkeeping_Drained
        and then Table_Column_Extent_Method_Call_Encoded
        and then Table_Column_Extent_Packet_Dispatched
        and then Table_Column_Extent_Reply_Queued
        and then Table_Column_Extent_Reply_Serialized
        and then Table_Column_Extent_Reply_Decoded
        and then Table_Column_Extent_Reply_Bookkeeping_Drained
        and then Document_Locale_Method_Call_Encoded
        and then Document_Locale_Packet_Dispatched
        and then Document_Locale_Reply_Queued
        and then Document_Locale_Reply_Serialized
        and then Document_Locale_Reply_Decoded
        and then Document_Locale_Reply_Bookkeeping_Drained
        and then Document_Landmark_Method_Call_Encoded
        and then Document_Landmark_Packet_Dispatched
        and then Document_Landmark_Reply_Queued
        and then Document_Landmark_Reply_Serialized
        and then Document_Landmark_Reply_Decoded
        and then Document_Landmark_Reply_Bookkeeping_Drained
        and then Document_Title_Method_Call_Encoded
        and then Document_Title_Packet_Dispatched
        and then Document_Title_Reply_Queued
        and then Document_Title_Reply_Serialized
        and then Document_Title_Reply_Decoded
        and then Document_Title_Reply_Bookkeeping_Drained
        and then Table_Current_Cell_Method_Call_Encoded
        and then Table_Current_Cell_Packet_Dispatched
        and then Table_Current_Cell_Reply_Queued
        and then Table_Current_Cell_Reply_Serialized
        and then Table_Current_Cell_Reply_Decoded
        and then Table_Current_Cell_Reply_Bookkeeping_Drained
        and then Table_Sort_Order_Method_Call_Encoded
        and then Table_Sort_Order_Packet_Dispatched
        and then Table_Sort_Order_Reply_Queued
        and then Table_Sort_Order_Reply_Serialized
        and then Table_Sort_Order_Reply_Decoded
        and then Table_Sort_Order_Reply_Bookkeeping_Drained
        and then Table_Sort_Key_Method_Call_Encoded
        and then Table_Sort_Key_Packet_Dispatched
        and then Table_Sort_Key_Reply_Queued
        and then Table_Sort_Key_Reply_Serialized
        and then Table_Sort_Key_Reply_Decoded
        and then Table_Sort_Key_Reply_Bookkeeping_Drained
        and then Stale_Path_Built
        and then Stale_Method_Call_Encoded
        and then Stale_Packet_Dispatched
        and then Stale_Error_Queued
        and then Stale_Error_Serialized
        and then Stale_Error_In_Flight
        and then Stale_Error_Decoded
        and then Stale_Error_Bookkeeping_Drained
        and then Unsupported_Interface_Method_Call_Encoded
        and then Unsupported_Interface_Packet_Dispatched
        and then Unsupported_Interface_Error_Queued
        and then Unsupported_Interface_Error_Serialized
        and then Unsupported_Interface_Error_In_Flight
        and then Unsupported_Interface_Error_Decoded
        and then Unsupported_Interface_Error_Bookkeeping_Drained
        and then Malformed_Packet_Rejected
        and then Oversized_Text_Payload_Rejected;
      Final_Status :=
        (if Serving_Path_Completed then A11y.Results.Success else Result.Status);

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_serving_packet_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""fixture_schema"": " & Q (A11y_Fixture_Application.Schema) & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Linux_ATSPI))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line
        ("  ""context_prepared"": "
         & (if Context_Prepared then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""context_admitted"": "
         & (if Context_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""context_registered"": "
         & (if Context_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_path_built"": "
         & (if Object_Path_Built then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""object_registered"": "
         & (if Object_Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""method_call_encoded"": "
         & (if Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""packet_dispatched"": "
         & (if Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registry_drained"": "
         & (if Registry_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""reply_queued"": "
         & (if Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""reply_serialized"": "
         & (if Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""reply_in_flight"": "
         & (if Reply_In_Flight then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""reply_decoded"": "
         & (if Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""reply_bookkeeping_drained"": "
         & (if Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""application_id_method_call_encoded"": "
         & (if Application_Id_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""application_id_packet_dispatched"": "
         & (if Application_Id_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""application_id_reply_queued"": "
         & (if Application_Id_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""application_id_reply_serialized"": "
         & (if Application_Id_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""application_id_reply_decoded"": "
         & (if Application_Id_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""application_id_reply_bookkeeping_drained"": "
         & (if Application_Id_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_name_method_call_encoded"": "
         & (if Property_Name_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_name_packet_dispatched"": "
         & (if Property_Name_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_name_reply_queued"": "
         & (if Property_Name_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_name_reply_serialized"": "
         & (if Property_Name_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_name_reply_decoded"": "
         & (if Property_Name_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_name_reply_bookkeeping_drained"": "
         & (if Property_Name_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_map_method_call_encoded"": "
         & (if Property_Map_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_map_packet_dispatched"": "
         & (if Property_Map_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_map_reply_queued"": "
         & (if Property_Map_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_map_reply_serialized"": "
         & (if Property_Map_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_map_reply_decoded"": "
         & (if Property_Map_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""property_map_reply_bookkeeping_drained"": "
         & (if Property_Map_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""role_method_call_encoded"": "
         & (if Role_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""role_packet_dispatched"": "
         & (if Role_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""role_reply_queued"": "
         & (if Role_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""role_reply_serialized"": "
         & (if Role_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""role_reply_decoded"": "
         & (if Role_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""role_reply_bookkeeping_drained"": "
         & (if Role_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state_method_call_encoded"": "
         & (if State_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state_packet_dispatched"": "
         & (if State_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state_reply_queued"": "
         & (if State_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state_reply_serialized"": "
         & (if State_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state_reply_decoded"": "
         & (if State_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state_reply_bookkeeping_drained"": "
         & (if State_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""interfaces_method_call_encoded"": "
         & (if Interfaces_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""interfaces_packet_dispatched"": "
         & (if Interfaces_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""interfaces_reply_queued"": "
         & (if Interfaces_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""interfaces_reply_serialized"": "
         & (if Interfaces_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""interfaces_reply_decoded"": "
         & (if Interfaces_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""interfaces_reply_bookkeeping_drained"": "
         & (if Interfaces_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_count_method_call_encoded"": "
         & (if Action_Count_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_count_packet_dispatched"": "
         & (if Action_Count_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_count_reply_queued"": "
         & (if Action_Count_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_count_reply_serialized"": "
         & (if Action_Count_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_count_reply_decoded"": "
         & (if Action_Count_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_count_reply_bookkeeping_drained"": "
         & (if Action_Count_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_name_method_call_encoded"": "
         & (if Action_Name_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_name_packet_dispatched"": "
         & (if Action_Name_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_name_reply_queued"": "
         & (if Action_Name_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_name_reply_serialized"": "
         & (if Action_Name_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_name_reply_decoded"": "
         & (if Action_Name_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_name_reply_bookkeeping_drained"": "
         & (if Action_Name_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_invoke_method_call_encoded"": "
         & (if Action_Invoke_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_invoke_packet_dispatched"": "
         & (if Action_Invoke_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_invoke_reply_queued"": "
         & (if Action_Invoke_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_invoke_reply_serialized"": "
         & (if Action_Invoke_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_invoke_reply_decoded"": "
         & (if Action_Invoke_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""action_invoke_reply_bookkeeping_drained"": "
         & (if Action_Invoke_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_extents_method_call_encoded"": "
         & (if Component_Extents_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_extents_packet_dispatched"": "
         & (if Component_Extents_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_extents_reply_queued"": "
         & (if Component_Extents_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_extents_reply_serialized"": "
         & (if Component_Extents_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_extents_reply_decoded"": "
         & (if Component_Extents_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_extents_reply_bookkeeping_drained"": "
         & (if Component_Extents_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_contains_method_call_encoded"": "
         & (if Component_Contains_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_contains_packet_dispatched"": "
         & (if Component_Contains_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_contains_reply_queued"": "
         & (if Component_Contains_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_contains_reply_serialized"": "
         & (if Component_Contains_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_contains_reply_decoded"": "
         & (if Component_Contains_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_contains_reply_bookkeeping_drained"": "
         & (if Component_Contains_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_hit_method_call_encoded"": "
         & (if Component_Hit_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_hit_packet_dispatched"": "
         & (if Component_Hit_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_hit_reply_queued"": "
         & (if Component_Hit_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_hit_reply_serialized"": "
         & (if Component_Hit_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_hit_reply_decoded"": "
         & (if Component_Hit_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_hit_reply_bookkeeping_drained"": "
         & (if Component_Hit_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_focus_method_call_encoded"": "
         & (if Component_Focus_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_focus_packet_dispatched"": "
         & (if Component_Focus_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_focus_reply_queued"": "
         & (if Component_Focus_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_focus_reply_serialized"": "
         & (if Component_Focus_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_focus_reply_decoded"": "
         & (if Component_Focus_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""component_focus_reply_bookkeeping_drained"": "
         & (if Component_Focus_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_method_call_encoded"": "
         & (if Value_Current_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_packet_dispatched"": "
         & (if Value_Current_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_reply_queued"": "
         & (if Value_Current_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_reply_serialized"": "
         & (if Value_Current_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_reply_decoded"": "
         & (if Value_Current_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_current_reply_bookkeeping_drained"": "
         & (if Value_Current_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_minimum_method_call_encoded"": "
         & (if Value_Minimum_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_minimum_packet_dispatched"": "
         & (if Value_Minimum_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_minimum_reply_queued"": "
         & (if Value_Minimum_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_minimum_reply_serialized"": "
         & (if Value_Minimum_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_minimum_reply_decoded"": "
         & (if Value_Minimum_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_minimum_reply_bookkeeping_drained"": "
         & (if Value_Minimum_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_maximum_method_call_encoded"": "
         & (if Value_Maximum_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_maximum_packet_dispatched"": "
         & (if Value_Maximum_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_maximum_reply_queued"": "
         & (if Value_Maximum_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_maximum_reply_serialized"": "
         & (if Value_Maximum_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_maximum_reply_decoded"": "
         & (if Value_Maximum_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_maximum_reply_bookkeeping_drained"": "
         & (if Value_Maximum_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_increment_method_call_encoded"": "
         & (if Value_Increment_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_increment_packet_dispatched"": "
         & (if Value_Increment_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_increment_reply_queued"": "
         & (if Value_Increment_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_increment_reply_serialized"": "
         & (if Value_Increment_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_increment_reply_decoded"": "
         & (if Value_Increment_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_increment_reply_bookkeeping_drained"": "
         & (if Value_Increment_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_method_call_encoded"": "
         & (if Value_Set_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_packet_dispatched"": "
         & (if Value_Set_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_reply_queued"": "
         & (if Value_Set_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_reply_serialized"": "
         & (if Value_Set_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_reply_decoded"": "
         & (if Value_Set_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""value_set_reply_bookkeeping_drained"": "
         & (if Value_Set_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_method_call_encoded"": "
         & (if Selection_Count_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_packet_dispatched"": "
         & (if Selection_Count_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_reply_queued"": "
         & (if Selection_Count_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_reply_serialized"": "
         & (if Selection_Count_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_reply_decoded"": "
         & (if Selection_Count_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_count_reply_bookkeeping_drained"": "
         & (if Selection_Count_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_selected_method_call_encoded"": "
         & (if Selection_Selected_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_selected_packet_dispatched"": "
         & (if Selection_Selected_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_selected_reply_queued"": "
         & (if Selection_Selected_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_selected_reply_serialized"": "
         & (if Selection_Selected_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_selected_reply_decoded"": "
         & (if Selection_Selected_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_selected_reply_bookkeeping_drained"": "
         & (if Selection_Selected_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_is_method_call_encoded"": "
         & (if Selection_Is_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_is_packet_dispatched"": "
         & (if Selection_Is_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_is_reply_queued"": "
         & (if Selection_Is_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_is_reply_serialized"": "
         & (if Selection_Is_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_is_reply_decoded"": "
         & (if Selection_Is_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_is_reply_bookkeeping_drained"": "
         & (if Selection_Is_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_method_call_encoded"": "
         & (if Selection_Select_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_packet_dispatched"": "
         & (if Selection_Select_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_reply_queued"": "
         & (if Selection_Select_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_reply_serialized"": "
         & (if Selection_Select_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_reply_decoded"": "
         & (if Selection_Select_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_reply_bookkeeping_drained"": "
         & (if Selection_Select_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_deselect_method_call_encoded"": "
         & (if Selection_Deselect_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_deselect_packet_dispatched"": "
         & (if Selection_Deselect_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_deselect_reply_queued"": "
         & (if Selection_Deselect_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_deselect_reply_serialized"": "
         & (if Selection_Deselect_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_deselect_reply_decoded"": "
         & (if Selection_Deselect_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_deselect_reply_bookkeeping_drained"": "
         & (if Selection_Deselect_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_method_call_encoded"": "
         & (if Selection_Select_All_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_packet_dispatched"": "
         & (if Selection_Select_All_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_reply_queued"": "
         & (if Selection_Select_All_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_reply_serialized"": "
         & (if Selection_Select_All_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_reply_decoded"": "
         & (if Selection_Select_All_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_select_all_reply_bookkeeping_drained"": "
         & (if Selection_Select_All_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_method_call_encoded"": "
         & (if Selection_Clear_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_packet_dispatched"": "
         & (if Selection_Clear_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_reply_queued"": "
         & (if Selection_Clear_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_reply_serialized"": "
         & (if Selection_Clear_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_reply_decoded"": "
         & (if Selection_Clear_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""selection_clear_reply_bookkeeping_drained"": "
         & (if Selection_Clear_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_method_call_encoded"": "
         & (if Text_Count_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_packet_dispatched"": "
         & (if Text_Count_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_reply_queued"": "
         & (if Text_Count_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_reply_serialized"": "
         & (if Text_Count_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_reply_decoded"": "
         & (if Text_Count_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_reply_bookkeeping_drained"": "
         & (if Text_Count_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_count_value"": "
         & Trimmed (Natural'Image (Text_Count_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_method_call_encoded"": "
         & (if Text_Caret_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_packet_dispatched"": "
         & (if Text_Caret_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_reply_queued"": "
         & (if Text_Caret_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_reply_serialized"": "
         & (if Text_Caret_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_reply_decoded"": "
         & (if Text_Caret_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_reply_bookkeeping_drained"": "
         & (if Text_Caret_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_value"": "
         & Trimmed (Natural'Image (Text_Caret_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_reply_serial"": "
         & Trimmed (Natural'Image (Text_Caret_Reply_Envelope.Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_caret_reply_signature"": "
         & Q (To_String (Text_Caret_Reply_Envelope.Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_method_call_encoded"": "
         & (if Text_Range_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_packet_dispatched"": "
         & (if Text_Range_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_reply_queued"": "
         & (if Text_Range_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_reply_serialized"": "
         & (if Text_Range_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_reply_decoded"": "
         & (if Text_Range_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_reply_bookkeeping_drained"": "
         & (if Text_Range_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_request_signature"": "
         & Q (To_String (Text_Range_Request_Envelope.Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_range_value"": "
         & Q (To_String (Text_Range_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_method_call_encoded"": "
         & (if Text_Edit_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_packet_dispatched"": "
         & (if Text_Edit_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_reply_queued"": "
         & (if Text_Edit_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_reply_serialized"": "
         & (if Text_Edit_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_reply_decoded"": "
         & (if Text_Edit_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_reply_bookkeeping_drained"": "
         & (if Text_Edit_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_request_signature"": "
         & Q (To_String (Text_Edit_Request_Envelope.Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_edit_value"": "
         & (if Text_Edit_Value then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_method_call_encoded"": "
         & (if Text_Delete_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_packet_dispatched"": "
         & (if Text_Delete_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_reply_queued"": "
         & (if Text_Delete_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_reply_serialized"": "
         & (if Text_Delete_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_reply_decoded"": "
         & (if Text_Delete_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_reply_bookkeeping_drained"": "
         & (if Text_Delete_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_request_signature"": "
         & Q (To_String (Text_Delete_Request_Envelope.Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_delete_value"": "
         & (if Text_Delete_Value then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_method_call_encoded"": "
         & (if Text_Replace_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_packet_dispatched"": "
         & (if Text_Replace_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_reply_queued"": "
         & (if Text_Replace_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_reply_serialized"": "
         & (if Text_Replace_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_reply_decoded"": "
         & (if Text_Replace_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_reply_bookkeeping_drained"": "
         & (if Text_Replace_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_request_signature"": "
         & Q (To_String (Text_Replace_Request_Envelope.Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_replace_value"": "
         & (if Text_Replace_Value then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_method_call_encoded"": "
         & (if Text_Set_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_packet_dispatched"": "
         & (if Text_Set_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_reply_queued"": "
         & (if Text_Set_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_reply_serialized"": "
         & (if Text_Set_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_reply_decoded"": "
         & (if Text_Set_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_reply_bookkeeping_drained"": "
         & (if Text_Set_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_request_signature"": "
         & Q (To_String (Text_Set_Request_Envelope.Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""text_set_value"": "
         & (if Text_Set_Value then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_method_call_encoded"": "
         & (if Image_Description_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_packet_dispatched"": "
         & (if Image_Description_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_reply_queued"": "
         & (if Image_Description_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_reply_serialized"": "
         & (if Image_Description_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_reply_decoded"": "
         & (if Image_Description_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_reply_bookkeeping_drained"": "
         & (if Image_Description_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_description_value"": "
         & Q (To_String (Image_Description_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_method_call_encoded"": "
         & (if Image_Caption_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_packet_dispatched"": "
         & (if Image_Caption_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_reply_queued"": "
         & (if Image_Caption_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_reply_serialized"": "
         & (if Image_Caption_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_reply_decoded"": "
         & (if Image_Caption_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_reply_bookkeeping_drained"": "
         & (if Image_Caption_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_caption_value"": "
         & Q (To_String (Image_Caption_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_method_call_encoded"": "
         & (if Image_Kind_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_packet_dispatched"": "
         & (if Image_Kind_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_reply_queued"": "
         & (if Image_Kind_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_reply_serialized"": "
         & (if Image_Kind_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_reply_decoded"": "
         & (if Image_Kind_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_reply_bookkeeping_drained"": "
         & (if Image_Kind_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_kind_value"": "
         & Q (To_String (Image_Kind_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_method_call_encoded"": "
         & (if Image_Size_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_packet_dispatched"": "
         & (if Image_Size_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_reply_queued"": "
         & (if Image_Size_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_reply_serialized"": "
         & (if Image_Size_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_reply_decoded"": "
         & (if Image_Size_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_reply_bookkeeping_drained"": "
         & (if Image_Size_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_width"": "
         & Trimmed (Natural'Image (Natural (Image_Size_Value.Width)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""image_size_height"": "
         & Trimmed (Natural'Image (Natural (Image_Size_Value.Height)))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_count_method_call_encoded"": "
         & (if Child_Count_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_count_packet_dispatched"": "
         & (if Child_Count_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_count_reply_queued"": "
         & (if Child_Count_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_count_reply_serialized"": "
         & (if Child_Count_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_count_reply_decoded"": "
         & (if Child_Count_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_count_reply_bookkeeping_drained"": "
         & (if Child_Count_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_at_method_call_encoded"": "
         & (if Child_At_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_at_packet_dispatched"": "
         & (if Child_At_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_at_reply_queued"": "
         & (if Child_At_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_at_reply_serialized"": "
         & (if Child_At_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_at_reply_decoded"": "
         & (if Child_At_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""child_at_reply_bookkeeping_drained"": "
         & (if Child_At_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""children_method_call_encoded"": "
         & (if Children_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""children_packet_dispatched"": "
         & (if Children_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""children_reply_queued"": "
         & (if Children_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""children_reply_serialized"": "
         & (if Children_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""children_reply_decoded"": "
         & (if Children_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""children_reply_bookkeeping_drained"": "
         & (if Children_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attributes_method_call_encoded"": "
         & (if Attributes_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attributes_packet_dispatched"": "
         & (if Attributes_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attributes_reply_queued"": "
         & (if Attributes_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attributes_reply_serialized"": "
         & (if Attributes_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attributes_reply_decoded"": "
         & (if Attributes_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""attributes_reply_bookkeeping_drained"": "
         & (if Attributes_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_method_call_encoded"": "
         & (if Relations_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_packet_dispatched"": "
         & (if Relations_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_reply_queued"": "
         & (if Relations_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_reply_serialized"": "
         & (if Relations_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_reply_decoded"": "
         & (if Relations_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""relations_reply_bookkeeping_drained"": "
         & (if Relations_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""parent_method_call_encoded"": "
         & (if Parent_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""parent_packet_dispatched"": "
         & (if Parent_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""parent_reply_queued"": "
         & (if Parent_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""parent_reply_serialized"": "
         & (if Parent_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""parent_reply_decoded"": "
         & (if Parent_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""parent_reply_bookkeeping_drained"": "
         & (if Parent_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""index_method_call_encoded"": "
         & (if Index_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""index_packet_dispatched"": "
         & (if Index_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""index_reply_queued"": "
         & (if Index_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""index_reply_serialized"": "
         & (if Index_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""index_reply_decoded"": "
         & (if Index_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""index_reply_bookkeeping_drained"": "
         & (if Index_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""accessible_tree_traversal_completed"": "
         & (if Accessible_Tree_Traversal_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_method_call_encoded"": "
         & (if Table_Row_Count_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_packet_dispatched"": "
         & (if Table_Row_Count_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_reply_queued"": "
         & (if Table_Row_Count_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_reply_serialized"": "
         & (if Table_Row_Count_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_reply_decoded"": "
         & (if Table_Row_Count_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_reply_bookkeeping_drained"": "
         & (if Table_Row_Count_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_count_value"": "
         & Trimmed (Natural'Image (Table_Row_Count_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_method_call_encoded"": "
         & (if Table_Column_Count_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_packet_dispatched"": "
         & (if Table_Column_Count_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_reply_queued"": "
         & (if Table_Column_Count_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_reply_serialized"": "
         & (if Table_Column_Count_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_reply_decoded"": "
         & (if Table_Column_Count_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_reply_bookkeeping_drained"": "
         & (if Table_Column_Count_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_count_value"": "
         & Trimmed (Natural'Image (Table_Column_Count_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_method_call_encoded"": "
         & (if Table_Cell_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_packet_dispatched"": "
         & (if Table_Cell_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_reply_queued"": "
         & (if Table_Cell_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_reply_serialized"": "
         & (if Table_Cell_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_reply_decoded"": "
         & (if Table_Cell_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_reply_bookkeeping_drained"": "
         & (if Table_Cell_Reply_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_cell_path"": "
         & Q (To_String (Table_Cell_Path))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_method_call_encoded"": "
         & (if Table_Row_Extent_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_packet_dispatched"": "
         & (if Table_Row_Extent_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_reply_queued"": "
         & (if Table_Row_Extent_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_reply_serialized"": "
         & (if Table_Row_Extent_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_reply_decoded"": "
         & (if Table_Row_Extent_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_reply_bookkeeping_drained"": "
         & (if Table_Row_Extent_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_row_extent_value"": "
         & Trimmed (Natural'Image (Table_Row_Extent_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_method_call_encoded"": "
         & (if Table_Column_Extent_Method_Call_Encoded
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_packet_dispatched"": "
         & (if Table_Column_Extent_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_reply_queued"": "
         & (if Table_Column_Extent_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_reply_serialized"": "
         & (if Table_Column_Extent_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_reply_decoded"": "
         & (if Table_Column_Extent_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_reply_bookkeeping_drained"": "
         & (if Table_Column_Extent_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_column_extent_value"": "
         & Trimmed (Natural'Image (Table_Column_Extent_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_method_call_encoded"": "
         & (if Table_Current_Cell_Method_Call_Encoded
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_packet_dispatched"": "
         & (if Table_Current_Cell_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_reply_queued"": "
         & (if Table_Current_Cell_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_reply_serialized"": "
         & (if Table_Current_Cell_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_reply_decoded"": "
         & (if Table_Current_Cell_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_reply_bookkeeping_drained"": "
         & (if Table_Current_Cell_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_current_cell_path"": "
         & Q (To_String (Table_Current_Cell_Path))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_method_call_encoded"": "
         & (if Table_Sort_Order_Method_Call_Encoded
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_packet_dispatched"": "
         & (if Table_Sort_Order_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_reply_queued"": "
         & (if Table_Sort_Order_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_reply_serialized"": "
         & (if Table_Sort_Order_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_reply_decoded"": "
         & (if Table_Sort_Order_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_reply_bookkeeping_drained"": "
         & (if Table_Sort_Order_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_order_value"": "
         & Trimmed (Natural'Image (Table_Sort_Order_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_method_call_encoded"": "
         & (if Table_Sort_Key_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_packet_dispatched"": "
         & (if Table_Sort_Key_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_reply_queued"": "
         & (if Table_Sort_Key_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_reply_serialized"": "
         & (if Table_Sort_Key_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_reply_decoded"": "
         & (if Table_Sort_Key_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_reply_bookkeeping_drained"": "
         & (if Table_Sort_Key_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""table_sort_key_path"": "
         & Q (To_String (Table_Sort_Key_Path))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_method_call_encoded"": "
         & (if Document_Locale_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_packet_dispatched"": "
         & (if Document_Locale_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_reply_queued"": "
         & (if Document_Locale_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_reply_serialized"": "
         & (if Document_Locale_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_reply_decoded"": "
         & (if Document_Locale_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_reply_bookkeeping_drained"": "
         & (if Document_Locale_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_locale_value"": "
         & Q (To_String (Document_Locale_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_method_call_encoded"": "
         & (if Document_Landmark_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_packet_dispatched"": "
         & (if Document_Landmark_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_reply_queued"": "
         & (if Document_Landmark_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_reply_serialized"": "
         & (if Document_Landmark_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_reply_decoded"": "
         & (if Document_Landmark_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_reply_bookkeeping_drained"": "
         & (if Document_Landmark_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_landmark_value"": "
         & (if Document_Landmark_Value then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_method_call_encoded"": "
         & (if Document_Title_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_packet_dispatched"": "
         & (if Document_Title_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_reply_queued"": "
         & (if Document_Title_Reply_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_reply_serialized"": "
         & (if Document_Title_Reply_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_reply_decoded"": "
         & (if Document_Title_Reply_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_reply_bookkeeping_drained"": "
         & (if Document_Title_Reply_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""document_title_value"": "
         & Q (To_String (Document_Title_Value))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_path_built"": "
         & (if Stale_Path_Built then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_method_call_encoded"": "
         & (if Stale_Method_Call_Encoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_packet_dispatched"": "
         & (if Stale_Packet_Dispatched then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_error_queued"": "
         & (if Stale_Error_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_error_serialized"": "
         & (if Stale_Error_Serialized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_error_in_flight"": "
         & (if Stale_Error_In_Flight then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_error_decoded"": "
         & (if Stale_Error_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""stale_error_bookkeeping_drained"": "
         & (if Stale_Error_Bookkeeping_Drained then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_method_call_encoded"": "
         & (if Unsupported_Interface_Method_Call_Encoded
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_packet_dispatched"": "
         & (if Unsupported_Interface_Packet_Dispatched
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_error_queued"": "
         & (if Unsupported_Interface_Error_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_error_serialized"": "
         & (if Unsupported_Interface_Error_Serialized
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_error_in_flight"": "
         & (if Unsupported_Interface_Error_In_Flight
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_error_decoded"": "
         & (if Unsupported_Interface_Error_Decoded then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""unsupported_interface_error_bookkeeping_drained"": "
         & (if Unsupported_Interface_Error_Bookkeeping_Drained
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""malformed_packet_rejected"": "
         & (if Malformed_Packet_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""oversized_text_payload_rejected"": "
         & (if Oversized_Text_Payload_Rejected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""serving_path_completed"": "
         & (if Serving_Path_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": " & Q (Status_Name (Final_Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_serving_packet_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""fixture_schema"": "
            & Q (A11y_Fixture_Application.Schema)
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line ("  ""context_prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""context_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""context_registered"": false,");
         Ada.Text_IO.Put_Line ("  ""object_path_built"": false,");
         Ada.Text_IO.Put_Line ("  ""object_registered"": false,");
         Ada.Text_IO.Put_Line ("  ""method_call_encoded"": false,");
         Ada.Text_IO.Put_Line ("  ""packet_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""registry_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""reply_queued"": false,");
         Ada.Text_IO.Put_Line ("  ""reply_serialized"": false,");
         Ada.Text_IO.Put_Line ("  ""reply_in_flight"": false,");
         Ada.Text_IO.Put_Line ("  ""reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""application_id_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""application_id_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""application_id_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""application_id_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""application_id_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""application_id_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_name_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_name_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_name_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_name_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_name_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_name_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_map_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_map_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_map_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_map_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_map_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""property_map_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""role_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line ("  ""role_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""role_reply_queued"": false,");
         Ada.Text_IO.Put_Line ("  ""role_reply_serialized"": false,");
         Ada.Text_IO.Put_Line ("  ""role_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""role_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""state_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line ("  ""state_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line ("  ""state_reply_queued"": false,");
         Ada.Text_IO.Put_Line ("  ""state_reply_serialized"": false,");
         Ada.Text_IO.Put_Line ("  ""state_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""state_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""interfaces_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""interfaces_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""interfaces_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""interfaces_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""interfaces_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""interfaces_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_count_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_count_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_count_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_count_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_count_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_name_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_name_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_name_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_name_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_name_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_name_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_invoke_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_invoke_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_invoke_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_invoke_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_invoke_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""action_invoke_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_extents_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_extents_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_extents_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_extents_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_extents_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_extents_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_contains_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_contains_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_contains_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_contains_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_contains_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_contains_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_hit_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_hit_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_hit_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_hit_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_hit_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""component_hit_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_current_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_minimum_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_minimum_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_minimum_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_minimum_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_minimum_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_minimum_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_maximum_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_maximum_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_maximum_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_maximum_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_maximum_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_maximum_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_increment_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_increment_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_increment_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_increment_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_increment_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_increment_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_set_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_set_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_set_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_set_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_set_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""value_set_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_count_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_selected_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_selected_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_selected_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_selected_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_selected_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_selected_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_is_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_is_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_is_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_is_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_is_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_is_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_deselect_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_deselect_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_deselect_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_deselect_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_deselect_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_deselect_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_select_all_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""selection_clear_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_count_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_count_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_count_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_count_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_count_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_caret_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_caret_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_caret_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_caret_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_caret_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_caret_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_range_request_signature"": """",");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_request_signature"": """",");
         Ada.Text_IO.Put_Line
           ("  ""text_edit_value"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_request_signature"": """",");
         Ada.Text_IO.Put_Line
           ("  ""text_delete_value"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_request_signature"": """",");
         Ada.Text_IO.Put_Line
           ("  ""text_replace_value"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""text_set_request_signature"": """",");
         Ada.Text_IO.Put_Line
           ("  ""text_set_value"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_description_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_caption_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_caption_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_caption_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_caption_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_caption_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_caption_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_kind_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_kind_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_kind_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_kind_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_kind_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_kind_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_size_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_size_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_size_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_size_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_size_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""image_size_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_count_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_count_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_count_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_count_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_count_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_at_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_at_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_at_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_at_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_at_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""child_at_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""children_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""children_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""children_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""children_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""children_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""children_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attributes_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attributes_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attributes_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attributes_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attributes_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""attributes_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""relations_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""relations_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""relations_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""relations_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""relations_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""relations_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""parent_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""parent_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""parent_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""parent_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""parent_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""parent_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""index_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""index_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""index_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""index_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""index_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""index_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""accessible_tree_traversal_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_count_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_count_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_count_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_count_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_count_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_count_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_count_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_count_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_count_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_count_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_cell_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_cell_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_cell_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_cell_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_cell_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_cell_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_extent_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_extent_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_extent_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_extent_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_extent_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_row_extent_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_extent_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_extent_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_extent_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_extent_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_extent_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""table_column_extent_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_locale_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_locale_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_locale_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_locale_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_locale_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_locale_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_landmark_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_landmark_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_landmark_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_landmark_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_landmark_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_landmark_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_packet_dispatched"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_reply_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_reply_serialized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_reply_decoded"": false,");
         Ada.Text_IO.Put_Line
           ("  ""document_title_reply_bookkeeping_drained"": false,");
         Ada.Text_IO.Put_Line ("  ""stale_error_in_flight"": false,");
         Ada.Text_IO.Put_Line
           ("  ""unsupported_interface_error_in_flight"": false,");
         Ada.Text_IO.Put_Line ("  ""serving_path_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Serving_Packet_Probe;

   procedure Emit_External_Client_Session_Probe
     (Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id;
      Direct_ATSPI_Address : Boolean := False)
   is
      type Backend_Session_Access is access all
        A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      type Session_Report_Access is access all
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      type Session_Startup_Report_Access is access all
        A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report;
      type Snapshot_Bundle_Access is access all
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      type Event_Loop_Report_Access is access all
        A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;
      type Session_Stop_Report_Access is access all
        A11y.Linux.ATSPi_Backend_Sessions.Session_Stop_Report;

      Root : constant A11y.Node_Ids.Node_Id := A11y.Node_Ids.From_Natural (1);
      Provider_Ref : constant Backend_Session_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Provider : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session
        renames Provider_Ref.all;
      Provider_Report_Ref : constant Session_Report_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      Provider_Report : A11y.Linux.ATSPi_Backend_Sessions.Session_Report
        renames Provider_Report_Ref.all;
      Startup_Report_Ref : constant Session_Startup_Report_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report;
      Startup_Report : A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report
        renames Startup_Report_Ref.all;
      Client_Session_Context : A11y.Linux.ATSPi_Bus.Connection_Context;
      Client_Session_Channel : A11y.Linux.ATSPi_Local_Channel.Channel;
      Client_Context : A11y.Linux.ATSPi_Bus.Connection_Context;
      Client_Channel : A11y.Linux.ATSPi_Local_Channel.Channel;
      Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Snapshots_Ref : constant Snapshot_Bundle_Access :=
        new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle
        renames Snapshots_Ref.all;
      Event_Report_Ref : constant Event_Loop_Report_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;
      Event_Report : A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report
        renames Event_Report_Ref.all;
      Stop_Report_Ref : constant Session_Stop_Report_Access :=
        new A11y.Linux.ATSPi_Backend_Sessions.Session_Stop_Report;
      Stop_Report : A11y.Linux.ATSPi_Backend_Sessions.Session_Stop_Report
        renames Stop_Report_Ref.all;
      Request_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Reply_Packet : A11y.Linux.DBus_Messages.Transport_Packet;
      Reply_Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result : A11y.Results.Result := A11y.Results.Ok;
      Step_Result : A11y.Results.Result := A11y.Results.Ok;
      Stop_Result : A11y.Results.Result := A11y.Results.Ok;
      Discovery_Result : A11y.Results.Result := A11y.Results.Ok;
      Provider_Started : Boolean := False;
      Provider_Registered : Boolean := False;
      Provider_Unique_Name : Unbounded_String := Null_Unbounded_String;
      Provider_Unique_Name_Received : Boolean := False;
      Provider_Object_Path_Available : Boolean := False;
      Child_Object_Path_Available : Boolean := False;
      Client_Discovered_Address : Boolean := False;
      Client_Raw_Connected : Boolean := False;
      Client_Hello_Completed : Boolean := False;
      Request_Encoded : Boolean := False;
      Request_Sent : Boolean := False;
      Provider_Event_Loop_Driven : Boolean := False;
      Provider_Dispatched_Request : Boolean := False;
      Provider_Wrote_Reply : Boolean := False;
      Client_Reply_Received : Boolean := False;
      Client_Reply_Decoded : Boolean := False;
      Client_Reply_Name_Matched : Boolean := False;
      Client_Role_Reply_Decoded : Boolean := False;
      Client_Role_Matched : Boolean := False;
      Client_Child_Count_Reply_Decoded : Boolean := False;
      Client_Child_Count_Matched : Boolean := False;
      Client_Child_At_Reply_Decoded : Boolean := False;
      Client_Child_At_Matched : Boolean := False;
      Client_Child_Name_Reply_Decoded : Boolean := False;
      Client_Child_Name_Matched : Boolean := False;
      Client_Child_Role_Reply_Decoded : Boolean := False;
      Client_Child_Role_Matched : Boolean := False;
      Client_Child_Description_Reply_Decoded : Boolean := False;
      Client_Child_Description_Matched : Boolean := False;
      Client_Child_Attributes_Reply_Decoded : Boolean := False;
      Client_Child_Attributes_Matched : Boolean := False;
      Client_Child_Relations_Reply_Decoded : Boolean := False;
      Client_Child_Relations_Matched : Boolean := False;
      Client_Protected_Attributes_Reply_Decoded : Boolean := False;
      Client_Protected_Value_Suppressed : Boolean := False;
      Client_Component_Extents_Reply_Decoded : Boolean := False;
      Client_Component_Extents_Matched : Boolean := False;
      Client_Component_Contains_Reply_Decoded : Boolean := False;
      Client_Component_Contains_Matched : Boolean := False;
      Client_Component_Hit_Reply_Decoded : Boolean := False;
      Client_Component_Hit_Matched : Boolean := False;
      Client_Action_Count_Reply_Decoded : Boolean := False;
      Client_Action_Count_Matched : Boolean := False;
      Client_Action_Name_Reply_Decoded : Boolean := False;
      Client_Action_Name_Matched : Boolean := False;
      Client_Action_Invoke_Reply_Decoded : Boolean := False;
      Client_Action_Invoke_Matched : Boolean := False;
      Client_Value_Current_Reply_Decoded : Boolean := False;
      Client_Value_Current_Matched : Boolean := False;
      Client_Value_Minimum_Reply_Decoded : Boolean := False;
      Client_Value_Minimum_Matched : Boolean := False;
      Client_Value_Maximum_Reply_Decoded : Boolean := False;
      Client_Value_Maximum_Matched : Boolean := False;
      Client_Value_Increment_Reply_Decoded : Boolean := False;
      Client_Value_Increment_Matched : Boolean := False;
      Client_Value_Set_Reply_Decoded : Boolean := False;
      Client_Value_Set_Matched : Boolean := False;
      Client_Selection_Count_Reply_Decoded : Boolean := False;
      Client_Selection_Count_Matched : Boolean := False;
      Client_Selection_Selected_Reply_Decoded : Boolean := False;
      Client_Selection_Selected_Matched : Boolean := False;
      Client_Selection_Is_Reply_Decoded : Boolean := False;
      Client_Selection_Is_Matched : Boolean := False;
      Client_Selection_Select_Reply_Decoded : Boolean := False;
      Client_Selection_Select_Matched : Boolean := False;
      Client_Selection_Deselect_Reply_Decoded : Boolean := False;
      Client_Selection_Deselect_Matched : Boolean := False;
      Client_Selection_Select_All_Reply_Decoded : Boolean := False;
      Client_Selection_Select_All_Matched : Boolean := False;
      Client_Selection_Clear_Reply_Decoded : Boolean := False;
      Client_Selection_Clear_Matched : Boolean := False;
      Client_Text_Count_Reply_Decoded : Boolean := False;
      Client_Text_Count_Matched : Boolean := False;
      Client_Text_Caret_Reply_Decoded : Boolean := False;
      Client_Text_Caret_Matched : Boolean := False;
      Client_Text_Range_Reply_Decoded : Boolean := False;
      Client_Text_Range_Matched : Boolean := False;
      Client_Image_Description_Reply_Decoded : Boolean := False;
      Client_Image_Description_Matched : Boolean := False;
      Client_Image_Caption_Reply_Decoded : Boolean := False;
      Client_Image_Caption_Matched : Boolean := False;
      Client_Image_Kind_Reply_Decoded : Boolean := False;
      Client_Image_Kind_Matched : Boolean := False;
      Client_Image_Size_Reply_Decoded : Boolean := False;
      Client_Image_Size_Matched : Boolean := False;
      Client_Document_Locale_Reply_Decoded : Boolean := False;
      Client_Document_Locale_Matched : Boolean := False;
      Client_Document_Landmark_Reply_Decoded : Boolean := False;
      Client_Document_Landmark_Matched : Boolean := False;
      Client_Document_Title_Reply_Decoded : Boolean := False;
      Client_Document_Title_Matched : Boolean := False;
      Client_Table_Row_Count_Reply_Decoded : Boolean := False;
      Client_Table_Row_Count_Matched : Boolean := False;
      Client_Table_Column_Count_Reply_Decoded : Boolean := False;
      Client_Table_Column_Count_Matched : Boolean := False;
      Client_Table_Cell_Reply_Decoded : Boolean := False;
      Client_Table_Cell_Matched : Boolean := False;
      Client_Table_Row_Extent_Reply_Decoded : Boolean := False;
      Client_Table_Row_Extent_Matched : Boolean := False;
      Client_Table_Column_Extent_Reply_Decoded : Boolean := False;
      Client_Table_Column_Extent_Matched : Boolean := False;
      Client_Table_Current_Cell_Reply_Decoded : Boolean := False;
      Client_Table_Current_Cell_Matched : Boolean := False;
      Client_Table_Sort_Order_Reply_Decoded : Boolean := False;
      Client_Table_Sort_Order_Matched : Boolean := False;
      Client_Table_Sort_Key_Reply_Decoded : Boolean := False;
      Client_Table_Sort_Key_Matched : Boolean := False;
      Client_Surface_Kind_Reply_Decoded : Boolean := False;
      Client_Surface_Kind_Matched : Boolean := False;
      Client_Surface_Role_Reply_Decoded : Boolean := False;
      Client_Surface_Role_Matched : Boolean := False;
      Client_Surface_Top_Level_Reply_Decoded : Boolean := False;
      Client_Surface_Top_Level_Matched : Boolean := False;
      Client_Surface_Modal_Reply_Decoded : Boolean := False;
      Client_Surface_Modal_Matched : Boolean := False;
      Client_Surface_Visible_Reply_Decoded : Boolean := False;
      Client_Surface_Visible_Matched : Boolean := False;
      Client_Surface_Active_Reply_Decoded : Boolean := False;
      Client_Surface_Active_Matched : Boolean := False;
      Client_Surface_Can_Close_Reply_Decoded : Boolean := False;
      Client_Surface_Can_Close_Matched : Boolean := False;
      Client_Live_Setting_Reply_Decoded : Boolean := False;
      Client_Live_Setting_Matched : Boolean := False;
      Client_Live_Relevant_Reply_Decoded : Boolean := False;
      Client_Live_Relevant_Matched : Boolean := False;
      Client_Live_Atomic_Reply_Decoded : Boolean := False;
      Client_Live_Atomic_Matched : Boolean := False;
      Client_Live_Assertive_Reply_Decoded : Boolean := False;
      Client_Live_Assertive_Matched : Boolean := False;
      Client_Live_Externally_Announced_Reply_Decoded : Boolean := False;
      Client_Live_Externally_Announced_Matched : Boolean := False;
      Reply_Name : Unbounded_String := Null_Unbounded_String;
      Reply_Child_Path : Unbounded_String := Null_Unbounded_String;
      Reply_Child_Name : Unbounded_String := Null_Unbounded_String;
      Reply_Child_Description : Unbounded_String := Null_Unbounded_String;
      Reply_Component_Hit_Path : Unbounded_String := Null_Unbounded_String;
      Reply_Action_Name : Unbounded_String := Null_Unbounded_String;
      Reply_Value_Current : Long_Float := 0.0;
      Reply_Value_Minimum : Long_Float := 0.0;
      Reply_Value_Maximum : Long_Float := 0.0;
      Reply_Value_Increment : Long_Float := 0.0;
      Reply_Value_Set : Boolean := False;
      Reply_Selection_Count : Natural := 0;
      Reply_Selection_Selected_Path : Unbounded_String := Null_Unbounded_String;
      Reply_Selection_Is : Boolean := False;
      Reply_Selection_Select : Boolean := False;
      Reply_Selection_Deselect : Boolean := False;
      Reply_Selection_Select_All : Boolean := False;
      Reply_Selection_Clear : Boolean := False;
      Reply_Text_Count : Natural := 0;
      Reply_Text_Caret : Natural := 0;
      Reply_Text_Range : Unbounded_String := Null_Unbounded_String;
      Reply_Image_Description : Unbounded_String := Null_Unbounded_String;
      Reply_Image_Caption : Unbounded_String := Null_Unbounded_String;
      Reply_Image_Kind : Unbounded_String := Null_Unbounded_String;
      Reply_Image_Size : A11y.Geometry.Size := (Width => 0, Height => 0);
      Reply_Document_Locale : Unbounded_String := Null_Unbounded_String;
      Reply_Document_Landmark : Boolean := False;
      Reply_Document_Title : Unbounded_String := Null_Unbounded_String;
      Reply_Table_Row_Count : Natural := 0;
      Reply_Table_Column_Count : Natural := 0;
      Reply_Table_Cell_Path : Unbounded_String := Null_Unbounded_String;
      Reply_Table_Row_Extent : Natural := 0;
      Reply_Table_Column_Extent : Natural := 0;
      Reply_Table_Current_Cell_Path : Unbounded_String := Null_Unbounded_String;
      Reply_Table_Sort_Order : Natural := 0;
      Reply_Table_Sort_Key_Path : Unbounded_String := Null_Unbounded_String;
      Reply_Surface_Kind : Unbounded_String := Null_Unbounded_String;
      Reply_Surface_Role : Natural := 0;
      Reply_Surface_Top_Level : Boolean := False;
      Reply_Surface_Modal : Boolean := False;
      Reply_Surface_Visible : Boolean := False;
      Reply_Surface_Active : Boolean := False;
      Reply_Surface_Can_Close : Boolean := False;
      Reply_Live_Setting : Unbounded_String := Null_Unbounded_String;
      Reply_Live_Relevant : Unbounded_String := Null_Unbounded_String;
      Reply_Live_Atomic : Boolean := False;
      Reply_Live_Assertive : Boolean := False;
      Reply_Live_Externally_Announced : Boolean := False;
      Reply_Child_Attributes :
        A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
      Reply_Child_Help_Text_Attribute_Matched : Boolean := False;
      Reply_Child_Placeholder_Attribute_Matched : Boolean := False;
      Reply_Child_Value_Text_Attribute_Matched : Boolean := False;
      Reply_Child_Visible_Title_Attribute_Matched : Boolean := False;
      Reply_Child_Keyboard_Shortcut_Attribute_Matched : Boolean := False;
      Reply_Child_Semantic_Identifier_Attribute_Matched : Boolean := False;
      Reply_Child_Locale_Attribute_Matched : Boolean := False;
      Reply_Child_Orientation_Attribute_Matched : Boolean := False;
      Reply_Child_Landmark_Attribute_Matched : Boolean := False;
      Reply_Protected_Attributes :
        A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
      Reply_Child_Relations :
        A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
      Reply_Child_First_Relation_Kind : Natural := 0;
      Reply_Child_First_Relation_Target : Natural := 0;
      Reply_Role : Natural := 0;
      Reply_Child_Role : Natural := 0;
      Reply_Child_Count : Natural := 0;
      Reply_Action_Count : Natural := 0;
      Reply_Action_Invoke : Boolean := False;
      Reply_Component_Bounds : A11y.Geometry.Rectangle :=
        A11y.Geometry.Empty_Rectangle;
      Reply_Component_Contains : Boolean := False;
      Child_Descriptor :
        A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor;
      Total_Event_Loop_Steps : Natural := 0;
      Total_Registered_Method_Calls : Natural := 0;
      Total_Registered_Replies : Natural := 0;
      Final_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Session_Address_Supplied : constant Boolean :=
        Session_Bus_Address'Length /= 0;

      procedure Finish_Status (Status : A11y.Results.Status_Code) is
      begin
         if Final_Status = A11y.Results.Success then
            Final_Status := Status;
         end if;
      end Finish_Status;

      function External_Core_Slice_Completed return Boolean;
      function External_Interaction_Slice_Completed return Boolean;
      function External_Content_Slice_Completed return Boolean;
      function External_Surface_Slice_Completed return Boolean;
      function External_Live_Region_Slice_Completed return Boolean;

      function External_Traversal_Completed return Boolean is
      begin
         return
           External_Core_Slice_Completed
           and then External_Interaction_Slice_Completed
           and then External_Content_Slice_Completed
           and then External_Surface_Slice_Completed
           and then External_Live_Region_Slice_Completed
           and then Client_Protected_Value_Suppressed;
      end External_Traversal_Completed;

      function External_Core_Slice_Completed return Boolean is
      begin
         return
           Client_Reply_Name_Matched
           and then Client_Role_Matched
           and then Client_Child_Count_Matched
           and then Client_Child_At_Matched
           and then Client_Child_Name_Matched
           and then Client_Child_Role_Matched
           and then Client_Child_Description_Matched
           and then Client_Child_Attributes_Matched
           and then Client_Child_Relations_Matched;
      end External_Core_Slice_Completed;

      function External_Interaction_Slice_Completed return Boolean is
      begin
         return
           Client_Component_Extents_Matched
           and then Client_Component_Contains_Matched
           and then Client_Component_Hit_Matched
           and then Client_Action_Count_Matched
           and then Client_Action_Name_Matched
           and then Client_Action_Invoke_Matched
           and then Client_Value_Current_Matched
           and then Client_Value_Minimum_Matched
           and then Client_Value_Maximum_Matched
           and then Client_Value_Increment_Matched
           and then Client_Value_Set_Matched
           and then Client_Selection_Count_Matched
           and then Client_Selection_Selected_Matched
           and then Client_Selection_Is_Matched
           and then Client_Selection_Select_Matched
           and then Client_Selection_Deselect_Matched
           and then Client_Selection_Select_All_Matched
           and then Client_Selection_Clear_Matched;
      end External_Interaction_Slice_Completed;

      function External_Content_Slice_Completed return Boolean is
      begin
         return
           Client_Text_Count_Matched
           and then Client_Text_Caret_Matched
           and then Client_Text_Range_Matched
           and then Client_Image_Description_Matched
           and then Client_Image_Caption_Matched
           and then Client_Image_Kind_Matched
           and then Client_Image_Size_Matched
           and then Client_Document_Locale_Matched
           and then Client_Document_Landmark_Matched
           and then Client_Document_Title_Matched
           and then Client_Table_Row_Count_Matched
           and then Client_Table_Column_Count_Matched
           and then Client_Table_Cell_Matched
           and then Client_Table_Row_Extent_Matched
           and then Client_Table_Column_Extent_Matched
           and then Client_Table_Current_Cell_Matched
           and then Client_Table_Sort_Order_Matched
           and then Client_Table_Sort_Key_Matched;
      end External_Content_Slice_Completed;

      function External_Surface_Slice_Completed return Boolean is
      begin
         return
           Client_Surface_Kind_Matched
           and then Client_Surface_Role_Matched
           and then Client_Surface_Top_Level_Matched
           and then Client_Surface_Modal_Matched
           and then Client_Surface_Visible_Matched
           and then Client_Surface_Active_Matched
           and then Client_Surface_Can_Close_Matched;
      end External_Surface_Slice_Completed;

      function External_Live_Region_Slice_Completed return Boolean is
      begin
         return
           Client_Live_Setting_Matched
           and then Client_Live_Relevant_Matched
           and then Client_Live_Atomic_Matched
           and then Client_Live_Assertive_Matched
           and then Client_Live_Externally_Announced_Matched;
      end External_Live_Region_Slice_Completed;

      function Failure_Stage return String is
      begin
         if Final_Status = A11y.Results.Success
         and then External_Traversal_Completed
         then
            return "none";
         elsif not Session_Address_Supplied then
            return
              (if Direct_ATSPI_Address then
                 "atspi_address_missing"
               else
                 "session_address_missing");
         elsif not Provider_Started then
            return "provider_startup";
         elsif not Provider_Registered
           or else not Provider_Unique_Name_Received
           or else not Provider_Object_Path_Available
         then
            return "provider_registration";
         elsif not Client_Discovered_Address then
            return "accessibility_address_discovery";
         elsif not Client_Raw_Connected then
            return "client_connection";
         elsif not Client_Hello_Completed then
            return "client_hello";
         elsif not Request_Encoded then
            return "external_method_call_encoding";
         elsif not Request_Sent then
            return "external_method_call_send";
         elsif not Provider_Event_Loop_Driven then
            return "provider_event_loop";
         elsif not Provider_Dispatched_Request then
            return "external_method_dispatch";
         elsif not Provider_Wrote_Reply then
            return "provider_reply";
         elsif not Client_Reply_Received then
            return "client_reply";
         elsif not Client_Reply_Decoded then
            return "client_reply_decode";
         else
            return "external_traversal";
         end if;
      end Failure_Stage;

      function Has_Attribute
        (Items : A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
         Key   : String;
         Value : String)
         return Boolean
      is
      begin
         for Item of Items loop
            if To_String (Item.Key) = Key
              and then To_String (Item.Value) = Value
            then
               return True;
            end if;
         end loop;
         return False;
      end Has_Attribute;

      function Has_Attribute_Key
        (Items : A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
         Key   : String)
         return Boolean
      is
      begin
         for Item of Items loop
            if To_String (Item.Key) = Key then
               return True;
            end if;
         end loop;
         return False;
      end Has_Attribute_Key;

      procedure Configure_Root_Snapshot is
         Root_Capabilities : A11y.Capabilities.Capability_Set :=
           A11y.Capabilities.Empty_Capability_Set;
         Window_Capabilities : A11y.Capabilities.Capability_Set :=
           A11y.Capabilities.Empty_Capability_Set;
      begin
         Snapshots.Accessible.Id := Root;
         Snapshots.Accessible.Root := Root;
         Snapshots.Accessible.Role := A11y.Roles.Application;
         Snapshots.Accessible.Name := To_Unbounded_String ("Fixture Application");
         Snapshots.Accessible.Parent := A11y.Node_Ids.No_Node;
         Snapshots.Accessible.Index_In_Parent := 0;
         Snapshots.Accessible.Children.Clear;
         Snapshots.Accessible.Children.Append
           (A11y_Test_Fixtures.Main_Window_Id);
         Snapshots.Accessible.Child_Count := 1;
         Window_Capabilities (A11y.Capabilities.Surface) := True;
         Window_Capabilities (A11y.Capabilities.Action) := True;
         Window_Capabilities (A11y.Capabilities.Value) := True;
         Window_Capabilities (A11y.Capabilities.Text) := True;
         Window_Capabilities (A11y.Capabilities.Image) := True;
         Window_Capabilities (A11y.Capabilities.Document) := True;
         Window_Capabilities (A11y.Capabilities.Table) := True;
         Window_Capabilities (A11y.Capabilities.Live_Region) := True;
         Root_Capabilities (A11y.Capabilities.Selection) := True;
         Snapshots.Accessible.Use_Node_Metadata := True;
         A11y.Semantic_Snapshots.Set_Node
           (Snapshots.Accessible.Nodes,
            Root,
            A11y.Roles.Application,
            "Fixture Application",
            A11y.States.Empty_State_Set,
            Root_Capabilities,
            A11y.Nodes.Expose_Node,
            Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;
         A11y.Semantic_Snapshots.Set_Node
           (Snapshot     => Snapshots.Accessible.Nodes,
            Node         => A11y_Test_Fixtures.Main_Window_Id,
            Role         => A11y.Roles.Window,
            Name         => "Main Window",
            Description  => "Primary semantic fixture window",
            Help_Text    => A11y.Properties.Present ("Main window help"),
            Placeholder  =>
              A11y.Properties.Present ("Main window placeholder"),
            Value_Text   => A11y.Properties.Present ("Main window value"),
            Protected_Value_Text => False,
            Bounds       =>
              (Status => A11y.Properties.Unsupported,
               Value  => A11y.Geometry.Empty_Rectangle),
            Semantic_Identifier =>
              A11y.Properties.Present ("main-window"),
            Visible_Title =>
              A11y.Properties.Present ("Main Window Title"),
            Keyboard_Shortcut =>
              A11y.Properties.Present ("Alt+M"),
            Locale       => A11y.Properties.Present ("en-US"),
            Orientation  => A11y.Properties.Present ("vertical"),
            Landmark     => A11y.Properties.Present ("main"),
            States       => A11y.States.Empty_State_Set,
            Capabilities => Window_Capabilities,
            Exposure     => A11y.Nodes.Expose_Node,
            Result       => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;
         A11y.Relations.Add
           (Snapshots.Accessible.Relations,
            A11y_Test_Fixtures.Main_Window_Id,
            A11y.Relations.Labelled_By,
            Root,
            Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;
         Snapshots.Application.Id := Root;
         Snapshots.Application.Application_Id :=
           A11y.Node_Ids.To_Natural (Root);
         Snapshots.Application.Toolkit_Name := To_Unbounded_String ("a11y_tests");
         Snapshots.Application.Version := To_Unbounded_String ("0.1.0-dev");
         Snapshots.Component.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Component.Root := Root;
         Snapshots.Component.Bounds :=
           (Origin => (X => 10, Y => 20),
            Extent => (Width => 640, Height => 480));
         Snapshots.Component.Hit_Test_Node := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Action.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Action.Root := Root;
         Snapshots.Action.Supported :=
           A11y.Actions.With_Action
             (A11y.Actions.With_Action
                (A11y.Actions.Empty_Action_Set, A11y.Actions.Press),
              A11y.Actions.Toggle);
         Snapshots.Action.States :=
           A11y.States.With_State
             (A11y.States.Empty_State_Set, A11y.States.Enabled);
         Snapshots.Value.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Value.Root := Root;
         Snapshots.Value.Metadata :=
           (Current         => A11y.Values.Floating (5.0),
            Minimum         => A11y.Values.Floating (0.0),
            Maximum         => A11y.Values.Floating (10.0),
            Small_Increment => A11y.Values.Floating (1.0),
            Large_Increment => A11y.Values.Floating (5.0),
            Mode            => A11y.Values.Writable,
            Units           => To_Unbounded_String (""),
            Presentation_Text => To_Unbounded_String (""),
            Precision       => 0);
         Snapshots.Selection.Id := Root;
         Snapshots.Selection.Root := Root;
         Snapshots.Selection.Children.Clear;
         Snapshots.Selection.Children.Append
           (A11y_Test_Fixtures.Main_Window_Id);
         A11y.Selection.Configure
           (Snapshots.Selection.Selection, A11y.Selection.Multiple);
         A11y.Selection.Select_Item
           (Snapshots.Selection.Selection,
            A11y_Test_Fixtures.Main_Window_Id,
            Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
         Snapshots.Text.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Text.Root := Root;
         Snapshots.Text.Content :=
           Ada.Strings.Wide_Wide_Unbounded.To_Unbounded_Wide_Wide_String
             ("Main text");
         Snapshots.Text.Caret := A11y.Text.Code_Point_Position (4);
         Snapshots.Text.Policy := A11y.Text.Plain_Text;
         Snapshots.Text.Read_Only := False;
         Snapshots.Image.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Image.Root := Root;
         Snapshots.Image.Metadata.Kind := A11y.Images.Chart;
         Snapshots.Image.Metadata.Alternative_Text :=
           To_Unbounded_String ("Main chart");
         Snapshots.Image.Metadata.Caption :=
           To_Unbounded_String ("Main chart caption");
         Snapshots.Image.Metadata.Has_Intrinsic_Size := True;
         Snapshots.Image.Metadata.Intrinsic_Dimensions :=
           (Width => 320, Height => 200);
         Snapshots.Document.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Document.Root := Root;
         Snapshots.Document.Metadata.Role := A11y.Documents.Document;
         Snapshots.Document.Metadata.Language :=
           To_Unbounded_String ("en-US");
         Snapshots.Document.Metadata.Title :=
           To_Unbounded_String ("Main document");
         Snapshots.Document.Metadata.Landmark :=
           To_Unbounded_String ("main");
         Snapshots.Table.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Table.Root := Root;
         A11y.Tables.Configure
           (Snapshots.Table.Table, Rows => 3, Columns => 5);
         A11y.Tables.Add_Cell
           (Snapshots.Table.Table,
            A11y_Test_Fixtures.Table_Cell_Id,
            Row => 1,
            Column => 2,
            Row_Span => 2,
            Column_Span => 3,
            Result => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;
         A11y.Tables.Set_Current_Cell
           (Snapshots.Table.Table,
            A11y_Test_Fixtures.Table_Cell_Id,
            Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;
         A11y.Tables.Set_Sort
           (Snapshots.Table.Table,
            A11y_Test_Fixtures.Table_Cell_Id,
            A11y.Tables.Descending,
            Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;
         Snapshots.Surface.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Surface.Root := Root;
         Snapshots.Surface.Metadata.Kind := A11y.Windows.Window;
         Snapshots.Surface.Metadata.State.Visible := True;
         Snapshots.Surface.Metadata.State.Active := True;
         Snapshots.Surface.Metadata.State.Closable := True;
         Snapshots.Surface.Metadata.State.Resizable := True;
         Snapshots.Surface.Metadata.State.Movable := True;
         Snapshots.Live_Region.Id := A11y_Test_Fixtures.Main_Window_Id;
         Snapshots.Live_Region.Metadata.Setting :=
           A11y.Live_Regions.Assertive;
         Snapshots.Live_Region.Metadata.Atomic := True;
         Snapshots.Live_Region.Metadata.Relevant :=
           A11y.Live_Regions.With_Change
             (A11y.Live_Regions.With_Change
                (A11y.Live_Regions.Empty_Relevant_Change_Set,
                 A11y.Live_Regions.Additions),
              A11y.Live_Regions.Text);
      end Configure_Root_Snapshot;

      procedure Execute_External_Accessible_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Accessible)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Accessible_Method;

      procedure Execute_External_Accessible_UInt32_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Argument           : Natural;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_UInt32_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Accessible)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Argument,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Accessible_UInt32_Method;

      procedure Execute_External_Component_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Component)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Component_Method;

      procedure Execute_External_Component_Point_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Point             : A11y.Geometry.Point;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Point_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Component)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Point,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Component_Point_Method;

      procedure Execute_External_Action_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Action)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Action_Method;

      procedure Execute_External_Action_UInt32_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Argument           : Natural;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_UInt32_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Action)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Argument,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Action_UInt32_Method;

      procedure Execute_External_Value_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Value)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Value_Method;

      procedure Execute_External_Value_Float_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Argument           : Long_Float;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Float_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Value)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Argument,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Value_Float_Method;

      procedure Execute_External_Selection_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Selection)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Selection_Method;

      procedure Execute_External_Selection_UInt32_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Argument           : Natural;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_UInt32_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Selection)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Argument,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Selection_UInt32_Method;

      procedure Execute_External_Text_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Text)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Text_Method;

      procedure Execute_External_Text_Range_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Start             : Natural;
         Count             : Natural;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Point_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Text)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       =>
              (X => A11y.Geometry.Coordinate (Start),
               Y => A11y.Geometry.Coordinate (Count)),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Text_Range_Method;

      procedure Execute_External_Image_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Image)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Image_Method;

      procedure Execute_External_Document_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Document)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Document_Method;

      procedure Execute_External_Document_String_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Argument           : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_String_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Document)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Argument,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Document_String_Method;

      procedure Execute_External_Table_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Table)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Table_Method;

      procedure Execute_External_Table_Point_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Argument           : A11y.Geometry.Point;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Point_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Table)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Argument       => Argument,
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Table_Point_Method;

      procedure Execute_External_Surface_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Surface)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Surface_Method;

      procedure Execute_External_Live_Region_Method
        (Method_Name       : String;
         Object_Path        : Unbounded_String;
         Serial            : Natural;
         Expected_Signature : String;
         Reply             : out A11y.Linux.DBus_Messages.Transport_Envelope;
         Sent              : out Boolean;
         Provider_Handled  : out Boolean;
         Provider_Replied  : out Boolean;
         Received          : out Boolean;
         Decoded           : out Boolean)
      is
      begin
         Reply := (others => <>);
         Sent := False;
         Provider_Handled := False;
         Provider_Replied := False;
         Received := False;
         Decoded := False;

         Request_Packet := Build_External_Method_Call_Packet
           (Destination    => Provider_Unique_Name,
            Object_Path    => Object_Path,
            Interface_Name => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Interface_Name
                 (A11y.Linux.ATSPi_Objects.Live_Region)),
            Member_Name    => To_Unbounded_String (Method_Name),
            Serial         => Serial,
            Result         => Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Local_Channel.Send_Packet
           (Client_Context, Client_Channel, Request_Packet, Result);
         Sent := A11y.Results.Succeeded (Result);
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
           (Provider, Snapshots, 8, 250, Event_Report, Step_Result);
         Total_Event_Loop_Steps :=
           Total_Event_Loop_Steps + Event_Report.Steps_Attempted;
         Total_Registered_Method_Calls :=
           Total_Registered_Method_Calls
           + Event_Report.Pump.Registered_Method_Calls;
         Total_Registered_Replies :=
           Total_Registered_Replies + Event_Report.Pump.Registered_Replies;
         Provider_Handled :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Registered_Method_Calls > 0
           and then
             Event_Report.Pump.Registered_Boundary_Completed_Calls > 0;
         Provider_Replied :=
           A11y.Results.Succeeded (Step_Result)
           and then Event_Report.Pump.Replies_Written > 0;
         if A11y.Results.Failed (Step_Result) then
            Finish_Status (Step_Result.Status);
            return;
         end if;

         if not Provider_Replied then
            return;
         end if;

         for Attempt in 1 .. 16 loop
            pragma Unreferenced (Attempt);
            A11y.Linux.ATSPi_Local_Channel.Receive_Next_Packet
              (Client_Channel, Reply_Packet, Result);
            if A11y.Results.Failed (Result)
              and then Result.Status = A11y.Results.Timed_Out
            then
               Result := A11y.Results.Ok;
            else
               exit when A11y.Results.Failed (Result);
               exit when Reply_Packet.Metadata.Kind /=
                 A11y.Linux.DBus_Messages.Signal_Message;
            end if;
         end loop;
         Received :=
           A11y.Results.Succeeded (Result)
           and then Reply_Packet.Metadata.Kind =
             A11y.Linux.DBus_Messages.Method_Return;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
            return;
         elsif not Received then
            return;
         end if;

         Reply := A11y.Linux.DBus_Messages.Decode_Method_Return
           (Reply_Packet.Bytes, Result);
         Decoded :=
           A11y.Results.Succeeded (Result)
           and then Reply.Reply_Serial = Serial
           and then To_String (Reply.Body_Signature) = Expected_Signature;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      exception
         when others =>
            Finish_Status (A11y.Results.Internal_Error);
      end Execute_External_Live_Region_Method;
   begin
      if Direct_ATSPI_Address then
         A11y.Linux.ATSPi_Backend_Sessions.Start_From_Address_With_Report
           (Provider, Session_Bus_Address, User_Id, Root, Startup_Report,
            Result);
      else
         A11y.Linux.ATSPi_Backend_Sessions
           .Start_From_Session_Bus_Address_With_Report
             (Provider, Session_Bus_Address, User_Id, Root, Startup_Report,
              Result);
      end if;
      Provider_Started := A11y.Results.Succeeded (Result);
      if A11y.Results.Failed (Result) then
         Finish_Status (Result.Status);
      end if;

      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Provider, Provider_Report);
      Provider_Registered := Provider_Report.Registered;
      Provider_Unique_Name :=
        To_Unbounded_String
          (A11y.Linux.ATSPi_Backend_Sessions.Unique_Name (Provider));
      Provider_Unique_Name_Received := Length (Provider_Unique_Name) /= 0;
      Provider_Object_Path_Available :=
        Provider_Report.Application_Exportable
        and then Length (Provider_Report.Application.Path) /= 0;

      if Direct_ATSPI_Address
        and then Provider_Started
        and then Provider_Registered
        and then Provider_Unique_Name_Received
        and then Provider_Object_Path_Available
      then
         Address.Text := To_Unbounded_String (Session_Bus_Address);
         Client_Discovered_Address := True;
         A11y.Linux.ATSPi_Bus.Prepare_Connection
           (Client_Context, Session_Bus_Address, Result);
      elsif Provider_Started
        and then Provider_Registered
        and then Provider_Unique_Name_Received
        and then Provider_Object_Path_Available
      then
         A11y.Linux.ATSPi_Bus.Prepare_Connection
           (Client_Session_Context, Session_Bus_Address, Discovery_Result);
         if A11y.Results.Succeeded (Discovery_Result) then
            A11y.Linux.ATSPi_Local_Channel
              .Connect_Authenticated_Hello_And_Discover_Accessibility_Bus
                (Client_Session_Context, Client_Session_Channel, User_Id,
                 Address, Discovery_Result);
         end if;
         A11y.Linux.ATSPi_Local_Channel.Close (Client_Session_Channel);
         if A11y.Results.Succeeded (Discovery_Result) then
            Client_Discovered_Address := True;
            A11y.Linux.ATSPi_Bus.Prepare_Connection
              (Client_Context, To_String (Address.Text), Result);
         else
            Finish_Status (Discovery_Result.Status);
         end if;
      end if;

      if Client_Discovered_Address and then A11y.Results.Succeeded (Result) then
         A11y.Linux.ATSPi_Local_Channel.Connect_Authenticated_And_Hello
           (Client_Context, Client_Channel, User_Id, Result);
         Client_Raw_Connected := A11y.Results.Succeeded (Result);
         Client_Hello_Completed :=
           Client_Raw_Connected and then Length (Client_Context.Unique_Name) /= 0;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      elsif Client_Discovered_Address then
         Finish_Status (Result.Status);
      end if;

      if Client_Hello_Completed then
         Configure_Root_Snapshot;

         Execute_External_Accessible_Method
           ("GetName", Provider_Report.Application.Path, 2, "s", Reply_Envelope,
            Request_Sent,
            Provider_Dispatched_Request, Provider_Wrote_Reply,
            Client_Reply_Received, Client_Reply_Decoded);
         Request_Encoded := Request_Sent;
         Provider_Event_Loop_Driven :=
           Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
         if Client_Reply_Decoded then
            Reply_Name := A11y.Linux.DBus_Messages.Decode_String_Body
              (Reply_Envelope.Body_Bytes, Result);
            Client_Reply_Name_Matched :=
              A11y.Results.Succeeded (Result)
              and then To_String (Reply_Name) = "Fixture Application";
         end if;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;

         if Client_Reply_Name_Matched then
            Execute_External_Accessible_Method
              ("GetRole", Provider_Report.Application.Path, 3, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received, Client_Role_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Role_Reply_Decoded then
               Reply_Role := A11y.Linux.DBus_Messages.Decode_UInt32_Body
                 (Reply_Envelope.Body_Bytes, Result);
               Client_Role_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Role =
                   A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                     (A11y.Linux.ATSPi_Mappings.Application);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Role_Matched then
            Execute_External_Accessible_Method
              ("GetChildCount", Provider_Report.Application.Path, 4, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received, Client_Child_Count_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_Count_Reply_Decoded then
               Reply_Child_Count :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Child_Count_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Child_Count = 1;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Child_Count_Matched then
            Execute_External_Accessible_UInt32_Method
              ("GetChildAtIndex", Provider_Report.Application.Path, 0, 5, "o",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received, Client_Child_At_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_At_Reply_Decoded then
               Reply_Child_Path := A11y.Linux.DBus_Messages.Decode_String_Body
                 (Reply_Envelope.Body_Bytes, Result);
               if A11y.Results.Succeeded (Result) then
                  declare
                     Child_Node : constant A11y.Node_Ids.Node_Id :=
                       A11y.Linux.ATSPi_Objects.Node_From_Object_Path
                         (To_String (Reply_Child_Path),
                          Provider_Report.Application.Session,
                          Result);
                  begin
                     Client_Child_At_Matched :=
                       A11y.Results.Succeeded (Result)
                       and then Child_Node = A11y_Test_Fixtures.Main_Window_Id;
                  end;
               end if;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Child_At_Matched then
            A11y.Linux.ATSPi_Backend_Sessions.Node_Descriptor
              (Provider, A11y_Test_Fixtures.Main_Window_Id,
               Child_Descriptor);
            Child_Object_Path_Available :=
              Child_Descriptor.Exportable
              and then Length (Child_Descriptor.Path) /= 0
              and then Child_Descriptor.Path = Reply_Child_Path;
            Execute_External_Accessible_Method
              ("GetName", Reply_Child_Path, 6, "s", Reply_Envelope,
               Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received, Client_Child_Name_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_Name_Reply_Decoded then
               Reply_Child_Name := A11y.Linux.DBus_Messages.Decode_String_Body
                 (Reply_Envelope.Body_Bytes, Result);
               Client_Child_Name_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Child_Name) = "Main Window";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Child_Name_Matched then
            Execute_External_Accessible_Method
              ("GetRole", Reply_Child_Path, 7, "u", Reply_Envelope,
               Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received, Client_Child_Role_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_Role_Reply_Decoded then
               Reply_Child_Role := A11y.Linux.DBus_Messages.Decode_UInt32_Body
                 (Reply_Envelope.Body_Bytes, Result);
               Client_Child_Role_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Child_Role =
                   A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                     (A11y.Linux.ATSPi_Mappings.Window);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Child_Role_Matched then
            Execute_External_Accessible_Method
              ("GetDescription", Reply_Child_Path, 8, "s", Reply_Envelope,
               Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Child_Description_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_Description_Reply_Decoded then
               Reply_Child_Description :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Child_Description_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Child_Description) =
                   "Primary semantic fixture window";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Child_Description_Matched then
            Execute_External_Accessible_Method
              ("GetAttributes", Reply_Child_Path, 9, "a{ss}",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Child_Attributes_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_Attributes_Reply_Decoded then
               Reply_Child_Attributes :=
                 A11y.Linux.DBus_Messages.Decode_Attribute_Set_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Reply_Child_Help_Text_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "help-text",
                    "Main window help");
               Reply_Child_Placeholder_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "placeholder-text",
                    "Main window placeholder");
               Reply_Child_Value_Text_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "accessible-value",
                    "Main window value");
               Reply_Child_Visible_Title_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "visible-title",
                    "Main Window Title");
               Reply_Child_Keyboard_Shortcut_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "keyboard-shortcut", "Alt+M");
               Reply_Child_Semantic_Identifier_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "semantic-identifier",
                    "main-window");
               Reply_Child_Locale_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "locale", "en-US");
               Reply_Child_Orientation_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "orientation", "vertical");
               Reply_Child_Landmark_Attribute_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Has_Attribute
                   (Reply_Child_Attributes, "landmark", "main");
               Client_Child_Attributes_Matched :=
                 Reply_Child_Help_Text_Attribute_Matched
                 and then Reply_Child_Placeholder_Attribute_Matched
                 and then Reply_Child_Value_Text_Attribute_Matched
                 and then Reply_Child_Visible_Title_Attribute_Matched
                 and then Reply_Child_Keyboard_Shortcut_Attribute_Matched
                 and then Reply_Child_Semantic_Identifier_Attribute_Matched
                 and then Reply_Child_Locale_Attribute_Matched
                 and then Reply_Child_Orientation_Attribute_Matched
                 and then Reply_Child_Landmark_Attribute_Matched;
            end if;
         if A11y.Results.Failed (Result) then
            Finish_Status (Result.Status);
         end if;
      end if;

         if Client_Child_Attributes_Matched then
            Execute_External_Accessible_Method
              ("GetRelationSet", Reply_Child_Path, 59, "a(uao)",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Child_Relations_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Child_Relations_Reply_Decoded then
               Reply_Child_Relations :=
                 A11y.Linux.DBus_Messages.Decode_Relation_Set_Body
                   (Provider_Report.Application.Session,
                    Reply_Envelope.Body_Bytes,
                    Result);
               if A11y.Results.Succeeded (Result)
                 and then not Reply_Child_Relations.Is_Empty
               then
                  Reply_Child_First_Relation_Kind :=
                    A11y.Linux.ATSPi_Mappings.ATSPI_Relation'Pos
                      (Reply_Child_Relations.First_Element.Kind);
                  if not Reply_Child_Relations.First_Element.Targets.Is_Empty
                  then
                     Reply_Child_First_Relation_Target :=
                       A11y.Node_Ids.To_Natural
                         (Reply_Child_Relations.First_Element
                            .Targets.First_Element);
                  end if;
               end if;
               Client_Child_Relations_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Natural (Reply_Child_Relations.Length) = 1
                 and then Reply_Child_Relations.First_Element.Kind =
                   A11y.Linux.ATSPi_Mappings.Labelled_By
                 and then Natural
                   (Reply_Child_Relations.First_Element.Targets.Length) = 1
                 and then Reply_Child_Relations.First_Element
                   .Targets.First_Element = Root;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Child_Relations_Matched then
            Execute_External_Component_Method
              ("GetExtents", Reply_Child_Path, 10, "(iiii)",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Component_Extents_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Component_Extents_Reply_Decoded then
               Reply_Component_Bounds :=
                 A11y.Linux.DBus_Messages.Decode_Rectangle_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Component_Extents_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Component_Bounds =
                   Snapshots.Component.Bounds;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Component_Extents_Matched then
            Execute_External_Component_Point_Method
              ("Contains", Reply_Child_Path, (X => 42, Y => 64), 11, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Component_Contains_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Component_Contains_Reply_Decoded then
               Reply_Component_Contains :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Component_Contains_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Component_Contains;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Component_Contains_Matched then
            Execute_External_Component_Point_Method
              ("GetAccessibleAtPoint", Reply_Child_Path, (X => 42, Y => 64),
               12, "o", Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received, Client_Component_Hit_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Component_Hit_Reply_Decoded then
               Reply_Component_Hit_Path :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Component_Hit_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Component_Hit_Path = Reply_Child_Path;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Component_Hit_Matched then
            Execute_External_Action_Method
              ("GetNActions", Reply_Child_Path, 13, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Action_Count_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Action_Count_Reply_Decoded then
               Reply_Action_Count :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Action_Count_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Action_Count = 2;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Action_Count_Matched then
            Execute_External_Action_UInt32_Method
              ("GetName", Reply_Child_Path, 0, 14, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Action_Name_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Action_Name_Reply_Decoded then
               Reply_Action_Name :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Action_Name_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Action_Name) =
                   A11y.Actions.Stable_Name (A11y.Actions.Press);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Action_Name_Matched then
            Execute_External_Action_UInt32_Method
              ("DoAction", Reply_Child_Path, 1, 15, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Action_Invoke_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Action_Invoke_Reply_Decoded then
               Reply_Action_Invoke :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Action_Invoke_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Action_Invoke;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Action_Invoke_Matched then
            Execute_External_Value_Method
              ("GetCurrentValue", Reply_Child_Path, 16, "d",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Value_Current_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Value_Current_Reply_Decoded then
               Reply_Value_Current :=
                 A11y.Linux.DBus_Messages.Decode_Float_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Value_Current_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Value_Current = 5.0;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Value_Current_Matched then
            Execute_External_Value_Method
              ("GetMinimumValue", Reply_Child_Path, 17, "d",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Value_Minimum_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Value_Minimum_Reply_Decoded then
               Reply_Value_Minimum :=
                 A11y.Linux.DBus_Messages.Decode_Float_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Value_Minimum_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Value_Minimum = 0.0;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Value_Minimum_Matched then
            Execute_External_Value_Method
              ("GetMaximumValue", Reply_Child_Path, 18, "d",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Value_Maximum_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Value_Maximum_Reply_Decoded then
               Reply_Value_Maximum :=
                 A11y.Linux.DBus_Messages.Decode_Float_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Value_Maximum_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Value_Maximum = 10.0;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Value_Maximum_Matched then
            Execute_External_Value_Method
              ("GetMinimumIncrement", Reply_Child_Path, 19, "d",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Value_Increment_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Value_Increment_Reply_Decoded then
               Reply_Value_Increment :=
                 A11y.Linux.DBus_Messages.Decode_Float_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Value_Increment_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Value_Increment = 1.0;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Value_Increment_Matched then
            Execute_External_Value_Float_Method
              ("SetCurrentValue", Reply_Child_Path, 6.0, 20, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Value_Set_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Value_Set_Reply_Decoded then
               Reply_Value_Set :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Value_Set_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Value_Set;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Value_Set_Matched then
            Execute_External_Selection_Method
              ("GetNSelectedChildren", Provider_Report.Application.Path, 21,
               "u", Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Count_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Count_Reply_Decoded then
               Reply_Selection_Count :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Count_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Count = 1;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Count_Matched then
            Execute_External_Selection_UInt32_Method
              ("GetSelectedChild", Provider_Report.Application.Path, 0, 22,
               "o", Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Selected_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Selected_Reply_Decoded then
               Reply_Selection_Selected_Path :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Selected_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Selected_Path = Reply_Child_Path;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Selected_Matched then
            Execute_External_Selection_UInt32_Method
              ("IsChildSelected", Provider_Report.Application.Path, 0, 23,
               "b", Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Is_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Is_Reply_Decoded then
               Reply_Selection_Is :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Is_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Is;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Is_Matched then
            Execute_External_Selection_UInt32_Method
              ("SelectChild", Provider_Report.Application.Path, 0, 24, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Select_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Select_Reply_Decoded then
               Reply_Selection_Select :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Select_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Select;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Select_Matched then
            Execute_External_Selection_UInt32_Method
              ("DeselectChild", Provider_Report.Application.Path, 0, 25, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Deselect_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Deselect_Reply_Decoded then
               Reply_Selection_Deselect :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Deselect_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Deselect;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Deselect_Matched then
            Execute_External_Selection_Method
              ("SelectAll", Provider_Report.Application.Path, 26, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Select_All_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Select_All_Reply_Decoded then
               Reply_Selection_Select_All :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Select_All_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Select_All;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Select_All_Matched then
            Execute_External_Selection_Method
              ("ClearSelection", Provider_Report.Application.Path, 27, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Selection_Clear_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Selection_Clear_Reply_Decoded then
               Reply_Selection_Clear :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Selection_Clear_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Selection_Clear;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Selection_Clear_Matched then
            Execute_External_Text_Method
              ("GetCharacterCount", Reply_Child_Path, 28, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Text_Count_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Text_Count_Reply_Decoded then
               Reply_Text_Count :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Text_Count_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Text_Count = 9;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Text_Count_Matched then
            Execute_External_Text_Method
              ("GetCaretOffset", Reply_Child_Path, 29, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Text_Caret_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Text_Caret_Reply_Decoded then
               Reply_Text_Caret :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Text_Caret_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Text_Caret = 4;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Text_Caret_Matched then
            Execute_External_Text_Range_Method
              ("GetText", Reply_Child_Path, 0, 4, 30, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Text_Range_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Text_Range_Reply_Decoded then
               Reply_Text_Range :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Text_Range_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Text_Range) = "Main";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Text_Range_Matched then
            Execute_External_Image_Method
              ("GetImageDescription", Reply_Child_Path, 31, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Image_Description_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Image_Description_Reply_Decoded then
               Reply_Image_Description :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Image_Description_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Image_Description) =
                   "Main chart";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Image_Description_Matched then
            Execute_External_Image_Method
              ("GetImageCaption", Reply_Child_Path, 32, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Image_Caption_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Image_Caption_Reply_Decoded then
               Reply_Image_Caption :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Image_Caption_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Image_Caption) =
                   "Main chart caption";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Image_Caption_Matched then
            Execute_External_Image_Method
              ("GetImageKind", Reply_Child_Path, 33, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Image_Kind_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Image_Kind_Reply_Decoded then
               Reply_Image_Kind :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Image_Kind_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Image_Kind) =
                   A11y.Images.Stable_Name (A11y.Images.Chart);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Image_Kind_Matched then
            Execute_External_Image_Method
              ("GetImageSize", Reply_Child_Path, 34, "(ii)",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Image_Size_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Image_Size_Reply_Decoded then
               Reply_Image_Size :=
                 A11y.Linux.DBus_Messages.Decode_Size_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Image_Size_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Image_Size.Width = 320
                 and then Reply_Image_Size.Height = 200;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Image_Size_Matched then
            Execute_External_Document_Method
              ("GetLocale", Reply_Child_Path, 35, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Document_Locale_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Document_Locale_Reply_Decoded then
               Reply_Document_Locale :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Document_Locale_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Document_Locale) = "en-US";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Document_Locale_Matched then
            Execute_External_Document_Method
              ("IsLandmark", Reply_Child_Path, 36, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Document_Landmark_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Document_Landmark_Reply_Decoded then
               Reply_Document_Landmark :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Document_Landmark_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Document_Landmark;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Document_Landmark_Matched then
            Execute_External_Document_String_Method
              ("GetAttributeValue", Reply_Child_Path,
               To_Unbounded_String ("title"), 37, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Document_Title_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Document_Title_Reply_Decoded then
               Reply_Document_Title :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Document_Title_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Document_Title) =
                   "Main document";
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Document_Title_Matched then
            Execute_External_Table_Method
              ("GetNRows", Reply_Child_Path, 38, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Row_Count_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Row_Count_Reply_Decoded then
               Reply_Table_Row_Count :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Row_Count_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Row_Count = 3;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Row_Count_Matched then
            Execute_External_Table_Method
              ("GetNColumns", Reply_Child_Path, 39, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Column_Count_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Column_Count_Reply_Decoded then
               Reply_Table_Column_Count :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Column_Count_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Column_Count = 5;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Column_Count_Matched then
            Execute_External_Table_Point_Method
              ("GetAccessibleAt", Reply_Child_Path,
               (X => 1, Y => 2), 40, "o",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Cell_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Cell_Reply_Decoded then
               Reply_Table_Cell_Path :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               if A11y.Results.Succeeded (Result) then
                  declare
                     Cell_Node : constant A11y.Node_Ids.Node_Id :=
                       A11y.Linux.ATSPi_Objects.Node_From_Object_Path
                         (To_String (Reply_Table_Cell_Path),
                          Provider_Report.Application.Session,
                          Result);
                  begin
                     Client_Table_Cell_Matched :=
                       A11y.Results.Succeeded (Result)
                       and then Cell_Node = A11y_Test_Fixtures.Table_Cell_Id;
                  end;
               end if;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Cell_Matched then
            Execute_External_Table_Point_Method
              ("GetRowExtentAt", Reply_Child_Path,
               (X => 1, Y => 2), 41, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Row_Extent_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Row_Extent_Reply_Decoded then
               Reply_Table_Row_Extent :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Row_Extent_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Row_Extent = 2;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Row_Extent_Matched then
            Execute_External_Table_Point_Method
              ("GetColumnExtentAt", Reply_Child_Path,
               (X => 1, Y => 2), 42, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Column_Extent_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Column_Extent_Reply_Decoded then
               Reply_Table_Column_Extent :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Column_Extent_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Column_Extent = 3;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Column_Extent_Matched then
            Execute_External_Table_Method
              ("GetCurrentCell", Reply_Child_Path, 43, "o",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Current_Cell_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Current_Cell_Reply_Decoded then
               Reply_Table_Current_Cell_Path :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Current_Cell_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Current_Cell_Path =
                   Reply_Table_Cell_Path;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Current_Cell_Matched then
            Execute_External_Table_Method
              ("GetSortOrder", Reply_Child_Path, 44, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Sort_Order_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Sort_Order_Reply_Decoded then
               Reply_Table_Sort_Order :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Sort_Order_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Sort_Order =
                   A11y.Tables.Sort_Order'Pos (A11y.Tables.Descending);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Sort_Order_Matched then
            Execute_External_Table_Method
              ("GetSortKey", Reply_Child_Path, 45, "o",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Table_Sort_Key_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Table_Sort_Key_Reply_Decoded then
               Reply_Table_Sort_Key_Path :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Table_Sort_Key_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Table_Sort_Key_Path = Reply_Table_Cell_Path;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Table_Sort_Key_Matched then
            Execute_External_Surface_Method
              ("GetSurfaceKind", Reply_Child_Path, 46, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Kind_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Kind_Reply_Decoded then
               Reply_Surface_Kind :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Kind_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Surface_Kind) =
                   A11y.Windows.Stable_Name (A11y.Windows.Window);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Kind_Matched then
            Execute_External_Surface_Method
              ("GetSurfaceRole", Reply_Child_Path, 47, "u",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Role_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Role_Reply_Decoded then
               Reply_Surface_Role :=
                 A11y.Linux.DBus_Messages.Decode_UInt32_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Role_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Surface_Role =
                   A11y.Linux.ATSPi_Mappings.ATSPI_Role'Pos
                     (A11y.Linux.ATSPi_Mappings.Window);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Role_Matched then
            Execute_External_Surface_Method
              ("IsTopLevel", Reply_Child_Path, 48, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Top_Level_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Top_Level_Reply_Decoded then
               Reply_Surface_Top_Level :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Top_Level_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Surface_Top_Level;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Top_Level_Matched then
            Execute_External_Surface_Method
              ("IsModal", Reply_Child_Path, 49, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Modal_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Modal_Reply_Decoded then
               Reply_Surface_Modal :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Modal_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then not Reply_Surface_Modal;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Modal_Matched then
            Execute_External_Surface_Method
              ("IsVisible", Reply_Child_Path, 50, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Visible_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Visible_Reply_Decoded then
               Reply_Surface_Visible :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Visible_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Surface_Visible;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Visible_Matched then
            Execute_External_Surface_Method
              ("IsActive", Reply_Child_Path, 51, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Active_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Active_Reply_Decoded then
               Reply_Surface_Active :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Active_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Surface_Active;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Active_Matched then
            Execute_External_Surface_Method
              ("CanClose", Reply_Child_Path, 52, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Surface_Can_Close_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Surface_Can_Close_Reply_Decoded then
               Reply_Surface_Can_Close :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Surface_Can_Close_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Surface_Can_Close;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Surface_Can_Close_Matched then
            Execute_External_Live_Region_Method
              ("GetLiveSetting", Reply_Child_Path, 53, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Live_Setting_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Live_Setting_Reply_Decoded then
               Reply_Live_Setting :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Live_Setting_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Live_Setting) =
                   A11y.Live_Regions.Stable_Name
                     (A11y.Live_Regions.Assertive);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Live_Setting_Matched then
            Execute_External_Live_Region_Method
              ("GetLiveRelevant", Reply_Child_Path, 54, "s",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Live_Relevant_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Live_Relevant_Reply_Decoded then
               Reply_Live_Relevant :=
                 A11y.Linux.DBus_Messages.Decode_String_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Live_Relevant_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then To_String (Reply_Live_Relevant) =
                   A11y.Live_Regions.Relevant_Names
                     (Snapshots.Live_Region.Metadata.Relevant);
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Live_Relevant_Matched then
            Execute_External_Live_Region_Method
              ("IsLiveAtomic", Reply_Child_Path, 55, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Live_Atomic_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Live_Atomic_Reply_Decoded then
               Reply_Live_Atomic :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Live_Atomic_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Live_Atomic;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Live_Atomic_Matched then
            Execute_External_Live_Region_Method
              ("IsLiveAssertive", Reply_Child_Path, 56, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Live_Assertive_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Live_Assertive_Reply_Decoded then
               Reply_Live_Assertive :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Live_Assertive_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Live_Assertive;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Live_Assertive_Matched then
            Execute_External_Live_Region_Method
              ("IsLiveExternallyAnnounced", Reply_Child_Path, 57, "b",
               Reply_Envelope, Request_Sent,
               Provider_Dispatched_Request, Provider_Wrote_Reply,
               Client_Reply_Received,
               Client_Live_Externally_Announced_Reply_Decoded);
            Request_Encoded := Request_Encoded and then Request_Sent;
            Provider_Event_Loop_Driven :=
              Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
            if Client_Live_Externally_Announced_Reply_Decoded then
               Reply_Live_Externally_Announced :=
                 A11y.Linux.DBus_Messages.Decode_Boolean_Body
                   (Reply_Envelope.Body_Bytes, Result);
               Client_Live_Externally_Announced_Matched :=
                 A11y.Results.Succeeded (Result)
                 and then Reply_Live_Externally_Announced;
            end if;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;
         end if;

         if Client_Live_Externally_Announced_Matched then
            declare
               Protected_Window_Capabilities :
                 A11y.Capabilities.Capability_Set :=
                   A11y.Capabilities.Empty_Capability_Set;
            begin
               Protected_Window_Capabilities
                 (A11y.Capabilities.Surface) := True;
               A11y.Semantic_Snapshots.Set_Node
                 (Snapshots.Accessible.Nodes,
                  A11y_Test_Fixtures.Main_Window_Id,
                  A11y.Roles.Window,
                  "Main Window",
                  "Primary semantic fixture window",
                  A11y.Properties.Present ("Main window help"),
                  A11y.Properties.Present ("Main window placeholder"),
                  A11y.Properties.Present ("Secret main window value"),
                  True,
                  A11y.States.Empty_State_Set,
                  Protected_Window_Capabilities,
                  A11y.Nodes.Expose_Node,
                  Result);
            end;
            if A11y.Results.Failed (Result) then
               Finish_Status (Result.Status);
            end if;

            if A11y.Results.Succeeded (Result) then
               Execute_External_Accessible_Method
                 ("GetAttributes", Reply_Child_Path, 58, "a{ss}",
                  Reply_Envelope, Request_Sent,
                  Provider_Dispatched_Request, Provider_Wrote_Reply,
                  Client_Reply_Received,
                  Client_Protected_Attributes_Reply_Decoded);
               Request_Encoded := Request_Encoded and then Request_Sent;
               Provider_Event_Loop_Driven :=
                 Provider_Event_Loop_Driven or else Provider_Dispatched_Request;
               if Client_Protected_Attributes_Reply_Decoded then
                  Reply_Protected_Attributes :=
                    A11y.Linux.DBus_Messages.Decode_Attribute_Set_Body
                      (Reply_Envelope.Body_Bytes, Result);
                  Client_Protected_Value_Suppressed :=
                    A11y.Results.Succeeded (Result)
                    and then Has_Attribute
                      (Reply_Protected_Attributes, "placeholder-text",
                       "Main window placeholder")
                    and then not Has_Attribute_Key
                      (Reply_Protected_Attributes, "accessible-value");
               end if;
               if A11y.Results.Failed (Result) then
                  Finish_Status (Result.Status);
               end if;
            end if;
         end if;
      end if;

      if not External_Traversal_Completed
        and then Final_Status = A11y.Results.Success
      then
         Final_Status := A11y.Results.Protocol_Failure;
      end if;

      A11y.Linux.ATSPi_Local_Channel.Close (Client_Channel);
      A11y.Linux.ATSPi_Backend_Sessions.Stop_With_Report
        (Provider, Stop_Report, Stop_Result);

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_external_client_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line
        ("  ""session_address_supplied"": "
         & (if Session_Address_Supplied then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""direct_atspi_address_supplied"": "
         & (if Direct_ATSPI_Address then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line ("  ""provider_started"": " & (if Provider_Started then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""provider_registered"": " & (if Provider_Registered then "true" else "false") & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_startup_status"": "
         & Q (Status_Name (Startup_Report.Status)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_raw_connect_attempted"": "
         & (if Startup_Report.Registration.Raw_Connect_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Registration.Raw_Connect_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_raw_connected"": "
         & (if Startup_Report.Registration.Raw_Connected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_auth_response_status"": "
         & Q (Status_Name (Startup_Report.Registration.Auth_Response_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_hello_completed"": "
         & (if Startup_Report.Registration.Hello_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_queued"": "
         & (if Startup_Report.Registration.Registration_Queued
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_sent"": "
         & (if Startup_Report.Registration.Registration_Sent
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_reply_received"": "
         & (if Startup_Report.Registration.Registration_Reply_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_reply_was_error_return"": "
         & (if Startup_Report.Registration.Registration_Reply_Was_Error_Return
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_reply_body_signature"": "
         & Q
           (To_String
              (Startup_Report.Registration
                 .Registration_Reply_Body_Signature))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_reply_body_bytes"": "
         & Trimmed
           (Natural'Image
           (Startup_Report.Registration.Registration_Reply_Body_Bytes)
           )
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_reply_bus_name_length"": "
         & Trimmed
           (Natural'Image
           (Startup_Report.Registration
              .Registration_Reply_Bus_Name_Length)
           )
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_reply_object_path_length"": "
         & Trimmed
           (Natural'Image
           (Startup_Report.Registration
              .Registration_Reply_Object_Path_Length)
           )
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_application_completed"": "
         & (if Startup_Report.Registration.Registration_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_transport_registration_observed"": "
         & (if Startup_Report.Registration.Transport_Registration_Observed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""provider_registration_status"": "
         & Q (Status_Name (Startup_Report.Registration.Status)) & ",");
      Ada.Text_IO.Put_Line ("  ""provider_unique_name_received"": " & (if Provider_Unique_Name_Received then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""provider_application_object_path_available"": " & (if Provider_Object_Path_Available then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""provider_child_object_path_available"": " & (if Child_Object_Path_Available then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""client_discovered_accessibility_address"": " & (if Client_Discovered_Address then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""client_raw_connected"": " & (if Client_Raw_Connected then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""client_hello_completed"": " & (if Client_Hello_Completed then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_method_call_encoded"": " & (if Request_Encoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_method_call_sent"": " & (if Request_Sent then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""provider_event_loop_driven"": " & (if Provider_Event_Loop_Driven then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""provider_dispatched_external_request"": " & (if Provider_Dispatched_Request then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""provider_wrote_external_reply"": " & (if Provider_Wrote_Reply then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""client_reply_received"": " & (if Client_Reply_Received then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""client_reply_decoded"": " & (if Client_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""client_reply_name_matched"": " & (if Client_Reply_Name_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_role_reply_decoded"": " & (if Client_Role_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_role_matched"": " & (if Client_Role_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_count_reply_decoded"": " & (if Client_Child_Count_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_count_matched"": " & (if Client_Child_Count_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_at_index_reply_decoded"": " & (if Client_Child_At_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_at_index_matched"": " & (if Client_Child_At_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_name_reply_decoded"": " & (if Client_Child_Name_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_name_matched"": " & (if Client_Child_Name_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_role_reply_decoded"": " & (if Client_Child_Role_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_role_matched"": " & (if Client_Child_Role_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_description_reply_decoded"": " & (if Client_Child_Description_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_description_matched"": " & (if Client_Child_Description_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_attributes_reply_decoded"": " & (if Client_Child_Attributes_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_attributes_matched"": " & (if Client_Child_Attributes_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_help_text_attribute_matched"": " & (if Reply_Child_Help_Text_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_placeholder_attribute_matched"": " & (if Reply_Child_Placeholder_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_value_text_attribute_matched"": " & (if Reply_Child_Value_Text_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_visible_title_attribute_matched"": " & (if Reply_Child_Visible_Title_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_keyboard_shortcut_attribute_matched"": " & (if Reply_Child_Keyboard_Shortcut_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_semantic_identifier_attribute_matched"": " & (if Reply_Child_Semantic_Identifier_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_locale_attribute_matched"": " & (if Reply_Child_Locale_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_orientation_attribute_matched"": " & (if Reply_Child_Orientation_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_landmark_attribute_matched"": " & (if Reply_Child_Landmark_Attribute_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_relations_reply_decoded"": " & (if Client_Child_Relations_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_child_relations_matched"": " & (if Client_Child_Relations_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_component_extents_reply_decoded"": " & (if Client_Component_Extents_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_component_extents_matched"": " & (if Client_Component_Extents_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_component_contains_reply_decoded"": " & (if Client_Component_Contains_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_component_contains_matched"": " & (if Client_Component_Contains_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_component_hit_reply_decoded"": " & (if Client_Component_Hit_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_component_hit_matched"": " & (if Client_Component_Hit_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_action_count_reply_decoded"": " & (if Client_Action_Count_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_action_count_matched"": " & (if Client_Action_Count_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_action_name_reply_decoded"": " & (if Client_Action_Name_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_action_name_matched"": " & (if Client_Action_Name_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_action_invoke_reply_decoded"": " & (if Client_Action_Invoke_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_action_invoke_matched"": " & (if Client_Action_Invoke_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_current_reply_decoded"": " & (if Client_Value_Current_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_current_matched"": " & (if Client_Value_Current_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_minimum_reply_decoded"": " & (if Client_Value_Minimum_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_minimum_matched"": " & (if Client_Value_Minimum_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_maximum_reply_decoded"": " & (if Client_Value_Maximum_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_maximum_matched"": " & (if Client_Value_Maximum_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_increment_reply_decoded"": " & (if Client_Value_Increment_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_increment_matched"": " & (if Client_Value_Increment_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_set_reply_decoded"": " & (if Client_Value_Set_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_value_set_matched"": " & (if Client_Value_Set_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_count_reply_decoded"": " & (if Client_Selection_Count_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_count_matched"": " & (if Client_Selection_Count_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_selected_reply_decoded"": " & (if Client_Selection_Selected_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_selected_matched"": " & (if Client_Selection_Selected_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_is_reply_decoded"": " & (if Client_Selection_Is_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_is_matched"": " & (if Client_Selection_Is_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_select_reply_decoded"": " & (if Client_Selection_Select_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_select_matched"": " & (if Client_Selection_Select_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_deselect_reply_decoded"": " & (if Client_Selection_Deselect_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_deselect_matched"": " & (if Client_Selection_Deselect_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_select_all_reply_decoded"": " & (if Client_Selection_Select_All_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_select_all_matched"": " & (if Client_Selection_Select_All_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_clear_reply_decoded"": " & (if Client_Selection_Clear_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_selection_clear_matched"": " & (if Client_Selection_Clear_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_text_count_reply_decoded"": " & (if Client_Text_Count_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_text_count_matched"": " & (if Client_Text_Count_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_text_caret_reply_decoded"": " & (if Client_Text_Caret_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_text_caret_matched"": " & (if Client_Text_Caret_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_text_range_reply_decoded"": " & (if Client_Text_Range_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_text_range_matched"": " & (if Client_Text_Range_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_description_reply_decoded"": " & (if Client_Image_Description_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_description_matched"": " & (if Client_Image_Description_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_caption_reply_decoded"": " & (if Client_Image_Caption_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_caption_matched"": " & (if Client_Image_Caption_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_kind_reply_decoded"": " & (if Client_Image_Kind_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_kind_matched"": " & (if Client_Image_Kind_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_size_reply_decoded"": " & (if Client_Image_Size_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_image_size_matched"": " & (if Client_Image_Size_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_document_locale_reply_decoded"": " & (if Client_Document_Locale_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_document_locale_matched"": " & (if Client_Document_Locale_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_document_landmark_reply_decoded"": " & (if Client_Document_Landmark_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_document_landmark_matched"": " & (if Client_Document_Landmark_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_document_title_reply_decoded"": " & (if Client_Document_Title_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_document_title_matched"": " & (if Client_Document_Title_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_row_count_reply_decoded"": " & (if Client_Table_Row_Count_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_row_count_matched"": " & (if Client_Table_Row_Count_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_column_count_reply_decoded"": " & (if Client_Table_Column_Count_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_column_count_matched"": " & (if Client_Table_Column_Count_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_cell_reply_decoded"": " & (if Client_Table_Cell_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_cell_matched"": " & (if Client_Table_Cell_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_row_extent_reply_decoded"": " & (if Client_Table_Row_Extent_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_row_extent_matched"": " & (if Client_Table_Row_Extent_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_column_extent_reply_decoded"": " & (if Client_Table_Column_Extent_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_column_extent_matched"": " & (if Client_Table_Column_Extent_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_current_cell_reply_decoded"": " & (if Client_Table_Current_Cell_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_current_cell_matched"": " & (if Client_Table_Current_Cell_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_sort_order_reply_decoded"": " & (if Client_Table_Sort_Order_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_sort_order_matched"": " & (if Client_Table_Sort_Order_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_sort_key_reply_decoded"": " & (if Client_Table_Sort_Key_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_table_sort_key_matched"": " & (if Client_Table_Sort_Key_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_kind_reply_decoded"": " & (if Client_Surface_Kind_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_kind_matched"": " & (if Client_Surface_Kind_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_role_reply_decoded"": " & (if Client_Surface_Role_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_role_matched"": " & (if Client_Surface_Role_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_top_level_reply_decoded"": " & (if Client_Surface_Top_Level_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_top_level_matched"": " & (if Client_Surface_Top_Level_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_modal_reply_decoded"": " & (if Client_Surface_Modal_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_modal_matched"": " & (if Client_Surface_Modal_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_visible_reply_decoded"": " & (if Client_Surface_Visible_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_visible_matched"": " & (if Client_Surface_Visible_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_active_reply_decoded"": " & (if Client_Surface_Active_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_active_matched"": " & (if Client_Surface_Active_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_can_close_reply_decoded"": " & (if Client_Surface_Can_Close_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_surface_can_close_matched"": " & (if Client_Surface_Can_Close_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_setting_reply_decoded"": " & (if Client_Live_Setting_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_setting_matched"": " & (if Client_Live_Setting_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_relevant_reply_decoded"": " & (if Client_Live_Relevant_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_relevant_matched"": " & (if Client_Live_Relevant_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_atomic_reply_decoded"": " & (if Client_Live_Atomic_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_atomic_matched"": " & (if Client_Live_Atomic_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_assertive_reply_decoded"": " & (if Client_Live_Assertive_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_assertive_matched"": " & (if Client_Live_Assertive_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_externally_announced_reply_decoded"": " & (if Client_Live_Externally_Announced_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_live_externally_announced_matched"": " & (if Client_Live_Externally_Announced_Matched then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_protected_attributes_reply_decoded"": " & (if Client_Protected_Attributes_Reply_Decoded then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""external_protected_value_suppressed"": " & (if Client_Protected_Value_Suppressed then "true" else "false") & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_traversal_completed"": "
         & (if External_Traversal_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_core_slice_completed"": "
         & (if External_Core_Slice_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_interaction_slice_completed"": "
         & (if External_Interaction_Slice_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_content_slice_completed"": "
         & (if External_Content_Slice_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_surface_slice_completed"": "
         & (if External_Surface_Slice_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""external_live_region_slice_completed"": "
         & (if External_Live_Region_Slice_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line ("  ""event_loop_steps_attempted"": " & Trimmed (Natural'Image (Total_Event_Loop_Steps)) & ",");
      Ada.Text_IO.Put_Line ("  ""event_loop_registered_method_calls"": " & Trimmed (Natural'Image (Total_Registered_Method_Calls)) & ",");
      Ada.Text_IO.Put_Line ("  ""event_loop_registered_replies"": " & Trimmed (Natural'Image (Total_Registered_Replies)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_name_length"": " & Trimmed (Natural'Image (Length (Reply_Name))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_role"": " & Trimmed (Natural'Image (Reply_Role)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_count"": " & Trimmed (Natural'Image (Reply_Child_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_path_length"": " & Trimmed (Natural'Image (Length (Reply_Child_Path))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_name_length"": " & Trimmed (Natural'Image (Length (Reply_Child_Name))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_role"": " & Trimmed (Natural'Image (Reply_Child_Role)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_description_length"": " & Trimmed (Natural'Image (Length (Reply_Child_Description))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_attribute_count"": " & Trimmed (Natural'Image (Natural (Reply_Child_Attributes.Length))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_relation_count"": " & Trimmed (Natural'Image (Natural (Reply_Child_Relations.Length))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_first_relation_kind"": " & Trimmed (Natural'Image (Reply_Child_First_Relation_Kind)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_child_first_relation_target"": " & Trimmed (Natural'Image (Reply_Child_First_Relation_Target)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_component_bounds_x"": " & Trimmed (A11y.Geometry.Coordinate'Image (Reply_Component_Bounds.Origin.X)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_component_bounds_y"": " & Trimmed (A11y.Geometry.Coordinate'Image (Reply_Component_Bounds.Origin.Y)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_component_bounds_width"": " & Trimmed (A11y.Geometry.Length'Image (Reply_Component_Bounds.Extent.Width)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_component_bounds_height"": " & Trimmed (A11y.Geometry.Length'Image (Reply_Component_Bounds.Extent.Height)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_component_contains"": " & (if Reply_Component_Contains then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_component_hit_path_length"": " & Trimmed (Natural'Image (Length (Reply_Component_Hit_Path))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_action_count"": " & Trimmed (Natural'Image (Reply_Action_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_action_name_length"": " & Trimmed (Natural'Image (Length (Reply_Action_Name))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_action_invoke"": " & (if Reply_Action_Invoke then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_value_current"": " & Trimmed (Long_Float'Image (Reply_Value_Current)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_value_minimum"": " & Trimmed (Long_Float'Image (Reply_Value_Minimum)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_value_maximum"": " & Trimmed (Long_Float'Image (Reply_Value_Maximum)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_value_increment"": " & Trimmed (Long_Float'Image (Reply_Value_Increment)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_value_set"": " & (if Reply_Value_Set then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_count"": " & Trimmed (Natural'Image (Reply_Selection_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_selected_path_length"": " & Trimmed (Natural'Image (Length (Reply_Selection_Selected_Path))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_is"": " & (if Reply_Selection_Is then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_select"": " & (if Reply_Selection_Select then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_deselect"": " & (if Reply_Selection_Deselect then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_select_all"": " & (if Reply_Selection_Select_All then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_selection_clear"": " & (if Reply_Selection_Clear then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_text_count"": " & Trimmed (Natural'Image (Reply_Text_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_text_caret"": " & Trimmed (Natural'Image (Reply_Text_Caret)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_text_range_length"": " & Trimmed (Natural'Image (Length (Reply_Text_Range))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_image_description_length"": " & Trimmed (Natural'Image (Length (Reply_Image_Description))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_image_caption_length"": " & Trimmed (Natural'Image (Length (Reply_Image_Caption))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_image_kind_length"": " & Trimmed (Natural'Image (Length (Reply_Image_Kind))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_image_width"": " & Trimmed (A11y.Geometry.Length'Image (Reply_Image_Size.Width)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_image_height"": " & Trimmed (A11y.Geometry.Length'Image (Reply_Image_Size.Height)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_document_locale_length"": " & Trimmed (Natural'Image (Length (Reply_Document_Locale))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_document_landmark"": " & (if Reply_Document_Landmark then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_document_title_length"": " & Trimmed (Natural'Image (Length (Reply_Document_Title))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_row_count"": " & Trimmed (Natural'Image (Reply_Table_Row_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_column_count"": " & Trimmed (Natural'Image (Reply_Table_Column_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_cell_path_length"": " & Trimmed (Natural'Image (Length (Reply_Table_Cell_Path))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_row_extent"": " & Trimmed (Natural'Image (Reply_Table_Row_Extent)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_column_extent"": " & Trimmed (Natural'Image (Reply_Table_Column_Extent)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_current_cell_path_length"": " & Trimmed (Natural'Image (Length (Reply_Table_Current_Cell_Path))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_sort_order"": " & Trimmed (Natural'Image (Reply_Table_Sort_Order)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_table_sort_key_path_length"": " & Trimmed (Natural'Image (Length (Reply_Table_Sort_Key_Path))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_kind_length"": " & Trimmed (Natural'Image (Length (Reply_Surface_Kind))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_role"": " & Trimmed (Natural'Image (Reply_Surface_Role)) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_top_level"": " & (if Reply_Surface_Top_Level then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_modal"": " & (if Reply_Surface_Modal then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_visible"": " & (if Reply_Surface_Visible then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_active"": " & (if Reply_Surface_Active then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_surface_can_close"": " & (if Reply_Surface_Can_Close then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_live_setting_length"": " & Trimmed (Natural'Image (Length (Reply_Live_Setting))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_live_relevant_length"": " & Trimmed (Natural'Image (Length (Reply_Live_Relevant))) & ",");
      Ada.Text_IO.Put_Line ("  ""reply_live_atomic"": " & (if Reply_Live_Atomic then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_live_assertive"": " & (if Reply_Live_Assertive then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_live_externally_announced"": " & (if Reply_Live_Externally_Announced then "true" else "false") & ",");
      Ada.Text_IO.Put_Line ("  ""reply_protected_attribute_count"": " & Trimmed (Natural'Image (Natural (Reply_Protected_Attributes.Length))) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_registry_before_live"": " & Trimmed (Natural'Image (Stop_Report.Registry_Before.Live_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_registry_after_live"": " & Trimmed (Natural'Image (Stop_Report.Registry_After.Live_Count)) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_registry_before_outstanding"": " & Trimmed (Natural'Image (Stop_Report.Registry_Before.Outstanding_Calls)) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_registry_after_outstanding"": " & Trimmed (Natural'Image (Stop_Report.Registry_After.Outstanding_Calls)) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_registry_status"": " & Q (Status_Name (Stop_Report.Registry_Status)) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_backend_status"": " & Q (Status_Name (Stop_Report.Backend_Status)) & ",");
      Ada.Text_IO.Put_Line ("  ""failure_stage"": " & Q (Failure_Stage) & ",");
      Ada.Text_IO.Put_Line ("  ""status"": " & Q (Status_Name (Final_Status)) & ",");
      Ada.Text_IO.Put_Line ("  ""stop_status"": " & Q (Status_Name (Stop_Result.Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         A11y.Linux.ATSPi_Local_Channel.Close (Client_Channel);
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Provider, Stop_Result);
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_external_client_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line
           ("  ""session_address_supplied"": "
            & (if Session_Address_Supplied then "true" else "false")
            & ",");
         Ada.Text_IO.Put_Line ("  ""provider_started"": false,");
         Ada.Text_IO.Put_Line ("  ""provider_registered"": false,");
         Ada.Text_IO.Put_Line ("  ""provider_unique_name_received"": false,");
         Ada.Text_IO.Put_Line ("  ""provider_application_object_path_available"": false,");
         Ada.Text_IO.Put_Line ("  ""client_discovered_accessibility_address"": false,");
         Ada.Text_IO.Put_Line ("  ""client_raw_connected"": false,");
         Ada.Text_IO.Put_Line ("  ""client_hello_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""external_method_call_encoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_method_call_sent"": false,");
         Ada.Text_IO.Put_Line ("  ""provider_event_loop_driven"": false,");
         Ada.Text_IO.Put_Line ("  ""provider_dispatched_external_request"": false,");
         Ada.Text_IO.Put_Line ("  ""provider_wrote_external_reply"": false,");
         Ada.Text_IO.Put_Line ("  ""client_reply_received"": false,");
         Ada.Text_IO.Put_Line ("  ""client_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""client_reply_name_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_role_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_role_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_count_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_at_index_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_at_index_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_name_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_name_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_role_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_role_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_description_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_description_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_attributes_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_attributes_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_help_text_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_placeholder_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_value_text_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_visible_title_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_keyboard_shortcut_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_semantic_identifier_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_locale_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_orientation_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_landmark_attribute_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_relations_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_child_relations_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_component_extents_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_component_extents_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_component_contains_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_component_contains_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_component_hit_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_component_hit_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_action_count_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_action_count_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_action_name_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_action_name_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_action_invoke_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_action_invoke_matched"": false,");
         Ada.Text_IO.Put_Line ("  ""external_protected_attributes_reply_decoded"": false,");
         Ada.Text_IO.Put_Line ("  ""external_protected_value_suppressed"": false,");
         Ada.Text_IO.Put_Line ("  ""external_traversal_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""external_core_slice_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""external_interaction_slice_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""external_content_slice_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""external_surface_slice_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""external_live_region_slice_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""failure_stage"": ""exception"",");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""stop_status"": " & Q (Status_Name (Stop_Result.Status)));
         Ada.Text_IO.Put_Line ("}");
   end Emit_External_Client_Session_Probe;

   procedure Emit_Probe
     (Address          : String;
      User_Id          : A11y.Linux.DBus_Auth.External_User_Id;
      From_Environment : Boolean := False;
      From_Host_Environment : Boolean := False)
   is
      Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Result : A11y.Results.Result;
      Stop_Result : A11y.Results.Result;
      Session_View :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      Startup_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report;
      Prepared : Boolean := False;
      Started : Boolean := False;
      Final_Status : A11y.Results.Status_Code := A11y.Results.Success;
   begin
      if From_Host_Environment then
         A11y.Linux.ATSPi_Backend_Sessions
           .Start_From_Host_Environment_With_Report
           (Session, User_Id, A11y.Node_Ids.From_Natural (1),
            Startup_Report, Result);
      elsif From_Environment then
         A11y.Linux.ATSPi_Backend_Sessions
           .Start_From_Environment_Value_With_Report
           (Session, Address, User_Id, A11y.Node_Ids.From_Natural (1),
            Startup_Report, Result);
      else
         A11y.Linux.ATSPi_Backend_Sessions.Start_From_Address_With_Report
           (Session, Address, User_Id, A11y.Node_Ids.From_Natural (1),
            Startup_Report, Result);
      end if;
      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Session, Session_View);
      Final_Status :=
        (if A11y.Results.Failed (Result)
         then Result.Status
         else Session_View.Transport.Last_Status);
      Prepared := Startup_Report.Prepared;
      Started :=
        A11y.Results.Succeeded (Result)
        and then Session_View.Transport.State =
          A11y.Backends.Native_Backends.Transport_Running;

      A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Stop_Result);
      if A11y.Results.Succeeded ((Status => Final_Status))
        and then A11y.Results.Failed (Stop_Result)
      then
         Final_Status := Stop_Result.Status;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Linux_ATSPI))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line
        ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line
        ("  ""address_supplied"": "
         & (if From_Host_Environment then "false" else "true")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_environment_used"": "
         & (if From_Host_Environment then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_source"": "
         & Q
           (A11y.Linux.ATSPi_Backend_Sessions.Startup_Source_Name
              (Startup_Report.Source))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_at_spi_bus_address_present"": "
         & (if Startup_Report.Host_AT_SPI_Address_Present
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_session_bus_address_present"": "
         & (if Startup_Report.Host_Session_Bus_Address_Present
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""host_discovery_source"": "
         & Q
           (A11y.Linux.ATSPi_Backend_Sessions.Startup_Source_Name
              (Startup_Report.Source))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_discovery_attempted"": "
         & (if Startup_Report.Discovery_Attempted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_discovery_raw_connect_attempted"": "
         & (if Startup_Report.Discovery.Raw_Connect_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_discovery_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Discovery.Raw_Connect_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_discovery_get_address_reply_status"": "
         & Q
             (Status_Name
                (Startup_Report.Discovery.Get_Address_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_discovery_get_address_reply_error_name"": "
         & Q
             (To_String
                (Startup_Report.Discovery.Get_Address_Reply_Error_Name))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_discovery_get_address_completed"": "
         & (if Startup_Report.Discovery.Get_Address_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""prepared"": " & (if Prepared then "true" else "false") & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_prepared"": "
         & (if Startup_Report.Prepared then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_synchronized"": "
         & (if Startup_Report.Backend_Synchronized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_status"": "
         & Q (Status_Name (Startup_Report.Backend_Synchronization.Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_before_state"": "
         & Q
           (A11y.Backends.Native_Backends.Name
              (Startup_Report.Backend_Synchronization.Backend_Before.State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_after_state"": "
         & Q
           (A11y.Backends.Native_Backends.Name
              (Startup_Report.Backend_Synchronization.Backend_After.State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_failure_record_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Failure_Record_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_transport_admission_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Transport_Admission_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_start_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Backend_Start_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_application_root_ensured"": "
         & (if Startup_Report.Application_Root_Ensured
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_resolved"": "
         & (if Startup_Report.Registration.Address_Resolved
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_transport"": "
         & Q
             (A11y.Linux.ATSPi_Bus.Transport_Name
                (Startup_Report.Registration.Address_Transport))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_field_count"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration.Address_Field_Count))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_uses_path"": "
         & (if Startup_Report.Registration.Address_Uses_Path
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_uses_abstract"": "
         & (if Startup_Report.Registration.Address_Uses_Abstract
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_raw_connect_attempted"": "
         & (if Startup_Report.Registration.Raw_Connect_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Registration.Raw_Connect_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_raw_connected"": "
         & (if Startup_Report.Registration.Raw_Connected
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_auth_sent"": "
         & (if Startup_Report.Registration.Auth_Sent then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_auth_response_status"": "
         & Q (Status_Name (Startup_Report.Registration.Auth_Response_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_auth_accepted"": "
         & (if Startup_Report.Registration.Auth_Accepted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_begin_sent"": "
         & (if Startup_Report.Registration.Begin_Sent
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_transport_admitted"": "
         & (if Startup_Report.Registration.Transport_Admitted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_queued"": "
         & (if Startup_Report.Registration.Hello_Queued
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_sent"": "
         & (if Startup_Report.Registration.Hello_Sent
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_reply_received"": "
         & (if Startup_Report.Registration.Hello_Reply_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_reply_serial"": "
         & Trimmed
             (Natural'Image (Startup_Report.Registration.Hello_Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_reply_status"": "
         & Q (Status_Name (Startup_Report.Registration.Hello_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_completed"": "
         & (if Startup_Report.Registration.Hello_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_unique_name_received"": "
         & (if Startup_Report.Registration.Unique_Name_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_unique_name_length"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration.Unique_Name_Length))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_unique_name_has_bus_prefix"": "
         & (if Startup_Report.Registration.Unique_Name_Has_Bus_Prefix
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_available"": "
         & (if Startup_Report.Registration.Application_Object_Path_Available
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_length"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration
                   .Application_Object_Path_Length))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_has_session_prefix"": "
         & (if Startup_Report.Registration
              .Application_Object_Path_Has_Session_Prefix
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_has_node_suffix"": "
         & (if Startup_Report.Registration.Application_Object_Path_Has_Node_Suffix
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_queued"": "
         & (if Startup_Report.Registration.Registration_Queued
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_sent"": "
         & (if Startup_Report.Registration.Registration_Sent
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_received"": "
         & (if Startup_Report.Registration.Registration_Reply_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_serial"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration.Registration_Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_was_error_return"": "
         & (if Startup_Report.Registration.Registration_Reply_Was_Error_Return
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_status"": "
         & Q
             (Status_Name
                (Startup_Report.Registration.Registration_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_error_name"": "
         & Q
             (To_String
                (Startup_Report.Registration.Registration_Reply_Error_Name))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_completed"": "
         & (if Startup_Report.Registration.Registration_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_transport_registration_observed"": "
         & (if Startup_Report.Registration.Transport_Registration_Observed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_pending_outgoing"": "
         & Trimmed
             (Natural'Image (Startup_Report.Registration.Pending_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_in_flight_outgoing"": "
         & Trimmed
             (Natural'Image (Startup_Report.Registration.In_Flight_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_stage_status"": "
         & Q (Status_Name (Startup_Report.Registration.Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""started"": " & (if Started then "true" else "false") & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered"": "
         & (if Session_View.Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_can_read"": "
         & (if Session_View.Interest.Can_Read then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_can_write"": "
         & (if Session_View.Interest.Can_Write then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_can_dispatch"": "
         & (if Session_View.Interest.Can_Dispatch then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_has_outgoing_work"": "
         & (if Session_View.Interest.Has_Outgoing_Work
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_next_operation"": "
         & Q (Operation_Name (Session_View.Interest.Next_Operation))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_pump_status"": "
         & Q (Status_Name (Session_View.Interest.Pump_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_pending_outgoing"": "
         & Trimmed (Natural'Image (Session_View.Interest.Pending_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_pending_capacity"": "
         & Trimmed (Natural'Image (Session_View.Interest.Pending_Capacity))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_pending_overflowed"": "
         & (if Session_View.Interest.Pending_Overflowed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_in_flight_outgoing"": "
         & Trimmed (Natural'Image (Session_View.Interest.In_Flight_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""event_loop_in_flight_capacity"": "
         & Trimmed (Natural'Image (Session_View.Interest.In_Flight_Capacity))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state"": "
         & Q (State_Name (Session_View.Startup_State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": " & Q (Status_Name (Final_Status)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""stop_status"": " & Q (Status_Name (Stop_Result.Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""client_process"": "
            & Q (A11y_Native_Client_Reports.Client_Process_Name
                   (A11y_Native_Client_Reports.Linux_ATSPI))
            & ",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line
           ("  ""address_supplied"": "
            & (if From_Host_Environment then "false" else "true")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""host_environment_used"": "
            & (if From_Host_Environment then "true" else "false")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""startup_source"": "
            & Q
              (if From_Host_Environment
               then "error"
               elsif From_Environment
               then "environment_value"
               else "direct_address")
            & ",");
         Ada.Text_IO.Put_Line
           ("  ""host_at_spi_bus_address_present"": false,");
         Ada.Text_IO.Put_Line
           ("  ""host_session_bus_address_present"": false,");
         Ada.Text_IO.Put_Line
           ("  ""host_discovery_source"": ""error"",");
         Ada.Text_IO.Put_Line
           ("  ""startup_discovery_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""startup_discovery_raw_connect_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""startup_discovery_raw_connect_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""startup_discovery_get_address_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""startup_discovery_get_address_reply_error_name"": """",");
         Ada.Text_IO.Put_Line
           ("  ""startup_discovery_get_address_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""startup_prepared"": false,");
         Ada.Text_IO.Put_Line
           ("  ""startup_backend_synchronized"": false,");
         Ada.Text_IO.Put_Line
           ("  ""startup_application_root_ensured"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_address_resolved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_raw_connect_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_raw_connect_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""registration_raw_connected"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_auth_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_auth_response_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""registration_auth_accepted"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_begin_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_transport_admitted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_queued"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_hello_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_reply_received"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_queued"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_received"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_was_error_return"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_transport_registration_observed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_pending_outgoing"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_in_flight_outgoing"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_stage_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""started"": false,");
         Ada.Text_IO.Put_Line ("  ""registered"": false,");
         Ada.Text_IO.Put_Line ("  ""event_loop_can_read"": false,");
         Ada.Text_IO.Put_Line ("  ""event_loop_can_write"": false,");
         Ada.Text_IO.Put_Line ("  ""event_loop_can_dispatch"": false,");
         Ada.Text_IO.Put_Line ("  ""event_loop_has_outgoing_work"": false,");
         Ada.Text_IO.Put_Line
           ("  ""event_loop_next_operation"": ""TRANSPORT_FAILED"",");
         Ada.Text_IO.Put_Line
           ("  ""event_loop_pump_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""event_loop_pending_outgoing"": 0,");
         Ada.Text_IO.Put_Line ("  ""event_loop_pending_capacity"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""event_loop_pending_overflowed"": false,");
         Ada.Text_IO.Put_Line ("  ""event_loop_in_flight_outgoing"": 0,");
         Ada.Text_IO.Put_Line ("  ""event_loop_in_flight_capacity"": 0,");
         Ada.Text_IO.Put_Line ("  ""state"": ""FAILED"",");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""stop_status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Probe;

   procedure Emit_Session_Bus_Probe
     (Session_Bus_Address : String;
      User_Id             : A11y.Linux.DBus_Auth.External_User_Id)
   is
      Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;
      Result : A11y.Results.Result;
      Stop_Result : A11y.Results.Result;
      Session_View :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Report;
      Startup_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Session_Startup_Report;
      Discovery_Context : A11y.Linux.ATSPi_Bus.Connection_Context;
      Discovery_Channel : A11y.Linux.ATSPi_Local_Channel.Channel;
      Discovery_Address : A11y.Linux.ATSPi_Bus.Bus_Address;
      Discovery_Report :
        A11y.Linux.ATSPi_Local_Channel.Address_Discovery_Startup_Report;
      Discovery_Result : A11y.Results.Result :=
        (Status => A11y.Results.Backend_Unavailable);
      Prepared : Boolean := False;
      Started : Boolean := False;
      Final_Status : A11y.Results.Status_Code := A11y.Results.Success;
   begin
      A11y.Linux.ATSPi_Bus.Prepare_Connection
        (Discovery_Context, Session_Bus_Address, Discovery_Result);
      if A11y.Results.Succeeded (Discovery_Result) then
         A11y.Linux.ATSPi_Local_Channel
           .Connect_Authenticated_Hello_And_Discover_With_Report
             (Discovery_Context,
              Discovery_Channel,
              User_Id,
              A11y.Resource_Limits.Default_Config,
              Discovery_Address,
              Discovery_Report,
              Discovery_Result);
      end if;
      A11y.Linux.ATSPi_Local_Channel.Close (Discovery_Channel);

      A11y.Linux.ATSPi_Backend_Sessions
        .Start_From_Session_Bus_Address_With_Report
        (Session, Session_Bus_Address, User_Id, A11y.Node_Ids.From_Natural (1),
         Startup_Report,
         Result);
      A11y.Linux.ATSPi_Backend_Sessions.Capture_Report
        (Session, Session_View);
      Final_Status :=
        (if A11y.Results.Failed (Result)
         then Result.Status
         else Session_View.Transport.Last_Status);
      Prepared := Startup_Report.Prepared;
      Started :=
        A11y.Results.Succeeded (Result)
        and then Session_View.Transport.State =
          A11y.Backends.Native_Backends.Transport_Running;

      A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Stop_Result);
      if A11y.Results.Succeeded ((Status => Final_Status))
        and then A11y.Results.Failed (Stop_Result)
      then
         Final_Status := Stop_Result.Status;
      end if;

      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_session_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""client_process"": "
         & Q (A11y_Native_Client_Reports.Client_Process_Name
                (A11y_Native_Client_Reports.Linux_ATSPI))
         & ",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line ("  ""session_address_supplied"": true,");
      Ada.Text_IO.Put_Line
        ("  ""discovery_status"": "
         & Q (Status_Name (Discovery_Result.Status)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_raw_connect_attempted"": "
         & (if Discovery_Report.Raw_Connect_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_raw_connect_status"": "
         & Q (Status_Name (Discovery_Report.Raw_Connect_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_raw_connected"": "
         & (if Discovery_Report.Raw_Connected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_auth_sent"": "
         & (if Discovery_Report.Auth_Sent then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_auth_response_status"": "
         & Q (Status_Name (Discovery_Report.Auth_Response_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_auth_accepted"": "
         & (if Discovery_Report.Auth_Accepted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_hello_completed"": "
         & (if Discovery_Report.Hello_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_get_address_queued"": "
         & (if Discovery_Report.Get_Address_Queued
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_get_address_sent"": "
         & (if Discovery_Report.Get_Address_Sent
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_get_address_reply_received"": "
         & (if Discovery_Report.Get_Address_Reply_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_get_address_reply_status"": "
         & Q (Status_Name (Discovery_Report.Get_Address_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_get_address_reply_error_name"": "
         & Q
             (To_String (Discovery_Report.Get_Address_Reply_Error_Name))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_get_address_completed"": "
         & (if Discovery_Report.Get_Address_Completed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_accessibility_address_state"": "
         & Q
             (Address_State_Name
                (Discovery_Report.Accessibility_Address_State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_accessibility_address_transport"": "
         & Q
             (A11y.Linux.ATSPi_Bus.Transport_Name
                (Discovery_Report.Accessibility_Address_Transport))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_pending_outgoing"": "
         & Trimmed (Natural'Image (Discovery_Report.Pending_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""discovery_in_flight_outgoing"": "
         & Trimmed (Natural'Image (Discovery_Report.In_Flight_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""accessibility_address_prepared"": "
         & (if Prepared then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_prepared"": "
         & (if Startup_Report.Prepared then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_synchronized"": "
         & (if Startup_Report.Backend_Synchronized then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_status"": "
         & Q (Status_Name (Startup_Report.Backend_Synchronization.Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_before_state"": "
         & Q
           (A11y.Backends.Native_Backends.Name
              (Startup_Report.Backend_Synchronization.Backend_Before.State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_after_state"": "
         & Q
           (A11y.Backends.Native_Backends.Name
              (Startup_Report.Backend_Synchronization.Backend_After.State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_failure_record_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Failure_Record_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_transport_admission_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Transport_Admission_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_backend_sync_start_attempted"": "
         & (if Startup_Report.Backend_Synchronization
             .Backend_Start_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""startup_application_root_ensured"": "
         & (if Startup_Report.Application_Root_Ensured then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_resolved"": "
         & (if Startup_Report.Registration.Address_Resolved then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_transport"": "
         & Q
             (A11y.Linux.ATSPi_Bus.Transport_Name
                (Startup_Report.Registration.Address_Transport))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_field_count"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration.Address_Field_Count))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_uses_path"": "
         & (if Startup_Report.Registration.Address_Uses_Path
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_address_uses_abstract"": "
         & (if Startup_Report.Registration.Address_Uses_Abstract
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_raw_connect_attempted"": "
         & (if Startup_Report.Registration.Raw_Connect_Attempted
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_raw_connect_status"": "
         & Q (Status_Name (Startup_Report.Registration.Raw_Connect_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_raw_connected"": "
         & (if Startup_Report.Registration.Raw_Connected then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_auth_sent"": "
         & (if Startup_Report.Registration.Auth_Sent then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_auth_response_status"": "
         & Q (Status_Name (Startup_Report.Registration.Auth_Response_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_auth_accepted"": "
         & (if Startup_Report.Registration.Auth_Accepted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_begin_sent"": "
         & (if Startup_Report.Registration.Begin_Sent then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_transport_admitted"": "
         & (if Startup_Report.Registration.Transport_Admitted then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_queued"": "
         & (if Startup_Report.Registration.Hello_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_sent"": "
         & (if Startup_Report.Registration.Hello_Sent then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_reply_received"": "
         & (if Startup_Report.Registration.Hello_Reply_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_reply_serial"": "
         & Trimmed
             (Natural'Image (Startup_Report.Registration.Hello_Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_reply_status"": "
         & Q (Status_Name (Startup_Report.Registration.Hello_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_hello_completed"": "
         & (if Startup_Report.Registration.Hello_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_unique_name_received"": "
         & (if Startup_Report.Registration.Unique_Name_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_unique_name_length"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration.Unique_Name_Length))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_unique_name_has_bus_prefix"": "
         & (if Startup_Report.Registration.Unique_Name_Has_Bus_Prefix
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_available"": "
         & (if Startup_Report.Registration.Application_Object_Path_Available
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_length"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration
                   .Application_Object_Path_Length))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_has_session_prefix"": "
         & (if Startup_Report.Registration
              .Application_Object_Path_Has_Session_Prefix
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_object_path_has_node_suffix"": "
         & (if Startup_Report.Registration.Application_Object_Path_Has_Node_Suffix
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_queued"": "
         & (if Startup_Report.Registration.Registration_Queued then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_sent"": "
         & (if Startup_Report.Registration.Registration_Sent then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_received"": "
         & (if Startup_Report.Registration.Registration_Reply_Received
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_serial"": "
         & Trimmed
             (Natural'Image
                (Startup_Report.Registration.Registration_Reply_Serial))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_was_error_return"": "
         & (if Startup_Report.Registration.Registration_Reply_Was_Error_Return
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_status"": "
         & Q
             (Status_Name
                (Startup_Report.Registration.Registration_Reply_Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_reply_error_name"": "
         & Q
             (To_String
                (Startup_Report.Registration.Registration_Reply_Error_Name))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_application_completed"": "
         & (if Startup_Report.Registration.Registration_Completed then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_transport_registration_observed"": "
         & (if Startup_Report.Registration.Transport_Registration_Observed
            then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_pending_outgoing"": "
         & Trimmed
             (Natural'Image (Startup_Report.Registration.Pending_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_in_flight_outgoing"": "
         & Trimmed
             (Natural'Image (Startup_Report.Registration.In_Flight_Outgoing))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""registration_stage_status"": "
         & Q (Status_Name (Startup_Report.Registration.Status))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""started"": " & (if Started then "true" else "false") & ",");
      Ada.Text_IO.Put_Line
        ("  ""registered"": "
         & (if Session_View.Registered then "true" else "false")
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""state"": "
         & Q (State_Name (Session_View.Startup_State))
         & ",");
      Ada.Text_IO.Put_Line
        ("  ""status"": " & Q (Status_Name (Final_Status)) & ",");
      Ada.Text_IO.Put_Line
        ("  ""stop_status"": " & Q (Status_Name (Stop_Result.Status)));
      Ada.Text_IO.Put_Line ("}");
   exception
      when others =>
         Ada.Text_IO.Put_Line ("{");
         Ada.Text_IO.Put_Line
           ("  ""schema"": "
            & Q ("org.a11y.native_client_atspi_session_probe.v1")
            & ",");
         Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
         Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
         Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
         Ada.Text_IO.Put_Line ("  ""session_address_supplied"": true,");
         Ada.Text_IO.Put_Line
         ("  ""accessibility_address_prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""startup_prepared"": false,");
         Ada.Text_IO.Put_Line ("  ""startup_backend_synchronized"": false,");
         Ada.Text_IO.Put_Line ("  ""startup_application_root_ensured"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_address_resolved"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_raw_connect_attempted"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_raw_connect_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""registration_raw_connected"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_auth_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_auth_response_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""registration_auth_accepted"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_begin_sent"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_transport_admitted"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_hello_queued"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_hello_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_reply_received"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_hello_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""registration_hello_completed"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_application_queued"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_application_sent"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_received"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_serial"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_was_error_return"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_application_reply_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""registration_application_completed"": false,");
         Ada.Text_IO.Put_Line
           ("  ""registration_transport_registration_observed"": false,");
         Ada.Text_IO.Put_Line ("  ""registration_pending_outgoing"": 0,");
         Ada.Text_IO.Put_Line ("  ""registration_in_flight_outgoing"": 0,");
         Ada.Text_IO.Put_Line
           ("  ""registration_stage_status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""started"": false,");
         Ada.Text_IO.Put_Line ("  ""registered"": false,");
         Ada.Text_IO.Put_Line ("  ""state"": ""FAILED"",");
         Ada.Text_IO.Put_Line ("  ""status"": ""INTERNAL_ERROR"",");
         Ada.Text_IO.Put_Line ("  ""stop_status"": ""INTERNAL_ERROR""");
         Ada.Text_IO.Put_Line ("}");
   end Emit_Session_Bus_Probe;

   Probe_Address : Unbounded_String := Null_Unbounded_String;
   Probe_Environment_Address : Unbounded_String := Null_Unbounded_String;
   Probe_Session_Address : Unbounded_String := Null_Unbounded_String;
   Probe_External_Client_Session_Address : Unbounded_String :=
     Null_Unbounded_String;
   Probe_External_Client_ATSPI_Address : Unbounded_String :=
     Null_Unbounded_String;
   Probe_External_Client_Host_Environment : Boolean := False;
   User_Id : A11y.Linux.DBus_Auth.External_User_Id := Default_User_Id;
   Parse_Result : A11y.Results.Result := A11y.Results.Ok;
   Probe_Boundary : Boolean := False;
   Probe_Fixture_Root : Boolean := False;
   Probe_Serving_Packet : Boolean := False;
   Probe_Session_Dispatch : Boolean := False;
   Probe_Host_Environment : Boolean := False;
begin
   for Index in 1 .. Ada.Command_Line.Argument_Count loop
      declare
         Arg : constant String := Ada.Command_Line.Argument (Index);
      begin
         if Arg = Boundary_Probe_Arg then
            Probe_Boundary := True;
         elsif Arg = Fixture_Root_Probe_Arg then
            Probe_Fixture_Root := True;
         elsif Arg = Serving_Packet_Probe_Arg then
            Probe_Serving_Packet := True;
         elsif Arg = Session_Dispatch_Probe_Arg then
            Probe_Session_Dispatch := True;
         elsif Arg = Probe_Host_Environment_Arg then
            Probe_Host_Environment := True;
         elsif Arg = External_Client_Host_Environment_Arg then
            Probe_External_Client_Host_Environment := True;
         elsif Arg'Length >= Probe_Session_Address_Prefix'Length
           and then Arg
             (Arg'First
              .. Arg'First + Probe_Session_Address_Prefix'Length - 1) =
               Probe_Session_Address_Prefix
         then
            Probe_Session_Address := To_Unbounded_String
              (Arg
                 (Arg'First + Probe_Session_Address_Prefix'Length
                  .. Arg'Last));
         elsif Arg'Length >= External_Client_Session_Probe_Prefix'Length
           and then Arg
             (Arg'First
              .. Arg'First + External_Client_Session_Probe_Prefix'Length - 1) =
               External_Client_Session_Probe_Prefix
         then
            Probe_External_Client_Session_Address := To_Unbounded_String
              (Arg
                 (Arg'First + External_Client_Session_Probe_Prefix'Length
                  .. Arg'Last));
         elsif Arg'Length >= External_Client_ATSPI_Probe_Prefix'Length
           and then Arg
             (Arg'First
              .. Arg'First + External_Client_ATSPI_Probe_Prefix'Length - 1) =
               External_Client_ATSPI_Probe_Prefix
         then
            Probe_External_Client_ATSPI_Address := To_Unbounded_String
              (Arg
                 (Arg'First + External_Client_ATSPI_Probe_Prefix'Length
                  .. Arg'Last));
         elsif Arg'Length >= Probe_Environment_Address_Prefix'Length
           and then Arg
             (Arg'First
              .. Arg'First + Probe_Environment_Address_Prefix'Length - 1) =
               Probe_Environment_Address_Prefix
         then
            Probe_Environment_Address := To_Unbounded_String
              (Arg
                 (Arg'First + Probe_Environment_Address_Prefix'Length
                  .. Arg'Last));
         elsif Arg'Length >= Probe_Address_Prefix'Length
           and then Arg
             (Arg'First .. Arg'First + Probe_Address_Prefix'Length - 1) =
               Probe_Address_Prefix
         then
            Probe_Address := To_Unbounded_String
              (Arg (Arg'First + Probe_Address_Prefix'Length .. Arg'Last));
         elsif Arg'Length >= Probe_UID_Prefix'Length
           and then Arg
             (Arg'First .. Arg'First + Probe_UID_Prefix'Length - 1) =
               Probe_UID_Prefix
         then
            User_Id := Parse_UID
              (Arg (Arg'First + Probe_UID_Prefix'Length .. Arg'Last),
               Parse_Result);
         end if;
      end;
   end loop;

   if A11y.Results.Failed (Parse_Result) then
      Ada.Text_IO.Put_Line ("{");
      Ada.Text_IO.Put_Line
        ("  ""schema"": "
         & Q ("org.a11y.native_client_atspi_probe.v1")
         & ",");
      Ada.Text_IO.Put_Line ("  ""client_process"": ""native_client_atspi"",");
      Ada.Text_IO.Put_Line ("  ""platform"": ""Linux"",");
      Ada.Text_IO.Put_Line ("  ""native_api"": ""AT-SPI2"",");
      Ada.Text_IO.Put_Line ("  ""address_supplied"": false,");
      Ada.Text_IO.Put_Line ("  ""prepared"": false,");
      Ada.Text_IO.Put_Line ("  ""started"": false,");
      Ada.Text_IO.Put_Line ("  ""registered"": false,");
      Ada.Text_IO.Put_Line ("  ""state"": ""FAILED"",");
      Ada.Text_IO.Put_Line ("  ""status"": ""INVALID_ARGUMENT"",");
      Ada.Text_IO.Put_Line ("  ""stop_status"": ""SUCCESS""");
      Ada.Text_IO.Put_Line ("}");
   elsif Probe_Boundary then
      Emit_Boundary_Probe;
   elsif Probe_Fixture_Root then
      Emit_Fixture_Root_Probe;
   elsif Probe_Serving_Packet then
      Emit_Serving_Packet_Probe;
   elsif Probe_Session_Dispatch then
      Emit_Session_Dispatch_Probe;
   elsif Length (Probe_External_Client_Session_Address) /= 0 then
      Emit_External_Client_Session_Probe
        (To_String (Probe_External_Client_Session_Address), User_Id);
   elsif Length (Probe_External_Client_ATSPI_Address) /= 0 then
      Emit_External_Client_Session_Probe
        (To_String (Probe_External_Client_ATSPI_Address), User_Id,
         Direct_ATSPI_Address => True);
   elsif Probe_External_Client_Host_Environment then
      declare
         AT_SPI_Address : constant String :=
           Host_Environment_Value ("AT_SPI_BUS_ADDRESS");
         Session_Address : constant String :=
           Host_Environment_Value ("DBUS_SESSION_BUS_ADDRESS");
      begin
         if AT_SPI_Address'Length /= 0 then
            Emit_External_Client_Session_Probe
              (AT_SPI_Address, User_Id, Direct_ATSPI_Address => True);
         else
            Emit_External_Client_Session_Probe (Session_Address, User_Id);
         end if;
      end;
   elsif Probe_Host_Environment then
      Emit_Probe
        ("",
         User_Id,
         From_Host_Environment => True);
   elsif Length (Probe_Session_Address) /= 0 then
      Emit_Session_Bus_Probe (To_String (Probe_Session_Address), User_Id);
   elsif Length (Probe_Environment_Address) /= 0 then
      Emit_Probe
        (To_String (Probe_Environment_Address),
         User_Id,
         From_Environment => True);
   elsif Length (Probe_Address) /= 0 then
      Emit_Probe (To_String (Probe_Address), User_Id);
   else
      Ada.Text_IO.Put
        (A11y_Native_Client_Reports.JSON
           (A11y_Native_Client_Reports.Linux_ATSPI));
   end if;
end Native_Client_ATSPI;
