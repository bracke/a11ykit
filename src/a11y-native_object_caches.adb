with A11y.Native_Object_Caches.Classification;

package body A11y.Native_Object_Caches is
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Node_Ids.Node_Id;

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Is_Valid (Object : Native_Object_Id) return Boolean
   with SPARK_Mode => On
   is
   begin
      return Object /= No_Object;
   end Is_Valid;

   function To_Natural (Object : Native_Object_Id) return Natural
   with SPARK_Mode => On
   is
   begin
      return Natural (Object);
   end To_Natural;

   function Image (Object : Native_Object_Id) return String is
     (if Object = No_Object then "none" else Trimmed_Image (Natural (Object)));

   function Valid_Capacity (Capacity : Natural) return Boolean is
     (A11y.Native_Object_Caches.Classification.Valid_Capacity (Capacity))
   with SPARK_Mode => On;

   function Allocated_Count (Next_Id : Natural) return Natural is
     (A11y.Native_Object_Caches.Classification.Allocated_Count (Next_Id))
   with SPARK_Mode => On;

   function Can_Set_Limits
     (Next_Id            : Natural;
      Tombstone_Count    : Natural;
      Object_Capacity    : Natural;
      Tombstone_Capacity : Natural)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Can_Set_Limits
        (Next_Id,
         Tombstone_Count,
         Object_Capacity,
         Tombstone_Capacity))
   with SPARK_Mode => On;

   function Can_Advance_Generation
     (Generation : Natural)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Can_Advance_Generation
        (Generation))
   with SPARK_Mode => On;

   function Generation_Advanced
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Generation_Advanced
        (Before, After))
   with SPARK_Mode => On;

   function Count_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Count_Changed
        (Before, After))
   with SPARK_Mode => On;

   function Object_Returned
     (Object : Native_Object_Id)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Object_Returned (Object))
   with SPARK_Mode => On;

   function Active_Slot
     (Slot    : Natural;
      Next_Id : Natural)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Active_Slot (Slot, Next_Id))
   with SPARK_Mode => On;

   function Live_Record
     (Used     : Boolean;
      Released : Boolean;
      Defunct  : Boolean)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Live_Record
        (Used, Released, Defunct))
   with SPARK_Mode => On;

   function Releasable_Record
     (Used     : Boolean;
      Released : Boolean)
      return Boolean is
     (A11y.Native_Object_Caches.Classification.Releasable_Record
        (Used, Released))
   with SPARK_Mode => On;

   protected body Native_Object_Cache is

      procedure Advance_Generation is
      begin
         if Can_Advance_Generation (Cache_Generation)
         then
            Cache_Generation := Cache_Generation + 1;
         end if;
      end Advance_Generation;

      procedure Begin_Report
        (Report    : out Cache_Mutation_Report;
         Operation : Cache_Mutation_Kind;
         Node      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
         Object    : Native_Object_Id := No_Object)
      is
      begin
         Report :=
           (Operation           => Operation,
            Generation_Before   => Cache_Generation,
            Generation_After    => Cache_Generation,
            Live_Before         => Live_Count,
            Live_After          => Live_Count,
            Tombstones_Before   => Tombstone_Count,
            Tombstones_After    => Tombstone_Count,
            Object              => Object,
            Node                => Node,
            Status              => A11y.Results.Success,
            Generation_Advanced => False,
            Live_Changed        => False,
            Tombstone_Changed   => False,
            Object_Returned     => False);
      end Begin_Report;

      procedure Complete_Report
        (Report : in out Cache_Mutation_Report;
         Object : Native_Object_Id;
         Result : A11y.Results.Result)
      is
      begin
         Report.Generation_After := Cache_Generation;
         Report.Live_After := Live_Count;
         Report.Tombstones_After := Tombstone_Count;
         Report.Object := Object;
         Report.Status := Result.Status;
         Report.Generation_Advanced :=
           Generation_Advanced
             (Report.Generation_Before, Report.Generation_After);
         Report.Live_Changed :=
           Count_Changed
             (Report.Live_Before, Report.Live_After);
         Report.Tombstone_Changed :=
           Count_Changed
             (Report.Tombstones_Before, Report.Tombstones_After);
         Report.Object_Returned :=
           Object_Returned (Object);
      end Complete_Report;

      procedure Validate_Limits
        (Object_Capacity    : Natural;
         Tombstone_Capacity : Natural;
         Result             : out A11y.Results.Result)
      is
      begin
         if not Valid_Capacity
           (Object_Capacity)
           or else not Valid_Capacity
             (Tombstone_Capacity)
         then
            Result := (Status => A11y.Results.Invalid_Argument);
         elsif not Can_Set_Limits
           (Next_Id,
            Tombstone_Count,
            Object_Capacity,
            Tombstone_Capacity)
         then
            Result := (Status => A11y.Results.Invalid_State);
         else
            Result := A11y.Results.Ok;
         end if;
      end Validate_Limits;

      procedure Can_Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result)
      is
         Validation : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Validation) then
            Result := Validation;
            return;
         end if;

         Validate_Limits
           (Object_Capacity =>
              Natural
                (A11y.Resource_Limits.Value
                   (Limits, A11y.Resource_Limits.Native_Object_Cache_Size)),
            Tombstone_Capacity =>
              Natural
                (A11y.Resource_Limits.Value
                   (Limits, A11y.Resource_Limits.Tombstone_Retention)),
            Result => Result);
      end Can_Configure;

      procedure Evict_Tombstones_For (Needed : Natural) is
         Current : Natural := Tombstone_Count;
         Node_Slot : Natural;
      begin
         if Needed = 0 then
            return;
         end if;

         for Index in 1 .. Next_Id - 1 loop
            exit when Current + Needed <= Tombstone_Limit;
            if Records (Index).Used
              and then (Records (Index).Released or else Records (Index).Defunct)
            then
               Node_Slot := A11y.Node_Ids.To_Natural (Records (Index).Node);
               if Node_Slot in Node_Index'Range
                 and then Node_Index (Node_Slot) = Native_Object_Id (Index)
               then
                  Node_Index (Node_Slot) := No_Object;
               end if;

               Records (Index) :=
                 (Used     => False,
                  Session  => A11y.Native_Identity.No_Session,
                  Node     => A11y.Node_Ids.No_Node,
                  Defunct  => False,
                  Released => False);
               Current := Current - 1;
               Advance_Generation;
            end if;
         end loop;
      end Evict_Tombstones_For;

      procedure Configure
        (Limits : A11y.Resource_Limits.Resource_Limit_Config;
         Result : out A11y.Results.Result)
      is
         Validation : constant A11y.Results.Result :=
           A11y.Resource_Limits.Validate (Limits);
      begin
         if A11y.Results.Failed (Validation) then
            Result := Validation;
            return;
         end if;

         Set_Limits
           (Object_Capacity =>
              Natural
                (A11y.Resource_Limits.Value
                   (Limits, A11y.Resource_Limits.Native_Object_Cache_Size)),
            Tombstone_Capacity =>
              Natural
                (A11y.Resource_Limits.Value
                   (Limits, A11y.Resource_Limits.Tombstone_Retention)),
            Result => Result);
      end Configure;

      procedure Set_Limits
        (Object_Capacity    : Natural;
         Tombstone_Capacity : Natural;
         Result             : out A11y.Results.Result)
      is
      begin
         Validate_Limits (Object_Capacity, Tombstone_Capacity, Result);
         if A11y.Results.Succeeded (Result) then
            Object_Limit := Object_Capacity;
            Tombstone_Limit := Tombstone_Capacity;
            Advance_Generation;
         end if;
      end Set_Limits;

      procedure Ensure_Object
        (Session : A11y.Native_Identity.Backend_Session_Id;
         Node    : A11y.Node_Ids.Node_Id;
         Object  : out Native_Object_Id;
         Result  : out A11y.Results.Result)
      is
         Report : Cache_Mutation_Report;
      begin
         Ensure_Object_With_Report (Session, Node, Object, Report, Result);
      end Ensure_Object;

      procedure Ensure_Object_With_Report
        (Session : A11y.Native_Identity.Backend_Session_Id;
         Node    : A11y.Node_Ids.Node_Id;
         Object  : out Native_Object_Id;
         Report  : out Cache_Mutation_Report;
         Result  : out A11y.Results.Result)
      is
         Node_Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
         Existing  : Native_Object_Id := No_Object;
         Object_Slot : Natural;
      begin
         Begin_Report (Report, Cache_Ensure_Object, Node);
         Object := No_Object;
         if not A11y.Native_Identity.Is_Valid (Session)
           or else not A11y.Node_Ids.Is_Valid (Node)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            Complete_Report (Report, Object, Result);
            return;
         elsif Defunct_Nodes (Node_Slot) then
            Result := (Status => A11y.Results.Node_Unavailable);
            Complete_Report (Report, Object, Result);
            return;
         end if;

         Existing := Node_Index (Node_Slot);
         if Existing /= No_Object then
            Object_Slot := Natural (Existing);
            if not Active_Slot
                (Object_Slot, Next_Id)
              or else not Live_Record
                (Records (Object_Slot).Used,
                 Records (Object_Slot).Released,
                 Records (Object_Slot).Defunct)
              or else Records (Object_Slot).Session /= Session
              or else Records (Object_Slot).Node /= Node
            then
               Result := (Status => A11y.Results.Node_Unavailable);
            else
               Object := Existing;
               Result := A11y.Results.Ok;
            end if;
            Complete_Report (Report, Object, Result);
            return;
         end if;

         if Next_Id > Object_Limit then
            Result := (Status => A11y.Results.Resource_Limit);
            Complete_Report (Report, Object, Result);
            return;
         end if;

         Records (Next_Id) :=
           (Used     => True,
            Session  => Session,
            Node     => Node,
            Defunct  => False,
            Released => False);
         Object := Native_Object_Id (Next_Id);
         Node_Index (Node_Slot) := Object;
         Next_Id := Next_Id + 1;
         Advance_Generation;
         Result := A11y.Results.Ok;
         Complete_Report (Report, Object, Result);
      end Ensure_Object_With_Report;

      procedure Find_Object
        (Session  : A11y.Native_Identity.Backend_Session_Id;
         Node     : A11y.Node_Ids.Node_Id;
         Snapshot : out Object_Snapshot;
         Result   : out A11y.Results.Result)
      is
         Node_Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
         Object : Native_Object_Id := No_Object;
         Object_Slot : Natural;
      begin
         Snapshot := (others => <>);
         if not A11y.Native_Identity.Is_Valid (Session)
           or else not A11y.Node_Ids.Is_Valid (Node)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Object := Node_Index (Node_Slot);
         if Object = No_Object then
            Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Object_Slot := Natural (Object);
         if not Active_Slot
             (Object_Slot, Next_Id)
           or else not Records (Object_Slot).Used
           or else Records (Object_Slot).Session /= Session
           or else Records (Object_Slot).Node /= Node
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Snapshot :=
           (Object   => Object,
            Cache_Generation => Cache_Generation,
            Session  => Records (Object_Slot).Session,
            Node     => Records (Object_Slot).Node,
            Defunct  => Records (Object_Slot).Defunct,
            Released => Records (Object_Slot).Released);

         if not Live_Record
             (Records (Object_Slot).Used,
              Records (Object_Slot).Released,
              Records (Object_Slot).Defunct)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         else
            Result := A11y.Results.Ok;
         end if;
      end Find_Object;

      procedure Resolve
        (Session  : A11y.Native_Identity.Backend_Session_Id;
         Object   : Native_Object_Id;
         Snapshot : out Object_Snapshot;
         Result   : out A11y.Results.Result)
      is
         Slot : constant Natural := Natural (Object);
      begin
         Snapshot := (others => <>);
         if not Active_Slot
             (Slot, Next_Id)
           or else not Records (Slot).Used
           or else Records (Slot).Session /= Session
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            return;
         end if;

         Snapshot :=
           (Object   => Object,
            Cache_Generation => Cache_Generation,
            Session  => Records (Slot).Session,
            Node     => Records (Slot).Node,
            Defunct  => Records (Slot).Defunct,
            Released => Records (Slot).Released);

         if not Live_Record
             (Records (Slot).Used,
              Records (Slot).Released,
              Records (Slot).Defunct)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
         else
            Result := A11y.Results.Ok;
         end if;
      end Resolve;

      procedure Mark_Defunct
        (Node   : A11y.Node_Ids.Node_Id;
         Result : out A11y.Results.Result)
      is
         Report : Cache_Mutation_Report;
      begin
         Mark_Defunct_With_Report (Node, Report, Result);
      end Mark_Defunct;

      procedure Mark_Defunct_With_Report
        (Node   : A11y.Node_Ids.Node_Id;
         Report : out Cache_Mutation_Report;
         Result : out A11y.Results.Result)
      is
         Node_Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
         Object : Native_Object_Id := No_Object;
         Object_Slot : Natural;
      begin
         Begin_Report (Report, Cache_Mark_Defunct, Node);
         if not A11y.Node_Ids.Is_Valid (Node) then
            Result := (Status => A11y.Results.Node_Unavailable);
            Complete_Report (Report, Object, Result);
            return;
         end if;

         Object := Node_Index (Node_Slot);
         if Object = No_Object then
            Result := (Status => A11y.Results.Node_Unavailable);
            Complete_Report (Report, Object, Result);
            return;
         end if;

         Object_Slot := Natural (Object);
         if not Active_Slot
             (Object_Slot, Next_Id)
           or else not Live_Record
             (Records (Object_Slot).Used,
              Records (Object_Slot).Released,
              Records (Object_Slot).Defunct)
           or else Records (Object_Slot).Node /= Node
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            Complete_Report (Report, Object, Result);
            return;
         end if;

         Evict_Tombstones_For (1);
         Records (Object_Slot).Defunct := True;
         Defunct_Nodes (Node_Slot) := True;
         Advance_Generation;
         Result := A11y.Results.Ok;
         Complete_Report (Report, Object, Result);
      end Mark_Defunct_With_Report;

      procedure Release
        (Object : Native_Object_Id;
         Result : out A11y.Results.Result)
      is
         Report : Cache_Mutation_Report;
      begin
         Release_With_Report (Object, Report, Result);
      end Release;

      procedure Release_With_Report
        (Object : Native_Object_Id;
         Report : out Cache_Mutation_Report;
         Result : out A11y.Results.Result)
      is
         Slot : constant Natural := Natural (Object);
         Node : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      begin
         if Slot /= 0 and then Slot < Next_Id and then Records (Slot).Used then
            Node := Records (Slot).Node;
         end if;
         Begin_Report (Report, Cache_Release_Object, Node, Object);

         if not Active_Slot
             (Slot, Next_Id)
           or else not Releasable_Record
             (Records (Slot).Used, Records (Slot).Released)
         then
            Result := (Status => A11y.Results.Node_Unavailable);
            Complete_Report (Report, Object, Result);
         else
            if not Records (Slot).Defunct then
               Evict_Tombstones_For (1);
            end if;
            if A11y.Node_Ids.To_Natural (Records (Slot).Node) in
              Defunct_Nodes'Range
            then
               Defunct_Nodes (A11y.Node_Ids.To_Natural (Records (Slot).Node)) :=
                 True;
            end if;
            Records (Slot).Released := True;
            Records (Slot).Defunct := True;
            Advance_Generation;
            Result := A11y.Results.Ok;
            Complete_Report (Report, Object, Result);
         end if;
      end Release_With_Report;

      procedure Reset is
         Report : Cache_Mutation_Report;
      begin
         Reset_With_Report (Report);
      end Reset;

      procedure Reset_With_Report (Report : out Cache_Mutation_Report) is
      begin
         Begin_Report (Report, Cache_Reset);
         Next_Id := 1;
         for Index in Node_Index'Range loop
            Node_Index (Index) := No_Object;
         end loop;
         for Index in Defunct_Nodes'Range loop
            Defunct_Nodes (Index) := False;
         end loop;
         for Index in Records'Range loop
            Records (Index) :=
              (Used     => False,
               Session  => A11y.Native_Identity.No_Session,
               Node     => A11y.Node_Ids.No_Node,
               Defunct  => False,
               Released => False);
         end loop;
         Advance_Generation;
         Complete_Report (Report, No_Object, A11y.Results.Ok);
      end Reset_With_Report;

      function Live_Count return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Next_Id - 1 loop
            if Records (Index).Used
              and then not Records (Index).Released
              and then not Records (Index).Defunct
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Live_Count;

      function Tombstone_Count return Natural is
         Count : Natural := 0;
      begin
         for Index in 1 .. Next_Id - 1 loop
            if Records (Index).Used
              and then (Records (Index).Released or else Records (Index).Defunct)
            then
               Count := Count + 1;
            end if;
         end loop;
         return Count;
      end Tombstone_Count;

      function Object_Capacity return Natural is
        (Object_Limit);

      function Tombstone_Capacity return Natural is
        (Tombstone_Limit);

      function Generation return Natural is
        (Cache_Generation);

   end Native_Object_Cache;

end A11y.Native_Object_Caches;
