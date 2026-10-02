package body A11y.Actions.Classification is
   pragma SPARK_Mode (On);

   function Is_Value_Mutation
     (Action : Action_Id)
      return Standard.Boolean is
     (A11y.Actions.Is_Value_Mutation (Action));

   function Is_Selection_Mutation
     (Action : Action_Id)
      return Standard.Boolean is
     (A11y.Actions.Is_Selection_Mutation (Action));

   function Is_Window_Operation
     (Action : Action_Id)
      return Standard.Boolean is
     (A11y.Actions.Is_Window_Operation (Action));

   function Is_Idempotent_By_Default
     (Action : Action_Id)
      return Standard.Boolean is
     (A11y.Actions.Is_Idempotent_By_Default (Action));

   function Failure_For
     (Item : Action_Precondition)
      return A11y.Results.Status_Code is
     (A11y.Actions.Failure_For (Item));

end A11y.Actions.Classification;
