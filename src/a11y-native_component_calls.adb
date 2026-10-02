with A11y.Native_Boundary_Calls;

package body A11y.Native_Component_Calls is
   use type A11y.Results.Status_Code;

   procedure Query_Object_Contains_Point
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Boolean_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Boolean_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Bounds : A11y.Geometry.Rectangle;
         Bounds_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Bounds := A11y.Nodes.Bounds_Safely (Provider, Bounds_Result);
         if A11y.Results.Failed (Bounds_Result) then
            Query_Result.Value := False;
            Query_Result.Status := Bounds_Result.Status;
            Callback_Result := Bounds_Result;
            return;
         end if;

         Query_Result.Value :=
           A11y.Geometry.Contains (Bounds, Point);
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
         Kind => A11y.Dispatchers.Geometry_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Value  => False);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Geometry_Query,
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
                    Value  => False);
   end Query_Object_Contains_Point;

   procedure Query_Node_Contains_Point
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Boolean_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Boolean_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Bounds : A11y.Geometry.Rectangle;
         Bounds_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Bounds := A11y.Nodes.Bounds_Safely (Provider, Bounds_Result);
         if A11y.Results.Failed (Bounds_Result) then
            Query_Result.Value := False;
            Query_Result.Status := Bounds_Result.Status;
            Callback_Result := Bounds_Result;
            return;
         end if;

         Query_Result.Value :=
           A11y.Geometry.Contains (Bounds, Point);
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
         Kind => A11y.Dispatchers.Geometry_Query);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Source => A11y.Node_Ids.No_Node,
                    Value  => False);
         return;
      end if;

      View := A11y.Native_Boundary_Calls.Snapshot (Context);
      Dispatch_Callback
        (Dispatcher,
         A11y.Dispatchers.Geometry_Query,
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
                    Value  => False);
   end Query_Node_Contains_Point;

   procedure Query_Object_Hit_Test
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Hit_Test_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Hit_Test_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Bounds : A11y.Geometry.Rectangle;
         Bounds_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Bounds := A11y.Nodes.Bounds_Safely (Provider, Bounds_Result);
         if A11y.Results.Failed (Bounds_Result) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := Bounds_Result.Status;
            Callback_Result := Bounds_Result;
            return;
         end if;

         if A11y.Geometry.Contains (Bounds, Point) then
            Query_Result.Target := View.Node;
         else
            Query_Result.Target := A11y.Node_Ids.No_Node;
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
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate,
         Runtime,
         Object,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Geometry_Query);
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
         A11y.Dispatchers.Geometry_Query,
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
   end Query_Object_Hit_Test;

   procedure Query_Node_Hit_Test
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Point      : A11y.Geometry.Point;
      Result     : out Native_Hit_Test_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Hit_Test_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Bounds : A11y.Geometry.Rectangle;
         Bounds_Result : A11y.Results.Result;
      begin
         Query_Result.Source := View.Node;
         Bounds := A11y.Nodes.Bounds_Safely (Provider, Bounds_Result);
         if A11y.Results.Failed (Bounds_Result) then
            Query_Result.Target := A11y.Node_Ids.No_Node;
            Query_Result.Status := Bounds_Result.Status;
            Callback_Result := Bounds_Result;
            return;
         end if;

         if A11y.Geometry.Contains (Bounds, Point) then
            Query_Result.Target := View.Node;
         else
            Query_Result.Target := A11y.Node_Ids.No_Node;
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
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate,
         Runtime,
         Node,
         Context,
         Begin_Result,
         Kind => A11y.Dispatchers.Geometry_Query);
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
         A11y.Dispatchers.Geometry_Query,
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
   end Query_Node_Hit_Test;

end A11y.Native_Component_Calls;
