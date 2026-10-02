with Ada.Strings.Unbounded;

with A11y.Live_Regions;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Live_Regions is

   type Live_Query is
     (Setting_Name,
      Relevant_Names,
      Is_Atomic,
      Is_Assertive,
      Is_Externally_Announced);

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
            null;
      end case;
   end record;

   function Query_Live_Region
     (Snapshot : Live_Snapshot;
      Query    : Live_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Live_Reply;

   function Query_Live_Region
     (Snapshot : Live_Snapshot;
      Query    : Live_Query)
      return Live_Reply;

end A11y.MacOS_Backend.NSAccessibility_Live_Regions;
