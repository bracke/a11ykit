with Interfaces;
with Interfaces.C;
with System;

with A11y.Results;
with A11y.Trees;
with A11y.Windows_Backend.UIA_COM_Live_Exports;
with A11y.Windows_Backend.UIA_COM_Object_Exports;
with A11y.Windows_Backend.UIA_Native_Bridge;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Request_Router;

package A11y.Windows_Backend.UIA_Native_Callbacks is

   --  The provider and COM object a node of the published tree is reached
   --  through, once navigation has led to it; zero until then.
   type Node_Export is record
      Provider : Interfaces.Unsigned_64 := 0;
      Object   : Interfaces.Unsigned_64 := 0;
   end record;

   type Node_Export_Table is
     array (Positive range 1 .. A11y.Trees.Max_Attached_Nodes) of Node_Export;

   type Callback_Context is limited record
      Object_Table :
        access A11y.Windows_Backend.UIA_COM_Object_Exports
          .COM_Object_Export_Table;
      Registry :
        access A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      --  Written as well as read: a request is answered from the snapshot
      --  pointed at the element it came to.
      Snapshots :
        access A11y.Windows_Backend.UIA_Request_Router
          .Snapshot_Bundle;
      Exports : Node_Export_Table;
      Dispatched : Boolean := False;
      Last_Report :
        A11y.Windows_Backend.UIA_COM_Live_Exports
          .ABI_Interface_Frame_Report;
      Last_Status : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Last_HResult_Code : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   function Dispatch_Interface_Frame_Callback
     (Frame   :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Context : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Property_Value_Callback
     (Frame           :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Native_Property :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Value_Kind      :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      UTF8_Buffer     : System.Address;
      UTF8_Capacity   :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      UTF8_Used       :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context         : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Runtime_Id_Callback
     (Frame      :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Value_Kind :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Items      : System.Address;
      Capacity   :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Used       :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context    : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Bounding_Rectangle_Callback
     (Frame   :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Left    : access Interfaces.C.double;
      Top     : access Interfaces.C.double;
      Width   : access Interfaces.C.double;
      Height  : access Interfaces.C.double;
      Context : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Boolean_Callback
     (Frame   :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Value   :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Check_Pattern_Supported_Callback
     (Frame          :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Native_Pattern :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Supported      :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context        : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Pattern_State_Callback
     (Frame             :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Native_State_Kind :
        A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      State             :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context           : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Dispatch_Range_Value_Set_Callback
     (Frame   :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Value   : Interfaces.C.double;
      Context : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Range_Value_Query_Callback
     (Frame         :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Numeric_Value : access Interfaces.C.double;
      Boolean_Value :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context       : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   function Copy_Window_Query_Callback
     (Frame   :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Value   :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Context : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

   --  Where navigation from the provider Frame names (session, provider,
   --  object token) leads: Direction 0 parent, 1 first child, 2 last child,
   --  3 next sibling, 4 previous sibling. Sets the target's provider and
   --  object token, exporting it on first use; zero when there is none.
   function Navigation_Callback
     (Frame           :
        access constant A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Direction       : A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32;
      Target_Provider :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Target_Object   :
        access A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt64;
      Context         : System.Address)
      return A11y.Windows_Backend.UIA_Native_Bridge.Native_UInt32
   with Convention => C;

end A11y.Windows_Backend.UIA_Native_Callbacks;
