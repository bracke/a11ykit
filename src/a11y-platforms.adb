with Hostkit.Host;

package body A11y.Platforms is

   function Current return Platform_Kind is
     (case Hostkit.Host.Current is
        when Hostkit.Host.Linux => Linux,
        when Hostkit.Host.MacOS => MacOS,
        when Hostkit.Host.Windows => Windows,
        when Hostkit.Host.Unsupported => Unsupported);

   function Native_Backend_Name return String is
     (case Current is
        when Linux => "AT-SPI",
        when MacOS => "NSAccessibility",
        when Windows => "UI Automation",
        when Unsupported => "none");

end A11y.Platforms;
