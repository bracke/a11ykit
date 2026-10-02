package body A11y.Windows_Backend.UIA_Provider_Registry is
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Node_Ids.Node_Id;

   function Trimmed_Image (Value : Natural) return String is
      Raw : constant String := Natural'Image (Value);
   begin
      return Raw (Raw'First + 1 .. Raw'Last);
   end Trimmed_Image;

   function Is_Valid (Id : Provider_Id) return Boolean is
     (Id /= No_Provider);

   function To_Natural (Id : Provider_Id) return Natural is
     (Natural (Id));

   function From_Natural (Value : Natural) return Provider_Id is
     (Provider_Id (Value));

   function Image (Id : Provider_Id) return String is
     (if Id = No_Provider then "none" else Trimmed_Image (Natural (Id)));

   procedure Advance_Generation (Registry : in out Provider_Registry) is
   begin
      if Registry.Generation < Natural'Last then
         Registry.Generation := Registry.Generation + 1;
      end if;
   end Advance_Generation;

   procedure Begin_Report
     (Registry  : Provider_Registry;
      Operation : Registry_Mutation_Kind;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Node      : A11y.Node_Ids.Node_Id;
      Id        : Provider_Id;
      Report    : out Registry_Mutation_Report)
   is
      View : constant Registry_Snapshot := Snapshot (Registry);
   begin
      Report :=
        (Operation           => Operation,
         Generation_Before  => View.Generation,
         Generation_After   => View.Generation,
         Live_Before        => View.Live_Count,
         Live_After         => View.Live_Count,
         Tombstones_Before  => View.Tombstones,
         Tombstones_After   => View.Tombstones,
         Outstanding_Before => View.Outstanding_Calls,
         Outstanding_After  => View.Outstanding_Calls,
         Id                 => Id,
         Session            => Session,
         Node               => Node,
         Status             => A11y.Results.Success,
         Generation_Advanced => False,
         Live_Changed        => False,
         Tombstone_Changed   => False,
         Outstanding_Changed => False,
         Provider_Returned   => False);
   end Begin_Report;

   procedure Complete_Report
     (Registry : Provider_Registry;
      Id       : Provider_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Report   : in out Registry_Mutation_Report;
      Result   : A11y.Results.Result)
   is
      View : constant Registry_Snapshot := Snapshot (Registry);
   begin
      Report.Generation_After := View.Generation;
      Report.Live_After := View.Live_Count;
      Report.Tombstones_After := View.Tombstones;
      Report.Outstanding_After := View.Outstanding_Calls;
      Report.Id := Id;
      if A11y.Node_Ids.Is_Valid (Node) then
         Report.Node := Node;
      end if;
      Report.Status := Result.Status;
      Report.Generation_Advanced :=
        Report.Generation_After > Report.Generation_Before;
      Report.Live_Changed := Report.Live_After /= Report.Live_Before;
      Report.Tombstone_Changed :=
        Report.Tombstones_After /= Report.Tombstones_Before;
      Report.Outstanding_Changed :=
        Report.Outstanding_After /= Report.Outstanding_Before;
      Report.Provider_Returned := Is_Valid (Id);
   end Complete_Report;

   procedure Begin_Call_Report
     (Registry  : Provider_Registry;
      Operation : Native_Call_Mutation_Kind;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Id        : Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Report    : out Native_Call_Mutation_Report)
   is
      View : constant Registry_Snapshot := Snapshot (Registry);
   begin
      Report :=
        (Operation           => Operation,
         Generation_Before  => View.Generation,
         Generation_After   => View.Generation,
         Outstanding_Before => View.Outstanding_Calls,
         Outstanding_After  => View.Outstanding_Calls,
         Id                 => Id,
         Session            => Session,
         Node               => A11y.Node_Ids.No_Node,
         Requested          => Requested,
         Context            => <>,
         Status             => A11y.Results.Success,
         Generation_Changed => False,
         Outstanding_Changed => False,
         Call_Active        => False);
   end Begin_Call_Report;

   procedure Complete_Call_Report
     (Registry : Provider_Registry;
      Id       : Provider_Id;
      Context  :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Report   : in out Native_Call_Mutation_Report;
      Result   : A11y.Results.Result)
   is
      View : constant Registry_Snapshot := Snapshot (Registry);
      Call_View : constant
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Snapshot :=
          A11y.Windows_Backend.UIA_Com_Providers.Snapshot (Context);
   begin
      Report.Generation_After := View.Generation;
      Report.Outstanding_After := View.Outstanding_Calls;
      Report.Id := Id;
      Report.Context := Call_View;
      Report.Status := Result.Status;
      if A11y.Node_Ids.Is_Valid (Call_View.Node) then
         Report.Node := Call_View.Node;
      end if;
      Report.Generation_Changed :=
        Report.Generation_After /= Report.Generation_Before;
      Report.Outstanding_Changed :=
        Report.Outstanding_After /= Report.Outstanding_Before;
      Report.Call_Active := Call_View.Active;
   end Complete_Call_Report;

   function Record_Snapshot
     (Registry : Provider_Registry;
      Id       : Provider_Id)
      return Provider_Record_Snapshot
   is
      Slot : constant Natural := Natural (Id);
   begin
      if Slot = 0
        or else Slot >= Registry.Next
        or else not Registry.Records (Slot).Used
      then
         return (others => <>);
      end if;

      return
        (Id       => Id,
         Used     => Registry.Records (Slot).Used,
         Released => Registry.Records (Slot).Released,
         Provider =>
           A11y.Windows_Backend.UIA_Com_Providers.Snapshot
             (Registry.Records (Slot).Provider),
         Registry_Generation => Registry.Generation);
   end Record_Snapshot;

   procedure Configure
     (Registry : in out Provider_Registry;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Requested : Natural;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      end if;

      Requested :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Native_Object_Cache_Size));
      if Requested = 0 or else Requested > Max_UIA_Providers then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif Requested < Registry.Next - 1 then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Registry.Limit := Requested;
         Advance_Generation (Registry);
         Result := A11y.Results.Ok;
      end if;
   end Configure;

   procedure Ensure_Provider
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Id       : out Provider_Id;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Ensure_Provider_With_Report
        (Registry, Session, Root, Node, Id, Report, Result);
   end Ensure_Provider;

   procedure Ensure_Provider_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Root     : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Id       : out Provider_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      Node_Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
      Existing : Provider_Id := No_Provider;
      View : A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
   begin
      Id := No_Provider;
      Begin_Report
        (Registry, Registry_Ensure_Provider, Session, Node, No_Provider,
         Report);
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not A11y.Node_Ids.Is_Valid (Root)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         Complete_Report (Registry, Id, Node, Report, Result);
         return;
      end if;

      Existing := Registry.Node_Index (Node_Slot);
      if Existing /= No_Provider then
         View := Record_Snapshot (Registry, Existing).Provider;
         if View.Session = Session
           and then View.Root = Root
           and then View.Node = Node
           and then not View.Defunct
           and then not Registry.Records (Natural (Existing)).Released
         then
            Id := Existing;
            Result := A11y.Results.Ok;
         else
            Result := (Status => A11y.Results.Node_Unavailable);
         end if;
         Complete_Report (Registry, Id, Node, Report, Result);
         return;
      end if;

      if Registry.Next > Registry.Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         Complete_Report (Registry, Id, Node, Report, Result);
         return;
      end if;

      A11y.Windows_Backend.UIA_Com_Providers.Initialize
        (Registry.Records (Registry.Next).Provider, Session, Root, Node,
         Result);
      if A11y.Results.Failed (Result) then
         Complete_Report (Registry, Id, Node, Report, Result);
         return;
      end if;

      Registry.Records (Registry.Next).Used := True;
      Registry.Records (Registry.Next).Released := False;
      Id := Provider_Id (Registry.Next);
      Registry.Node_Index (Node_Slot) := Id;
      Registry.Next := Registry.Next + 1;
      Advance_Generation (Registry);
      Result := A11y.Results.Ok;
      Complete_Report (Registry, Id, Node, Report, Result);
   end Ensure_Provider_With_Report;

   procedure Find_Provider
     (Registry : Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Provider_Record_Snapshot;
      Result   : out A11y.Results.Result)
   is
      Slot : constant Natural := A11y.Node_Ids.To_Natural (Node);
   begin
      Snapshot := (others => <>);
      if not A11y.Native_Identity.Is_Valid (Session)
        or else not A11y.Node_Ids.Is_Valid (Node)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Resolve_Provider
           (Registry, Session, Registry.Node_Index (Slot), Snapshot, Result);
      end if;
   end Find_Provider;

   procedure Resolve_Provider
     (Registry : Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Snapshot : out Provider_Record_Snapshot;
      Result   : out A11y.Results.Result)
   is
      Slot : constant Natural := Natural (Id);
   begin
      Snapshot := (others => <>);
      if Slot = 0
        or else Slot >= Registry.Next
        or else not Registry.Records (Slot).Used
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Snapshot := Record_Snapshot (Registry, Id);
      if Snapshot.Provider.Session /= Session
        or else Snapshot.Provider.Defunct
        or else Registry.Records (Slot).Released
      then
         Result := (Status => A11y.Results.Node_Unavailable);
      else
         Result := A11y.Results.Ok;
      end if;
   end Resolve_Provider;

   procedure Begin_Native_Call
     (Registry  : in out Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Id        : Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Context   :
        out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Result    : out A11y.Results.Result)
   is
   begin
      declare
         Report : Native_Call_Mutation_Report;
      begin
         Begin_Native_Call_With_Report
           (Registry, Session, Id, Requested, Context, Report, Result);
      end;
   end Begin_Native_Call;

   procedure Begin_Native_Call_With_Report
     (Registry  : in out Provider_Registry;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Id        : Provider_Id;
      Requested :
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface;
      Context   :
        out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Report    : out Native_Call_Mutation_Report;
      Result    : out A11y.Results.Result)
   is
      View : Provider_Record_Snapshot;
   begin
      Begin_Call_Report
        (Registry, Registry_Begin_Native_Call, Session, Id, Requested,
         Report);
      Resolve_Provider (Registry, Session, Id, View, Result);
      if A11y.Results.Failed (Result) then
         Context :=
           A11y.Windows_Backend.UIA_Com_Providers.Rejected_Call_Context
             (Requested, Result.Status);
         Complete_Call_Report (Registry, Id, Context, Report, Result);
         return;
      end if;

      A11y.Windows_Backend.UIA_Com_Providers.Begin_Native_Call
        (Registry.Records (Natural (Id)).Provider, Requested, Context,
         Result);
      Complete_Call_Report (Registry, Id, Context, Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Context :=
           A11y.Windows_Backend.UIA_Com_Providers.Rejected_Call_Context
             (Requested, Result.Status);
         Complete_Call_Report (Registry, Id, Context, Report, Result);
   end Begin_Native_Call_With_Report;

   procedure End_Native_Call
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Context  :
        in out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Result   : out A11y.Results.Result)
   is
   begin
      declare
         Report : Native_Call_Mutation_Report;
      begin
         End_Native_Call_With_Report
           (Registry, Session, Id, Context, Report, Result);
      end;
   end End_Native_Call;

   procedure End_Native_Call_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Context  :
        in out A11y.Windows_Backend.UIA_Com_Providers.Provider_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      Slot : constant Natural := Natural (Id);
      View : Provider_Record_Snapshot;
      Requested : constant
        A11y.Windows_Backend.UIA_Com_Providers.Provider_Interface :=
          A11y.Windows_Backend.UIA_Com_Providers.Snapshot
            (Context).Requested;
   begin
      Begin_Call_Report
        (Registry, Registry_End_Native_Call, Session, Id, Requested, Report);
      if Slot = 0
        or else Slot >= Registry.Next
        or else not Registry.Records (Slot).Used
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         Complete_Call_Report (Registry, Id, Context, Report, Result);
         return;
      end if;

      View := Record_Snapshot (Registry, Id);
      if View.Provider.Session /= Session then
         Result := (Status => A11y.Results.Node_Unavailable);
         Complete_Call_Report (Registry, Id, Context, Report, Result);
         return;
      end if;

      A11y.Windows_Backend.UIA_Com_Providers.End_Native_Call
        (Registry.Records (Slot).Provider, Context, Result);
      Complete_Call_Report (Registry, Id, Context, Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Complete_Call_Report (Registry, Id, Context, Report, Result);
   end End_Native_Call_With_Report;

   procedure Mark_Defunct
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Mark_Defunct_With_Report (Registry, Session, Node, Report, Result);
   end Mark_Defunct;

   procedure Mark_Defunct_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      View : Provider_Record_Snapshot;
   begin
      Begin_Report
        (Registry, Registry_Mark_Defunct, Session, Node, No_Provider, Report);
      Find_Provider (Registry, Session, Node, View, Result);
      if A11y.Results.Failed (Result) then
         Complete_Report (Registry, View.Id, Node, Report, Result);
         return;
      end if;

      A11y.Windows_Backend.UIA_Com_Providers.Mark_Defunct
        (Registry.Records (Natural (View.Id)).Provider, Result);
      if A11y.Results.Succeeded (Result) then
         Advance_Generation (Registry);
      end if;
      Complete_Report (Registry, View.Id, Node, Report, Result);
   end Mark_Defunct_With_Report;

   procedure Release
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Release_With_Report (Registry, Session, Id, Report, Result);
   end Release;

   procedure Release_With_Report
     (Registry : in out Provider_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Id       : Provider_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      View : Provider_Record_Snapshot;
      Count : Natural;
      Slot : constant Natural := Natural (Id);
   begin
      Begin_Report
        (Registry, Registry_Release_Provider, Session,
         A11y.Node_Ids.No_Node, Id, Report);
      if Slot = 0
        or else Slot >= Registry.Next
        or else not Registry.Records (Slot).Used
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         Complete_Report (Registry, Id, A11y.Node_Ids.No_Node, Report, Result);
         return;
      end if;

      View := Record_Snapshot (Registry, Id);
      if View.Provider.Session /= Session or else Registry.Records (Slot).Released
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         Complete_Report (Registry, Id, View.Provider.Node, Report, Result);
         return;
      end if;

      while View.Provider.References > 0 loop
         A11y.Windows_Backend.UIA_Com_Providers.Release
           (Registry.Records (Slot).Provider, Count, Result);
         exit when A11y.Results.Failed (Result);
         View := Record_Snapshot (Registry, Id);
      end loop;
      if A11y.Results.Succeeded (Result) then
         Registry.Records (Slot).Released := True;
         Advance_Generation (Registry);
      end if;
      Complete_Report (Registry, Id, View.Provider.Node, Report, Result);
   end Release_With_Report;

   procedure Reset_When_Drained
     (Registry : in out Provider_Registry;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Reset_When_Drained_With_Report (Registry, Report, Result);
   end Reset_When_Drained;

   procedure Reset_When_Drained_With_Report
     (Registry : in out Provider_Registry;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
   begin
      Begin_Report
        (Registry, Registry_Reset, A11y.Native_Identity.No_Session,
         A11y.Node_Ids.No_Node, No_Provider, Report);
      if not Drained (Registry) then
         Result := (Status => A11y.Results.Busy);
         Complete_Report
           (Registry, No_Provider, A11y.Node_Ids.No_Node, Report, Result);
         return;
      end if;

      Reset (Registry);
      Result := A11y.Results.Ok;
      Complete_Report
        (Registry, No_Provider, A11y.Node_Ids.No_Node, Report, Result);
   end Reset_When_Drained_With_Report;

   procedure Reset (Registry : in out Provider_Registry) is
      Report : Registry_Mutation_Report;
   begin
      Reset_With_Report (Registry, Report);
   end Reset;

   procedure Reset_With_Report
     (Registry : in out Provider_Registry;
      Report   : out Registry_Mutation_Report) is
      Result : constant A11y.Results.Result := A11y.Results.Ok;
   begin
      Begin_Report
        (Registry, Registry_Reset, A11y.Native_Identity.No_Session,
         A11y.Node_Ids.No_Node, No_Provider, Report);
      if not Drained (Registry) then
         Complete_Report
           (Registry, No_Provider, A11y.Node_Ids.No_Node, Report, Result);
         return;
      end if;

      Registry.Next := 1;
      Advance_Generation (Registry);
      for Index in Registry.Records'Range loop
         Registry.Records (Index) := (others => <>);
      end loop;
      for Index in Registry.Node_Index'Range loop
         Registry.Node_Index (Index) := No_Provider;
      end loop;
      Complete_Report
        (Registry, No_Provider, A11y.Node_Ids.No_Node, Report, Result);
   end Reset_With_Report;

   function Drained (Registry : Provider_Registry) return Boolean is
   begin
      for Index in 1 .. Registry.Next - 1 loop
         if Registry.Records (Index).Used
           and then not A11y.Windows_Backend.UIA_Com_Providers.Drained
             (Registry.Records (Index).Provider)
         then
            return False;
         end if;
      end loop;

      return True;
   end Drained;

   function Snapshot (Registry : Provider_Registry) return Registry_Snapshot is
      Live : Natural := 0;
      Dead : Natural := 0;
      Calls : Natural := 0;
      View : A11y.Windows_Backend.UIA_Com_Providers.Provider_Snapshot;
   begin
      for Index in 1 .. Registry.Next - 1 loop
         if Registry.Records (Index).Used then
            View :=
              A11y.Windows_Backend.UIA_Com_Providers.Snapshot
                (Registry.Records (Index).Provider);
            Calls := Calls + View.Active_Calls;
            if Registry.Records (Index).Released or else View.Defunct then
               Dead := Dead + 1;
            else
               Live := Live + 1;
            end if;
         end if;
      end loop;

      return
        (Live_Count => Live,
         Tombstones => Dead,
         Outstanding_Calls => Calls,
         Generation => Registry.Generation,
         Capacity   => Registry.Limit,
         Next_Id    => Registry.Next);
   end Snapshot;

end A11y.Windows_Backend.UIA_Provider_Registry;
