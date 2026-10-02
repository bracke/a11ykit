with A11y.Relations;
with A11y.Roles;
with A11y.States;

package A11y.Windows_Backend.UIA_Mappings is

   type UIA_Control_Type is
     (Custom,
      Button,
      Check_Box,
      Combo_Box,
      Edit,
      Hyperlink,
      Image,
      List,
      List_Item,
      Menu,
      Menu_Bar,
      Menu_Item,
      Pane,
      Progress_Bar,
      Radio_Button,
      Scroll_Bar,
      Separator,
      Slider,
      Spinner,
      Status_Bar,
      Tab,
      Tab_Item,
      Table,
      Text,
      Tool_Bar,
      Tool_Tip,
      Tree,
      Tree_Item,
      Window);

   type UIA_Property is
     (Is_Enabled,
      Has_Keyboard_Focus,
      Is_Keyboard_Focusable,
      Is_Offscreen,
      Is_Selected,
      Toggle_State,
      Expand_Collapse_State,
      Is_Read_Only,
      Is_Required_For_Form);

   type UIA_Property_Set is array (UIA_Property) of Boolean;

   Empty_UIA_Property_Set : constant UIA_Property_Set := [others => False];

   type UIA_Relation_Property is
     (Unsupported_Relation,
      Labeled_By,
      Controller_For,
      Described_By,
      Flows_To);

   function Map_Role (Role : A11y.Roles.Role) return UIA_Control_Type;
   function Map_States (States : A11y.States.State_Set) return UIA_Property_Set;
   function Map_Relation
     (Kind : A11y.Relations.Relation_Kind)
      return UIA_Relation_Property;

end A11y.Windows_Backend.UIA_Mappings;
