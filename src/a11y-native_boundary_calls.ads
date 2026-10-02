with A11y.Native_Callbacks;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Dispatchers;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Resource_Limits;

package A11y.Native_Boundary_Calls is
   use type A11y.Results.Status_Code;

   type Boundary_Call_Context is private;

   type Boundary_Return_Class is
     (Return_Success,
      Return_Unsupported,
      Return_Unavailable,
      Return_Invalid_Argument,
      Return_Invalid_State,
      Return_Read_Only,
      Return_Disabled,
      Return_Busy,
      Return_Timed_Out,
      Return_Cancelled,
      Return_Shutting_Down,
      Return_Permission_Denied,
      Return_Protocol_Failure,
      Return_Native_Failure,
      Return_Resource_Limit,
      Return_Internal_Error);

   type Boundary_Call_Snapshot is record
      Active  : Boolean := False;
      Object  : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Runtime_Generation : Natural := 0;
      Cache_Generation : Natural := 0;
      Node    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Defunct : Boolean := False;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query;
      Timeout_Limit : A11y.Resource_Limits.Limit_Kind :=
        A11y.Resource_Limits.Callback_Duration_MS;
      Last_Status : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

   type Boundary_Call_Outcome is record
      Active        : Boolean := False;
      Object        : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Runtime_Generation : Natural := 0;
      Cache_Generation : Natural := 0;
      Node          : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Defunct       : Boolean := False;
      Kind          : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query;
      Timeout_Limit : A11y.Resource_Limits.Limit_Kind :=
        A11y.Resource_Limits.Callback_Duration_MS;
      Status        : A11y.Results.Status_Code := A11y.Results.Success;
      Class         : Boundary_Return_Class := Return_Success;
   end record;

   type Boundary_Call_Admission_Report is record
      Requested_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Requested_Node   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Object           : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Node             : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Runtime_Generation : Natural := 0;
      Cache_Generation   : Natural := 0;
      Kind             : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query;
      Timeout_Limit    : A11y.Resource_Limits.Limit_Kind :=
        A11y.Resource_Limits.Callback_Duration_MS;
      Callback_Admitted : Boolean := False;
      Object_Resolved   : Boolean := False;
      Active            : Boolean := False;
      Defunct           : Boolean := False;
      Status            : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Class             : Boundary_Return_Class := Return_Unavailable;
   end record;

   type Boundary_Call_Completion_Report is record
      Before : Boundary_Call_Snapshot;
      After  : Boundary_Call_Snapshot;
      Requested_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Final_Status     : A11y.Results.Status_Code := A11y.Results.Success;
      Record_Result_Status : A11y.Results.Status_Code :=
        A11y.Results.Success;
      End_Result_Status    : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Recorded : Boolean := False;
      Released : Boolean := False;
      Status   : A11y.Results.Status_Code := A11y.Results.Success;
      Class    : Boundary_Return_Class := Return_Success;
   end record;

   type Boundary_Call_Release_Report is record
      Before : Boundary_Call_Snapshot;
      After  : Boundary_Call_Snapshot;
      Preserved_Status : A11y.Results.Status_Code := A11y.Results.Success;
      End_Result_Status : A11y.Results.Status_Code := A11y.Results.Success;
      Released : Boolean := False;
      Status   : A11y.Results.Status_Code := A11y.Results.Success;
      Class    : Boundary_Return_Class := Return_Success;
   end record;

   function Return_Class
     (Status : A11y.Results.Status_Code)
      return Boundary_Return_Class
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Return_Class'Result =
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
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Should_Replace_Final_Status'Result =
          (Current_Status = A11y.Results.Success
           and then Candidate_Status not in A11y.Results.Success
                                        | A11y.Results.Accepted_Asynchronous);

   function Completion_Operation_Status
     (Record_Result_Status : A11y.Results.Status_Code;
      End_Result_Status    : A11y.Results.Status_Code)
      return A11y.Results.Status_Code
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Completion_Operation_Status'Result =
          (if End_Result_Status not in A11y.Results.Success
                                      | A11y.Results.Accepted_Asynchronous
           then End_Result_Status
           else Record_Result_Status);

   function Final_Status_Overrides_Action
     (Final_Status  : A11y.Results.Status_Code;
      Action_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Final_Status_Overrides_Action'Result =
          (Final_Status /= Action_Status);

   function Dispatch_Status_Overrides_Query
     (Dispatch_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Dispatch_Status_Overrides_Query'Result =
          (Dispatch_Status not in A11y.Results.Success
                                | A11y.Results.Accepted_Asynchronous);

   function Dispatch_Status_Overrides_Action
     (Dispatch_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Dispatch_Status_Overrides_Action'Result =
          (Dispatch_Status not in A11y.Results.Success
                                | A11y.Results.Accepted_Asynchronous);

   function Begin_Status_Rejects_Call
     (Begin_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Begin_Status_Rejects_Call'Result =
          (Begin_Status not in A11y.Results.Success
                               | A11y.Results.Accepted_Asynchronous);

   procedure Begin_Object_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Object  : A11y.Native_Object_Caches.Native_Object_Id;
      Context : out Boundary_Call_Context;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query);

   procedure Begin_Object_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Object  : A11y.Native_Object_Caches.Native_Object_Id;
      Context : out Boundary_Call_Context;
      Report  : out Boundary_Call_Admission_Report;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query);

   procedure Begin_Node_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Context : out Boundary_Call_Context;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query);

   procedure Begin_Node_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Context : out Boundary_Call_Context;
      Report  : out Boundary_Call_Admission_Report;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query);

   procedure End_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Result  : out A11y.Results.Result);

   procedure End_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Report  : out Boundary_Call_Release_Report;
      Result  : out A11y.Results.Result);

   procedure Record_Status
     (Context : in out Boundary_Call_Context;
      Status  : A11y.Results.Status_Code;
      Result  : out A11y.Results.Result);

   procedure Complete_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Status  : in out A11y.Results.Status_Code;
      Result  : out A11y.Results.Result);

   procedure Complete_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Status  : in out A11y.Results.Status_Code;
      Report  : out Boundary_Call_Completion_Report;
      Result  : out A11y.Results.Result);

   function Snapshot
     (Context : Boundary_Call_Context)
      return Boundary_Call_Snapshot;

   function Outcome
     (Context : Boundary_Call_Context)
      return Boundary_Call_Outcome;

private
   type Boundary_Call_Context is record
      Active : Boolean := False;
      Token  : A11y.Native_Callbacks.Callback_Token :=
        A11y.Native_Callbacks.No_Token;
      Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Runtime_Generation : Natural := 0;
      Item   : A11y.Native_Object_Caches.Object_Snapshot;
      Kind   : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query;
      Last_Status : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

end A11y.Native_Boundary_Calls;
