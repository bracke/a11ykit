with A11y.Conformance;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Backends.Disabled_Backends is

   type Disabled_Backend is new A11y.Backends.Backend with private;

   overriding function Name (Self : Disabled_Backend) return String;
   overriding function State
     (Self : Disabled_Backend)
      return A11y.Backends.Backend_State;
   overriding function Configure_Limits
     (Self   : in out Disabled_Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result;
   overriding function Initialize
     (Self : in out Disabled_Backend)
      return A11y.Results.Result;
   overriding function Start
     (Self : in out Disabled_Backend)
      return A11y.Results.Result;
   overriding function Stop
     (Self : in out Disabled_Backend)
      return A11y.Results.Result;
   overriding function Publish
     (Self  : in out Disabled_Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result;
   overriding function Diagnostics
     (Self : Disabled_Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector;
   overriding function Support_Declarations
     (Self : Disabled_Backend)
      return A11y.Conformance.Declaration_Vectors.Vector;

private
   type Disabled_Backend is new A11y.Backends.Backend with record
      Current_State : A11y.Backends.Backend_State := A11y.Backends.Created;
      Notes         : A11y.Diagnostics.Diagnostic_Log;
   end record;

end A11y.Backends.Disabled_Backends;
