package body A11y.Platforms.Classification is
   pragma SPARK_Mode (On);

   function Has_Native_Backend
     (Platform : Platform_Kind)
      return Boolean is
     (Platform in Linux | MacOS | Windows);

   function Uses_Null_Backend_By_Default
     (Platform : Platform_Kind)
      return Boolean is
     (Platform = Unsupported);

   function Requires_ATSPI2
     (Platform : Platform_Kind)
      return Boolean is
     (Platform = Linux);

   function Requires_UIA
     (Platform : Platform_Kind)
      return Boolean is
     (Platform = Windows);

   function Requires_NSAccessibility
     (Platform : Platform_Kind)
      return Boolean is
     (Platform = MacOS);

end A11y.Platforms.Classification;
