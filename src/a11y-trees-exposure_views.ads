with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;

generic
   with function Exposure_Of
     (Node : A11y.Node_Ids.Node_Id)
      return A11y.Nodes.Exposure_Policy;
package A11y.Trees.Exposure_Views is

   procedure Exposed_Children_Of
     (Self     : Semantic_Tree;
      Node     : A11y.Node_Ids.Node_Id;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Children : out Child_Vectors.Vector;
      Result   : out A11y.Results.Result);

   procedure Exposed_Children_Of
     (Self     : Semantic_Tree;
      Node     : A11y.Node_Ids.Node_Id;
      Children : out Child_Vectors.Vector;
      Result   : out A11y.Results.Result);

   function Exposed_Parent_Of
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   function Exposed_Parent_Of
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   function Is_Externally_Exposed
     (Self   : Semantic_Tree;
      Node   : A11y.Node_Ids.Node_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Boolean;

   function Is_Externally_Exposed
     (Self : Semantic_Tree;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean;

end A11y.Trees.Exposure_Views;
