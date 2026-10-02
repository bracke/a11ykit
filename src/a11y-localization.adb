with Messages.Arguments;
with Messages.Result;
with Messages.Runtime;

package body A11y.Localization is
   use type Messages.Result.Render_Status;
   use type Messages.Runtime.Load_Status;

   Default_Catalog : constant String :=
     "default_locale = en" & ASCII.LF
     & "en.diagnostic.backend.initialization = ""Backend initialization""" & ASCII.LF
     & "en.diagnostic.native-runtime.connection = ""Native runtime connection""" & ASCII.LF
     & "en.diagnostic.native.registration = ""Native registration""" & ASCII.LF
     & "en.diagnostic.node.lifecycle = ""Node lifecycle""" & ASCII.LF
     & "en.diagnostic.provider.timeout = ""Provider timeout""" & ASCII.LF
     & "en.diagnostic.mapping.fallback = ""Mapping fallback""" & ASCII.LF
     & "en.diagnostic.unsupported.capability = ""Unsupported capability""" & ASCII.LF
     & "en.diagnostic.resource.limit = ""Resource limit""" & ASCII.LF
     & "en.diagnostic.event.overflow = ""Event overflow""" & ASCII.LF
     & "en.diagnostic.stale-native.query = ""Stale native query""" & ASCII.LF
     & "en.diagnostic.text.conversion = ""Text conversion""" & ASCII.LF
     & "en.diagnostic.native.allocation = ""Native allocation""" & ASCII.LF
     & "en.diagnostic.abi-boundary.failure = ""ABI boundary failure""" & ASCII.LF
     & "en.diagnostic.reference-count.anomaly = ""Reference-count anomaly""" & ASCII.LF
     & "en.diagnostic.autorelease.anomaly = ""Autorelease anomaly""" & ASCII.LF
     & "en.diagnostic.shutdown.anomaly = ""Shutdown anomaly""" & ASCII.LF
     & "en.diagnostic.conformance.failure = ""Conformance failure""" & ASCII.LF
     & "en.severity.trace = ""Trace""" & ASCII.LF
     & "en.severity.info = ""Info""" & ASCII.LF
     & "en.severity.warning = ""Warning""" & ASCII.LF
     & "en.severity.error = ""Error""" & ASCII.LF
     & "en.severity.fatal = ""Fatal""" & ASCII.LF
     & "en.result.success = ""Success""" & ASCII.LF
     & "en.result.accepted-asynchronous = ""Accepted asynchronously""" & ASCII.LF
     & "en.result.backend-unavailable = ""Backend unavailable""" & ASCII.LF
     & "en.result.accessibility-service-unavailable = ""Accessibility service unavailable""" & ASCII.LF
     & "en.result.node-unavailable = ""Node unavailable""" & ASCII.LF
     & "en.result.unsupported-property = ""Unsupported property""" & ASCII.LF
     & "en.result.unsupported-capability = ""Unsupported capability""" & ASCII.LF
     & "en.result.unsupported-action = ""Unsupported action""" & ASCII.LF
     & "en.result.invalid-argument = ""Invalid argument""" & ASCII.LF
     & "en.result.invalid-state = ""Invalid state""" & ASCII.LF
     & "en.result.invalid-range = ""Invalid range""" & ASCII.LF
     & "en.result.read-only = ""Read-only""" & ASCII.LF
     & "en.result.disabled = ""Disabled""" & ASCII.LF
     & "en.result.busy = ""Busy""" & ASCII.LF
     & "en.result.timed-out = ""Timed out""" & ASCII.LF
     & "en.result.cancelled = ""Cancelled""" & ASCII.LF
     & "en.result.shutting-down = ""Shutting down""" & ASCII.LF
     & "en.result.permission-denied = ""Permission denied""" & ASCII.LF
     & "en.result.protocol-failure = ""Protocol failure""" & ASCII.LF
     & "en.result.native-failure = ""Native failure""" & ASCII.LF
     & "en.result.resource-limit = ""Resource limit""" & ASCII.LF
     & "en.result.out-of-resources = ""Out of resources""" & ASCII.LF
     & "en.result.internal-error = ""Internal error""" & ASCII.LF;

   Catalog : Messages.Runtime.Instance;
   Catalog_Load : Messages.Runtime.Load_Result;

   function Stable_Key (Key : Message_Key) return String is
     (case Key is
        when Diagnostic_Backend_Initialization =>
          "diagnostic.backend.initialization",
        when Diagnostic_Native_Runtime_Connection =>
          "diagnostic.native-runtime.connection",
        when Diagnostic_Native_Registration =>
          "diagnostic.native.registration",
        when Diagnostic_Node_Lifecycle =>
          "diagnostic.node.lifecycle",
        when Diagnostic_Provider_Timeout =>
          "diagnostic.provider.timeout",
        when Diagnostic_Mapping_Fallback =>
          "diagnostic.mapping.fallback",
        when Diagnostic_Unsupported_Capability =>
          "diagnostic.unsupported.capability",
        when Diagnostic_Resource_Limit =>
          "diagnostic.resource.limit",
        when Diagnostic_Event_Overflow =>
          "diagnostic.event.overflow",
        when Diagnostic_Stale_Native_Query =>
          "diagnostic.stale-native.query",
        when Diagnostic_Text_Conversion =>
          "diagnostic.text.conversion",
        when Diagnostic_Native_Allocation =>
          "diagnostic.native.allocation",
        when Diagnostic_ABI_Boundary_Failure =>
          "diagnostic.abi-boundary.failure",
        when Diagnostic_Reference_Count_Anomaly =>
          "diagnostic.reference-count.anomaly",
        when Diagnostic_Autorelease_Anomaly =>
          "diagnostic.autorelease.anomaly",
        when Diagnostic_Shutdown_Anomaly =>
          "diagnostic.shutdown.anomaly",
        when Diagnostic_Conformance_Failure =>
          "diagnostic.conformance.failure",
        when Severity_Trace =>
          "severity.trace",
        when Severity_Info =>
          "severity.info",
        when Severity_Warning =>
          "severity.warning",
        when Severity_Error =>
          "severity.error",
        when Severity_Fatal =>
          "severity.fatal",
        when Result_Success =>
          "result.success",
        when Result_Accepted_Asynchronous =>
          "result.accepted-asynchronous",
        when Result_Backend_Unavailable =>
          "result.backend-unavailable",
        when Result_Accessibility_Service_Unavailable =>
          "result.accessibility-service-unavailable",
        when Result_Node_Unavailable =>
          "result.node-unavailable",
        when Result_Unsupported_Property =>
          "result.unsupported-property",
        when Result_Unsupported_Capability =>
          "result.unsupported-capability",
        when Result_Unsupported_Action =>
          "result.unsupported-action",
        when Result_Invalid_Argument =>
          "result.invalid-argument",
        when Result_Invalid_State =>
          "result.invalid-state",
        when Result_Invalid_Range =>
          "result.invalid-range",
        when Result_Read_Only =>
          "result.read-only",
        when Result_Disabled =>
          "result.disabled",
        when Result_Busy =>
          "result.busy",
        when Result_Timed_Out =>
          "result.timed-out",
        when Result_Cancelled =>
          "result.cancelled",
        when Result_Shutting_Down =>
          "result.shutting-down",
        when Result_Permission_Denied =>
          "result.permission-denied",
        when Result_Protocol_Failure =>
          "result.protocol-failure",
        when Result_Native_Failure =>
          "result.native-failure",
        when Result_Resource_Limit =>
          "result.resource-limit",
        when Result_Out_Of_Resources =>
          "result.out-of-resources",
        when Result_Internal_Error =>
          "result.internal-error");

   function Key_For_Category
     (Class : A11y.Diagnostics.Category)
      return Message_Key is
     (case Class is
        when A11y.Diagnostics.Backend_Initialization =>
          Diagnostic_Backend_Initialization,
        when A11y.Diagnostics.Native_Runtime_Connection =>
          Diagnostic_Native_Runtime_Connection,
        when A11y.Diagnostics.Native_Registration =>
          Diagnostic_Native_Registration,
        when A11y.Diagnostics.Node_Lifecycle =>
          Diagnostic_Node_Lifecycle,
        when A11y.Diagnostics.Provider_Timeout =>
          Diagnostic_Provider_Timeout,
        when A11y.Diagnostics.Mapping_Fallback =>
          Diagnostic_Mapping_Fallback,
        when A11y.Diagnostics.Unsupported_Capability =>
          Diagnostic_Unsupported_Capability,
        when A11y.Diagnostics.Resource_Limit =>
          Diagnostic_Resource_Limit,
        when A11y.Diagnostics.Event_Overflow =>
          Diagnostic_Event_Overflow,
        when A11y.Diagnostics.Stale_Native_Query =>
          Diagnostic_Stale_Native_Query,
        when A11y.Diagnostics.Text_Conversion =>
          Diagnostic_Text_Conversion,
        when A11y.Diagnostics.Native_Allocation =>
          Diagnostic_Native_Allocation,
        when A11y.Diagnostics.ABI_Boundary_Failure =>
          Diagnostic_ABI_Boundary_Failure,
        when A11y.Diagnostics.Reference_Count_Anomaly =>
          Diagnostic_Reference_Count_Anomaly,
        when A11y.Diagnostics.Autorelease_Anomaly =>
          Diagnostic_Autorelease_Anomaly,
        when A11y.Diagnostics.Shutdown_Anomaly =>
          Diagnostic_Shutdown_Anomaly,
        when A11y.Diagnostics.Conformance_Failure =>
          Diagnostic_Conformance_Failure);

   function Key_For_Severity
     (Level : A11y.Diagnostics.Severity)
      return Message_Key is
     (case Level is
        when A11y.Diagnostics.Trace =>
          Severity_Trace,
        when A11y.Diagnostics.Info =>
          Severity_Info,
        when A11y.Diagnostics.Warning =>
          Severity_Warning,
        when A11y.Diagnostics.Error =>
          Severity_Error,
        when A11y.Diagnostics.Fatal =>
          Severity_Fatal);

   function Key_For_Status
     (Status : A11y.Results.Status_Code)
      return Message_Key is
     (case Status is
        when A11y.Results.Success =>
          Result_Success,
        when A11y.Results.Accepted_Asynchronous =>
          Result_Accepted_Asynchronous,
        when A11y.Results.Backend_Unavailable =>
          Result_Backend_Unavailable,
        when A11y.Results.Accessibility_Service_Unavailable =>
          Result_Accessibility_Service_Unavailable,
        when A11y.Results.Node_Unavailable =>
          Result_Node_Unavailable,
        when A11y.Results.Unsupported_Property =>
          Result_Unsupported_Property,
        when A11y.Results.Unsupported_Capability =>
          Result_Unsupported_Capability,
        when A11y.Results.Unsupported_Action =>
          Result_Unsupported_Action,
        when A11y.Results.Invalid_Argument =>
          Result_Invalid_Argument,
        when A11y.Results.Invalid_State =>
          Result_Invalid_State,
        when A11y.Results.Invalid_Range =>
          Result_Invalid_Range,
        when A11y.Results.Read_Only =>
          Result_Read_Only,
        when A11y.Results.Disabled =>
          Result_Disabled,
        when A11y.Results.Busy =>
          Result_Busy,
        when A11y.Results.Timed_Out =>
          Result_Timed_Out,
        when A11y.Results.Cancelled =>
          Result_Cancelled,
        when A11y.Results.Shutting_Down =>
          Result_Shutting_Down,
        when A11y.Results.Permission_Denied =>
          Result_Permission_Denied,
        when A11y.Results.Protocol_Failure =>
          Result_Protocol_Failure,
        when A11y.Results.Native_Failure =>
          Result_Native_Failure,
        when A11y.Results.Resource_Limit =>
          Result_Resource_Limit,
        when A11y.Results.Out_Of_Resources =>
          Result_Out_Of_Resources,
        when A11y.Results.Internal_Error =>
          Result_Internal_Error);

   function Render
     (Key    : Message_Key;
      Locale : String := "en")
      return String
   is
      Args    : Messages.Arguments.Arguments;
   begin
      if Catalog_Load.Status /= Messages.Runtime.Loaded then
         return Stable_Key (Key);
      end if;

      declare
         Result : constant Messages.Result.Render_Result :=
           Messages.Runtime.Render
             (Item      => Catalog,
              Locale    => Locale,
              Key       => Stable_Key (Key),
              Arguments => Args);
      begin
         if Result.Status = Messages.Result.Success then
            return Messages.Result.Output_Text (Result.Text);
         end if;
      end;

      return Stable_Key (Key);
   end Render;

   function Render_Category
     (Class  : A11y.Diagnostics.Category;
      Locale : String := "en")
     return String is
     (Render (Key_For_Category (Class), Locale));

   function Render_Severity
     (Level  : A11y.Diagnostics.Severity;
      Locale : String := "en")
      return String is
     (Render (Key_For_Severity (Level), Locale));

   function Render_Status
     (Status : A11y.Results.Status_Code;
      Locale : String := "en")
      return String is
     (Render (Key_For_Status (Status), Locale));

begin
   Messages.Runtime.Load_Text
     (Item        => Catalog,
      Source_Name => "a11y-default-catalog",
      Text        => Default_Catalog,
      Result      => Catalog_Load);
end A11y.Localization;
