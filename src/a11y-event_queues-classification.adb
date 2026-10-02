package body A11y.Event_Queues.Classification is
   pragma SPARK_Mode (On);

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (Capacity in 1 .. Max_Queued_Events);

   function Can_Set_Capacity
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean is
     (Valid_Capacity (Capacity) and then Capacity >= Current_Length);

   function Available_Slots
     (Current_Length : Natural;
      Capacity       : Natural)
      return Natural is
     (if Current_Length >= Capacity then 0 else Capacity - Current_Length);

   function Can_Coalesce
     (Previous_Source : A11y.Node_Ids.Node_Id;
      New_Source      : A11y.Node_Ids.Node_Id;
      Previous_Kind   : A11y.Events.Event_Kind;
      New_Kind        : A11y.Events.Event_Kind)
     return Boolean is
     (Previous_Source = New_Source
      and then Previous_Kind = New_Kind
      and then A11y.Events.Is_Coalescible (New_Kind));

   function Rejects_Destroyed_Source
     (Already_Destroyed : Boolean;
      Kind              : A11y.Events.Event_Kind)
      return Boolean is
     (Already_Destroyed);

   function Destroyed_Source_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code is
     (if Kind = A11y.Events.Node_Destroyed
      then A11y.Results.Invalid_State
      else A11y.Results.Node_Unavailable);

   function Can_Append
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean is
     (Valid_Capacity (Capacity) and then Current_Length < Capacity);

   function Overflows_On_Append
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean is
     (Current_Length >= Capacity);

   function Can_Advance_Sequence
     (Sequence : A11y.Event_Sequence)
      return Boolean is
     (Sequence < A11y.Event_Sequence'Last);

end A11y.Event_Queues.Classification;
