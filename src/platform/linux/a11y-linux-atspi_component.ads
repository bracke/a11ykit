with Ada.Strings.Unbounded;

with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;

package A11y.Linux.ATSPi_Component is

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Component_Snapshot is record
      Id             : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root           : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Bounds         : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
      Hit_Test_Node  : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Focus_Request_Supported : Boolean := False;
      Focus_Request_Status :
        A11y.Results.Status_Code := A11y.Results.Unsupported_Action;
      Tree           : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure       : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Limits         : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct        : Boolean := False;
   end record;

   type Reply_Kind is
     (Rectangle_Reply,
      Boolean_Reply,
      Node_Reply,
      Error_Reply);

   type Component_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when Rectangle_Reply =>
            Bounds : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Node_Reply =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Point    : A11y.Geometry.Point;
      Snapshot : Component_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Component_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Point    : A11y.Geometry.Point;
      Snapshot : Component_Snapshot)
      return Component_Reply;

end A11y.Linux.ATSPi_Component;
