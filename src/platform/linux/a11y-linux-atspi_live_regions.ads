with Ada.Strings.Unbounded;

with A11y.Live_Regions;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Live_Regions is

   type Live_Snapshot is record
      Id       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Metadata : A11y.Live_Regions.Live_Region_Metadata;
      Defunct  : Boolean := False;
   end record;

   type Reply_Kind is
     (String_Reply,
      Boolean_Reply,
      Error_Reply);

   type Live_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Live_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Live_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Live_Snapshot)
      return Live_Reply;

end A11y.Linux.ATSPi_Live_Regions;
