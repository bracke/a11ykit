with Ada.Strings.Unbounded;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Selection;
with A11y.Trees;

package A11y.Linux.ATSPi_Selection is

   type Selection_Request_Kind is
     (Select_Child,
      Deselect_Child,
      Select_All,
      Clear_Selection);

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Selection_Snapshot is record
      Id        : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Children  : A11y.Selection.Node_Vectors.Vector;
      Selection : A11y.Selection.Selection_Set;
      Tree      : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure  : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Limits    : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct   : Boolean := False;
   end record;

   type Reply_Kind is
     (UInt32_Reply,
      Boolean_Reply,
      Node_Reply,
      Direction_Reply,
      Selection_Request_Reply,
      Error_Reply);

   type Selection_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Direction_Reply =>
            Direction : A11y.Selection.Selection_Direction :=
              A11y.Selection.No_Direction;
         when Node_Reply | Selection_Request_Reply =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Request : Selection_Request_Kind := Select_Child;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Child_At
     (Snapshot : Selection_Snapshot;
      Index    : Natural;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   function Child_At
     (Snapshot : Selection_Snapshot;
      Index    : Natural;
      Result   : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

   function Query_Direction
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply;

   function Query_Direction
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Snapshot : Selection_Snapshot)
      return Selection_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Selection_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Selection_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Selection_Snapshot)
      return Selection_Reply;

end A11y.Linux.ATSPi_Selection;
