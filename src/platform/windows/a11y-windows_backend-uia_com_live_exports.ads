with Interfaces;

with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_COM_Exports;
with A11y.Windows_Backend.UIA_COM_Object_Exports;
with A11y.Windows_Backend.UIA_COM_VTables;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Fragments;
with A11y.Windows_Backend.UIA_Provider_Boundary;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Request_Router;

package A11y.Windows_Backend.UIA_COM_Live_Exports is

   type UIA_Interface_Reference is record
      Present      : Boolean := False;
      Token        :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token :=
          A11y.Windows_Backend.UIA_COM_Object_Exports.No_COM_Object;
      Kind         :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Session      : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Provider     :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id :=
          A11y.Windows_Backend.UIA_Provider_Registry.No_Provider;
      Node         : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Method_Count : Natural := 0;
      Reference_Count : Natural := 0;
      Released     : Boolean := False;
      Status       : A11y.Results.Status_Code :=
        A11y.Results.Unsupported_Capability;
      ABI_HResult_Code : Interfaces.Unsigned_32 := 16#0000_0001#;
   end record;

   type Interface_Query_Report is record
      Object_Resolved : Boolean := False;
      Object_Report   :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Resolve_Report;
      Query           :
        A11y.Windows_Backend.UIA_COM_VTables.Interface_Query_Plan;
      Reference       : UIA_Interface_Reference;
      Status          : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      ABI_HResult_Code : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   type Interface_Dispatch_Report is record
      Object_Resolved          : Boolean := False;
      Interface_Accepted       : Boolean := False;
      Method_Allowed_For_Interface : Boolean := False;
      Frame_Prepared           : Boolean := False;
      Callback_Dispatched      : Boolean := False;
      Object_Report            :
        A11y.Windows_Backend.UIA_COM_Object_Exports.Object_Resolve_Report;
      Frame                    :
        A11y.Windows_Backend.UIA_COM_VTables.Callback_Frame_Plan;
      Callback                 : aliased
        A11y.Windows_Backend.UIA_COM_Exports.ABI_Callback_Report;
      Status                   : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      ABI_HResult_Code         : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   type Interface_Dispatch_Report_Access is
     access all Interface_Dispatch_Report;

   type ABI_Interface_Frame is record
      Session_Code   : Interfaces.Unsigned_64 := 0;
      Provider_Code  : Interfaces.Unsigned_64 := 0;
      Object_Token_Code : Interfaces.Unsigned_64 := 0;
      Interface_Code : Interfaces.Unsigned_32 := 0;
      Method_Code    : Interfaces.Unsigned_32 := 0;
      Direction_Code : Interfaces.Unsigned_32 := 0;
      Point_X        : A11y.Geometry.Coordinate := 0;
      Point_Y        : A11y.Geometry.Coordinate := 0;
   end record;

   type ABI_Interface_Frame_Report is record
      Session_Code_Valid   : Boolean := False;
      Provider_Code_Valid  : Boolean := False;
      Object_Token_Valid   : Boolean := False;
      Interface_Code_Valid : Boolean := False;
      Method_Code_Valid    : Boolean := False;
      Direction_Code_Valid : Boolean := False;
      Reference_Queried    : Boolean := False;
      Dispatch             : aliased Interface_Dispatch_Report;
      Status               : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      ABI_HResult_Code     : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   type ABI_Interface_Frame_Report_Access is
     access all ABI_Interface_Frame_Report;

   type Interface_Lifetime_Report is record
      Reference_Present : Boolean := False;
      Reference_Released_Before : Boolean := False;
      Reference_Released_After  : Boolean := False;
      Count_Before      : Natural := 0;
      Count_After       : Natural := 0;
      Status            : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      ABI_HResult_Code  : Interfaces.Unsigned_32 := 16#8004_0201#;
   end record;

   function Interface_Code
     (Kind : A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface)
      return Interfaces.Unsigned_32;

   function Interface_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;

   function Build_Interface_Frame
     (Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return ABI_Interface_Frame;

   procedure Add_Ref
     (Reference : in out UIA_Interface_Reference;
      Report    : out Interface_Lifetime_Report);

   procedure Release
     (Reference : in out UIA_Interface_Reference;
      Report    : out Interface_Lifetime_Report);

   procedure Query_Interface
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Token     :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Token;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  :
        A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Report    : out Interface_Query_Report);

   function Dispatch_Interface_Method
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Interface_Dispatch_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Dispatch_Interface_Method_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out Interface_Dispatch_Report;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Dispatch_Interface_Method_Report_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Reference : UIA_Interface_Reference;
      Method    : A11y.Windows_Backend.UIA_ABI_Surface.UIA_ABI_Method;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Interface_Dispatch_Report_Access;
      Direction :
        A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
          A11y.Windows_Backend.UIA_Fragments.Parent;
      Point     : A11y.Geometry.Point := (X => 0, Y => 0))
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Dispatch_Interface_Frame
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Frame     : ABI_Interface_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out ABI_Interface_Frame_Report)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Dispatch_Interface_Frame_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Frame     : ABI_Interface_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out ABI_Interface_Frame_Report)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

   function Dispatch_Interface_Frame_Report_Access
     (Object_Table :
        A11y.Windows_Backend.UIA_COM_Object_Exports.COM_Object_Export_Table;
      Frame     : ABI_Interface_Frame;
      Registry  :
        in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null ABI_Interface_Frame_Report_Access)
      return A11y.Windows_Backend.UIA_Provider_Boundary.Boundary_Reply;

end A11y.Windows_Backend.UIA_COM_Live_Exports;
