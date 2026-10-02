with A11y.Actions;
with A11y.Geometry;
with A11y.Linux.ATSPi_Accessible;
with A11y.Linux.ATSPi_Action;
with A11y.Linux.ATSPi_Application;
with A11y.Linux.ATSPi_Component;
with A11y.Linux.ATSPi_Document;
with A11y.Linux.ATSPi_Image;
with A11y.Linux.ATSPi_Live_Regions;
with A11y.Linux.ATSPi_Mappings;
with A11y.Linux.ATSPi_Objects;
with A11y.Linux.ATSPi_Selection;
with A11y.Linux.ATSPi_Surfaces;
with A11y.Linux.ATSPi_Table;
with A11y.Linux.ATSPi_Text;
with A11y.Linux.ATSPi_Value;
with A11y.Linux.DBus_Codec;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Tables;
with A11y.Text;
with A11y.Trees;
with A11y.Values;

package A11y.Linux.ATSPi_Method_Router is

   type Snapshot_Bundle is record
      Application : A11y.Linux.ATSPi_Application.Application_Snapshot;
      Accessible  : A11y.Linux.ATSPi_Accessible.Accessible_Snapshot;
      Component   : A11y.Linux.ATSPi_Component.Component_Snapshot;
      Action      : A11y.Linux.ATSPi_Action.Action_Snapshot;
      Value       : A11y.Linux.ATSPi_Value.Value_Snapshot;
      Selection   : A11y.Linux.ATSPi_Selection.Selection_Snapshot;
      Text        : A11y.Linux.ATSPi_Text.Text_Snapshot;
      Table       : A11y.Linux.ATSPi_Table.Table_Method_Snapshot;
      Image       : A11y.Linux.ATSPi_Image.Image_Snapshot;
      Document    : A11y.Linux.ATSPi_Document.Document_Snapshot;
      Live_Region : A11y.Linux.ATSPi_Live_Regions.Live_Snapshot;
      Surface     : A11y.Linux.ATSPi_Surfaces.Surface_Snapshot;
      Limits      : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   end record;

   type Method_Request is record
      Session         : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Path            : A11y.Properties.UString;
      Requested_Interface : A11y.Linux.ATSPi_Objects.ATSPI_Interface :=
        A11y.Linux.ATSPi_Objects.Accessible;
      Method          : A11y.Properties.UString;
      Index           : Natural := 0;
      Count           : Natural := 0;
      Point           : A11y.Geometry.Point := (X => 0, Y => 0);
      Row             : A11y.Tables.Logical_Index := 0;
      Column          : A11y.Tables.Logical_Index := 0;
      Attribute       : A11y.Properties.UString;
      Requested_Value : A11y.Values.Semantic_Value :=
        (Kind => A11y.Values.Unknown);
   end record;

   type Routed_Reply_Kind is
     (Empty_Method_Return,
      DBus_Variant_String,
      DBus_Variant_UInt32,
      DBus_Property_Map,
      Application_String,
      Application_UInt32,
      Accessible_Role,
      Accessible_State_Set,
      Accessible_String,
      Accessible_UInt32,
      Accessible_Int32,
      Accessible_Node,
      Accessible_Node_Array,
      Accessible_String_Array,
      Accessible_Attribute_Set,
      Accessible_Relation_Set,
      Component_Rectangle,
      Component_Boolean,
      Component_Node,
      Action_UInt32,
      Action_String,
      Action_Invocation,
      Value_Float,
      Value_Set_Request,
      Selection_UInt32,
      Selection_Boolean,
      Selection_Node,
      Selection_Request,
      Text_UInt32,
      Text_Wide_Text,
      Text_Edit_Request,
      Table_UInt32,
      Table_Node,
      Image_String,
      Image_Size,
      Document_String,
      Document_UInt32,
      Document_Boolean,
      Live_String,
      Live_Boolean,
      Surface_String,
      Surface_Role,
      Surface_State_Set,
      Surface_Boolean,
      Routed_Error);

   type Routed_Reply is record
      Kind         : Routed_Reply_Kind := Routed_Error;
      Status       : A11y.Results.Status_Code := A11y.Results.Success;
      Text         : A11y.Properties.UString;
      UInt32       : Natural := 0;
      Int32        : Integer := 0;
      Boolean_Item : Boolean := False;
      Float_Item   : Long_Float := 0.0;
      Node         : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Nodes        : A11y.Trees.Child_Vectors.Vector;
      Strings      : A11y.Linux.DBus_Codec.String_Vectors.Vector;
      Bounds       : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
      Size         : A11y.Geometry.Size := (Width => 0, Height => 0);
      State_Set    : A11y.Linux.ATSPi_Mappings.ATSPI_State_Set :=
        A11y.Linux.ATSPi_Mappings.Empty_ATSPI_State_Set;
      Attributes   :
        A11y.Linux.ATSPi_Accessible.Attribute_Entry_Vectors.Vector;
      Relations    : A11y.Linux.ATSPi_Accessible.Relation_Entry_Vectors.Vector;
      Requested_Action : A11y.Actions.Action_Id := A11y.Actions.Activate;
      Requested_Value : A11y.Values.Semantic_Value :=
        (Kind => A11y.Values.Unknown);
      Selection_Request :
        A11y.Linux.ATSPi_Selection.Selection_Request_Kind :=
          A11y.Linux.ATSPi_Selection.Select_Child;
      Requested_Edit : A11y.Text.Text_Edit_Request;
   end record;

   function Dispatch
     (Request   : Method_Request;
      Snapshots : Snapshot_Bundle)
      return Routed_Reply;

end A11y.Linux.ATSPi_Method_Router;
