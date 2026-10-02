with A11y.Events;
with A11y.Relations;
with A11y.Roles;
with A11y.States;

package A11y.Linux.ATSPi_Mappings is

   type ATSPI_Role is
     (Invalid,
      Application,
      Window,
      Dialog,
      Alert,
      Panel,
      Section,
      Push_Button,
      Toggle_Button,
      Check_Box,
      Radio_Button,
      Combo_Box,
      List,
      List_Item,
      Tree,
      Tree_Item,
      Table,
      Table_Row,
      Table_Column_Header,
      Table_Cell,
      Page_Tab_List,
      Page_Tab,
      Menu_Bar,
      Menu,
      Menu_Item,
      Tool_Bar,
      Text,
      Static,
      Text_Entry,
      Password_Text,
      Slider,
      Spin_Button,
      Progress_Bar,
      Scroll_Bar,
      Link,
      Image,
      Heading,
      Separator,
      Status_Bar,
      Tool_Tip,
      Document_Frame,
      Canvas,
      Filler);

   type ATSPI_State is
     (Enabled,
      Sensitive,
      Visible,
      Showing,
      Focused,
      Focusable,
      Selected,
      Selectable,
      Checked,
      Indeterminate,
      Expanded,
      Expandable,
      Pressed,
      Read_Only,
      Editable,
      Required,
      Invalid_Entry,
      Busy,
      Modal,
      Multi_Line,
      Multi_Selectable,
      Visited,
      Defunct,
      Active);

   type ATSPI_State_Set is array (ATSPI_State) of Boolean;

   Empty_ATSPI_State_Set : constant ATSPI_State_Set := [others => False];

   type ATSPI_Relation is
     (Labelled_By,
      Label_For,
      Described_By,
      Description_For,
      Controlled_By,
      Controller_For,
      Flows_To,
      Flows_From,
      Member_Of,
      Details,
      Details_For,
      Error_Message,
      Error_For,
      Active_Descendant,
      Embedded_By,
      Embeds,
      Popup_For,
      Popup_Controlled_By);

   function Map_Role (Role : A11y.Roles.Role) return ATSPI_Role;
   function Map_State (State : A11y.States.State_Flag) return ATSPI_State;
   function Map_States (States : A11y.States.State_Set) return ATSPI_State_Set;
   function Map_Relation
     (Kind : A11y.Relations.Relation_Kind)
      return ATSPI_Relation;
   function Event_Name (Kind : A11y.Events.Event_Kind) return String;

end A11y.Linux.ATSPi_Mappings;
