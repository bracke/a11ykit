with Ada.Calendar;

with A11y.Backends;
with A11y.Events;
with A11y.Native_Identity;
with A11y.Native_Object_Caches;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Native_Runtimes is
   use type A11y.Backends.Backend_State;
   use type A11y.Events.Event_Kind;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Results.Status_Code;

   type Native_Runtime is limited private;

   type Runtime_Snapshot is record
      State       : A11y.Backends.Backend_State := A11y.Backends.Created;
      Generation  : Natural := 0;
      Session     : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Live_Objects : Natural := 0;
      Tombstones   : Natural := 0;
      Object_Cache_Generation : Natural := 0;
      Object_Capacity : Natural := A11y.Native_Object_Caches.Max_Native_Objects;
      Tombstone_Capacity : Natural :=
        A11y.Native_Object_Caches.Max_Native_Objects;
      Last_Event   : A11y.Event_Sequence := A11y.No_Event;
      Destroyed_Nodes : Natural := 0;
   end record;

   type Prepared_Event is record
      Status       : A11y.Results.Status_Code := A11y.Results.Success;
      Event        : A11y.Events.Event;
      Object       : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Has_Object   : Boolean := False;
      Destroys_Node : Boolean := False;
      Has_Property_Payload : Boolean := False;
      Property_Payload : A11y.Events.Property_Event_Payload;
      Has_State_Payload : Boolean := False;
      State_Payload : A11y.Events.State_Event_Payload;
      Has_Bounds_Payload : Boolean := False;
      Bounds_Payload : A11y.Events.Bounds_Event_Payload;
      Has_Value_Payload : Boolean := False;
      Value_Payload : A11y.Events.Value_Event_Payload;
      Has_Selection_Payload : Boolean := False;
      Selection_Payload : A11y.Events.Selection_Event_Payload;
      Has_Relation_Payload : Boolean := False;
      Relation_Payload : A11y.Events.Relation_Event_Payload;
      Has_Focus_Payload : Boolean := False;
      Focus_Payload : A11y.Events.Focus_Event_Payload;
      Has_Node_Reference_Payload : Boolean := False;
      Node_Reference_Payload : A11y.Events.Node_Reference_Event_Payload;
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
   end record;

   type Event_Preparation_Report is record
      State_Before       : A11y.Backends.Backend_State :=
        A11y.Backends.Created;
      State_After        : A11y.Backends.Backend_State :=
        A11y.Backends.Created;
      Generation_Before  : Natural := 0;
      Generation_After   : Natural := 0;
      Last_Event_Before  : A11y.Event_Sequence := A11y.No_Event;
      Last_Event_After   : A11y.Event_Sequence := A11y.No_Event;
      Source             : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Kind               : A11y.Events.Event_Kind := A11y.Events.Node_Created;
      Object             : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Has_Object         : Boolean := False;
      Destroys_Node      : Boolean := False;
      Was_Defunct        : Boolean := False;
      Is_Defunct         : Boolean := False;
      Admitted           : Boolean := False;
      Committed          : Boolean := False;
      Status             : A11y.Results.Status_Code :=
        A11y.Results.Node_Unavailable;
   end record;

   type Runtime_Transition_Kind is
     (Runtime_Initialize,
      Runtime_Start,
      Runtime_Stop);

   type Runtime_Lifecycle_Report is record
      Operation : Runtime_Transition_Kind := Runtime_Initialize;
      Before    : Runtime_Snapshot;
      After     : Runtime_Snapshot;
      Status    : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Advanced : Boolean := False;
      State_Changed       : Boolean := False;
      Session_Changed     : Boolean := False;
      Cache_Reset         : Boolean := False;
      Event_Order_Reset   : Boolean := False;
   end record;

   function Can_Initialize
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Initialize'Result =
          (State in A11y.Backends.Created | A11y.Backends.Stopped);

   function Needs_Initialize_Before_Start
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Needs_Initialize_Before_Start'Result =
          (State in A11y.Backends.Created | A11y.Backends.Stopped);

   function Can_Enter_Running
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Enter_Running'Result = (State = A11y.Backends.Initialized);

   function Accepts_Object_Work
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Accepts_Object_Work'Result = (State = A11y.Backends.Running);

   function Accepts_Event_Work
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Accepts_Event_Work'Result = (State = A11y.Backends.Running);

   function Accepts_Defunct_Mark
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Accepts_Defunct_Mark'Result =
          (State in A11y.Backends.Running | A11y.Backends.Stopping);

   function Stop_Is_Idempotent
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Stop_Is_Idempotent'Result = (State = A11y.Backends.Stopped);

   function Can_Advance_Generation (Generation : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Advance_Generation'Result = (Generation < Natural'Last);

   function Drained
     (Live_Objects    : Natural;
      Tombstones      : Natural;
      Destroyed_Nodes : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Drained'Result =
          (Live_Objects = 0
           and then Tombstones = 0
           and then Destroyed_Nodes = 0);

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Generation_Changed'Result = (After > Before);

   function State_Changed
     (Before : A11y.Backends.Backend_State;
      After  : A11y.Backends.Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => State_Changed'Result = (After /= Before);

   function Session_Changed
     (Before : A11y.Native_Identity.Backend_Session_Id;
      After  : A11y.Native_Identity.Backend_Session_Id)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Session_Changed'Result = (After /= Before);

   function Cache_Reset
     (Before_Live       : Natural;
      Before_Tombstones : Natural;
      After_Live        : Natural;
      After_Tombstones  : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Cache_Reset'Result =
          ((Before_Live /= 0 or else Before_Tombstones /= 0)
           and then After_Live = 0
           and then After_Tombstones = 0);

   function Event_Order_Reset
     (Before : A11y.Event_Sequence;
      After  : A11y.Event_Sequence)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Event_Order_Reset'Result =
          (Before /= A11y.No_Event and then After = A11y.No_Event);

   function Valid_Node_Slot (Slot : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Valid_Node_Slot'Result =
          (Slot in 1 .. A11y.Node_Ids.Max_Node_Ids);

   function Sequence_Advances
     (Previous : A11y.Event_Sequence;
      Current  : A11y.Event_Sequence)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Sequence_Advances'Result = (Current > Previous);

   function Destroyed_Node_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Destroyed_Node_Status'Result =
          (if Kind = A11y.Events.Node_Destroyed
           then A11y.Results.Invalid_State
           else A11y.Results.Node_Unavailable);

   function Defunct_Mark_Cache_Failure_Blocks
     (Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Defunct_Mark_Cache_Failure_Blocks'Result =
          (Status not in A11y.Results.Success
                       | A11y.Results.Accepted_Asynchronous
                       | A11y.Results.Node_Unavailable);

   function Snapshot (Runtime : Native_Runtime) return Runtime_Snapshot;
   function State
     (Runtime : Native_Runtime)
      return A11y.Backends.Backend_State;
   function Session
     (Runtime : Native_Runtime)
      return A11y.Native_Identity.Backend_Session_Id;
   function Node_Defunct
     (Runtime : Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id)
      return Boolean;
   function Drained (Runtime : Native_Runtime) return Boolean;

   procedure Configure_Limits
     (Runtime : in out Native_Runtime;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Can_Configure_Limits
     (Runtime : in out Native_Runtime;
      Limits  : A11y.Resource_Limits.Resource_Limit_Config;
      Result  : out A11y.Results.Result);

   procedure Initialize
     (Runtime : in out Native_Runtime;
      Result  : out A11y.Results.Result);

   procedure Initialize_With_Report
     (Runtime : in out Native_Runtime;
      Report  : out Runtime_Lifecycle_Report;
      Result  : out A11y.Results.Result);

   procedure Start
     (Runtime : in out Native_Runtime;
      Result  : out A11y.Results.Result);

   procedure Start_With_Report
     (Runtime : in out Native_Runtime;
      Report  : out Runtime_Lifecycle_Report;
      Result  : out A11y.Results.Result);

   procedure Stop
     (Runtime : in out Native_Runtime;
      Result  : out A11y.Results.Result);

   procedure Stop_With_Report
     (Runtime : in out Native_Runtime;
      Report  : out Runtime_Lifecycle_Report;
      Result  : out A11y.Results.Result);

   procedure Ensure_Object
     (Runtime : in out Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Object  : out A11y.Native_Object_Caches.Native_Object_Id;
      Result  : out A11y.Results.Result);

   procedure Resolve_Object
     (Runtime : in out Native_Runtime;
      Object  : A11y.Native_Object_Caches.Native_Object_Id;
      Item    : out A11y.Native_Object_Caches.Object_Snapshot;
      Result  : out A11y.Results.Result);

   function Validate_Prepared_Event
     (Prepared : Prepared_Event)
      return A11y.Results.Result;

   procedure Find_Object
     (Runtime : in out Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Item    : out A11y.Native_Object_Caches.Object_Snapshot;
      Result  : out A11y.Results.Result);

   procedure Mark_Node_Defunct
     (Runtime : in out Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Result  : out A11y.Results.Result);

   procedure Apply_Event
     (Runtime : in out Native_Runtime;
      Event   : A11y.Events.Event;
      Result  : out A11y.Results.Result);

   procedure Prepare_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Event_With_Report
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Prepared : out Prepared_Event;
      Report   : out Event_Preparation_Report;
      Result   : out A11y.Results.Result);

   procedure Prepare_Property_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Property_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_State_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.State_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Bounds_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Bounds_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Value_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Value_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Selection_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Selection_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Relation_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Relation_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Focus_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Focus_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Node_Reference_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Node_Reference_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Live_Region_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Live_Region_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Tree_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Tree_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Table_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Table_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Document_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Document_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

   procedure Prepare_Window_Event
     (Runtime  : in out Native_Runtime;
      Event    : A11y.Events.Event;
      Payload  : A11y.Events.Window_Event_Payload;
      Prepared : out Prepared_Event;
      Result   : out A11y.Results.Result);

private
   type Destroyed_Node_Table is array
     (Positive range 1 .. A11y.Node_Ids.Max_Node_Ids) of Boolean;

   type Native_Runtime is limited record
      Current_State : A11y.Backends.Backend_State := A11y.Backends.Created;
      Generation : Natural := 0;
      Current_Session : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Last_Sequence : A11y.Event_Sequence := A11y.No_Event;
      Last_Timestamp : A11y.Timestamp := Ada.Calendar.Time_Of (1901, 1, 1);
      Destroyed : Destroyed_Node_Table := [others => False];
      Destroyed_Count : Natural := 0;
      Cache : A11y.Native_Object_Caches.Native_Object_Cache;
   end record;

end A11y.Native_Runtimes;
