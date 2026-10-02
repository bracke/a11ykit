with A11y.Native_Boundary_Calls;
with A11y.Results;

package body A11y.Native_Action_Calls is
   use type A11y.Results.Status_Code;

   procedure Invoke_Object_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      Call_View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Final_Status : A11y.Results.Status_Code;
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Action_Result : A11y.Actions.Action_Result :=
        (Status => A11y.Results.Internal_Error);

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Action_Result :=
           A11y.Actions.Invoke_Safely (Provider, Node, Action);
         Callback_Result := A11y.Actions.To_Result (Action_Result);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate,
         Runtime,
         Object,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Action_Invocation);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status);
         return;
      end if;

      Call_View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Node := Call_View.Node;

      Dispatch_Callback
         (Dispatcher,
         A11y.Dispatchers.Action_Invocation,
         Token,
         Dispatch_Result);
      if A11y.Native_Boundary_Calls.Dispatch_Status_Overrides_Action (Dispatch_Result.Status)
      then
         Action_Result := (Status => Dispatch_Result.Status);
      end if;

      Final_Status := A11y.Actions.To_Result (Action_Result).Status;
      A11y.Native_Boundary_Calls.Complete_Call
        (Gate, Context, Final_Status, End_Result);
      if A11y.Native_Boundary_Calls.Final_Status_Overrides_Action
             (Final_Status, A11y.Actions.To_Result (Action_Result).Status)
      then
         Result := (Status => Final_Status);
      else
         Result := Action_Result;
      end if;
   exception
      when others =>
         if A11y.Native_Boundary_Calls.Snapshot (Context).Active then
            A11y.Native_Boundary_Calls.End_Call
              (Gate, Context, End_Result);
         end if;
         Result := (Status => A11y.Results.Internal_Error);
   end Invoke_Object_Action;

   procedure Invoke_Object_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      States     : A11y.States.State_Set;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      Call_View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Final_Status : A11y.Results.Status_Code;
      Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Action_Result : A11y.Actions.Action_Result :=
        (Status => A11y.Results.Internal_Error);

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Action_Result :=
           A11y.Actions.Invoke_Safely (Provider, Node, Action, States);
         Callback_Result := A11y.Actions.To_Result (Action_Result);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate,
         Runtime,
         Object,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Action_Invocation);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status);
         return;
      end if;

      Call_View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Node := Call_View.Node;

      Dispatch_Callback
         (Dispatcher,
         A11y.Dispatchers.Action_Invocation,
         Token,
         Dispatch_Result);
      if A11y.Native_Boundary_Calls.Dispatch_Status_Overrides_Action (Dispatch_Result.Status)
      then
         Action_Result := (Status => Dispatch_Result.Status);
      end if;

      Final_Status := A11y.Actions.To_Result (Action_Result).Status;
      A11y.Native_Boundary_Calls.Complete_Call
        (Gate, Context, Final_Status, End_Result);
      if A11y.Native_Boundary_Calls.Final_Status_Overrides_Action
             (Final_Status, A11y.Actions.To_Result (Action_Result).Status)
      then
         Result := (Status => Final_Status);
      else
         Result := Action_Result;
      end if;
   exception
      when others =>
         if A11y.Native_Boundary_Calls.Snapshot (Context).Active then
            A11y.Native_Boundary_Calls.End_Call
              (Gate, Context, End_Result);
         end if;
         Result := (Status => A11y.Results.Internal_Error);
   end Invoke_Object_Action;

   procedure Invoke_Node_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      Call_View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Final_Status : A11y.Results.Status_Code;
      Resolved_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Action_Result : A11y.Actions.Action_Result :=
        (Status => A11y.Results.Internal_Error);

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Action_Result :=
           A11y.Actions.Invoke_Safely (Provider, Resolved_Node, Action);
         Callback_Result := A11y.Actions.To_Result (Action_Result);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate,
         Runtime,
         Node,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Action_Invocation);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status);
         return;
      end if;

      Call_View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Resolved_Node := Call_View.Node;

      Dispatch_Callback
         (Dispatcher,
         A11y.Dispatchers.Action_Invocation,
         Token,
         Dispatch_Result);
      if A11y.Native_Boundary_Calls.Dispatch_Status_Overrides_Action (Dispatch_Result.Status)
      then
         Action_Result := (Status => Dispatch_Result.Status);
      end if;

      Final_Status := A11y.Actions.To_Result (Action_Result).Status;
      A11y.Native_Boundary_Calls.Complete_Call
        (Gate, Context, Final_Status, End_Result);
      if A11y.Native_Boundary_Calls.Final_Status_Overrides_Action
             (Final_Status, A11y.Actions.To_Result (Action_Result).Status)
      then
         Result := (Status => Final_Status);
      else
         Result := Action_Result;
      end if;
   exception
      when others =>
         if A11y.Native_Boundary_Calls.Snapshot (Context).Active then
            A11y.Native_Boundary_Calls.End_Call
              (Gate, Context, End_Result);
         end if;
         Result := (Status => A11y.Results.Internal_Error);
   end Invoke_Node_Action;

   procedure Invoke_Node_Action
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Action     : A11y.Actions.Action_Id;
      States     : A11y.States.State_Set;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      Call_View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Final_Status : A11y.Results.Status_Code;
      Resolved_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Action_Result : A11y.Actions.Action_Result :=
        (Status => A11y.Results.Internal_Error);

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Action_Result :=
           A11y.Actions.Invoke_Safely
             (Provider, Resolved_Node, Action, States);
         Callback_Result := A11y.Actions.To_Result (Action_Result);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate,
         Runtime,
         Node,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Action_Invocation);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status);
         return;
      end if;

      Call_View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Resolved_Node := Call_View.Node;

      Dispatch_Callback
         (Dispatcher,
         A11y.Dispatchers.Action_Invocation,
         Token,
         Dispatch_Result);
      if A11y.Native_Boundary_Calls.Dispatch_Status_Overrides_Action (Dispatch_Result.Status)
      then
         Action_Result := (Status => Dispatch_Result.Status);
      end if;

      Final_Status := A11y.Actions.To_Result (Action_Result).Status;
      A11y.Native_Boundary_Calls.Complete_Call
        (Gate, Context, Final_Status, End_Result);
      if A11y.Native_Boundary_Calls.Final_Status_Overrides_Action
             (Final_Status, A11y.Actions.To_Result (Action_Result).Status)
      then
         Result := (Status => Final_Status);
      else
         Result := Action_Result;
      end if;
   exception
      when others =>
         if A11y.Native_Boundary_Calls.Snapshot (Context).Active then
            A11y.Native_Boundary_Calls.End_Call
              (Gate, Context, End_Result);
         end if;
         Result := (Status => A11y.Results.Internal_Error);
   end Invoke_Node_Action;

end A11y.Native_Action_Calls;
