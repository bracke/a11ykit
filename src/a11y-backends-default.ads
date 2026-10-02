with A11y.Backends.Null_Backends;
with A11y.Backends.Native_Backends;
with A11y.Backends.Selection;

package A11y.Backends.Default is

   --  Explicit validating Null Backend constructor for portable conformance
   --  tests and headless semantic validation.
   function Create_Null return A11y.Backends.Null_Backends.Null_Backend;

   --  Default constructor for application-facing code. It returns the native
   --  backend for supported host targets when the native transport is
   --  available and the validating Null Backend otherwise.
   function Create_Default return A11y.Backends.Backend'Class;

   --  Compatibility alias for code that adopted the staged name before
   --  Create_Default became target-aware.
   function Create_Platform_Default return A11y.Backends.Backend'Class
     renames Create_Default;

   --  Runtime override constructor for application-facing code. The returned
   --  backend is still platform-neutral; Selection records whether the override
   --  resolved cleanly, fell back, or requested a staged native backend whose
   --  live transport is not yet available.
   function Create_From_Override
     (Override  : String;
      Selection : out A11y.Backends.Selection.Selection_Result)
      return A11y.Backends.Backend'Class;

end A11y.Backends.Default;
