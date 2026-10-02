with Ada.Calendar;

with A11y.Conformance;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Registry;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Backends.Null_Backends is

   Max_Events : constant Natural := 1_024;

   type Null_Backend is new A11y.Backends.Backend with private;

   overriding function Name (Self : Null_Backend) return String;
   overriding function State (Self : Null_Backend) return A11y.Backends.Backend_State;
   overriding function Configure_Limits
     (Self   : in out Null_Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;
   overriding function Initialize
     (Self : in out Null_Backend)
      return A11y.Results.Result;
   overriding function Start
     (Self : in out Null_Backend)
      return A11y.Results.Result;
   overriding function Stop
     (Self : in out Null_Backend)
      return A11y.Results.Result;
   overriding function Publish
     (Self  : in out Null_Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result;
   overriding function Diagnostics
     (Self : Null_Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector;
   overriding function Support_Declarations
     (Self : Null_Backend)
      return A11y.Conformance.Declaration_Vectors.Vector;

   function Recorded_Events
     (Self : Null_Backend)
      return A11y.Events.Event_Vectors.Vector;

   function Recorded_Event_Capacity
     (Self : Null_Backend)
      return Natural;

private
   type Observed_Node_State is
     (Not_Seen,
      Created,
      Attached,
      Detached,
      Destroyed);

   type Observed_Node_State_Table is array
     (Positive range 1 .. A11y.Registry.Max_Nodes) of Observed_Node_State;

   type Null_Backend is new A11y.Backends.Backend with record
      Current_State : A11y.Backends.Backend_State := A11y.Backends.Created;
      Last_Sequence : A11y.Event_Sequence := A11y.No_Event;
      Last_Timestamp : A11y.Timestamp := Ada.Calendar.Time_Of (1901, 1, 1);
      Last_Revision : A11y.Semantic_Revision := A11y.Initial_Revision;
      Event_Limit : Natural := Max_Events;
      Events : A11y.Events.Event_Vectors.Vector;
      Nodes  : Observed_Node_State_Table := [others => Not_Seen];
      Notes  : A11y.Diagnostics.Diagnostic_Log;
   end record;
end A11y.Backends.Null_Backends;
