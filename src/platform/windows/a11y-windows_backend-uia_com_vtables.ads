with Interfaces;

with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_COM_Exports;
with A11y.Windows_Backend.UIA_Provider_Registry;

package A11y.Windows_Backend.UIA_COM_VTables is

   type Interface_Slot_Descriptor is record
      Supported      : Boolean := False;
      Kind           :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Method_Count   : Natural := 0;
      Requires_Root  : Boolean := False;
      Callback_Slot  :
        A11y.Windows_Backend.UIA_COM_Exports.Callback_Slot :=
          A11y.Windows_Backend.UIA_COM_Exports.Provider_Method_Slot;
      Status         : A11y.Results.Status_Code :=
        A11y.Results.Unsupported_Capability;
   end record;

   type Interface_Query_Plan is record
      Supported     : Boolean := False;
      Requested     :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Callback_Slot :
        A11y.Windows_Backend.UIA_COM_Exports.Callback_Slot :=
          A11y.Windows_Backend.UIA_COM_Exports.Query_Interface_Slot;
      Status        : A11y.Results.Status_Code :=
        A11y.Results.Unsupported_Capability;
      ABI_HResult_Code : Interfaces.Unsigned_32 := 16#0000_0001#;
   end record;

   type Callback_Frame_Plan is record
      Supported       : Boolean := False;
      Method          :
        A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method :=
          A11y.Windows_Backend.UIA_ABI_Surface.IUnknown_Query_Interface;
      Frame           : A11y.Windows_Backend.UIA_COM_Exports.ABI_Callback_Frame;
      Status          : A11y.Results.Status_Code :=
        A11y.Results.Unsupported_Capability;
      ABI_HResult_Code : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   type COM_Object_Descriptor is record
      Exportable                 : Boolean := False;
      Status                     : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Provider                   :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Session                    : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                       : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                       : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component      : Natural := 0;
      Interfaces                 :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface_Set :=
          [others => False];
      VTable_Methods             :
        A11y.Windows_Backend.UIA_COM_Exports.Method_Set :=
          [others => False];
      Provider_Frame_Methods     :
        A11y.Windows_Backend.UIA_COM_Exports.Method_Set :=
          [others => False];
      Interface_Count            : Natural := 0;
      VTable_Method_Count        : Natural := 0;
      Provider_Frame_Count       : Natural := 0;
      Controlling_IUnknown_Stable : Boolean := False;
      Host_Window_Bound          : Boolean := False;
      Host_Window_Component      : Natural := 0;
      Defunct                    : Boolean := False;
   end record;

   function Interface_Method_Count
     (Kind : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface)
      return Natural;

   function Interface_Slot
     (Object : COM_Object_Descriptor;
      Kind   : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface)
      return Interface_Slot_Descriptor;

   function Build_Object_Descriptor
     (Table : A11y.Windows_Backend.UIA_COM_Exports.COM_Export_Table)
      return COM_Object_Descriptor;

   function Interface_Supported
     (Object : COM_Object_Descriptor;
      Kind   : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface)
      return Boolean;

   function Method_Supported
     (Object : COM_Object_Descriptor;
      Method : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method)
      return Boolean;

   function Can_Enter_Provider_Frame
     (Object : COM_Object_Descriptor;
      Method : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method)
      return Boolean;

   function Query_Interface
     (Object    : COM_Object_Descriptor;
      Requested : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface)
      return Interface_Query_Plan;

   function Frame_For
     (Object : COM_Object_Descriptor;
      Method : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method)
      return Callback_Frame_Plan;

end A11y.Windows_Backend.UIA_COM_VTables;
