with Ada.Strings.Unbounded;

with A11y.Documents;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.MacOS_Backend.NSAccessibility_Document is

   type Document_Query is
     (Locale,
      Title,
      Author,
      Subject,
      Version,
      Revision,
      Creation,
      Modification,
      Landmark,
      Role,
      Heading_Level,
      Page_Count,
      Current_Page,
      Is_Landmark);

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Document_Snapshot is record
      Id       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Metadata : A11y.Documents.Document_Metadata;
      Tree     : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Defunct  : Boolean := False;
   end record;

   type Reply_Kind is
     (String_Reply,
      UInt32_Reply,
      Boolean_Reply,
      Error_Reply);

   type Document_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Error_Reply =>
            null;
      end case;
   end record;

   function Document_Role_Name
     (Role : A11y.Documents.Document_Role)
      return String;

   function Query_Document
     (Snapshot : Document_Snapshot;
      Query    : Document_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Document_Reply;

   function Query_Document
     (Snapshot : Document_Snapshot;
      Query    : Document_Query)
      return Document_Reply;

end A11y.MacOS_Backend.NSAccessibility_Document;
