package A11y.Results is
   pragma SPARK_Mode (On);

   type Status_Code is
     (Success,
      Accepted_Asynchronous,
      Backend_Unavailable,
      Accessibility_Service_Unavailable,
      Node_Unavailable,
      Unsupported_Property,
      Unsupported_Capability,
      Unsupported_Action,
      Invalid_Argument,
      Invalid_State,
      Invalid_Range,
      Read_Only,
      Disabled,
      Busy,
      Timed_Out,
      Cancelled,
      Shutting_Down,
      Permission_Denied,
      Protocol_Failure,
      Native_Failure,
      Resource_Limit,
      Out_Of_Resources,
      Internal_Error);

   type Result is record
      Status : Status_Code := Success;
   end record;

   type Stable_Name_Access is access constant String;

   type Status_Metadata is record
      Stable_Name : Stable_Name_Access;
      Is_Success  : Boolean := False;
      Expected    : Boolean := True;
   end record;

   Ok : constant Result := (Status => Success);

   function Is_Success_Status
     (Status : Status_Code)
      return Boolean
   with
      Global => null,
      Post =>
        Is_Success_Status'Result =
          (Status in Success | Accepted_Asynchronous);

   function Is_Expected_Status
     (Status : Status_Code)
      return Boolean
   with
      Global => null,
      Post =>
        Is_Expected_Status'Result =
          (Status not in Protocol_Failure
           | Native_Failure
           | Out_Of_Resources
           | Internal_Error);

   function Metadata (Status : Status_Code) return Status_Metadata
   with
      Global => null,
      Post =>
        Metadata'Result.Is_Success = Is_Success_Status (Status)
        and then Metadata'Result.Expected = Is_Expected_Status (Status);

   function Stable_Name (Status : Status_Code) return String;

   function Succeeded (Item : Result) return Boolean
     with
       Global => null,
       Post =>
         Succeeded'Result = Is_Success_Status (Item.Status);

   function Failed (Item : Result) return Boolean
     with
       Global => null,
       Post => Failed'Result = not Succeeded (Item);

end A11y.Results;
