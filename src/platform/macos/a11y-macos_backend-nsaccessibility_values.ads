with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;
with A11y.Values;

package A11y.MacOS_Backend.NSAccessibility_Values is

   type Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Value_Query is
     (Value,
      Min_Value,
      Max_Value,
      Increment,
      Is_Read_Only);

   type Value_Snapshot is record
      Id       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Metadata : A11y.Values.Value_Metadata;
      Root     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree     : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Defunct  : Boolean := False;
   end record;

   type Reply_Kind is
     (Float_Reply,
      Boolean_Reply,
      Set_Request_Reply,
      Not_Applicable_Reply,
      Error_Reply);

   type Value_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when Float_Reply =>
            Float_Item : Long_Float := 0.0;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Set_Request_Reply =>
            Requested_Value : A11y.Values.Semantic_Value;
         when Not_Applicable_Reply | Error_Reply =>
            null;
      end case;
   end record;

   function Query_Value
     (Snapshot : Value_Snapshot;
      Query    : Value_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Value_Reply;

   function Query_Value
     (Snapshot : Value_Snapshot;
      Query    : Value_Query)
      return Value_Reply;

   function Request_Value_Set
     (Snapshot        : Value_Snapshot;
      Requested_Value : A11y.Values.Semantic_Value;
      Limits          : A11y.Resource_Limits.Resource_Limit_Config)
      return Value_Reply;

   function Request_Value_Set
     (Snapshot        : Value_Snapshot;
      Requested_Value : A11y.Values.Semantic_Value)
      return Value_Reply;

end A11y.MacOS_Backend.NSAccessibility_Values;
