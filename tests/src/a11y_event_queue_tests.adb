with A11y;
with A11y.Event_Queues;
with A11y.Event_Queues.Classification;
with A11y.Events;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Event_Queue_Tests is
   use type A11y.Event_Sequence;
   use type A11y.Timestamp;
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Queue : A11y.Event_Queues.Event_Queue;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      Node : constant A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.From_Natural (10);
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      Check
        (A11y.Event_Queues.Capacity (Queue)
         = A11y.Event_Queues.Max_Queued_Events,
         "event queue defaults to the standard event capacity");
      Check
        (A11y.Event_Queues.Classification.Valid_Capacity
           (A11y.Event_Queues.Max_Queued_Events)
         and then not A11y.Event_Queues.Classification.Valid_Capacity (0)
         and then A11y.Event_Queues.Classification.Can_Set_Capacity (0, 1)
         and then not A11y.Event_Queues.Classification.Can_Set_Capacity
           (2, 1)
         and then A11y.Event_Queues.Classification.Available_Slots
           (2, 5) = 3
         and then A11y.Event_Queues.Classification.Available_Slots
           (5, 5) = 0,
         "event queue classification validates capacity policy");
      Check
        (A11y.Event_Queues.Classification.Can_Coalesce
           (Node, Node, A11y.Events.Bounds_Changed,
            A11y.Events.Bounds_Changed)
         and then not A11y.Event_Queues.Classification.Can_Coalesce
           (Node, Node, A11y.Events.Text_Inserted,
            A11y.Events.Text_Inserted)
         and then not A11y.Event_Queues.Classification.Can_Coalesce
           (Node, A11y.Node_Ids.From_Natural (11),
            A11y.Events.Bounds_Changed, A11y.Events.Bounds_Changed),
         "event queue classification validates adjacent coalescing policy");
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Bounds_Changed, 1, Event, Result);
      Check (A11y.Results.Succeeded (Result), "event queue accepts first event");
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Bounds_Changed, 2, Event, Result);
      Check
        (A11y.Event_Queues.Length (Queue) = 1,
         "event queue coalesces repeated safe bounds events");
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Value_Changed, 3, Event, Result);
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Value_Changed, 4, Event, Result);
      Check
        (A11y.Event_Queues.Length (Queue) = 2,
         "event queue coalesces repeated safe value events");
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Property_Changed, 5, Event, Result);
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Property_Changed, 6, Event, Result);
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.State_Changed, 7, Event, Result);
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.State_Changed, 8, Event, Result);
      Check
        (A11y.Event_Queues.Length (Queue) = 6,
         "event queue preserves payload-sensitive property and state events");
      Check
        (A11y.Event_Queues.Available_Capacity (Queue)
         = A11y.Event_Queues.Max_Queued_Events - 6,
         "event queue reports remaining bounded capacity");
      A11y.Event_Queues.Set_Capacity (Queue, 6, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Event_Queues.Capacity (Queue) = 6,
         "event queue accepts explicit capacity matching current length");
      A11y.Event_Queues.Set_Capacity (Queue, 0, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event queue rejects zero capacity");
      A11y.Event_Queues.Set_Capacity
        (Queue, A11y.Event_Queues.Max_Queued_Events + 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event queue rejects impossible capacity");
      A11y.Event_Queues.Set_Capacity (Queue, 8, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Event_Queues.Available_Capacity (Queue) = 2,
         "event queue grows configured capacity");

      A11y.Event_Queues.Enqueue
        (Queue,
         A11y.Node_Ids.No_Node,
         A11y.Events.Focus_Changed,
         3,
         Event,
         Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then A11y.Event_Queues.Length (Queue) = 6
         and then Event.Sequence = A11y.No_Event,
         "event queue rejects invalid sources before enqueue");

      declare
         Destroyed_Queue : A11y.Event_Queues.Event_Queue;
         Destroyed_Node : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (444);
      begin
         A11y.Event_Queues.Enqueue
           (Destroyed_Queue,
            Destroyed_Node,
            A11y.Events.Node_Destroyed,
            1,
            Event,
            Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Event.Kind = A11y.Events.Node_Destroyed
            and then Event.Sequence /= A11y.No_Event,
            "event queue records final node-destroyed events");

         A11y.Event_Queues.Enqueue
           (Destroyed_Queue,
            Destroyed_Node,
            A11y.Events.Node_Destroyed,
            2,
            Event,
            Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Event.Sequence = A11y.No_Event
            and then A11y.Event_Queues.Length (Destroyed_Queue) = 1,
            "event queue rejects duplicate node-destroyed events");

         A11y.Event_Queues.Enqueue
           (Destroyed_Queue,
            Destroyed_Node,
            A11y.Events.Property_Changed,
            3,
            Event,
            Result);
         Check
           (Result.Status = A11y.Results.Node_Unavailable
            and then Event.Sequence = A11y.No_Event
            and then A11y.Event_Queues.Length (Destroyed_Queue) = 1,
            "event queue rejects events after node-destroyed");

         A11y.Event_Queues.Clear (Destroyed_Queue);
         A11y.Event_Queues.Enqueue
           (Destroyed_Queue,
            Destroyed_Node,
            A11y.Events.Property_Changed,
            4,
            Event,
            Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then A11y.Event_Queues.Length (Destroyed_Queue) = 1,
            "event queue clear resets destroyed-node tracking");
      end;

      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Text_Inserted, 3, Event, Result);
      A11y.Event_Queues.Enqueue
        (Queue, Node, A11y.Events.Text_Inserted, 4, Event, Result);
      Check
        (A11y.Event_Queues.Length (Queue) = 8,
         "event queue preserves distinct text insertion events");
      A11y.Event_Queues.Set_Capacity (Queue, 2, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "event queue rejects shrinking below queued events");

      A11y.Event_Queues.Dequeue (Queue, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Bounds_Changed,
         "event queue dequeues in semantic order");

      A11y.Event_Queues.Clear (Queue);
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         2,
         Result);
      A11y.Event_Queues.Configure (Queue, Limits, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Event_Queues.Capacity (Queue) = 2,
         "event queue accepts resource-limit capacity");
      for Index in 1 .. 2 loop
         A11y.Event_Queues.Enqueue
           (Queue,
            A11y.Node_Ids.From_Natural (Index),
            A11y.Events.Focus_Changed,
            A11y.Semantic_Revision (Index),
            Event,
            Result);
      end loop;
      A11y.Event_Queues.Enqueue
        (Queue,
         A11y.Node_Ids.From_Natural (3),
         A11y.Events.Focus_Changed,
         3,
         Event,
         Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then A11y.Event_Queues.Length (Queue) = 2
         and then Event.Sequence = A11y.No_Event
         and then A11y.Event_Queues.Overflowed (Queue),
         "event queue reports configured bounded overflow");

      declare
         First_Sequence : A11y.Event_Sequence;
      begin
         A11y.Event_Queues.Dequeue (Queue, Event, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "event queue can drain after configured overflow");
         First_Sequence := Event.Sequence;
         A11y.Event_Queues.Enqueue
           (Queue,
            A11y.Node_Ids.From_Natural (4),
            A11y.Events.Focus_Changed,
            4,
            Event,
            Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Event.Sequence = First_Sequence + 2,
            "event queue does not consume a sequence for overflow");
      end;

      A11y.Event_Queues.Clear (Queue);
      A11y.Event_Queues.Set_Capacity (Queue, 3, Result);
      A11y.Event_Queues.Enqueue
        (Queue,
         A11y.Node_Ids.From_Natural (20),
         A11y.Events.Focus_Changed,
         20,
         Event,
         Result);
      A11y.Event_Queues.Enqueue
        (Queue,
         A11y.Node_Ids.From_Natural (21),
         A11y.Events.Property_Changed,
         21,
         Event,
         Result);
      declare
         First_Timestamp : A11y.Timestamp;
      begin
         A11y.Event_Queues.Peek (Queue, Event, Result);
         First_Timestamp := Event.Timestamp;
         Check
           (A11y.Results.Succeeded (Result)
            and then Event.Source = A11y.Node_Ids.From_Natural (20),
            "event queue peeks the front event without consuming it");
         A11y.Event_Queues.Dequeue (Queue, Event, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Event.Timestamp = First_Timestamp,
            "event queue preserves timestamp while dequeuing front event");
         A11y.Event_Queues.Peek (Queue, Event, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then First_Timestamp <= Event.Timestamp,
            "event queue assigns nondecreasing committed timestamps");
      end;
      A11y.Event_Queues.Acknowledge
        (Queue, Event.Sequence + 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Event_Queues.Length (Queue) = 1,
         "event queue rejects out-of-order acknowledgements");
      A11y.Event_Queues.Acknowledge (Queue, Event.Sequence, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Event_Queues.Length (Queue) = 0,
         "event queue acknowledges exactly the front event");
      A11y.Event_Queues.Dequeue (Queue, Event, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "event queue reports empty after acknowledgement drains later event");

      Limits.Limits (A11y.Resource_Limits.Event_Queue_Size) := 0;
      A11y.Event_Queues.Configure (Queue, Limits, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event queue rejects invalid resource-limit configurations");
   end Run;
end A11y_Event_Queue_Tests;
