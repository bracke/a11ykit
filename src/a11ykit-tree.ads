with Ada.Containers.Vectors;

--  The accessibility tree a consumer builds and hands to A11ykit.Provider.
--
--  A screen reader needs a *hierarchy* -- window contains toolbar contains
--  button -- but a self-drawn UI naturally produces a *flat* list of drawn
--  regions, each with a rectangle and a role but no parent. Build infers the
--  hierarchy from geometry, which is exactly the structure the flat draw list
--  implies, so the consumer never has to track parentage by hand.
package A11ykit.Tree is

   --  A node addressed by its 1-based position in the tree's vector. Parent is
   --  the index of the containing node, or 0 for the root.
   type Node is record
      Node_Role   : A11ykit.Role := Role_Pane;
      Bounds      : Rectangle;
      Name        : UString;
      Description : UString;
      Node_State  : A11ykit.State;
      Parent      : Natural := 0;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Node);

   package Index_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Positive);

   type Accessibility_Tree is record
      Nodes   : Node_Vectors.Vector;
      Focused : Natural := 0;  --  Index of the focused node, or 0 for none.
   end record;

   --  Build a tree from a flat node list by nesting nodes geometrically: each
   --  node's parent is the tightest other node whose rectangle contains it (the
   --  smallest-area container; ties broken by input order, so there are no
   --  cycles). Input order is preserved, so siblings keep their reading order,
   --  and the outermost node (the window) ends up as the root with Parent 0.
   --  Focused is set to the first node whose state is focused.
   --
   --  @param Flat Drawn regions in reading order, each with bounds and role.
   --  @return The same nodes with Parent filled in, plus the focused index.
   function Build (Flat : Node_Vectors.Vector) return Accessibility_Tree;

   --  The child indices of Parent_Index (0 for the roots) in reading order.
   --
   --  @param Tree The built tree.
   --  @param Parent_Index Parent node index, or 0 for top-level nodes.
   --  @return Child node indices, ascending.
   function Children_Of
     (Tree         : Accessibility_Tree;
      Parent_Index : Natural)
      return Index_Vectors.Vector;

end A11ykit.Tree;
