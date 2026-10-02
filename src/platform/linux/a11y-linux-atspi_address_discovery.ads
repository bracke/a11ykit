with A11y.Linux.ATSPi_Bus;
with A11y.Linux.DBus_Messages;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Address_Discovery is

   AT_SPI_Bus_Address_Variable : constant String := "AT_SPI_BUS_ADDRESS";
   DBus_Session_Bus_Address_Variable : constant String :=
     "DBUS_SESSION_BUS_ADDRESS";

   function Discover_From_Environment_Value
     (Value  : String;
      Result : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Bus.Bus_Address;

   procedure Queue_Accessibility_Bus_Address_Request
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Result  : out A11y.Results.Result);

   procedure Queue_Accessibility_Bus_Address_Request
     (Context : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   function Complete_Accessibility_Bus_Address_Request
     (Context  : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Result   : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Bus.Bus_Address;

   function Complete_Accessibility_Bus_Address_Request
     (Context  : in out A11y.Linux.ATSPi_Bus.Connection_Context;
      Envelope : A11y.Linux.DBus_Messages.Transport_Envelope;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Linux.ATSPi_Bus.Bus_Address;

end A11y.Linux.ATSPi_Address_Discovery;
