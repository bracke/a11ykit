with A11y.Dispatchers.Classification;

package body A11y.Dispatchers is
   Simple_Property_Query_Name : aliased constant String :=
     "simple-property-query";
   Tree_Navigation_Query_Name : aliased constant String :=
     "tree-navigation-query";
   Geometry_Query_Name        : aliased constant String := "geometry-query";
   Text_Query_Name            : aliased constant String := "text-query";
   Action_Invocation_Name     : aliased constant String := "action-invocation";
   Window_Operation_Name      : aliased constant String := "window-operation";
   Shutdown_Name              : aliased constant String := "shutdown";

   function Metadata (Kind : Call_Kind) return Call_Kind_Metadata is
     (case Kind is
        when Simple_Property_Query =>
          (Stable_Name => Simple_Property_Query_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Callback_Duration_MS,
           Cancellable => True),
        when Tree_Navigation_Query =>
          (Stable_Name => Tree_Navigation_Query_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Callback_Duration_MS,
           Cancellable => True),
        when Geometry_Query =>
          (Stable_Name => Geometry_Query_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Callback_Duration_MS,
           Cancellable => True),
        when Text_Query =>
          (Stable_Name => Text_Query_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Callback_Duration_MS,
           Cancellable => True),
        when Action_Invocation =>
          (Stable_Name => Action_Invocation_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Callback_Duration_MS,
           Cancellable => True),
        when Window_Operation =>
          (Stable_Name => Window_Operation_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Callback_Duration_MS,
           Cancellable => True),
        when Shutdown =>
          (Stable_Name => Shutdown_Name'Access,
           Timeout_Limit => A11y.Resource_Limits.Shutdown_Duration_MS,
           Cancellable => False));

   function Stable_Name (Kind : Call_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Timeout_Limit_For
     (Kind : Call_Kind)
      return A11y.Resource_Limits.Limit_Kind is
     (A11y.Dispatchers.Classification.Timeout_Limit_For (Kind))
   with SPARK_Mode => On;

   function Is_Cancellable_Kind (Kind : Call_Kind) return Boolean is
     (A11y.Dispatchers.Classification.Is_Cancellable_Kind (Kind))
   with SPARK_Mode => On;

   function Timeout_Limit
     (Kind : Call_Kind)
      return A11y.Resource_Limits.Limit_Kind is
     (Timeout_Limit_For (Kind))
   with SPARK_Mode => On;

   function Is_Cancellable (Kind : Call_Kind) return Boolean is
     (Is_Cancellable_Kind (Kind))
   with SPARK_Mode => On;

   function Has_Timed_Out
     (Config     : A11y.Resource_Limits.Resource_Limit_Config;
      Kind       : Call_Kind;
      Elapsed_MS : Natural)
      return Boolean is
     (A11y.Dispatchers.Classification.Has_Timed_Out
        (Config, Kind, Elapsed_MS))
   with SPARK_Mode => On;

   function Rejects_Before_Callback
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Callback_Present  : Boolean;
      Outstanding_Count : Natural)
      return Boolean is
     (A11y.Dispatchers.Classification.Rejects_Before_Callback
        (Stopping,
         Token_Cancelled,
         Kind,
         Callback_Present,
         Outstanding_Count))
   with SPARK_Mode => On;

   function Before_Callback_Rejection_Status
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Callback_Present  : Boolean;
      Outstanding_Count : Natural)
      return A11y.Results.Status_Code is
     (A11y.Dispatchers.Classification.Before_Callback_Rejection_Status
        (Stopping,
         Token_Cancelled,
         Kind,
         Callback_Present,
         Outstanding_Count))
   with SPARK_Mode => On;

   function Counts_Reentrant_Rejection
     (Outstanding_Count : Natural)
      return Boolean is
     (A11y.Dispatchers.Classification.Counts_Reentrant_Rejection
        (Outstanding_Count))
   with SPARK_Mode => On;

   function Rejects_On_Dispatch_Thread
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Outstanding_Count : Natural)
      return Boolean is
     (A11y.Dispatchers.Classification.Rejects_On_Dispatch_Thread
        (Stopping, Token_Cancelled, Kind, Outstanding_Count))
   with SPARK_Mode => On;

   function Dispatch_Thread_Rejection_Status
     (Stopping          : Boolean;
      Token_Cancelled   : Boolean;
      Kind              : Call_Kind;
      Outstanding_Count : Natural)
      return A11y.Results.Status_Code is
     (A11y.Dispatchers.Classification.Dispatch_Thread_Rejection_Status
        (Stopping, Token_Cancelled, Kind, Outstanding_Count))
   with SPARK_Mode => On;

   function Create_Cancellation_Token return Cancellation_Token is
     ((State => Not_Cancelled))
   with SPARK_Mode => On;

   procedure Cancel (Token : in out Cancellation_Token) is
   begin
      Token.State := Cancelled;
   end Cancel;

   function Is_Cancelled (Token : Cancellation_Token) return Boolean is
     (Token.State = Cancelled)
   with SPARK_Mode => On;

   procedure Invoke
     (Self     : in out Immediate_Dispatcher;
      Kind     : Call_Kind;
      Callback : Callback_Access;
      Result   : out A11y.Results.Result)
   is
      Token : constant Cancellation_Token := Create_Cancellation_Token;
   begin
      Invoke (Self, Kind, Token, Callback, Result);
   end Invoke;

   procedure Invoke
     (Self     : in out Immediate_Dispatcher;
      Kind     : Call_Kind;
      Token    : Cancellation_Token;
      Callback : Callback_Access;
      Result   : out A11y.Results.Result)
   is
   begin
      if Rejects_Before_Callback
        (Self.Stopping,
         Is_Cancelled (Token),
         Kind,
         Callback /= null,
         Self.Outstanding)
      then
         if Counts_Reentrant_Rejection
           (Self.Outstanding)
         then
            Self.Reentrant := Self.Reentrant + 1;
         end if;
         Self.Rejected (Kind) := Self.Rejected (Kind) + 1;
         Result :=
           (Status =>
              Before_Callback_Rejection_Status
                  (Self.Stopping,
                   Is_Cancelled (Token),
                   Kind,
                   Callback /= null,
                   Self.Outstanding));
         return;
      end if;

      Self.Outstanding := Self.Outstanding + 1;
      Self.Invoked (Kind) := Self.Invoked (Kind) + 1;
      begin
         Callback.all (Result);
      exception
         when others =>
            Self.Failures := Self.Failures + 1;
            Self.Failed (Kind) := Self.Failed (Kind) + 1;
            Result := (Status => A11y.Results.Internal_Error);
      end;
      Self.Outstanding := Self.Outstanding - 1;
   end Invoke;

   procedure Begin_Shutdown (Self : in out Immediate_Dispatcher) is
   begin
      Self.Stopping := True;
   end Begin_Shutdown;

   procedure Invoke_Callback
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Result : out A11y.Results.Result)
   is
      Token : constant Cancellation_Token := Create_Cancellation_Token;
      procedure Invoke_With_Token is new Invoke_Callback_With_Token (Callback);
   begin
      Invoke_With_Token (Self, Kind, Token, Result);
   end Invoke_Callback;

   procedure Invoke_Callback_With_Token
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Token  : Cancellation_Token;
      Result : out A11y.Results.Result)
   is
   begin
      if Rejects_Before_Callback
        (Self.Stopping,
         Is_Cancelled (Token),
         Kind,
         True,
         Self.Outstanding)
      then
         if Counts_Reentrant_Rejection
           (Self.Outstanding)
         then
            Self.Reentrant := Self.Reentrant + 1;
         end if;
         Self.Rejected (Kind) := Self.Rejected (Kind) + 1;
         Result :=
           (Status =>
              Before_Callback_Rejection_Status
                  (Self.Stopping,
                   Is_Cancelled (Token),
                   Kind,
                   True,
                   Self.Outstanding));
         return;
      end if;

      Self.Outstanding := Self.Outstanding + 1;
      Self.Invoked (Kind) := Self.Invoked (Kind) + 1;
      begin
         Callback (Result);
      exception
         when others =>
            Self.Failures := Self.Failures + 1;
            Self.Failed (Kind) := Self.Failed (Kind) + 1;
            Result := (Status => A11y.Results.Internal_Error);
      end;
      Self.Outstanding := Self.Outstanding - 1;
   end Invoke_Callback_With_Token;

   procedure Invoke_Callback_On_Dispatch_Thread
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Result : out A11y.Results.Result)
   is
   begin
      if Rejects_On_Dispatch_Thread
        (Self.Stopping, False, Kind, Self.Outstanding)
      then
         Self.Rejected (Kind) := Self.Rejected (Kind) + 1;
         Result :=
           (Status =>
              Dispatch_Thread_Rejection_Status
                (Self.Stopping, False, Kind, Self.Outstanding));
         return;
      end if;

      Self.Invoked (Kind) := Self.Invoked (Kind) + 1;
      begin
         Callback (Result);
      exception
         when others =>
            Self.Failures := Self.Failures + 1;
            Self.Failed (Kind) := Self.Failed (Kind) + 1;
            Result := (Status => A11y.Results.Internal_Error);
      end;
   end Invoke_Callback_On_Dispatch_Thread;

   procedure Invoke_Callback_On_Dispatch_Thread_With_Token
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Token  : Cancellation_Token;
      Result : out A11y.Results.Result)
   is
   begin
      if Rejects_On_Dispatch_Thread
        (Self.Stopping, Is_Cancelled (Token), Kind, Self.Outstanding)
      then
         Self.Rejected (Kind) := Self.Rejected (Kind) + 1;
         Result :=
           (Status =>
              Dispatch_Thread_Rejection_Status
                (Self.Stopping,
                 Is_Cancelled (Token),
                 Kind,
                 Self.Outstanding));
         return;
      end if;

      Self.Invoked (Kind) := Self.Invoked (Kind) + 1;
      begin
         Callback (Result);
      exception
         when others =>
            Self.Failures := Self.Failures + 1;
            Self.Failed (Kind) := Self.Failed (Kind) + 1;
            Result := (Status => A11y.Results.Internal_Error);
      end;
   end Invoke_Callback_On_Dispatch_Thread_With_Token;

   function Outstanding_Callbacks (Self : Immediate_Dispatcher) return Natural is
     (Self.Outstanding);

   function Already_On_Dispatch_Thread
     (Self : Immediate_Dispatcher)
      return Boolean is
     (Self.Outstanding > 0);

   function Is_Shutting_Down (Self : Immediate_Dispatcher) return Boolean is
     (Self.Stopping);

   function Reentrant_Rejections (Self : Immediate_Dispatcher) return Natural is
     (Self.Reentrant);

   function Callback_Failures (Self : Immediate_Dispatcher) return Natural is
     (Self.Failures);

   function Invocation_Count
     (Self : Immediate_Dispatcher;
      Kind : Call_Kind)
      return Natural is
     (Self.Invoked (Kind));

   function Rejection_Count
     (Self : Immediate_Dispatcher;
      Kind : Call_Kind)
      return Natural is
     (Self.Rejected (Kind));

   function Failure_Count
     (Self : Immediate_Dispatcher;
      Kind : Call_Kind)
      return Natural is
     (Self.Failed (Kind));

end A11y.Dispatchers;
