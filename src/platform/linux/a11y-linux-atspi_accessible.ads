with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with A11y.Linux.ATSPi_Mappings;
with A11y.Capabilities;
with A11y.Linux.DBus_Codec;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.Semantic_Snapshots;
with A11y.States;
with A11y.Trees;

package A11y.Linux.ATSPi_Accessible is

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Accessible_Snapshot is record
      Id          : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root        : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Parent      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Role        : A11y.Roles.Role := A11y.Roles.Custom;
      Name        : Ada.Strings.Unbounded.Unbounded_String;
      Description : Ada.Strings.Unbounded.Unbounded_String;
      Visible_Title : A11y.Properties.String_Property;
      Help_Text   : A11y.Properties.String_Property;
      Placeholder : A11y.Properties.String_Property;
      Value_Text  : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean := False;
      Keyboard_Shortcut : A11y.Properties.String_Property;
      Semantic_Identifier : A11y.Properties.String_Property;
      Locale : A11y.Properties.String_Property;
      Orientation : A11y.Properties.String_Property;
      Set_Position : A11y.Properties.Integer_Property;
      Set_Size : A11y.Properties.Integer_Property;
      Hierarchical_Level : A11y.Properties.Integer_Property;
      Heading_Level : A11y.Properties.Integer_Property;
      Landmark : A11y.Properties.String_Property;
      States      : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Child_Count : Natural := 0;
      Index_In_Parent : Integer := -1;
      Children    : A11y.Trees.Child_Vectors.Vector;
      Tree        : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Nodes       : A11y.Semantic_Snapshots.Semantic_Snapshot;
      Use_Node_Metadata : Boolean := False;
      Exposure    : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Relations   : A11y.Relations.Relation_Graph;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct     : Boolean := False;
   end record;

   type Relation_Entry is record
      Kind    : A11y.Linux.ATSPi_Mappings.ATSPI_Relation :=
        A11y.Linux.ATSPi_Mappings.Labelled_By;
      Targets : A11y.Relations.Target_Vectors.Vector;
   end record;

   package Relation_Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Relation_Entry);

   type Attribute_Entry is record
      Key   : Ada.Strings.Unbounded.Unbounded_String;
      Value : Ada.Strings.Unbounded.Unbounded_String;
   end record;

   package Attribute_Entry_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => Attribute_Entry);

   type Reply_Kind is
     (Role_Reply,
      State_Set_Reply,
      String_Reply,
      UInt32_Reply,
      Int32_Reply,
      Node_Reply,
      Node_Array_Reply,
      String_Array_Reply,
      Attribute_Set_Reply,
      Relation_Set_Reply,
      Error_Reply);

   type Accessible_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when Role_Reply =>
            Role : A11y.Linux.ATSPi_Mappings.ATSPI_Role :=
              A11y.Linux.ATSPi_Mappings.Invalid;
         when State_Set_Reply =>
            States : A11y.Linux.ATSPi_Mappings.ATSPI_State_Set :=
              A11y.Linux.ATSPi_Mappings.Empty_ATSPI_State_Set;
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when UInt32_Reply =>
            UInt32 : Natural := 0;
         when Int32_Reply =>
            Int32 : Integer := 0;
         when Node_Reply =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         when Node_Array_Reply =>
            Nodes : A11y.Trees.Child_Vectors.Vector;
         when String_Array_Reply =>
            Strings : A11y.Linux.DBus_Codec.String_Vectors.Vector;
         when Attribute_Set_Reply =>
            Attributes : Attribute_Entry_Vectors.Vector;
         when Relation_Set_Reply =>
            Relations : Relation_Entry_Vectors.Vector;
         when Error_Reply =>
            Error_Name : Ada.Strings.Unbounded.Unbounded_String;
      end case;
   end record;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Accessible_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Accessible_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Index    : Natural;
      Snapshot : Accessible_Snapshot)
      return Accessible_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Accessible_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Accessible_Reply;

   function Handle_Method
     (Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Method   : String;
      Snapshot : Accessible_Snapshot)
      return Accessible_Reply;

end A11y.Linux.ATSPi_Accessible;
