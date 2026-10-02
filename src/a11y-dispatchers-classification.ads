with A11y.Resource_Limits;
with A11y.Results;

package A11y.Dispatchers.Classification is
   pragma SPARK_Mode (On);
   use type A11y.Resource_Limits.Limit_Kind;
   use type A11y.Results.Status_Code;

   function Timeout_Limit_For
     (Kind : Call_Kind)
      return A11y.Resource_Limits.Limit_Kind
   with
      Global => null,
      Post =>
        Timeout_Limit_For'Result =
          (case Kind is
             when Shutdown =>
               A11y.Resource_Limits.Shutdown_Duration_MS,
             when others =>
               A11y.Resource_Limits.Callback_Duration_MS);

   function Is_Cancellable_Kind (Kind : Call_Kind) return Boolean
   with
      Global => null,
      Post => Is_Cancellable_Kind'Result = (Kind /= Shutdown);

   function Has_Timed_Out
     (Config     : A11y.Resource_Limits.Resource_Limit_Config;
      Kind       : Call_Kind;
      Elapsed_MS : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Has_Timed_Out'Result =
          A11y.Resource_Limits.">="
            (A11y.Resource_Limits.Limit_Value (Elapsed_MS),
             A11y.Resource_Limits.Value
               (Config, Timeout_Limit_For (Kind)));

   function Rejects_Before_Callback
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Callback_Present  : Boolean;
      Outstanding_Count : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Rejects_Before_Callback'Result =
          (Stopping
           or else (Token_Cancelled and then Is_Cancellable_Kind (Kind))
           or else not Callback_Present
           or else Outstanding_Count > 0);

   function Before_Callback_Rejection_Status
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Callback_Present  : Boolean;
      Outstanding_Count : Natural)
      return A11y.Results.Status_Code
   with
      Global => null,
      Pre =>
        Rejects_Before_Callback
          (Stopping,
           Token_Cancelled,
           Kind,
           Callback_Present,
           Outstanding_Count),
      Post =>
        (if Stopping then
           A11y.Results."="
             (Before_Callback_Rejection_Status'Result,
              A11y.Results.Shutting_Down)
         elsif Token_Cancelled and then Is_Cancellable_Kind (Kind) then
           A11y.Results."="
             (Before_Callback_Rejection_Status'Result,
              A11y.Results.Cancelled)
         elsif not Callback_Present then
           A11y.Results."="
             (Before_Callback_Rejection_Status'Result,
              A11y.Results.Invalid_Argument)
         else
           A11y.Results."="
             (Before_Callback_Rejection_Status'Result,
              A11y.Results.Busy));

   function Counts_Reentrant_Rejection
     (Outstanding_Count : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Counts_Reentrant_Rejection'Result = (Outstanding_Count > 0);

   function Rejects_On_Dispatch_Thread
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Outstanding_Count : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Rejects_On_Dispatch_Thread'Result =
          (Stopping
           or else (Token_Cancelled and then Is_Cancellable_Kind (Kind))
           or else Outstanding_Count = 0);

   function Dispatch_Thread_Rejection_Status
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Outstanding_Count : Natural)
      return A11y.Results.Status_Code
   with
      Global => null,
      Pre =>
        Rejects_On_Dispatch_Thread
          (Stopping, Token_Cancelled, Kind, Outstanding_Count),
      Post =>
        (if Stopping then
           A11y.Results."="
             (Dispatch_Thread_Rejection_Status'Result,
              A11y.Results.Shutting_Down)
         elsif Token_Cancelled and then Is_Cancellable_Kind (Kind) then
           A11y.Results."="
             (Dispatch_Thread_Rejection_Status'Result,
              A11y.Results.Cancelled)
         else
           A11y.Results."="
             (Dispatch_Thread_Rejection_Status'Result,
              A11y.Results.Invalid_State));

end A11y.Dispatchers.Classification;
