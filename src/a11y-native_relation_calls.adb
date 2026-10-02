with A11y.Native_Boundary_Calls;

package body A11y.Native_Relation_Calls is
   use type A11y.Results.Status_Code;

   function Target_Available
     (Runtime : A11y.Native_Runtimes.Native_Runtime;
      Target  : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Node_Ids.Is_Valid (Target)
      and then not A11y.Native_Runtimes.Node_Defunct (Runtime, Target));

   procedure Copy_Live_Targets
     (Runtime         : A11y.Native_Runtimes.Native_Runtime;
      All_Targets     : A11y.Relations.Target_Vectors.Vector;
      Limit           : Natural;
      Query_Result    : in out Native_Relation_Targets_Result;
      Callback_Result : out A11y.Results.Result)
   is
      Returned : constant Natural := Natural (All_Targets.Length);
   begin
      if Returned > Limit then
         Query_Result.Targets.Clear;
         Query_Result.Status := A11y.Results.Resource_Limit;
         Query_Result.Truncated := True;
         Callback_Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      for Index in 1 .. Returned loop
         if not Target_Available
           (Runtime, All_Targets.Element (Positive (Index)))
         then
            Query_Result.Targets.Clear;
            Query_Result.Status := A11y.Results.Node_Unavailable;
            Query_Result.Truncated := False;
            Callback_Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;
      end loop;

      for Index in 1 .. Returned loop
         Query_Result.Targets.Append
           (All_Targets.Element (Positive (Index)));
      end loop;

      Query_Result.Status := A11y.Results.Success;
      Query_Result.Truncated := False;
      Callback_Result := A11y.Results.Ok;
   end Copy_Live_Targets;

   procedure Query_Object_Relation_Targets
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Kind       : A11y.Relations.Relation_Kind;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Result     : out Native_Relation_Targets_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Relation_Targets_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         All_Targets : A11y.Relations.Target_Vectors.Vector;
         Limit : constant Natural := Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
      begin
         Query_Result.Source := View.Node;
         All_Targets := A11y.Relations.Targets (Graph, View.Node, Kind);
         Copy_Live_Targets
           (Runtime, All_Targets, Limit, Query_Result, Callback_Result);
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Query_Result.Targets.Clear;
            Query_Result.Truncated := False;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result := (others => <>);

      declare
         Limit_Result : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Limit_Result) then
            Result := (Status    => Limit_Result.Status,
                       Source    => A11y.Node_Ids.No_Node,
                       Targets   => A11y.Relations.Target_Vectors.Empty_Vector,
                       Truncated => False);
            return;
         end if;
      end;

      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate,
         Runtime,
         Object,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status    => Begin_Result.Status,
                    Source    => A11y.Node_Ids.No_Node,
                    Targets   => A11y.Relations.Target_Vectors.Empty_Vector,
                    Truncated => False);
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
         Result := (Status    => A11y.Results.Internal_Error,
                    Source    => A11y.Node_Ids.No_Node,
                    Targets   => A11y.Relations.Target_Vectors.Empty_Vector,
                    Truncated => False);
   end Query_Object_Relation_Targets;

   procedure Query_Node_Relation_Targets
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Kind       : A11y.Relations.Relation_Kind;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config;
      Result     : out Native_Relation_Targets_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Relation_Targets_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         All_Targets : A11y.Relations.Target_Vectors.Vector;
         Limit : constant Natural := Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
      begin
         Query_Result.Source := View.Node;
         All_Targets := A11y.Relations.Targets (Graph, View.Node, Kind);
         Copy_Live_Targets
           (Runtime, All_Targets, Limit, Query_Result, Callback_Result);
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Query_Result.Targets.Clear;
            Query_Result.Truncated := False;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result := (others => <>);

      declare
         Limit_Result : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Limit_Result) then
            Result := (Status    => Limit_Result.Status,
                       Source    => A11y.Node_Ids.No_Node,
                       Targets   => A11y.Relations.Target_Vectors.Empty_Vector,
                       Truncated => False);
            return;
         end if;
      end;

      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate,
         Runtime,
         Node,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status    => Begin_Result.Status,
                    Source    => A11y.Node_Ids.No_Node,
                    Targets   => A11y.Relations.Target_Vectors.Empty_Vector,
                    Truncated => False);
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
         Result := (Status    => A11y.Results.Internal_Error,
                    Source    => A11y.Node_Ids.No_Node,
                    Targets   => A11y.Relations.Target_Vectors.Empty_Vector,
                    Truncated => False);
   end Query_Node_Relation_Targets;

   procedure Query_Object_Active_Descendant
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Result     : out Native_Relation_Target_Result;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Relation_Target_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Targets : A11y.Relations.Target_Vectors.Vector;
         Limit : constant Natural := Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
      begin
         Query_Result.Source := View.Node;
         Targets := A11y.Relations.Targets
           (Graph, View.Node, A11y.Relations.Active_Descendant);
         if Natural (Targets.Length) > Limit then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Has_Target := False;
            Query_Result.Status := A11y.Results.Resource_Limit;
            Callback_Result := (Status => A11y.Results.Resource_Limit);
            return;
         elsif Natural (Targets.Length) > 1 then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Has_Target := False;
            Query_Result.Status := A11y.Results.Invalid_State;
            Callback_Result := (Status => A11y.Results.Invalid_State);
            return;
         elsif not Targets.Is_Empty then
            if not Target_Available (Runtime, Targets.First_Element) then
               Query_Result.Target := A11y.Node_Ids.No_Node;
               Query_Result.Has_Target := False;
               Query_Result.Status := A11y.Results.Node_Unavailable;
               Callback_Result := (Status => A11y.Results.Node_Unavailable);
               return;
            end if;

            Query_Result.Target := Targets.First_Element;
            Query_Result.Has_Target := True;
         end if;
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
      declare
         Limit_Result : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Limit_Result) then
            Result := (Status     => Limit_Result.Status,
                       Source     => A11y.Node_Ids.No_Node,
                       Target     => A11y.Node_Ids.No_Node,
                       Has_Target => False);
            return;
         end if;
      end;

      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate,
         Runtime,
         Object,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status     => Begin_Result.Status,
                    Source     => A11y.Node_Ids.No_Node,
                    Target     => A11y.Node_Ids.No_Node,
                    Has_Target => False);
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
         Result := (Status     => A11y.Results.Internal_Error,
                    Source     => A11y.Node_Ids.No_Node,
                    Target     => A11y.Node_Ids.No_Node,
                    Has_Target => False);
   end Query_Object_Active_Descendant;

   procedure Query_Node_Active_Descendant
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Graph      : A11y.Relations.Relation_Graph;
      Result     : out Native_Relation_Target_Result;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Relation_Target_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Targets : A11y.Relations.Target_Vectors.Vector;
         Limit : constant Natural := Natural
           (A11y.Resource_Limits.Value
              (Limits, A11y.Resource_Limits.Relation_Targets_Returned));
      begin
         Query_Result.Source := View.Node;
         Targets := A11y.Relations.Targets
           (Graph, View.Node, A11y.Relations.Active_Descendant);
         if Natural (Targets.Length) > Limit then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Has_Target := False;
            Query_Result.Status := A11y.Results.Resource_Limit;
            Callback_Result := (Status => A11y.Results.Resource_Limit);
            return;
         elsif Natural (Targets.Length) > 1 then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Has_Target := False;
            Query_Result.Status := A11y.Results.Invalid_State;
            Callback_Result := (Status => A11y.Results.Invalid_State);
            return;
         elsif not Targets.Is_Empty then
            if not Target_Available (Runtime, Targets.First_Element) then
               Query_Result.Target := A11y.Node_Ids.No_Node;
               Query_Result.Has_Target := False;
               Query_Result.Status := A11y.Results.Node_Unavailable;
               Callback_Result := (Status => A11y.Results.Node_Unavailable);
               return;
            end if;

            Query_Result.Target := Targets.First_Element;
            Query_Result.Has_Target := True;
         end if;
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
      declare
         Limit_Result : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Limit_Result) then
            Result := (Status     => Limit_Result.Status,
                       Source     => A11y.Node_Ids.No_Node,
                       Target     => A11y.Node_Ids.No_Node,
                       Has_Target => False);
            return;
         end if;
      end;

      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate,
         Runtime,
         Node,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Tree_Navigation_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status     => Begin_Result.Status,
                    Source     => A11y.Node_Ids.No_Node,
                    Target     => A11y.Node_Ids.No_Node,
                    Has_Target => False);
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
         Result := (Status     => A11y.Results.Internal_Error,
                    Source     => A11y.Node_Ids.No_Node,
                    Target     => A11y.Node_Ids.No_Node,
                    Has_Target => False);
   end Query_Node_Active_Descendant;

end A11y.Native_Relation_Calls;
