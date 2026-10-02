with Ada.Containers.Vectors;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Trees is
   Max_Attached_Nodes : constant Natural := 65_536;

   package Child_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => A11y.Node_Ids.Node_Id,
      "="          => A11y.Node_Ids."=");

   type Semantic_Tree is private;

   function Is_Addressable
     (Node : A11y.Node_Ids.Node_Id)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Addressable'Result =
          (A11y.Node_Ids.To_Natural (Node) in 1 .. Max_Attached_Nodes);

   function Valid_Attachment_Pair
     (Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id)
      return Boolean
   with
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Move_Node'Result =
          (Valid_Attachment_Pair (New_Parent, Node)
           and then A11y.Node_Ids."/=" (Node, Root_Node));

   function Root (Self : Semantic_Tree) return A11y.Node_Ids.Node_Id;
   function Is_Attached
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean;
   function Parent_Of
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Node_Ids.Node_Id;
   function Child_Count
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Natural;
   function Child_At
     (Self  : Semantic_Tree;
      Node  : A11y.Node_Ids.Node_Id;
      Index : Positive)
      return A11y.Node_Ids.Node_Id;
   function Children_Of
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Child_Vectors.Vector;

   procedure Set_Root
     (Self   : in out Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);
   procedure Attach
     (Self   : in out Semantic_Tree;
      Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);
   procedure Detach
     (Self   : in out Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);
   procedure Detach_Subtree
     (Self   : in out Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result);
   procedure Move
     (Self       : in out Semantic_Tree;
      New_Parent : A11y.Node_Ids.Node_Id;
      Node       : A11y.Node_Ids.Node_Id;
      Result     : out A11y.Results.Result);

   function Validate
     (Self   : Semantic_Tree;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;

   function Validate (Self : Semantic_Tree) return A11y.Results.Result;

private
   type Node_Record is record
      Attached : Boolean := False;
      Parent   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Children : Child_Vectors.Vector;
   end record;

   type Node_Table is array (Positive range 1 .. Max_Attached_Nodes) of Node_Record;

   type Semantic_Tree is record
      Root_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Nodes     : Node_Table;
   end record;

end A11y.Trees;
