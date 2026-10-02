package body A11y.Conformance.Classification is
   pragma SPARK_Mode (On);

   function Is_Production_Support
     (Level : A11y.Conformance.Support_Level)
      return Boolean is
     (Level in Exact | Equivalent | Approximate);

   function Is_Internal_Or_Unsupported
     (Level : A11y.Conformance.Support_Level)
      return Boolean is
     (Level in Internal_Only | Unsupported);

   function Support_Rank
     (Level : A11y.Conformance.Support_Level)
      return Natural is
     (case Level is
        when Unsupported => 0,
        when Internal_Only => 1,
        when Approximate => 2,
        when Equivalent => 3,
        when Exact => 4);

   function At_Least
     (Level     : A11y.Conformance.Support_Level;
      Threshold : A11y.Conformance.Support_Level)
      return Boolean is
     (Support_Rank (Level) >= Support_Rank (Threshold));

end A11y.Conformance.Classification;
