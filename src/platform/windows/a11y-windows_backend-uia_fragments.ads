with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Geometry;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.Windows_Backend.UIA_Fragments is

   type Navigate_Direction is
     (Parent,
      First_Child,
      Last_Child,
      Next_Sibling,
      Previous_Sibling);

   type Exposure_Table is array
     (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;
   type Bounds_Table is array
     (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Geometry.Rectangle;

   type Fragment_Snapshot is record
      Session       : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Fragment_Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Tree          : A11y.Trees.Semantic_Tree;
      Exposure      : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Bounds        : Bounds_Table := [others => A11y.Geometry.Empty_Rectangle];
      Node          : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Focused_Node  : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Hit_Test_Point : A11y.Geometry.Point := (X => 0, Y => 0);
      Defunct       : Boolean := False;
   end record;

   type Fragment_Reply (Found : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Found is
         when True =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         when False =>
            null;
      end case;
   end record;

   type Runtime_Id is record
      Session_Component : Natural := 0;
      Root_Component    : Natural := 0;
      Node_Component    : Natural := 0;
   end record;

   type Runtime_Id_Reply (Available : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Available is
         when True =>
            Id : Runtime_Id;
         when False =>
            null;
      end case;
   end record;

   function Navigate
     (Snapshot  : Fragment_Snapshot;
      Direction : Navigate_Direction)
      return Fragment_Reply;

   function Navigate
     (Snapshot  : Fragment_Snapshot;
      Direction : Navigate_Direction;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply;

   function Fragment_Root
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply;

   function Focused_Node
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply;

   function Node_From_Point
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Fragment_Reply;

   function Build_Runtime_Id
     (Snapshot : Fragment_Snapshot)
      return Runtime_Id_Reply;

   function Build_Runtime_Id
     (Snapshot : Fragment_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Runtime_Id_Reply;

end A11y.Windows_Backend.UIA_Fragments;
