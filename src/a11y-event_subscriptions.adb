with A11y.Event_Subscriptions.Classification;

package body A11y.Event_Subscriptions is
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;

   function Is_Valid (Id : Subscription_Id) return Boolean is
     (Id /= No_Subscription)
   with SPARK_Mode => On;

   function With_Event
     (Base : Event_Filter;
      Kind : A11y.Events.Event_Kind)
      return Event_Filter
   with SPARK_Mode => On
   is
      Result : Event_Filter := Base;
   begin
      Result (Kind) := True;
      return Result;
   end With_Event;

   function Has_Events (Filter : Event_Filter) return Boolean is
     (for some Kind in A11y.Events.Event_Kind => Filter (Kind))
   with SPARK_Mode => On;

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (A11y.Event_Subscriptions.Classification.Valid_Capacity (Capacity))
   with SPARK_Mode => On;

   function Can_Set_Capacity
     (Active_Count : Natural;
      Capacity     : Natural)
      return Boolean is
     (A11y.Event_Subscriptions.Classification.Can_Set_Capacity
        (Active_Count, Capacity))
   with SPARK_Mode => On;

   function Has_Enabled_Event (Filter : Event_Filter) return Boolean is
     (A11y.Event_Subscriptions.Classification.Has_Enabled_Event (Filter))
   with SPARK_Mode => On;

   function Accepts
     (Filter : Event_Filter;
      Kind   : A11y.Events.Event_Kind)
      return Boolean is
     (A11y.Event_Subscriptions.Classification.Accepts (Filter, Kind))
   with SPARK_Mode => On;

   protected body Subscription_Set is

      function Is_Destroyed
        (Node : A11y.Node_Ids.Node_Id)
         return Boolean
      is
         Index : constant Natural := A11y.Node_Ids.To_Natural (Node);
      begin
         return Index in Destroyed'Range and then Destroyed (Index);
      end Is_Destroyed;

      procedure Mark_Destroyed (Node : A11y.Node_Ids.Node_Id) is
         Index : constant Natural := A11y.Node_Ids.To_Natural (Node);
      begin
         if Index in Destroyed'Range then
            Destroyed (Index) := True;
         end if;
      end Mark_Destroyed;

      procedure Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result)
      is
         Validation : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Validation) then
            Result := Validation;
            return;
         end if;

         Set_Capacity
           (Natural
              (A11y.Resource_Limits.Value
                 (Limits, A11y.Resource_Limits.Outstanding_Callbacks)),
            Result);
      end Configure;

      procedure Set_Capacity
        (Capacity : Natural;
         Result   : out A11y.Results.Result)
      is
      begin
         if Can_Set_Capacity (Active_Count, Capacity)
         then
            Limit := Capacity;
            Result := A11y.Results.Ok;
         elsif Valid_Capacity (Capacity)
         then
            Result := (Status => A11y.Results.Invalid_State);
         else
            Result := (Status => A11y.Results.Invalid_Argument);
         end if;
      end Set_Capacity;

      procedure Subscribe
        (Filter : Event_Filter;
         Id     : out Subscription_Id;
         Result : out A11y.Results.Result)
      is
         Slot : Natural := 0;
      begin
         Id := No_Subscription;
         if not Has_Events (Filter) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return;
         end if;

         if Active_Count >= Limit then
            Result := (Status => A11y.Results.Resource_Limit);
            return;
         end if;

         for Index in Items'Range loop
            if not Items (Index).Active then
               Slot := Index;
               exit;
            end if;
         end loop;

         if Slot = 0 then
            Result := (Status => A11y.Results.Resource_Limit);
            return;
         end if;

         Id := Subscription_Id (Next_Id);
         if Next_Id < Natural'Last then
            Next_Id := Next_Id + 1;
         end if;

         Items (Slot) :=
           (Id        => Id,
            Active    => True,
            Filter    => Filter,
            Delivered => 0,
            Dropped   => 0);
         Result := A11y.Results.Ok;
      end Subscribe;

      procedure Unsubscribe
        (Id     : Subscription_Id;
         Result : out A11y.Results.Result)
      is
      begin
         if not Is_Valid (Id) then
            Result := (Status => A11y.Results.Invalid_Argument);
            return;
         end if;

         for Index in Items'Range loop
            if Items (Index).Active and then Items (Index).Id = Id then
               Items (Index).Active := False;
               Result := A11y.Results.Ok;
               return;
            end if;
         end loop;

         Result := (Status => A11y.Results.Node_Unavailable);
      end Unsubscribe;

      procedure Deliver
        (Event     : A11y.Events.Event;
         Delivered : out Natural;
         Result    : out A11y.Results.Result)
      is
      begin
         Delivered := 0;
         Result := A11y.Events.Validate_Event (Event);
         if A11y.Results.Failed (Result) then
            return;
         elsif Is_Destroyed (Event.Source) then
            Result :=
              (Status =>
                 (if Event.Kind = A11y.Events.Node_Destroyed
                  then A11y.Results.Invalid_State
                  else A11y.Results.Node_Unavailable));
            return;
         end if;

         for Index in Items'Range loop
            if Items (Index).Active then
               if Accepts (Items (Index).Filter, Event.Kind)
               then
                  Items (Index).Delivered := Items (Index).Delivered + 1;
                  Delivered := Delivered + 1;
               else
                  Items (Index).Dropped := Items (Index).Dropped + 1;
               end if;
            end if;
         end loop;

         if Event.Kind = A11y.Events.Node_Destroyed then
            Mark_Destroyed (Event.Source);
         end if;
         Result := A11y.Results.Ok;
      end Deliver;

      function Active_Count return Natural is
         Count : Natural := 0;
      begin
         for Item of Items loop
            if Item.Active then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Active_Count;

      function Capacity return Natural is
        (Limit);

      function Snapshot return Subscriber_Snapshot is
        (Items);

   end Subscription_Set;

end A11y.Event_Subscriptions;
