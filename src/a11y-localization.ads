with A11y.Diagnostics;
with A11y.Results;

package A11y.Localization is

   type Message_Key is
     (Diagnostic_Backend_Initialization,
      Diagnostic_Native_Runtime_Connection,
      Diagnostic_Native_Registration,
      Diagnostic_Node_Lifecycle,
      Diagnostic_Provider_Timeout,
      Diagnostic_Mapping_Fallback,
      Diagnostic_Unsupported_Capability,
      Diagnostic_Resource_Limit,
      Diagnostic_Event_Overflow,
      Diagnostic_Stale_Native_Query,
      Diagnostic_Text_Conversion,
      Diagnostic_Native_Allocation,
      Diagnostic_ABI_Boundary_Failure,
      Diagnostic_Reference_Count_Anomaly,
      Diagnostic_Autorelease_Anomaly,
      Diagnostic_Shutdown_Anomaly,
      Diagnostic_Conformance_Failure,
      Severity_Trace,
      Severity_Info,
      Severity_Warning,
      Severity_Error,
      Severity_Fatal,
      Result_Success,
      Result_Accepted_Asynchronous,
      Result_Backend_Unavailable,
      Result_Accessibility_Service_Unavailable,
      Result_Node_Unavailable,
      Result_Unsupported_Property,
      Result_Unsupported_Capability,
      Result_Unsupported_Action,
      Result_Invalid_Argument,
      Result_Invalid_State,
      Result_Invalid_Range,
      Result_Read_Only,
      Result_Disabled,
      Result_Busy,
      Result_Timed_Out,
      Result_Cancelled,
      Result_Shutting_Down,
      Result_Permission_Denied,
      Result_Protocol_Failure,
      Result_Native_Failure,
      Result_Resource_Limit,
      Result_Out_Of_Resources,
      Result_Internal_Error);

   function Stable_Key (Key : Message_Key) return String;

   function Key_For_Category
     (Class : A11y.Diagnostics.Category)
      return Message_Key;

   function Key_For_Severity
     (Level : A11y.Diagnostics.Severity)
      return Message_Key;

   function Key_For_Status
     (Status : A11y.Results.Status_Code)
      return Message_Key;

   function Render
     (Key    : Message_Key;
      Locale : String := "en")
      return String;

   function Render_Category
     (Class  : A11y.Diagnostics.Category;
      Locale : String := "en")
      return String;

   function Render_Severity
     (Level  : A11y.Diagnostics.Severity;
      Locale : String := "en")
      return String;

   function Render_Status
     (Status : A11y.Results.Status_Code;
      Locale : String := "en")
      return String;

end A11y.Localization;
