with A11y.Backends;
with A11y.Events;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Results;

package A11y.Native_Runtimes.Classification is
   pragma SPARK_Mode (On);

   function Can_Initialize
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post =>
        Can_Initialize'Result =
          (State in A11y.Backends.Created | A11y.Backends.Stopped);

   function Needs_Initialize_Before_Start
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post =>
        Needs_Initialize_Before_Start'Result =
          (State in A11y.Backends.Created | A11y.Backends.Stopped);

   function Can_Enter_Running
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post => Can_Enter_Running'Result = (State = A11y.Backends.Initialized);

   function Accepts_Object_Work
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post => Accepts_Object_Work'Result = (State = A11y.Backends.Running);

   function Accepts_Event_Work
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post => Accepts_Event_Work'Result = (State = A11y.Backends.Running);

   function Accepts_Defunct_Mark
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post =>
        Accepts_Defunct_Mark'Result =
          (State in A11y.Backends.Running | A11y.Backends.Stopping);

   function Stop_Is_Idempotent
     (State : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post => Stop_Is_Idempotent'Result = (State = A11y.Backends.Stopped);

   function Can_Advance_Generation (Generation : Natural) return Boolean
   with
      Global => null,
      Post => Can_Advance_Generation'Result = (Generation < Natural'Last);

   function Drained
     (Live_Objects    : Natural;
      Tombstones      : Natural;
      Destroyed_Nodes : Natural)
      return Boolean
   with
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
      Global => null,
      Post => Generation_Changed'Result = (After > Before);

   function State_Changed
     (Before : A11y.Backends.Backend_State;
      After  : A11y.Backends.Backend_State)
      return Boolean
   with
      Global => null,
      Post => State_Changed'Result = (After /= Before);

   function Session_Changed
     (Before : A11y.Native_Identity.Backend_Session_Id;
      After  : A11y.Native_Identity.Backend_Session_Id)
      return Boolean
   with
      Global => null,
      Post => Session_Changed'Result = (After /= Before);

   function Cache_Reset
     (Before_Live       : Natural;
      Before_Tombstones : Natural;
      After_Live        : Natural;
      After_Tombstones  : Natural)
      return Boolean
   with
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
      Global => null,
      Post =>
        Event_Order_Reset'Result =
          (Before /= A11y.No_Event and then After = A11y.No_Event);

   function Valid_Node_Slot (Slot : Natural) return Boolean
   with
      Global => null,
      Post =>
        Valid_Node_Slot'Result =
          (Slot in 1 .. A11y.Node_Ids.Max_Node_Ids);

   function Sequence_Advances
     (Previous : A11y.Event_Sequence;
      Current  : A11y.Event_Sequence)
      return Boolean
   with
      Global => null,
      Post => Sequence_Advances'Result = (Current > Previous);

   function Destroyed_Node_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code
   with
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
      Global => null,
      Post =>
        Defunct_Mark_Cache_Failure_Blocks'Result =
          (Status not in A11y.Results.Success
                       | A11y.Results.Accepted_Asynchronous
                       | A11y.Results.Node_Unavailable);

end A11y.Native_Runtimes.Classification;
