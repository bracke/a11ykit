with Ada.Strings.Unbounded;

with A11y.Native_Callbacks;
with A11y.Native_Identity;
with A11y.Native_Object_Caches;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Linux.ATSPi_Object_Registry is

   type Object_Registry is limited private;
   type Object_Call_Context is private;

   type Registry_Snapshot is record
      Live_Count         : Natural := 0;
      Tombstones         : Natural := 0;
      Outstanding_Calls  : Natural := 0;
      Generation         : Natural := 0;
      Capacity           : Natural := A11y.Native_Object_Caches.Max_Native_Objects;
      Tombstone_Capacity : Natural := A11y.Native_Object_Caches.Max_Native_Objects;
   end record;

   type Object_Record_Snapshot is record
      Object   : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Session  : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Path     : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Defunct  : Boolean := False;
      Released : Boolean := False;
      Registry_Generation : Natural := 0;
   end record;

   type Object_Call_Snapshot is record
      Active              : Boolean := False;
      Object              : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Session             : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node                : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Registry_Generation : Natural := 0;
   end record;

   type Object_Export_Descriptor is record
      Exportable : Boolean := False;
      Status     : A11y.Results.Status_Code := A11y.Results.Node_Unavailable;
      Object     : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Session    : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Path       : Ada.Strings.Unbounded.Unbounded_String :=
        Ada.Strings.Unbounded.Null_Unbounded_String;
      Defunct    : Boolean := False;
      Released   : Boolean := False;
      Registry_Generation : Natural := 0;
   end record;

   type Registry_Mutation_Kind is
     (Registry_Ensure_Object,
      Registry_Mark_Defunct,
      Registry_Release_Object,
      Registry_Reset);

   type Registry_Mutation_Report is record
      Operation          : Registry_Mutation_Kind := Registry_Ensure_Object;
      Generation_Before : Natural := 0;
      Generation_After  : Natural := 0;
      Live_Before       : Natural := 0;
      Live_After        : Natural := 0;
      Tombstones_Before : Natural := 0;
      Tombstones_After  : Natural := 0;
      Outstanding_Before : Natural := 0;
      Outstanding_After  : Natural := 0;
      Object            : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Session           : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Status            : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Advanced : Boolean := False;
      Live_Changed        : Boolean := False;
      Tombstone_Changed   : Boolean := False;
      Outstanding_Changed : Boolean := False;
      Object_Returned     : Boolean := False;
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
      Object             : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Session            : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node               : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Context            : Object_Call_Snapshot;
      Status             : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Changed : Boolean := False;
      Outstanding_Changed : Boolean := False;
      Call_Active        : Boolean := False;
   end record;

   procedure Configure
     (Registry : in out Object_Registry;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result);

   procedure Ensure_Object
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Object_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Ensure_Object_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Object_Record_Snapshot;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Find_Object
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Object_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Resolve_Path
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Snapshot : out Object_Record_Snapshot;
      Result   : out A11y.Results.Result);

   procedure Export_Descriptor
     (Registry   : in out Object_Registry;
      Session    : A11y.Native_Identity.Backend_Session_Id;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Descriptor : out Object_Export_Descriptor);

   procedure Begin_Native_Call
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : out Object_Call_Context;
      Result   : out A11y.Results.Result);

   procedure Begin_Native_Call_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : out Object_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure End_Native_Call
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : in out Object_Call_Context;
      Result   : out A11y.Results.Result);

   procedure End_Native_Call_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : in out Object_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Mark_Defunct
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result);

   procedure Mark_Defunct_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Release
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Result   : out A11y.Results.Result);

   procedure Release_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Reset_When_Drained
     (Registry : in out Object_Registry;
      Result   : out A11y.Results.Result);
   --  Checked shutdown reset. Returns Busy without mutation while any admitted
   --  native object call is still outstanding.

   procedure Reset (Registry : in out Object_Registry);
   --  Drained-only cleanup hook. While calls are outstanding this is a no-op so
   --  stale native contexts can still unwind through End_Native_Call.

   procedure Reset_When_Drained_With_Report
     (Registry : in out Object_Registry;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result);

   procedure Reset_With_Report
     (Registry : in out Object_Registry;
      Report   : out Registry_Mutation_Report);

   function Drained (Registry : Object_Registry) return Boolean;

   function Snapshot (Registry : Object_Registry) return Registry_Snapshot;

   function Snapshot
     (Context : Object_Call_Context)
      return Object_Call_Snapshot;

private
   type Object_Call_Context is record
      Active              : Boolean := False;
      Token               : A11y.Native_Callbacks.Callback_Token :=
        A11y.Native_Callbacks.No_Token;
      Object              : A11y.Native_Object_Caches.Native_Object_Id :=
        A11y.Native_Object_Caches.No_Object;
      Session             : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node                : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Registry_Generation : Natural := 0;
   end record;

   type Object_Registry is limited record
      Cache : A11y.Native_Object_Caches.Native_Object_Cache;
      Calls : A11y.Native_Callbacks.Callback_Gate;
      Generation : Natural := 0;
   end record;

end A11y.Linux.ATSPi_Object_Registry;
