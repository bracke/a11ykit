with A11y.Node_Ids;

package A11y.Trees.Classification is
   pragma SPARK_Mode (On);
   use type A11y.Node_Ids.Node_Id;

   function Is_Addressable
     (Node : A11y.Node_Ids.Node_Id)
      return Boolean
   with
      Global => null,
      Post =>
        Is_Addressable'Result =
          (A11y.Node_Ids.To_Natural (Node) in 1 .. Max_Attached_Nodes);

   function Valid_Attachment_Pair
     (Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id)
      return Boolean
   with
      Global => null,
      Post =>
        Valid_Attachment_Pair'Result =
          (Is_Addressable (Parent)
           and then Is_Addressable (Child)
           and then A11y.Node_Ids."/=" (Parent, Child));

   function Can_Detach_Node
     (Root_Node : A11y.Node_Ids.Node_Id;
      Node      : A11y.Node_Ids.Node_Id)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Detach_Node'Result =
          (Is_Addressable (Node)
           and then A11y.Node_Ids."/=" (Node, Root_Node));

   function Can_Move_Node
     (Root_Node   : A11y.Node_Ids.Node_Id;
      New_Parent  : A11y.Node_Ids.Node_Id;
      Node        : A11y.Node_Ids.Node_Id)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Move_Node'Result =
          (Valid_Attachment_Pair (New_Parent, Node)
           and then A11y.Node_Ids."/=" (Node, Root_Node));

end A11y.Trees.Classification;
