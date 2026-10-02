with Ada.Strings.Fixed;
with Ada.Unchecked_Conversion;
with Interfaces;

with A11y.Linux.ATSPi_Objects;
with A11y.Tables;

package body A11y.Linux.DBus_Messages is
   use Ada.Strings.Unbounded;
   use type A11y.Geometry.Coordinate;
   use type A11y.Linux.DBus_Codec.Value_Kind;
   use type A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type Interfaces.Unsigned_32;
   use type Interfaces.Unsigned_64;

   function Empty_Error return Outgoing_Message is
     ((Kind         => Error_Return,
       Serial       => 0,
       Reply_Serial => 0,
       Status       => A11y.Results.Node_Unavailable,
       Object_Path  => Null_Unbounded_String,
       Error_Name   => To_Unbounded_String
         (A11y.Linux.ATSPi_Objects.Error_Name
            (A11y.Results.Node_Unavailable))));

   function Queue_Length (Queue : Outgoing_Queue) return Natural is
     (Natural (Queue.Items.Length));

   function Queue_Capacity (Queue : Outgoing_Queue) return Natural is
     (Queue.Limit);

   function Queue_Overflowed (Queue : Outgoing_Queue) return Boolean is
     (Queue.Had_Overflow);

   function Posting_Interest
     (Queue : Outgoing_Queue)
      return Queue_Posting_Interest
   is
      Length : constant Natural := Queue_Length (Queue);
      Capacity : constant Natural := Queue_Capacity (Queue);
      Overflowed : constant Boolean := Queue_Overflowed (Queue);
      Operation : Queue_Posting_Operation := No_Posting_Operation;
   begin
      if Overflowed then
         Operation := Back_Pressure;
      elsif Length /= 0 then
         Operation := Send_Next_Message;
      end if;

      return
        (Can_Send       => Length /= 0 and then not Overflowed,
         Has_Pending    => Length /= 0,
         Overflowed     => Overflowed,
         Length         => Length,
         Capacity       => Capacity,
         Next_Operation => Operation);
   exception
      when others =>
         return (others => <>);
   end Posting_Interest;

   procedure Configure_Queue
     (Queue  : in out Outgoing_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      end if;

      Set_Queue_Capacity
        (Queue,
         Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Native_Array_Size)),
         Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Configure_Queue;

   procedure Set_Queue_Capacity
     (Queue    : in out Outgoing_Queue;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Capacity = 0 or else Capacity > Max_Queued_Messages then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Capacity < Natural (Queue.Items.Length) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Queue.Limit := Capacity;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Set_Queue_Capacity;

   procedure Enqueue
     (Queue   : in out Outgoing_Queue;
      Message : Outgoing_Message;
      Result  : out A11y.Results.Result)
   is
   begin
      if Message.Kind = Error_Return
        and then (Message.Serial = 0 or else Length (Message.Error_Name) = 0)
      then
         Result := (Status => Message.Status);
      elsif Message.Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Natural (Queue.Items.Length) >= Queue.Limit then
         Queue.Had_Overflow := True;
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Queue.Items.Append (Message);
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Enqueue;

   procedure Peek
     (Queue   : Outgoing_Queue;
      Message : out Outgoing_Message;
      Result  : out A11y.Results.Result)
   is
   begin
      if Queue.Items.Is_Empty then
         Message := Empty_Error;
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Message := Queue.Items.First_Element;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Message := Empty_Error;
         Result := (Status => A11y.Results.Internal_Error);
   end Peek;

   procedure Dequeue
     (Queue   : in out Outgoing_Queue;
      Message : out Outgoing_Message;
      Result  : out A11y.Results.Result)
   is
   begin
      if Queue.Items.Is_Empty then
         Message := Empty_Error;
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Message := Queue.Items.First_Element;
         Queue.Items.Delete_First;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Message := Empty_Error;
         Result := (Status => A11y.Results.Internal_Error);
   end Dequeue;

   procedure Clear (Queue : in out Outgoing_Queue) is
   begin
      Queue.Items.Clear;
      Queue.Had_Overflow := False;
   end Clear;

   function Tracker_Count (Tracker : Outgoing_Tracker) return Natural is
     (Natural (Tracker.Serials.Length));

   function Tracker_Capacity (Tracker : Outgoing_Tracker) return Natural is
     (Tracker.Limit);

   function Tracker_Has_Serial
     (Tracker : Outgoing_Tracker;
      Serial  : Natural)
      return Boolean
   is
   begin
      if Serial = 0 then
         return False;
      end if;

      for Item of Tracker.Serials loop
         if Item = Serial then
            return True;
         end if;
      end loop;
      return False;
   exception
      when others =>
         return False;
   end Tracker_Has_Serial;

   procedure Configure_Tracker
     (Tracker : in out Outgoing_Tracker;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      end if;

      Set_Tracker_Capacity
        (Tracker,
         Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Native_Array_Size)),
         Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Configure_Tracker;

   procedure Set_Tracker_Capacity
     (Tracker  : in out Outgoing_Tracker;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Capacity = 0 or else Capacity > Max_Queued_Messages then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Capacity < Natural (Tracker.Serials.Length) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Tracker.Limit := Capacity;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Set_Tracker_Capacity;

   procedure Mark_Sent
     (Tracker : in out Outgoing_Tracker;
      Message : Outgoing_Message;
      Result  : out A11y.Results.Result)
   is
   begin
      if Message.Kind = Error_Return
        and then (Message.Serial = 0 or else Length (Message.Error_Name) = 0)
      then
         Result := (Status => Message.Status);
      elsif Message.Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Message.Kind /= Method_Call then
         Result := A11y.Results.Ok;
      elsif Natural (Tracker.Serials.Length) >= Tracker.Limit then
         Result := (Status => A11y.Results.Resource_Limit);
      else
         for Serial of Tracker.Serials loop
            if Serial = Message.Serial then
               Result := (Status => A11y.Results.Invalid_State);
               return;
            end if;
         end loop;

         Tracker.Serials.Append (Message.Serial);
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Mark_Sent;

   procedure Complete_Sent
     (Tracker : in out Outgoing_Tracker;
      Serial  : Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      if Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Tracker.Serials.Is_Empty then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         for Index in
           Tracker.Serials.First_Index .. Tracker.Serials.Last_Index
         loop
            if Tracker.Serials.Element (Index) = Serial then
               Tracker.Serials.Delete (Index);
               Result := A11y.Results.Ok;
               return;
            end if;
         end loop;

         Result := (Status => A11y.Results.Node_Unavailable);
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Sent;

   procedure Clear (Tracker : in out Outgoing_Tracker) is
   begin
      Tracker.Serials.Clear;
   end Clear;

   function Empty_Envelope
     (Kind   : Message_Kind;
      Status : A11y.Results.Status_Code)
      return Transport_Envelope is
     ((Kind                      => Kind,
       Serial                    => 0,
       Reply_Serial              => 0,
       Status                    => Status,
       Object_Path               => Null_Unbounded_String,
       Interface_Name            => Null_Unbounded_String,
       Member_Name               => Null_Unbounded_String,
       Error_Name                => To_Unbounded_String
         (A11y.Linux.ATSPi_Objects.Error_Name (Status)),
       Sender_Name               => Null_Unbounded_String,
       Body_Signature            => Null_Unbounded_String,
       Body_Bytes                => Null_Unbounded_String,
       Body_Object_Path_Argument => Null_Unbounded_String,
       Body_String_Argument      => Null_Unbounded_String,
       Body_String_Argument_2    => Null_Unbounded_String,
       Body_UInt32_Argument      => 0,
       Body_UInt32_Argument_2    => 0,
       Body_Point_Argument       => (X => 0, Y => 0),
       Body_Float_Argument       => 0.0));

   function Empty_Frame
     (Kind : Message_Kind)
      return Transport_Frame_Metadata is
   begin
      return
        (Kind               => Kind,
         Serial             => 0,
         Reply_Serial       => 0,
         Header_Field_Count => 0,
         Body_Field_Count   => 0,
         Header_Text_Bytes  => 0,
         Body_Text_Bytes    => 0,
         Estimated_Bytes    => 0);
   end Empty_Frame;

   function Empty_Transport_Frame (Kind : Message_Kind) return Transport_Frame is
     ((Metadata     => Empty_Frame (Kind),
       Header_Bytes => Null_Unbounded_String,
       Body_Bytes   => Null_Unbounded_String));

   function Empty_Transport_Packet (Kind : Message_Kind) return Transport_Packet is
     ((Metadata => Empty_Frame (Kind),
       Bytes    => Null_Unbounded_String));

   function Empty_Packet_Header (Kind : Message_Kind) return Transport_Packet_Header is
     ((Kind                => Kind,
       Serial              => 0,
       Body_Length         => 0,
       Header_Fields_Bytes => 0,
       Header_Length       => 0,
       Packet_Length       => 0));

   function Empty_Incoming_Call (Kind : Message_Kind) return Incoming_Call is
      Empty_Call : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
   begin
      return
        (Header =>
           (Kind           => Kind,
            Serial         => 0,
            Reply_Serial   => 0,
            Object_Path    => Null_Unbounded_String,
            Interface_Name => Null_Unbounded_String,
            Member_Name    => Null_Unbounded_String,
            Error_Name     => Null_Unbounded_String,
            Sender_Name    => Null_Unbounded_String),
         Call => Empty_Call);
   end Empty_Incoming_Call;

   procedure Add_Checked
     (Total  : in out Natural;
      Amount : Natural;
      Result : in out A11y.Results.Result)
   is
   begin
      if A11y.Results.Failed (Result) then
         return;
      elsif Amount > Natural'Last - Total then
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Total := Total + Amount;
      end if;
   end Add_Checked;

   procedure Append_Byte
     (Bytes : in out Unbounded_String;
      Value : Natural) is
   begin
      Append (Bytes, Character'Val (Value mod 256));
   end Append_Byte;

   procedure Append_U32_LE
     (Bytes : in out Unbounded_String;
      Value : Natural) is
      Work : Natural := Value;
   begin
      for Part in 1 .. 4 loop
         pragma Unreferenced (Part);
         Append_Byte (Bytes, Work mod 256);
         Work := Work / 256;
      end loop;
   end Append_U32_LE;

   procedure Append_I32_LE
     (Bytes : in out Unbounded_String;
      Value : Integer)
   is
      function To_Bits is new Ada.Unchecked_Conversion
        (Interfaces.Integer_32, Interfaces.Unsigned_32);
      Work : Interfaces.Unsigned_32 :=
        To_Bits (Interfaces.Integer_32 (Value));
   begin
      for Part in 1 .. 4 loop
         pragma Unreferenced (Part);
         Append_Byte (Bytes, Natural (Work mod Interfaces.Unsigned_32'(256)));
         Work := Work / Interfaces.Unsigned_32'(256);
      end loop;
   end Append_I32_LE;

   procedure Align
     (Bytes     : in out Unbounded_String;
      Alignment : Positive) is
   begin
      while Length (Bytes) mod Alignment /= 0 loop
         Append_Byte (Bytes, 0);
      end loop;
   end Align;

   procedure Append_Boolean
     (Bytes : in out Unbounded_String;
      Value : Boolean) is
   begin
      Align (Bytes, 4);
      Append_U32_LE (Bytes, (if Value then 1 else 0));
   end Append_Boolean;

   procedure Append_Double
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
   end Append_Double;

   procedure Append_DBus_String
     (Bytes : in out Unbounded_String;
      Text  : Unbounded_String);

   procedure Append_State_Set
     (Bytes  : in out Unbounded_String;
      States : A11y.Linux.ATSPi_Mappings.ATSPI_State_Set;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : in out A11y.Results.Result)
   is
      Count       : Natural := 0;
      Byte_Length : Natural;
      Items       : A11y.Linux.DBus_Codec.UInt32_Vectors.Vector;
      Encoded     : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return;
      end if;

      for State in A11y.Linux.ATSPi_Mappings.ATSPI_State loop
         if States (State) then
            Count := Count + 1;
            Items.Append
              (A11y.Linux.ATSPi_Mappings.ATSPI_State'Pos (State));
         end if;
      end loop;

      Encoded := A11y.Linux.DBus_Codec.Make_UInt32_Array
        (Items, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif Encoded.Kind /= A11y.Linux.DBus_Codec.UInt32_Array_Value then
         Result := (Status => A11y.Results.Internal_Error);
         return;
      end if;

      if Count > Natural'Last / 4 then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Byte_Length := Count * 4;
      if A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Byte_Length + 4)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Align (Bytes, 4);
      Append_U32_LE (Bytes, Byte_Length);
      for State in A11y.Linux.ATSPi_Mappings.ATSPI_State loop
         if States (State) then
            Append_U32_LE
              (Bytes, A11y.Linux.ATSPi_Mappings.ATSPI_State'Pos (State));
         end if;
      end loop;
   end Append_State_Set;

   procedure Append_Relation_Set
     (Bytes     : in out Unbounded_String;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Relations :
        A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : in out A11y.Results.Result)
   is
      Relation_Bytes : Unbounded_String := Null_Unbounded_String;
      Target_Count   : Natural := 0;
      Target_Limit   : constant Natural :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Relation_Targets_Returned));

      procedure Check_Byte_Limit (Value : Unbounded_String) is
      begin
         if A11y.Resource_Limits.Exceeded
           (Limits, A11y.Resource_Limits.Native_Array_Size, Length (Value))
         then
            Result := (Status => A11y.Results.Resource_Limit);
         end if;
      end Check_Byte_Limit;
   begin
      if A11y.Results.Failed (Result) then
         return;
      elsif Session = A11y.Native_Identity.No_Session then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      for Relation of Relations loop
         declare
            Target_Bytes : Unbounded_String := Null_Unbounded_String;
            Target_Paths : A11y.Linux.DBus_Codec.String_Vectors.Vector;
            Encoded      : A11y.Linux.DBus_Codec.DBus_Value;
         begin
            if Natural (Relation.Targets.Length) > Target_Limit - Target_Count
            then
               Result := (Status => A11y.Results.Resource_Limit);
               return;
            end if;
            Target_Count := Target_Count + Natural (Relation.Targets.Length);

            for Target of Relation.Targets loop
               declare
                  Path : constant Unbounded_String :=
                    A11y.Linux.ATSPi_Objects.Object_Path
                      (Session, Target, Result);
               begin
                  if A11y.Results.Failed (Result) then
                     return;
                  end if;

                  Target_Paths.Append (Path);
               end;
            end loop;

            Encoded := A11y.Linux.DBus_Codec.Make_Object_Path_Array
              (Target_Paths, Limits, Result);
            if A11y.Results.Failed (Result) then
               return;
            elsif Encoded.Kind /=
              A11y.Linux.DBus_Codec.Object_Path_Array_Value
            then
               Result := (Status => A11y.Results.Internal_Error);
               return;
            end if;

            for Path of Target_Paths loop
               Append_DBus_String (Target_Bytes, Path);
               Check_Byte_Limit (Target_Bytes);
               if A11y.Results.Failed (Result) then
                  return;
               end if;
            end loop;

            Align (Relation_Bytes, 8);
            Append_U32_LE
              (Relation_Bytes,
               A11y.Linux.ATSPi_Mappings.ATSPI_Relation'Pos
                 (Relation.Kind));
            Align (Relation_Bytes, 4);
            Append_U32_LE (Relation_Bytes, Length (Target_Bytes));
            Append (Relation_Bytes, Target_Bytes);
            Check_Byte_Limit (Relation_Bytes);
            if A11y.Results.Failed (Result) then
               return;
            end if;
         end;
      end loop;

      Align (Bytes, 4);
      Append_U32_LE (Bytes, Length (Relation_Bytes));
      Align (Bytes, 8);
      Append (Bytes, Relation_Bytes);
   end Append_Relation_Set;

   procedure Append_Attribute_Set
     (Bytes      : in out Unbounded_String;
      Attributes :
        A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Result     : in out A11y.Results.Result)
   is
      Attribute_Bytes : Unbounded_String := Null_Unbounded_String;
      Attribute_Strings : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;

      procedure Check_Byte_Limit (Value : Unbounded_String) is
      begin
         if A11y.Resource_Limits.Exceeded
           (Limits, A11y.Resource_Limits.Native_Array_Size, Length (Value))
         then
            Result := (Status => A11y.Results.Resource_Limit);
         end if;
      end Check_Byte_Limit;
   begin
      if A11y.Results.Failed (Result) then
         return;
      end if;

      for Attribute of Attributes loop
         declare
            Ignored : A11y.Linux.DBus_Codec.DBus_Value;
         begin
            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Attribute.Key), Limits, Result);
            if A11y.Results.Failed (Result) then
               return;
            end if;
            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Attribute.Value), Limits, Result);
            if A11y.Results.Failed (Result) then
               return;
            end if;

            Attribute_Strings.Append (Attribute.Key);
            Attribute_Strings.Append (Attribute.Value);
         end;
      end loop;

      Encoded := A11y.Linux.DBus_Codec.Make_String_Array
        (Attribute_Strings, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif Encoded.Kind /= A11y.Linux.DBus_Codec.String_Array_Value then
         Result := (Status => A11y.Results.Internal_Error);
         return;
      end if;

      for Attribute of Attributes loop
         Align (Attribute_Bytes, 8);
         Append_DBus_String (Attribute_Bytes, Attribute.Key);
         Append_DBus_String (Attribute_Bytes, Attribute.Value);
         Check_Byte_Limit (Attribute_Bytes);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end loop;

      Align (Bytes, 4);
      Append_U32_LE (Bytes, Length (Attribute_Bytes));
      Align (Bytes, 8);
      Append (Bytes, Attribute_Bytes);
   end Append_Attribute_Set;

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

   procedure Append_Field_U32
     (Fields : in out Unbounded_String;
      Code   : Natural;
      Value  : Natural) is
   begin
      Align (Fields, 8);
      Append_Byte (Fields, Code);
      Append_DBus_Signature (Fields, "u");
      Align (Fields, 4);
      Append_U32_LE (Fields, Value);
   end Append_Field_U32;

   procedure Append_Field_Signature
     (Fields : in out Unbounded_String;
      Code   : Natural;
      Value  : String) is
   begin
      Align (Fields, 8);
      Append_Byte (Fields, Code);
      Append_DBus_Signature (Fields, "g");
      Append_DBus_Signature (Fields, Value);
   end Append_Field_Signature;

   function Message_Type_Byte (Kind : Message_Kind) return Natural is
     (case Kind is
        when Method_Call    => 1,
        when Method_Return  => 2,
        when Error_Return   => 3,
        when Signal_Message => 4);

   function Kind_From_Message_Type
     (Value  : Natural;
      Result : out A11y.Results.Result)
      return Message_Kind is
   begin
      case Value is
         when 1 =>
            Result := A11y.Results.Ok;
            return Method_Call;
         when 2 =>
            Result := A11y.Results.Ok;
            return Method_Return;
         when 3 =>
            Result := A11y.Results.Ok;
            return Error_Return;
         when 4 =>
            Result := A11y.Results.Ok;
            return Signal_Message;
         when others =>
            Result := (Status => A11y.Results.Unsupported_Capability);
            return Error_Return;
      end case;
   end Kind_From_Message_Type;

   function Byte_At (Text : String; Index : Positive) return Natural is
     (Character'Pos (Text (Index)));

   function Read_U32_LE (Text : String; Index : Positive) return Natural is
     (Byte_At (Text, Index)
      + Byte_At (Text, Index + 1) * 256
      + Byte_At (Text, Index + 2) * 65_536
      + Byte_At (Text, Index + 3) * 16_777_216);

   function Read_I32_LE (Text : String; Index : Positive) return Integer is
      function To_Signed is new Ada.Unchecked_Conversion
        (Interfaces.Unsigned_32, Interfaces.Integer_32);
      Value : constant Natural := Read_U32_LE (Text, Index);
   begin
      return Integer
        (To_Signed (Interfaces.Unsigned_32 (Value)));
   end Read_I32_LE;

   function Read_U64_LE
     (Text  : String;
      Index : Positive)
      return Interfaces.Unsigned_64
   is
      Value : Interfaces.Unsigned_64 := 0;
      Shift : Interfaces.Unsigned_64 := 1;
   begin
      for Offset in 0 .. 7 loop
         Value := Value
           + Interfaces.Unsigned_64 (Byte_At (Text, Index + Offset))
             * Shift;
         if Offset < 7 then
            Shift := Shift * Interfaces.Unsigned_64'(256);
         end if;
      end loop;
      return Value;
   end Read_U64_LE;

   function Read_Double_LE (Text : String; Index : Positive) return Long_Float is
      function To_Float is new Ada.Unchecked_Conversion
        (Interfaces.Unsigned_64, Long_Float);
   begin
      return To_Float (Read_U64_LE (Text, Index));
   end Read_Double_LE;

   function Align_Length
     (Length_Value : Natural;
      Alignment    : Positive)
      return Natural is
   begin
      if Length_Value mod Alignment = 0 then
         return Length_Value;
      end if;
      return Length_Value + (Alignment - (Length_Value mod Alignment));
   end Align_Length;

   function Slice_Unbounded
     (Text  : String;
      First : Positive;
      Count : Natural)
      return Unbounded_String is
   begin
      if Count = 0 then
         return Null_Unbounded_String;
      end if;
      return To_Unbounded_String (Text (First .. First + Count - 1));
   end Slice_Unbounded;

   procedure Ensure_Available
     (Text   : String;
      Index  : Positive;
      Count  : Natural;
      Result : in out A11y.Results.Result) is
   begin
      if A11y.Results.Failed (Result) then
         return;
      elsif Count = 0 then
         return;
      elsif Index > Text'Last or else Count - 1 > Text'Last - Index then
         Result := (Status => A11y.Results.Invalid_Argument);
      end if;
   end Ensure_Available;

   function Read_DBus_Signature
     (Text   : String;
      Index  : in out Positive;
      Limit  : Natural;
      Result : in out A11y.Results.Result)
      return String
   is
      Length_Value : Natural;
      Start : Positive;
   begin
      Ensure_Available (Text, Index, 1, Result);
      if A11y.Results.Failed (Result) then
         return "";
      end if;

      Length_Value := Byte_At (Text, Index);
      Index := Index + 1;
      Ensure_Available (Text, Index, Length_Value + 1, Result);
      if A11y.Results.Failed (Result) or else Index + Length_Value > Limit + 1
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return "";
      end if;

      Start := Index;
      Index := Index + Length_Value;
      if Text (Index) /= Character'Val (0) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return "";
      end if;
      Index := Index + 1;

      if Length_Value = 0 then
         return "";
      end if;
      return Text (Start .. Start + Length_Value - 1);
   end Read_DBus_Signature;

   function Read_DBus_String
     (Text   : String;
      Index  : in out Positive;
      Limit  : Natural;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : in out A11y.Results.Result)
      return Unbounded_String
   is
      Length_Value : Natural;
      Start : Positive;
   begin
      Index := Align_Length (Index - 1, 4) + 1;
      Ensure_Available (Text, Index, 4, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_String;
      end if;

      Length_Value := Read_U32_LE (Text, Index);
      Index := Index + 4;
      if A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_String_Size, Length_Value)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return Null_Unbounded_String;
      end if;

      Ensure_Available (Text, Index, Length_Value + 1, Result);
      if A11y.Results.Failed (Result) or else Index + Length_Value > Limit + 1
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Null_Unbounded_String;
      end if;

      Start := Index;
      Index := Index + Length_Value;
      if Text (Index) /= Character'Val (0) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Null_Unbounded_String;
      end if;
      Index := Index + 1;

      return Slice_Unbounded (Text, Start, Length_Value);
   end Read_DBus_String;

   function Build_Transport_Envelope
     (Message : Outgoing_Message;
      Result  : out A11y.Results.Result)
      return Transport_Envelope
   is
   begin
      return Build_Transport_Envelope
        (Message, A11y.Resource_Limits.Default_Config, Result);
   end Build_Transport_Envelope;

   function Build_Transport_Envelope
     (Message : Outgoing_Message;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Transport_Envelope
   is
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      Signature : Unbounded_String := Null_Unbounded_String;
   begin
      if Message.Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Envelope (Message.Kind, A11y.Results.Invalid_Argument);
      end if;

      case Message.Kind is
         when Method_Call =>
            if Length (Message.Interface_Name) = 0
              or else Length (Message.Member_Name) = 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, A11y.Results.Invalid_Argument);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
              (To_String (Message.Object_Path), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Message.Interface_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;
            if not A11y.Linux.DBus_Codec.Is_Valid_Interface_Name
              (To_String (Message.Interface_Name))
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Message.Member_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;
            if not A11y.Linux.DBus_Codec.Is_Valid_Member_Name
              (To_String (Message.Member_Name))
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;

            if Message.Has_Object_Path_Argument then
               Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
                 (To_String (Message.Object_Path_Argument), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String
                 (A11y.Linux.DBus_Codec.Signature
                    (A11y.Linux.DBus_Codec.Object_Path_Value));
            elsif Message.Has_Object_Reference_Argument then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.String_Argument), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;
               if not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
                 (To_String (Message.String_Argument))
               then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
                 (To_String (Message.Object_Path_Argument), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("(so)");
            elsif Message.Has_UInt32_Pair_Argument
              and then Message.Has_String_Argument
            then
               Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                 (Message.UInt32_Argument, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                 (Message.UInt32_Argument_2, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.String_Argument), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("uus");
            elsif Message.Has_String_Pair_Argument then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.String_Argument), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.String_Argument_2), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("ss");
            elsif Message.Has_String_Argument then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.String_Argument), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("s");
            elsif Message.Has_UInt32_Argument then
               Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                 (Message.UInt32_Argument, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("u");
            elsif Message.Has_UInt32_Pair_Argument then
               Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                 (Message.UInt32_Argument, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                 (Message.UInt32_Argument_2, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("uu");
            elsif Message.Has_Point_Argument then
               Signature := To_Unbounded_String ("ii");
            elsif Message.Has_Float_Argument then
               if Long_Float'Size /= 64 then
                  Result := (Status => A11y.Results.Native_Failure);
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Signature := To_Unbounded_String ("d");
            end if;

            Result := A11y.Results.Ok;
            return
              (Kind                      => Method_Call,
               Serial                    => Message.Serial,
               Reply_Serial              => 0,
               Status                    => Message.Status,
               Object_Path               => Message.Object_Path,
               Interface_Name            => Message.Interface_Name,
               Member_Name               => Message.Member_Name,
               Error_Name                => Null_Unbounded_String,
               Sender_Name               => Null_Unbounded_String,
               Body_Signature            => Signature,
               Body_Bytes                => Null_Unbounded_String,
               Body_Object_Path_Argument =>
                 (if Message.Has_Object_Path_Argument
                    or else Message.Has_Object_Reference_Argument
                  then Message.Object_Path_Argument
                  else Null_Unbounded_String),
               Body_String_Argument      =>
                 (if Message.Has_String_Argument
                    or else Message.Has_Object_Reference_Argument
                    or else Message.Has_String_Pair_Argument
                  then Message.String_Argument
                  else Null_Unbounded_String),
               Body_String_Argument_2    =>
                 (if Message.Has_String_Pair_Argument
                  then Message.String_Argument_2
                  else Null_Unbounded_String),
               Body_UInt32_Argument     =>
                 (if Message.Has_UInt32_Argument
                    or else Message.Has_UInt32_Pair_Argument
                  then Message.UInt32_Argument
                  else 0),
               Body_UInt32_Argument_2   =>
                 (if Message.Has_UInt32_Pair_Argument
                  then Message.UInt32_Argument_2
                  else 0),
               Body_Point_Argument      =>
                 (if Message.Has_Point_Argument
                  then Message.Point_Argument
                  else (X => 0, Y => 0)),
               Body_Float_Argument      =>
                 (if Message.Has_Float_Argument
                  then Message.Float_Argument
                  else 0.0));

         when Method_Return =>
            if Message.Reply_Serial = 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, A11y.Results.Invalid_Argument);
            end if;

            Signature := To_Unbounded_String
              (Method_Return_Body_Signature (Message.Routed_Kind));
            if Length (Signature) = 0
              and then Message.Routed_Kind /=
                A11y.Linux.ATSPi_Method_Router.Empty_Method_Return
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, A11y.Results.Invalid_Argument);
            end if;

            declare
               Payload : constant Unbounded_String :=
                 Method_Return_Payload_Bytes (Message, Limits, Result);
            begin
               if A11y.Results.Failed (Result) then
                  return Empty_Envelope (Message.Kind, Result.Status);
               end if;

               Result := A11y.Results.Ok;
               return
                 (Kind                      => Method_Return,
                  Serial                    => Message.Serial,
                  Reply_Serial              => Message.Reply_Serial,
                  Status                    => Message.Status,
                  Object_Path               => Message.Object_Path,
                  Interface_Name            => Null_Unbounded_String,
                  Member_Name               => Null_Unbounded_String,
                  Error_Name                => Null_Unbounded_String,
                  Sender_Name               => Null_Unbounded_String,
                  Body_Signature            => Signature,
                  Body_Bytes                => Payload,
                  Body_Object_Path_Argument => Null_Unbounded_String,
                  Body_String_Argument      => Null_Unbounded_String,
                  Body_String_Argument_2    => Null_Unbounded_String,
                  Body_UInt32_Argument      => 0,
                  Body_UInt32_Argument_2    => 0,
                  Body_Point_Argument       => (X => 0, Y => 0),
                  Body_Float_Argument       => 0.0);
            end;

         when Error_Return =>
            if Message.Reply_Serial = 0 or else Length (Message.Error_Name) = 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, A11y.Results.Invalid_Argument);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Message.Error_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Message.Kind, Result.Status);
            elsif not A11y.Linux.DBus_Codec.Is_Valid_Error_Name
              (To_String (Message.Error_Name))
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;

            Result := A11y.Results.Ok;
            return
              (Kind                      => Error_Return,
               Serial                    => Message.Serial,
               Reply_Serial              => Message.Reply_Serial,
               Status                    => Message.Status,
               Object_Path               => Message.Object_Path,
               Interface_Name            => Null_Unbounded_String,
               Member_Name               => Null_Unbounded_String,
               Error_Name                => Message.Error_Name,
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

         when Signal_Message =>
            if Length (Message.Event_Name) = 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Envelope (Message.Kind, A11y.Results.Invalid_Argument);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
              (To_String (Message.Object_Path), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Message.Event_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Message.Kind, Result.Status);
            end if;

            Result := A11y.Results.Ok;
            return
              (Kind                      => Signal_Message,
               Serial                    => Message.Serial,
               Reply_Serial              => 0,
               Status                    => Message.Status,
               Object_Path               => Message.Object_Path,
               Interface_Name            => Null_Unbounded_String,
               Member_Name               => Message.Event_Name,
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
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Envelope (Message.Kind, A11y.Results.Internal_Error);
   end Build_Transport_Envelope;

   function Build_Transport_Frame_Metadata
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return Transport_Frame_Metadata
   is
   begin
      return Build_Transport_Frame_Metadata
        (Envelope, A11y.Resource_Limits.Default_Config, Result);
   end Build_Transport_Frame_Metadata;

   function Destination_For_Method_Call
     (Envelope : Transport_Envelope)
      return Unbounded_String
   is
      Path : constant String := To_String (Envelope.Object_Path);
      Iface : constant String := To_String (Envelope.Interface_Name);
   begin
      if Envelope.Kind /= Method_Call then
         return Null_Unbounded_String;
      elsif Path = "/org/freedesktop/DBus"
        and then Iface = "org.freedesktop.DBus"
      then
         return To_Unbounded_String ("org.freedesktop.DBus");
      elsif Path = "/org/a11y/bus"
        and then Iface = "org.a11y.Bus"
      then
         return To_Unbounded_String ("org.a11y.Bus");
      elsif Path = "/org/a11y/atspi/registry"
        and then Iface = "org.a11y.atspi.Registry"
      then
         return To_Unbounded_String ("org.a11y.atspi.Registry");
      elsif Path = "/org/a11y/atspi/accessible/root"
        and then Iface = "org.a11y.atspi.Socket"
      then
         return To_Unbounded_String ("org.a11y.atspi.Registry");
      else
         return Null_Unbounded_String;
      end if;
   exception
      when others =>
         return Null_Unbounded_String;
   end Destination_For_Method_Call;

   function Build_Transport_Frame_Metadata
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Transport_Frame_Metadata
   is
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      Destination : constant Unbounded_String :=
        Destination_For_Method_Call (Envelope);
      Header_Fields : Natural := 1;
      Body_Fields : Natural := 0;
      Header_Text : Natural := 0;
      Body_Text : Natural := 0;
      Estimated : Natural := 16;
   begin
      if Envelope.Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Frame (Envelope.Kind);
      end if;

      Result := A11y.Results.Ok;
      Add_Checked (Estimated, Length (Envelope.Object_Path), Result);
      Add_Checked (Header_Text, Length (Envelope.Object_Path), Result);
      Add_Checked (Estimated, Length (Envelope.Interface_Name), Result);
      Add_Checked (Header_Text, Length (Envelope.Interface_Name), Result);
      Add_Checked (Estimated, Length (Envelope.Member_Name), Result);
      Add_Checked (Header_Text, Length (Envelope.Member_Name), Result);
      Add_Checked (Estimated, Length (Envelope.Error_Name), Result);
      Add_Checked (Header_Text, Length (Envelope.Error_Name), Result);
      Add_Checked (Estimated, Length (Envelope.Body_Signature), Result);
      Add_Checked (Header_Text, Length (Envelope.Body_Signature), Result);
      Add_Checked (Estimated, Length (Destination), Result);
      Add_Checked (Header_Text, Length (Destination), Result);
      if A11y.Results.Failed (Result) then
         return Empty_Frame (Envelope.Kind);
      end if;

      case Envelope.Kind is
         when Method_Call =>
            if Length (Envelope.Interface_Name) = 0
              or else Length (Envelope.Member_Name) = 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
              (To_String (Envelope.Object_Path), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Frame (Envelope.Kind);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Envelope.Interface_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Frame (Envelope.Kind);
            end if;
            if not A11y.Linux.DBus_Codec.Is_Valid_Interface_Name
              (To_String (Envelope.Interface_Name))
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Envelope.Member_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Frame (Envelope.Kind);
            end if;
            if not A11y.Linux.DBus_Codec.Is_Valid_Member_Name
              (To_String (Envelope.Member_Name))
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            if Length (Destination) /= 0 then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Destination), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Frame (Envelope.Kind);
               end if;
               if not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
                 (To_String (Destination))
               then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Frame (Envelope.Kind);
               end if;
            end if;

            if Length (Envelope.Error_Name) /= 0
              or else Envelope.Reply_Serial /= 0
              or else Length (Envelope.Body_Bytes) /= 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            Header_Fields :=
              (if Length (Envelope.Body_Signature) = 0 then 3 else 4)
              + (if Length (Destination) = 0 then 0 else 1);
            if Length (Envelope.Body_Signature) /= 0 then
               if To_String (Envelope.Body_Signature) =
                 A11y.Linux.DBus_Codec.Signature
                   (A11y.Linux.DBus_Codec.Object_Path_Value)
               then
                  Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
                    (To_String (Envelope.Body_Object_Path_Argument),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := Length (Envelope.Body_Object_Path_Argument);
                  Add_Checked
                    (Estimated,
                     Length (Envelope.Body_Object_Path_Argument),
                     Result);
               elsif To_String (Envelope.Body_Signature) = "(so)" then
                  Ignored := A11y.Linux.DBus_Codec.Make_String
                    (To_String (Envelope.Body_String_Argument),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;
                  if not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
                    (To_String (Envelope.Body_String_Argument))
                  then
                     Result := (Status => A11y.Results.Invalid_Argument);
                     return Empty_Frame (Envelope.Kind);
                  end if;
                  Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
                    (To_String (Envelope.Body_Object_Path_Argument),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := Length (Envelope.Body_String_Argument)
                    + Length (Envelope.Body_Object_Path_Argument);
                  Add_Checked
                    (Estimated,
                     Length (Envelope.Body_String_Argument)
                       + Length (Envelope.Body_Object_Path_Argument),
                     Result);
               elsif To_String (Envelope.Body_Signature) = "s" then
                  Ignored := A11y.Linux.DBus_Codec.Make_String
                    (To_String (Envelope.Body_String_Argument),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := Length (Envelope.Body_String_Argument);
                  Add_Checked
                    (Estimated,
                     Length (Envelope.Body_String_Argument),
                     Result);
               elsif To_String (Envelope.Body_Signature) = "ss" then
                  Ignored := A11y.Linux.DBus_Codec.Make_String
                    (To_String (Envelope.Body_String_Argument),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;
                  Ignored := A11y.Linux.DBus_Codec.Make_String
                    (To_String (Envelope.Body_String_Argument_2),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := Length (Envelope.Body_String_Argument)
                    + Length (Envelope.Body_String_Argument_2);
                  Add_Checked
                    (Estimated,
                     Length (Envelope.Body_String_Argument)
                       + Length (Envelope.Body_String_Argument_2),
                     Result);
               elsif To_String (Envelope.Body_Signature) = "u" then
                  Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                    (Envelope.Body_UInt32_Argument, Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := 4;
                  Add_Checked (Estimated, 4, Result);
               elsif To_String (Envelope.Body_Signature) = "uu" then
                  Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                    (Envelope.Body_UInt32_Argument, Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;
                  Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                    (Envelope.Body_UInt32_Argument_2, Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := 8;
                  Add_Checked (Estimated, 8, Result);
               elsif To_String (Envelope.Body_Signature) = "uus" then
                  Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                    (Envelope.Body_UInt32_Argument, Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;
                  Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                    (Envelope.Body_UInt32_Argument_2, Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;
                  Ignored := A11y.Linux.DBus_Codec.Make_String
                    (To_String (Envelope.Body_String_Argument),
                     Limits,
                     Result);
                  if A11y.Results.Failed (Result) then
                     return Empty_Frame (Envelope.Kind);
                  end if;

                  Body_Text := 8 + Length (Envelope.Body_String_Argument);
                  Add_Checked
                    (Estimated, 8 + Length (Envelope.Body_String_Argument),
                     Result);
               elsif To_String (Envelope.Body_Signature) = "ii" then
                  Body_Text := 8;
                  Add_Checked (Estimated, 8, Result);
               elsif To_String (Envelope.Body_Signature) = "d" then
                  Body_Text := 8;
                  Add_Checked (Estimated, 8, Result);
               else
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Frame (Envelope.Kind);
               end if;

               Body_Fields := 1;
            elsif Length (Envelope.Body_Object_Path_Argument) /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            elsif Length (Envelope.Body_String_Argument) /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            elsif Length (Envelope.Body_String_Argument_2) /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            elsif Envelope.Body_UInt32_Argument /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            elsif Envelope.Body_UInt32_Argument_2 /= 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

         when Method_Return =>
            if Envelope.Reply_Serial = 0
              or else Length (Envelope.Interface_Name) /= 0
              or else Length (Envelope.Member_Name) /= 0
              or else Length (Envelope.Error_Name) /= 0
              or else Length (Envelope.Body_Object_Path_Argument) /= 0
              or else Length (Envelope.Body_String_Argument) /= 0
              or else Length (Envelope.Body_String_Argument_2) /= 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            if Length (Envelope.Object_Path) /= 0 then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Envelope.Object_Path), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Frame (Envelope.Kind);
               end if;
               Add_Checked (Estimated, Length (Envelope.Object_Path), Result);
               Add_Checked (Header_Text, Length (Envelope.Object_Path), Result);
            end if;

            if Length (Envelope.Body_Signature) = 0 then
               if Length (Envelope.Body_Bytes) /= 0 then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Frame (Envelope.Kind);
               end if;
               Header_Fields :=
                 1 + (if Length (Envelope.Object_Path) = 0 then 0 else 1);
            else
               Body_Fields := 1;
               Header_Fields :=
                 2 + (if Length (Envelope.Object_Path) = 0 then 0 else 1);
               Body_Text := Length (Envelope.Body_Bytes);
               Add_Checked (Estimated, Length (Envelope.Body_Bytes), Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Frame (Envelope.Kind);
               end if;
            end if;

         when Error_Return =>
            if Envelope.Reply_Serial = 0
              or else Length (Envelope.Error_Name) = 0
              or else Length (Envelope.Interface_Name) /= 0
              or else Length (Envelope.Member_Name) /= 0
              or else Length (Envelope.Body_Object_Path_Argument) /= 0
              or else Length (Envelope.Body_String_Argument) /= 0
              or else Length (Envelope.Body_String_Argument_2) /= 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            if Length (Envelope.Object_Path) /= 0 then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Envelope.Object_Path), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Frame (Envelope.Kind);
               end if;
               Add_Checked (Estimated, Length (Envelope.Object_Path), Result);
               Add_Checked (Header_Text, Length (Envelope.Object_Path), Result);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Envelope.Error_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Frame (Envelope.Kind);
            elsif not A11y.Linux.DBus_Codec.Is_Valid_Error_Name
              (To_String (Envelope.Error_Name))
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            if Length (Envelope.Body_Signature) = 0 then
               if Length (Envelope.Body_Bytes) /= 0 then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Frame (Envelope.Kind);
               end if;
               Header_Fields :=
                 2 + (if Length (Envelope.Object_Path) = 0 then 0 else 1);
            elsif To_String (Envelope.Body_Signature) = "s" then
               declare
                  Payload_Result : A11y.Results.Result;
                  Payload_Text : constant Unbounded_String :=
                    Decode_String_Body
                      (Envelope.Body_Bytes, Limits, Payload_Result);
                  pragma Unreferenced (Payload_Text);
               begin
                  if A11y.Results.Failed (Payload_Result) then
                     Result := Payload_Result;
                     return Empty_Frame (Envelope.Kind);
                  end if;
               end;

               Body_Fields := 1;
               Header_Fields :=
                 3 + (if Length (Envelope.Object_Path) = 0 then 0 else 1);
               Body_Text := Length (Envelope.Body_Bytes);
               Add_Checked (Estimated, Length (Envelope.Body_Bytes), Result);
            else
               Result := (Status => A11y.Results.Unsupported_Capability);
               return Empty_Frame (Envelope.Kind);
            end if;

         when Signal_Message =>
            if Length (Envelope.Member_Name) = 0 then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
              (To_String (Envelope.Object_Path), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Frame (Envelope.Kind);
            end if;

            if Length (Envelope.Interface_Name) /= 0 then
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Envelope.Interface_Name), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Empty_Frame (Envelope.Kind);
               end if;
            end if;

            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Envelope.Member_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Frame (Envelope.Kind);
            end if;

            if Envelope.Reply_Serial /= 0
              or else Length (Envelope.Error_Name) /= 0
              or else Length (Envelope.Body_Object_Path_Argument) /= 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Frame (Envelope.Kind);
            end if;

            if Length (Envelope.Body_Signature) = 0 then
               if Length (Envelope.Body_Bytes) /= 0 then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Frame (Envelope.Kind);
               end if;
            else
               Body_Fields := 1;
               Body_Text := Length (Envelope.Body_Bytes);
               Add_Checked (Estimated, Length (Envelope.Body_Bytes), Result);
            end if;

            Header_Fields :=
              2
              + (if Length (Envelope.Interface_Name) = 0 then 0 else 1)
              + (if Length (Envelope.Body_Signature) = 0 then 0 else 1);
      end case;

      if A11y.Results.Failed (Result) then
         return Empty_Frame (Envelope.Kind);
      end if;

      Result := A11y.Results.Ok;
      return
        (Kind               => Envelope.Kind,
         Serial             => Envelope.Serial,
         Reply_Serial       => Envelope.Reply_Serial,
         Header_Field_Count => Header_Fields,
         Body_Field_Count   => Body_Fields,
         Header_Text_Bytes  => Header_Text,
         Body_Text_Bytes    => Body_Text,
         Estimated_Bytes    => Estimated);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Frame (Envelope.Kind);
   end Build_Transport_Frame_Metadata;

   function Build_Transport_Frame
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return Transport_Frame
   is
   begin
      return Build_Transport_Frame
        (Envelope, A11y.Resource_Limits.Default_Config, Result);
   end Build_Transport_Frame;

   function Build_Transport_Frame
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Transport_Frame
   is
      Metadata    : constant Transport_Frame_Metadata :=
        Build_Transport_Frame_Metadata (Envelope, Limits, Result);
      Header_Data : Unbounded_String := Null_Unbounded_String;
      Header      : Unbounded_String := Null_Unbounded_String;
      Payload     : Unbounded_String := Null_Unbounded_String;
      Total       : Natural := 0;
      Destination : constant Unbounded_String :=
        Destination_For_Method_Call (Envelope);
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Transport_Frame (Envelope.Kind);
      end if;

      case Envelope.Kind is
         when Method_Call =>
            if Length (Envelope.Body_Signature) /= 0 then
               if To_String (Envelope.Body_Signature) =
                 A11y.Linux.DBus_Codec.Signature
                   (A11y.Linux.DBus_Codec.Object_Path_Value)
               then
                  Append_DBus_String
                    (Payload, Envelope.Body_Object_Path_Argument);
               elsif To_String (Envelope.Body_Signature) = "(so)" then
                  Align (Payload, 8);
                  Append_DBus_String (Payload, Envelope.Body_String_Argument);
                  Append_DBus_String
                    (Payload, Envelope.Body_Object_Path_Argument);
               elsif To_String (Envelope.Body_Signature) = "s" then
                  Append_DBus_String (Payload, Envelope.Body_String_Argument);
               elsif To_String (Envelope.Body_Signature) = "ss" then
                  Append_DBus_String (Payload, Envelope.Body_String_Argument);
                  Append_DBus_String
                    (Payload, Envelope.Body_String_Argument_2);
               elsif To_String (Envelope.Body_Signature) = "u" then
                  Append_U32_LE (Payload, Envelope.Body_UInt32_Argument);
               elsif To_String (Envelope.Body_Signature) = "uu" then
                  Append_U32_LE (Payload, Envelope.Body_UInt32_Argument);
                  Append_U32_LE (Payload, Envelope.Body_UInt32_Argument_2);
               elsif To_String (Envelope.Body_Signature) = "uus" then
                  Append_U32_LE (Payload, Envelope.Body_UInt32_Argument);
                  Append_U32_LE (Payload, Envelope.Body_UInt32_Argument_2);
                  Append_DBus_String (Payload, Envelope.Body_String_Argument);
               elsif To_String (Envelope.Body_Signature) = "ii" then
                  Append_I32_LE
                    (Payload, Integer (Envelope.Body_Point_Argument.X));
                  Append_I32_LE
                    (Payload, Integer (Envelope.Body_Point_Argument.Y));
               elsif To_String (Envelope.Body_Signature) = "d" then
                  Append_Double (Payload, Envelope.Body_Float_Argument);
               else
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Empty_Transport_Frame (Envelope.Kind);
               end if;
            end if;

            Append_Field_Text (Header_Data, 1, "o", Envelope.Object_Path);
            Append_Field_Text (Header_Data, 2, "s", Envelope.Interface_Name);
            Append_Field_Text (Header_Data, 3, "s", Envelope.Member_Name);
            if Length (Destination) /= 0 then
               Append_Field_Text (Header_Data, 6, "s", Destination);
            end if;
            if Length (Envelope.Body_Signature) /= 0 then
               Append_Field_Signature
                 (Header_Data, 8, To_String (Envelope.Body_Signature));
            end if;

         when Method_Return =>
            Payload := Envelope.Body_Bytes;
            Append_Field_U32 (Header_Data, 5, Envelope.Reply_Serial);
            if Length (Envelope.Object_Path) /= 0 then
               Append_Field_Text (Header_Data, 6, "s", Envelope.Object_Path);
            end if;
            if Length (Envelope.Body_Signature) /= 0 then
               Append_Field_Signature
                 (Header_Data, 8, To_String (Envelope.Body_Signature));
            end if;

         when Error_Return =>
            Payload := Envelope.Body_Bytes;
            Append_Field_Text (Header_Data, 4, "s", Envelope.Error_Name);
            Append_Field_U32 (Header_Data, 5, Envelope.Reply_Serial);
            if Length (Envelope.Object_Path) /= 0 then
               Append_Field_Text (Header_Data, 6, "s", Envelope.Object_Path);
            end if;
            if Length (Envelope.Body_Signature) /= 0 then
               Append_Field_Signature
                 (Header_Data, 8, To_String (Envelope.Body_Signature));
            end if;

         when Signal_Message =>
            Append_Field_Text (Header_Data, 1, "o", Envelope.Object_Path);
            Append_Field_Text (Header_Data, 3, "s", Envelope.Member_Name);
      end case;

      Append_Byte (Header, Character'Pos ('l'));
      Append_Byte (Header, Message_Type_Byte (Envelope.Kind));
      Append_Byte (Header, 0);
      Append_Byte (Header, 1);
      Append_U32_LE (Header, Length (Payload));
      Append_U32_LE (Header, Envelope.Serial);
      Append_U32_LE (Header, Length (Header_Data));
      Align (Header, 8);
      Append (Header, Header_Data);
      Align (Header, 8);

      Add_Checked (Total, Length (Header), Result);
      Add_Checked (Total, Length (Payload), Result);
      if A11y.Results.Failed (Result)
        or else A11y.Resource_Limits.Exceeded
          (Limits, A11y.Resource_Limits.Native_Array_Size, Total)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Transport_Frame (Envelope.Kind);
      end if;

      Result := A11y.Results.Ok;
      return
        (Metadata     => Metadata,
         Header_Bytes => Header,
         Body_Bytes   => Payload);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Transport_Frame (Envelope.Kind);
   end Build_Transport_Frame;

   function Build_Transport_Packet
     (Frame  : Transport_Frame;
      Result : out A11y.Results.Result)
      return Transport_Packet
   is
   begin
      return Build_Transport_Packet
        (Frame, A11y.Resource_Limits.Default_Config, Result);
   end Build_Transport_Packet;

   function Build_Transport_Packet
     (Frame  : Transport_Frame;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Packet
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Total : Natural := 0;
      Bytes : Unbounded_String := Null_Unbounded_String;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return Empty_Transport_Packet (Frame.Metadata.Kind);
      elsif Frame.Metadata.Serial = 0
        or else Length (Frame.Header_Bytes) = 0
        or else Length (Frame.Header_Bytes) mod 8 /= 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Transport_Packet (Frame.Metadata.Kind);
      end if;

      Result := A11y.Results.Ok;
      Add_Checked (Total, Length (Frame.Header_Bytes), Result);
      Add_Checked (Total, Length (Frame.Body_Bytes), Result);
      if A11y.Results.Failed (Result)
        or else A11y.Resource_Limits.Exceeded
          (Limits, A11y.Resource_Limits.Native_Array_Size, Total)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Transport_Packet (Frame.Metadata.Kind);
      end if;

      Bytes := Frame.Header_Bytes;
      Append (Bytes, Frame.Body_Bytes);
      Result := A11y.Results.Ok;
      return
        (Metadata => Frame.Metadata,
         Bytes    => Bytes);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Transport_Packet (Frame.Metadata.Kind);
   end Build_Transport_Packet;

   function Build_Transport_Packet
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return Transport_Packet
   is
   begin
      return Build_Transport_Packet
        (Envelope, A11y.Resource_Limits.Default_Config, Result);
   end Build_Transport_Packet;

   function Build_Transport_Packet
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Transport_Packet
   is
      Frame : constant Transport_Frame :=
        Build_Transport_Frame (Envelope, Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Transport_Packet (Envelope.Kind);
      end if;

      return Build_Transport_Packet (Frame, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Transport_Packet (Envelope.Kind);
   end Build_Transport_Packet;

   function Decode_Transport_Fixed_Header
     (Bytes  : Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header
   is
   begin
      return Decode_Transport_Fixed_Header
        (Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Transport_Fixed_Header;

   function Decode_Transport_Fixed_Header
     (Bytes  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Bytes);
      Packet_Length : constant Natural := Text'Length;
      Kind : Message_Kind := Error_Return;
      Body_Length : Natural;
      Serial : Natural;
      Header_Fields_Bytes : Natural;
      Header_Length : Natural;
      Required_Length : Natural := 0;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return Empty_Packet_Header (Error_Return);
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Packet_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Packet_Header (Error_Return);
      elsif Packet_Length /= 16 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Packet_Header (Error_Return);
      elsif Text (1) /= 'l'
        or else Byte_At (Text, 3) > 7
        or else Byte_At (Text, 4) /= 1
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return Empty_Packet_Header (Error_Return);
      end if;

      Kind := Kind_From_Message_Type (Byte_At (Text, 2), Result);
      if A11y.Results.Failed (Result) then
         return Empty_Packet_Header (Kind);
      end if;

      Body_Length := Read_U32_LE (Text, 5);
      Serial := Read_U32_LE (Text, 9);
      Header_Fields_Bytes := Read_U32_LE (Text, 13);
      Header_Length := Align_Length (16 + Header_Fields_Bytes, 8);
      if Header_Length < 16 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Packet_Header (Kind);
      end if;

      Add_Checked (Required_Length, Header_Length, Result);
      if A11y.Results.Succeeded (Result) then
         Add_Checked (Required_Length, Body_Length, Result);
      end if;
      if A11y.Results.Failed (Result) then
         return Empty_Packet_Header (Kind);
      elsif Serial = 0
        or else Header_Fields_Bytes = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Packet_Header (Kind);
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Required_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return Empty_Packet_Header (Kind);
      end if;

      Result := A11y.Results.Ok;
      return
        (Kind                => Kind,
         Serial              => Serial,
         Body_Length         => Body_Length,
         Header_Fields_Bytes => Header_Fields_Bytes,
         Header_Length       => Header_Length,
         Packet_Length       => Required_Length);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Packet_Header (Kind);
   end Decode_Transport_Fixed_Header;

   function Decode_Transport_Packet_Header
     (Bytes  : Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header
   is
   begin
      return Decode_Transport_Packet_Header
        (Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Transport_Packet_Header;

   function Decode_Transport_Packet_Header
     (Bytes  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Packet_Header
   is
      Text : constant String := To_String (Bytes);
      Header : Transport_Packet_Header;
   begin
      if Text'Length < 16 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Packet_Header (Error_Return);
      end if;

      Header := Decode_Transport_Fixed_Header
        (To_Unbounded_String (Text (Text'First .. Text'First + 15)),
         Limits,
         Result);
      if A11y.Results.Failed (Result) then
         return Header;
      elsif Header.Packet_Length /= Text'Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Packet_Header (Header.Kind);
      end if;

      Result := A11y.Results.Ok;
      return Header;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Packet_Header (Error_Return);
   end Decode_Transport_Packet_Header;

   function Decode_Transport_Envelope
     (Bytes  : Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Envelope
   is
   begin
      return Decode_Transport_Envelope
        (Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Transport_Envelope;

   function Decode_Transport_Envelope
     (Bytes  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Envelope
   is
      Header : constant Transport_Packet_Header :=
        Decode_Transport_Packet_Header (Bytes, Limits, Result);
      Text : constant String := To_String (Bytes);
      Envelope : Transport_Envelope :=
        (Kind                      => Header.Kind,
         Serial                    => Header.Serial,
         Reply_Serial              => 0,
         Status                    => A11y.Results.Success,
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
      Field_Offset : Natural := 0;
      Field_Count : Natural := 0;
      Ignored_Header_Field_Count : Natural := 0;
      Metadata : Transport_Frame_Metadata;
      Seen_Path : Boolean := False;
      Seen_Interface : Boolean := False;
      Seen_Member : Boolean := False;
      Seen_Error : Boolean := False;
      Seen_Destination : Boolean := False;
      Seen_Sender : Boolean := False;
      Seen_Reply : Boolean := False;
      Seen_Signature : Boolean := False;
      Seen_Unix_FDs : Boolean := False;

      procedure Fail (Status : A11y.Results.Status_Code) is
      begin
         Result := (Status => Status);
      end Fail;

      procedure Assign_Text_Field
        (Code      : Natural;
         Signature : String;
         Value     : Unbounded_String) is
         Check_Result : A11y.Results.Result;
         Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      begin
         case Code is
            when 1 =>
               if Seen_Path or else Signature /= "o" then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
                 (To_String (Value), Limits, Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               end if;
               Envelope.Object_Path := Value;
               Seen_Path := True;
            when 2 =>
               if Seen_Interface or else Signature /= "s" then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Value), Limits, Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               elsif not A11y.Linux.DBus_Codec.Is_Valid_Interface_Name
                 (To_String (Value))
               then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Envelope.Interface_Name := Value;
               Seen_Interface := True;
            when 3 =>
               if Seen_Member or else Signature /= "s" then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Value), Limits, Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               elsif Envelope.Kind = Method_Call
                 and then not A11y.Linux.DBus_Codec.Is_Valid_Member_Name
                 (To_String (Value))
               then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Envelope.Member_Name := Value;
               Seen_Member := True;
            when 4 =>
               if Seen_Error or else Signature /= "s" then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Value), Limits, Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               elsif not A11y.Linux.DBus_Codec.Is_Valid_Error_Name
                 (To_String (Value))
               then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Envelope.Error_Name := Value;
               Seen_Error := True;
            when 6 =>
               if Seen_Destination or else Signature /= "s" then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Value), Limits, Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               elsif not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
                 (To_String (Value))
               then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Seen_Destination := True;
               Ignored_Header_Field_Count := Ignored_Header_Field_Count + 1;
            when 7 =>
               if Seen_Sender or else Signature /= "s" then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Value), Limits, Check_Result);
               if A11y.Results.Failed (Check_Result) then
                  Result := Check_Result;
                  return;
               elsif not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
                 (To_String (Value))
               then
                  Fail (A11y.Results.Invalid_Argument);
                  return;
               end if;
               Envelope.Sender_Name := Value;
               Seen_Sender := True;
               Ignored_Header_Field_Count := Ignored_Header_Field_Count + 1;
            when others =>
               Fail (A11y.Results.Unsupported_Capability);
         end case;
      end Assign_Text_Field;
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Envelope (Header.Kind, Result.Status);
      end if;

      Result := A11y.Results.Ok;
      while Field_Offset < Header.Header_Fields_Bytes loop
         declare
            Aligned_Offset : constant Natural :=
              Align_Length (Field_Offset, 8);
            Index : Positive := 17 + Aligned_Offset;
            Data_Limit : constant Natural := 16 + Header.Header_Fields_Bytes;
            Code : Natural;
            Field_Signature : Unbounded_String;
         begin
            if Aligned_Offset >= Header.Header_Fields_Bytes then
               exit;
            end if;

            Ensure_Available (Text, Index, 1, Result);
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Header.Kind, Result.Status);
            end if;

            Code := Byte_At (Text, Index);
            Index := Index + 1;
            Field_Signature := To_Unbounded_String
              (Read_DBus_Signature (Text, Index, Data_Limit, Result));
            if A11y.Results.Failed (Result) then
               return Empty_Envelope (Header.Kind, Result.Status);
            end if;

            case Code is
               when 1 | 2 | 3 | 4 | 6 | 7 =>
                  declare
                     Value : constant Unbounded_String :=
                       Read_DBus_String
                         (Text, Index, Data_Limit, Limits, Result);
                  begin
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                     Assign_Text_Field (Code, To_String (Field_Signature), Value);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               when 5 =>
                  if Seen_Reply or else To_String (Field_Signature) /= "u" then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  Index := Align_Length (Index - 1, 4) + 1;
                  Ensure_Available (Text, Index, 4, Result);
                  if A11y.Results.Failed (Result)
                    or else Index + 3 > Data_Limit
                  then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  Envelope.Reply_Serial := Read_U32_LE (Text, Index);
                  Index := Index + 4;
                  Seen_Reply := True;
               when 8 =>
                  if Seen_Signature or else To_String (Field_Signature) /= "g" then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  Envelope.Body_Signature := To_Unbounded_String
                    (Read_DBus_Signature (Text, Index, Data_Limit, Result));
                  if A11y.Results.Failed (Result) then
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  Seen_Signature := True;
               when 9 =>
                  if Seen_Unix_FDs or else To_String (Field_Signature) /= "u" then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  Index := Align_Length (Index - 1, 4) + 1;
                  Ensure_Available (Text, Index, 4, Result);
                  if A11y.Results.Failed (Result)
                    or else Index + 3 > Data_Limit
                  then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  if Read_U32_LE (Text, Index) /= 0 then
                     Fail (A11y.Results.Unsupported_Capability);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;
                  Index := Index + 4;
                  Seen_Unix_FDs := True;
                  Ignored_Header_Field_Count :=
                    Ignored_Header_Field_Count + 1;
               when others =>
                  Fail (A11y.Results.Unsupported_Capability);
                  return Empty_Envelope (Header.Kind, Result.Status);
            end case;

            Field_Count := Field_Count + 1;
            Field_Offset := Natural (Index - 17);
         end;
      end loop;

      if Length (Envelope.Body_Signature) /= 0 then
         case Envelope.Kind is
            when Method_Call =>
               if To_String (Envelope.Body_Signature) =
                 A11y.Linux.DBus_Codec.Signature
                   (A11y.Linux.DBus_Codec.Object_Path_Value)
               then
                  declare
                     Body_Index : Positive := Header.Header_Length + 1;
                     Body_Limit : constant Natural := Header.Packet_Length;
                  begin
                     Envelope.Body_Object_Path_Argument :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result)
                       or else Body_Index - 1 /= Header.Packet_Length
                     then
                        Fail
                          ((if A11y.Results.Failed (Result)
                            then Result.Status
                            else A11y.Results.Invalid_Argument));
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                     if not A11y.Linux.DBus_Codec.Is_Valid_Object_Path
                       (To_String (Envelope.Body_Object_Path_Argument))
                     then
                        Fail (A11y.Results.Invalid_Argument);
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               elsif To_String (Envelope.Body_Signature) = "(so)" then
                  declare
                     Body_Index : Positive := Header.Header_Length + 1;
                     Body_Limit : constant Natural := Header.Packet_Length;
                  begin
                     Body_Index :=
                       Align_Length (Body_Index - 1, 8) + 1;
                     Envelope.Body_String_Argument :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;

                     Envelope.Body_Object_Path_Argument :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result)
                       or else Body_Index - 1 /= Header.Packet_Length
                     then
                        Fail
                          ((if A11y.Results.Failed (Result)
                            then Result.Status
                            else A11y.Results.Invalid_Argument));
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                     if not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
                       (To_String (Envelope.Body_String_Argument))
                       or else not A11y.Linux.DBus_Codec.Is_Valid_Object_Path
                         (To_String (Envelope.Body_Object_Path_Argument))
                     then
                        Fail (A11y.Results.Invalid_Argument);
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               elsif To_String (Envelope.Body_Signature) = "s" then
                  declare
                     Body_Index : Positive := Header.Header_Length + 1;
                     Body_Limit : constant Natural := Header.Packet_Length;
                  begin
                     Envelope.Body_String_Argument :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result)
                       or else Body_Index - 1 /= Header.Packet_Length
                     then
                        Fail
                          ((if A11y.Results.Failed (Result)
                            then Result.Status
                            else A11y.Results.Invalid_Argument));
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               elsif To_String (Envelope.Body_Signature) = "ss" then
                  declare
                     Body_Index : Positive := Header.Header_Length + 1;
                     Body_Limit : constant Natural := Header.Packet_Length;
                  begin
                     Envelope.Body_String_Argument :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;

                     Envelope.Body_String_Argument_2 :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result)
                       or else Body_Index - 1 /= Header.Packet_Length
                     then
                        Fail
                          ((if A11y.Results.Failed (Result)
                            then Result.Status
                            else A11y.Results.Invalid_Argument));
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               elsif To_String (Envelope.Body_Signature) = "u" then
                  declare
                     Body_Text : constant Unbounded_String :=
                       Slice_Unbounded
                         (Text, Header.Header_Length + 1,
                          Header.Body_Length);
                  begin
                     Envelope.Body_UInt32_Argument :=
                       Decode_UInt32_Body (Body_Text, Limits, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               elsif To_String (Envelope.Body_Signature) = "uu" then
                  if Header.Body_Length /= 8 then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;

                  declare
                     Body_Index : constant Positive :=
                       Header.Header_Length + 1;
                  begin
                     Ensure_Available (Text, Body_Index, 8, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;

                     Envelope.Body_UInt32_Argument :=
                       Read_U32_LE (Text, Body_Index);
                     Envelope.Body_UInt32_Argument_2 :=
                       Read_U32_LE (Text, Body_Index + 4);
                  end;
               elsif To_String (Envelope.Body_Signature) = "uus" then
                  if Header.Body_Length < 12 then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;

                  declare
                     Body_Index : Positive := Header.Header_Length + 1;
                     Body_Limit : constant Natural := Header.Packet_Length;
                  begin
                     Ensure_Available (Text, Body_Index, 8, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;

                     Envelope.Body_UInt32_Argument :=
                       Read_U32_LE (Text, Body_Index);
                     Envelope.Body_UInt32_Argument_2 :=
                       Read_U32_LE (Text, Body_Index + 4);
                     Body_Index := Body_Index + 8;
                     Envelope.Body_String_Argument :=
                       Read_DBus_String
                         (Text, Body_Index, Body_Limit, Limits, Result);
                     if A11y.Results.Failed (Result)
                       or else Body_Index - 1 /= Header.Packet_Length
                     then
                        Fail
                          ((if A11y.Results.Failed (Result)
                            then Result.Status
                            else A11y.Results.Invalid_Argument));
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;
                  end;
               elsif To_String (Envelope.Body_Signature) = "ii" then
                  if Header.Body_Length /= 8 then
                     Fail (A11y.Results.Invalid_Argument);
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;

                  declare
                     Body_Index : constant Positive :=
                       Header.Header_Length + 1;
                  begin
                     Ensure_Available (Text, Body_Index, 8, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;

                     Envelope.Body_Point_Argument :=
                       (X => A11y.Geometry.Coordinate
                           (Read_I32_LE (Text, Body_Index)),
                        Y => A11y.Geometry.Coordinate
                           (Read_I32_LE (Text, Body_Index + 4)));
                  end;
               elsif To_String (Envelope.Body_Signature) = "d" then
                  if Header.Body_Length /= 8 or else Long_Float'Size /= 64 then
                     Fail
                       ((if Long_Float'Size /= 64
                         then A11y.Results.Native_Failure
                         else A11y.Results.Invalid_Argument));
                     return Empty_Envelope (Header.Kind, Result.Status);
                  end if;

                  declare
                     Body_Index : constant Positive :=
                       Header.Header_Length + 1;
                  begin
                     Ensure_Available (Text, Body_Index, 8, Result);
                     if A11y.Results.Failed (Result) then
                        return Empty_Envelope (Header.Kind, Result.Status);
                     end if;

                     Envelope.Body_Float_Argument :=
                       Read_Double_LE (Text, Body_Index);
                  end;
               else
                  Fail (A11y.Results.Unsupported_Capability);
                  return Empty_Envelope (Header.Kind, Result.Status);
               end if;

            when Method_Return =>
               Envelope.Body_Bytes :=
                 Slice_Unbounded
                   (Text, Header.Header_Length + 1, Header.Body_Length);

            when Error_Return =>
               if To_String (Envelope.Body_Signature) /= "s" then
                  Fail (A11y.Results.Unsupported_Capability);
                  return Empty_Envelope (Header.Kind, Result.Status);
               end if;

               Envelope.Body_Bytes :=
                 Slice_Unbounded
                   (Text, Header.Header_Length + 1, Header.Body_Length);

            when Signal_Message =>
               Envelope.Body_Bytes :=
                 Slice_Unbounded
                   (Text, Header.Header_Length + 1, Header.Body_Length);
         end case;
      elsif Header.Body_Length /= 0 then
         Fail (A11y.Results.Unsupported_Capability);
         return Empty_Envelope (Header.Kind, Result.Status);
      end if;

      Metadata := Build_Transport_Frame_Metadata (Envelope, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Empty_Envelope (Envelope.Kind, Result.Status);
      elsif Metadata.Header_Field_Count > Field_Count
        or else Field_Count >
          Metadata.Header_Field_Count + Ignored_Header_Field_Count
      then
         Fail (A11y.Results.Invalid_Argument);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      end if;

      Result := A11y.Results.Ok;
      return Envelope;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Envelope (Header.Kind, A11y.Results.Internal_Error);
   end Decode_Transport_Envelope;

   function Decode_Method_Return
     (Bytes  : Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Envelope
   is
   begin
      return Decode_Method_Return
        (Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Method_Return;

   function Decode_Method_Return
     (Bytes  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Envelope
   is
      Envelope : Transport_Envelope :=
        Decode_Transport_Envelope (Bytes, Limits, Result);
      Metadata : Transport_Frame_Metadata;
      pragma Unreferenced (Metadata);

      procedure Decode_Object_Reference_Body is
         Body_Text : constant String := To_String (Envelope.Body_Bytes);
         Body_Index : Positive := Body_Text'First;
         Body_Limit : constant Natural := Body_Text'Last;
      begin
         if Body_Text'Length = 0 then
            Result := (Status => A11y.Results.Invalid_Argument);
            return;
         end if;

         Body_Index := Align_Length (Body_Index - 1, 8) + 1;
         Envelope.Body_String_Argument :=
           Read_DBus_String (Body_Text, Body_Index, Body_Limit, Limits, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Envelope.Body_Object_Path_Argument :=
           Read_DBus_String (Body_Text, Body_Index, Body_Limit, Limits, Result);
         if A11y.Results.Failed (Result) then
            return;
         elsif Body_Index - 1 /= Body_Text'Last
           or else not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
             (To_String (Envelope.Body_String_Argument))
           or else not A11y.Linux.DBus_Codec.Is_Valid_Object_Path
             (To_String (Envelope.Body_Object_Path_Argument))
         then
            Result := (Status => A11y.Results.Invalid_Argument);
         end if;
      exception
         when others =>
            Result := (Status => A11y.Results.Internal_Error);
      end Decode_Object_Reference_Body;
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Envelope (Envelope.Kind, Result.Status);
      elsif Envelope.Kind /= Method_Return then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      elsif Envelope.Reply_Serial = 0
        or else Length (Envelope.Object_Path) /= 0
        or else Length (Envelope.Interface_Name) /= 0
        or else Length (Envelope.Member_Name) /= 0
        or else Length (Envelope.Error_Name) /= 0
        or else Length (Envelope.Body_Object_Path_Argument) /= 0
        or else Length (Envelope.Body_String_Argument) /= 0
        or else Length (Envelope.Body_String_Argument_2) /= 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      end if;

      Metadata := Build_Transport_Frame_Metadata (Envelope, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Empty_Envelope (Envelope.Kind, Result.Status);
      end if;

      if To_String (Envelope.Body_Signature) = "(so)" then
         Decode_Object_Reference_Body;
         if A11y.Results.Failed (Result) then
            return Empty_Envelope (Envelope.Kind, Result.Status);
         end if;
      end if;

      Result := A11y.Results.Ok;
      return Envelope;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Envelope (Method_Return, A11y.Results.Internal_Error);
   end Decode_Method_Return;

   function Decode_Error_Return
     (Bytes  : Unbounded_String;
      Result : out A11y.Results.Result)
      return Transport_Envelope
   is
   begin
      return Decode_Error_Return
        (Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Error_Return;

   function Decode_Error_Return
     (Bytes  : Unbounded_String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Transport_Envelope
   is
      Envelope : constant Transport_Envelope :=
        Decode_Transport_Envelope (Bytes, Limits, Result);
      Metadata : Transport_Frame_Metadata;
      pragma Unreferenced (Metadata);
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Envelope (Envelope.Kind, Result.Status);
      elsif Envelope.Kind /= Error_Return then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      elsif Envelope.Reply_Serial = 0
        or else Length (Envelope.Error_Name) = 0
        or else not A11y.Linux.DBus_Codec.Is_Valid_Error_Name
          (To_String (Envelope.Error_Name))
        or else Length (Envelope.Object_Path) /= 0
        or else Length (Envelope.Interface_Name) /= 0
        or else Length (Envelope.Member_Name) /= 0
        or else Length (Envelope.Body_Object_Path_Argument) /= 0
        or else Length (Envelope.Body_String_Argument) /= 0
        or else Length (Envelope.Body_String_Argument_2) /= 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      elsif Length (Envelope.Body_Signature) /= 0
        and then To_String (Envelope.Body_Signature) /= "s"
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      end if;

      if Length (Envelope.Body_Signature) /= 0 then
         declare
            Payload_Result : A11y.Results.Result;
            Payload_Text : constant Unbounded_String :=
              Decode_String_Body (Envelope.Body_Bytes, Limits, Payload_Result);
            pragma Unreferenced (Payload_Text);
         begin
            if A11y.Results.Failed (Payload_Result) then
               Result := Payload_Result;
               return Empty_Envelope (Envelope.Kind, Result.Status);
            end if;
         end;
      elsif Length (Envelope.Body_Bytes) /= 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Envelope (Envelope.Kind, Result.Status);
      end if;

      Metadata := Build_Transport_Frame_Metadata (Envelope, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Empty_Envelope (Envelope.Kind, Result.Status);
      end if;

      Result := A11y.Results.Ok;
      return Envelope;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Envelope (Error_Return, A11y.Results.Internal_Error);
   end Decode_Error_Return;

   function Diagnostic_For_Error_Return
     (Envelope : Transport_Envelope;
      Result   : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
   begin
      return Diagnostic_For_Error_Return
        (Envelope, A11y.Resource_Limits.Default_Config, Result);
   end Diagnostic_For_Error_Return;

   function Diagnostic_For_Error_Return
     (Envelope : Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic
   is
      Item : A11y.Diagnostics.Diagnostic;
      Payload_Result : A11y.Results.Result;
      Payload_Text : Unbounded_String := Null_Unbounded_String;
      Serial_Image : constant String :=
        Ada.Strings.Fixed.Trim
          (Natural'Image (Envelope.Reply_Serial), Ada.Strings.Left);
   begin
      if Envelope.Kind /= Error_Return
        or else Envelope.Reply_Serial = 0
        or else Length (Envelope.Error_Name) = 0
        or else not A11y.Linux.DBus_Codec.Is_Valid_Error_Name
          (To_String (Envelope.Error_Name))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Item;
      elsif Length (Envelope.Body_Signature) /= 0
        and then To_String (Envelope.Body_Signature) /= "s"
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return Item;
      end if;

      if Length (Envelope.Body_Signature) /= 0 then
         Payload_Text :=
           Decode_String_Body (Envelope.Body_Bytes, Limits, Payload_Result);
         if A11y.Results.Failed (Payload_Result) then
            Result := Payload_Result;
            return Item;
         end if;
      elsif Length (Envelope.Body_Bytes) /= 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Item;
      end if;

      A11y.Diagnostics.Create_For_Status
        (Identifier => "linux.dbus.error_return",
         Status     => A11y.Results.Protocol_Failure,
         Item       => Item,
         Result     => Result,
         Feature    => "linux.dbus.error_return_decode",
         Redacted   => True);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item, "reply_serial", Serial_Image, Limits, Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item, "error_name", To_String (Envelope.Error_Name), Limits, Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      A11y.Diagnostics.Add_Field
        (Item,
         "has_message",
         (if Length (Envelope.Body_Signature) = 0 then "false" else "true"),
         Limits,
         Result,
         Redacted => False);
      if A11y.Results.Failed (Result) then
         return Item;
      end if;

      if Length (Envelope.Body_Signature) /= 0 then
         A11y.Diagnostics.Add_Field
           (Item, "message", To_String (Payload_Text), Limits, Result,
            Redacted => True);
         if A11y.Results.Failed (Result) then
            return Item;
         end if;
      end if;

      Result := A11y.Results.Ok;
      return Item;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Item;
   end Diagnostic_For_Error_Return;

   function Decode_String_Body
     (Payload : Unbounded_String;
      Result : out A11y.Results.Result)
      return Unbounded_String
   is
   begin
      return Decode_String_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_String_Body;

   function Decode_String_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Unbounded_String
   is
      Text : constant String := To_String (Payload);
      Index : Positive := 1;
      Value : Unbounded_String;
   begin
      if Length (Payload) = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Null_Unbounded_String;
      end if;

      Value := Read_DBus_String (Text, Index, Text'Length, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_String;
      elsif Index - 1 /= Text'Length then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Null_Unbounded_String;
      end if;

      Result := A11y.Results.Ok;
      return Value;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_String;
   end Decode_String_Body;

   function Decode_UInt32_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return Natural
   is
   begin
      return Decode_UInt32_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_UInt32_Body;

   function Decode_UInt32_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Natural
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return 0;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return 0;
      elsif Text'Length /= 4 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Read_U32_LE (Text, 1);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return 0;
   end Decode_UInt32_Body;

   function Decode_Int32_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return Integer
   is
   begin
      return Decode_Int32_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Int32_Body;

   function Decode_Int32_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Integer
   is
      function To_Signed is new Ada.Unchecked_Conversion
        (Interfaces.Unsigned_32, Interfaces.Integer_32);
      Bits : Interfaces.Unsigned_32;
   begin
      Bits := Interfaces.Unsigned_32
        (Decode_UInt32_Body (Payload, Limits, Result));
      if A11y.Results.Failed (Result) then
         return 0;
      end if;

      Result := A11y.Results.Ok;
      return Integer (To_Signed (Bits));
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return 0;
   end Decode_Int32_Body;

   function Decode_UInt32_Array_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.UInt32_Vectors.Vector
   is
   begin
      return Decode_UInt32_Array_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_UInt32_Array_Body;

   function Decode_UInt32_Array_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.UInt32_Vectors.Vector
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Byte_Length : Natural;
      Items : A11y.Linux.DBus_Codec.UInt32_Vectors.Vector;
      Index : Positive := 5;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Linux.DBus_Codec.UInt32_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.DBus_Codec.UInt32_Vectors.Empty_Vector;
      elsif Text'Length < 4 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.DBus_Codec.UInt32_Vectors.Empty_Vector;
      end if;

      Byte_Length := Read_U32_LE (Text, 1);
      if Byte_Length mod 4 /= 0
        or else Byte_Length > Text'Length - 4
        or else Text'Length /= Byte_Length + 4
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.DBus_Codec.UInt32_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Byte_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.DBus_Codec.UInt32_Vectors.Empty_Vector;
      end if;

      while Index <= Text'Last loop
         Items.Append (Read_U32_LE (Text, Index));
         Index := Index + 4;
      end loop;

      Result := A11y.Results.Ok;
      return Items;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.DBus_Codec.UInt32_Vectors.Empty_Vector;
   end Decode_UInt32_Array_Body;

   function Decode_Object_Path_Array_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector
   is
   begin
      return Decode_Object_Path_Array_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Object_Path_Array_Body;

   function Decode_Object_Path_Array_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Byte_Length : Natural;
      Items : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Index : Positive := 5;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif Text'Length < 4 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      Byte_Length := Read_U32_LE (Text, 1);
      if Byte_Length > Text'Length - 4
        or else Text'Length /= Byte_Length + 4
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Byte_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      while Index <= Text'Last loop
         declare
            Path : constant Unbounded_String :=
              Read_DBus_String (Text, Index, Text'Last, Limits, Result);
         begin
            if A11y.Results.Failed (Result) then
               return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
            end if;
            Items.Append (Path);
         end;
      end loop;

      Encoded := A11y.Linux.DBus_Codec.Make_Object_Path_Array
        (Items, Limits, Result);
      if A11y.Results.Failed (Result) then
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif Encoded.Kind /= A11y.Linux.DBus_Codec.Object_Path_Array_Value then
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      Result := A11y.Results.Ok;
      return Items;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
   end Decode_Object_Path_Array_Body;

   function Decode_String_Array_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector
   is
   begin
      return Decode_String_Array_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_String_Array_Body;

   function Decode_String_Array_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.DBus_Codec.String_Vectors.Vector
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Byte_Length : Natural;
      Items : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Index : Positive := 5;
      Encoded : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif Text'Length < 4 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      Byte_Length := Read_U32_LE (Text, 1);
      if Byte_Length > Text'Length - 4
        or else Text'Length /= Byte_Length + 4
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Byte_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      while Index <= Text'Last loop
         declare
            Item : constant Unbounded_String :=
              Read_DBus_String (Text, Index, Text'Last, Limits, Result);
         begin
            if A11y.Results.Failed (Result) then
               return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
            end if;
            Items.Append (Item);
         end;
      end loop;

      Encoded := A11y.Linux.DBus_Codec.Make_String_Array
        (Items, Limits, Result);
      if A11y.Results.Failed (Result) then
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      elsif Encoded.Kind /= A11y.Linux.DBus_Codec.String_Array_Value then
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
      end if;

      Result := A11y.Results.Ok;
      return Items;
   exception
      when others =>
      Result := (Status => A11y.Results.Internal_Error);
      return A11y.Linux.DBus_Codec.String_Vectors.Empty_Vector;
   end Decode_String_Array_Body;

   function Decode_Attribute_Set_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector
   is
   begin
      return Decode_Attribute_Set_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Attribute_Set_Body;

   function Decode_Attribute_Set_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Byte_Length : Natural;
      Index : Positive := 5;
      End_Index : Natural;
      Items : A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
      elsif Text'Length < 4 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
      end if;

      Byte_Length := Read_U32_LE (Text, 1);
      if Byte_Length > Text'Length - 4
        or else Text'Length /= Align_Length (4, 8) + Byte_Length
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Byte_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
      end if;

      Index := Align_Length (4, 8) + 1;
      End_Index := Index + Byte_Length - 1;
      while Index <= End_Index loop
         declare
            Key : Unbounded_String;
            Value : Unbounded_String;
         begin
            Index := Align_Length (Index - 1, 8) + 1;
            if Index > End_Index then
               Result := (Status => A11y.Results.Invalid_Argument);
               return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
            end if;

            Key := Read_DBus_String (Text, Index, End_Index, Limits, Result);
            if A11y.Results.Failed (Result) then
               return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
            end if;

            Value := Read_DBus_String (Text, Index, End_Index, Limits, Result);
            if A11y.Results.Failed (Result) then
               return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
            end if;

            Items.Append
              (A11y.Linux.ATSPi_Accessible.Attribute_Entry'
                 (Key   => Key,
                  Value => Value));
         end;
      end loop;

      if Index - 1 /= End_Index then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
      end if;

      Result := A11y.Results.Ok;
      return Items;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Empty_Vector;
   end Decode_Attribute_Set_Body;

   function Decode_Relation_Set_Body
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector
   is
   begin
      return Decode_Relation_Set_Body
        (Session, Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Relation_Set_Body;

   function Decode_Relation_Set_Body
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Byte_Length : Natural;
      Index : Positive := 5;
      End_Index : Natural;
      Items : A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
      Total_Targets : Natural := 0;
      Target_Limit : constant Natural :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      elsif Session = A11y.Native_Identity.No_Session then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Text'Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      elsif Text'Length < 4 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      end if;

      Byte_Length := Read_U32_LE (Text, 1);
      if Byte_Length > Text'Length - 4
        or else Text'Length /= Align_Length (4, 8) + Byte_Length
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      elsif A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Native_Array_Size, Byte_Length)
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      end if;

      Index := Align_Length (4, 8) + 1;
      End_Index := Index + Byte_Length - 1;
      while Index <= End_Index loop
         declare
            Relation_Value : Natural;
            Target_Byte_Length : Natural;
            Target_End_Index : Natural;
            Item : A11y.Linux.ATSPi_Accessible.Relation_Entry;
         begin
            Index := Align_Length (Index - 1, 8) + 1;
            Ensure_Available (Text, Index, 4, Result);
            if A11y.Results.Failed (Result)
              or else Index + 3 > End_Index
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
            end if;

            Relation_Value := Read_U32_LE (Text, Index);
            if Relation_Value >
              A11y.Linux.ATSPi_Mappings.ATSPI_Relation'Pos
                (A11y.Linux.ATSPi_Mappings.ATSPI_Relation'Last)
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
            end if;
            Item.Kind :=
              A11y.Linux.ATSPi_Mappings.ATSPI_Relation'Val
                (Relation_Value);
            Index := Index + 4;

            Index := Align_Length (Index - 1, 4) + 1;
            Ensure_Available (Text, Index, 4, Result);
            if A11y.Results.Failed (Result)
              or else Index + 3 > End_Index
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
            end if;

            Target_Byte_Length := Read_U32_LE (Text, Index);
            Index := Index + 4;
            if Target_Byte_Length > End_Index - Index + 1
              or else A11y.Resource_Limits.Exceeded
                (Limits,
                 A11y.Resource_Limits.Native_Array_Size,
                 Target_Byte_Length)
            then
               Result :=
                 (Status =>
                    (if Target_Byte_Length > End_Index - Index + 1
                     then A11y.Results.Invalid_Argument
                     else A11y.Results.Resource_Limit));
               return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
            end if;

            Target_End_Index := Index + Target_Byte_Length - 1;
            while Index <= Target_End_Index loop
               declare
                  Path : constant Unbounded_String :=
                    Read_DBus_String
                      (Text, Index, Target_End_Index, Limits, Result);
                  Target : A11y.Node_Ids.Node_Id;
               begin
                  if A11y.Results.Failed (Result) then
                     return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
                  end if;

                  Target := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
                    (Session, To_String (Path), Result);
                  if A11y.Results.Failed (Result) then
                     return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
                  elsif Total_Targets >= Target_Limit then
                     Result := (Status => A11y.Results.Resource_Limit);
                     return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
                  end if;

                  Item.Targets.Append (Target);
                  Total_Targets := Total_Targets + 1;
               end;
            end loop;

            if Index - 1 /= Target_End_Index then
               Result := (Status => A11y.Results.Invalid_Argument);
               return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
            end if;

            Items.Append (Item);
         end;
      end loop;

      if Index - 1 /= End_Index then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
      end if;

      Result := A11y.Results.Ok;
      return Items;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Empty_Vector;
   end Decode_Relation_Set_Body;

   function Decode_Boolean_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return Boolean
   is
   begin
      return Decode_Boolean_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Boolean_Body;

   function Decode_Boolean_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Boolean
   is
      Value : constant Natural := Decode_UInt32_Body (Payload, Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return False;
      elsif Value > 1 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return False;
      end if;

      Result := A11y.Results.Ok;
      return Value = 1;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return False;
   end Decode_Boolean_Body;

   function Decode_Rectangle_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Rectangle
   is
   begin
      return Decode_Rectangle_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Rectangle_Body;

   function Decode_Rectangle_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Rectangle
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Width_Value : Integer;
      Height_Value : Integer;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return A11y.Geometry.Empty_Rectangle;
      elsif Text'Length /= 16 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Geometry.Empty_Rectangle;
      end if;

      Width_Value := Read_I32_LE (Text, Text'First + 8);
      Height_Value := Read_I32_LE (Text, Text'First + 12);
      if Width_Value < 0 or else Height_Value < 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return A11y.Geometry.Empty_Rectangle;
      end if;

      Result := A11y.Results.Ok;
      return
        (Origin =>
           (X => A11y.Geometry.Coordinate (Read_I32_LE (Text, Text'First)),
            Y => A11y.Geometry.Coordinate
              (Read_I32_LE (Text, Text'First + 4))),
         Extent =>
           (Width  => A11y.Geometry.Length (Width_Value),
            Height => A11y.Geometry.Length (Height_Value)));
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Geometry.Empty_Rectangle;
   end Decode_Rectangle_Body;

   function Decode_Size_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Size
   is
   begin
      return Decode_Size_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Size_Body;

   function Decode_Size_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return A11y.Geometry.Size
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
      Width_Value : Integer;
      Height_Value : Integer;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return (Width => 0, Height => 0);
      elsif Text'Length /= 8 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (Width => 0, Height => 0);
      end if;

      Width_Value := Read_I32_LE (Text, Text'First);
      Height_Value := Read_I32_LE (Text, Text'First + 4);
      if Width_Value < 0 or else Height_Value < 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (Width => 0, Height => 0);
      end if;

      Result := A11y.Results.Ok;
      return
        (Width  => A11y.Geometry.Length (Width_Value),
         Height => A11y.Geometry.Length (Height_Value));
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Width => 0, Height => 0);
   end Decode_Size_Body;

   function Decode_Float_Body
     (Payload : Unbounded_String;
      Result  : out A11y.Results.Result)
      return Long_Float
   is
   begin
      return Decode_Float_Body
        (Payload, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Float_Body;

   function Decode_Float_Body
     (Payload : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Long_Float
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Text : constant String := To_String (Payload);
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return 0.0;
      elsif Long_Float'Size /= 64 then
         Result := (Status => A11y.Results.Native_Failure);
         return 0.0;
      elsif Text'Length /= 8 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return 0.0;
      end if;

      Result := A11y.Results.Ok;
      return Read_Double_LE (Text, Text'First);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return 0.0;
   end Decode_Float_Body;

   function Decode_Incoming_Call
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Bytes   : Unbounded_String;
      Result  : out A11y.Results.Result)
      return Incoming_Call
   is
   begin
      return Decode_Incoming_Call
        (Session, Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Decode_Incoming_Call;

   function Decode_Incoming_Call
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Bytes   : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Incoming_Call
   is
      Envelope : constant Transport_Envelope :=
        Decode_Transport_Envelope (Bytes, Limits, Result);
      Call : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Call;
      Incoming : Incoming_Call;
      Validation : A11y.Results.Result;
   begin
      if A11y.Results.Failed (Result) then
         return Empty_Incoming_Call (Envelope.Kind);
      elsif Envelope.Kind /= Method_Call then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Incoming_Call (Envelope.Kind);
      elsif Length (Envelope.Error_Name) /= 0
        or else Envelope.Reply_Serial /= 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Incoming_Call (Envelope.Kind);
      elsif Length (Envelope.Body_Signature) /= 0
        and then To_String (Envelope.Body_Signature) /= "o"
        and then To_String (Envelope.Body_Signature) /= "(so)"
        and then To_String (Envelope.Body_Signature) /= "s"
        and then To_String (Envelope.Body_Signature) /= "ss"
        and then To_String (Envelope.Body_Signature) /= "u"
        and then To_String (Envelope.Body_Signature) /= "uu"
        and then To_String (Envelope.Body_Signature) /= "uus"
        and then To_String (Envelope.Body_Signature) /= "ii"
        and then To_String (Envelope.Body_Signature) /= "d"
      then
         Result := (Status => A11y.Results.Unsupported_Capability);
         return Empty_Incoming_Call (Envelope.Kind);
      end if;

      Call.Session := Session;
      Call.Object_Path := Envelope.Object_Path;
      Call.Interface_Name := Envelope.Interface_Name;
      Call.Method_Name := Envelope.Member_Name;
      Call.Attribute := Envelope.Body_Object_Path_Argument;
      if To_String (Envelope.Body_Signature) = "s" then
         Call.Attribute := Envelope.Body_String_Argument;
      elsif To_String (Envelope.Body_Signature) = "ss" then
         Call.Attribute := Envelope.Body_String_Argument;
         Call.Attribute_2 := Envelope.Body_String_Argument_2;
      end if;
      if To_String (Envelope.Body_Signature) = "u" then
         Call.Index := Envelope.Body_UInt32_Argument;
      elsif To_String (Envelope.Body_Signature) = "uu" then
         Call.Index := Envelope.Body_UInt32_Argument;
         Call.Count := Envelope.Body_UInt32_Argument_2;
      elsif To_String (Envelope.Body_Signature) = "uus" then
         Call.Index := Envelope.Body_UInt32_Argument;
         Call.Count := Envelope.Body_UInt32_Argument_2;
         Call.Attribute := Envelope.Body_String_Argument;
      elsif To_String (Envelope.Body_Signature) = "ii" then
         Call.Point := Envelope.Body_Point_Argument;
         if To_String (Envelope.Interface_Name) =
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Table)
           or else To_String (Envelope.Interface_Name) =
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Table_Cell)
         then
            if Envelope.Body_Point_Argument.X < 0
              or else Envelope.Body_Point_Argument.Y < 0
              or else Envelope.Body_Point_Argument.X >
                A11y.Geometry.Coordinate (A11y.Tables.Logical_Index'Last)
              or else Envelope.Body_Point_Argument.Y >
                A11y.Geometry.Coordinate (A11y.Tables.Logical_Index'Last)
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Incoming_Call (Envelope.Kind);
            end if;
            Call.Row :=
              A11y.Tables.Logical_Index (Envelope.Body_Point_Argument.X);
            Call.Column :=
              A11y.Tables.Logical_Index (Envelope.Body_Point_Argument.Y);
         elsif To_String (Envelope.Interface_Name) =
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Text)
           or else To_String (Envelope.Interface_Name) =
              A11y.Linux.ATSPi_Objects.Interface_Name
                (A11y.Linux.ATSPi_Objects.Editable_Text)
         then
            if Integer (Envelope.Body_Point_Argument.X) < 0
              or else Integer (Envelope.Body_Point_Argument.Y) < 0
            then
               Result := (Status => A11y.Results.Invalid_Argument);
               return Empty_Incoming_Call (Envelope.Kind);
            end if;
            Call.Index := Natural (Envelope.Body_Point_Argument.X);
            Call.Count := Natural (Envelope.Body_Point_Argument.Y);
         end if;
      elsif To_String (Envelope.Body_Signature) = "d" then
         Call.Requested_Value :=
           A11y.Values.Floating (Envelope.Body_Float_Argument);
      end if;

      Incoming.Header :=
        (Kind           => Envelope.Kind,
         Serial         => Envelope.Serial,
         Reply_Serial   => Envelope.Reply_Serial,
         Object_Path    => Envelope.Object_Path,
         Interface_Name => Envelope.Interface_Name,
         Member_Name    => Envelope.Member_Name,
         Error_Name     => Envelope.Error_Name,
         Sender_Name    => Envelope.Sender_Name);
      Incoming.Call := Call;

      Validation := Validate_Call (Incoming, Limits);
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return Empty_Incoming_Call (Envelope.Kind);
      end if;

      Result := A11y.Results.Ok;
      return Incoming;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Incoming_Call (Method_Call);
   end Decode_Incoming_Call;

   function Method_Return_Body_Signature
     (Routed_Kind : A11y.Linux.ATSPi_Method_Router.Routed_Reply_Kind)
      return String is
     (case Routed_Kind is
        when A11y.Linux.ATSPi_Method_Router.Empty_Method_Return =>
          "",
        when A11y.Linux.ATSPi_Method_Router.DBus_Variant_String
           | A11y.Linux.ATSPi_Method_Router.DBus_Variant_UInt32 =>
          "v",
        when A11y.Linux.ATSPi_Method_Router.DBus_Property_Map =>
          "a{sv}",
        when A11y.Linux.ATSPi_Method_Router.Application_String
           | A11y.Linux.ATSPi_Method_Router.Accessible_String
           | A11y.Linux.ATSPi_Method_Router.Action_String
           | A11y.Linux.ATSPi_Method_Router.Text_Wide_Text
           | A11y.Linux.ATSPi_Method_Router.Image_String
           | A11y.Linux.ATSPi_Method_Router.Document_String
           | A11y.Linux.ATSPi_Method_Router.Live_String
           | A11y.Linux.ATSPi_Method_Router.Surface_String =>
          "s",
        when A11y.Linux.ATSPi_Method_Router.Application_UInt32
           | A11y.Linux.ATSPi_Method_Router.Accessible_Role
           | A11y.Linux.ATSPi_Method_Router.Accessible_UInt32
           | A11y.Linux.ATSPi_Method_Router.Action_UInt32
           | A11y.Linux.ATSPi_Method_Router.Selection_UInt32
           | A11y.Linux.ATSPi_Method_Router.Text_UInt32
           | A11y.Linux.ATSPi_Method_Router.Table_UInt32
           | A11y.Linux.ATSPi_Method_Router.Document_UInt32
           | A11y.Linux.ATSPi_Method_Router.Surface_Role =>
          "u",
        when A11y.Linux.ATSPi_Method_Router.Accessible_Int32 =>
          "i",
        when A11y.Linux.ATSPi_Method_Router.Accessible_State_Set
           | A11y.Linux.ATSPi_Method_Router.Surface_State_Set =>
          "au",
        when A11y.Linux.ATSPi_Method_Router.Accessible_Attribute_Set =>
          "a{ss}",
        when A11y.Linux.ATSPi_Method_Router.Accessible_Relation_Set =>
          "a(uao)",
        when A11y.Linux.ATSPi_Method_Router.Accessible_Node_Array =>
          "ao",
        when A11y.Linux.ATSPi_Method_Router.Accessible_String_Array =>
          "as",
        when A11y.Linux.ATSPi_Method_Router.Component_Rectangle =>
          "(iiii)",
        when A11y.Linux.ATSPi_Method_Router.Component_Boolean
           | A11y.Linux.ATSPi_Method_Router.Action_Invocation
           | A11y.Linux.ATSPi_Method_Router.Selection_Boolean
           | A11y.Linux.ATSPi_Method_Router.Selection_Request
           | A11y.Linux.ATSPi_Method_Router.Text_Edit_Request
           | A11y.Linux.ATSPi_Method_Router.Document_Boolean
           | A11y.Linux.ATSPi_Method_Router.Live_Boolean
           | A11y.Linux.ATSPi_Method_Router.Surface_Boolean =>
          "b",
        when A11y.Linux.ATSPi_Method_Router.Component_Node
           | A11y.Linux.ATSPi_Method_Router.Accessible_Node
           | A11y.Linux.ATSPi_Method_Router.Selection_Node
           | A11y.Linux.ATSPi_Method_Router.Table_Node =>
          "o",
        when A11y.Linux.ATSPi_Method_Router.Value_Float =>
          "d",
        when A11y.Linux.ATSPi_Method_Router.Value_Set_Request =>
          "b",
        when A11y.Linux.ATSPi_Method_Router.Image_Size =>
          "(ii)",
        when A11y.Linux.ATSPi_Method_Router.Routed_Error =>
          "");

   function Method_Return_Payload_Bytes
     (Message : Outgoing_Message;
      Result  : out A11y.Results.Result)
      return Unbounded_String
   is
   begin
      return Method_Return_Payload_Bytes
        (Message, A11y.Resource_Limits.Default_Config, Result);
   end Method_Return_Payload_Bytes;

   function Method_Return_Payload_Bytes
     (Message : Outgoing_Message;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Unbounded_String
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Bytes : Unbounded_String := Null_Unbounded_String;
      Signature : constant String :=
        (if Message.Kind = Method_Return
         then Method_Return_Body_Signature (Message.Routed_Kind)
         else "");

      function Fits_I32 (Value : Long_Integer) return Boolean is
        (Value >= Long_Integer (Integer'First)
         and then Value <= Long_Integer (Integer'Last));

      procedure Check_Size is
      begin
         if A11y.Resource_Limits.Exceeded
           (Limits, A11y.Resource_Limits.Native_Array_Size, Length (Bytes))
         then
            Result := (Status => A11y.Results.Resource_Limit);
         end if;
      end Check_Size;

      function UInt32_Value (Text : Unbounded_String) return Natural is
      begin
         return Natural'Value (To_String (Text));
      exception
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return 0;
      end UInt32_Value;

      procedure Append_Property_Map_Entry
        (Map_Bytes : in out Unbounded_String;
         Name      : Unbounded_String;
         Signature : Unbounded_String;
         Value     : Unbounded_String)
      is
         Ignored : A11y.Linux.DBus_Codec.DBus_Value;
         Sig : constant String := To_String (Signature);
      begin
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Ignored := A11y.Linux.DBus_Codec.Make_String
           (To_String (Name), Limits, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         if Sig = "s" then
            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Value), Limits, Result);
         elsif Sig = "u" then
            Ignored := A11y.Linux.DBus_Codec.Make_UInt32
              (UInt32_Value (Value), Result);
         else
            Result := (Status => A11y.Results.Unsupported_Property);
         end if;

         if A11y.Results.Failed (Result) then
            return;
         end if;

         Align (Map_Bytes, 8);
         Append_DBus_String (Map_Bytes, Name);
         Append_DBus_Signature (Map_Bytes, Sig);
         if Sig = "s" then
            Append_DBus_String (Map_Bytes, Value);
         else
            Align (Map_Bytes, 4);
            Append_U32_LE (Map_Bytes, UInt32_Value (Value));
         end if;

         if A11y.Resource_Limits.Exceeded
           (Limits, A11y.Resource_Limits.Native_Array_Size,
            Length (Map_Bytes))
         then
            Result := (Status => A11y.Results.Resource_Limit);
         end if;
      end Append_Property_Map_Entry;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return Null_Unbounded_String;
      elsif Message.Kind /= Method_Return
        or else Message.Serial = 0
        or else Message.Reply_Serial = 0
        or else
          (Signature'Length = 0
           and then Message.Routed_Kind /=
             A11y.Linux.ATSPi_Method_Router.Empty_Method_Return)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Null_Unbounded_String;
      end if;

      Result := A11y.Results.Ok;
      case Message.Routed_Kind is
         when A11y.Linux.ATSPi_Method_Router.Empty_Method_Return =>
            null;

         when A11y.Linux.ATSPi_Method_Router.DBus_Variant_String =>
            declare
               Ignored : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.Payload_Text), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Null_Unbounded_String;
               end if;

               Append_DBus_Signature (Bytes, "s");
               Append_DBus_String (Bytes, Message.Payload_Text);
            end;

         when A11y.Linux.ATSPi_Method_Router.DBus_Variant_UInt32 =>
            declare
               Ignored : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               Ignored := A11y.Linux.DBus_Codec.Make_UInt32
                 (Message.Payload_UInt32, Result);
               if A11y.Results.Failed (Result) then
                  return Null_Unbounded_String;
               end if;

               Append_DBus_Signature (Bytes, "u");
               Align (Bytes, 4);
               Append_U32_LE (Bytes, Message.Payload_UInt32);
            end;

         when A11y.Linux.ATSPi_Method_Router.DBus_Property_Map =>
            declare
               Map_Bytes : Unbounded_String := Null_Unbounded_String;
               Count : constant Natural := Natural
                 (Message.Payload_Strings.Length);
            begin
               if Count mod 3 /= 0 then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Null_Unbounded_String;
               end if;

               declare
                  Index : A11y.Linux.DBus_Codec.String_Vectors.Extended_Index :=
                    Message.Payload_Strings.First_Index;
               begin
                  while Index <= Message.Payload_Strings.Last_Index loop
                     Append_Property_Map_Entry
                       (Map_Bytes,
                        Message.Payload_Strings.Element (Index),
                        Message.Payload_Strings.Element (Index + 1),
                        Message.Payload_Strings.Element (Index + 2));
                     if A11y.Results.Failed (Result) then
                        return Null_Unbounded_String;
                     end if;
                     Index := Index + 3;
                  end loop;
               end;

               Align (Bytes, 4);
               Append_U32_LE (Bytes, Length (Map_Bytes));
               Align (Bytes, 8);
               Append (Bytes, Map_Bytes);
            end;

         when A11y.Linux.ATSPi_Method_Router.Application_String
            | A11y.Linux.ATSPi_Method_Router.Accessible_String
            | A11y.Linux.ATSPi_Method_Router.Action_String
            | A11y.Linux.ATSPi_Method_Router.Text_Wide_Text
            | A11y.Linux.ATSPi_Method_Router.Image_String
            | A11y.Linux.ATSPi_Method_Router.Document_String
            | A11y.Linux.ATSPi_Method_Router.Live_String
            | A11y.Linux.ATSPi_Method_Router.Surface_String =>
            declare
               Ignored : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               Ignored := A11y.Linux.DBus_Codec.Make_String
                 (To_String (Message.Payload_Text), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Null_Unbounded_String;
               end if;
               Append_DBus_String (Bytes, Message.Payload_Text);
            end;

         when A11y.Linux.ATSPi_Method_Router.Application_UInt32
            | A11y.Linux.ATSPi_Method_Router.Accessible_Role
            | A11y.Linux.ATSPi_Method_Router.Accessible_UInt32
            | A11y.Linux.ATSPi_Method_Router.Action_UInt32
            | A11y.Linux.ATSPi_Method_Router.Selection_UInt32
            | A11y.Linux.ATSPi_Method_Router.Text_UInt32
            | A11y.Linux.ATSPi_Method_Router.Table_UInt32
            | A11y.Linux.ATSPi_Method_Router.Document_UInt32
            | A11y.Linux.ATSPi_Method_Router.Surface_Role =>
            Align (Bytes, 4);
            Append_U32_LE (Bytes, Message.Payload_UInt32);

         when A11y.Linux.ATSPi_Method_Router.Accessible_Int32 =>
            Align (Bytes, 4);
            Append_I32_LE (Bytes, Message.Payload_Int32);

         when A11y.Linux.ATSPi_Method_Router.Component_Boolean
            | A11y.Linux.ATSPi_Method_Router.Action_Invocation
            | A11y.Linux.ATSPi_Method_Router.Selection_Boolean
            | A11y.Linux.ATSPi_Method_Router.Selection_Request
            | A11y.Linux.ATSPi_Method_Router.Text_Edit_Request
            | A11y.Linux.ATSPi_Method_Router.Document_Boolean
            | A11y.Linux.ATSPi_Method_Router.Live_Boolean
            | A11y.Linux.ATSPi_Method_Router.Surface_Boolean
            | A11y.Linux.ATSPi_Method_Router.Value_Set_Request =>
            Append_Boolean (Bytes, Message.Payload_Boolean);

         when A11y.Linux.ATSPi_Method_Router.Component_Node
            | A11y.Linux.ATSPi_Method_Router.Accessible_Node
            | A11y.Linux.ATSPi_Method_Router.Selection_Node
            | A11y.Linux.ATSPi_Method_Router.Table_Node =>
            declare
               Ignored : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
                 (To_String (Message.Payload_Object_Path), Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Null_Unbounded_String;
               end if;
               Append_DBus_String (Bytes, Message.Payload_Object_Path);
            end;

         when A11y.Linux.ATSPi_Method_Router.Accessible_Node_Array =>
            declare
               Path_Bytes : Unbounded_String := Null_Unbounded_String;
               Paths : A11y.Linux.DBus_Codec.String_Vectors.Vector;
               Encoded : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               if Message.Payload_Session =
                 A11y.Native_Identity.No_Session
               then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return Null_Unbounded_String;
               end if;

               for Node of Message.Payload_Nodes loop
                  declare
                     Path : constant Unbounded_String :=
                       A11y.Linux.ATSPi_Objects.Object_Path
                         (Message.Payload_Session, Node, Result);
                  begin
                     if A11y.Results.Failed (Result) then
                        return Null_Unbounded_String;
                     end if;
                     Paths.Append (Path);
                  end;
               end loop;

               Encoded := A11y.Linux.DBus_Codec.Make_Object_Path_Array
                 (Paths, Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Null_Unbounded_String;
               elsif Encoded.Kind /=
                 A11y.Linux.DBus_Codec.Object_Path_Array_Value
               then
                  Result := (Status => A11y.Results.Internal_Error);
                  return Null_Unbounded_String;
               end if;

               for Path of Paths loop
                  Append_DBus_String (Path_Bytes, Path);
                  if A11y.Resource_Limits.Exceeded
                    (Limits,
                     A11y.Resource_Limits.Native_Array_Size,
                     Length (Path_Bytes))
                  then
                     Result := (Status => A11y.Results.Resource_Limit);
                     return Null_Unbounded_String;
                  end if;
               end loop;

               Align (Bytes, 4);
               Append_U32_LE (Bytes, Length (Path_Bytes));
               Append (Bytes, Path_Bytes);
            end;

         when A11y.Linux.ATSPi_Method_Router.Accessible_String_Array =>
            declare
               String_Bytes : Unbounded_String := Null_Unbounded_String;
               Encoded : A11y.Linux.DBus_Codec.DBus_Value;
            begin
               Encoded := A11y.Linux.DBus_Codec.Make_String_Array
                 (Message.Payload_Strings, Limits, Result);
               if A11y.Results.Failed (Result) then
                  return Null_Unbounded_String;
               elsif Encoded.Kind /=
                 A11y.Linux.DBus_Codec.String_Array_Value
               then
                  Result := (Status => A11y.Results.Internal_Error);
                  return Null_Unbounded_String;
               end if;

               for Item of Message.Payload_Strings loop
                  Append_DBus_String (String_Bytes, Item);
                  if A11y.Resource_Limits.Exceeded
                    (Limits,
                     A11y.Resource_Limits.Native_Array_Size,
                     Length (String_Bytes))
                  then
                     Result := (Status => A11y.Results.Resource_Limit);
                     return Null_Unbounded_String;
                  end if;
               end loop;

               Align (Bytes, 4);
               Append_U32_LE (Bytes, Length (String_Bytes));
               Append (Bytes, String_Bytes);
            end;

         when A11y.Linux.ATSPi_Method_Router.Component_Rectangle =>
            if not Fits_I32 (Long_Integer (Message.Payload_Bounds.Origin.X))
              or else not Fits_I32
                (Long_Integer (Message.Payload_Bounds.Origin.Y))
            then
               Result := (Status => A11y.Results.Resource_Limit);
               return Null_Unbounded_String;
            end if;
            Align (Bytes, 8);
            Append_I32_LE (Bytes, Integer (Message.Payload_Bounds.Origin.X));
            Append_I32_LE (Bytes, Integer (Message.Payload_Bounds.Origin.Y));
            Append_I32_LE
              (Bytes, Integer (Message.Payload_Bounds.Extent.Width));
            Append_I32_LE
              (Bytes, Integer (Message.Payload_Bounds.Extent.Height));

         when A11y.Linux.ATSPi_Method_Router.Image_Size =>
            Align (Bytes, 8);
            Append_I32_LE (Bytes, Integer (Message.Payload_Size.Width));
            Append_I32_LE (Bytes, Integer (Message.Payload_Size.Height));

         when A11y.Linux.ATSPi_Method_Router.Value_Float =>
            if Long_Float'Size /= 64 then
               Result := (Status => A11y.Results.Native_Failure);
               return Null_Unbounded_String;
            end if;
            Append_Double (Bytes, Message.Payload_Float);

         when A11y.Linux.ATSPi_Method_Router.Accessible_State_Set
            | A11y.Linux.ATSPi_Method_Router.Surface_State_Set =>
            Append_State_Set
              (Bytes, Message.Payload_State_Set, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Null_Unbounded_String;
            end if;

         when A11y.Linux.ATSPi_Method_Router.Accessible_Relation_Set =>
            Append_Relation_Set
              (Bytes,
               Message.Payload_Session,
               Message.Payload_Relations,
               Limits,
               Result);
            if A11y.Results.Failed (Result) then
               return Null_Unbounded_String;
            end if;

         when A11y.Linux.ATSPi_Method_Router.Accessible_Attribute_Set =>
            Append_Attribute_Set
              (Bytes, Message.Payload_Attributes, Limits, Result);
            if A11y.Results.Failed (Result) then
               return Null_Unbounded_String;
            end if;

         when A11y.Linux.ATSPi_Method_Router.Routed_Error =>
            Result := (Status => A11y.Results.Unsupported_Capability);
            return Null_Unbounded_String;
      end case;

      Check_Size;
      if A11y.Results.Failed (Result) then
         return Null_Unbounded_String;
      end if;

      Result := A11y.Results.Ok;
      return Bytes;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Null_Unbounded_String;
   end Method_Return_Payload_Bytes;

   function Validate_Call
     (Message : Incoming_Call)
      return A11y.Results.Result
   is
   begin
      return Validate_Call (Message, A11y.Resource_Limits.Default_Config);
   end Validate_Call;

   function Validate_Call
     (Message : Incoming_Call;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif Message.Header.Kind /= Method_Call then
         return (Status => A11y.Results.Invalid_Argument);
      elsif Message.Header.Serial = 0 then
         return (Status => A11y.Results.Invalid_Argument);
      elsif Message.Header.Reply_Serial /= 0
        or else Length (Message.Header.Error_Name) /= 0
      then
         return (Status => A11y.Results.Invalid_Argument);
      elsif Length (Message.Header.Interface_Name) = 0
        or else Length (Message.Header.Member_Name) = 0
        or else Length (Message.Call.Interface_Name) = 0
        or else Length (Message.Call.Method_Name) = 0
      then
         return (Status => A11y.Results.Invalid_Argument);
      elsif not A11y.Native_Identity.Is_Valid (Message.Call.Session) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Message.Header.Object_Path), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Message.Header.Interface_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Interface_Name
        (To_String (Message.Header.Interface_Name))
      then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Message.Header.Member_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Member_Name
        (To_String (Message.Header.Member_Name))
      then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Message.Call.Object_Path), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Message.Call.Interface_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Interface_Name
        (To_String (Message.Call.Interface_Name))
      then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Message.Call.Method_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Member_Name
        (To_String (Message.Call.Method_Name))
      then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Message.Call.Attribute), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Message.Call.Attribute_2), Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      if To_String (Message.Header.Object_Path) /=
           To_String (Message.Call.Object_Path)
        or else To_String (Message.Header.Interface_Name) /=
           To_String (Message.Call.Interface_Name)
        or else To_String (Message.Header.Member_Name) /=
           To_String (Message.Call.Method_Name)
      then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      return A11y.Results.Ok;
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Validate_Call;

   function Build_Reply
     (Original : Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Serial   : Natural;
      Result   : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Reply
        (Original, Reply, Serial, A11y.Resource_Limits.Default_Config, Result);
   end Build_Reply;

   function Build_Reply
     (Original : Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Serial   : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Outgoing_Message
   is
      Validation : constant A11y.Results.Result :=
        Validate_Call (Original, Limits);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      Payload_Path : Unbounded_String := Null_Unbounded_String;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => Original.Header.Serial,
            Status       => Validation.Status,
            Object_Path  => Original.Header.Sender_Name,
            Error_Name   => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Error_Name (Validation.Status)));
      elsif Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => Original.Header.Serial,
            Status       => A11y.Results.Invalid_Argument,
            Object_Path  => Original.Header.Sender_Name,
            Error_Name   => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Error_Name
                 (A11y.Results.Invalid_Argument)));
      end if;

      Result := A11y.Results.Ok;
      case Reply.Kind is
         when A11y.Linux.ATSPi_DBus_Boundary.Method_Reply =>
            if (Reply.Routed_Kind in
                  A11y.Linux.ATSPi_Method_Router.Component_Node
                  | A11y.Linux.ATSPi_Method_Router.Accessible_Node
                  | A11y.Linux.ATSPi_Method_Router.Selection_Node
                  | A11y.Linux.ATSPi_Method_Router.Table_Node)
              or else
                (Reply.Routed_Kind =
                   A11y.Linux.ATSPi_Method_Router.Selection_Request
                 and then A11y.Node_Ids.Is_Valid (Reply.Node))
            then
               Payload_Path := A11y.Linux.ATSPi_Objects.Object_Path
                 (Original.Call.Session, Reply.Node, Result);
               if A11y.Results.Failed (Result) then
                  return
                    (Kind         => Error_Return,
                     Serial       => Serial,
                     Reply_Serial => Original.Header.Serial,
                     Status       => Result.Status,
                     Object_Path  => Original.Header.Sender_Name,
                     Error_Name   => To_Unbounded_String
                       (A11y.Linux.ATSPi_Objects.Error_Name
                          (Result.Status)));
               end if;
            end if;

            return
              (Kind         => Method_Return,
               Serial       => Serial,
               Reply_Serial => Original.Header.Serial,
               Status       => Reply.Status,
               Object_Path  => Original.Header.Sender_Name,
               Routed_Kind  => Reply.Routed_Kind,
               Payload_Text => Reply.Text,
               Payload_UInt32 => Reply.UInt32,
               Payload_Int32 => Reply.Int32,
               Payload_Boolean => Reply.Boolean_Item,
               Payload_Float => Reply.Float_Item,
               Payload_Object_Path => Payload_Path,
               Payload_Nodes => Reply.Nodes,
               Payload_Strings => Reply.Strings,
               Payload_Bounds => Reply.Bounds,
               Payload_Size => Reply.Size,
               Payload_State_Set => Reply.State_Set,
               Payload_Session => Original.Call.Session,
               Payload_Attributes => Reply.Attributes,
               Payload_Relations => Reply.Relations,
               Payload_Action => Reply.Requested_Action,
               Payload_Value => Reply.Requested_Value,
               Payload_Selection_Request => Reply.Selection_Request,
               Payload_Text_Edit => Reply.Requested_Edit);
         when A11y.Linux.ATSPi_DBus_Boundary.Error_Reply =>
            Ignored := A11y.Linux.DBus_Codec.Make_String
              (To_String (Reply.Error_Name), Limits, Result);
            if A11y.Results.Failed (Result) then
               return
                 (Kind         => Error_Return,
                  Serial       => Serial,
                  Reply_Serial => Original.Header.Serial,
                  Status       => Result.Status,
                  Object_Path  => Original.Header.Sender_Name,
                  Error_Name   => To_Unbounded_String
                    (A11y.Linux.ATSPi_Objects.Error_Name (Result.Status)));
            end if;

            return
              (Kind         => Error_Return,
               Serial       => Serial,
               Reply_Serial => Original.Header.Serial,
               Status       => Reply.Status,
               Object_Path  => Original.Header.Sender_Name,
               Error_Name   => Reply.Error_Name);
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => Original.Header.Serial,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Original.Header.Sender_Name,
            Error_Name   => To_Unbounded_String
              (A11y.Linux.ATSPi_Objects.Error_Name
                 (A11y.Results.Internal_Error)));
   end Build_Reply;

   function Build_Method_Call
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call
        (Object_Path, Interface_Name, Member_Name, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call;

   function Build_Method_Call
     (Object_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Path_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial               : Natural;
      Result               : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call
        (Object_Path, Interface_Name, Member_Name, Object_Path_Argument,
         Serial, A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call;

   function Build_Method_Call_String
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_String
        (Object_Path, Interface_Name, Member_Name, Argument, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call_String;

   function Build_Method_Call_String_Pair
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Ada.Strings.Unbounded.Unbounded_String;
      Second_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Result          : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_String_Pair
        (Object_Path, Interface_Name, Member_Name, First_Argument,
         Second_Argument, Serial, A11y.Resource_Limits.Default_Config,
         Result);
   end Build_Method_Call_String_Pair;

   function Build_Method_Call_String_Pair
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Ada.Strings.Unbounded.Unbounded_String;
      Second_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config;
      Result          : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (First_Argument), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Second_Argument), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_String_Pair_Argument := True;
      Message.String_Argument := First_Argument;
      Message.String_Argument_2 := Second_Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_String_Pair;

   function Build_Method_Call_Object_Reference
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Bus_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Reference_Path  : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Result          : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_Object_Reference
        (Object_Path, Interface_Name, Member_Name, Bus_Name, Reference_Path,
         Serial, A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call_Object_Reference;

   function Build_Method_Call_Object_Reference
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      Bus_Name        : Ada.Strings.Unbounded.Unbounded_String;
      Reference_Path  : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config;
      Result          : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Bus_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;
      if not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
        (To_String (Bus_Name))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Reference_Path), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_Object_Reference_Argument := True;
      Message.String_Argument := Bus_Name;
      Message.Object_Path_Argument := Reference_Path;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_Object_Reference;

   function Build_Method_Call_UInt32
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Natural;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_UInt32
        (Object_Path, Interface_Name, Member_Name, Argument, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call_UInt32;

   function Build_Method_Call_UInt32_Pair
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument : Natural;
      Second_Argument : Natural;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_UInt32_Pair
        (Object_Path, Interface_Name, Member_Name, First_Argument,
         Second_Argument, Serial, A11y.Resource_Limits.Default_Config,
         Result);
   end Build_Method_Call_UInt32_Pair;

   function Build_Method_Call_UInt32_Pair_String
     (Object_Path     : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name  : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name     : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument  : Natural;
      Second_Argument : Natural;
      Text_Argument   : Ada.Strings.Unbounded.Unbounded_String;
      Serial          : Natural;
      Result          : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_UInt32_Pair_String
        (Object_Path, Interface_Name, Member_Name, First_Argument,
         Second_Argument, Text_Argument, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call_UInt32_Pair_String;

   function Build_Method_Call_Point
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : A11y.Geometry.Point;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_Point
        (Object_Path, Interface_Name, Member_Name, Argument, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call_Point;

   function Build_Method_Call_Float
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Long_Float;
      Serial         : Natural;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call_Float
        (Object_Path, Interface_Name, Member_Name, Argument, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Method_Call_Float;

   function Build_Method_Call
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Method_Call
        (Object_Path, Interface_Name, Member_Name, Null_Unbounded_String,
         Serial, Limits, Result);
   end Build_Method_Call;

   function Build_Method_Call
     (Object_Path          : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name       : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name          : Ada.Strings.Unbounded.Unbounded_String;
      Object_Path_Argument : Ada.Strings.Unbounded.Unbounded_String;
      Serial               : Natural;
      Limits               : A11y.Resource_Limits.Resource_Limit_Config;
      Result               : out A11y.Results.Result)
      return Outgoing_Message
   is
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
      Has_Argument : constant Boolean := Length (Object_Path_Argument) /= 0;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Invalid_Argument,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif Length (Interface_Name) = 0 or else Length (Member_Name) = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Invalid_Argument,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Object_Path), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Interface_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Interface_Name
        (To_String (Interface_Name))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Member_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Member_Name
        (To_String (Member_Name))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      if Has_Argument then
         Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
           (To_String (Object_Path_Argument), Limits, Result);
         if A11y.Results.Failed (Result) then
            return
              (Kind         => Error_Return,
               Serial       => Serial,
               Reply_Serial => 0,
               Status       => Result.Status,
               Object_Path  => Null_Unbounded_String,
               Error_Name   => Null_Unbounded_String);
         end if;
      end if;

      Result := A11y.Results.Ok;
      return
        (Kind           => Method_Call,
         Serial         => Serial,
         Reply_Serial   => 0,
         Status         => A11y.Results.Success,
         Object_Path    => Object_Path,
         Interface_Name => Interface_Name,
         Member_Name    => Member_Name,
         Has_Object_Path_Argument => Has_Argument,
         Object_Path_Argument => Object_Path_Argument,
         Has_String_Argument => False,
         String_Argument => Null_Unbounded_String,
         Has_String_Pair_Argument => False,
         String_Argument_2 => Null_Unbounded_String,
         Has_Object_Reference_Argument => False,
         Has_UInt32_Argument => False,
         UInt32_Argument => 0,
         Has_UInt32_Pair_Argument => False,
         UInt32_Argument_2 => 0,
         Has_Point_Argument => False,
         Point_Argument => (X => 0, Y => 0),
         Has_Float_Argument => False,
         Float_Argument => 0.0);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
           Error_Name   => Null_Unbounded_String);
   end Build_Method_Call;

   function Build_Method_Call_String
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Ada.Strings.Unbounded.Unbounded_String;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Argument), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_String_Argument := True;
      Message.String_Argument := Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_String;

   function Build_Method_Call_UInt32
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Natural;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_UInt32 (Argument, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_UInt32_Argument := True;
      Message.UInt32_Argument := Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
           Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_UInt32;

   function Build_Method_Call_UInt32_Pair
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      First_Argument : Natural;
      Second_Argument : Natural;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_UInt32
        (First_Argument, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_UInt32
        (Second_Argument, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_UInt32_Pair_Argument := True;
      Message.UInt32_Argument := First_Argument;
      Message.UInt32_Argument_2 := Second_Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_UInt32_Pair;

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
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call_UInt32_Pair
          (Object_Path, Interface_Name, Member_Name, First_Argument,
           Second_Argument, Serial, Limits, Result);
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Text_Argument), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_String_Argument := True;
      Message.String_Argument := Text_Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_UInt32_Pair_String;

   function Build_Method_Call_Point
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : A11y.Geometry.Point;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
      function Fits_I32 (Value : A11y.Geometry.Coordinate) return Boolean is
        (Long_Integer (Value) >= Long_Integer (Integer'First)
         and then Long_Integer (Value) <= Long_Integer (Integer'Last));
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      elsif not Fits_I32 (Argument.X) or else not Fits_I32 (Argument.Y) then
         Result := (Status => A11y.Results.Resource_Limit);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_Point_Argument := True;
      Message.Point_Argument := Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
           Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_Point;

   function Build_Method_Call_Float
     (Object_Path    : Ada.Strings.Unbounded.Unbounded_String;
      Interface_Name : Ada.Strings.Unbounded.Unbounded_String;
      Member_Name    : Ada.Strings.Unbounded.Unbounded_String;
      Argument       : Long_Float;
      Serial         : Natural;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Outgoing_Message
   is
      Message : Outgoing_Message :=
        Build_Method_Call
          (Object_Path, Interface_Name, Member_Name, Serial, Limits, Result);
   begin
      if A11y.Results.Failed (Result) then
         return Message;
      elsif Long_Float'Size /= 64 then
         Result := (Status => A11y.Results.Native_Failure);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Message.Has_Float_Argument := True;
      Message.Float_Argument := Argument;
      return Message;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Method_Call_Float;

   function Build_Signal
     (Signal : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial : Natural;
      Result : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Signal
        (Signal, Serial, A11y.Resource_Limits.Default_Config, Result);
   end Build_Signal;

   function Build_Signal
     (Signal : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial : Natural;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Outgoing_Message
   is
      Ignored : A11y.Linux.DBus_Codec.DBus_Value;
   begin
      Result := A11y.Resource_Limits.Validate (Limits);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif not Signal.Publishable then
         Result := (Status => Signal.Status);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Signal.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Signal.Error_Name);
      elsif Serial = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Invalid_Argument,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif Length (Signal.Event_Name) = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => A11y.Results.Invalid_Argument,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_Object_Path
        (To_String (Signal.Object_Path), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Ignored := A11y.Linux.DBus_Codec.Make_String
        (To_String (Signal.Event_Name), Limits, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Result := A11y.Results.Ok;
      return
        (Kind         => Signal_Message,
         Serial       => Serial,
         Reply_Serial => 0,
         Status       => A11y.Results.Success,
         Object_Path  => Signal.Object_Path,
         Event_Name   => Signal.Event_Name);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
           Error_Name   => Null_Unbounded_String);
   end Build_Signal;

   procedure Build_Signal_With_Report
     (Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial  : Natural;
      Message : out Outgoing_Message;
      Report  : out Signal_Envelope_Build_Report)
   is
   begin
      Build_Signal_With_Report
        (Signal, Serial, A11y.Resource_Limits.Default_Config, Message,
         Report);
   end Build_Signal_With_Report;

   procedure Build_Signal_With_Report
     (Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Serial  : Natural;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Message : out Outgoing_Message;
      Report  : out Signal_Envelope_Build_Report)
   is
      Result : A11y.Results.Result;
   begin
      Report :=
        (Source                  => A11y.Node_Ids.No_Node,
         Sequence                => A11y.No_Event,
         Revision                => A11y.Initial_Revision,
         Serial                  => Serial,
         Prepared_Input          => False,
         Prepared_Has_Object     => False,
         Prepared_Destroys_Node  => False,
         Signal_Publishable      => Signal.Publishable,
         Object_Path_Validated   =>
           (Signal.Publishable and then Length (Signal.Object_Path) /= 0),
         Event_Name_Validated    =>
           (Signal.Publishable and then Length (Signal.Event_Name) /= 0),
         Output_Signal_Message   => False,
         Status                  => A11y.Results.Node_Unavailable);

      Message := Build_Signal (Signal, Serial, Limits, Result);

      Report.Output_Signal_Message := Message.Kind = Signal_Message;
      Report.Object_Path_Validated :=
        Report.Output_Signal_Message and then Length (Message.Object_Path) /= 0;
      Report.Event_Name_Validated :=
        Report.Output_Signal_Message and then Length (Message.Event_Name) /= 0;
      Report.Status := Result.Status;
   exception
      when others =>
         Message :=
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
         Report :=
           (Source                  => A11y.Node_Ids.No_Node,
            Sequence                => A11y.No_Event,
            Revision                => A11y.Initial_Revision,
            Serial                  => Serial,
            Prepared_Input          => False,
            Prepared_Has_Object     => False,
            Prepared_Destroys_Node  => False,
            Signal_Publishable      => False,
            Object_Path_Validated   => False,
            Event_Name_Validated    => False,
            Output_Signal_Message   => False,
            Status                  => A11y.Results.Internal_Error);
   end Build_Signal_With_Report;

   function Build_Signal
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Result   : out A11y.Results.Result)
      return Outgoing_Message
   is
   begin
      return Build_Signal
        (Session, Prepared, Serial, A11y.Resource_Limits.Default_Config,
         Result);
   end Build_Signal;

   function Build_Signal
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return Outgoing_Message
   is
      Signal : constant A11y.Linux.ATSPi_Signals.Signal_Emission :=
        A11y.Linux.ATSPi_Signals.Build_Signal (Session, Prepared);
   begin
      return Build_Signal (Signal, Serial, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Signal;

   procedure Build_Signal_With_Report
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Message  : out Outgoing_Message;
      Report   : out Signal_Envelope_Build_Report)
   is
   begin
      Build_Signal_With_Report
        (Session, Prepared, Serial, A11y.Resource_Limits.Default_Config,
         Message, Report);
   end Build_Signal_With_Report;

   procedure Build_Signal_With_Report
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Serial   : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Message  : out Outgoing_Message;
      Report   : out Signal_Envelope_Build_Report)
   is
      Signal : A11y.Linux.ATSPi_Signals.Signal_Emission;
   begin
      Signal := A11y.Linux.ATSPi_Signals.Build_Signal (Session, Prepared);
      Build_Signal_With_Report (Signal, Serial, Limits, Message, Report);

      Report.Source := Prepared.Event.Source;
      Report.Sequence := Prepared.Event.Sequence;
      Report.Revision := Prepared.Event.Revision;
      Report.Prepared_Input := True;
      Report.Prepared_Has_Object := Prepared.Has_Object;
      Report.Prepared_Destroys_Node := Prepared.Destroys_Node;
      if A11y.Results.Failed ((Status => Prepared.Status)) then
         Report.Status := Prepared.Status;
      end if;
   exception
      when others =>
         Message :=
           (Kind         => Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
         Report :=
           (Source                  => Prepared.Event.Source,
            Sequence                => Prepared.Event.Sequence,
            Revision                => Prepared.Event.Revision,
            Serial                  => Serial,
            Prepared_Input          => True,
            Prepared_Has_Object     => Prepared.Has_Object,
            Prepared_Destroys_Node  => Prepared.Destroys_Node,
            Signal_Publishable      => False,
            Object_Path_Validated   => False,
            Event_Name_Validated    => False,
            Output_Signal_Message   => False,
            Status                  => A11y.Results.Internal_Error);
   end Build_Signal_With_Report;

end A11y.Linux.DBus_Messages;
