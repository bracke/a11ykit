package A11y.Conformance.Classification is
   pragma SPARK_Mode (On);

   function Is_Production_Support
     (Level : A11y.Conformance.Support_Level)
      return Boolean
   with
      Global => null,
      Post =>
        Is_Production_Support'Result =
          (Level in Exact | Equivalent | Approximate);

   function Is_Internal_Or_Unsupported
     (Level : A11y.Conformance.Support_Level)
      return Boolean
   with
      Global => null,
      Post =>
        Is_Internal_Or_Unsupported'Result =
          (Level in Internal_Only | Unsupported);

   function Support_Rank
     (Level : A11y.Conformance.Support_Level)
      return Natural
   with
      Global => null,
      Post =>
        (case Level is
           when Unsupported => Support_Rank'Result = 0,
           when Internal_Only => Support_Rank'Result = 1,
           when Approximate => Support_Rank'Result = 2,
           when Equivalent => Support_Rank'Result = 3,
           when Exact => Support_Rank'Result = 4);

   function At_Least
     (Level     : A11y.Conformance.Support_Level;
      Threshold : A11y.Conformance.Support_Level)
      return Boolean
   with
      Global => null,
      Post =>
        At_Least'Result =
          (Support_Rank (Level) >= Support_Rank (Threshold));

end A11y.Conformance.Classification;
