package A11y.Backends.Default_Classification is
   pragma SPARK_Mode (On);

   function Constructed_Backend
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Backend_Kind
   with
      Global => null,
      Post =>
        (if Selected = Native and then Native_Target_Supported then
           Constructed_Backend'Result = Native
         elsif Selected = Disabled then
           Constructed_Backend'Result = Disabled
         else
           Constructed_Backend'Result = Null_Backend);

   function Requires_Target_Lookup
     (Selected : Backend_Kind)
      return Boolean
   with
      Global => null,
      Post => Requires_Target_Lookup'Result = (Selected = Native);

   function Is_Defensive_Fallback
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Boolean
   with
      Global => null,
      Post =>
        Is_Defensive_Fallback'Result =
          (Selected = Native and then not Native_Target_Supported);

end A11y.Backends.Default_Classification;
