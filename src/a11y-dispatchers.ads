with A11y.Results;
with A11y.Resource_Limits;

package A11y.Dispatchers is

   type Call_Kind is
     (Simple_Property_Query,
      Tree_Navigation_Query,
      Geometry_Query,
      Text_Query,
      Action_Invocation,
      Window_Operation,
      Shutdown);

   type Call_Kind_Metadata is record
      Stable_Name   : access constant String;
      Timeout_Limit : A11y.Resource_Limits.Limit_Kind :=
        A11y.Resource_Limits.Callback_Duration_MS;
      Cancellable   : Boolean := True;
   end record;

   type Cancellation_State is (Not_Cancelled, Cancelled);

   type Cancellation_Token is private;

   type Callback_Access is access procedure
     (Result : out A11y.Results.Result);

   function Metadata (Kind : Call_Kind) return Call_Kind_Metadata;
   function Stable_Name (Kind : Call_Kind) return String;

   function Timeout_Limit_For
     (Kind : Call_Kind)
      return A11y.Resource_Limits.Limit_Kind
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        A11y.Resource_Limits."="
          (Timeout_Limit_For'Result,
           (case Kind is
              when Shutdown =>
                A11y.Resource_Limits.Shutdown_Duration_MS,
              when others =>
                A11y.Resource_Limits.Callback_Duration_MS));

   function Is_Cancellable_Kind (Kind : Call_Kind) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Cancellable_Kind'Result = (Kind /= Shutdown);

   function Timeout_Limit
     (Kind : Call_Kind)
      return A11y.Resource_Limits.Limit_Kind
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        A11y.Resource_Limits."="
          (Timeout_Limit'Result, Timeout_Limit_For (Kind));
   function Is_Cancellable (Kind : Call_Kind) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Cancellable'Result = Is_Cancellable_Kind (Kind);
   function Has_Timed_Out
     (Config     : A11y.Resource_Limits.Resource_Limit_Config;
      Kind       : Call_Kind;
      Elapsed_MS : Natural)
      return Boolean
   with
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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

   function Create_Cancellation_Token return Cancellation_Token
   with
      SPARK_Mode => On,
      Global => null,
      Post => not Is_Cancelled (Create_Cancellation_Token'Result);
   procedure Cancel (Token : in out Cancellation_Token);
   function Is_Cancelled (Token : Cancellation_Token) return Boolean
   with
      SPARK_Mode => On,
      Global => null;

   type Immediate_Dispatcher is limited private;

   procedure Invoke
     (Self     : in out Immediate_Dispatcher;
      Kind     : Call_Kind;
      Callback : Callback_Access;
      Result   : out A11y.Results.Result);

   procedure Invoke
     (Self     : in out Immediate_Dispatcher;
      Kind     : Call_Kind;
      Token    : Cancellation_Token;
      Callback : Callback_Access;
      Result   : out A11y.Results.Result);

   generic
      with procedure Callback (Result : out A11y.Results.Result);
   procedure Invoke_Callback
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Result : out A11y.Results.Result);

   generic
      with procedure Callback (Result : out A11y.Results.Result);
   procedure Invoke_Callback_With_Token
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Token  : Cancellation_Token;
      Result : out A11y.Results.Result);

   generic
      with procedure Callback (Result : out A11y.Results.Result);
   procedure Invoke_Callback_On_Dispatch_Thread
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Result : out A11y.Results.Result);

   generic
      with procedure Callback (Result : out A11y.Results.Result);
   procedure Invoke_Callback_On_Dispatch_Thread_With_Token
     (Self   : in out Immediate_Dispatcher;
      Kind   : Call_Kind;
      Token  : Cancellation_Token;
      Result : out A11y.Results.Result);

   procedure Begin_Shutdown (Self : in out Immediate_Dispatcher);

   function Outstanding_Callbacks (Self : Immediate_Dispatcher) return Natural;
   function Already_On_Dispatch_Thread
     (Self : Immediate_Dispatcher)
      return Boolean;
   function Is_Shutting_Down (Self : Immediate_Dispatcher) return Boolean;
   function Reentrant_Rejections (Self : Immediate_Dispatcher) return Natural;
   function Callback_Failures (Self : Immediate_Dispatcher) return Natural;
   function Invocation_Count
     (Self : Immediate_Dispatcher;
      Kind : Call_Kind)
      return Natural;
   function Rejection_Count
     (Self : Immediate_Dispatcher;
      Kind : Call_Kind)
      return Natural;
   function Failure_Count
     (Self : Immediate_Dispatcher;
      Kind : Call_Kind)
      return Natural;

private
   type Cancellation_Token is record
      State : Cancellation_State := Not_Cancelled;
   end record;

   type Call_Counters is array (Call_Kind) of Natural;

   type Immediate_Dispatcher is limited record
      Outstanding : Natural := 0;
      Stopping    : Boolean := False;
      Reentrant   : Natural := 0;
      Failures    : Natural := 0;
      Invoked     : Call_Counters := [others => 0];
      Rejected    : Call_Counters := [others => 0];
      Failed      : Call_Counters := [others => 0];
   end record;
end A11y.Dispatchers;
