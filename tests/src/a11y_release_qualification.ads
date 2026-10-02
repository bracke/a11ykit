package A11y_Release_Qualification is
   Schema : constant String := "org.a11y.release_qualification.v3";

   function Scenario_Count return Natural;
   function Linux_Required_Scenario_Count return Natural;
   function Windows_Required_Scenario_Count return Natural;
   function MacOS_Required_Scenario_Count return Natural;
   function Has_Core_Assistive_Technology_For_All_Platforms return Boolean;
   function Has_Tree_Traversal_For_All_Platforms return Boolean;
   function Has_Protected_Text_For_All_Platforms return Boolean;
   function Has_Window_Lifecycle_For_All_Platforms return Boolean;
   function Has_Action_Requests_For_All_Platforms return Boolean;
   function Has_Relations_For_All_Platforms return Boolean;
   function Has_Live_Announcements_For_All_Platforms return Boolean;
   function Evidence_Pending_Count return Natural;
   function Evidence_Captured_Count return Natural;
   function Linux_Evidence_Pending_Count return Natural;
   function Linux_Evidence_Captured_Count return Natural;
   function Windows_Evidence_Pending_Count return Natural;
   function Windows_Evidence_Captured_Count return Natural;
   function MacOS_Evidence_Pending_Count return Natural;
   function MacOS_Evidence_Captured_Count return Natural;
   function All_Evidence_Pending return Boolean;
   function Linux_ATSPI_Evidence_Template_JSON return String;
   function Linux_ATSPI_Host_Evidence_JSON return String;
   function Linux_ATSPI_Captured_Evidence_Status_JSON
     (Evidence_JSON : String) return String;
   function Windows_UIA_Evidence_Template_JSON return String;
   function Windows_UIA_Captured_Evidence_Status_JSON
     (Evidence_JSON : String) return String;
   function Windows_UIA_Public_Client_Traversal_Observed return Boolean;
   function Native_Client_Artifact_Status_JSON return String;
   function Native_Client_Artifacts_Complete return Boolean;
   function MacOS_NSAccessibility_Evidence_Template_JSON return String;
   function MacOS_NSAccessibility_Captured_Evidence_Status_JSON
     (Evidence_JSON : String) return String;
   function MacOS_NSAccessibility_Native_Client_Artifact_Status_JSON
     (Artifact_JSON : String) return String;
   function MacOS_NSAccessibility_Native_Client_Artifact_Path return String;
   function MacOS_NSAccessibility_Native_Client_Artifact_File_Status_JSON
     return String;
   function MacOS_NSAccessibility_Native_Client_Artifact_Complete
     (Artifact_JSON : String) return Boolean;
   function MacOS_NSAccessibility_Native_Client_Artifact_Available
     return Boolean;
   function MacOS_NSAccessibility_Public_Client_Traversal_Observed
     return Boolean;
   function Captured_Evidence_Summary_JSON
     (Linux_Evidence_JSON   : String;
      Windows_Evidence_JSON : String;
      MacOS_Evidence_JSON   : String) return String;
   function Platform_Evidence_Summary_JSON return String;
   function Project_Completion_Complete return Boolean;
   function Project_Completion_Gate_JSON return String;
   function Project_Completion_Gate_JSON
     (Linux_ATSPI_Artifact_JSON  : String;
      Windows_UIA_Artifact_Text  : String;
      MacOS_NSAX_Artifact_JSON   : String)
      return String;
   function Markdown return String;
   function JSON return String;
end A11y_Release_Qualification;
