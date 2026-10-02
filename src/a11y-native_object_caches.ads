with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Native_Object_Caches is

   Max_Native_Objects : constant Natural := 65_536;

   type Native_Object_Id is private;

   No_Object : constant Native_Object_Id;

   function Is_Valid (Object : Native_Object_Id) return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Valid'Result = (Object /= No_Object);
   function To_Natural (Object : Native_Object_Id) return Natural
   with
     SPARK_Mode => On,
     Global => null,
     Post => (if not Is_Valid (Object) then To_Natural'Result = 0);
   function Image (Object : Native_Object_Id) return String;

   function Valid_Capacity (Capacity : Natural) return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Valid_Capacity'Result =
          (Capacity in 1 .. Max_Native_Objects);

   function Allocated_Count (Next_Id : Natural) return Natural
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Allocated_Count'Result =
          (if Next_Id = 0 then 0 else Next_Id - 1);

   function Can_Set_Limits
     (Next_Id            : Natural;
      Tombstone_Count    : Natural;
      Object_Capacity    : Natural;
      Tombstone_Capacity : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Set_Limits'Result =
          (Valid_Capacity (Object_Capacity)
           and then Valid_Capacity (Tombstone_Capacity)
           and then Object_Capacity >= Allocated_Count (Next_Id)
           and then Tombstone_Capacity >= Tombstone_Count);

   function Can_Advance_Generation
     (Generation : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Advance_Generation'Result =
        (Generation < Natural'Last);

   function Generation_Advanced
     (Before : Natural;
      After  : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Generation_Advanced'Result = (After > Before);

   function Count_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Count_Changed'Result = (After /= Before);

   function Object_Returned
     (Object : Native_Object_Id)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Object_Returned'Result = (Object /= No_Object);

   function Active_Slot
     (Slot    : Natural;
      Next_Id : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Active_Slot'Result =
        (Slot /= 0 and then Slot < Next_Id);

   function Live_Record
     (Used     : Boolean;
      Released : Boolean;
      Defunct  : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Live_Record'Result =
        (Used and then not Released and then not Defunct);

   function Releasable_Record
     (Used     : Boolean;
      Released : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Releasable_Record'Result =
        (Used and then not Released);

   type Object_Snapshot is record
      Object   : Native_Object_Id := No_Object;
      Cache_Generation : Natural := 0;
      Session  : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Defunct  : Boolean := False;
      Released : Boolean := False;
   end record;

   type Cache_Mutation_Kind is
     (Cache_Ensure_Object,
      Cache_Mark_Defunct,
      Cache_Release_Object,
      Cache_Reset);

   type Cache_Mutation_Report is record
      Operation : Cache_Mutation_Kind := Cache_Ensure_Object;
      Generation_Before : Natural := 0;
      Generation_After  : Natural := 0;
      Live_Before       : Natural := 0;
      Live_After        : Natural := 0;
      Tombstones_Before : Natural := 0;
      Tombstones_After  : Natural := 0;
      Object            : Native_Object_Id := No_Object;
      Node              : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Status            : A11y.Results.Status_Code := A11y.Results.Success;
      Generation_Advanced : Boolean := False;
      Live_Changed        : Boolean := False;
      Tombstone_Changed   : Boolean := False;
      Object_Returned     : Boolean := False;
   end record;

   type Cache_Record is record
      Used     : Boolean := False;
      Session  : A11y.Native_Identity.Backend_Session_Id :=
        A11y.Native_Identity.No_Session;
      Node     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Defunct  : Boolean := False;
      Released : Boolean := False;
   end record;

   type Cache_Table is array
     (Positive range 1 .. Max_Native_Objects) of Cache_Record;

   type Node_Object_Index is array
     (Positive range 1 .. A11y.Node_Ids.Max_Node_Ids) of Native_Object_Id;
   type Node_Defunct_Index is array
     (Positive range 1 .. A11y.Node_Ids.Max_Node_Ids) of Boolean;

   protected type Native_Object_Cache is
      procedure Can_Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result);

      procedure Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result);

      procedure Set_Limits
        (Object_Capacity    : Natural;
         Tombstone_Capacity : Natural;
         Result             : out A11y.Results.Result);

      procedure Ensure_Object
        (Session : A11y.Native_Identity.Backend_Session_Id;
         Node    : A11y.Node_Ids.Node_Id;
         Object  : out Native_Object_Id;
         Result  : out A11y.Results.Result);

      procedure Ensure_Object_With_Report
        (Session : A11y.Native_Identity.Backend_Session_Id;
         Node    : A11y.Node_Ids.Node_Id;
         Object  : out Native_Object_Id;
         Report  : out Cache_Mutation_Report;
         Result  : out A11y.Results.Result);

      procedure Find_Object
        (Session  : A11y.Native_Identity.Backend_Session_Id;
         Node     : A11y.Node_Ids.Node_Id;
         Snapshot : out Object_Snapshot;
         Result   : out A11y.Results.Result);

      procedure Resolve
        (Session  : A11y.Native_Identity.Backend_Session_Id;
         Object   : Native_Object_Id;
         Snapshot : out Object_Snapshot;
         Result   : out A11y.Results.Result);

      procedure Mark_Defunct
        (Node   : A11y.Node_Ids.Node_Id;
         Result : out A11y.Results.Result);

      procedure Mark_Defunct_With_Report
        (Node   : A11y.Node_Ids.Node_Id;
         Report : out Cache_Mutation_Report;
         Result : out A11y.Results.Result);

      procedure Release
        (Object : Native_Object_Id;
         Result : out A11y.Results.Result);

      procedure Release_With_Report
        (Object : Native_Object_Id;
         Report : out Cache_Mutation_Report;
         Result : out A11y.Results.Result);

      procedure Reset;

      procedure Reset_With_Report (Report : out Cache_Mutation_Report);

      function Live_Count return Natural;
      function Tombstone_Count return Natural;
      function Object_Capacity return Natural;
      function Tombstone_Capacity return Natural;
      function Generation return Natural;
   private
      procedure Advance_Generation;
      procedure Begin_Report
        (Report    : out Cache_Mutation_Report;
         Operation : Cache_Mutation_Kind;
         Node      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         Object    : Native_Object_Id := No_Object);
      procedure Complete_Report
        (Report : in out Cache_Mutation_Report;
         Object : Native_Object_Id;
         Result : A11y.Results.Result);
      Next_Id : Natural := 1;
      Cache_Generation : Natural := 0;
      Object_Limit : Natural := Max_Native_Objects;
      Tombstone_Limit : Natural := Max_Native_Objects;
      Records : Cache_Table;
      Node_Index : Node_Object_Index := [others => No_Object];
      Defunct_Nodes : Node_Defunct_Index := [others => False];
   end Native_Object_Cache;

private
   type Native_Object_Id is new Natural;
   No_Object : constant Native_Object_Id := 0;

end A11y.Native_Object_Caches;
