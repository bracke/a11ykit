with A11ykit.Tree;

with A11y.Capabilities;
with A11y.Geometry;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Roles;
with A11y.Semantic_Snapshots;
with A11y.Sessions;
with A11y.States;

package A11ykit.Compatibility is

   function To_Semantic_Role
     (Role : A11ykit.Role)
      return A11y.Roles.Role;

   function To_Semantic_Bounds
     (Bounds : A11ykit.Rectangle)
      return A11y.Geometry.Rectangle;

   function To_Semantic_States
     (State : A11ykit.State;
      Role  : A11ykit.Role)
      return A11y.States.State_Set;

   function To_Semantic_Capabilities
     (Role : A11ykit.Role)
      return A11y.Capabilities.Capability_Set;

   function Node_Id_For_Index
     (Tree  : A11ykit.Tree.Accessibility_Tree;
      Index : Natural)
      return A11y.Node_Ids.Node_Id;

   function Parent_Id
     (Tree  : A11ykit.Tree.Accessibility_Tree;
      Index : Natural)
      return A11y.Node_Ids.Node_Id;

   function Focused_Node
     (Tree : A11ykit.Tree.Accessibility_Tree)
      return A11y.Node_Ids.Node_Id;

   function Validate_Tree
     (Tree : A11ykit.Tree.Accessibility_Tree)
      return A11y.Results.Result;

   function To_Semantic_Snapshot
     (Tree   : A11ykit.Tree.Accessibility_Tree;
      Result : out A11y.Results.Result)
      return A11y.Semantic_Snapshots.Semantic_Snapshot;

   procedure Populate_Session
     (Tree    : A11ykit.Tree.Accessibility_Tree;
      Session : in out A11y.Sessions.Semantic_Session;
      Result  : out A11y.Results.Result);

end A11ykit.Compatibility;
