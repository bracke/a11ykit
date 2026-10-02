with A11y.Results;

package A11y.Diagnostics.Classification is
   pragma SPARK_Mode (On);

   function Category_For_Status
     (Status : A11y.Results.Status_Code)
      return Category
   with
      Global => null,
      Post =>
        (case Status is
           when A11y.Results.Success
              | A11y.Results.Accepted_Asynchronous
              | A11y.Results.Invalid_State
              | A11y.Results.Read_Only
              | A11y.Results.Disabled
              | A11y.Results.Busy
              | A11y.Results.Cancelled
              | A11y.Results.Permission_Denied =>
             Category_For_Status'Result = Node_Lifecycle,
           when A11y.Results.Backend_Unavailable
              | A11y.Results.Accessibility_Service_Unavailable =>
             Category_For_Status'Result = Native_Runtime_Connection,
           when A11y.Results.Node_Unavailable =>
             Category_For_Status'Result = Stale_Native_Query,
           when A11y.Results.Unsupported_Property
              | A11y.Results.Unsupported_Capability
              | A11y.Results.Unsupported_Action =>
             Category_For_Status'Result = Unsupported_Capability,
           when A11y.Results.Invalid_Argument
              | A11y.Results.Invalid_Range
              | A11y.Results.Protocol_Failure
              | A11y.Results.Native_Failure
              | A11y.Results.Internal_Error =>
             Category_For_Status'Result = ABI_Boundary_Failure,
           when A11y.Results.Timed_Out =>
             Category_For_Status'Result = Provider_Timeout,
           when A11y.Results.Shutting_Down =>
             Category_For_Status'Result = Shutdown_Anomaly,
           when A11y.Results.Resource_Limit =>
             Category_For_Status'Result = Resource_Limit,
           when A11y.Results.Out_Of_Resources =>
             Category_For_Status'Result = Native_Allocation);

   function Default_Severity
     (Class : Category)
      return Severity
   with
      Global => null,
      Post =>
        (case Class is
           when Backend_Initialization
              | Node_Lifecycle =>
             Default_Severity'Result = Info,
           when Native_Runtime_Connection
              | Native_Registration
              | Provider_Timeout
              | Mapping_Fallback
              | Resource_Limit
              | Stale_Native_Query
              | Shutdown_Anomaly =>
             Default_Severity'Result = Warning,
           when Unsupported_Capability =>
             Default_Severity'Result = Trace,
           when Event_Overflow
              | Text_Conversion
              | ABI_Boundary_Failure
              | Reference_Count_Anomaly
              | Autorelease_Anomaly
              | Conformance_Failure =>
             Default_Severity'Result = Error,
           when Native_Allocation =>
             Default_Severity'Result = Fatal);

   function Severity_For_Status
     (Status : A11y.Results.Status_Code)
      return Severity
   with
      Global => null,
      Post =>
        (if Status in A11y.Results.Success
                    | A11y.Results.Accepted_Asynchronous
         then Severity_For_Status'Result = Trace
         else Severity_For_Status'Result =
              Default_Severity (Category_For_Status (Status)));

   function Is_Reportable
     (Level : Severity)
      return Boolean
   with
      Global => null,
      Post => Is_Reportable'Result = (Level in Warning | Error | Fatal);

   function Is_Native_Boundary_Category
     (Class : Category)
      return Boolean
   with
      Global => null,
      Post => Is_Native_Boundary_Category'Result =
        (Class in Native_Runtime_Connection | Native_Registration
         | Stale_Native_Query | Native_Allocation | ABI_Boundary_Failure
         | Reference_Count_Anomaly | Autorelease_Anomaly);

end A11y.Diagnostics.Classification;
