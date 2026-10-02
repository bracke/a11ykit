package body A11y.Dispatchers.Classification is
   pragma SPARK_Mode (On);

   function Timeout_Limit_For
     (Kind : Call_Kind)
      return A11y.Resource_Limits.Limit_Kind is
     (case Kind is
        when Shutdown =>
          A11y.Resource_Limits.Shutdown_Duration_MS,
        when others =>
          A11y.Resource_Limits.Callback_Duration_MS);

   function Is_Cancellable_Kind (Kind : Call_Kind) return Boolean is
     (Kind /= Shutdown);

   function Has_Timed_Out
     (Config     : A11y.Resource_Limits.Resource_Limit_Config;
      Kind       : Call_Kind;
      Elapsed_MS : Natural)
      return Boolean is
     (A11y.Resource_Limits.">="
        (A11y.Resource_Limits.Limit_Value (Elapsed_MS),
         A11y.Resource_Limits.Value (Config, Timeout_Limit_For (Kind))));

   function Rejects_Before_Callback
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Callback_Present  : Boolean;
      Outstanding_Count : Natural)
      return Boolean is
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
      return A11y.Results.Status_Code is
     (if Stopping then A11y.Results.Shutting_Down
      elsif Token_Cancelled and then Is_Cancellable_Kind (Kind) then
        A11y.Results.Cancelled
      elsif not Callback_Present then A11y.Results.Invalid_Argument
      else A11y.Results.Busy);

   function Counts_Reentrant_Rejection
     (Outstanding_Count : Natural)
      return Boolean is
     (Outstanding_Count > 0);

   function Rejects_On_Dispatch_Thread
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Outstanding_Count : Natural)
      return Boolean is
     (Stopping
      or else (Token_Cancelled and then Is_Cancellable_Kind (Kind))
      or else Outstanding_Count = 0);

   function Dispatch_Thread_Rejection_Status
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Outstanding_Count : Natural)
      return A11y.Results.Status_Code is
     (if Stopping then A11y.Results.Shutting_Down
      elsif Token_Cancelled and then Is_Cancellable_Kind (Kind) then
        A11y.Results.Cancelled
      else A11y.Results.Invalid_State);

end A11y.Dispatchers.Classification;
