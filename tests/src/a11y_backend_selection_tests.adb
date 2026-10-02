with Ada.Calendar;
with Ada.Strings.Unbounded;

with A11y;
with A11y.Backends;
with A11y.Backends.Default;
with A11y.Backends.Disabled_Backends;
with A11y.Backends.Native_Backends;
with A11y.Backends.Selection;
with A11y.Conformance;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Node_Ids;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Backend_Selection_Tests is
   use Ada.Strings.Unbounded;
   use type Ada.Calendar.Time;
   use type A11y.Event_Sequence;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;
   use type A11y.Backends.Backend_Kind;
   use type A11y.Backends.Backend_State;
   use type A11y.Backends.Selection.Selection_Mode;
   use type A11y.Conformance.Support_Level;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Backend : A11y.Backends.Disabled_Backends.Disabled_Backend;
      Result : A11y.Results.Result;
      Event : constant A11y.Events.Event :=
        (Sequence  => 10,
         Timestamp => Ada.Calendar.Clock,
         Source    => A11y.Node_Ids.From_Natural (88),
         Kind      => A11y.Events.Focus_Changed,
         Revision  => 1);
      Bad_Event : A11y.Events.Event := Event;
      Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      Declarations : A11y.Conformance.Declaration_Vectors.Vector;
      Selection : A11y.Backends.Selection.Selection_Result;
      Native_Target : A11y.Backends.Native_Backends.Native_Target_Result;
   begin
      Check
        (A11y.Backends.Selection.Parse ("native")
         = A11y.Backends.Selection.Use_Native
         and then A11y.Backends.Selection.Parse ("off")
           = A11y.Backends.Selection.Use_Disabled
         and then A11y.Backends.Selection.Parse ("bad")
           = A11y.Backends.Selection.Invalid,
         "backend selection parses runtime override names");

      Selection := A11y.Backends.Selection.Resolve ("");
      Check
        (Selection.Requested = A11y.Backends.Selection.Use_Default
         and then Selection.Status = A11y.Results.Backend_Unavailable
         and then Selection.Selected = A11y.Backends.Null_Backend
         and then Selection.Fallback,
         "backend default selection falls back when native transport is unavailable");

      Native_Target :=
        A11y.Backends.Native_Backends.Target_For_Current_Platform;
      Check
        (Native_Target.Supported
         = A11y.Backends.Selection.Native_Target_Supported,
         "backend selection reports native target support separately");

      Selection := A11y.Backends.Selection.Resolve ("native");
      Check
        ((if Native_Target.Supported
         then Selection.Selected = A11y.Backends.Native
            and then Selection.Status = A11y.Results.Backend_Unavailable
            and then not Selection.Fallback
          else Selection.Selected = A11y.Backends.Null_Backend
            and then Selection.Status = A11y.Results.Backend_Unavailable
            and then Selection.Fallback),
         "backend selection keeps explicit native requests distinct from fallback");

      Selection := A11y.Backends.Selection.Resolve ("disabled");
      Check
        (Selection.Selected = A11y.Backends.Disabled
         and then Selection.Status = A11y.Results.Success
         and then not Selection.Fallback,
         "backend selection supports explicit disabled mode");

      Selection := A11y.Backends.Selection.Resolve ("bad");
      Check
        (Selection.Status = A11y.Results.Invalid_Argument
         and then Selection.Fallback,
         "backend selection rejects invalid overrides");

      declare
         Created : A11y.Backends.Backend'Class :=
           A11y.Backends.Default.Create_From_Override ("default", Selection);
      begin
         Check
           (Selection.Requested = A11y.Backends.Selection.Use_Default
            and then Selection.Status = A11y.Results.Backend_Unavailable
            and then Selection.Selected = A11y.Backends.Null_Backend
            and then Selection.Fallback
            and then Created.Name = "Null",
            "backend override constructor falls back for unavailable default native transport");
      end;

      declare
         Created : A11y.Backends.Backend'Class :=
           A11y.Backends.Default.Create_From_Override ("disabled", Selection);
      begin
         Check
          (Selection.Selected = A11y.Backends.Disabled
            and then Selection.Status = A11y.Results.Success
            and then not Selection.Fallback
            and then Created.Name = "Disabled",
            "backend override constructor creates Disabled backend");
      end;

      declare
         Created : A11y.Backends.Backend'Class :=
           A11y.Backends.Default.Create_From_Override ("null", Selection);
      begin
         Check
          (Selection.Selected = A11y.Backends.Null_Backend
            and then Selection.Status = A11y.Results.Success
            and then not Selection.Fallback
            and then Created.Name = "Null",
            "backend override constructor creates Null backend");
      end;

      declare
         Created : A11y.Backends.Backend'Class :=
           A11y.Backends.Default.Create_From_Override ("bad", Selection);
      begin
         Check
          (Selection.Status = A11y.Results.Invalid_Argument
            and then Selection.Fallback
            and then Created.Name = "Null",
            "backend override constructor falls back for invalid overrides");
      end;

      declare
         Created : A11y.Backends.Backend'Class :=
           A11y.Backends.Default.Create_From_Override ("native", Selection);
      begin
         Check
           ((if Native_Target.Supported
             then Selection.Selected = A11y.Backends.Native
               and then not Selection.Fallback
               and then Created.Name =
                 A11y.Backends.Native_Backends.Name (Native_Target.Target)
             else Selection.Selected = A11y.Backends.Null_Backend
               and then Selection.Fallback
               and then Created.Name = "Null"),
            "backend override constructor creates compatible native selections");
      end;

      Check (Backend.Name = "Disabled", "Disabled backend reports its name");
      Result := Backend.Start;
      Check
        (A11y.Results.Succeeded (Result)
         and then Backend.State = A11y.Backends.Running,
         "Disabled backend starts deterministically");

      Result := Backend.Publish (Event);
      Check
        (Result.Status = A11y.Results.Backend_Unavailable,
         "Disabled backend rejects semantic event publication");

      Bad_Event.Source := A11y.Node_Ids.No_Node;
      Result := Backend.Publish (Bad_Event);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "Disabled backend rejects unavailable event sources");

      Bad_Event := Event;
      Bad_Event.Sequence := A11y.No_Event;
      Result := Backend.Publish (Bad_Event);
      Check
        (Result.Status = A11y.Results.Invalid_Argument,
         "Disabled backend rejects unsequenced events");

      Diagnostics := Backend.Diagnostics;
      Check
        (not Diagnostics.Is_Empty,
         "Disabled backend records structured diagnostics");
      Check
        (To_String (Diagnostics.Last_Element.Feature)
         = "backend.diagnostics.bounded"
         and then Diagnostics.Last_Element.Node = Event.Source
         and then Diagnostics.Last_Element.Sequence = Event.Sequence
         and then Diagnostics.Last_Element.Timestamp <= Ada.Calendar.Clock,
         "Disabled backend diagnostics retain feature identifiers");
      Check
        (A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element, "backend", "Disabled")
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element,
            "node_id",
            A11y.Node_Ids.Image (Event.Source))
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element,
            "event_kind",
            A11y.Events.Stable_Name (Event.Kind))
         and then A11y.Diagnostics.Has_Field
           (Diagnostics.Last_Element,
            "event_sequence",
            A11y.Event_Sequence_Image (Event.Sequence)),
         "Disabled backend diagnostics retain structured event fields");

      for Index in 1 .. 10 loop
         Result := Backend.Publish (Event);
      end loop;
      Diagnostics := Backend.Diagnostics;
      Check
        (Natural (Diagnostics.Length) = 2,
         "Disabled backend uses bounded diagnostic-log snapshots");

      Declarations := Backend.Support_Declarations;
      Check
        (A11y.Conformance.Support_For
           (Declarations,
            A11y.Conformance.Core_Role_Button,
            "Disabled") = A11y.Conformance.Unsupported,
         "Disabled backend declares all features unsupported");

      Result := Backend.Stop;
      Check
        (A11y.Results.Succeeded (Result)
         and then Backend.State = A11y.Backends.Stopped,
         "Disabled backend stops deterministically");
   end Run;
end A11y_Backend_Selection_Tests;
