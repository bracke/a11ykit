with Ada.Strings.Unbounded;

with A11y.Platforms;
with A11y_Release_Qualification;
with A11y_Native_Client_Reports;

package body A11y_Native_Observation_Report is
   use Ada.Strings.Unbounded;
   use type A11y.Platforms.Platform_Kind;
   use type A11y_Native_Client_Reports.Client_Kind;

   type Client_Record is record
      Platform : String (1 .. 16);
      Native_API : String (1 .. 24);
      Native_Evidence_Scope : String (1 .. 24);
      Row_Scopes_ATSPI : Boolean := False;
      Row_Scopes_UIA : Boolean := False;
      Row_Scopes_NSAccessibility : Boolean := False;
      Native_Bridge_Compiled_For_Windows : Boolean := False;
      Windows_Native_Bridge_Stub_Runtime : Boolean := False;
      Native_Bridge_Compiled_For_MacOS : Boolean := False;
      MacOS_Native_Bridge_Stub_Runtime : Boolean := False;
      Client_Process : String (1 .. 32);
      Fixture_Command : String (1 .. 32);
      Fixture_Host_Env_Serve_Command : String (1 .. 96);
      Runtime_Probe_Command : String (1 .. 96);
      Registered_Boundary_Probe_Command : String (1 .. 96);
      Host_Environment_Probe_Command : String (1 .. 96);
      Fixture_Native_Probe_Command : String (1 .. 96);
      Serving_Packet_Probe_Command : String (1 .. 96);
      Session_Bus_Probe_Command : String (1 .. 96);
      Session_Dispatch_Probe_Command : String (1 .. 96);
      External_Client_Probe_Command : String (1 .. 96);
      Status : String (1 .. 40);
      Normalized_Output : String (1 .. 48);
      Observation_Count : Natural := 0;
      Has_Native_Registry_Observation : Boolean := False;
      Has_Native_Export_Descriptor_Observation : Boolean := False;
      Has_Windows_UIA_Host_Window_Root_Binding_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_VTable_Observation : Boolean := False;
      Has_Windows_UIA_COM_Object_Export_Observation : Boolean := False;
      Has_Windows_UIA_COM_Live_Export_Observation : Boolean := False;
      Has_Windows_UIA_Bridge_Audit_Observation : Boolean := False;
      Has_Windows_UIA_COM_Live_Interface_Retain_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Interface_Release_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Released_Interface_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Provider_Options_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Root_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation :
        Boolean := False;
      Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_COM_Live_Chain_Observation :
        Boolean := False;
      Has_Windows_UIA_Public_Root_Export_Path_Observation :
        Boolean := False;
      Has_Windows_UIA_Public_Root_Native_Identity_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Provider_Options_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Fragment_Root_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Action_Frame_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Failure_Stage_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Metadata_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Metadata_Group_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Protected_Value_Observation :
        Boolean := False;
      Has_Windows_UIA_External_Client_Privacy_Boundary_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Main_Thread_Binding_Observation : Boolean := False;
      Has_MacOS_NSAX_Native_View_Binding_Observation : Boolean := False;
      Has_MacOS_NSAX_Selector_Attribute_Value_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Selector_Children_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Selector_Action_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Selector_Unsupported_Observation : Boolean := False;
      Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Released_Boundary_Observation : Boolean := False;
      Has_MacOS_NSAX_Bridge_Audit_Observation : Boolean := False;
      Has_MacOS_NSAX_Virtual_Element_Bridge_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Element_Chain_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Public_Root_Export_Path_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Public_Root_Native_Identity_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Children_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Action_Frame_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Failure_Stage_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Metadata_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Metadata_Group_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Protected_Value_Observation :
        Boolean := False;
      Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation :
        Boolean := False;
      Has_Native_Node_Index_Observation : Boolean := False;
      Has_Native_Cache_Tombstone_Observation : Boolean := False;
      Has_Native_Cache_Session_Scope_Observation : Boolean := False;
      Has_Native_Runtime_Lifecycle_Observation : Boolean := False;
      Has_Native_Runtime_Lifecycle_Report_Observation : Boolean := False;
      Has_Native_Runtime_Probe_Failure_Stage_Observation : Boolean := False;
      Has_Native_Runtime_Event_Application_Observation : Boolean := False;
      Has_Native_Runtime_Event_Preparation_Observation : Boolean := False;
      Has_Native_Runtime_Event_Preparation_Report_Observation :
        Boolean := False;
      Has_Native_Projection_Property_Observation : Boolean := False;
      Has_Native_Projection_Action_Observation : Boolean := False;
      Has_Native_Projection_Relation_Observation : Boolean := False;
      Has_Native_Projection_Event_Source_Observation : Boolean := False;
      Has_Native_Deterministic_Shutdown_Observation : Boolean := False;
      Has_Diagnostics_Bounded_Observation : Boolean := False;
      Has_Diagnostics_Result_Mapping_Observation : Boolean := False;
      Has_Diagnostics_Field_Bounds_Observation : Boolean := False;
      Has_Native_Resource_Limit_Observation : Boolean := False;
      Has_Native_Value_Resource_Limit_Observation : Boolean := False;
      Has_Hostile_Identity_Observation : Boolean := False;
      Has_Native_Boundary_Admission_Report_Observation : Boolean := False;
      Has_Native_Boundary_Native_Call_Report_Observation : Boolean := False;
      Has_Native_Boundary_Completion_Report_Observation : Boolean := False;
      Has_Native_Boundary_Release_Report_Observation : Boolean := False;
      Has_Native_Fixture_Root_Probe_Observation : Boolean := False;
      Has_Native_Fixture_Root_Failure_Stage_Observation : Boolean := False;
      Has_Native_Fixture_Root_Child_Traversal_Observation :
        Boolean := False;
      Has_Native_Fixture_Root_Child_Count_Observation : Boolean := False;
      Has_Native_Fixture_Root_Second_Child_Observation : Boolean := False;
      Has_Native_Fixture_Child_Query_Observation : Boolean := False;
      Has_Native_Fixture_Child_Object_Observation : Boolean := False;
      Has_Native_Fixture_Child_Parent_Observation : Boolean := False;
      Has_Native_Fixture_Child_Native_Identity_Observation :
        Boolean := False;
      Has_Native_Fixture_Second_Child_Parent_Observation : Boolean := False;
      Has_Native_Fixture_Second_Child_Native_Identity_Observation :
        Boolean := False;
      Has_Native_Fixture_Sibling_Order_Observation : Boolean := False;
      Has_Native_Fixture_Child_Stale_Id_Observation : Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Probe_Observation : Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Property_Observation : Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Session_Bus_Probe_Observation : Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Observation : Boolean := False;
      Has_Linux_ATSPI_Live_Registered_External_Client_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Attribute_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Component_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Action_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Value_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Selection_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Text_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Image_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Document_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Table_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Surface_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Session_Startup_Stage_Observation : Boolean := False;
      Has_Linux_ATSPI_Startup_Object_Path_Observation : Boolean := False;
      Has_Linux_ATSPI_Session_Dispatch_Probe_Observation : Boolean := False;
      Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation :
        Boolean := False;
      Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation :
        Boolean := False;
      Has_Linux_ATSPI_Registered_Boundary_Report_Observation :
        Boolean := False;
      Has_Malformed_Request_Observation : Boolean := False;
      Has_Linux_Error_Name_Map_Observation : Boolean := False;
      Has_Linux_Error_Name_Inverse_Map_Observation : Boolean := False;
      Has_Linux_Error_Name_Diagnostic_Observation : Boolean := False;
      Has_Linux_ATSPI_Core_Method_Observations : Boolean := False;
      Has_Linux_ATSPI_Interaction_Method_Observations : Boolean := False;
      Has_Linux_ATSPI_Component_Focus_Observation : Boolean := False;
      Has_Linux_ATSPI_Selection_Deselect_Observation : Boolean := False;
      Has_Linux_ATSPI_Selection_Select_All_Observation : Boolean := False;
      Has_Linux_ATSPI_Selection_Clear_Observation : Boolean := False;
      Has_Linux_ATSPI_Content_Method_Observations : Boolean := False;
      Has_Linux_ATSPI_Document_Surface_Event_Observations : Boolean := False;
      Has_Linux_DBus_Unsupported_Value_Observation : Boolean := False;
      Has_Linux_DBus_UInt32_Array_Value_Observation : Boolean := False;
      Has_Linux_DBus_State_Set_UInt32_Array_Observation : Boolean := False;
      Has_Linux_DBus_String_Array_Value_Observation : Boolean := False;
      Has_Linux_DBus_Attribute_String_Array_Observation : Boolean := False;
      Has_Linux_DBus_Cache_Interface_String_Array_Observation :
        Boolean := False;
      Has_Linux_DBus_Object_Path_Array_Value_Observation : Boolean := False;
      Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation :
        Boolean := False;
      Has_Windows_HResult_Map_Observation : Boolean := False;
      Has_Windows_HResult_Inverse_Map_Observation : Boolean := False;
      Has_Windows_HResult_Diagnostic_Observation : Boolean := False;
      Has_Windows_UIA_Event_Posting_Admission_Observation :
        Boolean := False;
      Has_Windows_UIA_Event_Posting_Report_Observation : Boolean := False;
      Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation :
        Boolean := False;
      Has_Windows_UIA_Core_Routing_Observations : Boolean := False;
      Has_Windows_UIA_Metadata_Property_Observation : Boolean := False;
      Has_Windows_UIA_Protected_Value_Observation : Boolean := False;
      Has_Windows_UIA_Advanced_Routing_Observations : Boolean := False;
      Has_Windows_UIA_Selection_Select_All_Observation : Boolean := False;
      Has_Windows_UIA_Selection_Clear_Observation : Boolean := False;
      Has_Windows_UIA_Native_Focus_Query_Observation : Boolean := False;
      Has_Windows_UIA_Native_Set_Focus_Observation : Boolean := False;
      Has_Windows_UIA_Hostile_Callback_Admission_Observation :
        Boolean := False;
      Has_Windows_UIA_Missing_Identity_Observation : Boolean := False;
      Has_Windows_UIA_Mismatched_Identity_Observation : Boolean := False;
      Has_Windows_UIA_Malformed_Identity_Observation : Boolean := False;
      Has_Windows_UIA_Text_Payload_Limit_Observation : Boolean := False;
      Has_MacOS_Native_Status_Map_Observation : Boolean := False;
      Has_MacOS_Native_Status_Inverse_Map_Observation : Boolean := False;
      Has_MacOS_Native_Status_Diagnostic_Observation : Boolean := False;
      Has_MacOS_NSAX_Event_Posting_Admission_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Event_Posting_Report_Observation : Boolean := False;
      Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Core_Routing_Observations : Boolean := False;
      Has_MacOS_NSAX_Metadata_Attribute_Observation : Boolean := False;
      Has_MacOS_NSAX_Protected_Value_Observation : Boolean := False;
      Has_MacOS_NSAX_Advanced_Routing_Observations : Boolean := False;
      Has_MacOS_NSAX_Selection_Select_All_Observation : Boolean := False;
      Has_MacOS_NSAX_Selection_Clear_Observation : Boolean := False;
      Has_MacOS_NSAX_Native_Focus_Query_Observation : Boolean := False;
      Has_MacOS_NSAX_Native_Set_Focus_Observation : Boolean := False;
      Has_MacOS_NSAX_Hostile_Callback_Admission_Observation :
        Boolean := False;
      Has_MacOS_NSAX_Missing_Identity_Observation : Boolean := False;
      Has_MacOS_NSAX_Mismatched_Identity_Observation : Boolean := False;
      Has_MacOS_NSAX_Malformed_Identity_Observation : Boolean := False;
      Has_MacOS_NSAX_Text_Payload_Limit_Observation : Boolean := False;
      Has_Transport_Staging_Observation : Boolean := False;
      Has_Transport_Generation_Observation : Boolean := False;
      Has_Transport_Transition_Report_Observation : Boolean := False;
      Has_Native_Cache_Generation_Observation : Boolean := False;
      Has_Native_Cache_Mutation_Report_Observation : Boolean := False;
      Has_Native_Registry_Generation_Observation : Boolean := False;
      Has_Native_Registry_Drained_Reset_Observation : Boolean := False;
      Has_Native_Registry_Reset_Node_Rejection_Observation :
        Boolean := False;
      Has_Native_Registry_Reset_Stale_Id_Rejection_Observation :
        Boolean := False;
      Has_Native_Registry_Mutation_Report_Observation : Boolean := False;
      Has_Native_Boundary_Runtime_Generation_Observation : Boolean := False;
      Has_Prepared_Status_Observation : Boolean := False;
      Has_Event_Posting_Interest_Observation : Boolean := False;
      Has_Native_Event_Validation_Observation : Boolean := False;
      Has_Native_Event_Posting_Boundary_Observation : Boolean := False;
      Has_Native_Event_Exhaustive_Map_Observation : Boolean := False;
      Has_Native_Role_Exhaustive_Map_Observation : Boolean := False;
      Has_Native_Relation_Exhaustive_Map_Observation : Boolean := False;
      Has_Method_Return_Decode_Observation : Boolean := False;
      Has_Error_Return_Decode_Observation : Boolean := False;
      Has_Error_Return_Diagnostic_Observation : Boolean := False;
      Has_Startup_Error_Completion_Observation : Boolean := False;
      Has_Incoming_Packet_Classification_Observation : Boolean := False;
      Has_Startup_Outgoing_Work_Observation : Boolean := False;
      Has_Startup_Event_Loop_Interest_Observation : Boolean := False;
      Has_Startup_Event_Loop_Operation_Observation : Boolean := False;
      Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation :
        Boolean := False;
      Has_Startup_Outgoing_Flush_Observation : Boolean := False;
      Has_Linux_DBus_Outgoing_Back_Pressure_Observation : Boolean := False;
      Has_Linux_DBus_Connection_Lifecycle_Observation : Boolean := False;
      Has_Linux_DBus_Local_Channel_Adapter_Observation : Boolean := False;
      Has_Linux_DBus_Local_Channel_Receive_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Controller_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Backend_Adapter_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Pump_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Pump_Report_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation :
        Boolean := False;
      Has_Linux_DBus_Startup_Pump_Bounds_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Registered_Pump_Observation : Boolean := False;
      Has_Linux_DBus_Bus_Address_Observation : Boolean := False;
      Has_Linux_DBus_Auth_External_Observation : Boolean := False;
      Has_Linux_DBus_Auth_Exchange_Observation : Boolean := False;
      Has_Linux_DBus_Authenticated_Connect_Observation : Boolean := False;
      Has_Linux_DBus_Hello_Observation : Boolean := False;
      Has_Linux_DBus_Authenticated_Hello_Observation : Boolean := False;
      Has_Linux_DBus_Registration_Completion_Observation : Boolean := False;
      Has_Linux_DBus_Authenticated_Registration_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Reply_Evidence_Observation : Boolean := False;
      Has_Linux_DBus_Application_Registration_Observation : Boolean := False;
      Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation :
        Boolean := False;
      Has_Linux_DBus_Address_Discovery_Observation : Boolean := False;
      Has_Linux_DBus_Host_Environment_Startup_Observation : Boolean := False;
      Has_Linux_DBus_A11y_Bus_Get_Address_Observation : Boolean := False;
      Has_Linux_DBus_Authenticated_Get_Address_Observation : Boolean := False;
      Has_Linux_DBus_Startup_Session_Discovery_Observation : Boolean := False;
      Has_Linux_DBus_Transport_Frame_Metadata_Observation : Boolean := False;
      Has_Linux_DBus_Method_Call_Destination_Routing_Observation :
        Boolean := False;
      Has_Linux_DBus_Transport_Frame_Bytes_Observation : Boolean := False;
      Has_Linux_DBus_Transport_Frame_Send_Observation : Boolean := False;
      Has_Linux_DBus_Transport_Packet_Observation : Boolean := False;
      Has_Linux_DBus_Transport_Packet_Send_Observation : Boolean := False;
      Has_Linux_DBus_Transport_Packet_Decode_Observation : Boolean := False;
      Has_Linux_DBus_Codec_Basic_Observation : Boolean := False;
      Has_Linux_DBus_Resource_Limits_Observation : Boolean := False;
      Has_Linux_DBus_Message_Envelope_Observation : Boolean := False;
      Has_Linux_DBus_Method_Call_Envelope_Observation : Boolean := False;
      Has_Linux_DBus_Transport_Envelope_Decode_Observation : Boolean := False;
      Has_Linux_DBus_Incoming_Call_Decode_Observation : Boolean := False;
      Has_Linux_DBus_Signal_Envelope_Observation : Boolean := False;
      Has_Linux_DBus_Prepared_Signal_Envelope_Observation : Boolean := False;
      Has_Linux_ATSPI_Signal_Build_Report_Observation : Boolean := False;
      Has_Linux_DBus_Method_Boundary_Observation : Boolean := False;
      Has_Focus_Observation : Boolean := False;
      Has_Property_Change_Observation : Boolean := False;
      Has_Orientation_Property_Event_Observation : Boolean := False;
      Has_Set_Position_Property_Event_Observation : Boolean := False;
      Has_Set_Size_Property_Event_Observation : Boolean := False;
      Has_Hierarchical_Level_Property_Event_Observation : Boolean := False;
      Has_Role_Property_Observation : Boolean := False;
      Has_State_Set_Property_Observation : Boolean := False;
      Has_Name_Observation : Boolean := False;
      Has_Description_Observation : Boolean := False;
      Has_Help_Text_Observation : Boolean := False;
      Has_Placeholder_Observation : Boolean := False;
      Has_Value_Text_Observation : Boolean := False;
      Has_Keyboard_Shortcut_Observation : Boolean := False;
      Has_Semantic_Identifier_Observation : Boolean := False;
      Has_Locale_Property_Observation : Boolean := False;
      Has_Visible_Title_Property_Observation : Boolean := False;
      Has_Orientation_Property_Observation : Boolean := False;
      Has_Set_Position_Property_Observation : Boolean := False;
      Has_Set_Size_Property_Observation : Boolean := False;
      Has_Hierarchical_Level_Property_Observation : Boolean := False;
      Has_Heading_Level_Property_Observation : Boolean := False;
      Has_Landmark_Property_Observation : Boolean := False;
      Has_Bounds_Property_Observation : Boolean := False;
      Has_State_Change_Observation : Boolean := False;
      Has_Bounds_Observation : Boolean := False;
      Has_Hit_Test_Observation : Boolean := False;
      Has_Tree_Change_Observation : Boolean := False;
      Has_Window_Event_Observation : Boolean := False;
      Has_Activate_Action_Observation : Boolean := False;
      Has_Action_Observation : Boolean := False;
      Has_Toggle_Action_Observation : Boolean := False;
      Has_Expand_Action_Observation : Boolean := False;
      Has_Collapse_Action_Observation : Boolean := False;
      Has_Show_Menu_Action_Observation : Boolean := False;
      Has_Dismiss_Action_Observation : Boolean := False;
      Has_Open_Action_Observation : Boolean := False;
      Has_Close_Action_Observation : Boolean := False;
      Has_Scroll_Action_Observation : Boolean := False;
      Has_Set_Focus_Action_Observation : Boolean := False;
      Has_Action_Payload_Observation : Boolean := False;
      Has_Action_Request_Payload_Observation : Boolean := False;
      Has_Value_Observation : Boolean := False;
      Has_Selection_Observation : Boolean := False;
      Has_Select_All_Observation : Boolean := False;
      Has_Selection_Event_Observation : Boolean := False;
      Has_Active_Descendant_Observation : Boolean := False;
      Has_Active_Descendant_Event_Observation : Boolean := False;
      Has_Current_Item_Observation : Boolean := False;
      Has_Current_Item_Event_Observation : Boolean := False;
      Has_Tree_Role_Observation : Boolean := False;
      Has_Tree_Item_Role_Observation : Boolean := False;
      Has_Menu_Bar_Role_Observation : Boolean := False;
      Has_Menu_Role_Observation : Boolean := False;
      Has_Menu_Item_Role_Observation : Boolean := False;
      Has_Tab_List_Role_Observation : Boolean := False;
      Has_Tab_Role_Observation : Boolean := False;
      Has_Tooltip_Role_Observation : Boolean := False;
      Has_Status_Role_Observation : Boolean := False;
      Has_Image_Role_Observation : Boolean := False;
      Has_Decorative_Image_Role_Observation : Boolean := False;
      Has_Vertical_Slice_Role_Observations : Boolean := False;
      Has_Extended_Fixture_Role_Observations : Boolean := False;
      Has_Fixture_Command_Coverage : Boolean := False;
      Has_Text_Observation : Boolean := False;
      Has_Text_Mutation_Observation : Boolean := False;
      Has_Text_Set_Observation : Boolean := False;
      Has_Caret_Observation : Boolean := False;
      Has_Table_Observation : Boolean := False;
      Has_Table_Current_Cell_Observation : Boolean := False;
      Has_Table_Sort_Metadata_Observation : Boolean := False;
      Has_Table_Event_Observation : Boolean := False;
      Has_Image_Observation : Boolean := False;
      Has_Document_Observation : Boolean := False;
      Has_Document_Event_Observation : Boolean := False;
      Has_Protected_Text_Observation : Boolean := False;
      Has_Live_Region_Observation : Boolean := False;
      Has_Relation_Observation : Boolean := False;
      Has_Relation_Event_Observation : Boolean := False;
      Has_Surface_Observation : Boolean := False;
      Has_Lifecycle_Observation : Boolean := False;
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

   function Item
     (Client : A11y_Native_Client_Reports.Client_Kind;
      Normalized_Output : String) return Client_Record is
     ((Platform =>
         Pad (A11y_Native_Client_Reports.Platform_Name (Client), 16),
       Native_API =>
         Pad (A11y_Native_Client_Reports.Native_API_Name (Client), 24),
       Native_Evidence_Scope =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "atspi",
               when A11y_Native_Client_Reports.Windows_UIA =>
                 "uia",
               when A11y_Native_Client_Reports.MacOS_NSAccessibility =>
                 "nsaccessibility"),
            24),
      Row_Scopes_ATSPI => Client = A11y_Native_Client_Reports.Linux_ATSPI,
      Row_Scopes_UIA => Client = A11y_Native_Client_Reports.Windows_UIA,
      Row_Scopes_NSAccessibility =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility,
      Native_Bridge_Compiled_For_Windows =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then A11y.Platforms.Current = A11y.Platforms.Windows,
      Windows_Native_Bridge_Stub_Runtime =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then A11y.Platforms.Current /= A11y.Platforms.Windows,
      Native_Bridge_Compiled_For_MacOS =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
          (A11y.Platforms.Current = A11y.Platforms.MacOS
           or else
             A11y_Release_Qualification
               .MacOS_NSAccessibility_Public_Client_Traversal_Observed),
      MacOS_Native_Bridge_Stub_Runtime =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then A11y.Platforms.Current /= A11y.Platforms.MacOS
        and then not
          A11y_Release_Qualification
            .MacOS_NSAccessibility_Public_Client_Traversal_Observed,
      Client_Process =>
        Pad (A11y_Native_Client_Reports.Client_Process_Name (Client), 32),
       Fixture_Command => Pad ("fixture_application --json", 32),
       Fixture_Host_Env_Serve_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "fixture_application --atspi-serve-host-env",
               when others =>
                 ""),
            96),
       Runtime_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "",
               when A11y_Native_Client_Reports.Windows_UIA =>
                 "native_client_uia --probe-runtime",
               when A11y_Native_Client_Reports.MacOS_NSAccessibility =>
                 "native_client_nsax --probe-runtime"),
            96),
       Registered_Boundary_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-boundary",
               when A11y_Native_Client_Reports.Windows_UIA =>
                 "native_client_uia --probe-registered-boundary",
               when A11y_Native_Client_Reports.MacOS_NSAccessibility =>
                 "native_client_nsax --probe-registered-boundary"),
            96),
       Host_Environment_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-host-env",
               when others =>
                 ""),
            96),
       Fixture_Native_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-fixture-root",
               when A11y_Native_Client_Reports.Windows_UIA =>
                 "native_client_uia --probe-fixture-root",
               when A11y_Native_Client_Reports.MacOS_NSAccessibility =>
                 "native_client_nsax --probe-fixture-root"),
            96),
       Serving_Packet_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-serving-packet",
               when others =>
                 ""),
            96),
       Session_Bus_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-session-bus-address=ADDR",
               when others =>
                 ""),
            96),
       Session_Dispatch_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-session-dispatch",
               when others =>
                 ""),
            96),
       External_Client_Probe_Command =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 "native_client_atspi --probe-external-client-host-env",
               when A11y_Native_Client_Reports.Windows_UIA =>
                 "native_client_uia --probe-external-client",
               when A11y_Native_Client_Reports.MacOS_NSAccessibility =>
                 "native_client_nsax --probe-external-client"),
            96),
       Status =>
         Pad
           ((case Client is
               when A11y_Native_Client_Reports.Linux_ATSPI =>
                 A11y_Native_Client_Reports.Status_Name
                   (A11y_Native_Client_Reports.Linux_ATSPI),
               when A11y_Native_Client_Reports.Windows_UIA =>
                 (if A11y_Release_Qualification
                       .Windows_UIA_Public_Client_Traversal_Observed
                  then "native_conformance_ready"
                  else A11y_Native_Client_Reports.Status_Name),
               when A11y_Native_Client_Reports.MacOS_NSAccessibility =>
                 (if A11y_Release_Qualification
                       .MacOS_NSAccessibility_Public_Client_Traversal_Observed
                  then "native_conformance_ready"
                  else A11y_Native_Client_Reports.Status_Name)),
            40),
       Normalized_Output => Pad (Normalized_Output, 48),
       Observation_Count => A11y_Native_Client_Reports.Observation_Count,
       Has_Native_Registry_Observation =>
         A11y_Native_Client_Reports.Has_Native_Registry_Observation,
       Has_Native_Export_Descriptor_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Export_Descriptor_Observation,
      Has_Windows_UIA_Host_Window_Root_Binding_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_Host_Window_Root_Binding_Observation,
      Has_Windows_UIA_COM_VTable_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports.Has_Windows_UIA_COM_VTable_Observation,
      Has_Windows_UIA_COM_Object_Export_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Object_Export_Observation,
      Has_Windows_UIA_COM_Live_Export_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Export_Observation,
      Has_Windows_UIA_Bridge_Audit_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_Bridge_Audit_Observation,
      Has_Windows_UIA_COM_Live_Interface_Retain_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Interface_Retain_Observation,
      Has_Windows_UIA_COM_Live_Interface_Release_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Interface_Release_Observation,
      Has_Windows_UIA_COM_Live_Released_Interface_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Released_Interface_Observation,
      Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation,
      Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation,
      Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation,
      Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation,
      Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation,
      Has_Windows_UIA_COM_Live_Provider_Options_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Provider_Options_Observation,
      Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation,
      Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation,
      Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Root_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Root_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation,
      Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation,
      Has_Windows_UIA_External_Client_COM_Live_Chain_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_COM_Live_Chain_Observation,
      Has_Windows_UIA_Public_Root_Export_Path_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_Public_Root_Export_Path_Observation,
      Has_Windows_UIA_Public_Root_Native_Identity_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_Public_Root_Native_Identity_Observation,
      Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation,
      Has_Windows_UIA_External_Client_Provider_Options_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Provider_Options_Observation,
      Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation,
      Has_Windows_UIA_External_Client_Fragment_Root_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Fragment_Root_Observation,
      Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation,
      Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation,
      Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation,
      Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation,
      Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation,
      Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation,
      Has_Windows_UIA_External_Client_Action_Frame_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Action_Frame_Observation,
      Has_Windows_UIA_External_Client_Failure_Stage_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Failure_Stage_Observation,
      Has_Windows_UIA_External_Client_Metadata_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Metadata_Observation,
      Has_Windows_UIA_External_Client_Metadata_Group_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Metadata_Group_Observation,
      Has_Windows_UIA_External_Client_Protected_Value_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Protected_Value_Observation,
      Has_Windows_UIA_External_Client_Privacy_Boundary_Observation =>
        Client = A11y_Native_Client_Reports.Windows_UIA
        and then
        A11y_Native_Client_Reports
          .Has_Windows_UIA_External_Client_Privacy_Boundary_Observation,
      Has_MacOS_NSAX_Main_Thread_Binding_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Main_Thread_Binding_Observation,
       Has_MacOS_NSAX_Native_View_Binding_Observation =>
         Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
         and then
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Native_View_Binding_Observation,
      Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation,
      Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation,
      Has_MacOS_NSAX_Selector_Attribute_Value_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Attribute_Value_Observation,
      Has_MacOS_NSAX_Selector_Children_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Children_Frame_Observation,
      Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation,
      Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation,
      Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation,
      Has_MacOS_NSAX_Selector_Action_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Action_Frame_Observation,
      Has_MacOS_NSAX_Selector_Unsupported_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Selector_Unsupported_Observation,
       Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation =>
         Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
         and then
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation,
       Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation =>
         Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
         and then
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation,
       Has_MacOS_NSAX_Released_Boundary_Observation =>
         Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
         and then
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Released_Boundary_Observation,
      Has_MacOS_NSAX_Bridge_Audit_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Bridge_Audit_Observation,
      Has_MacOS_NSAX_Virtual_Element_Bridge_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Virtual_Element_Bridge_Observation,
      Has_MacOS_NSAX_External_Client_Element_Chain_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Element_Chain_Observation,
      Has_MacOS_NSAX_Public_Root_Export_Path_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Public_Root_Export_Path_Observation,
      Has_MacOS_NSAX_Public_Root_Native_Identity_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Public_Root_Native_Identity_Observation,
      Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation,
      Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation,
      Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation,
      Has_MacOS_NSAX_External_Client_Children_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Children_Frame_Observation,
      Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation,
      Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation,
      Has_MacOS_NSAX_External_Client_Action_Frame_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Action_Frame_Observation,
      Has_MacOS_NSAX_External_Client_Failure_Stage_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Failure_Stage_Observation,
      Has_MacOS_NSAX_External_Client_Metadata_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Metadata_Observation,
      Has_MacOS_NSAX_External_Client_Metadata_Group_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Metadata_Group_Observation,
      Has_MacOS_NSAX_External_Client_Protected_Value_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Protected_Value_Observation,
      Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation =>
        Client = A11y_Native_Client_Reports.MacOS_NSAccessibility
        and then
        A11y_Native_Client_Reports
          .Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation,
       Has_Native_Node_Index_Observation =>
         A11y_Native_Client_Reports.Has_Native_Node_Index_Observation,
       Has_Native_Cache_Tombstone_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Cache_Tombstone_Observation,
       Has_Native_Cache_Session_Scope_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Cache_Session_Scope_Observation,
       Has_Native_Runtime_Lifecycle_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Runtime_Lifecycle_Observation,
       Has_Native_Runtime_Lifecycle_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Runtime_Lifecycle_Report_Observation,
       Has_Native_Runtime_Probe_Failure_Stage_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Runtime_Probe_Failure_Stage_Observation,
       Has_Native_Runtime_Event_Application_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Runtime_Event_Application_Observation,
       Has_Native_Runtime_Event_Preparation_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Runtime_Event_Preparation_Observation,
       Has_Native_Runtime_Event_Preparation_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Runtime_Event_Preparation_Report_Observation,
       Has_Native_Projection_Property_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Projection_Property_Observation,
       Has_Native_Projection_Action_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Projection_Action_Observation,
       Has_Native_Projection_Relation_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Projection_Relation_Observation,
       Has_Native_Projection_Event_Source_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Projection_Event_Source_Observation,
       Has_Native_Deterministic_Shutdown_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Deterministic_Shutdown_Observation,
       Has_Diagnostics_Bounded_Observation =>
         A11y_Native_Client_Reports.Has_Diagnostics_Bounded_Observation,
       Has_Diagnostics_Result_Mapping_Observation =>
         A11y_Native_Client_Reports
           .Has_Diagnostics_Result_Mapping_Observation,
       Has_Diagnostics_Field_Bounds_Observation =>
         A11y_Native_Client_Reports
           .Has_Diagnostics_Field_Bounds_Observation,
       Has_Native_Resource_Limit_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Resource_Limit_Observation,
       Has_Native_Value_Resource_Limit_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Value_Resource_Limit_Observation,
      Has_Hostile_Identity_Observation =>
         A11y_Native_Client_Reports.Has_Hostile_Identity_Observation,
       Has_Native_Boundary_Admission_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Boundary_Admission_Report_Observation,
       Has_Native_Boundary_Native_Call_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Boundary_Native_Call_Report_Observation,
       Has_Native_Boundary_Completion_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Boundary_Completion_Report_Observation,
       Has_Native_Boundary_Release_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Boundary_Release_Report_Observation,
       Has_Native_Fixture_Root_Probe_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Root_Probe_Observation,
       Has_Native_Fixture_Root_Failure_Stage_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Root_Failure_Stage_Observation,
       Has_Native_Fixture_Root_Child_Traversal_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Root_Child_Traversal_Observation,
       Has_Native_Fixture_Root_Child_Count_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Root_Child_Count_Observation,
       Has_Native_Fixture_Root_Second_Child_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Root_Second_Child_Observation,
       Has_Native_Fixture_Child_Query_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Child_Query_Observation,
       Has_Native_Fixture_Child_Object_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Child_Object_Observation,
       Has_Native_Fixture_Child_Parent_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Child_Parent_Observation,
       Has_Native_Fixture_Child_Native_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Child_Native_Identity_Observation,
       Has_Native_Fixture_Second_Child_Parent_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Second_Child_Parent_Observation,
       Has_Native_Fixture_Second_Child_Native_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Second_Child_Native_Identity_Observation,
       Has_Native_Fixture_Sibling_Order_Observation =>
         A11y_Native_Client_Reports.Has_Native_Fixture_Sibling_Order_Observation,
       Has_Native_Fixture_Child_Stale_Id_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Fixture_Child_Stale_Id_Observation,
       Has_Linux_ATSPI_Serving_Packet_Probe_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Probe_Observation,
      Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation,
      Has_Linux_ATSPI_Serving_Packet_Property_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Serving_Packet_Property_Observation,
      Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation,
      Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation,
       Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation,
       Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation,
       Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation,
       Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation,
       Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation,
       Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation,
       Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation,
       Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation,
       Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation,
      Has_Linux_ATSPI_Session_Bus_Probe_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Session_Bus_Probe_Observation,
      Has_Linux_ATSPI_Live_External_Client_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Observation,
      Has_Linux_ATSPI_Live_Registered_External_Client_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_Registered_External_Client_Observation,
      Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations,
      Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation,
      Has_Linux_ATSPI_Live_External_Client_Attribute_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Attribute_Observation,
      Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations,
      Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation,
      Has_Linux_ATSPI_Live_External_Client_Component_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Component_Observation,
      Has_Linux_ATSPI_Live_External_Client_Action_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Action_Observation,
      Has_Linux_ATSPI_Live_External_Client_Value_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Value_Observation,
      Has_Linux_ATSPI_Live_External_Client_Selection_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Selection_Observation,
      Has_Linux_ATSPI_Live_External_Client_Text_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Text_Observation,
      Has_Linux_ATSPI_Live_External_Client_Image_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Image_Observation,
      Has_Linux_ATSPI_Live_External_Client_Document_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Document_Observation,
      Has_Linux_ATSPI_Live_External_Client_Table_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Table_Observation,
      Has_Linux_ATSPI_Live_External_Client_Surface_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Surface_Observation,
      Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation =>
        Client = A11y_Native_Client_Reports.Linux_ATSPI
        and then A11y_Native_Client_Reports
          .Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation,
      Has_Linux_ATSPI_Session_Startup_Stage_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Session_Startup_Stage_Observation,
       Has_Linux_ATSPI_Startup_Object_Path_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Startup_Object_Path_Observation,
       Has_Linux_ATSPI_Session_Dispatch_Probe_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Session_Dispatch_Probe_Observation,
       Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation,
       Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation,
       Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation,
       Has_Linux_ATSPI_Registered_Boundary_Report_Observation =>
         Client = A11y_Native_Client_Reports.Linux_ATSPI
         and then A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Registered_Boundary_Report_Observation,
       Has_Malformed_Request_Observation =>
         A11y_Native_Client_Reports.Has_Malformed_Request_Observation,
       Has_Linux_Error_Name_Map_Observation =>
         A11y_Native_Client_Reports.Has_Linux_Error_Name_Map_Observation,
       Has_Linux_Error_Name_Inverse_Map_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_Error_Name_Inverse_Map_Observation,
       Has_Linux_Error_Name_Diagnostic_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_Error_Name_Diagnostic_Observation,
       Has_Linux_ATSPI_Core_Method_Observations =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Core_Method_Observations,
       Has_Linux_ATSPI_Interaction_Method_Observations =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Interaction_Method_Observations,
       Has_Linux_ATSPI_Component_Focus_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Component_Focus_Observation,
       Has_Linux_ATSPI_Selection_Deselect_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Selection_Deselect_Observation,
       Has_Linux_ATSPI_Selection_Select_All_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Selection_Select_All_Observation,
       Has_Linux_ATSPI_Selection_Clear_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Selection_Clear_Observation,
       Has_Linux_ATSPI_Content_Method_Observations =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Content_Method_Observations,
       Has_Linux_ATSPI_Document_Surface_Event_Observations =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Document_Surface_Event_Observations,
       Has_Linux_DBus_Unsupported_Value_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Unsupported_Value_Observation,
       Has_Linux_DBus_UInt32_Array_Value_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_UInt32_Array_Value_Observation,
       Has_Linux_DBus_State_Set_UInt32_Array_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_State_Set_UInt32_Array_Observation,
       Has_Linux_DBus_String_Array_Value_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_String_Array_Value_Observation,
       Has_Linux_DBus_Attribute_String_Array_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Attribute_String_Array_Observation,
       Has_Linux_DBus_Cache_Interface_String_Array_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Cache_Interface_String_Array_Observation,
       Has_Linux_DBus_Object_Path_Array_Value_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Object_Path_Array_Value_Observation,
       Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation,
       Has_Windows_HResult_Map_Observation =>
         A11y_Native_Client_Reports.Has_Windows_HResult_Map_Observation,
       Has_Windows_HResult_Inverse_Map_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_HResult_Inverse_Map_Observation,
       Has_Windows_HResult_Diagnostic_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_HResult_Diagnostic_Observation,
       Has_Windows_UIA_Event_Posting_Admission_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Event_Posting_Admission_Observation,
       Has_Windows_UIA_Event_Posting_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Event_Posting_Report_Observation,
       Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation,
       Has_Windows_UIA_Core_Routing_Observations =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Core_Routing_Observations,
       Has_Windows_UIA_Metadata_Property_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Metadata_Property_Observation,
       Has_Windows_UIA_Protected_Value_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Protected_Value_Observation,
       Has_Windows_UIA_Advanced_Routing_Observations =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Advanced_Routing_Observations,
       Has_Windows_UIA_Selection_Select_All_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Selection_Select_All_Observation,
       Has_Windows_UIA_Selection_Clear_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Selection_Clear_Observation,
       Has_Windows_UIA_Native_Focus_Query_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Native_Focus_Query_Observation,
       Has_Windows_UIA_Native_Set_Focus_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Native_Set_Focus_Observation,
       Has_Windows_UIA_Hostile_Callback_Admission_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Hostile_Callback_Admission_Observation,
       Has_Windows_UIA_Missing_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Missing_Identity_Observation,
       Has_Windows_UIA_Mismatched_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Mismatched_Identity_Observation,
       Has_Windows_UIA_Malformed_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Malformed_Identity_Observation,
       Has_Windows_UIA_Text_Payload_Limit_Observation =>
         A11y_Native_Client_Reports
           .Has_Windows_UIA_Text_Payload_Limit_Observation,
       Has_MacOS_Native_Status_Map_Observation =>
         A11y_Native_Client_Reports.Has_MacOS_Native_Status_Map_Observation,
       Has_MacOS_Native_Status_Inverse_Map_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_Native_Status_Inverse_Map_Observation,
       Has_MacOS_Native_Status_Diagnostic_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_Native_Status_Diagnostic_Observation,
       Has_MacOS_NSAX_Event_Posting_Admission_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Event_Posting_Admission_Observation,
       Has_MacOS_NSAX_Event_Posting_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Event_Posting_Report_Observation,
       Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation,
       Has_MacOS_NSAX_Core_Routing_Observations =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Core_Routing_Observations,
       Has_MacOS_NSAX_Metadata_Attribute_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Metadata_Attribute_Observation,
       Has_MacOS_NSAX_Protected_Value_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Protected_Value_Observation,
       Has_MacOS_NSAX_Advanced_Routing_Observations =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Advanced_Routing_Observations,
       Has_MacOS_NSAX_Selection_Select_All_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Selection_Select_All_Observation,
       Has_MacOS_NSAX_Selection_Clear_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Selection_Clear_Observation,
       Has_MacOS_NSAX_Native_Focus_Query_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Native_Focus_Query_Observation,
       Has_MacOS_NSAX_Native_Set_Focus_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Native_Set_Focus_Observation,
       Has_MacOS_NSAX_Hostile_Callback_Admission_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Hostile_Callback_Admission_Observation,
       Has_MacOS_NSAX_Missing_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Missing_Identity_Observation,
       Has_MacOS_NSAX_Mismatched_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Mismatched_Identity_Observation,
       Has_MacOS_NSAX_Malformed_Identity_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Malformed_Identity_Observation,
       Has_MacOS_NSAX_Text_Payload_Limit_Observation =>
         A11y_Native_Client_Reports
           .Has_MacOS_NSAX_Text_Payload_Limit_Observation,
       Has_Transport_Staging_Observation =>
         A11y_Native_Client_Reports.Has_Transport_Staging_Observation,
       Has_Transport_Generation_Observation =>
         A11y_Native_Client_Reports.Has_Transport_Generation_Observation,
       Has_Transport_Transition_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Transport_Transition_Report_Observation,
       Has_Native_Cache_Generation_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Cache_Generation_Observation,
       Has_Native_Cache_Mutation_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Cache_Mutation_Report_Observation,
       Has_Native_Registry_Generation_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Registry_Generation_Observation,
       Has_Native_Registry_Drained_Reset_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Registry_Drained_Reset_Observation,
       Has_Native_Registry_Reset_Node_Rejection_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Registry_Drained_Reset_Observation,
       Has_Native_Registry_Reset_Stale_Id_Rejection_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Registry_Drained_Reset_Observation,
       Has_Native_Registry_Mutation_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Registry_Mutation_Report_Observation,
       Has_Native_Boundary_Runtime_Generation_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Boundary_Runtime_Generation_Observation,
       Has_Prepared_Status_Observation =>
         A11y_Native_Client_Reports.Has_Prepared_Status_Observation,
       Has_Event_Posting_Interest_Observation =>
         A11y_Native_Client_Reports
           .Has_Event_Posting_Interest_Observation,
       Has_Native_Event_Validation_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Event_Validation_Observation,
       Has_Native_Event_Posting_Boundary_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Event_Posting_Boundary_Observation,
       Has_Native_Event_Exhaustive_Map_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Event_Exhaustive_Map_Observation,
       Has_Native_Role_Exhaustive_Map_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Role_Exhaustive_Map_Observation,
       Has_Native_Relation_Exhaustive_Map_Observation =>
         A11y_Native_Client_Reports
           .Has_Native_Relation_Exhaustive_Map_Observation,
       Has_Method_Return_Decode_Observation =>
         A11y_Native_Client_Reports.Has_Method_Return_Decode_Observation,
       Has_Error_Return_Decode_Observation =>
         A11y_Native_Client_Reports.Has_Error_Return_Decode_Observation,
       Has_Error_Return_Diagnostic_Observation =>
         A11y_Native_Client_Reports
           .Has_Error_Return_Diagnostic_Observation,
       Has_Startup_Error_Completion_Observation =>
         A11y_Native_Client_Reports
           .Has_Startup_Error_Completion_Observation,
       Has_Incoming_Packet_Classification_Observation =>
         A11y_Native_Client_Reports
           .Has_Incoming_Packet_Classification_Observation,
       Has_Startup_Outgoing_Work_Observation =>
         A11y_Native_Client_Reports
           .Has_Startup_Outgoing_Work_Observation,
       Has_Startup_Event_Loop_Interest_Observation =>
         A11y_Native_Client_Reports
           .Has_Startup_Event_Loop_Interest_Observation,
       Has_Startup_Event_Loop_Operation_Observation =>
         A11y_Native_Client_Reports
           .Has_Startup_Event_Loop_Operation_Observation,
       Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation,
       Has_Startup_Outgoing_Flush_Observation =>
         A11y_Native_Client_Reports
           .Has_Startup_Outgoing_Flush_Observation,
       Has_Linux_DBus_Outgoing_Back_Pressure_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Outgoing_Back_Pressure_Observation,
       Has_Linux_DBus_Connection_Lifecycle_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Connection_Lifecycle_Observation,
       Has_Linux_DBus_Local_Channel_Adapter_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Local_Channel_Adapter_Observation,
       Has_Linux_DBus_Local_Channel_Receive_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Local_Channel_Receive_Observation,
       Has_Linux_DBus_Startup_Controller_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Controller_Observation,
       Has_Linux_DBus_Startup_Backend_Adapter_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Backend_Adapter_Observation,
       Has_Linux_DBus_Startup_Pump_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Pump_Observation,
       Has_Linux_DBus_Startup_Pump_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Pump_Report_Observation,
       Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation,
       Has_Linux_DBus_Startup_Pump_Bounds_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Pump_Bounds_Observation,
       Has_Linux_DBus_Startup_Registered_Pump_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Registered_Pump_Observation,
       Has_Linux_DBus_Bus_Address_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Bus_Address_Observation,
       Has_Linux_DBus_Auth_External_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Auth_External_Observation,
       Has_Linux_DBus_Auth_Exchange_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Auth_Exchange_Observation,
       Has_Linux_DBus_Authenticated_Connect_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Authenticated_Connect_Observation,
       Has_Linux_DBus_Hello_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Hello_Observation,
       Has_Linux_DBus_Authenticated_Hello_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Authenticated_Hello_Observation,
       Has_Linux_DBus_Registration_Completion_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Registration_Completion_Observation,
       Has_Linux_DBus_Authenticated_Registration_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Authenticated_Registration_Observation,
       Has_Linux_DBus_Startup_Reply_Evidence_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Reply_Evidence_Observation,
       Has_Linux_DBus_Application_Registration_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Application_Registration_Observation,
       Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation,
       Has_Linux_DBus_Address_Discovery_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Address_Discovery_Observation,
       Has_Linux_DBus_Host_Environment_Startup_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Host_Environment_Startup_Observation,
       Has_Linux_DBus_A11y_Bus_Get_Address_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_A11y_Bus_Get_Address_Observation,
       Has_Linux_DBus_Authenticated_Get_Address_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Authenticated_Get_Address_Observation,
       Has_Linux_DBus_Startup_Session_Discovery_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Startup_Session_Discovery_Observation,
       Has_Linux_DBus_Transport_Frame_Metadata_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Frame_Metadata_Observation,
       Has_Linux_DBus_Method_Call_Destination_Routing_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Method_Call_Destination_Routing_Observation,
       Has_Linux_DBus_Transport_Frame_Bytes_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Frame_Bytes_Observation,
       Has_Linux_DBus_Transport_Frame_Send_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Frame_Send_Observation,
       Has_Linux_DBus_Transport_Packet_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Packet_Observation,
       Has_Linux_DBus_Transport_Packet_Send_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Packet_Send_Observation,
       Has_Linux_DBus_Transport_Packet_Decode_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Packet_Decode_Observation,
       Has_Linux_DBus_Codec_Basic_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Codec_Basic_Observation,
       Has_Linux_DBus_Resource_Limits_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Resource_Limits_Observation,
       Has_Linux_DBus_Message_Envelope_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Message_Envelope_Observation,
       Has_Linux_DBus_Method_Call_Envelope_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Method_Call_Envelope_Observation,
       Has_Linux_DBus_Transport_Envelope_Decode_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Transport_Envelope_Decode_Observation,
       Has_Linux_DBus_Incoming_Call_Decode_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Incoming_Call_Decode_Observation,
       Has_Linux_DBus_Signal_Envelope_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Signal_Envelope_Observation,
       Has_Linux_DBus_Prepared_Signal_Envelope_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Prepared_Signal_Envelope_Observation,
       Has_Linux_ATSPI_Signal_Build_Report_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_ATSPI_Signal_Build_Report_Observation,
       Has_Linux_DBus_Method_Boundary_Observation =>
         A11y_Native_Client_Reports
           .Has_Linux_DBus_Method_Boundary_Observation,
       Has_Focus_Observation =>
         A11y_Native_Client_Reports.Has_Focus_Observation,
      Has_Property_Change_Observation =>
        A11y_Native_Client_Reports.Has_Property_Change_Observation,
      Has_Orientation_Property_Event_Observation =>
        A11y_Native_Client_Reports
          .Has_Orientation_Property_Event_Observation,
      Has_Set_Position_Property_Event_Observation =>
        A11y_Native_Client_Reports
          .Has_Set_Position_Property_Event_Observation,
      Has_Set_Size_Property_Event_Observation =>
        A11y_Native_Client_Reports.Has_Set_Size_Property_Event_Observation,
      Has_Hierarchical_Level_Property_Event_Observation =>
        A11y_Native_Client_Reports
          .Has_Hierarchical_Level_Property_Event_Observation,
      Has_Role_Property_Observation =>
        A11y_Native_Client_Reports.Has_Role_Property_Observation,
      Has_State_Set_Property_Observation =>
        A11y_Native_Client_Reports.Has_State_Set_Property_Observation,
      Has_Name_Observation =>
         A11y_Native_Client_Reports.Has_Name_Observation,
       Has_Description_Observation =>
         A11y_Native_Client_Reports.Has_Description_Observation,
       Has_Help_Text_Observation =>
         A11y_Native_Client_Reports.Has_Help_Text_Observation,
       Has_Placeholder_Observation =>
         A11y_Native_Client_Reports.Has_Placeholder_Observation,
       Has_Value_Text_Observation =>
         A11y_Native_Client_Reports.Has_Value_Text_Observation,
       Has_Keyboard_Shortcut_Observation =>
         A11y_Native_Client_Reports.Has_Keyboard_Shortcut_Observation,
       Has_Semantic_Identifier_Observation =>
         A11y_Native_Client_Reports.Has_Semantic_Identifier_Observation,
       Has_Locale_Property_Observation =>
         A11y_Native_Client_Reports.Has_Locale_Property_Observation,
       Has_Visible_Title_Property_Observation =>
         A11y_Native_Client_Reports.Has_Visible_Title_Property_Observation,
       Has_Orientation_Property_Observation =>
         A11y_Native_Client_Reports.Has_Orientation_Property_Observation,
       Has_Set_Position_Property_Observation =>
         A11y_Native_Client_Reports.Has_Set_Position_Property_Observation,
       Has_Set_Size_Property_Observation =>
         A11y_Native_Client_Reports.Has_Set_Size_Property_Observation,
       Has_Hierarchical_Level_Property_Observation =>
         A11y_Native_Client_Reports
           .Has_Hierarchical_Level_Property_Observation,
       Has_Heading_Level_Property_Observation =>
         A11y_Native_Client_Reports.Has_Heading_Level_Property_Observation,
       Has_Landmark_Property_Observation =>
         A11y_Native_Client_Reports.Has_Landmark_Property_Observation,
       Has_Bounds_Property_Observation =>
         A11y_Native_Client_Reports.Has_Bounds_Property_Observation,
       Has_State_Change_Observation =>
         A11y_Native_Client_Reports.Has_State_Change_Observation,
       Has_Bounds_Observation =>
         A11y_Native_Client_Reports.Has_Bounds_Observation,
       Has_Hit_Test_Observation =>
         A11y_Native_Client_Reports.Has_Hit_Test_Observation,
       Has_Tree_Change_Observation =>
         A11y_Native_Client_Reports.Has_Tree_Change_Observation,
       Has_Window_Event_Observation =>
         A11y_Native_Client_Reports.Has_Window_Event_Observation,
       Has_Activate_Action_Observation =>
         A11y_Native_Client_Reports.Has_Activate_Action_Observation,
       Has_Action_Observation =>
         A11y_Native_Client_Reports.Has_Action_Observation,
       Has_Toggle_Action_Observation =>
         A11y_Native_Client_Reports.Has_Toggle_Action_Observation,
       Has_Expand_Action_Observation =>
         A11y_Native_Client_Reports.Has_Expand_Action_Observation,
       Has_Collapse_Action_Observation =>
         A11y_Native_Client_Reports.Has_Collapse_Action_Observation,
       Has_Show_Menu_Action_Observation =>
         A11y_Native_Client_Reports.Has_Show_Menu_Action_Observation,
       Has_Dismiss_Action_Observation =>
         A11y_Native_Client_Reports.Has_Dismiss_Action_Observation,
       Has_Open_Action_Observation =>
         A11y_Native_Client_Reports.Has_Open_Action_Observation,
       Has_Close_Action_Observation =>
         A11y_Native_Client_Reports.Has_Close_Action_Observation,
       Has_Scroll_Action_Observation =>
         A11y_Native_Client_Reports.Has_Scroll_Action_Observation,
       Has_Set_Focus_Action_Observation =>
         A11y_Native_Client_Reports.Has_Set_Focus_Action_Observation,
       Has_Action_Payload_Observation =>
         A11y_Native_Client_Reports.Has_Action_Payload_Observation,
       Has_Action_Request_Payload_Observation =>
         A11y_Native_Client_Reports
           .Has_Action_Request_Payload_Observation,
       Has_Value_Observation =>
         A11y_Native_Client_Reports.Has_Value_Observation,
       Has_Selection_Observation =>
         A11y_Native_Client_Reports.Has_Selection_Observation,
       Has_Select_All_Observation =>
         A11y_Native_Client_Reports.Has_Select_All_Observation,
       Has_Selection_Event_Observation =>
         A11y_Native_Client_Reports.Has_Selection_Event_Observation,
       Has_Active_Descendant_Observation =>
         A11y_Native_Client_Reports.Has_Active_Descendant_Observation,
       Has_Active_Descendant_Event_Observation =>
         A11y_Native_Client_Reports
           .Has_Active_Descendant_Event_Observation,
       Has_Current_Item_Observation =>
         A11y_Native_Client_Reports.Has_Current_Item_Observation,
       Has_Current_Item_Event_Observation =>
         A11y_Native_Client_Reports.Has_Current_Item_Event_Observation,
       Has_Tree_Role_Observation =>
         A11y_Native_Client_Reports.Has_Tree_Role_Observation,
       Has_Tree_Item_Role_Observation =>
         A11y_Native_Client_Reports.Has_Tree_Item_Role_Observation,
       Has_Menu_Bar_Role_Observation =>
         A11y_Native_Client_Reports.Has_Menu_Bar_Role_Observation,
       Has_Menu_Role_Observation =>
         A11y_Native_Client_Reports.Has_Menu_Role_Observation,
       Has_Menu_Item_Role_Observation =>
         A11y_Native_Client_Reports.Has_Menu_Item_Role_Observation,
       Has_Tab_List_Role_Observation =>
         A11y_Native_Client_Reports.Has_Tab_List_Role_Observation,
       Has_Tab_Role_Observation =>
         A11y_Native_Client_Reports.Has_Tab_Role_Observation,
      Has_Tooltip_Role_Observation =>
        A11y_Native_Client_Reports.Has_Tooltip_Role_Observation,
      Has_Status_Role_Observation =>
        A11y_Native_Client_Reports.Has_Status_Role_Observation,
      Has_Image_Role_Observation =>
        A11y_Native_Client_Reports.Has_Image_Role_Observation,
      Has_Decorative_Image_Role_Observation =>
        A11y_Native_Client_Reports.Has_Decorative_Image_Role_Observation,
      Has_Vertical_Slice_Role_Observations =>
        A11y_Native_Client_Reports.Has_Vertical_Slice_Role_Observations,
       Has_Extended_Fixture_Role_Observations =>
         A11y_Native_Client_Reports.Has_Extended_Fixture_Role_Observations,
       Has_Fixture_Command_Coverage =>
         A11y_Native_Client_Reports.Has_Fixture_Command_Coverage,
       Has_Text_Observation =>
         A11y_Native_Client_Reports.Has_Text_Observation,
       Has_Text_Mutation_Observation =>
         A11y_Native_Client_Reports.Has_Text_Mutation_Observation,
       Has_Text_Set_Observation =>
         A11y_Native_Client_Reports.Has_Text_Set_Observation,
       Has_Caret_Observation =>
         A11y_Native_Client_Reports.Has_Caret_Observation,
       Has_Table_Observation =>
         A11y_Native_Client_Reports.Has_Table_Observation,
       Has_Table_Current_Cell_Observation =>
         A11y_Native_Client_Reports.Has_Table_Current_Cell_Observation,
       Has_Table_Sort_Metadata_Observation =>
         A11y_Native_Client_Reports.Has_Table_Sort_Metadata_Observation,
       Has_Table_Event_Observation =>
         A11y_Native_Client_Reports.Has_Table_Event_Observation,
       Has_Image_Observation =>
         A11y_Native_Client_Reports.Has_Image_Observation,
       Has_Document_Observation =>
         A11y_Native_Client_Reports.Has_Document_Observation,
       Has_Document_Event_Observation =>
         A11y_Native_Client_Reports.Has_Document_Event_Observation,
       Has_Protected_Text_Observation =>
         A11y_Native_Client_Reports.Has_Protected_Text_Observation,
       Has_Live_Region_Observation =>
         A11y_Native_Client_Reports.Has_Live_Region_Observation,
       Has_Relation_Observation =>
         A11y_Native_Client_Reports.Has_Relation_Observation,
       Has_Relation_Event_Observation =>
         A11y_Native_Client_Reports.Has_Relation_Event_Observation,
       Has_Surface_Observation =>
         A11y_Native_Client_Reports.Has_Surface_Observation,
       Has_Lifecycle_Observation =>
         A11y_Native_Client_Reports.Has_Lifecycle_Observation));

   Clients : constant array (Positive range <>) of Client_Record :=
     [Item
        (A11y_Native_Client_Reports.Linux_ATSPI,
         "normalized_semantic_vocabulary"),
      Item
        (A11y_Native_Client_Reports.Windows_UIA,
         "normalized_semantic_vocabulary"),
      Item
        (A11y_Native_Client_Reports.MacOS_NSAccessibility,
         "normalized_semantic_vocabulary")];

   function Client_Count return Natural is (Clients'Length);

   function Internal_Native_Export_Chain_Ready
     (Client : Client_Record) return Boolean;

   function Native_Vertical_Slice_Observed
     (Client : Client_Record) return Boolean;

   function Public_Client_Traversal_Observed
     (Client : Client_Record) return Boolean;

   function Native_Boundary_Observed (Client : Client_Record) return Boolean;

   function All_Clients_Blocked return Boolean is
   begin
      for Client of Clients loop
         if Trimmed (Client.Status) /=
           A11y_Native_Client_Reports.Status_Name
         then
            return False;
         end if;
      end loop;
      return True;
   end All_Clients_Blocked;

   function Readiness return Readiness_Status is
   begin
      for Client of Clients loop
         if not Public_Client_Traversal_Observed (Client) then
            if All_Clients_Blocked then
               return Blocked_Transport_Unavailable;
            end if;

            return Incomplete_Native_Evidence;
         end if;
      end loop;

      return Native_Conformance_Ready;
   end Readiness;

   function Readiness_Name return String is
     (case Readiness is
        when Blocked_Transport_Unavailable => "blocked_transport_unavailable",
        when Incomplete_Native_Evidence => "incomplete_native_evidence",
        when Native_Conformance_Ready => "native_conformance_ready");

   function Is_Native_Conformance_Ready return Boolean is
     (Readiness = Native_Conformance_Ready);

   function MacOS_NSAccessibility_Artifact_State return String is
   begin
      if A11y_Release_Qualification
           .MacOS_NSAccessibility_Public_Client_Traversal_Observed
      then
         return "complete";
      elsif A11y_Release_Qualification
              .MacOS_NSAccessibility_Native_Client_Artifact_Available
      then
         return "incomplete_or_invalid";
      else
         return "missing";
      end if;
   end MacOS_NSAccessibility_Artifact_State;

   function Public_Client_Traversal_Observed
     (Client : Client_Record) return Boolean is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Windows" then
         return A11y_Release_Qualification
           .Windows_UIA_Public_Client_Traversal_Observed;
      elsif Platform = "macOS" then
         return A11y_Release_Qualification
           .MacOS_NSAccessibility_Public_Client_Traversal_Observed;
      end if;

      return Native_Vertical_Slice_Observed (Client);
   end Public_Client_Traversal_Observed;

   function Public_Client_Traversal_Observed_Name
     (Client : Client_Record) return String is
     (if Public_Client_Traversal_Observed (Client) then "true" else "false");

   function Readiness_Blocker_Count return Natural is
      Count : Natural := 0;
   begin
      for Client of Clients loop
         if not Public_Client_Traversal_Observed (Client) then
            Count := Count + 1;
         end if;
      end loop;
      return Count;
   end Readiness_Blocker_Count;

   function Native_Boundary_Observed (Client : Client_Record) return Boolean is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Windows"
        and then A11y_Release_Qualification
          .Windows_UIA_Public_Client_Traversal_Observed
      then
         return True;
      elsif Platform = "macOS"
        and then A11y_Release_Qualification
          .MacOS_NSAccessibility_Public_Client_Traversal_Observed
      then
         return True;
      end if;

      if Trimmed (Client.Status) =
        A11y_Native_Client_Reports.Status_Name
      then
         return False;
      end if;

      if Platform = "Linux" then
         return
           Client.Has_Linux_ATSPI_Live_Registered_External_Client_Observation;
      elsif Platform = "Windows" then
         return
           Client.Has_Windows_UIA_COM_Live_Export_Observation
           and then
             Client.Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Provider_Options_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
           and then Client.Has_Windows_UIA_External_Client_Fragment_Root_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Action_Frame_Observation;
      elsif Platform = "macOS" then
        return
          Client.Has_MacOS_NSAX_Native_View_Binding_Observation
           and then Client.Has_MacOS_NSAX_External_Client_Element_Chain_Observation
           and then Client.Has_MacOS_NSAX_External_Client_Children_Frame_Observation
           and then
             Client
               .Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
           and then
             Client
               .Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
           and then Client.Has_MacOS_NSAX_External_Client_Action_Frame_Observation;
      else
         return False;
      end if;
   end Native_Boundary_Observed;

   function Native_Boundary_Observed_Name
     (Client : Client_Record) return String is
     (if Native_Boundary_Observed (Client) then "true" else "false");

   function Native_Boundary_Stage (Client : Client_Record) return String is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Native_Boundary_Observed (Client) then
         if Platform = "Linux" then
            return "live_atspi_registered_transport_observed";
         elsif Platform = "Windows" then
            return "live_uia_com_provider_export_observed";
         elsif Platform = "macOS" then
            return "live_nsaccessibility_appkit_bridge_observed";
         else
            return "native_boundary_observed";
         end if;
      elsif Internal_Native_Export_Chain_Ready (Client) then
         if Platform = "Windows" then
            return "uia_public_root_export_path_ready";
         elsif Platform = "macOS" then
            return "nsaccessibility_public_root_export_path_ready";
         elsif Platform = "Linux" then
            return "internal_atspi_transport_chain_ready";
         else
            return "internal_native_export_chain_ready";
         end if;
      elsif Platform = "Windows" then
         return "uia_com_provider_export_required";
      elsif Platform = "macOS" then
         return "nsaccessibility_appkit_bridge_required";
      elsif Platform = "Linux" then
         return "atspi_transport_registration_required";
      else
         return "native_boundary_required";
      end if;
   end Native_Boundary_Stage;

   function Internal_Native_Export_Chain_Ready
     (Client : Client_Record) return Boolean
   is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Linux" then
         return
           Client.Has_Linux_ATSPI_Live_Registered_External_Client_Observation;
      elsif Platform = "Windows" then
         return
           Client.Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Provider_Options_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
           and then Client.Has_Windows_UIA_External_Client_Fragment_Root_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
           and then
             Client
               .Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Action_Frame_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Metadata_Group_Observation
           and then
             Client.Has_Windows_UIA_External_Client_Privacy_Boundary_Observation;
      elsif Platform = "macOS" then
        return
          Client.Has_MacOS_NSAX_External_Client_Element_Chain_Observation
           and then
             Client
               .Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation
           and then
             Client
               .Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation
           and then Client.Has_MacOS_NSAX_External_Client_Children_Frame_Observation
           and then
             Client
               .Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
           and then
             Client
               .Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
           and then
             Client.Has_MacOS_NSAX_External_Client_Action_Frame_Observation
           and then
             Client.Has_MacOS_NSAX_External_Client_Metadata_Group_Observation
           and then
             Client.Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation;
      else
         return False;
      end if;
   end Internal_Native_Export_Chain_Ready;

   function Internal_Native_Export_Chain_Ready_Name
     (Client : Client_Record) return String is
     (if Internal_Native_Export_Chain_Ready (Client) then "true" else "false");

   function Native_Vertical_Slice_Observed
     (Client : Client_Record) return Boolean is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Linux" then
         return
           Client.Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations;
      elsif Platform = "Windows" then
         return A11y_Release_Qualification
           .Windows_UIA_Public_Client_Traversal_Observed;
      elsif Platform = "macOS" then
         return A11y_Release_Qualification
           .MacOS_NSAccessibility_Public_Client_Traversal_Observed;
      else
         return False;
      end if;
   end Native_Vertical_Slice_Observed;

   function Native_Vertical_Slice_Observed_Name
     (Client : Client_Record) return String is
     (if Native_Vertical_Slice_Observed (Client) then "true" else "false");

   function Required_Native_Boundary (Client : Client_Record) return String is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Linux" then
         if Client.Has_Linux_ATSPI_Live_External_Client_Observation then
            return "live_atspi_dbus_transport_registration_observed";
         else
            return "live_atspi_dbus_transport_registration";
         end if;
      elsif Platform = "Windows" then
         return "live_uia_com_provider_export";
      elsif Platform = "macOS" then
         return "live_nsaccessibility_objc_appkit_bridge";
      else
         return "unknown_native_transport";
      end if;
   end Required_Native_Boundary;

   function Next_Required_Evidence (Client : Client_Record) return String is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Linux" then
         if Client
              .Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
         then
            return "linux_atspi_automated_native_qualification";
         elsif Client.Has_Linux_ATSPI_Live_External_Client_Observation then
            return "complete_live_atspi_vertical_slice";
         else
            return "external_atspi_client_traverses_registered_application";
         end if;
      elsif Platform = "Windows" then
         if Public_Client_Traversal_Observed (Client) then
            return "none";
         elsif Internal_Native_Export_Chain_Ready (Client) then
            return "windows_uia_automated_native_qualification";
         else
            return "external_uia_client_traverses_com_fragment_root";
         end if;
      elsif Platform = "macOS" then
         if Public_Client_Traversal_Observed (Client) then
            return "none";
         else
            return "external_ax_client_traverses_appkit_element_tree";
         end if;
      else
         return "external_native_client_traversal";
      end if;
   end Next_Required_Evidence;

   function Remaining_Evidence (Client : Client_Record) return String is
      Platform : constant String := Trimmed (Client.Platform);
   begin
      if Platform = "Linux" then
         if Client
              .Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
         then
            return
              "optional_assistive_technology_field_qualification";
         elsif Client.Has_Linux_ATSPI_Live_External_Client_Observation then
            return
              "complete_live_atspi_vertical_slice";
         else
            return
              "live_atspi_transport_registration_and_client_traversal_required";
         end if;
      elsif Platform = "Windows" then
         if Public_Client_Traversal_Observed (Client) then
            return "none";
         elsif Internal_Native_Export_Chain_Ready (Client) then
            return
              "external_uia_client_traversal_required";
         else
            return
              "internal_uia_export_chain_and_live_public_client_traversal_required";
         end if;
      elsif Platform = "macOS" then
         if Public_Client_Traversal_Observed (Client) then
            return "none";
         elsif Internal_Native_Export_Chain_Ready (Client) then
            return
              "live_nsaccessibility_appkit_bridge_and_public_ax_client_traversal_required";
         else
            return
              "internal_nsaccessibility_export_chain_and_live_public_ax_client_traversal_required";
         end if;
      else
         return "native_backend_evidence_required";
      end if;
   end Remaining_Evidence;

   function Markdown return String is
      Result : Unbounded_String;
      Table_Header : constant String :=
        "| Platform | Native API | Client process | Fixture command | Fixture host-env serve command | Runtime probe command | Registered boundary probe command | Host environment probe command | Fixture-root probe command | Serving packet probe command | Session bus probe command | Session dispatch probe command | Status | Observations | Native registry | Registry generation | Registry reset | Reset node rejection | Reset stale-id rejection | Registry mutation report | Export descriptor | Node index | Cache tombstone | Cache session | Cache generation | Cache mutation report | Runtime lifecycle | Runtime lifecycle report | Runtime preparation report | Boundary generation | Shutdown | Diagnostic bounds | Diagnostic result map | Diagnostic fields | Resource limit | Native value limit | Hostile identity | Boundary admission report | Boundary native-call report | Boundary completion report | Boundary release report | Fixture-root probe | Fixture child traversal | Fixture child count | Fixture second child | Fixture child query | Fixture child object | Fixture child parent | Fixture child identity | Fixture second child parent | Fixture second child identity | Fixture sibling order | Fixture child stale id | Fixture-root failure stage | Serving packet probe | Serving packet tree traversal | Session dispatch probe | Malformed request | Linux error map | Linux inverse error map | Linux error diagnostic | Linux unsupported value | Linux UInt32-array value | Linux state-set array | Linux string-array value | Linux attribute array | Linux cache interfaces | Linux object-path array | Linux relation targets | Windows HRESULT map | Windows inverse HRESULT map | Windows HRESULT diagnostic | Windows posting admission | Windows posting report | Windows posting drain | macOS status map | macOS inverse status map | macOS status diagnostic | macOS posting admission | macOS posting report | macOS posting drain | Transport staging | Transport generation | Transport transition report | Prepared status | Signal build report | Posting interest | Method return decode | Error return decode | Error diagnostic | Startup error completion | Packet classification | Startup work | Startup operation | Backend session step | Backend transport cycle | Startup flush | Outgoing back pressure | Linux connection lifecycle | Linux local channel | Linux local receive | Linux startup controller | Linux startup adapter | Linux startup pump | Linux pump report | Linux bounded pump report | Linux pump bounds | Linux registered pump | Linux bus address | Linux auth external | Linux auth exchange | Linux auth connect | Linux Hello | Linux auth hello | Linux registration reply | Linux auth registration | Linux startup replies | Linux application registration | Linux address discovery | Linux host env | Linux GetAddress | Linux auth GetAddress | Linux startup discovery | Linux frame metadata | Linux frame bytes | Linux frame send | Linux packet | Linux packet send | Linux packet decode | Focus evidence | Property change | Orientation event | Set-position event | Hierarchical event | Role property | State-set property | Name | Description | Help text | Placeholder | Value text | Keyboard shortcut | Semantic identifier | Locale | Set position property | Set size property | Hierarchical property | Heading level | Landmark | Bounds property | State change | Bounds | Hit test | Tree change | Window event | Activate action | Action evidence | Toggle action | Expand action | Collapse action | Show menu action | Dismiss action | Open action | Close action | Scroll action | Set focus action | Action payload | Action request payload | Value evidence | Selection evidence | Select all | Selection events | Active descendant | Active descendant event | Current item | Current item event | Tree role | Tree item role | Menu bar role | Menu role | Menu item role | Tab list | Tab role | Tooltip role | Status role | Image role | Decorative image role | Vertical-slice roles | Extended fixture roles | Fixture commands | Text evidence | Text mutation | Text set | Caret evidence | Table evidence | Table current cell | Table sort metadata | Table events | Image evidence | Document evidence | Document events | Protected evidence | Live evidence | Relation evidence | Relation events | Surface evidence | Lifecycle evidence | Normalized output |";

      function Separator_For (Header : String) return String is
         Separator : Unbounded_String;
         Saw_First : Boolean := False;
      begin
         for Character of Header loop
            if Character = '|' then
               if Saw_First then
                  Append (Separator, " --- |");
               else
                  Append (Separator, "|");
                  Saw_First := True;
               end if;
            end if;
         end loop;
         return To_String (Separator);
      end Separator_For;
   begin
      Append (Result, "# a11y Native Observation Report" & ASCII.LF & ASCII.LF);
      Append
        (Result,
         "Readiness: "
         & Readiness_Name
         & "; native conformance ready: "
         & (if Is_Native_Conformance_Ready then "true" else "false")
         & ASCII.LF
         & ASCII.LF);
      Append
        (Result,
         "macOS NSAccessibility captured artifact: "
         & MacOS_NSAccessibility_Artifact_State
         & " (vm/macos-nsax-native-client.txt)"
         & ASCII.LF
         & ASCII.LF);
      Append (Result, "Readiness blockers:" & ASCII.LF);
      for Client of Clients loop
         if not Public_Client_Traversal_Observed (Client) then
            Append
              (Result,
               "- "
               & Trimmed (Client.Platform)
               & ": "
               & Required_Native_Boundary (Client)
               & " -> "
               & Next_Required_Evidence (Client)
               & " (remaining: "
               & Remaining_Evidence (Client)
               & ")"
               & ASCII.LF);
         end if;
      end loop;
      if Readiness_Blocker_Count = 0 then
         Append (Result, "- none" & ASCII.LF);
      end if;
      Append (Result, ASCII.LF);
      Append (Result, Table_Header & ASCII.LF);
      Append (Result, Separator_For (Table_Header) & ASCII.LF);
      for Client of Clients loop
         Append
           (Result,
            "| "
            & Trimmed (Client.Platform)
            & " | "
            & Trimmed (Client.Native_API)
            & " | "
            & Trimmed (Client.Client_Process)
            & " | "
            & Trimmed (Client.Fixture_Command)
            & " | "
            & Trimmed (Client.Fixture_Host_Env_Serve_Command)
            & " | "
            & Trimmed (Client.Runtime_Probe_Command)
            & " | "
            & Trimmed (Client.Registered_Boundary_Probe_Command)
            & " | "
            & Trimmed (Client.Host_Environment_Probe_Command)
            & " | "
            & Trimmed (Client.Fixture_Native_Probe_Command)
            & " | "
            & Trimmed (Client.Serving_Packet_Probe_Command)
            & " | "
            & Trimmed (Client.Session_Bus_Probe_Command)
            & " | "
            & Trimmed (Client.Session_Dispatch_Probe_Command)
            & " | "
            & Trimmed (Client.Status)
            & " | "
            & Natural'Image (Client.Observation_Count)
            & " | "
            & (if Client.Has_Native_Registry_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Registry_Generation_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Registry_Drained_Reset_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Registry_Reset_Node_Rejection_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Registry_Reset_Stale_Id_Rejection_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Registry_Mutation_Report_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Export_Descriptor_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Node_Index_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Cache_Tombstone_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Cache_Session_Scope_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Cache_Generation_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Cache_Mutation_Report_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Runtime_Lifecycle_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Runtime_Lifecycle_Report_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Runtime_Probe_Failure_Stage_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Runtime_Event_Preparation_Report_Observation
               then
                 "yes"
              else
                 "no")
            & " | "
            & (if Client.Has_Native_Boundary_Runtime_Generation_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Deterministic_Shutdown_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Diagnostics_Bounded_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Diagnostics_Result_Mapping_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Diagnostics_Field_Bounds_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Resource_Limit_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Value_Resource_Limit_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Hostile_Identity_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Boundary_Admission_Report_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Boundary_Native_Call_Report_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Boundary_Completion_Report_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Boundary_Release_Report_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Root_Probe_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Fixture_Root_Child_Traversal_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Fixture_Root_Child_Count_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Root_Second_Child_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Child_Query_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Child_Object_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Child_Parent_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Fixture_Child_Native_Identity_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Fixture_Second_Child_Parent_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Fixture_Second_Child_Native_Identity_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Sibling_Order_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Native_Fixture_Child_Stale_Id_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Native_Fixture_Root_Failure_Stage_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_ATSPI_Serving_Packet_Probe_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Linux_ATSPI_Session_Dispatch_Probe_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Malformed_Request_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_Error_Name_Map_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_Error_Name_Inverse_Map_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_Error_Name_Diagnostic_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_DBus_Unsupported_Value_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_DBus_UInt32_Array_Value_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_DBus_State_Set_UInt32_Array_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_DBus_String_Array_Value_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_DBus_Attribute_String_Array_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client
                    .Has_Linux_DBus_Cache_Interface_String_Array_Observation
               then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Linux_DBus_Object_Path_Array_Value_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client
                    .Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation
               then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Windows_HResult_Map_Observation then
                  "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Windows_HResult_Inverse_Map_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Windows_HResult_Diagnostic_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Windows_UIA_Event_Posting_Admission_Observation
               then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Windows_UIA_Event_Posting_Report_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client
                    .Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation
               then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_MacOS_Native_Status_Map_Observation then
                  "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_MacOS_Native_Status_Inverse_Map_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_MacOS_Native_Status_Diagnostic_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_MacOS_NSAX_Event_Posting_Admission_Observation
               then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_MacOS_NSAX_Event_Posting_Report_Observation then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client
                    .Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation
               then
                  "yes"
               else
                  "no")
            & " | "
            & (if Client.Has_Transport_Staging_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Transport_Generation_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Transport_Transition_Report_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Prepared_Status_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_ATSPI_Signal_Build_Report_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Event_Posting_Interest_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Method_Return_Decode_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Error_Return_Decode_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Error_Return_Diagnostic_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Startup_Error_Completion_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Incoming_Packet_Classification_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Startup_Outgoing_Work_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Startup_Event_Loop_Operation_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Startup_Outgoing_Flush_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Outgoing_Back_Pressure_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Connection_Lifecycle_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Local_Channel_Adapter_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Local_Channel_Receive_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Controller_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Backend_Adapter_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Pump_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Pump_Report_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Pump_Bounds_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client
                    .Has_Linux_DBus_Startup_Registered_Pump_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Bus_Address_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Auth_External_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Auth_Exchange_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Authenticated_Connect_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Hello_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Authenticated_Hello_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Registration_Completion_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Authenticated_Registration_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Reply_Evidence_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Application_Registration_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Address_Discovery_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Host_Environment_Startup_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_A11y_Bus_Get_Address_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Authenticated_Get_Address_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Startup_Session_Discovery_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Transport_Frame_Metadata_Observation
               then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Transport_Frame_Bytes_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Transport_Frame_Send_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Transport_Packet_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Transport_Packet_Send_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Linux_DBus_Transport_Packet_Decode_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Focus_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Property_Change_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Orientation_Property_Event_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Set_Position_Property_Event_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Set_Size_Property_Event_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Hierarchical_Level_Property_Event_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Role_Property_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_State_Set_Property_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Name_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Description_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Help_Text_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Placeholder_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Value_Text_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Keyboard_Shortcut_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Semantic_Identifier_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Locale_Property_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Set_Position_Property_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Set_Size_Property_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Hierarchical_Level_Property_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Heading_Level_Property_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Landmark_Property_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Bounds_Property_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_State_Change_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Bounds_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Hit_Test_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Tree_Change_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Window_Event_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Activate_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Toggle_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Expand_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Collapse_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Show_Menu_Action_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Dismiss_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Open_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Close_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Scroll_Action_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Set_Focus_Action_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Action_Payload_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Action_Request_Payload_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Value_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Selection_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Select_All_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Selection_Event_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Active_Descendant_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Active_Descendant_Event_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Current_Item_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Current_Item_Event_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Tree_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Tree_Item_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Menu_Bar_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Menu_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Menu_Item_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Tab_List_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Tab_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Tooltip_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Status_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Image_Role_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Decorative_Image_Role_Observation then
                 "yes"
               else
                 "no")
            & " | "
            & (if Client.Has_Vertical_Slice_Role_Observations then "yes" else "no")
            & " | "
            & (if Client.Has_Extended_Fixture_Role_Observations then "yes" else "no")
            & " | "
            & (if Client.Has_Fixture_Command_Coverage then "yes" else "no")
            & " | "
            & (if Client.Has_Text_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Text_Mutation_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Text_Set_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Caret_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Table_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Table_Current_Cell_Observation
               then "yes" else "no")
            & " | "
            & (if Client.Has_Table_Sort_Metadata_Observation
               then "yes" else "no")
            & " | "
            & (if Client.Has_Table_Event_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Image_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Document_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Document_Event_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Protected_Text_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Live_Region_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Relation_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Relation_Event_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Surface_Observation then "yes" else "no")
            & " | "
            & (if Client.Has_Lifecycle_Observation then "yes" else "no")
            & " | "
            & Trimmed (Client.Normalized_Output)
            & " |"
            & ASCII.LF);
      end loop;
      return To_String (Result);
   end Markdown;

   function JSON return String is
      Result : Unbounded_String;
   begin
      Append (Result, "{" & ASCII.LF);
      Append (Result, "  ""schema"": " & Q (Schema) & "," & ASCII.LF);
      Append
        (Result,
         "  ""client_count"": " & Natural'Image (Client_Count) & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""clients_blocked"": "
         & (if All_Clients_Blocked then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""readiness"": "
         & Q (Readiness_Name)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""native_conformance_ready"": "
         & (if Is_Native_Conformance_Ready then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""readiness_blocker_count"": "
         & Natural'Image (Readiness_Blocker_Count)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""macos_nsaccessibility_native_client_artifact_path"": "
         & Q ("vm/macos-nsax-native-client.txt")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""macos_nsaccessibility_native_client_artifact_state"": "
         & Q (MacOS_NSAccessibility_Artifact_State)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""macos_nsaccessibility_native_client_artifact_complete"": "
         & (if A11y_Release_Qualification
                 .MacOS_NSAccessibility_Public_Client_Traversal_Observed
            then "true"
            else "false")
         & ","
         & ASCII.LF);
      Append (Result, "  ""readiness_blockers"": [" & ASCII.LF);
      declare
         Emitted : Natural := 0;
      begin
         for Index in Clients'Range loop
            declare
               Client : Client_Record renames Clients (Index);
            begin
               if not Public_Client_Traversal_Observed (Client) then
                  Emitted := Emitted + 1;
                  Append
                    (Result,
                     "    {"
                     & """platform"": "
                     & Q (Trimmed (Client.Platform))
                     & ", ""native_api"": "
                     & Q (Trimmed (Client.Native_API))
                     & ", ""blocking_status"": "
                     & Q (Trimmed (Client.Status))
                     & ", ""required_native_boundary"": "
                     & Q (Required_Native_Boundary (Client))
                     & ", ""native_boundary_observed"": "
                     & Native_Boundary_Observed_Name (Client)
                     & ", ""native_boundary_stage"": "
                     & Q (Native_Boundary_Stage (Client))
                     & ", ""internal_native_export_chain_ready"": "
                     & Internal_Native_Export_Chain_Ready_Name (Client)
                     & ", ""public_client_traversal_observed"": "
                     & Public_Client_Traversal_Observed_Name (Client)
                     & ", ""native_vertical_slice_observed"": "
                     & Native_Vertical_Slice_Observed_Name (Client)
                     & ", ""next_required_evidence"": "
                     & Q (Next_Required_Evidence (Client))
                     & ", ""remaining_evidence"": "
                     & Q (Remaining_Evidence (Client))
                     & "}"
                     & (if Emitted = Readiness_Blocker_Count then "" else ",")
                     & ASCII.LF);
               end if;
            end;
         end loop;
      end;
      Append (Result, "  ]," & ASCII.LF);
      Append (Result, "  ""clients"": [" & ASCII.LF);

      for Index in Clients'Range loop
         declare
            Client : Client_Record renames Clients (Index);
            Suffix : constant String :=
              (if Index = Clients'Last then "" else ",");
         begin
            Append
              (Result,
               "    {"
               & """platform"": "
               & Q (Trimmed (Client.Platform))
               & ", ""native_api"": "
               & Q (Trimmed (Client.Native_API))
               & ", ""native_evidence_scope"": "
               & Q (Trimmed (Client.Native_Evidence_Scope))
               & ", ""row_scopes_atspi"": "
               & (if Client.Row_Scopes_ATSPI then "true" else "false")
               & ", ""row_scopes_uia"": "
               & (if Client.Row_Scopes_UIA then "true" else "false")
               & ", ""row_scopes_nsaccessibility"": "
               & (if Client.Row_Scopes_NSAccessibility then
                    "true"
               else
                    "false")
               & ", ""client_process"": "
               & Q (Trimmed (Client.Client_Process))
               & ", ""native_bridge_compiled_for_windows"": "
               & (if Client.Native_Bridge_Compiled_For_Windows then
                    "true"
                  else
                    "false")
               & ", ""windows_native_bridge_stub_runtime"": "
               & (if Client.Windows_Native_Bridge_Stub_Runtime then
                    "true"
                  else
                    "false")
               & ", ""native_bridge_compiled_for_macos"": "
               & (if Client.Native_Bridge_Compiled_For_MacOS then
                    "true"
                  else
                    "false")
               & ", ""macos_native_bridge_stub_runtime"": "
               & (if Client.MacOS_Native_Bridge_Stub_Runtime then
                    "true"
                  else
                    "false")
               & ", ""fixture_command"": "
               & Q (Trimmed (Client.Fixture_Command))
               & ", ""fixture_host_env_serve_command"": "
               & Q (Trimmed (Client.Fixture_Host_Env_Serve_Command))
               & ", ""runtime_probe_command"": "
               & Q (Trimmed (Client.Runtime_Probe_Command))
               & ", ""registered_boundary_probe_command"": "
               & Q (Trimmed (Client.Registered_Boundary_Probe_Command))
               & ", ""host_environment_probe_command"": "
               & Q (Trimmed (Client.Host_Environment_Probe_Command))
               & ", ""fixture_native_probe_command"": "
               & Q (Trimmed (Client.Fixture_Native_Probe_Command))
               & ", ""serving_packet_probe_command"": "
               & Q (Trimmed (Client.Serving_Packet_Probe_Command))
               & ", ""session_bus_probe_command"": "
               & Q (Trimmed (Client.Session_Bus_Probe_Command))
	               & ", ""session_dispatch_probe_command"": "
	               & Q (Trimmed (Client.Session_Dispatch_Probe_Command))
	               & ", ""external_client_probe_command"": "
	               & Q (Trimmed (Client.External_Client_Probe_Command))
	               & ", ""status"": "
               & Q (Trimmed (Client.Status))
               & ", ""observation_count"": "
               & Natural'Image (Client.Observation_Count)
               & ", ""has_native_registry_observation"": "
               & (if Client.Has_Native_Registry_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_export_descriptor_observation"": "
               & (if Client.Has_Native_Export_Descriptor_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_host_window_root_binding_observation"": "
               & (if Client
                       .Has_Windows_UIA_Host_Window_Root_Binding_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_vtable_observation"": "
               & (if Client.Has_Windows_UIA_COM_VTable_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_object_export_observation"": "
               & (if Client.Has_Windows_UIA_COM_Object_Export_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_export_observation"": "
               & (if Client.Has_Windows_UIA_COM_Live_Export_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_bridge_audit_observation"": "
               & (if Client.Has_Windows_UIA_Bridge_Audit_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_interface_retain_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Interface_Retain_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_interface_release_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Interface_Release_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_released_interface_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Released_Interface_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_invalid_interface_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Invalid_Interface_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_invalid_method_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Invalid_Method_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_interface_method_mismatch_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Interface_Method_Mismatch_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_simple_property_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Simple_Property_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_action_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Action_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_navigate_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Navigate_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_last_child_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Last_Child_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_runtime_id_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Runtime_Id_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_embedded_fragment_roots_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Embedded_Fragment_Roots_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_provider_options_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Provider_Options_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_host_raw_element_provider_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Host_Raw_Element_Provider_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_pattern_provider_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Pattern_Provider_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_bounding_rectangle_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Bounding_Rectangle_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_root_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Root_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_root_point_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Root_Point_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_com_live_fragment_root_focus_observation"": "
               & (if Client
                       .Has_Windows_UIA_COM_Live_Fragment_Root_Focus_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_com_live_chain_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_public_root_export_path_observation"": "
               & (if Client
                       .Has_Windows_UIA_Public_Root_Export_Path_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_public_root_native_identity_observation"": "
               & (if Client
                       .Has_Windows_UIA_Public_Root_Native_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_embedded_fragment_roots_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Embedded_Fragment_Roots_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_provider_options_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Provider_Options_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_host_raw_element_provider_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Host_Raw_Element_Provider_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_fragment_root_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Fragment_Root_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_fragment_root_point_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Fragment_Root_Point_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_fragment_root_focus_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Fragment_Root_Focus_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_fragment_last_child_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Fragment_Last_Child_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_bounding_rectangle_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Bounding_Rectangle_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_pattern_provider_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Pattern_Provider_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_simple_property_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Simple_Property_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_action_frame_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Action_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_failure_stage_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Failure_Stage_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_metadata_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Metadata_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_metadata_group_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Metadata_Group_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_protected_value_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Protected_Value_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_external_client_privacy_boundary_observation"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_Privacy_Boundary_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_internal_native_export_chain_ready"": "
               & (if Client
                       .Has_Windows_UIA_External_Client_COM_Live_Chain_Observation
                    and then Client
                      .Has_Windows_UIA_Public_Root_Export_Path_Observation
                    and then Client
                      .Has_Windows_UIA_Public_Root_Native_Identity_Observation
                    and then Client
                      .Has_Windows_UIA_External_Client_Action_Frame_Observation
                     and then Client
                       .Has_Windows_UIA_External_Client_Metadata_Group_Observation
                     and then Client
                       .Has_Windows_UIA_External_Client_Privacy_Boundary_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_main_thread_binding_observation"": "
               & (if Client.Has_MacOS_NSAX_Main_Thread_Binding_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_native_view_binding_observation"": "
               & (if Client.Has_MacOS_NSAX_Native_View_Binding_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_attribute_value_observation"": "
               & (if Client.Has_MacOS_NSAX_Selector_Attribute_Value_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_children_frame_observation"": "
               & (if Client.Has_MacOS_NSAX_Selector_Children_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_child_at_index_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Selector_Child_At_Index_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_attribute_value_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Selector_Attribute_Value_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_attribute_settable_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Selector_Attribute_Settable_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_action_frame_observation"": "
               & (if Client.Has_MacOS_NSAX_Selector_Action_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_unsupported_observation"": "
               & (if Client.Has_MacOS_NSAX_Selector_Unsupported_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selector_main_thread_gate_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Selector_Main_Thread_Gate_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_registered_method_family_mismatch_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Registered_Method_Family_Mismatch_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_released_boundary_observation"": "
               & (if Client.Has_MacOS_NSAX_Released_Boundary_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_bridge_audit_observation"": "
               & (if Client.Has_MacOS_NSAX_Bridge_Audit_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_virtual_element_bridge_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Virtual_Element_Bridge_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_element_chain_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Element_Chain_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_public_root_export_path_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Public_Root_Export_Path_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_public_root_native_identity_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Public_Root_Native_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_public_root_hit_test_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Public_Root_Hit_Test_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_public_root_focused_element_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Public_Root_Focused_Element_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_public_root_notification_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Public_Root_Notification_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_main_thread_binding_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Main_Thread_Binding_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_native_view_binding_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Native_View_Binding_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_children_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Children_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_child_at_index_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Child_At_Index_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_attribute_settable_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Attribute_Settable_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_action_frame_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Action_Frame_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_failure_stage_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Failure_Stage_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_metadata_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Metadata_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_metadata_group_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Metadata_Group_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_protected_value_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Protected_Value_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_external_client_privacy_boundary_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_internal_native_export_chain_ready"": "
               & (if Client
                       .Has_MacOS_NSAX_External_Client_Element_Chain_Observation
                    and then Client
                      .Has_MacOS_NSAX_Public_Root_Export_Path_Observation
                    and then Client
                      .Has_MacOS_NSAX_Public_Root_Native_Identity_Observation
                    and then Client
                      .Has_MacOS_NSAX_External_Client_Action_Frame_Observation
                     and then Client
                       .Has_MacOS_NSAX_External_Client_Metadata_Group_Observation
                     and then Client
                       .Has_MacOS_NSAX_External_Client_Privacy_Boundary_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_node_index_observation"": "
               & (if Client.Has_Native_Node_Index_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_cache_tombstone_observation"": "
               & (if Client.Has_Native_Cache_Tombstone_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_cache_session_scope_observation"": "
               & (if Client.Has_Native_Cache_Session_Scope_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_runtime_lifecycle_observation"": "
               & (if Client.Has_Native_Runtime_Lifecycle_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_runtime_lifecycle_report_observation"": "
               & (if Client.Has_Native_Runtime_Lifecycle_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_runtime_probe_failure_stage_observation"": "
               & (if Client
                       .Has_Native_Runtime_Probe_Failure_Stage_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_runtime_event_application_observation"": "
               & (if Client.Has_Native_Runtime_Event_Application_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_runtime_event_preparation_observation"": "
               & (if Client.Has_Native_Runtime_Event_Preparation_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_runtime_event_preparation_report_observation"": "
               & (if Client
                       .Has_Native_Runtime_Event_Preparation_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_projection_property_observation"": "
               & (if Client.Has_Native_Projection_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_projection_action_observation"": "
               & (if Client.Has_Native_Projection_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_projection_relation_observation"": "
               & (if Client.Has_Native_Projection_Relation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_projection_event_source_observation"": "
               & (if Client.Has_Native_Projection_Event_Source_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_deterministic_shutdown_observation"": "
               & (if Client.Has_Native_Deterministic_Shutdown_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_diagnostics_bounded_observation"": "
               & (if Client.Has_Diagnostics_Bounded_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_diagnostics_result_mapping_observation"": "
               & (if Client.Has_Diagnostics_Result_Mapping_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_diagnostics_field_bounds_observation"": "
               & (if Client.Has_Diagnostics_Field_Bounds_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_resource_limit_observation"": "
               & (if Client.Has_Native_Resource_Limit_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_value_resource_limit_observation"": "
               & (if Client.Has_Native_Value_Resource_Limit_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_hostile_identity_observation"": "
               & (if Client.Has_Hostile_Identity_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_boundary_admission_report_observation"": "
               & (if Client
                       .Has_Native_Boundary_Admission_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_boundary_native_call_report_observation"": "
               & (if Client
                       .Has_Native_Boundary_Native_Call_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_boundary_completion_report_observation"": "
               & (if Client
                       .Has_Native_Boundary_Completion_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_boundary_release_report_observation"": "
               & (if Client
                       .Has_Native_Boundary_Release_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_root_probe_observation"": "
               & (if Client.Has_Native_Fixture_Root_Probe_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_root_failure_stage_observation"": "
               & (if Client
                       .Has_Native_Fixture_Root_Failure_Stage_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_root_child_traversal_observation"": "
               & (if Client
                       .Has_Native_Fixture_Root_Child_Traversal_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_root_child_count_observation"": "
               & (if Client
                       .Has_Native_Fixture_Root_Child_Count_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_root_second_child_observation"": "
               & (if Client.Has_Native_Fixture_Root_Second_Child_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_child_query_observation"": "
               & (if Client.Has_Native_Fixture_Child_Query_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_child_object_observation"": "
               & (if Client.Has_Native_Fixture_Child_Object_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_child_parent_observation"": "
               & (if Client.Has_Native_Fixture_Child_Parent_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_child_native_identity_observation"": "
               & (if Client
                       .Has_Native_Fixture_Child_Native_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_second_child_parent_observation"": "
               & (if Client
                       .Has_Native_Fixture_Second_Child_Parent_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_second_child_native_identity_observation"": "
               & (if Client
                       .Has_Native_Fixture_Second_Child_Native_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_sibling_order_observation"": "
               & (if Client.Has_Native_Fixture_Sibling_Order_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_fixture_child_stale_id_observation"": "
               & (if Client.Has_Native_Fixture_Child_Stale_Id_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_probe_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Probe_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_tree_traversal_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Tree_Traversal_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_property_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Property_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_property_map_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Property_Map_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_stale_error_queued_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Queued_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_stale_error_serialized_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Serialized_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_stale_error_decoded_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Decoded_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_stale_error_drained_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Stale_Error_Drained_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_unsupported_interface_queued_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Queued_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_unsupported_interface_serialized_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Serialized_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_unsupported_interface_decoded_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Decoded_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_unsupported_interface_drained_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Unsupported_Interface_Drained_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_malformed_packet_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Malformed_Packet_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_serving_packet_text_payload_limit_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Serving_Packet_Text_Payload_Limit_Observation
                  then
                    "true"
                  else
                    "false")
	               & ", ""has_linux_atspi_session_bus_probe_observation"": "
	               & (if Client.Has_Linux_ATSPI_Session_Bus_Probe_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_registered_external_client_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_Registered_External_Client_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_vertical_slice_observations"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Vertical_Slice_Observations
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_failure_stage_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Failure_Stage_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_attribute_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Attribute_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_attribute_detail_observations"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Attribute_Detail_Observations
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_protected_value_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Protected_Value_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_component_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Component_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_action_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Action_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_value_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Value_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_selection_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Selection_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_text_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Text_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_image_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Image_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_document_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Document_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_table_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Table_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_surface_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Surface_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_live_external_client_live_region_observation"": "
	               & (if Client
	                       .Has_Linux_ATSPI_Live_External_Client_Live_Region_Observation
	                  then
	                    "true"
	                  else
	                    "false")
	               & ", ""has_linux_atspi_session_startup_stage_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Session_Startup_Stage_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_startup_object_path_observation"": "
               & (if Client.Has_Linux_ATSPI_Startup_Object_Path_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_session_dispatch_probe_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Session_Dispatch_Probe_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_session_dispatch_boundary_drain_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Session_Dispatch_Boundary_Drain_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_session_dispatch_loop_report_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Session_Dispatch_Loop_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_registered_boundary_report_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Registered_Boundary_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_malformed_request_observation"": "
               & (if Client.Has_Malformed_Request_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_error_name_map_observation"": "
               & (if Client.Has_Linux_Error_Name_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_error_name_inverse_map_observation"": "
               & (if Client.Has_Linux_Error_Name_Inverse_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_error_name_diagnostic_observation"": "
               & (if Client.Has_Linux_Error_Name_Diagnostic_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_core_method_observations"": "
               & (if Client.Has_Linux_ATSPI_Core_Method_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_interaction_method_observations"": "
               & (if Client.Has_Linux_ATSPI_Interaction_Method_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_component_focus_observation"": "
               & (if Client.Has_Linux_ATSPI_Component_Focus_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_selection_deselect_observation"": "
               & (if Client.Has_Linux_ATSPI_Selection_Deselect_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_selection_select_all_observation"": "
               & (if Client.Has_Linux_ATSPI_Selection_Select_All_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_selection_clear_observation"": "
               & (if Client.Has_Linux_ATSPI_Selection_Clear_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_content_method_observations"": "
               & (if Client.Has_Linux_ATSPI_Content_Method_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_document_surface_event_observations"": "
               & (if Client
                         .Has_Linux_ATSPI_Document_Surface_Event_Observations
                    then
                       "true"
                    else
                       "false")
               & ", ""has_linux_dbus_unsupported_value_observation"": "
               & (if Client.Has_Linux_DBus_Unsupported_Value_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_uint32_array_value_observation"": "
               & (if Client.Has_Linux_DBus_UInt32_Array_Value_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_state_set_uint32_array_observation"": "
               & (if Client.Has_Linux_DBus_State_Set_UInt32_Array_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_string_array_value_observation"": "
               & (if Client.Has_Linux_DBus_String_Array_Value_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_attribute_string_array_observation"": "
               & (if Client.Has_Linux_DBus_Attribute_String_Array_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_cache_interface_string_array_observation"": "
               & (if Client
                         .Has_Linux_DBus_Cache_Interface_String_Array_Observation
                    then
                       "true"
                    else
                       "false")
               & ", ""has_linux_dbus_object_path_array_observation"": "
               & (if Client.Has_Linux_DBus_Object_Path_Array_Value_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_relation_target_object_path_array_observation"": "
               & (if Client
                         .Has_Linux_DBus_Relation_Target_Object_Path_Array_Observation
                    then
                       "true"
                    else
                       "false")
               & ", ""has_windows_hresult_map_observation"": "
               & (if Client.Has_Windows_HResult_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_hresult_inverse_map_observation"": "
               & (if Client.Has_Windows_HResult_Inverse_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_hresult_diagnostic_observation"": "
               & (if Client.Has_Windows_HResult_Diagnostic_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_event_posting_admission_observation"": "
               & (if Client
                       .Has_Windows_UIA_Event_Posting_Admission_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_event_posting_report_observation"": "
               & (if Client.Has_Windows_UIA_Event_Posting_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_event_posting_drain_bounded_observation"": "
               & (if Client
                       .Has_Windows_UIA_Event_Posting_Drain_Bounded_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_core_routing_observations"": "
               & (if Client.Has_Windows_UIA_Core_Routing_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_metadata_property_observation"": "
               & (if Client.Has_Windows_UIA_Metadata_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_protected_value_observation"": "
               & (if Client.Has_Windows_UIA_Protected_Value_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_advanced_routing_observations"": "
               & (if Client.Has_Windows_UIA_Advanced_Routing_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_selection_select_all_observation"": "
               & (if Client
                       .Has_Windows_UIA_Selection_Select_All_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_selection_clear_observation"": "
               & (if Client.Has_Windows_UIA_Selection_Clear_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_native_focus_query_observation"": "
               & (if Client.Has_Windows_UIA_Native_Focus_Query_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_native_set_focus_observation"": "
               & (if Client.Has_Windows_UIA_Native_Set_Focus_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_hostile_callback_admission_observation"": "
               & (if Client
                       .Has_Windows_UIA_Hostile_Callback_Admission_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_missing_identity_observation"": "
               & (if Client.Has_Windows_UIA_Missing_Identity_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_mismatched_identity_observation"": "
               & (if Client.Has_Windows_UIA_Mismatched_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_malformed_identity_observation"": "
               & (if Client.Has_Windows_UIA_Malformed_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_windows_uia_text_payload_limit_observation"": "
               & (if Client.Has_Windows_UIA_Text_Payload_Limit_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_native_status_map_observation"": "
               & (if Client.Has_MacOS_Native_Status_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_native_status_inverse_map_observation"": "
               & (if Client.Has_MacOS_Native_Status_Inverse_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_native_status_diagnostic_observation"": "
               & (if Client.Has_MacOS_Native_Status_Diagnostic_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_event_posting_admission_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Event_Posting_Admission_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_event_posting_report_observation"": "
               & (if Client.Has_MacOS_NSAX_Event_Posting_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_event_posting_drain_bounded_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Event_Posting_Drain_Bounded_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_core_routing_observations"": "
               & (if Client.Has_MacOS_NSAX_Core_Routing_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_metadata_attribute_observation"": "
               & (if Client.Has_MacOS_NSAX_Metadata_Attribute_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_protected_value_observation"": "
               & (if Client.Has_MacOS_NSAX_Protected_Value_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_advanced_routing_observations"": "
               & (if Client.Has_MacOS_NSAX_Advanced_Routing_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selection_select_all_observation"": "
               & (if Client.Has_MacOS_NSAX_Selection_Select_All_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_selection_clear_observation"": "
               & (if Client.Has_MacOS_NSAX_Selection_Clear_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_native_focus_query_observation"": "
               & (if Client.Has_MacOS_NSAX_Native_Focus_Query_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_native_set_focus_observation"": "
               & (if Client.Has_MacOS_NSAX_Native_Set_Focus_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_hostile_callback_admission_observation"": "
               & (if Client
                       .Has_MacOS_NSAX_Hostile_Callback_Admission_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_missing_identity_observation"": "
               & (if Client.Has_MacOS_NSAX_Missing_Identity_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_mismatched_identity_observation"": "
               & (if Client.Has_MacOS_NSAX_Mismatched_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_malformed_identity_observation"": "
               & (if Client.Has_MacOS_NSAX_Malformed_Identity_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_macos_nsax_text_payload_limit_observation"": "
               & (if Client.Has_MacOS_NSAX_Text_Payload_Limit_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_transport_staging_observation"": "
               & (if Client.Has_Transport_Staging_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_transport_generation_observation"": "
               & (if Client.Has_Transport_Generation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_transport_transition_report_observation"": "
               & (if Client.Has_Transport_Transition_Report_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_cache_generation_observation"": "
               & (if Client.Has_Native_Cache_Generation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_cache_mutation_report_observation"": "
               & (if Client.Has_Native_Cache_Mutation_Report_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_registry_generation_observation"": "
               & (if Client.Has_Native_Registry_Generation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_registry_drained_reset_observation"": "
               & (if Client.Has_Native_Registry_Drained_Reset_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_registry_reset_node_rejection_observation"": "
               & (if Client
                       .Has_Native_Registry_Reset_Node_Rejection_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_registry_reset_stale_id_rejection_observation"": "
               & (if Client
                       .Has_Native_Registry_Reset_Stale_Id_Rejection_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_registry_mutation_report_observation"": "
               & (if Client.Has_Native_Registry_Mutation_Report_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_boundary_runtime_generation_observation"": "
               & (if Client.Has_Native_Boundary_Runtime_Generation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_prepared_status_observation"": "
               & (if Client.Has_Prepared_Status_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_event_posting_interest_observation"": "
               & (if Client.Has_Event_Posting_Interest_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_event_validation_observation"": "
               & (if Client.Has_Native_Event_Validation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_event_posting_boundary_observation"": "
               & (if Client.Has_Native_Event_Posting_Boundary_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_native_event_exhaustive_map_observation"": "
               & (if Client.Has_Native_Event_Exhaustive_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_role_exhaustive_map_observation"": "
               & (if Client.Has_Native_Role_Exhaustive_Map_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_native_relation_exhaustive_map_observation"": "
               & (if Client.Has_Native_Relation_Exhaustive_Map_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_method_return_decode_observation"": "
               & (if Client.Has_Method_Return_Decode_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_error_return_decode_observation"": "
               & (if Client.Has_Error_Return_Decode_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_error_return_diagnostic_observation"": "
               & (if Client.Has_Error_Return_Diagnostic_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_startup_error_completion_observation"": "
               & (if Client.Has_Startup_Error_Completion_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_incoming_packet_classification_observation"": "
               & (if Client.Has_Incoming_Packet_Classification_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_startup_outgoing_work_observation"": "
               & (if Client.Has_Startup_Outgoing_Work_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_startup_event_loop_interest_observation"": "
               & (if Client.Has_Startup_Event_Loop_Interest_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_startup_event_loop_operation_observation"": "
               & (if Client.Has_Startup_Event_Loop_Operation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_backend_session_event_loop_step_observation"": "
               & (if Client
                       .Has_Linux_DBus_Backend_Session_Event_Loop_Step_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_backend_session_transport_cycle_scheduler_observation"": "
               & (if Client
                       .Has_Linux_DBus_Backend_Session_Transport_Cycle_Scheduler_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_startup_outgoing_flush_observation"": "
               & (if Client.Has_Startup_Outgoing_Flush_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_outgoing_back_pressure_observation"": "
               & (if Client.Has_Linux_DBus_Outgoing_Back_Pressure_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_connection_lifecycle_observation"": "
               & (if Client.Has_Linux_DBus_Connection_Lifecycle_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_local_channel_adapter_observation"": "
               & (if Client.Has_Linux_DBus_Local_Channel_Adapter_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_local_channel_receive_observation"": "
               & (if Client.Has_Linux_DBus_Local_Channel_Receive_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_controller_observation"": "
               & (if Client.Has_Linux_DBus_Startup_Controller_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_backend_adapter_observation"": "
               & (if Client.Has_Linux_DBus_Startup_Backend_Adapter_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_pump_observation"": "
               & (if Client.Has_Linux_DBus_Startup_Pump_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_pump_report_observation"": "
               & (if Client.Has_Linux_DBus_Startup_Pump_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_pump_bounded_report_observation"": "
               & (if Client
                       .Has_Linux_DBus_Startup_Pump_Bounded_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_pump_bounds_observation"": "
               & (if Client.Has_Linux_DBus_Startup_Pump_Bounds_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_registered_pump_observation"": "
               & (if Client
                       .Has_Linux_DBus_Startup_Registered_Pump_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_bus_address_observation"": "
               & (if Client.Has_Linux_DBus_Bus_Address_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_auth_external_observation"": "
               & (if Client.Has_Linux_DBus_Auth_External_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_auth_exchange_observation"": "
               & (if Client.Has_Linux_DBus_Auth_Exchange_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_authenticated_connect_observation"": "
               & (if Client.Has_Linux_DBus_Authenticated_Connect_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_hello_observation"": "
               & (if Client.Has_Linux_DBus_Hello_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_authenticated_hello_observation"": "
               & (if Client.Has_Linux_DBus_Authenticated_Hello_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_registration_completion_observation"": "
               & (if Client.Has_Linux_DBus_Registration_Completion_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_authenticated_registration_observation"": "
               & (if Client
                       .Has_Linux_DBus_Authenticated_Registration_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_reply_evidence_observation"": "
               & (if Client
                       .Has_Linux_DBus_Startup_Reply_Evidence_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_application_registration_observation"": "
               & (if Client.Has_Linux_DBus_Application_Registration_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_live_transport_registration_observed_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Live_Transport_Registration_Observed_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_address_discovery_observation"": "
               & (if Client.Has_Linux_DBus_Address_Discovery_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_host_environment_startup_observation"": "
               & (if Client
                       .Has_Linux_DBus_Host_Environment_Startup_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_a11y_bus_get_address_observation"": "
               & (if Client.Has_Linux_DBus_A11y_Bus_Get_Address_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_authenticated_get_address_observation"": "
               & (if Client.Has_Linux_DBus_Authenticated_Get_Address_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_startup_session_discovery_observation"": "
               & (if Client
                       .Has_Linux_DBus_Startup_Session_Discovery_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_frame_metadata_observation"": "
               & (if Client
                       .Has_Linux_DBus_Transport_Frame_Metadata_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_method_call_destination_routing_observation"": "
               & (if Client
                       .Has_Linux_DBus_Method_Call_Destination_Routing_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_frame_bytes_observation"": "
               & (if Client.Has_Linux_DBus_Transport_Frame_Bytes_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_frame_send_observation"": "
               & (if Client.Has_Linux_DBus_Transport_Frame_Send_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_packet_observation"": "
               & (if Client.Has_Linux_DBus_Transport_Packet_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_packet_send_observation"": "
               & (if Client.Has_Linux_DBus_Transport_Packet_Send_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_packet_decode_observation"": "
               & (if Client
                       .Has_Linux_DBus_Transport_Packet_Decode_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_codec_basic_observation"": "
               & (if Client.Has_Linux_DBus_Codec_Basic_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_resource_limits_observation"": "
               & (if Client.Has_Linux_DBus_Resource_Limits_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_message_envelope_observation"": "
               & (if Client.Has_Linux_DBus_Message_Envelope_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_method_call_envelope_observation"": "
               & (if Client.Has_Linux_DBus_Method_Call_Envelope_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_transport_envelope_decode_observation"": "
               & (if Client
                       .Has_Linux_DBus_Transport_Envelope_Decode_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_incoming_call_decode_observation"": "
               & (if Client.Has_Linux_DBus_Incoming_Call_Decode_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_signal_envelope_observation"": "
               & (if Client.Has_Linux_DBus_Signal_Envelope_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_prepared_signal_envelope_observation"": "
               & (if Client
                       .Has_Linux_DBus_Prepared_Signal_Envelope_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_atspi_signal_build_report_observation"": "
               & (if Client
                       .Has_Linux_ATSPI_Signal_Build_Report_Observation
                  then
                    "true"
                  else
                    "false")
               & ", ""has_linux_dbus_method_boundary_observation"": "
               & (if Client.Has_Linux_DBus_Method_Boundary_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_focus_observation"": "
               & (if Client.Has_Focus_Observation then "true" else "false")
               & ", ""has_property_change_observation"": "
               & (if Client.Has_Property_Change_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_orientation_property_event_observation"": "
               & (if Client.Has_Orientation_Property_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_set_position_property_event_observation"": "
               & (if Client.Has_Set_Position_Property_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_set_size_property_event_observation"": "
               & (if Client.Has_Set_Size_Property_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_hierarchical_level_property_event_observation"": "
               & (if Client.Has_Hierarchical_Level_Property_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_role_property_observation"": "
               & (if Client.Has_Role_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_state_set_property_observation"": "
               & (if Client.Has_State_Set_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_name_observation"": "
               & (if Client.Has_Name_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_description_observation"": "
               & (if Client.Has_Description_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_help_text_observation"": "
               & (if Client.Has_Help_Text_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_placeholder_observation"": "
               & (if Client.Has_Placeholder_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_value_text_observation"": "
               & (if Client.Has_Value_Text_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_keyboard_shortcut_observation"": "
               & (if Client.Has_Keyboard_Shortcut_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_semantic_identifier_observation"": "
               & (if Client.Has_Semantic_Identifier_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_locale_property_observation"": "
               & (if Client.Has_Locale_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_visible_title_property_observation"": "
               & (if Client.Has_Visible_Title_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_orientation_property_observation"": "
               & (if Client.Has_Orientation_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_set_position_property_observation"": "
               & (if Client.Has_Set_Position_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_set_size_property_observation"": "
               & (if Client.Has_Set_Size_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_hierarchical_level_property_observation"": "
               & (if Client.Has_Hierarchical_Level_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_heading_level_property_observation"": "
               & (if Client.Has_Heading_Level_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_landmark_property_observation"": "
               & (if Client.Has_Landmark_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_bounds_property_observation"": "
               & (if Client.Has_Bounds_Property_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_state_change_observation"": "
               & (if Client.Has_State_Change_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_bounds_observation"": "
               & (if Client.Has_Bounds_Observation then "true" else "false")
               & ", ""has_hit_test_observation"": "
               & (if Client.Has_Hit_Test_Observation then "true" else "false")
               & ", ""has_tree_change_observation"": "
               & (if Client.Has_Tree_Change_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_window_event_observation"": "
               & (if Client.Has_Window_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_activate_action_observation"": "
               & (if Client.Has_Activate_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_action_observation"": "
               & (if Client.Has_Action_Observation then "true" else "false")
               & ", ""has_toggle_action_observation"": "
               & (if Client.Has_Toggle_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_expand_action_observation"": "
               & (if Client.Has_Expand_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_collapse_action_observation"": "
               & (if Client.Has_Collapse_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_show_menu_action_observation"": "
               & (if Client.Has_Show_Menu_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_dismiss_action_observation"": "
               & (if Client.Has_Dismiss_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_open_action_observation"": "
               & (if Client.Has_Open_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_close_action_observation"": "
               & (if Client.Has_Close_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_scroll_action_observation"": "
               & (if Client.Has_Scroll_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_set_focus_action_observation"": "
               & (if Client.Has_Set_Focus_Action_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_action_payload_observation"": "
               & (if Client.Has_Action_Payload_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_action_request_payload_observation"": "
               & (if Client.Has_Action_Request_Payload_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_value_observation"": "
               & (if Client.Has_Value_Observation then "true" else "false")
               & ", ""has_selection_observation"": "
               & (if Client.Has_Selection_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_select_all_observation"": "
               & (if Client.Has_Select_All_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_selection_event_observation"": "
               & (if Client.Has_Selection_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_active_descendant_observation"": "
               & (if Client.Has_Active_Descendant_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_active_descendant_event_observation"": "
               & (if Client.Has_Active_Descendant_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_current_item_observation"": "
               & (if Client.Has_Current_Item_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_current_item_event_observation"": "
               & (if Client.Has_Current_Item_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_tree_role_observation"": "
               & (if Client.Has_Tree_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_tree_item_role_observation"": "
               & (if Client.Has_Tree_Item_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_menu_bar_role_observation"": "
               & (if Client.Has_Menu_Bar_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_menu_role_observation"": "
               & (if Client.Has_Menu_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_menu_item_role_observation"": "
               & (if Client.Has_Menu_Item_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_tab_list_role_observation"": "
               & (if Client.Has_Tab_List_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_tab_role_observation"": "
               & (if Client.Has_Tab_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_tooltip_role_observation"": "
               & (if Client.Has_Tooltip_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_status_role_observation"": "
               & (if Client.Has_Status_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_image_role_observation"": "
               & (if Client.Has_Image_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_decorative_image_role_observation"": "
               & (if Client.Has_Decorative_Image_Role_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_vertical_slice_role_observations"": "
               & (if Client.Has_Vertical_Slice_Role_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_extended_fixture_role_observations"": "
               & (if Client.Has_Extended_Fixture_Role_Observations then
                    "true"
                  else
                    "false")
               & ", ""has_fixture_command_coverage"": "
               & (if Client.Has_Fixture_Command_Coverage then
                    "true"
                  else
                    "false")
               & ", ""has_text_observation"": "
               & (if Client.Has_Text_Observation then "true" else "false")
               & ", ""has_text_mutation_observation"": "
               & (if Client.Has_Text_Mutation_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_text_set_observation"": "
               & (if Client.Has_Text_Set_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_caret_observation"": "
               & (if Client.Has_Caret_Observation then "true" else "false")
               & ", ""has_table_observation"": "
               & (if Client.Has_Table_Observation then "true" else "false")
               & ", ""has_table_current_cell_observation"": "
               & (if Client.Has_Table_Current_Cell_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_table_sort_metadata_observation"": "
               & (if Client.Has_Table_Sort_Metadata_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_table_event_observation"": "
               & (if Client.Has_Table_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_image_observation"": "
               & (if Client.Has_Image_Observation then "true" else "false")
               & ", ""has_document_observation"": "
               & (if Client.Has_Document_Observation then "true" else "false")
               & ", ""has_document_event_observation"": "
               & (if Client.Has_Document_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_protected_text_observation"": "
               & (if Client.Has_Protected_Text_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_live_region_observation"": "
               & (if Client.Has_Live_Region_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_relation_observation"": "
               & (if Client.Has_Relation_Observation then "true" else "false")
               & ", ""has_relation_event_observation"": "
               & (if Client.Has_Relation_Event_Observation then
                    "true"
                  else
                    "false")
               & ", ""has_surface_observation"": "
               & (if Client.Has_Surface_Observation then "true" else "false")
               & ", ""has_lifecycle_observation"": "
               & (if Client.Has_Lifecycle_Observation then
                    "true"
                  else
                    "false")
               & ", ""normalized_output"": "
               & Q (Trimmed (Client.Normalized_Output))
               & "}"
               & Suffix
               & ASCII.LF);
         end;
      end loop;

      Append (Result, "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Result);
   end JSON;

   function Summary_JSON return String is
      Result : Unbounded_String;
   begin
      Append (Result, "{" & ASCII.LF);
      Append (Result, "  ""schema"": " & Q (Schema & ".summary") & "," & ASCII.LF);
      Append
        (Result,
         "  ""client_count"": " & Natural'Image (Client_Count) & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""readiness"": "
         & Q (Readiness_Name)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""native_conformance_ready"": "
         & (if Is_Native_Conformance_Ready then "true" else "false")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""readiness_blocker_count"": "
         & Natural'Image (Readiness_Blocker_Count)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""macos_nsaccessibility_native_client_artifact_path"": "
         & Q ("vm/macos-nsax-native-client.txt")
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""macos_nsaccessibility_native_client_artifact_state"": "
         & Q (MacOS_NSAccessibility_Artifact_State)
         & ","
         & ASCII.LF);
      Append
        (Result,
         "  ""macos_nsaccessibility_native_client_artifact_complete"": "
         & (if A11y_Release_Qualification
                 .MacOS_NSAccessibility_Public_Client_Traversal_Observed
            then "true"
            else "false")
         & ","
         & ASCII.LF);
      Append (Result, "  ""readiness_blockers"": [" & ASCII.LF);
      declare
         Emitted : Natural := 0;
      begin
         for Index in Clients'Range loop
            declare
               Client : Client_Record renames Clients (Index);
            begin
               if not Public_Client_Traversal_Observed (Client) then
                  Emitted := Emitted + 1;
                  Append
                    (Result,
                     "    {"
                     & """platform"": "
                     & Q (Trimmed (Client.Platform))
                     & ", ""native_api"": "
                     & Q (Trimmed (Client.Native_API))
                     & ", ""status"": "
                     & Q (Trimmed (Client.Status))
                     & ", ""observation_count"": "
                     & Natural'Image (Client.Observation_Count)
                     & ", ""required_native_boundary"": "
                     & Q (Required_Native_Boundary (Client))
                     & ", ""native_boundary_observed"": "
                     & Native_Boundary_Observed_Name (Client)
                     & ", ""native_boundary_stage"": "
                     & Q (Native_Boundary_Stage (Client))
                     & ", ""internal_native_export_chain_ready"": "
                     & Internal_Native_Export_Chain_Ready_Name (Client)
                     & ", ""public_client_traversal_observed"": "
                     & Public_Client_Traversal_Observed_Name (Client)
                     & ", ""native_vertical_slice_observed"": "
                     & Native_Vertical_Slice_Observed_Name (Client)
                     & ", ""next_required_evidence"": "
                     & Q (Next_Required_Evidence (Client))
                     & ", ""remaining_evidence"": "
                     & Q (Remaining_Evidence (Client))
                     & "}"
                     & (if Emitted = Readiness_Blocker_Count then "" else ",")
                     & ASCII.LF);
               end if;
            end;
         end loop;
      end;
      Append (Result, "  ]" & ASCII.LF & "}" & ASCII.LF);
      return To_String (Result);
   end Summary_JSON;

end A11y_Native_Observation_Report;
