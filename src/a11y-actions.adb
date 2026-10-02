package body A11y.Actions is

   Activate_Name : aliased constant String := "activate";
   Press_Name : aliased constant String := "press";
   Toggle_Name : aliased constant String := "toggle";
   Expand_Name : aliased constant String := "expand";
   Collapse_Name : aliased constant String := "collapse";
   Show_Menu_Name : aliased constant String := "show-menu";
   Dismiss_Name : aliased constant String := "dismiss";
   Increment_Name : aliased constant String := "increment";
   Decrement_Name : aliased constant String := "decrement";
   Select_Item_Name : aliased constant String := "select";
   Deselect_Name : aliased constant String := "deselect";
   Clear_Selection_Name : aliased constant String := "clear-selection";
   Scroll_Into_View_Name : aliased constant String := "scroll-into-view";
   Set_Focus_Name : aliased constant String := "set-focus";
   Open_Name : aliased constant String := "open";
   Close_Name : aliased constant String := "close";

   Requires_Live_Node_Name : aliased constant String := "requires-live-node";
   Requires_Enabled_Name   : aliased constant String := "requires-enabled";
   Requires_Not_Busy_Name  : aliased constant String := "requires-not-busy";
   Requires_Writable_Name  : aliased constant String := "requires-writable";

   Dispatch_Synchronous_Name : aliased constant String :=
     "dispatch-synchronous";
   Dispatch_May_Accept_Asynchronous_Name : aliased constant String :=
     "dispatch-may-accept-asynchronous";

   Application_Policy_Name : aliased constant String :=
     "application-policy";
   Focus_Policy_Name : aliased constant String := "focus-policy";
   Selection_Policy_Name : aliased constant String := "selection-policy";
   Value_Mutation_Policy_Name : aliased constant String :=
     "value-mutation-policy";
   Window_Operation_Policy_Name : aliased constant String :=
     "window-operation-policy";

   function With_Precondition
     (Base : Action_Precondition_Set;
      Item : Action_Precondition)
      return Action_Precondition_Set
   with SPARK_Mode => On
   is
      Result : Action_Precondition_Set := Base;
   begin
      Result (Item) := True;
      return Result;
   end With_Precondition;

   function Enabled_Action return Action_Precondition_Set is
     (With_Precondition
        (With_Precondition
           (With_Precondition (Empty_Precondition_Set, Requires_Live_Node),
            Requires_Enabled),
         Requires_Not_Busy))
   with SPARK_Mode => On;

   function Mutable_Action return Action_Precondition_Set is
     (With_Precondition (Enabled_Action, Requires_Writable))
   with SPARK_Mode => On;

   function Metadata (Action : Action_Id) return Action_Metadata is
     (case Action is
        when Activate =>
          (Stable_Name => Activate_Name'Access,
           Idempotent => False,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Application_Policy),
        when Press =>
          (Stable_Name => Press_Name'Access,
           Idempotent => False,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Application_Policy),
        when Toggle =>
          (Stable_Name => Toggle_Name'Access,
           Idempotent => False,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Application_Policy),
        when Expand =>
          (Stable_Name => Expand_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Application_Policy),
        when Collapse =>
          (Stable_Name => Collapse_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Application_Policy),
        when Show_Menu =>
          (Stable_Name => Show_Menu_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Window_Operation_Policy),
        when Dismiss =>
          (Stable_Name => Dismiss_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Window_Operation_Policy),
        when Increment =>
          (Stable_Name => Increment_Name'Access,
           Idempotent => False,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Value_Mutation_Policy),
        when Decrement =>
          (Stable_Name => Decrement_Name'Access,
           Idempotent => False,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Value_Mutation_Policy),
        when Select_Item =>
          (Stable_Name => Select_Item_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Selection_Policy),
        when Deselect =>
          (Stable_Name => Deselect_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Selection_Policy),
        when Clear_Selection =>
          (Stable_Name => Clear_Selection_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Selection_Policy),
        when Scroll_Into_View =>
          (Stable_Name => Scroll_Into_View_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Application_Policy),
        when Set_Focus =>
          (Stable_Name => Set_Focus_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Focus_Policy),
        when Open =>
          (Stable_Name => Open_Name'Access,
           Idempotent => False,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Window_Operation_Policy),
        when Close =>
          (Stable_Name => Close_Name'Access,
           Idempotent => True,
           Requires_Params => False,
           May_Be_Async => True,
           Dispatch => Dispatch_May_Accept_Asynchronous,
           Security => Window_Operation_Policy));

   function Metadata
     (Item : Action_Dispatch_Behavior)
      return Action_Dispatch_Metadata is
     (case Item is
        when Dispatch_Synchronous =>
          (Stable_Name => Dispatch_Synchronous_Name'Access),
        when Dispatch_May_Accept_Asynchronous =>
          (Stable_Name => Dispatch_May_Accept_Asynchronous_Name'Access));

   function Metadata
     (Item : Action_Security_Policy)
      return Action_Security_Metadata is
     (case Item is
        when Application_Policy =>
          (Stable_Name => Application_Policy_Name'Access),
        when Focus_Policy =>
          (Stable_Name => Focus_Policy_Name'Access),
        when Selection_Policy =>
          (Stable_Name => Selection_Policy_Name'Access),
        when Value_Mutation_Policy =>
          (Stable_Name => Value_Mutation_Policy_Name'Access),
        when Window_Operation_Policy =>
          (Stable_Name => Window_Operation_Policy_Name'Access));

   function Metadata
     (Item : Action_Precondition)
      return Action_Precondition_Metadata is
     (case Item is
        when Requires_Live_Node =>
          (Stable_Name => Requires_Live_Node_Name'Access,
           Failure => A11y.Results.Node_Unavailable),
        when Requires_Enabled =>
          (Stable_Name => Requires_Enabled_Name'Access,
           Failure => A11y.Results.Disabled),
        when Requires_Not_Busy =>
          (Stable_Name => Requires_Not_Busy_Name'Access,
           Failure => A11y.Results.Busy),
        when Requires_Writable =>
          (Stable_Name => Requires_Writable_Name'Access,
           Failure => A11y.Results.Read_Only));

   function Stable_Name (Action : Action_Id) return String is
     (Metadata (Action).Stable_Name.all);

   function Stable_Name (Item : Action_Dispatch_Behavior) return String is
     (Metadata (Item).Stable_Name.all);

   function Stable_Name (Item : Action_Security_Policy) return String is
     (Metadata (Item).Stable_Name.all);

   function Stable_Name (Item : Action_Precondition) return String is
     (Metadata (Item).Stable_Name.all);

   function Is_Value_Mutation
     (Action : Action_Id)
      return Boolean is
     (Action in Increment | Decrement)
   with SPARK_Mode => On;

   function Is_Selection_Mutation
     (Action : Action_Id)
      return Boolean is
     (Action in Select_Item | Deselect | Clear_Selection)
   with SPARK_Mode => On;

   function Is_Window_Operation
     (Action : Action_Id)
      return Boolean is
     (Action in Show_Menu | Dismiss | Open | Close)
   with SPARK_Mode => On;

   function Is_Idempotent_By_Default
     (Action : Action_Id)
      return Boolean is
     (Action in Expand | Collapse | Show_Menu | Dismiss | Select_Item |
                Deselect | Clear_Selection | Scroll_Into_View |
                Set_Focus | Close)
   with SPARK_Mode => On;

   function Failure_For
     (Item : Action_Precondition)
      return A11y.Results.Status_Code is
     (case Item is
        when Requires_Live_Node => A11y.Results.Node_Unavailable,
        when Requires_Enabled   => A11y.Results.Disabled,
        when Requires_Not_Busy  => A11y.Results.Busy,
        when Requires_Writable  => A11y.Results.Read_Only)
   with SPARK_Mode => On;

   function Preconditions
     (Action : Action_Id)
      return Action_Precondition_Set is
     (case Action is
        when Activate | Press | Toggle | Expand | Collapse | Show_Menu |
             Dismiss | Select_Item | Deselect | Clear_Selection |
             Scroll_Into_View | Set_Focus | Open | Close =>
          Enabled_Action,
        when Increment | Decrement =>
          Mutable_Action)
   with SPARK_Mode => On;

   function Requires
     (Action : Action_Id;
      Item   : Action_Precondition)
      return Boolean is
     (Preconditions (Action) (Item))
   with SPARK_Mode => On;

   function Check_Preconditions
     (Action : Action_Id;
      States : A11y.States.State_Set)
      return Action_Result
   with SPARK_Mode => On
   is
      Required : constant Action_Precondition_Set := Preconditions (Action);
   begin
      if Required (Requires_Live_Node)
        and then States (A11y.States.Defunct)
      then
         return
           (Status =>
              Failure_For (Requires_Live_Node));
      elsif Required (Requires_Enabled)
        and then not States (A11y.States.Enabled)
      then
         return
           (Status =>
              Failure_For (Requires_Enabled));
      elsif Required (Requires_Not_Busy)
        and then States (A11y.States.Busy)
      then
         return
           (Status =>
              Failure_For (Requires_Not_Busy));
      elsif Required (Requires_Writable)
        and then States (A11y.States.Read_Only)
      then
         return
           (Status =>
              Failure_For (Requires_Writable));
      end if;

      return (Status => A11y.Results.Success);
   end Check_Preconditions;

   function Validate_Request
     (Set    : Action_Set;
      Action : Action_Id;
      States : A11y.States.State_Set)
      return Action_Result
   with SPARK_Mode => On
   is
      Result : Action_Result;
   begin
      if not Supports (Set, Action) then
         return (Status => A11y.Results.Unsupported_Action);
      end if;

      Result := Check_Preconditions (Action, States);
      if Result.Status /= A11y.Results.Success then
         return Result;
      end if;

      return (Status => A11y.Results.Success);
   end Validate_Request;

   function With_Action
     (Base : Action_Set;
      Item : Action_Id)
      return Action_Set
   with SPARK_Mode => On
   is
      Result : Action_Set := Base;
   begin
      Result (Item) := True;
      return Result;
   end With_Action;

   function Supports
     (Set    : Action_Set;
      Action : Action_Id)
      return Boolean is
     (Set (Action))
   with SPARK_Mode => On;

   function Preferred_Default_Action
     (Role : A11y.Roles.Role)
      return Action_Id is
     (case Role is
        when A11y.Roles.Button => Press,
        when A11y.Roles.Toggle_Button => Toggle,
        when A11y.Roles.Check_Box => Toggle,
        when A11y.Roles.Radio_Button => Select_Item,
        when A11y.Roles.Combo_Box => Show_Menu,
        when A11y.Roles.List_Item => Select_Item,
        when A11y.Roles.Tree_Item => Expand,
        when A11y.Roles.Tab => Select_Item,
        when A11y.Roles.Menu_Item => Activate,
        when A11y.Roles.Link => Open,
        when A11y.Roles.Text_Field |
             A11y.Roles.Search_Field |
             A11y.Roles.Password_Field => Set_Focus,
        when others => Activate)
   with SPARK_Mode => On;

   function Default_Action
     (Role : A11y.Roles.Role;
      Set  : Action_Set)
      return Action_Id
   with SPARK_Mode => On
   is
      Preferred : constant Action_Id := Preferred_Default_Action (Role);
   begin
      if Set (Preferred) then
         return Preferred;
      end if;

      for Action in Action_Id loop
         if Set (Action) then
            return Action;
         end if;
      end loop;

      return Activate;
   end Default_Action;

   function Has_Default_Action
     (Role : A11y.Roles.Role;
      Set  : Action_Set)
      return Boolean
   with SPARK_Mode => On
   is
      pragma Unreferenced (Role);
   begin
      for Action in Action_Id loop
         if Set (Action) then
            return True;
         end if;
      end loop;
      return False;
   end Has_Default_Action;

   function Invoke_Safely
     (Self   : in out Action_Provider'Class;
      Node   : A11y.Node_Ids.Node_Id;
      Action : Action_Id)
      return Action_Result
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      if not Supports (Self, Action) then
         return (Status => A11y.Results.Unsupported_Action);
      end if;

      return Invoke (Self, Node, Action);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Invoke_Safely;

   function Invoke_Safely
     (Self   : in out Action_Provider'Class;
      Node   : A11y.Node_Ids.Node_Id;
      Action : Action_Id;
      States : A11y.States.State_Set)
      return Action_Result
   is
      Precondition_Result : Action_Result;
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return (Status => A11y.Results.Node_Unavailable);
      end if;

      if not Supports (Self, Action) then
         return (Status => A11y.Results.Unsupported_Action);
      end if;

      Precondition_Result := Check_Preconditions (Action, States);
      if Precondition_Result.Status /= A11y.Results.Success then
         return Precondition_Result;
      end if;

      return Invoke (Self, Node, Action);
   exception
      when others =>
         return (Status => A11y.Results.Internal_Error);
   end Invoke_Safely;

   function To_Result (Item : Action_Result) return A11y.Results.Result is
     (Status => Item.Status)
   with SPARK_Mode => On;

end A11y.Actions;
