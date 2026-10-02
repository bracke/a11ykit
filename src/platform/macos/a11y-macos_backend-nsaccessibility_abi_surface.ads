with Interfaces;

with A11y.Actions;
with A11y.Native_Identity;
with A11y.MacOS_Backend.NSAccessibility_Bridge_Audit;
with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Elements;
with A11y.MacOS_Backend.NSAccessibility_Properties;
with A11y.MacOS_Backend.NSAccessibility_Provider_Boundary;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.Relations;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_ABI_Surface is

   type NSAX_Selector is
     (Accessibility_Attribute_Names,
      Accessibility_Attribute_Value,
      Accessibility_Is_Attribute_Settable,
      Accessibility_Set_Value,
      Accessibility_Action_Names,
      Accessibility_Perform_Action,
      Accessibility_Parent,
      Accessibility_Children,
      Accessibility_Child_At_Index,
      Accessibility_Hit_Test,
      Accessibility_Focused_UI_Element,
      Accessibility_Post_Notification);

   type Selector_Descriptor is record
      Supported                : Boolean := False;
      Method_Family            :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Native_Method_Family :=
            A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Any_Method;
      Request_Kind             :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Native_Request_Kind :=
            A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
              .Copy_Attribute_Value;
      Requires_Native_Identity : Boolean := True;
      Requires_Main_Thread     : Boolean := True;
      Status                   : A11y.Results.Status_Code :=
        A11y.Results.Success;
   end record;

   type Selector_Frame is record
      Session_Code     : Interfaces.Unsigned_64 := 0;
      Element_Code     : Interfaces.Unsigned_64 := 0;
      Selector_Code    : Interfaces.Unsigned_32 := 0;
      Child_Index_Code : Interfaces.Unsigned_32 := 0;
      Operand_Code     : Interfaces.Unsigned_32 := 0;
   end record;

   type Selector_Frame_Report is record
      Session_Code_Valid : Boolean := False;
      Element_Code_Valid : Boolean := False;
      Selector_Code_Valid : Boolean := False;
      Request_Prepared   : Boolean := False;
      Selector           : NSAX_Selector := Accessibility_Attribute_Value;
      Dispatch           :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
          .Registered_Native_Request_Report;
      Status             : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Native_Status      :
        A11y.MacOS_Backend.NSAccessibility_Provider_Boundary.Native_Status :=
          A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
            .Native_Element_Unavailable;
   end record;

   type Native_Bridge_Entry is record
      Selector   : NSAX_Selector := Accessibility_Attribute_Value;
      Operation  :
        A11y.MacOS_Backend.NSAccessibility_Bridge_Audit.Bridge_Operation :=
          A11y.MacOS_Backend.NSAccessibility_Bridge_Audit
            .Dispatch_Selector_Frame_Callback;
      ABI_Only   : Boolean := False;
      Requires_Main_Thread : Boolean := True;
      Dispatches_Notification : Boolean := False;
   end record;

   function Descriptor
     (Selector : NSAX_Selector)
      return Selector_Descriptor;

   function Selector_Name (Selector : NSAX_Selector) return String;

   function Bridge_Entry (Selector : NSAX_Selector) return Native_Bridge_Entry;

   function Selector_Code
     (Selector : NSAX_Selector)
      return Interfaces.Unsigned_32;

   function Attribute_Code
     (Attribute :
        A11y.MacOS_Backend.NSAccessibility_Properties.Core_Attribute)
      return Interfaces.Unsigned_32;

   function Action_Code
     (Action : A11y.Actions.Action_Id)
      return Interfaces.Unsigned_32;

   function Relation_Code
     (Relation : A11y.Relations.Relation_Kind)
      return Interfaces.Unsigned_32;

   function Selector_From_Code
     (Code   : Interfaces.Unsigned_32;
      Result : out A11y.Results.Result)
      return NSAX_Selector;

   function Can_Dispatch
     (Export :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor;
      Selector : NSAX_Selector)
      return Boolean;

   function Prepare_Request
     (Export :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Export_Descriptor;
      Selector : NSAX_Selector;
      Result   : out A11y.Results.Result)
      return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
        .Boundary_Request;

   function Build_Selector_Frame
     (Session     : A11y.Native_Identity.Backend_Session_Id;
      Element     :
        A11y.MacOS_Backend.NSAccessibility_Element_Registry.Element_Id;
      Selector    : NSAX_Selector;
      Child_Index : Positive := 1;
      Operand_Code : Interfaces.Unsigned_32 := 0)
      return Selector_Frame;

   function Build_Callback_Frame
     (Session_Code  : Interfaces.Unsigned_64;
      Element_Code  : Interfaces.Unsigned_64;
      Raw_Selector_Code : Interfaces.Unsigned_32;
      Operand_Code  : Interfaces.Unsigned_32 := 0)
      return Selector_Frame;

   function Dispatch_Selector_Frame
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Frame     : Selector_Frame;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Report    : out Selector_Frame_Report)
      return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
        .Boundary_Reply;

   function Dispatch_Callback
     (Registry  :
        in out A11y.MacOS_Backend.NSAccessibility_Element_Registry
          .Element_Registry;
      Session_Code  : Interfaces.Unsigned_64;
      Element_Code  : Interfaces.Unsigned_64;
      Selector_Code : Interfaces.Unsigned_32;
      Operand_Code  : Interfaces.Unsigned_32;
      Snapshots :
        A11y.MacOS_Backend.NSAccessibility_Request_Router.Snapshot_Bundle;
      Report    : out Selector_Frame_Report)
      return A11y.MacOS_Backend.NSAccessibility_Provider_Boundary
        .Boundary_Reply;

end A11y.MacOS_Backend.NSAccessibility_ABI_Surface;
