package A11y.Platforms.Classification is
   pragma SPARK_Mode (On);

   subtype Platform_Kind is A11y.Platforms.Platform_Kind;
   Linux       : constant Platform_Kind := A11y.Platforms.Linux;
   MacOS       : constant Platform_Kind := A11y.Platforms.MacOS;
   Windows     : constant Platform_Kind := A11y.Platforms.Windows;
   Unsupported : constant Platform_Kind := A11y.Platforms.Unsupported;

   function Has_Native_Backend
     (Platform : Platform_Kind)
      return Boolean
   with
      Global => null,
      Post =>
        Has_Native_Backend'Result =
          (Platform in Linux | MacOS | Windows);

   function Uses_Null_Backend_By_Default
     (Platform : Platform_Kind)
      return Boolean
   with
      Global => null,
      Post =>
        Uses_Null_Backend_By_Default'Result =
          (Platform = Unsupported);

   function Requires_ATSPI2
     (Platform : Platform_Kind)
      return Boolean
   with
      Global => null,
      Post => Requires_ATSPI2'Result = (Platform = Linux);

   function Requires_UIA
     (Platform : Platform_Kind)
      return Boolean
   with
      Global => null,
      Post => Requires_UIA'Result = (Platform = Windows);

   function Requires_NSAccessibility
     (Platform : Platform_Kind)
      return Boolean
   with
      Global => null,
      Post => Requires_NSAccessibility'Result = (Platform = MacOS);

private
end A11y.Platforms.Classification;
