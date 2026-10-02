with Ada.Strings.Unbounded;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Application is

   type Application_Snapshot is record
      Id             : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Application_Id : Natural := 0;
      Toolkit_Name   : Ada.Strings.Unbounded.Unbounded_String;
      Version        : Ada.Strings.Unbounded.Unbounded_String;
      Locale         : Ada.Strings.Unbounded.Unbounded_String;
      Defunct        : Boolean := False;
   end record;

   type Reply_Kind is
     (String_Reply,
      UInt32_Reply,
      Error_Reply);

   type Application_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Application_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Application_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Application_Snapshot)
      return Application_Reply;

end A11y.Linux.ATSPi_Application;
