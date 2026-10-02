with Interfaces;
with Interfaces.C;
with System;

package A11y.Windows_Backend.UIA_Native_Bridge is

   subtype Native_UInt32 is Interfaces.Unsigned_32;
   subtype Native_UInt64 is Interfaces.Unsigned_64;
   subtype Native_Int64 is Interfaces.Integer_64;
   subtype Native_UTF16_Unit is Interfaces.Unsigned_16;

   type Native_HResult is new Interfaces.Integer_32;

   E_Fail : constant Native_HResult := -2_147_467_259;

   type Client_Runtime_Probe is record
      Coinitialized            : Native_UInt32 := 0;
      Automation_Created       : Native_UInt32 := 0;
      Root_Element_Obtained    : Native_UInt32 := 0;
      Root_Name_Obtained       : Native_UInt32 := 0;
      Client_Runtime_Available : Native_UInt32 := 0;
      CoInitialize_HResult     : Native_HResult := 0;
      CoCreate_HResult         : Native_HResult := 0;
      Get_Root_HResult         : Native_HResult := 0;
      Get_Name_HResult         : Native_HResult := 0;
   end record
   with Convention => C;

   type Host_Window_Probe is record
      Window_Class_Registered            : Native_UInt32 := 0;
      Window_Created                     : Native_UInt32 := 0;
      WM_GetObject_Sent                  : Native_UInt32 := 0;
      UIA_Root_Object_Id_Matched         : Native_UInt32 := 0;
      Return_Raw_Element_Provider_Called : Native_UInt32 := 0;
      Null_Provider_Returned_Zero        : Native_UInt32 := 0;
      Window_Destroyed                   : Native_UInt32 := 0;
      Register_Error                     : Native_HResult := 0;
      Create_Error                       : Native_HResult := 0;
      Return_Raw_Element_Provider_LResult : Native_HResult := 0;
   end record
   with Convention => C;

   type Minimal_Provider_Host_Window_Probe is record
      Coinitialized                     : Native_UInt32 := 0;
      Window_Class_Registered           : Native_UInt32 := 0;
      Window_Created                    : Native_UInt32 := 0;
      Provider_Created                  : Native_UInt32 := 0;
      WM_GetObject_Sent                 : Native_UInt32 := 0;
      UIA_Root_Object_Id_Matched        : Native_UInt32 := 0;
      Return_Raw_Element_Provider_Called : Native_UInt32 := 0;
      Return_Raw_Element_Provider_Nonzero : Native_UInt32 := 0;
      Provider_Query_Interface_Called   : Native_UInt32 := 0;
      Provider_Add_Ref_Called           : Native_UInt32 := 0;
      Provider_Release_Called           : Native_UInt32 := 0;
      Provider_Options_Called           : Native_UInt32 := 0;
      Element_From_Handle_Called        : Native_UInt32 := 0;
      Element_From_Handle_Succeeded     : Native_UInt32 := 0;
      Window_Destroyed                  : Native_UInt32 := 0;
      Provider_Final_Ref_Count          : Native_UInt32 := 0;
      CoInitialize_HResult              : Native_HResult := 0;
      Register_Error                    : Native_HResult := 0;
      Create_Error                      : Native_HResult := 0;
      Return_Raw_Element_Provider_LResult : Native_HResult := 0;
      CoCreate_HResult                  : Native_HResult := 0;
      Element_From_Handle_HResult       : Native_HResult := 0;
   end record
   with Convention => C;

   type Callback_Provider_Host_Window_Probe is record
      Coinitialized                     : Native_UInt32 := 0;
      Window_Class_Registered           : Native_UInt32 := 0;
      Window_Created                    : Native_UInt32 := 0;
      Provider_Created                  : Native_UInt32 := 0;
      WM_GetObject_Sent                 : Native_UInt32 := 0;
      UIA_Root_Object_Id_Matched        : Native_UInt32 := 0;
      Return_Raw_Element_Provider_Called : Native_UInt32 := 0;
      Return_Raw_Element_Provider_Nonzero : Native_UInt32 := 0;
      Provider_Query_Interface_Called   : Native_UInt32 := 0;
      Provider_Add_Ref_Called           : Native_UInt32 := 0;
      Provider_Release_Called           : Native_UInt32 := 0;
      Provider_Options_Called           : Native_UInt32 := 0;
      Provider_Options_Callback_Called  : Native_UInt32 := 0;
      Provider_Options_Callback_Succeeded : Native_UInt32 := 0;
      Pattern_Provider_Called           : Native_UInt32 := 0;
      Pattern_Provider_Callback_Called  : Native_UInt32 := 0;
      Pattern_Provider_Callback_Succeeded : Native_UInt32 := 0;
      Pattern_Provider_Support_Callback_Called : Native_UInt32 := 0;
      Pattern_Provider_Support_Callback_Succeeded : Native_UInt32 := 0;
      Pattern_Provider_Returned_Invoke  : Native_UInt32 := 0;
      Pattern_Provider_Returned_Toggle  : Native_UInt32 := 0;
      Pattern_Provider_Returned_Expand_Collapse : Native_UInt32 := 0;
      Pattern_Provider_Returned_Scroll_Item : Native_UInt32 := 0;
      Pattern_Provider_Returned_Selection_Item : Native_UInt32 := 0;
      Pattern_Provider_Returned_Range_Value : Native_UInt32 := 0;
      Pattern_Provider_Returned_Window : Native_UInt32 := 0;
      Invoke_Provider_Invoke_Called     : Native_UInt32 := 0;
      Invoke_Provider_Invoke_Callback_Called : Native_UInt32 := 0;
      Invoke_Provider_Invoke_Callback_Succeeded : Native_UInt32 := 0;
      Toggle_Provider_Toggle_Called     : Native_UInt32 := 0;
      Toggle_Provider_Toggle_Callback_Called : Native_UInt32 := 0;
      Toggle_Provider_Toggle_Callback_Succeeded : Native_UInt32 := 0;
      Toggle_Provider_Get_State_Called : Native_UInt32 := 0;
      Toggle_Provider_Get_State_Callback_Called : Native_UInt32 := 0;
      Toggle_Provider_Get_State_Callback_Succeeded : Native_UInt32 := 0;
      Toggle_Provider_State : Native_UInt32 := 0;
      Expand_Collapse_Provider_Expand_Called : Native_UInt32 := 0;
      Expand_Collapse_Provider_Expand_Callback_Called : Native_UInt32 := 0;
      Expand_Collapse_Provider_Expand_Callback_Succeeded :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Collapse_Called : Native_UInt32 := 0;
      Expand_Collapse_Provider_Collapse_Callback_Called :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Collapse_Callback_Succeeded :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Get_State_Called : Native_UInt32 := 0;
      Expand_Collapse_Provider_Get_State_Callback_Called :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Get_State_Callback_Succeeded :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_State : Native_UInt32 := 0;
      Scroll_Item_Provider_Scroll_Into_View_Called : Native_UInt32 := 0;
      Scroll_Item_Provider_Scroll_Into_View_Callback_Called :
        Native_UInt32 := 0;
      Scroll_Item_Provider_Scroll_Into_View_Callback_Succeeded :
        Native_UInt32 := 0;
      Selection_Item_Provider_Select_Called : Native_UInt32 := 0;
      Selection_Item_Provider_Select_Callback_Called : Native_UInt32 := 0;
      Selection_Item_Provider_Select_Callback_Succeeded :
        Native_UInt32 := 0;
      Selection_Item_Provider_Add_To_Selection_Called : Native_UInt32 := 0;
      Selection_Item_Provider_Add_To_Selection_Callback_Called :
        Native_UInt32 := 0;
      Selection_Item_Provider_Add_To_Selection_Callback_Succeeded :
        Native_UInt32 := 0;
      Selection_Item_Provider_Remove_From_Selection_Called :
        Native_UInt32 := 0;
      Selection_Item_Provider_Remove_From_Selection_Callback_Called :
        Native_UInt32 := 0;
      Selection_Item_Provider_Remove_From_Selection_Callback_Succeeded :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Is_Selected_Called : Native_UInt32 := 0;
      Selection_Item_Provider_Get_Is_Selected_Callback_Called :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Is_Selected_Callback_Succeeded :
        Native_UInt32 := 0;
      Selection_Item_Provider_Is_Selected : Native_UInt32 := 0;
      Selection_Item_Provider_Get_Selection_Container_Called :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Selection_Container_Callback_Called :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Selection_Container_Callback_Succeeded :
        Native_UInt32 := 0;
      Selection_Item_Provider_Returned_Selection_Container :
        Native_UInt32 := 0;
      Range_Value_Provider_Set_Value_Called : Native_UInt32 := 0;
      Range_Value_Provider_Set_Value_Callback_Called : Native_UInt32 := 0;
      Range_Value_Provider_Set_Value_Callback_Succeeded : Native_UInt32 := 0;
      Range_Value_Provider_Get_Value_Callback_Succeeded : Native_UInt32 := 0;
      Range_Value_Provider_Get_Is_Read_Only_Callback_Succeeded :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Maximum_Callback_Succeeded :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Minimum_Callback_Succeeded :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Large_Change_Callback_Succeeded :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Small_Change_Callback_Succeeded :
        Native_UInt32 := 0;
      Window_Provider_Close_Called : Native_UInt32 := 0;
      Window_Provider_Close_Callback_Called : Native_UInt32 := 0;
      Window_Provider_Close_Callback_Succeeded : Native_UInt32 := 0;
      Window_Provider_Get_Can_Maximize_Callback_Succeeded :
        Native_UInt32 := 0;
      Window_Provider_Get_Can_Minimize_Callback_Succeeded :
        Native_UInt32 := 0;
      Window_Provider_Get_Is_Modal_Callback_Succeeded : Native_UInt32 := 0;
      Window_Provider_Get_Visual_State_Callback_Succeeded :
        Native_UInt32 := 0;
      Window_Provider_Get_Interaction_State_Callback_Succeeded :
        Native_UInt32 := 0;
      Advise_Events_Advise_Called        : Native_UInt32 := 0;
      Advise_Events_Advise_Callback_Called : Native_UInt32 := 0;
      Advise_Events_Advise_Callback_Succeeded : Native_UInt32 := 0;
      Advise_Events_Unadvise_Called      : Native_UInt32 := 0;
      Advise_Events_Unadvise_Callback_Called : Native_UInt32 := 0;
      Advise_Events_Unadvise_Callback_Succeeded : Native_UInt32 := 0;
      Property_Value_Called             : Native_UInt32 := 0;
      Property_Value_Callback_Called    : Native_UInt32 := 0;
      Property_Value_Callback_Succeeded : Native_UInt32 := 0;
      Host_Raw_Element_Provider_Called  : Native_UInt32 := 0;
      Host_Raw_Element_Provider_Callback_Called : Native_UInt32 := 0;
      Host_Raw_Element_Provider_Callback_Succeeded : Native_UInt32 := 0;
      Host_Raw_Element_Provider_Returned_Host : Native_UInt32 := 0;
      Fragment_Query_Interface_Called   : Native_UInt32 := 0;
      Fragment_Query_Interface_Succeeded : Native_UInt32 := 0;
      Fragment_Navigate_Called          : Native_UInt32 := 0;
      Fragment_Navigate_Callback_Called : Native_UInt32 := 0;
      Fragment_Navigate_Callback_Succeeded : Native_UInt32 := 0;
      Fragment_Runtime_Id_Called        : Native_UInt32 := 0;
      Fragment_Runtime_Id_Callback_Called : Native_UInt32 := 0;
      Fragment_Runtime_Id_Callback_Succeeded : Native_UInt32 := 0;
      Fragment_Bounding_Rectangle_Called : Native_UInt32 := 0;
      Fragment_Bounding_Rectangle_Callback_Called : Native_UInt32 := 0;
      Fragment_Bounding_Rectangle_Callback_Succeeded : Native_UInt32 := 0;
      Fragment_Embedded_Roots_Called     : Native_UInt32 := 0;
      Fragment_Embedded_Roots_Callback_Called : Native_UInt32 := 0;
      Fragment_Embedded_Roots_Callback_Succeeded : Native_UInt32 := 0;
      Fragment_Set_Focus_Called          : Native_UInt32 := 0;
      Fragment_Set_Focus_Callback_Called : Native_UInt32 := 0;
      Fragment_Set_Focus_Callback_Succeeded : Native_UInt32 := 0;
      Fragment_Root_Called               : Native_UInt32 := 0;
      Fragment_Root_Callback_Called      : Native_UInt32 := 0;
      Fragment_Root_Callback_Succeeded   : Native_UInt32 := 0;
      Fragment_Root_Query_Interface_Called : Native_UInt32 := 0;
      Fragment_Root_Query_Interface_Succeeded : Native_UInt32 := 0;
      Root_From_Point_Called             : Native_UInt32 := 0;
      Root_From_Point_Callback_Called    : Native_UInt32 := 0;
      Root_From_Point_Callback_Succeeded : Native_UInt32 := 0;
      Root_From_Point_Returned_Fragment  : Native_UInt32 := 0;
      Root_Get_Focus_Called              : Native_UInt32 := 0;
      Root_Get_Focus_Callback_Called     : Native_UInt32 := 0;
      Root_Get_Focus_Callback_Succeeded  : Native_UInt32 := 0;
      Root_Get_Focus_Returned_Fragment   : Native_UInt32 := 0;
      Full_Frame_Callback_Called         : Native_UInt32 := 0;
      Full_Frame_Callback_Succeeded      : Native_UInt32 := 0;
      Full_Frame_Simple_Count            : Native_UInt32 := 0;
      Full_Frame_Fragment_Count          : Native_UInt32 := 0;
      Full_Frame_Root_Count              : Native_UInt32 := 0;
      Full_Frame_Advise_Events_Count     : Native_UInt32 := 0;
      Window_Destroyed                  : Native_UInt32 := 0;
      Provider_Final_Ref_Count          : Native_UInt32 := 0;
      Options_Callback_Session          : Native_UInt64 := 0;
      Options_Callback_Provider         : Native_UInt64 := 0;
      Options_Callback_Method           : Native_UInt32 := 0;
      Options_Callback_HResult          : Native_UInt32 := 0;
      Property_Callback_Session         : Native_UInt64 := 0;
      Property_Callback_Provider        : Native_UInt64 := 0;
      Property_Callback_Method          : Native_UInt32 := 0;
      Property_Callback_HResult         : Native_UInt32 := 0;
      Pattern_Callback_Session          : Native_UInt64 := 0;
      Pattern_Callback_Provider         : Native_UInt64 := 0;
      Pattern_Callback_Method           : Native_UInt32 := 0;
      Pattern_Callback_HResult          : Native_UInt32 := 0;
      Host_Callback_Session             : Native_UInt64 := 0;
      Host_Callback_Provider            : Native_UInt64 := 0;
      Host_Callback_Method              : Native_UInt32 := 0;
      Host_Callback_HResult             : Native_UInt32 := 0;
      Fragment_Navigate_Callback_Method : Native_UInt32 := 0;
      Fragment_Navigate_Callback_HResult : Native_UInt32 := 0;
      Fragment_Runtime_Id_Callback_Method : Native_UInt32 := 0;
      Fragment_Runtime_Id_Callback_HResult : Native_UInt32 := 0;
      Fragment_Bounding_Rectangle_Callback_Method : Native_UInt32 := 0;
      Fragment_Bounding_Rectangle_Callback_HResult : Native_UInt32 := 0;
      Fragment_Embedded_Roots_Callback_Method : Native_UInt32 := 0;
      Fragment_Embedded_Roots_Callback_HResult : Native_UInt32 := 0;
      Fragment_Set_Focus_Callback_Method : Native_UInt32 := 0;
      Fragment_Set_Focus_Callback_HResult : Native_UInt32 := 0;
      Fragment_Root_Callback_Method      : Native_UInt32 := 0;
      Fragment_Root_Callback_HResult     : Native_UInt32 := 0;
      Root_From_Point_Callback_Method    : Native_UInt32 := 0;
      Root_From_Point_Callback_HResult   : Native_UInt32 := 0;
      Root_Get_Focus_Callback_Method     : Native_UInt32 := 0;
      Root_Get_Focus_Callback_HResult    : Native_UInt32 := 0;
      Invoke_Provider_Invoke_Callback_Method : Native_UInt32 := 0;
      Invoke_Provider_Invoke_Callback_HResult : Native_UInt32 := 0;
      Toggle_Provider_Toggle_Callback_Method : Native_UInt32 := 0;
      Toggle_Provider_Toggle_Callback_HResult : Native_UInt32 := 0;
      Toggle_Provider_Get_State_Callback_HResult : Native_UInt32 := 0;
      Expand_Collapse_Provider_Expand_Callback_Method :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Expand_Callback_HResult :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Collapse_Callback_Method :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Collapse_Callback_HResult :
        Native_UInt32 := 0;
      Expand_Collapse_Provider_Get_State_Callback_HResult :
        Native_UInt32 := 0;
      Scroll_Item_Provider_Scroll_Into_View_Callback_Method :
        Native_UInt32 := 0;
      Scroll_Item_Provider_Scroll_Into_View_Callback_HResult :
        Native_UInt32 := 0;
      Selection_Item_Provider_Select_Callback_Method : Native_UInt32 := 0;
      Selection_Item_Provider_Select_Callback_HResult : Native_UInt32 := 0;
      Selection_Item_Provider_Add_To_Selection_Callback_Method :
        Native_UInt32 := 0;
      Selection_Item_Provider_Add_To_Selection_Callback_HResult :
        Native_UInt32 := 0;
      Selection_Item_Provider_Remove_From_Selection_Callback_Method :
        Native_UInt32 := 0;
      Selection_Item_Provider_Remove_From_Selection_Callback_HResult :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Is_Selected_Callback_Method :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Is_Selected_Callback_HResult :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Selection_Container_Callback_Method :
        Native_UInt32 := 0;
      Selection_Item_Provider_Get_Selection_Container_Callback_HResult :
        Native_UInt32 := 0;
      Range_Value_Provider_Set_Value_Callback_Method : Native_UInt32 := 0;
      Range_Value_Provider_Set_Value_Callback_HResult : Native_UInt32 := 0;
      Range_Value_Provider_Get_Value_Callback_Method : Native_UInt32 := 0;
      Range_Value_Provider_Get_Value_Callback_HResult : Native_UInt32 := 0;
      Range_Value_Provider_Get_Is_Read_Only_Callback_Method :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Is_Read_Only_Callback_HResult :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Maximum_Callback_Method : Native_UInt32 := 0;
      Range_Value_Provider_Get_Maximum_Callback_HResult : Native_UInt32 := 0;
      Range_Value_Provider_Get_Minimum_Callback_Method : Native_UInt32 := 0;
      Range_Value_Provider_Get_Minimum_Callback_HResult : Native_UInt32 := 0;
      Range_Value_Provider_Get_Large_Change_Callback_Method :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Large_Change_Callback_HResult :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Small_Change_Callback_Method :
        Native_UInt32 := 0;
      Range_Value_Provider_Get_Small_Change_Callback_HResult :
        Native_UInt32 := 0;
      Window_Provider_Close_Callback_Method : Native_UInt32 := 0;
      Window_Provider_Close_Callback_HResult : Native_UInt32 := 0;
      Window_Provider_Get_Can_Maximize_Callback_Method : Native_UInt32 := 0;
      Window_Provider_Get_Can_Maximize_Callback_HResult : Native_UInt32 := 0;
      Window_Provider_Get_Can_Minimize_Callback_Method : Native_UInt32 := 0;
      Window_Provider_Get_Can_Minimize_Callback_HResult : Native_UInt32 := 0;
      Window_Provider_Get_Is_Modal_Callback_Method : Native_UInt32 := 0;
      Window_Provider_Get_Is_Modal_Callback_HResult : Native_UInt32 := 0;
      Window_Provider_Get_Visual_State_Callback_Method : Native_UInt32 := 0;
      Window_Provider_Get_Visual_State_Callback_HResult : Native_UInt32 := 0;
      Window_Provider_Get_Interaction_State_Callback_Method :
        Native_UInt32 := 0;
      Window_Provider_Get_Interaction_State_Callback_HResult :
        Native_UInt32 := 0;
      Advise_Events_Advise_Callback_Method : Native_UInt32 := 0;
      Advise_Events_Advise_Callback_HResult : Native_UInt32 := 0;
      Advise_Events_Unadvise_Callback_Method : Native_UInt32 := 0;
      Advise_Events_Unadvise_Callback_HResult : Native_UInt32 := 0;
      Full_Frame_Session                 : Native_UInt64 := 0;
      Full_Frame_Provider                : Native_UInt64 := 0;
      Full_Frame_Object_Token            : Native_UInt64 := 0;
      Full_Frame_Interface               : Native_UInt64 := 0;
      Full_Frame_Method                  : Native_UInt64 := 0;
      Full_Frame_Direction               : Native_UInt64 := 0;
      Full_Frame_Point_X                 : Native_UInt64 := 0;
      Full_Frame_Point_Y                 : Native_UInt64 := 0;
      Full_Frame_HResult                 : Native_UInt32 := 0;
      CoInitialize_HResult              : Native_HResult := 0;
      Register_Error                    : Native_HResult := 0;
      Create_Error                      : Native_HResult := 0;
      Return_Raw_Element_Provider_LResult : Native_HResult := 0;
      Provider_Options_HResult          : Native_HResult := 0;
      Property_Value_HResult            : Native_HResult := 0;
      Pattern_Provider_HResult          : Native_HResult := 0;
      Host_Raw_Element_Provider_HResult : Native_HResult := 0;
      Fragment_Navigate_HResult         : Native_HResult := 0;
      Fragment_Runtime_Id_HResult       : Native_HResult := 0;
      Fragment_Bounding_Rectangle_HResult : Native_HResult := 0;
      Fragment_Embedded_Roots_HResult   : Native_HResult := 0;
      Fragment_Set_Focus_HResult        : Native_HResult := 0;
      Fragment_Root_HResult             : Native_HResult := 0;
      Root_From_Point_HResult           : Native_HResult := 0;
      Root_Get_Focus_HResult            : Native_HResult := 0;
      Invoke_Provider_Invoke_HResult    : Native_HResult := 0;
      Toggle_Provider_Toggle_HResult    : Native_HResult := 0;
      Toggle_Provider_Get_State_HResult : Native_HResult := 0;
      Expand_Collapse_Provider_Expand_HResult : Native_HResult := 0;
      Expand_Collapse_Provider_Collapse_HResult : Native_HResult := 0;
      Expand_Collapse_Provider_Get_State_HResult : Native_HResult := 0;
      Scroll_Item_Provider_Scroll_Into_View_HResult : Native_HResult := 0;
      Selection_Item_Provider_Select_HResult : Native_HResult := 0;
      Selection_Item_Provider_Add_To_Selection_HResult : Native_HResult := 0;
      Selection_Item_Provider_Remove_From_Selection_HResult :
        Native_HResult := 0;
      Selection_Item_Provider_Get_Is_Selected_HResult : Native_HResult := 0;
      Selection_Item_Provider_Get_Selection_Container_HResult :
        Native_HResult := 0;
      Range_Value_Provider_Set_Value_HResult : Native_HResult := 0;
      Range_Value_Provider_Get_Value_HResult : Native_HResult := 0;
      Range_Value_Provider_Get_Is_Read_Only_HResult : Native_HResult := 0;
      Range_Value_Provider_Get_Maximum_HResult : Native_HResult := 0;
      Range_Value_Provider_Get_Minimum_HResult : Native_HResult := 0;
      Range_Value_Provider_Get_Large_Change_HResult : Native_HResult := 0;
      Range_Value_Provider_Get_Small_Change_HResult : Native_HResult := 0;
      Window_Provider_Close_HResult : Native_HResult := 0;
      Window_Provider_Get_Can_Maximize_HResult : Native_HResult := 0;
      Window_Provider_Get_Can_Minimize_HResult : Native_HResult := 0;
      Window_Provider_Get_Is_Modal_HResult : Native_HResult := 0;
      Window_Provider_Get_Visual_State_HResult : Native_HResult := 0;
      Window_Provider_Get_Interaction_State_HResult : Native_HResult := 0;
      Advise_Events_Advise_HResult       : Native_HResult := 0;
      Advise_Events_Unadvise_HResult     : Native_HResult := 0;
   end record
   with Convention => C;

   type UIA_Callback is access function
     (Session  : Native_UInt64;
      Provider : Native_UInt64;
      Method   : Native_UInt32;
      Context  : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Frame_Callback is access function
     (Frame   : access constant Native_UInt64;
      Context : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Value_Callback is access function
     (Frame            : access constant Native_UInt64;
      Native_Property  : Native_UInt32;
      Value_Kind       : access Native_UInt32;
      UTF8_Buffer      : System.Address;
      UTF8_Capacity    : Native_UInt32;
      UTF8_Used        : access Native_UInt32;
      Context          : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_UInt32_Array_Callback is access function
     (Frame       : access constant Native_UInt64;
      Value_Kind  : access Native_UInt32;
      Items       : System.Address;
      Capacity    : Native_UInt32;
      Used        : access Native_UInt32;
      Context     : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Rectangle_Callback is access function
     (Frame   : access constant Native_UInt64;
      Left    : access Interfaces.C.double;
      Top     : access Interfaces.C.double;
      Width   : access Interfaces.C.double;
      Height  : access Interfaces.C.double;
      Context : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Boolean_Callback is access function
     (Frame   : access constant Native_UInt64;
      Value   : access Native_UInt32;
      Context : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Pattern_Callback is access function
     (Frame          : access constant Native_UInt64;
      Native_Pattern : Native_UInt32;
      Supported      : access Native_UInt32;
      Context        : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_State_Callback is access function
     (Frame             : access constant Native_UInt64;
      Native_State_Kind : Native_UInt32;
      State             : access Native_UInt32;
      Context           : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Range_Value_Callback is access function
     (Frame   : access constant Native_UInt64;
      Value   : Interfaces.C.double;
      Context : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Range_Value_Query_Callback is access function
     (Frame         : access constant Native_UInt64;
      Numeric_Value : access Interfaces.C.double;
      Boolean_Value : access Native_UInt32;
      Context       : System.Address)
      return Native_UInt32
   with Convention => C;

   type UIA_Window_Query_Callback is access function
     (Frame   : access constant Native_UInt64;
      Value   : access Native_UInt32;
      Context : System.Address)
      return Native_UInt32
   with Convention => C;

   function Query_Interface
     (Callback     : UIA_Callback;
      Session      : Native_UInt64;
      Provider     : Native_UInt64;
      Interface_Id : Native_UInt32;
      Context      : System.Address)
      return Native_UInt32
   with Import, Convention => C, External_Name => "a11y_uia_query_interface";

   function Add_Ref
     (Callback : UIA_Callback;
      Session  : Native_UInt64;
      Provider : Native_UInt64;
      Context  : System.Address)
      return Native_UInt32
   with Import, Convention => C, External_Name => "a11y_uia_add_ref";

   function Release
     (Callback : UIA_Callback;
      Session  : Native_UInt64;
      Provider : Native_UInt64;
      Context  : System.Address)
      return Native_UInt32
   with Import, Convention => C, External_Name => "a11y_uia_release";

   function Dispatch_Provider_Method
     (Callback : UIA_Callback;
      Session  : Native_UInt64;
      Provider : Native_UInt64;
      Method   : Native_UInt32;
      Context  : System.Address)
      return Native_HResult
   with Import, Convention => C,
        External_Name => "a11y_uia_dispatch_provider_method";

   function Dispatch_Provider_Frame
     (Callback : UIA_Callback;
      Frame    : access constant Native_UInt64;
      Context  : System.Address)
      return Native_HResult
   with Import, Convention => C,
        External_Name => "a11y_uia_dispatch_provider_frame";

   function Dispatch_Provider_Full_Frame
     (Callback : UIA_Frame_Callback;
      Frame    : access constant Native_UInt64;
      Context  : System.Address)
      return Native_HResult
   with Import, Convention => C,
        External_Name => "a11y_uia_dispatch_provider_full_frame";

   function Copy_BSTR
     (Text  : access constant Native_UTF16_Unit;
      Units : Native_UInt64)
      return System.Address
   with Import, Convention => C, External_Name => "a11y_uia_copy_bstr";

   procedure Destroy_BSTR (Text : System.Address)
   with Import, Convention => C, External_Name => "a11y_uia_destroy_bstr";

   function Copy_UInt32_SAFEARRAY
     (Items : access constant Native_UInt32;
      Count : Native_UInt64)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_uia_copy_uint32_safearray";

   procedure Destroy_SAFEARRAY (Items : System.Address)
   with Import, Convention => C, External_Name => "a11y_uia_destroy_safearray";

   function Translate_HResult (Status : Native_HResult) return Native_HResult
   with Import, Convention => C, External_Name => "a11y_uia_translate_hresult";

   function Bridge_Is_Windows return Native_UInt32
   with Import, Convention => C, External_Name => "a11y_uia_bridge_is_windows";

   function Probe_Client_Runtime
     (Report : access Client_Runtime_Probe)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_uia_probe_client_runtime";

   function Probe_Host_Window_Handshake
     (Report : access Host_Window_Probe)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_uia_probe_host_window_handshake";

   function Probe_Minimal_Provider_Host_Window
     (Report : access Minimal_Provider_Host_Window_Probe)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_uia_probe_minimal_provider_host_window";

   function Probe_Callback_Provider_Host_Window
     (Session                 : Native_UInt64;
      Provider                : Native_UInt64;
      Object_Token            : Native_UInt64;
      Provider_Options_Method : Native_UInt32;
      Pattern_Provider_Method : Native_UInt32;
      Property_Value_Method   : Native_UInt32;
      Host_Raw_Element_Provider_Method : Native_UInt32;
      Fragment_Navigate_Method : Native_UInt32;
      Fragment_Runtime_Id_Method : Native_UInt32;
      Fragment_Bounding_Rectangle_Method : Native_UInt32;
      Fragment_Embedded_Roots_Method : Native_UInt32;
      Fragment_Set_Focus_Method : Native_UInt32;
      Fragment_Root_Method : Native_UInt32;
      Root_From_Point_Method : Native_UInt32;
      Root_Get_Focus_Method : Native_UInt32;
      Invoke_Provider_Invoke_Method : Native_UInt32;
      Toggle_Provider_Toggle_Method : Native_UInt32;
      Expand_Collapse_Provider_Expand_Method : Native_UInt32;
      Expand_Collapse_Provider_Collapse_Method : Native_UInt32;
      Scroll_Item_Provider_Scroll_Into_View_Method : Native_UInt32;
      Selection_Item_Provider_Select_Method : Native_UInt32;
      Selection_Item_Provider_Add_To_Selection_Method : Native_UInt32;
      Selection_Item_Provider_Remove_From_Selection_Method : Native_UInt32;
      Selection_Item_Provider_Get_Is_Selected_Method : Native_UInt32;
      Selection_Item_Provider_Get_Selection_Container_Method : Native_UInt32;
      Range_Value_Provider_Set_Value_Method : Native_UInt32;
      Range_Value_Provider_Get_Value_Method : Native_UInt32;
      Range_Value_Provider_Get_Is_Read_Only_Method : Native_UInt32;
      Range_Value_Provider_Get_Maximum_Method : Native_UInt32;
      Range_Value_Provider_Get_Minimum_Method : Native_UInt32;
      Range_Value_Provider_Get_Large_Change_Method : Native_UInt32;
      Range_Value_Provider_Get_Small_Change_Method : Native_UInt32;
      Window_Provider_Close_Method : Native_UInt32;
      Window_Provider_Get_Can_Maximize_Method : Native_UInt32;
      Window_Provider_Get_Can_Minimize_Method : Native_UInt32;
      Window_Provider_Get_Is_Modal_Method : Native_UInt32;
      Window_Provider_Get_Visual_State_Method : Native_UInt32;
      Window_Provider_Get_Interaction_State_Method : Native_UInt32;
      Advise_Events_Advise_Method : Native_UInt32;
      Advise_Events_Unadvise_Method : Native_UInt32;
      Callback                : UIA_Callback;
      Frame_Callback          : UIA_Frame_Callback;
      Value_Callback          : UIA_Value_Callback;
      UInt32_Array_Callback   : UIA_UInt32_Array_Callback;
      Rectangle_Callback      : UIA_Rectangle_Callback;
      Boolean_Callback        : UIA_Boolean_Callback;
      Pattern_Callback        : UIA_Pattern_Callback;
      State_Callback          : UIA_State_Callback;
      Range_Value_Callback    : UIA_Range_Value_Callback;
      Range_Value_Query_Callback : UIA_Range_Value_Query_Callback;
      Window_Query_Callback   : UIA_Window_Query_Callback;
      Context                 : System.Address;
      Report                  : access Callback_Provider_Host_Window_Probe)
      return Native_UInt32
   with Import, Convention => C,
        External_Name => "a11y_uia_probe_callback_provider_host_window";

   function Create_Callback_Provider_Host_Window
     (Session                 : Native_UInt64;
      Provider                : Native_UInt64;
      Object_Token            : Native_UInt64;
      Provider_Options_Method : Native_UInt32;
      Pattern_Provider_Method : Native_UInt32;
      Property_Value_Method   : Native_UInt32;
      Host_Raw_Element_Provider_Method : Native_UInt32;
      Fragment_Navigate_Method : Native_UInt32;
      Fragment_Runtime_Id_Method : Native_UInt32;
      Fragment_Bounding_Rectangle_Method : Native_UInt32;
      Fragment_Embedded_Roots_Method : Native_UInt32;
      Fragment_Set_Focus_Method : Native_UInt32;
      Fragment_Root_Method : Native_UInt32;
      Root_From_Point_Method : Native_UInt32;
      Root_Get_Focus_Method : Native_UInt32;
      Invoke_Provider_Invoke_Method : Native_UInt32;
      Toggle_Provider_Toggle_Method : Native_UInt32;
      Expand_Collapse_Provider_Expand_Method : Native_UInt32;
      Expand_Collapse_Provider_Collapse_Method : Native_UInt32;
      Scroll_Item_Provider_Scroll_Into_View_Method : Native_UInt32;
      Selection_Item_Provider_Select_Method : Native_UInt32;
      Selection_Item_Provider_Add_To_Selection_Method : Native_UInt32;
      Selection_Item_Provider_Remove_From_Selection_Method : Native_UInt32;
      Selection_Item_Provider_Get_Is_Selected_Method : Native_UInt32;
      Selection_Item_Provider_Get_Selection_Container_Method : Native_UInt32;
      Range_Value_Provider_Set_Value_Method : Native_UInt32;
      Range_Value_Provider_Get_Value_Method : Native_UInt32;
      Range_Value_Provider_Get_Is_Read_Only_Method : Native_UInt32;
      Range_Value_Provider_Get_Maximum_Method : Native_UInt32;
      Range_Value_Provider_Get_Minimum_Method : Native_UInt32;
      Range_Value_Provider_Get_Large_Change_Method : Native_UInt32;
      Range_Value_Provider_Get_Small_Change_Method : Native_UInt32;
      Window_Provider_Close_Method : Native_UInt32;
      Window_Provider_Get_Can_Maximize_Method : Native_UInt32;
      Window_Provider_Get_Can_Minimize_Method : Native_UInt32;
      Window_Provider_Get_Is_Modal_Method : Native_UInt32;
      Window_Provider_Get_Visual_State_Method : Native_UInt32;
      Window_Provider_Get_Interaction_State_Method : Native_UInt32;
      Advise_Events_Advise_Method : Native_UInt32;
      Advise_Events_Unadvise_Method : Native_UInt32;
      Callback                : UIA_Callback;
      Frame_Callback          : UIA_Frame_Callback;
      Value_Callback          : UIA_Value_Callback;
      UInt32_Array_Callback   : UIA_UInt32_Array_Callback;
      Rectangle_Callback      : UIA_Rectangle_Callback;
      Boolean_Callback        : UIA_Boolean_Callback;
      Pattern_Callback        : UIA_Pattern_Callback;
      State_Callback          : UIA_State_Callback;
      Range_Value_Callback    : UIA_Range_Value_Callback;
      Range_Value_Query_Callback : UIA_Range_Value_Query_Callback;
      Window_Query_Callback   : UIA_Window_Query_Callback;
      Context                 : System.Address)
      return System.Address
   with Import, Convention => C,
        External_Name => "a11y_uia_create_callback_provider_host_window";

   procedure Destroy_Callback_Provider_Host_Window (Handle : System.Address)
   with Import, Convention => C,
        External_Name => "a11y_uia_destroy_callback_provider_host_window";

   function Raise_Automation_Event
     (Handle   : System.Address;
      Event_Id : Native_UInt32)
      return Native_HResult
   with Import, Convention => C,
        External_Name => "a11y_uia_raise_automation_event";

end A11y.Windows_Backend.UIA_Native_Bridge;
