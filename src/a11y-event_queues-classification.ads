with A11y.Events;
with A11y.Node_Ids;
with A11y.Results;

package A11y.Event_Queues.Classification is
   pragma SPARK_Mode (On);
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      Global => null,
      Post =>
        Valid_Capacity'Result =
          (Capacity in 1 .. Max_Queued_Events);

   function Can_Set_Capacity
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Set_Capacity'Result =
          (Valid_Capacity (Capacity)
           and then Capacity >= Current_Length);

   function Available_Slots
     (Current_Length : Natural;
      Capacity       : Natural)
      return Natural
   with
      Global => null,
      Post =>
        Available_Slots'Result =
          (if Current_Length >= Capacity
           then 0
           else Capacity - Current_Length);

   function Can_Coalesce
     (Previous_Source : A11y.Node_Ids.Node_Id;
      New_Source      : A11y.Node_Ids.Node_Id;
      Previous_Kind   : A11y.Events.Event_Kind;
      New_Kind        : A11y.Events.Event_Kind)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Coalesce'Result =
          (Previous_Source = New_Source
           and then Previous_Kind = New_Kind
           and then A11y.Events.Is_Coalescible (New_Kind));

   function Rejects_Destroyed_Source
     (Already_Destroyed : Boolean;
      Kind              : A11y.Events.Event_Kind)
      return Boolean
   with
      Global => null,
      Post =>
        Rejects_Destroyed_Source'Result = Already_Destroyed;

   function Destroyed_Source_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code
   with
      Global => null,
      Post =>
        Destroyed_Source_Status'Result =
          (if Kind = A11y.Events.Node_Destroyed
           then A11y.Results.Invalid_State
           else A11y.Results.Node_Unavailable);

   function Can_Append
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Append'Result =
          (Valid_Capacity (Capacity)
           and then Current_Length < Capacity);

   function Overflows_On_Append
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean
   with
      Global => null,
      Post =>
        Overflows_On_Append'Result =
          (Current_Length >= Capacity);

   function Can_Advance_Sequence
     (Sequence : A11y.Event_Sequence)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Advance_Sequence'Result =
          (Sequence < A11y.Event_Sequence'Last);

end A11y.Event_Queues.Classification;
