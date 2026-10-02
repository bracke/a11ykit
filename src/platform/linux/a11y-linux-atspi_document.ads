with Ada.Strings.Unbounded;

with A11y.Documents;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.Linux.ATSPi_Document is

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
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Document_Role_Name
     (Role : A11y.Documents.Document_Role)
      return String;

   function Handle_Method
     (Session   : A11y.Native_Identity.Backend_Session_Id;
      Path      : String;
      Method    : String;
      Attribute : String;
      Snapshot  : Document_Snapshot;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config)
      return Document_Reply;

   function Handle_Method
     (Session   : A11y.Native_Identity.Backend_Session_Id;
      Path      : String;
      Method    : String;
      Attribute : String;
      Snapshot  : Document_Snapshot)
      return Document_Reply;

end A11y.Linux.ATSPi_Document;
