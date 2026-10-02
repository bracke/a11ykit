with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with A11y.Documents;
with A11y.Images;
with A11y.Node_Ids;
with A11y.Roles;
with A11y.Windows;

package A11y_Test_Fixtures is

   type Fixture_Node is record
      Id             : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Role           : A11y.Roles.Role := A11y.Roles.Custom;
      Name           : Ada.Strings.Unbounded.Unbounded_String;
      Protected_Text : Boolean := False;
      Image          : A11y.Images.Image_Metadata;
      Document       : A11y.Documents.Document_Metadata;
      Surface        : A11y.Windows.Surface_Metadata;
   end record;

   package Node_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Fixture_Node);

   type Command_Kind is
     (Move_Focus,
      Activate,
      Toggle,
      Expand,
      Collapse,
      Select_Item,
      Deselect,
      Clear_Selection,
      Show_Menu,
      Dismiss,
      Change_Value,
      Insert_Text,
      Remove_Text,
      Replace_Text,
      Set_Text,
      Move_Caret,
      Change_Property,
      Change_Relation,
      Insert_Node,
      Remove_Node,
      Reorder_Children,
      Open_Window,
      Close_Window,
      Announce,
      Destroy_Node,
      Shutdown);

   type Fixture_Command is record
      Kind   : Command_Kind := Move_Focus;
      Target : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   package Command_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Fixture_Command);

   function Nodes return Node_Vectors.Vector;
   function Script return Command_Vectors.Vector;

   Application_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_001);
   Main_Window_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_002);
   Dialog_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_003);
   Group_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_004);
   Static_Text_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_005);
   Button_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_006);
   Toggle_Button_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_007);
   Check_Box_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_008);
   Radio_Button_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_009);
   Password_Field_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_010);
   Text_Field_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_011);
   Slider_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_012);
   Progress_Bar_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_013);
   Spin_Button_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_014);
   List_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_015);
   Destroyed_List_Item_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_016);
   Tree_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_017);
   Tree_Item_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_018);
   Table_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_019);
   Table_Row_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_020);
   Table_Column_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_021);
   Heading_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_027);
   Document_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_028);
   Paragraph_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_029);
   Table_Cell_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_034);
   Combo_Box_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_035);
   Search_Field_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_036);
   Menu_Bar_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_037);
   Menu_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_038);
   Link_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_039);
   Menu_Item_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_040);
   Tab_List_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_041);
   Modal_Surface_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_032);
   Popup_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_042);
   Tab_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_043);
   Tooltip_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_044);
   Live_Region_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_045);
   Validation_Error_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_046);
   Informative_Image_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_030);
   Decorative_Image_Id : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1_031);

end A11y_Test_Fixtures;
