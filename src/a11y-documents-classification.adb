package body A11y.Documents.Classification is
   pragma SPARK_Mode (On);

   function Is_Landmark_Role
     (Role : Document_Role)
      return Standard.Boolean is
     (A11y.Documents.Is_Landmark_Role (Role));

   function Is_Structural_Block_Role
     (Role : Document_Role)
      return Standard.Boolean is
     (A11y.Documents.Is_Structural_Block_Role (Role));

   function Valid_Heading_Level
     (Level : Natural)
      return Standard.Boolean is
     (A11y.Documents.Valid_Heading_Level (Level));

   function Heading_Level_Applies
     (Role  : Document_Role;
      Level : Natural)
      return Standard.Boolean is
     (A11y.Documents.Heading_Level_Applies (Role, Level));

   function Pagination_Applies
     (Role         : Document_Role;
      Page_Count   : Natural;
      Current_Page : Natural)
      return Standard.Boolean is
     (A11y.Documents.Pagination_Applies
        (Role, Page_Count, Current_Page));

end A11y.Documents.Classification;
