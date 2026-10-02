with Ada.Calendar;

with A11y;
with A11y.Event_Subscriptions;
with A11y.Event_Subscriptions.Classification;
with A11y.Events;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Event_Subscription_Tests is
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Subscriptions : A11y.Event_Subscriptions.Subscription_Set;
      Focus_Filter : A11y.Event_Subscriptions.Event_Filter :=
        A11y.Event_Subscriptions.No_Events;
      Text_Filter : A11y.Event_Subscriptions.Event_Filter :=
        A11y.Event_Subscriptions.No_Events;
      Focus_Sub : A11y.Event_Subscriptions.Subscription_Id;
      Text_Sub : A11y.Event_Subscriptions.Subscription_Id;
      Extra_Sub : A11y.Event_Subscriptions.Subscription_Id;
      Result : A11y.Results.Result;
      Delivered : Natural;
      Snapshot : A11y.Event_Subscriptions.Subscriber_Snapshot;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Event : A11y.Events.Event :=
        (Sequence  => 50,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (15),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
   begin
      Focus_Filter := A11y.Event_Subscriptions.With_Event
        (Focus_Filter, A11y.Events.Focus_Changed);
      Text_Filter := A11y.Event_Subscriptions.With_Event
        (Text_Filter, A11y.Events.Text_Inserted);
      Check
        (not A11y.Event_Subscriptions.Has_Events
           (A11y.Event_Subscriptions.No_Events)
         and then A11y.Event_Subscriptions.Has_Events (Focus_Filter),
         "event subscription filters distinguish empty and active filters");
      Check
        (A11y.Event_Subscriptions.Classification.Valid_Capacity
           (A11y.Event_Subscriptions.Max_Subscriptions)
         and then not A11y.Event_Subscriptions.Classification.Valid_Capacity
           (0)
         and then A11y.Event_Subscriptions.Classification.Can_Set_Capacity
           (0, 1)
         and then not A11y.Event_Subscriptions.Classification.Can_Set_Capacity
           (2, 1)
         and then A11y.Event_Subscriptions.Classification.Has_Enabled_Event
           (Focus_Filter)
         and then not A11y.Event_Subscriptions.Classification.Has_Enabled_Event
           (A11y.Event_Subscriptions.No_Events),
         "event subscription classification validates capacity and active filters");
      Check
        (A11y.Event_Subscriptions.Classification.Accepts
           (Focus_Filter, A11y.Events.Focus_Changed)
         and then not A11y.Event_Subscriptions.Classification.Accepts
           (Focus_Filter, A11y.Events.Text_Inserted),
         "event subscription classification validates event filter matching");
      Check
        (Subscriptions.Capacity = A11y.Event_Subscriptions.Max_Subscriptions,
         "event subscriptions default to the standard subscriber capacity");
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Outstanding_Callbacks,
         2,
         Result);
      Subscriptions.Configure (Limits, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Subscriptions.Capacity = 2,
         "event subscriptions accept resource-limit capacity");

      Subscriptions.Subscribe
        (A11y.Event_Subscriptions.No_Events, Extra_Sub, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then not A11y.Event_Subscriptions.Is_Valid (Extra_Sub)
         and then Subscriptions.Active_Count = 0,
         "event subscriptions reject empty filters without allocating ids");

      Subscriptions.Subscribe (Focus_Filter, Focus_Sub, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Event_Subscriptions.Is_Valid (Focus_Sub),
         "event subscriptions create stable subscription identities");

      Subscriptions.Subscribe (Text_Filter, Text_Sub, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Subscriptions.Active_Count = 2,
         "event subscriptions track active subscribers");

      Subscriptions.Deliver (Event, Delivered, Result);
      Snapshot := Subscriptions.Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then Delivered = 1
         and then Snapshot (1).Delivered = 1
         and then Snapshot (2).Dropped = 1,
         "event subscriptions deliver matching events and count filtered drops");

      Event.Kind := A11y.Events.Text_Inserted;
      Event.Sequence := 51;
      Subscriptions.Deliver (Event, Delivered, Result);
      Snapshot := Subscriptions.Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then Delivered = 1
         and then Snapshot (2).Delivered = 1,
         "event subscriptions deliver text events to text subscribers");

      Subscriptions.Unsubscribe (Focus_Sub, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Subscriptions.Active_Count = 1,
         "event subscriptions unsubscribe deterministically");

      Subscriptions.Set_Capacity (1, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Subscriptions.Capacity = 1,
         "event subscriptions shrink to active subscriber count");
      Subscriptions.Set_Capacity (0, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event subscriptions reject zero capacity");
      Subscriptions.Set_Capacity
        (A11y.Event_Subscriptions.Max_Subscriptions + 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event subscriptions reject impossible capacity");

      Event.Sequence := A11y.No_Event;
      Subscriptions.Deliver (Event, Delivered, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event subscriptions reject unsequenced events");

      Event.Sequence := 52;
      Event.Source := A11y.Node_Ids.No_Node;
      Subscriptions.Deliver (Event, Delivered, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Delivered = 0,
         "event subscriptions reject unavailable event sources");

      declare
         Final_Subscriptions : A11y.Event_Subscriptions.Subscription_Set;
         Final_Sub : A11y.Event_Subscriptions.Subscription_Id;
         Final_Node : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (616);
         Final_Event : A11y.Events.Event :=
           (Sequence  => 90,
            Timestamp => Ada.Calendar.Clock,
            Source    => Final_Node,
            Kind      => A11y.Events.Node_Destroyed,
            Revision  => 1);
      begin
         Final_Subscriptions.Subscribe
           (A11y.Event_Subscriptions.All_Events, Final_Sub, Result);
         Final_Subscriptions.Deliver (Final_Event, Delivered, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Delivered = 1,
            "event subscriptions record final node-destroyed delivery");

         Final_Event.Sequence := 91;
         Final_Subscriptions.Deliver (Final_Event, Delivered, Result);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Delivered = 0,
            "event subscriptions reject duplicate node-destroyed delivery");

         Final_Event.Sequence := 92;
         Final_Event.Kind := A11y.Events.Property_Changed;
         Final_Subscriptions.Deliver (Final_Event, Delivered, Result);
         Check
           (Result.Status = A11y.Results.Node_Unavailable
            and then Delivered = 0,
            "event subscriptions reject delivery after node-destroyed");
      end;

      Event.Source := A11y.Node_Ids.From_Natural (15);

      Subscriptions.Subscribe
        (A11y.Event_Subscriptions.All_Events, Extra_Sub, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit,
         "event subscriptions enforce bounded subscriber counts");
      Subscriptions.Set_Capacity (2, Result);
      Subscriptions.Subscribe
        (A11y.Event_Subscriptions.All_Events, Extra_Sub, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Subscriptions.Active_Count = 2,
         "event subscriptions grow configured capacity");
      Subscriptions.Set_Capacity (1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "event subscriptions reject shrinking below active subscribers");
      Limits.Limits (A11y.Resource_Limits.Outstanding_Callbacks) := 0;
      Subscriptions.Configure (Limits, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "event subscriptions reject invalid resource-limit configurations");
   end Run;
end A11y_Event_Subscription_Tests;
