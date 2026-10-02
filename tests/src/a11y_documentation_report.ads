package A11y_Documentation_Report is
   Schema : constant String := "org.a11y.documentation_report.v1";

   function Document_Count return Natural;
   function All_Required_Content_Present return Boolean;
   function Markdown return String;
   function JSON return String;
end A11y_Documentation_Report;
