with A11y.Node_Ids;
with A11y.Actions;
with A11y.Windows_Backend.UIA_Selection;
with A11y.Windows_Backend.UIA_Surfaces;
with A11y.Windows_Backend.UIA_Values;

package body A11y.Windows_Backend.UIA_ABI_Surface is

   use type A11y.Results.Status_Code;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;

   function Descriptor
     (Method : UIA_ABI_Method)
      return ABI_Method_Descriptor
   is
      package COM renames A11y.Windows_Backend.UIA_Com_Providers;
      package Boundary renames A11y.Windows_Backend.UIA_Provider_Boundary;
   begin
      return
        (case Method is
           when IUnknown_Query_Interface =>
             (Supported => True,
              Provider_Interface_Kind => COM.IUnknown_Interface,
              Request_Kind => Boundary.Get_Property_Value,
              Requires_Native_Identity => False,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => True,
              Status => A11y.Results.Success),
           when IUnknown_Add_Ref | IUnknown_Release =>
             (Supported => True,
              Provider_Interface_Kind => COM.IUnknown_Interface,
              Request_Kind => Boundary.Get_Property_Value,
              Requires_Native_Identity => False,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => True,
              Status => A11y.Results.Success),
           when Simple_Get_Provider_Options =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Provider_Options,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Simple_Get_Pattern_Provider =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Pattern_Provider,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Simple_Get_Property_Value =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Property_Value,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Simple_Get_Host_Raw_Element_Provider =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Host_Raw_Element_Provider,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Navigate =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment,
              Request_Kind => Boundary.Navigate_Fragment,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Get_Runtime_Id =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment,
              Request_Kind => Boundary.Get_Runtime_Id,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Get_Bounding_Rectangle =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment,
              Request_Kind => Boundary.Get_Property_Value,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Get_Embedded_Fragment_Roots =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment,
              Request_Kind => Boundary.Get_Embedded_Fragment_Roots,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Set_Focus =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment,
              Request_Kind => Boundary.Invoke_Action,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Root_Element_Provider_From_Point |
                Fragment_Root_Get_Focus =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment_Root,
              Request_Kind =>
                (if Method = Fragment_Root_Element_Provider_From_Point
                 then Boundary.Get_Fragment_From_Point
                 else Boundary.Get_Fragment_Focus),
              Requires_Native_Identity => True,
              Requires_Root_Provider => True,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Fragment_Get_Fragment_Root =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Fragment,
              Request_Kind => Boundary.Get_Fragment_Root,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Invoke_Provider_Invoke =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Invoke_Action,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Toggle_Provider_Toggle =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Invoke_Action,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Expand_Collapse_Provider_Expand |
                Expand_Collapse_Provider_Collapse |
                Scroll_Item_Provider_Scroll_Into_View |
                Window_Provider_Close =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Invoke_Action,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Window_Provider_Get_Can_Maximize |
                Window_Provider_Get_Can_Minimize |
                Window_Provider_Get_Is_Modal |
                Window_Provider_Get_Window_Visual_State |
                Window_Provider_Get_Window_Interaction_State =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Surface,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Selection_Item_Provider_Select |
                Selection_Item_Provider_Add_To_Selection |
                Selection_Item_Provider_Remove_From_Selection =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Set_Selection,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Selection_Item_Provider_Get_Is_Selected |
                Selection_Item_Provider_Get_Selection_Container =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Selection,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Range_Value_Provider_Set_Value =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Set_Value,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Range_Value_Provider_Get_Value |
                Range_Value_Provider_Get_Is_Read_Only |
                Range_Value_Provider_Get_Maximum |
                Range_Value_Provider_Get_Minimum |
                Range_Value_Provider_Get_Large_Change |
                Range_Value_Provider_Get_Small_Change =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Get_Value,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success),
           when Value_Provider_Set_Value =>
             (Supported => False,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Simple,
              Request_Kind => Boundary.Set_Value,
              Requires_Native_Identity => True,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Unsupported_Capability),
           when Advise_Events_Advise | Advise_Events_Unadvise =>
             (Supported => True,
              Provider_Interface_Kind => COM.Raw_Element_Provider_Advise_Events,
              Request_Kind =>
                (if Method = Advise_Events_Advise
                 then Boundary.Advise_Event
                 else Boundary.Unadvise_Event),
              Requires_Native_Identity => False,
              Requires_Root_Provider => False,
              Is_Lifetime_Method => False,
              Status => A11y.Results.Success));
   end Descriptor;

   function Method_Name (Method : UIA_ABI_Method) return String is
     (case Method is
        when IUnknown_Query_Interface => "IUnknown.QueryInterface",
        when IUnknown_Add_Ref => "IUnknown.AddRef",
        when IUnknown_Release => "IUnknown.Release",
        when Simple_Get_Provider_Options =>
          "IRawElementProviderSimple.get_ProviderOptions",
        when Simple_Get_Pattern_Provider =>
          "IRawElementProviderSimple.GetPatternProvider",
        when Simple_Get_Property_Value =>
          "IRawElementProviderSimple.GetPropertyValue",
        when Simple_Get_Host_Raw_Element_Provider =>
          "IRawElementProviderSimple.get_HostRawElementProvider",
        when Fragment_Navigate =>
          "IRawElementProviderFragment.Navigate",
        when Fragment_Get_Runtime_Id =>
          "IRawElementProviderFragment.GetRuntimeId",
        when Fragment_Get_Bounding_Rectangle =>
          "IRawElementProviderFragment.get_BoundingRectangle",
        when Fragment_Get_Embedded_Fragment_Roots =>
          "IRawElementProviderFragment.GetEmbeddedFragmentRoots",
        when Fragment_Set_Focus =>
          "IRawElementProviderFragment.SetFocus",
        when Fragment_Get_Fragment_Root =>
          "IRawElementProviderFragment.get_FragmentRoot",
        when Fragment_Root_Element_Provider_From_Point =>
          "IRawElementProviderFragmentRoot.ElementProviderFromPoint",
        when Fragment_Root_Get_Focus =>
          "IRawElementProviderFragmentRoot.GetFocus",
        when Invoke_Provider_Invoke =>
          "IInvokeProvider.Invoke",
        when Toggle_Provider_Toggle =>
          "IToggleProvider.Toggle",
        when Expand_Collapse_Provider_Expand =>
          "IExpandCollapseProvider.Expand",
        when Expand_Collapse_Provider_Collapse =>
          "IExpandCollapseProvider.Collapse",
        when Value_Provider_Set_Value =>
          "IValueProvider.SetValue",
        when Range_Value_Provider_Set_Value =>
          "IRangeValueProvider.SetValue",
        when Range_Value_Provider_Get_Value =>
          "IRangeValueProvider.get_Value",
        when Range_Value_Provider_Get_Is_Read_Only =>
          "IRangeValueProvider.get_IsReadOnly",
        when Range_Value_Provider_Get_Maximum =>
          "IRangeValueProvider.get_Maximum",
        when Range_Value_Provider_Get_Minimum =>
          "IRangeValueProvider.get_Minimum",
        when Range_Value_Provider_Get_Large_Change =>
          "IRangeValueProvider.get_LargeChange",
        when Range_Value_Provider_Get_Small_Change =>
          "IRangeValueProvider.get_SmallChange",
        when Selection_Item_Provider_Select =>
          "ISelectionItemProvider.Select",
        when Selection_Item_Provider_Add_To_Selection =>
          "ISelectionItemProvider.AddToSelection",
        when Selection_Item_Provider_Remove_From_Selection =>
          "ISelectionItemProvider.RemoveFromSelection",
        when Selection_Item_Provider_Get_Is_Selected =>
          "ISelectionItemProvider.get_IsSelected",
        when Selection_Item_Provider_Get_Selection_Container =>
          "ISelectionItemProvider.get_SelectionContainer",
        when Scroll_Item_Provider_Scroll_Into_View =>
          "IScrollItemProvider.ScrollIntoView",
        when Window_Provider_Close =>
          "IWindowProvider.Close",
        when Window_Provider_Get_Can_Maximize =>
          "IWindowProvider.get_CanMaximize",
        when Window_Provider_Get_Can_Minimize =>
          "IWindowProvider.get_CanMinimize",
        when Window_Provider_Get_Is_Modal =>
          "IWindowProvider.get_IsModal",
        when Window_Provider_Get_Window_Visual_State =>
          "IWindowProvider.get_WindowVisualState",
        when Window_Provider_Get_Window_Interaction_State =>
          "IWindowProvider.get_WindowInteractionState",
        when Advise_Events_Advise =>
          "IRawElementProviderAdviseEvents.AdviseEventAdded",
        when Advise_Events_Unadvise =>
          "IRawElementProviderAdviseEvents.AdviseEventRemoved");

   function Method_Code
     (Method : UIA_ABI_Method)
      return Interfaces.Unsigned_32 is
     (case Method is
        when IUnknown_Query_Interface => 1,
        when IUnknown_Add_Ref => 2,
        when IUnknown_Release => 3,
        when Simple_Get_Provider_Options => 10,
        when Simple_Get_Pattern_Provider => 11,
        when Simple_Get_Property_Value => 12,
        when Simple_Get_Host_Raw_Element_Provider => 13,
        when Fragment_Navigate => 20,
        when Fragment_Get_Runtime_Id => 21,
        when Fragment_Get_Bounding_Rectangle => 22,
        when Fragment_Get_Embedded_Fragment_Roots => 23,
        when Fragment_Set_Focus => 24,
        when Fragment_Get_Fragment_Root => 25,
        when Fragment_Root_Element_Provider_From_Point => 30,
        when Fragment_Root_Get_Focus => 31,
        when Invoke_Provider_Invoke => 50,
        when Toggle_Provider_Toggle => 51,
        when Expand_Collapse_Provider_Expand => 52,
        when Expand_Collapse_Provider_Collapse => 53,
        when Value_Provider_Set_Value => 54,
        when Range_Value_Provider_Set_Value => 55,
        when Range_Value_Provider_Get_Value => 63,
        when Range_Value_Provider_Get_Is_Read_Only => 64,
        when Range_Value_Provider_Get_Maximum => 65,
        when Range_Value_Provider_Get_Minimum => 66,
        when Range_Value_Provider_Get_Large_Change => 67,
        when Range_Value_Provider_Get_Small_Change => 68,
        when Selection_Item_Provider_Select => 56,
        when Selection_Item_Provider_Remove_From_Selection => 57,
        when Scroll_Item_Provider_Scroll_Into_View => 58,
        when Window_Provider_Close => 59,
        when Selection_Item_Provider_Add_To_Selection => 60,
        when Selection_Item_Provider_Get_Is_Selected => 61,
        when Selection_Item_Provider_Get_Selection_Container => 62,
        when Window_Provider_Get_Can_Maximize => 69,
        when Window_Provider_Get_Can_Minimize => 70,
        when Window_Provider_Get_Is_Modal => 71,
        when Window_Provider_Get_Window_Visual_State => 72,
        when Window_Provider_Get_Window_Interaction_State => 73,
        when Advise_Events_Advise => 40,
        when Advise_Events_Unadvise => 41);

   function Method_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return UIA_ABI_Method
   is
   begin
      Result := A11y.Results.Ok;
      case Code is
         when 1 => return IUnknown_Query_Interface;
         when 2 => return IUnknown_Add_Ref;
         when 3 => return IUnknown_Release;
         when 10 => return Simple_Get_Provider_Options;
         when 11 => return Simple_Get_Pattern_Provider;
         when 12 => return Simple_Get_Property_Value;
         when 13 => return Simple_Get_Host_Raw_Element_Provider;
         when 20 => return Fragment_Navigate;
         when 21 => return Fragment_Get_Runtime_Id;
         when 22 => return Fragment_Get_Bounding_Rectangle;
         when 23 => return Fragment_Get_Embedded_Fragment_Roots;
         when 24 => return Fragment_Set_Focus;
         when 25 => return Fragment_Get_Fragment_Root;
         when 30 => return Fragment_Root_Element_Provider_From_Point;
         when 31 => return Fragment_Root_Get_Focus;
         when 50 => return Invoke_Provider_Invoke;
         when 51 => return Toggle_Provider_Toggle;
         when 52 => return Expand_Collapse_Provider_Expand;
         when 53 => return Expand_Collapse_Provider_Collapse;
         when 54 => return Value_Provider_Set_Value;
         when 55 => return Range_Value_Provider_Set_Value;
         when 63 => return Range_Value_Provider_Get_Value;
         when 64 => return Range_Value_Provider_Get_Is_Read_Only;
         when 65 => return Range_Value_Provider_Get_Maximum;
         when 66 => return Range_Value_Provider_Get_Minimum;
         when 67 => return Range_Value_Provider_Get_Large_Change;
         when 68 => return Range_Value_Provider_Get_Small_Change;
         when 56 => return Selection_Item_Provider_Select;
         when 57 => return Selection_Item_Provider_Remove_From_Selection;
         when 58 => return Scroll_Item_Provider_Scroll_Into_View;
         when 59 => return Window_Provider_Close;
         when 60 => return Selection_Item_Provider_Add_To_Selection;
         when 61 => return Selection_Item_Provider_Get_Is_Selected;
         when 62 => return Selection_Item_Provider_Get_Selection_Container;
         when 69 => return Window_Provider_Get_Can_Maximize;
         when 70 => return Window_Provider_Get_Can_Minimize;
         when 71 => return Window_Provider_Get_Is_Modal;
         when 72 => return Window_Provider_Get_Window_Visual_State;
         when 73 => return Window_Provider_Get_Window_Interaction_State;
         when 40 => return Advise_Events_Advise;
         when 41 => return Advise_Events_Unadvise;
         when others =>
            Result := (Status => A11y.Results.Invalid_Argument);
            return IUnknown_Query_Interface;
      end case;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return IUnknown_Query_Interface;
   end Method_From_Code;

   function Can_Dispatch
     (Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Method : UIA_ABI_Method)
      return Boolean
   is
      Info : constant ABI_Method_Descriptor := Descriptor (Method);
   begin
      return Export.Exportable
        and then not Export.Defunct
        and then Info.Supported
        and then
          (Info.Provider_Interface_Kind =
             A11y.Windows_Backend.UIA_Com_Providers.IUnknown_Interface
           or else
             (Info.Provider_Interface_Kind /=
                A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface
              and then Export.Interfaces (Info.Provider_Interface_Kind)))
        and then (not Info.Requires_Root_Provider or else Export.Node = Export.Root);
   end Can_Dispatch;

   function Prepare_Request
     (Export :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor;
      Method : UIA_ABI_Method;
      Result : out A11y.Results.Result)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request
   is
      Info : constant ABI_Method_Descriptor := Descriptor (Method);
      Request : A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Request;
   begin
      Request.Kind := Info.Request_Kind;
      Request.Has_Native_Identity := False;
      Request.Native_Node_Component := 0;

      if not Export.Exportable or else Export.Defunct then
         Result := (Status => A11y.Results.Node_Unavailable);
      elsif not Info.Supported then
         Result := (Status => Info.Status);
      elsif not Can_Dispatch (Export, Method) then
         Result := (Status => A11y.Results.Unsupported_Capability);
      else
         Request.Has_Native_Identity := Info.Requires_Native_Identity;
         if Info.Requires_Native_Identity then
            Request.Native_Node_Component := Export.Native_Node_Component;
         end if;
         if Method = Fragment_Set_Focus then
            Request.Action := A11y.Actions.Set_Focus;
         elsif Method = Invoke_Provider_Invoke then
            Request.Action := A11y.Actions.Activate;
         elsif Method = Toggle_Provider_Toggle then
            Request.Action := A11y.Actions.Toggle;
         elsif Method = Expand_Collapse_Provider_Expand then
            Request.Action := A11y.Actions.Expand;
         elsif Method = Expand_Collapse_Provider_Collapse then
            Request.Action := A11y.Actions.Collapse;
         elsif Method = Selection_Item_Provider_Select then
            Request.Selection_Request :=
              A11y.Windows_Backend.UIA_Selection.Select_Item;
            Request.Selection_Target := Export.Node;
         elsif Method = Selection_Item_Provider_Add_To_Selection then
            Request.Selection_Request :=
              A11y.Windows_Backend.UIA_Selection.Add_Item_To_Selection;
            Request.Selection_Target := Export.Node;
         elsif Method = Selection_Item_Provider_Remove_From_Selection then
            Request.Selection_Request :=
              A11y.Windows_Backend.UIA_Selection.Deselect_Item;
            Request.Selection_Target := Export.Node;
         elsif Method = Selection_Item_Provider_Get_Is_Selected then
            Request.Selection :=
              A11y.Windows_Backend.UIA_Selection.Is_Item_Selected;
         elsif Method = Selection_Item_Provider_Get_Selection_Container then
            Request.Selection :=
              A11y.Windows_Backend.UIA_Selection.Selection_Root;
         elsif Method = Scroll_Item_Provider_Scroll_Into_View then
            Request.Action := A11y.Actions.Scroll_Into_View;
         elsif Method = Window_Provider_Close then
            Request.Action := A11y.Actions.Close;
         elsif Method = Window_Provider_Get_Can_Maximize then
            Request.Surface := A11y.Windows_Backend.UIA_Surfaces.Can_Resize;
         elsif Method = Window_Provider_Get_Can_Minimize then
            Request.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Top_Level;
         elsif Method = Window_Provider_Get_Is_Modal then
            Request.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Modal;
         elsif Method = Window_Provider_Get_Window_Visual_State then
            Request.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Maximized;
         elsif Method = Window_Provider_Get_Window_Interaction_State then
            Request.Surface := A11y.Windows_Backend.UIA_Surfaces.Is_Active;
         elsif Method = Range_Value_Provider_Get_Value then
            Request.Value := A11y.Windows_Backend.UIA_Values.Current_Value;
         elsif Method = Range_Value_Provider_Get_Is_Read_Only then
            Request.Value := A11y.Windows_Backend.UIA_Values.Is_Read_Only;
         elsif Method = Range_Value_Provider_Get_Maximum then
            Request.Value := A11y.Windows_Backend.UIA_Values.Maximum_Value;
         elsif Method = Range_Value_Provider_Get_Minimum then
            Request.Value := A11y.Windows_Backend.UIA_Values.Minimum_Value;
         elsif Method = Range_Value_Provider_Get_Large_Change then
            Request.Value := A11y.Windows_Backend.UIA_Values.Large_Increment;
         elsif Method = Range_Value_Provider_Get_Small_Change then
            Request.Value := A11y.Windows_Backend.UIA_Values.Small_Increment;
         end if;
         Result := A11y.Results.Ok;
      end if;

      return Request;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return Request;
   end Prepare_Request;

end A11y.Windows_Backend.UIA_ABI_Surface;
