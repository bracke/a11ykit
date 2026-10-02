with Ada.Calendar;

with A11y.Backends.Disabled_Backends;
with A11y.Backends.Native_Backends;
with A11y.Backends.Null_Backends;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Event_Queues;
with A11y.Linux.DBus_Codec;
with A11y.Native_Object_Caches;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Selection;
with A11y.Text;

with A11ykit_Test_Support;

package body A11y_Backend_Limit_Tests is
   use type A11y.Resource_Limits.Limit_Value;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event :=
        (Sequence  => 20,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.No_Node,
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
   begin
      Check
        (A11y.Resource_Limits.Validate (Limits).Status = A11y.Results.Success,
         "resource-limit defaults validate");

      Check
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Event_Queue_Size)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Event_Queues.Max_Queued_Events)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Selection_Items_Materialized)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Selection.Max_Selected_Items)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Text_Returned)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Text.Max_Text_Returned)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Native_Object_Cache_Size)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Native_Object_Caches.Max_Native_Objects)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Diagnostic_Trace_Size)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Diagnostics.Max_Diagnostics)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Native_String_Size)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Linux.DBus_Codec.Max_String_Length)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Native_Array_Size)
         = A11y.Resource_Limits.Limit_Value
             (A11y.Linux.DBus_Codec.Max_Array_Length),
         "resource-limit defaults mirror current bounded containers");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Text_Returned,
         128,
         Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Text_Returned) = 128,
         "resource-limit configuration accepts explicit bounds");

      Check
        (A11y.Resource_Limits.Exceeded
           (Limits, A11y.Resource_Limits.Text_Returned, 129)
         and then not A11y.Resource_Limits.Exceeded
           (Limits, A11y.Resource_Limits.Text_Returned, 128),
         "resource-limit configuration detects exceeded requests");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Text_Returned,
         0,
         Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "resource-limit configuration rejects zero bounds");

      Limits.Limits (A11y.Resource_Limits.Event_Queue_Size) := 0;
      Check
        (A11y.Resource_Limits.Validate (Limits).Status
         = A11y.Results.Invalid_Argument,
         "resource-limit validation rejects invalid configurations");

      Limits := A11y.Resource_Limits.Default_Config;

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Diagnostic_Trace_Size,
         1,
         Result);
      Check
        (A11y.Results.Succeeded (Result),
         "backend resource-limit fixture sets diagnostic trace size");

      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend;
         Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      begin
         Result := Backend.Configure_Limits (Limits);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend accepts common resource limits");
         Result := Backend.Start;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend starts with configured resource limits");
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Node_Unavailable,
            "Null backend records first configured-limit diagnostic");
         Event.Source := A11y.Node_Ids.From_Natural (90);
         Event.Sequence := 21;
         Result := Backend.Stop;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend stops before configured-limit overflow");
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Shutting_Down,
            "Null backend reports shutdown after configured-limit overflow");
         Diagnostics := Backend.Diagnostics;
         Check
           (Natural (Diagnostics.Length) = 1,
            "Null backend applies diagnostic trace resource limit");
      end;

      declare
         Backend : A11y.Backends.Disabled_Backends.Disabled_Backend;
         Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      begin
         Result := Backend.Configure_Limits (Limits);
         Check
           (A11y.Results.Succeeded (Result),
            "Disabled backend accepts common resource limits");
         Result := Backend.Start;
         Check
           (A11y.Results.Succeeded (Result),
            "Disabled backend starts with configured resource limits");
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Backend_Unavailable,
            "Disabled backend reports unavailable after configured-limit overflow");
         Diagnostics := Backend.Diagnostics;
         Check
           (Natural (Diagnostics.Length) = 1,
            "Disabled backend applies diagnostic trace resource limit");
      end;

      declare
         Backend : A11y.Backends.Native_Backends.Native_Backend
           (A11y.Backends.Native_Backends.Windows_UIA);
         Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      begin
         Result := Backend.Configure_Limits (Limits);
         Check
           (A11y.Results.Succeeded (Result),
            "Native backend accepts common resource limits");
         Result := Backend.Start;
         Diagnostics := Backend.Diagnostics;
         Check
           (Natural (Diagnostics.Length) = 1,
            "Native backend applies diagnostic trace resource limit");
      end;

      Limits.Limits (A11y.Resource_Limits.Diagnostic_Trace_Size) := 0;
      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend;
      begin
         Result := Backend.Configure_Limits (Limits);
         Check
           (Result.Status = A11y.Results.Invalid_Argument,
            "backend resource-limit configuration rejects invalid bounds");
      end;
   end Run;
end A11y_Backend_Limit_Tests;
