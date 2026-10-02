package A11y.Properties.Classification is
   pragma SPARK_Mode (On);

   function Is_Available
     (Status : A11y.Properties.Property_Status)
      return Boolean
     with
       Global => null,
       Post =>
         Is_Available'Result =
           (Status in A11y.Properties.Present | A11y.Properties.Empty);

   function Is_Expected_Failure
     (Status : A11y.Properties.Property_Status)
      return Boolean
     with
       Global => null,
       Post =>
         Is_Expected_Failure'Result =
           (Status in A11y.Properties.Unsupported
            | A11y.Properties.Temporarily_Unavailable
            | A11y.Properties.Node_Unavailable
            | A11y.Properties.Resource_Limited
            | A11y.Properties.Permission_Denied);

   function Status_From_Result
     (Status : A11y.Results.Status_Code)
      return A11y.Properties.Property_Status
     with
       Global => null,
       Post =>
         (case Status is
            when A11y.Results.Success =>
              Status_From_Result'Result = A11y.Properties.Present,
            when A11y.Results.Node_Unavailable =>
              Status_From_Result'Result = A11y.Properties.Node_Unavailable,
            when A11y.Results.Timed_Out
               | A11y.Results.Cancelled
               | A11y.Results.Busy
               | A11y.Results.Shutting_Down =>
              Status_From_Result'Result =
                A11y.Properties.Temporarily_Unavailable,
            when A11y.Results.Unsupported_Property
               | A11y.Results.Unsupported_Capability =>
              Status_From_Result'Result = A11y.Properties.Unsupported,
            when A11y.Results.Resource_Limit
               | A11y.Results.Out_Of_Resources =>
              Status_From_Result'Result = A11y.Properties.Resource_Limited,
            when A11y.Results.Permission_Denied =>
              Status_From_Result'Result = A11y.Properties.Permission_Denied,
            when others =>
              Status_From_Result'Result = A11y.Properties.Error);

   function Value_Kind_For
     (Id : A11y.Properties.Property_Id)
      return A11y.Properties.Property_Value_Kind
     with
       Global => null,
       Post =>
         (case Id is
            when A11y.Properties.Bounds =>
              Value_Kind_For'Result = A11y.Properties.Rectangle_Value,
            when A11y.Properties.Set_Position
               | A11y.Properties.Set_Size
               | A11y.Properties.Hierarchical_Level
               | A11y.Properties.Heading_Level =>
              Value_Kind_For'Result = A11y.Properties.Integer_Value,
            when A11y.Properties.Role_Property =>
              Value_Kind_For'Result = A11y.Properties.Role_Value,
            when A11y.Properties.State_Property =>
              Value_Kind_For'Result = A11y.Properties.State_Set_Value,
            when others =>
              Value_Kind_For'Result = A11y.Properties.String_Value);

end A11y.Properties.Classification;
