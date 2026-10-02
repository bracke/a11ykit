with Ada.Calendar;

with A11y.Events;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Event_Queues is
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   Max_Queued_Events : constant Natural := 1_024;

   type Event_Queue is private;

   function Length (Self : Event_Queue) return Natural;
   function Overflowed (Self : Event_Queue) return Boolean;
   function Capacity (Self : Event_Queue) return Natural;
   function Available_Capacity (Self : Event_Queue) return Natural;

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Valid_Capacity'Result =
          (Capacity in 1 .. Max_Queued_Events);

   function Can_Set_Capacity
     (Current_Length : Natural;
      Capacity       : Natural)
      return Boolean
   with
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
      Global => null,
      Post =>
        Rejects_Destroyed_Source'Result = Already_Destroyed;

   function Destroyed_Source_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code
   with
      SPARK_Mode => On,
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
      SPARK_Mode => On,
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
      SPARK_Mode => On,
      Global => null,
      Post =>
        Overflows_On_Append'Result =
          (Current_Length >= Capacity);

   function Can_Advance_Sequence
     (Sequence : A11y.Event_Sequence)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Advance_Sequence'Result =
          (Sequence < A11y.Event_Sequence'Last);

   procedure Configure
     (Self   : in out Event_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Can_Configure
     (Self   : Event_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Set_Capacity
     (Self     : in out Event_Queue;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Enqueue
     (Self     : in out Event_Queue;
      Source   : A11y.Node_Ids.Node_Id;
      Kind     : A11y.Events.Event_Kind;
      Revision : A11y.Semantic_Revision;
      Event    : out A11y.Events.Event;
      Result   : out A11y.Results.Result);

   procedure Dequeue
     (Self   : in out Event_Queue;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result);

   procedure Peek
     (Self   : Event_Queue;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result);

   procedure Acknowledge
     (Self     : in out Event_Queue;
      Sequence : A11y.Event_Sequence;
      Result   : out A11y.Results.Result);

   procedure Clear (Self : in out Event_Queue);

private
   type Destroyed_Node_Set is
     array (Natural range 0 .. A11y.Node_Ids.Max_Node_Ids) of Boolean;

   type Event_Queue is record
      Next_Sequence : A11y.Event_Sequence := 1;
      Last_Timestamp : A11y.Timestamp := Ada.Calendar.Time_Of (1901, 1, 1);
      Items         : A11y.Events.Event_Vectors.Vector;
      Had_Overflow  : Boolean := False;
      Limit         : Natural := Max_Queued_Events;
      Destroyed     : Destroyed_Node_Set := [others => False];
   end record;
end A11y.Event_Queues;
