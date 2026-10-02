with Ada.Strings.Unbounded;

with A11y.Node_Ids;

package body A11y.Backends.Null_Backends is
   use Ada.Strings.Unbounded;
   use type Ada.Calendar.Time;
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;

   procedure Add_Diagnostic
     (Self       : in out Null_Backend;
      Identifier : String;
      Level      : A11y.Diagnostics.Severity;
      Class      : A11y.Diagnostics.Category;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Source     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Kind       : A11y.Events.Event_Kind := A11y.Events.Node_Created;
      Has_Event  : Boolean := False;
      Feature    : String := "")
   is
      Item : A11y.Diagnostics.Diagnostic;
      Append_Result : A11y.Results.Result;
      Field_Result : A11y.Results.Result;
   begin
      Item.Identifier := To_Unbounded_String (Identifier);
      Item.Level := Level;
      Item.Class := Class;
      Item.Node := Source;
      Item.Sequence := Sequence;
      Item.Timestamp := Ada.Calendar.Clock;
      Item.Feature := To_Unbounded_String (Feature);
      A11y.Diagnostics.Add_Field
        (Item, "backend", "Null", Field_Result);
      if A11y.Node_Ids.Is_Valid (Source) then
         A11y.Diagnostics.Add_Field
           (Item, "node_id", A11y.Node_Ids.Image (Source), Field_Result);
      end if;
      if Has_Event then
         A11y.Diagnostics.Add_Field
           (Item, "event_kind", A11y.Events.Stable_Name (Kind), Field_Result);
      end if;
      if Sequence /= A11y.No_Event then
         A11y.Diagnostics.Add_Field
           (Item, "event_sequence", A11y.Event_Sequence_Image (Sequence),
            Field_Result);
      end if;
      A11y.Diagnostics.Append (Self.Notes, Item, Append_Result);
   end Add_Diagnostic;

   procedure Validate_Event_Lifecycle
     (Self   : in out Null_Backend;
      Event  : A11y.Events.Event;
      Result : out A11y.Results.Result)
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Event.Source);
      State : Observed_Node_State;
   begin
      if Slot = 0 or else Slot > A11y.Registry.Max_Nodes then
         Add_Diagnostic
           (Self,
            "events.source.out_of_range",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Resource_Limit,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.null.event_order");
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      State := Self.Nodes (Slot);
      if not A11y.Events.Is_Lifecycle_Event (Event.Kind)
        and then State in Not_Seen | Destroyed
      then
         Add_Diagnostic
           (Self,
            "events.node.event_without_live_node",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Conformance_Failure,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.null.event_order");
         Result :=
           (Status =>
              (if State = Destroyed
               then A11y.Results.Node_Unavailable
               else A11y.Results.Invalid_State));
         return;
      end if;

      if not A11y.Events.Is_Lifecycle_Event (Event.Kind)
        and then State /= Attached
      then
         Add_Diagnostic
           (Self,
            "events.node.event_without_attached_node",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Conformance_Failure,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.null.event_order");
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      case Event.Kind is
         when A11y.Events.Node_Created =>
            if State /= Not_Seen then
               Add_Diagnostic
                 (Self,
                  "events.node.created_twice",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "backend.null.event_order");
               Result := (Status => A11y.Results.Invalid_State);
               return;
            end if;

         when A11y.Events.Node_Attached =>
            if State not in Created | Detached then
               Add_Diagnostic
                 (Self,
                  "events.node.attach_without_created",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "backend.null.event_order");
               Result := (Status => A11y.Results.Invalid_State);
               return;
            end if;

         when A11y.Events.Node_Detached =>
            if State /= Attached then
               Add_Diagnostic
                 (Self,
                  "events.node.detach_without_attached",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "backend.null.event_order");
               Result := (Status => A11y.Results.Invalid_State);
               return;
            end if;

         when A11y.Events.Node_Destroyed =>
            if State in Not_Seen | Destroyed then
               Add_Diagnostic
                 (Self,
                  "events.node.destroy_without_live_node",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "events.node.destroyed");
               Result := (Status => A11y.Results.Invalid_State);
               return;
            end if;

         when others =>
            if State = Destroyed then
               Add_Diagnostic
                 (Self,
                  "events.node.event_without_live_node",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "backend.null.event_order");
               Result := (Status => A11y.Results.Node_Unavailable);
               return;
            end if;
      end case;

      Result := A11y.Results.Ok;
   end Validate_Event_Lifecycle;

   procedure Commit_Event_Lifecycle
     (Self  : in out Null_Backend;
      Event : A11y.Events.Event)
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Event.Source);
   begin
      case Event.Kind is
         when A11y.Events.Node_Created =>
            Self.Nodes (Slot) := Created;
         when A11y.Events.Node_Attached =>
            Self.Nodes (Slot) := Attached;
         when A11y.Events.Node_Detached =>
            Self.Nodes (Slot) := Detached;
         when A11y.Events.Node_Destroyed =>
            Self.Nodes (Slot) := Destroyed;
         when others =>
            null;
      end case;
   end Commit_Event_Lifecycle;

   overriding function Name (Self : Null_Backend) return String is
      pragma Unreferenced (Self);
   begin
      return "Null";
   end Name;

   overriding function State
     (Self : Null_Backend)
      return A11y.Backends.Backend_State is
     (Self.Current_State);

   overriding function Configure_Limits
     (Self   : in out Null_Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Event_Limit : Natural;
      Result : A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
   begin
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Event_Limit := Natural
        (A11y.Resource_Limits.Value
           (Limits, A11y.Resource_Limits.Event_Queue_Size));

      if Event_Limit > Max_Events then
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      if Event_Limit < Natural (Self.Events.Length) then
         return (Status => A11y.Results.Invalid_State);
      end if;

      A11y.Diagnostics.Configure (Self.Notes, Limits, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Self.Event_Limit := Event_Limit;
      return A11y.Results.Ok;
   end Configure_Limits;

   overriding function Initialize
     (Self : in out Null_Backend)
      return A11y.Results.Result
   is
   begin
      if Self.Current_State /= A11y.Backends.Created then
         return (Status => A11y.Results.Invalid_State);
      end if;
      Self.Current_State := A11y.Backends.Initialized;
      return A11y.Results.Ok;
   end Initialize;

   overriding function Start
     (Self : in out Null_Backend)
      return A11y.Results.Result
   is
   begin
      if Self.Current_State = A11y.Backends.Created then
         declare
            Init : constant A11y.Results.Result := Self.Initialize;
         begin
            if A11y.Results.Failed (Init) then
               return Init;
            end if;
         end;
      end if;

      if Self.Current_State /= A11y.Backends.Initialized then
         return (Status => A11y.Results.Invalid_State);
      end if;

      Self.Current_State := A11y.Backends.Running;
      return A11y.Results.Ok;
   end Start;

   overriding function Stop
     (Self : in out Null_Backend)
      return A11y.Results.Result
   is
   begin
      if Self.Current_State in A11y.Backends.Stopped | A11y.Backends.Created then
         Self.Current_State := A11y.Backends.Stopped;
         return A11y.Results.Ok;
      end if;

      Self.Current_State := A11y.Backends.Stopping;
      Self.Current_State := A11y.Backends.Stopped;
      return A11y.Results.Ok;
   end Stop;

   overriding function Publish
     (Self  : in out Null_Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
   begin
      if Self.Current_State /= A11y.Backends.Running then
         Add_Diagnostic
           (Self,
            "backend.null.not_running",
            A11y.Diagnostics.Warning,
            A11y.Diagnostics.Shutdown_Anomaly,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.null.event_order");
         return (Status => A11y.Results.Shutting_Down);
      end if;

      if Event.Sequence <= Self.Last_Sequence then
         Add_Diagnostic
           (Self,
            "events.sequence.not_increasing",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Conformance_Failure,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.null.event_order");
         return (Status => A11y.Results.Invalid_Argument);
      end if;

      if Event.Timestamp < Self.Last_Timestamp then
         Add_Diagnostic
           (Self,
            "events.timestamp.not_monotonic",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Conformance_Failure,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "events.timestamp_order");
         return (Status => A11y.Results.Invalid_State);
      end if;

      if Event.Revision < Self.Last_Revision then
         Add_Diagnostic
           (Self,
            "events.revision.stale",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Conformance_Failure,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "events.revision_order");
         return (Status => A11y.Results.Invalid_State);
      end if;

      Result := A11y.Events.Validate_Event (Event);
      if A11y.Results.Failed (Result) then
         Add_Diagnostic
           (Self,
            "events.source.invalid",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Conformance_Failure,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.null.event_order");
         return Result;
      end if;

      if Natural (Self.Events.Length) >= Self.Event_Limit then
         Add_Diagnostic
           (Self,
            "events.queue.overflow",
            A11y.Diagnostics.Error,
            A11y.Diagnostics.Event_Overflow,
            Event.Sequence,
            Event.Source,
            Event.Kind,
            Has_Event => True,
            Feature => "backend.diagnostics.bounded");
         return (Status => A11y.Results.Resource_Limit);
      end if;

      if Event.Kind = A11y.Events.Node_Destroyed then
         for Prior of Self.Events loop
            if Prior.Source = Event.Source
              and then Prior.Kind = A11y.Events.Node_Destroyed
            then
               Add_Diagnostic
                 (Self,
                  "events.node.destroyed_twice",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "events.node.destroyed");
               return (Status => A11y.Results.Invalid_State);
            end if;
         end loop;
      else
         for Prior of Self.Events loop
            if Prior.Source = Event.Source
              and then Prior.Kind = A11y.Events.Node_Destroyed
            then
               Add_Diagnostic
                 (Self,
                  "events.after_destroy",
                  A11y.Diagnostics.Error,
                  A11y.Diagnostics.Conformance_Failure,
                  Event.Sequence,
                  Event.Source,
                  Event.Kind,
                  Has_Event => True,
                  Feature => "events.node.destroyed");
               return (Status => A11y.Results.Node_Unavailable);
            end if;
         end loop;
      end if;

      Validate_Event_Lifecycle (Self, Event, Result);
      if A11y.Results.Failed (Result) then
         return Result;
      end if;

      Self.Events.Append (Event);
      Commit_Event_Lifecycle (Self, Event);
      Self.Last_Sequence := Event.Sequence;
      Self.Last_Timestamp := Event.Timestamp;
      Self.Last_Revision := Event.Revision;
      return A11y.Results.Ok;
   end Publish;

   overriding function Diagnostics
     (Self : Null_Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector is
     (A11y.Diagnostics.Snapshot (Self.Notes));

   overriding function Support_Declarations
     (Self : Null_Backend)
      return A11y.Conformance.Declaration_Vectors.Vector
   is
      pragma Unreferenced (Self);
   begin
      return A11y.Conformance.Null_Backend_Declarations;
   end Support_Declarations;

   function Recorded_Events
     (Self : Null_Backend)
      return A11y.Events.Event_Vectors.Vector is
     (Self.Events);

   function Recorded_Event_Capacity
     (Self : Null_Backend)
      return Natural is
     (Self.Event_Limit);

end A11y.Backends.Null_Backends;
