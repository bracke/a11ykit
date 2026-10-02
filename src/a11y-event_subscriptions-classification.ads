with A11y.Events;

package A11y.Event_Subscriptions.Classification is
   pragma SPARK_Mode (On);

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      Global => null,
      Post =>
        Valid_Capacity'Result =
          (Capacity in 1 .. Max_Subscriptions);

   function Can_Set_Capacity
     (Active_Count : Natural;
      Capacity     : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Set_Capacity'Result =
          (Valid_Capacity (Capacity)
           and then Capacity >= Active_Count);

   function Has_Enabled_Event (Filter : Event_Filter) return Boolean
   with
      Global => null,
      Post =>
        Has_Enabled_Event'Result =
          (for some Kind in A11y.Events.Event_Kind => Filter (Kind));

   function Accepts
     (Filter : Event_Filter;
      Kind   : A11y.Events.Event_Kind)
      return Boolean
   with
      Global => null,
      Post =>
        Accepts'Result =
          Filter (Kind);

end A11y.Event_Subscriptions.Classification;
