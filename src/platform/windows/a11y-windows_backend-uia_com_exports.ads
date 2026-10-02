with Interfaces;

with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_Bridge_Audit;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Fragments;
with A11y.Windows_Backend.UIA_Provider_Boundary;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Request_Router;

package A11y.Windows_Backend.UIA_COM_Exports is

   type Callback_Slot is
     (Query_Interface_Slot,
      Add_Ref_Slot,
      Release_Slot,
      Provider_Method_Slot);

   type Callback_Set is array (Callback_Slot) of Boolean;

   type Method_Set is array
     (A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method) of Boolean;

   type Native_Bridge_Entry is record
      Slot       : Callback_Slot := Query_Interface_Slot;
      Operation  :
        A11y.Windows_Backend.UIA_Bridge_Audit.Bridge_Operation :=
          A11y.Windows_Backend.UIA_Bridge_Audit.Query_Interface_Callback;
      ABI_Only   : Boolean := False;
      Symbol     : A11y.Windows_Backend.UIA_Bridge_Audit.Bridge_Operation :=
        A11y.Windows_Backend.UIA_Bridge_Audit.Query_Interface_Callback;
      Dispatches_Provider_Method : Boolean := False;
   end record;

   type COM_Export_Table is record
      Exportable            : Boolean := False;
      Status                : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Provider              :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Session               : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Root                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Node                  : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Callbacks             : Callback_Set := [others => False];
      Methods               : Method_Set := [others => False];
      Dispatchable_Methods  : Natural := 0;
      Host_Window_Bound     : Boolean := False;
      Host_Window_Component : Natural := 0;
      Defunct               : Boolean := False;
   end record;

   type Method_Invoke_Report is record
      Callback_Allowed      : Boolean := False;
      Method_Dispatchable   : Boolean := False;
      Request_Prepared      : Boolean := False;
      Registered_Call_Attempted : Boolean := False;
      Registered_Dispatched : Boolean := False;
      Dispatch_Stage       : Natural := 0;
      Requested_Interface   :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Request_Kind          :
        A11y.Windows_Backend.UIA_Provider_Boundary.UIA_Request_Kind :=
          A11y.Windows_Backend.UIA_Provider_Boundary.Get_Property_Value;
      Boundary_Report       : aliased
        A11y.Windows_Backend.UIA_Provider_Boundary
          .Registered_Native_Request_Report;
      Reply_Status          : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      HResult               :
        A11y.Windows_Backend.UIA_Provider_Boundary.HRESULT_Status :=
          A11y.Windows_Backend.UIA_Provider_Boundary
            .UIA_E_ELEMENTNOTAVAILABLE;
      ABI_HResult_Code      : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   type Method_Invoke_Report_Access is access all Method_Invoke_Report;

   type ABI_Callback_Frame is record
      Session_Code  : Interfaces.Unsigned_64 := 0;
      Provider_Code : Interfaces.Unsigned_64 := 0;
      Method_Code   : Interfaces.Unsigned_32 := 0;
   end record;

   type ABI_Callback_Report is record
      Frame_Matches_Export : Boolean := False;
      Method_Code_Valid    : Boolean := False;
      Method               :
        A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method :=
          A11y.Windows_Backend.UIA_ABI_Surface.IUnknown_Query_Interface;
      Invoke               : aliased Method_Invoke_Report;
      Reply_Status         : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      ABI_HResult_Code     : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   type ABI_Callback_Report_Access is access all ABI_Callback_Report;

   function Required_Bridge_Operation
     (Slot : Callback_Slot)
      return A11y.Windows_Backend.UIA_Bridge_Audit.Bridge_Operation;

   function Callback_Name (Slot : Callback_Slot) return String;

   function Bridge_Entry (Slot : Callback_Slot) return Native_Bridge_Entry;

   function Build_Export_Table
     (Provider :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Export   :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Export_Descriptor)
      return COM_Export_Table;

   function Can_Invoke_Callback
     (Table : COM_Export_Table;
      Slot  : Callback_Slot)
      return Boolean;

   function Can_Dispatch_Method
     (Table  : COM_Export_Table;
      Method : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method)
      return Boolean;

   function HRESULT_Code
     (Status : A11y.Windows_Backend.UIA_Provider_Boundary.HRESULT_Status)
      return Interfaces.Unsigned_32;

   function Method_Code
     (Method : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method)
      return Interfaces.Unsigned_32;

   function Method_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;

   function Build_Callback_Frame
     (Table  : COM_Export_Table;
      Method : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method)
      return ABI_Callback_Frame;

   function Invoke_Provider_Method
     (Table     : COM_Export_Table;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Method_Invoke_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Invoke_Provider_Method_Access
     (Table     : COM_Export_Table;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out Method_Invoke_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Invoke_Provider_Method_Report_Access
     (Table     : COM_Export_Table;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Method_Invoke_Report_Access;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Invoke_Callback_Frame
     (Table     : COM_Export_Table;
      Frame     : ABI_Callback_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out ABI_Callback_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Invoke_Callback_Frame_Access
     (Table     : COM_Export_Table;
      Frame     : ABI_Callback_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out ABI_Callback_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Invoke_Callback_Frame_Report_Access
     (Table     : COM_Export_Table;
      Frame     : ABI_Callback_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null ABI_Callback_Report_Access;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function All_Callbacks_Audited (Table : COM_Export_Table) return Boolean;

end A11y.Windows_Backend.UIA_COM_Exports;
