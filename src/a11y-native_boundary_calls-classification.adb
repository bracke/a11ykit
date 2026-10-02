package body A11y.Native_Boundary_Calls.Classification is
   pragma SPARK_Mode (On);

   function Return_Class
     (Status : A11y.Results.Status_Code)
      return Boundary_Return_Class is
     (case Status is
        when A11y.Results.Success |
             A11y.Results.Accepted_Asynchronous =>
          Return_Success,
        when A11y.Results.Unsupported_Property |
             A11y.Results.Unsupported_Capability |
             A11y.Results.Unsupported_Action =>
          Return_Unsupported,
        when A11y.Results.Backend_Unavailable |
             A11y.Results.Accessibility_Service_Unavailable |
             A11y.Results.Node_Unavailable =>
          Return_Unavailable,
        when A11y.Results.Invalid_Argument |
             A11y.Results.Invalid_Range =>
          Return_Invalid_Argument,
        when A11y.Results.Invalid_State =>
          Return_Invalid_State,
        when A11y.Results.Read_Only =>
          Return_Read_Only,
        when A11y.Results.Disabled =>
          Return_Disabled,
        when A11y.Results.Busy =>
          Return_Busy,
        when A11y.Results.Timed_Out =>
          Return_Timed_Out,
        when A11y.Results.Cancelled =>
          Return_Cancelled,
        when A11y.Results.Shutting_Down =>
          Return_Shutting_Down,
        when A11y.Results.Permission_Denied =>
          Return_Permission_Denied,
        when A11y.Results.Protocol_Failure =>
          Return_Protocol_Failure,
        when A11y.Results.Native_Failure =>
          Return_Native_Failure,
        when A11y.Results.Resource_Limit |
             A11y.Results.Out_Of_Resources =>
          Return_Resource_Limit,
        when A11y.Results.Internal_Error =>
          Return_Internal_Error);

   function Should_Replace_Final_Status
     (Current_Status  : A11y.Results.Status_Code;
      Candidate_Status : A11y.Results.Status_Code)
      return Boolean is
     (Current_Status = A11y.Results.Success
      and then Candidate_Status not in A11y.Results.Success
                                   | A11y.Results.Accepted_Asynchronous);

   function Completion_Operation_Status
     (Record_Result_Status : A11y.Results.Status_Code;
      End_Result_Status    : A11y.Results.Status_Code)
      return A11y.Results.Status_Code is
     (if End_Result_Status not in A11y.Results.Success
                                 | A11y.Results.Accepted_Asynchronous
      then End_Result_Status
      else Record_Result_Status);

   function Final_Status_Overrides_Action
     (Final_Status  : A11y.Results.Status_Code;
      Action_Status : A11y.Results.Status_Code)
      return Boolean is
     (Final_Status /= Action_Status);

   function Dispatch_Status_Overrides_Query
     (Dispatch_Status : A11y.Results.Status_Code)
      return Boolean is
     (Dispatch_Status not in A11y.Results.Success
                         | A11y.Results.Accepted_Asynchronous);

   function Dispatch_Status_Overrides_Action
     (Dispatch_Status : A11y.Results.Status_Code)
      return Boolean is
     (Dispatch_Status not in A11y.Results.Success
                         | A11y.Results.Accepted_Asynchronous);

   function Begin_Status_Rejects_Call
     (Begin_Status : A11y.Results.Status_Code)
      return Boolean is
     (Begin_Status not in A11y.Results.Success
                         | A11y.Results.Accepted_Asynchronous);

end A11y.Native_Boundary_Calls.Classification;
