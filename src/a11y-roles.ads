package A11y.Roles is
   pragma SPARK_Mode (On);

   type Role is
     (Application,
      Window,
      Dialog,
      Alert,
      Group,
      Region,
      Button,
      Toggle_Button,
      Check_Box,
      Radio_Button,
      Combo_Box,
      List,
      List_Item,
      Tree,
      Tree_Item,
      Table,
      Row,
      Column,
      Cell,
      Tab_List,
      Tab,
      Menu_Bar,
      Menu,
      Menu_Item,
      Tool_Bar,
      Text,
      Static_Text,
      Text_Field,
      Search_Field,
      Password_Field,
      Slider,
      Spin_Button,
      Progress_Bar,
      Scroll_Bar,
      Link,
      Image,
      Heading,
      Separator,
      Status,
      Tooltip,
      Document,
      Canvas,
      Custom);

   type Role_Focus_Behavior is
     (Never_Focusable,
      Focusable_When_Interactive,
      Focusable_When_Text_Entry,
      Focusable_Surface);

   type Role_Selection_Behavior is
     (Not_Selectable,
      Selection_Container,
      Selectable_Item);

   type Stable_Name_Access is access constant String;

   type Role_Metadata is record
      Stable_Name : Stable_Name_Access;
      Text_Entry  : Boolean := False;
      Surface     : Boolean := False;
      Focus       : Role_Focus_Behavior := Never_Focusable;
      Selection   : Role_Selection_Behavior := Not_Selectable;
   end record;

   function Metadata (Item : Role) return Role_Metadata
     with
       Global => null,
       Post =>
         Metadata'Result.Text_Entry =
           (Item in Text_Field | Search_Field | Password_Field)
         and then Metadata'Result.Surface =
           (Item in Application | Window | Dialog | Alert)
         and then Metadata'Result.Focus =
           (case Item is
              when Application | Window | Dialog | Alert =>
                Focusable_Surface,
              when Text_Field | Search_Field | Password_Field =>
                Focusable_When_Text_Entry,
              when
                Button | Toggle_Button | Check_Box | Radio_Button
                | Combo_Box | List | List_Item | Tree | Tree_Item | Table
                | Cell | Tab_List | Tab | Menu_Bar | Menu | Menu_Item
                | Slider | Spin_Button | Scroll_Bar | Link | Document
                | Canvas =>
                Focusable_When_Interactive,
              when
                Group | Region | Row | Column | Tool_Bar | Text
                | Static_Text | Progress_Bar | Image | Heading | Separator
                | Status | Tooltip | Custom =>
                Never_Focusable)
         and then Metadata'Result.Selection =
           (case Item is
              when Combo_Box | List | Tree | Table | Tab_List =>
                Selection_Container,
              when List_Item | Tree_Item | Row | Cell | Tab =>
                Selectable_Item,
              when
                Application | Window | Dialog | Alert | Group | Region
                | Button | Toggle_Button | Check_Box | Radio_Button | Column
                | Menu_Bar | Menu | Menu_Item | Tool_Bar | Text | Static_Text
                | Text_Field | Search_Field | Password_Field | Slider
                | Spin_Button | Progress_Bar | Scroll_Bar | Link | Image
                | Heading | Separator | Status | Tooltip | Document | Canvas
                | Custom =>
                Not_Selectable);
   function Stable_Name (Item : Role) return String;

   function Is_Text_Entry (Item : Role) return Boolean
     with
       Global => null,
       Post =>
         Is_Text_Entry'Result =
           (Item in Text_Field | Search_Field | Password_Field);

   function Is_Surface (Item : Role) return Boolean
     with
       Global => null,
       Post =>
         Is_Surface'Result =
           (Item in Application | Window | Dialog | Alert);

   function Focus_Behavior (Item : Role) return Role_Focus_Behavior
     with
       Global => null,
       Post =>
         Focus_Behavior'Result =
           (case Item is
              when Application | Window | Dialog | Alert =>
                Focusable_Surface,
              when Text_Field | Search_Field | Password_Field =>
                Focusable_When_Text_Entry,
              when
                Button | Toggle_Button | Check_Box | Radio_Button
                | Combo_Box | List | List_Item | Tree | Tree_Item | Table
                | Cell | Tab_List | Tab | Menu_Bar | Menu | Menu_Item
                | Slider | Spin_Button | Scroll_Bar | Link | Document
                | Canvas =>
                Focusable_When_Interactive,
              when
                Group | Region | Row | Column | Tool_Bar | Text
                | Static_Text | Progress_Bar | Image | Heading | Separator
                | Status | Tooltip | Custom =>
                Never_Focusable);

   function Selection_Behavior (Item : Role) return Role_Selection_Behavior
     with
       Global => null,
       Post =>
         Selection_Behavior'Result =
           (case Item is
              when Combo_Box | List | Tree | Table | Tab_List =>
                Selection_Container,
              when List_Item | Tree_Item | Row | Cell | Tab =>
                Selectable_Item,
              when
                Application | Window | Dialog | Alert | Group | Region
                | Button | Toggle_Button | Check_Box | Radio_Button | Column
                | Menu_Bar | Menu | Menu_Item | Tool_Bar | Text | Static_Text
                | Text_Field | Search_Field | Password_Field | Slider
                | Spin_Button | Progress_Bar | Scroll_Bar | Link | Image
                | Heading | Separator | Status | Tooltip | Document | Canvas
                | Custom =>
                Not_Selectable);

   function Is_Selection_Container (Item : Role) return Boolean
     with
       Global => null,
       Post =>
         Is_Selection_Container'Result =
           (Item in Combo_Box | List | Tree | Table | Tab_List);

   function Is_Selectable_Item (Item : Role) return Boolean
     with
       Global => null,
       Post =>
         Is_Selectable_Item'Result =
           (Item in List_Item | Tree_Item | Row | Cell | Tab);

end A11y.Roles;
