with A11y.Dispatchers;
with A11y.Dispatchers.Classification;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Dispatcher_Tests is
   use type A11y.Resource_Limits.Limit_Kind;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Dispatcher : A11y.Dispatchers.Immediate_Dispatcher;
      Timeout_Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Result : A11y.Results.Result;
      Nested_Result : A11y.Results.Result;
      Inline_Result : A11y.Results.Result;
      Inline_Cancelled_Result : A11y.Results.Result;
      Saw_Dispatch_Thread : Boolean := False;
      Cancellation : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Inline_Cancellation : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;

      procedure Successful_Callback (Result : out A11y.Results.Result) is
      begin
         Result := A11y.Results.Ok;
      end Successful_Callback;

      procedure Failing_Callback (Result : out A11y.Results.Result) is
         pragma Unreferenced (Result);
      begin
         raise Program_Error;
      end Failing_Callback;

      procedure Nested_Callback (Result : out A11y.Results.Result) is
      begin
         Result := A11y.Results.Ok;
      end Nested_Callback;

      procedure Invoke_Nested is new A11y.Dispatchers.Invoke_Callback
        (Nested_Callback);
      procedure Invoke_Nested_On_Dispatch_Thread is new
        A11y.Dispatchers.Invoke_Callback_On_Dispatch_Thread
          (Nested_Callback);
      procedure Invoke_Nested_On_Dispatch_Thread_With_Token is new
        A11y.Dispatchers.Invoke_Callback_On_Dispatch_Thread_With_Token
          (Nested_Callback);

      procedure Reentrant_Callback (Result : out A11y.Results.Result) is
      begin
         Invoke_Nested
           (Dispatcher,
            A11y.Dispatchers.Simple_Property_Query,
            Nested_Result);
         Result := A11y.Results.Ok;
      end Reentrant_Callback;

      procedure Inline_Dispatch_Callback (Result : out A11y.Results.Result) is
      begin
         Saw_Dispatch_Thread :=
           A11y.Dispatchers.Already_On_Dispatch_Thread (Dispatcher);
         Invoke_Nested_On_Dispatch_Thread
           (Dispatcher,
            A11y.Dispatchers.Geometry_Query,
            Inline_Result);
         Invoke_Nested_On_Dispatch_Thread_With_Token
           (Dispatcher,
            A11y.Dispatchers.Action_Invocation,
            Inline_Cancellation,
            Inline_Cancelled_Result);
         Result := Inline_Result;
      end Inline_Dispatch_Callback;

      procedure Invoke_Successful is new A11y.Dispatchers.Invoke_Callback
        (Successful_Callback);
      procedure Invoke_Successful_With_Token is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Successful_Callback);
      procedure Invoke_Failing is new A11y.Dispatchers.Invoke_Callback
        (Failing_Callback);
      procedure Invoke_Reentrant is new A11y.Dispatchers.Invoke_Callback
        (Reentrant_Callback);
      procedure Invoke_Inline_Dispatch is new A11y.Dispatchers.Invoke_Callback
        (Inline_Dispatch_Callback);
   begin
      Check
        (A11y.Dispatchers.Stable_Name
           (A11y.Dispatchers.Tree_Navigation_Query)
         = "tree-navigation-query"
         and then A11y.Dispatchers.Timeout_Limit
           (A11y.Dispatchers.Action_Invocation)
           = A11y.Resource_Limits.Callback_Duration_MS
         and then A11y.Dispatchers.Classification.Timeout_Limit_For
           (A11y.Dispatchers.Action_Invocation)
           = A11y.Resource_Limits.Callback_Duration_MS
         and then A11y.Dispatchers.Timeout_Limit
           (A11y.Dispatchers.Shutdown)
           = A11y.Resource_Limits.Shutdown_Duration_MS
         and then A11y.Dispatchers.Classification.Timeout_Limit_For
           (A11y.Dispatchers.Shutdown)
           = A11y.Resource_Limits.Shutdown_Duration_MS
         and then A11y.Dispatchers.Is_Cancellable
           (A11y.Dispatchers.Action_Invocation)
         and then A11y.Dispatchers.Classification.Is_Cancellable_Kind
           (A11y.Dispatchers.Action_Invocation)
         and then not A11y.Dispatchers.Is_Cancellable
           (A11y.Dispatchers.Shutdown)
         and then not A11y.Dispatchers.Classification.Is_Cancellable_Kind
           (A11y.Dispatchers.Shutdown),
         "dispatcher exposes stable call-kind timeout metadata");

      A11y.Resource_Limits.Set_Limit
        (Timeout_Limits,
         A11y.Resource_Limits.Callback_Duration_MS,
         7,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Dispatchers.Has_Timed_Out
           (Timeout_Limits,
            A11y.Dispatchers.Action_Invocation,
            6)
         and then A11y.Dispatchers.Has_Timed_Out
           (Timeout_Limits,
            A11y.Dispatchers.Action_Invocation,
            7)
         and then A11y.Dispatchers.Has_Timed_Out
           (Timeout_Limits,
            A11y.Dispatchers.Action_Invocation,
            8)
         and then A11y.Dispatchers.Classification.Has_Timed_Out
           (Timeout_Limits,
            A11y.Dispatchers.Action_Invocation,
            8)
         and then not A11y.Dispatchers.Has_Timed_Out
           (Timeout_Limits,
            A11y.Dispatchers.Shutdown,
            7)
         and then not A11y.Dispatchers.Classification.Has_Timed_Out
           (Timeout_Limits,
            A11y.Dispatchers.Shutdown,
            7),
         "dispatcher classifies elapsed callbacks against per-kind timeouts");

      Check
        (A11y.Dispatchers.Classification.Rejects_Before_Callback
           (Stopping          => True,
            Token_Cancelled   => False,
            Kind              => A11y.Dispatchers.Simple_Property_Query,
            Callback_Present  => True,
            Outstanding_Count => 0)
         and then A11y.Dispatchers.Classification.Rejects_Before_Callback
           (Stopping          => False,
            Token_Cancelled   => True,
            Kind              => A11y.Dispatchers.Text_Query,
            Callback_Present  => True,
            Outstanding_Count => 0)
         and then not A11y.Dispatchers.Classification.Rejects_Before_Callback
           (Stopping          => False,
            Token_Cancelled   => True,
            Kind              => A11y.Dispatchers.Shutdown,
            Callback_Present  => True,
            Outstanding_Count => 0)
         and then A11y.Dispatchers.Classification.Rejects_Before_Callback
           (Stopping          => False,
            Token_Cancelled   => False,
            Kind              => A11y.Dispatchers.Text_Query,
            Callback_Present  => False,
            Outstanding_Count => 0)
         and then A11y.Dispatchers.Classification.Rejects_Before_Callback
           (Stopping          => False,
            Token_Cancelled   => False,
            Kind              => A11y.Dispatchers.Text_Query,
            Callback_Present  => True,
            Outstanding_Count => 1),
         "dispatcher classification exposes pre-callback rejection policy");

      Check
        (A11y.Dispatchers.Classification.Rejects_On_Dispatch_Thread
           (Stopping          => False,
            Token_Cancelled   => False,
            Kind              => A11y.Dispatchers.Geometry_Query,
            Outstanding_Count => 0)
         and then A11y.Dispatchers.Classification.Rejects_On_Dispatch_Thread
           (Stopping          => False,
            Token_Cancelled   => True,
            Kind              => A11y.Dispatchers.Geometry_Query,
            Outstanding_Count => 1)
         and then not A11y.Dispatchers.Classification.Rejects_On_Dispatch_Thread
           (Stopping          => False,
            Token_Cancelled   => True,
            Kind              => A11y.Dispatchers.Shutdown,
            Outstanding_Count => 1),
         "dispatcher classification exposes dispatch-thread rejection policy");

      Invoke_Successful
        (Dispatcher, A11y.Dispatchers.Simple_Property_Query, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Dispatchers.Outstanding_Callbacks (Dispatcher) = 0
         and then A11y.Dispatchers.Invocation_Count
           (Dispatcher, A11y.Dispatchers.Simple_Property_Query) = 1,
         "dispatcher runs a successful callback and clears outstanding state");

      Invoke_Reentrant
        (Dispatcher, A11y.Dispatchers.Tree_Navigation_Query, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Nested_Result.Status = A11y.Results.Busy
         and then A11y.Dispatchers.Reentrant_Rejections (Dispatcher) = 1
         and then A11y.Dispatchers.Invocation_Count
           (Dispatcher, A11y.Dispatchers.Tree_Navigation_Query) = 1
         and then A11y.Dispatchers.Rejection_Count
           (Dispatcher, A11y.Dispatchers.Simple_Property_Query) = 1,
         "dispatcher rejects reentrant provider callbacks");

      Check
        (not A11y.Dispatchers.Already_On_Dispatch_Thread (Dispatcher),
         "dispatcher reports idle dispatch-thread state outside callbacks");
      Invoke_Nested_On_Dispatch_Thread
        (Dispatcher, A11y.Dispatchers.Geometry_Query, Inline_Result);
      Check
        (Inline_Result.Status = A11y.Results.Invalid_State
         and then A11y.Dispatchers.Rejection_Count
           (Dispatcher, A11y.Dispatchers.Geometry_Query) = 1,
         "dispatcher rejects dispatch-thread fast path outside callbacks");

      A11y.Dispatchers.Cancel (Inline_Cancellation);
      Invoke_Inline_Dispatch
        (Dispatcher, A11y.Dispatchers.Tree_Navigation_Query, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Results.Succeeded (Inline_Result)
         and then Inline_Cancelled_Result.Status = A11y.Results.Cancelled
         and then Saw_Dispatch_Thread
         and then not A11y.Dispatchers.Already_On_Dispatch_Thread (Dispatcher)
         and then A11y.Dispatchers.Outstanding_Callbacks (Dispatcher) = 0
         and then A11y.Dispatchers.Invocation_Count
           (Dispatcher, A11y.Dispatchers.Geometry_Query) = 1
         and then A11y.Dispatchers.Rejection_Count
           (Dispatcher, A11y.Dispatchers.Action_Invocation) = 1
         and then A11y.Dispatchers.Reentrant_Rejections (Dispatcher) = 1,
         "dispatcher supports explicit already-on-dispatch-thread fast path");

      Invoke_Failing
        (Dispatcher, A11y.Dispatchers.Action_Invocation, Result);
      Check
        (Result.Status = A11y.Results.Internal_Error
         and then A11y.Dispatchers.Callback_Failures (Dispatcher) = 1
         and then A11y.Dispatchers.Failure_Count
           (Dispatcher, A11y.Dispatchers.Action_Invocation) = 1,
         "dispatcher converts callback exceptions into structured failure");

      A11y.Dispatchers.Invoke
        (Dispatcher,
         A11y.Dispatchers.Window_Operation,
         null,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Dispatchers.Rejection_Count
           (Dispatcher, A11y.Dispatchers.Window_Operation) = 1,
         "dispatcher accounts invalid callback arguments per call kind");

      A11y.Dispatchers.Cancel (Cancellation);
      Check
        (A11y.Dispatchers.Is_Cancelled (Cancellation),
         "dispatcher cancellation tokens record cancellation state");
      Invoke_Successful_With_Token
        (Dispatcher,
         A11y.Dispatchers.Text_Query,
         Cancellation,
         Result);
      Check
        (Result.Status = A11y.Results.Cancelled
         and then A11y.Dispatchers.Invocation_Count
           (Dispatcher, A11y.Dispatchers.Text_Query) = 0
         and then A11y.Dispatchers.Rejection_Count
           (Dispatcher, A11y.Dispatchers.Text_Query) = 1,
         "dispatcher rejects cancelled provider callbacks before invocation");

      A11y.Dispatchers.Begin_Shutdown (Dispatcher);
      Invoke_Successful
        (Dispatcher, A11y.Dispatchers.Simple_Property_Query, Result);
      Check
        (Result.Status = A11y.Results.Shutting_Down
         and then A11y.Dispatchers.Is_Shutting_Down (Dispatcher)
         and then A11y.Dispatchers.Rejection_Count
           (Dispatcher, A11y.Dispatchers.Simple_Property_Query) = 2,
         "dispatcher rejects new callbacks during shutdown");
   end Run;
end A11y_Dispatcher_Tests;
