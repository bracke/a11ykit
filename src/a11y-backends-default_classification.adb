package body A11y.Backends.Default_Classification is
   pragma SPARK_Mode (On);

   function Constructed_Backend
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Backend_Kind is
     (A11y.Backends.Constructed_Backend
        (Selected, Native_Target_Supported));

   function Requires_Target_Lookup
     (Selected : Backend_Kind)
      return Boolean is
     (A11y.Backends.Requires_Target_Lookup (Selected));

   function Is_Defensive_Fallback
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Boolean is
     (A11y.Backends.Is_Defensive_Fallback
        (Selected, Native_Target_Supported));

end A11y.Backends.Default_Classification;
