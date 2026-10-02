package body A11y_Test_Fixtures is
   use Ada.Strings.Unbounded;

   function Make
     (Id             : A11y.Node_Ids.Node_Id;
      Role           : A11y.Roles.Role;
      Name           : String;
      Protected_Text : Boolean := False)
      return Fixture_Node
   is
      Result : Fixture_Node;
   begin
      Result.Id := Id;
      Result.Role := Role;
      Result.Name := To_Unbounded_String (Name);
      Result.Protected_Text := Protected_Text;
      return Result;
   end Make;

   function Nodes return Node_Vectors.Vector is
      Result : Node_Vectors.Vector;
      Image_Node : Fixture_Node;
      Decorative : Fixture_Node;
      Heading : Fixture_Node;
      Document : Fixture_Node;
      Link : Fixture_Node;
      Modal : Fixture_Node;
      Popup : Fixture_Node;
   begin
      Result.Append (Make (Application_Id, A11y.Roles.Application, "Fixture Application"));
      Result.Append (Make (Main_Window_Id, A11y.Roles.Window, "Main Window"));
      Result.Append (Make (Dialog_Id, A11y.Roles.Dialog, "Dialog"));
      Result.Append (Make (Group_Id, A11y.Roles.Group, "Group"));
      Result.Append (Make (Static_Text_Id, A11y.Roles.Static_Text, "Static Text"));
      Result.Append (Make (Button_Id, A11y.Roles.Button, "Button"));
      Result.Append (Make (Toggle_Button_Id, A11y.Roles.Toggle_Button, "Toggle Button"));
      Result.Append (Make (Check_Box_Id, A11y.Roles.Check_Box, "Check Box"));
      Result.Append (Make (Radio_Button_Id, A11y.Roles.Radio_Button, "Radio Button"));
      Result.Append (Make (Password_Field_Id, A11y.Roles.Password_Field, "Password", True));
      Result.Append (Make (Text_Field_Id, A11y.Roles.Text_Field, "Text Field"));
      Result.Append (Make (Slider_Id, A11y.Roles.Slider, "Slider"));
      Result.Append (Make (Progress_Bar_Id, A11y.Roles.Progress_Bar, "Progress"));
      Result.Append (Make (Spin_Button_Id, A11y.Roles.Spin_Button, "Spin Button"));
      Result.Append (Make (List_Id, A11y.Roles.List, "List"));
      Result.Append (Make (Destroyed_List_Item_Id, A11y.Roles.List_Item, "List Item"));
      Result.Append (Make (Tree_Id, A11y.Roles.Tree, "Tree"));
      Result.Append (Make (Tree_Item_Id, A11y.Roles.Tree_Item, "Tree Item"));
      Result.Append (Make (Table_Id, A11y.Roles.Table, "Table"));
      Result.Append (Make (Table_Row_Id, A11y.Roles.Row, "Table Row"));
      Result.Append (Make (Table_Column_Id, A11y.Roles.Column, "Table Column"));
      Result.Append (Make (Table_Cell_Id, A11y.Roles.Cell, "Table Cell"));
      Result.Append (Make (Combo_Box_Id, A11y.Roles.Combo_Box, "Combo Box"));
      Result.Append (Make (Search_Field_Id, A11y.Roles.Search_Field, "Search"));
      Result.Append (Make (Menu_Bar_Id, A11y.Roles.Menu_Bar, "Menu Bar"));
      Result.Append (Make (Menu_Id, A11y.Roles.Menu, "Menu"));
      Result.Append (Make (Menu_Item_Id, A11y.Roles.Menu_Item, "Menu Item"));
      Result.Append (Make (Tab_List_Id, A11y.Roles.Tab_List, "Tabs"));
      Result.Append (Make (Tab_Id, A11y.Roles.Tab, "Tab"));
      Result.Append (Make (Tooltip_Id, A11y.Roles.Tooltip, "Tooltip"));
      Result.Append (Make (Live_Region_Id, A11y.Roles.Status, "Live Region"));
      Result.Append (Make (Validation_Error_Id, A11y.Roles.Alert, "Validation Error"));

      Heading := Make (Heading_Id, A11y.Roles.Heading, "Document Heading");
      Heading.Document.Role := A11y.Documents.Heading;
      Heading.Document.Heading_Level := 1;
      Result.Append (Heading);

      Document := Make (Document_Id, A11y.Roles.Document, "Document");
      Document.Document.Role := A11y.Documents.Document;
      Result.Append (Document);

      Result.Append (Make (Paragraph_Id, A11y.Roles.Text, "Paragraph"));

      Link := Make (Link_Id, A11y.Roles.Link, "Document Link");
      Result.Append (Link);

      Image_Node := Make (Informative_Image_Id, A11y.Roles.Image, "Informative Image");
      Image_Node.Image.Kind := A11y.Images.Informative;
      Image_Node.Image.Alternative_Text := To_Unbounded_String ("Informative image");
      Result.Append (Image_Node);

      Decorative := Make (Decorative_Image_Id, A11y.Roles.Image, "Decorative Image");
      Decorative.Image.Kind := A11y.Images.Decorative;
      Result.Append (Decorative);

      Modal := Make (Modal_Surface_Id, A11y.Roles.Dialog, "Modal Dialog");
      Modal.Surface.Kind := A11y.Windows.Modal_Dialog;
      Modal.Surface.State.Modal := True;
      Result.Append (Modal);

      Popup := Make (Popup_Id, A11y.Roles.Dialog, "Popup");
      Popup.Surface.Kind := A11y.Windows.Popup;
      Popup.Surface.State.Visible := True;
      Result.Append (Popup);

      return Result;
   end Nodes;

   function Script return Command_Vectors.Vector is
      Result : Command_Vectors.Vector;
   begin
      Result.Append
        (Fixture_Command'(Kind => Move_Focus, Target => Button_Id));
      Result.Append
        (Fixture_Command'(Kind => Activate, Target => Button_Id));
      Result.Append
        (Fixture_Command'(Kind => Toggle, Target => Toggle_Button_Id));
      Result.Append
        (Fixture_Command'(Kind => Expand, Target => Tree_Id));
      Result.Append
        (Fixture_Command'(Kind => Collapse, Target => Tree_Id));
      Result.Append
        (Fixture_Command'(Kind => Select_Item, Target => Destroyed_List_Item_Id));
      Result.Append
        (Fixture_Command'(Kind => Deselect, Target => Destroyed_List_Item_Id));
      Result.Append
        (Fixture_Command'(Kind => Clear_Selection, Target => List_Id));
      Result.Append
        (Fixture_Command'(Kind => Show_Menu, Target => Menu_Id));
      Result.Append
        (Fixture_Command'(Kind => Dismiss, Target => Popup_Id));
      Result.Append
        (Fixture_Command'(Kind => Insert_Text, Target => Text_Field_Id));
      Result.Append
        (Fixture_Command'(Kind => Remove_Text, Target => Text_Field_Id));
      Result.Append
        (Fixture_Command'(Kind => Replace_Text, Target => Text_Field_Id));
      Result.Append
        (Fixture_Command'(Kind => Set_Text, Target => Text_Field_Id));
      Result.Append
        (Fixture_Command'(Kind => Move_Caret, Target => Text_Field_Id));
      Result.Append
        (Fixture_Command'(Kind => Change_Value, Target => Slider_Id));
      Result.Append
        (Fixture_Command'(Kind => Change_Property, Target => Button_Id));
      Result.Append
        (Fixture_Command'(Kind => Change_Relation, Target => Password_Field_Id));
      Result.Append
        (Fixture_Command'(Kind => Insert_Node, Target => Destroyed_List_Item_Id));
      Result.Append
        (Fixture_Command'(Kind => Remove_Node, Target => Destroyed_List_Item_Id));
      Result.Append
        (Fixture_Command'(Kind => Reorder_Children, Target => List_Id));
      Result.Append
        (Fixture_Command'(Kind => Open_Window, Target => Modal_Surface_Id));
      Result.Append
        (Fixture_Command'(Kind => Close_Window, Target => Modal_Surface_Id));
      Result.Append
        (Fixture_Command'(Kind => Announce, Target => Live_Region_Id));
      Result.Append
        (Fixture_Command'(Kind => Destroy_Node, Target => Destroyed_List_Item_Id));
      Result.Append
        (Fixture_Command'(Kind => Shutdown, Target => Application_Id));
      return Result;
   end Script;

end A11y_Test_Fixtures;
