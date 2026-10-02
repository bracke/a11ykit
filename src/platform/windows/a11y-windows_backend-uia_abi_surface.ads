with Interfaces;

with A11y.Results;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Provider_Boundary;

package A11y.Windows_Backend.UIA_ABI_Surface is

   type UIA_ABI_Method is
     (IUnknown_Query_Interface,
      IUnknown_Add_Ref,
      IUnknown_Release,
      Simple_Get_Provider_Options,
      Simple_Get_Pattern_Provider,
      Simple_Get_Property_Value,
      Simple_Get_Host_Raw_Element_Provider,
      Fragment_Navigate,
      Fragment_Get_Runtime_Id,
      Fragment_Get_Bounding_Rectangle,
      Fragment_Get_Embedded_Fragment_Roots,
      Fragment_Set_Focus,
      Fragment_Get_Fragment_Root,
      Fragment_Root_Element_Provider_From_Point,
      Fragment_Root_Get_Focus,
      Invoke_Provider_Invoke,
      Toggle_Provider_Toggle,
      Expand_Collapse_Provider_Expand,
      Expand_Collapse_Provider_Collapse,
      Value_Provider_Set_Value,
      Range_Value_Provider_Set_Value,
      Range_Value_Provider_Get_Value,
      Range_Value_Provider_Get_Is_Read_Only,
      Range_Value_Provider_Get_Maximum,
      Range_Value_Provider_Get_Minimum,
      Range_Value_Provider_Get_Large_Change,
      Range_Value_Provider_Get_Small_Change,
      Selection_Item_Provider_Select,
      Selection_Item_Provider_Add_To_Selection,
      Selection_Item_Provider_Remove_From_Selection,
      Selection_Item_Provider_Get_Is_Selected,
      Selection_Item_Provider_Get_Selection_Container,
      Scroll_Item_Provider_Scroll_Into_View,
      Window_Provider_Close,
      Window_Provider_Get_Can_Maximize,
      Window_Provider_Get_Can_Minimize,
      Window_Provider_Get_Is_Modal,
      Window_Provider_Get_Window_Visual_State,
      Window_Provider_Get_Window_Interaction_State,
      Advise_Events_Advise,
      Advise_Events_Unadvise);

   type ABI_Method_Descriptor is record
      Supported                : Boolean := False;
      Provider_Interface_Kind  :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Request_Kind             :
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_Request_Kind :=
          A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
      Requires_Native_Identity : Boolean := True;
      Requires_Root_Provider   : Boolean := False;
      Is_Lifetime_Method       : Boolean := False;
      Status                   : A11y.Results.Status_Code :=
        A11y.Results.Success;
   end record;

   function Descriptor
     (Method : UIA_ABI_Method)
      return ABI_Method_Descriptor;

   function Method_Name (Method : UIA_ABI_Method) return String;

   function Method_Code
     (Method : UIA_ABI_Method)
      return Interfaces.Unsigned_32;

   function Method_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return UIA_ABI_Method;

   function Can_Dispatch
     (Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Method : UIA_ABI_Method)
      return Boolean;

   function Prepare_Request
     (Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Method : UIA_ABI_Method;
      Result : out A11y.Results.Result)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request;

end A11y.Windows_Backend.UIA_ABI_Surface;
