package A11y.Values.Classification is
   pragma SPARK_Mode (On);

   function Is_Numeric_Kind
     (Kind : Value_Kind)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Numeric_Kind'Result =
         (Kind in Integer_Value | Decimal_Value | Floating_Value);

   function Is_Known_Kind
     (Kind : Value_Kind)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Is_Known_Kind'Result =
         (Kind not in Unknown | Indeterminate);

   function Is_Mutable
     (Mode : Access_Mode)
      return Standard.Boolean
   with
     Global => null,
     Post => Is_Mutable'Result = (Mode = Writable);

   function Is_Numeric_Value
     (Item : Semantic_Value)
      return Standard.Boolean
   with
     Global => null,
     Post => Is_Numeric_Value'Result = Is_Numeric_Kind (Item.Kind);

   function Is_Known_Value
     (Item : Semantic_Value)
      return Standard.Boolean
   with
     Global => null,
     Post => Is_Known_Value'Result = Is_Known_Kind (Item.Kind);

   function Known_Range_Bound_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Known_Range_Bound_Is_Invalid'Result =
         (Is_Known_Value (Item) and then not Is_Numeric_Value (Item));

   function Known_Increment_Is_Invalid
     (Item : Semantic_Value)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Known_Increment_Is_Invalid'Result =
         (Is_Known_Value (Item) and then not Is_Numeric_Value (Item));

   function Known_Increment_Is_Not_Positive
     (Item : Semantic_Value)
      return Standard.Boolean
   with
     Global => null,
     Post =>
       Known_Increment_Is_Not_Positive'Result =
         (case Item.Kind is
            when Unknown | Indeterminate => False,
            when Integer_Value => Item.Integer_Item <= 0,
            when Decimal_Value => Item.Decimal_Item.Units <= 0,
            when Floating_Value => Item.Floating_Item <= 0.0,
            when Boolean_Value | Enumerated_Value => True);

end A11y.Values.Classification;
