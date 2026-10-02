with Ada.Strings.Unbounded;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Roles;
with A11y_Test_Fixtures;

package body A11y_Native_Client_Reports is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Roles.Role;
   use type A11y_Test_Fixtures.Command_Kind;

   function Q (Value : String) return String is
      Result : Unbounded_String;
   begin
      Append (Result, '"');
      for Ch of Value loop
         if Ch = '"' then
            Append (Result, "\""");
         elsif Ch = '\' then
            Append (Result, "\\");
         elsif Character'Pos (Ch) < 32 then
            Append (Result, ' ');
         else
            Append (Result, Ch);
         end if;
      end loop;
      Append (Result, '"');
      return To_String (Result);
   end Q;

   function Platform_Name (Client : Client_Kind) return String is
     (case Client is
        when Linux_ATSPI => "Linux",
        when Windows_UIA => "Windows",
        when MacOS_NSAccessibility => "macOS");

   function Native_API_Name (Client : Client_Kind) return String is
     (case Client is
        when Linux_ATSPI => "AT-SPI2",
        when Windows_UIA => "UI Automation",
        when MacOS_NSAccessibility => "NSAccessibility");

   function Client_Process_Name (Client : Client_Kind) return String is
     (case Client is
        when Linux_ATSPI => "native_client_atspi",
        when Windows_UIA => "native_client_uia",
        when MacOS_NSAccessibility => "native_client_nsax");

   function Status_Name return String is
     ("blocked_transport_unavailable");

   function Status_Name (Client : Client_Kind) return String is
   begin
      case Client is
         when Linux_ATSPI =>
            if Has_Linux_ATSPI_Live_Registered_External_Client_Observation
              and then
                Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
              and then
                Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation
            then
               return "native_conformance_ready";
            end if;

         when Windows_UIA =>
            if Has_Windows_UIA_Internal_Native_Export_Chain_Ready
              and then Has_Windows_UIA_External_Client_Full_Frame_Callback_Observation
              and then Has_Windows_UIA_External_Client_Protected_Value_Observation
            then
               return "native_conformance_ready";
            end if;

         when MacOS_NSAccessibility =>
            null;
      end case;

      return Status_Name;
   end Status_Name;

   Feature_Id_Size : constant Positive := 64;
   Conformance_Id_Size : constant Positive := 64;
   Fixture_Schema : constant String := "org.a11y.fixture_application.v1";
   Linux_Path_Prefix : constant String := "/org/a11y/ada/session/";
   Linux_Path_Node_Sep : constant String := "/node/";

   type Observation_Record is record
      Feature : String (1 .. Feature_Id_Size);
      Conformance_Id : String (1 .. Conformance_Id_Size);
      Node    : A11y.Node_Ids.Node_Id;
      Role    : A11y.Roles.Role;
      Status  : String (1 .. 32);
      Privacy : String (1 .. 32);
      Native_Resolution : String (1 .. 32);
   end record;

   function Pad (Value : String; Size : Positive) return String is
      Result : String (1 .. Size) := [others => ' '];
      Last : constant Natural := Natural'Min (Value'Length, Size);
   begin
      if Last > 0 then
         Result (1 .. Last) := Value (Value'First .. Value'First + Last - 1);
      end if;
      return Result;
   end Pad;

   function Trimmed (Value : String) return String is
      Last : Natural := Value'Last;
   begin
      while Last >= Value'First and then Value (Last) = ' ' loop
         if Last = Value'First then
            return "";
         end if;
         Last := Last - 1;
      end loop;
      return Value (Value'First .. Last);
   end Trimmed;

   Observations : constant array (Positive range <>) of Observation_Record :=
     [(Feature => Pad ("fixture.application", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.application", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Application_Id,
       Role    => A11y.Roles.Application,
       Status  => Pad ("ready", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.main_window", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.window", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Main_Window_Id,
       Role    => A11y.Roles.Window,
       Status  => Pad ("ready", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.dialog", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.dialog", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Dialog_Id,
       Role    => A11y.Roles.Dialog,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.group", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.group", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Group_Id,
       Role    => A11y.Roles.Group,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.static_text", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.static_text", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Static_Text_Id,
       Role    => A11y.Roles.Static_Text,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.button_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.button", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.toggle_button", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.toggle_button", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Toggle_Button_Id,
       Role    => A11y.Roles.Toggle_Button,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.check_box", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.check_box", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Check_Box_Id,
       Role    => A11y.Roles.Check_Box,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.radio_button", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.radio_button", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Radio_Button_Id,
       Role    => A11y.Roles.Radio_Button,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.focus_target", Feature_Id_Size),
       Conformance_Id => Pad ("events.focus.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("focusable", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.property_change", Feature_Id_Size),
       Conformance_Id => Pad ("events.property.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("property_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.orientation_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.property.orientation", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Slider_Id,
       Role    => A11y.Roles.Slider,
       Status  => Pad ("property_event", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.set_position_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.property.set_position", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Destroyed_List_Item_Id,
       Role    => A11y.Roles.List_Item,
       Status  => Pad ("property_event", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.set_size_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.property.set_size", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("property_event", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.hierarchical_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.property.hierarchical_level", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Item_Id,
       Role    => A11y.Roles.Tree_Item,
       Status  => Pad ("property_event", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.role_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.role", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("role_property", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.state_set_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.state_set", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Toggle_Button_Id,
       Role    => A11y.Roles.Toggle_Button,
       Status  => Pad ("state_set_property", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.name_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.name", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("name", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.description_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.description", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("description", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.help_text_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.help_text", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("help_text", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.placeholder_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.placeholder", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Search_Field_Id,
       Role    => A11y.Roles.Search_Field,
       Status  => Pad ("placeholder", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.value_text_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.value_text", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Progress_Bar_Id,
       Role    => A11y.Roles.Progress_Bar,
       Status  => Pad ("value_text", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.keyboard_shortcut", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.keyboard_shortcut", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("keyboard_shortcut", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.semantic_identifier", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.semantic_identifier", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("semantic_identifier", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.locale_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.locale", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Document_Id,
       Role    => A11y.Roles.Document,
       Status  => Pad ("locale", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.visible_title_property", Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.visible_title", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Main_Window_Id,
       Role    => A11y.Roles.Window,
       Status  => Pad ("visible_title", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.orientation_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.orientation", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Slider_Id,
       Role    => A11y.Roles.Slider,
       Status  => Pad ("orientation", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.set_position_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.set_position", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Destroyed_List_Item_Id,
       Role    => A11y.Roles.List_Item,
       Status  => Pad ("set_position", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.set_size_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.set_size", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("set_size", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.hierarchical_level_property", Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.hierarchical_level", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Item_Id,
       Role    => A11y.Roles.Tree_Item,
       Status  => Pad ("hierarchical_level", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.heading_level_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.heading_level", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Heading_Id,
       Role    => A11y.Roles.Heading,
       Status  => Pad ("heading_level", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.landmark_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.landmark", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Document_Id,
       Role    => A11y.Roles.Document,
       Status  => Pad ("landmark", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.bounds_property", Feature_Id_Size),
       Conformance_Id => Pad ("core.property.bounds", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("bounds", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.state_change", Feature_Id_Size),
       Conformance_Id => Pad ("events.state.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Toggle_Button_Id,
       Role    => A11y.Roles.Toggle_Button,
       Status  => Pad ("state_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.bounds", Feature_Id_Size),
       Conformance_Id => Pad ("events.bounds.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("bounds_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.hit_test", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.component_call", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("hit_test", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.tree_change", Feature_Id_Size),
       Conformance_Id => Pad ("events.tree.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("tree_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.window_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.window.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Modal_Surface_Id,
       Role    => A11y.Roles.Dialog,
       Status  => Pad ("window_event", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.activate_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.activate", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("activate_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.default_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.press", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Button_Id,
       Role    => A11y.Roles.Button,
       Status  => Pad ("actionable", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.toggle_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.toggle", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Toggle_Button_Id,
       Role    => A11y.Roles.Toggle_Button,
       Status  => Pad ("toggle_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.expand_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.expand", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Item_Id,
       Role    => A11y.Roles.Tree_Item,
       Status  => Pad ("expand_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.collapse_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.collapse", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Item_Id,
       Role    => A11y.Roles.Tree_Item,
       Status  => Pad ("collapse_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.show_menu_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.show_menu", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Combo_Box_Id,
       Role    => A11y.Roles.Combo_Box,
       Status  => Pad ("show_menu_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.dismiss_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.dismiss", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Popup_Id,
       Role    => A11y.Roles.Dialog,
       Status  => Pad ("dismiss_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.open_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.open", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Link_Id,
       Role    => A11y.Roles.Link,
       Status  => Pad ("open_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.close_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.close", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Modal_Surface_Id,
       Role    => A11y.Roles.Dialog,
       Status  => Pad ("close_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.scroll_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.scroll_into_view", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Item_Id,
       Role    => A11y.Roles.Tree_Item,
       Status  => Pad ("scroll_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.set_focus_action", Feature_Id_Size),
       Conformance_Id => Pad ("actions.set_focus", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("set_focus_action", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.slider_value", Feature_Id_Size),
       Conformance_Id => Pad ("value.range", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Slider_Id,
       Role    => A11y.Roles.Slider,
       Status  => Pad ("range_value", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.progress_bar", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.progress_bar", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Progress_Bar_Id,
       Role    => A11y.Roles.Progress_Bar,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.spin_button", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.spin_button", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Spin_Button_Id,
       Role    => A11y.Roles.Spin_Button,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.list_selection", Feature_Id_Size),
       Conformance_Id => Pad ("selection.single", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("selectable", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.select_all", Feature_Id_Size),
       Conformance_Id => Pad ("selection.select_all", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("select_all", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.selection_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.selection.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("selection_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.active_descendant", Feature_Id_Size),
       Conformance_Id => Pad ("relations.active_descendant", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Id,
       Role    => A11y.Roles.Tree,
       Status  => Pad ("active_descendant", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.active_desc_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.node_reference.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Id,
       Role    => A11y.Roles.Tree,
       Status  => Pad ("active_desc_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.current_item", Feature_Id_Size),
       Conformance_Id => Pad ("selection.current_item", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("current_item", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.current_item_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.node_reference.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("current_item_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.list_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.list", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.List_Id,
       Role    => A11y.Roles.List,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.list_item_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.list_item", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Destroyed_List_Item_Id,
       Role    => A11y.Roles.List_Item,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.tree", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.tree", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Id,
       Role    => A11y.Roles.Tree,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.tree_item", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.tree_item", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tree_Item_Id,
       Role    => A11y.Roles.Tree_Item,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.table", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Id,
       Role    => A11y.Roles.Table,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_row", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.row", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Row_Id,
       Role    => A11y.Roles.Row,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_column", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.column", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Column_Id,
       Role    => A11y.Roles.Column,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.cell_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.cell", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Cell_Id,
       Role    => A11y.Roles.Cell,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.combo_box", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.combo_box", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Combo_Box_Id,
       Role    => A11y.Roles.Combo_Box,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.search_field", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.search_field", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Search_Field_Id,
       Role    => A11y.Roles.Search_Field,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.menu_bar", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.menu_bar", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Menu_Bar_Id,
       Role    => A11y.Roles.Menu_Bar,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.menu", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.menu", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Menu_Id,
       Role    => A11y.Roles.Menu,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.menu_item", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.menu_item", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Menu_Item_Id,
       Role    => A11y.Roles.Menu_Item,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.tab_list", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.tab_list", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tab_List_Id,
       Role    => A11y.Roles.Tab_List,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.tab", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.tab", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tab_Id,
       Role    => A11y.Roles.Tab,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.tooltip", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.tooltip", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Tooltip_Id,
       Role    => A11y.Roles.Tooltip,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.text_range", Feature_Id_Size),
       Conformance_Id => Pad ("text.range.basic", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("text_range", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.text_insert", Feature_Id_Size),
       Conformance_Id => Pad ("events.text.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("text_inserted", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.text_remove", Feature_Id_Size),
       Conformance_Id => Pad ("events.text.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("text_removed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.text_replace", Feature_Id_Size),
       Conformance_Id => Pad ("events.text.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("text_replaced", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.text_set", Feature_Id_Size),
       Conformance_Id => Pad ("text.edit.request", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("text_set", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.caret_move", Feature_Id_Size),
       Conformance_Id => Pad ("events.text.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("caret_moved", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.text_field_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.text_field", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Text_Field_Id,
       Role    => A11y.Roles.Text_Field,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_cell", Feature_Id_Size),
       Conformance_Id => Pad ("table.cell.basic", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Cell_Id,
       Role    => A11y.Roles.Cell,
       Status  => Pad ("table_cell", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_current_cell", Feature_Id_Size),
       Conformance_Id => Pad ("table.current_cell", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Cell_Id,
       Role    => A11y.Roles.Cell,
       Status  => Pad ("current_cell", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_sort_metadata", Feature_Id_Size),
       Conformance_Id => Pad ("table.sort.metadata", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Id,
       Role    => A11y.Roles.Table,
       Status  => Pad ("sort_metadata", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_row_insert", Feature_Id_Size),
       Conformance_Id => Pad ("events.table.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Id,
       Role    => A11y.Roles.Table,
       Status  => Pad ("row_inserted", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.table_cell_change", Feature_Id_Size),
       Conformance_Id => Pad ("events.table.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Table_Cell_Id,
       Role    => A11y.Roles.Cell,
       Status  => Pad ("cell_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.informative_image", Feature_Id_Size),
       Conformance_Id => Pad ("image.alternative_text", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Informative_Image_Id,
       Role    => A11y.Roles.Image,
       Status  => Pad ("alternative_text", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.image_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.image", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Informative_Image_Id,
       Role    => A11y.Roles.Image,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.decorative_image_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.decorative_image", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Decorative_Image_Id,
       Role    => A11y.Roles.Image,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.document_heading", Feature_Id_Size),
       Conformance_Id => Pad ("document.heading.level", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Heading_Id,
       Role    => A11y.Roles.Heading,
       Status  => Pad ("heading_level", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.document_loaded", Feature_Id_Size),
       Conformance_Id => Pad ("events.document.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Document_Id,
       Role    => A11y.Roles.Document,
       Status  => Pad ("document_loaded", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.heading_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.heading", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Heading_Id,
       Role    => A11y.Roles.Heading,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.document_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.document", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Document_Id,
       Role    => A11y.Roles.Document,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.paragraph_text_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.text", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Paragraph_Id,
       Role    => A11y.Roles.Text,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.link_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.link", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Link_Id,
       Role    => A11y.Roles.Link,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.password_protected", Feature_Id_Size),
       Conformance_Id => Pad ("text.protected", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Password_Field_Id,
       Role    => A11y.Roles.Password_Field,
       Status  => Pad ("protected", 32),
       Privacy => Pad ("protected_redacted", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.password_field_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.password_field", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Password_Field_Id,
       Role    => A11y.Roles.Password_Field,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.live_region", Feature_Id_Size),
       Conformance_Id => Pad ("events.live_region.changed", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Live_Region_Id,
       Role    => A11y.Roles.Status,
       Status  => Pad ("ready", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.status_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.status", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Live_Region_Id,
       Role    => A11y.Roles.Status,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.validation_error", Feature_Id_Size),
       Conformance_Id => Pad ("relations.error_message", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Validation_Error_Id,
       Role    => A11y.Roles.Alert,
       Status  => Pad ("ready", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.relation_event", Feature_Id_Size),
       Conformance_Id => Pad ("events.relation.payload", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Password_Field_Id,
       Role    => A11y.Roles.Password_Field,
       Status  => Pad ("relation_changed", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.alert_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.alert", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Validation_Error_Id,
       Role    => A11y.Roles.Alert,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.popup_role", Feature_Id_Size),
       Conformance_Id => Pad ("core.role.popup_dialog", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Popup_Id,
       Role    => A11y.Roles.Dialog,
       Status  => Pad ("role", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.modal_surface", Feature_Id_Size),
       Conformance_Id => Pad ("window.surface.state_metadata", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Modal_Surface_Id,
       Role    => A11y.Roles.Dialog,
       Status  => Pad ("ready", 32),
       Privacy => Pad ("public", 32),
       Native_Resolution => Pad ("available", 32)),
      (Feature => Pad ("fixture.destroyed_list_item", Feature_Id_Size),
       Conformance_Id => Pad ("lifecycle.stale_reference", Conformance_Id_Size),
       Node    => A11y_Test_Fixtures.Destroyed_List_Item_Id,
       Role    => A11y.Roles.List_Item,
       Status  => Pad ("stale_reference", 32),
       Privacy => Pad ("lifecycle_only", 32),
       Native_Resolution => Pad ("node_unavailable", 32)),
      (Feature => Pad ("native.object_registry", Feature_Id_Size),
       Conformance_Id => Pad ("native.object_cache.identity", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registry_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.export_descriptor", Feature_Id_Size),
       Conformance_Id => Pad ("native.object_export_descriptor", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("descriptor_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("windows.uia.host_window_root_binding", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.host_window_root_binding", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("host_window_bound", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("macos.nsax.main_thread_binding", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.main_thread_binding", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("main_thread_bound", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("macos.nsax.native_view_binding", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.native_view_binding", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_view_bound", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.node_index", Feature_Id_Size),
       Conformance_Id => Pad ("native.object_cache.node_index", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("node_index_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.cache_tombstone", Feature_Id_Size),
       Conformance_Id => Pad ("native.object_cache.tombstone", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("tombstones_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.cache_session_scope", Feature_Id_Size),
       Conformance_Id => Pad ("native.object_cache.session_scope", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_scoped", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.runtime_lifecycle", Feature_Id_Size),
       Conformance_Id => Pad ("native.runtime.lifecycle", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("runtime_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.runtime_lifecycle_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.runtime.lifecycle_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("lifecycle_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.runtime_probe_failure_stage", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.runtime.probe_failure_stage", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("failure_stage_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.runtime_event_application", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.runtime.event_application", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_application_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.runtime_event_preparation", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.runtime.event_preparation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_preparation_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.runtime_event_preparation_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.runtime.event_preparation_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("preparation_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.projection_property", Feature_Id_Size),
       Conformance_Id => Pad ("native.projection.property", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("property_projection_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.projection_action", Feature_Id_Size),
       Conformance_Id => Pad ("native.projection.action", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_projection_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.projection_relation", Feature_Id_Size),
       Conformance_Id => Pad ("native.projection.relation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("relation_projection_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.projection_event_source", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.projection.event_source", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_source_projection", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.transport", Feature_Id_Size),
       Conformance_Id => Pad ("backend.transport.unavailable", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("blocked_transport_unavailable", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client", Conformance_Id_Size),
      Node    => A11y.Node_Ids.No_Node,
      Role    => A11y.Roles.Application,
      Status  => Pad ("external_client_traversal", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.registered_transport",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.registered_transport",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registered_transport", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.vertical_core",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_core_slice", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.vertical_interaction",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_interaction_slice", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.vertical_content",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_content_slice", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.vertical_surface",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_surface_slice", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.vertical_live_region",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_live_region_slice", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.failure_stage",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.failure_stage",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("failure_stage_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attributes", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.attributes", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_attributes_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.help_text",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.help_text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_help_text", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.placeholder",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.placeholder", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_placeholder", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.value_text",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.value_text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_value_text", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.visible_title",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.visible_title", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_visible_title", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.keyboard_shortcut",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.keyboard_shortcut", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_shortcut", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.semantic_identifier",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.semantic_identifier", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_identifier", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.locale",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.locale", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_locale", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.orientation",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.orientation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_orientation", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.attribute.landmark",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("core.property.landmark", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_landmark", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.protected_value", Feature_Id_Size),
      Conformance_Id =>
         Pad
           ("linux.atspi.live_external_client.protected_value",
            Conformance_Id_Size),
      Node    => A11y.Node_Ids.No_Node,
      Role    => A11y.Roles.Application,
      Status  => Pad ("protected_value_checked", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.component", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.component", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_component_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.action", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.action", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_action_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.value", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.value", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_value_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.selection", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.selection", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_selection_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.text", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_text_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.image", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.image", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_image_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.document", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.document", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_document_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.table", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.table", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_table_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.surface", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.surface", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("external_surface_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("linux.atspi.live_external_client.live_region",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.live_external_client.live_region",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("external_live_region_checked", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("live_atspi_session_bus", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.com_live_chain", Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live_export", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
      Role    => A11y.Roles.Application,
      Status  => Pad ("com_live_chain_observed", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.public_root_export.path", Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.public_root_export", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_export_path_observed", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.public_root.native_identity", Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.public_root.native_identity",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_identity_stable", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.failure_stage", Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.external_client.failure_stage",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("failure_stage_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.metadata", Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.metadata_properties", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("metadata_preserved", 32),
       Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.embedded_fragment_roots_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.embedded_fragment_roots",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("embedded_fragment_roots_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.fragment_last_child_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.fragment_last_child_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("fragment_last_child_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.provider_options_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.provider_options",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("provider_options_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.host_raw_element_provider_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.host_raw_element_provider",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("host_raw_element_provider_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.pattern_provider_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.pattern_provider_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("pattern_provider_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.bounding_rectangle_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.bounding_rectangle_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("bounding_rectangle_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.simple_property_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.simple_property_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("simple_property_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.full_frame_callback",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.bridge_audit", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("full_frame_callback", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.fragment_action_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.fragment_action_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fragment_action_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.fragment_root_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.fragment_root", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fragment_root_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.fragment_root_point_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.fragment_root_point",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fragment_root_point_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.fragment_root_focus_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.com_live.fragment_root_focus",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fragment_root_focus_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("windows.uia.external_client.protected_value",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("windows.uia.protected_value_text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("protected_suppressed", 32),
       Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.element_chain", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.hierarchy", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("element_chain_observed", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.public_root_export.path", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.public_root_export",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_export_path_observed", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.public_root.native_identity", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.public_root.native_identity",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_identity_stable", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.public_root.hit_test_frame", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.public_root.hit_test_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hit_test_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.public_root.focused_element_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.public_root.focused_element_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("focused_element_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.public_root.notification_frame", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.public_root.notification_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("notification_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.virtual_element_bridge", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.virtual_element_bridge",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("virtual_element_bridge", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.failure_stage", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.external_client.failure_stage",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("failure_stage_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.metadata", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.metadata_attributes",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("metadata_preserved", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.attribute_value_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.selector.attribute_value_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("attribute_value_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.children_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.selector.children_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("children_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.child_at_index_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.selector.child_at_index_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("child_at_index_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.attribute_settable_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.selector.attribute_settable_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
      Status  => Pad ("attribute_settable_frame", 32),
      Privacy => Pad ("transport_only", 32),
      Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.action_frame",
              Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.selector.action_frame",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("macos.nsax.external_client.protected_value", Feature_Id_Size),
      Conformance_Id =>
         Pad ("macos.nsaccessibility.protected_value_text",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("protected_suppressed", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.transport_generation", Feature_Id_Size),
       Conformance_Id =>
         Pad ("backend.native.transport_generation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("generation_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.transport_transition_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("backend.native.transport_transition_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("transition_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.cache_generation", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.object_cache.generation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("generation_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.cache_mutation_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.object_cache.mutation_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("mutation_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.registry_generation", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.object_registry.generation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registry_generation", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.registry_drained_reset", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.object_registry.drained_reset", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("drained_reset_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.registry_mutation_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.object_registry.mutation_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registry_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.boundary_runtime_generation", Feature_Id_Size),
       Conformance_Id => Pad ("native.runtime.generation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("boundary_generation", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.action_payload", Feature_Id_Size),
       Conformance_Id => Pad ("native.request.action_payload", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_payload_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.action_request_payload", Feature_Id_Size),
       Conformance_Id => Pad ("native.request.action_payload", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_request_payload", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.event_staging", Feature_Id_Size),
       Conformance_Id => Pad ("native.event.staging_queue", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("bounded_queue", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.event_prepared_status", Feature_Id_Size),
       Conformance_Id => Pad ("native.event.prepared_status", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("status_handoff", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.event_posting_interest", Feature_Id_Size),
       Conformance_Id => Pad ("native.event.posting_interest", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_interest", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.event_validation", Feature_Id_Size),
       Conformance_Id => Pad ("native.event.validation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_validation_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.event_posting_boundary", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.event.posting_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_boundary_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.event_exhaustive_map", Feature_Id_Size),
       Conformance_Id => Pad ("native.event.exhaustive_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.role_exhaustive_map", Feature_Id_Size),
       Conformance_Id => Pad ("native.role.exhaustive_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("role_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.relation_exhaustive_map", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.relation.exhaustive_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("relation_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.method_return_payload", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.method_return_payload", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("transport_payload_bytes", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.method_return_decode", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.method_return_decode", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("return_decode", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.error_return_decode", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.error_return_decode", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("error_decode", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.error_return_diagnostic", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.error_return_diagnostic", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("error_diagnostic", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.startup_error_completion", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_error_completion", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("startup_error_completion", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.incoming_packet_classification", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.incoming_packet_classification", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("packet_classification", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.incoming_dispatch", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.incoming_packet_dispatch", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("dispatch_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.startup_pump_ready", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_pump_readiness", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("readiness_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.startup_outgoing_work", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_outgoing_work", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("work_state_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.startup_loop_interest", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_event_loop_interest", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("loop_interest_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.startup_next_operation", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_event_loop_operation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("operation_classified", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_backend_session_loop", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.backend_session_event_loop_step", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_loop_step", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_backend_session_loop_status", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.backend_session_event_loop_step", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_loop_step_status", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_backend_session_transport_cycle", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.backend_session_transport_cycle_scheduler",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_transport_cycle", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_backend_session_transport_cycle_status",
                       Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.backend_session_transport_cycle_scheduler",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_transport_cycle_status", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_backend_session_transport_cycle_write_wait",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.backend_session_transport_cycle_scheduler",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_transport_cycle_write_wait", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_backend_session_transport_cycle_after",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.backend_session_transport_cycle_scheduler",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_transport_cycle_after", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_backend_session_transport_cycle_packet",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.backend_session_transport_cycle_scheduler",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("backend_transport_cycle_packet", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_session_dispatch_loop_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.session_dispatch.loop_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_loop_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.startup_outgoing_flush", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_outgoing_flush", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("flush_staged", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_outgoing_back_pressure", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.outgoing_back_pressure", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("back_pressure_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_connection_lifecycle", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.connection_lifecycle", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("connection_lifecycle_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_local_channel_adapter", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.local_channel_adapter", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("local_channel_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_local_channel_receive", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.local_channel_receive", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("local_receive_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_controller", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_controller", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("startup_controller_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_backend_adapter", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_backend_adapter", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("startup_adapter_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_pump", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_pump", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("startup_pump_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_pump_report", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_pump_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("startup_pump_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_pump_bounded_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.startup_pump_bounded_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("pump_bounded_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_pump_bounds", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_pump_bounds", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("pump_bounds_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_registered_pump", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.startup_registered_pump", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registered_pump", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_bus_address", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.bus_address", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("bus_address_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_auth_external", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.auth_external", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("auth_external_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_auth_exchange", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.auth_exchange", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("auth_exchange_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_authenticated_connect", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.authenticated_connect", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("auth_connect_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_hello", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.hello", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hello_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_authenticated_hello", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.authenticated_hello", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("auth_hello_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_registration_completion", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.registration_completion", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registration_reply_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_authenticated_registration", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.authenticated_registration", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("auth_registration_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_reply_evidence", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_reply_evidence", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("reply_stage_reported", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_application_registration", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.application_registration", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("application_registration_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_live_transport_registration", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.live_transport.registration_observed", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("transport_registration_observed", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_address_discovery", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.address_discovery", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("address_discovery_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_host_environment_startup", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.host_environment_startup",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("host_env_startup_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_a11y_bus_get_address", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.a11y_bus_get_address", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("get_address_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_authenticated_get_address", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.authenticated_get_address", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("auth_get_address_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_startup_session_discovery", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.startup_session_discovery", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_discovery_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_frame_metadata", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_frame_metadata", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("frame_metadata_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_frame_bytes", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_frame_bytes", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("frame_bytes_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_frame_send", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_frame_send", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("frame_send_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_packet", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_packet", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("packet_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_packet_send", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_packet_send", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("packet_send_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_packet_decode", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_packet_decode", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("packet_decode_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_dbus_codec_basic", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.codec.basic", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("codec_basic_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_dbus_resource_limits", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.resource_limits", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("dbus_limits_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_message_envelope", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.message_envelope", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("message_envelope_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_method_call_envelope", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.method_call_envelope", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("method_call_envelope_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_transport_envelope_decode", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.transport_envelope_decode", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("envelope_decode_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_incoming_call_decode", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.incoming_call_decode", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("incoming_call_decode_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_signal_envelope", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.signal_envelope", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("signal_envelope_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_prepared_signal_envelope", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.prepared_signal_envelope", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_signal_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_signal_build_report", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.signal.build_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("signal_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_method_boundary", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.method_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("method_boundary_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.deterministic_shutdown", Feature_Id_Size),
       Conformance_Id => Pad ("backend.native.deterministic_shutdown", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("shutdown_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.diagnostics_bounded", Feature_Id_Size),
       Conformance_Id => Pad ("backend.diagnostics.bounded", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("diagnostics_bounded", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.diagnostics_result", Feature_Id_Size),
       Conformance_Id => Pad ("diagnostics.result_mapping", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("result_mapping_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.diagnostics_fields", Feature_Id_Size),
       Conformance_Id => Pad ("diagnostics.field_bounds", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("field_bounds_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.resource_limit", Feature_Id_Size),
       Conformance_Id => Pad ("native.object_cache.resource_limit", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("resource_limit_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.value_resource_limit", Feature_Id_Size),
       Conformance_Id => Pad ("native.value.resource_limit", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_values_bounded", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.hostile_identity", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.identity_admission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("identity_rejected", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.boundary_admission_report", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.admission_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("admission_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.boundary_native_call_report", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.native_call_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_call_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.boundary_completion_report", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.completion_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("completion_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.boundary_release_report", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.release_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("release_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.malformed_request", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.error_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("malformed_rejected", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_error_name_map", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.error_name_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("error_names_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_error_name_inverse", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.error_name_inverse_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("error_statuses_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_error_name_diagnostic", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.error_name_diagnostic", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("error_diagnostic_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_role_map", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.role_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("role_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_state_map", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.state_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("state_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_object_path", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.object_path", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("object_path_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_startup_object_path", Feature_Id_Size),
       Conformance_Id => Pad
         ("linux.atspi.startup_object_path", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("startup_object_path_redacted", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_method_router", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.method_router", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("method_router_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_application_id", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.application.id", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("application_id_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_application_metadata", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.application.metadata", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("application_metadata", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_accessible_role", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.accessible.role", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("accessible_role_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_accessible_state", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.accessible.state", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("accessible_state_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_accessible_name", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.accessible.name", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("accessible_name_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_accessible_description", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.accessible.description", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("accessible_description", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_accessible_child_count", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.accessible.child_count", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("accessible_child_count", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_accessible_relations", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.accessible.relations", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("accessible_relations", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_component_extents", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.component.extents", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("component_extents", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_component_contains", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.component.contains", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("component_contains", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_component_hit_test", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.component.hit_test", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("component_hit_test", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_component_focus", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.component.focus", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("component_focus", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_action_count", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.action.count", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_count_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_action_name", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.action.name", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_name_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_action_invoke", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.action.invoke", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_invoke_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_value_current", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.value.current", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_current_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_value_range", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.value.range", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_range_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_value_set_request", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.value.set_request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_set_request", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_selection_count", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.selection.count", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_count", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_selection_selected_child", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.selection.selected_child", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_selected_child", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_selection_request", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.selection.request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_request", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_selection_deselect", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.selection.deselect_child", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_deselect", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_selection_select_all", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.selection.select_all", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_select_all", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_selection_clear", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.selection.clear_selection", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_clear", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_text_character_count", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.text.character_count", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_character_count", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_text_range", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.text.range", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_range_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_text_caret", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.text.caret", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_caret_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_text_protected", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.text.protected", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_protected_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_text_edit_request", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.text.edit_request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_edit_request", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_table_dimensions", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.table.dimensions", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("table_dimensions", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_table_cell", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.table.cell", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("table_cell_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_table_cell_span", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.table.cell_span", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("table_cell_span", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_image_description", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.image.description", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("image_description", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_image_size", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.image.size", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("image_size_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_image_decorative_omission", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.image.decorative_omission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("image_decorative", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_document_locale", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.document.locale", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("document_locale", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_document_attributes", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.document.attributes", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("document_attributes", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_document_heading_level", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.document.heading_level", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("document_heading_level", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_document_landmark", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.document.landmark", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("document_landmark", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_surface_metadata", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.surface.metadata", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("surface_metadata", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_surface_routing", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.surface_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("surface_routing", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_signal_focus", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.signal.focus", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("signal_focus", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_signal_text", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.signal.text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("signal_text", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_signal_lifecycle", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.signal.lifecycle", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("signal_lifecycle", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_atspi_signal_prepared_publication", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.signal.prepared_publication", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("signal_prepared", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_atspi_cache_node", Feature_Id_Size),
       Conformance_Id => Pad ("linux.atspi.cache.node", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("cache_node", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_dbus_unsupported_value", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.unsupported_value", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("unsupported_value_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_dbus_uint32_array_value", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.uint32_array_value", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("uint32_array_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_state_set_uint32_array", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.state_set_uint32_array", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("state_set_array_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_dbus_string_array_value", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.string_array_value", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("string_array_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_attribute_string_array", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.attribute_string_array", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("attribute_array_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_cache_interface_array", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.cache_interface_string_array", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("cache_interfaces_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_dbus_object_path_array", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.object_path_array_value", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("object_path_array_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.linux_relation_target_object_paths", Feature_Id_Size),
       Conformance_Id => Pad ("linux.dbus.relation_target_object_path_array", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("relation_targets_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_hresult_map", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.hresult_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hresults_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_hresult_inverse", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.hresult_inverse_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hresult_statuses_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_hresult_diagnostic", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.hresult_diagnostic", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hresult_diagnostic_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_event_posting_admission", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.event_posting_admission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_admission_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_event_posting_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.event_posting_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_event_posting_drain_bounded", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.event_posting_drain_bounded", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_drain_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_core_properties", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.core_properties", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("core_properties_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_bounds", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.bounding_rectangle", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("bounds_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_textual_properties", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.textual_properties", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_properties_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_metadata_properties", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.metadata_properties", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("metadata_props_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_protected_value_text", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.protected_value_text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("protected_value_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_action_map", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.action_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_action_request", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.action.request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_request_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_set_focus", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.action.set_focus", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("set_focus_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_native_focus_query", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.focus_call", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("focus_query_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_native_set_focus", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.focus_call", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("set_focus_dispatched", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_open", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.action.open", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("open_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_scroll", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.action.scroll_into_view", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("scroll_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_close", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.action.close", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("close_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_event_map", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.event_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_event_details", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.event_details", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_details_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_prepared_emission", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.prepared_event_emission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_emit_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_event_build_report", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.event.build_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_prepared_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.prepared_event_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_prepared_boundary", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.prepared_event_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_boundary", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_fragment_navigation", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.fragment.navigation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fragment_nav_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_runtime_id", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.runtime_id", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("runtime_id_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_relation_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.relation_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("relation_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_value_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.value_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_value_set", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.value.set_request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_set_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_selection_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.selection_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_route", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_selection_request", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.selection.request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_request", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_selection_select_all", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.selection.select_all", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_select_all", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_selection_clear", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.selection.clear_selection", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_clear", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_text_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.text_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_text_edit", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.text_edit_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_edit_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_table_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.table_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("table_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_image_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.image_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("image_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_document_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.document_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("doc_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_surface_routing", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.surface_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("surface_route", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_request_router", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.request_router", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("request_router", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_provider_boundary", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.provider_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("provider_boundary", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_provider_registry", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.provider_registry", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("provider_registry", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_lifetime", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_lifetime", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_lifetime", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_export", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_export_descriptor", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_export", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_vtable", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_vtable_descriptor", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_vtable", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_object_export", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_object_export", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_object_export", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_export", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live_export", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_export", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_interface_retain", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.interface_retain", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_iface_retain", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_interface_release", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.interface_release", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_iface_release", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_released_interface", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.released_interface", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_iface_released", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_invalid_interface_frame", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.invalid_interface_frame", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_bad_iface_frame", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_invalid_method_frame", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.invalid_method_frame", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_bad_method", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_interface_method_mismatch", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.interface_method_mismatch", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_iface_mismatch", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_registered_routed_error_status", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.native_call_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registered_routed_error", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_fragment_navigate", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.fragment_navigate", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_fragment_nav", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_com_live_fragment_runtime_id", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.com_live.fragment_runtime_id", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("com_live_fragment_rtid", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_native_values", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.native_values", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_values", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_bridge_audit", Feature_Id_Size),
       Conformance_Id => Pad ("windows.uia.bridge_audit", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("bridge_audit", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_hostile_callback_admission", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.native_callback.hostile_admission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hostile_callback_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_missing_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.native_callback.missing_identity",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("missing_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_mismatched_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.native_callback.mismatched_identity",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("mismatched_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_malformed_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.native_callback.malformed_identity",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("malformed_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.windows_uia_text_payload_limit", Feature_Id_Size),
       Conformance_Id =>
         Pad ("windows.uia.native_callback.text_payload_limit",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_payload_limit", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_status_map", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.native_status_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_status_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_status_inverse", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.native_status_inverse_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_statuses_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_status_diagnostic", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.native_status_diagnostic", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_status_diagnostic", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_event_posting_admission", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.event_posting_admission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_admission_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_event_posting_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.event_posting_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_event_posting_drain_bounded", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.event_posting_drain_bounded", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("posting_drain_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_hostile_callback_admission", Feature_Id_Size),
       Conformance_Id =>
         Pad
           ("macos.nsaccessibility.native_callback.hostile_admission",
            Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hostile_callback_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_missing_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad
           ("macos.nsaccessibility.native_callback.missing_identity",
            Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("missing_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_mismatched_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad
           ("macos.nsaccessibility.native_callback.mismatched_identity",
            Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("mismatched_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_malformed_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad
           ("macos.nsaccessibility.native_callback.malformed_identity",
            Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("malformed_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_text_payload_limit", Feature_Id_Size),
       Conformance_Id =>
         Pad
           ("macos.nsaccessibility.native_callback.text_payload_limit",
            Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_payload_limit", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_core_attributes", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.core_attributes", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("core_attrs_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_attribute_names", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.attribute_names", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("attribute_names", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_frame", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.frame_attribute", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("frame_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_textual_attributes", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.textual_attributes", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_attrs_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_metadata_attributes", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.metadata_attributes", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("metadata_attrs_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_protected_value_text", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.protected_value_text", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("protected_value_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_action_map", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.action_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_action_request", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.action.request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("action_request_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_open", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.action.open", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("open_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_close", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.action.close", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("close_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_set_focus", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.action.set_focus", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("set_focus_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_native_focus_query", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.focus_call", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("focus_query_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_native_set_focus", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.focus_call", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("set_focus_dispatched", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_scroll_visible", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.action.scroll_to_visible", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("scroll_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_event_map", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.event_map", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_map_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_event_details", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.event_details", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_details_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_prepared_emission", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.prepared_event_emission", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_emit_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_event_build_report", Feature_Id_Size),
       Conformance_Id =>
         Pad ("macos.nsaccessibility.event.build_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("event_report_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_prepared_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.prepared_event_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_prepared_boundary", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.prepared_event_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("prepared_boundary", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_hierarchy", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.hierarchy", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("hierarchy_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_element_id", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.element_id", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("element_id_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_relation_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.relation_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("relation_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_value_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.value_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_value_set", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.value.set_request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("value_set_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selection_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selection_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_route", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selection_request", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selection.request", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_request", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selection_select_all", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selection.select_all", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_select_all", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selection_clear", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selection.clear_selection", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selection_clear", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_text_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.text_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_text_edit", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.text_edit_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_edit_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_table_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.table_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("table_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_image_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.image_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("image_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_document_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.document_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("doc_route_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_surface_routing", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.surface_routing", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("surface_route", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_request_router", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.request_router", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("request_router", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_provider_boundary", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.provider_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("provider_boundary", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_element_registry", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.element_registry", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("element_registry", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_element_lifetime", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.element_lifetime", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("element_lifetime", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_element_export", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.element_export_descriptor", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("element_export", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selector_attribute_value", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selector.attribute_value", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selector_attr_value", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selector_unsupported", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selector.unsupported", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selector_unsupported", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_selector_main_thread_gate", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.selector.main_thread_gate", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("selector_main_thread", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_registered_method_family_mismatch", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.registered_method_family_mismatch", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("method_family_mismatch", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_registered_routed_error_status", Feature_Id_Size),
       Conformance_Id => Pad ("native.boundary.native_call_report", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("registered_routed_error", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_released_boundary", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.released_boundary", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("released_boundary", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_native_values", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.native_values", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("native_values", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.macos_nsax_bridge_audit", Feature_Id_Size),
       Conformance_Id => Pad ("macos.nsaccessibility.bridge_audit",
                              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("bridge_audit", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.backend_override", Feature_Id_Size),
       Conformance_Id => Pad ("backend.selection.runtime_override", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("override_resolved", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_root_probe", Feature_Id_Size),
       Conformance_Id => Pad ("native.fixture_root.query", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_root_query", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_root_child_traversal", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_root.child_traversal", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_traversal", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_root_child_count", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_root.child_count", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_count", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.fixture_root_second_child_traversal", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_root.second_child", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_second_child", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_child_query", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_child.query", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_query", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_child_object", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_child.native_object", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_object", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.fixture_child_parent_navigation", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_child.parent_navigation", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_parent", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.fixture_child_native_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_child.native_identity", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.fixture_second_child_parent", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_second_child.parent_navigation",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_second_parent", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.fixture_second_child_native_identity", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_second_child.native_identity",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_second_identity", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_sibling_order", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture.sibling_order", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_sibling_order", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_child_stale_id", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_child.stale_id", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("fixture_child_stale_id", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("native.fixture_root_failure_stage", Feature_Id_Size),
       Conformance_Id =>
         Pad ("native.fixture_root.failure_stage", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("failure_stage_report", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("linux.atspi.serving_packet_probe", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet_probe", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("serving_packet", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_tree_traversal", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.tree_traversal",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("tree_traversal", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_property", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.property",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("property_variant", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_property_map", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.property_map",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("property_map", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("linux.atspi.serving_packet_stale_error", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.stale_error", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("stale_error_checked", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_stale_error_queued",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.stale_error.queued",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("stale_error_queued", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_stale_error_serialized",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.stale_error.serialized",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("stale_error_serialized", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_stale_error_decoded",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.stale_error.decoded",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("stale_error_decoded", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_stale_error_drained",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.stale_error.drained",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("stale_error_drained", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_unsupported_interface",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.unsupported_interface",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("unsupported_interface", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_unsupported_interface_queued",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.unsupported_interface.queued",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("unsupported_queued", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_unsupported_interface_serialized",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.unsupported_interface.serialized",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("unsupported_serialized", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_unsupported_interface_decoded",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.unsupported_interface.decoded",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("unsupported_decoded", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_unsupported_interface_drained",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.unsupported_interface.drained",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("unsupported_drained", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_malformed_packet",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.malformed_packet",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("malformed_packet", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.serving_packet_text_payload_limit",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.serving_packet.text_payload_limit",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("text_payload_limit", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("linux.atspi.session_dispatch_probe", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.session_dispatch_probe", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_dispatch", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("linux.atspi.session_dispatch_boundary_drained",
              Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.session_dispatch.boundary_drained",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_boundary_drained", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("linux.atspi.session_bus_probe", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.session_bus_probe", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_bus_probe", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature => Pad ("linux.atspi.session_startup_stage", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.atspi.session_startup_stage", Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("session_startup_stage", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32)),
      (Feature =>
         Pad ("native.linux_method_call_destination_routing", Feature_Id_Size),
       Conformance_Id =>
         Pad ("linux.dbus.method_call_destination_routing",
              Conformance_Id_Size),
       Node    => A11y.Node_Ids.No_Node,
       Role    => A11y.Roles.Application,
       Status  => Pad ("destination_header", 32),
       Privacy => Pad ("transport_only", 32),
       Native_Resolution => Pad ("transport_unavailable", 32))];

   function Observation_Count return Natural is (Observations'Length);

   function Protected_Observation_Count return Natural is
      Count : Natural := 0;
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Privacy) = "protected_redacted" then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Protected_Observation_Count;

   function Lifecycle_Observation_Count return Natural is
      Count : Natural := 0;
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Privacy) = "lifecycle_only" then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Lifecycle_Observation_Count;

   function Transport_Observation_Count return Natural is
      Count : Natural := 0;
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Privacy) = "transport_only" then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Transport_Observation_Count;

   function Semantic_Node_Identity_Count return Natural is
      Count : Natural := 0;
   begin
      for Observation of Observations loop
         if A11y.Node_Ids.Is_Valid (Observation.Node) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Semantic_Node_Identity_Count;

   function Has_Observation
     (Feature : String;
      Conformance_Id : String;
      Node : A11y.Node_Ids.Node_Id;
      Role : A11y.Roles.Role)
      return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = Feature
           and then Trimmed (Observation.Conformance_Id) = Conformance_Id
           and then Observation.Node = Node
           and then Observation.Role = Role
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Observation;

   function Has_Transport_Staging_Observation return Boolean is
     (Has_Observation
        ("native.event_staging",
         "native.event.staging_queue",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Transport_Generation_Observation return Boolean is
     (Has_Observation
        ("native.transport_generation",
         "backend.native.transport_generation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Transport_Transition_Report_Observation return Boolean is
     (Has_Observation
        ("native.transport_transition_report",
         "backend.native.transport_transition_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Cache_Generation_Observation return Boolean is
     (Has_Observation
        ("native.cache_generation",
         "native.object_cache.generation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Cache_Mutation_Report_Observation return Boolean is
     (Has_Observation
        ("native.cache_mutation_report",
         "native.object_cache.mutation_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Registry_Generation_Observation return Boolean is
     (Has_Observation
        ("native.registry_generation",
         "native.object_registry.generation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Registry_Drained_Reset_Observation return Boolean is
     (Has_Observation
        ("native.registry_drained_reset",
         "native.object_registry.drained_reset",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Registry_Mutation_Report_Observation return Boolean is
     (Has_Observation
        ("native.registry_mutation_report",
         "native.object_registry.mutation_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Boundary_Runtime_Generation_Observation
      return Boolean is
     (Has_Observation
        ("native.boundary_runtime_generation",
         "native.runtime.generation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Root_Probe_Observation return Boolean is
     (Has_Observation
        ("native.fixture_root_probe",
         "native.fixture_root.query",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Root_Failure_Stage_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_root_failure_stage",
         "native.fixture_root.failure_stage",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Root_Child_Traversal_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_root_child_traversal",
         "native.fixture_root.child_traversal",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Root_Child_Count_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_root_child_count",
         "native.fixture_root.child_count",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Root_Second_Child_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_root_second_child_traversal",
         "native.fixture_root.second_child",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Child_Query_Observation return Boolean is
     (Has_Observation
        ("native.fixture_child_query",
         "native.fixture_child.query",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Child_Object_Observation return Boolean is
     (Has_Observation
        ("native.fixture_child_object",
         "native.fixture_child.native_object",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Child_Parent_Observation return Boolean is
     (Has_Observation
        ("native.fixture_child_parent_navigation",
         "native.fixture_child.parent_navigation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Child_Native_Identity_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_child_native_identity",
         "native.fixture_child.native_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Second_Child_Parent_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_second_child_parent",
         "native.fixture_second_child.parent_navigation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Second_Child_Native_Identity_Observation
      return Boolean is
     (Has_Observation
        ("native.fixture_second_child_native_identity",
         "native.fixture_second_child.native_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Sibling_Order_Observation return Boolean is
     (Has_Observation
        ("native.fixture_sibling_order",
         "native.fixture.sibling_order",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Fixture_Child_Stale_Id_Observation return Boolean is
     (Has_Observation
        ("native.fixture_child_stale_id",
         "native.fixture_child.stale_id",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Probe_Observation return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_probe",
         "linux.atspi.serving_packet_probe",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_tree_traversal",
         "linux.atspi.serving_packet.tree_traversal",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Property_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_property",
         "linux.atspi.serving_packet.property",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_property_map",
         "linux.atspi.serving_packet.property_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Core_Observations return Boolean is
     (Has_Linux_ATSPI_Serving_Packet_Probe_Observation
      and then Has_Linux_ATSPI_Serving_Packet_Property_Observation
      and then Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation
      and then Has_Linux_ATSPI_Core_Method_Observations);

   function Has_Linux_ATSPI_Serving_Packet_Interaction_Observations
      return Boolean is
     (Has_Linux_ATSPI_Serving_Packet_Probe_Observation
      and then Has_Linux_ATSPI_Interaction_Method_Observations);

   function Has_Linux_ATSPI_Serving_Packet_Content_Observations
      return Boolean is
     (Has_Linux_ATSPI_Serving_Packet_Probe_Observation
      and then Has_Linux_ATSPI_Content_Method_Observations
      and then Has_Linux_ATSPI_Document_Surface_Event_Observations);

   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_stale_error",
         "linux.atspi.serving_packet.stale_error",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_stale_error_queued",
         "linux.atspi.serving_packet.stale_error.queued",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_stale_error_serialized",
         "linux.atspi.serving_packet.stale_error.serialized",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_stale_error_decoded",
         "linux.atspi.serving_packet.stale_error.decoded",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_stale_error_drained",
         "linux.atspi.serving_packet.stale_error.drained",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_unsupported_interface",
         "linux.atspi.serving_packet.unsupported_interface",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_unsupported_interface_queued",
         "linux.atspi.serving_packet.unsupported_interface.queued",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_unsupported_interface_serialized",
         "linux.atspi.serving_packet.unsupported_interface.serialized",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_unsupported_interface_decoded",
         "linux.atspi.serving_packet.unsupported_interface.decoded",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_unsupported_interface_drained",
         "linux.atspi.serving_packet.unsupported_interface.drained",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_malformed_packet",
         "linux.atspi.serving_packet.malformed_packet",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.serving_packet_text_payload_limit",
         "linux.atspi.serving_packet.text_payload_limit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Serving_Packet_Full_Observations return Boolean is
     (Has_Linux_ATSPI_Serving_Packet_Core_Observations
      and then Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation
      and then Has_Linux_ATSPI_Serving_Packet_Interaction_Observations
      and then Has_Linux_ATSPI_Serving_Packet_Content_Observations
      and then Has_Linux_ATSPI_Serving_Packet_Stale_Error_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation
      and then Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation
      and then
        Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation);

   function Has_Linux_ATSPI_Session_Dispatch_Probe_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.session_dispatch_probe",
         "linux.atspi.session_dispatch_probe",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.session_dispatch_boundary_drained",
         "linux.atspi.session_dispatch.boundary_drained",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Registered_Boundary_Report_Observation
      return Boolean is
     (Has_Linux_ATSPI_Session_Dispatch_Probe_Observation
      and then Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation
      and then Has_Native_Boundary_Native_Call_Report_Observation);

   function Has_Linux_ATSPI_Session_Bus_Probe_Observation return Boolean is
     (Has_Observation
        ("linux.atspi.session_bus_probe",
         "linux.atspi.session_bus_probe",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Observation return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client",
         "linux.atspi.live_external_client",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_Registered_External_Client_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.registered_transport",
         "linux.atspi.live_external_client.registered_transport",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Linux_ATSPI_Live_External_Client_Observation
      and then Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation);

   function Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.vertical_core",
         "linux.atspi.live_external_client",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.vertical_interaction",
         "linux.atspi.live_external_client",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.vertical_content",
         "linux.atspi.live_external_client",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.vertical_surface",
         "linux.atspi.live_external_client",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.vertical_live_region",
         "linux.atspi.live_external_client",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.failure_stage",
         "linux.atspi.live_external_client.failure_stage",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Attribute_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.attributes",
         "linux.atspi.live_external_client.attributes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function
      Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.attribute.help_text",
         "core.property.help_text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.placeholder",
         "core.property.placeholder",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.value_text",
         "core.property.value_text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.visible_title",
         "core.property.visible_title",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.keyboard_shortcut",
         "core.property.keyboard_shortcut",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.semantic_identifier",
         "core.property.semantic_identifier",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.locale",
         "core.property.locale",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.orientation",
         "core.property.orientation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("linux.atspi.live_external_client.attribute.landmark",
         "core.property.landmark",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.protected_value",
         "linux.atspi.live_external_client.protected_value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Component_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.component",
         "linux.atspi.live_external_client.component",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Action_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.action",
         "linux.atspi.live_external_client.action",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Value_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.value",
         "linux.atspi.live_external_client.value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Selection_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.selection",
         "linux.atspi.live_external_client.selection",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Text_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.text",
         "linux.atspi.live_external_client.text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Image_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.image",
         "linux.atspi.live_external_client.image",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Document_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.document",
         "linux.atspi.live_external_client.document",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Table_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.table",
         "linux.atspi.live_external_client.table",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Surface_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.surface",
         "linux.atspi.live_external_client.surface",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation
      return Boolean is
     (Has_Observation
        ("linux.atspi.live_external_client.live_region",
         "linux.atspi.live_external_client.live_region",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Session_Startup_Stage_Observation return Boolean is
     (Has_Observation
        ("linux.atspi.session_startup_stage",
         "linux.atspi.session_startup_stage",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Startup_Object_Path_Observation return Boolean is
     (Has_Observation
        ("native.linux_atspi_startup_object_path",
         "linux.atspi.startup_object_path",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Prepared_Status_Observation return Boolean is
     (Has_Observation
        ("native.event_prepared_status",
         "native.event.prepared_status",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Event_Posting_Interest_Observation return Boolean is
     (Has_Observation
        ("native.event_posting_interest",
         "native.event.posting_interest",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Event_Validation_Observation return Boolean is
     (Has_Observation
        ("native.event_validation",
         "native.event.validation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Event_Posting_Boundary_Observation return Boolean is
     (Has_Observation
        ("native.event_posting_boundary",
         "native.event.posting_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Event_Exhaustive_Map_Observation return Boolean is
     (Has_Observation
        ("native.event_exhaustive_map",
         "native.event.exhaustive_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Role_Exhaustive_Map_Observation return Boolean is
     (Has_Observation
        ("native.role_exhaustive_map",
         "native.role.exhaustive_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Relation_Exhaustive_Map_Observation return Boolean is
     (Has_Observation
        ("native.relation_exhaustive_map",
         "native.relation.exhaustive_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Method_Return_Decode_Observation return Boolean is
     (Has_Observation
        ("native.method_return_decode",
         "linux.dbus.method_return_decode",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Error_Return_Decode_Observation return Boolean is
     (Has_Observation
        ("native.error_return_decode",
         "linux.dbus.error_return_decode",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Error_Return_Diagnostic_Observation return Boolean is
     (Has_Observation
        ("native.error_return_diagnostic",
         "linux.dbus.error_return_diagnostic",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Startup_Error_Completion_Observation return Boolean is
     (Has_Observation
        ("native.startup_error_completion",
         "linux.dbus.startup_error_completion",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Incoming_Packet_Classification_Observation return Boolean is
     (Has_Observation
        ("native.incoming_packet_classification",
         "linux.dbus.incoming_packet_classification",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Registry_Observation return Boolean is
     (Has_Observation
        ("native.object_registry",
         "native.object_cache.identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Export_Descriptor_Observation return Boolean is
     (Has_Observation
        ("native.export_descriptor",
         "native.object_export_descriptor",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Host_Window_Root_Binding_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.host_window_root_binding",
         "windows.uia.host_window_root_binding",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_VTable_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_com_vtable",
         "windows.uia.com_vtable_descriptor",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Object_Export_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_com_object_export",
         "windows.uia.com_object_export",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Export_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_export",
         "windows.uia.com_live_export",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Bridge_Audit_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_bridge_audit",
         "windows.uia.bridge_audit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Interface_Retain_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_interface_retain",
         "windows.uia.com_live.interface_retain",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Interface_Release_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_interface_release",
         "windows.uia.com_live.interface_release",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Released_Interface_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_released_interface",
         "windows.uia.com_live.released_interface",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_invalid_interface_frame",
         "windows.uia.com_live.invalid_interface_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_invalid_method_frame",
         "windows.uia.com_live.invalid_method_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_interface_method_mismatch",
         "windows.uia.com_live.interface_method_mismatch",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Registered_Routed_Error_Status_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_registered_routed_error_status",
         "native.boundary.native_call_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.simple_property_frame",
         "windows.uia.com_live.simple_property_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.fragment_action_frame",
         "windows.uia.com_live.fragment_action_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_fragment_navigate",
         "windows.uia.com_live.fragment_navigate",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.fragment_last_child_frame",
         "windows.uia.com_live.fragment_last_child_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_com_live_fragment_runtime_id",
         "windows.uia.com_live.fragment_runtime_id",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.embedded_fragment_roots_frame",
         "windows.uia.com_live.embedded_fragment_roots",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Provider_Options_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.provider_options_frame",
         "windows.uia.com_live.provider_options",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.host_raw_element_provider_frame",
         "windows.uia.com_live.host_raw_element_provider",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.pattern_provider_frame",
         "windows.uia.com_live.pattern_provider_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.bounding_rectangle_frame",
         "windows.uia.com_live.bounding_rectangle_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Root_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.fragment_root_frame",
         "windows.uia.com_live.fragment_root",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.fragment_root_point_frame",
         "windows.uia.com_live.fragment_root_point",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.fragment_root_focus_frame",
         "windows.uia.com_live.fragment_root_focus",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.com_live_chain",
         "windows.uia.com_live_export",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Public_Root_Export_Path_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.public_root_export.path",
         "windows.uia.public_root_export",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Public_Root_Native_Identity_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.public_root.native_identity",
         "windows.uia.public_root.native_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation);

   function Has_Windows_UIA_External_Client_Provider_Options_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Provider_Options_Observation);

   function Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation);

   function Has_Windows_UIA_External_Client_Fragment_Root_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Fragment_Root_Observation);

   function Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation);

   function Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation);

   function Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation);

   function Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation);

   function Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation);

   function Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation);

   function Has_Windows_UIA_External_Client_Full_Frame_Callback_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.full_frame_callback",
         "windows.uia.bridge_audit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_External_Client_Action_Frame_Observation
      return Boolean is
     (Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation);

   function Has_Windows_UIA_External_Client_Failure_Stage_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.failure_stage",
         "windows.uia.external_client.failure_stage",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_External_Client_Metadata_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.metadata",
         "windows.uia.metadata_properties",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_External_Client_Metadata_Group_Observation
      return Boolean is
     (Has_Windows_UIA_External_Client_Metadata_Observation);

   function Has_Windows_UIA_External_Client_Protected_Value_Observation
      return Boolean is
     (Has_Observation
        ("windows.uia.external_client.protected_value",
         "windows.uia.protected_value_text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_External_Client_Privacy_Boundary_Observation
      return Boolean is
     (Has_Windows_UIA_External_Client_Protected_Value_Observation);

   function Has_Windows_UIA_Internal_Native_Export_Chain_Ready
     return Boolean is
     (Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
      and then Has_Windows_UIA_Public_Root_Export_Path_Observation
      and then Has_Windows_UIA_Public_Root_Native_Identity_Observation
      and then
        Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
      and then
        Has_Windows_UIA_External_Client_Provider_Options_Observation
      and then
        Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
      and then Has_Windows_UIA_External_Client_Fragment_Root_Observation
      and then Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
      and then Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
      and then
        Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
      and then
        Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
      and then
        Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
      and then
        Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
      and then
        Has_Windows_UIA_External_Client_Full_Frame_Callback_Observation
      and then Has_Windows_UIA_External_Client_Action_Frame_Observation
      and then Has_Windows_UIA_External_Client_Metadata_Group_Observation
      and then Has_Windows_UIA_External_Client_Privacy_Boundary_Observation);

   function Has_MacOS_NSAX_Main_Thread_Binding_Observation return Boolean is
     (Has_Observation
        ("macos.nsax.main_thread_binding",
         "macos.nsaccessibility.main_thread_binding",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Native_View_Binding_Observation return Boolean is
     (Has_Observation
        ("macos.nsax.native_view_binding",
         "macos.nsaccessibility.native_view_binding",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Attribute_Value_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_selector_attribute_value",
         "macos.nsaccessibility.selector.attribute_value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Children_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.children_frame",
         "macos.nsaccessibility.selector.children_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.child_at_index_frame",
         "macos.nsaccessibility.selector.child_at_index_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.attribute_value_frame",
         "macos.nsaccessibility.selector.attribute_value_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.attribute_settable_frame",
         "macos.nsaccessibility.selector.attribute_settable_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Action_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.action_frame",
         "macos.nsaccessibility.selector.action_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Unsupported_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_selector_unsupported",
         "macos.nsaccessibility.selector.unsupported",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_selector_main_thread_gate",
         "macos.nsaccessibility.selector.main_thread_gate",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_registered_method_family_mismatch",
         "macos.nsaccessibility.registered_method_family_mismatch",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Registered_Routed_Error_Status_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_registered_routed_error_status",
         "native.boundary.native_call_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Released_Boundary_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_released_boundary",
         "macos.nsaccessibility.released_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Bridge_Audit_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_bridge_audit",
         "macos.nsaccessibility.bridge_audit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Virtual_Element_Bridge_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.virtual_element_bridge",
         "macos.nsaccessibility.virtual_element_bridge",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_External_Client_Element_Chain_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.element_chain",
         "macos.nsaccessibility.hierarchy",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Public_Root_Export_Path_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.public_root_export.path",
         "macos.nsaccessibility.public_root_export",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Public_Root_Native_Identity_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.public_root.native_identity",
         "macos.nsaccessibility.public_root.native_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.public_root.hit_test_frame",
         "macos.nsaccessibility.public_root.hit_test_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.public_root.focused_element_frame",
         "macos.nsaccessibility.public_root.focused_element_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.public_root.notification_frame",
         "macos.nsaccessibility.public_root.notification_frame",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation
      return Boolean is
     (Has_MacOS_NSAX_Main_Thread_Binding_Observation);

   function Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation
      return Boolean is
     (Has_MacOS_NSAX_Native_View_Binding_Observation);

   function Has_MacOS_NSAX_External_Client_Children_Frame_Observation
      return Boolean is
     (Has_MacOS_NSAX_Selector_Children_Frame_Observation);

   function Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
      return Boolean is
     (Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation);

   function Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
      return Boolean is
     (Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation);

   function Has_MacOS_NSAX_External_Client_Action_Frame_Observation
      return Boolean is
     (Has_MacOS_NSAX_Selector_Action_Frame_Observation);

   function Has_MacOS_NSAX_External_Client_Failure_Stage_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.failure_stage",
         "macos.nsaccessibility.external_client.failure_stage",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_External_Client_Metadata_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.metadata",
         "macos.nsaccessibility.metadata_attributes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_External_Client_Metadata_Group_Observation
      return Boolean is
     (Has_MacOS_NSAX_External_Client_Metadata_Observation);

   function Has_MacOS_NSAX_External_Client_Protected_Value_Observation
      return Boolean is
     (Has_Observation
        ("macos.nsax.external_client.protected_value",
         "macos.nsaccessibility.protected_value_text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation
      return Boolean is
     (Has_MacOS_NSAX_External_Client_Protected_Value_Observation);

   function Has_MacOS_NSAX_Internal_Native_Export_Chain_Ready
     return Boolean is
     (Has_MacOS_NSAX_External_Client_Element_Chain_Observation
      and then Has_MacOS_NSAX_Public_Root_Export_Path_Observation
      and then Has_MacOS_NSAX_Public_Root_Native_Identity_Observation
     and then Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation
     and then Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation
     and then Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation
      and then Has_MacOS_NSAX_Virtual_Element_Bridge_Observation
      and then Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation
      and then Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation
      and then Has_MacOS_NSAX_External_Client_Children_Frame_Observation
      and then
        Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
      and then
        Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
      and then Has_MacOS_NSAX_External_Client_Action_Frame_Observation
      and then Has_MacOS_NSAX_External_Client_Metadata_Group_Observation
      and then Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation);

   function Has_Native_Node_Index_Observation return Boolean is
     (Has_Observation
        ("native.node_index",
         "native.object_cache.node_index",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Cache_Tombstone_Observation return Boolean is
     (Has_Observation
        ("native.cache_tombstone",
         "native.object_cache.tombstone",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Cache_Session_Scope_Observation return Boolean is
     (Has_Observation
        ("native.cache_session_scope",
         "native.object_cache.session_scope",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Runtime_Lifecycle_Observation return Boolean is
     (Has_Observation
        ("native.runtime_lifecycle",
         "native.runtime.lifecycle",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Runtime_Lifecycle_Report_Observation return Boolean is
     (Has_Observation
        ("native.runtime_lifecycle_report",
         "native.runtime.lifecycle_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Runtime_Probe_Failure_Stage_Observation
      return Boolean is
     (Has_Observation
        ("native.runtime_probe_failure_stage",
         "native.runtime.probe_failure_stage",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Runtime_Event_Application_Observation return Boolean is
     (Has_Observation
        ("native.runtime_event_application",
         "native.runtime.event_application",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Runtime_Event_Preparation_Observation return Boolean is
     (Has_Observation
        ("native.runtime_event_preparation",
         "native.runtime.event_preparation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Runtime_Event_Preparation_Report_Observation
      return Boolean is
     (Has_Observation
        ("native.runtime_event_preparation_report",
         "native.runtime.event_preparation_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Projection_Property_Observation return Boolean is
     (Has_Observation
        ("native.projection_property",
         "native.projection.property",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Projection_Action_Observation return Boolean is
     (Has_Observation
        ("native.projection_action",
         "native.projection.action",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Projection_Relation_Observation return Boolean is
     (Has_Observation
        ("native.projection_relation",
         "native.projection.relation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Projection_Event_Source_Observation return Boolean is
     (Has_Observation
        ("native.projection_event_source",
         "native.projection.event_source",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Deterministic_Shutdown_Observation return Boolean is
     (Has_Observation
        ("native.deterministic_shutdown",
         "backend.native.deterministic_shutdown",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Diagnostics_Bounded_Observation return Boolean is
     (Has_Observation
        ("native.diagnostics_bounded",
         "backend.diagnostics.bounded",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Diagnostics_Result_Mapping_Observation return Boolean is
     (Has_Observation
        ("native.diagnostics_result",
         "diagnostics.result_mapping",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Diagnostics_Field_Bounds_Observation return Boolean is
     (Has_Observation
        ("native.diagnostics_fields",
         "diagnostics.field_bounds",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Resource_Limit_Observation return Boolean is
     (Has_Observation
        ("native.resource_limit",
         "native.object_cache.resource_limit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Value_Resource_Limit_Observation return Boolean is
     (Has_Observation
        ("native.value_resource_limit",
         "native.value.resource_limit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Hostile_Identity_Observation return Boolean is
     (Has_Observation
        ("native.hostile_identity",
         "native.boundary.identity_admission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Boundary_Admission_Report_Observation return Boolean is
     (Has_Observation
        ("native.boundary_admission_report",
         "native.boundary.admission_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Boundary_Native_Call_Report_Observation return Boolean is
     (Has_Observation
        ("native.boundary_native_call_report",
         "native.boundary.native_call_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Boundary_Completion_Report_Observation return Boolean is
     (Has_Observation
        ("native.boundary_completion_report",
         "native.boundary.completion_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Native_Boundary_Release_Report_Observation return Boolean is
     (Has_Observation
        ("native.boundary_release_report",
         "native.boundary.release_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Malformed_Request_Observation return Boolean is
     (Has_Observation
        ("native.malformed_request",
         "native.boundary.error_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_Error_Name_Map_Observation return Boolean is
     (Has_Observation
        ("native.linux_error_name_map",
         "linux.atspi.error_name_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_Error_Name_Inverse_Map_Observation return Boolean is
     (Has_Observation
        ("native.linux_error_name_inverse",
         "linux.atspi.error_name_inverse_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_Error_Name_Diagnostic_Observation return Boolean is
     (Has_Observation
        ("native.linux_error_name_diagnostic",
         "linux.atspi.error_name_diagnostic",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Core_Method_Observations return Boolean is
     (Has_Observation
        ("native.linux_atspi_role_map",
         "linux.atspi.role_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_state_map",
         "linux.atspi.state_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_object_path",
         "linux.atspi.object_path",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_method_router",
         "linux.atspi.method_router",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_application_id",
         "linux.atspi.application.id",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_application_metadata",
         "linux.atspi.application.metadata",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_accessible_role",
         "linux.atspi.accessible.role",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_accessible_state",
         "linux.atspi.accessible.state",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_accessible_name",
         "linux.atspi.accessible.name",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_accessible_description",
         "linux.atspi.accessible.description",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_accessible_child_count",
         "linux.atspi.accessible.child_count",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_accessible_relations",
        "linux.atspi.accessible.relations",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Interaction_Method_Observations return Boolean is
     (Has_Observation
        ("native.linux_atspi_component_extents",
         "linux.atspi.component.extents",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_component_contains",
         "linux.atspi.component.contains",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_component_hit_test",
         "linux.atspi.component.hit_test",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Linux_ATSPI_Component_Focus_Observation
      and then Has_Observation
        ("native.linux_atspi_action_count",
         "linux.atspi.action.count",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_action_name",
         "linux.atspi.action.name",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_action_invoke",
         "linux.atspi.action.invoke",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_value_current",
         "linux.atspi.value.current",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_value_range",
         "linux.atspi.value.range",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_value_set_request",
         "linux.atspi.value.set_request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_selection_count",
         "linux.atspi.selection.count",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_selection_selected_child",
         "linux.atspi.selection.selected_child",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_selection_request",
        "linux.atspi.selection.request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Linux_ATSPI_Selection_Deselect_Observation
      and then Has_Linux_ATSPI_Selection_Select_All_Observation
      and then Has_Linux_ATSPI_Selection_Clear_Observation);

   function Has_Linux_ATSPI_Component_Focus_Observation return Boolean is
     (Has_Observation
        ("native.linux_atspi_component_focus",
         "linux.atspi.component.focus",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Selection_Deselect_Observation return Boolean is
     (Has_Observation
        ("native.linux_atspi_selection_deselect",
         "linux.atspi.selection.deselect_child",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Selection_Select_All_Observation return Boolean is
     (Has_Observation
        ("native.linux_atspi_selection_select_all",
         "linux.atspi.selection.select_all",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Selection_Clear_Observation return Boolean is
     (Has_Observation
        ("native.linux_atspi_selection_clear",
         "linux.atspi.selection.clear_selection",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Content_Method_Observations return Boolean is
     (Has_Observation
        ("native.linux_atspi_text_character_count",
         "linux.atspi.text.character_count",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_text_range",
         "linux.atspi.text.range",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_text_caret",
         "linux.atspi.text.caret",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_text_protected",
         "linux.atspi.text.protected",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_text_edit_request",
         "linux.atspi.text.edit_request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_table_dimensions",
         "linux.atspi.table.dimensions",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_table_cell",
         "linux.atspi.table.cell",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_table_cell_span",
         "linux.atspi.table.cell_span",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_image_description",
         "linux.atspi.image.description",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_image_size",
         "linux.atspi.image.size",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_image_decorative_omission",
        "linux.atspi.image.decorative_omission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Document_Surface_Event_Observations
      return Boolean is
     (Has_Observation
        ("native.linux_atspi_document_locale",
         "linux.atspi.document.locale",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_document_attributes",
         "linux.atspi.document.attributes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_document_heading_level",
         "linux.atspi.document.heading_level",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_document_landmark",
         "linux.atspi.document.landmark",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_surface_metadata",
         "linux.atspi.surface.metadata",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_surface_routing",
         "linux.atspi.surface_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_signal_focus",
         "linux.atspi.signal.focus",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_signal_text",
         "linux.atspi.signal.text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_signal_lifecycle",
         "linux.atspi.signal.lifecycle",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_signal_prepared_publication",
         "linux.atspi.signal.prepared_publication",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_atspi_cache_node",
         "linux.atspi.cache.node",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Unsupported_Value_Observation return Boolean is
     (Has_Observation
        ("native.linux_dbus_unsupported_value",
         "linux.dbus.unsupported_value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_UInt32_Array_Value_Observation return Boolean is
     (Has_Observation
        ("native.linux_dbus_uint32_array_value",
         "linux.dbus.uint32_array_value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_State_Set_UInt32_Array_Observation return Boolean is
     (Has_Observation
        ("native.linux_state_set_uint32_array",
         "linux.dbus.state_set_uint32_array",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_String_Array_Value_Observation return Boolean is
     (Has_Observation
        ("native.linux_dbus_string_array_value",
         "linux.dbus.string_array_value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Attribute_String_Array_Observation return Boolean is
     (Has_Observation
        ("native.linux_attribute_string_array",
         "linux.dbus.attribute_string_array",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Cache_Interface_String_Array_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_cache_interface_array",
         "linux.dbus.cache_interface_string_array",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Object_Path_Array_Value_Observation return Boolean is
     (Has_Observation
        ("native.linux_dbus_object_path_array",
         "linux.dbus.object_path_array_value",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_relation_target_object_paths",
         "linux.dbus.relation_target_object_path_array",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_HResult_Map_Observation return Boolean is
     (Has_Observation
        ("native.windows_hresult_map",
         "windows.uia.hresult_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_HResult_Inverse_Map_Observation return Boolean is
     (Has_Observation
        ("native.windows_hresult_inverse",
         "windows.uia.hresult_inverse_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_HResult_Diagnostic_Observation return Boolean is
     (Has_Observation
        ("native.windows_hresult_diagnostic",
         "windows.uia.hresult_diagnostic",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Event_Posting_Admission_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_event_posting_admission",
         "windows.uia.event_posting_admission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Event_Posting_Report_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_event_posting_report",
         "windows.uia.event_posting_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_event_posting_drain_bounded",
         "windows.uia.event_posting_drain_bounded",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Native_Focus_Query_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_native_focus_query",
         "native.boundary.focus_call",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Native_Set_Focus_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_native_set_focus",
         "native.boundary.focus_call",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Hostile_Callback_Admission_Observation
      return Boolean is
     (Has_Observation
        ("native.windows_uia_hostile_callback_admission",
         "windows.uia.native_callback.hostile_admission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Missing_Identity_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_missing_identity",
         "windows.uia.native_callback.missing_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Mismatched_Identity_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_mismatched_identity",
         "windows.uia.native_callback.mismatched_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Malformed_Identity_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_malformed_identity",
         "windows.uia.native_callback.malformed_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Text_Payload_Limit_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_text_payload_limit",
         "windows.uia.native_callback.text_payload_limit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Core_Routing_Observations return Boolean is
     (Has_Observation
        ("native.windows_uia_core_properties",
         "windows.uia.core_properties",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_bounds",
         "windows.uia.bounding_rectangle",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_textual_properties",
         "windows.uia.textual_properties",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Windows_UIA_Metadata_Property_Observation
      and then Has_Windows_UIA_Protected_Value_Observation
      and then Has_Observation
        ("native.windows_uia_action_map",
         "windows.uia.action_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_action_request",
         "windows.uia.action.request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_set_focus",
         "windows.uia.action.set_focus",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Windows_UIA_Native_Focus_Query_Observation
      and then Has_Windows_UIA_Native_Set_Focus_Observation
      and then Has_Observation
        ("native.windows_uia_open",
         "windows.uia.action.open",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_scroll",
         "windows.uia.action.scroll_into_view",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_close",
         "windows.uia.action.close",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_event_map",
         "windows.uia.event_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_event_details",
         "windows.uia.event_details",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_prepared_emission",
         "windows.uia.prepared_event_emission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_event_build_report",
         "windows.uia.event.build_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_prepared_routing",
         "windows.uia.prepared_event_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_prepared_boundary",
         "windows.uia.prepared_event_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_fragment_navigation",
         "windows.uia.fragment.navigation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_runtime_id",
         "windows.uia.runtime_id",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_relation_routing",
         "windows.uia.relation_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Metadata_Property_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_metadata_properties",
         "windows.uia.metadata_properties",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Protected_Value_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_protected_value_text",
         "windows.uia.protected_value_text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Advanced_Routing_Observations return Boolean is
     (Has_Observation
        ("native.windows_uia_value_routing",
         "windows.uia.value_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_value_set",
         "windows.uia.value.set_request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_selection_routing",
         "windows.uia.selection_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_selection_request",
         "windows.uia.selection.request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_selection_select_all",
         "windows.uia.selection.select_all",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_selection_clear",
         "windows.uia.selection.clear_selection",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_text_routing",
         "windows.uia.text_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_text_edit",
         "windows.uia.text_edit_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_table_routing",
         "windows.uia.table_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_image_routing",
         "windows.uia.image_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_document_routing",
         "windows.uia.document_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_surface_routing",
         "windows.uia.surface_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_request_router",
         "windows.uia.request_router",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_provider_boundary",
         "windows.uia.provider_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_provider_registry",
         "windows.uia.provider_registry",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_com_lifetime",
         "windows.uia.com_lifetime",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_com_export",
         "windows.uia.com_export_descriptor",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.windows_uia_native_values",
         "windows.uia.native_values",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_Native_Status_Map_Observation return Boolean is
     (Has_Observation
        ("native.macos_status_map",
         "macos.nsaccessibility.native_status_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Selection_Select_All_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_selection_select_all",
         "windows.uia.selection.select_all",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Windows_UIA_Selection_Clear_Observation return Boolean is
     (Has_Observation
        ("native.windows_uia_selection_clear",
         "windows.uia.selection.clear_selection",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_Native_Status_Inverse_Map_Observation return Boolean is
     (Has_Observation
        ("native.macos_status_inverse",
         "macos.nsaccessibility.native_status_inverse_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_Native_Status_Diagnostic_Observation return Boolean is
     (Has_Observation
        ("native.macos_status_diagnostic",
         "macos.nsaccessibility.native_status_diagnostic",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Event_Posting_Admission_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_event_posting_admission",
         "macos.nsaccessibility.event_posting_admission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Event_Posting_Report_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_event_posting_report",
         "macos.nsaccessibility.event_posting_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_event_posting_drain_bounded",
         "macos.nsaccessibility.event_posting_drain_bounded",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Native_Focus_Query_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_native_focus_query",
         "native.boundary.focus_call",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Native_Set_Focus_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_native_set_focus",
         "native.boundary.focus_call",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Hostile_Callback_Admission_Observation
      return Boolean is
     (Has_Observation
        ("native.macos_nsax_hostile_callback_admission",
         "macos.nsaccessibility.native_callback.hostile_admission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Missing_Identity_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_missing_identity",
         "macos.nsaccessibility.native_callback.missing_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Mismatched_Identity_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_mismatched_identity",
         "macos.nsaccessibility.native_callback.mismatched_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Malformed_Identity_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_malformed_identity",
         "macos.nsaccessibility.native_callback.malformed_identity",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Text_Payload_Limit_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_text_payload_limit",
         "macos.nsaccessibility.native_callback.text_payload_limit",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Core_Routing_Observations return Boolean is
     (Has_Observation
        ("native.macos_nsax_core_attributes",
         "macos.nsaccessibility.core_attributes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_attribute_names",
         "macos.nsaccessibility.attribute_names",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_frame",
         "macos.nsaccessibility.frame_attribute",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_textual_attributes",
         "macos.nsaccessibility.textual_attributes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_MacOS_NSAX_Metadata_Attribute_Observation
      and then Has_MacOS_NSAX_Protected_Value_Observation
      and then Has_Observation
        ("native.macos_nsax_action_map",
         "macos.nsaccessibility.action_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_action_request",
         "macos.nsaccessibility.action.request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_open",
         "macos.nsaccessibility.action.open",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_close",
         "macos.nsaccessibility.action.close",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_set_focus",
         "macos.nsaccessibility.action.set_focus",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_MacOS_NSAX_Native_Focus_Query_Observation
      and then Has_MacOS_NSAX_Native_Set_Focus_Observation
      and then Has_Observation
        ("native.macos_nsax_scroll_visible",
         "macos.nsaccessibility.action.scroll_to_visible",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_event_map",
         "macos.nsaccessibility.event_map",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_event_details",
         "macos.nsaccessibility.event_details",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_prepared_emission",
         "macos.nsaccessibility.prepared_event_emission",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_event_build_report",
         "macos.nsaccessibility.event.build_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_prepared_routing",
         "macos.nsaccessibility.prepared_event_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_prepared_boundary",
         "macos.nsaccessibility.prepared_event_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_hierarchy",
         "macos.nsaccessibility.hierarchy",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_element_id",
         "macos.nsaccessibility.element_id",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_relation_routing",
         "macos.nsaccessibility.relation_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Metadata_Attribute_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_metadata_attributes",
         "macos.nsaccessibility.metadata_attributes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Protected_Value_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_protected_value_text",
         "macos.nsaccessibility.protected_value_text",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Advanced_Routing_Observations return Boolean is
     (Has_Observation
        ("native.macos_nsax_value_routing",
         "macos.nsaccessibility.value_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_value_set",
         "macos.nsaccessibility.value.set_request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_selection_routing",
         "macos.nsaccessibility.selection_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_selection_request",
         "macos.nsaccessibility.selection.request",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_selection_select_all",
         "macos.nsaccessibility.selection.select_all",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_selection_clear",
         "macos.nsaccessibility.selection.clear_selection",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_text_routing",
         "macos.nsaccessibility.text_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_text_edit",
         "macos.nsaccessibility.text_edit_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_table_routing",
         "macos.nsaccessibility.table_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_image_routing",
         "macos.nsaccessibility.image_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_document_routing",
         "macos.nsaccessibility.document_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_surface_routing",
         "macos.nsaccessibility.surface_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_request_router",
         "macos.nsaccessibility.request_router",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_provider_boundary",
         "macos.nsaccessibility.provider_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_element_registry",
         "macos.nsaccessibility.element_registry",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_element_lifetime",
         "macos.nsaccessibility.element_lifetime",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_element_export",
         "macos.nsaccessibility.element_export_descriptor",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.macos_nsax_native_values",
         "macos.nsaccessibility.native_values",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selection_Select_All_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_selection_select_all",
         "macos.nsaccessibility.selection.select_all",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_MacOS_NSAX_Selection_Clear_Observation return Boolean is
     (Has_Observation
        ("native.macos_nsax_selection_clear",
         "macos.nsaccessibility.selection.clear_selection",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Startup_Outgoing_Work_Observation return Boolean is
     (Has_Observation
        ("native.startup_outgoing_work",
         "linux.dbus.startup_outgoing_work",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Startup_Event_Loop_Interest_Observation return Boolean is
     (Has_Observation
        ("native.startup_loop_interest",
         "linux.dbus.startup_event_loop_interest",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Startup_Event_Loop_Operation_Observation return Boolean is
     (Has_Observation
        ("native.startup_next_operation",
         "linux.dbus.startup_event_loop_operation",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

  function Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_backend_session_loop",
         "linux.dbus.backend_session_event_loop_step",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_backend_session_loop_status",
         "linux.dbus.backend_session_event_loop_step",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_backend_session_transport_cycle",
         "linux.dbus.backend_session_transport_cycle_scheduler",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_backend_session_transport_cycle_status",
         "linux.dbus.backend_session_transport_cycle_scheduler",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_backend_session_transport_cycle_write_wait",
         "linux.dbus.backend_session_transport_cycle_scheduler",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_backend_session_transport_cycle_after",
         "linux.dbus.backend_session_transport_cycle_scheduler",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application)
      and then Has_Observation
        ("native.linux_backend_session_transport_cycle_packet",
         "linux.dbus.backend_session_transport_cycle_scheduler",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_session_dispatch_loop_report",
         "linux.atspi.session_dispatch.loop_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Startup_Outgoing_Flush_Observation return Boolean is
     (Has_Observation
        ("native.startup_outgoing_flush",
         "linux.dbus.startup_outgoing_flush",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Outgoing_Back_Pressure_Observation return Boolean is
     (Has_Observation
        ("native.linux_outgoing_back_pressure",
         "linux.dbus.outgoing_back_pressure",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Connection_Lifecycle_Observation return Boolean is
     (Has_Observation
        ("native.linux_connection_lifecycle",
         "linux.dbus.connection_lifecycle",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Local_Channel_Adapter_Observation return Boolean is
     (Has_Observation
        ("native.linux_local_channel_adapter",
         "linux.dbus.local_channel_adapter",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Local_Channel_Receive_Observation return Boolean is
     (Has_Observation
        ("native.linux_local_channel_receive",
         "linux.dbus.local_channel_receive",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Controller_Observation return Boolean is
     (Has_Observation
        ("native.linux_startup_controller",
         "linux.dbus.startup_controller",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Backend_Adapter_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_startup_backend_adapter",
         "linux.dbus.startup_backend_adapter",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Pump_Observation return Boolean is
     (Has_Observation
        ("native.linux_startup_pump",
         "linux.dbus.startup_pump",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Pump_Report_Observation return Boolean is
     (Has_Observation
        ("native.linux_startup_pump_report",
         "linux.dbus.startup_pump_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_startup_pump_bounded_report",
         "linux.dbus.startup_pump_bounded_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Pump_Bounds_Observation return Boolean is
     (Has_Observation
        ("native.linux_startup_pump_bounds",
         "linux.dbus.startup_pump_bounds",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Registered_Pump_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_registered_pump",
         "linux.dbus.startup_registered_pump",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Bus_Address_Observation return Boolean is
     (Has_Observation
        ("native.linux_bus_address",
         "linux.dbus.bus_address",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Auth_External_Observation return Boolean is
     (Has_Observation
        ("native.linux_auth_external",
         "linux.dbus.auth_external",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Auth_Exchange_Observation return Boolean is
     (Has_Observation
        ("native.linux_auth_exchange",
         "linux.dbus.auth_exchange",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Authenticated_Connect_Observation return Boolean is
     (Has_Observation
        ("native.linux_authenticated_connect",
         "linux.dbus.authenticated_connect",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Hello_Observation return Boolean is
     (Has_Observation
        ("native.linux_hello",
         "linux.dbus.hello",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Authenticated_Hello_Observation return Boolean is
     (Has_Observation
        ("native.linux_authenticated_hello",
         "linux.dbus.authenticated_hello",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Registration_Completion_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_registration_completion",
         "linux.dbus.registration_completion",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Authenticated_Registration_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_authenticated_registration",
         "linux.dbus.authenticated_registration",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Reply_Evidence_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_startup_reply_evidence",
         "linux.dbus.startup_reply_evidence",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Application_Registration_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_application_registration",
         "linux.dbus.application_registration",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_live_transport_registration",
         "linux.atspi.live_transport.registration_observed",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Address_Discovery_Observation return Boolean is
     (Has_Observation
        ("native.linux_address_discovery",
         "linux.dbus.address_discovery",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Host_Environment_Startup_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_host_environment_startup",
         "linux.dbus.host_environment_startup",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_A11y_Bus_Get_Address_Observation return Boolean is
     (Has_Observation
        ("native.linux_a11y_bus_get_address",
         "linux.dbus.a11y_bus_get_address",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Authenticated_Get_Address_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_authenticated_get_address",
         "linux.dbus.authenticated_get_address",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Startup_Session_Discovery_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_startup_session_discovery",
         "linux.dbus.startup_session_discovery",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Frame_Metadata_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_transport_frame_metadata",
         "linux.dbus.transport_frame_metadata",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Method_Call_Destination_Routing_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_method_call_destination_routing",
         "linux.dbus.method_call_destination_routing",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Frame_Bytes_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_transport_frame_bytes",
         "linux.dbus.transport_frame_bytes",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Frame_Send_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_transport_frame_send",
         "linux.dbus.transport_frame_send",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Packet_Observation return Boolean is
     (Has_Observation
        ("native.linux_transport_packet",
         "linux.dbus.transport_packet",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Packet_Send_Observation return Boolean is
     (Has_Observation
        ("native.linux_transport_packet_send",
         "linux.dbus.transport_packet_send",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Packet_Decode_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_transport_packet_decode",
         "linux.dbus.transport_packet_decode",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Codec_Basic_Observation return Boolean is
     (Has_Observation
        ("native.linux_dbus_codec_basic",
         "linux.dbus.codec.basic",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Resource_Limits_Observation return Boolean is
     (Has_Observation
        ("native.linux_dbus_resource_limits",
         "linux.dbus.resource_limits",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Message_Envelope_Observation return Boolean is
     (Has_Observation
        ("native.linux_message_envelope",
         "linux.dbus.message_envelope",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Method_Call_Envelope_Observation return Boolean is
     (Has_Observation
        ("native.linux_method_call_envelope",
         "linux.dbus.method_call_envelope",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Transport_Envelope_Decode_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_transport_envelope_decode",
         "linux.dbus.transport_envelope_decode",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Incoming_Call_Decode_Observation return Boolean is
     (Has_Observation
        ("native.linux_incoming_call_decode",
         "linux.dbus.incoming_call_decode",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Signal_Envelope_Observation return Boolean is
     (Has_Observation
        ("native.linux_signal_envelope",
         "linux.dbus.signal_envelope",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Prepared_Signal_Envelope_Observation
      return Boolean is
     (Has_Observation
        ("native.linux_prepared_signal_envelope",
         "linux.dbus.prepared_signal_envelope",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_ATSPI_Signal_Build_Report_Observation return Boolean is
     (Has_Observation
        ("native.linux_atspi_signal_build_report",
         "linux.atspi.signal.build_report",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Linux_DBus_Method_Boundary_Observation return Boolean is
     (Has_Observation
        ("native.linux_method_boundary",
         "linux.dbus.method_boundary",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Focus_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.focus_target"
           and then Trimmed (Observation.Conformance_Id) =
             "events.focus.payload"
           and then Observation.Node = A11y_Test_Fixtures.Button_Id
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Focus_Observation;

   function Has_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.default_action",
         "actions.press",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button)
      and then Has_Observation
        ("fixture.open_action",
         "actions.open",
         A11y_Test_Fixtures.Link_Id,
         A11y.Roles.Link)
      and then Has_Observation
        ("fixture.close_action",
         "actions.close",
         A11y_Test_Fixtures.Modal_Surface_Id,
         A11y.Roles.Dialog)
      and then Has_Observation
        ("fixture.scroll_action",
         "actions.scroll_into_view",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item)
      and then Has_Observation
        ("fixture.expand_action",
         "actions.expand",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item)
      and then Has_Observation
        ("fixture.collapse_action",
         "actions.collapse",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item)
      and then Has_Observation
        ("fixture.show_menu_action",
         "actions.show_menu",
         A11y_Test_Fixtures.Combo_Box_Id,
         A11y.Roles.Combo_Box)
      and then Has_Observation
        ("fixture.dismiss_action",
         "actions.dismiss",
         A11y_Test_Fixtures.Popup_Id,
         A11y.Roles.Dialog)
      and then Has_Observation
        ("fixture.set_focus_action",
         "actions.set_focus",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field));

   function Has_Activate_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.activate_action",
         "actions.activate",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Toggle_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.toggle_action",
         "actions.toggle",
         A11y_Test_Fixtures.Toggle_Button_Id,
         A11y.Roles.Toggle_Button));

   function Has_Expand_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.expand_action",
         "actions.expand",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item));

   function Has_Collapse_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.collapse_action",
         "actions.collapse",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item));

   function Has_Show_Menu_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.show_menu_action",
         "actions.show_menu",
         A11y_Test_Fixtures.Combo_Box_Id,
         A11y.Roles.Combo_Box));

   function Has_Dismiss_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.dismiss_action",
         "actions.dismiss",
         A11y_Test_Fixtures.Popup_Id,
         A11y.Roles.Dialog));

   function Has_Open_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.open_action",
         "actions.open",
         A11y_Test_Fixtures.Link_Id,
         A11y.Roles.Link));

   function Has_Close_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.close_action",
         "actions.close",
         A11y_Test_Fixtures.Modal_Surface_Id,
         A11y.Roles.Dialog));

   function Has_Scroll_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.scroll_action",
         "actions.scroll_into_view",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item));

   function Has_Set_Focus_Action_Observation return Boolean is
     (Has_Observation
        ("fixture.set_focus_action",
         "actions.set_focus",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field));

   function Has_Action_Payload_Observation return Boolean is
     (Has_Observation
        ("native.action_payload",
         "native.request.action_payload",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Action_Request_Payload_Observation return Boolean is
     (Has_Observation
        ("native.action_request_payload",
         "native.request.action_payload",
         A11y.Node_Ids.No_Node,
         A11y.Roles.Application));

   function Has_Property_Change_Observation return Boolean is
     (Has_Observation
        ("fixture.property_change",
         "events.property.payload",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Orientation_Property_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.orientation_event",
         "events.property.orientation",
         A11y_Test_Fixtures.Slider_Id,
         A11y.Roles.Slider));

   function Has_Set_Position_Property_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.set_position_event",
         "events.property.set_position",
         A11y_Test_Fixtures.Destroyed_List_Item_Id,
         A11y.Roles.List_Item));

   function Has_Set_Size_Property_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.set_size_event",
         "events.property.set_size",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Hierarchical_Level_Property_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.hierarchical_event",
         "events.property.hierarchical_level",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item));

   function Has_Role_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.role_property",
         "core.property.role",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_State_Set_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.state_set_property",
         "core.property.state_set",
         A11y_Test_Fixtures.Toggle_Button_Id,
         A11y.Roles.Toggle_Button));

   function Has_Name_Observation return Boolean is
     (Has_Observation
        ("fixture.name_property",
         "core.property.name",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Description_Observation return Boolean is
     (Has_Observation
        ("fixture.description_property",
         "core.property.description",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Help_Text_Observation return Boolean is
     (Has_Observation
        ("fixture.help_text_property",
         "core.property.help_text",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Placeholder_Observation return Boolean is
     (Has_Observation
        ("fixture.placeholder_property",
         "core.property.placeholder",
         A11y_Test_Fixtures.Search_Field_Id,
         A11y.Roles.Search_Field));

   function Has_Value_Text_Observation return Boolean is
     (Has_Observation
        ("fixture.value_text_property",
         "core.property.value_text",
         A11y_Test_Fixtures.Progress_Bar_Id,
         A11y.Roles.Progress_Bar));

   function Has_Keyboard_Shortcut_Observation return Boolean is
     (Has_Observation
        ("fixture.keyboard_shortcut",
         "core.property.keyboard_shortcut",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Semantic_Identifier_Observation return Boolean is
     (Has_Observation
        ("fixture.semantic_identifier",
         "core.property.semantic_identifier",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Locale_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.locale_property",
         "core.property.locale",
         A11y_Test_Fixtures.Document_Id,
         A11y.Roles.Document));

   function Has_Visible_Title_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.visible_title_property",
         "core.property.visible_title",
         A11y_Test_Fixtures.Main_Window_Id,
         A11y.Roles.Window));

   function Has_Orientation_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.orientation_property",
         "core.property.orientation",
         A11y_Test_Fixtures.Slider_Id,
         A11y.Roles.Slider));

   function Has_Set_Position_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.set_position_property",
         "core.property.set_position",
         A11y_Test_Fixtures.Destroyed_List_Item_Id,
         A11y.Roles.List_Item));

   function Has_Set_Size_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.set_size_property",
         "core.property.set_size",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Hierarchical_Level_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.hierarchical_level_property",
         "core.property.hierarchical_level",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item));

   function Has_Heading_Level_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.heading_level_property",
         "core.property.heading_level",
         A11y_Test_Fixtures.Heading_Id,
         A11y.Roles.Heading));

   function Has_Landmark_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.landmark_property",
         "core.property.landmark",
         A11y_Test_Fixtures.Document_Id,
         A11y.Roles.Document));

   function Has_Bounds_Property_Observation return Boolean is
     (Has_Observation
        ("fixture.bounds_property",
         "core.property.bounds",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_State_Change_Observation return Boolean is
     (Has_Observation
        ("fixture.state_change",
         "events.state.payload",
         A11y_Test_Fixtures.Toggle_Button_Id,
         A11y.Roles.Toggle_Button));

   function Has_Bounds_Observation return Boolean is
     (Has_Observation
        ("fixture.bounds",
         "events.bounds.payload",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Hit_Test_Observation return Boolean is
     (Has_Observation
        ("fixture.hit_test",
         "native.boundary.component_call",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button));

   function Has_Tree_Change_Observation return Boolean is
     (Has_Observation
        ("fixture.tree_change",
         "events.tree.payload",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Window_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.window_event",
         "events.window.payload",
         A11y_Test_Fixtures.Modal_Surface_Id,
         A11y.Roles.Dialog));

   function Has_Value_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.slider_value"
           and then Trimmed (Observation.Conformance_Id) = "value.range"
           and then Observation.Node = A11y_Test_Fixtures.Slider_Id
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Value_Observation;

   function Has_Selection_Observation return Boolean is
     (Has_Observation
        ("fixture.list_selection",
         "selection.single",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Select_All_Observation return Boolean is
     (Has_Observation
        ("fixture.select_all",
         "selection.select_all",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Selection_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.selection_event",
         "events.selection.payload",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Active_Descendant_Observation return Boolean is
     (Has_Observation
        ("fixture.active_descendant",
         "relations.active_descendant",
         A11y_Test_Fixtures.Tree_Id,
         A11y.Roles.Tree));

   function Has_Active_Descendant_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.active_desc_event",
         "events.node_reference.payload",
         A11y_Test_Fixtures.Tree_Id,
         A11y.Roles.Tree));

   function Has_Current_Item_Observation return Boolean is
     (Has_Observation
        ("fixture.current_item",
         "selection.current_item",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Current_Item_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.current_item_event",
         "events.node_reference.payload",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List));

   function Has_Tree_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.tree",
         "core.role.tree",
         A11y_Test_Fixtures.Tree_Id,
         A11y.Roles.Tree));

   function Has_Tree_Item_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.tree_item",
         "core.role.tree_item",
         A11y_Test_Fixtures.Tree_Item_Id,
         A11y.Roles.Tree_Item));

   function Has_Menu_Bar_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.menu_bar",
         "core.role.menu_bar",
         A11y_Test_Fixtures.Menu_Bar_Id,
         A11y.Roles.Menu_Bar));

   function Has_Menu_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.menu",
         "core.role.menu",
         A11y_Test_Fixtures.Menu_Id,
         A11y.Roles.Menu));

   function Has_Menu_Item_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.menu_item",
         "core.role.menu_item",
         A11y_Test_Fixtures.Menu_Item_Id,
         A11y.Roles.Menu_Item));

   function Has_Tab_List_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.tab_list",
         "core.role.tab_list",
         A11y_Test_Fixtures.Tab_List_Id,
         A11y.Roles.Tab_List));

   function Has_Tab_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.tab",
         "core.role.tab",
         A11y_Test_Fixtures.Tab_Id,
         A11y.Roles.Tab));

   function Has_Tooltip_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.tooltip",
         "core.role.tooltip",
         A11y_Test_Fixtures.Tooltip_Id,
         A11y.Roles.Tooltip));

   function Has_Status_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.status_role",
         "core.role.status",
         A11y_Test_Fixtures.Live_Region_Id,
         A11y.Roles.Status));

   function Has_Image_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.image_role",
         "core.role.image",
         A11y_Test_Fixtures.Informative_Image_Id,
         A11y.Roles.Image));

   function Has_Decorative_Image_Role_Observation return Boolean is
     (Has_Observation
        ("fixture.decorative_image_role",
         "core.role.decorative_image",
         A11y_Test_Fixtures.Decorative_Image_Id,
         A11y.Roles.Image));

   function Has_Vertical_Slice_Role_Observations return Boolean is
     (Has_Observation
        ("fixture.application",
         "core.role.application",
         A11y_Test_Fixtures.Application_Id,
         A11y.Roles.Application)
      and then Has_Observation
        ("fixture.main_window",
         "core.role.window",
         A11y_Test_Fixtures.Main_Window_Id,
         A11y.Roles.Window)
      and then Has_Observation
        ("fixture.dialog",
         "core.role.dialog",
         A11y_Test_Fixtures.Dialog_Id,
         A11y.Roles.Dialog)
      and then Has_Observation
        ("fixture.group",
         "core.role.group",
         A11y_Test_Fixtures.Group_Id,
         A11y.Roles.Group)
      and then Has_Observation
        ("fixture.static_text",
         "core.role.static_text",
         A11y_Test_Fixtures.Static_Text_Id,
         A11y.Roles.Static_Text)
      and then Has_Observation
        ("fixture.button_role",
         "core.role.button",
         A11y_Test_Fixtures.Button_Id,
         A11y.Roles.Button)
      and then Has_Observation
        ("fixture.toggle_button",
         "core.role.toggle_button",
         A11y_Test_Fixtures.Toggle_Button_Id,
         A11y.Roles.Toggle_Button)
      and then Has_Observation
        ("fixture.check_box",
         "core.role.check_box",
         A11y_Test_Fixtures.Check_Box_Id,
         A11y.Roles.Check_Box)
      and then Has_Observation
        ("fixture.radio_button",
         "core.role.radio_button",
         A11y_Test_Fixtures.Radio_Button_Id,
         A11y.Roles.Radio_Button)
      and then Has_Observation
        ("fixture.text_field_role",
         "core.role.text_field",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field)
      and then Has_Observation
        ("fixture.password_field_role",
         "core.role.password_field",
         A11y_Test_Fixtures.Password_Field_Id,
         A11y.Roles.Password_Field)
      and then Has_Observation
        ("fixture.list_role",
         "core.role.list",
         A11y_Test_Fixtures.List_Id,
         A11y.Roles.List)
      and then Has_Observation
        ("fixture.list_item_role",
         "core.role.list_item",
         A11y_Test_Fixtures.Destroyed_List_Item_Id,
         A11y.Roles.List_Item)
      and then Has_Tree_Role_Observation
      and then Has_Tree_Item_Role_Observation
      and then Has_Menu_Bar_Role_Observation
      and then Has_Menu_Role_Observation
      and then Has_Menu_Item_Role_Observation
      and then Has_Tab_List_Role_Observation
      and then Has_Tab_Role_Observation
      and then Has_Image_Role_Observation
      and then Has_Tooltip_Role_Observation
      and then Has_Status_Role_Observation);

   function Has_Extended_Fixture_Role_Observations return Boolean is
     (Has_Vertical_Slice_Role_Observations
      and then Has_Observation
        ("fixture.progress_bar",
         "core.role.progress_bar",
         A11y_Test_Fixtures.Progress_Bar_Id,
         A11y.Roles.Progress_Bar)
      and then Has_Observation
        ("fixture.spin_button",
         "core.role.spin_button",
         A11y_Test_Fixtures.Spin_Button_Id,
         A11y.Roles.Spin_Button)
      and then Has_Observation
        ("fixture.table_role",
         "core.role.table",
         A11y_Test_Fixtures.Table_Id,
         A11y.Roles.Table)
      and then Has_Observation
        ("fixture.table_row",
         "core.role.row",
         A11y_Test_Fixtures.Table_Row_Id,
         A11y.Roles.Row)
      and then Has_Observation
        ("fixture.table_column",
         "core.role.column",
         A11y_Test_Fixtures.Table_Column_Id,
         A11y.Roles.Column)
      and then Has_Observation
        ("fixture.cell_role",
         "core.role.cell",
         A11y_Test_Fixtures.Table_Cell_Id,
         A11y.Roles.Cell)
      and then Has_Observation
        ("fixture.combo_box",
         "core.role.combo_box",
         A11y_Test_Fixtures.Combo_Box_Id,
         A11y.Roles.Combo_Box)
      and then Has_Observation
        ("fixture.search_field",
         "core.role.search_field",
         A11y_Test_Fixtures.Search_Field_Id,
         A11y.Roles.Search_Field)
      and then Has_Decorative_Image_Role_Observation
      and then Has_Observation
        ("fixture.heading_role",
         "core.role.heading",
         A11y_Test_Fixtures.Heading_Id,
         A11y.Roles.Heading)
      and then Has_Observation
        ("fixture.document_role",
         "core.role.document",
         A11y_Test_Fixtures.Document_Id,
         A11y.Roles.Document)
      and then Has_Observation
        ("fixture.paragraph_text_role",
         "core.role.text",
         A11y_Test_Fixtures.Paragraph_Id,
         A11y.Roles.Text)
      and then Has_Observation
        ("fixture.link_role",
         "core.role.link",
         A11y_Test_Fixtures.Link_Id,
         A11y.Roles.Link)
      and then Has_Observation
        ("fixture.alert_role",
         "core.role.alert",
         A11y_Test_Fixtures.Validation_Error_Id,
         A11y.Roles.Alert)
      and then Has_Observation
        ("fixture.popup_role",
         "core.role.popup_dialog",
         A11y_Test_Fixtures.Popup_Id,
         A11y.Roles.Dialog));

   function Has_Fixture_Command_Coverage return Boolean is
      Commands : constant A11y_Test_Fixtures.Command_Vectors.Vector :=
        A11y_Test_Fixtures.Script;
   begin
      if Natural (Commands.Length) /=
        Natural (A11y_Test_Fixtures.Script.Length)
        or else Natural (Commands.Length) <
          A11y_Test_Fixtures.Command_Kind'Pos
            (A11y_Test_Fixtures.Command_Kind'Last) + 1
      then
         return False;
      end if;

      for Kind in A11y_Test_Fixtures.Command_Kind loop
         declare
            Found : Boolean := False;
         begin
            for Command of Commands loop
               if Command.Kind = Kind
                 and then A11y.Node_Ids.Is_Valid (Command.Target)
               then
                  Found := True;
                  exit;
               end if;
            end loop;

            if not Found then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Has_Fixture_Command_Coverage;

   function Has_Text_Observation return Boolean is
     (Has_Observation
        ("fixture.text_range",
         "text.range.basic",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field));

   function Has_Text_Mutation_Observation return Boolean is
     (Has_Observation
        ("fixture.text_insert",
         "events.text.payload",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field)
      and then Has_Observation
        ("fixture.text_remove",
         "events.text.payload",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field)
      and then Has_Observation
        ("fixture.text_replace",
         "events.text.payload",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field));

   function Has_Text_Set_Observation return Boolean is
     (Has_Observation
        ("fixture.text_set",
         "text.edit.request",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field));

   function Has_Caret_Observation return Boolean is
     (Has_Observation
        ("fixture.caret_move",
         "events.text.payload",
         A11y_Test_Fixtures.Text_Field_Id,
         A11y.Roles.Text_Field));

   function Has_Table_Observation return Boolean is
     (Has_Observation
        ("fixture.table_cell",
         "table.cell.basic",
         A11y_Test_Fixtures.Table_Cell_Id,
         A11y.Roles.Cell));

   function Has_Table_Current_Cell_Observation return Boolean is
     (Has_Observation
        ("fixture.table_current_cell",
         "table.current_cell",
         A11y_Test_Fixtures.Table_Cell_Id,
         A11y.Roles.Cell));

   function Has_Table_Sort_Metadata_Observation return Boolean is
     (Has_Observation
        ("fixture.table_sort_metadata",
         "table.sort.metadata",
         A11y_Test_Fixtures.Table_Id,
         A11y.Roles.Table));

   function Has_Table_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.table_row_insert",
         "events.table.payload",
         A11y_Test_Fixtures.Table_Id,
         A11y.Roles.Table)
      and then Has_Observation
        ("fixture.table_cell_change",
         "events.table.payload",
         A11y_Test_Fixtures.Table_Cell_Id,
         A11y.Roles.Cell));

   function Has_Image_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.informative_image"
           and then Trimmed (Observation.Conformance_Id) =
             "image.alternative_text"
           and then Observation.Node = A11y_Test_Fixtures.Informative_Image_Id
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Image_Observation;

   function Has_Document_Observation return Boolean is
     (Has_Observation
        ("fixture.document_heading",
         "document.heading.level",
         A11y_Test_Fixtures.Heading_Id,
         A11y.Roles.Heading));

   function Has_Document_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.document_loaded",
         "events.document.payload",
         A11y_Test_Fixtures.Document_Id,
         A11y.Roles.Document));

   function Has_Protected_Text_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.password_protected"
           and then Trimmed (Observation.Conformance_Id) = "text.protected"
           and then Observation.Node = A11y_Test_Fixtures.Password_Field_Id
           and then Trimmed (Observation.Privacy) = "protected_redacted"
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Protected_Text_Observation;

   function Has_Live_Region_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.live_region"
           and then Trimmed (Observation.Conformance_Id) =
             "events.live_region.changed"
           and then Observation.Node = A11y_Test_Fixtures.Live_Region_Id
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Live_Region_Observation;

   function Has_Relation_Observation return Boolean is
     (Has_Observation
        ("fixture.validation_error",
         "relations.error_message",
         A11y_Test_Fixtures.Validation_Error_Id,
         A11y.Roles.Alert));

   function Has_Relation_Event_Observation return Boolean is
     (Has_Observation
        ("fixture.relation_event",
         "events.relation.payload",
         A11y_Test_Fixtures.Password_Field_Id,
         A11y.Roles.Password_Field));

   function Has_Surface_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.modal_surface"
           and then Trimmed (Observation.Conformance_Id) =
             "window.surface.state_metadata"
           and then A11y.Node_Ids.Is_Valid (Observation.Node)
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Surface_Observation;

   function Has_Lifecycle_Observation return Boolean is
   begin
      for Observation of Observations loop
         if Trimmed (Observation.Feature) = "fixture.destroyed_list_item"
           and then Trimmed (Observation.Conformance_Id) =
             "lifecycle.stale_reference"
           and then Trimmed (Observation.Native_Resolution) =
             "node_unavailable"
           and then A11y.Node_Ids.Is_Valid (Observation.Node)
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Lifecycle_Observation;

   function Has_Required_Conformance_Evidence return Boolean is
      Saw_Core_Application : Boolean := False;
      Saw_Core_Window : Boolean := False;
      Saw_Focus_Conformance : Boolean := False;
      Saw_Property_Conformance : Boolean := False;
      Saw_Orientation_Property_Event : Boolean := False;
      Saw_Set_Position_Property_Event : Boolean := False;
      Saw_Set_Size_Property_Event : Boolean := False;
      Saw_Hierarchical_Level_Property_Event : Boolean := False;
      Saw_Role_Property_Conformance : Boolean := False;
      Saw_State_Set_Property_Conformance : Boolean := False;
      Saw_Help_Text_Conformance : Boolean := False;
      Saw_Placeholder_Conformance : Boolean := False;
      Saw_Name_Conformance : Boolean := False;
      Saw_Description_Conformance : Boolean := False;
      Saw_Value_Text_Conformance : Boolean := False;
      Saw_Semantic_Identifier_Conformance : Boolean := False;
      Saw_Locale_Property_Conformance : Boolean := False;
      Saw_Visible_Title_Property_Conformance : Boolean := False;
      Saw_Orientation_Property_Conformance : Boolean := False;
      Saw_Set_Position_Property_Conformance : Boolean := False;
      Saw_Set_Size_Property_Conformance : Boolean := False;
      Saw_Hierarchical_Level_Property_Conformance : Boolean := False;
      Saw_Heading_Level_Property_Conformance : Boolean := False;
      Saw_Landmark_Property_Conformance : Boolean := False;
      Saw_Bounds_Property_Conformance : Boolean := False;
      Saw_Keyboard_Shortcut_Conformance : Boolean := False;
      Saw_State_Conformance : Boolean := False;
      Saw_Bounds_Conformance : Boolean := False;
      Saw_Hit_Test_Conformance : Boolean := False;
      Saw_Tree_Conformance : Boolean := False;
      Saw_Window_Conformance : Boolean := False;
      Saw_Action_Conformance : Boolean := False;
      Saw_Value_Conformance : Boolean := False;
      Saw_Selection_Conformance : Boolean := False;
      Saw_Select_All_Conformance : Boolean := False;
      Saw_Active_Descendant_Conformance : Boolean := False;
      Saw_Current_Item_Conformance : Boolean := False;
      Saw_Node_Reference_Conformance : Boolean := False;
      Saw_Selection_Event_Conformance : Boolean := False;
      Saw_Tree_Role : Boolean := False;
      Saw_Tree_Item_Role : Boolean := False;
      Saw_Menu_Bar_Role : Boolean := False;
      Saw_Menu_Role : Boolean := False;
      Saw_Menu_Item_Role : Boolean := False;
      Saw_Tab_List_Role : Boolean := False;
      Saw_Tab_Role : Boolean := False;
      Saw_Tooltip_Role : Boolean := False;
      Saw_Text_Range_Conformance : Boolean := False;
      Saw_Text_Event_Conformance : Boolean := False;
      Saw_Table_Cell_Conformance : Boolean := False;
      Saw_Table_Event_Conformance : Boolean := False;
      Saw_Image_Conformance : Boolean := False;
      Saw_Document_Conformance : Boolean := False;
      Saw_Document_Event_Conformance : Boolean := False;
      Saw_Text_Protected : Boolean := False;
      Saw_Live_Conformance : Boolean := False;
      Saw_Error_Relation : Boolean := False;
      Saw_Relation_Event_Conformance : Boolean := False;
      Saw_Surface_Conformance : Boolean := False;
      Saw_Stale_Conformance : Boolean := False;
      Saw_Native_Registry : Boolean := False;
      Saw_Native_Export_Descriptor : Boolean := False;
      Saw_Windows_UIA_Host_Window_Root_Binding : Boolean := False;
      Saw_MacOS_NSAX_Main_Thread_Binding : Boolean := False;
      Saw_MacOS_NSAX_Native_View_Binding : Boolean := False;
      Saw_Native_Node_Index : Boolean := False;
      Saw_Native_Cache_Tombstone : Boolean := False;
      Saw_Native_Cache_Session_Scope : Boolean := False;
      Saw_Native_Cache_Generation : Boolean := False;
      Saw_Native_Cache_Mutation_Report : Boolean := False;
      Saw_Native_Registry_Generation : Boolean := False;
      Saw_Native_Registry_Mutation_Report : Boolean := False;
      Saw_Native_Boundary_Runtime_Generation : Boolean := False;
      Saw_Native_Runtime_Lifecycle : Boolean := False;
      Saw_Native_Runtime_Lifecycle_Report : Boolean := False;
      Saw_Native_Runtime_Probe_Failure_Stage : Boolean := False;
      Saw_Native_Runtime_Event_Application : Boolean := False;
      Saw_Native_Runtime_Event_Preparation : Boolean := False;
      Saw_Native_Runtime_Event_Preparation_Report : Boolean := False;
      Saw_Native_Projection_Property : Boolean := False;
      Saw_Native_Projection_Action : Boolean := False;
      Saw_Native_Projection_Relation : Boolean := False;
      Saw_Native_Projection_Event_Source : Boolean := False;
      Saw_Native_Deterministic_Shutdown : Boolean := False;
      Saw_Diagnostics_Bounded : Boolean := False;
      Saw_Diagnostics_Result_Mapping : Boolean := False;
      Saw_Diagnostics_Field_Bounds : Boolean := False;
      Saw_Native_Resource_Limit : Boolean := False;
      Saw_Native_Value_Resource_Limit : Boolean := False;
      Saw_Hostile_Identity : Boolean := False;
      Saw_Native_Boundary_Admission_Report : Boolean := False;
      Saw_Native_Boundary_Native_Call_Report : Boolean := False;
      Saw_Native_Boundary_Completion_Report : Boolean := False;
      Saw_Native_Boundary_Release_Report : Boolean := False;
      Saw_Native_Fixture_Root_Probe : Boolean := False;
      Saw_Native_Fixture_Root_Failure_Stage : Boolean := False;
      Saw_Native_Fixture_Root_Child_Traversal : Boolean := False;
      Saw_Native_Fixture_Root_Child_Count : Boolean := False;
      Saw_Native_Fixture_Root_Second_Child : Boolean := False;
      Saw_Native_Fixture_Child_Query : Boolean := False;
      Saw_Native_Fixture_Child_Object : Boolean := False;
      Saw_Native_Fixture_Child_Parent : Boolean := False;
      Saw_Native_Fixture_Child_Native_Identity : Boolean := False;
      Saw_Native_Fixture_Second_Child_Parent : Boolean := False;
      Saw_Native_Fixture_Second_Child_Native_Identity : Boolean := False;
      Saw_Native_Fixture_Sibling_Order : Boolean := False;
      Saw_Native_Fixture_Child_Stale_Id : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Probe : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Tree_Traversal : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Property : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Property_Map : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Stale_Error : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Queued : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Drained : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued :
        Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized :
        Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded :
        Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained :
        Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Malformed_Packet : Boolean := False;
      Saw_Linux_ATSPI_Serving_Packet_Text_Payload_Limit : Boolean := False;
      Saw_Linux_ATSPI_Session_Bus_Probe : Boolean := False;
      Saw_Linux_ATSPI_Session_Startup_Stage : Boolean := False;
      Saw_Linux_ATSPI_Session_Dispatch_Probe : Boolean := False;
      Saw_Linux_ATSPI_Session_Dispatch_Boundary_Drained : Boolean := False;
      Saw_Malformed_Request : Boolean := False;
      Saw_Linux_Error_Name_Map : Boolean := False;
      Saw_Linux_Error_Name_Inverse_Map : Boolean := False;
      Saw_Linux_Error_Name_Diagnostic : Boolean := False;
      Saw_Linux_DBus_Unsupported_Value : Boolean := False;
      Saw_Linux_DBus_UInt32_Array_Value : Boolean := False;
      Saw_Linux_DBus_State_Set_UInt32_Array : Boolean := False;
      Saw_Linux_DBus_String_Array_Value : Boolean := False;
      Saw_Linux_DBus_Attribute_String_Array : Boolean := False;
      Saw_Linux_DBus_Cache_Interface_String_Array : Boolean := False;
      Saw_Linux_DBus_Object_Path_Array_Value : Boolean := False;
      Saw_Linux_DBus_Relation_Target_Object_Path_Array : Boolean := False;
      Saw_Windows_HResult_Map : Boolean := False;
      Saw_Windows_HResult_Inverse_Map : Boolean := False;
      Saw_Windows_HResult_Diagnostic : Boolean := False;
      Saw_Windows_UIA_Event_Posting_Admission : Boolean := False;
      Saw_Windows_UIA_Event_Posting_Report : Boolean := False;
      Saw_Windows_UIA_Event_Posting_Drain_Bounded : Boolean := False;
      Saw_Windows_UIA_Event_Build_Report : Boolean := False;
      Saw_Windows_UIA_Hostile_Callback_Admission : Boolean := False;
      Saw_Windows_UIA_Missing_Identity : Boolean := False;
      Saw_Windows_UIA_Mismatched_Identity : Boolean := False;
      Saw_Windows_UIA_Malformed_Identity : Boolean := False;
      Saw_Windows_UIA_Text_Payload_Limit : Boolean := False;
      Saw_MacOS_Native_Status_Map : Boolean := False;
      Saw_MacOS_Native_Status_Inverse_Map : Boolean := False;
      Saw_MacOS_Native_Status_Diagnostic : Boolean := False;
      Saw_MacOS_NSAX_Event_Posting_Admission : Boolean := False;
      Saw_MacOS_NSAX_Event_Posting_Report : Boolean := False;
      Saw_MacOS_NSAX_Event_Posting_Drain_Bounded : Boolean := False;
      Saw_MacOS_NSAX_Event_Build_Report : Boolean := False;
      Saw_MacOS_NSAX_Hostile_Callback_Admission : Boolean := False;
      Saw_MacOS_NSAX_Missing_Identity : Boolean := False;
      Saw_MacOS_NSAX_Mismatched_Identity : Boolean := False;
      Saw_MacOS_NSAX_Malformed_Identity : Boolean := False;
      Saw_MacOS_NSAX_Text_Payload_Limit : Boolean := False;
      Saw_Transport_Conformance : Boolean := False;
      Saw_Transport_Transition_Report : Boolean := False;
      Saw_Action_Payload_Conformance : Boolean := False;
      Saw_Action_Request_Payload_Conformance : Boolean := False;
      Saw_Prepared_Status_Conformance : Boolean := False;
      Saw_Event_Staging_Conformance : Boolean := False;
      Saw_Event_Posting_Interest : Boolean := False;
      Saw_Native_Event_Validation : Boolean := False;
      Saw_Native_Event_Posting_Boundary : Boolean := False;
      Saw_Native_Event_Exhaustive_Map : Boolean := False;
      Saw_Native_Role_Exhaustive_Map : Boolean := False;
      Saw_Native_Relation_Exhaustive_Map : Boolean := False;
      Saw_Method_Return_Payload : Boolean := False;
      Saw_Method_Return_Decode : Boolean := False;
      Saw_Error_Return_Decode : Boolean := False;
      Saw_Error_Return_Diagnostic : Boolean := False;
      Saw_Startup_Error_Completion : Boolean := False;
      Saw_Incoming_Packet_Classification : Boolean := False;
      Saw_Incoming_Packet_Dispatch : Boolean := False;
      Saw_Startup_Pump_Readiness : Boolean := False;
      Saw_Startup_Outgoing_Work : Boolean := False;
      Saw_Startup_Event_Loop_Interest : Boolean := False;
      Saw_Startup_Event_Loop_Operation : Boolean := False;
      Saw_Linux_DBus_Backend_Session_Event_Loop_Step : Boolean := False;
      Saw_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler :
        Boolean := False;
      Saw_Startup_Outgoing_Flush : Boolean := False;
      Saw_Linux_DBus_Outgoing_Back_Pressure : Boolean := False;
      Saw_Linux_DBus_Connection_Lifecycle : Boolean := False;
      Saw_Linux_DBus_Local_Channel_Adapter : Boolean := False;
      Saw_Linux_DBus_Local_Channel_Receive : Boolean := False;
      Saw_Linux_DBus_Startup_Controller : Boolean := False;
      Saw_Linux_DBus_Startup_Backend_Adapter : Boolean := False;
      Saw_Linux_DBus_Startup_Pump : Boolean := False;
      Saw_Linux_DBus_Startup_Pump_Report : Boolean := False;
      Saw_Linux_DBus_Startup_Pump_Bounded_Report : Boolean := False;
      Saw_Linux_DBus_Startup_Pump_Bounds : Boolean := False;
      Saw_Linux_DBus_Startup_Registered_Pump : Boolean := False;
      Saw_Linux_DBus_Bus_Address : Boolean := False;
      Saw_Linux_DBus_Auth_External : Boolean := False;
      Saw_Linux_DBus_Auth_Exchange : Boolean := False;
      Saw_Linux_DBus_Authenticated_Connect : Boolean := False;
      Saw_Linux_DBus_Hello : Boolean := False;
      Saw_Linux_DBus_Authenticated_Hello : Boolean := False;
      Saw_Linux_DBus_Registration_Completion : Boolean := False;
      Saw_Linux_DBus_Authenticated_Registration : Boolean := False;
      Saw_Linux_DBus_Application_Registration : Boolean := False;
      Saw_Linux_ATSPI_Live_Transport_Registration_Observed :
        Boolean := False;
      Saw_Linux_DBus_Address_Discovery : Boolean := False;
      Saw_Linux_DBus_Host_Environment_Startup : Boolean := False;
      Saw_Linux_DBus_A11y_Bus_Get_Address : Boolean := False;
      Saw_Linux_DBus_Authenticated_Get_Address : Boolean := False;
      Saw_Linux_DBus_Startup_Session_Discovery : Boolean := False;
      Saw_Linux_DBus_Transport_Frame_Metadata : Boolean := False;
      Saw_Linux_DBus_Method_Call_Destination_Routing : Boolean := False;
      Saw_Linux_DBus_Transport_Frame_Bytes : Boolean := False;
      Saw_Linux_DBus_Transport_Frame_Send : Boolean := False;
      Saw_Linux_DBus_Transport_Packet : Boolean := False;
      Saw_Linux_DBus_Transport_Packet_Send : Boolean := False;
      Saw_Linux_DBus_Transport_Packet_Decode : Boolean := False;
      Saw_Linux_DBus_Codec_Basic : Boolean := False;
      Saw_Linux_DBus_Resource_Limits : Boolean := False;
      Saw_Linux_DBus_Message_Envelope : Boolean := False;
      Saw_Linux_DBus_Method_Call_Envelope : Boolean := False;
      Saw_Linux_DBus_Transport_Envelope_Decode : Boolean := False;
      Saw_Linux_DBus_Incoming_Call_Decode : Boolean := False;
      Saw_Linux_DBus_Signal_Envelope : Boolean := False;
      Saw_Linux_DBus_Prepared_Signal_Envelope : Boolean := False;
      Saw_Linux_ATSPI_Signal_Build_Report : Boolean := False;
      Saw_Linux_DBus_Method_Boundary : Boolean := False;
      Saw_Runtime_Override : Boolean := False;
   begin
      for Observation of Observations loop
         declare
            Id : constant String := Trimmed (Observation.Conformance_Id);
            Feature : constant String := Trimmed (Observation.Feature);
         begin
            if Id = "core.role.application" then
               Saw_Core_Application := True;
            elsif Id = "core.role.window" then
               Saw_Core_Window := True;
            elsif Id = "events.focus.payload" then
               Saw_Focus_Conformance := True;
            elsif Id = "events.property.payload" then
               Saw_Property_Conformance := True;
            elsif Id = "events.property.orientation" then
               Saw_Orientation_Property_Event := True;
            elsif Id = "events.property.set_position" then
               Saw_Set_Position_Property_Event := True;
            elsif Id = "events.property.set_size" then
               Saw_Set_Size_Property_Event := True;
            elsif Id = "events.property.hierarchical_level" then
               Saw_Hierarchical_Level_Property_Event := True;
            elsif Id = "core.property.role" then
               Saw_Role_Property_Conformance := True;
            elsif Id = "core.property.state_set" then
               Saw_State_Set_Property_Conformance := True;
            elsif Id = "core.property.name" then
               Saw_Name_Conformance := True;
            elsif Id = "core.property.description" then
               Saw_Description_Conformance := True;
            elsif Id = "core.property.help_text" then
               Saw_Help_Text_Conformance := True;
            elsif Id = "core.property.placeholder" then
               Saw_Placeholder_Conformance := True;
            elsif Id = "core.property.value_text" then
               Saw_Value_Text_Conformance := True;
            elsif Id = "core.property.semantic_identifier" then
               Saw_Semantic_Identifier_Conformance := True;
            elsif Id = "core.property.locale" then
               Saw_Locale_Property_Conformance := True;
            elsif Id = "core.property.visible_title" then
               Saw_Visible_Title_Property_Conformance := True;
            elsif Id = "core.property.orientation" then
               Saw_Orientation_Property_Conformance := True;
            elsif Id = "core.property.set_position" then
               Saw_Set_Position_Property_Conformance := True;
            elsif Id = "core.property.set_size" then
               Saw_Set_Size_Property_Conformance := True;
            elsif Id = "core.property.hierarchical_level" then
               Saw_Hierarchical_Level_Property_Conformance := True;
            elsif Id = "core.property.heading_level" then
               Saw_Heading_Level_Property_Conformance := True;
            elsif Id = "core.property.landmark" then
               Saw_Landmark_Property_Conformance := True;
            elsif Id = "core.property.bounds" then
               Saw_Bounds_Property_Conformance := True;
            elsif Id = "core.property.keyboard_shortcut" then
               Saw_Keyboard_Shortcut_Conformance := True;
            elsif Id = "events.state.payload" then
               Saw_State_Conformance := True;
            elsif Id = "events.bounds.payload" then
               Saw_Bounds_Conformance := True;
            elsif Id = "native.boundary.component_call" then
               Saw_Hit_Test_Conformance := True;
            elsif Id = "events.tree.payload" then
               Saw_Tree_Conformance := True;
            elsif Id = "events.window.payload" then
               Saw_Window_Conformance := True;
            elsif Id = "actions.activate"
              or else Id = "actions.press"
              or else Id = "actions.toggle"
              or else Id = "actions.expand"
              or else Id = "actions.collapse"
              or else Id = "actions.show_menu"
              or else Id = "actions.dismiss"
              or else Id = "actions.open"
              or else Id = "actions.close"
              or else Id = "actions.scroll_into_view"
              or else Id = "actions.set_focus"
            then
               Saw_Action_Conformance := True;
            elsif Id = "value.range" then
               Saw_Value_Conformance := True;
            elsif Id = "selection.single" then
               Saw_Selection_Conformance := True;
            elsif Id = "selection.select_all" then
               Saw_Select_All_Conformance := True;
            elsif Id = "relations.active_descendant" then
               Saw_Active_Descendant_Conformance := True;
            elsif Id = "selection.current_item" then
               Saw_Current_Item_Conformance := True;
            elsif Id = "events.node_reference.payload" then
               Saw_Node_Reference_Conformance := True;
            elsif Id = "events.selection.payload" then
               Saw_Selection_Event_Conformance := True;
            elsif Id = "core.role.tree" then
               Saw_Tree_Role := True;
            elsif Id = "core.role.tree_item" then
               Saw_Tree_Item_Role := True;
            elsif Id = "core.role.menu_bar" then
               Saw_Menu_Bar_Role := True;
            elsif Id = "core.role.menu" then
               Saw_Menu_Role := True;
            elsif Id = "core.role.menu_item" then
               Saw_Menu_Item_Role := True;
            elsif Id = "core.role.tab_list" then
               Saw_Tab_List_Role := True;
            elsif Id = "core.role.tab" then
               Saw_Tab_Role := True;
            elsif Id = "core.role.tooltip" then
               Saw_Tooltip_Role := True;
            elsif Id = "text.range.basic" then
               Saw_Text_Range_Conformance := True;
            elsif Id = "events.text.payload" then
               Saw_Text_Event_Conformance := True;
            elsif Id = "table.cell.basic" then
               Saw_Table_Cell_Conformance := True;
            elsif Id = "events.table.payload" then
               Saw_Table_Event_Conformance := True;
            elsif Id = "image.alternative_text" then
               Saw_Image_Conformance := True;
            elsif Id = "document.heading.level" then
               Saw_Document_Conformance := True;
            elsif Id = "events.document.payload" then
               Saw_Document_Event_Conformance := True;
            elsif Id = "text.protected" then
               Saw_Text_Protected := True;
            elsif Id = "events.live_region.changed" then
               Saw_Live_Conformance := True;
            elsif Id = "relations.error_message" then
               Saw_Error_Relation := True;
            elsif Id = "events.relation.payload" then
               Saw_Relation_Event_Conformance := True;
            elsif Id = "window.surface.state_metadata" then
               Saw_Surface_Conformance := True;
            elsif Id = "lifecycle.stale_reference" then
               Saw_Stale_Conformance := True;
            elsif Id = "native.object_cache.identity" then
               Saw_Native_Registry := True;
            elsif Id = "native.object_export_descriptor" then
               Saw_Native_Export_Descriptor := True;
            elsif Id = "windows.uia.host_window_root_binding" then
               Saw_Windows_UIA_Host_Window_Root_Binding := True;
            elsif Id = "macos.nsaccessibility.main_thread_binding" then
               Saw_MacOS_NSAX_Main_Thread_Binding := True;
            elsif Id = "macos.nsaccessibility.native_view_binding" then
               Saw_MacOS_NSAX_Native_View_Binding := True;
            elsif Id = "native.object_cache.node_index" then
               Saw_Native_Node_Index := True;
            elsif Id = "native.object_cache.tombstone" then
               Saw_Native_Cache_Tombstone := True;
            elsif Id = "native.object_cache.session_scope" then
               Saw_Native_Cache_Session_Scope := True;
            elsif Id = "native.object_cache.generation" then
               Saw_Native_Cache_Generation := True;
            elsif Id = "native.object_cache.mutation_report" then
               Saw_Native_Cache_Mutation_Report := True;
            elsif Id = "native.object_registry.generation" then
               Saw_Native_Registry_Generation := True;
            elsif Id = "native.object_registry.mutation_report" then
               Saw_Native_Registry_Mutation_Report := True;
            elsif Id = "native.runtime.generation"
              and then Feature = "native.boundary_runtime_generation"
            then
               Saw_Native_Boundary_Runtime_Generation := True;
            elsif Id = "native.runtime.lifecycle" then
               Saw_Native_Runtime_Lifecycle := True;
            elsif Id = "native.runtime.lifecycle_report" then
               Saw_Native_Runtime_Lifecycle_Report := True;
            elsif Id = "native.runtime.probe_failure_stage" then
               Saw_Native_Runtime_Probe_Failure_Stage := True;
            elsif Id = "native.runtime.event_application" then
               Saw_Native_Runtime_Event_Application := True;
            elsif Id = "native.runtime.event_preparation" then
               Saw_Native_Runtime_Event_Preparation := True;
            elsif Id = "native.runtime.event_preparation_report" then
               Saw_Native_Runtime_Event_Preparation_Report := True;
            elsif Id = "native.projection.property" then
               Saw_Native_Projection_Property := True;
            elsif Id = "native.projection.action" then
               Saw_Native_Projection_Action := True;
            elsif Id = "native.projection.relation" then
               Saw_Native_Projection_Relation := True;
            elsif Id = "native.projection.event_source" then
               Saw_Native_Projection_Event_Source := True;
            elsif Id = "backend.transport.unavailable" then
               Saw_Transport_Conformance := True;
            elsif Id = "backend.native.transport_transition_report" then
               Saw_Transport_Transition_Report := True;
            elsif Id = "native.request.action_payload"
              and then Feature = "native.action_payload"
            then
               Saw_Action_Payload_Conformance := True;
            elsif Id = "native.request.action_payload"
              and then Feature = "native.action_request_payload"
            then
               Saw_Action_Request_Payload_Conformance := True;
            elsif Id = "backend.native.deterministic_shutdown" then
               Saw_Native_Deterministic_Shutdown := True;
            elsif Id = "backend.diagnostics.bounded" then
               Saw_Diagnostics_Bounded := True;
            elsif Id = "diagnostics.result_mapping" then
               Saw_Diagnostics_Result_Mapping := True;
            elsif Id = "diagnostics.field_bounds" then
               Saw_Diagnostics_Field_Bounds := True;
            elsif Id = "native.object_cache.resource_limit" then
               Saw_Native_Resource_Limit := True;
            elsif Id = "native.value.resource_limit" then
               Saw_Native_Value_Resource_Limit := True;
            elsif Id = "native.boundary.identity_admission" then
               Saw_Hostile_Identity := True;
            elsif Id = "native.boundary.admission_report" then
               Saw_Native_Boundary_Admission_Report := True;
            elsif Id = "native.boundary.native_call_report" then
               Saw_Native_Boundary_Native_Call_Report := True;
            elsif Id = "native.boundary.completion_report" then
               Saw_Native_Boundary_Completion_Report := True;
            elsif Id = "native.boundary.release_report" then
               Saw_Native_Boundary_Release_Report := True;
            elsif Id = "native.fixture_root.query" then
               Saw_Native_Fixture_Root_Probe := True;
            elsif Id = "native.fixture_root.failure_stage" then
               Saw_Native_Fixture_Root_Failure_Stage := True;
            elsif Id = "native.fixture_root.child_traversal" then
               Saw_Native_Fixture_Root_Child_Traversal := True;
            elsif Id = "native.fixture_root.child_count" then
               Saw_Native_Fixture_Root_Child_Count := True;
            elsif Id = "native.fixture_root.second_child" then
               Saw_Native_Fixture_Root_Second_Child := True;
            elsif Id = "native.fixture_child.query" then
               Saw_Native_Fixture_Child_Query := True;
            elsif Id = "native.fixture_child.native_object" then
               Saw_Native_Fixture_Child_Object := True;
            elsif Id = "native.fixture_child.parent_navigation" then
               Saw_Native_Fixture_Child_Parent := True;
            elsif Id = "native.fixture_child.native_identity" then
               Saw_Native_Fixture_Child_Native_Identity := True;
            elsif Id = "native.fixture_second_child.parent_navigation" then
               Saw_Native_Fixture_Second_Child_Parent := True;
            elsif Id = "native.fixture_second_child.native_identity" then
               Saw_Native_Fixture_Second_Child_Native_Identity := True;
            elsif Id = "native.fixture.sibling_order" then
               Saw_Native_Fixture_Sibling_Order := True;
            elsif Id = "native.fixture_child.stale_id" then
               Saw_Native_Fixture_Child_Stale_Id := True;
            elsif Id = "linux.atspi.serving_packet_probe" then
               Saw_Linux_ATSPI_Serving_Packet_Probe := True;
            elsif Id = "linux.atspi.serving_packet.tree_traversal" then
               Saw_Linux_ATSPI_Serving_Packet_Tree_Traversal := True;
            elsif Id = "linux.atspi.serving_packet.property" then
               Saw_Linux_ATSPI_Serving_Packet_Property := True;
            elsif Id = "linux.atspi.serving_packet.property_map" then
               Saw_Linux_ATSPI_Serving_Packet_Property_Map := True;
            elsif Id = "linux.atspi.serving_packet.stale_error" then
               Saw_Linux_ATSPI_Serving_Packet_Stale_Error := True;
            elsif Id =
              "linux.atspi.serving_packet.stale_error.queued"
            then
               Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Queued := True;
            elsif Id =
              "linux.atspi.serving_packet.stale_error.serialized"
            then
               Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized := True;
            elsif Id =
              "linux.atspi.serving_packet.stale_error.decoded"
            then
               Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded := True;
            elsif Id =
              "linux.atspi.serving_packet.stale_error.drained"
            then
               Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Drained := True;
            elsif Id = "linux.atspi.serving_packet.unsupported_interface" then
               Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface := True;
            elsif Id =
              "linux.atspi.serving_packet.unsupported_interface.queued"
            then
               Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued :=
                 True;
            elsif Id =
              "linux.atspi.serving_packet.unsupported_interface.serialized"
            then
               Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized
                 := True;
            elsif Id =
              "linux.atspi.serving_packet.unsupported_interface.decoded"
            then
               Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded :=
                 True;
            elsif Id =
              "linux.atspi.serving_packet.unsupported_interface.drained"
            then
               Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained :=
                 True;
            elsif Id = "linux.atspi.serving_packet.malformed_packet" then
               Saw_Linux_ATSPI_Serving_Packet_Malformed_Packet := True;
            elsif Id = "linux.atspi.serving_packet.text_payload_limit" then
               Saw_Linux_ATSPI_Serving_Packet_Text_Payload_Limit := True;
            elsif Id = "linux.atspi.session_bus_probe" then
               Saw_Linux_ATSPI_Session_Bus_Probe := True;
            elsif Id = "linux.atspi.session_startup_stage" then
               Saw_Linux_ATSPI_Session_Startup_Stage := True;
            elsif Id = "linux.atspi.session_dispatch_probe" then
               Saw_Linux_ATSPI_Session_Dispatch_Probe := True;
            elsif Id = "linux.atspi.session_dispatch.boundary_drained" then
               Saw_Linux_ATSPI_Session_Dispatch_Boundary_Drained := True;
            elsif Id = "native.boundary.error_map" then
               Saw_Malformed_Request := True;
            elsif Id = "linux.atspi.error_name_map" then
               Saw_Linux_Error_Name_Map := True;
            elsif Id = "linux.atspi.error_name_inverse_map" then
               Saw_Linux_Error_Name_Inverse_Map := True;
            elsif Id = "linux.atspi.error_name_diagnostic" then
               Saw_Linux_Error_Name_Diagnostic := True;
            elsif Id = "linux.dbus.unsupported_value" then
               Saw_Linux_DBus_Unsupported_Value := True;
            elsif Id = "linux.dbus.uint32_array_value" then
               Saw_Linux_DBus_UInt32_Array_Value := True;
            elsif Id = "linux.dbus.state_set_uint32_array" then
               Saw_Linux_DBus_State_Set_UInt32_Array := True;
            elsif Id = "linux.dbus.string_array_value" then
               Saw_Linux_DBus_String_Array_Value := True;
            elsif Id = "linux.dbus.attribute_string_array" then
               Saw_Linux_DBus_Attribute_String_Array := True;
            elsif Id = "linux.dbus.cache_interface_string_array" then
               Saw_Linux_DBus_Cache_Interface_String_Array := True;
            elsif Id = "linux.dbus.object_path_array_value" then
               Saw_Linux_DBus_Object_Path_Array_Value := True;
            elsif Id = "linux.dbus.relation_target_object_path_array" then
               Saw_Linux_DBus_Relation_Target_Object_Path_Array := True;
            elsif Id = "windows.uia.hresult_map" then
               Saw_Windows_HResult_Map := True;
            elsif Id = "windows.uia.hresult_inverse_map" then
               Saw_Windows_HResult_Inverse_Map := True;
            elsif Id = "windows.uia.hresult_diagnostic" then
               Saw_Windows_HResult_Diagnostic := True;
            elsif Id = "windows.uia.event_posting_admission" then
               Saw_Windows_UIA_Event_Posting_Admission := True;
            elsif Id = "windows.uia.event_posting_report" then
               Saw_Windows_UIA_Event_Posting_Report := True;
            elsif Id = "windows.uia.event_posting_drain_bounded" then
               Saw_Windows_UIA_Event_Posting_Drain_Bounded := True;
            elsif Id = "windows.uia.event.build_report" then
               Saw_Windows_UIA_Event_Build_Report := True;
            elsif Id = "windows.uia.native_callback.hostile_admission" then
               Saw_Windows_UIA_Hostile_Callback_Admission := True;
            elsif Id = "windows.uia.native_callback.missing_identity" then
               Saw_Windows_UIA_Missing_Identity := True;
            elsif Id = "windows.uia.native_callback.mismatched_identity" then
               Saw_Windows_UIA_Mismatched_Identity := True;
            elsif Id = "windows.uia.native_callback.malformed_identity" then
               Saw_Windows_UIA_Malformed_Identity := True;
            elsif Id = "windows.uia.native_callback.text_payload_limit" then
               Saw_Windows_UIA_Text_Payload_Limit := True;
            elsif Id = "macos.nsaccessibility.native_status_map" then
               Saw_MacOS_Native_Status_Map := True;
            elsif Id = "macos.nsaccessibility.native_status_inverse_map" then
               Saw_MacOS_Native_Status_Inverse_Map := True;
            elsif Id = "macos.nsaccessibility.native_status_diagnostic" then
               Saw_MacOS_Native_Status_Diagnostic := True;
            elsif Id = "macos.nsaccessibility.event_posting_admission" then
               Saw_MacOS_NSAX_Event_Posting_Admission := True;
            elsif Id = "macos.nsaccessibility.event_posting_report" then
               Saw_MacOS_NSAX_Event_Posting_Report := True;
            elsif Id = "macos.nsaccessibility.event_posting_drain_bounded" then
               Saw_MacOS_NSAX_Event_Posting_Drain_Bounded := True;
            elsif Id = "macos.nsaccessibility.event.build_report" then
               Saw_MacOS_NSAX_Event_Build_Report := True;
            elsif Id =
              "macos.nsaccessibility.native_callback.hostile_admission"
            then
               Saw_MacOS_NSAX_Hostile_Callback_Admission := True;
            elsif Id =
              "macos.nsaccessibility.native_callback.missing_identity"
            then
               Saw_MacOS_NSAX_Missing_Identity := True;
            elsif Id =
              "macos.nsaccessibility.native_callback.mismatched_identity"
            then
               Saw_MacOS_NSAX_Mismatched_Identity := True;
            elsif Id =
              "macos.nsaccessibility.native_callback.malformed_identity"
            then
               Saw_MacOS_NSAX_Malformed_Identity := True;
            elsif Id =
              "macos.nsaccessibility.native_callback.text_payload_limit"
            then
               Saw_MacOS_NSAX_Text_Payload_Limit := True;
            elsif Id = "native.event.prepared_status" then
               Saw_Prepared_Status_Conformance := True;
            elsif Id = "native.event.staging_queue" then
               Saw_Event_Staging_Conformance := True;
            elsif Id = "native.event.posting_interest" then
               Saw_Event_Posting_Interest := True;
            elsif Id = "native.event.validation" then
               Saw_Native_Event_Validation := True;
            elsif Id = "native.event.posting_boundary" then
               Saw_Native_Event_Posting_Boundary := True;
            elsif Id = "native.event.exhaustive_map" then
               Saw_Native_Event_Exhaustive_Map := True;
            elsif Id = "native.role.exhaustive_map" then
               Saw_Native_Role_Exhaustive_Map := True;
            elsif Id = "native.relation.exhaustive_map" then
               Saw_Native_Relation_Exhaustive_Map := True;
            elsif Id = "linux.dbus.method_return_payload" then
               Saw_Method_Return_Payload := True;
            elsif Id = "linux.dbus.method_return_decode" then
               Saw_Method_Return_Decode := True;
            elsif Id = "linux.dbus.error_return_decode" then
               Saw_Error_Return_Decode := True;
            elsif Id = "linux.dbus.error_return_diagnostic" then
               Saw_Error_Return_Diagnostic := True;
            elsif Id = "linux.dbus.startup_error_completion" then
               Saw_Startup_Error_Completion := True;
            elsif Id = "linux.dbus.incoming_packet_classification" then
               Saw_Incoming_Packet_Classification := True;
            elsif Id = "linux.dbus.incoming_packet_dispatch" then
               Saw_Incoming_Packet_Dispatch := True;
            elsif Id = "linux.dbus.startup_pump_readiness" then
               Saw_Startup_Pump_Readiness := True;
            elsif Id = "linux.dbus.startup_outgoing_work" then
               Saw_Startup_Outgoing_Work := True;
            elsif Id = "linux.dbus.startup_event_loop_interest" then
               Saw_Startup_Event_Loop_Interest := True;
            elsif Id = "linux.dbus.startup_event_loop_operation" then
               Saw_Startup_Event_Loop_Operation := True;
            elsif Id = "linux.dbus.backend_session_event_loop_step" then
               Saw_Linux_DBus_Backend_Session_Event_Loop_Step := True;
            elsif Id =
              "linux.dbus.backend_session_transport_cycle_scheduler"
            then
               Saw_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler :=
                 True;
            elsif Id = "linux.dbus.startup_outgoing_flush" then
               Saw_Startup_Outgoing_Flush := True;
            elsif Id = "linux.dbus.outgoing_back_pressure" then
               Saw_Linux_DBus_Outgoing_Back_Pressure := True;
            elsif Id = "linux.dbus.connection_lifecycle" then
               Saw_Linux_DBus_Connection_Lifecycle := True;
            elsif Id = "linux.dbus.local_channel_adapter" then
               Saw_Linux_DBus_Local_Channel_Adapter := True;
            elsif Id = "linux.dbus.local_channel_receive" then
               Saw_Linux_DBus_Local_Channel_Receive := True;
            elsif Id = "linux.dbus.startup_controller" then
               Saw_Linux_DBus_Startup_Controller := True;
            elsif Id = "linux.dbus.startup_backend_adapter" then
               Saw_Linux_DBus_Startup_Backend_Adapter := True;
            elsif Id = "linux.dbus.startup_pump" then
               Saw_Linux_DBus_Startup_Pump := True;
            elsif Id = "linux.dbus.startup_pump_report" then
               Saw_Linux_DBus_Startup_Pump_Report := True;
            elsif Id = "linux.dbus.startup_pump_bounded_report" then
               Saw_Linux_DBus_Startup_Pump_Bounded_Report := True;
            elsif Id = "linux.dbus.startup_pump_bounds" then
               Saw_Linux_DBus_Startup_Pump_Bounds := True;
            elsif Id = "linux.dbus.startup_registered_pump" then
               Saw_Linux_DBus_Startup_Registered_Pump := True;
            elsif Id = "linux.dbus.bus_address" then
               Saw_Linux_DBus_Bus_Address := True;
            elsif Id = "linux.dbus.auth_external" then
               Saw_Linux_DBus_Auth_External := True;
            elsif Id = "linux.dbus.auth_exchange" then
               Saw_Linux_DBus_Auth_Exchange := True;
            elsif Id = "linux.dbus.authenticated_connect" then
               Saw_Linux_DBus_Authenticated_Connect := True;
            elsif Id = "linux.dbus.hello" then
               Saw_Linux_DBus_Hello := True;
            elsif Id = "linux.dbus.authenticated_hello" then
               Saw_Linux_DBus_Authenticated_Hello := True;
            elsif Id = "linux.dbus.registration_completion" then
               Saw_Linux_DBus_Registration_Completion := True;
            elsif Id = "linux.dbus.authenticated_registration" then
               Saw_Linux_DBus_Authenticated_Registration := True;
            elsif Id = "linux.dbus.application_registration" then
               Saw_Linux_DBus_Application_Registration := True;
            elsif Id = "linux.atspi.live_transport.registration_observed" then
               Saw_Linux_ATSPI_Live_Transport_Registration_Observed := True;
            elsif Id = "linux.dbus.address_discovery" then
               Saw_Linux_DBus_Address_Discovery := True;
            elsif Id = "linux.dbus.host_environment_startup" then
               Saw_Linux_DBus_Host_Environment_Startup := True;
            elsif Id = "linux.dbus.a11y_bus_get_address" then
               Saw_Linux_DBus_A11y_Bus_Get_Address := True;
            elsif Id = "linux.dbus.authenticated_get_address" then
               Saw_Linux_DBus_Authenticated_Get_Address := True;
            elsif Id = "linux.dbus.startup_session_discovery" then
               Saw_Linux_DBus_Startup_Session_Discovery := True;
            elsif Id = "linux.dbus.transport_frame_metadata" then
               Saw_Linux_DBus_Transport_Frame_Metadata := True;
            elsif Id = "linux.dbus.method_call_destination_routing" then
               Saw_Linux_DBus_Method_Call_Destination_Routing := True;
            elsif Id = "linux.dbus.transport_frame_bytes" then
               Saw_Linux_DBus_Transport_Frame_Bytes := True;
            elsif Id = "linux.dbus.transport_frame_send" then
               Saw_Linux_DBus_Transport_Frame_Send := True;
            elsif Id = "linux.dbus.transport_packet" then
               Saw_Linux_DBus_Transport_Packet := True;
            elsif Id = "linux.dbus.transport_packet_send" then
               Saw_Linux_DBus_Transport_Packet_Send := True;
            elsif Id = "linux.dbus.transport_packet_decode" then
               Saw_Linux_DBus_Transport_Packet_Decode := True;
            elsif Id = "linux.dbus.codec.basic" then
               Saw_Linux_DBus_Codec_Basic := True;
            elsif Id = "linux.dbus.resource_limits" then
               Saw_Linux_DBus_Resource_Limits := True;
            elsif Id = "linux.dbus.message_envelope" then
               Saw_Linux_DBus_Message_Envelope := True;
            elsif Id = "linux.dbus.method_call_envelope" then
               Saw_Linux_DBus_Method_Call_Envelope := True;
            elsif Id = "linux.dbus.transport_envelope_decode" then
               Saw_Linux_DBus_Transport_Envelope_Decode := True;
            elsif Id = "linux.dbus.incoming_call_decode" then
               Saw_Linux_DBus_Incoming_Call_Decode := True;
            elsif Id = "linux.dbus.signal_envelope" then
               Saw_Linux_DBus_Signal_Envelope := True;
            elsif Id = "linux.dbus.prepared_signal_envelope" then
               Saw_Linux_DBus_Prepared_Signal_Envelope := True;
            elsif Id = "linux.atspi.signal.build_report" then
               Saw_Linux_ATSPI_Signal_Build_Report := True;
            elsif Id = "linux.dbus.method_boundary" then
               Saw_Linux_DBus_Method_Boundary := True;
            elsif Id = "backend.selection.runtime_override" then
               Saw_Runtime_Override := True;
            end if;
         end;
      end loop;

      return
        Saw_Core_Application
        and then Saw_Core_Window
        and then Saw_Focus_Conformance
        and then Saw_Property_Conformance
        and then Saw_Orientation_Property_Event
        and then Saw_Set_Position_Property_Event
        and then Saw_Set_Size_Property_Event
        and then Saw_Hierarchical_Level_Property_Event
        and then Saw_Role_Property_Conformance
        and then Saw_State_Set_Property_Conformance
        and then Saw_Name_Conformance
        and then Saw_Description_Conformance
        and then Saw_Help_Text_Conformance
        and then Saw_Placeholder_Conformance
        and then Saw_Value_Text_Conformance
        and then Saw_Semantic_Identifier_Conformance
        and then Saw_Locale_Property_Conformance
        and then Saw_Visible_Title_Property_Conformance
        and then Saw_Orientation_Property_Conformance
        and then Saw_Set_Position_Property_Conformance
        and then Saw_Set_Size_Property_Conformance
        and then Saw_Hierarchical_Level_Property_Conformance
        and then Saw_Heading_Level_Property_Conformance
        and then Saw_Landmark_Property_Conformance
        and then Saw_Bounds_Property_Conformance
        and then Saw_Keyboard_Shortcut_Conformance
        and then Saw_State_Conformance
        and then Saw_Bounds_Conformance
        and then Saw_Hit_Test_Conformance
        and then Saw_Tree_Conformance
        and then Saw_Window_Conformance
        and then Saw_Action_Conformance
        and then Saw_Value_Conformance
        and then Saw_Selection_Conformance
        and then Saw_Select_All_Conformance
        and then Saw_Active_Descendant_Conformance
        and then Saw_Current_Item_Conformance
        and then Saw_Node_Reference_Conformance
        and then Saw_Selection_Event_Conformance
        and then Saw_Tree_Role
        and then Saw_Tree_Item_Role
        and then Saw_Menu_Bar_Role
        and then Saw_Menu_Role
        and then Saw_Menu_Item_Role
        and then Saw_Tab_List_Role
        and then Saw_Tab_Role
        and then Saw_Tooltip_Role
        and then Saw_Text_Range_Conformance
        and then Saw_Text_Event_Conformance
        and then Saw_Table_Cell_Conformance
        and then Saw_Table_Event_Conformance
        and then Saw_Image_Conformance
        and then Saw_Document_Conformance
        and then Saw_Document_Event_Conformance
        and then Saw_Text_Protected
        and then Saw_Live_Conformance
        and then Saw_Error_Relation
        and then Saw_Relation_Event_Conformance
        and then Saw_Surface_Conformance
        and then Saw_Stale_Conformance
        and then Saw_Native_Registry
        and then Saw_Native_Export_Descriptor
        and then Saw_Windows_UIA_Host_Window_Root_Binding
        and then Saw_MacOS_NSAX_Main_Thread_Binding
        and then Saw_MacOS_NSAX_Native_View_Binding
        and then Saw_Native_Node_Index
        and then Saw_Native_Cache_Tombstone
        and then Saw_Native_Cache_Session_Scope
        and then Saw_Native_Cache_Generation
        and then Saw_Native_Cache_Mutation_Report
        and then Saw_Native_Registry_Generation
        and then Saw_Native_Registry_Mutation_Report
        and then Saw_Native_Boundary_Runtime_Generation
        and then Saw_Native_Runtime_Lifecycle
        and then Saw_Native_Runtime_Lifecycle_Report
        and then Saw_Native_Runtime_Probe_Failure_Stage
        and then Saw_Native_Runtime_Event_Application
        and then Saw_Native_Runtime_Event_Preparation
        and then Saw_Native_Runtime_Event_Preparation_Report
        and then Saw_Native_Projection_Property
        and then Saw_Native_Projection_Action
        and then Saw_Native_Projection_Relation
        and then Saw_Native_Projection_Event_Source
        and then Saw_Transport_Conformance
        and then Saw_Transport_Transition_Report
        and then Saw_Action_Payload_Conformance
        and then Saw_Action_Request_Payload_Conformance
        and then Saw_Native_Deterministic_Shutdown
        and then Saw_Diagnostics_Bounded
        and then Saw_Diagnostics_Result_Mapping
        and then Saw_Diagnostics_Field_Bounds
        and then Saw_Native_Resource_Limit
        and then Saw_Native_Value_Resource_Limit
        and then Saw_Hostile_Identity
        and then Saw_Native_Boundary_Admission_Report
        and then Saw_Native_Boundary_Native_Call_Report
        and then Saw_Native_Boundary_Completion_Report
        and then Saw_Native_Boundary_Release_Report
        and then Saw_Native_Fixture_Root_Probe
        and then Saw_Native_Fixture_Root_Failure_Stage
        and then Saw_Native_Fixture_Root_Child_Traversal
        and then Saw_Native_Fixture_Root_Child_Count
        and then Saw_Native_Fixture_Root_Second_Child
        and then Saw_Native_Fixture_Child_Query
        and then Saw_Native_Fixture_Child_Object
        and then Saw_Native_Fixture_Child_Parent
        and then Saw_Native_Fixture_Child_Native_Identity
        and then Saw_Native_Fixture_Second_Child_Parent
        and then Saw_Native_Fixture_Second_Child_Native_Identity
        and then Saw_Native_Fixture_Sibling_Order
        and then Saw_Native_Fixture_Child_Stale_Id
        and then Saw_Linux_ATSPI_Serving_Packet_Probe
        and then Saw_Linux_ATSPI_Serving_Packet_Tree_Traversal
        and then Saw_Linux_ATSPI_Serving_Packet_Property
        and then Saw_Linux_ATSPI_Serving_Packet_Property_Map
        and then Saw_Linux_ATSPI_Serving_Packet_Stale_Error
        and then Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Queued
        and then Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized
        and then Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded
        and then Saw_Linux_ATSPI_Serving_Packet_Stale_Error_Drained
        and then Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface
        and then
          Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued
        and then
          Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized
        and then
          Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded
        and then
          Saw_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained
        and then Saw_Linux_ATSPI_Serving_Packet_Malformed_Packet
        and then Saw_Linux_ATSPI_Serving_Packet_Text_Payload_Limit
        and then Saw_Linux_ATSPI_Session_Bus_Probe
        and then Saw_Linux_ATSPI_Session_Startup_Stage
        and then Saw_Linux_ATSPI_Session_Dispatch_Probe
        and then Saw_Linux_ATSPI_Session_Dispatch_Boundary_Drained
        and then Saw_Malformed_Request
        and then Saw_Linux_Error_Name_Map
        and then Saw_Linux_Error_Name_Inverse_Map
        and then Saw_Linux_Error_Name_Diagnostic
        and then Saw_Linux_DBus_Unsupported_Value
        and then Saw_Linux_DBus_UInt32_Array_Value
        and then Saw_Linux_DBus_State_Set_UInt32_Array
        and then Saw_Linux_DBus_String_Array_Value
        and then Saw_Linux_DBus_Attribute_String_Array
        and then Saw_Linux_DBus_Cache_Interface_String_Array
        and then Saw_Linux_DBus_Object_Path_Array_Value
        and then Saw_Linux_DBus_Relation_Target_Object_Path_Array
        and then Saw_Windows_HResult_Map
        and then Saw_Windows_HResult_Inverse_Map
        and then Saw_Windows_HResult_Diagnostic
        and then Saw_Windows_UIA_Event_Posting_Admission
        and then Saw_Windows_UIA_Event_Posting_Report
        and then Saw_Windows_UIA_Event_Posting_Drain_Bounded
        and then Saw_Windows_UIA_Event_Build_Report
        and then Saw_Windows_UIA_Hostile_Callback_Admission
        and then Saw_Windows_UIA_Missing_Identity
        and then Saw_Windows_UIA_Mismatched_Identity
        and then Saw_Windows_UIA_Malformed_Identity
        and then Saw_Windows_UIA_Text_Payload_Limit
        and then Saw_MacOS_Native_Status_Map
        and then Saw_MacOS_Native_Status_Inverse_Map
        and then Saw_MacOS_Native_Status_Diagnostic
        and then Saw_MacOS_NSAX_Event_Posting_Admission
        and then Saw_MacOS_NSAX_Event_Posting_Report
        and then Saw_MacOS_NSAX_Event_Posting_Drain_Bounded
        and then Saw_MacOS_NSAX_Event_Build_Report
        and then Saw_MacOS_NSAX_Hostile_Callback_Admission
        and then Saw_MacOS_NSAX_Missing_Identity
        and then Saw_MacOS_NSAX_Mismatched_Identity
        and then Saw_MacOS_NSAX_Malformed_Identity
        and then Saw_MacOS_NSAX_Text_Payload_Limit
        and then Saw_Prepared_Status_Conformance
        and then Saw_Event_Staging_Conformance
        and then Saw_Event_Posting_Interest
        and then Saw_Native_Event_Validation
        and then Saw_Native_Event_Posting_Boundary
        and then Saw_Native_Event_Exhaustive_Map
        and then Saw_Native_Role_Exhaustive_Map
        and then Saw_Native_Relation_Exhaustive_Map
        and then Saw_Method_Return_Payload
        and then Saw_Method_Return_Decode
        and then Saw_Error_Return_Decode
        and then Saw_Error_Return_Diagnostic
        and then Saw_Linux_ATSPI_Signal_Build_Report
        and then Saw_Startup_Error_Completion
        and then Saw_Incoming_Packet_Classification
        and then Saw_Incoming_Packet_Dispatch
        and then Saw_Startup_Pump_Readiness
        and then Saw_Startup_Outgoing_Work
        and then Saw_Startup_Event_Loop_Interest
        and then Saw_Startup_Event_Loop_Operation
        and then Saw_Linux_DBus_Backend_Session_Event_Loop_Step
        and then Saw_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler
        and then Saw_Startup_Outgoing_Flush
        and then Saw_Linux_DBus_Outgoing_Back_Pressure
        and then Saw_Linux_DBus_Connection_Lifecycle
        and then Saw_Linux_DBus_Local_Channel_Adapter
        and then Saw_Linux_DBus_Local_Channel_Receive
        and then Saw_Linux_DBus_Startup_Controller
        and then Saw_Linux_DBus_Startup_Backend_Adapter
        and then Saw_Linux_DBus_Startup_Pump
        and then Saw_Linux_DBus_Startup_Pump_Report
        and then Saw_Linux_DBus_Startup_Pump_Bounded_Report
        and then Saw_Linux_DBus_Startup_Pump_Bounds
        and then Saw_Linux_DBus_Startup_Registered_Pump
        and then Saw_Linux_DBus_Bus_Address
        and then Saw_Linux_DBus_Auth_External
        and then Saw_Linux_DBus_Auth_Exchange
        and then Saw_Linux_DBus_Authenticated_Connect
        and then Saw_Linux_DBus_Hello
        and then Saw_Linux_DBus_Authenticated_Hello
        and then Saw_Linux_DBus_Registration_Completion
        and then Saw_Linux_DBus_Authenticated_Registration
        and then Saw_Linux_DBus_Application_Registration
        and then Saw_Linux_ATSPI_Live_Transport_Registration_Observed
        and then Saw_Linux_DBus_Address_Discovery
        and then Saw_Linux_DBus_Host_Environment_Startup
        and then Saw_Linux_DBus_A11y_Bus_Get_Address
        and then Saw_Linux_DBus_Authenticated_Get_Address
        and then Saw_Linux_DBus_Startup_Session_Discovery
        and then Saw_Linux_DBus_Transport_Frame_Metadata
        and then Saw_Linux_DBus_Method_Call_Destination_Routing
        and then Saw_Linux_DBus_Transport_Frame_Bytes
        and then Saw_Linux_DBus_Transport_Frame_Send
        and then Saw_Linux_DBus_Transport_Packet
        and then Saw_Linux_DBus_Transport_Packet_Send
        and then Saw_Linux_DBus_Transport_Packet_Decode
        and then Saw_Linux_DBus_Codec_Basic
        and then Saw_Linux_DBus_Resource_Limits
        and then Saw_Linux_DBus_Message_Envelope
        and then Saw_Linux_DBus_Method_Call_Envelope
        and then Saw_Linux_DBus_Transport_Envelope_Decode
        and then Saw_Linux_DBus_Incoming_Call_Decode
        and then Saw_Linux_DBus_Signal_Envelope
        and then Saw_Linux_DBus_Prepared_Signal_Envelope
        and then Saw_Linux_DBus_Method_Boundary
        and then Saw_Runtime_Override
        and then Has_Extended_Fixture_Role_Observations;
   end Has_Required_Conformance_Evidence;

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Native_Identity_Kind (Client : Client_Kind) return String is
     (case Client is
        when Linux_ATSPI => "dbus_object_path",
        when Windows_UIA => "uia_runtime_id",
        when MacOS_NSAccessibility => "nsaccessibility_element_id");

   function Component_Identity
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Root    : A11y.Node_Ids.Node_Id;
      Node    : A11y.Node_Ids.Node_Id)
      return String
   is
      Result : A11y.Results.Result;
      Root_Component : Natural;
      Node_Component : Natural;
   begin
      Root_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Root, Result);
      if A11y.Results.Failed (Result) then
         return "none";
      end if;

      Node_Component :=
        A11y.Native_Identity.Runtime_Identifier_Component
          (Session, Node, Result);
      if A11y.Results.Failed (Result) then
         return "none";
      end if;

      return
        "session:"
        & A11y.Native_Identity.Image (Session)
        & ";root:"
        & Trimmed_Image (Root_Component)
        & ";node:"
        & Trimmed_Image (Node_Component);
   end Component_Identity;

   function Linux_Object_Path
     (Session : A11y.Native_Identity.Backend_Session_Id;
      Node    : A11y.Node_Ids.Node_Id)
      return String
   is
   begin
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         return "none";
      end if;

      return
        Linux_Path_Prefix
        & A11y.Native_Identity.Image (Session)
        & Linux_Path_Node_Sep
        & Trimmed_Image (A11y.Node_Ids.To_Natural (Node));
   end Linux_Object_Path;

   function Native_Identity_Value
     (Client  : Client_Kind;
      Session : A11y.Native_Identity.Backend_Session_Id;
      Node    : A11y.Node_Ids.Node_Id)
      return String
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return "none";
      end if;

      case Client is
         when Linux_ATSPI =>
            return Linux_Object_Path (Session, Node);
         when Windows_UIA | MacOS_NSAccessibility =>
            return Component_Identity
         (Session, A11y_Test_Fixtures.Application_Id, Node);
      end case;
   end Native_Identity_Value;

   function Client_Report_Complete (Client : Client_Kind) return Boolean is
      Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
   begin
      if Status_Name (Client) /= "native_conformance_ready"
        and then Status_Name (Client) /= "blocked_transport_unavailable"
      then
         return False;
      end if;

      if Observation_Count /= 500
        or else Protected_Observation_Count /= 1
        or else Lifecycle_Observation_Count /= 1
        or else Transport_Observation_Count /= 394
        or else
          Semantic_Node_Identity_Count /= Observation_Count - Transport_Observation_Count
        or else not Has_Native_Registry_Observation
        or else not Has_Native_Export_Descriptor_Observation
        or else not Has_Windows_UIA_Host_Window_Root_Binding_Observation
        or else not Has_Windows_UIA_COM_VTable_Observation
        or else not Has_Windows_UIA_COM_Object_Export_Observation
        or else not Has_Windows_UIA_COM_Live_Export_Observation
        or else not Has_Windows_UIA_Bridge_Audit_Observation
        or else not Has_Windows_UIA_COM_Live_Interface_Retain_Observation
        or else not Has_Windows_UIA_COM_Live_Interface_Release_Observation
        or else not Has_Windows_UIA_COM_Live_Released_Interface_Observation
        or else
          not Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation
        or else
          not Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation
        or else
          not Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation
        or else
          not Has_Windows_UIA_Registered_Routed_Error_Status_Observation
        or else
          not Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation
        or else
          not Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation
        or else not Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation
        or else
          not Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation
        or else not Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation
        or else
          not Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation
        or else not Has_Windows_UIA_COM_Live_Provider_Options_Observation
        or else
          not Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation
        or else
          not Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation
        or else
          not Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation
        or else not Has_Windows_UIA_COM_Live_Fragment_Root_Observation
        or else not Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation
        or else not Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation
        or else
          not Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
        or else not Has_Windows_UIA_Public_Root_Export_Path_Observation
        or else not Has_Windows_UIA_Public_Root_Native_Identity_Observation
        or else
          not Has_Windows_UIA_External_Client_Full_Frame_Callback_Observation
        or else not Has_Windows_UIA_External_Client_Failure_Stage_Observation
        or else not Has_Windows_UIA_External_Client_Metadata_Observation
        or else not Has_Windows_UIA_External_Client_Protected_Value_Observation
        or else not Has_MacOS_NSAX_Main_Thread_Binding_Observation
        or else not Has_MacOS_NSAX_Native_View_Binding_Observation
        or else not Has_MacOS_NSAX_Selector_Attribute_Value_Observation
        or else not Has_MacOS_NSAX_Selector_Children_Frame_Observation
        or else
          not Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation
        or else not Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation
        or else not Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation
        or else not Has_MacOS_NSAX_Selector_Action_Frame_Observation
        or else not Has_MacOS_NSAX_Selector_Unsupported_Observation
        or else not Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation
        or else
          not Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation
        or else
          not Has_MacOS_NSAX_Registered_Routed_Error_Status_Observation
        or else not Has_MacOS_NSAX_Released_Boundary_Observation
        or else not Has_MacOS_NSAX_Bridge_Audit_Observation
        or else not Has_MacOS_NSAX_Virtual_Element_Bridge_Observation
        or else not Has_MacOS_NSAX_External_Client_Element_Chain_Observation
        or else not Has_MacOS_NSAX_Public_Root_Export_Path_Observation
        or else not Has_MacOS_NSAX_Public_Root_Native_Identity_Observation
        or else not Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation
        or else not
          Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation
        or else not Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation
        or else not Has_MacOS_NSAX_External_Client_Failure_Stage_Observation
        or else not Has_MacOS_NSAX_External_Client_Metadata_Observation
        or else not
          Has_MacOS_NSAX_External_Client_Protected_Value_Observation
        or else not Has_Native_Node_Index_Observation
        or else not Has_Native_Cache_Tombstone_Observation
        or else not Has_Native_Cache_Session_Scope_Observation
        or else not Has_Native_Cache_Generation_Observation
        or else not Has_Native_Cache_Mutation_Report_Observation
        or else not Has_Native_Registry_Generation_Observation
        or else not Has_Native_Registry_Drained_Reset_Observation
        or else not Has_Native_Registry_Mutation_Report_Observation
        or else not Has_Native_Boundary_Runtime_Generation_Observation
        or else not Has_Native_Runtime_Lifecycle_Observation
        or else not Has_Native_Runtime_Lifecycle_Report_Observation
        or else not Has_Native_Runtime_Probe_Failure_Stage_Observation
        or else not Has_Native_Runtime_Event_Application_Observation
        or else not Has_Native_Runtime_Event_Preparation_Observation
        or else not Has_Native_Runtime_Event_Preparation_Report_Observation
        or else not Has_Native_Projection_Property_Observation
        or else not Has_Native_Projection_Action_Observation
        or else not Has_Native_Projection_Relation_Observation
        or else not Has_Native_Projection_Event_Source_Observation
        or else not Has_Native_Deterministic_Shutdown_Observation
        or else not Has_Diagnostics_Bounded_Observation
        or else not Has_Diagnostics_Result_Mapping_Observation
        or else not Has_Diagnostics_Field_Bounds_Observation
        or else not Has_Native_Resource_Limit_Observation
        or else not Has_Native_Value_Resource_Limit_Observation
        or else not Has_Hostile_Identity_Observation
        or else not Has_Native_Boundary_Admission_Report_Observation
        or else not Has_Native_Boundary_Completion_Report_Observation
        or else not Has_Native_Boundary_Release_Report_Observation
        or else not Has_Native_Fixture_Root_Probe_Observation
        or else not Has_Native_Fixture_Root_Failure_Stage_Observation
        or else not Has_Native_Fixture_Root_Child_Traversal_Observation
        or else not Has_Native_Fixture_Root_Child_Count_Observation
        or else not Has_Native_Fixture_Root_Second_Child_Observation
        or else not Has_Native_Fixture_Child_Query_Observation
        or else not Has_Native_Fixture_Child_Object_Observation
        or else not Has_Native_Fixture_Child_Parent_Observation
        or else not Has_Native_Fixture_Child_Native_Identity_Observation
        or else not Has_Native_Fixture_Second_Child_Parent_Observation
        or else not
          Has_Native_Fixture_Second_Child_Native_Identity_Observation
        or else not Has_Native_Fixture_Sibling_Order_Observation
        or else not Has_Native_Fixture_Child_Stale_Id_Observation
        or else not Has_Linux_ATSPI_Serving_Packet_Probe_Observation
        or else not Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation
        or else not Has_Linux_ATSPI_Serving_Packet_Property_Observation
        or else not Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation
        or else not Has_Linux_ATSPI_Serving_Packet_Stale_Error_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation
        or else not
          Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation
        or else not Has_Linux_ATSPI_Serving_Packet_Full_Observations
        or else not Has_Linux_ATSPI_Session_Bus_Probe_Observation
        or else not Has_Linux_ATSPI_Live_External_Client_Observation
        or else not
          Has_Linux_ATSPI_Live_Registered_External_Client_Observation
        or else not
          Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
        or else not
          Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation
        or else not
          Has_Linux_ATSPI_Live_External_Client_Attribute_Observation
        or else not
          Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations
        or else not
          Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation
        or else not Has_Linux_ATSPI_Session_Startup_Stage_Observation
        or else not Has_Linux_ATSPI_Startup_Object_Path_Observation
        or else not Has_Linux_ATSPI_Session_Dispatch_Probe_Observation
        or else not
          Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation
        or else not
          Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation
        or else not Has_Malformed_Request_Observation
        or else not Has_Linux_Error_Name_Map_Observation
        or else not Has_Linux_Error_Name_Inverse_Map_Observation
        or else not Has_Linux_Error_Name_Diagnostic_Observation
        or else not Has_Linux_ATSPI_Core_Method_Observations
        or else not Has_Linux_ATSPI_Interaction_Method_Observations
        or else not Has_Linux_ATSPI_Content_Method_Observations
        or else not Has_Linux_ATSPI_Document_Surface_Event_Observations
        or else not Has_Native_Boundary_Runtime_Generation_Observation
        or else not Has_Linux_DBus_Unsupported_Value_Observation
        or else not Has_Linux_DBus_UInt32_Array_Value_Observation
        or else not Has_Linux_DBus_State_Set_UInt32_Array_Observation
        or else not Has_Linux_DBus_String_Array_Value_Observation
        or else not Has_Linux_DBus_Attribute_String_Array_Observation
        or else not Has_Linux_DBus_Cache_Interface_String_Array_Observation
        or else not Has_Linux_DBus_Object_Path_Array_Value_Observation
        or else not Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation
        or else not Has_Windows_HResult_Map_Observation
        or else not Has_Windows_HResult_Inverse_Map_Observation
        or else not Has_Windows_HResult_Diagnostic_Observation
        or else not Has_Windows_UIA_Event_Posting_Report_Observation
        or else not Has_Observation
          ("native.windows_uia_event_build_report",
           "windows.uia.event.build_report",
           A11y.Node_Ids.No_Node,
           A11y.Roles.Application)
        or else not Has_Windows_UIA_Core_Routing_Observations
        or else not Has_Windows_UIA_Advanced_Routing_Observations
        or else not Has_Windows_UIA_Hostile_Callback_Admission_Observation
        or else not Has_Windows_UIA_Missing_Identity_Observation
        or else not Has_Windows_UIA_Mismatched_Identity_Observation
        or else not Has_Windows_UIA_Malformed_Identity_Observation
        or else not Has_Windows_UIA_Text_Payload_Limit_Observation
        or else not Has_MacOS_Native_Status_Map_Observation
        or else not Has_MacOS_Native_Status_Inverse_Map_Observation
        or else not Has_MacOS_Native_Status_Diagnostic_Observation
        or else not Has_MacOS_NSAX_Event_Posting_Report_Observation
        or else not Has_Observation
          ("native.macos_nsax_event_build_report",
           "macos.nsaccessibility.event.build_report",
           A11y.Node_Ids.No_Node,
           A11y.Roles.Application)
        or else not Has_MacOS_NSAX_Core_Routing_Observations
        or else not Has_MacOS_NSAX_Advanced_Routing_Observations
        or else not Has_MacOS_NSAX_Hostile_Callback_Admission_Observation
        or else not Has_MacOS_NSAX_Missing_Identity_Observation
        or else not Has_MacOS_NSAX_Mismatched_Identity_Observation
        or else not Has_MacOS_NSAX_Malformed_Identity_Observation
        or else not Has_MacOS_NSAX_Text_Payload_Limit_Observation
        or else not Has_Transport_Staging_Observation
        or else not Has_Transport_Generation_Observation
        or else not Has_Transport_Transition_Report_Observation
        or else not Has_Native_Cache_Generation_Observation
        or else not Has_Native_Cache_Mutation_Report_Observation
        or else not Has_Prepared_Status_Observation
        or else not Has_Event_Posting_Interest_Observation
        or else not Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation
        or else not Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation
        or else not Has_Native_Event_Validation_Observation
        or else not Has_Native_Event_Posting_Boundary_Observation
        or else not Has_Native_Event_Exhaustive_Map_Observation
        or else not Has_Native_Role_Exhaustive_Map_Observation
        or else not Has_Native_Relation_Exhaustive_Map_Observation
        or else not Has_Linux_ATSPI_Signal_Build_Report_Observation
        or else not Has_Method_Return_Decode_Observation
        or else not Has_Error_Return_Decode_Observation
        or else not Has_Error_Return_Diagnostic_Observation
        or else not Has_Startup_Error_Completion_Observation
        or else not Has_Startup_Outgoing_Work_Observation
        or else not Has_Startup_Event_Loop_Interest_Observation
        or else not Has_Startup_Event_Loop_Operation_Observation
        or else
          not Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation
        or else not
          Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation
        or else not
          Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation
        or else not Has_Startup_Outgoing_Flush_Observation
        or else not Has_Linux_DBus_Outgoing_Back_Pressure_Observation
        or else not Has_Linux_DBus_Connection_Lifecycle_Observation
        or else not Has_Linux_DBus_Local_Channel_Adapter_Observation
        or else not Has_Linux_DBus_Local_Channel_Receive_Observation
        or else not Has_Linux_DBus_Startup_Controller_Observation
        or else not Has_Linux_DBus_Startup_Backend_Adapter_Observation
        or else not Has_Linux_DBus_Startup_Pump_Observation
        or else not Has_Linux_DBus_Startup_Pump_Report_Observation
        or else not Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation
        or else not Has_Linux_DBus_Startup_Pump_Bounds_Observation
        or else not Has_Linux_DBus_Startup_Registered_Pump_Observation
        or else not Has_Linux_DBus_Bus_Address_Observation
        or else not Has_Linux_DBus_Auth_External_Observation
        or else not Has_Linux_DBus_Auth_Exchange_Observation
        or else not Has_Linux_DBus_Authenticated_Connect_Observation
        or else not Has_Linux_DBus_Hello_Observation
        or else not Has_Linux_DBus_Authenticated_Hello_Observation
        or else not Has_Linux_DBus_Registration_Completion_Observation
        or else not Has_Linux_DBus_Authenticated_Registration_Observation
        or else not Has_Linux_DBus_Startup_Reply_Evidence_Observation
        or else not Has_Linux_DBus_Application_Registration_Observation
        or else not
          Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation
        or else not Has_Linux_DBus_Address_Discovery_Observation
        or else not Has_Linux_DBus_Host_Environment_Startup_Observation
        or else not Has_Linux_DBus_A11y_Bus_Get_Address_Observation
        or else not Has_Linux_DBus_Authenticated_Get_Address_Observation
        or else not Has_Linux_DBus_Startup_Session_Discovery_Observation
        or else not Has_Linux_DBus_Transport_Frame_Metadata_Observation
        or else not Has_Linux_DBus_Method_Call_Destination_Routing_Observation
        or else not Has_Linux_DBus_Transport_Frame_Bytes_Observation
        or else not Has_Linux_DBus_Transport_Frame_Send_Observation
        or else not Has_Linux_DBus_Transport_Packet_Observation
        or else not Has_Linux_DBus_Transport_Packet_Send_Observation
        or else not Has_Linux_DBus_Transport_Packet_Decode_Observation
        or else not Has_Linux_DBus_Codec_Basic_Observation
        or else not Has_Linux_DBus_Resource_Limits_Observation
        or else not Has_Linux_DBus_Message_Envelope_Observation
        or else not Has_Linux_DBus_Method_Call_Envelope_Observation
        or else not Has_Linux_DBus_Transport_Envelope_Decode_Observation
        or else not Has_Linux_DBus_Incoming_Call_Decode_Observation
        or else not Has_Linux_DBus_Signal_Envelope_Observation
        or else not Has_Linux_DBus_Prepared_Signal_Envelope_Observation
        or else not Has_Linux_ATSPI_Signal_Build_Report_Observation
        or else not Has_Linux_DBus_Method_Boundary_Observation
        or else not Has_Focus_Observation
        or else not Has_Property_Change_Observation
        or else not Has_Orientation_Property_Event_Observation
        or else not Has_Set_Position_Property_Event_Observation
        or else not Has_Set_Size_Property_Event_Observation
        or else not Has_Hierarchical_Level_Property_Event_Observation
        or else not Has_Role_Property_Observation
        or else not Has_State_Set_Property_Observation
        or else not Has_Name_Observation
        or else not Has_Description_Observation
        or else not Has_Help_Text_Observation
        or else not Has_Placeholder_Observation
        or else not Has_Value_Text_Observation
        or else not Has_Semantic_Identifier_Observation
        or else not Has_Locale_Property_Observation
        or else not Has_Visible_Title_Property_Observation
        or else not Has_Orientation_Property_Observation
        or else not Has_Set_Position_Property_Observation
        or else not Has_Set_Size_Property_Observation
        or else not Has_Hierarchical_Level_Property_Observation
        or else not Has_Heading_Level_Property_Observation
        or else not Has_Landmark_Property_Observation
        or else not Has_Bounds_Property_Observation
        or else not Has_Keyboard_Shortcut_Observation
        or else not Has_State_Change_Observation
        or else not Has_Bounds_Observation
        or else not Has_Hit_Test_Observation
        or else not Has_Tree_Change_Observation
        or else not Has_Window_Event_Observation
        or else not Has_Activate_Action_Observation
        or else not Has_Action_Observation
        or else not Has_Toggle_Action_Observation
        or else not Has_Expand_Action_Observation
        or else not Has_Collapse_Action_Observation
        or else not Has_Show_Menu_Action_Observation
        or else not Has_Dismiss_Action_Observation
        or else not Has_Open_Action_Observation
        or else not Has_Close_Action_Observation
        or else not Has_Scroll_Action_Observation
        or else not Has_Set_Focus_Action_Observation
        or else not Has_Action_Payload_Observation
        or else not Has_Action_Request_Payload_Observation
        or else not Has_Value_Observation
        or else not Has_Selection_Observation
        or else not Has_Select_All_Observation
        or else not Has_Selection_Event_Observation
        or else not Has_Active_Descendant_Observation
        or else not Has_Active_Descendant_Event_Observation
        or else not Has_Current_Item_Observation
        or else not Has_Current_Item_Event_Observation
        or else not Has_Tree_Role_Observation
        or else not Has_Tree_Item_Role_Observation
        or else not Has_Menu_Bar_Role_Observation
        or else not Has_Menu_Role_Observation
        or else not Has_Menu_Item_Role_Observation
        or else not Has_Tab_List_Role_Observation
        or else not Has_Tab_Role_Observation
        or else not Has_Tooltip_Role_Observation
        or else not Has_Status_Role_Observation
        or else not Has_Image_Role_Observation
        or else not Has_Decorative_Image_Role_Observation
        or else not Has_Vertical_Slice_Role_Observations
        or else not Has_Extended_Fixture_Role_Observations
        or else not Has_Fixture_Command_Coverage
        or else not Has_Text_Observation
        or else not Has_Text_Mutation_Observation
        or else not Has_Text_Set_Observation
        or else not Has_Caret_Observation
        or else not Has_Table_Observation
        or else not Has_Table_Current_Cell_Observation
        or else not Has_Table_Sort_Metadata_Observation
        or else not Has_Table_Event_Observation
        or else not Has_Image_Observation
        or else not Has_Document_Observation
        or else not Has_Document_Event_Observation
        or else not Has_Protected_Text_Observation
        or else not Has_Live_Region_Observation
        or else not Has_Relation_Observation
        or else not Has_Relation_Event_Observation
        or else not Has_Surface_Observation
        or else not Has_Lifecycle_Observation
        or else not Has_Required_Conformance_Evidence
      then
         return False;
      end if;

      for Observation of Observations loop
         declare
            Identity : constant String :=
              Native_Identity_Value (Client, Session, Observation.Node);
         begin
            if A11y.Node_Ids.Is_Valid (Observation.Node) then
               if Identity = "none" then
                  return False;
               end if;
            elsif Identity /= "none" then
               return False;
            end if;
         end;
      end loop;

      return True;
   end Client_Report_Complete;

   function All_Client_Reports_Blocked return Boolean is
   begin
      for Client in Client_Kind loop
         if Status_Name (Client) /= "blocked_transport_unavailable"
           or else not Client_Report_Complete (Client)
         then
            return False;
         end if;
      end loop;
      return True;
   end All_Client_Reports_Blocked;

   function JSON (Client : Client_Kind) return String is
      Result : Unbounded_String;
      Session : constant A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.Create_Session;
   begin
      Append (Result, "{" & ASCII.LF);
      Append (Result, "  ""schema"": " & Q (Schema) & "," & ASCII.LF);
      Append
        (Result,
         "  ""client_process"": "
         & Q (Client_Process_Name (Client))
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""platform"": "
         & Q (Platform_Name (Client))
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""native_api"": "
         & Q (Native_API_Name (Client))
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""fixture_schema"": "
         & Q (Fixture_Schema)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""fixture_ready"": true,"
         & ASCII.LF);
      Append
        (Result,
         "  ""fixture_command_results"": "
         & Natural'Image (Natural (A11y_Test_Fixtures.Script.Length))
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""status"": "
         & Q (Status_Name (Client))
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""normalized_output"": "
         & Q ("normalized_semantic_vocabulary")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""observation_count"": "
         & Natural'Image (Observation_Count)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""complete"": "
         & (if Client_Report_Complete (Client) then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_required_conformance_evidence"": "
         & (if Has_Required_Conformance_Evidence then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_host_window_root_binding_observation"": "
         & (if Has_Windows_UIA_Host_Window_Root_Binding_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_bridge_audit_observation"": "
         & (if Has_Windows_UIA_Bridge_Audit_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_interface_retain_observation"": "
         & (if Has_Windows_UIA_COM_Live_Interface_Retain_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_interface_release_observation"": "
         & (if Has_Windows_UIA_COM_Live_Interface_Release_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_released_interface_observation"": "
         & (if Has_Windows_UIA_COM_Live_Released_Interface_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_invalid_interface_frame_observation"": "
         & (if
              Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_invalid_method_frame_observation"": "
         & (if Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_interface_method_mismatch_observation"": "
         & (if
              Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_registered_routed_error_status_observation"": "
         & (if
              Has_Windows_UIA_Registered_Routed_Error_Status_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_simple_property_frame_observation"": "
         & (if
              Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_action_frame_observation"": "
         & (if
              Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_navigate_observation"": "
         & (if Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_last_child_frame_observation"": "
         & (if
              Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_runtime_id_observation"": "
         & (if Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_embedded_fragment_roots_observation"": "
         & (if Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_provider_options_observation"": "
         & (if Has_Windows_UIA_COM_Live_Provider_Options_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_host_raw_element_provider_observation"": "
         & (if Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_pattern_provider_frame_observation"": "
         & (if Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_bounding_rectangle_frame_observation"": "
         & (if Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_root_observation"": "
         & (if Has_Windows_UIA_COM_Live_Fragment_Root_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_root_point_observation"": "
         & (if Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_com_live_fragment_root_focus_observation"": "
         & (if Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_com_live_chain_observation"": "
         & (if
              Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_public_root_export_path_observation"": "
         & (if Has_Windows_UIA_Public_Root_Export_Path_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_public_root_native_identity_observation"": "
         & (if Has_Windows_UIA_Public_Root_Native_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_embedded_fragment_roots_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_provider_options_observation"": "
         & (if Has_Windows_UIA_External_Client_Provider_Options_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_host_raw_element_provider_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_fragment_root_observation"": "
         & (if Has_Windows_UIA_External_Client_Fragment_Root_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_fragment_root_point_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_fragment_root_focus_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_fragment_last_child_frame_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_bounding_rectangle_frame_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_pattern_provider_frame_observation"": "
         & (if
              Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_simple_property_frame_observation"": "
         & (if Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_full_frame_callback_observation"": "
         & (if Has_Windows_UIA_External_Client_Full_Frame_Callback_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_action_frame_observation"": "
         & (if Has_Windows_UIA_External_Client_Action_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_failure_stage_observation"": "
         & (if Has_Windows_UIA_External_Client_Failure_Stage_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_metadata_observation"": "
         & (if Has_Windows_UIA_External_Client_Metadata_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_metadata_group_observation"": "
         & (if Has_Windows_UIA_External_Client_Metadata_Group_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_protected_value_observation"": "
         & (if Has_Windows_UIA_External_Client_Protected_Value_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_external_client_privacy_boundary_observation"": "
         & (if Has_Windows_UIA_External_Client_Privacy_Boundary_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_internal_native_export_chain_ready"": "
         & (if Has_Windows_UIA_Internal_Native_Export_Chain_Ready then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_main_thread_binding_observation"": "
         & (if Has_MacOS_NSAX_Main_Thread_Binding_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_native_view_binding_observation"": "
         & (if Has_MacOS_NSAX_Native_View_Binding_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_attribute_value_observation"": "
         & (if Has_MacOS_NSAX_Selector_Attribute_Value_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_children_frame_observation"": "
         & (if Has_MacOS_NSAX_Selector_Children_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_child_at_index_frame_observation"": "
         & (if Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_attribute_value_frame_observation"": "
         & (if Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_attribute_settable_frame_observation"": "
         & (if Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_action_frame_observation"": "
         & (if Has_MacOS_NSAX_Selector_Action_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_unsupported_observation"": "
         & (if Has_MacOS_NSAX_Selector_Unsupported_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selector_main_thread_gate_observation"": "
         & (if Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_registered_method_family_mismatch_observation"": "
         & (if
              Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_registered_routed_error_status_observation"": "
         & (if
              Has_MacOS_NSAX_Registered_Routed_Error_Status_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_released_boundary_observation"": "
         & (if Has_MacOS_NSAX_Released_Boundary_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_bridge_audit_observation"": "
         & (if Has_MacOS_NSAX_Bridge_Audit_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_virtual_element_bridge_observation"": "
         & (if Has_MacOS_NSAX_Virtual_Element_Bridge_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_element_chain_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Element_Chain_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_public_root_export_path_observation"": "
         & (if Has_MacOS_NSAX_Public_Root_Export_Path_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_public_root_native_identity_observation"": "
         & (if Has_MacOS_NSAX_Public_Root_Native_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_public_root_hit_test_frame_observation"": "
         & (if Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_public_root_focused_element_frame_observation"": "
         & (if
              Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_public_root_notification_frame_observation"": "
         & (if Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_main_thread_binding_observation"": "
         & (if
              Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_native_view_binding_observation"": "
         & (if
              Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_children_frame_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Children_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_child_at_index_frame_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_attribute_settable_frame_observation"": "
         & (if
              Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_action_frame_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Action_Frame_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_failure_stage_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Failure_Stage_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_metadata_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Metadata_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_metadata_group_observation"": "
         & (if Has_MacOS_NSAX_External_Client_Metadata_Group_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_protected_value_observation"": "
         & (if
              Has_MacOS_NSAX_External_Client_Protected_Value_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_external_client_privacy_boundary_observation"": "
         & (if
              Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_internal_native_export_chain_ready"": "
         & (if Has_MacOS_NSAX_Internal_Native_Export_Chain_Ready then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_cache_generation_observation"": "
         & (if Has_Native_Cache_Generation_Observation then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_cache_mutation_report_observation"": "
         & (if Has_Native_Cache_Mutation_Report_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_registry_generation_observation"": "
         & (if Has_Native_Registry_Generation_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_registry_drained_reset_observation"": "
         & (if Has_Native_Registry_Drained_Reset_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_registry_mutation_report_observation"": "
         & (if Has_Native_Registry_Mutation_Report_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_boundary_runtime_generation_observation"": "
         & (if Has_Native_Boundary_Runtime_Generation_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_boundary_native_call_report_observation"": "
         & (if Has_Native_Boundary_Native_Call_Report_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_root_probe_observation"": "
         & (if Has_Native_Fixture_Root_Probe_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_root_failure_stage_observation"": "
         & (if Has_Native_Fixture_Root_Failure_Stage_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_root_child_traversal_observation"": "
         & (if Has_Native_Fixture_Root_Child_Traversal_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_root_child_count_observation"": "
         & (if Has_Native_Fixture_Root_Child_Count_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_root_second_child_observation"": "
         & (if Has_Native_Fixture_Root_Second_Child_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_child_query_observation"": "
         & (if Has_Native_Fixture_Child_Query_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_child_object_observation"": "
         & (if Has_Native_Fixture_Child_Object_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_child_parent_observation"": "
         & (if Has_Native_Fixture_Child_Parent_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_child_native_identity_observation"": "
         & (if Has_Native_Fixture_Child_Native_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_second_child_parent_observation"": "
         & (if Has_Native_Fixture_Second_Child_Parent_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_second_child_native_identity_observation"": "
         & (if Has_Native_Fixture_Second_Child_Native_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_sibling_order_observation"": "
         & (if Has_Native_Fixture_Sibling_Order_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_fixture_child_stale_id_observation"": "
         & (if Has_Native_Fixture_Child_Stale_Id_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_probe_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Probe_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_tree_traversal_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_property_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Property_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_property_map_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_core_observations"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Core_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_interaction_observations"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Interaction_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_content_observations"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Content_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_stale_error_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Stale_Error_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_stale_error_queued_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_stale_error_serialized_observation"": "
         & (if
              Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_stale_error_decoded_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_stale_error_drained_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_unsupported_interface_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_unsupported_interface_queued_observation"": "
         & (if
              Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_unsupported_interface_serialized_observation"": "
         & (if
              Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_unsupported_interface_decoded_observation"": "
         & (if
              Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_unsupported_interface_drained_observation"": "
         & (if
              Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_malformed_packet_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_text_payload_limit_observation"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_serving_packet_full_observations"": "
         & (if Has_Linux_ATSPI_Serving_Packet_Full_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_session_bus_probe_observation"": "
         & (if Has_Linux_ATSPI_Session_Bus_Probe_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_registered_external_client_observation"": "
         & (if Has_Linux_ATSPI_Live_Registered_External_Client_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_vertical_slice_observations"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_failure_stage_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_attribute_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Attribute_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_attribute_detail_observations"": "
         & (if
              Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_protected_value_observation"": "
         & (if
              Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_component_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Component_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_action_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Action_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_value_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Value_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_selection_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Selection_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_text_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Text_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_image_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Image_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_document_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Document_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_table_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Table_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_surface_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Surface_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_live_external_client_live_region_observation"": "
         & (if Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_session_startup_stage_observation"": "
         & (if Has_Linux_ATSPI_Session_Startup_Stage_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_startup_object_path_observation"": "
         & (if Has_Linux_ATSPI_Startup_Object_Path_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_session_dispatch_probe_observation"": "
         & (if Has_Linux_ATSPI_Session_Dispatch_Probe_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_session_dispatch_boundary_drain_observation"": "
         & (if Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_session_dispatch_loop_report_observation"": "
         & (if Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_dbus_backend_session_transport_cycle_scheduler_observation"": "
         & (if
              Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation
            then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_registered_boundary_report_observation"": "
         & (if Has_Linux_ATSPI_Registered_Boundary_Report_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_dbus_startup_reply_evidence_observation"": "
         & (if Has_Linux_DBus_Startup_Reply_Evidence_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_runtime_lifecycle_report_observation"": "
         & (if Has_Native_Runtime_Lifecycle_Report_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_native_runtime_probe_failure_stage_observation"": "
         & (if Has_Native_Runtime_Probe_Failure_Stage_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_transport_transition_report_observation"": "
         & (if Has_Transport_Transition_Report_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_core_method_observations"": "
         & (if Has_Linux_ATSPI_Core_Method_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_interaction_method_observations"": "
         & (if Has_Linux_ATSPI_Interaction_Method_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_component_focus_observation"": "
         & (if Has_Linux_ATSPI_Component_Focus_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_selection_deselect_observation"": "
         & (if Has_Linux_ATSPI_Selection_Deselect_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_selection_select_all_observation"": "
         & (if Has_Linux_ATSPI_Selection_Select_All_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_selection_clear_observation"": "
         & (if Has_Linux_ATSPI_Selection_Clear_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_content_method_observations"": "
         & (if Has_Linux_ATSPI_Content_Method_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_atspi_document_surface_event_observations"": "
         & (if Has_Linux_ATSPI_Document_Surface_Event_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_linux_dbus_startup_registered_pump_observation"": "
         & (if Has_Linux_DBus_Startup_Registered_Pump_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_core_routing_observations"": "
         & (if Has_Windows_UIA_Core_Routing_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_metadata_property_observation"": "
         & (if Has_Windows_UIA_Metadata_Property_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_protected_value_observation"": "
         & (if Has_Windows_UIA_Protected_Value_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_advanced_routing_observations"": "
         & (if Has_Windows_UIA_Advanced_Routing_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_selection_select_all_observation"": "
         & (if Has_Windows_UIA_Selection_Select_All_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_selection_clear_observation"": "
         & (if Has_Windows_UIA_Selection_Clear_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_native_focus_query_observation"": "
         & (if Has_Windows_UIA_Native_Focus_Query_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_native_set_focus_observation"": "
         & (if Has_Windows_UIA_Native_Set_Focus_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_hostile_callback_admission_observation"": "
         & (if Has_Windows_UIA_Hostile_Callback_Admission_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_missing_identity_observation"": "
         & (if Has_Windows_UIA_Missing_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_mismatched_identity_observation"": "
         & (if Has_Windows_UIA_Mismatched_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_malformed_identity_observation"": "
         & (if Has_Windows_UIA_Malformed_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_windows_uia_text_payload_limit_observation"": "
         & (if Has_Windows_UIA_Text_Payload_Limit_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_core_routing_observations"": "
         & (if Has_MacOS_NSAX_Core_Routing_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_metadata_attribute_observation"": "
         & (if Has_MacOS_NSAX_Metadata_Attribute_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_protected_value_observation"": "
         & (if Has_MacOS_NSAX_Protected_Value_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_advanced_routing_observations"": "
         & (if Has_MacOS_NSAX_Advanced_Routing_Observations then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selection_select_all_observation"": "
         & (if Has_MacOS_NSAX_Selection_Select_All_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_selection_clear_observation"": "
         & (if Has_MacOS_NSAX_Selection_Clear_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_native_focus_query_observation"": "
         & (if Has_MacOS_NSAX_Native_Focus_Query_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_native_set_focus_observation"": "
         & (if Has_MacOS_NSAX_Native_Set_Focus_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_hostile_callback_admission_observation"": "
         & (if Has_MacOS_NSAX_Hostile_Callback_Admission_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_missing_identity_observation"": "
         & (if Has_MacOS_NSAX_Missing_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_mismatched_identity_observation"": "
         & (if Has_MacOS_NSAX_Mismatched_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_malformed_identity_observation"": "
         & (if Has_MacOS_NSAX_Malformed_Identity_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""has_macos_nsax_text_payload_limit_observation"": "
         & (if Has_MacOS_NSAX_Text_Payload_Limit_Observation then
              "true"
            else
              "false")
         & ","
         & ASCII.LF);
      Append (Result, "  ""observations"": [" & ASCII.LF);

      for Index in Observations'Range loop
         declare
            Observation : Observation_Record renames Observations (Index);
            Suffix : constant String :=
              (if Index = Observations'Last then "" else ",");
         begin
            Append
              (Result,
               "    {"
               & """feature"": "
               & Q (Trimmed (Observation.Feature))
               & ", ""conformance_id"": "
               & Q (Trimmed (Observation.Conformance_Id))
               & ", ""node"": "
               & Q (A11y.Node_Ids.Image (Observation.Node))
               & ", ""role"": "
               & Q (A11y.Roles.Stable_Name (Observation.Role))
               & ", ""status"": "
               & Q (Trimmed (Observation.Status))
               & ", ""privacy"": "
               & Q (Trimmed (Observation.Privacy))
               & ", ""native_resolution"": "
               & Q (Trimmed (Observation.Native_Resolution))
               & ", ""native_identity_kind"": "
               & Q (Native_Identity_Kind (Client))
               & ", ""native_identity"": "
               & Q
                 (Native_Identity_Value
                    (Client, Session, Observation.Node))
               & "}"
               & Suffix
               & ASCII.LF);
         end;
      end loop;

      Append (Result, "  ]" & ASCII.LF);
      Append (Result, "}" & ASCII.LF);
      return To_String (Result);
   end JSON;

end A11y_Native_Client_Reports;
