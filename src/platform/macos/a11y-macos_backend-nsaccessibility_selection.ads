with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Selection;
with A11y.Trees;

package A11y.MacOS_Backend.NSAccessibility_Selection is

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Selection_Query is
     (Selected_Count,
      Selected_Item,
      Is_Item_Selected,
      Is_Selection_Required,
      Allows_Multiple_Selection,
      Current_Item,
      Anchor_Item,
      Selection_Direction);

   type Selection_Request_Kind is
     (Select_Item,
      Deselect_Item,
      Toggle_Item,
      Select_All,
      Clear_Selection);

   type Selection_Snapshot is record
      Selection : A11y.Selection.Selection_Set;
      Item      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Items     : A11y.Selection.Node_Vectors.Vector;
      Root      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree      : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure  : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Limits    : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct   : Boolean := False;
   end record;

   type Reply_Kind is
     (UInt32_Reply,
      Boolean_Reply,
      Node_Reply,
      Direction_Reply,
      Selection_Request_Reply,
      Nil_Reply,
      Error_Reply);

   type Selection_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Direction_Reply =>
            Direction : A11y.Selection.Selection_Direction :=
              A11y.Selection.No_Direction;
         when Node_Reply | Selection_Request_Reply =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Request : Selection_Request_Kind := Select_Item;
         when Nil_Reply | Error_Reply =>
            null;
      end case;
   end record;

   function Query_Selection
     (Snapshot : Selection_Snapshot;
      Query    : Selection_Query;
      Index    : Positive := 1)
      return Selection_Reply;

   function Query_Selection
     (Snapshot : Selection_Snapshot;
      Query    : Selection_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Index    : Positive := 1)
      return Selection_Reply;

   function Request_Selection
     (Snapshot : Selection_Snapshot;
      Request  : Selection_Request_Kind;
      Target   : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply;

   function Request_Selection
     (Snapshot : Selection_Snapshot;
      Request  : Selection_Request_Kind;
      Target   : A11y.Node_Ids.Node_Id)
      return Selection_Reply;

end A11y.MacOS_Backend.NSAccessibility_Selection;
