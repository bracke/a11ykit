package A11y_Tool_Reports is

   Capability_Matrix_Schema : constant String :=
     "org.a11y.capability_matrix.v1";

   function Capability_Matrix_Markdown return String;
   function Capability_Matrix_JSON return String;

end A11y_Tool_Reports;
