with A11y.Linux.ATSPi_Objects;
with A11y.Linux.DBus_Codec;

package body A11y.Linux.ATSPi_Bus is
   use Ada.Strings.Unbounded;
   use type A11y.Results.Status_Code;
   use type A11y.Linux.DBus_Messages.Message_Kind;

   function Transport_Name (Transport : Transport_Kind) return String is
     (case Transport is
        when Unix_Transport => "unix",
        when Tcp_Transport => "tcp",
        when Launchd_Transport => "launchd",
        when Other_Transport => "other");

   function Empty_Context return Connection_Context is
     (State   => Disconnected,
      Address => (State => Address_Unavailable,
                  Transport => Other_Transport,
                  Text => Null_Unbounded_String,
                  Field_Count => 0),
      Session => A11y.Native_Identity.No_Session,
      Unique_Name => Null_Unbounded_String,
      Last_Serial => 0,
      Outgoing => <>,
      In_Flight => <>);

   function Is_Address_Character (Ch : Character) return Boolean is
     (Character'Pos (Ch) >= 33 and then Character'Pos (Ch) <= 126);

   function Is_Name_Character (Ch : Character) return Boolean is
     (Ch in 'A' .. 'Z'
      or else Ch in 'a' .. 'z'
      or else Ch in '0' .. '9'
      or else Ch in '_' | '-');

   function Is_Valid_Unique_Name (Name : String) return Boolean is
   begin
      return Name'Length > 0
        and then Name (Name'First) = ':'
        and then A11y.Linux.DBus_Codec.Is_Valid_Bus_Name (Name);
   end Is_Valid_Unique_Name;

   function Transport_From (Name : String) return Transport_Kind is
   begin
      if Name = "unix" then
         return Unix_Transport;
      elsif Name = "tcp" then
         return Tcp_Transport;
      elsif Name = "launchd" then
         return Launchd_Transport;
      else
         return Other_Transport;
      end if;
   end Transport_From;

   function Parse_Address
     (Address : String;
      Result  : out A11y.Results.Result)
      return Bus_Address
   is
      Colon : Natural := 0;
      Fields : Natural := 1;
      Saw_Equals : Boolean := False;
      Last_Was_Separator : Boolean := False;
   begin
      if Address'Length = 0 then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return (State => Address_Unavailable,
                 Transport => Other_Transport,
                 Text => Null_Unbounded_String,
                 Field_Count => 0);
      elsif Address'Length > Max_Address_Length then
         Result := (Status => A11y.Results.Resource_Limit);
         return (State => Address_Invalid,
                 Transport => Other_Transport,
                 Text => Null_Unbounded_String,
                 Field_Count => 0);
      end if;

      for Index in Address'Range loop
         if not Is_Address_Character (Address (Index)) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return (State => Address_Invalid,
                    Transport => Other_Transport,
                    Text => Null_Unbounded_String,
                    Field_Count => 0);
         end if;

         if Address (Index) = ':' and then Colon = 0 then
            Colon := Index;
         end if;
      end loop;

      if Colon = 0 or else Colon = Address'First or else Colon = Address'Last then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (State => Address_Invalid,
                 Transport => Other_Transport,
                 Text => Null_Unbounded_String,
                 Field_Count => 0);
      end if;

      for Index in Address'First .. Colon - 1 loop
         if not Is_Name_Character (Address (Index)) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return (State => Address_Invalid,
                    Transport => Other_Transport,
                    Text => Null_Unbounded_String,
                    Field_Count => 0);
         end if;
      end loop;

      for Index in Colon + 1 .. Address'Last loop
         case Address (Index) is
            when '=' =>
               if Saw_Equals or else Last_Was_Separator then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return (State => Address_Invalid,
                          Transport => Other_Transport,
                          Text => Null_Unbounded_String,
                          Field_Count => 0);
               end if;
               Saw_Equals := True;
               Last_Was_Separator := False;
            when ',' | ';' =>
               if not Saw_Equals or else Last_Was_Separator then
                  Result := (Status => A11y.Results.Invalid_Argument);
                  return (State => Address_Invalid,
                          Transport => Other_Transport,
                          Text => Null_Unbounded_String,
                          Field_Count => 0);
               end if;
               Fields := Fields + 1;
               if Fields > Max_Address_Fields then
                  Result := (Status => A11y.Results.Resource_Limit);
                  return (State => Address_Invalid,
                          Transport => Other_Transport,
                          Text => Null_Unbounded_String,
                          Field_Count => 0);
               end if;
               Saw_Equals := False;
               Last_Was_Separator := True;
            when others =>
               Last_Was_Separator := False;
         end case;
      end loop;

      if not Saw_Equals or else Last_Was_Separator then
         Result := (Status => A11y.Results.Invalid_Argument);
         return (State => Address_Invalid,
                 Transport => Other_Transport,
                 Text => Null_Unbounded_String,
                 Field_Count => 0);
      end if;

      Result := A11y.Results.Ok;
      return
        (State       => Address_Valid,
         Transport   => Transport_From (Address (Address'First .. Colon - 1)),
         Text        => To_Unbounded_String (Address),
         Field_Count => Fields);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (State => Address_Invalid,
                 Transport => Other_Transport,
                 Text => Null_Unbounded_String,
                 Field_Count => 0);
   end Parse_Address;

   procedure Prepare_Connection
     (Context : in out Connection_Context;
      Address : String;
      Result  : out A11y.Results.Result)
   is
      Parsed : Bus_Address;
   begin
      Parsed := Parse_Address (Address, Result);
      if A11y.Results.Failed (Result) then
         Context := Empty_Context;
         if Parsed.State = Address_Invalid then
            Context.State := Failed;
            Context.Address := Parsed;
         end if;
         return;
      end if;

      Context.Address := Parsed;
      Context.Session := A11y.Native_Identity.Create_Session;
      if not A11y.Native_Identity.Is_Valid (Context.Session) then
         Context := Empty_Context;
         Context.State := Failed;
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Context.State := Address_Resolved;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Context := Empty_Context;
         Context.State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
   end Prepare_Connection;

   procedure Register_Application
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      if Context.State = Registered then
         Result := A11y.Results.Ok;
      elsif Context.State = Connected then
         Context.State := Registered;
         Result := A11y.Results.Ok;
      elsif Context.State = Address_Resolved then
         --  Address validation and session creation are ready, but this layer
         --  does not own a live D-Bus socket. The future transport layer must
         --  mark the context connected after hostkit establishes the channel.
         Result := (Status => A11y.Results.Backend_Unavailable);
      else
         Result := (Status => A11y.Results.Invalid_State);
      end if;
   exception
      when others =>
         Context.State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
   end Register_Application;

   function Next_Outgoing_Serial
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result)
      return Natural
   is
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return 0;
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return 0;
      elsif Context.Last_Serial = Natural'Last then
         Result := (Status => A11y.Results.Resource_Limit);
         return 0;
      end if;

      Context.Last_Serial := Context.Last_Serial + 1;
      Result := A11y.Results.Ok;
      return Context.Last_Serial;
   exception
      when others =>
         Context.State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
         return 0;
   end Next_Outgoing_Serial;

   function Pending_Outgoing_Count
     (Context : Connection_Context)
      return Natural is
     (A11y.Linux.DBus_Messages.Queue_Length (Context.Outgoing));

   function Pending_Outgoing_Capacity
     (Context : Connection_Context)
      return Natural is
     (A11y.Linux.DBus_Messages.Queue_Capacity (Context.Outgoing));

   function Pending_Outgoing_Overflowed
     (Context : Connection_Context)
      return Boolean is
     (A11y.Linux.DBus_Messages.Queue_Overflowed (Context.Outgoing));

   function Posting_Interest
     (Context : Connection_Context)
      return A11y.Linux.DBus_Messages.Queue_Posting_Interest is
     (A11y.Linux.DBus_Messages.Posting_Interest (Context.Outgoing));

   function Send_Rejection
     (Posting : A11y.Linux.DBus_Messages.Queue_Posting_Interest)
      return A11y.Results.Status_Code
   is
   begin
      if Posting.Overflowed then
         return A11y.Results.Resource_Limit;
      elsif not Posting.Has_Pending then
         return A11y.Results.Node_Unavailable;
      else
         return A11y.Results.Invalid_State;
      end if;
   end Send_Rejection;

   function In_Flight_Outgoing_Count
     (Context : Connection_Context)
      return Natural is
     (A11y.Linux.DBus_Messages.Tracker_Count (Context.In_Flight));

   function In_Flight_Outgoing_Capacity
     (Context : Connection_Context)
      return Natural is
     (A11y.Linux.DBus_Messages.Tracker_Capacity (Context.In_Flight));

   procedure Configure_Outgoing_Queue
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result) is
   begin
      A11y.Linux.DBus_Messages.Configure_Queue
        (Context.Outgoing, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Configure_Tracker
        (Context.In_Flight, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Configure_Outgoing_Queue;

   procedure Clear_Outgoing_Queue (Context : in out Connection_Context) is
   begin
      A11y.Linux.DBus_Messages.Clear (Context.Outgoing);
   end Clear_Outgoing_Queue;

   procedure Queue_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
   is
   begin
      Queue_Application_Registration
        (Context, Application_Node, A11y.Resource_Limits.Default_Config,
         Result);
   end Queue_Application_Registration;

   procedure Queue_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
   begin
      Message := Build_Application_Registration
        (Context, Application_Node, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Enqueue
        (Context.Outgoing, Message, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Application_Registration;

   procedure Queue_Bus_Hello
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      Queue_Bus_Hello
        (Context, A11y.Resource_Limits.Default_Config, Result);
   end Queue_Bus_Hello;

   procedure Queue_Bus_Hello
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Probe_Result : A11y.Results.Result;
      Serial : Natural;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Method_Call
        (To_Unbounded_String ("/org/freedesktop/DBus"),
         To_Unbounded_String ("org.freedesktop.DBus"),
         To_Unbounded_String ("Hello"),
         1,
         Limits,
         Probe_Result);
      if A11y.Results.Failed (Probe_Result) then
         Result := Probe_Result;
         return;
      end if;

      Serial := Next_Outgoing_Serial (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Method_Call
        (To_Unbounded_String ("/org/freedesktop/DBus"),
         To_Unbounded_String ("org.freedesktop.DBus"),
         To_Unbounded_String ("Hello"),
         Serial,
         Limits,
         Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Enqueue
        (Context.Outgoing, Message, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Bus_Hello;

   procedure Complete_Bus_Hello
     (Context  : in out Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result)
   is
   begin
      Complete_Bus_Hello
        (Context, Envelope, A11y.Resource_Limits.Default_Config, Result);
   end Complete_Bus_Hello;

   procedure Complete_Bus_Hello
     (Context  : in out Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
   is
      Name : Unbounded_String;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      elsif Envelope.Kind = A11y.Linux.DBus_Messages.Error_Return then
         if Envelope.Reply_Serial = 0
           or else Length (Envelope.Error_Name) = 0
         then
            Result := (Status => A11y.Results.Invalid_Argument);
            return;
         end if;

         Complete_Outgoing (Context, Envelope.Reply_Serial, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Result :=
           (Status =>
              A11y.Linux.ATSPi_Objects.Status_For_Error_Name
                (To_String (Envelope.Error_Name)));
         return;
      elsif Envelope.Kind /= A11y.Linux.DBus_Messages.Method_Return
        or else Envelope.Reply_Serial = 0
        or else To_String (Envelope.Body_Signature) /= "s"
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Complete_Outgoing (Context, Envelope.Reply_Serial, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Name := A11y.Linux.DBus_Messages.Decode_String_Body
        (Envelope.Body_Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif not Is_Valid_Unique_Name (To_String (Name))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Context.Unique_Name := Name;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Bus_Hello;

   procedure Complete_Application_Registration
     (Context  : in out Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result)
   is
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      elsif Length (Context.Unique_Name) = 0 then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      elsif Envelope.Kind = A11y.Linux.DBus_Messages.Error_Return then
         if Envelope.Reply_Serial = 0
           or else Length (Envelope.Error_Name) = 0
         then
            Result := (Status => A11y.Results.Invalid_Argument);
            return;
         end if;

         Complete_Outgoing (Context, Envelope.Reply_Serial, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Result :=
           (Status =>
              A11y.Linux.ATSPi_Objects.Status_For_Error_Name
                (To_String (Envelope.Error_Name)));
         return;
      elsif Envelope.Kind /= A11y.Linux.DBus_Messages.Method_Return
        or else Envelope.Reply_Serial = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Complete_Outgoing (Context, Envelope.Reply_Serial, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif Length (Envelope.Body_Signature) = 0 then
         if Length (Envelope.Body_Bytes) /= 0 then
            Result := (Status => A11y.Results.Invalid_Argument);
            return;
         end if;
      elsif To_String (Envelope.Body_Signature) /= "(so)"
         or else Length (Envelope.Body_Bytes) = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif Length (Envelope.Body_String_Argument) = 0
        or else Length (Envelope.Body_Object_Path_Argument) = 0
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Bus_Name
        (To_String (Envelope.Body_String_Argument))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif not A11y.Linux.DBus_Codec.Is_Valid_Object_Path
        (To_String (Envelope.Body_Object_Path_Argument))
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      Context.State := Registered;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Application_Registration;

   procedure Queue_Method_Reply
     (Context  : in out Connection_Context;
      Original : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Result   : out A11y.Results.Result)
   is
   begin
      Queue_Method_Reply
        (Context, Original, Reply, A11y.Resource_Limits.Default_Config,
         Result);
   end Queue_Method_Reply;

   procedure Queue_Method_Reply
     (Context  : in out Connection_Context;
      Original : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply    : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Probe_Result : A11y.Results.Result;
      Serial : Natural;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Reply
        (Original, Reply, 1, Limits, Probe_Result);
      if A11y.Results.Failed (Probe_Result) then
         Result := Probe_Result;
         return;
      end if;

      Serial := Next_Outgoing_Serial (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Reply
        (Original, Reply, Serial, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Enqueue
        (Context.Outgoing, Message, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Method_Reply;

   function Empty_Classification
     (Status : A11y.Results.Status_Code)
      return Incoming_Packet_Classification is
     ((Status       => Status,
       Kind         => A11y.Linux.DBus_Messages.Error_Return,
       Serial       => 0,
       Reply_Serial => 0,
       Reply_Tracked => False));

   function Classify_Incoming_Packet
     (Context : Connection_Context;
      Bytes   : Unbounded_String;
      Result  : out A11y.Results.Result)
      return Incoming_Packet_Classification
   is
   begin
      return Classify_Incoming_Packet
        (Context, Bytes, A11y.Resource_Limits.Default_Config, Result);
   end Classify_Incoming_Packet;

   function Classify_Incoming_Packet
     (Context : Connection_Context;
      Bytes   : Unbounded_String;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Incoming_Packet_Classification
   is
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return Empty_Classification (Result.Status);
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return Empty_Classification (Result.Status);
      end if;

      Envelope := A11y.Linux.DBus_Messages.Decode_Transport_Envelope
        (Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Empty_Classification (Result.Status);
      end if;

      Result := A11y.Results.Ok;
      return
        (Status       => A11y.Results.Success,
         Kind         => Envelope.Kind,
         Serial       => Envelope.Serial,
         Reply_Serial => Envelope.Reply_Serial,
         Reply_Tracked =>
           A11y.Linux.DBus_Messages.Tracker_Has_Serial
             (Context.In_Flight, Envelope.Reply_Serial));
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Classification (A11y.Results.Internal_Error);
   end Classify_Incoming_Packet;

   procedure Handle_Incoming_Packet
     (Context   : in out Connection_Context;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
   begin
      Handle_Incoming_Packet
        (Context, Bytes, Snapshots, A11y.Resource_Limits.Default_Config,
         Result);
   end Handle_Incoming_Packet;

   procedure Handle_Incoming_Packet
     (Context   : in out Connection_Context;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result)
   is
      Classification : Incoming_Packet_Classification;
      Incoming : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
   begin
      Classification := Classify_Incoming_Packet
        (Context, Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif Classification.Kind /= A11y.Linux.DBus_Messages.Method_Call then
         Result := A11y.Results.Ok;
         return;
      end if;

      Incoming := A11y.Linux.DBus_Messages.Decode_Incoming_Call
        (Context.Session, Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Reply := A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Call
        (Incoming.Call, Snapshots);
      Queue_Method_Reply (Context, Incoming, Reply, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Handle_Incoming_Packet;

   procedure Handle_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
   begin
      Handle_Incoming_Registered_Packet
        (Context, Registry, Bytes, Snapshots,
         A11y.Resource_Limits.Default_Config, Result);
   end Handle_Incoming_Registered_Packet;

   procedure Handle_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Result    : out A11y.Results.Result)
   is
      Classification : Incoming_Packet_Classification;
      Incoming : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
   begin
      Classification := Classify_Incoming_Packet
        (Context, Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      elsif Classification.Kind /= A11y.Linux.DBus_Messages.Method_Call then
         Result := A11y.Results.Ok;
         return;
      end if;

      Incoming := A11y.Linux.DBus_Messages.Decode_Incoming_Call
        (Context.Session, Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Reply := A11y.Linux.ATSPi_DBus_Boundary.Dispatch_Registered_Call
        (Registry, Incoming.Call, Snapshots);
      Queue_Method_Reply (Context, Incoming, Reply, Limits, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Handle_Incoming_Registered_Packet;

   function Empty_Packet
     (Kind : A11y.Linux.DBus_Messages.Message_Kind)
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

   function Empty_Serve_Report
     (Status : A11y.Results.Status_Code)
      return Registered_Packet_Serve_Report is
     ((Packet_Classified    => False,
       Incoming_Kind        => A11y.Linux.DBus_Messages.Error_Return,
       Incoming_Method_Call => False,
       Incoming_Serial      => 0,
       Incoming_Reply_Serial => 0,
       Reply_Queued         => False,
       Reply_Serialized     => False,
       Reply_Kind           => A11y.Linux.DBus_Messages.Error_Return,
       Reply_Serial         => 0,
       Reply_Reply_Serial   => 0,
       Reply_Estimated_Bytes => 0,
       Reply_In_Flight      => False,
       Registry_Drained     => False,
       Boundary_Resolved    => False,
       Boundary_Admitted    => False,
       Boundary_Completed   => False,
       Boundary_Status      => Status,
       Native_Call_Begin_Outstanding_Before => 0,
       Native_Call_Begin_Outstanding_After  => 0,
       Native_Call_End_Outstanding_Before   => 0,
       Native_Call_End_Outstanding_After    => 0,
       Status               => Status));

   procedure Serve_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result)
   is
   begin
      Serve_Incoming_Registered_Packet
        (Context, Registry, Bytes, Snapshots,
         A11y.Resource_Limits.Default_Config, Packet, Report, Result);
   end Serve_Incoming_Registered_Packet;

   procedure Serve_Incoming_Registered_Packet
     (Context   : in out Connection_Context;
      Registry  : in out A11y.Linux.ATSPi_Object_Registry.Object_Registry;
      Bytes     : Unbounded_String;
      Snapshots : A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config;
      Packet    : out A11y.Linux.DBus_Messages.Transport_Packet;
      Report    : out Registered_Packet_Serve_Report;
      Result    : out A11y.Results.Result)
   is
      Classification : Incoming_Packet_Classification;
      Incoming : A11y.Linux.DBus_Messages.Incoming_Call;
      Reply : A11y.Linux.ATSPi_DBus_Boundary.DBus_Method_Reply;
      Boundary_Report :
        A11y.Linux.ATSPi_DBus_Boundary.Registered_Call_Boundary_Report;
      Registry_Before :
        A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;
      Registry_After :
        A11y.Linux.ATSPi_Object_Registry.Registry_Snapshot;
   begin
      Packet := Empty_Packet (A11y.Linux.DBus_Messages.Error_Return);
      Report := Empty_Serve_Report (A11y.Results.Success);

      Classification := Classify_Incoming_Packet
        (Context, Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;

      Report.Packet_Classified := True;
      Report.Incoming_Kind := Classification.Kind;
      Report.Incoming_Method_Call :=
        Classification.Kind = A11y.Linux.DBus_Messages.Method_Call;
      Report.Incoming_Serial := Classification.Serial;
      Report.Incoming_Reply_Serial := Classification.Reply_Serial;

      if not Report.Incoming_Method_Call then
         Result := A11y.Results.Ok;
         Report.Status := A11y.Results.Success;
         return;
      end if;

      Incoming := A11y.Linux.DBus_Messages.Decode_Incoming_Call
        (Context.Session, Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;

      Registry_Before := A11y.Linux.ATSPi_Object_Registry.Snapshot
        (Registry);
      Reply := A11y.Linux.ATSPi_DBus_Boundary
        .Dispatch_Registered_Call_With_Report
          (Registry, Incoming.Call, Snapshots, Boundary_Report);
      Registry_After := A11y.Linux.ATSPi_Object_Registry.Snapshot
        (Registry);
      Report.Boundary_Resolved := Boundary_Report.Resolved;
      Report.Boundary_Admitted := Boundary_Report.Native_Admitted;
      Report.Boundary_Completed := Boundary_Report.Native_Completed;
      Report.Boundary_Status := Boundary_Report.Final_Status;
      Report.Native_Call_Begin_Outstanding_Before :=
        Boundary_Report.Begin_Report.Outstanding_Before;
      Report.Native_Call_Begin_Outstanding_After :=
        Boundary_Report.Begin_Report.Outstanding_After;
      Report.Native_Call_End_Outstanding_Before :=
        Boundary_Report.End_Report.Outstanding_Before;
      Report.Native_Call_End_Outstanding_After :=
        Boundary_Report.End_Report.Outstanding_After;
      Report.Registry_Drained :=
        (if Boundary_Report.Native_Admitted then
           Boundary_Report.Native_Completed
           and then Boundary_Report.End_Report.Outstanding_After = 0
         else
           Registry_Before.Outstanding_Calls = 0
           and then Registry_After.Outstanding_Calls = 0);

      Queue_Method_Reply (Context, Incoming, Reply, Limits, Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;
      Report.Reply_Queued := True;

      Send_Next_Transport_Packet (Context, Limits, Packet, Result);
      if A11y.Results.Failed (Result) then
         Report.Status := Result.Status;
         return;
      end if;

      Report.Reply_Serialized := True;
      Report.Reply_Kind := Packet.Metadata.Kind;
      Report.Reply_Serial := Packet.Metadata.Serial;
      Report.Reply_Reply_Serial := Packet.Metadata.Reply_Serial;
      Report.Reply_Estimated_Bytes := Packet.Metadata.Estimated_Bytes;
      Report.Reply_In_Flight :=
        A11y.Linux.DBus_Messages.Tracker_Has_Serial
          (Context.In_Flight, Packet.Metadata.Serial);
      Report.Status := A11y.Results.Success;
   exception
      when others =>
         Packet := Empty_Packet (A11y.Linux.DBus_Messages.Error_Return);
         Report := Empty_Serve_Report (A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Serve_Incoming_Registered_Packet;

   procedure Queue_Signal
     (Context : in out Connection_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Result  : out A11y.Results.Result)
   is
   begin
      Queue_Signal
        (Context, Signal, A11y.Resource_Limits.Default_Config, Result);
   end Queue_Signal;

   procedure Queue_Signal
     (Context : in out Connection_Context;
      Signal  : A11y.Linux.ATSPi_Signals.Signal_Emission;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Probe_Result : A11y.Results.Result;
      Serial : Natural;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Signal
        (Signal, 1, Limits, Probe_Result);
      if A11y.Results.Failed (Probe_Result) then
         Result := Probe_Result;
         return;
      end if;

      Serial := Next_Outgoing_Serial (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Signal
        (Signal, Serial, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Enqueue
        (Context.Outgoing, Message, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Queue_Signal;

   procedure Dequeue_Outgoing
     (Context : in out Connection_Context;
      Message : out A11y.Linux.DBus_Messages.Outgoing_Message;
      Result  : out A11y.Results.Result) is
   begin
      A11y.Linux.DBus_Messages.Dequeue
        (Context.Outgoing, Message, Result);
   exception
      when others =>
         Message :=
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
         Result := (Status => A11y.Results.Internal_Error);
   end Dequeue_Outgoing;

   procedure Send_Next_Outgoing
     (Context : in out Connection_Context;
      Message : out A11y.Linux.DBus_Messages.Outgoing_Message;
      Result  : out A11y.Results.Result)
   is
      Expected : A11y.Linux.DBus_Messages.Outgoing_Message;
      Posting : A11y.Linux.DBus_Messages.Queue_Posting_Interest;
   begin
      if Context.State not in Connected | Registered then
         Message :=
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Backend_Unavailable,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      Posting := Posting_Interest (Context);
      if not Posting.Can_Send then
         Message :=
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Send_Rejection (Posting),
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
         Result := (Status => Send_Rejection (Posting));
         return;
      end if;

      A11y.Linux.DBus_Messages.Peek
        (Context.Outgoing, Message, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;
      Expected := Message;

      declare
         Envelope : constant A11y.Linux.DBus_Messages.Transport_Envelope :=
           A11y.Linux.DBus_Messages.Build_Transport_Envelope
             (Message, Result);
      begin
         pragma Unreferenced (Envelope);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end;

      A11y.Linux.DBus_Messages.Mark_Sent
        (Context.In_Flight, Message, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Dequeue
        (Context.Outgoing, Message, Result);
      if A11y.Results.Failed (Result) then
         declare
            Failure_Status : constant A11y.Results.Status_Code := Result.Status;
            Cleanup        : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Expected.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
            Message := Expected;
            Result := (Status => Failure_Status);
         end;
      elsif Message.Serial /= Expected.Serial then
         declare
            Cleanup : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Expected.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
            Message := Expected;
            Result := (Status => A11y.Results.Invalid_State);
         end;
      end if;
   exception
      when others =>
         Message :=
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
         Result := (Status => A11y.Results.Internal_Error);
   end Send_Next_Outgoing;

   procedure Send_Next_Transport_Envelope
     (Context  : in out Connection_Context;
      Envelope : out A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Dequeued : A11y.Linux.DBus_Messages.Outgoing_Message;
      Posting : A11y.Linux.DBus_Messages.Queue_Posting_Interest;
   begin
      if Context.State not in Connected | Registered then
         Envelope :=
           (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
            Serial                    => 0,
            Reply_Serial              => 0,
            Status                    => A11y.Results.Backend_Unavailable,
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
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      end if;

      Posting := Posting_Interest (Context);
      if not Posting.Can_Send then
         Envelope :=
           (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
            Serial                    => 0,
            Reply_Serial              => 0,
            Status                    => Send_Rejection (Posting),
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
         Result := (Status => Send_Rejection (Posting));
         return;
      end if;

      A11y.Linux.DBus_Messages.Peek
        (Context.Outgoing, Message, Result);
      if A11y.Results.Failed (Result) then
         Envelope :=
           (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
            Serial                    => 0,
            Reply_Serial              => 0,
            Status                    => Result.Status,
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
         return;
      end if;

      Envelope := A11y.Linux.DBus_Messages.Build_Transport_Envelope
        (Message, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Mark_Sent
        (Context.In_Flight, Message, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Linux.DBus_Messages.Dequeue
        (Context.Outgoing, Dequeued, Result);
      if A11y.Results.Failed (Result) then
         declare
            Failure_Status : constant A11y.Results.Status_Code := Result.Status;
            Cleanup        : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Message.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
            Result := (Status => Failure_Status);
         end;
         Envelope :=
           (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
            Serial                    => 0,
            Reply_Serial              => 0,
            Status                    => Result.Status,
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
      elsif Dequeued.Serial /= Message.Serial then
         declare
            Cleanup : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Message.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
         end;
         Envelope :=
           (Kind                      => A11y.Linux.DBus_Messages.Error_Return,
            Serial                    => 0,
            Reply_Serial              => 0,
            Status                    => A11y.Results.Invalid_State,
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
         Result := (Status => A11y.Results.Invalid_State);
      end if;
   exception
      when others =>
         Envelope :=
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
         Result := (Status => A11y.Results.Internal_Error);
   end Send_Next_Transport_Envelope;

   procedure Send_Next_Transport_Frame
     (Context : in out Connection_Context;
      Frame   : out A11y.Linux.DBus_Messages.Transport_Frame;
      Result  : out A11y.Results.Result)
   is
   begin
      Send_Next_Transport_Frame
        (Context, A11y.Resource_Limits.Default_Config, Frame, Result);
   end Send_Next_Transport_Frame;

   procedure Send_Next_Transport_Frame
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Frame   : out A11y.Linux.DBus_Messages.Transport_Frame;
      Result  : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Dequeued : A11y.Linux.DBus_Messages.Outgoing_Message;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Posting : A11y.Linux.DBus_Messages.Queue_Posting_Interest;

      procedure Set_Error_Frame (Status : A11y.Results.Status_Code) is
      begin
         Frame :=
           (Metadata     =>
              (Kind               => A11y.Linux.DBus_Messages.Error_Return,
               Serial             => 0,
               Reply_Serial       => 0,
               Header_Field_Count => 0,
               Body_Field_Count   => 0,
               Header_Text_Bytes  => 0,
               Body_Text_Bytes    => 0,
               Estimated_Bytes    => 0),
            Header_Bytes => Null_Unbounded_String,
            Body_Bytes   => Null_Unbounded_String);
         Result := (Status => Status);
      end Set_Error_Frame;
   begin
      if Context.State not in Connected | Registered then
         Set_Error_Frame (A11y.Results.Backend_Unavailable);
         return;
      end if;

      Posting := Posting_Interest (Context);
      if not Posting.Can_Send then
         Set_Error_Frame (Send_Rejection (Posting));
         return;
      end if;

      A11y.Linux.DBus_Messages.Peek
        (Context.Outgoing, Message, Result);
      if A11y.Results.Failed (Result) then
         Set_Error_Frame (Result.Status);
         return;
      end if;

      Envelope := A11y.Linux.DBus_Messages.Build_Transport_Envelope
        (Message, Limits, Result);
      if A11y.Results.Failed (Result) then
         Set_Error_Frame (Result.Status);
         return;
      end if;

      Frame := A11y.Linux.DBus_Messages.Build_Transport_Frame
        (Envelope, Limits, Result);
      if A11y.Results.Failed (Result) then
         Set_Error_Frame (Result.Status);
         return;
      end if;

      A11y.Linux.DBus_Messages.Mark_Sent
        (Context.In_Flight, Message, Result);
      if A11y.Results.Failed (Result) then
         Set_Error_Frame (Result.Status);
         return;
      end if;

      A11y.Linux.DBus_Messages.Dequeue
        (Context.Outgoing, Dequeued, Result);
      if A11y.Results.Failed (Result) then
         declare
            Failure_Status : constant A11y.Results.Status_Code := Result.Status;
            Cleanup        : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Message.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
            Set_Error_Frame (Failure_Status);
         end;
      elsif Dequeued.Serial /= Message.Serial then
         declare
            Cleanup : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Message.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
         end;
         Set_Error_Frame (A11y.Results.Invalid_State);
      end if;
   exception
      when others =>
         Set_Error_Frame (A11y.Results.Internal_Error);
   end Send_Next_Transport_Frame;

   procedure Send_Next_Transport_Packet
     (Context : in out Connection_Context;
      Packet  : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result  : out A11y.Results.Result)
   is
   begin
      Send_Next_Transport_Packet
        (Context, A11y.Resource_Limits.Default_Config, Packet, Result);
   end Send_Next_Transport_Packet;

   procedure Send_Next_Transport_Packet
     (Context : in out Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Packet  : out A11y.Linux.DBus_Messages.Transport_Packet;
      Result  : out A11y.Results.Result)
   is
      Frame : A11y.Linux.DBus_Messages.Transport_Frame;
   begin
      Send_Next_Transport_Frame (Context, Limits, Frame, Result);
      if A11y.Results.Failed (Result) then
         Packet :=
           (Metadata =>
              (Kind               => Frame.Metadata.Kind,
               Serial             => 0,
               Reply_Serial       => 0,
               Header_Field_Count => 0,
               Body_Field_Count   => 0,
               Header_Text_Bytes  => 0,
               Body_Text_Bytes    => 0,
               Estimated_Bytes    => 0),
            Bytes => Null_Unbounded_String);
         return;
      end if;

      Packet := A11y.Linux.DBus_Messages.Build_Transport_Packet
        (Frame, Limits, Result);
      if A11y.Results.Failed (Result)
        and then Frame.Metadata.Serial /= 0
      then
         declare
            Failure_Status : constant A11y.Results.Status_Code := Result.Status;
            Cleanup        : A11y.Results.Result;
         begin
            Complete_Outgoing (Context, Frame.Metadata.Serial, Cleanup);
            pragma Unreferenced (Cleanup);
            Result := (Status => Failure_Status);
         end;
      end if;
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
         Result := (Status => A11y.Results.Internal_Error);
   end Send_Next_Transport_Packet;

   procedure Complete_Outgoing
     (Context : in out Connection_Context;
      Serial  : Natural;
      Result  : out A11y.Results.Result)
   is
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
      else
         A11y.Linux.DBus_Messages.Complete_Sent
           (Context.In_Flight, Serial, Result);
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Outgoing;

   procedure Mark_Transport_Connected
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      if Context.State = Connected or else Context.State = Registered then
         Result := A11y.Results.Ok;
      elsif Context.State /= Address_Resolved then
         Result := (Status => A11y.Results.Invalid_State);
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Context.State := Failed;
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Context.State := Connected;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Context.State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
   end Mark_Transport_Connected;

   function Build_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message
   is
   begin
      return Build_Application_Registration
        (Context, Application_Node, A11y.Resource_Limits.Default_Config,
         Result);
   end Build_Application_Registration;

   function Build_Application_Registration
     (Context          : in out Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message
   is
      Path : Unbounded_String;
      Path_Result : A11y.Results.Result;
      Probe_Result : A11y.Results.Result;
      Probe : A11y.Linux.DBus_Messages.Outgoing_Message;
      Serial : Natural;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif not Is_Valid_Unique_Name (To_String (Context.Unique_Name)) then
         Result := (Status => A11y.Results.Invalid_State);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Path := A11y.Linux.ATSPi_Objects.Object_Path
        (Context.Session, Application_Node, Path_Result);
      if A11y.Results.Failed (Path_Result) then
         Result := Path_Result;
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Probe := A11y.Linux.DBus_Messages.Build_Method_Call_Object_Reference
        (Object_Path    => To_Unbounded_String
           ("/org/a11y/atspi/accessible/root"),
         Interface_Name => To_Unbounded_String
           ("org.a11y.atspi.Socket"),
         Member_Name    => To_Unbounded_String ("Embed"),
         Bus_Name       => Context.Unique_Name,
         Reference_Path => Path,
         Serial         => 1,
         Limits         => Limits,
         Result         => Probe_Result);
      if A11y.Results.Failed (Probe_Result) then
         Result := Probe_Result;
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Serial := Next_Outgoing_Serial (Context, Result);
      if A11y.Results.Failed (Result) then
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Probe := A11y.Linux.DBus_Messages.Build_Method_Call_Object_Reference
        (Object_Path    => To_Unbounded_String
           ("/org/a11y/atspi/accessible/root"),
         Interface_Name => To_Unbounded_String
           ("org.a11y.atspi.Socket"),
         Member_Name    => To_Unbounded_String ("Embed"),
         Bus_Name       => Context.Unique_Name,
         Reference_Path => Path,
         Serial         => Serial,
         Limits         => Limits,
         Result         => Result);
      return Probe;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Application_Registration;

   function Build_Application_Registration
     (Context          : Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Serial           : Natural;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message
   is
   begin
      return Build_Application_Registration
        (Context, Application_Node, Serial,
         A11y.Resource_Limits.Default_Config, Result);
   end Build_Application_Registration;

   function Build_Application_Registration
     (Context          : Connection_Context;
      Application_Node : A11y.Node_Ids.Node_Id;
      Serial           : Natural;
      Limits           : A11y.Resource_Limits.Resource_Limit_Config;
      Result           : out A11y.Results.Result)
      return A11y.Linux.DBus_Messages.Outgoing_Message
   is
      Path : Unbounded_String;
      Path_Result : A11y.Results.Result;
   begin
      if Context.State not in Connected | Registered then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif Context.Address.State /= Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      elsif not Is_Valid_Unique_Name (To_String (Context.Unique_Name)) then
         Result := (Status => A11y.Results.Invalid_State);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      Path := A11y.Linux.ATSPi_Objects.Object_Path
        (Context.Session, Application_Node, Path_Result);
      if A11y.Results.Failed (Path_Result) then
         Result := Path_Result;
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => Serial,
            Reply_Serial => 0,
            Status       => Result.Status,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
      end if;

      return A11y.Linux.DBus_Messages.Build_Method_Call_Object_Reference
        (Object_Path    => To_Unbounded_String
           ("/org/a11y/atspi/accessible/root"),
         Interface_Name => To_Unbounded_String
           ("org.a11y.atspi.Socket"),
         Member_Name    => To_Unbounded_String ("Embed"),
         Bus_Name       => Context.Unique_Name,
         Reference_Path => Path,
         Serial         => Serial,
         Limits         => Limits,
         Result         => Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Kind         => A11y.Linux.DBus_Messages.Error_Return,
            Serial       => 0,
            Reply_Serial => 0,
            Status       => A11y.Results.Internal_Error,
            Object_Path  => Null_Unbounded_String,
            Error_Name   => Null_Unbounded_String);
   end Build_Application_Registration;

   procedure Disconnect
     (Context : in out Connection_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      Context := Empty_Context;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Context := Empty_Context;
         Context.State := Failed;
         Result := (Status => A11y.Results.Internal_Error);
   end Disconnect;

end A11y.Linux.ATSPi_Bus;
