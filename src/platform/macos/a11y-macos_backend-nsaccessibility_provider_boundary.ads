with Ada.Strings.Wide_Wide_Unbounded;

with A11y.Actions;
with A11y.Diagnostics;
with A11y.Events;
with A11y.Native_Identity;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.MacOS_Backend.NSAccessibility_Document;
with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Image;
with A11y.MacOS_Backend.NSAccessibility_Live_Regions;
with A11y.MacOS_Backend.NSAccessibility_Properties;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.MacOS_Backend.NSAccessibility_Selection;
with A11y.MacOS_Backend.NSAccessibility_Surfaces;
with A11y.MacOS_Backend.NSAccessibility_Table;
with A11y.MacOS_Backend.NSAccessibility_Text;
with A11y.MacOS_Backend.NSAccessibility_Values;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Tables;
with A11y.Text;
with A11y.Values;

package A11y.MacOS_Backend.NSAccessibility_Provider_Boundary is

   type Native_Request_Kind is
     (Copy_Attribute_Names,
      Copy_Attribute_Value,
      Is_Attribute_Settable,
      Copy_Action_Names,
      Perform_Action,
      Copy_Parent,
      Copy_Children,
      Copy_Child_At_Index,
      Copy_Element_Id,
      Copy_Relation_Targets,
      Copy_Value,
      Set_Value,
      Copy_Selection,
      Set_Selection,
      Copy_Text,
      Edit_Text,
      Copy_Table,
      Copy_Image,
      Copy_Document,
      Copy_Live_Region,
      Copy_Surface,
      Post_Notification);

   type Native_Method_Family is
     (Any_Method,
      Attribute_Method,
      Action_Method,
      Hierarchy_Method,
      Value_Method,
      Selection_Method,
      Text_Method,
      Table_Method,
      Image_Method,
      Document_Method,
      Live_Region_Method,
      Surface_Method,
      Notification_Method);

   type Boundary_Request is record
      Kind      : Native_Request_Kind := Copy_Attribute_Value;
      Has_Native_Identity : Boolean := False;
      Native_Node_Component : Natural := 0;
      Attribute :
        A11y.MacOS_Backend.NSAccessibility_Properties.Core_Attribute :=
          A11y.MacOS_Backend.NSAccessibility_Properties.Title;
      Action    : A11y.Actions.Action_Id := A11y.Actions.Activate;
      Child_Index : Positive := 1;
      Relation  : A11y.Relations.Relation_Kind := A11y.Relations.Labelled_By;
      Value     : A11y.MacOS_Backend.NSAccessibility_Values.Value_Query :=
        A11y.MacOS_Backend.NSAccessibility_Values.Value;
      Requested_Value : A11y.Values.Semantic_Value := (Kind => A11y.Values.Unknown);
      Selection :
        A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Query :=
          A11y.MacOS_Backend.NSAccessibility_Selection.Selected_Count;
      Selection_Request :
        A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Request_Kind :=
          A11y.MacOS_Backend.NSAccessibility_Selection.Select_Item;
      Selection_Target : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Text      : A11y.MacOS_Backend.NSAccessibility_Text.Text_Query :=
        A11y.MacOS_Backend.NSAccessibility_Text.Character_Count;
      Text_Edit : A11y.Text.Text_Edit_Kind := A11y.Text.Insert_Text;
      Table     : A11y.MacOS_Backend.NSAccessibility_Table.Table_Query :=
        A11y.MacOS_Backend.NSAccessibility_Table.Row_Count;
      Image     : A11y.MacOS_Backend.NSAccessibility_Image.Image_Query :=
        A11y.MacOS_Backend.NSAccessibility_Image.Description;
      Document  :
        A11y.MacOS_Backend.NSAccessibility_Document.Document_Query :=
          A11y.MacOS_Backend.NSAccessibility_Document.Locale;
      Live_Region :
        A11y.MacOS_Backend.NSAccessibility_Live_Regions.Live_Query :=
          A11y.MacOS_Backend.NSAccessibility_Live_Regions.Setting_Name;
      Surface   :
        A11y.MacOS_Backend.NSAccessibility_Surfaces.Surface_Query :=
          A11y.MacOS_Backend.NSAccessibility_Surfaces.Kind_Name;
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

   type Native_Status is
     (Native_Success,
      Native_Not_Applicable,
      Native_No_Value,
      Native_Element_Unavailable,
      Native_Invalid_Argument,
      Native_Permission_Denied,
      Native_Out_Of_Resources,
      Native_Busy,
      Native_Failed);

   type Boundary_Reply_Kind is
     (Native_Reply,
      Native_Nil,
      Native_Error);

   type Boundary_Reply is record
      Kind          : Boundary_Reply_Kind := Native_Error;
      Native_Result : Native_Status := Native_Failed;
      Status        : A11y.Results.Status_Code := A11y.Results.Internal_Error;
      Routed        :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply_Kind :=
          A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Error;
      Payload       :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Reply :=
          (Kind =>
             A11y.MacOS_Backend.NSAccessibility_Request_Router.Routed_Error,
           Status => A11y.Results.Internal_Error);
      Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
   end record;

   type Registered_Native_Request_Report is record
      Method_Family        : Native_Method_Family := Any_Method;
      Request_Kind         : Native_Request_Kind := Copy_Attribute_Value;
      Method_Family_Supported : Boolean := False;
      Resolved                : Boolean := False;
      Resolved_Node           : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Resolved_Root           : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Native_Node_Component   : Natural := 0;
      Native_Identity_Prepared : Boolean := False;
      Native_Admitted         : Boolean := False;
      Native_Completed        : Boolean := False;
      Begin_Report :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Native_Call_Mutation_Report;
      End_Report :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Native_Call_Mutation_Report;
      Reply_Status            : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Final_Status            : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   function Native_Status_For
     (Status : A11y.Results.Status_Code)
      return Native_Status;

   function Status_For_Native_Status
     (Status : Native_Status)
      return A11y.Results.Status_Code;

   function Native_Status_Name (Status : Native_Status) return String;

   function Diagnostic_For_Native_Status
     (Status : Native_Status;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Diagnostic_For_Native_Status
     (Status : Native_Status;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Diagnostics.Diagnostic;

   function Dispatch_Request
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
      return Boundary_Reply;

   function Dispatch_Native_Request
     (Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle)
      return Boundary_Reply;

   function Dispatch_Registered_Native_Request
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Element   :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
      Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Require_Main_Thread : Boolean := False;
      Method_Family : Native_Method_Family := Any_Method)
      return Boundary_Reply;

   function Dispatch_Registered_Native_Request_With_Report
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Element   :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
      Request   : Boundary_Request;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Report    : out Registered_Native_Request_Report;
      Require_Main_Thread : Boolean := False;
      Method_Family : Native_Method_Family := Any_Method)
      return Boundary_Reply;

end A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
