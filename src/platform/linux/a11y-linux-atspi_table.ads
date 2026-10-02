with Ada.Strings.Unbounded;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Tables;
with A11y.Trees;

package A11y.Linux.ATSPi_Table is

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Table_Method_Snapshot is record
      Id      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Table   : A11y.Tables.Table_Snapshot;
      Tree    : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Limits   : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct : Boolean := False;
   end record;

   type Reply_Kind is
     (UInt32_Reply,
      Node_Reply,
      Error_Reply);

   type Table_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Node_Reply =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Row      : A11y.Tables.Logical_Index;
      Column   : A11y.Tables.Logical_Index;
      Snapshot : Table_Method_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Table_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Row      : A11y.Tables.Logical_Index;
      Column   : A11y.Tables.Logical_Index;
      Snapshot : Table_Method_Snapshot)
      return Table_Reply;

end A11y.Linux.ATSPi_Table;
