with Ada.Strings.Unbounded;

with A11y.Capabilities;
with A11y.MacOS_Backend.NSAccessibility_Mappings;
with A11y.Geometry;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.Semantic_Snapshots;
with A11y.States;
with A11y.Trees;

package A11y.MacOS_Backend.NSAccessibility_Properties is

   type Core_Attribute is
     (Role,
      Title,
      Label,
      Description,
      Help,
      Placeholder,
      Value_Text,
      Keyboard_Shortcut,
      Locale,
      Orientation,
      Position_In_Set,
      Size_Of_Set,
      Hierarchical_Level,
      Heading_Level,
      Landmark,
      Identifier,
      Frame,
      Enabled,
      Focused,
      Selected,
      Required,
      Modal);

   type Core_Attribute_Set is array (Core_Attribute) of Boolean;

   Empty_Core_Attribute_Set : constant Core_Attribute_Set := [others => False];

   type Exposure_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes)
       of A11y.Nodes.Exposure_Policy;

   type Property_Snapshot is record
      Id          : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Root        : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Role        : A11y.Roles.Role := A11y.Roles.Custom;
      States      : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Bounds      : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
      Title       : A11y.Properties.String_Property;
      Label       : A11y.Properties.String_Property;
      Description : A11y.Properties.String_Property;
      Help        : A11y.Properties.String_Property;
      Placeholder : A11y.Properties.String_Property;
      Value_Text  : A11y.Properties.String_Property;
      Protected_Value_Text : Boolean := False;
      Keyboard_Shortcut : A11y.Properties.String_Property;
      Locale     : A11y.Properties.String_Property;
      Orientation : A11y.Properties.String_Property;
      Position_In_Set : A11y.Properties.Integer_Property;
      Size_Of_Set : A11y.Properties.Integer_Property;
      Hierarchical_Level : A11y.Properties.Integer_Property;
      Heading_Level : A11y.Properties.Integer_Property;
      Landmark    : A11y.Properties.String_Property;
      Identifier  : A11y.Properties.String_Property;
      Tree        : A11y.Trees.Semantic_Tree;
      Use_Tree_Projection : Boolean := False;
      Exposure    : Exposure_Table := [others => A11y.Nodes.Expose_Node];
      Nodes       : A11y.Semantic_Snapshots.Semantic_Snapshot;
      Use_Node_Metadata : Boolean := False;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Defunct     : Boolean := False;
   end record;

   type Reply_Kind is
     (Attribute_Set_Reply,
      String_Reply,
      Empty_String_Reply,
      Integer_Reply,
      Boolean_Reply,
      Rectangle_Reply,
      Role_Reply,
      Not_Supported_Reply,
      Error_Reply);

   type Attribute_Reply (Kind : Reply_Kind := Error_Reply) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when Attribute_Set_Reply =>
            Attributes : Core_Attribute_Set := Empty_Core_Attribute_Set;
         when String_Reply =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when Empty_String_Reply | Not_Supported_Reply =>
            null;
         when Integer_Reply =>
            Integer_Item : Integer := 0;
         when Boolean_Reply =>
            Boolean_Item : Boolean := False;
         when Rectangle_Reply =>
            Bounds : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
         when Role_Reply =>
            Role :
              A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Role :=
                A11y.MacOS_Backend.NSAccessibility_Mappings.Unknown;
         when Error_Reply =>
            null;
      end case;
   end record;

   function Query_Attribute
     (Snapshot  : Property_Snapshot;
      Attribute : Core_Attribute)
      return Attribute_Reply;

   function Query_Attribute
     (Snapshot  : Property_Snapshot;
      Attribute : Core_Attribute;
      Limits    : A11y.Resource_Limits.Resource_Limit_Config)
      return Attribute_Reply;

   function Query_Attribute_Names
     (Snapshot : Property_Snapshot)
      return Attribute_Reply;

   function Query_Attribute_Names
     (Snapshot : Property_Snapshot;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config)
      return Attribute_Reply;

   function Neutral_Property (Attribute : Core_Attribute)
      return A11y.Properties.Property_Id;

end A11y.MacOS_Backend.NSAccessibility_Properties;
