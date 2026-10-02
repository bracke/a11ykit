with Ada.Containers.Vectors;
with Ada.Strings.Wide_Wide_Unbounded;

with A11y.Geometry;
with A11y.Live_Regions;
with A11y.Node_Ids;
with A11y.Properties;
with A11y.Relations;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.States;
with A11y.Tables;
with A11y.Text;
with A11y.Values;
with A11y.Windows;

package A11y.Events is

   type Event_Kind is
     (Node_Created,
      Node_Destroyed,
      Node_Attached,
      Node_Detached,
      Child_Added,
      Child_Removed,
      Children_Reordered,
      Subtree_Rebuilt,
      Property_Changed,
      State_Changed,
      Bounds_Changed,
      Focus_Changed,
      Active_Descendant_Changed,
      Selection_Changed,
      Current_Item_Changed,
      Value_Changed,
      Range_Changed,
      Text_Inserted,
      Text_Removed,
      Text_Replaced,
      Caret_Moved,
      Text_Selection_Changed,
      Text_Attributes_Changed,
      Row_Inserted,
      Row_Removed,
      Column_Inserted,
      Column_Removed,
      Cell_Changed,
      Window_Opened,
      Window_Closed,
      Window_Activated,
      Window_Deactivated,
      Document_Loaded,
      Document_Closed,
      Announcement_Requested,
      Live_Region_Changed,
      Relation_Added,
      Relation_Removed,
      Relation_Targets_Changed);

   type Event_Metadata is record
      Stable_Name : access constant String;
      Coalescible : Boolean := False;
   end record;

   type Event is record
      Sequence : A11y.Event_Sequence := A11y.No_Event;
      Timestamp : A11y.Timestamp;
      Source : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Kind : Event_Kind := Node_Created;
      Revision : A11y.Semantic_Revision := A11y.Initial_Revision;
   end record;

   function Validate_Event
     (Item : Event)
      return A11y.Results.Result
   with
     SPARK_Mode => On,
     Global => null;

   type Text_Event_Payload is record
      Span : A11y.Text.Text_Range := A11y.Text.Empty_Range;
      Text : Ada.Strings.Wide_Wide_Unbounded.Unbounded_Wide_Wide_String;
      Carries_Text : Boolean := False;
   end record;

   type Property_Event_Payload is record
      Property   : A11y.Properties.Property_Id :=
        A11y.Properties.Accessible_Name;
      Value_Kind : A11y.Properties.Property_Value_Kind :=
        A11y.Properties.String_Value;
      Old_Status : A11y.Properties.Property_Status :=
        A11y.Properties.Unsupported;
      New_Status : A11y.Properties.Property_Status :=
        A11y.Properties.Unsupported;
   end record;

   type State_Event_Payload is record
      State     : A11y.States.State_Flag := A11y.States.Enabled;
      Source    : A11y.States.State_Source := A11y.States.Application_Provided;
      Old_Value : Boolean := False;
      New_Value : Boolean := False;
   end record;

   type Relation_Event_Payload is record
      Relation   : A11y.Relations.Relation_Kind := A11y.Relations.Labelled_By;
      Inverse    : A11y.Relations.Relation_Kind := A11y.Relations.Label_For;
      Target     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Target : Boolean := False;
   end record;

   type Bounds_Event_Payload is record
      Old_Bounds : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
      New_Bounds : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
   end record;

   type Focus_Event_Payload is record
      Old_Focus : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      New_Focus : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   type Node_Reference_Event_Payload is record
      Old_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      New_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   end record;

   type Value_Event_Payload is record
      Old_Value : A11y.Values.Semantic_Value := (Kind => A11y.Values.Unknown);
      New_Value : A11y.Values.Semantic_Value := (Kind => A11y.Values.Unknown);
      Old_Kind  : A11y.Values.Value_Kind := A11y.Values.Unknown;
      New_Kind  : A11y.Values.Value_Kind := A11y.Values.Unknown;
   end record;

   type Selection_Event_Payload is record
      Changed_Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Changed_Node   : Boolean := False;
      Old_Selected       : Boolean := False;
      New_Selected       : Boolean := False;
      Requires_Selection : Boolean := False;
   end record;

   type Live_Region_Event_Payload is record
      Metadata         : A11y.Live_Regions.Live_Region_Metadata;
      Announcement     : A11y.Live_Regions.Announcement;
      Has_Announcement : Boolean := False;
   end record;

   type Tree_Event_Payload is record
      Parent    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Child     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Child : Boolean := False;
      Index     : Positive := Positive'First;
      Has_Index : Boolean := False;
   end record;

   type Table_Event_Payload is record
      Table      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Item       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Item   : Boolean := False;
      Row        : A11y.Tables.Logical_Index := 0;
      Has_Row    : Boolean := False;
      Column     : A11y.Tables.Logical_Index := 0;
      Has_Column : Boolean := False;
   end record;

   type Document_Event_Payload is record
      Document    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Surface     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Surface : Boolean := False;
   end record;

   type Window_Event_Payload is record
      Surface   : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Kind      : A11y.Windows.Surface_Kind := A11y.Windows.Window;
      Owner     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Has_Owner : Boolean := False;
   end record;

   package Event_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Event);

   function Metadata (Kind : Event_Kind) return Event_Metadata;

   function Stable_Name (Kind : Event_Kind) return String;

   function Is_Coalescible (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Coalescible'Result =
       (Kind in Bounds_Changed | Value_Changed);

   function Is_Text_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Text_Event'Result =
       (Kind in Text_Inserted | Text_Removed | Text_Replaced | Caret_Moved
        | Text_Selection_Changed | Text_Attributes_Changed);

   function Is_Property_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Property_Event'Result =
       (Kind in Property_Changed | Bounds_Changed);

   function Is_State_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_State_Event'Result =
       (Kind in State_Changed | Focus_Changed | Active_Descendant_Changed);

   function Is_Value_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Value_Event'Result =
       (Kind in Value_Changed | Range_Changed);

   function Is_Selection_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Selection_Event'Result =
       (Kind in Selection_Changed | Current_Item_Changed
        | Text_Selection_Changed);

   function Is_Focus_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Focus_Event'Result =
       (Kind in Focus_Changed | Active_Descendant_Changed
        | Current_Item_Changed);

   function Is_Live_Region_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Live_Region_Event'Result =
       (Kind in Announcement_Requested | Live_Region_Changed);

   function Is_Lifecycle_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Lifecycle_Event'Result =
       (Kind in Node_Created | Node_Destroyed | Node_Attached | Node_Detached);

   function Is_Tree_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Tree_Event'Result =
       (Kind in Node_Created | Node_Destroyed | Node_Attached
        | Node_Detached | Child_Added | Child_Removed | Children_Reordered
        | Subtree_Rebuilt);

   function Is_Table_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Table_Event'Result =
       (Kind in Row_Inserted | Row_Removed | Column_Inserted
        | Column_Removed | Cell_Changed);

   function Is_Document_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Document_Event'Result =
       (Kind in Document_Loaded | Document_Closed);

   function Is_Relation_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Relation_Event'Result =
       (Kind in Active_Descendant_Changed | Relation_Added
        | Relation_Removed | Relation_Targets_Changed);

   function Is_Window_Event (Kind : Event_Kind) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Window_Event'Result =
       (Kind in Window_Opened | Window_Closed | Window_Activated
        | Window_Deactivated);

   function Must_Preserve_Individual_Order
     (Kind : Event_Kind)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Must_Preserve_Individual_Order'Result =
       (Is_Text_Event (Kind) or else Is_Lifecycle_Event (Kind)
        or else Is_Relation_Event (Kind));

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Text           : Wide_Wide_String;
      Policy         : A11y.Text.Protected_Text_Policy;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload;

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Start          : Natural;
      Count          : Natural;
      Text           : Wide_Wide_String;
      Policy         : A11y.Text.Protected_Text_Policy;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload;

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Payload        : Text_Event_Payload;
      Policy         : A11y.Text.Protected_Text_Policy;
      Limits         : A11y.Resource_Limits.Resource_Limit_Config;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload;

   function Validate_Text_Event_Payload
     (Kind           : Event_Kind;
      Content_Length : Natural;
      Payload        : Text_Event_Payload;
      Policy         : A11y.Text.Protected_Text_Policy;
      Result         : out A11y.Results.Result)
      return Text_Event_Payload;

   function Validate_Property_Event_Payload
     (Kind       : Event_Kind;
      Property   : A11y.Properties.Property_Id;
      Old_Status : A11y.Properties.Property_Status;
      New_Status : A11y.Properties.Property_Status;
      Result     : out A11y.Results.Result)
      return Property_Event_Payload;

   function Validate_Property_Event_Payload
     (Kind    : Event_Kind;
      Payload : Property_Event_Payload;
      Result  : out A11y.Results.Result)
      return Property_Event_Payload;

   function Validate_State_Event_Payload
     (Kind      : Event_Kind;
      State     : A11y.States.State_Flag;
      Old_Value : Boolean;
      New_Value : Boolean;
      Result    : out A11y.Results.Result)
      return State_Event_Payload;

   function Validate_State_Event_Payload
     (Kind    : Event_Kind;
      Payload : State_Event_Payload;
      Result  : out A11y.Results.Result)
      return State_Event_Payload;

   function Validate_Relation_Event_Payload
     (Kind       : Event_Kind;
      Relation   : A11y.Relations.Relation_Kind;
      Target     : A11y.Node_Ids.Node_Id;
      Has_Target : Boolean;
      Result     : out A11y.Results.Result)
      return Relation_Event_Payload;

   function Validate_Relation_Event_Payload
     (Kind    : Event_Kind;
      Payload : Relation_Event_Payload;
      Result  : out A11y.Results.Result)
      return Relation_Event_Payload;

   function Validate_Bounds_Event_Payload
     (Kind       : Event_Kind;
      Old_Bounds : A11y.Geometry.Rectangle;
      New_Bounds : A11y.Geometry.Rectangle;
      Result     : out A11y.Results.Result)
      return Bounds_Event_Payload;

   function Validate_Bounds_Event_Payload
     (Kind    : Event_Kind;
      Payload : Bounds_Event_Payload;
      Result  : out A11y.Results.Result)
      return Bounds_Event_Payload;

   function Validate_Focus_Event_Payload
     (Kind      : Event_Kind;
      Old_Focus : A11y.Node_Ids.Node_Id;
      New_Focus : A11y.Node_Ids.Node_Id;
      Result    : out A11y.Results.Result)
      return Focus_Event_Payload;

   function Validate_Focus_Event_Payload
     (Kind    : Event_Kind;
      Payload : Focus_Event_Payload;
      Result  : out A11y.Results.Result)
      return Focus_Event_Payload;

   function Validate_Node_Reference_Event_Payload
     (Kind     : Event_Kind;
      Old_Node : A11y.Node_Ids.Node_Id;
      New_Node : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
      return Node_Reference_Event_Payload;

   function Validate_Node_Reference_Event_Payload
     (Kind    : Event_Kind;
      Payload : Node_Reference_Event_Payload;
      Result  : out A11y.Results.Result)
      return Node_Reference_Event_Payload;

   function Validate_Value_Event_Payload
     (Kind      : Event_Kind;
      Old_Value : A11y.Values.Semantic_Value;
      New_Value : A11y.Values.Semantic_Value;
      Result    : out A11y.Results.Result)
      return Value_Event_Payload;

   function Validate_Value_Event_Payload
     (Kind    : Event_Kind;
      Payload : Value_Event_Payload;
      Result  : out A11y.Results.Result)
      return Value_Event_Payload;

   function Validate_Selection_Event_Payload
     (Kind               : Event_Kind;
      Changed_Node       : A11y.Node_Ids.Node_Id;
      Has_Changed_Node   : Boolean;
      Old_Selected       : Boolean;
      New_Selected       : Boolean;
      Requires_Selection : Boolean;
      Result             : out A11y.Results.Result)
      return Selection_Event_Payload;

   function Validate_Selection_Event_Payload
     (Kind    : Event_Kind;
      Payload : Selection_Event_Payload;
      Result  : out A11y.Results.Result)
      return Selection_Event_Payload;

   function Validate_Live_Region_Event_Payload
     (Kind             : Event_Kind;
      Metadata         : A11y.Live_Regions.Live_Region_Metadata;
      Announcement     : A11y.Live_Regions.Announcement;
      Has_Announcement : Boolean;
      Result           : out A11y.Results.Result)
      return Live_Region_Event_Payload;

   function Validate_Live_Region_Event_Payload
     (Kind    : Event_Kind;
      Payload : Live_Region_Event_Payload;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result)
      return Live_Region_Event_Payload;

   function Validate_Live_Region_Event_Payload
     (Kind    : Event_Kind;
      Payload : Live_Region_Event_Payload;
      Result  : out A11y.Results.Result)
      return Live_Region_Event_Payload;

   function Validate_Tree_Event_Payload
     (Kind      : Event_Kind;
      Parent    : A11y.Node_Ids.Node_Id;
      Child     : A11y.Node_Ids.Node_Id;
      Has_Child : Boolean;
      Index     : Positive;
      Has_Index : Boolean;
      Result    : out A11y.Results.Result)
      return Tree_Event_Payload;

   function Validate_Tree_Event_Payload
     (Kind    : Event_Kind;
      Payload : Tree_Event_Payload;
      Result  : out A11y.Results.Result)
      return Tree_Event_Payload;

   function Validate_Table_Event_Payload
     (Kind       : Event_Kind;
      Table      : A11y.Node_Ids.Node_Id;
      Item       : A11y.Node_Ids.Node_Id;
      Has_Item   : Boolean;
      Row        : A11y.Tables.Logical_Index;
      Has_Row    : Boolean;
      Column     : A11y.Tables.Logical_Index;
      Has_Column : Boolean;
      Result     : out A11y.Results.Result)
      return Table_Event_Payload;

   function Validate_Table_Event_Payload
     (Kind    : Event_Kind;
      Payload : Table_Event_Payload;
      Result  : out A11y.Results.Result)
      return Table_Event_Payload;

   function Validate_Document_Event_Payload
     (Kind        : Event_Kind;
      Document    : A11y.Node_Ids.Node_Id;
      Surface     : A11y.Node_Ids.Node_Id;
      Has_Surface : Boolean;
      Result      : out A11y.Results.Result)
      return Document_Event_Payload;

   function Validate_Document_Event_Payload
     (Kind    : Event_Kind;
      Payload : Document_Event_Payload;
      Result  : out A11y.Results.Result)
      return Document_Event_Payload;

   function Validate_Window_Event_Payload
     (Kind      : Event_Kind;
      Surface   : A11y.Node_Ids.Node_Id;
      Surface_Kind : A11y.Windows.Surface_Kind;
      Owner     : A11y.Node_Ids.Node_Id;
      Has_Owner : Boolean;
      Result    : out A11y.Results.Result)
      return Window_Event_Payload;

   function Validate_Window_Event_Payload
     (Kind    : Event_Kind;
      Payload : Window_Event_Payload;
      Result  : out A11y.Results.Result)
      return Window_Event_Payload;

end A11y.Events;
