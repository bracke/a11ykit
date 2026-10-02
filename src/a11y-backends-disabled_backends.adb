with Ada.Calendar;
with Ada.Strings.Unbounded;

with A11y.Node_Ids;

package body A11y.Backends.Disabled_Backends is
   use Ada.Strings.Unbounded;

   procedure Add_Diagnostic
     (Self       : in out Disabled_Backend;
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
        (Item, "backend", "Disabled", Field_Result);
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

   overriding function Name (Self : Disabled_Backend) return String is
      pragma Unreferenced (Self);
   begin
      return "Disabled";
   end Name;

   overriding function State
     (Self : Disabled_Backend)
      return A11y.Backends.Backend_State is
     (Self.Current_State);

   overriding function Configure_Limits
     (Self   : in out Disabled_Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result
   is
      Result : A11y.Results.Result;
   begin
      A11y.Diagnostics.Configure (Self.Notes, Limits, Result);
      return Result;
   end Configure_Limits;

   overriding function Initialize
     (Self : in out Disabled_Backend)
      return A11y.Results.Result
   is
   begin
      if Self.Current_State not in A11y.Backends.Created | A11y.Backends.Stopped then
         return (Status => A11y.Results.Invalid_State);
      end if;

      Self.Current_State := A11y.Backends.Initialized;
      Add_Diagnostic
        (Self,
         "backend.disabled.initialized",
         A11y.Diagnostics.Info,
         A11y.Diagnostics.Backend_Initialization,
         Feature => "backend.disabled.lifecycle");
      return A11y.Results.Ok;
   end Initialize;

   overriding function Start
     (Self : in out Disabled_Backend)
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
     (Self : in out Disabled_Backend)
      return A11y.Results.Result
   is
   begin
      Self.Current_State := A11y.Backends.Stopped;
      return A11y.Results.Ok;
   end Stop;

   overriding function Publish
     (Self  : in out Disabled_Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result
   is
      Validation : constant A11y.Results.Result :=
        A11y.Events.Validate_Event (Event);
   begin
      if A11y.Results.Failed (Validation) then
         return Validation;
      end if;

      Add_Diagnostic
        (Self,
         "backend.disabled.event_ignored",
         A11y.Diagnostics.Trace,
         A11y.Diagnostics.Unsupported_Capability,
         Event.Sequence,
         Event.Source,
         Event.Kind,
         Has_Event => True,
         Feature => "backend.diagnostics.bounded");
      return (Status => A11y.Results.Backend_Unavailable);
   end Publish;

   overriding function Diagnostics
     (Self : Disabled_Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector is
     (A11y.Diagnostics.Snapshot (Self.Notes));

   overriding function Support_Declarations
     (Self : Disabled_Backend)
      return A11y.Conformance.Declaration_Vectors.Vector
   is
      pragma Unreferenced (Self);
   begin
      return A11y.Conformance.Disabled_Backend_Declarations;
   end Support_Declarations;

end A11y.Backends.Disabled_Backends;
