with A11y.Results.Classification;

package body A11y.Results is
   pragma SPARK_Mode (On);

   Success_Name                         : aliased constant String := "success";
   Accepted_Asynchronous_Name           : aliased constant String :=
     "accepted-asynchronous";
   Backend_Unavailable_Name             : aliased constant String :=
     "backend-unavailable";
   Accessibility_Service_Unavailable_Name : aliased constant String :=
     "accessibility-service-unavailable";
   Node_Unavailable_Name                : aliased constant String :=
     "node-unavailable";
   Unsupported_Property_Name            : aliased constant String :=
     "unsupported-property";
   Unsupported_Capability_Name          : aliased constant String :=
     "unsupported-capability";
   Unsupported_Action_Name              : aliased constant String :=
     "unsupported-action";
   Invalid_Argument_Name                : aliased constant String :=
     "invalid-argument";
   Invalid_State_Name                   : aliased constant String :=
     "invalid-state";
   Invalid_Range_Name                   : aliased constant String :=
     "invalid-range";
   Read_Only_Name                       : aliased constant String := "read-only";
   Disabled_Name                        : aliased constant String := "disabled";
   Busy_Name                            : aliased constant String := "busy";
   Timed_Out_Name                       : aliased constant String := "timed-out";
   Cancelled_Name                       : aliased constant String := "cancelled";
   Shutting_Down_Name                   : aliased constant String :=
     "shutting-down";
   Permission_Denied_Name               : aliased constant String :=
     "permission-denied";
   Protocol_Failure_Name                : aliased constant String :=
     "protocol-failure";
   Native_Failure_Name                  : aliased constant String :=
     "native-failure";
   Resource_Limit_Name                  : aliased constant String :=
     "resource-limit";
   Out_Of_Resources_Name                : aliased constant String :=
     "out-of-resources";
   Internal_Error_Name                  : aliased constant String :=
     "internal-error";

   function Is_Success_Status
     (Status : Status_Code)
      return Boolean is
     (A11y.Results.Classification.Is_Success_Status (Status));

   function Is_Expected_Status
     (Status : Status_Code)
      return Boolean is
     (A11y.Results.Classification.Is_Expected_Status (Status));

   function Metadata (Status : Status_Code) return Status_Metadata is
     (case Status is
        when Success =>
          (Stable_Name => Success_Name'Access,
           Is_Success => True,
           Expected => True),
        when Accepted_Asynchronous =>
          (Stable_Name => Accepted_Asynchronous_Name'Access,
           Is_Success => True,
           Expected => True),
        when Backend_Unavailable =>
          (Stable_Name => Backend_Unavailable_Name'Access,
           Is_Success => False,
           Expected => True),
        when Accessibility_Service_Unavailable =>
          (Stable_Name => Accessibility_Service_Unavailable_Name'Access,
           Is_Success => False,
           Expected => True),
        when Node_Unavailable =>
          (Stable_Name => Node_Unavailable_Name'Access,
           Is_Success => False,
           Expected => True),
        when Unsupported_Property =>
          (Stable_Name => Unsupported_Property_Name'Access,
           Is_Success => False,
           Expected => True),
        when Unsupported_Capability =>
          (Stable_Name => Unsupported_Capability_Name'Access,
           Is_Success => False,
           Expected => True),
        when Unsupported_Action =>
          (Stable_Name => Unsupported_Action_Name'Access,
           Is_Success => False,
           Expected => True),
        when Invalid_Argument =>
          (Stable_Name => Invalid_Argument_Name'Access,
           Is_Success => False,
           Expected => True),
        when Invalid_State =>
          (Stable_Name => Invalid_State_Name'Access,
           Is_Success => False,
           Expected => True),
        when Invalid_Range =>
          (Stable_Name => Invalid_Range_Name'Access,
           Is_Success => False,
           Expected => True),
        when Read_Only =>
          (Stable_Name => Read_Only_Name'Access,
           Is_Success => False,
           Expected => True),
        when Disabled =>
          (Stable_Name => Disabled_Name'Access,
           Is_Success => False,
           Expected => True),
        when Busy =>
          (Stable_Name => Busy_Name'Access,
           Is_Success => False,
           Expected => True),
        when Timed_Out =>
          (Stable_Name => Timed_Out_Name'Access,
           Is_Success => False,
           Expected => True),
        when Cancelled =>
          (Stable_Name => Cancelled_Name'Access,
           Is_Success => False,
           Expected => True),
        when Shutting_Down =>
          (Stable_Name => Shutting_Down_Name'Access,
           Is_Success => False,
           Expected => True),
        when Permission_Denied =>
          (Stable_Name => Permission_Denied_Name'Access,
           Is_Success => False,
           Expected => True),
        when Protocol_Failure =>
          (Stable_Name => Protocol_Failure_Name'Access,
           Is_Success => False,
           Expected => False),
        when Native_Failure =>
          (Stable_Name => Native_Failure_Name'Access,
           Is_Success => False,
           Expected => False),
        when Resource_Limit =>
          (Stable_Name => Resource_Limit_Name'Access,
           Is_Success => False,
           Expected => True),
        when Out_Of_Resources =>
          (Stable_Name => Out_Of_Resources_Name'Access,
           Is_Success => False,
           Expected => False),
        when Internal_Error =>
          (Stable_Name => Internal_Error_Name'Access,
           Is_Success => False,
           Expected => False));

   function Stable_Name (Status : Status_Code) return String is
     (Metadata (Status).Stable_Name.all);

   function Succeeded (Item : Result) return Boolean is
     (A11y.Results.Classification.Succeeded (Item));

   function Failed (Item : Result) return Boolean is
     (A11y.Results.Classification.Failed (Item));

end A11y.Results;
