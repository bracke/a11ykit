package body A11y.Results.Classification is
   pragma SPARK_Mode (On);

   function Is_Success_Status
     (Status : A11y.Results.Status_Code)
      return Boolean is
     (Status in A11y.Results.Success
      | A11y.Results.Accepted_Asynchronous);

   function Is_Expected_Status
     (Status : A11y.Results.Status_Code)
      return Boolean is
     (Status not in A11y.Results.Protocol_Failure
      | A11y.Results.Native_Failure
      | A11y.Results.Out_Of_Resources
      | A11y.Results.Internal_Error);

   function Succeeded
     (Item : A11y.Results.Result)
      return Boolean is
     (Is_Success_Status (Item.Status));

   function Failed
     (Item : A11y.Results.Result)
      return Boolean is
     (not Succeeded (Item));

end A11y.Results.Classification;
