package body A11y.Diagnostics.Classification is
   pragma SPARK_Mode (On);

   function Category_For_Status
     (Status : A11y.Results.Status_Code)
      return Category is
     (A11y.Diagnostics.Category_For_Status (Status));

   function Default_Severity
     (Class : Category)
      return Severity is
     (A11y.Diagnostics.Default_Severity (Class));

   function Severity_For_Status
     (Status : A11y.Results.Status_Code)
      return Severity is
     (A11y.Diagnostics.Severity_For_Status (Status));

   function Is_Reportable
     (Level : Severity)
      return Boolean is
     (A11y.Diagnostics.Is_Reportable (Level));

   function Is_Native_Boundary_Category
     (Class : Category)
      return Boolean is
     (A11y.Diagnostics.Is_Native_Boundary_Category (Class));

end A11y.Diagnostics.Classification;
