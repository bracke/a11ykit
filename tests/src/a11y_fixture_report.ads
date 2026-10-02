package A11y_Fixture_Report is
   Schema : constant String := "org.a11y.fixture_report.v1";

   function Node_Count return Natural;
   function Command_Count return Natural;
   function Complete return Boolean;
   function Markdown return String;
   function JSON return String;
end A11y_Fixture_Report;
