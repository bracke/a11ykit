with A11y.Native_Action_Calls;
with A11y.Native_Boundary_Calls;
with A11y.States;

package body A11y.Native_Focus_Calls is
   use type A11y.Results.Status_Code;

   procedure Query_Object_Focused
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Focus_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Focus_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot := A11y.Nodes.Contract_Snapshot_Safely
           (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Focused := False;
            Query_Result.Status := Snapshot_Result.Status;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         Query_Result.Focused :=
           A11y.States.Derive
             (Snapshot.States,
              Snapshot.Role,
              Snapshot.Capabilities) (A11y.States.Focused);
         Query_Result.Status := A11y.Results.Success;
         Callback_Result := A11y.Results.Ok;
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result := (others => <>);
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate,
         Runtime,
         Object,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Simple_Property_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status  => Begin_Result.Status,
                    Node    => A11y.Node_Ids.No_Node,
                    Focused => False);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Simple_Property_Query,
         Token,
         Dispatch_Result);
      if A11y.Native_Boundary_Calls.Dispatch_Status_Overrides_Query (Dispatch_Result.Status)
      then
         Query_Result.Status := Dispatch_Result.Status;
      end if;

      A11y.Native_Boundary_Calls.Complete_Call
        (Gate, Context, Query_Result.Status, End_Result);
      Result := Query_Result;
   exception
      when others =>
         if A11y.Native_Boundary_Calls.Snapshot (Context).Active then
            A11y.Native_Boundary_Calls.End_Call
              (Gate, Context, End_Result);
         end if;
         Result := (Status  => A11y.Results.Internal_Error,
                    Node    => A11y.Node_Ids.No_Node,
                    Focused => False);
   end Query_Object_Focused;

   procedure Query_Node_Focused
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Focus_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Focus_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot := A11y.Nodes.Contract_Snapshot_Safely
           (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Focused := False;
            Query_Result.Status := Snapshot_Result.Status;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         Query_Result.Focused :=
           A11y.States.Derive
             (Snapshot.States,
              Snapshot.Role,
              Snapshot.Capabilities) (A11y.States.Focused);
         Query_Result.Status := A11y.Results.Success;
         Callback_Result := A11y.Results.Ok;
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result := (others => <>);
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate,
         Runtime,
         Node,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Simple_Property_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status  => Begin_Result.Status,
                    Node    => A11y.Node_Ids.No_Node,
                    Focused => False);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Simple_Property_Query,
         Token,
         Dispatch_Result);
      if A11y.Native_Boundary_Calls.Dispatch_Status_Overrides_Query (Dispatch_Result.Status)
      then
         Query_Result.Status := Dispatch_Result.Status;
      end if;

      A11y.Native_Boundary_Calls.Complete_Call
        (Gate, Context, Query_Result.Status, End_Result);
      Result := Query_Result;
   exception
      when others =>
         if A11y.Native_Boundary_Calls.Snapshot (Context).Active then
            A11y.Native_Boundary_Calls.End_Call
              (Gate, Context, End_Result);
         end if;
         Result := (Status  => A11y.Results.Internal_Error,
                    Node    => A11y.Node_Ids.No_Node,
                    Focused => False);
   end Query_Node_Focused;

   procedure Request_Object_Focus
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
   begin
      A11y.Native_Action_Calls.Invoke_Object_Action
        (Gate,
         Runtime,
         Dispatcher,
         Object,
         Provider,
         A11y.Actions.Set_Focus,
         Result,
         Token => Token);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Request_Object_Focus;

   procedure Request_Node_Focus
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : in out A11y.Actions.Action_Provider'Class;
      Result     : out A11y.Actions.Action_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
   begin
      A11y.Native_Action_Calls.Invoke_Node_Action
        (Gate,
         Runtime,
         Dispatcher,
         Node,
         Provider,
         A11y.Actions.Set_Focus,
         Result,
         Token => Token);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Request_Node_Focus;

end A11y.Native_Focus_Calls;
