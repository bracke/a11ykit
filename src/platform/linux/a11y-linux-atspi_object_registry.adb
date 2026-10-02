with A11y.Linux.ATSPi_Objects;

package body A11y.Linux.ATSPi_Object_Registry is
   use type A11y.Results.Status_Code;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Native_Object_Caches.Native_Object_Id;

   procedure Advance_Generation (Registry : in out Object_Registry) is
   begin
      if Registry.Generation < Natural'Last then
         Registry.Generation := Registry.Generation + 1;
      end if;
   end Advance_Generation;

   procedure Begin_Report
     (Registry  : Object_Registry;
      Operation : Registry_Mutation_Kind;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Node      : A11y.Node_Ids.Node_Id;
      Object    : A11y.Native_Object_Caches.Native_Object_Id;
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
         Object             => Object,
         Session            => Session,
         Node               => Node,
         Status             => A11y.Results.Success,
         Generation_Advanced => False,
         Live_Changed        => False,
         Tombstone_Changed   => False,
         Outstanding_Changed => False,
         Object_Returned     => False);
   end Begin_Report;

   procedure Complete_Report
     (Registry : Object_Registry;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
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
      Report.Object := Object;
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
      Report.Object_Returned := A11y.Native_Object_Caches.Is_Valid (Object);
   end Complete_Report;

   procedure Begin_Call_Report
     (Registry  : Object_Registry;
      Operation : Native_Call_Mutation_Kind;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Object    : A11y.Native_Object_Caches.Native_Object_Id;
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
         Object             => Object,
         Session            => Session,
         Node               => A11y.Node_Ids.No_Node,
         Context            => <>,
         Status             => A11y.Results.Success,
         Generation_Changed => False,
         Outstanding_Changed => False,
         Call_Active        => False);
   end Begin_Call_Report;

   procedure Complete_Call_Report
     (Registry : Object_Registry;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : Object_Call_Context;
      Report   : in out Native_Call_Mutation_Report;
      Result   : A11y.Results.Result)
   is
      View : constant Registry_Snapshot := Snapshot (Registry);
      Call_View : constant Object_Call_Snapshot := Snapshot (Context);
   begin
      Report.Generation_After := View.Generation;
      Report.Outstanding_After := View.Outstanding_Calls;
      Report.Object := Object;
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

   function With_Path
     (Registry_Generation : Natural;
      Item                : A11y.Native_Object_Caches.Object_Snapshot;
      Result              : out A11y.Results.Result)
      return Object_Record_Snapshot
   is
      Path_Result : A11y.Results.Result;
      Path : constant Ada.Strings.Unbounded.Unbounded_String :=
        A11y.Linux.ATSPi_Objects.Object_Path
          (Item.Session, Item.Node, Path_Result);
   begin
      if A11y.Results.Failed (Path_Result) then
         Result := Path_Result;
         return (others => <>);
      end if;

      Result := A11y.Results.Ok;
      return
        (Object   => Item.Object,
         Session  => Item.Session,
         Node     => Item.Node,
         Path     => Path,
         Defunct  => Item.Defunct,
         Released => Item.Released,
         Registry_Generation => Registry_Generation);
   end With_Path;

   procedure Configure
     (Registry : in out Object_Registry;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Requested_Callbacks : Natural;
      Call_View : A11y.Native_Callbacks.Callback_Gate_Snapshot;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return;
      end if;

      Registry.Cache.Can_Configure (Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Requested_Callbacks :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Outstanding_Callbacks));
      Call_View := Registry.Calls.Snapshot;
      if Requested_Callbacks = 0
        or else Requested_Callbacks > A11y.Native_Callbacks.Max_Callbacks
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif Requested_Callbacks < Call_View.Outstanding then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      elsif Call_View.Outstanding /= 0
        and then Requested_Callbacks /= Registry.Calls.Capacity
      then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Registry.Cache.Configure (Limits, Result);
      if A11y.Results.Succeeded (Result) then
         Registry.Calls.Configure (Limits, Result);
         if A11y.Results.Succeeded (Result) then
            Advance_Generation (Registry);
         end if;
      end if;
   end Configure;

   procedure Ensure_Object
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Object_Record_Snapshot;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Ensure_Object_With_Report
        (Registry, Session, Node, Snapshot, Report, Result);
   end Ensure_Object;

   procedure Ensure_Object_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Object_Record_Snapshot;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      Object : A11y.Native_Object_Caches.Native_Object_Id;
      Item   : A11y.Native_Object_Caches.Object_Snapshot;
      Before : constant Natural := Registry.Cache.Generation;
   begin
      Snapshot := (others => <>);
      Begin_Report
        (Registry, Registry_Ensure_Object, Session, Node,
         A11y.Native_Object_Caches.No_Object, Report);
      Registry.Cache.Ensure_Object (Session, Node, Object, Result);
      if A11y.Results.Failed (Result) then
         Complete_Report (Registry, Object, Node, Report, Result);
         return;
      end if;
      if Registry.Cache.Generation /= Before then
         Advance_Generation (Registry);
      end if;

      Registry.Cache.Resolve (Session, Object, Item, Result);
      if A11y.Results.Failed (Result) then
         Complete_Report (Registry, Object, Node, Report, Result);
         return;
      end if;

      Snapshot := With_Path (Registry.Generation, Item, Result);
      Complete_Report (Registry, Object, Snapshot.Node, Report, Result);
   end Ensure_Object_With_Report;

   procedure Find_Object
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Snapshot : out Object_Record_Snapshot;
      Result   : out A11y.Results.Result)
   is
      Item : A11y.Native_Object_Caches.Object_Snapshot;
   begin
      Snapshot := (others => <>);
      Registry.Cache.Find_Object (Session, Node, Item, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Snapshot := With_Path (Registry.Generation, Item, Result);
   end Find_Object;

   procedure Resolve_Path
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Path     : String;
      Snapshot : out Object_Record_Snapshot;
      Result   : out A11y.Results.Result)
   is
      Node : A11y.Node_Ids.Node_Id;
   begin
      Snapshot := (others => <>);
      Node := A11y.Linux.ATSPi_Objects.Node_From_Object_Path
        (Path, Session, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Find_Object (Registry, Session, Node, Snapshot, Result);
   end Resolve_Path;

   procedure Export_Descriptor
     (Registry   : in out Object_Registry;
      Session    : A11y.Native_Identity.Backend_Session_Id;
      Object     : A11y.Native_Object_Caches.Native_Object_Id;
      Descriptor : out Object_Export_Descriptor)
   is
      Item : A11y.Native_Object_Caches.Object_Snapshot;
      View : Object_Record_Snapshot;
      Result : A11y.Results.Result;
   begin
      Descriptor := (others => <>);
      Registry.Cache.Resolve (Session, Object, Item, Result);
      if A11y.Results.Failed (Result) then
         Descriptor.Status := Result.Status;
         if A11y.Native_Object_Caches.Is_Valid (Item.Object) then
            View := With_Path (Registry.Generation, Item, Result);
            Descriptor.Object := Item.Object;
            Descriptor.Session := Item.Session;
            Descriptor.Node := Item.Node;
            Descriptor.Defunct := Item.Defunct;
            Descriptor.Released := Item.Released;
            Descriptor.Registry_Generation := Registry.Generation;
            if A11y.Results.Succeeded (Result) then
               Descriptor.Path := View.Path;
               Descriptor.Status := A11y.Results.Node_Unavailable;
            end if;
         end if;
         return;
      end if;

      View := With_Path (Registry.Generation, Item, Result);
      if A11y.Results.Failed (Result) then
         Descriptor.Status := Result.Status;
         Descriptor.Object := Item.Object;
         Descriptor.Session := Item.Session;
         Descriptor.Node := Item.Node;
         Descriptor.Defunct := Item.Defunct;
         Descriptor.Released := Item.Released;
         Descriptor.Registry_Generation := Registry.Generation;
         return;
      end if;

      Descriptor :=
        (Exportable => True,
         Status     => A11y.Results.Success,
         Object     => View.Object,
         Session    => View.Session,
         Node       => View.Node,
         Path       => View.Path,
         Defunct    => View.Defunct,
         Released   => View.Released,
         Registry_Generation => Registry.Generation);
   exception
      when others =>
         Descriptor :=
           (Exportable => False,
            Status     => A11y.Results.Internal_Error,
            Object     => A11y.Native_Object_Caches.No_Object,
            Session    => A11y.Native_Identity.No_Session,
            Node       => A11y.Node_Ids.No_Node,
            Path       => Ada.Strings.Unbounded.Null_Unbounded_String,
            Defunct    => True,
            Released   => False,
            Registry_Generation => 0);
   end Export_Descriptor;

   procedure Begin_Native_Call
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : out Object_Call_Context;
      Result   : out A11y.Results.Result)
   is
   begin
      declare
         Report : Native_Call_Mutation_Report;
      begin
         Begin_Native_Call_With_Report
           (Registry, Session, Object, Context, Report, Result);
      end;
   end Begin_Native_Call;

   procedure Begin_Native_Call_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : out Object_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      Item : A11y.Native_Object_Caches.Object_Snapshot;
      Token : A11y.Native_Callbacks.Callback_Token;
   begin
      Context := (others => <>);
      Begin_Call_Report
        (Registry, Registry_Begin_Native_Call, Session, Object, Report);
      Registry.Cache.Resolve (Session, Object, Item, Result);
      if A11y.Results.Failed (Result) then
         Complete_Call_Report (Registry, Object, Context, Report, Result);
         return;
      end if;

      Registry.Calls.Begin_Callback (Token, Result);
      if A11y.Results.Failed (Result) then
         Complete_Call_Report (Registry, Object, Context, Report, Result);
         return;
      end if;

      Context :=
        (Active              => True,
         Token               => Token,
         Object              => Item.Object,
         Session             => Item.Session,
         Node                => Item.Node,
         Registry_Generation => Registry.Generation);
      Complete_Call_Report (Registry, Object, Context, Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Context := (others => <>);
         Complete_Call_Report (Registry, Object, Context, Report, Result);
   end Begin_Native_Call_With_Report;

   procedure End_Native_Call
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : in out Object_Call_Context;
      Result   : out A11y.Results.Result) is
   begin
      declare
         Report : Native_Call_Mutation_Report;
      begin
         End_Native_Call_With_Report
           (Registry, Session, Object, Context, Report, Result);
      end;
   end End_Native_Call;

   procedure End_Native_Call_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Context  : in out Object_Call_Context;
      Report   : out Native_Call_Mutation_Report;
      Result   : out A11y.Results.Result) is
   begin
      Begin_Call_Report
        (Registry, Registry_End_Native_Call, Session, Object, Report);
      if not Context.Active
        or else Context.Session /= Session
        or else Context.Object /= Object
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         Complete_Call_Report (Registry, Object, Context, Report, Result);
         return;
      end if;

      Registry.Calls.End_Callback (Context.Token, Result);
      if A11y.Results.Succeeded (Result) then
         Context.Active := False;
      elsif Result.Status = A11y.Results.Invalid_State then
         Context.Active := False;
      end if;
      Complete_Call_Report (Registry, Object, Context, Report, Result);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         Complete_Call_Report (Registry, Object, Context, Report, Result);
   end End_Native_Call_With_Report;

   procedure Mark_Defunct
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Mark_Defunct_With_Report (Registry, Session, Node, Report, Result);
   end Mark_Defunct;

   procedure Mark_Defunct_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Node     : A11y.Node_Ids.Node_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      Item : A11y.Native_Object_Caches.Object_Snapshot;
   begin
      Begin_Report
        (Registry, Registry_Mark_Defunct, Session, Node,
         A11y.Native_Object_Caches.No_Object, Report);
      Registry.Cache.Find_Object (Session, Node, Item, Result);
      if A11y.Results.Failed (Result) then
         Complete_Report (Registry, Item.Object, Node, Report, Result);
         return;
      end if;

      Registry.Cache.Mark_Defunct (Node, Result);
      if A11y.Results.Succeeded (Result) then
         Advance_Generation (Registry);
      end if;
      Complete_Report (Registry, Item.Object, Item.Node, Report, Result);
   end Mark_Defunct_With_Report;

   procedure Release
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Release_With_Report (Registry, Session, Object, Report, Result);
   end Release;

   procedure Release_With_Report
     (Registry : in out Object_Registry;
      Session  : A11y.Native_Identity.Backend_Session_Id;
      Object   : A11y.Native_Object_Caches.Native_Object_Id;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result)
   is
      Item : A11y.Native_Object_Caches.Object_Snapshot;
   begin
      Begin_Report
        (Registry, Registry_Release_Object, Session, A11y.Node_Ids.No_Node,
         Object, Report);
      Registry.Cache.Resolve (Session, Object, Item, Result);
      if A11y.Results.Failed (Result) then
         Complete_Report (Registry, Object, Item.Node, Report, Result);
         return;
      end if;

      Registry.Cache.Release (Object, Result);
      if A11y.Results.Succeeded (Result) then
         Advance_Generation (Registry);
      end if;
      Complete_Report (Registry, Object, Item.Node, Report, Result);
   end Release_With_Report;

   procedure Reset_When_Drained
     (Registry : in out Object_Registry;
      Result   : out A11y.Results.Result)
   is
      Report : Registry_Mutation_Report;
   begin
      Reset_When_Drained_With_Report (Registry, Report, Result);
   end Reset_When_Drained;

   procedure Reset_When_Drained_With_Report
     (Registry : in out Object_Registry;
      Report   : out Registry_Mutation_Report;
      Result   : out A11y.Results.Result) is
   begin
      Begin_Report
        (Registry, Registry_Reset, A11y.Native_Identity.No_Session,
         A11y.Node_Ids.No_Node, A11y.Native_Object_Caches.No_Object, Report);
      if Drained (Registry) then
         Registry.Calls.Reset (Result);
         if A11y.Results.Failed (Result) then
            Complete_Report
              (Registry, A11y.Native_Object_Caches.No_Object,
               A11y.Node_Ids.No_Node, Report, Result);
            return;
         end if;

         Registry.Cache.Reset;
         Advance_Generation (Registry);
         Result := A11y.Results.Ok;
      else
         Result := (Status => A11y.Results.Busy);
      end if;
      Complete_Report
        (Registry, A11y.Native_Object_Caches.No_Object,
         A11y.Node_Ids.No_Node, Report, Result);
   end Reset_When_Drained_With_Report;

   procedure Reset (Registry : in out Object_Registry) is
      Report : Registry_Mutation_Report;
   begin
      Reset_With_Report (Registry, Report);
   end Reset;

   procedure Reset_With_Report
     (Registry : in out Object_Registry;
      Report   : out Registry_Mutation_Report) is
      Result : constant A11y.Results.Result := A11y.Results.Ok;
   begin
      Begin_Report
        (Registry, Registry_Reset, A11y.Native_Identity.No_Session,
         A11y.Node_Ids.No_Node, A11y.Native_Object_Caches.No_Object, Report);
      if Registry.Calls.Drained then
         Registry.Calls.Reset;
         Registry.Cache.Reset;
         Advance_Generation (Registry);
      end if;
      Complete_Report
        (Registry, A11y.Native_Object_Caches.No_Object,
         A11y.Node_Ids.No_Node, Report, Result);
   end Reset_With_Report;

   function Drained (Registry : Object_Registry) return Boolean is
     (Registry.Cache.Live_Count = 0 and then Registry.Calls.Drained);

   function Snapshot (Registry : Object_Registry) return Registry_Snapshot is
     ((Live_Count         => Registry.Cache.Live_Count,
       Tombstones         => Registry.Cache.Tombstone_Count,
       Outstanding_Calls  => Registry.Calls.Snapshot.Outstanding,
       Generation         => Registry.Generation,
       Capacity           => Registry.Cache.Object_Capacity,
       Tombstone_Capacity => Registry.Cache.Tombstone_Capacity));

   function Snapshot
     (Context : Object_Call_Context)
      return Object_Call_Snapshot is
     ((Active              => Context.Active,
       Object              => Context.Object,
       Session             => Context.Session,
       Node                => Context.Node,
       Registry_Generation => Context.Registry_Generation));

end A11y.Linux.ATSPi_Object_Registry;
