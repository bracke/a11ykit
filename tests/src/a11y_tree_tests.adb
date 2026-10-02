with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;
with A11y.Trees.Classification;
with A11y.Trees.Exposure_Views;

with A11ykit_Test_Support;

package body A11y_Tree_Tests is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Test_Semantic_Tree is
      Semantic_Tree : A11y.Trees.Semantic_Tree;
      Root_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (1);
      Window_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (2);
      Group_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (3);
      Button_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (4);
      Result : A11y.Results.Result;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Trees.Set_Root (Semantic_Tree, Root_Id, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Trees.Classification.Is_Addressable (Root_Id)
         and then not A11y.Trees.Classification.Is_Addressable
           (A11y.Node_Ids.No_Node),
         "semantic tree accepts one root");
      A11y.Trees.Set_Root (Semantic_Tree, Window_Id, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "semantic tree rejects a second root");

      A11y.Trees.Attach (Semantic_Tree, Root_Id, Window_Id, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Trees.Classification.Valid_Attachment_Pair
           (Root_Id, Window_Id)
         and then not A11y.Trees.Classification.Valid_Attachment_Pair
           (Window_Id, Window_Id),
         "semantic tree attaches a child");
      A11y.Trees.Attach (Semantic_Tree, Window_Id, Group_Id, Result);
      A11y.Trees.Attach (Semantic_Tree, Group_Id, Button_Id, Result);
      Check
        (A11y.Trees.Parent_Of (Semantic_Tree, Button_Id) = Group_Id,
         "semantic tree keeps stable parent lookup");
      Check
        (A11y.Trees.Child_At (Semantic_Tree, Group_Id, 1) = Button_Id,
         "semantic tree keeps deterministic child order");
      Check
        (A11y.Trees.Child_At (Semantic_Tree, Button_Id, 1)
         = A11y.Node_Ids.No_Node,
         "semantic tree returns no node for leaf child lookup");

      A11y.Trees.Move (Semantic_Tree, Button_Id, Group_Id, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then A11y.Trees.Classification.Can_Move_Node
           (Root_Id, Button_Id, Group_Id),
         "semantic tree rejects cycles during move");
      A11y.Trees.Move (Semantic_Tree, Window_Id, Button_Id, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Trees.Classification.Can_Move_Node
           (Root_Id, Window_Id, Button_Id)
         and then not A11y.Trees.Classification.Can_Move_Node
           (Root_Id, Window_Id, Root_Id)
         and then A11y.Trees.Parent_Of (Semantic_Tree, Button_Id) = Window_Id,
         "semantic tree moves a subtree without changing identity");
      Check
        (A11y.Results.Succeeded (A11y.Trees.Validate (Semantic_Tree)),
         "semantic tree validates ownership invariants");
      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Traversal_Depth, 2, Result);
      Check
        (A11y.Results.Succeeded (Result),
         "semantic tree fixture sets traversal-depth limit");
      Check
        (A11y.Trees.Validate (Semantic_Tree, Limits).Status
         = A11y.Results.Resource_Limit,
         "semantic tree validates traversal depth bounds");
      Limits.Limits (A11y.Resource_Limits.Traversal_Depth) := 0;
      Check
        (A11y.Trees.Validate (Semantic_Tree, Limits).Status
         = A11y.Results.Invalid_Argument,
         "semantic tree rejects invalid traversal-depth configs");

      A11y.Trees.Detach (Semantic_Tree, Window_Id, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then A11y.Trees.Classification.Can_Detach_Node
           (Root_Id, Window_Id)
         and then not A11y.Trees.Classification.Can_Detach_Node
           (Root_Id, Root_Id)
         and then A11y.Trees.Is_Attached (Semantic_Tree, Window_Id),
         "semantic tree rejects non-leaf single-node detachment");

      A11y.Trees.Detach (Semantic_Tree, Button_Id, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Trees.Is_Attached (Semantic_Tree, Button_Id),
         "semantic tree detaches nodes from exposure");
   end Test_Semantic_Tree;

   procedure Test_Exposure_View is
      Semantic_Tree : A11y.Trees.Semantic_Tree;
      Root_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (1);
      Flattened_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (2);
      Button_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (3);
      Hidden_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (4);
      Hidden_Button_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (5);
      Descendants_Only_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (6);
      List_Item_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (7);
      Trailing_Id : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (8);

      function Exposure_Of
        (Node : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy
      is
      begin
         case A11y.Node_Ids.To_Natural (Node) is
            when 2 =>
               return A11y.Nodes.Flatten_Node;
            when 4 =>
               return A11y.Nodes.Hide_Node_And_Subtree;
            when 6 =>
               return A11y.Nodes.Expose_Descendants_Only;
            when others =>
               return A11y.Nodes.Expose_Node;
         end case;
      end Exposure_Of;

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Exposure_Of);

      Children : A11y.Trees.Child_Vectors.Vector;
      Result : A11y.Results.Result;
      Parent : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Trees.Set_Root (Semantic_Tree, Root_Id, Result);
      A11y.Trees.Attach (Semantic_Tree, Root_Id, Flattened_Id, Result);
      A11y.Trees.Attach (Semantic_Tree, Flattened_Id, Button_Id, Result);
      A11y.Trees.Attach (Semantic_Tree, Root_Id, Hidden_Id, Result);
      A11y.Trees.Attach (Semantic_Tree, Hidden_Id, Hidden_Button_Id, Result);
      A11y.Trees.Attach
        (Semantic_Tree, Root_Id, Descendants_Only_Id, Result);
      A11y.Trees.Attach
        (Semantic_Tree, Descendants_Only_Id, List_Item_Id, Result);
      A11y.Trees.Attach (Semantic_Tree, Root_Id, Trailing_Id, Result);

      Exposure_View.Exposed_Children_Of
        (Semantic_Tree, Root_Id, Children, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Natural (Children.Length) = 3
         and then Children (1) = Button_Id
         and then Children (2) = List_Item_Id
         and then Children (3) = Trailing_Id,
         "semantic tree exposure view flattens and hides children centrally");

      Parent := Exposure_View.Exposed_Parent_Of
        (Semantic_Tree, Button_Id, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Parent = Root_Id,
         "semantic tree exposure view skips flattened parents");

      Parent := Exposure_View.Exposed_Parent_Of
        (Semantic_Tree, Hidden_Button_Id, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Parent = A11y.Node_Ids.No_Node
         and then not Exposure_View.Is_Externally_Exposed
           (Semantic_Tree, Hidden_Button_Id)
         and then not Exposure_View.Is_Externally_Exposed
           (Semantic_Tree, Flattened_Id),
         "semantic tree exposure view rejects hidden and flattened nodes");

      A11y.Resource_Limits.Set_Limit
        (Limits, A11y.Resource_Limits.Native_Array_Size, 2, Result);
      Exposure_View.Exposed_Children_Of
        (Semantic_Tree, Root_Id, Limits, Children, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit,
         "semantic tree exposure view enforces materialized child bounds");
   end Test_Exposure_View;

   procedure Run is
   begin
      Test_Semantic_Tree;
      Test_Exposure_View;
   end Run;
end A11y_Tree_Tests;
