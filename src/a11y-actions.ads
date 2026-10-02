with A11y.Node_Ids;
with A11y.States;
with A11y.Results;
with A11y.Roles;

package A11y.Actions is

   use type A11y.Results.Status_Code;

   type Action_Id is
     (Activate,
      Press,
      Toggle,
      Expand,
      Collapse,
      Show_Menu,
      Dismiss,
      Increment,
      Decrement,
      Select_Item,
      Deselect,
      Clear_Selection,
      Scroll_Into_View,
      Set_Focus,
      Open,
      Close);

   type Action_Result is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
   end record;

   type Action_Set is array (Action_Id) of Boolean;

   Empty_Action_Set : constant Action_Set := [others => False];

   type Action_Dispatch_Behavior is
     (Dispatch_Synchronous,
      Dispatch_May_Accept_Asynchronous);

   type Action_Security_Policy is
     (Application_Policy,
      Focus_Policy,
      Selection_Policy,
      Value_Mutation_Policy,
      Window_Operation_Policy);

   type Action_Metadata is record
      Stable_Name      : access constant String;
      Idempotent       : Boolean := False;
      Requires_Params  : Boolean := False;
      May_Be_Async     : Boolean := False;
      Dispatch         : Action_Dispatch_Behavior := Dispatch_Synchronous;
      Security         : Action_Security_Policy := Application_Policy;
   end record;

   type Action_Dispatch_Metadata is record
      Stable_Name : access constant String;
   end record;

   type Action_Security_Metadata is record
      Stable_Name : access constant String;
   end record;

   type Action_Precondition is
     (Requires_Live_Node,
      Requires_Enabled,
      Requires_Not_Busy,
      Requires_Writable);

   type Action_Precondition_Set is array (Action_Precondition) of Boolean;

   Empty_Precondition_Set : constant Action_Precondition_Set :=
     [others => False];

   type Action_Precondition_Metadata is record
      Stable_Name : access constant String;
      Failure     : A11y.Results.Status_Code := A11y.Results.Invalid_State;
   end record;

   function Metadata (Action : Action_Id) return Action_Metadata;
   function Metadata
     (Item : Action_Dispatch_Behavior)
      return Action_Dispatch_Metadata;
   function Metadata
     (Item : Action_Security_Policy)
      return Action_Security_Metadata;
   function Metadata
     (Item : Action_Precondition)
      return Action_Precondition_Metadata;

   function Stable_Name (Action : Action_Id) return String;
   function Stable_Name (Item : Action_Dispatch_Behavior) return String;
   function Stable_Name (Item : Action_Security_Policy) return String;
   function Stable_Name (Item : Action_Precondition) return String;

   function Is_Value_Mutation
     (Action : Action_Id)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Value_Mutation'Result =
         (Action in Increment | Decrement);

   function Is_Selection_Mutation
     (Action : Action_Id)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Selection_Mutation'Result =
         (Action in Select_Item | Deselect | Clear_Selection);

   function Is_Window_Operation
     (Action : Action_Id)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Window_Operation'Result =
         (Action in Show_Menu | Dismiss | Open | Close);

   function Is_Idempotent_By_Default
     (Action : Action_Id)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Is_Idempotent_By_Default'Result =
         (Action in Expand | Collapse | Show_Menu | Dismiss | Select_Item |
                    Deselect | Clear_Selection | Scroll_Into_View |
                    Set_Focus | Close);

   function Failure_For
     (Item : Action_Precondition)
      return A11y.Results.Status_Code
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       (case Item is
          when Requires_Live_Node =>
            Failure_For'Result = A11y.Results.Node_Unavailable,
          when Requires_Enabled =>
            Failure_For'Result = A11y.Results.Disabled,
          when Requires_Not_Busy =>
            Failure_For'Result = A11y.Results.Busy,
          when Requires_Writable =>
            Failure_For'Result = A11y.Results.Read_Only);

   function Preconditions
     (Action : Action_Id)
      return Action_Precondition_Set
   with
      SPARK_Mode => On,
      Global => null;

   function Requires
     (Action : Action_Id;
      Item   : Action_Precondition)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Requires'Result = Preconditions (Action) (Item);

   function Check_Preconditions
     (Action : Action_Id;
      States : A11y.States.State_Set)
      return Action_Result
   with
      SPARK_Mode => On,
      Global => null;

   function Validate_Request
     (Set    : Action_Set;
      Action : Action_Id;
      States : A11y.States.State_Set)
      return Action_Result
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if not Set (Action)
         then Validate_Request'Result.Status =
           A11y.Results.Unsupported_Action);

   function With_Action
     (Base : Action_Set;
      Item : Action_Id)
      return Action_Set
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        With_Action'Result (Item)
        and then
          (for all Other in Action_Id =>
             (if Other /= Item
              then With_Action'Result (Other) = Base (Other)));

   function Supports
     (Set    : Action_Set;
      Action : Action_Id)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Supports'Result = Set (Action);

   function Preferred_Default_Action
     (Role : A11y.Roles.Role)
      return Action_Id
   with
      SPARK_Mode => On,
      Global => null;

   function Default_Action
     (Role : A11y.Roles.Role;
      Set  : Action_Set)
      return Action_Id
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Set (Preferred_Default_Action (Role))
         then Default_Action'Result = Preferred_Default_Action (Role))
        and then
          (if (for some Action in Action_Id => Set (Action))
           then Set (Default_Action'Result));

   function Has_Default_Action
     (Role : A11y.Roles.Role;
      Set  : Action_Set)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Has_Default_Action'Result =
          (for some Action in Action_Id => Set (Action));

   type Action_Provider is limited interface;

   function Supports
     (Self   : Action_Provider;
      Action : Action_Id)
      return Boolean is abstract;

   function Invoke
     (Self   : in out Action_Provider;
      Node   : A11y.Node_Ids.Node_Id;
      Action : Action_Id)
      return Action_Result is abstract;

   function Invoke_Safely
     (Self   : in out Action_Provider'Class;
      Node   : A11y.Node_Ids.Node_Id;
      Action : Action_Id)
      return Action_Result;

   function Invoke_Safely
     (Self   : in out Action_Provider'Class;
      Node   : A11y.Node_Ids.Node_Id;
      Action : Action_Id;
      States : A11y.States.State_Set)
      return Action_Result;

   function To_Result (Item : Action_Result) return A11y.Results.Result
   with
      SPARK_Mode => On,
      Global => null,
      Post => To_Result'Result.Status = Item.Status;

end A11y.Actions;
