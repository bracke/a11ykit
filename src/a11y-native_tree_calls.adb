with A11y.Native_Boundary_Calls;

package body A11y.Native_Tree_Calls is
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   function Live_Target
     (Runtime : A11y.Native_Runtimes.Native_Runtime;
      Target  : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Node_Ids.Is_Valid (Target)
      and then not A11y.Native_Runtimes.Node_Defunct (Runtime, Target));

   procedure Query_Object_Parent
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Node_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Node_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Tree_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Snapshot := A11y.Nodes.Tree_Snapshot_Safely
           (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := Snapshot_Result.Status;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         if Snapshot.Parent /= A11y.Node_Ids.No_Node
           and then not Live_Target (Runtime, Snapshot.Parent)
         then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := A11y.Results.Node_Unavailable;
            Callback_Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Query_Result.Target := Snapshot.Parent;
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
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Tree_Navigation_Query,
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
         Result := (Status => A11y.Results.Internal_Error,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
   end Query_Object_Parent;

   procedure Query_Node_Parent
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Node_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Node_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Tree_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Snapshot := A11y.Nodes.Tree_Snapshot_Safely
           (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := Snapshot_Result.Status;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         if Snapshot.Parent /= A11y.Node_Ids.No_Node
           and then not Live_Target (Runtime, Snapshot.Parent)
         then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := A11y.Results.Node_Unavailable;
            Callback_Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Query_Result.Target := Snapshot.Parent;
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
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Tree_Navigation_Query,
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
         Result := (Status => A11y.Results.Internal_Error,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
   end Query_Node_Parent;

   procedure Query_Object_Child_Count
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Count_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Count_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Tree_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Snapshot := A11y.Nodes.Tree_Snapshot_Safely
           (Provider, Snapshot_Result);
         Query_Result.Count := Snapshot.Child_Count;
         Query_Result.Status := Snapshot_Result.Status;
         Callback_Result := Snapshot_Result;
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
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Count  => 0);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Tree_Navigation_Query,
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
         Result := (Status => A11y.Results.Internal_Error,
                    Source => A11y.Node_Ids.No_Node,
                    Count  => 0);
   end Query_Object_Child_Count;

   procedure Query_Node_Child_Count
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Count_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Count_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Tree_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Snapshot := A11y.Nodes.Tree_Snapshot_Safely
           (Provider, Snapshot_Result);
         Query_Result.Count := Snapshot.Child_Count;
         Query_Result.Status := Snapshot_Result.Status;
         Callback_Result := Snapshot_Result;
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
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Count  => 0);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Tree_Navigation_Query,
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
         Result := (Status => A11y.Results.Internal_Error,
                    Source => A11y.Node_Ids.No_Node,
                    Count  => 0);
   end Query_Node_Child_Count;

   procedure Query_Object_Child_At
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Index      : Positive;
      Result     : out Native_Node_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Node_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Child : A11y.Node_Ids.Node_Id;
         Child_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Child := A11y.Nodes.Child_At_Safely
           (Provider, Index, Child_Result);
         if A11y.Results.Failed (Child_Result) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := Child_Result.Status;
            Callback_Result := Child_Result;
            return;
         end if;

         if not Live_Target (Runtime, Child) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := A11y.Results.Node_Unavailable;
            Callback_Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Query_Result.Target := Child;
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
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Tree_Navigation_Query,
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
         Result := (Status => A11y.Results.Internal_Error,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
   end Query_Object_Child_At;

   procedure Query_Node_Child_At
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Index      : Positive;
      Result     : out Native_Node_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Node_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Child : A11y.Node_Ids.Node_Id;
         Child_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Child := A11y.Nodes.Child_At_Safely
           (Provider, Index, Child_Result);
         if A11y.Results.Failed (Child_Result) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := Child_Result.Status;
            Callback_Result := Child_Result;
            return;
         end if;

         if not Live_Target (Runtime, Child) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := A11y.Results.Node_Unavailable;
            Callback_Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Query_Result.Target := Child;
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
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Tree_Navigation_Query,
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
         Result := (Status => A11y.Results.Internal_Error,
                    Source => A11y.Node_Ids.No_Node,
                    Target => A11y.Node_Ids.No_Node);
   end Query_Node_Child_At;

end A11y.Native_Tree_Calls;
