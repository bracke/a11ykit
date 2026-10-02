with Ada.Strings.Unbounded;

with A11y.Results;

package A11y.Linux.DBus_Auth is

   type External_User_Id is range 0 .. 4_294_967_295;

   type Auth_Response_Kind is
     (Auth_Ok,
      Auth_Rejected,
      Auth_Error,
      Auth_Data,
      Auth_Unknown);

   type Auth_Response is record
      Kind      : Auth_Response_Kind := Auth_Unknown;
      Challenge : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   function Encode_External_User_Id
     (User_Id : External_User_Id;
      Result  : out A11y.Results.Result)
      return String;

   function Auth_External_Command
     (User_Id : External_User_Id;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Begin_Command return Ada.Strings.Unbounded.Unbounded_String;

   function Decode_Response
     (Line   : String;
      Result : out A11y.Results.Result)
      return Auth_Response;

end A11y.Linux.DBus_Auth;
