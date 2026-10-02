with A11y.Results;
with A11y.Resource_Limits;

package A11y.Native_Callbacks is

   Max_Callbacks : constant Natural := 4_096;

   type Callback_Token is private;

   No_Token : constant Callback_Token;

   function Is_Valid (Token : Callback_Token) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Valid'Result = (Token /= No_Token);

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Valid_Capacity'Result = (Capacity in 1 .. Max_Callbacks);

   function Can_Set_Limit
     (Outstanding_Count  : Natural;
      Highest_Active     : Natural;
      Capacity           : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Set_Limit'Result =
          (Valid_Capacity (Capacity)
           and then Capacity >= Outstanding_Count
           and then Capacity >= Highest_Active);

   function Can_Begin_Callback
     (Accepting          : Boolean;
      Outstanding_Count  : Natural;
      Capacity           : Natural;
      Next_Generation    : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Begin_Callback'Result =
          (Accepting
           and then Outstanding_Count < Capacity
           and then Next_Generation < Natural'Last);

   function Can_Advance_Gate_Generation
     (Generation : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Advance_Gate_Generation'Result =
        (Generation < Natural'Last);

   function Should_Advance_On_Shutdown
     (Accepting : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Should_Advance_On_Shutdown'Result = Accepting;

   function Can_Reset (Outstanding_Count : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Reset'Result = (Outstanding_Count = 0);

   function Is_Drained (Outstanding_Count : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Drained'Result = (Outstanding_Count = 0);

   type Callback_Gate_Snapshot is record
      Accepting           : Boolean := True;
      Generation          : Natural := 0;
      Outstanding         : Natural := 0;
      Accepted            : Natural := 0;
      Rejected_Shutdown   : Natural := 0;
      Rejected_Limit      : Natural := 0;
      Invalid_Completions : Natural := 0;
      Rejected_Resets     : Natural := 0;
   end record;

   type Active_Token_Array is array
     (Positive range 1 .. Max_Callbacks)
      of Callback_Token;

   protected type Callback_Gate is
      procedure Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result);

      procedure Set_Limit
        (Capacity : Natural;
         Result : out A11y.Results.Result);

      procedure Begin_Callback
        (Token  : out Callback_Token;
         Result : out A11y.Results.Result);

      procedure End_Callback
        (Token  : in out Callback_Token;
         Result : out A11y.Results.Result);

      procedure Begin_Shutdown;

      procedure Reset;

      procedure Reset
        (Result : out A11y.Results.Result);

      function Drained return Boolean;
      function Snapshot return Callback_Gate_Snapshot;
      function Capacity return Natural;
   private
      procedure Advance_Gate_Generation;
      function Highest_Active_Slot return Natural;

      Limit               : Natural := Max_Callbacks;
      Accepting           : Boolean := True;
      Gate_Generation     : Natural := 0;
      Outstanding         : Natural := 0;
      Accepted            : Natural := 0;
      Rejected_Shutdown   : Natural := 0;
      Rejected_Limit      : Natural := 0;
      Invalid_Completions : Natural := 0;
      Rejected_Resets     : Natural := 0;
      Next_Generation     : Natural := 1;
      Active_Tokens       : Active_Token_Array := [others => No_Token];
   end Callback_Gate;

private
   type Callback_Token is record
      Slot       : Natural := 0;
      Generation : Natural := 0;
   end record;

   No_Token : constant Callback_Token := (Slot => 0, Generation => 0);

end A11y.Native_Callbacks;
