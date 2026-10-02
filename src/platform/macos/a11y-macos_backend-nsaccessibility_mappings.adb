package body A11y.MacOS_Backend.NSAccessibility_Mappings is

   function Map_Role (Role : A11y.Roles.Role) return NSAX_Role is
     (case Role is
        when A11y.Roles.Application => Application,
        when A11y.Roles.Window => Window,
        when A11y.Roles.Dialog | A11y.Roles.Alert => Dialog,
        when A11y.Roles.Group | A11y.Roles.Region => Group,
        when A11y.Roles.Button | A11y.Roles.Toggle_Button => Button,
        when A11y.Roles.Check_Box => Check_Box,
        when A11y.Roles.Radio_Button => Radio_Button,
        when A11y.Roles.Combo_Box => Combo_Box,
        when A11y.Roles.List | A11y.Roles.List_Item => List,
        when A11y.Roles.Row => Row,
        when A11y.Roles.Tree | A11y.Roles.Tree_Item => Outline,
        when A11y.Roles.Table => Table,
        when A11y.Roles.Cell | A11y.Roles.Column => Cell,
        when A11y.Roles.Tab_List | A11y.Roles.Tab => Tab_Group,
        when A11y.Roles.Menu_Bar => Menu_Bar,
        when A11y.Roles.Menu => Menu,
        when A11y.Roles.Menu_Item => Menu_Item,
        when A11y.Roles.Tool_Bar => Toolbar,
        when A11y.Roles.Static_Text |
             A11y.Roles.Text => Static_Text,
        when A11y.Roles.Heading => Heading,
        when A11y.Roles.Text_Field | A11y.Roles.Search_Field => Text_Field,
        when A11y.Roles.Password_Field => Secure_Text_Field,
        when A11y.Roles.Slider => Slider,
        when A11y.Roles.Spin_Button => Incrementor,
        when A11y.Roles.Progress_Bar => Progress_Indicator,
        when A11y.Roles.Scroll_Bar => Scroll_Bar,
        when A11y.Roles.Link => Link,
        when A11y.Roles.Image => Image,
        when A11y.Roles.Separator => Splitter,
        when A11y.Roles.Status => Value_Indicator,
        when A11y.Roles.Tooltip => Help_Tag,
        when A11y.Roles.Document | A11y.Roles.Canvas => Document,
        when A11y.Roles.Custom => Unknown);

   function Map_States (States : A11y.States.State_Set) return NSAX_State_Set is
      Result : NSAX_State_Set := Empty_NSAX_State_Set;
   begin
      Result (Enabled) := States (A11y.States.Enabled);
      Result (Focused) := States (A11y.States.Focused);
      Result (Selected) := States (A11y.States.Selected);
      Result (Checked) :=
        States (A11y.States.Checked) or else States (A11y.States.Indeterminate);
      Result (Expanded) := States (A11y.States.Expanded);
      Result (Required) := States (A11y.States.Required);
      Result (Busy) := States (A11y.States.Busy);
      Result (Modal) := States (A11y.States.Modal);
      Result (Visited) := States (A11y.States.Visited);
      return Result;
   end Map_States;

   function Map_Relation
     (Kind : A11y.Relations.Relation_Kind)
      return NSAX_Relation_Attribute is
     (case Kind is
        when A11y.Relations.Labelled_By => Title_UI_Element,
        when A11y.Relations.Label_For => Serves_As_Title_For_UI_Elements,
        when A11y.Relations.Controlled_By |
             A11y.Relations.Controller_For |
             A11y.Relations.Flows_To |
             A11y.Relations.Flows_From |
             A11y.Relations.Popup_For |
             A11y.Relations.Popup_Controlled_By => Linked_UI_Elements,
        when A11y.Relations.Active_Descendant => Active_Descendant,
        when A11y.Relations.Member_Of => Shared_Focus_Elements,
        when A11y.Relations.Details |
             A11y.Relations.Details_For => Details_Elements,
        when A11y.Relations.Error_Message |
             A11y.Relations.Error_For => Error_Message_Elements,
        when A11y.Relations.Described_By |
             A11y.Relations.Description_For |
             A11y.Relations.Embedded_By |
             A11y.Relations.Embeds =>
          Unsupported_Relation);

end A11y.MacOS_Backend.NSAccessibility_Mappings;
