with A11y.Windows_Backend.UIA_Provider_Boundary;

package body A11y.Windows_Backend.UIA_COM_VTables is

   package ABI renames A11y.Windows_Backend.UIA_ABI_Surface;
   package COM renames A11y.Windows_Backend.UIA_Com_Providers;
   package Exports renames A11y.Windows_Backend.UIA_COM_Exports;
   package Registry renames A11y.Windows_Backend.UIA_Provider_Registry;

   use type COM.Provider_Interface;

   function Interface_Method_Count
     (Kind : COM.Provider_Interface)
      return Natural is
     (case Kind is
        when COM.IUnknown_Interface => 3,
        when COM.Raw_Element_Provider_Simple => 4,
        when COM.Raw_Element_Provider_Fragment => 6,
        when COM.Raw_Element_Provider_Fragment_Root => 2,
        when COM.Raw_Element_Provider_Advise_Events => 2,
        when COM.Unsupported_Interface => 0);

   function Interface_Slot
     (Object : COM_Object_Descriptor;
      Kind   : COM.Provider_Interface)
      return Interface_Slot_Descriptor
   is
      Supported : constant Boolean :=
        Object.Exportable
        and then Kind /= COM.Unsupported_Interface
        and then Object.Interfaces (Kind);
      Requires_Root : constant Boolean :=
        Kind = COM.Raw_Element_Provider_Fragment_Root;
   begin
      return
        (Supported     => Supported,
         Kind          => Kind,
         Method_Count  =>
           (if Supported then Interface_Method_Count (Kind) else 0),
         Requires_Root => Requires_Root,
         Callback_Slot =>
           (if Kind = COM.IUnknown_Interface
            then Exports.Query_Interface_Slot
            else Exports.Provider_Method_Slot),
         Status        =>
           (if Supported then A11y.Results.Success
            elsif Object.Defunct then A11y.Results.Node_Unavailable
            else A11y.Results.Unsupported_Capability));
   exception
      when others =>
         return
           (Supported     => False,
            Kind          => COM.Unsupported_Interface,
            Method_Count  => 0,
            Requires_Root => False,
            Callback_Slot => Exports.Provider_Method_Slot,
            Status        => A11y.Results.Internal_Error);
   end Interface_Slot;

   function Build_Object_Descriptor
     (Table : Exports.COM_Export_Table)
      return COM_Object_Descriptor
   is
      Object : COM_Object_Descriptor;
      Info : ABI.ABI_Method_Descriptor;
   begin
      Object.Exportable := Table.Exportable;
      Object.Status := Table.Status;
      Object.Provider := Table.Provider;
      Object.Session := Table.Session;
      Object.Root := Table.Root;
      Object.Node := Table.Node;
      Object.Native_Node_Component := Table.Native_Node_Component;
      Object.Host_Window_Bound := Table.Host_Window_Bound;
      Object.Host_Window_Component := Table.Host_Window_Component;
      Object.Defunct := Table.Defunct;

      if not Table.Exportable or else Table.Defunct then
         return Object;
      end if;

      Object.Interfaces (COM.IUnknown_Interface) :=
        Table.Callbacks (Exports.Query_Interface_Slot)
        and then Table.Callbacks (Exports.Add_Ref_Slot)
        and then Table.Callbacks (Exports.Release_Slot);
      Object.Interfaces (COM.Raw_Element_Provider_Simple) := True;
      Object.Interfaces (COM.Raw_Element_Provider_Fragment) := True;
      Object.Interfaces (COM.Raw_Element_Provider_Fragment_Root) :=
        Table.Methods (ABI.Fragment_Root_Element_Provider_From_Point)
        and then Table.Methods (ABI.Fragment_Root_Get_Focus);
      Object.Interfaces (COM.Raw_Element_Provider_Advise_Events) :=
        Table.Methods (ABI.Advise_Events_Advise)
        and then Table.Methods (ABI.Advise_Events_Unadvise);
      Object.Interfaces (COM.Unsupported_Interface) := False;

      for Kind in COM.Provider_Interface loop
         if Object.Interfaces (Kind) then
            Object.Interface_Count := Object.Interface_Count + 1;
         end if;
      end loop;

      Object.VTable_Methods (ABI.IUnknown_Query_Interface) :=
        Object.Interfaces (COM.IUnknown_Interface);
      Object.VTable_Methods (ABI.IUnknown_Add_Ref) :=
        Object.Interfaces (COM.IUnknown_Interface);
      Object.VTable_Methods (ABI.IUnknown_Release) :=
        Object.Interfaces (COM.IUnknown_Interface);

      for Method in ABI.UIA_ABI_Method loop
         Info := ABI.Descriptor (Method);
         if Table.Methods (Method) then
            Object.VTable_Methods (Method) := True;
         end if;

         if Table.Methods (Method)
           and then not Info.Is_Lifetime_Method
           and then Table.Callbacks (Exports.Provider_Method_Slot)
         then
            Object.Provider_Frame_Methods (Method) := True;
         end if;
      end loop;

      for Method in ABI.UIA_ABI_Method loop
         if Object.VTable_Methods (Method) then
            Object.VTable_Method_Count := Object.VTable_Method_Count + 1;
         end if;
         if Object.Provider_Frame_Methods (Method) then
            Object.Provider_Frame_Count := Object.Provider_Frame_Count + 1;
         end if;
      end loop;

      Object.Controlling_IUnknown_Stable :=
        Object.Exportable
        and then Registry.Is_Valid (Object.Provider)
        and then A11y.Native_Identity.Is_Valid (Object.Session)
        and then Object.Native_Node_Component /= 0
        and then Object.Interfaces (COM.IUnknown_Interface);

      if Object.Controlling_IUnknown_Stable then
         Object.Status := A11y.Results.Success;
      else
         Object.Exportable := False;
         Object.Status := A11y.Results.Node_Unavailable;
      end if;

      return Object;
   exception
      when others =>
         return
           (Exportable                  => False,
            Status                      => A11y.Results.Internal_Error,
            Provider                    => Registry.No_Provider,
            Session                     => A11y.Native_Identity.No_Session,
            Root                        => A11y.Node_Ids.No_Node,
            Node                        => A11y.Node_Ids.No_Node,
            Native_Node_Component       => 0,
            Interfaces                  => [others => False],
            VTable_Methods              => [others => False],
            Provider_Frame_Methods      => [others => False],
            Interface_Count             => 0,
            VTable_Method_Count         => 0,
            Provider_Frame_Count        => 0,
            Controlling_IUnknown_Stable => False,
            Host_Window_Bound           => False,
            Host_Window_Component       => 0,
            Defunct                     => True);
   end Build_Object_Descriptor;

   function Interface_Supported
     (Object : COM_Object_Descriptor;
      Kind   : COM.Provider_Interface)
      return Boolean is
     (Interface_Slot (Object, Kind).Supported);

   function Method_Supported
     (Object : COM_Object_Descriptor;
      Method : ABI.UIA_ABI_Method)
      return Boolean is
     (Object.Exportable and then Object.VTable_Methods (Method));

   function Can_Enter_Provider_Frame
     (Object : COM_Object_Descriptor;
      Method : ABI.UIA_ABI_Method)
      return Boolean is
     (Object.Exportable and then Object.Provider_Frame_Methods (Method));

   function Query_Interface
     (Object    : COM_Object_Descriptor;
      Requested : COM.Provider_Interface)
      return Interface_Query_Plan
   is
      Supported : constant Boolean :=
        Interface_Supported (Object, Requested);
   begin
      return
        (Supported        => Supported,
         Requested        => Requested,
         Callback_Slot    => Exports.Query_Interface_Slot,
         Status           =>
           (if Supported then A11y.Results.Success
            elsif Object.Defunct then A11y.Results.Node_Unavailable
            else A11y.Results.Unsupported_Capability),
         ABI_HResult_Code =>
           (if Supported
            then Exports.HRESULT_Code
              (A11y.Windows_Backend.UIA_Provider_Boundary.S_OK)
            else Exports.HRESULT_Code
              (A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE)));
   exception
      when others =>
         return
           (Supported        => False,
            Requested        => COM.Unsupported_Interface,
            Callback_Slot    => Exports.Query_Interface_Slot,
            Status           => A11y.Results.Internal_Error,
            ABI_HResult_Code =>
              Exports.HRESULT_Code
                (A11y.Windows_Backend.UIA_Provider_Boundary.E_FAIL));
   end Query_Interface;

   function Frame_For
     (Object : COM_Object_Descriptor;
      Method : ABI.UIA_ABI_Method)
      return Callback_Frame_Plan
   is
      Supported : constant Boolean :=
        Can_Enter_Provider_Frame (Object, Method);
      Table : Exports.COM_Export_Table;
   begin
      if not Supported then
         return
           (Supported        => False,
            Method           => Method,
            Frame            => <>,
            Status           =>
              (if Object.Defunct then A11y.Results.Node_Unavailable
               else A11y.Results.Unsupported_Capability),
            ABI_HResult_Code =>
              Exports.HRESULT_Code
                (A11y.Windows_Backend.UIA_Provider_Boundary.S_FALSE));
      end if;

      Table :=
        (Exportable            => Object.Exportable,
         Status                => Object.Status,
         Provider              => Object.Provider,
         Session               => Object.Session,
         Root                  => Object.Root,
         Node                  => Object.Node,
         Native_Node_Component => Object.Native_Node_Component,
         Callbacks             =>
           [Exports.Query_Interface_Slot => True,
            Exports.Add_Ref_Slot => True,
            Exports.Release_Slot => True,
            Exports.Provider_Method_Slot => True],
         Methods               => Object.Provider_Frame_Methods,
         Dispatchable_Methods  => Object.Provider_Frame_Count,
         Host_Window_Bound     => Object.Host_Window_Bound,
         Host_Window_Component => Object.Host_Window_Component,
         Defunct               => Object.Defunct);

      return
        (Supported        => True,
         Method           => Method,
         Frame            => Exports.Build_Callback_Frame (Table, Method),
         Status           => A11y.Results.Success,
         ABI_HResult_Code =>
           Exports.HRESULT_Code
             (A11y.Windows_Backend.UIA_Provider_Boundary.S_OK));
   exception
      when others =>
         return
           (Supported        => False,
            Method           => Method,
            Frame            => <>,
            Status           => A11y.Results.Internal_Error,
            ABI_HResult_Code =>
              Exports.HRESULT_Code
                (A11y.Windows_Backend.UIA_Provider_Boundary.E_FAIL));
   end Frame_For;

end A11y.Windows_Backend.UIA_COM_VTables;
