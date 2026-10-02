with Ada.Strings.Unbounded;

with A11y.Linux.ATSPi_Objects;
with A11y.Native_Identity;

package body A11y.Linux.ATSPi_Address_Discovery is
   use Ada.Strings.Unbounded;
   use type A11y.Linux.ATSPi_Bus.Address_State;
   use type A11y.Linux.ATSPi_Bus.Connection_State;
   use type A11y.Linux.DBus_Messages.Message_Kind;

   function Empty_Address
     (State : A11y.Linux.ATSPi_Bus.Address_State)
      return A11y.Linux.ATSPi_Bus.Bus_Address is
     (State       => State,
      Transport   => A11y.Linux.ATSPi_Bus.Other_Transport,
      Text        => Null_Unbounded_String,
      Field_Count => 0);

   function Discover_From_Environment_Value
     (Value  : String;
      Result : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Bus.Bus_Address is
   begin
      return A11y.Linux.ATSPi_Bus.Parse_Address (Value, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (State       => A11y.Linux.ATSPi_Bus.Address_Invalid,
            Transport   => A11y.Linux.ATSPi_Bus.Other_Transport,
            Text        => <>,
            Field_Count => 0);
   end Discover_From_Environment_Value;

   procedure Queue_Accessibility_Bus_Address_Request
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Result  : out A11y.Results.Result)
   is
   begin
      Queue_Accessibility_Bus_Address_Request
        (Context, A11y.Resource_Limits.Default_Config, Result);
   end Queue_Accessibility_Bus_Address_Request;

   procedure Queue_Accessibility_Bus_Address_Request
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
   is
      Message : A11y.Linux.DBus_Messages.Outgoing_Message;
      Probe_Result : A11y.Results.Result;
      Serial : Natural;
   begin
      if Context.State not in A11y.Linux.ATSPi_Bus.Connected
        | A11y.Linux.ATSPi_Bus.Registered
      then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return;
      elsif Context.Address.State /= A11y.Linux.ATSPi_Bus.Address_Valid
        or else not A11y.Native_Identity.Is_Valid (Context.Session)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Method_Call
        (To_Unbounded_String ("/org/a11y/bus"),
         To_Unbounded_String ("org.a11y.Bus"),
         To_Unbounded_String ("GetAddress"),
         1,
         Limits,
         Probe_Result);
      if A11y.Results.Failed (Probe_Result) then
         Result := Probe_Result;
         return;
      end if;

      Serial := A11y.Linux.ATSPi_Bus.Next_Outgoing_Serial
        (Context, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Message := A11y.Linux.DBus_Messages.Build_Method_Call
        (To_Unbounded_String ("/org/a11y/bus"),
         To_Unbounded_String ("org.a11y.Bus"),
         To_Unbounded_String ("GetAddress"),
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
   end Queue_Accessibility_Bus_Address_Request;

   function Complete_Accessibility_Bus_Address_Request
     (Context  : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Bus.Bus_Address
   is
   begin
      return Complete_Accessibility_Bus_Address_Request
        (Context, Envelope, A11y.Resource_Limits.Default_Config, Result);
   end Complete_Accessibility_Bus_Address_Request;

   function Complete_Accessibility_Bus_Address_Request
     (Context  : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Bus.Bus_Address
   is
      Address_Text : Unbounded_String;
   begin
      if Context.State not in A11y.Linux.ATSPi_Bus.Connected
        | A11y.Linux.ATSPi_Bus.Registered
      then
         Result := (Status => A11y.Results.Backend_Unavailable);
         return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Unavailable);
      elsif Envelope.Kind = A11y.Linux.DBus_Messages.Error_Return then
         if Envelope.Reply_Serial = 0
           or else Length (Envelope.Error_Name) = 0
         then
            Result := (Status => A11y.Results.Invalid_Argument);
            return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
         end if;

         A11y.Linux.ATSPi_Bus.Complete_Outgoing
           (Context, Envelope.Reply_Serial, Result);
         if A11y.Results.Failed (Result) then
            return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
         end if;

         Result :=
           (Status =>
              A11y.Linux.ATSPi_Objects.Status_For_Error_Name
                (To_String (Envelope.Error_Name)));
         return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
      elsif Envelope.Kind /= A11y.Linux.DBus_Messages.Method_Return
        or else Envelope.Reply_Serial = 0
        or else To_String (Envelope.Body_Signature) /= "s"
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
      end if;

      A11y.Linux.ATSPi_Bus.Complete_Outgoing
        (Context, Envelope.Reply_Serial, Result);
      if A11y.Results.Failed (Result) then
         return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
      end if;

      Address_Text := A11y.Linux.DBus_Messages.Decode_String_Body
        (Envelope.Body_Bytes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
      end if;

      return Discover_From_Environment_Value
        (To_String (Address_Text), Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Empty_Address (A11y.Linux.ATSPi_Bus.Address_Invalid);
   end Complete_Accessibility_Bus_Address_Request;

end A11y.Linux.ATSPi_Address_Discovery;
