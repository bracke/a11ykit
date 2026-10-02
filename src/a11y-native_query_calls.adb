with Ada.Strings.Unbounded;

with A11y.Native_Boundary_Calls;

package body A11y.Native_Query_Calls is
   use type A11y.Properties.Property_Status;
   use type A11y.Roles.Role;
   use type A11y.Results.Status_Code;

   procedure Enforce_String_Limit
     (Item   : in out Native_String_Result;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Validation) then
         Item.Status := Validation.Status;
         Item.Value :=
           (Status => A11y.Properties.Status_From_Result (Validation.Status),
            Value  => <>);
      elsif Item.Status = A11y.Results.Success
        and then Item.Value.Status = A11y.Properties.Present
        and then A11y.Resource_Limits.Exceeded
          (Limits,
           A11y.Resource_Limits.Native_String_Size,
           Ada.Strings.Unbounded.Length (Item.Value.Value))
      then
         Item.Status := A11y.Results.Resource_Limit;
         Item.Value :=
           (Status => A11y.Properties.Status_From_Result (Item.Status),
            Value  => <>);
      end if;
   end Enforce_String_Limit;

   function Property_Value
     (Result : Native_Role_Result)
      return A11y.Properties.Role_Value_Property is
     (if Result.Status = A11y.Results.Success then
        A11y.Properties.Present (Result.Role)
      else
        (Status => A11y.Properties.Status_From_Result (Result.Status),
         Value  => A11y.Roles.Custom));

   function Property_Value
     (Result : Native_State_Result)
      return A11y.Properties.State_Set_Value_Property is
     (if Result.Status = A11y.Results.Success then
        A11y.Properties.Present (Result.States)
      else
        (Status => A11y.Properties.Status_From_Result (Result.Status),
         Value  => A11y.States.Empty_State_Set));

   function Property_Value
     (Result : Native_Integer_Result)
      return A11y.Properties.Integer_Property is
     (if Result.Status = A11y.Results.Success then
        Result.Value
      else
        (Status => A11y.Properties.Status_From_Result (Result.Status),
         Value  => 0));

   function Property_Value
     (Result : Native_Bounds_Result)
      return A11y.Properties.Rectangle_Property is
     (if Result.Status = A11y.Results.Success then
        A11y.Properties.Present (Result.Bounds)
      else
        (Status => A11y.Properties.Status_From_Result (Result.Status),
         Value  => A11y.Geometry.Empty_Rectangle));

   procedure Query_Object_Role
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Role_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Role_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Contract_Snapshot_Safely
             (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Status := Snapshot_Result.Status;
            Query_Result.Role := A11y.Roles.Custom;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         Query_Result.Role := Snapshot.Role;
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Role   => A11y.Roles.Custom);
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Role   => A11y.Roles.Custom);
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Role   => A11y.Roles.Custom);
   end Query_Object_Role;

   procedure Query_Node_Role
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Role_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Role_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Contract_Snapshot_Safely
             (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Status := Snapshot_Result.Status;
            Query_Result.Role := A11y.Roles.Custom;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         Query_Result.Role := Snapshot.Role;
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Role   => A11y.Roles.Custom);
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Role   => A11y.Roles.Custom);
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Role   => A11y.Roles.Custom);
   end Query_Node_Role;

   procedure Query_Object_States
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_State_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_State_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Contract_Snapshot_Safely
             (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Status := Snapshot_Result.Status;
            Query_Result.States := A11y.States.Empty_State_Set;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         Query_Result.States :=
           A11y.States.Derive
             (Snapshot.States,
              Snapshot.Role,
              Snapshot.Capabilities);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         States => A11y.States.Empty_State_Set);
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    States => A11y.States.Empty_State_Set);
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    States => A11y.States.Empty_State_Set);
   end Query_Object_States;

   procedure Query_Node_States
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_State_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_State_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Contract_Snapshot_Safely
             (Provider, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            Query_Result.Status := Snapshot_Result.Status;
            Query_Result.States := A11y.States.Empty_State_Set;
            Callback_Result := Snapshot_Result;
            return;
         end if;

         Query_Result.States :=
           A11y.States.Derive
             (Snapshot.States,
              Snapshot.Role,
              Snapshot.Capabilities);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         States => A11y.States.Empty_State_Set);
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    States => A11y.States.Empty_State_Set);
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    States => A11y.States.Empty_State_Set);
   end Query_Node_States;

   procedure Query_Object_Name
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Basic_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Basic_Snapshot_Safely
             (Provider, Limits, Snapshot_Result);
         Query_Result.Value := Snapshot.Name;
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Name;

   procedure Query_Node_Name
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Basic_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Basic_Snapshot_Safely
             (Provider, Limits, Snapshot_Result);
         Query_Result.Value := Snapshot.Name;
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Name;

   procedure Query_Object_Visible_Title
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Visible_Title
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Visible_Title;

   procedure Query_Node_Visible_Title
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Visible_Title
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Visible_Title;

   procedure Query_Object_Description
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Basic_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Basic_Snapshot_Safely
             (Provider, Limits, Snapshot_Result);
         Query_Result.Value := Snapshot.Description;
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Description;

   procedure Query_Node_Description
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Snapshot : A11y.Nodes.Node_Basic_Snapshot;
         Snapshot_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Snapshot :=
           A11y.Nodes.Basic_Snapshot_Safely
             (Provider, Limits, Snapshot_Result);
         Query_Result.Value := Snapshot.Description;
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Description;

   procedure Query_Object_Help_Text
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Help_Text
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Help_Text;

   procedure Query_Node_Help_Text
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Help_Text
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Help_Text;

   procedure Query_Object_Placeholder
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Placeholder
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Placeholder;

   procedure Query_Node_Placeholder
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Placeholder
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Placeholder;

   procedure Query_Object_Value_Text
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Value_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Query_Result.Value :=
           A11y.Nodes.Value_Text_Safely (Provider, Limits, Value_Result);
         Query_Result.Status := Value_Result.Status;
         Callback_Result := Value_Result;
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Value_Text;

   procedure Query_Node_Value_Text
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Value_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Query_Result.Value :=
           A11y.Nodes.Value_Text_Safely (Provider, Limits, Value_Result);
         Query_Result.Status := Value_Result.Status;
         Callback_Result := Value_Result;
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Value_Text;

   procedure Query_Object_Keyboard_Shortcut
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Keyboard_Shortcut
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Keyboard_Shortcut;

   procedure Query_Node_Keyboard_Shortcut
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Keyboard_Shortcut
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Keyboard_Shortcut;

   procedure Query_Object_Semantic_Identifier
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Semantic_Identifier
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Semantic_Identifier;

   procedure Query_Node_Semantic_Identifier
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Semantic_Identifier
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Semantic_Identifier;

   procedure Query_Object_Locale
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Locale
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Locale;

   procedure Query_Node_Locale
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Locale
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Locale;

   procedure Query_Object_Orientation
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Orientation
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Orientation;

   procedure Query_Node_Orientation
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Orientation
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Orientation;

   procedure Query_Object_Landmark
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Landmark
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Landmark;

   procedure Query_Node_Landmark
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_String_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token;
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_String_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Textual_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Landmark
                (A11y.Properties.Textual_Property_Provider'Class (Provider));
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => <>);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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

      Enforce_String_Limit (Query_Result, Limits);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Landmark;

   procedure Query_Object_Set_Position
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Set_Position);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Set_Position;

   procedure Query_Node_Set_Position
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Set_Position);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Set_Position;

   procedure Query_Object_Set_Size
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Set_Size);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Set_Size;

   procedure Query_Node_Set_Size
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Set_Size);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Set_Size;

   procedure Query_Object_Hierarchical_Level
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Hierarchical_Level);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Hierarchical_Level;

   procedure Query_Node_Hierarchical_Level
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Hierarchical_Level);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Hierarchical_Level;

   procedure Query_Object_Heading_Level
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Heading_Level);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Object_Call
        (Gate, Runtime, Object, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Object_Heading_Level;

   procedure Query_Node_Heading_Level
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Integer_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Integer_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
      begin
         Query_Result.Node := View.Node;
         if Provider in A11y.Properties.Structural_Property_Provider'Class then
            Query_Result.Value :=
              A11y.Properties.Structural_Property_Safely
                (A11y.Properties.Structural_Property_Provider'Class (Provider),
                 A11y.Properties.Heading_Level);
         else
            Query_Result.Value := (Status => A11y.Properties.Unsupported,
                                   Value  => 0);
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
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Value  => (others => <>));
      A11y.Native_Boundary_Calls.Begin_Node_Call
        (Gate, Runtime, Node, Context, Begin_Result);
      if A11y.Native_Boundary_Calls.Begin_Status_Rejects_Call (Begin_Result.Status)
      then
         Result := (Status => Begin_Result.Status,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
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
         Result := (Status => A11y.Results.Internal_Error,
                    Node   => A11y.Node_Ids.No_Node,
                    Value  => (others => <>));
   end Query_Node_Heading_Level;

   procedure Query_Object_Bounds
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Bounds_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Bounds_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Bounds_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Query_Result.Bounds :=
           A11y.Nodes.Bounds_Safely (Provider, Bounds_Result);
         Query_Result.Status := Bounds_Result.Status;
         Callback_Result := Bounds_Result;
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Bounds => A11y.Geometry.Empty_Rectangle);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Bounds => A11y.Geometry.Empty_Rectangle);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Bounds => A11y.Geometry.Empty_Rectangle);
   end Query_Object_Bounds;

   procedure Query_Node_Bounds
     (Gate       : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime    : in out A11y.Native_Runtimes.Native_Runtime;
      Dispatcher : in out A11y.Dispatchers.Immediate_Dispatcher;
      Node       : A11y.Node_Ids.Node_Id;
      Provider   : A11y.Nodes.Accessible_Node'Class;
      Result     : out Native_Bounds_Result;
      Token      : A11y.Dispatchers.Cancellation_Token :=
        A11y.Dispatchers.Create_Cancellation_Token)
   is
      Context : A11y.Native_Boundary_Calls.Boundary_Call_Context;
      View : A11y.Native_Boundary_Calls.Boundary_Call_Snapshot;
      Begin_Result : A11y.Results.Result;
      Dispatch_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Query_Result : Native_Bounds_Result;

      procedure Callback (Callback_Result : out A11y.Results.Result) is
         Bounds_Result : A11y.Results.Result;
      begin
         Query_Result.Node := View.Node;
         Query_Result.Bounds :=
           A11y.Nodes.Bounds_Safely (Provider, Bounds_Result);
         Query_Result.Status := Bounds_Result.Status;
         Callback_Result := Bounds_Result;
      exception
         when others =>
            Query_Result.Status := A11y.Results.Internal_Error;
            Callback_Result := (Status => A11y.Results.Internal_Error);
      end Callback;

      procedure Dispatch_Callback is new
        A11y.Dispatchers.Invoke_Callback_With_Token (Callback);
   begin
      Query_Result :=
        (Status => A11y.Results.Internal_Error,
         Node   => A11y.Node_Ids.No_Node,
         Bounds => A11y.Geometry.Empty_Rectangle);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Bounds => A11y.Geometry.Empty_Rectangle);
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
                    Node   => A11y.Node_Ids.No_Node,
                    Bounds => A11y.Geometry.Empty_Rectangle);
   end Query_Node_Bounds;

end A11y.Native_Query_Calls;
