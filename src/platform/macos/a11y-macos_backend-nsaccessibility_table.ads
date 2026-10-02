with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Tables;
with A11y.Trees;

package A11y.MacOS_Backend.NSAccessibility_Table is

   type Table_Query is
     (Row_Count,
      Column_Count,
      Displayed_Row_Count,
      Displayed_Column_Count,
      Visible_Row_Start,
      Visible_Row_Count,
      Visible_Column_Start,
      Visible_Column_Count,
      Current_Cell,
      Sort_Order,
      Sort_Key,
      Cell_At,
      Row_Span,
      Column_Span);

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Table_Snapshot is record
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
            null;
      end case;
   end record;

   function Query_Table
     (Snapshot : Table_Snapshot;
      Query    : Table_Query;
      Row      : A11y.Tables.Logical_Index := 0;
      Column   : A11y.Tables.Logical_Index := 0)
      return Table_Reply;

   function Query_Table
     (Snapshot : Table_Snapshot;
      Query    : Table_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Row      : A11y.Tables.Logical_Index := 0;
      Column   : A11y.Tables.Logical_Index := 0)
      return Table_Reply;

end A11y.MacOS_Backend.NSAccessibility_Table;
