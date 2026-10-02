package body A11y.Trees.Classification is
   pragma SPARK_Mode (On);

   function Is_Addressable
     (Node : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Node_Ids.To_Natural (Node) in 1 .. Max_Attached_Nodes);

   function Valid_Attachment_Pair
     (Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id)
      return Boolean is
     (Is_Addressable (Parent)
      and then Is_Addressable (Child)
      and then Parent /= Child);

   function Can_Detach_Node
     (Root_Node : A11y.Node_Ids.Node_Id;
      Node      : A11y.Node_Ids.Node_Id)
      return Boolean is
     (Is_Addressable (Node)
      and then Node /= Root_Node);

   function Can_Move_Node
     (Root_Node   : A11y.Node_Ids.Node_Id;
      New_Parent  : A11y.Node_Ids.Node_Id;
      Node        : A11y.Node_Ids.Node_Id)
      return Boolean is
     (Valid_Attachment_Pair (New_Parent, Node)
      and then Node /= Root_Node);

end A11y.Trees.Classification;
