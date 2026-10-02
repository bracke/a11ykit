with Ada.Calendar;
with Ada.Strings.Unbounded;

with A11y.Backends.Default;
with A11y.Backends.Null_Backends;
with A11y.Conformance;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Null_Backend_Tests is
   use Ada.Strings.Unbounded;
   use type A11y.Event_Sequence;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Results.Status_Code;
   use type A11y.Conformance.Support_Level;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
   begin
      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend :=
           A11y.Backends.Default.Create_Null;
         Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
         Result : A11y.Results.Result;
         Event_1 : A11y.Events.Event;
         Event_2 : A11y.Events.Event;
         Events : A11y.Events.Event_Vectors.Vector;
         Declarations : A11y.Conformance.Declaration_Vectors.Vector;
      begin
         Check (Backend.Name = "Null", "explicit Null backend is validating");
         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Event_Queue_Size,
            1,
            Result);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend fixture sets recorded-event capacity");
         Result := Backend.Configure_Limits (Limits);
         Check
           (A11y.Results.Succeeded (Result)
            and then Backend.Recorded_Event_Capacity = 1,
            "Null backend applies configured recorded-event capacity");
         Limits.Limits (A11y.Resource_Limits.Event_Queue_Size) := 0;
         Result := Backend.Configure_Limits (Limits);
         Check
           (Result.Status = A11y.Results.Invalid_Argument
            and then Backend.Recorded_Event_Capacity = 1,
            "Null backend rejects invalid shared limits before reconfiguration");
         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Event_Queue_Size,
            1,
            Result);
         Result := Backend.Start;
         Check (A11y.Results.Succeeded (Result), "Null backend starts");

         Event_1.Sequence := 1;
         Event_1.Source := A11y.Node_Ids.From_Natural (77);
         Event_1.Kind := A11y.Events.Node_Created;
         Result := Backend.Publish (Event_1);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend records ordered events");

         Event_2 := Event_1;
         Event_2.Sequence := 1;
         Event_2.Kind := A11y.Events.Property_Changed;
         Result := Backend.Publish (Event_2);
         Check
           (Result.Status = A11y.Results.Invalid_Argument,
            "Null backend rejects non-increasing event sequences");

         Events := Backend.Recorded_Events;
         Check
           (Natural (Events.Length) = 1,
            "Null backend keeps normalized event history");

         Event_2 := Event_1;
         Event_2.Sequence := 2;
         Event_2.Kind := A11y.Events.Focus_Changed;
         Result := Backend.Publish (Event_2);
         Check
           (Result.Status = A11y.Results.Resource_Limit
            and then Natural (Backend.Recorded_Events.Length) = 1,
            "Null backend enforces configured recorded-event capacity");

         Event_2 := Event_1;
         Event_2.Sequence := 3;
         Event_2.Source := A11y.Node_Ids.No_Node;
         Event_2.Kind := A11y.Events.Focus_Changed;
         Result := Backend.Publish (Event_2);
         Check
           (Result.Status = A11y.Results.Node_Unavailable
            and then Natural (Backend.Recorded_Events.Length) = 1,
            "Null backend rejects invalid event sources without committing order");

         Declarations := Backend.Support_Declarations;
         Check
           (A11y.Conformance.Support_For
              (Declarations,
               A11y.Conformance.Native_Identity_Object_Path,
               "Null") = A11y.Conformance.Internal_Only,
            "Null backend exposes structured support declarations");
         Result := Backend.Stop;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend stops deterministically");
      end;

      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend;
         Node : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (79);
         Event_1 : A11y.Events.Event;
         Event_2 : A11y.Events.Event;
         Result : A11y.Results.Result;
         Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      begin
         Result := Backend.Start;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend timestamp fixture starts backend");

         Event_1.Sequence := 1;
         Event_1.Timestamp := Ada.Calendar.Clock;
         Event_1.Source := Node;
         Event_1.Kind := A11y.Events.Node_Created;
         Result := Backend.Publish (Event_1);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend timestamp fixture records first event");

         Event_2 := Event_1;
         Event_2.Sequence := 2;
         Event_2.Timestamp := Ada.Calendar."-" (Event_1.Timestamp, 1.0);
         Event_2.Kind := A11y.Events.Node_Destroyed;
         Result := Backend.Publish (Event_2);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 1,
            "Null backend rejects nonmonotonic event timestamps without commit");
         Diagnostics := Backend.Diagnostics;
         declare
            Last : constant A11y.Diagnostics.Diagnostic :=
              Diagnostics.Last_Element;
         begin
            Check
              (To_String (Last.Identifier)
                 = "events.timestamp.not_monotonic"
               and then To_String (Last.Feature) = "events.timestamp_order",
               "Null backend reports timestamp-order conformance diagnostics");
         end;

         Event_2.Timestamp := Ada.Calendar."+" (Event_1.Timestamp, 1.0);
         Result := Backend.Publish (Event_2);
         Check
           (A11y.Results.Succeeded (Result)
            and then Natural (Backend.Recorded_Events.Length) = 2,
            "Null backend accepts corrected timestamp without stale mutation");
      end;

      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend;
         Node : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (80);
         Event_1 : A11y.Events.Event;
         Event_2 : A11y.Events.Event;
         Result : A11y.Results.Result;
         Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      begin
         Result := Backend.Start;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend revision fixture starts backend");

         Event_1.Sequence := 1;
         Event_1.Timestamp := Ada.Calendar.Clock;
         Event_1.Source := Node;
         Event_1.Kind := A11y.Events.Node_Created;
         Event_1.Revision := 3;
         Result := Backend.Publish (Event_1);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend revision fixture records first event");

         Event_2 := Event_1;
         Event_2.Sequence := 2;
         Event_2.Timestamp := Ada.Calendar."+" (Event_1.Timestamp, 1.0);
         Event_2.Kind := A11y.Events.Node_Attached;
         Event_2.Revision := 2;
         Result := Backend.Publish (Event_2);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 1,
            "Null backend rejects stale semantic revisions without commit");
         Diagnostics := Backend.Diagnostics;
         declare
            Last : constant A11y.Diagnostics.Diagnostic :=
              Diagnostics.Last_Element;
         begin
            Check
              (To_String (Last.Identifier) = "events.revision.stale"
               and then To_String (Last.Feature) = "events.revision_order",
               "Null backend reports revision-order conformance diagnostics");
         end;

         Event_2.Revision := 3;
         Result := Backend.Publish (Event_2);
         Check
           (A11y.Results.Succeeded (Result)
            and then Natural (Backend.Recorded_Events.Length) = 2,
            "Null backend accepts corrected semantic revision without stale mutation");
      end;

      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend;
         Node : constant A11y.Node_Ids.Node_Id :=
           A11y.Node_Ids.From_Natural (78);
         Event : A11y.Events.Event;
         Result : A11y.Results.Result;
         Diagnostics : A11y.Diagnostics.Diagnostic_Vectors.Vector;
      begin
         Result := Backend.Start;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend lifecycle fixture starts backend");

         Event.Sequence := 1;
         Event.Source := Node;
         Event.Kind := A11y.Events.Focus_Changed;
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 0,
            "Null backend rejects non-lifecycle events before creation");
         Diagnostics := Backend.Diagnostics;
         declare
            Last : constant A11y.Diagnostics.Diagnostic :=
              Diagnostics.Last_Element;
         begin
            Check
              (To_String (Last.Identifier)
                 = "events.node.event_without_live_node"
               and then Last.Node = Node
               and then Last.Sequence = 1
               and then A11y.Diagnostics.Has_Field
                 (Last, "node_id", A11y.Node_Ids.Image (Node))
               and then A11y.Diagnostics.Has_Field
                 (Last,
                  "event_kind",
                  A11y.Events.Stable_Name (A11y.Events.Focus_Changed))
               and then A11y.Diagnostics.Has_Field
                 (Last, "event_sequence", "1"),
               "Null backend lifecycle diagnostics include node and event context");
         end;

         Event.Sequence := 2;
         Event.Kind := A11y.Events.Node_Attached;
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 0,
            "Null backend rejects attach before creation");

         Event.Sequence := 3;
         Event.Kind := A11y.Events.Node_Created;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend records first node creation");

         Event.Sequence := 4;
         Event.Kind := A11y.Events.Property_Changed;
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 1,
            "Null backend rejects non-lifecycle events before attach");

         Event.Sequence := 5;
         Event.Kind := A11y.Events.Node_Created;
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 1,
            "Null backend rejects duplicate node creation");

         Event.Sequence := 6;
         Event.Kind := A11y.Events.Node_Attached;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend records attach after creation");

         Event.Sequence := 7;
         Event.Kind := A11y.Events.Node_Detached;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend records detach after attach");

         Event.Sequence := 8;
         Event.Kind := A11y.Events.State_Changed;
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Natural (Backend.Recorded_Events.Length) = 3,
            "Null backend rejects non-lifecycle events while detached");

         Event.Sequence := 9;
         Event.Kind := A11y.Events.Node_Attached;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend records reattach after detach");

         Event.Sequence := 10;
         Event.Kind := A11y.Events.Node_Destroyed;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result)
            and then Natural (Backend.Recorded_Events.Length) = 5,
            "Null backend records valid attach detach reattach destroy lifecycle");

         Event.Sequence := 11;
         Event.Kind := A11y.Events.Property_Changed;
         Result := Backend.Publish (Event);
         Check
           (Result.Status = A11y.Results.Node_Unavailable
            and then Natural (Backend.Recorded_Events.Length) = 5,
            "Null backend rejects events after node destruction");
      end;

      declare
         Backend : A11y.Backends.Null_Backends.Null_Backend;
         Limits : A11y.Resource_Limits.Resource_Limit_Config :=
           A11y.Resource_Limits.Default_Config;
         Result : A11y.Results.Result;
         Event : A11y.Events.Event;
      begin
         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Event_Queue_Size,
            2,
            Result);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend shrink fixture sets initial capacity");
         Result := Backend.Configure_Limits (Limits);
         Check
           (A11y.Results.Succeeded (Result)
            and then Backend.Recorded_Event_Capacity = 2,
            "Null backend shrink fixture applies initial capacity");
         Result := Backend.Start;
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend shrink fixture starts backend");

         Event.Sequence := 10;
         Event.Source := A11y.Node_Ids.From_Natural (88);
         Event.Kind := A11y.Events.Node_Created;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend shrink fixture records first event");
         Event.Sequence := 11;
         Event.Kind := A11y.Events.Node_Attached;
         Result := Backend.Publish (Event);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend shrink fixture records second event");

         A11y.Resource_Limits.Set_Limit
           (Limits,
            A11y.Resource_Limits.Event_Queue_Size,
            1,
            Result);
         Check
           (A11y.Results.Succeeded (Result),
            "Null backend shrink fixture sets smaller capacity");
         Result := Backend.Configure_Limits (Limits);
         Check
           (Result.Status = A11y.Results.Invalid_State
            and then Backend.Recorded_Event_Capacity = 2,
            "Null backend rejects shrinking below recorded event history");
      end;
   end Run;
end A11y_Null_Backend_Tests;
