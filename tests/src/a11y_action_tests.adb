with A11y.Actions;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Roles;
with A11y.States;

with A11ykit_Test_Support;

package body A11y_Action_Tests is
   use type A11y.Actions.Action_Dispatch_Behavior;
   use type A11y.Actions.Action_Id;
   use type A11y.Actions.Action_Security_Policy;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   type Test_Action_Provider is new A11y.Actions.Action_Provider with record
      Supported : A11y.Actions.Action_Set := A11y.Actions.Empty_Action_Set;
      Calls     : Natural := 0;
      Raise_On_Invoke : Boolean := False;
   end record;

   overriding function Supports
     (Self   : Test_Action_Provider;
      Action : A11y.Actions.Action_Id)
      return Boolean is
     (A11y.Actions.Supports (Self.Supported, Action));

   overriding function Invoke
     (Self   : in out Test_Action_Provider;
      Node   : A11y.Node_Ids.Node_Id;
      Action : A11y.Actions.Action_Id)
      return A11y.Actions.Action_Result
   is
      pragma Unreferenced (Node, Action);
   begin
      if Self.Raise_On_Invoke then
         raise Program_Error;
      end if;
      Self.Calls := Self.Calls + 1;
      return (Status => A11y.Results.Success);
   end Invoke;

   procedure Run is
      Provider : Test_Action_Provider;
      Result : A11y.Actions.Action_Result;
      Actions : A11y.Actions.Action_Set := A11y.Actions.Empty_Action_Set;
      States : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Node : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (100);
   begin
      Actions := A11y.Actions.With_Action (Actions, A11y.Actions.Press);
      Actions := A11y.Actions.With_Action (Actions, A11y.Actions.Toggle);
      Actions := A11y.Actions.With_Action (Actions, A11y.Actions.Increment);
      Provider.Supported := Actions;

      Check
        (A11y.Actions.Supports (Actions, A11y.Actions.Press),
         "action set reports supported actions");
      Check
        (A11y.Actions.Default_Action (A11y.Roles.Button, Actions)
         = A11y.Actions.Press,
         "action framework chooses role-appropriate default action");
      Check
        (A11y.Actions.Preferred_Default_Action (A11y.Roles.List_Item)
         = A11y.Actions.Select_Item
         and then A11y.Actions.Preferred_Default_Action
           (A11y.Roles.Password_Field) = A11y.Actions.Set_Focus
         and then A11y.Actions.Preferred_Default_Action
           (A11y.Roles.Link) = A11y.Actions.Open
         and then A11y.Actions.Preferred_Default_Action
           (A11y.Roles.Custom) = A11y.Actions.Activate,
         "action framework exposes role default-action semantics");
      Check
        (A11y.Actions.Has_Default_Action (A11y.Roles.Button, Actions),
         "action framework reports default action availability");
      Check
        (A11y.Actions.Stable_Name (A11y.Actions.Scroll_Into_View)
         = "scroll-into-view",
         "action framework exposes stable protocol action names");
      Check
        (A11y.Actions.Metadata (A11y.Actions.Expand).Idempotent
         and then not A11y.Actions.Metadata
           (A11y.Actions.Expand).Requires_Params
         and then A11y.Actions.Metadata (A11y.Actions.Expand).May_Be_Async
         and then A11y.Actions.Metadata (A11y.Actions.Expand).Dispatch =
           A11y.Actions.Dispatch_May_Accept_Asynchronous
         and then A11y.Actions.Metadata (A11y.Actions.Set_Focus).Security =
           A11y.Actions.Focus_Policy
         and then A11y.Actions.Metadata (A11y.Actions.Select_Item).Security =
           A11y.Actions.Selection_Policy
         and then A11y.Actions.Metadata (A11y.Actions.Increment).Security =
           A11y.Actions.Value_Mutation_Policy
         and then A11y.Actions.Metadata (A11y.Actions.Close).Security =
           A11y.Actions.Window_Operation_Policy,
         "action framework exposes behavioral action metadata");
      Check
        (A11y.Actions.Stable_Name
           (A11y.Actions.Dispatch_May_Accept_Asynchronous)
         = "dispatch-may-accept-asynchronous"
         and then A11y.Actions.Stable_Name
           (A11y.Actions.Focus_Policy) = "focus-policy"
         and then A11y.Actions.Stable_Name
           (A11y.Actions.Value_Mutation_Policy)
         = "value-mutation-policy",
         "action framework exposes stable dispatch and security policy metadata");
      Check
        (A11y.Actions.Stable_Name (A11y.Actions.Requires_Enabled)
         = "requires-enabled"
         and then A11y.Actions.Metadata
           (A11y.Actions.Requires_Writable).Failure = A11y.Results.Read_Only,
         "action framework exposes stable precondition metadata");
      Check
        (A11y.Actions.Requires
           (A11y.Actions.Press, A11y.Actions.Requires_Enabled)
         and then A11y.Actions.Requires
           (A11y.Actions.Increment, A11y.Actions.Requires_Writable),
         "action framework declares action preconditions centrally");
      States (A11y.States.Enabled) := True;
      Result := A11y.Actions.Check_Preconditions
        (A11y.Actions.Press, States);
      Check
        (Result.Status = A11y.Results.Success,
         "action framework accepts satisfied preconditions");
      States (A11y.States.Busy) := True;
      Result := A11y.Actions.Check_Preconditions
        (A11y.Actions.Press, States);
      Check
        (Result.Status = A11y.Results.Busy,
         "action framework rejects busy nodes before provider invocation");
      States (A11y.States.Busy) := False;
      States (A11y.States.Enabled) := False;
      Result := A11y.Actions.Check_Preconditions
        (A11y.Actions.Press, States);
      Check
        (Result.Status = A11y.Results.Disabled,
         "action framework rejects disabled nodes before provider invocation");
      States (A11y.States.Enabled) := True;
      States (A11y.States.Read_Only) := True;
      Result := A11y.Actions.Check_Preconditions
        (A11y.Actions.Increment, States);
      Check
        (Result.Status = A11y.Results.Read_Only,
         "action framework rejects read-only mutable actions");
      States := A11y.States.Empty_State_Set;
      States (A11y.States.Defunct) := True;
      Result := A11y.Actions.Check_Preconditions
        (A11y.Actions.Press, States);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "action framework rejects defunct nodes before provider invocation");

      States := A11y.States.Empty_State_Set;
      States (A11y.States.Enabled) := True;
      Result := A11y.Actions.Validate_Request
        (Actions, A11y.Actions.Press, States);
      Check
        (Result.Status = A11y.Results.Success,
         "action framework validates supported action requests");

      Result := A11y.Actions.Validate_Request
        (Actions, A11y.Actions.Open, States);
      Check
        (Result.Status = A11y.Results.Unsupported_Action,
         "action framework rejects unsupported requests before dispatch");

      States (A11y.States.Busy) := True;
      Result := A11y.Actions.Validate_Request
        (Actions, A11y.Actions.Press, States);
      Check
        (Result.Status = A11y.Results.Busy,
         "action framework combines support and state precondition checks");

      States := A11y.States.Empty_State_Set;
      States (A11y.States.Enabled) := True;
      States (A11y.States.Read_Only) := True;
      Result := A11y.Actions.Invoke_Safely
        (Provider, Node, A11y.Actions.Increment, States);
      Check
        (Result.Status = A11y.Results.Read_Only
         and then Provider.Calls = 0,
         "action framework state-aware invocation rejects read-only actions "
         & "before provider code");

      States (A11y.States.Enabled) := False;
      States (A11y.States.Busy) := True;
      Result := A11y.Actions.Invoke_Safely
        (Provider, Node, A11y.Actions.Open, States);
      Check
        (Result.Status = A11y.Results.Unsupported_Action
         and then Provider.Calls = 0,
         "action framework state-aware invocation rejects unsupported actions "
         & "before state failures");
      Result := A11y.Actions.Invoke_Safely
        (Provider, Node, A11y.Actions.Press);
      Check
        (Result.Status = A11y.Results.Success and then Provider.Calls = 1,
         "action framework invokes supported actions safely");

      Result := A11y.Actions.Invoke_Safely
        (Provider, Node, A11y.Actions.Open);
      Check
        (Result.Status = A11y.Results.Unsupported_Action
         and then Provider.Calls = 1,
         "action framework rejects unsupported actions without provider mutation");

      Result := A11y.Actions.Invoke_Safely
        (Provider, A11y.Node_Ids.No_Node, A11y.Actions.Press);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "action framework rejects invalid node identity");

      Provider.Raise_On_Invoke := True;
      Result := A11y.Actions.Invoke_Safely
        (Provider, Node, A11y.Actions.Toggle);
      Check
        (Result.Status = A11y.Results.Internal_Error,
         "action framework contains provider exceptions");
   end Run;
end A11y_Action_Tests;
