package A11y.Native_Callbacks.Classification is
   pragma SPARK_Mode (On);

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      Global => null,
      Post =>
        Valid_Capacity'Result = (Capacity in 1 .. Max_Callbacks);

   function Can_Set_Limit
     (Outstanding_Count  : Natural;
      Highest_Active     : Natural;
      Capacity           : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Set_Limit'Result =
          (Valid_Capacity (Capacity)
           and then Capacity >= Outstanding_Count
           and then Capacity >= Highest_Active);

   function Can_Begin_Callback
     (Accepting          : Boolean;
      Outstanding_Count  : Natural;
      Capacity           : Natural;
      Next_Generation    : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Begin_Callback'Result =
          (Accepting
           and then Outstanding_Count < Capacity
           and then Next_Generation < Natural'Last);

   function Can_Advance_Gate_Generation
     (Generation : Natural)
      return Boolean
   with
      Global => null,
      Post => Can_Advance_Gate_Generation'Result =
        (Generation < Natural'Last);

   function Should_Advance_On_Shutdown
     (Accepting : Boolean)
      return Boolean
   with
      Global => null,
      Post => Should_Advance_On_Shutdown'Result = Accepting;

   function Can_Reset (Outstanding_Count : Natural) return Boolean
   with
      Global => null,
      Post => Can_Reset'Result = (Outstanding_Count = 0);

   function Is_Drained (Outstanding_Count : Natural) return Boolean
   with
      Global => null,
      Post => Is_Drained'Result = (Outstanding_Count = 0);

end A11y.Native_Callbacks.Classification;
