with Ada.Strings.Unbounded;

--  Accessibility backend for applications that draw their own UI (Vulkan,
--  OpenGL, a custom toolkit) and therefore have no OS-recognised widget objects
--  for a screen reader to inspect.
--
--  A standard toolkit (GTK, Qt, Win32, Cocoa) exposes an accessibility tree to
--  the OS for free: each widget is an object the accessibility service can walk.
--  A self-drawn UI is a texture -- there is nothing to walk. So the application
--  must build a *semantic* description of what it drew and hand it to the OS
--  accessibility service itself. This crate is that seam: the application pushes
--  a neutral A11ykit.Tree, and a per-OS provider (A11ykit.Provider) publishes it
--  to the host's screen-reader service.
--
--  This root package holds only the vocabulary shared by the tree and the
--  provider: the roles a node can have, its on-screen rectangle, and its state.
package A11ykit is
   pragma Elaborate_Body;

   subtype UString is Ada.Strings.Unbounded.Unbounded_String;

   --  The kind of thing a node represents, in the terms screen readers speak.
   --  Deliberately small and toolkit-neutral: each host's provider maps these to
   --  its own role constants (an AT-SPI role, a UIA control type, an
   --  NSAccessibility role).
   type Role is
     (Role_Window,
      Role_Dialog,
      Role_Pane,
      Role_Toolbar,
      Role_Button,
      Role_Text_Input,
      Role_List,
      Role_List_Item,
      Role_Table,
      Role_Table_Row,
      Role_Heading,
      Role_Status,
      Role_Unknown);

   --  A node's rectangle in framebuffer pixels, top-left origin. Screen readers
   --  use it to place the focus highlight and to route touch/explore gestures.
   type Rectangle is record
      X      : Natural := 0;
      Y      : Natural := 0;
      Width  : Natural := 0;
      Height : Natural := 0;
   end record;

   --  The states a screen reader announces. Kept minimal on purpose; richer
   --  states (expanded, checked, ...) can be added as consumers need them.
   type State is record
      Enabled  : Boolean := True;
      Selected : Boolean := False;
      Focused  : Boolean := False;
   end record;

end A11ykit;
