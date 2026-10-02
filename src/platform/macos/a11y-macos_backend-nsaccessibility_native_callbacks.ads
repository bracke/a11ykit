with System;

with A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Native_Callbacks is

   type Callback_Context is limited record
      Registry :
        access A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Snapshots :
        access constant A11y.MacOS_Backend.NSAccessibility_Request_Router
          .Snapshot_Bundle;
      Dispatched : Boolean := False;
      Last_Report :
        A11y.MacOS_Backend.NSAccessibility_ABI_Surface
          .Selector_Frame_Report;
      Last_Status : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   function Dispatch_Selector_Callback
     (Session  :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Node     :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Selector :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Operand  :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Context  : System.Address)
      return A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_Status
   with Convention => C;

   function Copy_Value_Callback
     (Session       :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Node          :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Selector      :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Operand       :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Value_Kind    :
        access A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Items         : System.Address;
      Item_Capacity :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Item_Count    :
        access A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      UTF8_Buffer   : System.Address;
      UTF8_Capacity :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      UTF8_Used     :
        access A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Context       : System.Address)
      return A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_Status
   with Convention => C;

   function Copy_Object_Callback
     (Session       :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Node          :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Selector      :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Operand       :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt32;
      Point_X       :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_Int64;
      Point_Y       :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_Int64;
      Items         : System.Address;
      Item_Capacity :
        A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Item_Count    :
        access A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_UInt64;
      Context       : System.Address)
      return A11y.MacOS_Backend.NSAccessibility_Native_Bridge.Native_Status
   with Convention => C;

end A11y.MacOS_Backend.NSAccessibility_Native_Callbacks;
