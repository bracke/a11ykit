with A11y.Results;

package A11y.Actions.Classification is
   pragma SPARK_Mode (On);

   function Is_Value_Mutation
     (Action : Action_Id)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Value_Mutation'Result =
         (Action in Increment | Decrement);

   function Is_Selection_Mutation
     (Action : Action_Id)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Selection_Mutation'Result =
         (Action in Select_Item | Deselect | Clear_Selection);

   function Is_Window_Operation
     (Action : Action_Id)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Window_Operation'Result =
         (Action in Show_Menu | Dismiss | Open | Close);

   function Is_Idempotent_By_Default
     (Action : Action_Id)
      return Standard.Boolean
   with
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
     Global => null,
     Post =>
       (case Item is
          when Requires_Live_Node => Failure_For'Result = A11y.Results.Node_Unavailable,
          when Requires_Enabled   => Failure_For'Result = A11y.Results.Disabled,
          when Requires_Not_Busy  => Failure_For'Result = A11y.Results.Busy,
          when Requires_Writable  => Failure_For'Result = A11y.Results.Read_Only);

end A11y.Actions.Classification;
