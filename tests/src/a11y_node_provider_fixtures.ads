with Ada.Strings.Unbounded;

with A11y.Capabilities;
with A11y.Geometry;
with A11y.Live_Regions;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Roles;
with A11y.States;

package A11y_Node_Provider_Fixtures is
   type Test_Node_Provider is new A11y.Nodes.Accessible_Node
     and A11y.Properties.Textual_Property_Provider
     and A11y.Properties.Privacy_Property_Provider
     and A11y.Properties.Structural_Property_Provider with record
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Node_Role : A11y.Roles.Role := A11y.Roles.Custom;
      Node_States : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Node_Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Parent_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Child_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Child_Total : Natural := 0;
      Node_Name : Ada.Strings.Unbounded.Unbounded_String;
      Node_Visible_Title : Ada.Strings.Unbounded.Unbounded_String;
      Node_Description : Ada.Strings.Unbounded.Unbounded_String;
      Node_Help_Text : Ada.Strings.Unbounded.Unbounded_String;
      Node_Placeholder : Ada.Strings.Unbounded.Unbounded_String;
      Node_Value_Text : Ada.Strings.Unbounded.Unbounded_String;
      Node_Keyboard_Shortcut : Ada.Strings.Unbounded.Unbounded_String;
      Node_Semantic_Identifier : Ada.Strings.Unbounded.Unbounded_String;
      Node_Locale : Ada.Strings.Unbounded.Unbounded_String;
      Node_Orientation : Ada.Strings.Unbounded.Unbounded_String;
      Node_Landmark : Ada.Strings.Unbounded.Unbounded_String;
      Override_Visible_Title : Boolean := False;
      Visible_Title_Override : A11y.Properties.String_Property;
      Node_Protected_Value_Text : A11y.Properties.Boolean_Property;
      Node_Set_Position : A11y.Properties.Integer_Property;
      Node_Set_Size : A11y.Properties.Integer_Property;
      Node_Hierarchical_Level : A11y.Properties.Integer_Property;
      Node_Heading_Level : A11y.Properties.Integer_Property;
      Node_Bounds : A11y.Geometry.Rectangle :=
        A11y.Geometry.Empty_Rectangle;
      Raise_On_Query : Boolean := False;
   end record;

   overriding function Id
     (Self : Test_Node_Provider)
      return A11y.Node_Ids.Node_Id;

   overriding function Role
     (Self : Test_Node_Provider)
      return A11y.Roles.Role;

   overriding function States
     (Self : Test_Node_Provider)
      return A11y.States.State_Set;

   overriding function Parent
     (Self : Test_Node_Provider)
      return A11y.Node_Ids.Node_Id;

   overriding function Child_Count
     (Self : Test_Node_Provider)
      return Natural;

   overriding function Child_At
     (Self  : Test_Node_Provider;
      Index : Positive)
      return A11y.Node_Ids.Node_Id;

   overriding function Name
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Description
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Visible_Title
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Help_Text
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Placeholder
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Value_Text
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Keyboard_Shortcut
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Semantic_Identifier
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Locale
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Orientation
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Landmark
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property;

   overriding function Protected_Value_Text
     (Self : Test_Node_Provider)
      return A11y.Properties.Boolean_Property;

   overriding function Set_Position
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property;

   overriding function Set_Size
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property;

   overriding function Hierarchical_Level
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property;

   overriding function Heading_Level
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property;

   overriding function Bounds
     (Self : Test_Node_Provider)
      return A11y.Geometry.Rectangle;

   overriding function Capabilities
     (Self : Test_Node_Provider)
      return A11y.Capabilities.Capability_Set;

   overriding function Exposure
     (Self : Test_Node_Provider)
      return A11y.Nodes.Exposure_Policy;

   type Exposure_Test_Node is new Test_Node_Provider with record
      Policy : A11y.Nodes.Exposure_Policy := A11y.Nodes.Expose_Node;
   end record;

   overriding function Exposure
     (Self : Exposure_Test_Node)
      return A11y.Nodes.Exposure_Policy;

   type Test_Live_Region_Provider is
     new A11y.Live_Regions.Live_Region_Provider with record
      Metadata : A11y.Live_Regions.Live_Region_Metadata;
      Raise_On_Query : Boolean := False;
   end record;

   overriding function Current_Metadata
     (Self : Test_Live_Region_Provider)
      return A11y.Live_Regions.Live_Region_Metadata;
end A11y_Node_Provider_Fixtures;
