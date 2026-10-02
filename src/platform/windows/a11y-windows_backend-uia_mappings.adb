package body A11y.Windows_Backend.UIA_Mappings is

   function Map_Role (Role : A11y.Roles.Role) return UIA_Control_Type is
     (case Role is
        when A11y.Roles.Application => Pane,
        when A11y.Roles.Window | A11y.Roles.Dialog | A11y.Roles.Alert => Window,
        when A11y.Roles.Button | A11y.Roles.Toggle_Button => Button,
        when A11y.Roles.Check_Box => Check_Box,
        when A11y.Roles.Radio_Button => Radio_Button,
        when A11y.Roles.Combo_Box => Combo_Box,
        when A11y.Roles.Text_Field |
             A11y.Roles.Search_Field |
             A11y.Roles.Password_Field => Edit,
        when A11y.Roles.Link => Hyperlink,
        when A11y.Roles.Image => Image,
        when A11y.Roles.List => List,
        when A11y.Roles.List_Item => List_Item,
        when A11y.Roles.Menu => Menu,
        when A11y.Roles.Menu_Bar => Menu_Bar,
        when A11y.Roles.Menu_Item => Menu_Item,
        when A11y.Roles.Progress_Bar => Progress_Bar,
        when A11y.Roles.Scroll_Bar => Scroll_Bar,
        when A11y.Roles.Separator => Separator,
        when A11y.Roles.Slider => Slider,
        when A11y.Roles.Spin_Button => Spinner,
        when A11y.Roles.Status => Status_Bar,
        when A11y.Roles.Tab_List => Tab,
        when A11y.Roles.Tab => Tab_Item,
        when A11y.Roles.Table => Table,
        when A11y.Roles.Static_Text |
             A11y.Roles.Text |
             A11y.Roles.Heading => Text,
        when A11y.Roles.Tool_Bar => Tool_Bar,
        when A11y.Roles.Tooltip => Tool_Tip,
        when A11y.Roles.Tree => Tree,
        when A11y.Roles.Tree_Item => Tree_Item,
        when A11y.Roles.Group |
             A11y.Roles.Region |
             A11y.Roles.Document |
             A11y.Roles.Canvas => Pane,
        when A11y.Roles.Row |
             A11y.Roles.Column |
             A11y.Roles.Cell |
             A11y.Roles.Custom => Custom);

   function Map_States (States : A11y.States.State_Set) return UIA_Property_Set is
      Result : UIA_Property_Set := Empty_UIA_Property_Set;
   begin
      Result (Is_Enabled) := States (A11y.States.Enabled);
      Result (Has_Keyboard_Focus) := States (A11y.States.Focused);
      Result (Is_Keyboard_Focusable) := States (A11y.States.Focusable);
      Result (Is_Offscreen) := States (A11y.States.Offscreen);
      Result (Is_Selected) := States (A11y.States.Selected);
      Result (Toggle_State) :=
        States (A11y.States.Checked) or else States (A11y.States.Indeterminate);
      Result (Expand_Collapse_State) :=
        States (A11y.States.Expanded) or else States (A11y.States.Expandable);
      Result (Is_Read_Only) := States (A11y.States.Read_Only);
      Result (Is_Required_For_Form) := States (A11y.States.Required);
      return Result;
   end Map_States;

   function Map_Relation
     (Kind : A11y.Relations.Relation_Kind)
      return UIA_Relation_Property is
     (case Kind is
        when A11y.Relations.Labelled_By => Labeled_By,
        when A11y.Relations.Controller_For => Controller_For,
        when A11y.Relations.Described_By => Described_By,
        when A11y.Relations.Flows_To => Flows_To,
        when A11y.Relations.Label_For |
             A11y.Relations.Description_For |
             A11y.Relations.Controlled_By |
             A11y.Relations.Flows_From |
             A11y.Relations.Member_Of |
             A11y.Relations.Details |
             A11y.Relations.Details_For |
             A11y.Relations.Error_Message |
             A11y.Relations.Error_For |
             A11y.Relations.Active_Descendant |
             A11y.Relations.Embedded_By |
             A11y.Relations.Embeds |
             A11y.Relations.Popup_For |
             A11y.Relations.Popup_Controlled_By =>
          Unsupported_Relation);

end A11y.Windows_Backend.UIA_Mappings;
