package A11y.Documents.Classification is
   pragma SPARK_Mode (On);

   function Is_Landmark_Role
     (Role : Document_Role)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Landmark_Role'Result =
         (Role in Navigation | Header | Footer | Form | Region);

   function Is_Structural_Block_Role
     (Role : Document_Role)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Structural_Block_Role'Result =
         (Role not in Annotation | Embedded_Object);

   function Valid_Heading_Level
     (Level : Natural)
      return Standard.Boolean
   with
     Global => null,
     Post => Valid_Heading_Level'Result = (Level <= 9);

   function Heading_Level_Applies
     (Role  : Document_Role;
      Level : Natural)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Heading_Level_Applies'Result =
         ((Role = Heading and then Level in 1 .. 9)
          or else (Role /= Heading and then Level = 0));

   function Pagination_Applies
     (Role         : Document_Role;
      Page_Count   : Natural;
      Current_Page : Natural)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Pagination_Applies'Result =
         ((Page_Count = 0 and then Current_Page = 0)
          or else
            (Is_Structural_Block_Role (Role)
             and then Page_Count > 0
             and then Current_Page in 1 .. Page_Count));

end A11y.Documents.Classification;
