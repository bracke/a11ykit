package body A11y_UIA_Native_Probe_Callbacks is

   function Return_S_OK
     (Session  : A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Provider : A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Method   : A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context  : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 is
   begin
      pragma Unreferenced (Session, Provider, Method, Context);
      return 0;
   end Return_S_OK;

   function Return_Frame_S_OK
     (Frame   : access constant
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Context : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32 is
   begin
      pragma Unreferenced (Frame, Context);
      return 0;
   end Return_Frame_S_OK;

end A11y_UIA_Native_Probe_Callbacks;
