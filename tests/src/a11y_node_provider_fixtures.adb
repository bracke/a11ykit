with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

package body A11y_Node_Provider_Fixtures is
   overriding function Id
     (Self : Test_Node_Provider)
      return A11y.Node_Ids.Node_Id is
     (Self.Node);

   overriding function Role
     (Self : Test_Node_Provider)
      return A11y.Roles.Role
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Role;
   end Role;

   overriding function States
     (Self : Test_Node_Provider)
      return A11y.States.State_Set
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_States;
   end States;

   overriding function Parent
     (Self : Test_Node_Provider)
      return A11y.Node_Ids.Node_Id is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Parent_Node;
   end Parent;

   overriding function Child_Count
     (Self : Test_Node_Provider)
      return Natural is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Child_Total;
   end Child_Count;

   overriding function Child_At
     (Self  : Test_Node_Provider;
      Index : Positive)
      return A11y.Node_Ids.Node_Id is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Index = 1 then
         return Self.Child_Node;
      end if;
      return A11y.Node_Ids.No_Node;
   end Child_At;

   overriding function Name
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Name));
   end Name;

   overriding function Description
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Description) = 0 then
         return A11y.Properties.Empty;
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Description));
   end Description;

   overriding function Visible_Title
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      elsif Self.Override_Visible_Title then
         return Self.Visible_Title_Override;
      end if;
      if Length (Self.Node_Visible_Title) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Visible_Title));
   end Visible_Title;

   overriding function Help_Text
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Help_Text) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Help_Text));
   end Help_Text;

   overriding function Placeholder
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Placeholder) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Placeholder));
   end Placeholder;

   overriding function Value_Text
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Value_Text) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Value_Text));
   end Value_Text;

   overriding function Keyboard_Shortcut
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Keyboard_Shortcut) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present
        (To_String (Self.Node_Keyboard_Shortcut));
   end Keyboard_Shortcut;

   overriding function Semantic_Identifier
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Semantic_Identifier) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present
        (To_String (Self.Node_Semantic_Identifier));
   end Semantic_Identifier;

   overriding function Locale
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Locale) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Locale));
   end Locale;

   overriding function Orientation
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Orientation) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Orientation));
   end Orientation;

   overriding function Landmark
     (Self : Test_Node_Provider)
      return A11y.Properties.String_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      if Length (Self.Node_Landmark) = 0 then
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
      return A11y.Properties.Present (To_String (Self.Node_Landmark));
   end Landmark;

   overriding function Protected_Value_Text
     (Self : Test_Node_Provider)
      return A11y.Properties.Boolean_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Protected_Value_Text;
   end Protected_Value_Text;

   overriding function Set_Position
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Set_Position;
   end Set_Position;

   overriding function Set_Size
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Set_Size;
   end Set_Size;

   overriding function Hierarchical_Level
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Hierarchical_Level;
   end Hierarchical_Level;

   overriding function Heading_Level
     (Self : Test_Node_Provider)
      return A11y.Properties.Integer_Property
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Heading_Level;
   end Heading_Level;

   overriding function Bounds
     (Self : Test_Node_Provider)
      return A11y.Geometry.Rectangle
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Bounds;
   end Bounds;

   overriding function Capabilities
     (Self : Test_Node_Provider)
      return A11y.Capabilities.Capability_Set
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Node_Capabilities;
   end Capabilities;

   overriding function Exposure
     (Self : Test_Node_Provider)
      return A11y.Nodes.Exposure_Policy
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return A11y.Nodes.Expose_Node;
   end Exposure;

   overriding function Exposure
     (Self : Exposure_Test_Node)
      return A11y.Nodes.Exposure_Policy
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Policy;
   end Exposure;

   overriding function Current_Metadata
     (Self : Test_Live_Region_Provider)
      return A11y.Live_Regions.Live_Region_Metadata
   is
   begin
      if Self.Raise_On_Query then
         raise Program_Error;
      end if;
      return Self.Metadata;
   end Current_Metadata;
end A11y_Node_Provider_Fixtures;
