with Ada.Directories;
with Ada.Text_IO;
with Ada.Strings;
with Ada.Strings.Fixed;
with Ada.Strings.Unbounded;

with Project_Tools.JSON;
with Project_Tools.Files;
with Hostkit.Process;

package body A11y_Release_Qualification is
   use Ada.Strings.Unbounded;

   type Platform_Id is (Linux, Windows, MacOS);
   type Scenario_Id is
     (Fixture_Readiness,
      Tree_Traversal,
      Focus_And_Activation,
      Action_Requests,
      Protected_Text,
      Relations,
      Live_Announcement,
      Window_Lifecycle,
      Voice_Control,
      Switch_Access);

   type Scenario_Record is record
      Platform : Platform_Id;
      Assistive_Technology : String (1 .. 32);
      OS_Version : String (1 .. 32);
      AT_Version : String (1 .. 32);
      Scenario : Scenario_Id;
      Steps : String (1 .. 96);
      Expected : String (1 .. 96);
      Observed : String (1 .. 96);
      Evidence : String (1 .. 96);
      Native_Probe_Command : String (1 .. 128);
      Conformance_Feature_Id : String (1 .. 96);
      Limitation : String (1 .. 32);
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

   function Platform_Name (Platform : Platform_Id) return String is
     (case Platform is
        when Linux => "Linux",
        when Windows => "Windows",
        when MacOS => "macOS");

   function Scenario_Name (Scenario : Scenario_Id) return String is
     (case Scenario is
        when Fixture_Readiness => "fixture.readiness",
        when Tree_Traversal => "fixture.tree_traversal",
        when Focus_And_Activation => "fixture.focus_activation",
        when Action_Requests => "fixture.action_requests",
        when Protected_Text => "fixture.protected_text",
        when Relations => "fixture.relations",
        when Live_Announcement => "fixture.live_announcement",
        when Window_Lifecycle => "fixture.window_lifecycle",
        when Voice_Control => "fixture.voice_control",
        when Switch_Access => "fixture.switch_access");

   function Native_Probe_Command (Platform : Platform_Id) return String is
     (case Platform is
        when Linux =>
          "tests/bin/native_client_atspi --probe-external-client-host-env",
        when Windows =>
          "tests/bin/native_client_uia --probe-external-client",
        when MacOS =>
          "tests/bin/native_client_nsax --probe-external-client");

   function Conformance_Feature_Id
     (Platform : Platform_Id;
      Scenario : Scenario_Id)
      return String is
     (case Platform is
        when Linux =>
          (case Scenario is
             when Fixture_Readiness | Tree_Traversal |
                  Focus_And_Activation =>
               "linux.atspi.live_external_client.traversal",
             when Action_Requests =>
               "linux.atspi.live_external_client.action",
             when Protected_Text =>
               "linux.atspi.text.protected",
             when Relations =>
               "linux.atspi.accessible.relations",
             when Live_Announcement =>
               "linux.atspi.live_external_client.live_region",
             when Window_Lifecycle =>
               "linux.atspi.live_external_client.surface",
             when Voice_Control | Switch_Access =>
               "linux.atspi.live_external_client.traversal"),
        when Windows =>
          (case Scenario is
             when Fixture_Readiness | Tree_Traversal |
                  Focus_And_Activation =>
               "windows.uia.external_client.failure_stage",
             when Action_Requests =>
               "windows.uia.action.request",
             when Protected_Text =>
               "windows.uia.protected_value_text",
             when Relations =>
               "windows.uia.relation_routing",
             when Live_Announcement =>
               "windows.uia.event_map",
             when Window_Lifecycle =>
               "windows.uia.surface_routing",
             when Voice_Control | Switch_Access =>
               "windows.uia.external_client.failure_stage"),
        when MacOS =>
          (case Scenario is
             when Fixture_Readiness | Tree_Traversal |
                  Focus_And_Activation =>
               "macos.nsaccessibility.external_client.failure_stage",
             when Action_Requests =>
               "macos.nsaccessibility.action.request",
             when Protected_Text =>
               "macos.nsaccessibility.protected_value_text",
             when Relations =>
               "macos.nsaccessibility.relation_routing",
             when Live_Announcement =>
               "macos.nsaccessibility.event_map",
             when Window_Lifecycle =>
               "macos.nsaccessibility.surface_routing",
             when Voice_Control | Switch_Access =>
               "macos.nsaccessibility.external_client.failure_stage"));

   function Readiness_Evidence_Id
     (Platform : Platform_Id)
      return String is
     (case Platform is
        when Linux =>
          "record_linux_atspi_assistive_technology_qualification",
        when Windows =>
          "external_uia_client_traverses_com_fragment_root",
        when MacOS =>
          "external_ax_client_traverses_appkit_element_tree");

   function Native_API (Platform : Platform_Id) return String is
     (case Platform is
        when Linux => "AT-SPI2",
        when Windows => "UI Automation",
        when MacOS => "NSAccessibility");

   function Qualification_Gate_Status (Platform : Platform_Id) return String is
     (case Platform is
        when Linux | Windows | MacOS => "pending_public_client_traversal");

   function Native_Boundary_Stage (Platform : Platform_Id) return String is
     (case Platform is
        when Linux =>
          "live_atspi_registered_transport_observed",
        when Windows =>
          "uia_public_root_export_path_ready",
        when MacOS =>
          "nsaccessibility_public_root_export_path_ready");

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

   function Natural_Image (Value : Natural) return String is
     (Ada.Strings.Fixed.Trim (Natural'Image (Value), Ada.Strings.Left));

   function Q (Value : String) return String is
      Result : Unbounded_String;
   begin
      Append (Result, '"');
      for Ch of Value loop
         case Ch is
            when '"' =>
               Append (Result, "\""");
            when '\' =>
               Append (Result, "\\");
            when Character'Val (8) =>
               Append (Result, "\b");
            when Character'Val (9) =>
               Append (Result, "\t");
            when Character'Val (10) =>
               Append (Result, "\n");
            when Character'Val (12) =>
               Append (Result, "\f");
            when Character'Val (13) =>
               Append (Result, "\r");
            when others =>
               if Character'Pos (Ch) < 32 then
                  Append (Result, ' ');
               else
                  Append (Result, Ch);
               end if;
         end case;
      end loop;
      Append (Result, '"');
      return To_String (Result);
   end Q;

   function File_Exists (Path : String) return Boolean is
   begin
      return Ada.Directories.Exists (Path);
   exception
      when others =>
         return False;
   end File_Exists;

   function JSON_Boolean
     (Document : String;
      Field    : String)
      return Boolean;

   function File_Contains (Path : String; Needle : String) return Boolean is
      File : Ada.Text_IO.File_Type;
   begin
      if not File_Exists (Path) then
         return False;
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, Path);
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Ada.Strings.Fixed.Index (Line, Needle) /= 0 then
               Ada.Text_IO.Close (File);
               return True;
            end if;
         end;
      end loop;
      Ada.Text_IO.Close (File);
      return False;
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return False;
   end File_Contains;

   function Windows_UIA_Public_Client_Traversal_Observed return Boolean is
      Report_Path : constant String :=
        "vm/windows11/a11y-windows-native-client.txt";
   begin
      return
        File_Contains (Report_Path, "probe_external_client_exit=0")
        and then File_Contains (Report_Path, "uia_router_tests_exit=0")
        and then File_Contains
          (Report_Path, """transport_status"": ""native_client_available""")
        and then File_Contains
          (Report_Path, """external_client_traversal_observed"": true")
        and then File_Contains
          (Report_Path, """native_conformance_ready"": true")
        and then File_Contains (Report_Path, """status"": ""success""");
   end Windows_UIA_Public_Client_Traversal_Observed;

   function Windows_UIA_Native_Client_Artifact_Path return String is
     ("vm/windows11/a11y-windows-native-client.txt");

   function Linux_ATSPI_Public_Client_Traversal_Observed return Boolean is
      Report_Path : constant String := "vm/linux-atspi-native-client.txt";
   begin
      return
        File_Contains (Report_Path, """provider_registered"": true")
        and then File_Contains
          (Report_Path, """provider_registration_auth_response_status"": ""SUCCESS""")
        and then File_Contains
          (Report_Path, """provider_registration_transport_registration_observed"": true")
        and then File_Contains
          (Report_Path, """client_raw_connected"": true")
        and then File_Contains
          (Report_Path, """external_traversal_completed"": true")
        and then File_Contains
          (Report_Path, """external_core_slice_completed"": true")
        and then File_Contains
          (Report_Path, """external_interaction_slice_completed"": true")
        and then File_Contains
          (Report_Path, """external_content_slice_completed"": true")
        and then File_Contains
          (Report_Path, """external_surface_slice_completed"": true")
        and then File_Contains
          (Report_Path, """external_live_region_slice_completed"": true")
        and then File_Contains
          (Report_Path, """external_protected_value_suppressed"": true")
        and then File_Contains (Report_Path, """status"": ""SUCCESS""")
        and then File_Contains (Report_Path, """stop_status"": ""SUCCESS""");
   end Linux_ATSPI_Public_Client_Traversal_Observed;

   function Linux_ATSPI_Native_Client_Artifact_Path return String is
     ("vm/linux-atspi-native-client.txt");

   function Artifact_State
     (Available : Boolean;
      Complete  : Boolean)
      return String is
     (if Complete then
        "complete"
      elsif Available then
        "incomplete_or_invalid"
      else
        "missing");

   procedure Append_Native_Client_Artifact_Item
     (Report    : in out Unbounded_String;
      Platform  : String;
      Native_API : String;
      Path      : String;
      Complete  : Boolean)
   is
      Available : constant Boolean := File_Exists (Path);
   begin
      Append
        (Report,
         "    {""platform"": "
         & Q (Platform)
         & ", ""native_api"": "
         & Q (Native_API)
         & ", ""artifact_path"": "
         & Q (Path)
         & ", ""artifact_available"": "
         & (if Available then "true" else "false")
         & ", ""artifact_state"": "
         & Q (Artifact_State (Available, Complete))
         & ", ""native_conformance_claim_allowed"": "
         & (if Complete then "true" else "false")
         & "}");
   end Append_Native_Client_Artifact_Item;

   function Native_Client_Artifacts_Complete return Boolean is
     (Linux_ATSPI_Public_Client_Traversal_Observed
      and then Windows_UIA_Public_Client_Traversal_Observed
      and then MacOS_NSAccessibility_Public_Client_Traversal_Observed);

   function Native_Client_Artifact_Status_JSON return String is
      Linux_Complete : constant Boolean :=
        Linux_ATSPI_Public_Client_Traversal_Observed;
      Windows_Complete : constant Boolean :=
        Windows_UIA_Public_Client_Traversal_Observed;
      MacOS_Complete : constant Boolean :=
        MacOS_NSAccessibility_Public_Client_Traversal_Observed;
      Complete : constant Boolean :=
        Linux_Complete and then Windows_Complete and then MacOS_Complete;
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.native_client_artifact_status.v1")
           & "," & ASCII.LF
           & "  ""all_native_client_artifacts_complete"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_conformance_claim_allowed"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""artifacts"": [" & ASCII.LF);
   begin
      Append_Native_Client_Artifact_Item
        (Report,
         "Linux",
         "AT-SPI2",
         Linux_ATSPI_Native_Client_Artifact_Path,
         Linux_Complete);
      Append (Report, "," & ASCII.LF);
      Append_Native_Client_Artifact_Item
        (Report,
         "Windows",
         "UI Automation",
         Windows_UIA_Native_Client_Artifact_Path,
         Windows_Complete);
      Append (Report, "," & ASCII.LF);
      Append_Native_Client_Artifact_Item
        (Report,
         "macOS",
         "NSAccessibility",
         MacOS_NSAccessibility_Native_Client_Artifact_Path,
         MacOS_Complete);
      Append (Report, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end Native_Client_Artifact_Status_JSON;

   function MacOS_NSAX_Native_Client_Artifact_Complete
     (Artifact_JSON : String)
      return Boolean is
     (Project_Tools.JSON.Field_Value (Artifact_JSON, "schema")
      = "org.a11y.native_client_nsax_external_client.v1"
      and then Project_Tools.JSON.Field_Value (Artifact_JSON, "platform")
        = "macOS"
      and then Project_Tools.JSON.Field_Value (Artifact_JSON, "native_api")
        = "NSAccessibility"
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "client_process")
        = "native_client_nsax"
      and then JSON_Boolean
        (Artifact_JSON, "native_bridge_compiled_for_macos")
      and then not JSON_Boolean
        (Artifact_JSON, "native_bridge_stub_runtime")
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "transport_status")
        = "native_client_available"
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "next_required_evidence")
        = "macos_nsaccessibility_automated_native_qualification_complete"
      and then JSON_Boolean (Artifact_JSON, "appkit_bridge_observed")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_virtual_element_bridge_audited")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_virtual_element_runtime_available")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_virtual_element_runtime_probe_observed")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_ax_client_runtime_available")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_ax_client_process_id_available")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_ax_client_probe_observed")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_export_path_observed")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_element_ensured")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_main_thread_bound")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_element_resolved")
      and then JSON_Boolean
        (Artifact_JSON,
         "macos_nsax_public_root_native_node_component_stable")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_children_frame_built")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_child_at_index_frame_built")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_attribute_frame_built")
      and then JSON_Boolean
        (Artifact_JSON,
         "macos_nsax_public_root_attribute_settable_frame_built")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_action_frame_built")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_hit_test_frame_built")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_focused_element_frame_built")
      and then JSON_Boolean
        (Artifact_JSON, "macos_nsax_public_root_notification_frame_built")
      and then JSON_Boolean (Artifact_JSON, "element_registered")
      and then JSON_Boolean (Artifact_JSON, "element_main_thread_bound")
      and then JSON_Boolean (Artifact_JSON, "element_chain_observed")
      and then JSON_Boolean (Artifact_JSON, "metadata_label_preserved")
      and then JSON_Boolean (Artifact_JSON, "metadata_identifier_preserved")
      and then JSON_Boolean (Artifact_JSON, "metadata_help_preserved")
      and then JSON_Boolean (Artifact_JSON, "metadata_placeholder_preserved")
      and then JSON_Boolean (Artifact_JSON, "metadata_detail_preserved")
      and then JSON_Boolean (Artifact_JSON, "metadata_group_preserved")
      and then JSON_Boolean (Artifact_JSON, "protected_value_suppressed")
      and then JSON_Boolean (Artifact_JSON, "privacy_boundary_observed")
      and then JSON_Boolean
        (Artifact_JSON, "internal_native_export_chain_ready")
      and then JSON_Boolean
        (Artifact_JSON, "external_client_traversal_observed")
      and then JSON_Boolean
        (Artifact_JSON, "public_ax_client_traversal_observed")
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "required_scenario_count") = "9"
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "captured_scenario_count") = "9"
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "pending_scenario_count") = "0"
      and then JSON_Boolean (Artifact_JSON, "tree_traversal_captured")
      and then JSON_Boolean
        (Artifact_JSON, "focus_and_activation_captured")
      and then JSON_Boolean (Artifact_JSON, "protected_text_captured")
      and then JSON_Boolean (Artifact_JSON, "window_lifecycle_captured")
      and then JSON_Boolean (Artifact_JSON, "action_requests_captured")
      and then JSON_Boolean (Artifact_JSON, "relations_captured")
      and then JSON_Boolean (Artifact_JSON, "live_announcement_captured")
      and then JSON_Boolean (Artifact_JSON, "switch_access_captured")
      and then JSON_Boolean (Artifact_JSON, "voice_control_captured")
      and then not JSON_Boolean (Artifact_JSON, "semantic_state_mutated")
      and then JSON_Boolean (Artifact_JSON, "native_conformance_ready")
      and then Project_Tools.JSON.Field_Value
        (Artifact_JSON, "boundary_status")
        = "SUCCESS"
      and then Project_Tools.JSON.Field_Value (Artifact_JSON, "status")
        = "success");

   function MacOS_NSAX_Public_Client_Traversal_Observed return Boolean is
      Report_Path : constant String := "vm/macos-nsax-native-client.txt";
   begin
      return
        MacOS_NSAccessibility_Native_Client_Artifact_Available
        and then MacOS_NSAX_Native_Client_Artifact_Complete
          (Project_Tools.Files.Read_Raw_File (Report_Path));
   end MacOS_NSAX_Public_Client_Traversal_Observed;

   function MacOS_NSAccessibility_Native_Client_Artifact_Complete
     (Artifact_JSON : String)
      return Boolean is
     (MacOS_NSAX_Native_Client_Artifact_Complete (Artifact_JSON));

   function MacOS_NSAccessibility_Native_Client_Artifact_Path return String is
     ("vm/macos-nsax-native-client.txt");

   function MacOS_NSAccessibility_Native_Client_Artifact_Available
     return Boolean is
     (File_Exists (MacOS_NSAccessibility_Native_Client_Artifact_Path));

   function MacOS_NSAccessibility_Native_Client_Artifact_File_Status_JSON
     return String
   is
      Path : constant String :=
        MacOS_NSAccessibility_Native_Client_Artifact_Path;
      Available : constant Boolean := File_Exists (Path);
      Complete : constant Boolean :=
        Available
        and then MacOS_NSAccessibility_Native_Client_Artifact_Complete
          (Project_Tools.Files.Read_Raw_File (Path));
      State : constant String :=
        (if Complete then
           "complete"
         elsif Available then
           "incomplete_or_invalid"
         else
           "missing");
   begin
      return
        "{"
        & ASCII.LF
        & "  ""schema"": "
        & Q
          ("org.a11y.macos_nsaccessibility_native_client_artifact_file_status.v1")
        & ","
        & ASCII.LF
        & "  ""artifact_path"": "
        & Q (Path)
        & ","
        & ASCII.LF
        & "  ""artifact_available"": "
        & (if Available then "true" else "false")
        & ","
        & ASCII.LF
        & "  ""artifact_state"": "
        & Q (State)
        & ","
        & ASCII.LF
        & "  ""macos_nsaccessibility_automated_native_qualification_complete"": "
        & (if Complete then "true" else "false")
        & ","
        & ASCII.LF
        & "  ""native_conformance_claim_allowed"": "
        & (if Complete then "true" else "false")
        & ASCII.LF
        & "}"
        & ASCII.LF;
   end MacOS_NSAccessibility_Native_Client_Artifact_File_Status_JSON;

   function MacOS_NSAccessibility_Public_Client_Traversal_Observed
     return Boolean is
   begin
      return MacOS_NSAX_Public_Client_Traversal_Observed;
   end MacOS_NSAccessibility_Public_Client_Traversal_Observed;

   function Linux_ATSPI_Artifact_Complete
     (Artifact_JSON : String)
      return Boolean is
     (Ada.Strings.Fixed.Index
        (Artifact_JSON, """provider_registered"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON,
         """provider_registration_transport_registration_observed"": true")
        /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON,
         """provider_registration_auth_response_status"": ""SUCCESS""")
        /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """client_raw_connected"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_traversal_completed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_core_slice_completed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_interaction_slice_completed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_content_slice_completed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_surface_slice_completed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_live_region_slice_completed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """external_protected_value_suppressed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """status"": ""SUCCESS""") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_JSON, """stop_status"": ""SUCCESS""") /= 0);

   function Windows_UIA_Artifact_Complete
     (Artifact_Text : String)
      return Boolean is
     (Ada.Strings.Fixed.Index
        (Artifact_Text, "probe_external_client_exit=0") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_Text, "uia_router_tests_exit=0") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_Text, """transport_status"": ""native_client_available""")
        /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_Text, """external_client_traversal_observed"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_Text, """native_conformance_ready"": true") /= 0
      and then Ada.Strings.Fixed.Index
        (Artifact_Text, """status"": ""success""") /= 0);

   function OS_Release_Pretty_Name return String is
      File : Ada.Text_IO.File_Type;
      Prefix : constant String := "PRETTY_NAME=";
   begin
      if not File_Exists ("/etc/os-release") then
         return "unavailable";
      end if;

      Ada.Text_IO.Open (File, Ada.Text_IO.In_File, "/etc/os-release");
      while not Ada.Text_IO.End_Of_File (File) loop
         declare
            Line : constant String := Ada.Text_IO.Get_Line (File);
         begin
            if Line'Length >= Prefix'Length
              and then Line (Line'First .. Line'First + Prefix'Length - 1)
                = Prefix
            then
               Ada.Text_IO.Close (File);
               declare
                  Value : constant String :=
                    Line (Line'First + Prefix'Length .. Line'Last);
               begin
                  if Value'Length >= 2
                    and then Value (Value'First) = '"'
                    and then Value (Value'Last) = '"'
                  then
                     return Value (Value'First + 1 .. Value'Last - 1);
                  end if;
                  return Value;
               end;
            end if;
         end;
      end loop;

      Ada.Text_IO.Close (File);
      return "unavailable";
   exception
      when others =>
         if Ada.Text_IO.Is_Open (File) then
            Ada.Text_IO.Close (File);
         end if;
         return "unavailable";
   end OS_Release_Pretty_Name;

   function Host_Environment_Present (Name : String) return Boolean is
      Value : Hostkit.UString;
   begin
      return Hostkit.Process.Environment_Value (Name, Value);
   exception
      when others =>
         return False;
   end Host_Environment_Present;

   function Item
     (Platform : Platform_Id;
      Assistive_Tech : String;
      Scenario : Scenario_Id;
      Steps : String;
      Expected : String;
      Limitation : String := "none";
      Observed : String := "pending manual qualification";
      Evidence : String := "pending evidence capture";
      OS_Version : String := "to be recorded";
      AT_Version : String := "to be recorded")
      return Scenario_Record is
     ((Platform => Platform,
       Assistive_Technology => Pad (Assistive_Tech, 32),
       OS_Version => Pad (OS_Version, 32),
       AT_Version => Pad (AT_Version, 32),
       Scenario => Scenario,
       Steps => Pad (Steps, 96),
       Expected => Pad (Expected, 96),
       Observed => Pad (Observed, 96),
       Evidence => Pad (Evidence, 96),
       Native_Probe_Command => Pad (Native_Probe_Command (Platform), 128),
       Conformance_Feature_Id =>
         Pad (Conformance_Feature_Id (Platform, Scenario), 96),
       Limitation => Pad (Limitation, 32)));

   Scenarios : constant array (Positive range <>) of Scenario_Record :=
     [Item
        (Linux,
         "Orca",
         Fixture_Readiness,
         "start fixture application and wait for deterministic ready line",
         "application root and main window are discoverable"),
      Item
        (Linux,
         "Accessibility Inspector",
         Tree_Traversal,
         "expand application, window, menu, list, tree, and document nodes",
         "roles, names, states, and exposed children match the semantic fixture"),
      Item
        (Linux,
         "Orca",
         Protected_Text,
         "focus password field and request current text/value",
         "protected text is never spoken, inspected, logged, or exposed"),
      Item
        (Linux,
         "Accessibility Inspector",
         Window_Lifecycle,
         "open and close modal dialog, popup, tooltip, and main window surfaces",
         "AT-SPI window/surface events follow committed semantic lifecycle"),
      Item
        (Linux,
         "Accessibility Inspector",
         Relations,
         "inspect labels, descriptions, and validation-error relation targets",
         "relation targets resolve only to live exposed AT-SPI objects"),
      Item
        (Linux,
         "Orca",
         Live_Announcement,
         "issue fixture announcement and live-region update commands",
         "announcement and live-region output follow committed semantic events"),
      Item
        (Linux,
         "Accessibility Inspector",
         Action_Requests,
         "invoke activate, press, toggle, expand, collapse, menu, dismiss, open, close, scroll, and focus through AT-SPI",
         "AT-SPI DoAction requests dispatch the matching semantic action"),
      Item
        (Windows,
         "UI Automation Inspector",
         Tree_Traversal,
         "expand application, window, menu, list, tree, tab, and document fragments",
         "ControlType, Name, state, and fragment navigation match the semantic fixture"),
      Item
        (Windows,
         "NVDA",
         Focus_And_Activation,
         "move focus through buttons, toggles, list items, and tabs",
         "focus events arrive after committed state and default actions work"),
      Item
        (Windows,
         "Narrator",
         Protected_Text,
         "focus password field and use value/text commands",
         "secure value is unavailable while role and safe state remain exposed"),
      Item
        (Windows,
         "UI Automation Inspector",
         Relations,
         "inspect labelled-by, described-by, and validation-error targets",
         "relations resolve only to live exposed stable runtime identities"),
      Item
        (Windows,
         "UI Automation Inspector",
         Live_Announcement,
         "issue fixture announcement and live-region update commands",
         "UIA live-region or notification events follow committed semantics"),
      Item
        (Windows,
         "UI Automation Inspector",
         Window_Lifecycle,
         "open and close modal dialog, popup, tooltip, and main window surfaces",
         "UIA window events and stale fragments follow semantic lifecycle"),
      Item
        (Windows,
         "UI Automation Inspector",
         Action_Requests,
         "invoke activate, press, toggle, expand, collapse, menu, dismiss, open, close, scroll, and focus through UIA",
         "Invoke, Toggle, Window, and ScrollItem route to semantic actions"),
      Item
        (MacOS,
         "Accessibility Inspector",
         Tree_Traversal,
         "expand application, window, menu, list, tree, tab, and document elements",
         "roles, titles, states, and children match the semantic fixture"),
      Item
        (MacOS,
         "VoiceOver",
         Focus_And_Activation,
         "navigate controls, activate buttons, and toggle checkable controls",
         "role, title, value, selected, expanded, and focused output matches fixture"),
      Item
        (MacOS,
         "VoiceOver",
         Protected_Text,
         "focus password field and request spoken text, value, and selected text",
         "protected content is suppressed while safe role and state remain exposed"),
      Item
        (MacOS,
         "Accessibility Inspector",
         Window_Lifecycle,
         "open and close dialog, popup, tooltip, and main window surfaces",
         "notifications follow semantic lifecycle and stale elements become defunct"),
      Item
        (MacOS,
         "Accessibility Inspector",
         Action_Requests,
         "invoke activate, press, toggle, expand, collapse, menu, dismiss, open, close, scroll, and focus through NSAX",
         "NSAccessibility actions route to matching semantic actions"),
      Item
        (MacOS,
         "Accessibility Inspector",
         Relations,
         "inspect labelled, described, and validation-error relationships",
         "relations resolve only to live exposed NSAccessibility elements"),
      Item
        (MacOS,
         "VoiceOver",
         Live_Announcement,
         "issue fixture announcement and live-region update commands",
         "announcement is emitted after semantic event publication"),
      Item
        (MacOS,
         "Switch Control",
         Switch_Access,
         "scan controls and activate the fixture button and toggle controls",
         "switch access reaches exposed controls and invokes semantic actions"),
      Item
        (MacOS,
         "Voice Control",
         Voice_Control,
         "show names or number overlays and speak commands for fixture controls",
         "voice commands target stable exposed names without protected text leaks")];

   function Scenario_Count return Natural is (Scenarios'Length);

   function Has_Scenario_For_All_Platforms
     (Scenario : Scenario_Id) return Boolean is
      Saw_Linux : Boolean := False;
      Saw_Windows : Boolean := False;
      Saw_MacOS : Boolean := False;
   begin
      for Item of Scenarios loop
         if Item.Scenario = Scenario then
            case Item.Platform is
               when Linux =>
                  Saw_Linux := True;
               when Windows =>
                  Saw_Windows := True;
               when MacOS =>
                  Saw_MacOS := True;
            end case;
         end if;
      end loop;

      return Saw_Linux and then Saw_Windows and then Saw_MacOS;
   end Has_Scenario_For_All_Platforms;

   function Has_Core_Assistive_Technology_For_All_Platforms
      return Boolean is
      Saw_Linux : Boolean := False;
      Saw_Windows : Boolean := False;
      Saw_MacOS : Boolean := False;
   begin
      for Scenario of Scenarios loop
         if Trimmed (Scenario.Assistive_Technology) /= "" then
            case Scenario.Platform is
               when Linux =>
                  Saw_Linux := True;
               when Windows =>
                  Saw_Windows := True;
               when MacOS =>
                  Saw_MacOS := True;
            end case;
         end if;
      end loop;

      return Saw_Linux and then Saw_Windows and then Saw_MacOS;
   end Has_Core_Assistive_Technology_For_All_Platforms;

   function Has_Tree_Traversal_For_All_Platforms return Boolean is
     (Has_Scenario_For_All_Platforms (Tree_Traversal));

   function Has_Protected_Text_For_All_Platforms return Boolean is
     (Has_Scenario_For_All_Platforms (Protected_Text));

   function Has_Window_Lifecycle_For_All_Platforms return Boolean is
     (Has_Scenario_For_All_Platforms (Window_Lifecycle));

   function Has_Action_Requests_For_All_Platforms return Boolean is
     (Has_Scenario_For_All_Platforms (Action_Requests));

   function Has_Relations_For_All_Platforms return Boolean is
     (Has_Scenario_For_All_Platforms (Relations));

   function Has_Live_Announcements_For_All_Platforms return Boolean is
     (Has_Scenario_For_All_Platforms (Live_Announcement));

   function Is_Pending_Evidence (Scenario : Scenario_Record) return Boolean is
     (Trimmed (Scenario.Observed) = "pending manual qualification"
      or else Trimmed (Scenario.Evidence) = "pending evidence capture");

   function Qualification_Status (Scenario : Scenario_Record) return String is
     (if Is_Pending_Evidence (Scenario) then "pending" else "captured");

   function Evidence_Pending_Count return Natural is
      Count : Natural := 0;
   begin
      for Scenario of Scenarios loop
         if Is_Pending_Evidence (Scenario) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Evidence_Pending_Count;

   function Evidence_Captured_Count return Natural is
      Count : Natural := 0;
   begin
      for Scenario of Scenarios loop
         if not Is_Pending_Evidence (Scenario) then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Evidence_Captured_Count;

   function Evidence_Count_For
     (Platform : Platform_Id;
      Pending  : Boolean)
      return Natural
   is
      Count : Natural := 0;
   begin
      for Scenario of Scenarios loop
         if Scenario.Platform = Platform
           and then Is_Pending_Evidence (Scenario) = Pending
         then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Evidence_Count_For;

   function Required_Scenario_Count_For
     (Platform : Platform_Id)
      return Natural
   is
      Count : Natural := 0;
   begin
      for Scenario of Scenarios loop
         if Scenario.Platform = Platform then
            Count := Count + 1;
         end if;
      end loop;

      return Count;
   end Required_Scenario_Count_For;

   function Linux_Required_Scenario_Count return Natural is
     (Required_Scenario_Count_For (Linux));

   function Windows_Required_Scenario_Count return Natural is
     (Required_Scenario_Count_For (Windows));

   function MacOS_Required_Scenario_Count return Natural is
     (Required_Scenario_Count_For (MacOS));

   function Linux_Evidence_Pending_Count return Natural is
     (Evidence_Count_For (Linux, True));

   function Linux_Evidence_Captured_Count return Natural is
     (Evidence_Count_For (Linux, False));

   function Windows_Evidence_Pending_Count return Natural is
     (Evidence_Count_For (Windows, True));

   function Windows_Evidence_Captured_Count return Natural is
     (Evidence_Count_For (Windows, False));

   function MacOS_Evidence_Pending_Count return Natural is
     (Evidence_Count_For (MacOS, True));

   function MacOS_Evidence_Captured_Count return Natural is
     (Evidence_Count_For (MacOS, False));

   function All_Evidence_Pending return Boolean is
     (Evidence_Pending_Count = Scenario_Count
      and then Evidence_Captured_Count = 0);

   function Platform_Evidence_Readiness_Evidence_Id
     (Platform : Platform_Id)
      return String is
     (case Platform is
        when Linux =>
          (if Linux_ATSPI_Public_Client_Traversal_Observed then
             "linux_atspi_automated_native_qualification"
           else
             Readiness_Evidence_Id (Linux)),
        when Windows =>
          (if Windows_UIA_Public_Client_Traversal_Observed then
             "windows_uia_automated_native_qualification"
           else
             Readiness_Evidence_Id (Windows)),
        when MacOS =>
          (if MacOS_NSAX_Public_Client_Traversal_Observed then
             "macos_nsaccessibility_automated_native_qualification"
           else
             Readiness_Evidence_Id (MacOS)));

   function Platform_Evidence_Qualification_Gate_Status
     (Platform : Platform_Id)
      return String is
     (case Platform is
        when Linux =>
          (if Linux_ATSPI_Public_Client_Traversal_Observed then
             "automated_native_qualification_complete"
           else
             Qualification_Gate_Status (Linux)),
        when Windows =>
          (if Windows_UIA_Public_Client_Traversal_Observed then
             "automated_native_qualification_complete"
           else
             Qualification_Gate_Status (Windows)),
        when MacOS =>
          (if MacOS_NSAX_Public_Client_Traversal_Observed then
             "automated_native_qualification_complete"
           else
             Qualification_Gate_Status (MacOS)));

   function Platform_Evidence_Native_Boundary_Stage
     (Platform : Platform_Id)
      return String is
     (case Platform is
        when Linux =>
          (if Linux_ATSPI_Public_Client_Traversal_Observed then
             "live_atspi_external_client_traversal_observed"
           else
             Native_Boundary_Stage (Linux)),
        when Windows =>
          (if Windows_UIA_Public_Client_Traversal_Observed then
             "uia_external_client_traversal_observed"
           else
             Native_Boundary_Stage (Windows)),
        when MacOS =>
          (if MacOS_NSAX_Public_Client_Traversal_Observed then
             "nsaccessibility_external_client_traversal_observed"
           else
             Native_Boundary_Stage (MacOS)));

   function Native_Public_Client_Traversal_Observed
     (Platform : Platform_Id)
      return Boolean is
     (case Platform is
        when Linux => Linux_ATSPI_Public_Client_Traversal_Observed,
        when Windows => Windows_UIA_Public_Client_Traversal_Observed,
        when MacOS => MacOS_NSAX_Public_Client_Traversal_Observed);

   function Platform_Evidence_Pending_Count
     (Platform : Platform_Id)
      return Natural is
     (if Native_Public_Client_Traversal_Observed (Platform) then
        0
      else
        Evidence_Count_For (Platform, True));

   function Platform_Evidence_Captured_Count
     (Platform : Platform_Id)
      return Natural is
     (if Native_Public_Client_Traversal_Observed (Platform) then
        Required_Scenario_Count_For (Platform)
      else
        Evidence_Count_For (Platform, False));

   procedure Append_Platform_Evidence_Item
     (Report   : in out Unbounded_String;
      Platform : Platform_Id)
   is
   begin
      Append
        (Report,
         "    {""platform"": "
         & Q (Platform_Name (Platform))
         & ", ""native_api"": "
         & Q (Native_API (Platform))
         & ", ""readiness_evidence_id"": "
         & Q (Platform_Evidence_Readiness_Evidence_Id (Platform))
         & ", ""qualification_gate_status"": "
         & Q (Platform_Evidence_Qualification_Gate_Status (Platform))
         & ", ""native_boundary_stage"": "
         & Q (Platform_Evidence_Native_Boundary_Stage (Platform))
         & ", ""native_public_client_traversal_observed"": "
         & (if Native_Public_Client_Traversal_Observed (Platform) then
              "true"
            else
              "false")
         & ", ""required_scenario_count"": "
         & Natural_Image (Required_Scenario_Count_For (Platform))
         & ", ""pending_scenario_count"": "
         & Natural_Image (Platform_Evidence_Pending_Count (Platform))
         & ", ""captured_scenario_count"": "
         & Natural_Image (Platform_Evidence_Captured_Count (Platform))
         & "}");
   end Append_Platform_Evidence_Item;

   function Platform_Evidence_Summary_JSON return String is
      Report : Unbounded_String := To_Unbounded_String ("[" & ASCII.LF);
   begin
      Append_Platform_Evidence_Item (Report, Linux);
      Append (Report, "," & ASCII.LF);
      Append_Platform_Evidence_Item (Report, Windows);
      Append (Report, "," & ASCII.LF);
      Append_Platform_Evidence_Item (Report, MacOS);
      Append (Report, ASCII.LF & "  ]");
      return To_String (Report);
   end Platform_Evidence_Summary_JSON;

   function Project_Completion_Complete return Boolean is
     (Linux_ATSPI_Public_Client_Traversal_Observed
      and then Windows_UIA_Public_Client_Traversal_Observed
      and then MacOS_NSAccessibility_Public_Client_Traversal_Observed);

   function Build_Project_Completion_Gate_JSON
     (Linux_Complete   : Boolean;
      Windows_Complete : Boolean;
      MacOS_Complete   : Boolean)
      return String
   is
      Complete : constant Boolean :=
        Linux_Complete and then Windows_Complete and then MacOS_Complete;
      Missing_Count : constant Natural :=
        (if Linux_Complete then 0 else 1)
        + (if Windows_Complete then 0 else 1)
        + (if MacOS_Complete then 0 else 1);
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.project_completion_gate.v1")
           & "," & ASCII.LF
           & "  ""original_scope_complete"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""linux_atspi_automated_native_qualification_complete"": "
           & (if Linux_Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""windows_uia_automated_native_qualification_complete"": "
           & (if Windows_Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""macos_nsaccessibility_automated_native_qualification_complete"": "
           & (if MacOS_Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""missing_native_backend_count"": "
           & Natural_Image (Missing_Count)
           & "," & ASCII.LF
           & "  ""missing_native_backends"": [");
   begin
      if not Linux_Complete then
         Append (Report, Q ("Linux AT-SPI2"));
      end if;
      if not Windows_Complete then
         if not Linux_Complete then
            Append (Report, ", ");
         end if;
         Append (Report, Q ("Windows UI Automation"));
      end if;
      if not MacOS_Complete then
         if not Linux_Complete or else not Windows_Complete then
            Append (Report, ", ");
         end if;
         Append (Report, Q ("macOS NSAccessibility"));
      end if;

      Append
        (Report,
         "]," & ASCII.LF
         & "  ""next_required_evidence"": "
         & (if Complete then
              Q ("none")
            elsif not MacOS_Complete then
              Q ("vm/macos-nsax-native-client.txt")
            elsif not Windows_Complete then
              Q ("vm/windows11/a11y-windows-native-client.txt")
            else
              Q ("vm/linux-atspi-native-client.txt"))
         & "," & ASCII.LF
         & "  ""completion_policy"": "
         & Q ("automated_native_client_conformance")
         & ASCII.LF
         & "}" & ASCII.LF);
      return To_String (Report);
   end Build_Project_Completion_Gate_JSON;

   function Project_Completion_Gate_JSON return String is
     (Build_Project_Completion_Gate_JSON
        (Linux_ATSPI_Public_Client_Traversal_Observed,
         Windows_UIA_Public_Client_Traversal_Observed,
         MacOS_NSAX_Public_Client_Traversal_Observed));

   function Project_Completion_Gate_JSON
     (Linux_ATSPI_Artifact_JSON : String;
      Windows_UIA_Artifact_Text : String;
      MacOS_NSAX_Artifact_JSON  : String)
      return String is
     (Build_Project_Completion_Gate_JSON
        (Linux_ATSPI_Artifact_Complete (Linux_ATSPI_Artifact_JSON),
         Windows_UIA_Artifact_Complete (Windows_UIA_Artifact_Text),
         MacOS_NSAX_Native_Client_Artifact_Complete
           (MacOS_NSAX_Artifact_JSON)));

   procedure Append_Template_Scenarios
     (Report   : in out Unbounded_String;
      Platform : Platform_Id)
   is
      Have_Output : Boolean := False;
   begin
      for Index in Scenarios'Range loop
         declare
            Scenario : Scenario_Record renames Scenarios (Index);
         begin
            if Scenario.Platform = Platform then
               if Have_Output then
                  Append (Report, "," & ASCII.LF);
               end if;
               Have_Output := True;

               Append
                 (Report,
                  "    {""assistive_technology"": "
                  & Q (Trimmed (Scenario.Assistive_Technology))
                  & ", ""scenario"": "
                  & Q (Scenario_Name (Scenario.Scenario))
                  & ", ""conformance_feature_id"": "
                  & Q (Trimmed (Scenario.Conformance_Feature_Id))
                  & ", ""steps"": "
                  & Q (Trimmed (Scenario.Steps))
                  & ", ""expected"": "
                  & Q (Trimmed (Scenario.Expected))
                  & ", ""observed"": """", ""evidence_location"": """","
                  & " ""qualification_status"": ""pending""}");
            end if;
         end;
      end loop;
   end Append_Template_Scenarios;

   function Linux_ATSPI_Evidence_Template_JSON return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.linux_atspi_release_evidence.v1")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (Linux))
           & "," & ASCII.LF
           & "  ""platform"": ""Linux""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (Linux))
           & "," & ASCII.LF
           & "  ""qualification_gate_status"": "
           & Q (Qualification_Gate_Status (Linux))
           & ","
           & ASCII.LF
           & "  ""native_boundary_stage"": "
           & Q (Native_Boundary_Stage (Linux))
           & "," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (Linux_Required_Scenario_Count)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (Linux_Evidence_Captured_Count)
           & "," & ASCII.LF
           & "  ""required_live_probe"": "
           & Q ("tests/bin/native_client_atspi --probe-external-client-host-env")
           & "," & ASCII.LF
           & "  ""required_probe_flags"": {"
           & """provider_registration_auth_response_status"": ""SUCCESS"","
           & """provider_registration_transport_registration_observed"": true,"
           & " ""external_traversal_completed"": true,"
           & " ""external_core_slice_completed"": true,"
           & " ""external_interaction_slice_completed"": true,"
           & " ""external_content_slice_completed"": true,"
           & " ""external_surface_slice_completed"": true,"
           & " ""external_live_region_slice_completed"": true},"
           & ASCII.LF
           & "  ""manual_record_fields"": ["
           & Q ("os_version")
           & ", "
           & Q ("assistive_technology")
           & ", "
           & Q ("assistive_technology_version")
           & ", "
           & Q ("fixture_scenario")
           & ", "
           & Q ("exact_steps")
           & ", "
           & Q ("expected_behavior")
           & ", "
           & Q ("observed_behavior")
           & ", "
           & Q ("evidence_location")
           & ", "
           & Q ("known_limitation_id")
           & "]," & ASCII.LF
           & "  ""scenario_records"": [" & ASCII.LF);
   begin
      Append_Template_Scenarios (Report, Linux);
      Append (Report, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end Linux_ATSPI_Evidence_Template_JSON;

   function Linux_ATSPI_Host_Evidence_JSON return String is
      Orca_Path : constant String := "/usr/bin/orca";
      Busctl_Path : constant String := "/usr/bin/busctl";
      OS_Release_Path : constant String := "/etc/os-release";
      AT_SPI_Env_Name : constant String := "AT_SPI_BUS_ADDRESS";
      Session_Env_Name : constant String := "DBUS_SESSION_BUS_ADDRESS";
      Orca_Present : constant Boolean := File_Exists (Orca_Path);
      Busctl_Present : constant Boolean := File_Exists (Busctl_Path);
      OS_Release_Present : constant Boolean := File_Exists (OS_Release_Path);
      AT_SPI_Address_Present : constant Boolean :=
        Host_Environment_Present (AT_SPI_Env_Name);
      Session_Bus_Address_Present : constant Boolean :=
        Host_Environment_Present (Session_Env_Name);
      Host_Discovery_Source : constant String :=
        (if AT_SPI_Address_Present then "at_spi_bus_address"
         elsif Session_Bus_Address_Present then "dbus_session_bus_address"
         else "missing_host_environment");
      Required_Live_Probe : constant String :=
        (if AT_SPI_Address_Present or else Session_Bus_Address_Present then
           "tests/bin/native_client_atspi --probe-external-client-host-env"
         else
           "tests/bin/native_client_atspi --probe-host-env");
      Report : constant Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.linux_atspi_host_evidence.v1")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (Linux))
           & "," & ASCII.LF
           & "  ""platform"": ""Linux""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (Linux))
           & "," & ASCII.LF
           & "  ""qualification_gate_status"": "
           & Q (Qualification_Gate_Status (Linux))
           & "," & ASCII.LF
           & "  ""native_boundary_stage"": "
           & Q (Native_Boundary_Stage (Linux))
           & "," & ASCII.LF
           & "  ""host_os_pretty_name"": "
           & Q (OS_Release_Pretty_Name)
           & "," & ASCII.LF
           & "  ""os_release_file_present"": "
           & (if OS_Release_Present then "true" else "false")
           & "," & ASCII.LF
           & "  ""orca_binary_present"": "
           & (if Orca_Present then "true" else "false")
           & "," & ASCII.LF
           & "  ""orca_binary_path"": "
           & Q (if Orca_Present then Orca_Path else "")
           & "," & ASCII.LF
           & "  ""busctl_binary_present"": "
           & (if Busctl_Present then "true" else "false")
           & "," & ASCII.LF
           & "  ""busctl_binary_path"": "
           & Q (if Busctl_Present then Busctl_Path else "")
           & "," & ASCII.LF
           & "  ""host_at_spi_bus_address_present"": "
           & (if AT_SPI_Address_Present then "true" else "false")
           & "," & ASCII.LF
           & "  ""host_session_bus_address_present"": "
           & (if Session_Bus_Address_Present then "true" else "false")
           & "," & ASCII.LF
           & "  ""host_discovery_source"": "
           & Q (Host_Discovery_Source)
           & "," & ASCII.LF
           & "  ""required_live_probe"": "
           & Q (Required_Live_Probe)
           & "," & ASCII.LF
           & "  ""host_transport_probe_command"": "
           & Q ("tests/bin/native_client_atspi --probe-host-env")
           & "," & ASCII.LF
           & "  ""sandbox_socket_access_may_require_escalation"": true,"
           & ASCII.LF
           & "  ""host_evidence_complete"": "
           & (if OS_Release_Present
                 and then Orca_Present
                 and then Busctl_Present
                 and then (AT_SPI_Address_Present or else Session_Bus_Address_Present)
              then "true"
              else "false")
           & "," & ASCII.LF
           & "  ""manual_assistive_technology_evidence_required"": false,"
           & ASCII.LF
           & "  ""manual_assistive_technology_evidence_optional"": true,"
           & ASCII.LF
           & "  ""does_not_claim_screen_reader_behavior"": true"
           & ASCII.LF
           & "}" & ASCII.LF);
   begin
      return To_String (Report);
   end Linux_ATSPI_Host_Evidence_JSON;

   function JSON_Boolean
     (Document : String;
      Field    : String)
      return Boolean is
     (Project_Tools.JSON.Field_Value (Document, Field) = "true");

   function Count_If (Value : Boolean) return Natural is
     (if Value then 1 else 0);

   function JSON_Natural
     (Document : String;
      Field    : String)
      return Natural
   is
      Value : constant String :=
        Project_Tools.JSON.Field_Value (Document, Field);
      Result : Natural := 0;
   begin
      if Value'Length = 0 then
         return 0;
      end if;

      for Ch of Value loop
         if Ch not in '0' .. '9' then
            return 0;
         end if;

         Result :=
           Result * 10 + Character'Pos (Ch) - Character'Pos ('0');
      end loop;

      return Result;
   end JSON_Natural;

   function Linux_ATSPI_Captured_Evidence_Status_JSON
     (Evidence_JSON : String) return String
   is
      Valid_Schema : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "schema")
        = "org.a11y.linux_atspi_captured_evidence.v1";
      Valid_Readiness : constant Boolean :=
        Project_Tools.JSON.Field_Value
          (Evidence_JSON, "readiness_evidence_id")
        = Readiness_Evidence_Id (Linux);
      Valid_Platform : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "platform") = "Linux";
      Valid_Native_API : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "native_api")
        = Native_API (Linux);
      Valid : constant Boolean :=
        Valid_Schema
        and then Valid_Readiness
        and then Valid_Platform
        and then Valid_Native_API;
      Captured : constant Natural :=
        (if Valid then
           Count_If (JSON_Boolean (Evidence_JSON, "fixture_readiness_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "tree_traversal_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "protected_text_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "window_lifecycle_captured"))
           + Count_If (JSON_Boolean (Evidence_JSON, "relations_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "live_announcement_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "action_requests_captured"))
         else 0);
      Required : constant Natural := Linux_Required_Scenario_Count;
      Pending : constant Natural := Required - Captured;
      Complete : constant Boolean := Valid and then Captured = Required;
      Report : constant Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.linux_atspi_captured_evidence_status.v1")
           & "," & ASCII.LF
           & "  ""input_schema_valid"": "
           & (if Valid_Schema then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_readiness_evidence_valid"": "
           & (if Valid_Readiness then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_platform_valid"": "
           & (if Valid_Platform then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_native_api_valid"": "
           & (if Valid_Native_API then "true" else "false")
           & "," & ASCII.LF
           & "  ""valid"": "
           & (if Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (Linux))
           & "," & ASCII.LF
           & "  ""platform"": ""Linux""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (Linux))
           & "," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (Required)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (Captured)
           & "," & ASCII.LF
           & "  ""pending_scenario_count"": "
           & Natural_Image (Pending)
           & "," & ASCII.LF
           & "  ""linux_atspi_assistive_technology_qualification_complete"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_conformance_claim_allowed"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""manual_evidence_ingested"": "
           & (if Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""does_not_verify_evidence_authenticity"": true"
           & ASCII.LF
           & "}" & ASCII.LF);
   begin
      return To_String (Report);
   end Linux_ATSPI_Captured_Evidence_Status_JSON;

   function Windows_UIA_Evidence_Template_JSON return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.windows_uia_release_evidence.v1")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (Windows))
           & "," & ASCII.LF
           & "  ""platform"": ""Windows""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (Windows))
           & "," & ASCII.LF
           & "  ""qualification_gate_status"": "
           & Q (Qualification_Gate_Status (Windows))
           & ","
           & ASCII.LF
           & "  ""native_boundary_stage"": "
           & Q (Native_Boundary_Stage (Windows))
           & "," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (Windows_Required_Scenario_Count)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (Windows_Evidence_Captured_Count)
           & "," & ASCII.LF
           & "  ""required_live_probe"": "
           & Q ("tests/bin/native_client_uia --probe-external-client")
           & "," & ASCII.LF
           & "  ""required_probe_flags"": {"
           & """provider_export_observed"": true,"
           & " ""fragment_interface_queried"": true,"
           & " ""fragment_navigate_dispatched"": true,"
           & " ""fragment_last_child_frame_dispatched"": true,"
           & " ""fragment_runtime_id_dispatched"": true,"
           & " ""simple_property_frame_dispatched"": true,"
           & " ""pattern_provider_frame_dispatched"": true,"
           & " ""bounding_rectangle_frame_dispatched"": true,"
           & " ""fragment_action_frame_dispatched"": true,"
           & " ""fragment_action_frame_status"": ""SUCCESS"","
           & " ""fragment_action_frame_routed"": ""ACTION_REQUEST"","
           & " ""fragment_set_focus_payload_preserved"": true,"
           & " ""internal_native_export_chain_ready"": true,"
           & " ""external_client_traversal_observed"": true},"
           & ASCII.LF
           & "  ""manual_record_fields"": ["
           & Q ("os_version")
           & ", "
           & Q ("assistive_technology")
           & ", "
           & Q ("assistive_technology_version")
           & ", "
           & Q ("fixture_scenario")
           & ", "
           & Q ("exact_steps")
           & ", "
           & Q ("expected_behavior")
           & ", "
           & Q ("observed_behavior")
           & ", "
           & Q ("evidence_location")
           & ", "
           & Q ("known_limitation_id")
           & "]," & ASCII.LF
           & "  ""scenario_records"": [" & ASCII.LF);
   begin
      Append_Template_Scenarios (Report, Windows);
      Append (Report, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end Windows_UIA_Evidence_Template_JSON;

   function Windows_UIA_Captured_Evidence_Status_JSON
     (Evidence_JSON : String) return String
   is
      Valid_Schema : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "schema")
        = "org.a11y.windows_uia_captured_evidence.v1";
      Valid_Readiness : constant Boolean :=
        Project_Tools.JSON.Field_Value
          (Evidence_JSON, "readiness_evidence_id")
        = Readiness_Evidence_Id (Windows);
      Valid_Platform : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "platform")
        = "Windows";
      Valid_Native_API : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "native_api")
        = Native_API (Windows);
      Valid : constant Boolean :=
        Valid_Schema
        and then Valid_Readiness
        and then Valid_Platform
        and then Valid_Native_API;
      Captured : constant Natural :=
        (if Valid then
           Count_If
             (JSON_Boolean (Evidence_JSON, "tree_traversal_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "focus_and_activation_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "protected_text_captured"))
           + Count_If (JSON_Boolean (Evidence_JSON, "relations_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "live_announcement_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "window_lifecycle_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "action_requests_captured"))
         else 0);
      Required : constant Natural := Windows_Required_Scenario_Count;
      Pending : constant Natural := Required - Captured;
      Complete : constant Boolean := Valid and then Captured = Required;
      Report : constant Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.windows_uia_captured_evidence_status.v1")
           & "," & ASCII.LF
           & "  ""input_schema_valid"": "
           & (if Valid_Schema then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_readiness_evidence_valid"": "
           & (if Valid_Readiness then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_platform_valid"": "
           & (if Valid_Platform then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_native_api_valid"": "
           & (if Valid_Native_API then "true" else "false")
           & "," & ASCII.LF
           & "  ""valid"": "
           & (if Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (Windows))
           & "," & ASCII.LF
           & "  ""platform"": ""Windows""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (Windows))
           & "," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (Required)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (Captured)
           & "," & ASCII.LF
           & "  ""pending_scenario_count"": "
           & Natural_Image (Pending)
           & "," & ASCII.LF
           & "  ""windows_uia_public_client_qualification_complete"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_conformance_claim_allowed"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""manual_evidence_ingested"": "
           & (if Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""does_not_verify_evidence_authenticity"": true"
           & ASCII.LF
           & "}" & ASCII.LF);
   begin
      return To_String (Report);
   end Windows_UIA_Captured_Evidence_Status_JSON;

   function MacOS_NSAccessibility_Evidence_Template_JSON return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.macos_nsaccessibility_release_evidence.v1")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (MacOS))
           & "," & ASCII.LF
           & "  ""platform"": ""macOS""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (MacOS))
           & "," & ASCII.LF
           & "  ""qualification_gate_status"": "
           & Q (Qualification_Gate_Status (MacOS))
           & ","
           & ASCII.LF
           & "  ""native_boundary_stage"": "
           & Q (Native_Boundary_Stage (MacOS))
           & "," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (MacOS_Required_Scenario_Count)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (MacOS_Evidence_Captured_Count)
           & "," & ASCII.LF
           & "  ""required_live_probe"": "
           & Q ("tests/bin/native_client_nsax --probe-external-client")
           & "," & ASCII.LF
           & "  ""public_ax_smoke_probe"": "
           & Q ("tests/bin/native_client_nsax --probe-public-ax-client")
           & "," & ASCII.LF
           & "  ""required_probe_flags"": {"
           & """appkit_bridge_observed"": true,"
           & " ""element_registered"": true,"
           & " ""element_main_thread_bound"": true,"
           & " ""hierarchy_children_dispatched"": true,"
           & " ""hierarchy_children_frame_dispatched"": true,"
           & " ""hierarchy_child_at_index_dispatched"": true,"
           & " ""hierarchy_child_at_index_frame_dispatched"": true,"
           & " ""element_id_dispatched"": true,"
           & " ""attribute_value_frame_dispatched"": true,"
           & " ""attribute_settable_frame_dispatched"": true,"
           & " ""action_frame_dispatched"": true,"
           & " ""internal_native_export_chain_ready"": true,"
           & " ""macos_nsax_virtual_element_runtime_available"": true,"
           & " ""macos_nsax_virtual_element_runtime_probe_observed"": true,"
           & " ""macos_nsax_public_ax_client_runtime_available"": true,"
           & " ""macos_nsax_public_ax_client_process_id_available"": true,"
           & " ""macos_nsax_public_ax_client_probe_observed"": true,"
           & " ""external_client_traversal_observed"": true,"
           & " ""public_ax_client_traversal_observed"": true,"
           & " ""tree_traversal_captured"": true,"
           & " ""focus_and_activation_captured"": true,"
           & " ""protected_text_captured"": true,"
           & " ""window_lifecycle_captured"": true,"
           & " ""action_requests_captured"": true,"
           & " ""relations_captured"": true,"
           & " ""live_announcement_captured"": true,"
           & " ""switch_access_captured"": true,"
           & " ""voice_control_captured"": true},"
           & ASCII.LF
           & "  ""manual_record_fields"": ["
           & Q ("os_version")
           & ", "
           & Q ("assistive_technology")
           & ", "
           & Q ("assistive_technology_version")
           & ", "
           & Q ("fixture_scenario")
           & ", "
           & Q ("exact_steps")
           & ", "
           & Q ("expected_behavior")
           & ", "
           & Q ("observed_behavior")
           & ", "
           & Q ("evidence_location")
           & ", "
           & Q ("known_limitation_id")
           & "]," & ASCII.LF
           & "  ""scenario_records"": [" & ASCII.LF);
   begin
      Append_Template_Scenarios (Report, MacOS);
      Append (Report, ASCII.LF & "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end MacOS_NSAccessibility_Evidence_Template_JSON;

   function MacOS_NSAccessibility_Captured_Evidence_Status_JSON
     (Evidence_JSON : String) return String
   is
      Valid_Schema : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "schema")
        = "org.a11y.macos_nsaccessibility_captured_evidence.v1";
      Valid_Readiness : constant Boolean :=
        Project_Tools.JSON.Field_Value
          (Evidence_JSON, "readiness_evidence_id")
        = Readiness_Evidence_Id (MacOS);
      Valid_Platform : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "platform") = "macOS";
      Valid_Native_API : constant Boolean :=
        Project_Tools.JSON.Field_Value (Evidence_JSON, "native_api")
        = Native_API (MacOS);
      Valid : constant Boolean :=
        Valid_Schema
        and then Valid_Readiness
        and then Valid_Platform
        and then Valid_Native_API;
      Captured : constant Natural :=
        (if Valid then
           Count_If
             (JSON_Boolean (Evidence_JSON, "tree_traversal_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "focus_and_activation_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "protected_text_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "window_lifecycle_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "action_requests_captured"))
           + Count_If (JSON_Boolean (Evidence_JSON, "relations_captured"))
           + Count_If
               (JSON_Boolean (Evidence_JSON, "live_announcement_captured"))
           + Count_If (JSON_Boolean (Evidence_JSON, "switch_access_captured"))
           + Count_If (JSON_Boolean (Evidence_JSON, "voice_control_captured"))
         else 0);
      Required : constant Natural := MacOS_Required_Scenario_Count;
      Pending : constant Natural := Required - Captured;
      Complete : constant Boolean := Valid and then Captured = Required;
      Report : constant Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q
             ("org.a11y.macos_nsaccessibility_captured_evidence_status.v1")
           & "," & ASCII.LF
           & "  ""input_schema_valid"": "
           & (if Valid_Schema then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_readiness_evidence_valid"": "
           & (if Valid_Readiness then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_platform_valid"": "
           & (if Valid_Platform then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_native_api_valid"": "
           & (if Valid_Native_API then "true" else "false")
           & "," & ASCII.LF
           & "  ""valid"": "
           & (if Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""readiness_evidence_id"": "
           & Q (Readiness_Evidence_Id (MacOS))
           & "," & ASCII.LF
           & "  ""platform"": ""macOS""," & ASCII.LF
           & "  ""native_api"": "
           & Q (Native_API (MacOS))
           & "," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (Required)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (Captured)
           & "," & ASCII.LF
           & "  ""pending_scenario_count"": "
           & Natural_Image (Pending)
           & "," & ASCII.LF
           & "  ""macos_nsaccessibility_public_client_qualification_complete"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_conformance_claim_allowed"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""manual_evidence_ingested"": "
           & (if Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""does_not_verify_evidence_authenticity"": true"
           & ASCII.LF
           & "}" & ASCII.LF);
   begin
      return To_String (Report);
   end MacOS_NSAccessibility_Captured_Evidence_Status_JSON;

   function MacOS_NSAccessibility_Native_Client_Artifact_Status_JSON
     (Artifact_JSON : String) return String
   is
      Valid_Schema : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "schema")
        = "org.a11y.native_client_nsax_external_client.v1";
      Valid_Platform : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "platform") = "macOS";
      Valid_Native_API : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "native_api")
        = "NSAccessibility";
      Valid_Client : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "client_process")
        = "native_client_nsax";
      Native_Bridge_Compiled : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "native_bridge_compiled_for_macos");
      Non_Stub_Runtime : constant Boolean :=
        not JSON_Boolean (Artifact_JSON, "native_bridge_stub_runtime");
      Native_Transport : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "transport_status")
        = "native_client_available";
      Artifact_Transport_Status : constant String :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "transport_status");
      Completed_Evidence_Marker : constant Boolean :=
        Project_Tools.JSON.Field_Value
          (Artifact_JSON, "next_required_evidence")
        = "macos_nsaccessibility_automated_native_qualification_complete";
      Artifact_Next_Required_Evidence : constant String :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "next_required_evidence");
      Public_Root_Export_Path : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_export_path_observed");
      Virtual_Element_Bridge_Audited : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_virtual_element_bridge_audited");
      Virtual_Element_Runtime_Available : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_virtual_element_runtime_available");
      Virtual_Element_Runtime_Probe : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON,
           "macos_nsax_virtual_element_runtime_probe_observed");
      Public_AX_Client_Runtime_Available : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_ax_client_runtime_available");
      Public_AX_Client_Process_Id_Available : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON,
           "macos_nsax_public_ax_client_process_id_available");
      Public_AX_Client_Probe : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_ax_client_probe_observed");
      Public_Root_Element_Ensured : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_element_ensured");
      Public_Root_Main_Thread : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_main_thread_bound");
      Public_Root_Element_Resolved : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_element_resolved");
      Public_Root_Native_Identity : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON,
           "macos_nsax_public_root_native_node_component_stable");
      Public_Root_Children_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_children_frame_built");
      Public_Root_Child_At_Index_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON,
           "macos_nsax_public_root_child_at_index_frame_built");
      Public_Root_Attribute_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_attribute_frame_built");
      Public_Root_Attribute_Settable_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON,
           "macos_nsax_public_root_attribute_settable_frame_built");
      Public_Root_Action_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_action_frame_built");
      Public_Root_Hit_Test_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_hit_test_frame_built");
      Public_Root_Focused_Element_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON,
           "macos_nsax_public_root_focused_element_frame_built");
      Public_Root_Notification_Frame : constant Boolean :=
        JSON_Boolean
          (Artifact_JSON, "macos_nsax_public_root_notification_frame_built");
      Internal_Chain_Ready : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "internal_native_export_chain_ready");
      External_Traversal : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "external_client_traversal_observed");
      Public_AX_Client_Traversal : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "public_ax_client_traversal_observed");
      Scenario_Counts_Valid : constant Boolean :=
        JSON_Natural (Artifact_JSON, "required_scenario_count") = 9
        and then JSON_Natural (Artifact_JSON, "captured_scenario_count") = 9
        and then JSON_Natural (Artifact_JSON, "pending_scenario_count") = 0;
      Tree_Traversal : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "tree_traversal_captured");
      Focus_And_Activation : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "focus_and_activation_captured");
      Protected_Text_Scenario : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "protected_text_captured");
      Window_Lifecycle : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "window_lifecycle_captured");
      Action_Requests : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "action_requests_captured");
      Relations : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "relations_captured");
      Live_Announcement : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "live_announcement_captured");
      Switch_Access : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "switch_access_captured");
      Voice_Control : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "voice_control_captured");
      Protected_Text_Suppressed : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "protected_value_suppressed");
      Privacy_Boundary : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "privacy_boundary_observed");
      Semantic_State_Not_Mutated : constant Boolean :=
        not JSON_Boolean (Artifact_JSON, "semantic_state_mutated");
      Native_Conformance_Ready : constant Boolean :=
        JSON_Boolean (Artifact_JSON, "native_conformance_ready");
      Boundary_Success : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "boundary_status")
        = "SUCCESS";
      Status_Success : constant Boolean :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "status") = "success";
      Artifact_Status : constant String :=
        Project_Tools.JSON.Field_Value (Artifact_JSON, "status");
      Complete : constant Boolean :=
        MacOS_NSAX_Native_Client_Artifact_Complete (Artifact_JSON);
      Missing : constant Natural :=
        Count_If (not Valid_Schema)
        + Count_If (not Valid_Platform)
        + Count_If (not Valid_Native_API)
        + Count_If (not Valid_Client)
        + Count_If (not Native_Bridge_Compiled)
        + Count_If (not Non_Stub_Runtime)
        + Count_If (not Native_Transport)
        + Count_If (not Completed_Evidence_Marker)
        + Count_If (not Virtual_Element_Bridge_Audited)
        + Count_If (not Virtual_Element_Runtime_Available)
        + Count_If (not Virtual_Element_Runtime_Probe)
        + Count_If (not Public_AX_Client_Runtime_Available)
        + Count_If (not Public_AX_Client_Process_Id_Available)
        + Count_If (not Public_AX_Client_Probe)
        + Count_If (not Public_Root_Export_Path)
        + Count_If (not Public_Root_Element_Ensured)
        + Count_If (not Public_Root_Main_Thread)
        + Count_If (not Public_Root_Element_Resolved)
        + Count_If (not Public_Root_Native_Identity)
        + Count_If (not Public_Root_Children_Frame)
        + Count_If (not Public_Root_Child_At_Index_Frame)
        + Count_If (not Public_Root_Attribute_Frame)
        + Count_If (not Public_Root_Attribute_Settable_Frame)
        + Count_If (not Public_Root_Action_Frame)
        + Count_If (not Public_Root_Hit_Test_Frame)
        + Count_If (not Public_Root_Focused_Element_Frame)
        + Count_If (not Public_Root_Notification_Frame)
        + Count_If (not Internal_Chain_Ready)
        + Count_If (not External_Traversal)
        + Count_If (not Public_AX_Client_Traversal)
        + Count_If (not Scenario_Counts_Valid)
        + Count_If (not Tree_Traversal)
        + Count_If (not Focus_And_Activation)
        + Count_If (not Protected_Text_Scenario)
        + Count_If (not Window_Lifecycle)
        + Count_If (not Action_Requests)
        + Count_If (not Relations)
        + Count_If (not Live_Announcement)
        + Count_If (not Switch_Access)
        + Count_If (not Voice_Control)
        + Count_If (not Protected_Text_Suppressed)
        + Count_If (not Privacy_Boundary)
        + Count_If (not Semantic_State_Not_Mutated)
        + Count_If (not Native_Conformance_Ready)
        + Count_If (not Boundary_Success)
        + Count_If (not Status_Success);
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q
             ("org.a11y.macos_nsaccessibility_native_client_artifact_status.v1")
           & "," & ASCII.LF
           & "  ""input_schema_valid"": "
           & (if Valid_Schema then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_platform_valid"": "
           & (if Valid_Platform then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_native_api_valid"": "
           & (if Valid_Native_API then "true" else "false")
           & "," & ASCII.LF
           & "  ""input_client_process_valid"": "
           & (if Valid_Client then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_bridge_compiled_for_macos"": "
           & (if Native_Bridge_Compiled then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_bridge_stub_runtime_rejected"": "
           & (if Non_Stub_Runtime then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_transport_available"": "
           & (if Native_Transport then "true" else "false")
           & "," & ASCII.LF
           & "  ""completed_evidence_marker_present"": "
           & (if Completed_Evidence_Marker then "true" else "false")
           & "," & ASCII.LF
           & "  ""artifact_transport_status"": "
           & Q (Artifact_Transport_Status)
           & "," & ASCII.LF
           & "  ""artifact_next_required_evidence"": "
           & Q (Artifact_Next_Required_Evidence)
           & "," & ASCII.LF
           & "  ""virtual_element_bridge_audited"": "
           & (if Virtual_Element_Bridge_Audited then "true" else "false")
           & "," & ASCII.LF
           & "  ""virtual_element_runtime_available"": "
           & (if Virtual_Element_Runtime_Available then "true" else "false")
           & "," & ASCII.LF
           & "  ""virtual_element_runtime_probe_observed"": "
           & (if Virtual_Element_Runtime_Probe then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_ax_client_runtime_available"": "
           & (if Public_AX_Client_Runtime_Available then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_ax_client_process_id_available"": "
           & (if Public_AX_Client_Process_Id_Available
              then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_ax_client_probe_observed"": "
           & (if Public_AX_Client_Probe then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_export_path_observed"": "
           & (if Public_Root_Export_Path then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_element_ensured"": "
           & (if Public_Root_Element_Ensured then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_main_thread_bound"": "
           & (if Public_Root_Main_Thread then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_element_resolved"": "
           & (if Public_Root_Element_Resolved then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_native_identity_stable"": "
           & (if Public_Root_Native_Identity then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_children_frame_built"": "
           & (if Public_Root_Children_Frame then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_child_at_index_frame_built"": "
           & (if Public_Root_Child_At_Index_Frame then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_attribute_frame_built"": "
           & (if Public_Root_Attribute_Frame then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_attribute_settable_frame_built"": "
           & (if Public_Root_Attribute_Settable_Frame
              then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_action_frame_built"": "
           & (if Public_Root_Action_Frame then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_hit_test_frame_built"": "
           & (if Public_Root_Hit_Test_Frame then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_focused_element_frame_built"": "
           & (if Public_Root_Focused_Element_Frame
              then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_root_notification_frame_built"": "
           & (if Public_Root_Notification_Frame then "true" else "false")
           & "," & ASCII.LF
           & "  ""internal_native_export_chain_ready"": "
           & (if Internal_Chain_Ready then "true" else "false")
           & "," & ASCII.LF
           & "  ""external_client_traversal_observed"": "
           & (if External_Traversal then "true" else "false")
           & "," & ASCII.LF
           & "  ""public_ax_client_traversal_observed"": "
           & (if Public_AX_Client_Traversal then "true" else "false")
           & "," & ASCII.LF
           & "  ""scenario_counts_valid"": "
           & (if Scenario_Counts_Valid then "true" else "false")
           & "," & ASCII.LF
           & "  ""tree_traversal_captured"": "
           & (if Tree_Traversal then "true" else "false")
           & "," & ASCII.LF
           & "  ""focus_and_activation_captured"": "
           & (if Focus_And_Activation then "true" else "false")
           & "," & ASCII.LF
           & "  ""protected_text_captured"": "
           & (if Protected_Text_Scenario then "true" else "false")
           & "," & ASCII.LF
           & "  ""window_lifecycle_captured"": "
           & (if Window_Lifecycle then "true" else "false")
           & "," & ASCII.LF
           & "  ""action_requests_captured"": "
           & (if Action_Requests then "true" else "false")
           & "," & ASCII.LF
           & "  ""relations_captured"": "
           & (if Relations then "true" else "false")
           & "," & ASCII.LF
           & "  ""live_announcement_captured"": "
           & (if Live_Announcement then "true" else "false")
           & "," & ASCII.LF
           & "  ""switch_access_captured"": "
           & (if Switch_Access then "true" else "false")
           & "," & ASCII.LF
           & "  ""voice_control_captured"": "
           & (if Voice_Control then "true" else "false")
           & "," & ASCII.LF
           & "  ""protected_text_suppressed"": "
           & (if Protected_Text_Suppressed then "true" else "false")
           & "," & ASCII.LF
           & "  ""privacy_boundary_observed"": "
           & (if Privacy_Boundary then "true" else "false")
           & "," & ASCII.LF
           & "  ""semantic_state_not_mutated"": "
           & (if Semantic_State_Not_Mutated then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_conformance_ready"": "
           & (if Native_Conformance_Ready then "true" else "false")
           & "," & ASCII.LF
           & "  ""boundary_status_success"": "
           & (if Boundary_Success then "true" else "false")
           & "," & ASCII.LF
           & "  ""status_success"": "
           & (if Status_Success then "true" else "false")
           & "," & ASCII.LF
           & "  ""artifact_status"": "
           & Q (Artifact_Status)
           & "," & ASCII.LF
           & "  ""missing_required_field_count"": "
           & Natural_Image (Missing)
           & "," & ASCII.LF
           & "  ""macos_nsaccessibility_automated_native_qualification_complete"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""project_completion_gate_accepts_artifact"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""missing_required_fields"": [");
      Have_Missing : Boolean := False;

      procedure Append_Missing
        (Condition : Boolean;
         Name      : String)
      is
      begin
         if not Condition then
            if Have_Missing then
               Append (Report, ", ");
            end if;
            Append (Report, Q (Name));
            Have_Missing := True;
         end if;
      end Append_Missing;
   begin
      Append_Missing (Valid_Schema, "schema");
      Append_Missing (Valid_Platform, "platform");
      Append_Missing (Valid_Native_API, "native_api");
      Append_Missing (Valid_Client, "client_process");
      Append_Missing
        (Native_Bridge_Compiled, "native_bridge_compiled_for_macos");
      Append_Missing
        (Non_Stub_Runtime, "native_bridge_stub_runtime_false");
      Append_Missing (Native_Transport, "transport_status");
      Append_Missing
        (Completed_Evidence_Marker, "next_required_evidence");
      Append_Missing
        (Virtual_Element_Bridge_Audited,
         "macos_nsax_virtual_element_bridge_audited");
      Append_Missing
        (Virtual_Element_Runtime_Available,
         "macos_nsax_virtual_element_runtime_available");
      Append_Missing
        (Virtual_Element_Runtime_Probe,
         "macos_nsax_virtual_element_runtime_probe_observed");
      Append_Missing
        (Public_AX_Client_Runtime_Available,
         "macos_nsax_public_ax_client_runtime_available");
      Append_Missing
        (Public_AX_Client_Process_Id_Available,
         "macos_nsax_public_ax_client_process_id_available");
      Append_Missing
        (Public_AX_Client_Probe,
         "macos_nsax_public_ax_client_probe_observed");
      Append_Missing
        (Public_Root_Export_Path,
         "macos_nsax_public_root_export_path_observed");
      Append_Missing
        (Public_Root_Element_Ensured,
         "macos_nsax_public_root_element_ensured");
      Append_Missing
        (Public_Root_Main_Thread,
         "macos_nsax_public_root_main_thread_bound");
      Append_Missing
        (Public_Root_Element_Resolved,
         "macos_nsax_public_root_element_resolved");
      Append_Missing
        (Public_Root_Native_Identity,
         "macos_nsax_public_root_native_node_component_stable");
      Append_Missing
        (Public_Root_Children_Frame,
         "macos_nsax_public_root_children_frame_built");
      Append_Missing
        (Public_Root_Child_At_Index_Frame,
         "macos_nsax_public_root_child_at_index_frame_built");
      Append_Missing
        (Public_Root_Attribute_Frame,
         "macos_nsax_public_root_attribute_frame_built");
      Append_Missing
        (Public_Root_Attribute_Settable_Frame,
         "macos_nsax_public_root_attribute_settable_frame_built");
      Append_Missing
        (Public_Root_Action_Frame,
         "macos_nsax_public_root_action_frame_built");
      Append_Missing
        (Public_Root_Hit_Test_Frame,
         "macos_nsax_public_root_hit_test_frame_built");
      Append_Missing
        (Public_Root_Focused_Element_Frame,
         "macos_nsax_public_root_focused_element_frame_built");
      Append_Missing
        (Public_Root_Notification_Frame,
         "macos_nsax_public_root_notification_frame_built");
      Append_Missing
        (Internal_Chain_Ready, "internal_native_export_chain_ready");
      Append_Missing
        (External_Traversal, "external_client_traversal_observed");
      Append_Missing
        (Public_AX_Client_Traversal, "public_ax_client_traversal_observed");
      Append_Missing (Scenario_Counts_Valid, "scenario_counts_valid");
      Append_Missing (Tree_Traversal, "tree_traversal_captured");
      Append_Missing
        (Focus_And_Activation, "focus_and_activation_captured");
      Append_Missing (Protected_Text_Scenario, "protected_text_captured");
      Append_Missing (Window_Lifecycle, "window_lifecycle_captured");
      Append_Missing (Action_Requests, "action_requests_captured");
      Append_Missing (Relations, "relations_captured");
      Append_Missing (Live_Announcement, "live_announcement_captured");
      Append_Missing (Switch_Access, "switch_access_captured");
      Append_Missing (Voice_Control, "voice_control_captured");
      Append_Missing
        (Protected_Text_Suppressed, "protected_value_suppressed");
      Append_Missing (Privacy_Boundary, "privacy_boundary_observed");
      Append_Missing
        (Semantic_State_Not_Mutated, "semantic_state_mutated_false");
      Append_Missing (Native_Conformance_Ready, "native_conformance_ready");
      Append_Missing (Boundary_Success, "boundary_status");
      Append_Missing (Status_Success, "status");
      Append (Report, "]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end MacOS_NSAccessibility_Native_Client_Artifact_Status_JSON;

   function Captured_Evidence_Summary_JSON
     (Linux_Evidence_JSON   : String;
      Windows_Evidence_JSON : String;
      MacOS_Evidence_JSON   : String) return String
   is
      Linux_Status : constant String :=
        Linux_ATSPI_Captured_Evidence_Status_JSON (Linux_Evidence_JSON);
      Windows_Status : constant String :=
        Windows_UIA_Captured_Evidence_Status_JSON (Windows_Evidence_JSON);
      MacOS_Status : constant String :=
        MacOS_NSAccessibility_Captured_Evidence_Status_JSON
          (MacOS_Evidence_JSON);
      Linux_Complete : constant Boolean :=
        JSON_Boolean (Linux_Status, "native_conformance_claim_allowed");
      Windows_Complete : constant Boolean :=
        JSON_Boolean (Windows_Status, "native_conformance_claim_allowed");
      MacOS_Complete : constant Boolean :=
        JSON_Boolean (MacOS_Status, "native_conformance_claim_allowed");
      Required : constant Natural :=
        JSON_Natural (Linux_Status, "required_scenario_count")
        + JSON_Natural (Windows_Status, "required_scenario_count")
        + JSON_Natural (MacOS_Status, "required_scenario_count");
      Captured : constant Natural :=
        JSON_Natural (Linux_Status, "captured_scenario_count")
        + JSON_Natural (Windows_Status, "captured_scenario_count")
        + JSON_Natural (MacOS_Status, "captured_scenario_count");
      Pending : constant Natural :=
        JSON_Natural (Linux_Status, "pending_scenario_count")
        + JSON_Natural (Windows_Status, "pending_scenario_count")
        + JSON_Natural (MacOS_Status, "pending_scenario_count");
      Complete : constant Boolean :=
        Linux_Complete and then Windows_Complete and then MacOS_Complete;
      Report : constant Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": "
           & Q ("org.a11y.captured_evidence_summary.v1")
           & "," & ASCII.LF
           & "  ""platform_count"": 3," & ASCII.LF
           & "  ""required_scenario_count"": "
           & Natural_Image (Required)
           & "," & ASCII.LF
           & "  ""captured_scenario_count"": "
           & Natural_Image (Captured)
           & "," & ASCII.LF
           & "  ""pending_scenario_count"": "
           & Natural_Image (Pending)
           & "," & ASCII.LF
           & "  ""linux_native_conformance_claim_allowed"": "
           & (if Linux_Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""windows_native_conformance_claim_allowed"": "
           & (if Windows_Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""macos_native_conformance_claim_allowed"": "
           & (if MacOS_Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""native_conformance_claim_allowed"": "
           & (if Complete then "true" else "false")
           & "," & ASCII.LF
           & "  ""does_not_verify_evidence_authenticity"": true,"
           & ASCII.LF
           & "  ""platform_statuses"": ["
           & ASCII.LF
           & Linux_Status
           & ","
           & ASCII.LF
           & Windows_Status
           & ","
           & ASCII.LF
           & MacOS_Status
           & "  ]"
           & ASCII.LF
           & "}" & ASCII.LF);
   begin
      return To_String (Report);
   end Captured_Evidence_Summary_JSON;

   function Markdown return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("# a11y Release Qualification" & ASCII.LF & ASCII.LF
           & "Record OS version, assistive-technology version, observed behavior,"
           & " and evidence location for each scenario." & ASCII.LF & ASCII.LF
           & "Evidence status: "
           & Natural_Image (Evidence_Pending_Count)
           & " pending, "
           & Natural_Image (Evidence_Captured_Count)
           & " captured."
           & ASCII.LF
           & ASCII.LF
           & "| Platform | Assistive technology | OS version | AT version | Scenario | Steps | Expected | Observed | Evidence | Native probe command | Conformance feature | Readiness evidence | Known limitation | Qualification status |"
           & ASCII.LF
           & "| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |"
           & ASCII.LF);
   begin
      for Scenario of Scenarios loop
         Append
           (Report,
            "| "
            & Platform_Name (Scenario.Platform)
            & " | "
            & Trimmed (Scenario.Assistive_Technology)
            & " | "
            & Trimmed (Scenario.OS_Version)
            & " | "
            & Trimmed (Scenario.AT_Version)
            & " | "
            & Scenario_Name (Scenario.Scenario)
            & " | "
            & Trimmed (Scenario.Steps)
            & " | "
            & Trimmed (Scenario.Expected)
            & " | "
            & Trimmed (Scenario.Observed)
            & " | "
            & Trimmed (Scenario.Evidence)
            & " | "
            & Trimmed (Scenario.Native_Probe_Command)
            & " | "
            & Trimmed (Scenario.Conformance_Feature_Id)
            & " | "
            & Readiness_Evidence_Id (Scenario.Platform)
            & " | "
            & Trimmed (Scenario.Limitation)
            & " | "
            & Qualification_Status (Scenario)
            & " |"
            & ASCII.LF);
      end loop;
      return To_String (Report);
   end Markdown;

   function JSON return String is
      Report : Unbounded_String :=
        To_Unbounded_String
          ("{" & ASCII.LF
           & "  ""schema"": " & Q (Schema) & "," & ASCII.LF
           & "  ""coverage"": {""core_assistive_technology_all_platforms"": "
           & (if Has_Core_Assistive_Technology_For_All_Platforms then
                "true"
              else
                "false")
           & ", ""tree_traversal_all_platforms"": "
           & (if Has_Tree_Traversal_For_All_Platforms then "true" else "false")
           & ", ""protected_text_all_platforms"": "
           & (if Has_Protected_Text_For_All_Platforms then "true" else "false")
           & ", ""window_lifecycle_all_platforms"": "
           & (if Has_Window_Lifecycle_For_All_Platforms then "true" else "false")
           & ", ""action_requests_all_platforms"": "
           & (if Has_Action_Requests_For_All_Platforms then "true" else "false")
           & ", ""relations_all_platforms"": "
           & (if Has_Relations_For_All_Platforms then "true" else "false")
           & ", ""live_announcements_all_platforms"": "
           & (if Has_Live_Announcements_For_All_Platforms then
                "true"
              else
                "false")
           & ", ""evidence_pending_count"": "
           & Natural_Image (Evidence_Pending_Count)
           & ", ""evidence_captured_count"": "
           & Natural_Image (Evidence_Captured_Count)
           & ", ""linux_required_scenario_count"": "
           & Natural_Image (Linux_Required_Scenario_Count)
           & ", ""linux_evidence_pending_count"": "
           & Natural_Image (Linux_Evidence_Pending_Count)
           & ", ""linux_evidence_captured_count"": "
           & Natural_Image (Linux_Evidence_Captured_Count)
           & ", ""windows_required_scenario_count"": "
           & Natural_Image (Windows_Required_Scenario_Count)
           & ", ""windows_evidence_pending_count"": "
           & Natural_Image (Windows_Evidence_Pending_Count)
           & ", ""windows_evidence_captured_count"": "
           & Natural_Image (Windows_Evidence_Captured_Count)
           & ", ""macos_required_scenario_count"": "
           & Natural_Image (MacOS_Required_Scenario_Count)
           & ", ""macos_evidence_pending_count"": "
           & Natural_Image (MacOS_Evidence_Pending_Count)
           & ", ""macos_evidence_captured_count"": "
           & Natural_Image (MacOS_Evidence_Captured_Count)
           & ", ""all_evidence_pending"": "
           & (if All_Evidence_Pending then "true" else "false")
           & "}," & ASCII.LF
           & "  ""platform_evidence"": "
           & Platform_Evidence_Summary_JSON
           & "," & ASCII.LF
           & "  ""scenarios"": [" & ASCII.LF);
   begin
      for Index in Scenarios'Range loop
         declare
            Scenario : Scenario_Record renames Scenarios (Index);
            Suffix : constant String :=
              (if Index = Scenarios'Last then "" else ",");
         begin
            Append
              (Report,
               "    {""platform"": "
               & Q (Platform_Name (Scenario.Platform))
               & ", ""assistive_technology"": "
               & Q (Trimmed (Scenario.Assistive_Technology))
               & ", ""os_version"": "
               & Q (Trimmed (Scenario.OS_Version))
               & ", ""assistive_technology_version"": "
               & Q (Trimmed (Scenario.AT_Version))
               & ", ""scenario"": "
               & Q (Scenario_Name (Scenario.Scenario))
               & ", ""steps"": "
               & Q (Trimmed (Scenario.Steps))
               & ", ""expected"": "
               & Q (Trimmed (Scenario.Expected))
               & ", ""observed"": "
               & Q (Trimmed (Scenario.Observed))
               & ", ""evidence"": "
               & Q (Trimmed (Scenario.Evidence))
               & ", ""native_probe_command"": "
               & Q (Trimmed (Scenario.Native_Probe_Command))
               & ", ""conformance_feature_id"": "
               & Q (Trimmed (Scenario.Conformance_Feature_Id))
               & ", ""readiness_evidence_id"": "
               & Q (Readiness_Evidence_Id (Scenario.Platform))
               & ", ""known_limitation"": "
               & Q (Trimmed (Scenario.Limitation))
               & ", ""qualification_status"": "
               & Q (Qualification_Status (Scenario))
               & "}" & Suffix & ASCII.LF);
         end;
      end loop;
      Append (Report, "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Report);
   end JSON;
end A11y_Release_Qualification;
