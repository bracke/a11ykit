with Ada.Strings.Unbounded;

with A11y.Diagnostics;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Objects is

   type ATSPI_Interface is
     (Accessible,
      Application,
      Component,
      Action,
      Selection,
      Value,
      Text,
      Editable_Text,
      Table,
      Table_Cell,
      Document,
      Image,
      Live_Region,
      Surface);

   function Interface_Name (Item : ATSPI_Interface) return String;

   function Error_Name (Status : A11y.Results.Status_Code) return String;

   function Status_For_Error_Name (Name : String)
      return A11y.Results.Status_Code;

   function Diagnostic_For_Error_Name
     (Name   : String;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Diagnostic_For_Error_Name
     (Name   : String;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Object_Path
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result)
      return Ada.Strings.Unbounded.Unbounded_String;

   function Node_From_Object_Path
     (Path    : String;
      Session : A11y.Native_Identity.Backend_Session_Id;
      Result  : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   function Node_From_Object_Path
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Path    : String;
      Result  : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

end A11y.Linux.ATSPi_Objects;
