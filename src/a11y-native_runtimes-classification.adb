package body A11y.Native_Runtimes.Classification is
   pragma SPARK_Mode (On);

   function Can_Initialize
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State in A11y.Backends.Created | A11y.Backends.Stopped);

   function Needs_Initialize_Before_Start
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State in A11y.Backends.Created | A11y.Backends.Stopped);

   function Can_Enter_Running
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State = A11y.Backends.Initialized);

   function Accepts_Object_Work
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State = A11y.Backends.Running);

   function Accepts_Event_Work
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State = A11y.Backends.Running);

   function Accepts_Defunct_Mark
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State in A11y.Backends.Running | A11y.Backends.Stopping);

   function Stop_Is_Idempotent
     (State : A11y.Backends.Backend_State)
      return Boolean is
     (State = A11y.Backends.Stopped);

   function Can_Advance_Generation (Generation : Natural) return Boolean is
     (Generation < Natural'Last);

   function Drained
     (Live_Objects    : Natural;
      Tombstones      : Natural;
      Destroyed_Nodes : Natural)
      return Boolean is
     (Live_Objects = 0 and then Tombstones = 0 and then Destroyed_Nodes = 0);

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (After > Before);

   function State_Changed
     (Before : A11y.Backends.Backend_State;
      After  : A11y.Backends.Backend_State)
      return Boolean is
     (After /= Before);

   function Session_Changed
     (Before : A11y.Native_Identity.Backend_Session_Id;
      After  : A11y.Native_Identity.Backend_Session_Id)
      return Boolean is
     (After /= Before);

   function Cache_Reset
     (Before_Live       : Natural;
      Before_Tombstones : Natural;
      After_Live        : Natural;
      After_Tombstones  : Natural)
      return Boolean is
     ((Before_Live /= 0 or else Before_Tombstones /= 0)
      and then After_Live = 0
      and then After_Tombstones = 0);

   function Event_Order_Reset
     (Before : A11y.Event_Sequence;
      After  : A11y.Event_Sequence)
      return Boolean is
     (Before /= A11y.No_Event and then After = A11y.No_Event);

   function Valid_Node_Slot (Slot : Natural) return Boolean is
     (Slot in 1 .. A11y.Node_Ids.Max_Node_Ids);

   function Sequence_Advances
     (Previous : A11y.Event_Sequence;
      Current  : A11y.Event_Sequence)
      return Boolean is
     (Current > Previous);

   function Destroyed_Node_Status
     (Kind : A11y.Events.Event_Kind)
      return A11y.Results.Status_Code is
     (if Kind = A11y.Events.Node_Destroyed
      then A11y.Results.Invalid_State
      else A11y.Results.Node_Unavailable);

   function Defunct_Mark_Cache_Failure_Blocks
     (Status : A11y.Results.Status_Code)
      return Boolean is
     (Status not in A11y.Results.Success
                  | A11y.Results.Accepted_Asynchronous
                  | A11y.Results.Node_Unavailable);

end A11y.Native_Runtimes.Classification;
