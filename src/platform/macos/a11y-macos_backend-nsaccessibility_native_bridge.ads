with Interfaces;
with Interfaces.C;
with System;

package A11y.MacOS_Backend.NSAccessibility_Native_Bridge is

   use type Interfaces.Unsigned_32;

   subtype Native_UInt32 is Interfaces.Unsigned_32;
   subtype Native_UInt64 is Interfaces.Unsigned_64;
   subtype Native_Int64 is Interfaces.Integer_64;

   type Native_Status is new Interfaces.C.int;
   subtype Native_Int is Interfaces.C.int;

   Probe_Element_Created : constant Native_UInt32 := 2#0000_0000_0001#;
   Probe_Identity_Matched : constant Native_UInt32 := 2#0000_0000_0010#;
   Probe_Attribute_Names_Dispatched : constant Native_UInt32 :=
     2#0000_0000_0100#;
   Probe_Attribute_Value_Dispatched : constant Native_UInt32 :=
     2#0000_0000_1000#;
   Probe_Settable_Dispatched : constant Native_UInt32 := 2#0000_0001_0000#;
   Probe_Action_Names_Dispatched : constant Native_UInt32 :=
     2#0000_0010_0000#;
   Probe_Parent_Dispatched : constant Native_UInt32 := 2#0000_0100_0000#;
   Probe_Children_Dispatched : constant Native_UInt32 := 2#0000_1000_0000#;
   Probe_Child_At_Index_Dispatched : constant Native_UInt32 :=
     2#0001_0000_0000#;
   Probe_Hit_Test_Dispatched : constant Native_UInt32 := 2#0010_0000_0000#;
   Probe_Focused_Dispatched : constant Native_UInt32 := 2#0100_0000_0000#;
   Probe_Notification_Dispatched : constant Native_UInt32 :=
     2#1000_0000_0000#;
   Probe_Released : constant Native_UInt32 := 2#1_0000_0000_0000#;
   Probe_All_Required : constant Native_UInt32 :=
     Probe_Element_Created
     or Probe_Identity_Matched
     or Probe_Attribute_Names_Dispatched
     or Probe_Attribute_Value_Dispatched
     or Probe_Settable_Dispatched
     or Probe_Action_Names_Dispatched
     or Probe_Parent_Dispatched
     or Probe_Children_Dispatched
     or Probe_Child_At_Index_Dispatched
     or Probe_Hit_Test_Dispatched
     or Probe_Focused_Dispatched
     or Probe_Notification_Dispatched
     or Probe_Released;

   Public_AX_Probe_Trust_Checked : constant Native_UInt32 :=
     2#0000_0001#;
   Public_AX_Probe_Application_Created : constant Native_UInt32 :=
     2#0000_0010#;
   Public_AX_Probe_Attribute_Names_Attempted : constant Native_UInt32 :=
     2#0000_0100#;
   Public_AX_Probe_Role_Attempted : constant Native_UInt32 :=
     2#0000_1000#;
   Public_AX_Probe_Windows_Attempted : constant Native_UInt32 :=
     2#0001_0000#;
   Public_AX_Probe_Window_Children_Attempted : constant Native_UInt32 :=
     2#0010_0000#;
   Public_AX_Probe_Root_Role_Attempted : constant Native_UInt32 :=
     2#0100_0000#;
   Public_AX_Probe_Released : constant Native_UInt32 := 2#1000_0000#;
   Public_AX_Probe_All_Required : constant Native_UInt32 :=
     Public_AX_Probe_Trust_Checked
     or Public_AX_Probe_Application_Created
     or Public_AX_Probe_Attribute_Names_Attempted
     or Public_AX_Probe_Role_Attempted
     or Public_AX_Probe_Windows_Attempted
     or Public_AX_Probe_Window_Children_Attempted
     or Public_AX_Probe_Root_Role_Attempted
     or Public_AX_Probe_Released;

   function Bridge_Is_MacOS return Native_UInt32
   with Import, Convention => C, External_Name => "a11y_nsax_bridge_is_macos";

   type NSAX_Callback is access function
     (Session  : Native_UInt64;
      Node     : Native_UInt64;
      Selector : Native_UInt32;
      Operand  : Native_UInt32;
      Context  : System.Address)
      return Native_Status
   with Convention => C;

   type NSAX_Value_Callback is access function
     (Session       : Native_UInt64;
      Node          : Native_UInt64;
      Selector      : Native_UInt32;
      Operand       : Native_UInt32;
      Value_Kind    : access Native_UInt32;
      Items         : System.Address;
      Item_Capacity : Native_UInt64;
      Item_Count    : access Native_UInt64;
      UTF8_Buffer   : System.Address;
      UTF8_Capacity : Native_UInt64;
      UTF8_Used     : access Native_UInt64;
      Context       : System.Address)
      return Native_Status
   with Convention => C;

   type NSAX_Object_Callback is access function
     (Session       : Native_UInt64;
      Node          : Native_UInt64;
      Selector      : Native_UInt32;
      Operand       : Native_UInt32;
      Point_X       : Native_Int64;
      Point_Y       : Native_Int64;
      Items         : System.Address;
      Item_Capacity : Native_UInt64;
      Item_Count    : access Native_UInt64;
      Context       : System.Address)
      return Native_Status
   with Convention => C;

   function Create_Autorelease_Pool return System.Address
   with Import, Convention => C,
        External_Name => "a11y_nsax_create_autorelease_pool";

   procedure Drain_Autorelease_Pool (Pool : System.Address)
   with Import, Convention => C,
        External_Name => "a11y_nsax_drain_autorelease_pool";

   function Retain_Object (Object : System.Address) return System.Address
   with Import, Convention => C, External_Name => "a11y_nsax_retain_object";

   procedure Release_Object (Object : System.Address)
   with Import, Convention => C, External_Name => "a11y_nsax_release_object";

   function Copy_UTF8_String (Text : System.Address) return System.Address
   with Import, Convention => C, External_Name => "a11y_nsax_copy_utf8_string";

   function Copy_UInt32_Array
     (Items : access constant Native_UInt32;
      Count : Native_UInt64)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_nsax_copy_uint32_array";

   function Create_Virtual_Element
     (Callback : NSAX_Callback;
      Session  : Native_UInt64;
      Node     : Native_UInt64;
      Context  : System.Address)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_nsax_create_virtual_element";

   function Create_Virtual_Element_With_Value_Callback
     (Callback       : NSAX_Callback;
      Value_Callback : NSAX_Value_Callback;
      Session        : Native_UInt64;
      Node           : Native_UInt64;
      Context        : System.Address)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_nsax_create_virtual_element_with_value_callback";

   function Create_Virtual_Element_With_Callbacks
     (Callback        : NSAX_Callback;
      Value_Callback  : NSAX_Value_Callback;
      Object_Callback : NSAX_Object_Callback;
      Session         : Native_UInt64;
      Node            : Native_UInt64;
      Context         : System.Address)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_nsax_create_virtual_element_with_callbacks";

   function Install_Process_Root
     (Callback        : NSAX_Callback;
      Value_Callback  : NSAX_Value_Callback;
      Object_Callback : NSAX_Object_Callback;
      Session         : Native_UInt64;
      Node            : Native_UInt64;
      Context         : System.Address)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_nsax_install_process_root";

   function Virtual_Element_Matches
     (Object  : System.Address;
      Session : Native_UInt64;
      Node    : Native_UInt64)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_nsax_virtual_element_matches";

   function Probe_Virtual_Element_Bridge
     (Callback : NSAX_Callback;
      Session  : Native_UInt64;
      Node     : Native_UInt64;
      Context  : System.Address)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_nsax_probe_virtual_element_bridge";

   function Probe_Value_Returning_Virtual_Element_Bridge
     (Callback       : NSAX_Callback;
      Value_Callback : NSAX_Value_Callback;
      Session        : Native_UInt64;
      Node           : Native_UInt64;
      Context        : System.Address)
      return Native_UInt32
   with Import, Convention => C,
        External_Name =>
          "a11y_nsax_probe_value_returning_virtual_element_bridge";

   function Probe_Object_Returning_Virtual_Element_Bridge
     (Callback        : NSAX_Callback;
      Value_Callback  : NSAX_Value_Callback;
      Object_Callback : NSAX_Object_Callback;
      Session         : Native_UInt64;
      Node            : Native_UInt64;
      Context         : System.Address)
      return Native_UInt32
   with Import, Convention => C,
        External_Name =>
          "a11y_nsax_probe_object_returning_virtual_element_bridge";

   function Probe_Public_AX_Client_For_PID
     (Process_Id : Native_Int)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_nsax_probe_public_ax_client_for_pid";

   function Dispatch_Selector
     (Callback : NSAX_Callback;
      Session  : Native_UInt64;
      Node     : Native_UInt64;
      Selector : Native_UInt32;
      Context  : System.Address)
      return Native_Status
   with Import, Convention => C, External_Name => "a11y_nsax_dispatch_selector";

   function Dispatch_Selector_Frame
     (Callback : NSAX_Callback;
      Frame    : access constant Native_UInt64;
      Context  : System.Address)
      return Native_Status
   with Import, Convention => C,
        External_Name => "a11y_nsax_dispatch_selector_frame";

   function Post_Notification
     (Callback     : NSAX_Callback;
      Session      : Native_UInt64;
      Node         : Native_UInt64;
      Notification : Native_UInt32;
      Context      : System.Address)
      return Native_Status
   with Import, Convention => C, External_Name => "a11y_nsax_post_notification";

   function Post_Notification_For_Object
     (Object       : System.Address;
      Notification : Native_UInt32)
      return Native_Status
   with Import, Convention => C,
        External_Name => "a11y_nsax_post_notification_for_object";

end A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
