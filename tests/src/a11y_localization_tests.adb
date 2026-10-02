with A11y.Diagnostics;
with A11y.Localization;
with A11y.Results;

with A11ykit_Test_Support;

package body A11y_Localization_Tests is
   use type A11y.Diagnostics.Severity;
   use type A11y.Localization.Message_Key;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
   begin
      Check
        (A11y.Localization.Stable_Key
           (A11y.Localization.Diagnostic_Provider_Timeout)
         = "diagnostic.provider.timeout"
         and then A11y.Localization.Key_For_Category
           (A11y.Diagnostics.Provider_Timeout)
         = A11y.Localization.Diagnostic_Provider_Timeout,
         "localization facade maps diagnostic categories to stable message keys");
      Check
        (A11y.Localization.Render_Category
           (A11y.Diagnostics.Provider_Timeout, "en") = "Provider timeout"
         and then A11y.Localization.Render_Category
           (A11y.Diagnostics.Provider_Timeout, "da-DK") = "Provider timeout",
         "localization facade renders diagnostic category labels through the message catalog");
      Check
        (A11y.Diagnostics.Stable_Name (A11y.Diagnostics.Warning) = "warning"
         and then A11y.Diagnostics.Stable_Name (A11y.Diagnostics.Fatal) = "fatal"
         and then A11y.Localization.Stable_Key
           (A11y.Localization.Severity_Warning) = "severity.warning"
         and then A11y.Localization.Key_For_Severity (A11y.Diagnostics.Fatal)
           = A11y.Localization.Severity_Fatal,
         "localization facade maps diagnostic severities to stable message keys");
      Check
        (A11y.Localization.Render_Severity
           (A11y.Diagnostics.Warning, "en") = "Warning"
         and then A11y.Localization.Render_Severity
           (A11y.Diagnostics.Fatal, "da-DK") = "Fatal",
         "localization facade renders diagnostic severity labels through the message catalog");
      Check
        (A11y.Localization.Stable_Key
           (A11y.Localization.Result_Backend_Unavailable)
         = "result.backend-unavailable"
         and then A11y.Localization.Key_For_Status
           (A11y.Results.Backend_Unavailable)
         = A11y.Localization.Result_Backend_Unavailable,
         "localization facade maps result statuses to stable message keys");
      Check
        (A11y.Localization.Render_Status
           (A11y.Results.Backend_Unavailable, "en") = "Backend unavailable"
         and then A11y.Localization.Render_Status
           (A11y.Results.Internal_Error, "da-DK") = "Internal error",
         "localization facade renders result status labels through the message catalog");
      Check
        (A11y.Localization.Render_Status
           (A11y.Results.Backend_Unavailable, "en")
         = A11y.Localization.Render_Status
           (A11y.Results.Backend_Unavailable, "en"),
         "localization facade reuses a stable loaded catalog across renders");
      for Key in A11y.Localization.Message_Key loop
         Check
           (A11y.Localization.Render (Key, "en")
            /= A11y.Localization.Stable_Key (Key),
            "localization facade catalog covers every public message key");
      end loop;
   end Run;
end A11y_Localization_Tests;
