with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Windows_Backend.UIA_Com_Providers;

package A11y.Windows_Backend.UIA_Provider_Registry is

   Max_UIA_Providers : constant Natural := 65_536;

   type Provider_Id is private;
   No_Provider : constant Provider_Id;

   function Is_Valid (Id : Provider_Id) return Boolean;
   function To_Natural (Id : Provider_Id) return Natural;
   function From_Natural (Value : Natural) return Provider_Id;
   function Image (Id : Provider_Id) return String;

   type Provider_Registry is limited private;

   type Registry_Snapshot is record
      Live_Count : Natural := 0;
      Tombstones : Natural := 0;
      Outstanding_Calls : Natural := 0;
      Generation : Natural := 0;
      Capacity   : Natural := Max_UIA_Providers;
      Next_Id    : Natural := 1;
   end record;

   type Provider_Record_Snapshot is record
      Id       : Provider_Id := No_Provider;
      Used     : Boolean := False;
      Released : Boolean := False;
      Provider :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
      Registry_Generation : Natural := 0;
   end record;

   type Registry_Mutation_Kind is
     (Registry_Ensure_Provider,
      Registry_Mark_Defunct,
      Registry_Release_Provider,
      Registry_Reset);

   type Registry_Mutation_Report is record
      Operation          : Registry_Mutation_Kind := Registry_Ensure_Provider;
      Generation_Before : Natural := 0;
      Generation_After  : Natural := 0;
      Live_Before       : Natural := 0;
      Live_After        : Natural := 0;
      Tombstones_Before : Natural := 0;
      Tombstones_After  : Natural := 0;
      Outstanding_Before : Natural := 0;
      Outstanding_After  : Natural := 0;
      Id                : Provider_Id := No_Provider;
      Session           : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Status            : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Advanced : Boolean := False;
      Live_Changed        : Boolean := False;
      Tombstone_Changed   : Boolean := False;
      Outstanding_Changed : Boolean := False;
      Provider_Returned   : Boolean := False;
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
      Id                 : Provider_Id := No_Provider;
      Session            : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node               : A11y.Node_Ids.Node_Id :=
        A11y.Node_Ids.No_Node;
      Requested          :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Unsupported_Interface;
      Context            :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot;
      Status             : A11y.Results.Status_Code :=
        A11y.Results.Success;
      Generation_Changed : Boolean := False;
      Outstanding_Changed : Boolean := False;
      Call_Active        : Boolean := False;
   end record;

   procedure Configure
     (Registry : in out Provider_Registry;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result);

   procedure Ensure_Provider
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Id       : out Provider_Id;
      Result   : out A11y.Results.Result);

   procedure Ensure_Provider_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Id       : out Provider_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Find_Provider
     (Registry : Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Provider_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Resolve_Provider
     (Registry : Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Snapshot : out Provider_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Begin_Native_Call
     (Registry  : in out Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Id        : Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Context   :
        out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Result    : out A11y.Results.Result);

   procedure Begin_Native_Call_With_Report
     (Registry  : in out Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Id        : Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Context   :
        out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Report    : out Native_Call_Mutation_Report;
      Result    : out A11y.Results.Result);

   procedure End_Native_Call
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Context  :
        in out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Result   : out A11y.Results.Result);

   procedure End_Native_Call_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Context  :
        in out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Mark_Defunct
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result);

   procedure Mark_Defunct_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Release
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Result   : out A11y.Results.Result);

   procedure Release_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Reset_When_Drained
     (Registry : in out Provider_Registry;
      Result   : out A11y.Results.Result);
   --  Checked shutdown reset. Returns Busy without mutation while any admitted
   --  provider call is still outstanding.

   procedure Reset (Registry : in out Provider_Registry);
   --  Drained-only cleanup hook. While calls are outstanding this is a no-op so
   --  stale native contexts can still unwind through End_Native_Call.

   procedure Reset_When_Drained_With_Report
     (Registry : in out Provider_Registry;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Reset_With_Report
     (Registry : in out Provider_Registry;
      Report   : out Registry_Mutation_Report);

   function Drained (Registry : Provider_Registry) return Boolean;

   function Snapshot (Registry : Provider_Registry) return Registry_Snapshot;

private
   type Provider_Id is new Natural;
   No_Provider : constant Provider_Id := 0;

   type Registry_Record is record
      Used     : Boolean := False;
      Released : Boolean := False;
      Provider : A11y.Windows_Backend.UIA_Com_Providers.Provider_Object;
   end record;

   type Registry_Table is array
     (Positive range 1 .. Max_UIA_Providers) of Registry_Record;
   type Node_Index_Table is array
     (Positive range 1 .. A11y.Node_Ids.Max_Node_Ids) of Provider_Id;

   type Provider_Registry is limited record
      Next : Natural := 1;
      Limit : Natural := Max_UIA_Providers;
      Generation : Natural := 0;
      Records : Registry_Table;
      Node_Index : Node_Index_Table := [others => No_Provider];
   end record;

end A11y.Windows_Backend.UIA_Provider_Registry;
