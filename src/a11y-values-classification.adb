package body A11y.Values.Classification is
   pragma SPARK_Mode (On);

   function Is_Numeric_Kind
     (Kind : Value_Kind)
      return Standard.Boolean is
     (A11y.Values.Is_Numeric_Kind (Kind));

   function Is_Known_Kind
     (Kind : Value_Kind)
      return Standard.Boolean is
     (A11y.Values.Is_Known_Kind (Kind));

   function Is_Mutable
     (Mode : Access_Mode)
      return Standard.Boolean is
     (A11y.Values.Is_Mutable (Mode));

   function Is_Numeric_Value
     (Item : Semantic_Value)
      return Standard.Boolean is
     (A11y.Values.Is_Numeric (Item));

   function Is_Known_Value
     (Item : Semantic_Value)
      return Standard.Boolean is
     (A11y.Values.Is_Known (Item));

   function Known_Range_Bound_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean is
     (A11y.Values.Known_Range_Bound_Is_Invalid (Item));

   function Known_Increment_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean is
     (A11y.Values.Known_Increment_Is_Invalid (Item));

   function Known_Increment_Is_Not_Positive
     (Item : Semantic_Value)
      return Standard.Boolean is
     (A11y.Values.Known_Increment_Is_Not_Positive (Item));

end A11y.Values.Classification;
