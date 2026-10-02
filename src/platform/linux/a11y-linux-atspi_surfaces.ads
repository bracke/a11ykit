with Ada.Strings.Unbounded;

with A11y.Linux.ATSPi_Mappings;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Trees;
with A11y.Windows;

package A11y.Linux.ATSPi_Surfaces is

   type Surface_Query is
     (Kind_Name,
      Surface_Role,
      Surface_States,
      Is_Top_Level,
      Is_Modal,
      Is_Visible,
      Is_Active,
      Is_Minimized,
      Is_Maximized,
      Is_Fullscreen,
      Can_Close,
      Can_Resize,
      Can_Move);

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Surface_Snapshot is record
      Id       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Metadata : A11y.Windows.Surface_Metadata;
      Tree     : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Limits   : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct  : Boolean := False;
   end record;

   type Reply_Kind is
     (String_Reply,
      Role_Reply,
      State_Set_Reply,
      Boolean_Reply,
      Error_Reply);

   type Surface_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when Role_Reply =>
            Role : A11y.Linux.ATSPi_Mappings.ATSPI_Role :=
              A11y.Linux.ATSPi_Mappings.Invalid;
         when State_Set_Reply =>
            States : A11y.Linux.ATSPi_Mappings.ATSPI_State_Set :=
              A11y.Linux.ATSPi_Mappings.Empty_ATSPI_State_Set;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Error_Reply =>
            null;
      end case;
   end record;

   function Map_Surface_Role
     (Kind : A11y.Windows.Surface_Kind)
      return A11y.Linux.ATSPi_Mappings.ATSPI_Role;

   function Surface_Kind_Name
     (Kind : A11y.Windows.Surface_Kind)
      return String;

   function Map_Surface_States
     (Metadata : A11y.Windows.Surface_Metadata)
      return A11y.Linux.ATSPi_Mappings.ATSPI_State_Set;

   function Query_Surface
     (Snapshot : Surface_Snapshot;
      Query    : Surface_Query)
      return Surface_Reply;

   function Query_Surface
     (Snapshot : Surface_Snapshot;
      Query    : Surface_Query;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Surface_Reply;

end A11y.Linux.ATSPi_Surfaces;
