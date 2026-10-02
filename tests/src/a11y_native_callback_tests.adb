with A11y.Native_Callbacks;
with A11y.Native_Callbacks.Classification;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Native_Callback_Tests is
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Gate : A11y.Native_Callbacks.Callback_Gate;
      Token : A11y.Native_Callbacks.Callback_Token;
      Snapshot : A11y.Native_Callbacks.Callback_Gate_Snapshot;
      type Token_Array is array
        (Positive range 1 .. A11y.Native_Callbacks.Max_Callbacks)
        of A11y.Native_Callbacks.Callback_Token;
      Tokens : Token_Array := [others => A11y.Native_Callbacks.No_Token];
      Result : A11y.Results.Result;
   begin
      Check
        (A11y.Native_Callbacks.Classification.Valid_Capacity (1)
         and then A11y.Native_Callbacks.Classification.Valid_Capacity
           (A11y.Native_Callbacks.Max_Callbacks)
         and then not A11y.Native_Callbacks.Classification.Valid_Capacity (0)
         and then not A11y.Native_Callbacks.Classification.Valid_Capacity
           (A11y.Native_Callbacks.Max_Callbacks + 1),
         "native callback classification validates callback capacities");
      Check
        (A11y.Native_Callbacks.Classification.Can_Set_Limit
           (Outstanding_Count => 2,
            Highest_Active    => 2,
            Capacity          => 2)
         and then not A11y.Native_Callbacks.Classification.Can_Set_Limit
           (Outstanding_Count => 3,
            Highest_Active    => 2,
            Capacity          => 2)
         and then not A11y.Native_Callbacks.Classification.Can_Set_Limit
           (Outstanding_Count => 1,
            Highest_Active    => 3,
            Capacity          => 2),
         "native callback classification exposes limit-shrink admission");
      Check
        (A11y.Native_Callbacks.Classification.Can_Begin_Callback
           (Accepting         => True,
            Outstanding_Count => 1,
            Capacity          => 2,
            Next_Generation   => 1)
         and then not A11y.Native_Callbacks.Classification.Can_Begin_Callback
           (Accepting         => False,
            Outstanding_Count => 1,
            Capacity          => 2,
            Next_Generation   => 1)
         and then not A11y.Native_Callbacks.Classification.Can_Begin_Callback
           (Accepting         => True,
            Outstanding_Count => 2,
            Capacity          => 2,
            Next_Generation   => 1)
         and then not A11y.Native_Callbacks.Classification.Can_Begin_Callback
           (Accepting         => True,
            Outstanding_Count => 1,
            Capacity          => 2,
            Next_Generation   => Natural'Last),
         "native callback classification exposes begin-callback admission");
      Check
        (A11y.Native_Callbacks.Classification.Can_Reset (0)
         and then not A11y.Native_Callbacks.Classification.Can_Reset (1)
         and then A11y.Native_Callbacks.Classification.Is_Drained (0)
         and then not A11y.Native_Callbacks.Classification.Is_Drained (1),
         "native callback classification exposes drain and reset policy");

      Gate.Begin_Callback (Token, Result);
      Snapshot := Gate.Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Native_Callbacks.Is_Valid (Token)
         and then Snapshot.Generation = 1
         and then Snapshot.Outstanding = 1
         and then not Gate.Drained
         and then Snapshot.Accepted = 1,
         "native callback gate admits callbacks and records outstanding state");

      Gate.End_Callback (Token, Result);
      Snapshot := Gate.Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Native_Callbacks.Is_Valid (Token)
         and then Snapshot.Generation = 1
         and then Snapshot.Outstanding = 0
         and then Gate.Drained,
         "native callback gate completes callbacks deterministically");

      Gate.End_Callback (Token, Result);
      Snapshot := Gate.Snapshot;
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Generation = 1
         and then Snapshot.Invalid_Completions = 1,
         "native callback gate rejects invalid completions");

      Gate.Reset;
      declare
         First : A11y.Native_Callbacks.Callback_Token;
         Second : A11y.Native_Callbacks.Callback_Token;
         Third : A11y.Native_Callbacks.Callback_Token;
         Stale_First : A11y.Native_Callbacks.Callback_Token;
      begin
         Gate.Begin_Callback (First, Result);
         Stale_First := First;
         Gate.Begin_Callback (Second, Result);
         Gate.End_Callback (First, Result);
         Gate.Begin_Callback (Third, Result);
         Gate.End_Callback (Stale_First, Result);
         Snapshot := Gate.Snapshot;
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Snapshot.Generation = 5
            and then Snapshot.Outstanding = 2
            and then Snapshot.Invalid_Completions = 1,
            "native callback gate rejects stale duplicate tokens after slot reuse");

         Gate.End_Callback (Second, Result);
         Gate.End_Callback (Third, Result);
         Snapshot := Gate.Snapshot;
         Check
           (A11y.Results.Succeeded (Result)
            and then Snapshot.Outstanding = 0,
            "native callback gate preserves unrelated outstanding tokens");
      end;

      Gate.Reset;
      Gate.Begin_Callback (Token, Result);
      Gate.Reset;
      Snapshot := Gate.Snapshot;
      Check
        (Snapshot.Outstanding = 1
         and then Snapshot.Generation = 7
         and then Snapshot.Rejected_Resets = 1
         and then A11y.Native_Callbacks.Is_Valid (Token),
         "native callback gate does not reset while callbacks are outstanding");
      Check
        (not Gate.Drained,
         "native callback gate reports outstanding callbacks during drain");
      Gate.Reset (Result);
      Snapshot := Gate.Snapshot;
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then Snapshot.Outstanding = 1
         and then Snapshot.Generation = 7
         and then Snapshot.Rejected_Resets = 2,
         "native callback gate reports rejected outstanding reset attempts");
      Gate.End_Callback (Token, Result);
      Gate.Reset (Result);
      Snapshot := Gate.Snapshot;
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Outstanding = 0
         and then Snapshot.Generation = 8
         and then Snapshot.Rejected_Resets = 0
         and then Gate.Drained,
         "native callback gate resets after outstanding callbacks complete");

      Gate.Reset;
      Gate.Set_Limit (2, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Gate.Capacity = 2,
         "native callback gate accepts configured outstanding bound");
      for Index in 1 .. 2 loop
         Gate.Begin_Callback (Tokens (Index), Result);
      end loop;
      Gate.Begin_Callback (Token, Result);
      Snapshot := Gate.Snapshot;
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then not A11y.Native_Callbacks.Is_Valid (Token)
         and then Snapshot.Outstanding = 2
         and then Snapshot.Rejected_Limit = 1,
         "native callback gate enforces configured outstanding callbacks");
      Gate.Set_Limit (1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "native callback gate rejects shrinking below outstanding callbacks");
      Gate.Set_Limit (A11y.Native_Callbacks.Max_Callbacks + 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "native callback gate rejects impossible callback limits");
      Gate.End_Callback (Tokens (1), Result);
      Gate.End_Callback (Tokens (2), Result);

      declare
         Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
      begin
         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Outstanding_Callbacks,
            3,
            Result);
         Gate.Configure (Limits, Result);
         Check
           (A11y.Results.Succeeded (Result)
            and then Gate.Capacity = 3,
            "native callback gate accepts resource-limit configuration");
         Limits.Limits (A11y.Resource_Limits.Outstanding_Callbacks) := 0;
         Gate.Configure (Limits, Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument,
            "native callback gate rejects invalid resource-limit configuration");
      end;

      Gate.Reset;
      Gate.Begin_Shutdown;
      Gate.Begin_Callback (Token, Result);
      Snapshot := Gate.Snapshot;
      Check
        (Result.Status = A11y.Results.Shutting_Down
         and then not Snapshot.Accepting
         and then Snapshot.Generation = 13
         and then Gate.Drained
         and then Snapshot.Rejected_Shutdown = 1,
         "native callback gate rejects callbacks during shutdown");
   end Run;
end A11y_Native_Callback_Tests;
