with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.MacOS_Backend.NSAccessibility_Hierarchy is

   type Exposure_Table is array
     (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;
   type Bounds_Table is array
     (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Geometry.Rectangle;

   type Hierarchy_Snapshot is record
      Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree    : A11y.Trees.Semantic_Tree;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Bounds  : Bounds_Table := [others => A11y.Geometry.Empty_Rectangle];
      Node    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Focused_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Defunct : Boolean := False;
   end record;

   type Node_Reply (Found : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Found is
         when True =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         when False =>
            null;
      end case;
   end record;

   type Children_Reply (Available : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Available is
         when True =>
            Children : A11y.Trees.Child_Vectors.Vector;
         when False =>
            null;
      end case;
   end record;

   type Element_Id is record
      Session_Component : Natural := 0;
      Root_Component    : Natural := 0;
      Node_Component    : Natural := 0;
   end record;

   type Element_Id_Reply (Available : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Available is
         when True =>
            Id : Element_Id;
         when False =>
            null;
      end case;
   end record;

   function Parent
     (Snapshot : Hierarchy_Snapshot)
      return Node_Reply;

   function Parent
     (Snapshot : Hierarchy_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Node_Reply;

   function Children
     (Snapshot : Hierarchy_Snapshot)
      return Children_Reply;

   function Children
     (Snapshot : Hierarchy_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Children_Reply;

   function Child_At
     (Snapshot : Hierarchy_Snapshot;
      Index    : Positive)
      return Node_Reply;

   function Child_At
     (Snapshot : Hierarchy_Snapshot;
      Index    : Positive;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Node_Reply;

   function Build_Element_Id
     (Snapshot : Hierarchy_Snapshot)
      return Element_Id_Reply;

   function Build_Element_Id
     (Snapshot : Hierarchy_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Element_Id_Reply;

   function Hit_Test
     (Snapshot : Hierarchy_Snapshot;
      Point    : A11y.Geometry.Point;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Node_Reply;

   function Focused
     (Snapshot : Hierarchy_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Node_Reply;

end A11y.MacOS_Backend.NSAccessibility_Hierarchy;
