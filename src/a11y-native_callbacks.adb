with A11y.Native_Callbacks.Classification;

package body A11y.Native_Callbacks is

   function Is_Valid (Token : Callback_Token) return Boolean
   with SPARK_Mode => On
   is
   begin
      return Token /= No_Token;
   end Is_Valid;

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (A11y.Native_Callbacks.Classification.Valid_Capacity (Capacity))
   with SPARK_Mode => On;

   function Can_Set_Limit
     (Outstanding_Count  : Natural;
      Highest_Active     : Natural;
      Capacity           : Natural)
      return Boolean is
     (A11y.Native_Callbacks.Classification.Can_Set_Limit
        (Outstanding_Count, Highest_Active, Capacity))
   with SPARK_Mode => On;

   function Can_Begin_Callback
     (Accepting          : Boolean;
      Outstanding_Count  : Natural;
      Capacity           : Natural;
      Next_Generation    : Natural)
     return Boolean is
     (A11y.Native_Callbacks.Classification.Can_Begin_Callback
        (Accepting, Outstanding_Count, Capacity, Next_Generation))
   with SPARK_Mode => On;

   function Can_Advance_Gate_Generation
     (Generation : Natural)
      return Boolean is
     (A11y.Native_Callbacks.Classification.Can_Advance_Gate_Generation
        (Generation))
   with SPARK_Mode => On;

   function Should_Advance_On_Shutdown
     (Accepting : Boolean)
      return Boolean is
     (A11y.Native_Callbacks.Classification.Should_Advance_On_Shutdown
        (Accepting))
   with SPARK_Mode => On;

   function Can_Reset (Outstanding_Count : Natural) return Boolean is
     (A11y.Native_Callbacks.Classification.Can_Reset (Outstanding_Count))
   with SPARK_Mode => On;

   function Is_Drained (Outstanding_Count : Natural) return Boolean is
     (A11y.Native_Callbacks.Classification.Is_Drained (Outstanding_Count))
   with SPARK_Mode => On;

   protected body Callback_Gate is

      procedure Advance_Gate_Generation is
      begin
         if Can_Advance_Gate_Generation (Gate_Generation)
         then
            Gate_Generation := Gate_Generation + 1;
         end if;
      end Advance_Gate_Generation;

      function Highest_Active_Slot return Natural is
         Highest : Natural := 0;
      begin
         for Index in Active_Tokens'Range loop
            if Is_Valid (Active_Tokens (Index)) then
               Highest := Index;
            end if;
         end loop;
         return Highest;
      end Highest_Active_Slot;

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

         Set_Limit
           (Natural
              (A11y.Resource_Limits.Value
                 (Limits, A11y.Resource_Limits.Outstanding_Callbacks)),
            Result);
      end Configure;

      procedure Set_Limit
        (Capacity : Natural;
         Result   : out A11y.Results.Result)
      is
      begin
         if not Valid_Capacity
           (Capacity)
         then
            Result := (Status => A11y.Results.Invalid_Argument);
         elsif not Can_Set_Limit
           (Outstanding,
            Highest_Active_Slot,
            Capacity)
         then
            Result := (Status => A11y.Results.Invalid_State);
         else
            Limit := Capacity;
            Result := A11y.Results.Ok;
         end if;
      end Set_Limit;

      procedure Begin_Callback
        (Token  : out Callback_Token;
         Result : out A11y.Results.Result)
      is
         Slot : Natural := 0;
      begin
         Token := No_Token;
         if not Accepting then
            Rejected_Shutdown := Rejected_Shutdown + 1;
            Result := (Status => A11y.Results.Shutting_Down);
         elsif not Can_Begin_Callback
           (Accepting,
            Outstanding,
            Limit,
            Next_Generation)
         then
            Rejected_Limit := Rejected_Limit + 1;
            Result := (Status => A11y.Results.Resource_Limit);
         else
            for Index in 1 .. Limit loop
               if not Is_Valid (Active_Tokens (Index)) then
                  Slot := Index;
                  exit;
               end if;
            end loop;

            if Slot = 0 then
               Rejected_Limit := Rejected_Limit + 1;
               Result := (Status => A11y.Results.Resource_Limit);
               return;
            end if;

            Token :=
              (Slot       => Slot,
               Generation => Next_Generation);
            Next_Generation := Next_Generation + 1;
            Advance_Gate_Generation;
            Outstanding := Outstanding + 1;
            Active_Tokens (Slot) := Token;
            Accepted := Accepted + 1;
            Result := A11y.Results.Ok;
         end if;
      exception
         when others =>
            Token := No_Token;
            Result := (Status => A11y.Results.Internal_Error);
      end Begin_Callback;

      procedure End_Callback
        (Token  : in out Callback_Token;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := Token.Slot;
      begin
         if not Is_Valid (Token)
           or else Slot not in Active_Tokens'Range
           or else Active_Tokens (Slot) /= Token
         then
            Invalid_Completions := Invalid_Completions + 1;
            Token := No_Token;
            Result := (Status => A11y.Results.Invalid_State);
         else
            Active_Tokens (Slot) := No_Token;
            Outstanding := Outstanding - 1;
            Token := No_Token;
            Result := A11y.Results.Ok;
         end if;
      exception
         when others =>
            Token := No_Token;
            Result := (Status => A11y.Results.Internal_Error);
      end End_Callback;

      procedure Begin_Shutdown is
      begin
         if Should_Advance_On_Shutdown (Accepting)
         then
            Advance_Gate_Generation;
         end if;
         Accepting := False;
      end Begin_Shutdown;

      procedure Reset is
      begin
         if not Can_Reset
           (Outstanding)
         then
            Rejected_Resets := Rejected_Resets + 1;
            return;
         end if;

         Accepting := True;
         Outstanding := 0;
         Accepted := 0;
         Rejected_Shutdown := 0;
         Rejected_Limit := 0;
         Invalid_Completions := 0;
         Rejected_Resets := 0;
         Next_Generation := 1;
         Active_Tokens := [others => No_Token];
         Advance_Gate_Generation;
      end Reset;

      procedure Reset
        (Result : out A11y.Results.Result)
      is
      begin
         if not Can_Reset
           (Outstanding)
         then
            Rejected_Resets := Rejected_Resets + 1;
            Result := (Status => A11y.Results.Invalid_State);
            return;
         end if;

         Accepting := True;
         Outstanding := 0;
         Accepted := 0;
         Rejected_Shutdown := 0;
         Rejected_Limit := 0;
         Invalid_Completions := 0;
         Rejected_Resets := 0;
         Next_Generation := 1;
         Active_Tokens := [others => No_Token];
         Advance_Gate_Generation;
         Result := A11y.Results.Ok;
      end Reset;

      function Drained return Boolean is
        (Is_Drained (Outstanding));

      function Snapshot return Callback_Gate_Snapshot is
        (Accepting           => Accepting,
         Generation          => Gate_Generation,
         Outstanding         => Outstanding,
         Accepted            => Accepted,
         Rejected_Shutdown   => Rejected_Shutdown,
         Rejected_Limit      => Rejected_Limit,
         Invalid_Completions => Invalid_Completions,
         Rejected_Resets     => Rejected_Resets);

      function Capacity return Natural is
        (Limit);

   end Callback_Gate;

end A11y.Native_Callbacks;
