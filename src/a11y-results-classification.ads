package A11y.Results.Classification is
   pragma SPARK_Mode (On);

   function Is_Success_Status
     (Status : A11y.Results.Status_Code)
      return Boolean
     with
       Global => null,
       Post =>
         Is_Success_Status'Result =
           (Status in A11y.Results.Success
            | A11y.Results.Accepted_Asynchronous);

   function Is_Expected_Status
     (Status : A11y.Results.Status_Code)
      return Boolean
     with
       Global => null,
       Post =>
         Is_Expected_Status'Result =
           (Status not in A11y.Results.Protocol_Failure
            | A11y.Results.Native_Failure
            | A11y.Results.Out_Of_Resources
            | A11y.Results.Internal_Error);

   function Succeeded
     (Item : A11y.Results.Result)
      return Boolean
     with
       Global => null,
       Post =>
         Succeeded'Result = Is_Success_Status (Item.Status);

   function Failed
     (Item : A11y.Results.Result)
      return Boolean
     with
       Global => null,
       Post => Failed'Result = not Succeeded (Item);

end A11y.Results.Classification;
