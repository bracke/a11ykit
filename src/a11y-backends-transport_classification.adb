package body A11y.Backends.Transport_Classification is
   pragma SPARK_Mode (On);

   function Can_Mutate_Transport
     (Runtime_State : Backend_State)
      return Boolean is
     (A11y.Backends.Can_Mutate_Transport (Runtime_State));

   function Failure_Status_Allowed
     (Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Backends.Failure_Status_Allowed (Status));

   function Should_Advance_On_Admission
     (Admitted    : Boolean;
      Last_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Backends.Should_Advance_On_Admission (Admitted, Last_Status));

   function Should_Advance_On_Failure
     (Admitted         : Boolean;
      Last_Status      : A11y.Results.Status_Code;
      Requested_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Backends.Should_Advance_On_Failure
        (Admitted, Last_Status, Requested_Status));

   function Should_Advance_On_Stop
     (Was_Admitted : Boolean;
      Was_Running  : Boolean;
      Last_Status  : A11y.Results.Status_Code;
      Stop_Status  : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Backends.Should_Advance_On_Stop
        (Was_Admitted, Was_Running, Last_Status, Stop_Status));

   function Should_Advance_On_Start_Connected
     (Admitted : Boolean)
      return Boolean is
     (A11y.Backends.Should_Advance_On_Start_Connected (Admitted));

   function Should_Advance_On_Start_Unavailable
     (Last_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Backends.Should_Advance_On_Start_Unavailable (Last_Status));

   function Can_Prepare_Publication
     (Admitted : Boolean)
      return Boolean is
     (A11y.Backends.Can_Prepare_Publication (Admitted));

   function Should_Advance_On_Publication_Status
     (Last_Status        : A11y.Results.Status_Code;
      Publication_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Backends.Should_Advance_On_Publication_Status
        (Last_Status, Publication_Status));

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (A11y.Backends.Generation_Changed (Before, After));

   function Flag_Changed
     (Before : Boolean;
      After  : Boolean)
      return Boolean is
     (A11y.Backends.Flag_Changed (Before, After));

end A11y.Backends.Transport_Classification;
