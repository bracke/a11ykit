package A11y_Public_Surface_Audit is
   Schema : constant String := "org.a11y.public_surface_audit.v1";

   function Spec_Count return Natural;
   function Forbidden_Token_Count return Natural;
   function Leak_Count return Natural;
   function Complete return Boolean;
   function Markdown return String;
   function JSON return String;
end A11y_Public_Surface_Audit;
