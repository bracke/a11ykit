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
with A11y.MacOS_Backend.NSAccessibility_Mappings;

package A11y.MacOS_Backend.NSAccessibility_Events is

   type NSAX_Notification is
     (Focused_UI_Element_Changed,
      Title_Changed,
      Value_Changed,
      Selected_Children_Changed,
      Selected_Text_Changed,
      Row_Count_Changed,
      Layout_Changed,
      UI_Element_Destroyed,
      Window_Created,
      Window_Moved,
      Window_Resized,
      Main_Window_Changed,
      Announcement_Requested,
      Live_Region_Changed);

   type NSAX_Attribute_Event is
     (No_Attribute_Event,
      Title_Attribute,
      Description_Attribute,
      Help_Attribute,
      Placeholder_Attribute,
      Value_Attribute,
      Identifier_Attribute,
      Locale_Attribute,
      Enabled_Attribute,
      Focused_Attribute,
      Selected_Attribute,
      Children_Attribute,
      Selected_Children_Attribute,
      Selected_Text_Attribute,
      Visible_Character_Range_Attribute,
      Row_Count_Attribute,
      Column_Count_Attribute,
      Layout_Attribute,
      Window_Attribute,
      Live_Region_Attribute,
      Relation_Attribute);

   type NSAX_Window_Event is
     (No_Window_Event,
      Window_Created_Event,
      Window_Destroyed_Event,
      Window_Activated_Event,
      Window_Deactivated_Event,
      Window_Moved_Event,
      Window_Resized_Event);

   type NSAX_Event_Emission (Publishable : Boolean := False) is record
      Status : A11y.Results.Status_Code := A11y.Results.Success;
      case Publishable is
         when True =>
            Source       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
            Native_Object :
              A11y.Native_Object_Caches.Native_Object_Id :=
                A11y.Native_Object_Caches.No_Object;
            Notification : NSAX_Notification := Layout_Changed;
            Attribute    : NSAX_Attribute_Event := No_Attribute_Event;
            Window       : NSAX_Window_Event := No_Window_Event;
            Relation     :
              A11y.MacOS_Backend.NSAccessibility_Mappings.NSAX_Relation_Attribute :=
                A11y.MacOS_Backend.NSAccessibility_Mappings.Unsupported_Relation;
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
            Sequence     : A11y.Event_Sequence := A11y.No_Event;
            Revision     : A11y.Semantic_Revision := A11y.Initial_Revision;
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
      Can_Post       : Boolean := False;
      Has_Pending    : Boolean := False;
      Overflowed     : Boolean := False;
      Length         : Natural := 0;
      Capacity       : Natural := 0;
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
      Emission : NSAX_Event_Emission;
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
      Emission : out NSAX_Event_Emission;
      Result   : out A11y.Results.Result);

   procedure Dequeue
     (Queue    : in out Event_Emission_Queue;
      Emission : out NSAX_Event_Emission;
      Result   : out A11y.Results.Result);

   procedure Dequeue_For_Posting
     (Queue    : in out Event_Emission_Queue;
      Emission : out NSAX_Event_Emission;
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
      Emission : out NSAX_Event_Emission;
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
        (Emission : NSAX_Event_Emission;
         Result   : out A11y.Results.Result);
      Report       : out Posting_Drain_Report;
      Result       : out A11y.Results.Result);

   procedure Clear (Queue : in out Event_Emission_Queue);

   function Validate_For_Posting
     (Emission : NSAX_Event_Emission)
      return A11y.Results.Result;

   function Notification_Code
     (Notification : NSAX_Notification)
      return Natural;

   function Map_Event
     (Kind : A11y.Events.Event_Kind)
      return NSAX_Notification;

   function Map_Attribute_Event
     (Kind : A11y.Events.Event_Kind)
      return NSAX_Attribute_Event;

   function Map_Attribute_Event
     (Property : A11y.Properties.Property_Id)
      return NSAX_Attribute_Event;

   function Map_State_Event
     (State : A11y.States.State_Flag)
      return NSAX_Attribute_Event;

   function Map_Window_Event
     (Kind : A11y.Events.Event_Kind)
      return NSAX_Window_Event;

   function Build_Event
     (Event : A11y.Events.Event)
      return NSAX_Event_Emission;

   function Build_Prepared_Event
     (Prepared : A11y.Native_Runtimes.Prepared_Event)
      return NSAX_Event_Emission;

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
      Emission : out NSAX_Event_Emission;
      Report   : out Event_Build_Report);

   procedure Build_Prepared_Event_With_Report
     (Prepared : A11y.Native_Runtimes.Prepared_Event;
      Emission : out NSAX_Event_Emission;
      Report   : out Event_Build_Report);

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Property_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.State_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Relation_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Bounds_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Focus_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Node_Reference_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Value_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Selection_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Live_Region_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Tree_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Table_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Document_Event_Payload)
      return NSAX_Event_Emission;

   function Build_Event
     (Event   : A11y.Events.Event;
      Payload : A11y.Events.Window_Event_Payload)
      return NSAX_Event_Emission;

private

   package Event_Emission_Vectors is new Ada.Containers.Vectors
     (Index_Type   => Positive,
      Element_Type => NSAX_Event_Emission);

   type Event_Emission_Queue is record
      Items        : Event_Emission_Vectors.Vector;
      Limit        : Natural := Max_Queued_Events;
      Had_Overflow : Boolean := False;
   end record;

end A11y.MacOS_Backend.NSAccessibility_Events;
