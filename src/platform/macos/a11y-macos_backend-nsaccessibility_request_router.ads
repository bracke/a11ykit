with Ada.Strings.Unbounded;
with Ada.Strings.Wide_Wide_Unbounded;

with A11y.Actions;
with A11y.Events;
with A11y.Geometry;
with A11y.MacOS_Backend.NSAccessibility_Actions;
with A11y.MacOS_Backend.NSAccessibility_Document;
with A11y.MacOS_Backend.NSAccessibility_Hierarchy;
with A11y.MacOS_Backend.NSAccessibility_Image;
with A11y.MacOS_Backend.NSAccessibility_Live_Regions;
with A11y.MacOS_Backend.NSAccessibility_Mappings;
with A11y.MacOS_Backend.NSAccessibility_Properties;
with A11y.MacOS_Backend.NSAccessibility_Selection;
with A11y.MacOS_Backend.NSAccessibility_Surfaces;
with A11y.MacOS_Backend.NSAccessibility_Table;
with A11y.MacOS_Backend.NSAccessibility_Text;
with A11y.MacOS_Backend.NSAccessibility_Values;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Selection;
with A11y.States;
with A11y.Tables;
with A11y.Text;
with A11y.Trees;
with A11y.Values;

package A11y.MacOS_Backend.NSAccessibility_Request_Router is

   type Action_Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Relation_Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Event_Exposure_Table is array (Natural range 0 .. 4_095) of
     A11y.Nodes.Exposure_Policy;

   type Request_Kind is
     (Attribute_Names_Query,
      Attribute_Query,
      Attribute_Settable_Query,
      Action_Set_Query,
      Action_Map_Query,
      Action_Request_Query,
      Parent_Query,
      Children_Query,
      Child_At_Query,
      Element_Id_Query,
      Relation_Query,
      Value_Query,
      Value_Set_Query,
      Selection_Query,
      Selection_Request_Query,
      Text_Query,
      Text_Edit_Query,
      Table_Query,
      Image_Query,
      Document_Query,
      Live_Region_Query,
      Surface_Query,
      Notification_Query);

   type Request is record
      Kind      : Request_Kind := Attribute_Query;
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

   type Snapshot_Bundle is record
      Properties :
        A11y.MacOS_Backend.NSAccessibility_Properties.Property_Snapshot;
      Actions    : A11y.Actions.Action_Set := A11y.Actions.Empty_Action_Set;
      Action_States : A11y.States.State_Set :=
        A11y.States.With_State
          (A11y.States.Empty_State_Set, A11y.States.Enabled);
      Action_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Action_Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Action_Tree : A11y.Trees.Semantic_Tree;
      Action_Use_Tree_Projection : Boolean := False;
      Action_Exposure : Action_Exposure_Table :=
        [others => A11y.Nodes.Expose_Node];
      Hierarchy  :
        A11y.MacOS_Backend.NSAccessibility_Hierarchy.Hierarchy_Snapshot;
      Relations  : A11y.Relations.Relation_Graph;
      Relation_Source : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Relation_Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Relation_Tree : A11y.Trees.Semantic_Tree;
      Relation_Use_Tree_Projection : Boolean := False;
      Relation_Exposure : Relation_Exposure_Table :=
        [others => A11y.Nodes.Expose_Node];
      Value      : A11y.MacOS_Backend.NSAccessibility_Values.Value_Snapshot;
      Selection  :
        A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Snapshot;
      Text       : A11y.MacOS_Backend.NSAccessibility_Text.Text_Snapshot;
      Table      : A11y.MacOS_Backend.NSAccessibility_Table.Table_Snapshot;
      Image      : A11y.MacOS_Backend.NSAccessibility_Image.Image_Snapshot;
      Document   :
        A11y.MacOS_Backend.NSAccessibility_Document.Document_Snapshot;
      Live_Region :
        A11y.MacOS_Backend.NSAccessibility_Live_Regions.Live_Snapshot;
      Surface    :
        A11y.MacOS_Backend.NSAccessibility_Surfaces.Surface_Snapshot;
      Event_Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Event_Tree : A11y.Trees.Semantic_Tree;
      Event_Use_Tree_Projection : Boolean := False;
      Event_Exposure : Event_Exposure_Table :=
        [others => A11y.Nodes.Expose_Node];
      Limits     : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   end record;

   type Routed_Reply_Kind is
     (Attribute_Set,
      Attribute_String,
      Attribute_Empty_String,
      Attribute_Integer,
      Attribute_Boolean,
      Attribute_Rectangle,
      Attribute_Role,
      Attribute_Not_Supported,
      Action_Set,
      Action_Mapping,
      Action_Request,
      Hierarchy_Node,
      Hierarchy_Children,
      Hierarchy_Empty,
      Element_Id,
      Relation_Targets,
      Relation_Empty,
      Relation_Not_Supported,
      Value_Float,
      Value_Boolean,
      Value_Set_Request,
      Value_Not_Applicable,
      Selection_UInt32,
      Selection_Boolean,
      Selection_Node,
      Selection_Direction,
      Selection_Request_Reply,
      Selection_Nil,
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
      Surface_Boolean,
      Notification,
      Routed_Error);

   type Routed_Reply (Kind : Routed_Reply_Kind := Routed_Error) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Kind is
         when Attribute_Set =>
            Attributes :
              A11y.MacOS_Backend.NSAccessibility_Properties.Core_Attribute_Set :=
                A11y.MacOS_Backend.NSAccessibility_Properties
                  .Empty_Core_Attribute_Set;
         when Notification =>
            Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
              A11y.Native_Object_Caches.No_Object;
         when Value_Float =>
            Float_Item : Long_Float := 0.0;
         when Attribute_Boolean | Value_Boolean | Selection_Boolean
            | Document_Boolean | Live_Boolean | Surface_Boolean =>
            Boolean_Item : Boolean := False;
         when Text_UInt32 | Table_UInt32 | Document_UInt32
            | Selection_UInt32 =>
            UInt32 : Natural := 0;
         when Attribute_Integer =>
            Integer_Item : Integer := 0;
         when Action_Set =>
            Actions :
              A11y.MacOS_Backend.NSAccessibility_Actions.NSAX_Action_Set :=
                A11y.MacOS_Backend.NSAccessibility_Actions
                  .Empty_NSAX_Action_Set;
         when Action_Mapping =>
            Mapping :
              A11y.MacOS_Backend.NSAccessibility_Actions.Action_Mapping;
         when Hierarchy_Node | Selection_Node | Table_Node =>
            Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         when Hierarchy_Children =>
            Children : A11y.Trees.Child_Vectors.Vector;
         when Element_Id =>
            Id : A11y.MacOS_Backend.NSAccessibility_Hierarchy.Element_Id;
         when Selection_Request_Reply =>
            Selection_Target : A11y.Node_Ids.Node_Id :=
              A11y.Node_Ids.No_Node;
            Selection_Request :
              A11y.MacOS_Backend.NSAccessibility_Selection.Selection_Request_Kind :=
                A11y.MacOS_Backend.NSAccessibility_Selection.Select_Item;
         when Action_Request =>
            Requested_Action : A11y.Actions.Action_Id := A11y.Actions.Activate;
         when Selection_Direction =>
            Direction : A11y.Selection.Selection_Direction :=
              A11y.Selection.No_Direction;
         when Value_Set_Request =>
            Requested_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
         when Text_Wide_Text =>
            Wide_Text :
              Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
         when Text_Edit_Request =>
            Requested_Edit : A11y.Text.Text_Edit_Request;
         when Attribute_String | Image_String | Document_String | Live_String
            | Surface_String =>
            Text : Ada.Strings.Unbounded.Unbounded_String;
         when Attribute_Rectangle =>
            Bounds : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
         when Attribute_Role =>
            Role :
              A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Role :=
                A11y.MacOS_Backend.NSAccessibility_Mappings.Unknown;
         when Relation_Targets =>
            Relation_Attribute :
              A11y.MacOS_Backend.NSAccessibility_Mappings
                .NSAX_Relation_Attribute :=
                  A11y.MacOS_Backend.NSAccessibility_Mappings
                    .Unsupported_Relation;
            Relation_Target_Nodes : A11y.Relations.Target_Vectors.Vector;
         when Image_Size =>
            Size : A11y.Geometry.Size := (Width => 0, Height => 0);
         when others =>
            null;
      end case;
   end record;

   function Dispatch
     (Item      : Request;
      Snapshots : Snapshot_Bundle)
      return Routed_Reply;

end A11y.MacOS_Backend.NSAccessibility_Request_Router;
