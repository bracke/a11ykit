with Ada.Containers.Vectors;

with A11y.Events;
with A11y.Geometry;
with A11y.Native_Object_Caches;
with A11y.Native_Runtimes;
with A11y.Node_Ids;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.States;
with A11y.Values;
with A11y.Windows_Backend.UIA_Mappings;

package A11y.Windows_Backend.UIA_Events is

   type UIA_Event_Kind is
     (Automation_Focus_Changed,
      Automation_Property_Changed,
      Automation_Structure_Changed,
      Automation_Selection_Invalidated,
      Automation_Text_Changed,
      Automation_Text_Selection_Changed,
      Automation_Live_Region_Changed,
      Automation_Notification,
      Automation_Window_Opened,
      Automation_Window_Closed,
      Automation_Layout_Invalidated);

   type UIA_Property_Event is
     (No_Property_Event,
      Name_Property,
      Description_Property,
      Help_Text_Property,
      Placeholder_Property,
      Automation_Id_Property,
      Localized_Control_Type_Property,
      Is_Enabled_Property,
      Has_Keyboard_Focus_Property,
      Is_Keyboard_Focusable_Property,
      Is_Offscreen_Property,
      Bounding_Rectangle_Property,
      Value_Property,
      Range_Value_Property,
      Orientation_Property,
      Position_In_Set_Property,
      Size_Of_Set_Property,
      Level_Property,
      Heading_Level_Property,
      Landmark_Type_Property,
      Is_Required_For_Form_Property,
      Selection_Property,
      Active_Descendant_Property,
      Relation_Property,
      Live_Setting_Property);

   type UIA_Structure_Event is
     (No_Structure_Event,
      Child_Added_Event,
      Child_Removed_Event,
      Children_Reordered_Event,
      Subtree_Rebuilt_Event,
      Row_Inserted_Event,
      Row_Removed_Event,
      Column_Inserted_Event,
      Column_Removed_Event,
      Cell_Changed_Event,
      Document_Loaded_Event,
      Document_Closed_Event);

   type UIA_Window_Event is
     (No_Window_Event,
      Window_Opened_Event,
      Window_Closed_Event,
      Window_Activated_Event,
      Window_Deactivated_Event);

   type UIA_Event_Emission (Publishable : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Publishable is
         when True =>
            Source    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Native_Object : A11y.Native_Object_Caches.Native_Object_Id :=
              A11y.Native_Object_Caches.No_Object;
            Kind      : UIA_Event_Kind := Automation_Property_Changed;
            Property  : UIA_Property_Event := No_Property_Event;
            Structure : UIA_Structure_Event := No_Structure_Event;
            Window    : UIA_Window_Event := No_Window_Event;
            Relation  : A11y.Windows_Backend.UIA_Mappings.UIA_Relation_Property :=
              A11y.Windows_Backend.UIA_Mappings.Unsupported_Relation;
            Has_Bounds_Payload : Boolean := False;
            Old_Bounds : A11y.Geometry.Rectangle :=
              A11y.Geometry.Empty_Rectangle;
            New_Bounds : A11y.Geometry.Rectangle :=
              A11y.Geometry.Empty_Rectangle;
            Has_Focus_Payload : Boolean := False;
            Old_Focus : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            New_Focus : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Has_Node_Reference_Payload : Boolean := False;
            Old_Reference : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            New_Reference : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Has_Value_Payload : Boolean := False;
            Old_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
            New_Value : A11y.Values.Semantic_Value :=
              (Kind => A11y.Values.Unknown);
            Has_Selection_Payload : Boolean := False;
            Selection_Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Selection_Has_Node : Boolean := False;
            Selection_Old_Selected : Boolean := False;
            Selection_New_Selected : Boolean := False;
            Selection_Required : Boolean := False;
            Has_Live_Region_Payload : Boolean := False;
            Live_Region_Payload : A11y.Events.Live_Region_Event_Payload;
            Has_Tree_Payload : Boolean := False;
            Tree_Payload : A11y.Events.Tree_Event_Payload;
            Has_Table_Payload : Boolean := False;
            Table_Payload : A11y.Events.Table_Event_Payload;
            Has_Document_Payload : Boolean := False;
            Document_Payload : A11y.Events.Document_Event_Payload;
            Has_Window_Payload : Boolean := False;
            Window_Payload : A11y.Events.Window_Event_Payload;
            Sequence  : A11y.Event_Sequence := A11y.No_Event;
            Revision  : A11y.Semantic_Revision := A11y.Initial_Revision;
         when False =>
            null;
      end case;
   end record;

   Max_Queued_Events : constant Natural := 1_024;

   type Event_Emission_Queue is private;

   function Queue_Length (Queue : Event_Emission_Queue) return Natural;
   function Queue_Capacity (Queue : Event_Emission_Queue) return Natural;
   function Queue_Overflowed (Queue : Event_Emission_Queue) return Boolean;

   type Queue_Posting_Operation is
     (No_Posting_Operation,
      Post_Next_Event,
      Back_Pressure);

   type Queue_Posting_Interest is record
      Can_Post      : Boolean := False;
      Has_Pending   : Boolean := False;
      Overflowed    : Boolean := False;
      Length        : Natural := 0;
      Capacity      : Natural := 0;
      Next_Operation : Queue_Posting_Operation := No_Posting_Operation;
   end record;

   function Posting_Interest
     (Queue : Event_Emission_Queue)
      return Queue_Posting_Interest;

   procedure Configure_Queue
     (Queue  : in out Event_Emission_Queue;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Set_Queue_Capacity
     (Queue    : in out Event_Emission_Queue;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Enqueue
     (Queue    : in out Event_Emission_Queue;
      Emission : UIA_Event_Emission;
      Result   : out A11y.Results.Result);

   procedure Enqueue_Prepared_Event
     (Queue    : in out Event_Emission_Queue;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Result   : out A11y.Results.Result);

   type Prepared_Enqueue_Report is record
      Source                 : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Sequence               : A11y.Event_Sequence := A11y.No_Event;
      Revision               : A11y.Semantic_Revision :=
        A11y.Initial_Revision;
      Length_Before          : Natural := 0;
      Length_After           : Natural := 0;
      Capacity               : Natural := 0;
      Had_Overflow           : Boolean := False;
      Prepared_Status        : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Validation_Status : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
      Prepared_Has_Object    : Boolean := False;
      Prepared_Destroys_Node : Boolean := False;
      Build_Publishable      : Boolean := False;
      Native_Object_Resolved : Boolean := False;
      Enqueued               : Boolean := False;
      Status                 : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Enqueue_Prepared_Event_With_Report
     (Queue    : in out Event_Emission_Queue;
      Prepared : A11y.Native_Runtimes.Prepared_Event;
      Report   : out Prepared_Enqueue_Report;
      Result   : out A11y.Results.Result);

   procedure Peek
     (Queue    : Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Result   : out A11y.Results.Result);

   procedure Dequeue
     (Queue    : in out Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Result   : out A11y.Results.Result);

   procedure Dequeue_For_Posting
     (Queue    : in out Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Result   : out A11y.Results.Result);

   type Posting_Attempt_Report is record
      Source          : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence        : A11y.Event_Sequence := A11y.No_Event;
      Revision        : A11y.Semantic_Revision := A11y.Initial_Revision;
      Length_Before   : Natural := 0;
      Length_After    : Natural := 0;
      Capacity        : Natural := 0;
      Had_Pending     : Boolean := False;
      Had_Overflow    : Boolean := False;
      Admitted        : Boolean := False;
      Emission_Taken  : Boolean := False;
      Next_Operation  : Queue_Posting_Operation := No_Posting_Operation;
      Status          : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Dequeue_For_Posting_With_Report
     (Queue    : in out Event_Emission_Queue;
      Emission : out UIA_Event_Emission;
      Report   : out Posting_Attempt_Report;
      Result   : out A11y.Results.Result);

   type Posting_Drain_Stop_Reason is
     (Not_Stopped,
      Invalid_Request,
      No_Pending,
      Back_Pressure,
      Iteration_Limit_Reached,
      Callback_Failed);

   type Posting_Drain_Report is record
      Last_Source    : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Last_Sequence  : A11y.Event_Sequence := A11y.No_Event;
      Last_Revision  : A11y.Semantic_Revision := A11y.Initial_Revision;
      Attempt_Limit   : Natural := 0;
      Attempts        : Natural := 0;
      Posted          : Natural := 0;
      Length_Before   : Natural := 0;
      Length_After    : Natural := 0;
      Capacity        : Natural := 0;
      Had_Overflow    : Boolean := False;
      Stop_Reason     : Posting_Drain_Stop_Reason := Not_Stopped;
      Last_Status     : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Drain_For_Posting_Bounded
     (Queue        : in out Event_Emission_Queue;
      Max_Attempts : Natural;
      Poster       : not null access procedure
        (Emission : UIA_Event_Emission;
         Result   : out A11y.Results.Result);
      Report       : out Posting_Drain_Report;
      Result       : out A11y.Results.Result);

   procedure Clear (Queue : in out Event_Emission_Queue);

   function Validate_For_Posting
     (Emission : UIA_Event_Emission)
      return A11y.Results.Result;

   function Map_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Event_Kind;

   function Map_Property_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Property_Event;

   function Map_Property_Event
     (Property : A11y.Properties.Property_Id)
      return UIA_Property_Event;

   function Map_State_Event
     (State : A11y.States.State_Flag)
      return UIA_Property_Event;

   function Map_Structure_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Structure_Event;

   function Map_Window_Event
     (Kind : A11y.Events.Event_Kind)
      return UIA_Window_Event;

   function Build_Event
     (Event : A11y.Events.Event)
      return UIA_Event_Emission;

   function Build_Prepared_Event
     (Prepared : A11y.Native_Runtimes.Prepared_Event)
      return UIA_Event_Emission;

   type Event_Build_Report is record
      Source       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence     : A11y.Event_Sequence := A11y.No_Event;
      Revision     : A11y.Semantic_Revision := A11y.Initial_Revision;
      Envelope_Valid : Boolean := False;
      Prepared_Input : Boolean := False;
      Prepared_Has_Object : Boolean := False;
      Prepared_Destroys_Node : Boolean := False;
      Native_Object_Resolved : Boolean := False;
      Publishable  : Boolean := False;
      Status       : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   procedure Build_Event_With_Report
     (Event    : A11y.Events.Event;
      Emission : out UIA_Event_Emission;
      Report   : out Event_Build_Report);

   procedure Build_Prepared_Event_With_Report
     (Prepared : A11y.Native_Runtimes.Prepared_Event;
      Emission : out UIA_Event_Emission;
      Report   : out Event_Build_Report);

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Property_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.State_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Relation_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Bounds_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Focus_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Node_Reference_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Value_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Selection_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Live_Region_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Tree_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Table_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Document_Event_Payload)
      return UIA_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Window_Event_Payload)
      return UIA_Event_Emission;

private

   package Event_Emission_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => UIA_Event_Emission);

   type Event_Emission_Queue is record
      Items        : Event_Emission_Vectors.Vector;
      Limit        : Natural := Max_Queued_Events;
      Had_Overflow : Boolean := False;
   end record;

end A11y.Windows_Backend.UIA_Events;
