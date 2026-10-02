with A11y.MacOS_Backend.NSAccessibility_Elements;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.MacOS_Backend.NSAccessibility_Element_Registry is

   Max_NSAccessibility_Elements : constant Natural := 65_536;

   type Element_Id is private;
   No_Element : constant Element_Id;

   function Is_Valid (Id : Element_Id) return Boolean;
   function To_Natural (Id : Element_Id) return Natural;
   function From_Natural (Value : Natural) return Element_Id;
   function Image (Id : Element_Id) return String;

   type Element_Registry is limited private;

   type Registry_Snapshot is record
      Live_Count : Natural := 0;
      Tombstones : Natural := 0;
      Outstanding_Calls : Natural := 0;
      Generation : Natural := 0;
      Capacity   : Natural := Max_NSAccessibility_Elements;
      Next_Id    : Natural := 1;
   end record;

   type Element_Record_Snapshot is record
      Id       : Element_Id := No_Element;
      Used     : Boolean := False;
      Released : Boolean := False;
      Element  : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Snapshot;
      Registry_Generation : Natural := 0;
   end record;

   type Registry_Mutation_Kind is
     (Registry_Ensure_Element,
      Registry_Mark_Defunct,
      Registry_Release_Element,
      Registry_Reset);

   type Registry_Mutation_Report is record
      Operation          : Registry_Mutation_Kind := Registry_Ensure_Element;
      Generation_Before : Natural := 0;
      Generation_After  : Natural := 0;
      Live_Before       : Natural := 0;
      Live_After        : Natural := 0;
      Tombstones_Before : Natural := 0;
      Tombstones_After  : Natural := 0;
      Outstanding_Before : Natural := 0;
      Outstanding_After  : Natural := 0;
      Id                : Element_Id := No_Element;
      Session           : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Status            : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Advanced : Boolean := False;
      Live_Changed        : Boolean := False;
      Tombstone_Changed   : Boolean := False;
      Outstanding_Changed : Boolean := False;
      Element_Returned    : Boolean := False;
   end record;

   type Native_Call_Mutation_Kind is
     (Registry_Begin_Native_Call,
      Registry_End_Native_Call);

   type Native_Call_Mutation_Report is record
      Operation          : Native_Call_Mutation_Kind :=
        Registry_Begin_Native_Call;
      Generation_Before  : Natural := 0;
      Generation_After   : Natural := 0;
      Outstanding_Before : Natural := 0;
      Outstanding_After  : Natural := 0;
      Id                 : Element_Id := No_Element;
      Session            : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node               : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Require_Main_Thread : Boolean := False;
      Context            :
        A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Snapshot;
      Status             : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Generation_Changed : Boolean := False;
      Outstanding_Changed : Boolean := False;
      Call_Active        : Boolean := False;
   end record;

   procedure Configure
     (Registry : in out Element_Registry;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result);

   procedure Ensure_Element
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Id       : out Element_Id;
      Result   : out A11y.Results.Result);

   procedure Ensure_Element_With_Report
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Id       : out Element_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Find_Element
     (Registry : Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Element_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Resolve_Element
     (Registry : Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Element_Id;
      Snapshot : out Element_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Begin_Native_Call
     (Registry            : in out Element_Registry;
      Session             : A11y.Native_Identity.Backend_Session_Id;
      Id                  : Element_Id;
      Context             :
        out A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Result              : out A11y.Results.Result;
      Require_Main_Thread : Boolean := False);

   procedure Begin_Native_Call_With_Report
     (Registry            : in out Element_Registry;
      Session             : A11y.Native_Identity.Backend_Session_Id;
      Id                  : Element_Id;
      Context             :
        out A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Report              : out Native_Call_Mutation_Report;
      Result              : out A11y.Results.Result;
      Require_Main_Thread : Boolean := False);

   procedure End_Native_Call
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Element_Id;
      Context  :
        in out A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Result   : out A11y.Results.Result);

   procedure End_Native_Call_With_Report
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Element_Id;
      Context  :
        in out A11y.MacOS_Backend.NSAccessibility_Elements.Element_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Bind_Main_Thread
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Element_Id;
      Result   : out A11y.Results.Result);

   procedure Bind_Native_View
     (Registry              : in out Element_Registry;
      Session               : A11y.Native_Identity.Backend_Session_Id;
      Id                    : Element_Id;
      Native_View_Component : Natural;
      Result                : out A11y.Results.Result);

   procedure Mark_Defunct
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result);

   procedure Mark_Defunct_With_Report
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Release
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Element_Id;
      Result   : out A11y.Results.Result);

   procedure Release_With_Report
     (Registry : in out Element_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Element_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Reset_When_Drained
     (Registry : in out Element_Registry;
      Result   : out A11y.Results.Result);
   --  Checked shutdown reset. Returns Busy without mutation while any admitted
   --  element call is still outstanding.

   procedure Reset (Registry : in out Element_Registry);
   --  Drained-only cleanup hook. While calls are outstanding this is a no-op so
   --  stale native contexts can still unwind through End_Native_Call.

   procedure Reset_When_Drained_With_Report
     (Registry : in out Element_Registry;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Reset_With_Report
     (Registry : in out Element_Registry;
      Report   : out Registry_Mutation_Report);

   function Drained (Registry : Element_Registry) return Boolean;

   function Snapshot (Registry : Element_Registry) return Registry_Snapshot;

private
   type Element_Id is new Natural;
   No_Element : constant Element_Id := 0;

   type Registry_Record is record
      Used     : Boolean := False;
      Released : Boolean := False;
      Element  : A11y.MacOS_Backend.NSAccessibility_Elements.Element_Object;
   end record;

   type Registry_Table is array
     (Positive range 1 .. Max_NSAccessibility_Elements) of Registry_Record;
   type Node_Index_Table is array
     (Positive range 1 .. A11y.Node_Ids.Max_Node_Ids) of Element_Id;

   type Element_Registry is limited record
      Next       : Natural := 1;
      Limit      : Natural := Max_NSAccessibility_Elements;
      Generation : Natural := 0;
      Records    : Registry_Table;
      Node_Index : Node_Index_Table := [others => No_Element];
   end record;

end A11y.MacOS_Backend.NSAccessibility_Element_Registry;
