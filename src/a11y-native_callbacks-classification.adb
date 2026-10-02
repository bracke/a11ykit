package body A11y.Native_Callbacks.Classification is
   pragma SPARK_Mode (On);

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (Capacity in 1 .. Max_Callbacks);

   function Can_Set_Limit
     (Outstanding_Count  : Natural;
      Highest_Active     : Natural;
      Capacity           : Natural)
      return Boolean is
     (Valid_Capacity (Capacity)
      and then Capacity >= Outstanding_Count
      and then Capacity >= Highest_Active);

   function Can_Begin_Callback
     (Accepting          : Boolean;
      Outstanding_Count  : Natural;
      Capacity           : Natural;
      Next_Generation    : Natural)
     return Boolean is
     (Accepting
      and then Outstanding_Count < Capacity
      and then Next_Generation < Natural'Last);

   function Can_Advance_Gate_Generation
     (Generation : Natural)
      return Boolean is
     (Generation < Natural'Last);

   function Should_Advance_On_Shutdown
     (Accepting : Boolean)
      return Boolean is
     (Accepting);

   function Can_Reset (Outstanding_Count : Natural) return Boolean is
     (Outstanding_Count = 0);

   function Is_Drained (Outstanding_Count : Natural) return Boolean is
     (Outstanding_Count = 0);

end A11y.Native_Callbacks.Classification;
