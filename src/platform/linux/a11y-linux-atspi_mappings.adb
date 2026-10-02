package body A11y.Linux.ATSPi_Mappings is

   function Map_Role (Role : A11y.Roles.Role) return ATSPI_Role is
     (case Role is
        when A11y.Roles.Application => Application,
        when A11y.Roles.Window => Window,
        when A11y.Roles.Dialog => Dialog,
        when A11y.Roles.Alert => Alert,
        when A11y.Roles.Group => Panel,
        when A11y.Roles.Region => Section,
        when A11y.Roles.Button => Push_Button,
        when A11y.Roles.Toggle_Button => Toggle_Button,
        when A11y.Roles.Check_Box => Check_Box,
        when A11y.Roles.Radio_Button => Radio_Button,
        when A11y.Roles.Combo_Box => Combo_Box,
        when A11y.Roles.List => List,
        when A11y.Roles.List_Item => List_Item,
        when A11y.Roles.Tree => Tree,
        when A11y.Roles.Tree_Item => Tree_Item,
        when A11y.Roles.Table => Table,
        when A11y.Roles.Row => Table_Row,
        when A11y.Roles.Column => Table_Column_Header,
        when A11y.Roles.Cell => Table_Cell,
        when A11y.Roles.Tab_List => Page_Tab_List,
        when A11y.Roles.Tab => Page_Tab,
        when A11y.Roles.Menu_Bar => Menu_Bar,
        when A11y.Roles.Menu => Menu,
        when A11y.Roles.Menu_Item => Menu_Item,
        when A11y.Roles.Tool_Bar => Tool_Bar,
        when A11y.Roles.Text => Text,
        when A11y.Roles.Static_Text => Static,
        when A11y.Roles.Text_Field | A11y.Roles.Search_Field => Text_Entry,
        when A11y.Roles.Password_Field => Password_Text,
        when A11y.Roles.Slider => Slider,
        when A11y.Roles.Spin_Button => Spin_Button,
        when A11y.Roles.Progress_Bar => Progress_Bar,
        when A11y.Roles.Scroll_Bar => Scroll_Bar,
        when A11y.Roles.Link => Link,
        when A11y.Roles.Image => Image,
        when A11y.Roles.Heading => Heading,
        when A11y.Roles.Separator => Separator,
        when A11y.Roles.Status => Status_Bar,
        when A11y.Roles.Tooltip => Tool_Tip,
        when A11y.Roles.Document => Document_Frame,
        when A11y.Roles.Canvas => Canvas,
        when A11y.Roles.Custom => Filler);

   function Map_State (State : A11y.States.State_Flag) return ATSPI_State is
     (case State is
        when A11y.States.Enabled => Enabled,
        when A11y.States.Sensitive => Sensitive,
        when A11y.States.Visible => Visible,
        when A11y.States.Showing => Showing,
        when A11y.States.Focused => Focused,
        when A11y.States.Focusable => Focusable,
        when A11y.States.Selected => Selected,
        when A11y.States.Selectable => Selectable,
        when A11y.States.Checked => Checked,
        when A11y.States.Indeterminate => Indeterminate,
        when A11y.States.Expanded => Expanded,
        when A11y.States.Expandable => Expandable,
        when A11y.States.Pressed => Pressed,
        when A11y.States.Read_Only => Read_Only,
        when A11y.States.Editable => Editable,
        when A11y.States.Required => Required,
        when A11y.States.Invalid => Invalid_Entry,
        when A11y.States.Busy => Busy,
        when A11y.States.Modal => Modal,
        when A11y.States.Multi_Line => Multi_Line,
        when A11y.States.Multi_Selectable => Multi_Selectable,
        when A11y.States.Visited => Visited,
        when A11y.States.Offscreen => Showing,
        when A11y.States.Defunct => Defunct,
        when A11y.States.Active => Active);

   function Map_States (States : A11y.States.State_Set) return ATSPI_State_Set is
      Result : ATSPI_State_Set := Empty_ATSPI_State_Set;
   begin
      for State in A11y.States.State_Flag loop
         if States (State) then
            Result (Map_State (State)) := True;
         end if;
      end loop;
      return Result;
   end Map_States;

   function Map_Relation
     (Kind : A11y.Relations.Relation_Kind)
      return ATSPI_Relation is
     (case Kind is
        when A11y.Relations.Labelled_By => Labelled_By,
        when A11y.Relations.Label_For => Label_For,
        when A11y.Relations.Described_By => Described_By,
        when A11y.Relations.Description_For => Description_For,
        when A11y.Relations.Controlled_By => Controlled_By,
        when A11y.Relations.Controller_For => Controller_For,
        when A11y.Relations.Flows_To => Flows_To,
        when A11y.Relations.Flows_From => Flows_From,
        when A11y.Relations.Member_Of => Member_Of,
        when A11y.Relations.Details => Details,
        when A11y.Relations.Details_For => Details_For,
        when A11y.Relations.Error_Message => Error_Message,
        when A11y.Relations.Error_For => Error_For,
        when A11y.Relations.Active_Descendant => Active_Descendant,
        when A11y.Relations.Embedded_By => Embedded_By,
        when A11y.Relations.Embeds => Embeds,
        when A11y.Relations.Popup_For => Popup_For,
        when A11y.Relations.Popup_Controlled_By => Popup_Controlled_By);

   function Event_Name (Kind : A11y.Events.Event_Kind) return String is
     (case Kind is
        when A11y.Events.Node_Created => "object:children-changed:add",
        when A11y.Events.Node_Destroyed => "object:children-changed:remove",
        when A11y.Events.Node_Attached => "object:children-changed:add",
        when A11y.Events.Node_Detached => "object:children-changed:remove",
        when A11y.Events.Child_Added => "object:children-changed:add",
        when A11y.Events.Child_Removed => "object:children-changed:remove",
        when A11y.Events.Children_Reordered => "object:children-changed:reorder",
        when A11y.Events.Subtree_Rebuilt => "object:children-changed",
        when A11y.Events.Property_Changed => "object:property-change",
        when A11y.Events.State_Changed => "object:state-changed",
        when A11y.Events.Bounds_Changed => "object:bounds-changed",
        when A11y.Events.Focus_Changed => "object:state-changed:focused",
        when A11y.Events.Active_Descendant_Changed => "object:active-descendant-changed",
        when A11y.Events.Selection_Changed => "object:selection-changed",
        when A11y.Events.Current_Item_Changed => "object:property-change:current-item",
        when A11y.Events.Value_Changed => "object:property-change:accessible-value",
        when A11y.Events.Range_Changed => "object:property-change:accessible-value",
        when A11y.Events.Text_Inserted => "object:text-changed:insert",
        when A11y.Events.Text_Removed => "object:text-changed:delete",
        when A11y.Events.Text_Replaced => "object:text-changed",
        when A11y.Events.Caret_Moved => "object:text-caret-moved",
        when A11y.Events.Text_Selection_Changed => "object:text-selection-changed",
        when A11y.Events.Text_Attributes_Changed => "object:attributes-changed",
        when A11y.Events.Row_Inserted => "object:row-inserted",
        when A11y.Events.Row_Removed => "object:row-deleted",
        when A11y.Events.Column_Inserted => "object:column-inserted",
        when A11y.Events.Column_Removed => "object:column-deleted",
        when A11y.Events.Cell_Changed => "object:property-change:accessible-table-cell",
        when A11y.Events.Window_Opened => "window:create",
        when A11y.Events.Window_Closed => "window:destroy",
        when A11y.Events.Window_Activated => "window:activate",
        when A11y.Events.Window_Deactivated => "window:deactivate",
        when A11y.Events.Document_Loaded => "document:load-complete",
        when A11y.Events.Document_Closed => "document:reload",
        when A11y.Events.Announcement_Requested => "object:announcement",
        when A11y.Events.Live_Region_Changed => "object:children-changed",
        when A11y.Events.Relation_Added => "object:property-change:accessible-relation",
        when A11y.Events.Relation_Removed => "object:property-change:accessible-relation",
        when A11y.Events.Relation_Targets_Changed => "object:property-change:accessible-relation");

end A11y.Linux.ATSPi_Mappings;
