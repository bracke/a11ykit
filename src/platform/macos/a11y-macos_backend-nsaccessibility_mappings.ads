with A11y.Relations;
with A11y.Roles;
with A11y.States;

package A11y.MacOS_Backend.NSAccessibility_Mappings is

   type NSAX_Role is
     (Application,
      Window,
      Dialog,
      Group,
      Button,
      Check_Box,
      Radio_Button,
      Combo_Box,
      List,
      Row,
      Outline,
      Table,
      Cell,
      Tab_Group,
      Menu_Bar,
      Menu,
      Menu_Item,
      Toolbar,
      Static_Text,
      Text_Field,
      Secure_Text_Field,
      Slider,
      Incrementor,
      Progress_Indicator,
      Scroll_Bar,
      Link,
      Image,
      Heading,
      Splitter,
      Value_Indicator,
      Help_Tag,
      Document,
      Unknown);

   type NSAX_State is
     (Enabled,
      Focused,
      Selected,
      Checked,
      Expanded,
      Required,
      Busy,
      Modal,
      Visited);

   type NSAX_State_Set is array (NSAX_State) of Boolean;

   Empty_NSAX_State_Set : constant NSAX_State_Set := [others => False];

   type NSAX_Relation_Attribute is
     (Unsupported_Relation,
      Title_UI_Element,
      Serves_As_Title_For_UI_Elements,
      Linked_UI_Elements,
      Shared_Focus_Elements,
      Details_Elements,
      Error_Message_Elements,
      Active_Descendant);

   function Map_Role (Role : A11y.Roles.Role) return NSAX_Role;
   function Map_States (States : A11y.States.State_Set) return NSAX_State_Set;
   function Map_Relation
     (Kind : A11y.Relations.Relation_Kind)
      return NSAX_Relation_Attribute;

end A11y.MacOS_Backend.NSAccessibility_Mappings;
