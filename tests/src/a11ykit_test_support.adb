with Ada.Command_Line;
with Ada.Text_IO;
with Interfaces.C;

package body A11ykit_Test_Support is
   Failures : Natural := 0;

   procedure Raise_Main_Stack_Limit is
      use Interfaces.C;

      RLIMIT_STACK : constant int := 3;
      Target_Stack : constant unsigned_long := 512 * 1024 * 1024;
      RLIM_INFINITY : constant unsigned_long := unsigned_long'Last;

      type Rlimit is record
         Cur : unsigned_long;
         Max : unsigned_long;
      end record
        with Convention => C;

      function Getrlimit
        (Resource : int;
         Limit    : access Rlimit)
         return int
        with Import, Convention => C, External_Name => "getrlimit";

      function Setrlimit
        (Resource : int;
         Limit    : access constant Rlimit)
         return int
        with Import, Convention => C, External_Name => "setrlimit";

      Limit : aliased Rlimit;
      Ignored : int;
   begin
      if Getrlimit (RLIMIT_STACK, Limit'Access) = 0
        and then Limit.Cur < Target_Stack
      then
         if Limit.Max = RLIM_INFINITY or else Limit.Max >= Target_Stack then
            Limit.Cur := Target_Stack;
         else
            Limit.Cur := Limit.Max;
         end if;

         Ignored := Setrlimit (RLIMIT_STACK, Limit'Access);
      end if;
   end Raise_Main_Stack_Limit;

   procedure Check (Condition : Boolean; Message : String) is
   begin
      if Condition then
         Ada.Text_IO.Put_Line ("ok   " & Message);
      else
         Ada.Text_IO.Put_Line ("FAIL " & Message);
         Failures := Failures + 1;
      end if;
   end Check;

   function Failure_Count return Natural is
     (Failures);

   procedure Finish is
   begin
      if Failures = 0 then
         Ada.Text_IO.Put_Line ("All a11ykit tests passed.");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Success);
      else
         Ada.Text_IO.Put_Line (Failures'Image & " a11ykit test(s) FAILED");
         Ada.Command_Line.Set_Exit_Status (Ada.Command_Line.Failure);
      end if;
   end Finish;
end A11ykit_Test_Support;
