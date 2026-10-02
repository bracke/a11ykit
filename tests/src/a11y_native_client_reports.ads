package A11y_Native_Client_Reports is
   Schema : constant String := "org.a11y.native_client_observation.v1";

   type Client_Kind is (Linux_ATSPI, Windows_UIA, MacOS_NSAccessibility);

   function Platform_Name (Client : Client_Kind) return String;
   function Native_API_Name (Client : Client_Kind) return String;
   function Client_Process_Name (Client : Client_Kind) return String;
   function Status_Name return String;
   function Status_Name (Client : Client_Kind) return String;
   function Observation_Count return Natural;
   function Protected_Observation_Count return Natural;
   function Lifecycle_Observation_Count return Natural;
   function Transport_Observation_Count return Natural;
   function Semantic_Node_Identity_Count return Natural;
   function Has_Native_Registry_Observation return Boolean;
   function Has_Native_Export_Descriptor_Observation return Boolean;
   function Has_Windows_UIA_Host_Window_Root_Binding_Observation
      return Boolean;
   function Has_Windows_UIA_COM_VTable_Observation return Boolean;
   function Has_Windows_UIA_COM_Object_Export_Observation return Boolean;
   function Has_Windows_UIA_COM_Live_Export_Observation return Boolean;
   function Has_Windows_UIA_Bridge_Audit_Observation return Boolean;
   function Has_Windows_UIA_COM_Live_Interface_Retain_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Interface_Release_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Released_Interface_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation
      return Boolean;
   function Has_Windows_UIA_Registered_Routed_Error_Status_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Provider_Options_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Root_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation
      return Boolean;
   function Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
      return Boolean;
   function Has_Windows_UIA_Public_Root_Export_Path_Observation
      return Boolean;
   function Has_Windows_UIA_Public_Root_Native_Identity_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Provider_Options_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Fragment_Root_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Full_Frame_Callback_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Action_Frame_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Failure_Stage_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Metadata_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Metadata_Group_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Protected_Value_Observation
      return Boolean;
   function Has_Windows_UIA_External_Client_Privacy_Boundary_Observation
      return Boolean;
   function Has_Windows_UIA_Internal_Native_Export_Chain_Ready
      return Boolean;
   function Has_MacOS_NSAX_Main_Thread_Binding_Observation return Boolean;
   function Has_MacOS_NSAX_Native_View_Binding_Observation return Boolean;
   function Has_MacOS_NSAX_Selector_Attribute_Value_Observation
      return Boolean;
   function Has_MacOS_NSAX_Selector_Children_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Selector_Action_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Selector_Unsupported_Observation return Boolean;
   function Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation
      return Boolean;
   function Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation
      return Boolean;
   function Has_MacOS_NSAX_Registered_Routed_Error_Status_Observation
      return Boolean;
   function Has_MacOS_NSAX_Released_Boundary_Observation return Boolean;
   function Has_MacOS_NSAX_Bridge_Audit_Observation return Boolean;
   function Has_MacOS_NSAX_Virtual_Element_Bridge_Observation
     return Boolean;
   function Has_MacOS_NSAX_External_Client_Element_Chain_Observation
     return Boolean;
   function Has_MacOS_NSAX_Public_Root_Export_Path_Observation
      return Boolean;
   function Has_MacOS_NSAX_Public_Root_Native_Identity_Observation
      return Boolean;
   function Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Children_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Action_Frame_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Failure_Stage_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Metadata_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Metadata_Group_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Protected_Value_Observation
      return Boolean;
   function Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation
      return Boolean;
   function Has_MacOS_NSAX_Internal_Native_Export_Chain_Ready
      return Boolean;
   function Has_Native_Node_Index_Observation return Boolean;
   function Has_Native_Cache_Tombstone_Observation return Boolean;
   function Has_Native_Cache_Session_Scope_Observation return Boolean;
   function Has_Native_Runtime_Lifecycle_Observation return Boolean;
   function Has_Native_Runtime_Lifecycle_Report_Observation return Boolean;
   function Has_Native_Runtime_Probe_Failure_Stage_Observation return Boolean;
   function Has_Native_Runtime_Event_Application_Observation return Boolean;
   function Has_Native_Runtime_Event_Preparation_Observation return Boolean;
   function Has_Native_Runtime_Event_Preparation_Report_Observation
      return Boolean;
   function Has_Native_Projection_Property_Observation return Boolean;
   function Has_Native_Projection_Action_Observation return Boolean;
   function Has_Native_Projection_Relation_Observation return Boolean;
   function Has_Native_Projection_Event_Source_Observation return Boolean;
   function Has_Native_Deterministic_Shutdown_Observation return Boolean;
   function Has_Diagnostics_Bounded_Observation return Boolean;
   function Has_Diagnostics_Result_Mapping_Observation return Boolean;
   function Has_Diagnostics_Field_Bounds_Observation return Boolean;
   function Has_Native_Resource_Limit_Observation return Boolean;
   function Has_Native_Value_Resource_Limit_Observation return Boolean;
   function Has_Hostile_Identity_Observation return Boolean;
   function Has_Native_Boundary_Admission_Report_Observation return Boolean;
   function Has_Native_Boundary_Native_Call_Report_Observation return Boolean;
   function Has_Native_Boundary_Completion_Report_Observation return Boolean;
   function Has_Native_Boundary_Release_Report_Observation return Boolean;
   function Has_Native_Fixture_Root_Probe_Observation return Boolean;
   function Has_Native_Fixture_Root_Failure_Stage_Observation return Boolean;
   function Has_Native_Fixture_Root_Child_Traversal_Observation return Boolean;
   function Has_Native_Fixture_Root_Child_Count_Observation return Boolean;
   function Has_Native_Fixture_Root_Second_Child_Observation return Boolean;
   function Has_Native_Fixture_Child_Query_Observation return Boolean;
   function Has_Native_Fixture_Child_Object_Observation return Boolean;
   function Has_Native_Fixture_Child_Parent_Observation return Boolean;
   function Has_Native_Fixture_Child_Native_Identity_Observation return Boolean;
   function Has_Native_Fixture_Second_Child_Parent_Observation return Boolean;
   function Has_Native_Fixture_Second_Child_Native_Identity_Observation
      return Boolean;
   function Has_Native_Fixture_Sibling_Order_Observation return Boolean;
   function Has_Native_Fixture_Child_Stale_Id_Observation return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Probe_Observation return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Property_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Core_Observations return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Interaction_Observations
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Content_Observations return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Observation
      return Boolean;
   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation
      return Boolean;
   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation
      return Boolean;
   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation
      return Boolean;
   function
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation
      return Boolean;
   function Has_Linux_ATSPI_Serving_Packet_Full_Observations return Boolean;
   function Has_Linux_ATSPI_Session_Bus_Probe_Observation return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Observation return Boolean;
   function Has_Linux_ATSPI_Live_Registered_External_Client_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Attribute_Observation
      return Boolean;
   function
      Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Component_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Action_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Value_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Selection_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Text_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Image_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Document_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Table_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Surface_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation
      return Boolean;
   function Has_Linux_ATSPI_Session_Startup_Stage_Observation return Boolean;
   function Has_Linux_ATSPI_Startup_Object_Path_Observation return Boolean;
   function Has_Linux_ATSPI_Session_Dispatch_Probe_Observation return Boolean;
   function Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation
      return Boolean;
   function Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation
      return Boolean;
   function Has_Linux_ATSPI_Registered_Boundary_Report_Observation
      return Boolean;
   function Has_Malformed_Request_Observation return Boolean;
   function Has_Linux_Error_Name_Map_Observation return Boolean;
   function Has_Linux_Error_Name_Inverse_Map_Observation return Boolean;
   function Has_Linux_Error_Name_Diagnostic_Observation return Boolean;
   function Has_Linux_ATSPI_Core_Method_Observations return Boolean;
   function Has_Linux_ATSPI_Interaction_Method_Observations return Boolean;
   function Has_Linux_ATSPI_Component_Focus_Observation return Boolean;
   function Has_Linux_ATSPI_Selection_Deselect_Observation return Boolean;
   function Has_Linux_ATSPI_Selection_Select_All_Observation return Boolean;
   function Has_Linux_ATSPI_Selection_Clear_Observation return Boolean;
   function Has_Linux_ATSPI_Content_Method_Observations return Boolean;
   function Has_Linux_ATSPI_Document_Surface_Event_Observations return Boolean;
   function Has_Windows_UIA_Core_Routing_Observations return Boolean;
   function Has_Windows_UIA_Metadata_Property_Observation return Boolean;
   function Has_Windows_UIA_Protected_Value_Observation return Boolean;
   function Has_Windows_UIA_Advanced_Routing_Observations return Boolean;
   function Has_Windows_UIA_Selection_Select_All_Observation return Boolean;
   function Has_Windows_UIA_Selection_Clear_Observation return Boolean;
   function Has_Linux_DBus_Unsupported_Value_Observation return Boolean;
   function Has_Linux_DBus_UInt32_Array_Value_Observation return Boolean;
   function Has_Linux_DBus_State_Set_UInt32_Array_Observation return Boolean;
   function Has_Linux_DBus_String_Array_Value_Observation return Boolean;
   function Has_Linux_DBus_Attribute_String_Array_Observation return Boolean;
   function Has_Linux_DBus_Cache_Interface_String_Array_Observation
      return Boolean;
   function Has_Linux_DBus_Object_Path_Array_Value_Observation return Boolean;
   function Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation
      return Boolean;
   function Has_Windows_HResult_Map_Observation return Boolean;
   function Has_Windows_HResult_Inverse_Map_Observation return Boolean;
   function Has_Windows_HResult_Diagnostic_Observation return Boolean;
   function Has_Windows_UIA_Event_Posting_Admission_Observation return Boolean;
   function Has_Windows_UIA_Event_Posting_Report_Observation return Boolean;
   function Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation
      return Boolean;
   function Has_Windows_UIA_Native_Focus_Query_Observation return Boolean;
   function Has_Windows_UIA_Native_Set_Focus_Observation return Boolean;
   function Has_Windows_UIA_Hostile_Callback_Admission_Observation
      return Boolean;
   function Has_Windows_UIA_Missing_Identity_Observation return Boolean;
   function Has_Windows_UIA_Mismatched_Identity_Observation return Boolean;
   function Has_Windows_UIA_Malformed_Identity_Observation return Boolean;
   function Has_Windows_UIA_Text_Payload_Limit_Observation return Boolean;
   function Has_MacOS_Native_Status_Map_Observation return Boolean;
   function Has_MacOS_Native_Status_Inverse_Map_Observation return Boolean;
   function Has_MacOS_Native_Status_Diagnostic_Observation return Boolean;
   function Has_MacOS_NSAX_Event_Posting_Admission_Observation return Boolean;
   function Has_MacOS_NSAX_Event_Posting_Report_Observation return Boolean;
   function Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation
      return Boolean;
   function Has_MacOS_NSAX_Native_Focus_Query_Observation return Boolean;
   function Has_MacOS_NSAX_Native_Set_Focus_Observation return Boolean;
   function Has_MacOS_NSAX_Hostile_Callback_Admission_Observation
      return Boolean;
   function Has_MacOS_NSAX_Missing_Identity_Observation return Boolean;
   function Has_MacOS_NSAX_Mismatched_Identity_Observation return Boolean;
   function Has_MacOS_NSAX_Malformed_Identity_Observation return Boolean;
   function Has_MacOS_NSAX_Text_Payload_Limit_Observation return Boolean;
   function Has_MacOS_NSAX_Core_Routing_Observations return Boolean;
   function Has_MacOS_NSAX_Metadata_Attribute_Observation return Boolean;
   function Has_MacOS_NSAX_Protected_Value_Observation return Boolean;
   function Has_MacOS_NSAX_Advanced_Routing_Observations return Boolean;
   function Has_MacOS_NSAX_Selection_Select_All_Observation return Boolean;
   function Has_MacOS_NSAX_Selection_Clear_Observation return Boolean;
   function Has_Transport_Staging_Observation return Boolean;
   function Has_Transport_Generation_Observation return Boolean;
   function Has_Transport_Transition_Report_Observation return Boolean;
   function Has_Native_Cache_Generation_Observation return Boolean;
   function Has_Native_Cache_Mutation_Report_Observation return Boolean;
   function Has_Native_Registry_Generation_Observation return Boolean;
   function Has_Native_Registry_Drained_Reset_Observation return Boolean;
   function Has_Native_Registry_Mutation_Report_Observation return Boolean;
   function Has_Native_Boundary_Runtime_Generation_Observation return Boolean;
   function Has_Prepared_Status_Observation return Boolean;
   function Has_Event_Posting_Interest_Observation return Boolean;
   function Has_Native_Event_Validation_Observation return Boolean;
   function Has_Native_Event_Posting_Boundary_Observation return Boolean;
   function Has_Native_Event_Exhaustive_Map_Observation return Boolean;
   function Has_Native_Role_Exhaustive_Map_Observation return Boolean;
   function Has_Native_Relation_Exhaustive_Map_Observation return Boolean;
   function Has_Method_Return_Decode_Observation return Boolean;
   function Has_Error_Return_Decode_Observation return Boolean;
   function Has_Error_Return_Diagnostic_Observation return Boolean;
   function Has_Startup_Error_Completion_Observation return Boolean;
   function Has_Incoming_Packet_Classification_Observation return Boolean;
   function Has_Startup_Outgoing_Work_Observation return Boolean;
   function Has_Startup_Event_Loop_Interest_Observation return Boolean;
   function Has_Startup_Event_Loop_Operation_Observation return Boolean;
   function Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation
      return Boolean;
   function
     Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation
     return Boolean;
   function Has_Startup_Outgoing_Flush_Observation return Boolean;
   function Has_Linux_DBus_Outgoing_Back_Pressure_Observation return Boolean;
   function Has_Linux_DBus_Connection_Lifecycle_Observation return Boolean;
   function Has_Linux_DBus_Local_Channel_Adapter_Observation return Boolean;
   function Has_Linux_DBus_Local_Channel_Receive_Observation return Boolean;
   function Has_Linux_DBus_Startup_Controller_Observation return Boolean;
   function Has_Linux_DBus_Startup_Backend_Adapter_Observation
      return Boolean;
   function Has_Linux_DBus_Startup_Pump_Observation return Boolean;
   function Has_Linux_DBus_Startup_Pump_Report_Observation return Boolean;
   function Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation
      return Boolean;
   function Has_Linux_DBus_Startup_Pump_Bounds_Observation return Boolean;
   function Has_Linux_DBus_Startup_Registered_Pump_Observation
      return Boolean;
   function Has_Linux_DBus_Bus_Address_Observation return Boolean;
   function Has_Linux_DBus_Auth_External_Observation return Boolean;
   function Has_Linux_DBus_Auth_Exchange_Observation return Boolean;
   function Has_Linux_DBus_Authenticated_Connect_Observation return Boolean;
   function Has_Linux_DBus_Hello_Observation return Boolean;
   function Has_Linux_DBus_Authenticated_Hello_Observation return Boolean;
   function Has_Linux_DBus_Registration_Completion_Observation
      return Boolean;
   function Has_Linux_DBus_Authenticated_Registration_Observation
      return Boolean;
   function Has_Linux_DBus_Startup_Reply_Evidence_Observation
      return Boolean;
   function Has_Linux_DBus_Application_Registration_Observation
      return Boolean;
   function Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation
      return Boolean;
   function Has_Linux_DBus_Address_Discovery_Observation return Boolean;
   function Has_Linux_DBus_Host_Environment_Startup_Observation
      return Boolean;
   function Has_Linux_DBus_A11y_Bus_Get_Address_Observation return Boolean;
   function Has_Linux_DBus_Authenticated_Get_Address_Observation
      return Boolean;
   function Has_Linux_DBus_Startup_Session_Discovery_Observation
      return Boolean;
   function Has_Linux_DBus_Transport_Frame_Metadata_Observation
      return Boolean;
   function Has_Linux_DBus_Method_Call_Destination_Routing_Observation
      return Boolean;
   function Has_Linux_DBus_Transport_Frame_Bytes_Observation return Boolean;
   function Has_Linux_DBus_Transport_Frame_Send_Observation return Boolean;
   function Has_Linux_DBus_Transport_Packet_Observation return Boolean;
   function Has_Linux_DBus_Transport_Packet_Send_Observation return Boolean;
   function Has_Linux_DBus_Transport_Packet_Decode_Observation return Boolean;
   function Has_Linux_DBus_Codec_Basic_Observation return Boolean;
   function Has_Linux_DBus_Resource_Limits_Observation return Boolean;
   function Has_Linux_DBus_Message_Envelope_Observation return Boolean;
   function Has_Linux_DBus_Method_Call_Envelope_Observation return Boolean;
   function Has_Linux_DBus_Transport_Envelope_Decode_Observation
      return Boolean;
   function Has_Linux_DBus_Incoming_Call_Decode_Observation return Boolean;
   function Has_Linux_DBus_Signal_Envelope_Observation return Boolean;
   function Has_Linux_DBus_Prepared_Signal_Envelope_Observation
      return Boolean;
   function Has_Linux_ATSPI_Signal_Build_Report_Observation return Boolean;
   function Has_Linux_DBus_Method_Boundary_Observation return Boolean;
   function Has_Focus_Observation return Boolean;
   function Has_Property_Change_Observation return Boolean;
   function Has_Orientation_Property_Event_Observation return Boolean;
   function Has_Set_Position_Property_Event_Observation return Boolean;
   function Has_Set_Size_Property_Event_Observation return Boolean;
   function Has_Hierarchical_Level_Property_Event_Observation return Boolean;
   function Has_Role_Property_Observation return Boolean;
   function Has_State_Set_Property_Observation return Boolean;
   function Has_Name_Observation return Boolean;
   function Has_Description_Observation return Boolean;
   function Has_Help_Text_Observation return Boolean;
   function Has_Placeholder_Observation return Boolean;
   function Has_Value_Text_Observation return Boolean;
   function Has_Keyboard_Shortcut_Observation return Boolean;
   function Has_Semantic_Identifier_Observation return Boolean;
   function Has_Locale_Property_Observation return Boolean;
   function Has_Visible_Title_Property_Observation return Boolean;
   function Has_Orientation_Property_Observation return Boolean;
   function Has_Set_Position_Property_Observation return Boolean;
   function Has_Set_Size_Property_Observation return Boolean;
   function Has_Hierarchical_Level_Property_Observation return Boolean;
   function Has_Heading_Level_Property_Observation return Boolean;
   function Has_Landmark_Property_Observation return Boolean;
   function Has_Bounds_Property_Observation return Boolean;
   function Has_State_Change_Observation return Boolean;
   function Has_Bounds_Observation return Boolean;
   function Has_Hit_Test_Observation return Boolean;
   function Has_Tree_Change_Observation return Boolean;
   function Has_Window_Event_Observation return Boolean;
   function Has_Activate_Action_Observation return Boolean;
   function Has_Action_Observation return Boolean;
   function Has_Toggle_Action_Observation return Boolean;
   function Has_Expand_Action_Observation return Boolean;
   function Has_Collapse_Action_Observation return Boolean;
   function Has_Show_Menu_Action_Observation return Boolean;
   function Has_Dismiss_Action_Observation return Boolean;
   function Has_Open_Action_Observation return Boolean;
   function Has_Close_Action_Observation return Boolean;
   function Has_Scroll_Action_Observation return Boolean;
   function Has_Set_Focus_Action_Observation return Boolean;
   function Has_Action_Payload_Observation return Boolean;
   function Has_Action_Request_Payload_Observation return Boolean;
   function Has_Value_Observation return Boolean;
   function Has_Selection_Observation return Boolean;
   function Has_Select_All_Observation return Boolean;
   function Has_Selection_Event_Observation return Boolean;
   function Has_Active_Descendant_Observation return Boolean;
   function Has_Active_Descendant_Event_Observation return Boolean;
   function Has_Current_Item_Observation return Boolean;
   function Has_Current_Item_Event_Observation return Boolean;
   function Has_Tree_Role_Observation return Boolean;
   function Has_Tree_Item_Role_Observation return Boolean;
   function Has_Menu_Bar_Role_Observation return Boolean;
   function Has_Menu_Role_Observation return Boolean;
   function Has_Menu_Item_Role_Observation return Boolean;
   function Has_Tab_List_Role_Observation return Boolean;
   function Has_Tab_Role_Observation return Boolean;
   function Has_Tooltip_Role_Observation return Boolean;
   function Has_Status_Role_Observation return Boolean;
   function Has_Image_Role_Observation return Boolean;
   function Has_Decorative_Image_Role_Observation return Boolean;
   function Has_Vertical_Slice_Role_Observations return Boolean;
   function Has_Extended_Fixture_Role_Observations return Boolean;
   function Has_Fixture_Command_Coverage return Boolean;
   function Has_Text_Observation return Boolean;
   function Has_Text_Mutation_Observation return Boolean;
   function Has_Text_Set_Observation return Boolean;
   function Has_Caret_Observation return Boolean;
   function Has_Table_Observation return Boolean;
   function Has_Table_Current_Cell_Observation return Boolean;
   function Has_Table_Sort_Metadata_Observation return Boolean;
   function Has_Table_Event_Observation return Boolean;
   function Has_Image_Observation return Boolean;
   function Has_Document_Observation return Boolean;
   function Has_Document_Event_Observation return Boolean;
   function Has_Protected_Text_Observation return Boolean;
   function Has_Live_Region_Observation return Boolean;
   function Has_Relation_Observation return Boolean;
   function Has_Relation_Event_Observation return Boolean;
   function Has_Surface_Observation return Boolean;
   function Has_Lifecycle_Observation return Boolean;
   function Has_Required_Conformance_Evidence return Boolean;
   function Client_Report_Complete (Client : Client_Kind) return Boolean;
   function All_Client_Reports_Blocked return Boolean;
   function JSON (Client : Client_Kind) return String;
end A11y_Native_Client_Reports;
