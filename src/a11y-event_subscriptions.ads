with A11y.Events;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Event_Subscriptions is

   Max_Subscriptions : constant Natural := 32;

   type Subscription_Id is private;
   No_Subscription : constant Subscription_Id;

   type Event_Filter is array (A11y.Events.Event_Kind) of Boolean;

   All_Events : constant Event_Filter := [others => True];
   No_Events  : constant Event_Filter := [others => False];

   type Subscriber is record
      Id       : Subscription_Id := No_Subscription;
      Active   : Boolean := False;
      Filter   : Event_Filter := No_Events;
      Delivered : Natural := 0;
      Dropped   : Natural := 0;
   end record;

   type Subscriber_Snapshot is array
     (Positive range 1 .. Max_Subscriptions) of Subscriber;

   type Destroyed_Node_Set is
     array (Natural range 0 .. A11y.Node_Ids.Max_Node_Ids) of Boolean;

   protected type Subscription_Set is
      procedure Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result);

      procedure Set_Capacity
        (Capacity : Natural;
         Result   : out A11y.Results.Result);

      procedure Subscribe
        (Filter : Event_Filter;
         Id     : out Subscription_Id;
         Result : out A11y.Results.Result);

      procedure Unsubscribe
        (Id     : Subscription_Id;
         Result : out A11y.Results.Result);

      procedure Deliver
        (Event     : A11y.Events.Event;
         Delivered : out Natural;
         Result    : out A11y.Results.Result);

      function Active_Count return Natural;
      function Capacity return Natural;
      function Snapshot return Subscriber_Snapshot;
   private
      Next_Id : Natural := 1;
      Limit   : Natural := Max_Subscriptions;
      Items   : Subscriber_Snapshot;
      Destroyed : Destroyed_Node_Set := [others => False];
   end Subscription_Set;

   function Is_Valid (Id : Subscription_Id) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Valid'Result = (Id /= No_Subscription);
   function With_Event
     (Base : Event_Filter;
      Kind : A11y.Events.Event_Kind)
      return Event_Filter
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        With_Event'Result (Kind)
        and then
          (for all Other in A11y.Events.Event_Kind =>
             (if A11y.Events."/=" (Other, Kind)
              then With_Event'Result (Other) = Base (Other)));
   function Has_Events (Filter : Event_Filter) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Has_Events'Result =
          (for some Kind in A11y.Events.Event_Kind => Filter (Kind));

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Valid_Capacity'Result =
          (Capacity in 1 .. Max_Subscriptions);

   function Can_Set_Capacity
     (Active_Count : Natural;
      Capacity     : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Set_Capacity'Result =
          (Valid_Capacity (Capacity)
           and then Capacity >= Active_Count);

   function Has_Enabled_Event (Filter : Event_Filter) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Has_Enabled_Event'Result =
          (for some Kind in A11y.Events.Event_Kind => Filter (Kind));

   function Accepts
     (Filter : Event_Filter;
      Kind   : A11y.Events.Event_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Accepts'Result = Filter (Kind);

private
   type Subscription_Id is new Natural;
   No_Subscription : constant Subscription_Id := 0;

end A11y.Event_Subscriptions;
