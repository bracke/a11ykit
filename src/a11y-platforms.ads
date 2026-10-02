package A11y.Platforms is
   pragma SPARK_Mode (On);

   type Platform_Kind is (Linux, MacOS, Windows, Unsupported);

   function Current return Platform_Kind;
   function Native_Backend_Name return String;

end A11y.Platforms;
