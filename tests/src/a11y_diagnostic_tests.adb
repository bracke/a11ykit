with Ada.Calendar;
with Ada.Strings.Unbounded;

with A11y.Diagnostics;
with A11y.Diagnostics.Classification;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Diagnostic_Tests is
   use Ada.Strings.Unbounded;
   use type Ada.Calendar.Time;
   use type A11y.Event_Sequence;
   use type A11y.Diagnostics.Category;
   use type A11y.Diagnostics.Severity;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Log : A11y.Diagnostics.Diagnostic_Log;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Result : A11y.Results.Result;
      Item : A11y.Diagnostics.Diagnostic;
      Last : A11y.Diagnostics.Diagnostic;
   begin
      A11y.Diagnostics.Create_For_Status
        (Identifier => "diagnostic.test.repeat",
         Status     => A11y.Results.Resource_Limit,
         Item       => Item,
         Result     => Result,
         Node       => A11y.Node_Ids.From_Natural (401),
         Sequence   => 17,
         Feature    => "backend.diagnostics.bounded");
      Check
        (A11y.Results.Succeeded (Result)
         and then To_String (Item.Identifier) = "diagnostic.test.repeat"
         and then Item.Level = A11y.Diagnostics.Warning
         and then Item.Class = A11y.Diagnostics.Resource_Limit
         and then Item.Node = A11y.Node_Ids.From_Natural (401)
         and then Item.Sequence = 17
         and then To_String (Item.Feature) = "backend.diagnostics.bounded"
         and then Item.Redacted,
         "diagnostic constructors derive category and severity from structured results");
      A11y.Diagnostics.Add_Field
        (Item, "limit", "diagnostic-trace", Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Natural (Item.Fields.Length) = 1,
         "diagnostic records accept bounded structured fields");
      Check
        (A11y.Diagnostics.Has_Field (Item, "limit")
         and then A11y.Diagnostics.Has_Field
           (Item, "limit", "diagnostic-trace")
         and then not A11y.Diagnostics.Has_Field (Item, "")
         and then not A11y.Diagnostics.Has_Field
           (Item, "limit", "different"),
         "diagnostic field lookup uses bounded structured fields");
      A11y.Diagnostics.Add_Field (Item, "", "value", Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Natural (Item.Fields.Length) = 1,
         "diagnostic records reject empty field keys");
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_String_Size,
         4,
         Result);
      A11y.Diagnostics.Add_Field
        (Item, "code", "safe", Limits, Result, Redacted => False);
      Check
        (A11y.Results.Succeeded (Result)
         and then Natural (Item.Fields.Length) = 2
         and then not Item.Fields.Last_Element.Redacted,
         "diagnostic records accept configured bounded field text");
      A11y.Diagnostics.Add_Field
        (Item, "limit", "safe", Limits, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Natural (Item.Fields.Length) = 2,
         "diagnostic records bound field key text");
      A11y.Diagnostics.Add_Field
        (Item, "ok", "value", Limits, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Natural (Item.Fields.Length) = 2,
         "diagnostic records bound field value text");
      Check
        (A11y.Diagnostics.Capacity (Log) = A11y.Diagnostics.Max_Diagnostics,
         "diagnostic log defaults to the standard trace capacity");
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Diagnostic_Trace_Size,
         4,
         Result);
      A11y.Diagnostics.Configure (Log, Limits, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Diagnostics.Capacity (Log) = 4,
         "diagnostic log accepts trace capacity from resource limits");
      A11y.Diagnostics.Set_Capacity (Log, 3, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Diagnostics.Capacity (Log) = 3,
         "diagnostic log accepts explicit trace capacity");

      declare
         Created : A11y.Diagnostics.Diagnostic;
         Bad_Item : A11y.Diagnostics.Diagnostic := Item;
         Long_Identifier : constant String
           (1 .. A11y.Diagnostics.Max_Diagnostic_Identifier_Length + 1) :=
             [others => 'i'];
         Long_Feature : constant String
           (1 .. A11y.Diagnostics.Max_Diagnostic_Feature_Length + 1) :=
             [others => 'f'];
      begin
         A11y.Diagnostics.Create
           ("",
            A11y.Diagnostics.Node_Lifecycle,
            Created,
            Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument
            and then Length (Created.Identifier) = 0,
            "diagnostic constructors reject empty identifiers");

         A11y.Diagnostics.Create
           (Long_Identifier,
            A11y.Diagnostics.Node_Lifecycle,
            Created,
            Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then Length (Created.Identifier) = 0,
            "diagnostic constructors bound identifiers before retention");

         A11y.Diagnostics.Create
           ("diagnostic.test.long-feature",
            A11y.Diagnostics.Node_Lifecycle,
            Created,
            Result,
            Feature => Long_Feature);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then Length (Created.Feature) = 0,
            "diagnostic constructors bound feature identifiers before retention");

         Bad_Item.Identifier := Null_Unbounded_String;
         A11y.Diagnostics.Append (Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Invalid_Argument
            and then A11y.Diagnostics.Count (Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Log) = 1,
            "diagnostic log rejects empty identifiers before retention");

         Bad_Item := Item;
         Bad_Item.Identifier := To_Unbounded_String (Long_Identifier);
         A11y.Diagnostics.Append (Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Log) = 2,
            "diagnostic log bounds diagnostic identifiers");

         Bad_Item := Item;
         Bad_Item.Feature := To_Unbounded_String (Long_Feature);
         A11y.Diagnostics.Append (Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Log) = 3,
            "diagnostic log bounds feature identifiers");
      end;

      declare
         Tiny_Log : A11y.Diagnostics.Diagnostic_Log;
         Bad_Item : A11y.Diagnostics.Diagnostic := Item;
      begin
         A11y.Diagnostics.Configure (Tiny_Log, Limits, Result);
         Check
           (A11y.Results.Succeeded (Result),
            "diagnostic log applies configured string bounds");
         Bad_Item.Identifier := To_Unbounded_String ("toolong");
         Bad_Item.Feature := To_Unbounded_String ("feat");
         A11y.Diagnostics.Append (Tiny_Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Tiny_Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Tiny_Log) = 1,
            "diagnostic log bounds directly constructed identifiers");

         Bad_Item.Identifier := To_Unbounded_String ("diag");
         Bad_Item.Feature := To_Unbounded_String ("toolong");
         A11y.Diagnostics.Append (Tiny_Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Tiny_Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Tiny_Log) = 2,
            "diagnostic log bounds directly constructed features");

         Bad_Item.Feature := To_Unbounded_String ("feat");
         Bad_Item.Fields.Clear;
         Bad_Item.Fields.Append
           (A11y.Diagnostics.Diagnostic_Field'
              (Key      => To_Unbounded_String ("toolong"),
               Value    => To_Unbounded_String ("safe"),
               Redacted => True));
         A11y.Diagnostics.Append (Tiny_Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Tiny_Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Tiny_Log) = 3,
            "diagnostic log bounds directly constructed field keys");

         Bad_Item.Fields.Clear;
         Bad_Item.Fields.Append
           (A11y.Diagnostics.Diagnostic_Field'
              (Key      => To_Unbounded_String ("key"),
               Value    => To_Unbounded_String ("toolong"),
               Redacted => True));
         A11y.Diagnostics.Append (Tiny_Log, Bad_Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Tiny_Log) = 0
            and then A11y.Diagnostics.Dropped_Count (Tiny_Log) = 4,
            "diagnostic log bounds directly constructed field values");
      end;

      Limits := A11y.Resource_Limits.Default_Config;
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Diagnostic_Trace_Size,
         3,
         Result);
      A11y.Diagnostics.Configure (Log, Limits, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Diagnostics.Capacity (Log) = 3,
         "diagnostic log restores default string bounds after configured-limit checks");

      Check
        (A11y.Diagnostics.Stable_Name
           (A11y.Diagnostics.Resource_Limit) = "resource.limit"
         and then A11y.Diagnostics.Stable_Name (A11y.Diagnostics.Error)
           = "error"
         and then A11y.Diagnostics.Metadata
           (A11y.Diagnostics.Native_Allocation).Default_Severity
           = A11y.Diagnostics.Fatal,
         "diagnostic framework exposes stable category metadata");
      Check
        (A11y.Diagnostics.Category_For_Status (A11y.Results.Timed_Out)
           = A11y.Diagnostics.Provider_Timeout
         and then A11y.Diagnostics.Category_For_Status
           (A11y.Results.Node_Unavailable)
           = A11y.Diagnostics.Stale_Native_Query
         and then A11y.Diagnostics.Category_For_Status
           (A11y.Results.Unsupported_Capability)
           = A11y.Diagnostics.Unsupported_Capability
         and then A11y.Diagnostics.Category_For_Status
           (A11y.Results.Invalid_Argument)
           = A11y.Diagnostics.ABI_Boundary_Failure
         and then A11y.Diagnostics.Category_For_Status
           (A11y.Results.Shutting_Down)
           = A11y.Diagnostics.Shutdown_Anomaly
         and then A11y.Diagnostics.Category_For_Status
           (A11y.Results.Out_Of_Resources)
           = A11y.Diagnostics.Native_Allocation
         and then A11y.Diagnostics.Severity_For_Status
           (A11y.Results.Success) = A11y.Diagnostics.Trace,
         "diagnostic framework maps structured results to stable categories");
      Check
        (A11y.Diagnostics.Classification.Category_For_Status
           (A11y.Results.Timed_Out) =
             A11y.Diagnostics.Category_For_Status (A11y.Results.Timed_Out)
         and then A11y.Diagnostics.Classification.Category_For_Status
           (A11y.Results.Node_Unavailable)
             = A11y.Diagnostics.Stale_Native_Query
         and then A11y.Diagnostics.Classification.Category_For_Status
           (A11y.Results.Out_Of_Resources)
             = A11y.Diagnostics.Native_Allocation
         and then A11y.Diagnostics.Classification.Default_Severity
           (A11y.Diagnostics.Native_Allocation) = A11y.Diagnostics.Fatal
         and then A11y.Diagnostics.Classification.Severity_For_Status
           (A11y.Results.Protocol_Failure) =
             A11y.Diagnostics.Severity_For_Status
               (A11y.Results.Protocol_Failure)
         and then A11y.Diagnostics.Classification.Is_Reportable
           (A11y.Diagnostics.Warning)
         and then not A11y.Diagnostics.Classification.Is_Reportable
           (A11y.Diagnostics.Info)
         and then A11y.Diagnostics.Classification.Is_Native_Boundary_Category
           (A11y.Diagnostics.ABI_Boundary_Failure)
         and then not
           A11y.Diagnostics.Classification.Is_Native_Boundary_Category
             (A11y.Diagnostics.Node_Lifecycle),
         "diagnostic classification mirrors result and native-boundary policy");

      A11y.Diagnostics.Append (Log, Item, Result);
      A11y.Diagnostics.Append (Log, Item, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Diagnostics.Count (Log) = 1
         and then A11y.Diagnostics.Dropped_Count (Log) = 4,
         "diagnostic log rate-limits repeated adjacent diagnostics");

      Last := A11y.Diagnostics.Last (Log);
      Check
        (Last.Redacted
         and then To_String (Last.Identifier) = "diagnostic.test.repeat"
         and then Last.Timestamp <= Ada.Calendar.Clock
         and then To_String (Last.Feature) = "backend.diagnostics.bounded",
         "diagnostic log preserves structured redaction metadata");
      Check
        (Natural (Last.Fields.Length) = 2
         and then Last.Fields.First_Element.Redacted
         and then To_String (Last.Fields.First_Element.Key) = "limit",
         "diagnostic log preserves structured fields");

      for Index in 1 .. A11y.Diagnostics.Max_Diagnostic_Fields loop
         A11y.Diagnostics.Add_Field
           (Item, "extra" & Natural'Image (Index), "value", Result);
      end loop;
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Natural (Item.Fields.Length)
           = A11y.Diagnostics.Max_Diagnostic_Fields,
         "diagnostic records bound structured field counts");

      Item.Feature := To_Unbounded_String ("diagnostics.metadata");
      A11y.Diagnostics.Append (Log, Item, Result);
      Check
        (A11y.Diagnostics.Count (Log) = 2,
         "diagnostic log keeps repeated identifiers for distinct features");

      A11y.Diagnostics.Set_Capacity (Log, 1, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "diagnostic log rejects shrinking below retained records");
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Diagnostic_Trace_Size,
         1,
         Result);
      A11y.Diagnostics.Configure (Log, Limits, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State,
         "diagnostic log rejects resource-limit capacity below retained records");
      Limits.Limits (A11y.Resource_Limits.Diagnostic_Trace_Size) := 0;
      A11y.Diagnostics.Configure (Log, Limits, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "diagnostic log rejects invalid resource-limit configurations");
      A11y.Diagnostics.Set_Capacity (Log, 0, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "diagnostic log rejects zero trace capacity");

      Item.Identifier := To_Unbounded_String ("diagnostic.test.capacity");
      A11y.Diagnostics.Append (Log, Item, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Diagnostics.Count (Log) = 3,
         "diagnostic log fills configured capacity");

      Item.Identifier := To_Unbounded_String ("diagnostic.test.capacity.overflow");
      A11y.Diagnostics.Append (Log, Item, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then A11y.Diagnostics.Count (Log) = 3,
         "diagnostic log reports configured-capacity overflow");

      declare
         Full_Log : A11y.Diagnostics.Diagnostic_Log;
      begin
         for Index in 1 .. A11y.Diagnostics.Max_Diagnostics loop
            Item.Identifier :=
              To_Unbounded_String ("diagnostic.test." & Natural'Image (Index));
            A11y.Diagnostics.Append (Full_Log, Item, Result);
         end loop;

         Item.Identifier := To_Unbounded_String ("diagnostic.test.overflow");
         A11y.Diagnostics.Append (Full_Log, Item, Result);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then A11y.Diagnostics.Count (Full_Log)
              = A11y.Diagnostics.Max_Diagnostics,
            "diagnostic log reports bounded overflow");
      end;
   end Run;
end A11y_Diagnostic_Tests;
