with A11y.Conformance.Classification;

package body A11y.Conformance is
   use Ada.Strings.Unbounded;

   function Dotted_Name (Feature : Feature_Id) return String is
     (case Feature is
        when Core_Role_Button => "core.role.button",
        when Core_Role_Application => "core.role.application",
        when Core_Role_Window => "core.role.window",
        when Core_Role_Dialog => "core.role.dialog",
        when Core_Role_Group => "core.role.group",
        when Core_Role_Region => "core.role.region",
        when Core_Role_Static_Text => "core.role.static_text",
        when Core_Role_Toggle_Button => "core.role.toggle_button",
        when Core_Role_Check_Box => "core.role.check_box",
        when Core_Role_Radio_Button => "core.role.radio_button",
        when Core_Role_Progress_Bar => "core.role.progress_bar",
        when Core_Role_Spin_Button => "core.role.spin_button",
        when Core_Role_Slider => "core.role.slider",
        when Core_Role_List => "core.role.list",
        when Core_Role_List_Item => "core.role.list_item",
        when Core_Role_Tree => "core.role.tree",
        when Core_Role_Tree_Item => "core.role.tree_item",
        when Core_Role_Table => "core.role.table",
        when Core_Role_Row => "core.role.row",
        when Core_Role_Column => "core.role.column",
        when Core_Role_Cell => "core.role.cell",
        when Core_Role_Combo_Box => "core.role.combo_box",
        when Core_Role_Search_Field => "core.role.search_field",
        when Core_Role_Menu_Bar => "core.role.menu_bar",
        when Core_Role_Menu => "core.role.menu",
        when Core_Role_Menu_Item => "core.role.menu_item",
        when Core_Role_Tool_Bar => "core.role.tool_bar",
        when Core_Role_Tab_List => "core.role.tab_list",
        when Core_Role_Tab => "core.role.tab",
        when Core_Role_Tooltip => "core.role.tooltip",
        when Core_Role_Heading => "core.role.heading",
        when Core_Role_Document => "core.role.document",
        when Core_Role_Text => "core.role.text",
        when Core_Role_Link => "core.role.link",
        when Core_Role_Password_Field => "core.role.password_field",
        when Core_Role_Scroll_Bar => "core.role.scroll_bar",
        when Core_Role_Separator => "core.role.separator",
        when Core_Role_Alert => "core.role.alert",
        when Core_Role_Popup_Dialog => "core.role.popup_dialog",
        when Core_Role_Text_Field => "core.role.text_field",
        when Core_Role_Image => "core.role.image",
        when Core_Role_Status => "core.role.status",
        when Core_Role_Decorative_Image => "core.role.decorative_image",
        when Core_Role_Canvas => "core.role.canvas",
        when Core_Role_Custom => "core.role.custom",
        when Core_Role_Metadata => "core.role.metadata",
        when Core_Lifecycle_Metadata => "core.lifecycle.metadata",
        when Core_Lifecycle_Transition => "core.lifecycle.transition",
        when Lifecycle_Stale_Reference => "lifecycle.stale_reference",
        when Core_Exposure_Metadata => "core.exposure.metadata",
        when Core_Focus_Session => "core.focus.session",
        when Core_State_Enabled => "core.state.enabled",
        when Core_State_Sensitive => "core.state.sensitive",
        when Core_State_Visible => "core.state.visible",
        when Core_State_Showing => "core.state.showing",
        when Core_State_Focused => "core.state.focused",
        when Core_State_Focusable => "core.state.focusable",
        when Core_State_Selected => "core.state.selected",
        when Core_State_Selectable => "core.state.selectable",
        when Core_State_Checked => "core.state.checked",
        when Core_State_Indeterminate => "core.state.indeterminate",
        when Core_State_Expanded => "core.state.expanded",
        when Core_State_Expandable => "core.state.expandable",
        when Core_State_Pressed => "core.state.pressed",
        when Core_State_Read_Only => "core.state.read_only",
        when Core_State_Editable => "core.state.editable",
        when Core_State_Required => "core.state.required",
        when Core_State_Invalid => "core.state.invalid",
        when Core_State_Busy => "core.state.busy",
        when Core_State_Modal => "core.state.modal",
        when Core_State_Multi_Line => "core.state.multi_line",
        when Core_State_Multi_Selectable => "core.state.multi_selectable",
        when Core_State_Visited => "core.state.visited",
        when Core_State_Offscreen => "core.state.offscreen",
        when Core_State_Defunct => "core.state.defunct",
        when Core_State_Active => "core.state.active",
        when Core_State_Metadata => "core.state.metadata",
        when Core_State_Derivation => "core.state.derivation",
        when Core_State_Validation => "core.state.validation",
        when Core_Capability_Action => "core.capability.action",
        when Core_Capability_Text => "core.capability.text",
        when Core_Capability_Editable_Text => "core.capability.editable_text",
        when Core_Capability_Value => "core.capability.value",
        when Core_Capability_Selection => "core.capability.selection",
        when Core_Capability_Table => "core.capability.table",
        when Core_Capability_Document => "core.capability.document",
        when Core_Capability_Image => "core.capability.image",
        when Core_Capability_Relation => "core.capability.relation",
        when Core_Capability_Live_Region =>
          "core.capability.live_region",
        when Core_Capability_Surface => "core.capability.surface",
        when Core_Capability_Metadata => "core.capability.metadata",
        when Core_Provider_Contract => "core.provider.contract",
        when Core_Geometry_Visibility => "core.geometry.visibility",
        when Core_Geometry_Region => "core.geometry.region",
        when Core_Node_Key_Registry => "core.node_key.registry",
        when Core_Property_Role => "core.property.role",
        when Core_Property_State_Set => "core.property.state_set",
        when Core_Property_Name => "core.property.name",
        when Core_Property_Visible_Title => "core.property.visible_title",
        when Core_Property_Description => "core.property.description",
        when Core_Property_Help_Text => "core.property.help_text",
        when Core_Property_Placeholder => "core.property.placeholder",
        when Core_Property_Value_Text => "core.property.value_text",
        when Core_Property_Keyboard_Shortcut =>
          "core.property.keyboard_shortcut",
        when Core_Property_Semantic_Identifier =>
          "core.property.semantic_identifier",
        when Core_Property_Locale => "core.property.locale",
        when Core_Property_Orientation => "core.property.orientation",
        when Core_Property_Set_Position => "core.property.set_position",
        when Core_Property_Set_Size => "core.property.set_size",
        when Core_Property_Hierarchical_Level =>
          "core.property.hierarchical_level",
        when Core_Property_Heading_Level => "core.property.heading_level",
        when Core_Property_Landmark => "core.property.landmark",
        when Core_Property_Bounds => "core.property.bounds",
        when Core_Property_Typed_Results => "core.property.typed_results",
        when Core_Property_Status_Mapping =>
          "core.property.status_mapping",
        when Core_Property_Metadata => "core.property.metadata",
        when Actions_Activate => "actions.activate",
        when Actions_Press => "actions.press",
        when Actions_Toggle => "actions.toggle",
        when Actions_Expand => "actions.expand",
        when Actions_Collapse => "actions.collapse",
        when Actions_Show_Menu => "actions.show_menu",
        when Actions_Dismiss => "actions.dismiss",
        when Actions_Increment => "actions.increment",
        when Actions_Decrement => "actions.decrement",
        when Actions_Select_Item => "actions.select",
        when Actions_Deselect => "actions.deselect",
        when Actions_Clear_Selection => "actions.clear_selection",
        when Actions_Open => "actions.open",
        when Actions_Close => "actions.close",
        when Actions_Scroll_Into_View => "actions.scroll_into_view",
        when Actions_Set_Focus => "actions.set_focus",
        when Actions_Metadata => "actions.metadata",
        when Actions_Preconditions => "actions.preconditions",
        when Relations_Metadata => "relations.metadata",
        when Relations_Labelled_By => "relations.labelled_by",
        when Relations_Label_For => "relations.label_for",
        when Relations_Described_By => "relations.described_by",
        when Relations_Description_For => "relations.description_for",
        when Relations_Controlled_By => "relations.controlled_by",
        when Relations_Controller_For => "relations.controller_for",
        when Relations_Flows_To => "relations.flows_to",
        when Relations_Flows_From => "relations.flows_from",
        when Relations_Member_Of => "relations.member_of",
        when Relations_Details => "relations.details",
        when Relations_Details_For => "relations.details_for",
        when Relations_Active_Descendant =>
          "relations.active_descendant",
        when Relations_Error_Message => "relations.error_message",
        when Relations_Error_For => "relations.error_for",
        when Relations_Embedded_By => "relations.embedded_by",
        when Relations_Embeds => "relations.embeds",
        when Relations_Popup_For => "relations.popup_for",
        when Relations_Popup_Controlled_By =>
          "relations.popup_controlled_by",
        when Relations_Resource_Limit => "relations.resource_limit",
        when Relations_Session_Ownership =>
          "relations.session_ownership",
        when Value_Kind_Unknown => "value.kind.unknown",
        when Value_Kind_Indeterminate => "value.kind.indeterminate",
        when Value_Kind_Integer => "value.kind.integer",
        when Value_Kind_Decimal => "value.kind.decimal",
        when Value_Kind_Floating => "value.kind.floating",
        when Value_Kind_Boolean => "value.kind.boolean",
        when Value_Kind_Enumerated => "value.kind.enumerated",
        when Value_Access_Read_Only => "value.access.read_only",
        when Value_Access_Writable => "value.access.writable",
        when Value_Metadata => "value.metadata",
        when Value_Basic => "value.basic",
        when Value_Range => "value.range",
        when Value_Decimal_Exact => "value.decimal.exact",
        when Value_Resource_Limit => "value.resource_limit",
        when Value_Precision_Loss => "value.precision_loss",
        when Selection_Metadata => "selection.metadata",
        when Selection_Single => "selection.single",
        when Selection_Multiple => "selection.multiple",
        when Selection_Range => "selection.range",
        when Selection_Direction => "selection.direction",
        when Selection_Select_All => "selection.select_all",
        when Selection_Current_Item => "selection.current_item",
        when Selection_Resource_Limit => "selection.resource_limit",
        when Selection_Validation => "selection.validation",
        when Text_Metadata => "text.metadata",
        when Text_Range_Basic => "text.range.basic",
        when Text_Edit_Request => "text.edit.request",
        when Text_UTF16_Conversion => "text.utf16.conversion",
        when Text_Protected => "text.protected",
        when Text_Resource_Limit => "text.resource_limit",
        when Table_Metadata => "table.metadata",
        when Table_Cell_Basic => "table.cell.basic",
        when Table_Cell_Span => "table.cell.span",
        when Table_Current_Cell => "table.current_cell",
        when Table_Sort_Metadata => "table.sort.metadata",
        when Table_Virtual_Size => "table.virtual.size",
        when Table_Resource_Limit => "table.resource_limit",
        when Document_Metadata => "document.metadata",
        when Document_Heading_Level => "document.heading.level",
        when Document_Landmark => "document.landmark",
        when Document_Resource_Limit => "document.resource_limit",
        when Image_Metadata => "image.metadata",
        when Image_Alternative_Text => "image.alternative_text",
        when Image_Caption => "image.caption",
        when Image_Category => "image.category",
        when Image_Decorative => "image.decorative",
        when Image_Resource_Limit => "image.resource_limit",
        when Window_Surface_Metadata => "window.surface.metadata",
        when Window_Surface_Kind_Name => "window.surface.kind_name",
        when Window_Surface_Modal => "window.surface.modal",
        when Window_Surface_State_Metadata =>
          "window.surface.state_metadata",
        when Window_Surface_Validation => "window.surface.validation",
        when Native_Identity_Object_Path => "native.identity.object_path",
        when Native_Identity_Runtime_Id => "native.identity.runtime_id",
        when Native_Object_Cache_Identity =>
          "native.object_cache.identity",
        when Native_Object_Cache_Tombstone =>
          "native.object_cache.tombstone",
        when Native_Object_Cache_Session_Scope =>
          "native.object_cache.session_scope",
        when Native_Object_Cache_Node_Index =>
          "native.object_cache.node_index",
        when Native_Object_Cache_Resource_Limit =>
          "native.object_cache.resource_limit",
        when Native_Object_Cache_Generation =>
          "native.object_cache.generation",
        when Native_Object_Cache_Mutation_Report =>
          "native.object_cache.mutation_report",
        when Native_Object_Registry_Generation =>
          "native.object_registry.generation",
        when Native_Object_Registry_Drained_Reset =>
          "native.object_registry.drained_reset",
        when Native_Object_Registry_Mutation_Report =>
          "native.object_registry.mutation_report",
        when Native_Object_Export_Descriptor =>
          "native.object_export_descriptor",
        when Native_Object_Lifetime_Resource_Limit =>
          "native.object_lifetime.resource_limit",
        when Native_Value_Resource_Limit =>
          "native.value.resource_limit",
        when Native_Runtime_Lifecycle =>
          "native.runtime.lifecycle",
        when Native_Runtime_Generation =>
          "native.runtime.generation",
        when Native_Runtime_Lifecycle_Report =>
          "native.runtime.lifecycle_report",
        when Native_Runtime_Probe_Failure_Stage =>
          "native.runtime.probe_failure_stage",
        when Native_Readiness_Boundary_Stage =>
          "native.readiness.boundary_stage",
        when Native_Readiness_Remaining_Evidence =>
          "native.readiness.remaining_evidence",
        when Native_Runtime_Event_Application =>
          "native.runtime.event_application",
        when Native_Runtime_Event_Preparation =>
          "native.runtime.event_preparation",
        when Native_Runtime_Event_Preparation_Report =>
          "native.runtime.event_preparation_report",
        when Native_Projection_Property =>
          "native.projection.property",
        when Native_Projection_Action =>
          "native.projection.action",
        when Native_Request_Action_Payload =>
          "native.request.action_payload",
        when Native_Projection_Relation =>
          "native.projection.relation",
        when Native_Projection_Event_Source =>
          "native.projection.event_source",
        when Native_Event_Validation =>
          "native.event.validation",
        when Native_Event_Prepared_Status =>
          "native.event.prepared_status",
        when Native_Event_Staging_Queue =>
          "native.event.staging_queue",
        when Native_Event_Posting_Interest =>
          "native.event.posting_interest",
        when Native_Event_Posting_Boundary =>
          "native.event.posting_boundary",
        when Native_Event_Exhaustive_Map =>
          "native.event.exhaustive_map",
        when Native_Role_Exhaustive_Map =>
          "native.role.exhaustive_map",
        when Native_Relation_Exhaustive_Map =>
          "native.relation.exhaustive_map",
        when Native_Callback_Gate =>
          "native.callback.gate",
        when Native_Callback_Generation =>
          "native.callback.generation",
        when Native_Boundary_Call_Context =>
          "native.boundary.call_context",
        when Native_Boundary_Call_Kind =>
          "native.boundary.call_kind",
        when Native_Boundary_Return_Class =>
          "native.boundary.return_class",
        when Native_Boundary_Status_Recording =>
          "native.boundary.status_recording",
        when Native_Boundary_Cancellation =>
          "native.boundary.cancellation",
        when Native_Boundary_Query_Cancellation =>
          "native.boundary.query_cancellation",
        when Native_Boundary_Tree_Cancellation =>
          "native.boundary.tree_cancellation",
        when Native_Boundary_Component_Cancellation =>
          "native.boundary.component_cancellation",
        when Native_Boundary_Focus_Cancellation =>
          "native.boundary.focus_cancellation",
        when Native_Boundary_Relation_Cancellation =>
          "native.boundary.relation_cancellation",
        when Native_Boundary_Action_Call =>
          "native.boundary.action_call",
        when Native_Boundary_Node_Action_Call =>
          "native.boundary.node_action_call",
        when Native_Boundary_Query_Call =>
          "native.boundary.query_call",
        when Native_Boundary_Node_Query_Call =>
          "native.boundary.node_query_call",
        when Native_Boundary_Tree_Call =>
          "native.boundary.tree_call",
        when Native_Boundary_Node_Tree_Call =>
          "native.boundary.node_tree_call",
        when Native_Boundary_Component_Call =>
          "native.boundary.component_call",
        when Native_Boundary_Node_Component_Call =>
          "native.boundary.node_component_call",
        when Native_Boundary_Focus_Call =>
          "native.boundary.focus_call",
        when Native_Boundary_Node_Focus_Call =>
          "native.boundary.node_focus_call",
        when Native_Boundary_Relation_Call =>
          "native.boundary.relation_call",
        when Native_Boundary_Node_Relation_Call =>
          "native.boundary.node_relation_call",
        when Native_Boundary_Node_Call =>
          "native.boundary.node_call",
        when Native_Boundary_Stale_Metadata =>
          "native.boundary.stale_metadata",
        when Native_Boundary_Error_Map =>
          "native.boundary.error_map",
        when Native_Boundary_Identity_Admission =>
          "native.boundary.identity_admission",
        when Native_Boundary_Request_Admission =>
          "native.boundary.request_admission",
        when Native_Boundary_Admission_Report =>
          "native.boundary.admission_report",
        when Native_Boundary_Native_Call_Report =>
          "native.boundary.native_call_report",
        when Native_Boundary_Completion_Report =>
          "native.boundary.completion_report",
        when Native_Boundary_Release_Report =>
          "native.boundary.release_report",
        when Native_Fixture_Root_Query =>
          "native.fixture_root.query",
        when Native_Fixture_Root_Failure_Stage =>
          "native.fixture_root.failure_stage",
        when Native_Fixture_Root_Child_Traversal =>
          "native.fixture_root.child_traversal",
        when Native_Fixture_Root_Child_Count =>
          "native.fixture_root.child_count",
        when Native_Fixture_Root_Second_Child =>
          "native.fixture_root.second_child",
        when Native_Fixture_Child_Query =>
          "native.fixture_child.query",
        when Native_Fixture_Child_Native_Object =>
          "native.fixture_child.native_object",
        when Native_Fixture_Child_Parent_Navigation =>
          "native.fixture_child.parent_navigation",
        when Native_Fixture_Child_Native_Identity =>
          "native.fixture_child.native_identity",
        when Native_Fixture_Second_Child_Parent_Navigation =>
          "native.fixture_second_child.parent_navigation",
        when Native_Fixture_Second_Child_Native_Identity =>
          "native.fixture_second_child.native_identity",
        when Native_Fixture_Sibling_Order =>
          "native.fixture.sibling_order",
        when Native_Fixture_Child_Stale_Id =>
          "native.fixture_child.stale_id",
        when Linux_ATSPI_Role_Map => "linux.atspi.role_map",
        when Linux_ATSPI_State_Map => "linux.atspi.state_map",
        when Linux_ATSPI_Object_Path => "linux.atspi.object_path",
        when Linux_ATSPI_Error_Name_Map =>
          "linux.atspi.error_name_map",
        when Linux_ATSPI_Error_Name_Inverse_Map =>
          "linux.atspi.error_name_inverse_map",
        when Linux_ATSPI_Error_Name_Diagnostic =>
          "linux.atspi.error_name_diagnostic",
        when Linux_DBUS_Bus_Address => "linux.dbus.bus_address",
        when Linux_DBUS_Connection_Lifecycle =>
          "linux.dbus.connection_lifecycle",
        when Linux_DBUS_Local_Channel_Adapter =>
          "linux.dbus.local_channel_adapter",
        when Linux_DBUS_Local_Channel_Receive =>
          "linux.dbus.local_channel_receive",
        when Linux_DBUS_Auth_External =>
          "linux.dbus.auth_external",
        when Linux_DBUS_Auth_Exchange =>
          "linux.dbus.auth_exchange",
        when Linux_DBUS_Authenticated_Connect =>
          "linux.dbus.authenticated_connect",
        when Linux_DBUS_Hello =>
          "linux.dbus.hello",
        when Linux_DBUS_Authenticated_Hello =>
          "linux.dbus.authenticated_hello",
        when Linux_DBUS_Registration_Completion =>
          "linux.dbus.registration_completion",
        when Linux_DBUS_Authenticated_Registration =>
          "linux.dbus.authenticated_registration",
        when Linux_DBUS_Address_Discovery =>
          "linux.dbus.address_discovery",
        when Linux_DBUS_Host_Environment_Startup =>
          "linux.dbus.host_environment_startup",
        when Linux_DBUS_A11y_Bus_Get_Address =>
          "linux.dbus.a11y_bus_get_address",
        when Linux_DBUS_Authenticated_Get_Address =>
          "linux.dbus.authenticated_get_address",
        when Linux_DBUS_Startup_Session_Discovery =>
          "linux.dbus.startup_session_discovery",
        when Linux_DBUS_Startup_Controller =>
          "linux.dbus.startup_controller",
        when Linux_DBUS_Startup_Backend_Adapter =>
          "linux.dbus.startup_backend_adapter",
        when Linux_DBUS_Startup_Outgoing_Work =>
          "linux.dbus.startup_outgoing_work",
        when Linux_DBUS_Startup_Event_Loop_Interest =>
          "linux.dbus.startup_event_loop_interest",
        when Linux_DBUS_Startup_Event_Loop_Operation =>
          "linux.dbus.startup_event_loop_operation",
        when Linux_DBUS_Startup_Outgoing_Flush =>
          "linux.dbus.startup_outgoing_flush",
        when Linux_DBUS_Backend_Session_Event_Loop_Step =>
          "linux.dbus.backend_session_event_loop_step",
        when Linux_DBUS_Backend_Session_Scheduler =>
          "linux.dbus.backend_session_scheduler",
        when Linux_DBUS_Backend_Session_Transport_Cycle_Scheduler =>
          "linux.dbus.backend_session_transport_cycle_scheduler",
        when Linux_DBUS_Outgoing_Back_Pressure =>
          "linux.dbus.outgoing_back_pressure",
        when Linux_DBUS_Startup_Pump_Readiness =>
          "linux.dbus.startup_pump_readiness",
        when Linux_DBUS_Startup_Pump =>
          "linux.dbus.startup_pump",
        when Linux_DBUS_Startup_Pump_Report =>
          "linux.dbus.startup_pump_report",
        when Linux_DBUS_Startup_Pump_Bounded_Report =>
          "linux.dbus.startup_pump_bounded_report",
        when Linux_DBUS_Startup_Pump_Bounds =>
          "linux.dbus.startup_pump_bounds",
        when Linux_DBUS_Startup_Registered_Pump =>
          "linux.dbus.startup_registered_pump",
        when Linux_DBUS_Transport_Serve_Cycle =>
          "linux.dbus.transport_serve_cycle",
        when Linux_DBUS_Codec_Basic => "linux.dbus.codec.basic",
        when Linux_DBUS_Unsupported_Value =>
          "linux.dbus.unsupported_value",
        when Linux_DBUS_UInt32_Array_Value =>
          "linux.dbus.uint32_array_value",
        when Linux_DBUS_State_Set_UInt32_Array =>
          "linux.dbus.state_set_uint32_array",
        when Linux_DBUS_String_Array_Value =>
          "linux.dbus.string_array_value",
        when Linux_DBUS_Attribute_String_Array =>
          "linux.dbus.attribute_string_array",
        when Linux_DBUS_Cache_Interface_String_Array =>
          "linux.dbus.cache_interface_string_array",
        when Linux_DBUS_Object_Path_Array_Value =>
          "linux.dbus.object_path_array_value",
        when Linux_DBUS_Relation_Target_Object_Path_Array =>
          "linux.dbus.relation_target_object_path_array",
        when Linux_DBUS_Resource_Limits =>
          "linux.dbus.resource_limits",
        when Linux_DBUS_Message_Envelope =>
          "linux.dbus.message_envelope",
        when Linux_DBUS_Method_Call_Envelope =>
          "linux.dbus.method_call_envelope",
        when Linux_DBUS_Method_Return_Payload =>
          "linux.dbus.method_return_payload",
        when Linux_DBUS_Startup_Reply_Evidence =>
          "linux.dbus.startup_reply_evidence",
        when Linux_DBUS_Transport_Frame_Metadata =>
          "linux.dbus.transport_frame_metadata",
        when Linux_DBUS_Method_Call_Destination_Routing =>
          "linux.dbus.method_call_destination_routing",
        when Linux_DBUS_Transport_Frame_Bytes =>
          "linux.dbus.transport_frame_bytes",
        when Linux_DBUS_Transport_Frame_Send =>
          "linux.dbus.transport_frame_send",
        when Linux_DBUS_Transport_Packet =>
          "linux.dbus.transport_packet",
        when Linux_DBUS_Transport_Packet_Send =>
          "linux.dbus.transport_packet_send",
        when Linux_DBUS_Transport_Packet_Decode =>
          "linux.dbus.transport_packet_decode",
        when Linux_DBUS_Transport_Envelope_Decode =>
          "linux.dbus.transport_envelope_decode",
        when Linux_DBUS_Method_Return_Decode =>
          "linux.dbus.method_return_decode",
        when Linux_DBUS_Error_Return_Decode =>
          "linux.dbus.error_return_decode",
        when Linux_DBUS_Error_Return_Diagnostic =>
          "linux.dbus.error_return_diagnostic",
        when Linux_DBUS_Startup_Error_Completion =>
          "linux.dbus.startup_error_completion",
        when Linux_DBUS_Incoming_Call_Decode =>
          "linux.dbus.incoming_call_decode",
        when Linux_DBUS_Incoming_Packet_Classification =>
          "linux.dbus.incoming_packet_classification",
        when Linux_DBUS_Incoming_Packet_No_Dispatch =>
          "linux.dbus.incoming_packet_no_dispatch",
        when Linux_DBUS_Incoming_Packet_Dispatch =>
          "linux.dbus.incoming_packet_dispatch",
        when Linux_DBUS_Signal_Envelope =>
          "linux.dbus.signal_envelope",
        when Linux_DBUS_Prepared_Signal_Envelope =>
          "linux.dbus.prepared_signal_envelope",
        when Linux_DBUS_Signal_Envelope_Build_Report =>
          "linux.dbus.signal_envelope.build_report",
        when Linux_DBUS_Method_Boundary =>
          "linux.dbus.method_boundary",
        when Linux_DBUS_Application_Registration =>
          "linux.dbus.application_registration",
        when Linux_ATSPI_Live_Transport_Registration_Observed =>
          "linux.atspi.live_transport.registration_observed",
        when Linux_ATSPI_Serving_Packet_Stale_Error_Queued =>
          "linux.atspi.serving_packet.stale_error.queued",
        when Linux_ATSPI_Serving_Packet_Stale_Error_Serialized =>
          "linux.atspi.serving_packet.stale_error.serialized",
        when Linux_ATSPI_Serving_Packet_Stale_Error_Decoded =>
          "linux.atspi.serving_packet.stale_error.decoded",
        when Linux_ATSPI_Serving_Packet_Stale_Error_Drained =>
          "linux.atspi.serving_packet.stale_error.drained",
        when Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued =>
          "linux.atspi.serving_packet.unsupported_interface.queued",
        when Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized =>
          "linux.atspi.serving_packet.unsupported_interface.serialized",
        when Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded =>
          "linux.atspi.serving_packet.unsupported_interface.decoded",
        when Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained =>
          "linux.atspi.serving_packet.unsupported_interface.drained",
        when Linux_ATSPI_Serving_Packet_Probe =>
          "linux.atspi.serving_packet_probe",
        when Linux_ATSPI_Serving_Packet_Tree_Traversal =>
          "linux.atspi.serving_packet.tree_traversal",
        when Linux_ATSPI_Serving_Packet_Property =>
          "linux.atspi.serving_packet.property",
        when Linux_ATSPI_Serving_Packet_Property_Map =>
          "linux.atspi.serving_packet.property_map",
        when Linux_ATSPI_Serving_Packet_Stale_Error =>
          "linux.atspi.serving_packet.stale_error",
        when Linux_ATSPI_Serving_Packet_Unsupported_Interface =>
          "linux.atspi.serving_packet.unsupported_interface",
        when Linux_ATSPI_Serving_Packet_Malformed_Packet =>
          "linux.atspi.serving_packet.malformed_packet",
        when Linux_ATSPI_Serving_Packet_Text_Payload_Limit =>
          "linux.atspi.serving_packet.text_payload_limit",
        when Linux_ATSPI_Session_Dispatch_Probe =>
          "linux.atspi.session_dispatch_probe",
        when Linux_ATSPI_Session_Dispatch_Boundary_Drained =>
          "linux.atspi.session_dispatch.boundary_drained",
        when Linux_ATSPI_Session_Dispatch_Loop_Report =>
          "linux.atspi.session_dispatch.loop_report",
        when Linux_ATSPI_Session_Bus_Probe =>
          "linux.atspi.session_bus_probe",
        when Linux_ATSPI_Session_Startup_Stage =>
          "linux.atspi.session_startup_stage",
        when Linux_ATSPI_Startup_Object_Path =>
          "linux.atspi.startup_object_path",
        when Linux_ATSPI_Method_Router =>
          "linux.atspi.method_router",
        when Linux_ATSPI_Application_Id =>
          "linux.atspi.application.id",
        when Linux_ATSPI_Application_Metadata =>
          "linux.atspi.application.metadata",
        when Linux_ATSPI_Accessible_Role =>
          "linux.atspi.accessible.role",
        when Linux_ATSPI_Accessible_Application =>
          "linux.atspi.accessible.application",
        when Linux_ATSPI_Accessible_Interfaces =>
          "linux.atspi.accessible.interfaces",
        when Linux_ATSPI_Accessible_Role_Name =>
          "linux.atspi.accessible.role_name",
        when Linux_ATSPI_Accessible_Localized_Role_Name =>
          "linux.atspi.accessible.localized_role_name",
        when Linux_ATSPI_Accessible_State =>
          "linux.atspi.accessible.state",
        when Linux_ATSPI_Accessible_Name =>
          "linux.atspi.accessible.name",
        when Linux_ATSPI_Accessible_Description =>
          "linux.atspi.accessible.description",
        when Linux_ATSPI_Accessible_Child_Count =>
          "linux.atspi.accessible.child_count",
        when Linux_ATSPI_Accessible_Child_At =>
          "linux.atspi.accessible.child_at",
        when Linux_ATSPI_Accessible_Children =>
          "linux.atspi.accessible.children",
        when Linux_ATSPI_Accessible_Parent =>
          "linux.atspi.accessible.parent",
        when Linux_ATSPI_Accessible_Index_In_Parent =>
          "linux.atspi.accessible.index_in_parent",
        when Linux_ATSPI_Accessible_Relations =>
          "linux.atspi.accessible.relations",
        when Linux_ATSPI_Component_Extents =>
          "linux.atspi.component.extents",
        when Linux_ATSPI_Component_Contains =>
          "linux.atspi.component.contains",
        when Linux_ATSPI_Component_Hit_Test =>
          "linux.atspi.component.hit_test",
        when Linux_ATSPI_Component_Focus =>
          "linux.atspi.component.focus",
        when Linux_ATSPI_Action_Count =>
          "linux.atspi.action.count",
        when Linux_ATSPI_Action_Name =>
          "linux.atspi.action.name",
        when Linux_ATSPI_Action_Invoke =>
          "linux.atspi.action.invoke",
        when Linux_ATSPI_Value_Current =>
          "linux.atspi.value.current",
        when Linux_ATSPI_Value_Range =>
          "linux.atspi.value.range",
        when Linux_ATSPI_Value_Set_Request =>
          "linux.atspi.value.set_request",
        when Linux_ATSPI_Selection_Count =>
          "linux.atspi.selection.count",
        when Linux_ATSPI_Selection_Selected_Child =>
          "linux.atspi.selection.selected_child",
        when Linux_ATSPI_Selection_Request =>
          "linux.atspi.selection.request",
        when Linux_ATSPI_Selection_Deselect_Child =>
          "linux.atspi.selection.deselect_child",
        when Linux_ATSPI_Selection_Select_All =>
          "linux.atspi.selection.select_all",
        when Linux_ATSPI_Selection_Clear_Selection =>
          "linux.atspi.selection.clear_selection",
        when Linux_ATSPI_Text_Character_Count =>
          "linux.atspi.text.character_count",
        when Linux_ATSPI_Text_Range =>
          "linux.atspi.text.range",
        when Linux_ATSPI_Text_Caret =>
          "linux.atspi.text.caret",
        when Linux_ATSPI_Text_Protected =>
          "linux.atspi.text.protected",
        when Linux_ATSPI_Text_Edit_Request =>
          "linux.atspi.text.edit_request",
        when Linux_ATSPI_Table_Dimensions =>
          "linux.atspi.table.dimensions",
        when Linux_ATSPI_Table_Cell =>
          "linux.atspi.table.cell",
        when Linux_ATSPI_Table_Cell_Span =>
          "linux.atspi.table.cell_span",
        when Linux_ATSPI_Table_Current_Cell =>
          "linux.atspi.table.current_cell",
        when Linux_ATSPI_Table_Sort_Metadata =>
          "linux.atspi.table.sort_metadata",
        when Linux_ATSPI_Image_Description =>
          "linux.atspi.image.description",
        when Linux_ATSPI_Image_Size =>
          "linux.atspi.image.size",
        when Linux_ATSPI_Image_Decorative_Omission =>
          "linux.atspi.image.decorative_omission",
        when Linux_ATSPI_Document_Locale =>
          "linux.atspi.document.locale",
        when Linux_ATSPI_Document_Attributes =>
          "linux.atspi.document.attributes",
        when Linux_ATSPI_Document_Heading_Level =>
          "linux.atspi.document.heading_level",
        when Linux_ATSPI_Document_Landmark =>
          "linux.atspi.document.landmark",
        when Linux_ATSPI_Surface_Metadata =>
          "linux.atspi.surface.metadata",
        when Linux_ATSPI_Surface_Routing =>
          "linux.atspi.surface_routing",
        when Linux_ATSPI_Signal_Focus =>
          "linux.atspi.signal.focus",
        when Linux_ATSPI_Signal_Text =>
          "linux.atspi.signal.text",
        when Linux_ATSPI_Signal_Lifecycle =>
          "linux.atspi.signal.lifecycle",
        when Linux_ATSPI_Signal_Prepared_Publication =>
          "linux.atspi.signal.prepared_publication",
        when Linux_ATSPI_Signal_Build_Report =>
          "linux.atspi.signal.build_report",
        when Linux_ATSPI_Cache_Node =>
          "linux.atspi.cache.node",
        when Linux_ATSPI_Object_Registry =>
          "linux.atspi.object_registry",
        when Linux_ATSPI_Object_Export_Descriptor =>
          "linux.atspi.object_export_descriptor",
        when Linux_ATSPI_Live_External_Client =>
          "linux.atspi.live_external_client",
        when Linux_ATSPI_Live_External_Client_Registered_Transport =>
          "linux.atspi.live_external_client.registered_transport",
        when Linux_ATSPI_Live_External_Client_Traversal =>
          "linux.atspi.live_external_client.traversal",
        when Linux_ATSPI_Live_External_Client_Failure_Stage =>
          "linux.atspi.live_external_client.failure_stage",
        when Linux_ATSPI_Live_External_Client_Attributes =>
          "linux.atspi.live_external_client.attributes",
        when Linux_ATSPI_Live_External_Client_Protected_Value =>
          "linux.atspi.live_external_client.protected_value",
        when Linux_ATSPI_Live_External_Client_Component =>
          "linux.atspi.live_external_client.component",
        when Linux_ATSPI_Live_External_Client_Action =>
          "linux.atspi.live_external_client.action",
        when Linux_ATSPI_Live_External_Client_Value =>
          "linux.atspi.live_external_client.value",
        when Linux_ATSPI_Live_External_Client_Selection =>
          "linux.atspi.live_external_client.selection",
        when Linux_ATSPI_Live_External_Client_Text =>
          "linux.atspi.live_external_client.text",
        when Linux_ATSPI_Live_External_Client_Image =>
          "linux.atspi.live_external_client.image",
        when Linux_ATSPI_Live_External_Client_Document =>
          "linux.atspi.live_external_client.document",
        when Linux_ATSPI_Live_External_Client_Table =>
          "linux.atspi.live_external_client.table",
        when Linux_ATSPI_Live_External_Client_Surface =>
          "linux.atspi.live_external_client.surface",
        when Linux_ATSPI_Live_External_Client_Live_Region =>
          "linux.atspi.live_external_client.live_region",
        when Windows_UIA_Control_Type =>
          "windows.uia.control_type",
        when Windows_UIA_Core_Properties =>
          "windows.uia.core_properties",
        when Windows_UIA_Bounding_Rectangle =>
          "windows.uia.bounding_rectangle",
        when Windows_UIA_Textual_Properties =>
          "windows.uia.textual_properties",
        when Windows_UIA_Metadata_Properties =>
          "windows.uia.metadata_properties",
        when Windows_UIA_Protected_Value_Text =>
          "windows.uia.protected_value_text",
        when Windows_UIA_Unsupported_Value =>
          "windows.uia.unsupported_value",
        when Windows_UIA_Action_Map =>
          "windows.uia.action_map",
        when Windows_UIA_Pattern_Discovery =>
          "windows.uia.pattern.discovery",
        when Windows_UIA_Action_Request =>
          "windows.uia.action.request",
        when Windows_UIA_Set_Focus_Request =>
          "windows.uia.action.set_focus",
        when Windows_UIA_Open_Action =>
          "windows.uia.action.open",
        when Windows_UIA_Scroll_Into_View_Action =>
          "windows.uia.action.scroll_into_view",
        when Windows_UIA_Close_Action =>
          "windows.uia.action.close",
        when Windows_UIA_Event_Map =>
          "windows.uia.event_map",
        when Windows_UIA_Event_Details =>
          "windows.uia.event_details",
        when Windows_UIA_Prepared_Event_Emission =>
          "windows.uia.prepared_event_emission",
        when Windows_UIA_Event_Build_Report =>
          "windows.uia.event.build_report",
        when Windows_UIA_Prepared_Event_Routing =>
          "windows.uia.prepared_event_routing",
        when Windows_UIA_Prepared_Event_Boundary =>
          "windows.uia.prepared_event_boundary",
        when Windows_UIA_Event_Posting_Admission =>
          "windows.uia.event_posting_admission",
        when Windows_UIA_Event_Posting_Report =>
          "windows.uia.event_posting_report",
        when Windows_UIA_Event_Posting_Drain_Bounded =>
          "windows.uia.event_posting_drain_bounded",
        when Windows_UIA_Hostile_Callback_Admission =>
          "windows.uia.native_callback.hostile_admission",
        when Windows_UIA_Missing_Identity =>
          "windows.uia.native_callback.missing_identity",
        when Windows_UIA_Mismatched_Identity =>
          "windows.uia.native_callback.mismatched_identity",
        when Windows_UIA_Malformed_Identity =>
          "windows.uia.native_callback.malformed_identity",
        when Windows_UIA_Text_Payload_Limit =>
          "windows.uia.native_callback.text_payload_limit",
        when Windows_UIA_Fragment_Navigation =>
          "windows.uia.fragment.navigation",
        when Windows_UIA_Runtime_Id =>
          "windows.uia.runtime_id",
        when Windows_UIA_Relation_Routing =>
          "windows.uia.relation_routing",
        when Windows_UIA_Value_Routing =>
          "windows.uia.value_routing",
        when Windows_UIA_Value_Set_Request =>
          "windows.uia.value.set_request",
        when Windows_UIA_Selection_Routing =>
          "windows.uia.selection_routing",
        when Windows_UIA_Selection_Request =>
          "windows.uia.selection.request",
        when Windows_UIA_Selection_Select_All =>
          "windows.uia.selection.select_all",
        when Windows_UIA_Selection_Clear_Selection =>
          "windows.uia.selection.clear_selection",
        when Windows_UIA_Text_Routing =>
          "windows.uia.text_routing",
        when Windows_UIA_Text_Edit_Routing =>
          "windows.uia.text_edit_routing",
        when Windows_UIA_Table_Routing =>
          "windows.uia.table_routing",
        when Windows_UIA_Image_Routing =>
          "windows.uia.image_routing",
        when Windows_UIA_Document_Routing =>
          "windows.uia.document_routing",
        when Windows_UIA_Surface_Routing =>
          "windows.uia.surface_routing",
        when Windows_UIA_Request_Router =>
          "windows.uia.request_router",
        when Windows_UIA_ABI_Surface =>
          "windows.uia.abi_surface",
        when Windows_UIA_Provider_Boundary =>
          "windows.uia.provider_boundary",
        when Windows_UIA_Bridge_Audit =>
          "windows.uia.bridge_audit",
        when Windows_UIA_Native_Bridge_Binding =>
          "windows.uia.native_bridge_binding",
        when Windows_UIA_HResult_Map =>
          "windows.uia.hresult_map",
        when Windows_UIA_HResult_Inverse_Map =>
          "windows.uia.hresult_inverse_map",
        when Windows_UIA_HResult_Diagnostic =>
          "windows.uia.hresult_diagnostic",
        when Windows_UIA_Provider_Registry =>
          "windows.uia.provider_registry",
        when Windows_UIA_COM_Lifetime =>
          "windows.uia.com_lifetime",
        when Windows_UIA_COM_Export_Descriptor =>
          "windows.uia.com_export_descriptor",
        when Windows_UIA_COM_Live_Export =>
          "windows.uia.com_live_export",
        when Windows_UIA_Public_Root_Export =>
          "windows.uia.public_root_export",
        when Windows_UIA_Public_Root_Native_Identity =>
          "windows.uia.public_root.native_identity",
        when Windows_UIA_Host_Window_Root_Binding =>
          "windows.uia.host_window_root_binding",
        when Windows_UIA_COM_VTable_Descriptor =>
          "windows.uia.com_vtable_descriptor",
        when Windows_UIA_COM_Object_Export =>
          "windows.uia.com_object_export",
        when Windows_UIA_COM_Live_Interface_Retain =>
          "windows.uia.com_live.interface_retain",
        when Windows_UIA_COM_Live_Interface_Release =>
          "windows.uia.com_live.interface_release",
        when Windows_UIA_COM_Live_Released_Interface =>
          "windows.uia.com_live.released_interface",
        when Windows_UIA_COM_Live_Invalid_Interface_Frame =>
          "windows.uia.com_live.invalid_interface_frame",
        when Windows_UIA_COM_Live_Invalid_Method_Frame =>
          "windows.uia.com_live.invalid_method_frame",
        when Windows_UIA_COM_Live_Interface_Method_Mismatch =>
          "windows.uia.com_live.interface_method_mismatch",
        when Windows_UIA_COM_Live_Provider_Options =>
          "windows.uia.com_live.provider_options",
        when Windows_UIA_COM_Live_Host_Raw_Element_Provider =>
          "windows.uia.com_live.host_raw_element_provider",
        when Windows_UIA_COM_Live_Pattern_Provider_Frame =>
          "windows.uia.com_live.pattern_provider_frame",
        when Windows_UIA_COM_Live_Simple_Property_Frame =>
          "windows.uia.com_live.simple_property_frame",
        when Windows_UIA_COM_Live_Bounding_Rectangle_Frame =>
          "windows.uia.com_live.bounding_rectangle_frame",
        when Windows_UIA_COM_Live_Fragment_Action_Frame =>
          "windows.uia.com_live.fragment_action_frame",
        when Windows_UIA_COM_Live_Fragment_Navigate =>
          "windows.uia.com_live.fragment_navigate",
        when Windows_UIA_COM_Live_Fragment_Last_Child_Frame =>
          "windows.uia.com_live.fragment_last_child_frame",
        when Windows_UIA_COM_Live_Fragment_Runtime_Id =>
          "windows.uia.com_live.fragment_runtime_id",
        when Windows_UIA_COM_Live_Embedded_Fragment_Roots =>
          "windows.uia.com_live.embedded_fragment_roots",
        when Windows_UIA_COM_Live_Fragment_Root =>
          "windows.uia.com_live.fragment_root",
        when Windows_UIA_COM_Live_Fragment_Root_Point =>
          "windows.uia.com_live.fragment_root_point",
        when Windows_UIA_COM_Live_Fragment_Root_Focus =>
          "windows.uia.com_live.fragment_root_focus",
        when Windows_UIA_External_Client_Blocked_Probe =>
          "windows.uia.external_client.blocked_probe",
        when Windows_UIA_External_Client_Failure_Stage =>
          "windows.uia.external_client.failure_stage",
        when Windows_UIA_Native_Values =>
          "windows.uia.native_values",
        when MacOS_NSAX_Role =>
          "macos.nsaccessibility.role",
        when MacOS_NSAX_Core_Attributes =>
          "macos.nsaccessibility.core_attributes",
        when MacOS_NSAX_Frame_Attribute =>
          "macos.nsaccessibility.frame_attribute",
        when MacOS_NSAX_Textual_Attributes =>
          "macos.nsaccessibility.textual_attributes",
        when MacOS_NSAX_Metadata_Attributes =>
          "macos.nsaccessibility.metadata_attributes",
        when MacOS_NSAX_Protected_Value_Text =>
          "macos.nsaccessibility.protected_value_text",
        when MacOS_NSAX_Unsupported_Value =>
          "macos.nsaccessibility.unsupported_value",
        when MacOS_NSAX_Action_Map =>
          "macos.nsaccessibility.action_map",
        when MacOS_NSAX_Action_Discovery =>
          "macos.nsaccessibility.action.discovery",
        when MacOS_NSAX_Action_Request =>
          "macos.nsaccessibility.action.request",
        when MacOS_NSAX_Open_Action =>
          "macos.nsaccessibility.action.open",
        when MacOS_NSAX_Close_Action =>
          "macos.nsaccessibility.action.close",
        when MacOS_NSAX_Set_Focus_Action =>
          "macos.nsaccessibility.action.set_focus",
        when MacOS_NSAX_Scroll_To_Visible_Action =>
          "macos.nsaccessibility.action.scroll_to_visible",
        when MacOS_NSAX_Event_Map =>
          "macos.nsaccessibility.event_map",
        when MacOS_NSAX_Event_Details =>
          "macos.nsaccessibility.event_details",
        when MacOS_NSAX_Prepared_Event_Emission =>
          "macos.nsaccessibility.prepared_event_emission",
        when MacOS_NSAX_Event_Build_Report =>
          "macos.nsaccessibility.event.build_report",
        when MacOS_NSAX_Prepared_Event_Routing =>
          "macos.nsaccessibility.prepared_event_routing",
        when MacOS_NSAX_Prepared_Event_Boundary =>
          "macos.nsaccessibility.prepared_event_boundary",
        when MacOS_NSAX_Event_Posting_Admission =>
          "macos.nsaccessibility.event_posting_admission",
        when MacOS_NSAX_Event_Posting_Report =>
          "macos.nsaccessibility.event_posting_report",
        when MacOS_NSAX_Event_Posting_Drain_Bounded =>
          "macos.nsaccessibility.event_posting_drain_bounded",
        when MacOS_NSAX_Hostile_Callback_Admission =>
          "macos.nsaccessibility.native_callback.hostile_admission",
        when MacOS_NSAX_Missing_Identity =>
          "macos.nsaccessibility.native_callback.missing_identity",
        when MacOS_NSAX_Mismatched_Identity =>
          "macos.nsaccessibility.native_callback.mismatched_identity",
        when MacOS_NSAX_Malformed_Identity =>
          "macos.nsaccessibility.native_callback.malformed_identity",
        when MacOS_NSAX_Text_Payload_Limit =>
          "macos.nsaccessibility.native_callback.text_payload_limit",
        when MacOS_NSAX_Hierarchy =>
          "macos.nsaccessibility.hierarchy",
        when MacOS_NSAX_Element_Id =>
          "macos.nsaccessibility.element_id",
        when MacOS_NSAX_Relation_Routing =>
          "macos.nsaccessibility.relation_routing",
        when MacOS_NSAX_Value_Routing =>
          "macos.nsaccessibility.value_routing",
        when MacOS_NSAX_Value_Set_Request =>
          "macos.nsaccessibility.value.set_request",
        when MacOS_NSAX_Selection_Routing =>
          "macos.nsaccessibility.selection_routing",
        when MacOS_NSAX_Selection_Request =>
          "macos.nsaccessibility.selection.request",
        when MacOS_NSAX_Selection_Select_All =>
          "macos.nsaccessibility.selection.select_all",
        when MacOS_NSAX_Selection_Clear_Selection =>
          "macos.nsaccessibility.selection.clear_selection",
        when MacOS_NSAX_Text_Routing =>
          "macos.nsaccessibility.text_routing",
        when MacOS_NSAX_Text_Edit_Routing =>
          "macos.nsaccessibility.text_edit_routing",
        when MacOS_NSAX_Table_Routing =>
          "macos.nsaccessibility.table_routing",
        when MacOS_NSAX_Image_Routing =>
          "macos.nsaccessibility.image_routing",
        when MacOS_NSAX_Document_Routing =>
          "macos.nsaccessibility.document_routing",
        when MacOS_NSAX_Surface_Routing =>
          "macos.nsaccessibility.surface_routing",
        when MacOS_NSAX_Request_Router =>
          "macos.nsaccessibility.request_router",
        when MacOS_NSAX_ABI_Surface =>
          "macos.nsaccessibility.abi_surface",
        when MacOS_NSAX_Provider_Boundary =>
          "macos.nsaccessibility.provider_boundary",
        when MacOS_NSAX_Bridge_Audit =>
          "macos.nsaccessibility.bridge_audit",
        when MacOS_NSAX_Native_Bridge_Binding =>
          "macos.nsaccessibility.native_bridge_binding",
        when MacOS_NSAX_Virtual_Element_Bridge =>
          "macos.nsaccessibility.virtual_element_bridge",
        when MacOS_NSAX_Native_Status_Map =>
          "macos.nsaccessibility.native_status_map",
        when MacOS_NSAX_Native_Status_Inverse_Map =>
          "macos.nsaccessibility.native_status_inverse_map",
        when MacOS_NSAX_Native_Status_Diagnostic =>
          "macos.nsaccessibility.native_status_diagnostic",
        when MacOS_NSAX_Element_Registry =>
          "macos.nsaccessibility.element_registry",
        when MacOS_NSAX_Element_Lifetime =>
          "macos.nsaccessibility.element_lifetime",
        when MacOS_NSAX_Element_Export_Descriptor =>
          "macos.nsaccessibility.element_export_descriptor",
        when MacOS_NSAX_Public_Root_Export =>
          "macos.nsaccessibility.public_root_export",
        when MacOS_NSAX_Public_Root_Native_Identity =>
          "macos.nsaccessibility.public_root.native_identity",
        when MacOS_NSAX_Public_Root_Hit_Test_Frame =>
          "macos.nsaccessibility.public_root.hit_test_frame",
        when MacOS_NSAX_Public_Root_Focused_Element_Frame =>
          "macos.nsaccessibility.public_root.focused_element_frame",
        when MacOS_NSAX_Public_Root_Notification_Frame =>
          "macos.nsaccessibility.public_root.notification_frame",
        when MacOS_NSAX_Main_Thread_Binding =>
          "macos.nsaccessibility.main_thread_binding",
        when MacOS_NSAX_Native_View_Binding =>
          "macos.nsaccessibility.native_view_binding",
        when MacOS_NSAX_Attribute_Names =>
          "macos.nsaccessibility.attribute_names",
        when MacOS_NSAX_Selector_Attribute_Value =>
          "macos.nsaccessibility.selector.attribute_value",
        when MacOS_NSAX_Selector_Children_Frame =>
          "macos.nsaccessibility.selector.children_frame",
        when MacOS_NSAX_Selector_Child_At_Index_Frame =>
          "macos.nsaccessibility.selector.child_at_index_frame",
        when MacOS_NSAX_Selector_Attribute_Value_Frame =>
          "macos.nsaccessibility.selector.attribute_value_frame",
        when MacOS_NSAX_Selector_Attribute_Settable_Frame =>
          "macos.nsaccessibility.selector.attribute_settable_frame",
        when MacOS_NSAX_Selector_Action_Frame =>
          "macos.nsaccessibility.selector.action_frame",
        when MacOS_NSAX_Selector_Unsupported =>
          "macos.nsaccessibility.selector.unsupported",
        when MacOS_NSAX_Selector_Main_Thread_Gate =>
          "macos.nsaccessibility.selector.main_thread_gate",
        when MacOS_NSAX_Registered_Method_Family_Mismatch =>
          "macos.nsaccessibility.registered_method_family_mismatch",
        when MacOS_NSAX_Released_Boundary =>
          "macos.nsaccessibility.released_boundary",
        when MacOS_NSAX_External_Client_Blocked_Probe =>
          "macos.nsaccessibility.external_client.blocked_probe",
        when MacOS_NSAX_External_Client_Failure_Stage =>
          "macos.nsaccessibility.external_client.failure_stage",
        when MacOS_NSAX_Native_Values =>
          "macos.nsaccessibility.native_values",
        when Diagnostics_Metadata =>
          "diagnostics.metadata",
        when Diagnostics_Result_Mapping =>
          "diagnostics.result_mapping",
        when Diagnostics_Field_Bounds =>
          "diagnostics.field_bounds",
        when Diagnostics_Localization =>
          "diagnostics.localization",
        when Backend_Diagnostics_Bounded =>
          "backend.diagnostics.bounded",
        when Backend_Null_Event_Limit =>
          "backend.null.event_limit",
        when Results_Metadata =>
          "results.metadata",
        when Resource_Limits_Defaults =>
          "resource_limits.defaults",
        when Resource_Limits_Metadata =>
          "resource_limits.metadata",
        when Resource_Limits_Validation =>
          "resource_limits.validation",
        when Backend_Selection_Default =>
          "backend.selection.default",
        when Backend_Selection_Runtime_Override =>
          "backend.selection.runtime_override",
        when Backend_Selection_Fallback =>
          "backend.selection.fallback",
        when Backend_Selection_Disabled =>
          "backend.selection.disabled",
        when Backend_State_Metadata =>
          "backend.state.metadata",
        when Backend_Kind_Metadata =>
          "backend.kind.metadata",
        when Backend_Disabled_Lifecycle =>
          "backend.disabled.lifecycle",
        when Backend_Native_Scaffold =>
          "backend.native.scaffold",
        when Backend_Native_Target_Resolution =>
          "backend.native.target_resolution",
        when Backend_Native_Transport_Admission =>
          "backend.native.transport_admission",
        when Backend_Native_Transport_Status =>
          "backend.native.transport_status",
        when Backend_Transport_Unavailable =>
          "backend.transport.unavailable",
        when Backend_Native_Transport_Generation =>
          "backend.native.transport_generation",
        when Backend_Native_Transport_Transition_Report =>
          "backend.native.transport_transition_report",
        when Backend_Native_Deterministic_Shutdown =>
          "backend.native.deterministic_shutdown",
        when Backend_Native_Publication_Preparation =>
          "backend.native.publication_preparation",
        when Events_Metadata => "events.metadata",
        when Events_Envelope => "events.envelope",
        when Events_Timestamp_Order => "events.timestamp_order",
        when Events_Classification => "events.classification",
        when Events_Node_Created => "events.node.created",
        when Events_Focus_Changed => "events.focus.changed",
        when Events_Node_Destroyed => "events.node.destroyed",
        when Events_Node_Attached => "events.node.attached",
        when Events_Node_Detached => "events.node.detached",
        when Events_Child_Added => "events.child.added",
        when Events_Child_Removed => "events.child.removed",
        when Events_Children_Reordered => "events.children.reordered",
        when Events_Subtree_Rebuilt => "events.subtree.rebuilt",
        when Events_Property_Changed => "events.property.changed",
        when Events_State_Changed => "events.state.changed",
        when Events_Bounds_Changed => "events.bounds.changed",
        when Events_Active_Descendant_Changed =>
          "events.active_descendant.changed",
        when Events_Selection_Changed => "events.selection.changed",
        when Events_Current_Item_Changed => "events.current_item.changed",
        when Events_Value_Changed => "events.value.changed",
        when Events_Range_Changed => "events.range.changed",
        when Events_Text_Inserted => "events.text.inserted",
        when Events_Text_Removed => "events.text.removed",
        when Events_Text_Replaced => "events.text.replaced",
        when Events_Caret_Moved => "events.caret.moved",
        when Events_Text_Selection_Changed =>
          "events.text_selection.changed",
        when Events_Text_Attributes_Changed =>
          "events.text_attributes.changed",
        when Events_Row_Inserted => "events.row.inserted",
        when Events_Row_Removed => "events.row.removed",
        when Events_Column_Inserted => "events.column.inserted",
        when Events_Column_Removed => "events.column.removed",
        when Events_Cell_Changed => "events.cell.changed",
        when Events_Window_Opened => "events.window.opened",
        when Events_Window_Closed => "events.window.closed",
        when Events_Window_Activated => "events.window.activated",
        when Events_Window_Deactivated => "events.window.deactivated",
        when Events_Document_Loaded => "events.document.loaded",
        when Events_Document_Closed => "events.document.closed",
        when Events_Announcement_Requested =>
          "events.announcement.requested",
        when Events_Live_Region => "events.live_region",
        when Events_Live_Region_Changed => "events.live_region.changed",
        when Events_Relation_Added => "events.relation.added",
        when Events_Relation_Removed => "events.relation.removed",
        when Events_Relation_Targets_Changed =>
          "events.relation.targets_changed",
        when Events_Live_Region_Payload => "events.live_region.payload",
        when Live_Region_Metadata => "live_region.metadata",
        when Live_Region_Relevance => "live_region.relevance",
        when Live_Region_Backend_Routing => "live_region.backend_routing",
        when Events_Text_Payload => "events.text.payload",
        when Events_Property_Payload => "events.property.payload",
        when Events_Property_Orientation =>
          "events.property.orientation",
        when Events_Property_Set_Position =>
          "events.property.set_position",
        when Events_Property_Set_Size =>
          "events.property.set_size",
        when Events_Property_Hierarchical_Level =>
          "events.property.hierarchical_level",
        when Events_State_Payload => "events.state.payload",
        when Events_Relation_Payload => "events.relation.payload",
        when Events_Bounds_Payload => "events.bounds.payload",
        when Events_Focus_Payload => "events.focus.payload",
        when Events_Node_Reference_Payload =>
          "events.node_reference.payload",
        when Events_Value_Payload => "events.value.payload",
        when Events_Selection_Payload => "events.selection.payload",
        when Events_Tree_Payload => "events.tree.payload",
        when Events_Table_Payload => "events.table.payload",
        when Events_Document_Payload => "events.document.payload",
        when Events_Window_Payload => "events.window.payload",
        when Events_Session_Notification => "events.session.notification",
        when Events_Backend_Pump => "events.backend_pump",
        when Events_Backend_Pump_Report => "events.backend_pump_report",
        when Events_Subscription_Filter =>
          "events.subscription.filter",
        when Events_Subscription_Bounds =>
          "events.subscription.bounds",
        when Tree_Ownership => "tree.ownership",
        when Tree_Attachment_Validation =>
          "tree.attachment.validation",
        when Tree_Exposure_Projection =>
          "tree.exposure.projection",
        when Tree_Mutation_Event_Order =>
          "tree.mutation.event_order",
        when Tree_Traversal_Limit => "tree.traversal_limit",
        when Lifecycle_Tombstone => "lifecycle.tombstone",
        when Dispatcher_Call_Metadata =>
          "dispatcher.call.metadata",
        when Dispatcher_Timeout_Classification =>
          "dispatcher.timeout.classification",
        when Dispatcher_Call_Accounting =>
          "dispatcher.call.accounting",
        when Dispatcher_Cancellation =>
          "dispatcher.cancellation",
        when Dispatcher_Reentrancy => "dispatcher.reentrancy",
        when Null_Backend_Event_Order => "backend.null.event_order")
   with SPARK_Mode => On;

   procedure Add
     (Items          : in out Declaration_Vectors.Vector;
      Feature        : Feature_Id;
      Backend        : String;
      Support        : Support_Level;
      Native_Mapping : String := "";
      Test_Id        : String := "")
   is
      Item : Declaration;
   begin
      Item.Feature := Feature;
      Item.Backend := To_Unbounded_String (Backend);
      Item.Support := Support;
      Item.Native_Mapping := To_Unbounded_String (Native_Mapping);
      Item.Test_Id := To_Unbounded_String (Test_Id);

      for Index in Items.First_Index .. Items.Last_Index loop
         if Items (Index).Feature = Feature
           and then To_String (Items (Index).Backend) = Backend
         then
            Items.Replace_Element (Index, Item);
            return;
         end if;
      end loop;

      Items.Append (Item);
   end Add;

   Common_State_Features : constant array (Positive range <>) of Feature_Id :=
     [Core_State_Enabled,
      Core_State_Sensitive,
      Core_State_Visible,
      Core_State_Showing,
      Core_State_Focused,
      Core_State_Focusable,
      Core_State_Selected,
      Core_State_Selectable,
      Core_State_Checked,
      Core_State_Indeterminate,
      Core_State_Expanded,
      Core_State_Expandable,
      Core_State_Pressed,
      Core_State_Read_Only,
      Core_State_Editable,
      Core_State_Required,
      Core_State_Invalid,
      Core_State_Busy,
      Core_State_Modal,
      Core_State_Multi_Line,
      Core_State_Multi_Selectable,
      Core_State_Visited,
      Core_State_Offscreen,
      Core_State_Defunct,
      Core_State_Active];

   procedure Add_Common_State_Declarations
     (Items          : in out Declaration_Vectors.Vector;
      Backend        : String;
      Native_Mapping : String;
      Test_Suffix    : String)
   is
   begin
      for Feature of Common_State_Features loop
         Add
           (Items,
            Feature,
            Backend,
            Internal_Only,
            Native_Mapping => Native_Mapping,
            Test_Id => Dotted_Name (Feature) & "." & Test_Suffix);
      end loop;
   end Add_Common_State_Declarations;

   Common_Capability_Features : constant array (Positive range <>) of
     Feature_Id :=
     [Core_Capability_Action,
      Core_Capability_Text,
      Core_Capability_Editable_Text,
      Core_Capability_Value,
      Core_Capability_Selection,
      Core_Capability_Table,
      Core_Capability_Document,
      Core_Capability_Image,
      Core_Capability_Relation,
      Core_Capability_Live_Region,
      Core_Capability_Surface];

   procedure Add_Common_Capability_Declarations
     (Items          : in out Declaration_Vectors.Vector;
      Backend        : String;
      Native_Mapping : String;
      Test_Suffix    : String)
   is
   begin
      for Feature of Common_Capability_Features loop
         Add
           (Items,
            Feature,
            Backend,
            Internal_Only,
            Native_Mapping => Native_Mapping,
            Test_Id => Dotted_Name (Feature) & "." & Test_Suffix);
      end loop;
   end Add_Common_Capability_Declarations;

   Common_Value_Features : constant array (Positive range <>) of Feature_Id :=
     [Value_Kind_Unknown,
      Value_Kind_Indeterminate,
      Value_Kind_Integer,
      Value_Kind_Decimal,
      Value_Kind_Floating,
      Value_Kind_Boolean,
      Value_Kind_Enumerated,
      Value_Access_Read_Only,
      Value_Access_Writable];

   procedure Add_Common_Value_Declarations
     (Items          : in out Declaration_Vectors.Vector;
      Backend        : String;
      Native_Mapping : String;
      Test_Suffix    : String)
   is
   begin
      for Feature of Common_Value_Features loop
         Add
           (Items,
            Feature,
            Backend,
            Internal_Only,
            Native_Mapping => Native_Mapping,
            Test_Id => Dotted_Name (Feature) & "." & Test_Suffix);
      end loop;
   end Add_Common_Value_Declarations;

   function Support_For
     (Items   : Declaration_Vectors.Vector;
      Feature : Feature_Id;
      Backend : String)
      return Support_Level
   is
   begin
      for Item of Items loop
         if Item.Feature = Feature and then To_String (Item.Backend) = Backend then
            return Item.Support;
         end if;
      end loop;

      return Unsupported;
   end Support_For;

   function Is_Production_Support (Level : Support_Level) return Boolean is
     (A11y.Conformance.Classification.Is_Production_Support (Level))
   with SPARK_Mode => On;

   function Is_Internal_Or_Unsupported
     (Level : Support_Level)
      return Boolean is
     (A11y.Conformance.Classification.Is_Internal_Or_Unsupported (Level))
   with SPARK_Mode => On;

   function Support_Rank (Level : Support_Level) return Natural is
     (A11y.Conformance.Classification.Support_Rank (Level))
   with SPARK_Mode => On;

   function At_Least
     (Level     : Support_Level;
      Threshold : Support_Level)
      return Boolean is
     (A11y.Conformance.Classification.At_Least (Level, Threshold))
   with SPARK_Mode => On;

   function Is_Native_Backend (Backend : String) return Boolean is
     (Backend = "AT-SPI"
      or else Backend = "UIA"
      or else Backend = "NSAccessibility")
   with SPARK_Mode => On;

   function Native_Production_Claims_Require_Evidence
     (Items                     : Declaration_Vectors.Vector;
      Native_Evidence_Available : Boolean)
      return Boolean
   is
   begin
      for Item of Items loop
         if Is_Native_Backend (To_String (Item.Backend))
           and then Is_Production_Support (Item.Support)
           and then not Native_Evidence_Available
         then
            return False;
         end if;
      end loop;

      return True;
   end Native_Production_Claims_Require_Evidence;

   function Null_Backend_Declarations return Declaration_Vectors.Vector is
      Items : Declaration_Vectors.Vector;
   begin
      for Feature in Feature_Id loop
         Add
           (Items,
            Feature,
            "Null",
            Internal_Only,
            Native_Mapping => "semantic validation",
            Test_Id => Dotted_Name (Feature) & ".null");
      end loop;

      return Items;
   end Null_Backend_Declarations;

   function Disabled_Backend_Declarations return Declaration_Vectors.Vector is
      Items : Declaration_Vectors.Vector;
   begin
      for Feature in Feature_Id loop
         Add
           (Items,
            Feature,
            "Disabled",
            Unsupported,
            Native_Mapping => "accessibility disabled",
            Test_Id => Dotted_Name (Feature) & ".disabled");
      end loop;

      Add
        (Items,
         Backend_Diagnostics_Bounded,
         "Disabled",
         Internal_Only,
         Native_Mapping => "bounded disabled-backend diagnostic log",
         Test_Id => "backend.diagnostics.bounded.disabled");
      Add
        (Items,
         Events_Envelope,
         "Disabled",
         Internal_Only,
         Native_Mapping => "central semantic event envelope validation",
         Test_Id => "events.envelope.disabled");
      Add
        (Items,
         Diagnostics_Field_Bounds,
         "Disabled",
         Internal_Only,
         Native_Mapping => "bounded diagnostic field and record metadata validation",
         Test_Id => "diagnostics.field_bounds.disabled");
      Add
        (Items,
         Diagnostics_Localization,
         "Disabled",
         Internal_Only,
         Native_Mapping => "message-catalog-backed diagnostic/status labels",
         Test_Id => "diagnostics.localization.disabled");

      return Items;
   end Disabled_Backend_Declarations;

   function Linux_ATSPI_Declarations return Declaration_Vectors.Vector is
      Items : Declaration_Vectors.Vector;

      procedure Internal_Map
        (Feature : Feature_Id;
         Mapping : String) is
      begin
         Add
           (Items,
            Feature,
            "AT-SPI",
            Internal_Only,
            Native_Mapping => Mapping,
            Test_Id => Dotted_Name (Feature) & ".linux");
      end Internal_Map;

      procedure Exact_Map
        (Feature : Feature_Id;
         Mapping : String) is
      begin
         Add
           (Items,
            Feature,
            "AT-SPI",
            Exact,
            Native_Mapping => Mapping,
            Test_Id => Dotted_Name (Feature) & ".linux");
      end Exact_Map;
   begin
      Internal_Map
        (Core_Role_Application,
         "AT-SPI application role projection through central role map");
      Internal_Map
        (Core_Role_Window,
         "AT-SPI window role projection through central role map");
      Internal_Map
        (Core_Role_Dialog,
         "AT-SPI dialog role projection through central role map");
      Internal_Map
        (Core_Role_Group,
         "AT-SPI group role projection through central role map");
      Internal_Map
        (Core_Role_Region,
         "AT-SPI region role projection through central role map");
      Internal_Map
        (Core_Role_Static_Text,
         "AT-SPI static-text role projection through central role map");
      Internal_Map
        (Core_Role_Button,
         "AT-SPI button role projection through central role map");
      Internal_Map
        (Core_Role_Text_Field,
         "AT-SPI text field role projection through central role map");
      Internal_Map
        (Core_Role_Toggle_Button,
         "AT-SPI toggle button role projection through central role map");
      Internal_Map
        (Core_Role_Check_Box,
         "AT-SPI check box role projection through central role map");
      Internal_Map
        (Core_Role_Radio_Button,
         "AT-SPI radio button role projection through central role map");
      Internal_Map
        (Core_Role_Progress_Bar,
         "AT-SPI progress bar role projection through central role map");
      Internal_Map
        (Core_Role_Spin_Button,
         "AT-SPI spin button role projection through central role map");
      Internal_Map
        (Core_Role_Slider,
         "AT-SPI slider role projection through central role map");
      Internal_Map
        (Core_Role_List,
         "AT-SPI list role projection through central role map");
      Internal_Map
        (Core_Role_List_Item,
         "AT-SPI list item role projection through central role map");
      Internal_Map
        (Core_Role_Tree,
         "AT-SPI tree role projection through central role map");
      Internal_Map
        (Core_Role_Tree_Item,
         "AT-SPI tree item role projection through central role map");
      Internal_Map
        (Core_Role_Table,
         "AT-SPI table role projection through central role map");
      Internal_Map
        (Core_Role_Row,
         "AT-SPI row role projection through central role map");
      Internal_Map
        (Core_Role_Column,
         "AT-SPI column role projection through central role map");
      Internal_Map
        (Core_Role_Cell,
         "AT-SPI cell role projection through central role map");
      Internal_Map
        (Core_Role_Combo_Box,
         "AT-SPI combo box role projection through central role map");
      Internal_Map
        (Core_Role_Search_Field,
         "AT-SPI search field role projection through central role map");
      Internal_Map
        (Core_Role_Menu_Bar,
         "AT-SPI menu bar role projection through central role map");
      Internal_Map
        (Core_Role_Menu,
         "AT-SPI menu role projection through central role map");
      Internal_Map
        (Core_Role_Menu_Item,
         "AT-SPI menu item role projection through central role map");
      Internal_Map
        (Core_Role_Tool_Bar,
         "AT-SPI toolbar role projection through central role map");
      Internal_Map
        (Core_Role_Tab_List,
         "AT-SPI tab list role projection through central role map");
      Internal_Map
        (Core_Role_Tab,
         "AT-SPI tab role projection through central role map");
      Internal_Map
        (Core_Role_Tooltip,
         "AT-SPI tooltip role projection through central role map");
      Internal_Map
        (Core_Role_Heading,
         "AT-SPI heading role projection through central role map");
      Internal_Map
        (Core_Role_Document,
         "AT-SPI document role projection through central role map");
      Internal_Map
        (Core_Role_Text,
         "AT-SPI text role projection through central role map");
      Internal_Map
        (Core_Role_Link,
         "AT-SPI link role projection through central role map");
      Internal_Map
        (Core_Role_Password_Field,
         "AT-SPI password field role projection through central role map");
      Internal_Map
        (Core_Role_Scroll_Bar,
         "AT-SPI scroll bar role projection through central role map");
      Internal_Map
        (Core_Role_Separator,
         "AT-SPI separator role projection through central role map");
      Internal_Map
        (Core_Role_Alert,
         "AT-SPI alert role projection through central role map");
      Internal_Map
        (Core_Role_Popup_Dialog,
         "AT-SPI popup dialog role projection through central role map");
      Internal_Map (Value_Range, "AT-SPI value range semantics");
      Internal_Map (Selection_Single, "AT-SPI single-selection semantics");
      Internal_Map
        (Relations_Active_Descendant,
         "AT-SPI active-descendant relation projection");
      Internal_Map
        (Relations_Labelled_By,
         "AT-SPI labelled-by relation projection");
      Internal_Map
        (Relations_Label_For,
         "AT-SPI label-for relation projection");
      Internal_Map
        (Relations_Described_By,
         "AT-SPI described-by relation projection");
      Internal_Map
        (Relations_Description_For,
         "AT-SPI description-for relation projection");
      Internal_Map
        (Relations_Controlled_By,
         "AT-SPI controlled-by relation projection");
      Internal_Map
        (Relations_Controller_For,
         "AT-SPI controller-for relation projection");
      Internal_Map
        (Relations_Flows_To,
         "AT-SPI flows-to relation projection");
      Internal_Map
        (Relations_Flows_From,
         "AT-SPI flows-from relation projection");
      Internal_Map
        (Relations_Member_Of,
         "AT-SPI member-of relation projection");
      Internal_Map
        (Relations_Details,
         "AT-SPI details relation projection");
      Internal_Map
        (Relations_Details_For,
         "AT-SPI details-for relation projection");
      Internal_Map
        (Selection_Current_Item,
         "AT-SPI current-item selection metadata");
      Internal_Map (Text_Range_Basic, "AT-SPI Text.GetText range query");
      Internal_Map (Table_Cell_Basic, "AT-SPI stable table cell query");
      Internal_Map
        (Image_Alternative_Text,
         "AT-SPI image alternative text projection");
      Internal_Map
        (Document_Heading_Level,
         "AT-SPI document heading-level projection");
      Internal_Map (Text_Protected, "AT-SPI protected text redaction");
      Internal_Map
        (Events_Live_Region_Changed,
         "AT-SPI live-region changed event routing");
      Internal_Map
        (Relations_Error_Message,
         "AT-SPI error-message relation projection");
      Internal_Map
        (Relations_Error_For,
         "AT-SPI error-for relation projection");
      Internal_Map
        (Relations_Embedded_By,
         "AT-SPI embedded-by relation projection");
      Internal_Map
        (Relations_Embeds,
         "AT-SPI embeds relation projection");
      Internal_Map
        (Relations_Popup_For,
         "AT-SPI popup-for relation projection");
      Internal_Map
        (Relations_Popup_Controlled_By,
         "AT-SPI popup-controlled-by relation projection");
      Internal_Map
        (Lifecycle_Stale_Reference,
         "AT-SPI stale object-path rejection");
      Internal_Map
        (Backend_Transport_Unavailable,
         "AT-SPI unavailable transport status reporting");
      Internal_Map
        (Native_Fixture_Root_Child_Traversal,
         "AT-SPI fixture-root child traversal probe");
      Internal_Map
        (Native_Fixture_Root_Child_Count,
         "AT-SPI fixture-root child-count probe");
      Internal_Map
        (Native_Fixture_Root_Second_Child,
         "AT-SPI fixture-root second-child probe");
      Internal_Map
        (Native_Fixture_Child_Query,
         "AT-SPI fixture child query probe");
      Internal_Map
        (Native_Fixture_Child_Native_Object,
         "AT-SPI fixture child native object probe");
      Internal_Map
        (Native_Fixture_Child_Parent_Navigation,
         "AT-SPI fixture child parent navigation probe");
      Internal_Map
        (Native_Fixture_Child_Native_Identity,
         "AT-SPI fixture child native identity probe");
      Internal_Map
        (Native_Fixture_Second_Child_Parent_Navigation,
         "AT-SPI fixture second-child parent navigation probe");
      Internal_Map
        (Native_Fixture_Second_Child_Native_Identity,
         "AT-SPI fixture second-child native identity probe");
      Internal_Map
        (Native_Fixture_Sibling_Order,
         "AT-SPI fixture sibling-order probe");
      Internal_Map
        (Native_Fixture_Child_Stale_Id,
         "AT-SPI fixture stale child identity probe");
      Internal_Map
        (Linux_ATSPI_Live_External_Client,
         "live external AT-SPI client probe");
      Internal_Map
        (Linux_ATSPI_Live_External_Client_Attributes,
         "live external AT-SPI client attribute probe");
      Internal_Map
        (Linux_ATSPI_Live_External_Client_Protected_Value,
         "live external AT-SPI client protected-value probe");
      Internal_Map
        (Linux_ATSPI_Session_Dispatch_Loop_Report,
         "AT-SPI session dispatch loop report");
      Internal_Map
        (Linux_DBUS_Startup_Reply_Evidence,
         "D-Bus startup reply evidence");
      Internal_Map
        (Linux_ATSPI_Startup_Object_Path,
         "AT-SPI startup object-path evidence");
      Internal_Map (Linux_ATSPI_Component_Focus, "Component.GrabFocus");
      Internal_Map
        (Linux_ATSPI_Selection_Deselect_Child,
         "Selection.DeselectChild request");
      Internal_Map
        (Linux_ATSPI_Selection_Select_All,
         "Selection.SelectAll request");
      Internal_Map
        (Linux_ATSPI_Selection_Clear_Selection,
         "Selection.ClearSelection request");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Probe,
         "AT-SPI serving-packet probe");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Tree_Traversal,
         "AT-SPI serving-packet tree traversal");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Property,
         "AT-SPI serving-packet property query");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Property_Map,
         "AT-SPI serving-packet property map");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Stale_Error,
         "AT-SPI serving-packet stale error");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Unsupported_Interface,
         "AT-SPI serving-packet unsupported interface");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Malformed_Packet,
         "AT-SPI serving-packet malformed packet");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Text_Payload_Limit,
         "AT-SPI serving-packet text payload limit");
      Internal_Map
        (Linux_ATSPI_Session_Dispatch_Probe,
         "AT-SPI session-dispatch probe");
      Internal_Map
        (Linux_ATSPI_Session_Dispatch_Boundary_Drained,
         "AT-SPI session-dispatch boundary-drained report");
      Internal_Map
        (Linux_ATSPI_Session_Bus_Probe,
         "AT-SPI session-bus probe");
      Internal_Map
        (Linux_ATSPI_Session_Startup_Stage,
         "AT-SPI session startup-stage report");
      Internal_Map
        (Linux_DBUS_Method_Call_Destination_Routing,
         "D-Bus method-call destination routing");

      Internal_Map (Linux_ATSPI_Role_Map, "Role constants");
      Internal_Map (Backend_Native_Scaffold, "native runtime scaffold");
      Internal_Map
        (Backend_Native_Target_Resolution,
         "host platform to AT-SPI backend target");
      Internal_Map
        (Backend_Selection_Runtime_Override,
         "common runtime backend override constructor");
      Internal_Map
        (Backend_Selection_Fallback,
         "common runtime backend override fallback classification");
      Internal_Map
        (Backend_Native_Transport_Admission,
         "adapter-facing transport admission snapshot");
      Internal_Map
        (Backend_Native_Transport_Status,
         "adapter-facing typed transport state and failure snapshot");
      Internal_Map
        (Backend_Native_Transport_Generation,
         "adapter-facing monotonic transport snapshot generation");
      Internal_Map
        (Backend_Native_Transport_Transition_Report,
         "adapter-facing structured transport transition report");
      Internal_Map
        (Backend_Native_Deterministic_Shutdown,
         "adapter-facing deterministic transport shutdown");
      Internal_Map
        (Native_Runtime_Lifecycle,
         "shared native runtime start, stop, and drained lifecycle");
      Internal_Map
        (Native_Runtime_Generation,
         "shared native runtime lifecycle generation snapshot");
      Internal_Map
        (Native_Runtime_Lifecycle_Report,
         "shared native runtime lifecycle transition report");
      Internal_Map
        (Backend_Native_Publication_Preparation,
         "adapter-facing prepared native publication record");
      Internal_Map
        (Backend_Diagnostics_Bounded,
         "bounded native-backend diagnostic log");
      Internal_Map
        (Diagnostics_Result_Mapping,
         "structured result-to-diagnostic category mapping");
      Internal_Map
        (Diagnostics_Field_Bounds,
         "bounded diagnostic field, identifier, and record-retention validation");
      Internal_Map
        (Diagnostics_Localization,
         "message-catalog-backed diagnostic/status labels");
      Internal_Map
        (Native_Runtime_Event_Application,
         "committed semantic event application, direct defunct ledgering, " &
         "bounded tombstone eviction, and stale destroyed-node rejection");
      Internal_Map
        (Core_Node_Key_Registry,
         "stable application key to Node_Id registry");
      Internal_Map
        (Core_Geometry_Visibility,
         "central logical desktop clipping and visibility classification");
      Internal_Map
        (Core_Geometry_Region,
         "bounded logical desktop visible-region representation");
      Internal_Map
        (Core_Provider_Contract,
         "central provider role/state/capability contract validation");
      Add_Common_Capability_Declarations
        (Items,
         "AT-SPI",
         "AT-SPI interface exposure from central semantic capability set",
         "linux");
      Internal_Map
        (Core_Role_Image,
         "AT-SPI image role projection through central role map");
      Internal_Map
        (Core_Role_Status,
         "AT-SPI status/live-region role projection through central role map");
      Internal_Map
        (Core_Role_Decorative_Image,
         "decorative semantic image omission before AT-SPI exposure");
      Internal_Map
        (Core_Role_Canvas,
         "AT-SPI canvas role projection through central role map");
      Internal_Map
        (Core_Role_Custom,
         "AT-SPI custom role fallback through central role map");
      Internal_Map
        (Core_State_Derivation,
         "central role/capability-derived effective state normalization");
      Add_Common_State_Declarations
        (Items,
         "AT-SPI",
         "AT-SPI state set projection from central semantic state map",
         "linux");
      Internal_Map
        (Events_Live_Region,
         "live-region metadata and announcement validation");
      Internal_Map
        (Events_Classification,
         "central semantic event-family classification");
      declare
         Event_Kinds : constant array (Positive range <>) of Feature_Id :=
           [Events_Node_Created,
            Events_Node_Attached,
            Events_Node_Detached,
            Events_Child_Added,
            Events_Child_Removed,
            Events_Children_Reordered,
            Events_Subtree_Rebuilt,
            Events_Property_Changed,
            Events_State_Changed,
            Events_Bounds_Changed,
            Events_Focus_Changed,
            Events_Active_Descendant_Changed,
            Events_Selection_Changed,
            Events_Current_Item_Changed,
            Events_Value_Changed,
            Events_Range_Changed,
            Events_Text_Inserted,
            Events_Text_Removed,
            Events_Text_Replaced,
            Events_Caret_Moved,
            Events_Text_Selection_Changed,
            Events_Text_Attributes_Changed,
            Events_Row_Inserted,
            Events_Row_Removed,
            Events_Column_Inserted,
            Events_Column_Removed,
            Events_Cell_Changed,
            Events_Window_Opened,
            Events_Window_Closed,
            Events_Window_Activated,
            Events_Window_Deactivated,
            Events_Document_Loaded,
            Events_Document_Closed,
            Events_Announcement_Requested,
            Events_Relation_Added,
            Events_Relation_Removed,
            Events_Relation_Targets_Changed,
            Events_Node_Destroyed];
      begin
         for Feature of Event_Kinds loop
            Internal_Map
              (Feature,
               "central semantic event-kind validation and AT-SPI event mapping");
         end loop;
      end;
      Internal_Map
        (Events_Envelope,
         "central semantic event envelope validation");
      Internal_Map
        (Events_Timestamp_Order,
         "event queue nondecreasing committed timestamp order");
      Internal_Map
        (Events_Live_Region_Payload,
         "typed live-region change and announcement payload validation");
      Internal_Map
        (Live_Region_Metadata,
         "central live-region setting, atomicity, and announcement policy");
      Internal_Map
        (Live_Region_Relevance,
         "central stable live-region relevance names and validation");
      Internal_Map
        (Live_Region_Backend_Routing,
         "AT-SPI live-region query routing and bounded native replies");
      Internal_Map
        (Events_Text_Payload,
         "typed text mutation event payload and record validation");
      Internal_Map
        (Events_Property_Payload,
         "typed property-change event payload validation");
      Internal_Map
        (Events_Property_Orientation,
         "AT-SPI property-change:orientation signal projection");
      Internal_Map
        (Events_Property_Set_Position,
         "AT-SPI property-change:set-position signal projection");
      Internal_Map
        (Events_Property_Set_Size,
         "AT-SPI property-change:set-size signal projection");
      Internal_Map
        (Events_Property_Hierarchical_Level,
         "AT-SPI property-change:hierarchical-level signal projection");
      Internal_Map
        (Events_State_Payload,
         "typed state-change event payload validation");
      Internal_Map
        (Events_Relation_Payload,
         "typed relation-change event payload and inverse validation");
      Internal_Map
        (Events_Bounds_Payload,
         "typed bounds-change event payload validation");
      Internal_Map
        (Events_Focus_Payload,
         "typed focus-change event payload validation");
      Internal_Map
        (Events_Node_Reference_Payload,
         "typed active-descendant/current-item event payload validation");
      Internal_Map
        (Events_Value_Payload,
         "typed value/range event payload validation");
      Internal_Map
        (Events_Selection_Payload,
         "typed item and invalidation selection payload validation");
      Internal_Map
        (Events_Tree_Payload,
         "typed child and aggregate tree event payload validation");
      Internal_Map
        (Events_Table_Payload,
         "typed table row/column/cell event payload family validation");
      Internal_Map
        (Events_Document_Payload,
         "typed document lifecycle event payload validation");
      Internal_Map
        (Events_Window_Payload,
         "typed window and surface event payload validation");
      Internal_Map
        (Events_Session_Notification,
         "validated provider semantic event notification");
      Internal_Map
        (Events_Backend_Pump_Report,
         "structured common session-to-backend event pump report");
      Internal_Map
        (Events_Subscription_Filter,
         "bounded backend event subscription filters");
      Internal_Map
        (Events_Subscription_Bounds,
         "bounded backend event fan-out admission");
      Internal_Map
        (Tree_Attachment_Validation,
         "attachment validation before event-capacity preflight");
      Internal_Map
        (Tree_Exposure_Projection,
         "central semantic exposure projection");
      Internal_Map
        (Tree_Mutation_Event_Order,
         "committed tree mutation event ordering");
      Internal_Map
        (Native_Runtime_Event_Preparation,
         "atomic runtime event to native object preparation");
      Internal_Map
        (Native_Runtime_Event_Preparation_Report,
         "structured runtime event-preparation report");
      Internal_Map
        (Native_Projection_Property,
         "central exposure validation before AT-SPI property projection");
      Internal_Map
        (Native_Projection_Action,
         "central exposure validation before AT-SPI action projection");
      Internal_Map
        (Native_Request_Action_Payload,
         "neutral Action_Id retained for backend-private action dispatch");
      Internal_Map
        (Native_Projection_Relation,
         "central exposure validation before AT-SPI relation projection");
      Internal_Map
        (Native_Projection_Event_Source,
         "central exposure validation before AT-SPI signal projection");
      Internal_Map
        (Native_Event_Validation,
         "native event emission validation");
      Internal_Map
        (Native_Event_Prepared_Status,
         "prepared native publication status handoff");
      Internal_Map
        (Native_Event_Exhaustive_Map,
         "native event mapping for every semantic event kind");
      Internal_Map
        (Native_Role_Exhaustive_Map,
         "native role mapping for every semantic role");
      Internal_Map
        (Native_Relation_Exhaustive_Map,
         "native relation mapping for every semantic relation");
      Internal_Map
        (Native_Object_Cache_Node_Index,
         "indexed Node_Id to native object cache lookup");
      Internal_Map
        (Native_Object_Cache_Tombstone,
         "bounded stale native object tombstones");
      Internal_Map
        (Native_Object_Cache_Session_Scope,
         "backend-session-scoped native object identities");
      Internal_Map
        (Native_Object_Cache_Resource_Limit,
         "bounded native object cache");
      Internal_Map
        (Native_Object_Cache_Generation,
         "monotonic native object cache mutation generation");
      Internal_Map
        (Native_Object_Cache_Mutation_Report,
         "structured native object cache mutation reports");
      Internal_Map
        (Native_Object_Registry_Generation,
         "monotonic AT-SPI object registry mutation generation");
      Internal_Map
        (Native_Object_Registry_Drained_Reset,
         "drained-aware AT-SPI object registry reset");
      Internal_Map
        (Native_Object_Registry_Mutation_Report,
         "structured AT-SPI object registry mutation reports");
      Internal_Map
        (Native_Object_Lifetime_Resource_Limit,
         "bounded native object lifetime references");
      Internal_Map
        (Native_Value_Resource_Limit,
         "bounded native value strings and arrays");
      Internal_Map
        (Native_Callback_Gate,
         "native callback admission and reset guard");
      Internal_Map
        (Native_Callback_Generation,
         "native callback gate lifecycle generation snapshot");
      Internal_Map
        (Native_Boundary_Call_Context,
         "native boundary object-call context");
      Internal_Map
        (Native_Boundary_Call_Kind,
         "native boundary dispatcher call-kind and failure-context snapshot");
      Internal_Map
        (Native_Boundary_Return_Class,
         "native boundary structured return classification");
      Internal_Map
        (Native_Boundary_Status_Recording,
         "native boundary provider-status recording");
      Internal_Map
        (Native_Boundary_Admission_Report,
         "native boundary admission report");
      Internal_Map
        (Native_Boundary_Native_Call_Report,
         "native boundary native-call mutation report");
      Internal_Map
        (Native_Boundary_Completion_Report,
         "native boundary completion report");
      Internal_Map
        (Native_Boundary_Release_Report,
         "native boundary release report");
      Internal_Map
        (Native_Fixture_Root_Query,
         "fixture application root query through native provider boundary");
      Internal_Map
        (Native_Fixture_Root_Failure_Stage,
         "fixture root probe lifecycle failure-stage report");
      Internal_Map
        (Native_Boundary_Cancellation,
         "native boundary cancellation propagation");
      Internal_Map
        (Native_Boundary_Query_Cancellation,
         "native boundary property and geometry query cancellation");
      Internal_Map
        (Native_Boundary_Tree_Cancellation,
         "native boundary tree-navigation cancellation");
      Internal_Map
        (Native_Boundary_Component_Cancellation,
         "native boundary component geometry cancellation");
      Internal_Map
        (Dispatcher_Call_Metadata,
         "dispatcher call-kind timeout metadata");
      Internal_Map
        (Dispatcher_Timeout_Classification,
         "dispatcher elapsed-time timeout classification");
      Internal_Map
        (Dispatcher_Call_Accounting,
         "dispatcher call-kind bounded accounting");
      Internal_Map
        (Dispatcher_Cancellation,
         "dispatcher cancellation token policy");
      Internal_Map
        (Dispatcher_Reentrancy,
         "dispatcher reentrant rejection and explicit inline fast path");
      Internal_Map
        (Native_Boundary_Action_Call,
         "native boundary action-call dispatcher");
      Internal_Map
        (Native_Boundary_Node_Action_Call,
         "native boundary existing-node action dispatcher");
      Internal_Map
        (Native_Boundary_Query_Call,
         "native boundary property-query dispatcher");
      Internal_Map
        (Native_Boundary_Node_Query_Call,
         "native boundary existing-node property-query dispatcher");
      Internal_Map
        (Native_Boundary_Tree_Call,
         "native boundary tree-navigation dispatcher");
      Internal_Map
        (Native_Boundary_Node_Tree_Call,
         "native boundary existing-node tree-navigation dispatcher");
      Internal_Map
        (Native_Boundary_Component_Call,
         "native boundary component geometry dispatcher");
      Internal_Map
        (Native_Boundary_Node_Component_Call,
         "native boundary existing-node component geometry dispatcher");
      Internal_Map
        (Native_Boundary_Focus_Cancellation,
         "native boundary focus query/action cancellation");
      Internal_Map
        (Native_Boundary_Focus_Call,
         "native boundary focus query/action dispatcher");
      Internal_Map
        (Native_Boundary_Node_Focus_Call,
         "native boundary existing-node focus query/action dispatcher");
      Internal_Map
        (Core_Focus_Session,
         "session-owned focus state and events");
      Internal_Map
        (Native_Boundary_Relation_Cancellation,
         "native boundary relation query cancellation");
      Internal_Map
        (Native_Boundary_Relation_Call,
         "native boundary relation query dispatcher");
      Internal_Map
        (Native_Boundary_Node_Relation_Call,
         "native boundary existing-node relation query dispatcher");
      Internal_Map
        (Native_Boundary_Node_Call,
         "native boundary existing-node callback admission");
      Internal_Map
        (Native_Boundary_Stale_Metadata,
         "native boundary stale object metadata preservation");
      Internal_Map
        (Native_Boundary_Error_Map,
         "native boundary structured error map");
      Internal_Map (Linux_ATSPI_State_Map, "StateSet bits");
      Internal_Map (Linux_ATSPI_Object_Path, "D-Bus object path");
      Internal_Map (Linux_DBUS_Bus_Address, "D-Bus bus address validation");
      Internal_Map
        (Linux_DBUS_Connection_Lifecycle,
         "D-Bus connection lifecycle staging");
      Internal_Map
        (Linux_DBUS_Local_Channel_Adapter,
         "hostkit local-channel adapter for Unix D-Bus sockets");
      Internal_Map
        (Linux_DBUS_Local_Channel_Receive,
         "hostkit local-channel receive boundary for D-Bus packets");
      Internal_Map
        (Linux_DBUS_Auth_External,
         "D-Bus EXTERNAL authentication command codec");
      Internal_Map
        (Linux_DBUS_Auth_Exchange,
         "D-Bus authentication response and BEGIN exchange boundary");
      Internal_Map
        (Linux_DBUS_Authenticated_Connect,
         "hostkit local-channel connect with EXTERNAL auth admission");
      Internal_Map
        (Linux_DBUS_Hello,
         "org.freedesktop.DBus.Hello request and unique-name reply");
      Internal_Map
        (Linux_DBUS_Authenticated_Hello,
         "authenticated local-channel connect through D-Bus Hello completion");
      Internal_Map
        (Linux_DBUS_Registration_Completion,
         "Socket.Embed method-return completion boundary");
      Internal_Map
        (Linux_DBUS_Authenticated_Registration,
         "authenticated local-channel connect through AT-SPI registration");
      Internal_Map
        (Linux_DBUS_Address_Discovery,
         "AT_SPI_BUS_ADDRESS value normalization for Linux AT-SPI startup");
      Internal_Map
        (Linux_DBUS_Host_Environment_Startup,
         "AT_SPI_BUS_ADDRESS host environment startup through hostkit");
      Internal_Map
        (Linux_DBUS_A11y_Bus_Get_Address,
         "org.a11y.Bus.GetAddress request and address reply completion");
      Internal_Map
        (Linux_DBUS_Authenticated_Get_Address,
         "authenticated session-bus connect through accessibility bus address discovery");
      Internal_Map
        (Linux_DBUS_Startup_Session_Discovery,
         "Linux AT-SPI startup preparation from session-bus discovery");
      Internal_Map
        (Linux_DBUS_Startup_Controller,
         "Linux AT-SPI startup context for bus/channel lifecycle");
      Internal_Map
        (Linux_DBUS_Startup_Backend_Adapter,
         "Linux AT-SPI startup result to common native backend transport status adapter");
      Internal_Map
        (Linux_DBUS_Startup_Outgoing_Work,
         "Linux AT-SPI startup pending/in-flight outgoing work counters");
      Internal_Map
        (Linux_DBUS_Startup_Event_Loop_Interest,
         "Linux AT-SPI no-I/O event-loop read/write interest snapshot");
      Internal_Map
        (Linux_DBUS_Startup_Event_Loop_Operation,
         "Linux AT-SPI no-I/O event-loop next-operation classification");
      Internal_Map
        (Linux_DBUS_Startup_Outgoing_Flush,
         "Linux AT-SPI bounded startup outgoing packet flush");
      Internal_Map
        (Linux_DBUS_Backend_Session_Event_Loop_Step,
         "Linux AT-SPI backend-session one-step event-loop driver");
      Internal_Map
        (Linux_DBUS_Backend_Session_Scheduler,
         "Linux AT-SPI backend-session bounded scheduler adapter");
      Internal_Map
        (Linux_DBUS_Backend_Session_Transport_Cycle_Scheduler,
         "Linux AT-SPI backend-session transport-cycle scheduler adapter");
      Internal_Map
        (Linux_DBUS_Startup_Pump_Readiness,
         "Linux AT-SPI startup pump readiness admission check");
      Internal_Map
        (Linux_DBUS_Startup_Pump,
         "Linux AT-SPI one-iteration receive/dispatch/reply pump");
      Internal_Map
        (Linux_DBUS_Startup_Pump_Report,
         "Linux AT-SPI one-iteration pump activity report");
      Internal_Map
        (Linux_DBUS_Startup_Pump_Bounded_Report,
         "Linux AT-SPI bounded pump aggregate activity report");
      Internal_Map
        (Linux_DBUS_Startup_Pump_Bounds,
         "Linux AT-SPI bounded pump iteration control");
      Internal_Map
        (Linux_DBUS_Startup_Registered_Pump,
         "Linux AT-SPI startup pump through registered object dispatch");
      Internal_Map
        (Linux_DBUS_Transport_Serve_Cycle,
         "Linux AT-SPI readable packet registered dispatch/write cycle");
      Internal_Map (Linux_DBUS_Codec_Basic, "D-Bus typed values");
      Internal_Map
        (Linux_DBUS_Unsupported_Value,
         "D-Bus explicit unsupported-value sentinel");
      Internal_Map
        (Linux_DBUS_UInt32_Array_Value,
         "D-Bus bounded UInt32-array typed value");
      Internal_Map
        (Linux_DBUS_State_Set_UInt32_Array,
         "D-Bus state-set method returns validated through bounded UInt32 arrays");
      Internal_Map
        (Linux_DBUS_String_Array_Value,
         "D-Bus bounded string-array typed value");
      Internal_Map
        (Linux_DBUS_Attribute_String_Array,
         "D-Bus attribute key/value arrays validated through bounded strings");
      Internal_Map
        (Linux_DBUS_Cache_Interface_String_Array,
         "D-Bus cache interface names validated through bounded string arrays");
      Internal_Map
        (Linux_DBUS_Object_Path_Array_Value,
         "D-Bus bounded object-path-array typed value");
      Internal_Map
        (Linux_DBUS_Relation_Target_Object_Path_Array,
         "D-Bus relation target arrays validated through bounded object paths");
      Internal_Map
        (Linux_DBUS_Resource_Limits,
         "bounded D-Bus header/body strings, object paths, and bus address fields");
      Internal_Map (Linux_DBUS_Message_Envelope, "D-Bus message envelope");
      Internal_Map
        (Linux_DBUS_Method_Call_Envelope,
         "D-Bus outgoing method-call envelope");
      Internal_Map
        (Linux_DBUS_Method_Return_Payload,
         "D-Bus method-return body signature and transport-frame payload bytes");
      Internal_Map
        (Linux_DBUS_Transport_Frame_Metadata,
         "D-Bus outgoing transport frame metadata");
      Internal_Map
        (Linux_DBUS_Transport_Frame_Bytes,
         "D-Bus outgoing transport frame bytes");
      Internal_Map
        (Linux_DBUS_Transport_Frame_Send,
         "D-Bus outgoing transport frame send staging");
      Internal_Map
        (Linux_DBUS_Transport_Packet,
         "D-Bus outgoing transport packet bytes");
      Internal_Map
        (Linux_DBUS_Transport_Packet_Send,
         "D-Bus outgoing transport packet send staging");
      Internal_Map
        (Linux_DBUS_Transport_Packet_Decode,
         "D-Bus incoming transport packet header decode");
      Internal_Map
        (Linux_DBUS_Transport_Envelope_Decode,
         "D-Bus incoming transport envelope decode");
      Internal_Map
        (Linux_DBUS_Method_Return_Decode,
         "D-Bus incoming method-return boundary decode");
      Internal_Map
        (Linux_DBUS_Error_Return_Decode,
         "D-Bus incoming error-return boundary decode");
      Internal_Map
        (Linux_DBUS_Error_Return_Diagnostic,
         "D-Bus incoming error-return structured diagnostics");
      Internal_Map
        (Linux_DBUS_Startup_Error_Completion,
         "D-Bus startup error replies completed through tracked serials");
      Internal_Map
        (Linux_DBUS_Outgoing_Back_Pressure,
         "D-Bus outgoing queue overflow back-pressure admission");
      Internal_Map
        (Linux_DBUS_Incoming_Call_Decode,
         "D-Bus incoming method-call boundary decode");
      Internal_Map
        (Linux_DBUS_Incoming_Packet_Classification,
         "D-Bus incoming packet no-mutation classification");
      Internal_Map
        (Linux_DBUS_Incoming_Packet_No_Dispatch,
         "D-Bus valid non-method packet no-dispatch handling");
      Internal_Map
        (Linux_DBUS_Incoming_Packet_Dispatch,
         "D-Bus incoming packet dispatch to queued reply");
      Internal_Map (Linux_DBUS_Signal_Envelope, "D-Bus signal envelope");
      Internal_Map
        (Native_Event_Staging_Queue, "bounded D-Bus outgoing event queue");
      Internal_Map
        (Native_Event_Prepared_Status,
         "prepared native publication status handoff");
      Internal_Map
        (Native_Event_Posting_Interest,
         "backend-private native event queue posting interest snapshot");
      Internal_Map
        (Native_Event_Posting_Boundary,
         "D-Bus outgoing transport envelope validation before send");
      Internal_Map
        (Linux_DBUS_Prepared_Signal_Envelope,
         "prepared native publication to D-Bus signal envelope");
      Internal_Map
        (Linux_DBUS_Signal_Envelope_Build_Report,
         "structured D-Bus signal-envelope build report");
      Internal_Map
        (Linux_ATSPI_Signal_Build_Report,
         "structured AT-SPI signal build report");
      Internal_Map
        (Linux_DBUS_Method_Boundary,
         "D-Bus method-call validation and argument-boundary checks");
      Internal_Map
        (Linux_ATSPI_Error_Name_Map,
         "structured status to AT-SPI/D-Bus error-name table");
      Internal_Map
        (Linux_ATSPI_Error_Name_Inverse_Map,
         "AT-SPI/D-Bus error-name to structured status table");
      Internal_Map
        (Linux_ATSPI_Error_Name_Diagnostic,
         "bounded AT-SPI/D-Bus error-name diagnostics");
      Internal_Map
        (Linux_DBUS_Application_Registration,
         "AT-SPI Socket.Embed application-registration method call");
      Internal_Map
        (Linux_ATSPI_Live_Transport_Registration_Observed,
         "observed AT-SPI transport registration after Socket.Embed reply");
      Internal_Map
        (Native_Boundary_Identity_Admission,
         "D-Bus object-path identity admission");
      Internal_Map
        (Native_Boundary_Admission_Report,
         "D-Bus object-path admission report");
      Internal_Map
        (Native_Boundary_Native_Call_Report,
         "D-Bus object-path native-call mutation report");
      Internal_Map
        (Native_Boundary_Completion_Report,
         "D-Bus object-path completion report");
      Internal_Map
        (Native_Boundary_Release_Report,
         "D-Bus object-path release report");
      Internal_Map
        (Native_Fixture_Root_Failure_Stage,
         "AT-SPI fixture-root probe status and failure-stage report");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Stale_Error_Queued,
         "stale object-path serving error queueing");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Stale_Error_Serialized,
         "stale object-path serving error serialization");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Stale_Error_Decoded,
         "stale object-path serving error decode");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Stale_Error_Drained,
         "stale object-path serving error bookkeeping drain");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued,
         "unsupported-interface serving error queueing");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized,
         "unsupported-interface serving error serialization");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded,
         "unsupported-interface serving error decode");
      Internal_Map
        (Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained,
         "unsupported-interface serving error bookkeeping drain");
      Internal_Map (Linux_ATSPI_Method_Router, "typed interface/method routing");
      Internal_Map (Linux_ATSPI_Application_Id, "Application.GetID");
      Internal_Map
        (Linux_ATSPI_Application_Metadata,
         "Application toolkit/version/locale methods");
      Internal_Map (Linux_ATSPI_Accessible_Role, "Accessible.GetRole");
      Internal_Map (Core_Property_Role, "Accessible.GetRole");
      Internal_Map
        (Linux_ATSPI_Accessible_Application,
         "Accessible.GetApplication");
      Internal_Map
        (Linux_ATSPI_Accessible_Interfaces,
         "Accessible.GetInterfaces");
      Internal_Map
        (Linux_ATSPI_Accessible_Role_Name,
         "Accessible.GetRoleName");
      Internal_Map
        (Linux_ATSPI_Accessible_Localized_Role_Name,
         "Accessible.GetLocalizedRoleName");
      Internal_Map (Linux_ATSPI_Accessible_State, "Accessible.GetState");
      Internal_Map (Core_Property_State_Set, "Accessible.GetState");
      Internal_Map
        (Core_State_Validation, "common state snapshot validation");
      Internal_Map (Linux_ATSPI_Accessible_Name, "Accessible.GetName");
      Internal_Map
        (Core_Property_Name,
         "Accessible.GetName");
      Internal_Map
        (Core_Property_Visible_Title,
         "Accessible.GetAttributes visible-title attribute");
      Internal_Map
        (Core_Property_Description,
         "Accessible.GetDescription");
      Internal_Map
        (Core_Property_Help_Text,
         "Accessible.GetAttributes help-text attribute");
      Internal_Map
        (Core_Property_Placeholder,
         "Accessible.GetAttributes placeholder-text attribute");
      Internal_Map
        (Core_Property_Value_Text,
         "Accessible.GetAttributes accessible-value attribute");
      Internal_Map
        (Core_Property_Keyboard_Shortcut,
         "Accessible.GetAttributes keyboard-shortcut attribute");
      Internal_Map
        (Core_Property_Semantic_Identifier,
         "Accessible.GetAttributes semantic-identifier attribute");
      Internal_Map
        (Core_Property_Typed_Results,
         "portable typed property result records");
      Internal_Map
        (Core_Property_Status_Mapping,
         "common result-to-property-status classification");
      Internal_Map
        (Linux_ATSPI_Accessible_Description,
         "Accessible.GetDescription");
      Internal_Map
        (Linux_ATSPI_Accessible_Child_Count,
         "Accessible.GetChildCount");
      Internal_Map
        (Linux_ATSPI_Accessible_Child_At,
         "Accessible.GetChildAtIndex");
      Internal_Map
        (Linux_ATSPI_Accessible_Children,
         "Accessible.GetChildren");
      Internal_Map
        (Linux_ATSPI_Accessible_Parent,
         "Accessible.GetParent");
      Internal_Map
        (Linux_ATSPI_Accessible_Index_In_Parent,
         "Accessible.GetIndexInParent");
      Internal_Map
        (Linux_ATSPI_Accessible_Relations,
         "Accessible.GetRelationSet");
      Internal_Map
        (Relations_Resource_Limit, "bounded relation target materialization");
      Internal_Map
        (Relations_Session_Ownership, "session-owned relation graph cleanup");
      Internal_Map (Linux_ATSPI_Component_Extents, "Component.GetExtents");
      Internal_Map (Core_Property_Bounds, "Component.GetExtents");
      Internal_Map (Linux_ATSPI_Component_Contains, "Component.Contains");
      Internal_Map
        (Linux_ATSPI_Component_Hit_Test, "Component.GetAccessibleAtPoint");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Component,
         "live external D-Bus client Component.GetExtents, Component.Contains,"
         & " and Component.GetAccessibleAtPoint traversal");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Action,
         "live external D-Bus client Action.GetNActions, Action.GetName,"
         & " and Action.DoAction invocation");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Value,
         "live external D-Bus client Value.GetCurrentValue,"
         & " GetMinimumValue, GetMaximumValue, GetMinimumIncrement,"
         & " and SetCurrentValue");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Selection,
         "live external D-Bus client Selection.GetNSelectedChildren,"
         & " GetSelectedChild, IsChildSelected, SelectChild,"
         & " DeselectChild, SelectAll, and ClearSelection");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Text,
         "live external D-Bus client Text.GetCharacterCount,"
         & " Text.GetCaretOffset, and Text.GetText");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Image,
         "live external D-Bus client Image.GetImageDescription,"
         & " Image.GetImageCaption, Image.GetImageKind,"
         & " and Image.GetImageSize");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Document,
         "live external D-Bus client Document.GetLocale,"
         & " Document.IsLandmark, and Document.GetAttributeValue(title)");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Table,
         "live external D-Bus client Table.GetNRows/GetNColumns,"
         & " GetAccessibleAt, extents, current cell, and sort metadata");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Surface,
         "live external D-Bus client Surface kind, role, and state queries");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Live_Region,
         "live external D-Bus client LiveRegion setting and relevance queries");
      Internal_Map (Linux_ATSPI_Action_Count, "Action.GetNActions");
      Internal_Map (Linux_ATSPI_Action_Name, "Action.GetName");
      Internal_Map (Linux_ATSPI_Action_Invoke, "Action.DoAction request");
      Internal_Map
        (Actions_Activate,
         "AT-SPI Action.DoAction default activation request");
      Internal_Map (Actions_Press, "AT-SPI Action.DoAction press request");
      Internal_Map (Actions_Toggle, "AT-SPI Action.DoAction toggle request");
      Internal_Map (Actions_Expand, "AT-SPI Action.DoAction expand request");
      Internal_Map (Actions_Collapse, "AT-SPI Action.DoAction collapse request");
      Internal_Map
        (Actions_Show_Menu, "AT-SPI Action.DoAction show-menu request");
      Internal_Map (Actions_Dismiss, "AT-SPI Action.DoAction dismiss request");
      Internal_Map
        (Actions_Increment, "AT-SPI Action.DoAction increment request");
      Internal_Map
        (Actions_Decrement, "AT-SPI Action.DoAction decrement request");
      Internal_Map
        (Actions_Select_Item, "AT-SPI Action.DoAction select request");
      Internal_Map
        (Actions_Deselect, "AT-SPI Action.DoAction deselect request");
      Internal_Map
        (Actions_Clear_Selection,
         "AT-SPI Action.DoAction clear-selection request");
      Internal_Map (Actions_Open, "AT-SPI Action.DoAction open request");
      Internal_Map (Actions_Close, "AT-SPI Action.DoAction close request");
      Internal_Map
        (Actions_Scroll_Into_View,
         "AT-SPI Action.DoAction scroll-into-view request");
      Internal_Map
        (Actions_Set_Focus, "AT-SPI Action.DoAction set-focus request");
      Internal_Map (Actions_Metadata, "common action metadata for names");
      Internal_Map
        (Actions_Preconditions,
         "common action precondition validation");
      Internal_Map (Linux_ATSPI_Value_Current, "Value.CurrentValue");
      Internal_Map (Linux_ATSPI_Value_Range, "Value.MinimumValue/MaximumValue");
      Internal_Map
        (Linux_ATSPI_Value_Set_Request, "Value.SetCurrentValue request");
      Internal_Map
        (Value_Resource_Limit, "bounded value metadata validation");
      Internal_Map
        (Value_Precision_Loss,
         "lossless native floating-point value conversion");
      Add_Common_Value_Declarations
        (Items,
         "AT-SPI",
         "AT-SPI Value interface conversion from typed semantic values",
         "linux");
      Internal_Map
        (Linux_ATSPI_Selection_Count, "Selection.GetNSelectedChildren");
      Internal_Map
        (Linux_ATSPI_Selection_Selected_Child,
         "Selection.GetSelectedChild");
      Internal_Map
        (Linux_ATSPI_Selection_Request, "Selection selection requests");
      Internal_Map
        (Selection_Range,
         "common stable-identity range selection validation");
      Internal_Map
        (Selection_Direction,
         "common anchor-to-current selection direction metadata");
      Internal_Map
        (Selection_Select_All,
         "Selection.SelectAll and common select-all validation");
      Internal_Map
        (Selection_Validation, "bounded selection snapshot validation");
      Internal_Map (Linux_ATSPI_Text_Character_Count, "Text.CharacterCount");
      Internal_Map (Linux_ATSPI_Text_Range, "Text.GetText");
      Internal_Map (Linux_ATSPI_Text_Caret, "Text.CaretOffset");
      Internal_Map (Linux_ATSPI_Text_Protected, "Text protected redaction");
      Internal_Map
        (Text_Edit_Request, "validated semantic text edit requests");
      Internal_Map
        (Linux_ATSPI_Text_Edit_Request,
         "EditableText.InsertText/DeleteText/SetTextContents request");
      Internal_Map (Linux_ATSPI_Table_Dimensions, "Table row/column count");
      Internal_Map (Linux_ATSPI_Table_Cell, "Table.GetAccessibleAt");
      Internal_Map (Linux_ATSPI_Table_Cell_Span, "TableCell row/column span");
      Internal_Map (Linux_ATSPI_Table_Current_Cell, "Table.GetCurrentCell");
      Internal_Map
        (Linux_ATSPI_Table_Sort_Metadata, "Table.GetSortOrder/GetSortKey");
      Internal_Map (Table_Current_Cell, "common stable current-cell metadata");
      Internal_Map (Table_Sort_Metadata, "common stable sort metadata");
      Internal_Map (Table_Resource_Limit, "bounded table cell materialization");
      Internal_Map (Linux_ATSPI_Image_Description, "Image.GetImageDescription");
      Internal_Map (Image_Caption, "Image.GetImageCaption");
      Internal_Map (Image_Category, "Image.GetImageKind");
      Internal_Map (Linux_ATSPI_Image_Size, "Image.GetImageSize");
      Internal_Map
        (Linux_ATSPI_Image_Decorative_Omission, "tree exposure policy");
      Internal_Map (Image_Resource_Limit, "bounded image metadata text");
      Internal_Map (Linux_ATSPI_Document_Locale, "Document locale attribute");
      Internal_Map
        (Core_Property_Locale,
         "Application.GetLocale and Document.GetLocale");
      Internal_Map
        (Core_Property_Orientation,
         "orientation semantic metadata");
      Internal_Map
        (Core_Property_Set_Position,
         "set position semantic metadata");
      Internal_Map
        (Core_Property_Set_Size,
         "set size semantic metadata");
      Internal_Map
        (Core_Property_Hierarchical_Level,
         "hierarchical level semantic metadata");
      Internal_Map (Linux_ATSPI_Document_Attributes, "Document attributes");
      Internal_Map
        (Linux_ATSPI_Document_Heading_Level,
         "Document heading-level attribute");
      Internal_Map (Linux_ATSPI_Document_Landmark, "Document landmark metadata");
      Internal_Map
        (Core_Property_Heading_Level,
         "Document heading-level attribute");
      Internal_Map
        (Core_Property_Landmark,
         "Document landmark metadata");
      Internal_Map (Document_Resource_Limit, "bounded document metadata text");
      Internal_Map (Linux_ATSPI_Surface_Metadata, "role/state surface metadata");
      Internal_Map (Window_Surface_Kind_Name, "Surface.GetSurfaceKind");
      Internal_Map
        (Linux_ATSPI_Surface_Routing,
         "Surface kind/role/state/modality method routing");
      Internal_Map
        (Window_Surface_State_Metadata,
         "surface state flag metadata");
      Internal_Map (Window_Surface_Validation, "surface state validation");
      Internal_Map (Linux_ATSPI_Signal_Focus, "object:state-changed:focused");
      Internal_Map (Linux_ATSPI_Signal_Text, "object:text-changed");
      Internal_Map (Linux_ATSPI_Signal_Lifecycle, "object:children-changed");
      Internal_Map
        (Linux_ATSPI_Signal_Prepared_Publication,
         "prepared native publication to AT-SPI signal handoff");
      Internal_Map (Linux_ATSPI_Cache_Node, "Cache node projection");
      Internal_Map
        (Native_Object_Cache_Identity,
         "stable semantic identity to native object identity registry");
      Internal_Map
        (Linux_ATSPI_Object_Registry,
         "stable object-path to native object registry");
      Internal_Map
        (Native_Object_Export_Descriptor,
         "backend-private native object export descriptor");
      Internal_Map
        (Linux_ATSPI_Object_Export_Descriptor,
         "SDK-free D-Bus object export descriptor");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Traversal,
         "live external D-Bus client traversal of registered AT-SPI root, "
         & "child metadata, and protected-value suppression");
      Exact_Map
        (Linux_ATSPI_Live_External_Client_Registered_Transport,
         "live external D-Bus client traversal paired with observed provider "
         & "transport registration completion");
      Internal_Map
        (Linux_ATSPI_Live_External_Client_Failure_Stage,
         "external-client probe failure-stage diagnostics");
      Internal_Map
        (Native_Readiness_Boundary_Stage,
         "aggregate native readiness boundary-stage classifier");
      Internal_Map
        (Native_Readiness_Remaining_Evidence,
         "aggregate native readiness remaining-evidence classifier");

      return Items;
   end Linux_ATSPI_Declarations;

   function Windows_UIA_Declarations return Declaration_Vectors.Vector is
      Items : Declaration_Vectors.Vector;

      procedure Internal_Map
        (Feature : Feature_Id;
         Mapping : String) is
      begin
         Add
           (Items,
            Feature,
            "UIA",
            Internal_Only,
            Native_Mapping => Mapping,
            Test_Id => Dotted_Name (Feature) & ".windows");
      end Internal_Map;
   begin
      declare
         type Feature_List is array (Positive range <>) of Feature_Id;
         Evidence : constant Feature_List :=
           [Core_Role_Application,
            Core_Role_Window,
            Core_Role_Dialog,
            Core_Role_Group,
            Core_Role_Region,
            Core_Role_Static_Text,
            Core_Role_Button,
            Core_Role_Text_Field,
            Core_Role_Toggle_Button,
            Core_Role_Check_Box,
            Core_Role_Radio_Button,
            Core_Role_Progress_Bar,
            Core_Role_Spin_Button,
            Core_Role_Slider,
            Core_Role_List,
            Core_Role_List_Item,
            Core_Role_Tree,
            Core_Role_Tree_Item,
            Core_Role_Table,
            Core_Role_Row,
            Core_Role_Column,
            Core_Role_Cell,
            Core_Role_Combo_Box,
            Core_Role_Search_Field,
            Core_Role_Menu_Bar,
            Core_Role_Menu,
            Core_Role_Menu_Item,
            Core_Role_Tool_Bar,
            Core_Role_Tab_List,
            Core_Role_Tab,
            Core_Role_Tooltip,
            Core_Role_Heading,
            Core_Role_Document,
            Core_Role_Text,
            Core_Role_Link,
            Core_Role_Password_Field,
            Core_Role_Scroll_Bar,
            Core_Role_Separator,
            Core_Role_Alert,
            Core_Role_Popup_Dialog,
            Core_Role_Canvas,
            Core_Role_Custom,
            Value_Range,
            Selection_Single,
            Relations_Active_Descendant,
            Relations_Labelled_By,
            Relations_Label_For,
            Relations_Described_By,
            Relations_Description_For,
            Relations_Controlled_By,
            Relations_Controller_For,
            Relations_Flows_To,
            Relations_Flows_From,
            Relations_Member_Of,
            Relations_Details,
            Relations_Details_For,
            Selection_Current_Item,
            Text_Range_Basic,
            Table_Cell_Basic,
            Image_Alternative_Text,
            Document_Heading_Level,
            Text_Protected,
            Events_Live_Region_Changed,
            Relations_Error_Message,
            Relations_Error_For,
            Relations_Embedded_By,
            Relations_Embeds,
            Relations_Popup_For,
            Relations_Popup_Controlled_By,
            Lifecycle_Stale_Reference,
            Backend_Transport_Unavailable,
            Native_Fixture_Root_Child_Traversal,
            Native_Fixture_Root_Child_Count,
            Native_Fixture_Root_Second_Child,
            Native_Fixture_Child_Query,
            Native_Fixture_Child_Native_Object,
            Native_Fixture_Child_Parent_Navigation,
            Native_Fixture_Child_Native_Identity,
            Native_Fixture_Second_Child_Parent_Navigation,
            Native_Fixture_Second_Child_Native_Identity,
            Native_Fixture_Sibling_Order,
            Native_Fixture_Child_Stale_Id,
            Windows_UIA_Host_Window_Root_Binding,
            Windows_UIA_Selection_Select_All,
            Windows_UIA_Selection_Clear_Selection,
            Windows_UIA_COM_VTable_Descriptor,
            Windows_UIA_COM_Object_Export,
            Windows_UIA_COM_Live_Interface_Retain,
            Windows_UIA_COM_Live_Interface_Release,
            Windows_UIA_COM_Live_Released_Interface,
            Windows_UIA_COM_Live_Invalid_Interface_Frame,
            Windows_UIA_COM_Live_Invalid_Method_Frame,
            Windows_UIA_COM_Live_Interface_Method_Mismatch,
            Windows_UIA_COM_Live_Provider_Options,
            Windows_UIA_COM_Live_Host_Raw_Element_Provider,
            Windows_UIA_COM_Live_Pattern_Provider_Frame,
            Windows_UIA_COM_Live_Simple_Property_Frame,
            Windows_UIA_COM_Live_Bounding_Rectangle_Frame,
            Windows_UIA_COM_Live_Fragment_Action_Frame,
            Windows_UIA_COM_Live_Fragment_Navigate,
            Windows_UIA_COM_Live_Fragment_Last_Child_Frame,
            Windows_UIA_COM_Live_Fragment_Runtime_Id,
            Windows_UIA_COM_Live_Embedded_Fragment_Roots,
            Windows_UIA_COM_Live_Fragment_Root,
            Windows_UIA_COM_Live_Fragment_Root_Point,
            Windows_UIA_COM_Live_Fragment_Root_Focus];
      begin
         for Feature of Evidence loop
            Internal_Map (Feature, "UIA native-client conformance evidence");
         end loop;
      end;

      Add
        (Items,
         Backend_Native_Scaffold,
         "UIA",
         Internal_Only,
         Native_Mapping => "native runtime scaffold",
         Test_Id => "backend.native.scaffold.windows");
      Add
        (Items,
         Backend_Native_Target_Resolution,
         "UIA",
         Internal_Only,
         Native_Mapping => "host platform to UIA backend target",
         Test_Id => "backend.native.target_resolution.windows");
      Add
        (Items,
         Backend_Selection_Runtime_Override,
         "UIA",
         Internal_Only,
         Native_Mapping => "common runtime backend override constructor",
         Test_Id => "backend.selection.runtime_override.windows");
      Add
        (Items,
         Backend_Selection_Fallback,
         "UIA",
         Internal_Only,
         Native_Mapping => "common runtime backend override fallback classification",
         Test_Id => "backend.selection.fallback.windows");
      Add
        (Items,
         Backend_Native_Transport_Admission,
         "UIA",
         Internal_Only,
         Native_Mapping => "adapter-facing transport admission snapshot",
         Test_Id => "backend.native.transport_admission.windows");
      Add
        (Items,
         Backend_Native_Transport_Status,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "adapter-facing typed transport state and failure snapshot",
         Test_Id => "backend.native.transport_status.windows");
      Add
        (Items,
         Backend_Native_Transport_Generation,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "adapter-facing monotonic transport snapshot generation",
         Test_Id => "backend.native.transport_generation.windows");
      Add
        (Items,
         Backend_Native_Transport_Transition_Report,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "adapter-facing structured transport transition report",
         Test_Id => "backend.native.transport_transition_report.windows");
      Add
        (Items,
         Backend_Native_Deterministic_Shutdown,
         "UIA",
         Internal_Only,
         Native_Mapping => "adapter-facing deterministic transport shutdown",
         Test_Id => "backend.native.deterministic_shutdown.windows");
      Add
        (Items,
         Native_Runtime_Lifecycle,
         "UIA",
         Internal_Only,
         Native_Mapping => "shared native runtime start, stop, and drained lifecycle",
         Test_Id => "native.runtime.lifecycle.windows");
      Add
        (Items,
         Native_Runtime_Generation,
         "UIA",
         Internal_Only,
         Native_Mapping => "shared native runtime lifecycle generation snapshot",
         Test_Id => "native.runtime.generation.windows");
      Add
        (Items,
         Native_Runtime_Lifecycle_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "shared native runtime lifecycle transition report",
         Test_Id => "native.runtime.lifecycle_report.windows");
      Add
        (Items,
         Native_Runtime_Probe_Failure_Stage,
         "UIA",
         Internal_Only,
         Native_Mapping => "native runtime probe status and failure-stage report",
         Test_Id => "native.runtime.probe_failure_stage.windows");
      Add
        (Items,
         Backend_Native_Publication_Preparation,
         "UIA",
         Internal_Only,
         Native_Mapping => "adapter-facing prepared native publication record",
         Test_Id => "backend.native.publication_preparation.windows");
      Add
        (Items,
         Backend_Diagnostics_Bounded,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded native-backend diagnostic log",
         Test_Id => "backend.diagnostics.bounded.windows");
      Add
        (Items,
         Diagnostics_Result_Mapping,
         "UIA",
         Internal_Only,
         Native_Mapping => "structured result-to-diagnostic category mapping",
         Test_Id => "diagnostics.result_mapping.windows");
      Add
        (Items,
         Diagnostics_Field_Bounds,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "bounded diagnostic field, identifier, and record-retention validation",
         Test_Id => "diagnostics.field_bounds.windows");
      Add
        (Items,
         Diagnostics_Localization,
         "UIA",
         Internal_Only,
         Native_Mapping => "message-catalog-backed diagnostic/status labels",
         Test_Id => "diagnostics.localization.windows");
      Add
        (Items,
         Native_Runtime_Event_Application,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "committed semantic event application, direct defunct ledgering, " &
           "bounded tombstone eviction, and stale destroyed-node rejection",
         Test_Id => "native.runtime.event_application.windows");
      Add
        (Items,
         Core_Node_Key_Registry,
         "UIA",
         Internal_Only,
         Native_Mapping => "stable application key to Node_Id registry",
         Test_Id => "core.node_key.registry.windows");
      Add
        (Items,
         Core_Geometry_Visibility,
         "UIA",
         Internal_Only,
         Native_Mapping => "logical desktop clipping before UIA projection",
         Test_Id => "core.geometry.visibility.windows");
      Add
        (Items,
         Core_Geometry_Region,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded logical desktop region before UIA projection",
         Test_Id => "core.geometry.region.windows");
      Add
        (Items,
         Core_Provider_Contract,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "central provider role/state/capability contract validation",
         Test_Id => "core.provider.contract.windows");
      Add_Common_Capability_Declarations
        (Items,
         "UIA",
         "UIA pattern exposure from central semantic capability set",
         "windows");
      Add
        (Items,
         Core_Role_Image,
         "UIA",
         Internal_Only,
         Native_Mapping => "UIA Image control type through central role map",
         Test_Id => "core.role.image.windows");
      Add
        (Items,
         Core_Role_Status,
         "UIA",
         Internal_Only,
         Native_Mapping => "UIA StatusBar/text live-region role projection",
         Test_Id => "core.role.status.windows");
      Add
        (Items,
         Core_Role_Decorative_Image,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "decorative semantic image omission before UIA exposure",
         Test_Id => "core.role.decorative_image.windows");
      Add
        (Items,
         Core_State_Derivation,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "central role/capability-derived effective state normalization",
         Test_Id => "core.state.derivation.windows");
      Add_Common_State_Declarations
        (Items,
         "UIA",
         "UIA property projection from central semantic state map",
         "windows");
      Add
        (Items,
         Events_Live_Region,
         "UIA",
         Internal_Only,
         Native_Mapping => "LiveSetting and notification event validation",
         Test_Id => "events.live_region.windows");
      Add
        (Items,
         Events_Classification,
         "UIA",
         Internal_Only,
         Native_Mapping => "central semantic event-family classification",
         Test_Id => "events.classification.windows");
      declare
         Event_Kinds : constant array (Positive range <>) of Feature_Id :=
           [Events_Node_Created,
            Events_Node_Attached,
            Events_Node_Detached,
            Events_Child_Added,
            Events_Child_Removed,
            Events_Children_Reordered,
            Events_Subtree_Rebuilt,
            Events_Property_Changed,
            Events_State_Changed,
            Events_Bounds_Changed,
            Events_Focus_Changed,
            Events_Active_Descendant_Changed,
            Events_Selection_Changed,
            Events_Current_Item_Changed,
            Events_Value_Changed,
            Events_Range_Changed,
            Events_Text_Inserted,
            Events_Text_Removed,
            Events_Text_Replaced,
            Events_Caret_Moved,
            Events_Text_Selection_Changed,
            Events_Text_Attributes_Changed,
            Events_Row_Inserted,
            Events_Row_Removed,
            Events_Column_Inserted,
            Events_Column_Removed,
            Events_Cell_Changed,
            Events_Window_Opened,
            Events_Window_Closed,
            Events_Window_Activated,
            Events_Window_Deactivated,
            Events_Document_Loaded,
            Events_Document_Closed,
            Events_Announcement_Requested,
            Events_Relation_Added,
            Events_Relation_Removed,
            Events_Relation_Targets_Changed,
            Events_Node_Destroyed];
      begin
         for Feature of Event_Kinds loop
            Internal_Map
              (Feature,
               "central semantic event-kind validation and UIA event mapping");
         end loop;
      end;
      Add
        (Items,
         Events_Envelope,
         "UIA",
         Internal_Only,
         Native_Mapping => "central semantic event envelope validation",
         Test_Id => "events.envelope.windows");
      Add
        (Items,
         Events_Timestamp_Order,
         "UIA",
         Internal_Only,
         Native_Mapping => "event queue nondecreasing committed timestamp order",
         Test_Id => "events.timestamp_order.windows");
      Add
        (Items,
         Events_Live_Region_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed live-region change and announcement payload validation",
         Test_Id => "events.live_region.payload.windows");
      Add
        (Items,
         Live_Region_Metadata,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "LiveSetting, atomicity, and announcement policy metadata",
         Test_Id => "live_region.metadata.windows");
      Add
        (Items,
         Live_Region_Relevance,
         "UIA",
         Internal_Only,
         Native_Mapping => "stable live-region relevance strings",
         Test_Id => "live_region.relevance.windows");
      Add
        (Items,
         Live_Region_Backend_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "bounded UIA live-region query mapper and provider-boundary routing",
         Test_Id => "live_region.backend_routing.windows");
      Add
        (Items,
         Events_Text_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed text mutation event payload and record validation",
         Test_Id => "events.text.payload.windows");
      Add
        (Items,
         Events_Property_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed property-change event payload validation",
         Test_Id => "events.property.payload.windows");
      Add
        (Items,
         Events_Property_Orientation,
         "UIA",
         Internal_Only,
         Native_Mapping => "Orientation property-change notification",
         Test_Id => "events.property.orientation.windows");
      Add
        (Items,
         Events_Property_Set_Position,
         "UIA",
         Internal_Only,
         Native_Mapping => "PositionInSet property-change notification",
         Test_Id => "events.property.set_position.windows");
      Add
        (Items,
         Events_Property_Set_Size,
         "UIA",
         Internal_Only,
         Native_Mapping => "SizeOfSet property-change notification",
         Test_Id => "events.property.set_size.windows");
      Add
        (Items,
         Events_Property_Hierarchical_Level,
         "UIA",
         Internal_Only,
         Native_Mapping => "Level property-change notification",
         Test_Id => "events.property.hierarchical_level.windows");
      Add
        (Items,
         Events_State_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed state-change event payload validation",
         Test_Id => "events.state.payload.windows");
      Add
        (Items,
         Events_Relation_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed relation-change event payload and inverse validation",
         Test_Id => "events.relation.payload.windows");
      Add
        (Items,
         Events_Bounds_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed bounds-change event payload validation",
         Test_Id => "events.bounds.payload.windows");
      Add
        (Items,
         Events_Focus_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed focus-change event payload validation",
         Test_Id => "events.focus.payload.windows");
      Add
        (Items,
         Events_Node_Reference_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed active-descendant/current-item event payload validation",
         Test_Id => "events.node_reference.payload.windows");
      Add
        (Items,
         Events_Value_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed value/range event payload validation",
         Test_Id => "events.value.payload.windows");
      Add
        (Items,
         Events_Selection_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed item and invalidation selection payload validation",
         Test_Id => "events.selection.payload.windows");
      Add
        (Items,
         Events_Session_Notification,
         "UIA",
         Internal_Only,
         Native_Mapping => "validated provider semantic event notification",
         Test_Id => "events.session.notification.windows");
      Add
        (Items,
         Events_Backend_Pump_Report,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "structured common session-to-backend event pump report",
         Test_Id => "events.backend_pump_report.windows");
      Add
        (Items,
         Events_Subscription_Filter,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded backend event subscription filters",
         Test_Id => "events.subscription.filter.windows");
      Add
        (Items,
         Events_Subscription_Bounds,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded backend event fan-out admission",
         Test_Id => "events.subscription.bounds.windows");
      Add
        (Items,
         Tree_Attachment_Validation,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "attachment validation before event-capacity preflight",
         Test_Id => "tree.attachment.validation.windows");
      Add
        (Items,
         Tree_Exposure_Projection,
         "UIA",
         Internal_Only,
         Native_Mapping => "central semantic exposure projection",
         Test_Id => "tree.exposure.projection.windows");
      Add
        (Items,
         Tree_Mutation_Event_Order,
         "UIA",
         Internal_Only,
         Native_Mapping => "committed tree mutation event ordering",
         Test_Id => "tree.mutation.event_order.windows");
      Add
        (Items,
         Events_Tree_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed child and aggregate tree event payload validation",
         Test_Id => "events.tree.payload.windows");
      Add
        (Items,
         Events_Table_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "typed table row/column/cell event payload family validation",
         Test_Id => "events.table.payload.windows");
      Add
        (Items,
         Events_Document_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed document lifecycle event payload validation",
         Test_Id => "events.document.payload.windows");
      Add
        (Items,
         Events_Window_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed window and surface event payload validation",
         Test_Id => "events.window.payload.windows");
      Add
        (Items,
         Native_Runtime_Event_Preparation,
         "UIA",
         Internal_Only,
         Native_Mapping => "atomic runtime event to native object preparation",
         Test_Id => "native.runtime.event_preparation.windows");
      Add
        (Items,
         Native_Runtime_Event_Preparation_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "structured runtime event-preparation report",
         Test_Id => "native.runtime.event_preparation_report.windows");
      Add
        (Items,
         Native_Projection_Property,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before UIA property projection",
         Test_Id => "native.projection.property.windows");
      Add
        (Items,
         Native_Projection_Action,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before UIA action projection",
         Test_Id => "native.projection.action.windows");
      Add
        (Items,
         Native_Request_Action_Payload,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "routed action-request payload retains neutral Action_Id",
         Test_Id => "native.request.action_payload.windows");
      Add
        (Items,
         Native_Projection_Relation,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before UIA relation projection",
         Test_Id => "native.projection.relation.windows");
      Add
        (Items,
         Native_Projection_Event_Source,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before UIA event projection",
         Test_Id => "native.projection.event_source.windows");
      Add
        (Items,
         Native_Event_Validation,
         "UIA",
         Internal_Only,
         Native_Mapping => "UIA event emission validation",
         Test_Id => "native.event.validation.windows");
      Add
        (Items,
         Native_Event_Prepared_Status,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "prepared native publication status handoff before UIA object mapping",
         Test_Id => "native.event.prepared_status.windows");
      Add
        (Items,
         Native_Event_Staging_Queue,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded UIA event-emission FIFO",
         Test_Id => "windows.uia.event_queue.router");
      Add
        (Items,
         Native_Event_Posting_Interest,
         "UIA",
         Internal_Only,
         Native_Mapping => "UIA event queue posting-interest snapshot",
         Test_Id => "windows.uia.event_queue_interest.router");
      Add
        (Items,
         Native_Event_Posting_Boundary,
         "UIA",
         Internal_Only,
         Native_Mapping => "UIA event posting boundary validation",
         Test_Id => "windows.uia.event_posting_boundary.router");
      Add
        (Items,
         Native_Event_Exhaustive_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "semantic event kind to UIA event category map",
         Test_Id => "native.event.exhaustive_map.windows");
      Add
        (Items,
         Native_Role_Exhaustive_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "semantic role to UIA ControlType map",
         Test_Id => "native.role.exhaustive_map.windows");
      Add
        (Items,
         Native_Relation_Exhaustive_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "semantic relation to UIA relation property map",
         Test_Id => "native.relation.exhaustive_map.windows");
      Add
        (Items,
         Native_Object_Cache_Node_Index,
         "UIA",
         Internal_Only,
         Native_Mapping => "indexed Node_Id to native object cache lookup",
         Test_Id => "native.object_cache.node_index.windows");
      Add
        (Items,
         Native_Object_Cache_Tombstone,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded stale native provider tombstones",
         Test_Id => "native.object_cache.tombstone.windows");
      Add
        (Items,
         Native_Object_Cache_Session_Scope,
         "UIA",
         Internal_Only,
         Native_Mapping => "backend-session-scoped provider identities",
         Test_Id => "native.object_cache.session_scope.windows");
      Add
        (Items,
         Native_Object_Cache_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded native object cache",
         Test_Id => "native.object_cache.resource_limit.windows");
      Add
        (Items,
         Native_Object_Cache_Generation,
         "UIA",
         Internal_Only,
         Native_Mapping => "monotonic native object cache mutation generation",
         Test_Id => "native.object_cache.generation.windows");
      Add
        (Items,
         Native_Object_Cache_Mutation_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "shared native object-cache mutation report",
         Test_Id => "native.object_cache.mutation_report.windows");
      Add
        (Items,
         Native_Object_Registry_Generation,
         "UIA",
         Internal_Only,
         Native_Mapping => "monotonic native provider registry mutation generation",
         Test_Id => "native.object_registry.generation.windows");
      Add
        (Items,
         Native_Object_Registry_Drained_Reset,
         "UIA",
         Internal_Only,
         Native_Mapping => "drained-aware native provider registry reset",
         Test_Id => "native.object_registry.drained_reset.windows");
      Add
        (Items,
         Native_Object_Registry_Mutation_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "structured UIA provider registry mutation reports",
         Test_Id => "native.object_registry.mutation_report.windows");
      Add
        (Items,
         Native_Object_Lifetime_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded COM provider reference count",
         Test_Id => "native.object_lifetime.resource_limit.windows");
      Add
        (Items,
         Native_Value_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded BSTR and SAFEARRAY values",
         Test_Id => "windows.uia.native_values.resource_limit.router");
      Add
        (Items,
         Native_Callback_Gate,
         "UIA",
         Internal_Only,
         Native_Mapping => "native callback admission and reset guard",
         Test_Id => "native.callback.gate.windows");
      Add
        (Items,
         Native_Callback_Generation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native callback gate lifecycle generation snapshot",
         Test_Id => "native.callback.generation.windows");
      Add
        (Items,
         Native_Boundary_Call_Context,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary object-call context",
         Test_Id => "native.boundary.call_context.windows");
      Add
        (Items,
         Native_Boundary_Call_Kind,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary dispatcher call-kind and failure-context snapshot",
         Test_Id => "native.boundary.call_kind.windows");
      Add
        (Items,
         Native_Boundary_Native_Call_Report,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "provider registry begin/end native-call mutation reports",
         Test_Id => "native.boundary.native_call_report.windows");
      Add
        (Items,
         Native_Boundary_Return_Class,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary structured return classification",
         Test_Id => "native.boundary.return_class.windows");
      Add
        (Items,
         Native_Boundary_Status_Recording,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary provider-status recording",
         Test_Id => "native.boundary.status_recording.windows");
      Add
        (Items,
         Native_Boundary_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary cancellation propagation",
         Test_Id => "native.boundary.cancellation.windows");
      Add
        (Items,
         Native_Boundary_Query_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary property and geometry query cancellation",
         Test_Id => "native.boundary.query_cancellation.windows");
      Add
        (Items,
         Native_Boundary_Tree_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary tree-navigation cancellation",
         Test_Id => "native.boundary.tree_cancellation.windows");
      Add
        (Items,
         Native_Boundary_Component_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary component geometry cancellation",
         Test_Id => "native.boundary.component_cancellation.windows");
      Add
        (Items,
         Dispatcher_Call_Metadata,
         "UIA",
         Internal_Only,
         Native_Mapping => "dispatcher call-kind timeout metadata",
         Test_Id => "dispatcher.call.metadata.windows");
      Add
        (Items,
         Dispatcher_Timeout_Classification,
         "UIA",
         Internal_Only,
         Native_Mapping => "dispatcher elapsed-time timeout classification",
         Test_Id => "dispatcher.timeout.classification.windows");
      Add
        (Items,
         Dispatcher_Call_Accounting,
         "UIA",
         Internal_Only,
         Native_Mapping => "dispatcher call-kind bounded accounting",
         Test_Id => "dispatcher.call.accounting.windows");
      Add
        (Items,
         Dispatcher_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "dispatcher cancellation token policy",
         Test_Id => "dispatcher.cancellation.windows");
      Add
        (Items,
         Dispatcher_Reentrancy,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "dispatcher reentrant rejection and explicit inline fast path",
         Test_Id => "dispatcher.reentrancy.windows");
      Add
        (Items,
         Native_Boundary_Action_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary action-call dispatcher",
         Test_Id => "native.boundary.action_call.windows");
      Add
        (Items,
         Native_Boundary_Node_Action_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary existing-node action dispatcher",
         Test_Id => "native.boundary.node_action_call.windows");
      Add
        (Items,
         Native_Boundary_Query_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary property-query dispatcher",
         Test_Id => "native.boundary.query_call.windows");
      Add
        (Items,
         Native_Boundary_Node_Query_Call,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node property-query dispatcher",
         Test_Id => "native.boundary.node_query_call.windows");
      Add
        (Items,
         Native_Boundary_Tree_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary tree-navigation dispatcher",
         Test_Id => "native.boundary.tree_call.windows");
      Add
        (Items,
         Native_Boundary_Node_Tree_Call,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node tree-navigation dispatcher",
         Test_Id => "native.boundary.node_tree_call.windows");
      Add
        (Items,
         Native_Boundary_Component_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary component geometry dispatcher",
         Test_Id => "native.boundary.component_call.windows");
      Add
        (Items,
         Native_Boundary_Node_Component_Call,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node component geometry dispatcher",
         Test_Id => "native.boundary.node_component_call.windows");
      Add
        (Items,
         Native_Boundary_Focus_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary focus query/action dispatcher",
         Test_Id => "native.boundary.focus_call.windows");
      Add
        (Items,
         Native_Boundary_Node_Focus_Call,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node focus query/action dispatcher",
         Test_Id => "native.boundary.node_focus_call.windows");
      Add
        (Items,
         Native_Boundary_Focus_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary focus query/action cancellation",
         Test_Id => "native.boundary.focus_cancellation.windows");
      Add
        (Items,
         Core_Focus_Session,
         "UIA",
         Internal_Only,
         Native_Mapping => "session-owned focus state and events",
         Test_Id => "core.focus.session.windows");
      Add
        (Items,
         Native_Boundary_Relation_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary relation query dispatcher",
         Test_Id => "native.boundary.relation_call.windows");
      Add
        (Items,
         Native_Boundary_Node_Relation_Call,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node relation query dispatcher",
         Test_Id => "native.boundary.node_relation_call.windows");
      Add
        (Items,
         Native_Boundary_Relation_Cancellation,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary relation query cancellation",
         Test_Id => "native.boundary.relation_cancellation.windows");
      Add
        (Items,
         Native_Boundary_Node_Call,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary existing-node callback admission",
         Test_Id => "native.boundary.node_call.windows");
      Add
        (Items,
         Native_Boundary_Stale_Metadata,
         "UIA",
         Internal_Only,
         Native_Mapping => "native boundary stale object metadata preservation",
         Test_Id => "native.boundary.stale_metadata.windows");
      Add
        (Items,
         Native_Boundary_Error_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "structured status to HRESULT mapping",
         Test_Id => "native.boundary.error_map.windows");
      Add
        (Items,
         Native_Boundary_Identity_Admission,
         "UIA",
         Internal_Only,
         Native_Mapping => "runtime-id component admission before routing",
         Test_Id => "native.boundary.identity_admission.windows");
      Add
        (Items,
         Native_Boundary_Request_Admission,
         "UIA",
         Internal_Only,
         Native_Mapping => "COM provider-interface request admission before routing",
         Test_Id => "native.boundary.request_admission.windows");
      Add
        (Items,
         Native_Boundary_Admission_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "runtime-id component admission report",
         Test_Id => "native.boundary.admission_report.windows");
      Add
        (Items,
         Native_Boundary_Completion_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "runtime-id component completion report",
         Test_Id => "native.boundary.completion_report.windows");
      Add
        (Items,
         Native_Boundary_Release_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "runtime-id component release report",
         Test_Id => "native.boundary.release_report.windows");
      Add
        (Items,
         Native_Fixture_Root_Query,
         "UIA",
         Internal_Only,
         Native_Mapping => "fixture application root query through UIA provider boundary",
         Test_Id => "native.fixture_root.query.windows");
      Add
        (Items,
         Native_Fixture_Root_Failure_Stage,
         "UIA",
         Internal_Only,
         Native_Mapping => "fixture-root probe status and failure-stage report",
         Test_Id => "native.fixture_root.failure_stage.windows");
      Add
        (Items,
         Windows_UIA_Control_Type,
         "UIA",
         Internal_Only,
         Native_Mapping => "ControlType",
         Test_Id => "windows.uia.control_type.compile");
      Add
        (Items,
         Windows_UIA_Core_Properties,
         "UIA",
         Internal_Only,
         Native_Mapping => "core provider properties",
         Test_Id => "windows.uia.core_properties.compile");
      Add
        (Items,
         Windows_UIA_Bounding_Rectangle,
         "UIA",
         Internal_Only,
         Native_Mapping => "BoundingRectangle property",
         Test_Id => "windows.uia.bounding_rectangle.router");
      Add
        (Items,
         Core_Property_Bounds,
         "UIA",
         Internal_Only,
         Native_Mapping => "BoundingRectangle property",
         Test_Id => "core.property.bounds.windows.router");
      Add
        (Items,
         Core_Property_Role,
         "UIA",
         Internal_Only,
         Native_Mapping => "ControlType property",
         Test_Id => "core.property.role.windows.router");
      Add
        (Items,
         Core_Property_State_Set,
         "UIA",
         Internal_Only,
         Native_Mapping => "state-derived UIA properties",
         Test_Id => "core.property.state_set.windows.router");
      Add
        (Items,
         Windows_UIA_Textual_Properties,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "Name, AutomationId, HelpText, description, placeholder, and shortcut properties",
         Test_Id => "windows.uia.textual_properties.router");
      Add
        (Items,
         Core_Property_Placeholder,
         "UIA",
         Internal_Only,
         Native_Mapping => "PlaceholderText property",
         Test_Id => "core.property.placeholder.windows.router");
      Add
        (Items,
         Core_Property_Name,
         "UIA",
         Internal_Only,
         Native_Mapping => "Name property",
         Test_Id => "core.property.name.windows.router");
      Add
        (Items,
         Core_Property_Help_Text,
         "UIA",
         Internal_Only,
         Native_Mapping => "HelpText property",
         Test_Id => "core.property.help_text.windows.router");
      Add
        (Items,
         Core_Property_Description,
         "UIA",
         Internal_Only,
         Native_Mapping => "FullDescription property",
         Test_Id => "core.property.description.windows.router");
      Add
        (Items,
         Core_Property_Value_Text,
         "UIA",
         Internal_Only,
         Native_Mapping => "Value text property",
         Test_Id => "core.property.value_text.windows.router");
      Add
        (Items,
         Core_Property_Semantic_Identifier,
         "UIA",
         Internal_Only,
         Native_Mapping => "AutomationId property",
         Test_Id => "core.property.semantic_identifier.windows.router");
      Add
        (Items,
         Core_Property_Keyboard_Shortcut,
         "UIA",
         Internal_Only,
         Native_Mapping => "AcceleratorKey/AccessKey property",
         Test_Id => "core.property.keyboard_shortcut.windows.router");
      Add
        (Items,
         Core_Property_Typed_Results,
         "UIA",
         Internal_Only,
         Native_Mapping => "portable typed property result records",
         Test_Id => "core.property.typed_results.windows.semantic");
      Add
        (Items,
         Core_Property_Status_Mapping,
         "UIA",
         Internal_Only,
         Native_Mapping => "common result-to-property-status classification",
         Test_Id => "core.property.status_mapping.windows.semantic");
      Add
        (Items,
         Core_State_Validation,
         "UIA",
         Internal_Only,
         Native_Mapping => "common state snapshot validation",
         Test_Id => "core.state.validation.windows.router");
      Add
        (Items,
         Windows_UIA_Metadata_Properties,
         "UIA",
         Internal_Only,
         Native_Mapping => "metadata-backed Name/HelpText/Placeholder/Value properties",
         Test_Id => "windows.uia.metadata_properties.router");
      Add
        (Items,
         Windows_UIA_Protected_Value_Text,
         "UIA",
         Internal_Only,
         Native_Mapping => "Permission_Denied for protected value text",
         Test_Id => "windows.uia.protected_value_text.router");
      Add
        (Items,
         Windows_UIA_Unsupported_Value,
         "UIA",
         Internal_Only,
         Native_Mapping => "UIA not-supported sentinel",
         Test_Id => "windows.uia.unsupported_value.compile");
      Add
        (Items,
         Windows_UIA_Action_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "provider pattern operations",
         Test_Id => "windows.uia.action_map.compile");
      Add
        (Items,
         Windows_UIA_Pattern_Discovery,
         "UIA",
         Internal_Only,
         Native_Mapping => "capability-derived GetPatternProvider result",
         Test_Id => "windows.uia.pattern_discovery.router");
      Add
        (Items,
         Windows_UIA_Action_Request,
         "UIA",
         Internal_Only,
         Native_Mapping => "validated UI Automation action request routing",
         Test_Id => "windows.uia.action_request.router");
      Add
        (Items,
         Actions_Activate,
         "UIA",
         Internal_Only,
         Native_Mapping => "Invoke pattern default activation request",
         Test_Id => "actions.activate.windows");
      Add
        (Items,
         Actions_Press,
         "UIA",
         Internal_Only,
         Native_Mapping => "Invoke pattern press request",
         Test_Id => "actions.press.windows");
      Add
        (Items,
         Actions_Toggle,
         "UIA",
         Internal_Only,
         Native_Mapping => "Toggle pattern request",
         Test_Id => "actions.toggle.windows");
      Add
        (Items,
         Actions_Expand,
         "UIA",
         Internal_Only,
         Native_Mapping => "ExpandCollapse pattern expand request",
         Test_Id => "actions.expand.windows");
      Add
        (Items,
         Actions_Collapse,
         "UIA",
         Internal_Only,
         Native_Mapping => "ExpandCollapse pattern collapse request",
         Test_Id => "actions.collapse.windows");
      Add
        (Items,
         Actions_Show_Menu,
         "UIA",
         Internal_Only,
         Native_Mapping => "ExpandCollapse pattern expand request",
         Test_Id => "actions.show_menu.windows");
      Add
        (Items,
         Actions_Dismiss,
         "UIA",
         Internal_Only,
         Native_Mapping => "ExpandCollapse pattern collapse request",
         Test_Id => "actions.dismiss.windows");
      Add
        (Items,
         Actions_Increment,
         "UIA",
         Internal_Only,
         Native_Mapping => "RangeValue or Scroll pattern increment request",
         Test_Id => "actions.increment.windows");
      Add
        (Items,
         Actions_Decrement,
         "UIA",
         Internal_Only,
         Native_Mapping => "RangeValue or Scroll pattern decrement request",
         Test_Id => "actions.decrement.windows");
      Add
        (Items,
         Actions_Select_Item,
         "UIA",
         Internal_Only,
         Native_Mapping => "SelectionItem pattern select request",
         Test_Id => "actions.select.windows");
      Add
        (Items,
         Actions_Deselect,
         "UIA",
         Internal_Only,
         Native_Mapping => "SelectionItem pattern remove-from-selection request",
         Test_Id => "actions.deselect.windows");
      Add
        (Items,
         Actions_Clear_Selection,
         "UIA",
         Internal_Only,
         Native_Mapping => "Selection pattern clear-selection request",
         Test_Id => "actions.clear_selection.windows");
      Add
        (Items,
         Windows_UIA_Set_Focus_Request,
         "UIA",
         Internal_Only,
         Native_Mapping => "IRawElementProviderFragment.SetFocus request",
         Test_Id => "windows.uia.action.set_focus.router");
      Add
        (Items,
         Actions_Set_Focus,
         "UIA",
         Internal_Only,
         Native_Mapping => "IRawElementProviderFragment.SetFocus request",
         Test_Id => "actions.set_focus.windows");
      Add
        (Items,
         Windows_UIA_Open_Action,
         "UIA",
         Internal_Only,
         Native_Mapping => "Invoke pattern open request",
         Test_Id => "windows.uia.action.open.router");
      Add
        (Items,
         Actions_Open,
         "UIA",
         Internal_Only,
         Native_Mapping => "Invoke pattern open request",
         Test_Id => "actions.open.windows");
      Add
        (Items,
         Windows_UIA_Scroll_Into_View_Action,
         "UIA",
         Internal_Only,
         Native_Mapping => "ScrollItem pattern request",
         Test_Id => "windows.uia.action.scroll_into_view.router");
      Add
        (Items,
         Actions_Scroll_Into_View,
         "UIA",
         Internal_Only,
         Native_Mapping => "ScrollItem pattern request",
         Test_Id => "actions.scroll_into_view.windows");
      Add
        (Items,
         Windows_UIA_Close_Action,
         "UIA",
         Internal_Only,
         Native_Mapping => "Window pattern close request",
         Test_Id => "windows.uia.action.close.router");
      Add
        (Items,
         Actions_Close,
         "UIA",
         Internal_Only,
         Native_Mapping => "Window pattern close request",
         Test_Id => "actions.close.windows");
      Add
        (Items,
         Actions_Preconditions,
         "UIA",
         Internal_Only,
         Native_Mapping => "common action precondition validation",
         Test_Id => "actions.preconditions.windows");
      Add
        (Items,
         Windows_UIA_Event_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "UI Automation event categories",
         Test_Id => "windows.uia.event_map.compile");
      Add
        (Items,
         Windows_UIA_Event_Details,
         "UIA",
         Internal_Only,
         Native_Mapping => "property, structure, and window event details",
         Test_Id => "windows.uia.event_details.router");
      Add
        (Items,
         Windows_UIA_Prepared_Event_Emission,
         "UIA",
         Internal_Only,
         Native_Mapping => "prepared native publication to UIA event emission",
         Test_Id => "windows.uia.prepared_event_emission.router");
      Add
        (Items,
         Windows_UIA_Event_Build_Report,
         "UIA",
         Internal_Only,
         Native_Mapping => "structured UIA event build report",
         Test_Id => "windows.uia.event.build_report.router");
      Add
        (Items,
         Windows_UIA_Prepared_Event_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "request-router handoff of prepared native publication records",
         Test_Id => "windows.uia.prepared_event_routing.router");
      Add
        (Items,
         Windows_UIA_Prepared_Event_Boundary,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "provider-boundary handoff of prepared native publication records",
         Test_Id => "windows.uia.prepared_event_boundary.router");
      Add
        (Items,
         Windows_UIA_Event_Posting_Admission,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "bridge-facing bounded event queue dequeue admission",
         Test_Id => "windows.uia.event_posting_admission.router");
      Add
        (Items,
         Windows_UIA_Event_Posting_Report,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "bridge-facing bounded event queue dequeue admission report",
         Test_Id => "windows.uia.event_posting_report.router");
      Add
        (Items,
         Windows_UIA_Event_Posting_Drain_Bounded,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "bridge-facing callback-based bounded event posting drain",
         Test_Id => "windows.uia.event_posting_drain_bounded.router");
      Add
        (Items,
         Events_Subscription_Filter,
         "UIA",
         Internal_Only,
         Native_Mapping => "listener-aware UIA event subscription filter metadata",
         Test_Id => "events.subscription_filter.windows");
      Add
        (Items,
         Events_Subscription_Bounds,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded UIA event subscription and posting interest",
         Test_Id => "events.subscription_bounds.windows");
      Add
        (Items,
         Windows_UIA_Hostile_Callback_Admission,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "hostile native callback admission gate before provider routing",
         Test_Id => "windows.uia.native_callback.hostile_admission.router");
      Add
        (Items,
         Windows_UIA_Missing_Identity,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "missing native identity rejection before provider routing",
         Test_Id => "windows.uia.native_callback.missing_identity.router");
      Add
        (Items,
         Windows_UIA_Mismatched_Identity,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "mismatched native identity rejection before provider routing",
         Test_Id => "windows.uia.native_callback.mismatched_identity.router");
      Add
        (Items,
         Windows_UIA_Malformed_Identity,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "malformed native identity rejection before provider routing",
         Test_Id => "windows.uia.native_callback.malformed_identity.router");
      Add
        (Items,
         Windows_UIA_Text_Payload_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "native text-edit payload limit rejection before provider routing",
         Test_Id => "windows.uia.native_callback.text_payload_limit.router");
      Add
        (Items,
         Windows_UIA_Fragment_Navigation,
         "UIA",
         Internal_Only,
         Native_Mapping => "IRawElementProviderFragment navigation",
         Test_Id => "windows.uia.fragment.navigation.compile");
      Add
        (Items,
         Windows_UIA_Runtime_Id,
         "UIA",
         Internal_Only,
         Native_Mapping => "GetRuntimeId components",
         Test_Id => "windows.uia.runtime_id.compile");
      Add
        (Items,
         Windows_UIA_Relation_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "relation provider properties",
         Test_Id => "windows.uia.relation_routing.router");
      Add
        (Items,
         Relations_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded relation target materialization",
         Test_Id => "relations.resource_limit.windows.router");
      Add
        (Items,
         Relations_Session_Ownership,
         "UIA",
         Internal_Only,
         Native_Mapping => "session-owned relation graph cleanup",
         Test_Id => "relations.session_ownership.windows");
      Add
        (Items,
         Windows_UIA_Value_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Value and RangeValue property routing",
         Test_Id => "windows.uia.value_routing.router");
      Add
        (Items,
         Windows_UIA_Value_Set_Request,
         "UIA",
         Internal_Only,
         Native_Mapping => "RangeValue set request validation",
         Test_Id => "windows.uia.value_set_request.router");
      Add
        (Items,
         Value_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded value metadata validation",
         Test_Id => "value.resource_limit.windows.router");
      Add
        (Items,
         Value_Precision_Loss,
         "UIA",
         Internal_Only,
         Native_Mapping => "lossless native floating-point value conversion",
         Test_Id => "value.precision_loss.windows.router");
      Add_Common_Value_Declarations
        (Items,
         "UIA",
         "UIA Value and RangeValue conversion from typed semantic values",
         "windows");
      Add
        (Items,
         Windows_UIA_Selection_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Selection and SelectionItem property routing",
         Test_Id => "windows.uia.selection_routing.router");
      Add
        (Items,
         Windows_UIA_Selection_Request,
         "UIA",
         Internal_Only,
         Native_Mapping => "Selection and SelectionItem request validation",
         Test_Id => "windows.uia.selection_request.router");
      Add
        (Items,
         Selection_Range,
         "UIA",
         Internal_Only,
         Native_Mapping => "common stable-identity range selection validation",
         Test_Id => "selection.range.windows.router");
      Add
        (Items,
         Selection_Direction,
         "UIA",
         Internal_Only,
         Native_Mapping => "common anchor-to-current selection direction metadata",
         Test_Id => "selection.direction.windows.router");
      Add
        (Items,
         Selection_Select_All,
         "UIA",
         Internal_Only,
         Native_Mapping => "SelectionItem/Selection select-all request staging",
         Test_Id => "selection.select_all.windows.router");
      Add
        (Items,
         Selection_Validation,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded selection snapshot validation",
         Test_Id => "selection.validation.windows.router");
      Add
        (Items,
         Windows_UIA_Text_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Text and TextRange query routing",
         Test_Id => "windows.uia.text_routing.router");
      Add
        (Items,
         Text_Edit_Request,
         "UIA",
         Internal_Only,
         Native_Mapping => "validated semantic text edit requests",
         Test_Id => "text.edit.request.windows.router");
      Add
        (Items,
         Windows_UIA_Text_Edit_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Value/Text edit request routing",
         Test_Id => "windows.uia.text_edit_routing.router");
      Add
        (Items,
         Windows_UIA_Table_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Grid and Table property routing",
         Test_Id => "windows.uia.table_routing.router");
      Add
        (Items,
         Table_Current_Cell,
         "UIA",
         Internal_Only,
         Native_Mapping => "current table cell routing",
         Test_Id => "table.current_cell.windows.router");
      Add
        (Items,
         Table_Sort_Metadata,
         "UIA",
         Internal_Only,
         Native_Mapping => "table sort metadata routing",
         Test_Id => "table.sort.metadata.windows.router");
      Add
        (Items,
         Table_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded table cell materialization",
         Test_Id => "table.resource_limit.windows.router");
      Add
        (Items,
         Windows_UIA_Image_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Image property routing",
         Test_Id => "windows.uia.image_routing.router");
      Add
        (Items,
         Image_Caption,
         "UIA",
         Internal_Only,
         Native_Mapping => "image caption property routing",
         Test_Id => "image.caption.windows.router");
      Add
        (Items,
         Image_Category,
         "UIA",
         Internal_Only,
         Native_Mapping => "image category property routing",
         Test_Id => "image.category.windows.router");
      Add
        (Items,
         Image_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded image metadata properties",
         Test_Id => "image.resource_limit.windows.router");
      Add
        (Items,
         Windows_UIA_Document_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Document metadata property routing",
         Test_Id => "windows.uia.document_routing.router");
      Add
        (Items,
         Core_Property_Locale,
         "UIA",
         Internal_Only,
         Native_Mapping => "Locale property and document locale metadata",
         Test_Id => "core.property.locale.windows.router");
      Add
        (Items,
         Core_Property_Visible_Title,
         "UIA",
         Internal_Only,
         Native_Mapping => "Visible title property",
         Test_Id => "core.property.visible_title.windows.router");
      Add
        (Items,
         Core_Property_Orientation,
         "UIA",
         Internal_Only,
         Native_Mapping => "Orientation property",
         Test_Id => "core.property.orientation.windows.router");
      Add
        (Items,
         Core_Property_Set_Position,
         "UIA",
         Internal_Only,
         Native_Mapping => "PositionInSet property",
         Test_Id => "core.property.set_position.windows.router");
      Add
        (Items,
         Core_Property_Set_Size,
         "UIA",
         Internal_Only,
         Native_Mapping => "SizeOfSet property",
         Test_Id => "core.property.set_size.windows.router");
      Add
        (Items,
         Core_Property_Hierarchical_Level,
         "UIA",
         Internal_Only,
         Native_Mapping => "Level property",
         Test_Id => "core.property.hierarchical_level.windows.router");
      Add
        (Items,
         Core_Property_Heading_Level,
         "UIA",
         Internal_Only,
         Native_Mapping => "HeadingLevel property",
         Test_Id => "core.property.heading_level.windows.router");
      Add
        (Items,
         Core_Property_Landmark,
         "UIA",
         Internal_Only,
         Native_Mapping => "Landmark metadata property",
         Test_Id => "core.property.landmark.windows.router");
      Add
        (Items,
         Document_Resource_Limit,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded document metadata properties",
         Test_Id => "document.resource_limit.windows.router");
      Add
        (Items,
         Windows_UIA_Surface_Routing,
         "UIA",
         Internal_Only,
         Native_Mapping => "Window and Transform property routing",
         Test_Id => "windows.uia.surface_routing.router");
      Add
        (Items,
         Window_Surface_Kind_Name,
         "UIA",
         Internal_Only,
         Native_Mapping => "stable surface kind-name property routing",
         Test_Id => "window.surface.kind_name.windows.router");
      Add
        (Items,
         Window_Surface_State_Metadata,
         "UIA",
         Internal_Only,
         Native_Mapping => "surface state flag metadata",
         Test_Id => "window.surface.state_metadata.windows");
      Add
        (Items,
         Window_Surface_Validation,
         "UIA",
         Internal_Only,
         Native_Mapping => "surface state validation",
         Test_Id => "window.surface.validation.windows.router");
      Add
        (Items,
         Windows_UIA_Request_Router,
         "UIA",
         Internal_Only,
         Native_Mapping => "typed provider request routing",
         Test_Id => "windows.uia.request_router.compile");
      Add
        (Items,
         Windows_UIA_ABI_Surface,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "COM provider method surface to provider-boundary request contract",
         Test_Id => "windows.uia.abi_surface.compile");
      Add
        (Items,
         Windows_UIA_Provider_Boundary,
         "UIA",
         Internal_Only,
         Native_Mapping => "HRESULT provider boundary and payload admission",
         Test_Id => "windows.uia.provider_boundary.compile");
      Add
        (Items,
         Windows_UIA_Bridge_Audit,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "C ABI bridge audit for calling convention, nullability, lifetime, and representation",
         Test_Id => "windows.uia.bridge_audit.router");
      Add
        (Items,
         Windows_UIA_HResult_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "structured status to audited HRESULT code table",
         Test_Id => "windows.uia.hresult_map.router");
      Add
        (Items,
         Windows_UIA_HResult_Inverse_Map,
         "UIA",
         Internal_Only,
         Native_Mapping => "HRESULT return code to structured status table",
         Test_Id => "windows.uia.hresult_inverse_map.router");
      Add
        (Items,
         Windows_UIA_HResult_Diagnostic,
         "UIA",
         Internal_Only,
         Native_Mapping => "bounded HRESULT diagnostic records",
         Test_Id => "windows.uia.hresult_diagnostic.router");
      Add
        (Items,
         Native_Object_Cache_Identity,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "stable semantic identity to native provider identity registry",
         Test_Id => "native.object_cache.identity.windows");
      Add
        (Items,
         Windows_UIA_Provider_Registry,
         "UIA",
         Internal_Only,
         Native_Mapping => "stable Node_Id to COM provider registry",
         Test_Id => "windows.uia.provider_registry.compile");
      Add
        (Items,
         Windows_UIA_COM_Lifetime,
         "UIA",
         Internal_Only,
         Native_Mapping => "COM provider identity and refcount scaffold",
         Test_Id => "windows.uia.com_lifetime.compile");
      Add
        (Items,
         Native_Object_Export_Descriptor,
         "UIA",
         Internal_Only,
         Native_Mapping => "backend-private native provider export descriptor",
         Test_Id => "native.object_export_descriptor.windows");
      Add
        (Items,
         Windows_UIA_COM_Export_Descriptor,
         "UIA",
         Internal_Only,
         Native_Mapping => "SDK-free COM provider export descriptor",
         Test_Id => "windows.uia.com_export_descriptor.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Export,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "opaque COM object token to interface-reference dispatch surface",
         Test_Id => "windows.uia.com_live_export.router");
      Add
        (Items,
         Windows_UIA_Public_Root_Export,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "backend-owned public root provider export through COM object surface",
         Test_Id => "windows.uia.public_root_export.router");
      Add
        (Items,
         Windows_UIA_Public_Root_Native_Identity,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "public root native node component derived from neutral runtime identifier",
         Test_Id => "windows.uia.public_root.native_identity.router");
      Add
        (Items,
         Windows_UIA_Native_Bridge_Binding,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "Ada import binding for the audited minimal UIA C bridge symbols",
         Test_Id => "windows.uia.native_bridge_binding.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Provider_Options,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderSimple.get_ProviderOptions through ABI interface frame",
         Test_Id => "windows.uia.com_live.provider_options.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Host_Raw_Element_Provider,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderSimple.get_HostRawElementProvider through ABI interface frame",
         Test_Id => "windows.uia.com_live.host_raw_element_provider.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Pattern_Provider_Frame,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderSimple.GetPatternProvider through ABI interface frame",
         Test_Id => "windows.uia.com_live.pattern_provider_frame.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Simple_Property_Frame,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderSimple.GetPropertyValue through ABI interface frame",
         Test_Id => "windows.uia.com_live.simple_property_frame.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Bounding_Rectangle_Frame,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragment.get_BoundingRectangle through ABI interface frame",
         Test_Id => "windows.uia.com_live.bounding_rectangle_frame.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Fragment_Action_Frame,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragment.SetFocus through ABI interface frame to semantic action route",
         Test_Id => "windows.uia.com_live.fragment_action_frame.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Fragment_Last_Child_Frame,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragment.Navigate LastChild through ABI interface frame",
         Test_Id => "windows.uia.com_live.fragment_last_child_frame.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Embedded_Fragment_Roots,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragment.GetEmbeddedFragmentRoots through ABI interface frame",
         Test_Id => "windows.uia.com_live.embedded_fragment_roots.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Fragment_Root,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragment.get_FragmentRoot through ABI interface frame",
         Test_Id => "windows.uia.com_live.fragment_root.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Fragment_Root_Point,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragmentRoot.ElementProviderFromPoint through ABI interface frame",
         Test_Id => "windows.uia.com_live.fragment_root_point.router");
      Add
        (Items,
         Windows_UIA_COM_Live_Fragment_Root_Focus,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "IRawElementProviderFragmentRoot.GetFocus through ABI interface frame",
         Test_Id => "windows.uia.com_live.fragment_root_focus.router");
      Add
        (Items,
         Windows_UIA_External_Client_Blocked_Probe,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "blocked external UIA client probe until live COM provider export",
         Test_Id => "windows.uia.external_client.blocked_probe");
      Add
        (Items,
         Windows_UIA_External_Client_Failure_Stage,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "ordered external UIA client failure-stage diagnostics",
         Test_Id => "windows.uia.external_client.failure_stage");
      Add
        (Items,
         Native_Readiness_Remaining_Evidence,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "aggregate UIA readiness remaining-evidence classifier",
         Test_Id => "native.readiness.remaining_evidence.windows");
      Add
        (Items,
         Native_Readiness_Boundary_Stage,
         "UIA",
         Internal_Only,
         Native_Mapping =>
           "aggregate UIA readiness native-boundary stage classifier",
         Test_Id => "native.readiness.boundary_stage.windows");
      Add
        (Items,
         Windows_UIA_Native_Values,
         "UIA",
         Internal_Only,
         Native_Mapping => "BSTR/VARIANT/SAFEARRAY ownership scaffold",
         Test_Id => "windows.uia.native_values.compile");
      return Items;
   end Windows_UIA_Declarations;

   function MacOS_NSAccessibility_Declarations return Declaration_Vectors.Vector is
      Items : Declaration_Vectors.Vector;

      procedure Internal_Map
        (Feature : Feature_Id;
         Mapping : String) is
      begin
         Add
           (Items,
            Feature,
            "NSAccessibility",
            Internal_Only,
            Native_Mapping => Mapping,
            Test_Id => Dotted_Name (Feature) & ".macos");
      end Internal_Map;
   begin
      declare
         type Feature_List is array (Positive range <>) of Feature_Id;
         Evidence : constant Feature_List :=
           [Core_Role_Application,
            Core_Role_Window,
            Core_Role_Dialog,
            Core_Role_Group,
            Core_Role_Region,
            Core_Role_Static_Text,
            Core_Role_Button,
            Core_Role_Text_Field,
            Core_Role_Toggle_Button,
            Core_Role_Check_Box,
            Core_Role_Radio_Button,
            Core_Role_Progress_Bar,
            Core_Role_Spin_Button,
            Core_Role_Slider,
            Core_Role_List,
            Core_Role_List_Item,
            Core_Role_Tree,
            Core_Role_Tree_Item,
            Core_Role_Table,
            Core_Role_Row,
            Core_Role_Column,
            Core_Role_Cell,
            Core_Role_Combo_Box,
            Core_Role_Search_Field,
            Core_Role_Menu_Bar,
            Core_Role_Menu,
            Core_Role_Menu_Item,
            Core_Role_Tool_Bar,
            Core_Role_Tab_List,
            Core_Role_Tab,
            Core_Role_Tooltip,
            Core_Role_Heading,
            Core_Role_Document,
            Core_Role_Text,
            Core_Role_Link,
            Core_Role_Password_Field,
            Core_Role_Scroll_Bar,
            Core_Role_Separator,
            Core_Role_Alert,
            Core_Role_Popup_Dialog,
            Core_Role_Canvas,
            Core_Role_Custom,
            Value_Range,
            Selection_Single,
            Relations_Active_Descendant,
            Relations_Labelled_By,
            Relations_Label_For,
            Relations_Described_By,
            Relations_Description_For,
            Relations_Controlled_By,
            Relations_Controller_For,
            Relations_Flows_To,
            Relations_Flows_From,
            Relations_Member_Of,
            Relations_Details,
            Relations_Details_For,
            Selection_Current_Item,
            Text_Range_Basic,
            Table_Cell_Basic,
            Image_Alternative_Text,
            Document_Heading_Level,
            Text_Protected,
            Events_Live_Region_Changed,
            Relations_Error_Message,
            Relations_Error_For,
            Relations_Embedded_By,
            Relations_Embeds,
            Relations_Popup_For,
            Relations_Popup_Controlled_By,
            Lifecycle_Stale_Reference,
            Backend_Transport_Unavailable,
            Native_Fixture_Root_Child_Traversal,
            Native_Fixture_Root_Child_Count,
            Native_Fixture_Root_Second_Child,
            Native_Fixture_Child_Query,
            Native_Fixture_Child_Native_Object,
            Native_Fixture_Child_Parent_Navigation,
            Native_Fixture_Child_Native_Identity,
            Native_Fixture_Second_Child_Parent_Navigation,
            Native_Fixture_Second_Child_Native_Identity,
            Native_Fixture_Sibling_Order,
            Native_Fixture_Child_Stale_Id,
            MacOS_NSAX_Main_Thread_Binding,
            MacOS_NSAX_Native_View_Binding,
            MacOS_NSAX_Attribute_Names,
            MacOS_NSAX_Selection_Select_All,
            MacOS_NSAX_Selection_Clear_Selection,
            MacOS_NSAX_Selector_Attribute_Value,
            MacOS_NSAX_Selector_Children_Frame,
            MacOS_NSAX_Selector_Child_At_Index_Frame,
            MacOS_NSAX_Selector_Attribute_Value_Frame,
            MacOS_NSAX_Selector_Attribute_Settable_Frame,
            MacOS_NSAX_Selector_Action_Frame,
            MacOS_NSAX_Selector_Unsupported,
            MacOS_NSAX_Selector_Main_Thread_Gate,
            MacOS_NSAX_Registered_Method_Family_Mismatch,
            MacOS_NSAX_Released_Boundary];
      begin
         for Feature of Evidence loop
            Internal_Map
              (Feature, "NSAccessibility native-client conformance evidence");
         end loop;
      end;

      Add
        (Items,
         Backend_Native_Scaffold,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native runtime scaffold",
         Test_Id => "backend.native.scaffold.macos");
      Add
        (Items,
         Backend_Native_Target_Resolution,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "host platform to NSAccessibility backend target",
         Test_Id => "backend.native.target_resolution.macos");
      Add
        (Items,
         Backend_Selection_Runtime_Override,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common runtime backend override constructor",
         Test_Id => "backend.selection.runtime_override.macos");
      Add
        (Items,
         Backend_Selection_Fallback,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common runtime backend override fallback classification",
         Test_Id => "backend.selection.fallback.macos");
      Add
        (Items,
         Backend_Native_Transport_Admission,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "adapter-facing transport admission snapshot",
         Test_Id => "backend.native.transport_admission.macos");
      Add
        (Items,
         Backend_Native_Transport_Status,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "adapter-facing typed transport state and failure snapshot",
         Test_Id => "backend.native.transport_status.macos");
      Add
        (Items,
         Backend_Native_Transport_Generation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "adapter-facing monotonic transport snapshot generation",
         Test_Id => "backend.native.transport_generation.macos");
      Add
        (Items,
         Backend_Native_Transport_Transition_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "adapter-facing structured transport transition report",
         Test_Id => "backend.native.transport_transition_report.macos");
      Add
        (Items,
         Backend_Native_Deterministic_Shutdown,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "adapter-facing deterministic transport shutdown",
         Test_Id => "backend.native.deterministic_shutdown.macos");
      Add
        (Items,
         Native_Runtime_Lifecycle,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "shared native runtime start, stop, and drained lifecycle",
         Test_Id => "native.runtime.lifecycle.macos");
      Add
        (Items,
         Native_Runtime_Generation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "shared native runtime lifecycle generation snapshot",
         Test_Id => "native.runtime.generation.macos");
      Add
        (Items,
         Native_Runtime_Lifecycle_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "shared native runtime lifecycle transition report",
         Test_Id => "native.runtime.lifecycle_report.macos");
      Add
        (Items,
         Native_Runtime_Probe_Failure_Stage,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native runtime probe status and failure-stage report",
         Test_Id => "native.runtime.probe_failure_stage.macos");
      Add
        (Items,
         Backend_Native_Publication_Preparation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "adapter-facing prepared native publication record",
         Test_Id => "backend.native.publication_preparation.macos");
      Add
        (Items,
         Backend_Diagnostics_Bounded,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded native-backend diagnostic log",
         Test_Id => "backend.diagnostics.bounded.macos");
      Add
        (Items,
         Diagnostics_Result_Mapping,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "structured result-to-diagnostic category mapping",
         Test_Id => "diagnostics.result_mapping.macos");
      Add
        (Items,
         Diagnostics_Field_Bounds,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bounded diagnostic field, identifier, and record-retention validation",
         Test_Id => "diagnostics.field_bounds.macos");
      Add
        (Items,
         Diagnostics_Localization,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "message-catalog-backed diagnostic/status labels",
         Test_Id => "diagnostics.localization.macos");
      Add
        (Items,
         Native_Runtime_Event_Application,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "committed semantic event application, direct defunct ledgering, " &
           "bounded tombstone eviction, and stale destroyed-node rejection",
         Test_Id => "native.runtime.event_application.macos");
      Add
        (Items,
         Core_Node_Key_Registry,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "stable application key to Node_Id registry",
         Test_Id => "core.node_key.registry.macos");
      Add
        (Items,
         Core_Geometry_Visibility,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "logical desktop clipping before AppKit projection",
         Test_Id => "core.geometry.visibility.macos");
      Add
        (Items,
         Core_Geometry_Region,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bounded logical desktop region before AppKit projection",
         Test_Id => "core.geometry.region.macos");
      Add_Common_Capability_Declarations
        (Items,
         "NSAccessibility",
         "NSAccessibility attribute and action exposure from central " &
         "semantic capability set",
         "macos");
      Add
        (Items,
         Core_Provider_Contract,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "central provider role/state/capability contract validation",
         Test_Id => "core.provider.contract.macos");
      Add
        (Items,
         Core_Role_Image,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSAccessibility image role through central role map",
         Test_Id => "core.role.image.macos");
      Add
        (Items,
         Core_Role_Status,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSAccessibility status/static-text role projection",
         Test_Id => "core.role.status.macos");
      Add
        (Items,
         Core_Role_Decorative_Image,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "decorative semantic image omission before NSAccessibility exposure",
         Test_Id => "core.role.decorative_image.macos");
      Add
        (Items,
         Core_State_Derivation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "central role/capability-derived effective state normalization",
         Test_Id => "core.state.derivation.macos");
      Add_Common_State_Declarations
        (Items,
         "NSAccessibility",
         "NSAccessibility attribute projection from central semantic state map",
         "macos");
      Add
        (Items,
         Events_Live_Region,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "live-region attributes and notifications",
         Test_Id => "events.live_region.macos");
      Add
        (Items,
         Events_Classification,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "central semantic event-family classification",
         Test_Id => "events.classification.macos");
      declare
         Event_Kinds : constant array (Positive range <>) of Feature_Id :=
           [Events_Node_Created,
            Events_Node_Attached,
            Events_Node_Detached,
            Events_Child_Added,
            Events_Child_Removed,
            Events_Children_Reordered,
            Events_Subtree_Rebuilt,
            Events_Property_Changed,
            Events_State_Changed,
            Events_Bounds_Changed,
            Events_Focus_Changed,
            Events_Active_Descendant_Changed,
            Events_Selection_Changed,
            Events_Current_Item_Changed,
            Events_Value_Changed,
            Events_Range_Changed,
            Events_Text_Inserted,
            Events_Text_Removed,
            Events_Text_Replaced,
            Events_Caret_Moved,
            Events_Text_Selection_Changed,
            Events_Text_Attributes_Changed,
            Events_Row_Inserted,
            Events_Row_Removed,
            Events_Column_Inserted,
            Events_Column_Removed,
            Events_Cell_Changed,
            Events_Window_Opened,
            Events_Window_Closed,
            Events_Window_Activated,
            Events_Window_Deactivated,
            Events_Document_Loaded,
            Events_Document_Closed,
            Events_Announcement_Requested,
            Events_Relation_Added,
            Events_Relation_Removed,
            Events_Relation_Targets_Changed,
            Events_Node_Destroyed];
      begin
         for Feature of Event_Kinds loop
            Internal_Map
              (Feature,
               "central semantic event-kind validation and NSAX event mapping");
         end loop;
      end;
      Add
        (Items,
         Events_Envelope,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "central semantic event envelope validation",
         Test_Id => "events.envelope.macos");
      Add
        (Items,
         Events_Timestamp_Order,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "event queue nondecreasing committed timestamp order",
         Test_Id => "events.timestamp_order.macos");
      Add
        (Items,
         Events_Live_Region_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed live-region change and announcement payload validation",
         Test_Id => "events.live_region.payload.macos");
      Add
        (Items,
         Live_Region_Metadata,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "live-region setting, atomicity, and announcement policy metadata",
         Test_Id => "live_region.metadata.macos");
      Add
        (Items,
         Live_Region_Relevance,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "stable live-region relevance strings",
         Test_Id => "live_region.relevance.macos");
      Add
        (Items,
         Live_Region_Backend_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bounded NSAccessibility live-region query mapper and provider-boundary routing",
         Test_Id => "live_region.backend_routing.macos");
      Add
        (Items,
         Events_Text_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed text mutation event payload and record validation",
         Test_Id => "events.text.payload.macos");
      Add
        (Items,
         Events_Property_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed property-change event payload validation",
         Test_Id => "events.property.payload.macos");
      Add
        (Items,
         Events_Property_Orientation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "orientation attribute-change notification",
         Test_Id => "events.property.orientation.macos");
      Add
        (Items,
         Events_Property_Set_Position,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "set-position attribute-change notification",
         Test_Id => "events.property.set_position.macos");
      Add
        (Items,
         Events_Property_Set_Size,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "set-size attribute-change notification",
         Test_Id => "events.property.set_size.macos");
      Add
        (Items,
         Events_Property_Hierarchical_Level,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "hierarchical-level attribute-change notification",
         Test_Id => "events.property.hierarchical_level.macos");
      Add
        (Items,
         Events_State_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed state-change event payload validation",
         Test_Id => "events.state.payload.macos");
      Add
        (Items,
         Events_Relation_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed relation-change event payload and inverse validation",
         Test_Id => "events.relation.payload.macos");
      Add
        (Items,
         Events_Bounds_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed bounds-change event payload validation",
         Test_Id => "events.bounds.payload.macos");
      Add
        (Items,
         Events_Focus_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed focus-change event payload validation",
         Test_Id => "events.focus.payload.macos");
      Add
        (Items,
         Events_Node_Reference_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed active-descendant/current-item event payload validation",
         Test_Id => "events.node_reference.payload.macos");
      Add
        (Items,
         Events_Value_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed value/range event payload validation",
         Test_Id => "events.value.payload.macos");
      Add
        (Items,
         Events_Selection_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed item and invalidation selection payload validation",
         Test_Id => "events.selection.payload.macos");
      Add
        (Items,
         Events_Session_Notification,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "validated provider semantic event notification",
         Test_Id => "events.session.notification.macos");
      Add
        (Items,
         Events_Backend_Pump_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "structured common session-to-backend event pump report",
         Test_Id => "events.backend_pump_report.macos");
      Add
        (Items,
         Events_Subscription_Filter,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded backend event subscription filters",
         Test_Id => "events.subscription.filter.macos");
      Add
        (Items,
         Events_Subscription_Bounds,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded backend event fan-out admission",
         Test_Id => "events.subscription.bounds.macos");
      Add
        (Items,
         Tree_Attachment_Validation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "attachment validation before event-capacity preflight",
         Test_Id => "tree.attachment.validation.macos");
      Add
        (Items,
         Tree_Exposure_Projection,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "central semantic exposure projection",
         Test_Id => "tree.exposure.projection.macos");
      Add
        (Items,
         Tree_Mutation_Event_Order,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "committed tree mutation event ordering",
         Test_Id => "tree.mutation.event_order.macos");
      Add
        (Items,
         Events_Tree_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed child and aggregate tree event payload validation",
         Test_Id => "events.tree.payload.macos");
      Add
        (Items,
         Events_Table_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "typed table row/column/cell event payload family validation",
         Test_Id => "events.table.payload.macos");
      Add
        (Items,
         Events_Document_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed document lifecycle event payload validation",
         Test_Id => "events.document.payload.macos");
      Add
        (Items,
         Events_Window_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed window and surface event payload validation",
         Test_Id => "events.window.payload.macos");
      Add
        (Items,
         Native_Runtime_Event_Preparation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "atomic runtime event to native object preparation",
         Test_Id => "native.runtime.event_preparation.macos");
      Add
        (Items,
         Native_Runtime_Event_Preparation_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "structured runtime event-preparation report",
         Test_Id => "native.runtime.event_preparation_report.macos");
      Add
        (Items,
         Native_Projection_Property,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before NSAccessibility attribute projection",
         Test_Id => "native.projection.property.macos");
      Add
        (Items,
         Native_Projection_Action,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before NSAccessibility action projection",
         Test_Id => "native.projection.action.macos");
      Add
        (Items,
         Native_Request_Action_Payload,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "routed action-request payload retains neutral Action_Id",
         Test_Id => "native.request.action_payload.macos");
      Add
        (Items,
         Native_Projection_Relation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before NSAccessibility relation projection",
         Test_Id => "native.projection.relation.macos");
      Add
        (Items,
         Native_Projection_Event_Source,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "central exposure validation before NSAccessibility notification projection",
         Test_Id => "native.projection.event_source.macos");
      Add
        (Items,
         Native_Event_Validation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSAccessibility notification validation",
         Test_Id => "native.event.validation.macos");
      Add
        (Items,
         Native_Event_Prepared_Status,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "prepared native publication status handoff before NSAccessibility object mapping",
         Test_Id => "native.event.prepared_status.macos");
      Add
        (Items,
         Native_Event_Staging_Queue,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded NSAccessibility notification FIFO",
         Test_Id => "macos.nsaccessibility.event_queue.router");
      Add
        (Items,
         Native_Event_Posting_Interest,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "NSAccessibility notification queue posting-interest snapshot",
         Test_Id => "macos.nsaccessibility.event_queue_interest.router");
      Add
        (Items,
         Native_Event_Posting_Boundary,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSAccessibility notification posting boundary validation",
         Test_Id => "macos.nsaccessibility.event_posting_boundary.router");
      Add
        (Items,
         Native_Event_Exhaustive_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "semantic event kind to NSAccessibility notification map",
         Test_Id => "native.event.exhaustive_map.macos");
      Add
        (Items,
         Native_Role_Exhaustive_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "semantic role to NSAccessibility role map",
         Test_Id => "native.role.exhaustive_map.macos");
      Add
        (Items,
         Native_Relation_Exhaustive_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "semantic relation to NSAccessibility relation attribute map",
         Test_Id => "native.relation.exhaustive_map.macos");
      Add
        (Items,
         Native_Object_Cache_Node_Index,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "indexed Node_Id to native object cache lookup",
         Test_Id => "native.object_cache.node_index.macos");
      Add
        (Items,
         Native_Object_Cache_Tombstone,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded stale native element tombstones",
         Test_Id => "native.object_cache.tombstone.macos");
      Add
        (Items,
         Native_Object_Cache_Session_Scope,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "backend-session-scoped element identities",
         Test_Id => "native.object_cache.session_scope.macos");
      Add
        (Items,
         Native_Object_Cache_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded native object cache",
         Test_Id => "native.object_cache.resource_limit.macos");
      Add
        (Items,
         Native_Object_Cache_Generation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "monotonic native object cache mutation generation",
         Test_Id => "native.object_cache.generation.macos");
      Add
        (Items,
         Native_Object_Cache_Mutation_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "shared native object-cache mutation report",
         Test_Id => "native.object_cache.mutation_report.macos");
      Add
        (Items,
         Native_Object_Registry_Generation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "monotonic native element registry mutation generation",
         Test_Id => "native.object_registry.generation.macos");
      Add
        (Items,
         Native_Object_Registry_Drained_Reset,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "drained-aware native element registry reset",
         Test_Id => "native.object_registry.drained_reset.macos");
      Add
        (Items,
         Native_Object_Registry_Mutation_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "structured NSAccessibility element registry mutation reports",
         Test_Id => "native.object_registry.mutation_report.macos");
      Add
        (Items,
         Native_Object_Lifetime_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded NSAccessibility element retain count",
         Test_Id => "native.object_lifetime.resource_limit.macos");
      Add
        (Items,
         Native_Value_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded NSString and NSArray values",
         Test_Id => "macos.nsaccessibility.native_values.resource_limit.router");
      Add
        (Items,
         Native_Callback_Gate,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native callback admission and reset guard",
         Test_Id => "native.callback.gate.macos");
      Add
        (Items,
         Native_Callback_Generation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native callback gate lifecycle generation snapshot",
         Test_Id => "native.callback.generation.macos");
      Add
        (Items,
         Native_Boundary_Call_Context,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary object-call context",
         Test_Id => "native.boundary.call_context.macos");
      Add
        (Items,
         Native_Boundary_Call_Kind,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary dispatcher call-kind and failure-context snapshot",
         Test_Id => "native.boundary.call_kind.macos");
      Add
        (Items,
         Native_Boundary_Native_Call_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "element registry begin/end native-call mutation reports",
         Test_Id => "native.boundary.native_call_report.macos");
      Add
        (Items,
         Native_Boundary_Return_Class,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary structured return classification",
         Test_Id => "native.boundary.return_class.macos");
      Add
        (Items,
         Native_Boundary_Status_Recording,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary provider-status recording",
         Test_Id => "native.boundary.status_recording.macos");
      Add
        (Items,
         Native_Boundary_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary cancellation propagation",
         Test_Id => "native.boundary.cancellation.macos");
      Add
        (Items,
         Native_Boundary_Query_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary property and geometry query cancellation",
         Test_Id => "native.boundary.query_cancellation.macos");
      Add
        (Items,
         Native_Boundary_Tree_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary tree-navigation cancellation",
         Test_Id => "native.boundary.tree_cancellation.macos");
      Add
        (Items,
         Native_Boundary_Component_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary component geometry cancellation",
         Test_Id => "native.boundary.component_cancellation.macos");
      Add
        (Items,
         Dispatcher_Call_Metadata,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "dispatcher call-kind timeout metadata",
         Test_Id => "dispatcher.call.metadata.macos");
      Add
        (Items,
         Dispatcher_Timeout_Classification,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "dispatcher elapsed-time timeout classification",
         Test_Id => "dispatcher.timeout.classification.macos");
      Add
        (Items,
         Dispatcher_Call_Accounting,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "dispatcher call-kind bounded accounting",
         Test_Id => "dispatcher.call.accounting.macos");
      Add
        (Items,
         Dispatcher_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "dispatcher cancellation token policy",
         Test_Id => "dispatcher.cancellation.macos");
      Add
        (Items,
         Dispatcher_Reentrancy,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "dispatcher reentrant rejection and explicit inline fast path",
         Test_Id => "dispatcher.reentrancy.macos");
      Add
        (Items,
         Native_Boundary_Action_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary action-call dispatcher",
         Test_Id => "native.boundary.action_call.macos");
      Add
        (Items,
         Native_Boundary_Node_Action_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary existing-node action dispatcher",
         Test_Id => "native.boundary.node_action_call.macos");
      Add
        (Items,
         Native_Boundary_Query_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary property-query dispatcher",
         Test_Id => "native.boundary.query_call.macos");
      Add
        (Items,
         Native_Boundary_Node_Query_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node property-query dispatcher",
         Test_Id => "native.boundary.node_query_call.macos");
      Add
        (Items,
         Native_Boundary_Tree_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary tree-navigation dispatcher",
         Test_Id => "native.boundary.tree_call.macos");
      Add
        (Items,
         Native_Boundary_Node_Tree_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node tree-navigation dispatcher",
         Test_Id => "native.boundary.node_tree_call.macos");
      Add
        (Items,
         Native_Boundary_Component_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary component geometry dispatcher",
         Test_Id => "native.boundary.component_call.macos");
      Add
        (Items,
         Native_Boundary_Node_Component_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node component geometry dispatcher",
         Test_Id => "native.boundary.node_component_call.macos");
      Add
        (Items,
         Native_Boundary_Focus_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary focus query/action dispatcher",
         Test_Id => "native.boundary.focus_call.macos");
      Add
        (Items,
         Native_Boundary_Node_Focus_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node focus query/action dispatcher",
         Test_Id => "native.boundary.node_focus_call.macos");
      Add
        (Items,
         Native_Boundary_Focus_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary focus query/action cancellation",
         Test_Id => "native.boundary.focus_cancellation.macos");
      Add
        (Items,
         Core_Focus_Session,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "session-owned focus state and events",
         Test_Id => "core.focus.session.macos");
      Add
        (Items,
         Native_Boundary_Relation_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary relation query dispatcher",
         Test_Id => "native.boundary.relation_call.macos");
      Add
        (Items,
         Native_Boundary_Node_Relation_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native boundary existing-node relation query dispatcher",
         Test_Id => "native.boundary.node_relation_call.macos");
      Add
        (Items,
         Native_Boundary_Relation_Cancellation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary relation query cancellation",
         Test_Id => "native.boundary.relation_cancellation.macos");
      Add
        (Items,
         Native_Boundary_Node_Call,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary existing-node callback admission",
         Test_Id => "native.boundary.node_call.macos");
      Add
        (Items,
         Native_Boundary_Stale_Metadata,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "native boundary stale object metadata preservation",
         Test_Id => "native.boundary.stale_metadata.macos");
      Add
        (Items,
         Native_Boundary_Error_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "structured status to native selector result mapping",
         Test_Id => "native.boundary.error_map.macos");
      Add
        (Items,
         Native_Boundary_Identity_Admission,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "virtual element id admission before routing",
         Test_Id => "native.boundary.identity_admission.macos");
      Add
        (Items,
         Native_Boundary_Request_Admission,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "NSAccessibility method-family request admission before routing",
         Test_Id => "native.boundary.request_admission.macos");
      Add
        (Items,
         Native_Boundary_Admission_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "virtual element id admission report",
         Test_Id => "native.boundary.admission_report.macos");
      Add
        (Items,
         Native_Boundary_Completion_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "virtual element id completion report",
         Test_Id => "native.boundary.completion_report.macos");
      Add
        (Items,
         Native_Boundary_Release_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "virtual element id release report",
         Test_Id => "native.boundary.release_report.macos");
      Add
        (Items,
         Native_Fixture_Root_Query,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "fixture application root query through NSAccessibility element boundary",
         Test_Id => "native.fixture_root.query.macos");
      Add
        (Items,
         Native_Fixture_Root_Failure_Stage,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "fixture-root probe status and failure-stage report",
         Test_Id => "native.fixture_root.failure_stage.macos");
      Add
        (Items,
         MacOS_NSAX_Role,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSAccessibility role",
         Test_Id => "macos.nsaccessibility.role.compile");
      Add
        (Items,
         MacOS_NSAX_Core_Attributes,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "core accessibility attributes",
         Test_Id => "macos.nsaccessibility.core_attributes.compile");
      Add
        (Items,
         MacOS_NSAX_Frame_Attribute,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "frame accessibility attribute",
         Test_Id => "macos.nsaccessibility.frame_attribute.router");
      Add
        (Items,
         Core_Property_Bounds,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "frame accessibility attribute",
         Test_Id => "core.property.bounds.macos.router");
      Add
        (Items,
         Core_Property_Role,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "role accessibility attribute",
         Test_Id => "core.property.role.macos.router");
      Add
        (Items,
         Core_Property_State_Set,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "state accessibility attributes",
         Test_Id => "core.property.state_set.macos.router");
      Add
        (Items,
         MacOS_NSAX_Textual_Attributes,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "title, label, description, help, placeholder, value text, and shortcut attributes",
         Test_Id => "macos.nsaccessibility.textual_attributes.router");
      Add
        (Items,
         Core_Property_Placeholder,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "placeholder accessibility attribute",
         Test_Id => "core.property.placeholder.macos.router");
      Add
        (Items,
         Core_Property_Name,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "label accessibility attribute",
         Test_Id => "core.property.name.macos.router");
      Add
        (Items,
         Core_Property_Help_Text,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "help accessibility attribute",
         Test_Id => "core.property.help_text.macos.router");
      Add
        (Items,
         Core_Property_Description,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "description accessibility attribute",
         Test_Id => "core.property.description.macos.router");
      Add
        (Items,
         Core_Property_Value_Text,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "value accessibility attribute",
         Test_Id => "core.property.value_text.macos.router");
      Add
        (Items,
         Core_Property_Semantic_Identifier,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "identifier accessibility attribute",
         Test_Id => "core.property.semantic_identifier.macos.router");
      Add
        (Items,
         Core_Property_Keyboard_Shortcut,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "keyboard shortcut accessibility attribute",
         Test_Id => "core.property.keyboard_shortcut.macos.router");
      Add
        (Items,
         Core_Property_Typed_Results,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "portable typed property result records",
         Test_Id => "core.property.typed_results.macos.semantic");
      Add
        (Items,
         Core_Property_Status_Mapping,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common result-to-property-status classification",
         Test_Id => "core.property.status_mapping.macos.semantic");
      Add
        (Items,
         Core_State_Validation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common state snapshot validation",
         Test_Id => "core.state.validation.macos.router");
      Add
        (Items,
         MacOS_NSAX_Metadata_Attributes,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "metadata-backed label/help/placeholder/value attributes",
         Test_Id => "macos.nsaccessibility.metadata_attributes.router");
      Add
        (Items,
         MacOS_NSAX_Protected_Value_Text,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "Permission_Denied for protected value text",
         Test_Id => "macos.nsaccessibility.protected_value_text.router");
      Add
        (Items,
         MacOS_NSAX_Unsupported_Value,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "unsupported nullable attributes",
         Test_Id => "macos.nsaccessibility.unsupported_value.compile");
      Add
        (Items,
         MacOS_NSAX_Action_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "accessibility action names",
         Test_Id => "macos.nsaccessibility.action_map.compile");
      Add
        (Items,
         MacOS_NSAX_Action_Discovery,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "capability-derived action name set",
         Test_Id => "macos.nsaccessibility.action_discovery.router");
      Add
        (Items,
         MacOS_NSAX_Action_Request,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "validated NSAccessibility action request routing",
         Test_Id => "macos.nsaccessibility.action_request.router");
      Add
        (Items,
         Actions_Activate,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "press accessibility action default activation",
         Test_Id => "actions.activate.macos");
      Add
        (Items,
         Actions_Press,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "press accessibility action",
         Test_Id => "actions.press.macos");
      Add
        (Items,
         Actions_Toggle,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "press accessibility action for toggle controls",
         Test_Id => "actions.toggle.macos");
      Add
        (Items,
         Actions_Expand,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "expand accessibility action request",
         Test_Id => "actions.expand.macos");
      Add
        (Items,
         Actions_Collapse,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "collapse accessibility action request",
         Test_Id => "actions.collapse.macos");
      Add
        (Items,
         Actions_Show_Menu,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "show-menu accessibility action",
         Test_Id => "actions.show_menu.macos");
      Add
        (Items,
         Actions_Dismiss,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "cancel accessibility action",
         Test_Id => "actions.dismiss.macos");
      Add
        (Items,
         Actions_Increment,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "increment accessibility action",
         Test_Id => "actions.increment.macos");
      Add
        (Items,
         Actions_Decrement,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "decrement accessibility action",
         Test_Id => "actions.decrement.macos");
      Add
        (Items,
         Actions_Select_Item,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "pick or press accessibility action for selection",
         Test_Id => "actions.select.macos");
      Add
        (Items,
         Actions_Deselect,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "cancel or press accessibility action for deselection",
         Test_Id => "actions.deselect.macos");
      Add
        (Items,
         Actions_Clear_Selection,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "selection removal through accessibility action routing",
         Test_Id => "actions.clear_selection.macos");
      Add
        (Items,
         MacOS_NSAX_Open_Action,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "confirm accessibility action",
         Test_Id => "macos.nsaccessibility.action.open.router");
      Add
        (Items,
         Actions_Open,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "confirm accessibility action",
         Test_Id => "actions.open.macos");
      Add
        (Items,
         MacOS_NSAX_Close_Action,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "cancel accessibility action",
         Test_Id => "macos.nsaccessibility.action.close.router");
      Add
        (Items,
         Actions_Close,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "cancel accessibility action",
         Test_Id => "actions.close.macos");
      Add
        (Items,
         MacOS_NSAX_Set_Focus_Action,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "raise accessibility action",
         Test_Id => "macos.nsaccessibility.action.set_focus.router");
      Add
        (Items,
         Actions_Set_Focus,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "raise accessibility action",
         Test_Id => "actions.set_focus.macos");
      Add
        (Items,
         MacOS_NSAX_Scroll_To_Visible_Action,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "scroll-to-visible accessibility action",
         Test_Id => "macos.nsaccessibility.action.scroll_to_visible.router");
      Add
        (Items,
         Actions_Scroll_Into_View,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "scroll-to-visible accessibility action",
         Test_Id => "actions.scroll_into_view.macos");
      Add
        (Items,
         Actions_Preconditions,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common action precondition validation",
         Test_Id => "actions.preconditions.macos");
      Add
        (Items,
         MacOS_NSAX_Event_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "accessibility notifications",
         Test_Id => "macos.nsaccessibility.event_map.compile");
      Add
        (Items,
         MacOS_NSAX_Event_Details,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "attribute and window notification details",
         Test_Id => "macos.nsaccessibility.event_details.router");
      Add
        (Items,
         MacOS_NSAX_Prepared_Event_Emission,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "prepared native publication to NSAccessibility notification",
         Test_Id => "macos.nsaccessibility.prepared_event_emission.router");
      Add
        (Items,
         MacOS_NSAX_Event_Build_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "structured NSAccessibility notification build report",
         Test_Id => "macos.nsaccessibility.event.build_report.router");
      Add
        (Items,
         MacOS_NSAX_Prepared_Event_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "request-router handoff of prepared native publication records",
         Test_Id => "macos.nsaccessibility.prepared_event_routing.router");
      Add
        (Items,
         MacOS_NSAX_Prepared_Event_Boundary,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "provider-boundary handoff of prepared native publication records",
         Test_Id => "macos.nsaccessibility.prepared_event_boundary.router");
      Add
        (Items,
         MacOS_NSAX_Event_Posting_Admission,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bridge-facing bounded notification queue dequeue admission",
         Test_Id => "macos.nsaccessibility.event_posting_admission.router");
      Add
        (Items,
         MacOS_NSAX_Event_Posting_Report,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bridge-facing bounded notification queue dequeue admission report",
         Test_Id => "macos.nsaccessibility.event_posting_report.router");
      Add
        (Items,
         MacOS_NSAX_Event_Posting_Drain_Bounded,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bridge-facing callback-based bounded notification posting drain",
         Test_Id =>
           "macos.nsaccessibility.event_posting_drain_bounded.router");
      Add
        (Items,
         Events_Subscription_Filter,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "listener-aware NSAccessibility notification subscription filter metadata",
         Test_Id => "events.subscription_filter.macos");
      Add
        (Items,
         Events_Subscription_Bounds,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bounded NSAccessibility notification subscription and posting interest",
         Test_Id => "events.subscription_bounds.macos");
      Add
        (Items,
         MacOS_NSAX_Hostile_Callback_Admission,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "hostile native callback admission gate before provider routing",
         Test_Id =>
           "macos.nsaccessibility.native_callback.hostile_admission.router");
      Add
        (Items,
         MacOS_NSAX_Missing_Identity,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "missing native identity rejection before provider routing",
         Test_Id =>
           "macos.nsaccessibility.native_callback.missing_identity.router");
      Add
        (Items,
         MacOS_NSAX_Mismatched_Identity,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "mismatched native identity rejection before provider routing",
         Test_Id =>
           "macos.nsaccessibility.native_callback.mismatched_identity.router");
      Add
        (Items,
         MacOS_NSAX_Malformed_Identity,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "malformed native identity rejection before provider routing",
         Test_Id =>
           "macos.nsaccessibility.native_callback.malformed_identity.router");
      Add
        (Items,
         MacOS_NSAX_Text_Payload_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "native text-edit payload limit rejection before provider routing",
         Test_Id =>
           "macos.nsaccessibility.native_callback.text_payload_limit.router");
      Add
        (Items,
         MacOS_NSAX_Hierarchy,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "parent and children attributes",
         Test_Id => "macos.nsaccessibility.hierarchy.compile");
      Add
        (Items,
         MacOS_NSAX_Element_Id,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "virtual element identity components",
         Test_Id => "macos.nsaccessibility.element_id.compile");
      Add
        (Items,
         MacOS_NSAX_Relation_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "relation accessibility attributes",
         Test_Id => "macos.nsaccessibility.relation_routing.router");
      Add
        (Items,
         Relations_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded relation target materialization",
         Test_Id => "relations.resource_limit.macos.router");
      Add
        (Items,
         Relations_Session_Ownership,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "session-owned relation graph cleanup",
         Test_Id => "relations.session_ownership.macos");
      Add
        (Items,
         MacOS_NSAX_Value_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "value accessibility attributes",
         Test_Id => "macos.nsaccessibility.value_routing.router");
      Add
        (Items,
         MacOS_NSAX_Value_Set_Request,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "settable value attribute validation",
         Test_Id => "macos.nsaccessibility.value_set_request.router");
      Add
        (Items,
         Value_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded value metadata validation",
         Test_Id => "value.resource_limit.macos.router");
      Add
        (Items,
         Value_Precision_Loss,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "lossless native floating-point value conversion",
         Test_Id => "value.precision_loss.macos.router");
      Add_Common_Value_Declarations
        (Items,
         "NSAccessibility",
         "NSAccessibility value attribute conversion from typed semantic values",
         "macos");
      Add
        (Items,
         MacOS_NSAX_Selection_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "selection accessibility attributes",
         Test_Id => "macos.nsaccessibility.selection_routing.router");
      Add
        (Items,
         MacOS_NSAX_Selection_Request,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "validated semantic selection requests",
         Test_Id => "macos.nsaccessibility.selection_request.router");
      Add
        (Items,
         Selection_Range,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common stable-identity range selection validation",
         Test_Id => "selection.range.macos.router");
      Add
        (Items,
         Selection_Direction,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "common anchor-to-current selection direction metadata",
         Test_Id => "selection.direction.macos.router");
      Add
        (Items,
         Selection_Select_All,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "selection select-all request staging",
         Test_Id => "selection.select_all.macos.router");
      Add
        (Items,
         Selection_Validation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded selection snapshot validation",
         Test_Id => "selection.validation.macos.router");
      Add
        (Items,
         MacOS_NSAX_Text_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "text accessibility attributes",
         Test_Id => "macos.nsaccessibility.text_routing.router");
      Add
        (Items,
         Text_Edit_Request,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "validated semantic text edit requests",
         Test_Id => "text.edit.request.macos.router");
      Add
        (Items,
         MacOS_NSAX_Text_Edit_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "settable text attribute request routing",
         Test_Id => "macos.nsaccessibility.text_edit_routing.router");
      Add
        (Items,
         MacOS_NSAX_Table_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "table accessibility attributes",
         Test_Id => "macos.nsaccessibility.table_routing.router");
      Add
        (Items,
         Table_Current_Cell,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "current table cell accessibility attribute routing",
         Test_Id => "table.current_cell.macos.router");
      Add
        (Items,
         Table_Sort_Metadata,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "table sort accessibility attribute routing",
         Test_Id => "table.sort.metadata.macos.router");
      Add
        (Items,
         Table_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded table cell materialization",
         Test_Id => "table.resource_limit.macos.router");
      Add
        (Items,
         MacOS_NSAX_Image_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "image accessibility attributes",
         Test_Id => "macos.nsaccessibility.image_routing.router");
      Add
        (Items,
         Image_Caption,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "image caption accessibility attribute",
         Test_Id => "image.caption.macos.router");
      Add
        (Items,
         Image_Category,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "image category accessibility attribute",
         Test_Id => "image.category.macos.router");
      Add
        (Items,
         Image_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded image accessibility attributes",
         Test_Id => "image.resource_limit.macos.router");
      Add
        (Items,
         MacOS_NSAX_Document_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "document accessibility attributes",
         Test_Id => "macos.nsaccessibility.document_routing.router");
      Add
        (Items,
         Core_Property_Locale,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "locale accessibility attribute and document locale metadata",
         Test_Id => "core.property.locale.macos.router");
      Add
        (Items,
         Core_Property_Visible_Title,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "title accessibility attribute",
         Test_Id => "core.property.visible_title.macos.router");
      Add
        (Items,
         Core_Property_Orientation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "orientation accessibility attribute",
         Test_Id => "core.property.orientation.macos.router");
      Add
        (Items,
         Core_Property_Set_Position,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "set-position accessibility attribute",
         Test_Id => "core.property.set_position.macos.router");
      Add
        (Items,
         Core_Property_Set_Size,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "set-size accessibility attribute",
         Test_Id => "core.property.set_size.macos.router");
      Add
        (Items,
         Core_Property_Hierarchical_Level,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "hierarchical-level accessibility attribute",
         Test_Id => "core.property.hierarchical_level.macos.router");
      Add
        (Items,
         Core_Property_Heading_Level,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "document heading-level accessibility attribute",
         Test_Id => "core.property.heading_level.macos.router");
      Add
        (Items,
         Core_Property_Landmark,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "document landmark accessibility attribute",
         Test_Id => "core.property.landmark.macos.router");
      Add
        (Items,
         Document_Resource_Limit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "bounded document accessibility attributes",
         Test_Id => "document.resource_limit.macos.router");
      Add
        (Items,
         MacOS_NSAX_Surface_Routing,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "window accessibility attributes",
         Test_Id => "macos.nsaccessibility.surface_routing.router");
      Add
        (Items,
         Window_Surface_Kind_Name,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "stable surface kind-name accessibility attribute",
         Test_Id => "window.surface.kind_name.macos.router");
      Add
        (Items,
         Window_Surface_State_Metadata,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "surface state flag metadata",
         Test_Id => "window.surface.state_metadata.macos");
      Add
        (Items,
         Window_Surface_Validation,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "surface state validation",
         Test_Id => "window.surface.validation.macos.router");
      Add
        (Items,
         MacOS_NSAX_Request_Router,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "typed attribute/action/hierarchy routing",
         Test_Id => "macos.nsaccessibility.request_router.compile");
      Add
        (Items,
         MacOS_NSAX_ABI_Surface,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "Objective-C selector surface to provider-boundary request contract",
         Test_Id => "macos.nsaccessibility.abi_surface.compile");
      Add
        (Items,
         MacOS_NSAX_Provider_Boundary,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "selector provider boundary and payload admission",
         Test_Id => "macos.nsaccessibility.provider_boundary.compile");
      Add
        (Items,
         MacOS_NSAX_Bridge_Audit,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "Objective-C bridge audit for calling convention, nullability, lifetime, and representation",
         Test_Id => "macos.nsaccessibility.bridge_audit.router");
      Add
        (Items,
         MacOS_NSAX_Native_Status_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "structured status to stable NSAccessibility native status table",
         Test_Id => "macos.nsaccessibility.native_status_map.router");
      Add
        (Items,
         MacOS_NSAX_Native_Status_Inverse_Map,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "NSAccessibility native status to structured status table",
         Test_Id => "macos.nsaccessibility.native_status_inverse_map.router");
      Add
        (Items,
         MacOS_NSAX_Native_Status_Diagnostic,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "bounded NSAccessibility native-status diagnostics",
         Test_Id => "macos.nsaccessibility.native_status_diagnostic.router");
      Add
        (Items,
         Native_Object_Cache_Identity,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "stable semantic identity to native element identity registry",
         Test_Id => "native.object_cache.identity.macos");
      Add
        (Items,
         MacOS_NSAX_Element_Registry,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "stable Node_Id to NSAccessibility element registry",
         Test_Id => "macos.nsaccessibility.element_registry.compile");
      Add
        (Items,
         MacOS_NSAX_Element_Lifetime,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSAccessibilityElement identity and retain scaffold",
         Test_Id => "macos.nsaccessibility.element_lifetime.compile");
      Add
        (Items,
         Native_Object_Export_Descriptor,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "backend-private native element export descriptor",
         Test_Id => "native.object_export_descriptor.macos");
      Add
        (Items,
         MacOS_NSAX_Element_Export_Descriptor,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "Objective-C-free NSAccessibility element export descriptor",
         Test_Id => "macos.nsaccessibility.element_export_descriptor.router");
      Add
        (Items,
         MacOS_NSAX_Public_Root_Export,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "backend-owned public root element export and selector-frame surface",
         Test_Id => "macos.nsaccessibility.public_root_export.router");
      Add
        (Items,
         MacOS_NSAX_Public_Root_Native_Identity,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "public root native node component derived from neutral runtime identifier",
         Test_Id => "macos.nsaccessibility.public_root.native_identity.router");
      Add
        (Items,
         MacOS_NSAX_Public_Root_Hit_Test_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "public root NSAccessibility hit-test selector frame",
         Test_Id => "macos.nsaccessibility.public_root.hit_test_frame.router");
      Add
        (Items,
         MacOS_NSAX_Public_Root_Focused_Element_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "public root NSAccessibility focused-element selector frame",
         Test_Id =>
           "macos.nsaccessibility.public_root.focused_element_frame.router");
      Add
        (Items,
         MacOS_NSAX_Public_Root_Notification_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "public root NSAccessibility notification selector frame",
         Test_Id =>
           "macos.nsaccessibility.public_root.notification_frame.router");
      Add
        (Items,
         MacOS_NSAX_Native_Bridge_Binding,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "Ada import binding for the audited minimal Objective-C bridge symbols",
         Test_Id => "macos.nsaccessibility.native_bridge_binding.router");
      Add
        (Items,
         MacOS_NSAX_Virtual_Element_Bridge,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "minimal NSAccessibilityElement subclass creation and stable identity matching",
         Test_Id => "macos.nsaccessibility.virtual_element_bridge.router");
      Add
        (Items,
         MacOS_NSAX_External_Client_Blocked_Probe,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "blocked external AX client probe until live AppKit bridge",
         Test_Id =>
           "macos.nsaccessibility.external_client.blocked_probe");
      Add
        (Items,
         MacOS_NSAX_External_Client_Failure_Stage,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "ordered external AX client failure-stage diagnostics",
         Test_Id =>
           "macos.nsaccessibility.external_client.failure_stage");
      Add
        (Items,
         Native_Readiness_Remaining_Evidence,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "aggregate NSAccessibility readiness remaining-evidence classifier",
         Test_Id =>
           "native.readiness.remaining_evidence.macos");
      Add
        (Items,
         Native_Readiness_Boundary_Stage,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "aggregate NSAccessibility readiness native-boundary stage classifier",
         Test_Id =>
           "native.readiness.boundary_stage.macos");
      Add
        (Items,
         MacOS_NSAX_Selector_Children_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "accessibilityChildren through ABI selector frame",
         Test_Id =>
           "macos.nsaccessibility.selector.children_frame.router");
      Add
        (Items,
         MacOS_NSAX_Selector_Child_At_Index_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "accessibilityChildAtIndex: through ABI selector frame",
         Test_Id =>
           "macos.nsaccessibility.selector.child_at_index_frame.router");
      Add
        (Items,
         MacOS_NSAX_Selector_Attribute_Value_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "accessibilityAttributeValue: through ABI selector frame",
         Test_Id =>
           "macos.nsaccessibility.selector.attribute_value_frame.router");
      Add
        (Items,
         MacOS_NSAX_Selector_Attribute_Settable_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "accessibilityIsAttributeSettable: through ABI selector frame",
         Test_Id =>
           "macos.nsaccessibility.selector.attribute_settable_frame.router");
      Add
        (Items,
         MacOS_NSAX_Selector_Action_Frame,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping =>
           "accessibilityPerformAction: through ABI selector frame to semantic action route",
         Test_Id =>
           "macos.nsaccessibility.selector.action_frame.router");
      Add
        (Items,
         MacOS_NSAX_Native_Values,
         "NSAccessibility",
         Internal_Only,
         Native_Mapping => "NSString/NSArray ownership scaffold",
         Test_Id => "macos.nsaccessibility.native_values.compile");
      return Items;
   end MacOS_NSAccessibility_Declarations;

   procedure Append_All
     (Target : in out Declaration_Vectors.Vector;
      Source : Declaration_Vectors.Vector) is
   begin
      for Item of Source loop
         Target.Append (Item);
      end loop;
   end Append_All;

   function All_Declarations return Declaration_Vectors.Vector is
      Items : Declaration_Vectors.Vector;
   begin
      Append_All (Items, Null_Backend_Declarations);
      Append_All (Items, Disabled_Backend_Declarations);
      Append_All (Items, Linux_ATSPI_Declarations);
      Append_All (Items, Windows_UIA_Declarations);
      Append_All (Items, MacOS_NSAccessibility_Declarations);
      return Items;
   end All_Declarations;

end A11y.Conformance;
