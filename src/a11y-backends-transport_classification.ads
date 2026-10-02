with A11y.Results;

package A11y.Backends.Transport_Classification is
   pragma SPARK_Mode (On);
   use type A11y.Results.Status_Code;

   function Can_Mutate_Transport
     (Runtime_State : Backend_State)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Mutate_Transport'Result =
          (Runtime_State in Created | Initialized | Stopped);

   function Failure_Status_Allowed
     (Status : A11y.Results.Status_Code)
      return Boolean
   with
      Global => null,
      Post => Failure_Status_Allowed'Result = (Status /= A11y.Results.Success);

   function Should_Advance_On_Admission
     (Admitted    : Boolean;
      Last_Status : A11y.Results.Status_Code)
      return Boolean
   with
      Global => null,
      Post =>
        Should_Advance_On_Admission'Result =
          ((not Admitted) or else Last_Status /= A11y.Results.Success);

   function Should_Advance_On_Failure
     (Admitted         : Boolean;
      Last_Status      : A11y.Results.Status_Code;
      Requested_Status : A11y.Results.Status_Code)
      return Boolean
   with
      Global => null,
      Pre => Failure_Status_Allowed (Requested_Status),
      Post =>
        Should_Advance_On_Failure'Result =
          (Admitted or else Last_Status /= Requested_Status);

   function Should_Advance_On_Stop
     (Was_Admitted : Boolean;
      Was_Running  : Boolean;
      Last_Status  : A11y.Results.Status_Code;
      Stop_Status  : A11y.Results.Status_Code)
      return Boolean
   with
      Global => null,
      Post =>
        Should_Advance_On_Stop'Result =
          (Was_Admitted
           or else Was_Running
           or else Last_Status /= Stop_Status);

   function Should_Advance_On_Start_Connected
     (Admitted : Boolean)
      return Boolean
   with
      Global => null,
      Post => Should_Advance_On_Start_Connected'Result = Admitted;

   function Should_Advance_On_Start_Unavailable
     (Last_Status : A11y.Results.Status_Code)
      return Boolean
   with
      Global => null,
      Post =>
        Should_Advance_On_Start_Unavailable'Result =
          (Last_Status /= A11y.Results.Backend_Unavailable);

   function Can_Prepare_Publication
     (Admitted : Boolean)
      return Boolean
   with
      Global => null,
      Post => Can_Prepare_Publication'Result = Admitted;

   function Should_Advance_On_Publication_Status
     (Last_Status        : A11y.Results.Status_Code;
      Publication_Status : A11y.Results.Status_Code)
      return Boolean
   with
      Global => null,
      Post =>
        Should_Advance_On_Publication_Status'Result =
          (Last_Status /= Publication_Status);

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean
   with
      Global => null,
      Post => Generation_Changed'Result = (After > Before);

   function Flag_Changed
     (Before : Boolean;
      After  : Boolean)
      return Boolean
   with
      Global => null,
      Post => Flag_Changed'Result = (After /= Before);

end A11y.Backends.Transport_Classification;
