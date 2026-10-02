with Ada.Strings.Wide_Wide_Unbounded;

with A11y.Actions;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Tables;
with A11y.Text;
with A11y.Values;
with A11y.Windows_Backend.UIA_Document;
with A11y.Windows_Backend.UIA_Fragments;
with A11y.Windows_Backend.UIA_Image;
with A11y.Windows_Backend.UIA_Live_Regions;
with A11y.Windows_Backend.UIA_Properties;
with A11y.Windows_Backend.UIA_Com_Providers;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Request_Router;
with A11y.Windows_Backend.UIA_Selection;
with A11y.Windows_Backend.UIA_Surfaces;
with A11y.Windows_Backend.UIA_Table;
with A11y.Windows_Backend.UIA_Text;
with A11y.Windows_Backend.UIA_Values;

package A11y.Windows_Backend.UIA_Provider_Boundary is

   type UIA_Request_Kind is
     (Get_Provider_Options,
      Get_Host_Raw_Element_Provider,
      Get_Property_Value,
      Get_Pattern_Provider,
      Invoke_Action,
      Navigate_Fragment,
      Get_Embedded_Fragment_Roots,
      Get_Fragment_Root,
      Get_Fragment_Focus,
      Get_Fragment_From_Point,
      Get_Runtime_Id,
      Get_Relation_Targets,
      Get_Value,
      Set_Value,
      Get_Selection,
      Set_Selection,
      Get_Text,
      Get_Text_Edit,
      Get_Table,
      Get_Image,
      Get_Document,
      Get_Live_Region,
      Get_Surface,
      Advise_Event,
      Unadvise_Event,
      Raise_Event);

   type Boundary_Request is record
      Kind      : UIA_Request_Kind := Get_Property_Value;
      Has_Native_Identity : Boolean := False;
      Native_Node_Component : Natural := 0;
      Property  : A11y.Windows_Backend.UIA_Properties.Core_Property :=
        A11y.Windows_Backend.UIA_Properties.Name;
      Action    : A11y.Actions.Action_Id := A11y.Actions.Activate;
      Direction : A11y.Windows_Backend.UIA_Fragments.Navigate_Direction :=
        A11y.Windows_Backend.UIA_Fragments.Parent;
      Hit_Test_Point : A11y.Geometry.Point := (X => 0, Y => 0);
      Relation  : A11y.Relations.Relation_Kind := A11y.Relations.Labelled_By;
      Value     : A11y.Windows_Backend.UIA_Values.Value_Query :=
        A11y.Windows_Backend.UIA_Values.Current_Value;
      Requested_Value : A11y.Values.Semantic_Value := (Kind => A11y.Values.Unknown);
      Selection : A11y.Windows_Backend.UIA_Selection.Selection_Query :=
        A11y.Windows_Backend.UIA_Selection.Selected_Count;
      Selection_Request :
        A11y.Windows_Backend.UIA_Selection.Selection_Request_Kind :=
          A11y.Windows_Backend.UIA_Selection.Select_Item;
      Selection_Target : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Text      : A11y.Windows_Backend.UIA_Text.Text_Query :=
        A11y.Windows_Backend.UIA_Text.Character_Count;
      Text_Edit : A11y.Text.Text_Edit_Kind := A11y.Text.Insert_Text;
      Table     : A11y.Windows_Backend.UIA_Table.Table_Query :=
        A11y.Windows_Backend.UIA_Table.Row_Count;
      Image     : A11y.Windows_Backend.UIA_Image.Image_Query :=
        A11y.Windows_Backend.UIA_Image.Description;
      Document  : A11y.Windows_Backend.UIA_Document.Document_Query :=
        A11y.Windows_Backend.UIA_Document.Locale;
      Live_Region : A11y.Windows_Backend.UIA_Live_Regions.Live_Query :=
        A11y.Windows_Backend.UIA_Live_Regions.Setting_Name;
      Surface   : A11y.Windows_Backend.UIA_Surfaces.Surface_Query :=
        A11y.Windows_Backend.UIA_Surfaces.Kind_Name;
      Index     : Positive := 1;
      Count     : Natural := 0;
      Replacement :
        Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
      Row       : A11y.Tables.Logical_Index := 0;
      Column    : A11y.Tables.Logical_Index := 0;
      Event     : A11y.Events.Event;
      Use_Prepared_Event : Boolean := False;
      Prepared_Event : A11y.Native_Runtimes.Prepared_Event;
   end record;

   type Boundary_Request_Access is access constant Boundary_Request;

   type HRESULT_Status is
     (S_OK,
      S_FALSE,
      UIA_E_ELEMENTNOTAVAILABLE,
      UIA_E_ELEMENTNOTENABLED,
      UIA_E_INVALIDOPERATION,
      E_INVALIDARG,
      E_ACCESSDENIED,
      E_OUTOFMEMORY,
      E_FAIL);

   type Boundary_Reply_Kind is
     (Provider_Reply,
      Provider_Not_Supported,
      Provider_Error);

   type Boundary_Reply is record
      Kind   : Boundary_Reply_Kind := Provider_Error;
      HResult : HRESULT_Status := E_FAIL;
      Status : A11y.Results.Status_Code := A11y.Results.Internal_Error;
      Routed : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply_Kind :=
        A11y.Windows_Backend.UIA_Request_Router.Routed_Error;
      Payload : A11y.Windows_Backend.UIA_Request_Router.Routed_Reply :=
        (Kind   => A11y.Windows_Backend.UIA_Request_Router.Routed_Error,
         Status => A11y.Results.Internal_Error);
      Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
   end record;

   type Boundary_Reply_Access is access all Boundary_Reply;

   type Registered_Native_Request_Report is record
      Requested_Interface :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Request_Kind         : UIA_Request_Kind := Get_Property_Value;
      Boundary_Stage       : Natural := 0;
      Interface_Supported : Boolean := False;
      Resolved            : Boolean := False;
      Resolved_Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Resolved_Root       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Native_Node_Component : Natural := 0;
      Native_Identity_Prepared : Boolean := False;
      Native_Admitted     : Boolean := False;
      Native_Completed    : Boolean := False;
      Begin_Report :
        A11y.Windows_Backend.UIA_Provider_Registry
          .Native_Call_Mutation_Report;
      End_Report :
        A11y.Windows_Backend.UIA_Provider_Registry
          .Native_Call_Mutation_Report;
      Reply_Status        : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Final_Status        : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   type Registered_Native_Request_Report_Access is
     access all Registered_Native_Request_Report;

   function HResult_For
     (Status : A11y.Results.Status_Code)
      return HRESULT_Status;

   function Status_For_HResult
     (Status : HRESULT_Status)
      return A11y.Results.Status_Code;

   function HResult_Code (Status : HRESULT_Status) return String;

   function Diagnostic_For_HResult
     (Status : HRESULT_Status;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Diagnostic_For_HResult
     (Status : HRESULT_Status;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Dispatch_Request
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return Boundary_Reply;

   function Dispatch_Native_Request
     (Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return Boundary_Reply;

   function Dispatch_Registered_Native_Request
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle)
      return Boundary_Reply;

   function Dispatch_Registered_Native_Request_With_Report
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : Boundary_Request;
      Snapshots : A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Registered_Native_Request_Report)
      return Boundary_Reply;

   function Dispatch_Registered_Native_Request_With_Report_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : out Registered_Native_Request_Report)
      return Boundary_Reply;

   procedure Dispatch_Registered_Native_Request_Into_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : in out Registered_Native_Request_Report;
      Reply_Out : in out Boundary_Reply);

   procedure Dispatch_Registered_Native_Request_Into_Report_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Registered_Native_Request_Report_Access;
      Reply_Out : in out Boundary_Reply);

   procedure Dispatch_Registered_Native_Request_Full_Access
     (Registry  : in out A11y.Windows_Backend.UIA_Provider_Registry.Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Provider  : A11y.Windows_Backend.UIA_Provider_Registry.Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Request   : not null Boundary_Request_Access;
      Snapshots :
        not null access constant
          A11y.Windows_Backend.UIA_Request_Router.Snapshot_Bundle;
      Report    : not null Registered_Native_Request_Report_Access;
      Reply_Out : not null Boundary_Reply_Access);

end A11y.Windows_Backend.UIA_Provider_Boundary;
