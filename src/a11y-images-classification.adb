package body A11y.Images.Classification is
   pragma SPARK_Mode (On);

   function Exposed_By_Default
     (Kind : Image_Kind)
      return Standard.Boolean is
     (Kind /= Decorative);

   function Is_Structured_Kind
     (Kind : Image_Kind)
      return Standard.Boolean is
     (Kind in Chart | Diagram | Map | Canvas);

   function Is_Informative_Kind
     (Kind : Image_Kind)
      return Standard.Boolean is
     (Kind in Informative | Chart | Diagram | Map | Canvas);

end A11y.Images.Classification;
