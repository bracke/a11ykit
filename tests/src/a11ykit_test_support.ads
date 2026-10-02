package A11ykit_Test_Support is
   procedure Raise_Main_Stack_Limit;
   procedure Check (Condition : Boolean; Message : String);
   function Failure_Count return Natural;
   procedure Finish;
end A11ykit_Test_Support;
