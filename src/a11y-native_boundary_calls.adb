with A11y.Native_Boundary_Calls.Classification;
with A11y.Native_Identity;

package body A11y.Native_Boundary_Calls is

   function Return_Class
     (Status : A11y.Results.Status_Code)
      return Boundary_Return_Class is
     (A11y.Native_Boundary_Calls.Classification.Return_Class (Status))
   with SPARK_Mode => On;

   function Should_Replace_Final_Status
     (Current_Status  : A11y.Results.Status_Code;
      Candidate_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Native_Boundary_Calls.Classification
        .Should_Replace_Final_Status (Current_Status, Candidate_Status))
   with SPARK_Mode => On;

   function Completion_Operation_Status
     (Record_Result_Status : A11y.Results.Status_Code;
      End_Result_Status    : A11y.Results.Status_Code)
      return A11y.Results.Status_Code is
     (A11y.Native_Boundary_Calls.Classification
        .Completion_Operation_Status
          (Record_Result_Status, End_Result_Status))
   with SPARK_Mode => On;

   function Final_Status_Overrides_Action
     (Final_Status  : A11y.Results.Status_Code;
      Action_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Native_Boundary_Calls.Classification
        .Final_Status_Overrides_Action (Final_Status, Action_Status))
   with SPARK_Mode => On;

   function Dispatch_Status_Overrides_Query
     (Dispatch_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Query (Dispatch_Status))
   with SPARK_Mode => On;

   function Dispatch_Status_Overrides_Action
     (Dispatch_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Action (Dispatch_Status))
   with SPARK_Mode => On;

   function Begin_Status_Rejects_Call
     (Begin_Status : A11y.Results.Status_Code)
      return Boolean is
     (A11y.Native_Boundary_Calls.Classification
        .Begin_Status_Rejects_Call (Begin_Status))
   with SPARK_Mode => On;

   function Empty_Context return Boundary_Call_Context is
     (Active => False,
      Token  => A11y.Native_Callbacks.No_Token,
      Object => A11y.Native_Object_Caches.No_Object,
      Runtime_Generation => 0,
      Item   => (others => <>),
      Kind   => A11y.Dispatchers.Simple_Property_Query,
      Last_Status => A11y.Results.Success);

   function Empty_Context
     (Status : A11y.Results.Status_Code)
     return Boundary_Call_Context is
     (Active => False,
      Token  => A11y.Native_Callbacks.No_Token,
      Object => A11y.Native_Object_Caches.No_Object,
      Runtime_Generation => 0,
      Item   => (others => <>),
      Kind   => A11y.Dispatchers.Simple_Property_Query,
      Last_Status => Status);

   function Empty_Context
     (Status : A11y.Results.Status_Code;
      Object : A11y.Native_Object_Caches.Native_Object_Id;
      Kind   : A11y.Dispatchers.Call_Kind;
      Runtime_Generation : Natural := 0)
      return Boundary_Call_Context is
     (Active => False,
      Token  => A11y.Native_Callbacks.No_Token,
      Object => Object,
      Runtime_Generation => Runtime_Generation,
      Item   => (others => <>),
      Kind   => Kind,
      Last_Status => Status);

   function Failed_Context
     (Status : A11y.Results.Status_Code;
      Object : A11y.Native_Object_Caches.Native_Object_Id;
      Runtime_Generation : Natural;
      Item   : A11y.Native_Object_Caches.Object_Snapshot;
      Kind   : A11y.Dispatchers.Call_Kind)
      return Boundary_Call_Context is
     (Active => False,
      Token  => A11y.Native_Callbacks.No_Token,
      Object => Object,
      Runtime_Generation => Runtime_Generation,
      Item   => Item,
      Kind   => Kind,
      Last_Status => Status);

   function Released_Context
     (Context : Boundary_Call_Context;
      Status  : A11y.Results.Status_Code)
     return Boundary_Call_Context is
     (Active => False,
      Token  => A11y.Native_Callbacks.No_Token,
      Object => Context.Object,
      Runtime_Generation => Context.Runtime_Generation,
      Item   => Context.Item,
      Kind   => Context.Kind,
      Last_Status => Status);

   function Empty_Node_Context
     (Status : A11y.Results.Status_Code;
      Node   : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Dispatchers.Call_Kind;
      Runtime_Generation : Natural := 0)
      return Boundary_Call_Context is
     (Active => False,
      Token  => A11y.Native_Callbacks.No_Token,
      Object => A11y.Native_Object_Caches.No_Object,
      Runtime_Generation => Runtime_Generation,
      Item   =>
        (Object   => A11y.Native_Object_Caches.No_Object,
         Cache_Generation => 0,
         Session  => A11y.Native_Identity.No_Session,
         Node     => Node,
         Defunct  => False,
         Released => False),
      Kind   => Kind,
      Last_Status => Status);

   procedure Begin_Object_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Object  : A11y.Native_Object_Caches.Native_Object_Id;
      Context : out Boundary_Call_Context;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query)
   is
      Report : Boundary_Call_Admission_Report;
   begin
      Begin_Object_Call_With_Report
        (Gate, Runtime, Object, Context, Report, Result, Kind);
   end Begin_Object_Call;

   procedure Begin_Object_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Object  : A11y.Native_Object_Caches.Native_Object_Id;
      Context : out Boundary_Call_Context;
      Report  : out Boundary_Call_Admission_Report;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query)
   is
      Token : A11y.Native_Callbacks.Callback_Token :=
        A11y.Native_Callbacks.No_Token;
      End_Result : A11y.Results.Result;
      Item : A11y.Native_Object_Caches.Object_Snapshot;
      Runtime_View : constant A11y.Native_Runtimes.Runtime_Snapshot :=
        A11y.Native_Runtimes.Snapshot (Runtime);
   begin
      Context := Empty_Context;
      Report :=
        (Requested_Object => Object,
         Requested_Node   => A11y.Node_Ids.No_Node,
         Object           => Object,
         Node             => A11y.Node_Ids.No_Node,
         Runtime_Generation => Runtime_View.Generation,
         Cache_Generation   => 0,
         Kind             => Kind,
         Timeout_Limit    => A11y.Dispatchers.Timeout_Limit (Kind),
         Callback_Admitted => False,
         Object_Resolved   => False,
         Active            => False,
         Defunct           => False,
         Status            => A11y.Results.Node_Unavailable,
         Class             => Return_Unavailable);

      Gate.Begin_Callback (Token, Result);
      if A11y.Results.Failed (Result) then
         Context :=
           Empty_Context
             (Result.Status, Object, Kind, Runtime_View.Generation);
         Report.Status := Result.Status;
         Report.Class := Return_Class (Result.Status);
         return;
      end if;
      Report.Callback_Admitted := True;

      A11y.Native_Runtimes.Resolve_Object (Runtime, Object, Item, Result);
      if A11y.Results.Failed (Result) then
         Gate.End_Callback (Token, End_Result);
         Context :=
           Failed_Context
             (Result.Status, Object, Runtime_View.Generation, Item, Kind);
         Report.Object := Object;
         Report.Node := Item.Node;
         Report.Cache_Generation := Item.Cache_Generation;
         Report.Defunct := Item.Defunct;
         Report.Status := Result.Status;
         Report.Class := Return_Class (Result.Status);
         return;
      end if;
      Report.Object_Resolved := True;
      Report.Object := Object;
      Report.Node := Item.Node;
      Report.Cache_Generation := Item.Cache_Generation;
      Report.Defunct := Item.Defunct;

      Context :=
        (Active => True,
         Token  => Token,
         Object => Object,
         Runtime_Generation => Runtime_View.Generation,
         Item   => Item,
         Kind   => Kind,
         Last_Status => A11y.Results.Success);
      Report.Active := True;
      Report.Status := A11y.Results.Success;
      Report.Class := Return_Success;
      Result := A11y.Results.Ok;
   exception
      when others =>
         if A11y.Native_Callbacks.Is_Valid (Token) then
            Gate.End_Callback (Token, End_Result);
         end if;
         Context := Empty_Context (A11y.Results.Internal_Error);
         Report :=
           (Requested_Object => Object,
            Requested_Node   => A11y.Node_Ids.No_Node,
            Object           => Object,
            Node             => A11y.Node_Ids.No_Node,
            Runtime_Generation => 0,
            Cache_Generation   => 0,
            Kind             => Kind,
            Timeout_Limit    => A11y.Dispatchers.Timeout_Limit (Kind),
            Callback_Admitted => False,
            Object_Resolved   => False,
            Active            => False,
            Defunct           => False,
            Status            => A11y.Results.Internal_Error,
            Class             => Return_Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Begin_Object_Call_With_Report;

   procedure Begin_Node_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Context : out Boundary_Call_Context;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query)
   is
      Report : Boundary_Call_Admission_Report;
   begin
      Begin_Node_Call_With_Report
        (Gate, Runtime, Node, Context, Report, Result, Kind);
   end Begin_Node_Call;

   procedure Begin_Node_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Runtime : in out A11y.Native_Runtimes.Native_Runtime;
      Node    : A11y.Node_Ids.Node_Id;
      Context : out Boundary_Call_Context;
      Report  : out Boundary_Call_Admission_Report;
      Result  : out A11y.Results.Result;
      Kind    : A11y.Dispatchers.Call_Kind :=
        A11y.Dispatchers.Simple_Property_Query)
   is
      Token : A11y.Native_Callbacks.Callback_Token :=
        A11y.Native_Callbacks.No_Token;
      End_Result : A11y.Results.Result;
      Item : A11y.Native_Object_Caches.Object_Snapshot;
      Runtime_View : constant A11y.Native_Runtimes.Runtime_Snapshot :=
        A11y.Native_Runtimes.Snapshot (Runtime);
   begin
      Context := Empty_Context;
      Report :=
        (Requested_Object => A11y.Native_Object_Caches.No_Object,
         Requested_Node   => Node,
         Object           => A11y.Native_Object_Caches.No_Object,
         Node             => Node,
         Runtime_Generation => Runtime_View.Generation,
         Cache_Generation   => 0,
         Kind             => Kind,
         Timeout_Limit    => A11y.Dispatchers.Timeout_Limit (Kind),
         Callback_Admitted => False,
         Object_Resolved   => False,
         Active            => False,
         Defunct           => False,
         Status            => A11y.Results.Node_Unavailable,
         Class             => Return_Unavailable);

      Gate.Begin_Callback (Token, Result);
      if A11y.Results.Failed (Result) then
         Context :=
           Empty_Node_Context
             (Result.Status, Node, Kind, Runtime_View.Generation);
         Report.Status := Result.Status;
         Report.Class := Return_Class (Result.Status);
         return;
      end if;
      Report.Callback_Admitted := True;

      A11y.Native_Runtimes.Find_Object (Runtime, Node, Item, Result);
      if A11y.Results.Failed (Result) then
         Gate.End_Callback (Token, End_Result);
         Context :=
           Failed_Context
             (Result.Status, Item.Object, Runtime_View.Generation, Item, Kind);
         Report.Object := Item.Object;
         Report.Node := Node;
         Report.Cache_Generation := Item.Cache_Generation;
         Report.Defunct := Item.Defunct;
         Report.Status := Result.Status;
         Report.Class := Return_Class (Result.Status);
         return;
      end if;
      Report.Object_Resolved := True;
      Report.Object := Item.Object;
      Report.Node := Item.Node;
      Report.Cache_Generation := Item.Cache_Generation;
      Report.Defunct := Item.Defunct;

      Context :=
        (Active => True,
         Token  => Token,
         Object => Item.Object,
         Runtime_Generation => Runtime_View.Generation,
         Item   => Item,
         Kind   => Kind,
         Last_Status => A11y.Results.Success);
      Report.Active := True;
      Report.Status := A11y.Results.Success;
      Report.Class := Return_Success;
      Result := A11y.Results.Ok;
   exception
      when others =>
         if A11y.Native_Callbacks.Is_Valid (Token) then
            Gate.End_Callback (Token, End_Result);
         end if;
         Context := Empty_Node_Context (A11y.Results.Internal_Error, Node, Kind);
         Report :=
           (Requested_Object => A11y.Native_Object_Caches.No_Object,
            Requested_Node   => Node,
            Object           => A11y.Native_Object_Caches.No_Object,
            Node             => Node,
            Runtime_Generation => 0,
            Cache_Generation   => 0,
            Kind             => Kind,
            Timeout_Limit    => A11y.Dispatchers.Timeout_Limit (Kind),
            Callback_Admitted => False,
            Object_Resolved   => False,
            Active            => False,
            Defunct           => False,
            Status            => A11y.Results.Internal_Error,
            Class             => Return_Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Begin_Node_Call_With_Report;

   procedure End_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Result  : out A11y.Results.Result)
   is
      Report : Boundary_Call_Release_Report;
   begin
      End_Call_With_Report (Gate, Context, Report, Result);
   end End_Call;

   procedure End_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Report  : out Boundary_Call_Release_Report;
      Result  : out A11y.Results.Result)
   is
      Previous_Status : constant A11y.Results.Status_Code :=
        Context.Last_Status;
      Before : constant Boundary_Call_Snapshot := Snapshot (Context);
   begin
      Report :=
        (Before => Before,
         After  => Before,
         Preserved_Status => Previous_Status,
         End_Result_Status => A11y.Results.Success,
         Released => False,
         Status => A11y.Results.Success,
         Class => Return_Class (Previous_Status));

      if not Context.Active then
         Context := Empty_Context (A11y.Results.Invalid_State);
         Result := (Status => A11y.Results.Invalid_State);
         Report.After := Snapshot (Context);
         Report.End_Result_Status := Result.Status;
         Report.Status := Result.Status;
         Report.Class := Return_Class (Result.Status);
         return;
      end if;

      Gate.End_Callback (Context.Token, Result);
      Report.End_Result_Status := Result.Status;
      if A11y.Results.Failed (Result) then
         Context := Released_Context (Context, Result.Status);
      else
         Context := Released_Context (Context, Previous_Status);
      end if;
      Report.After := Snapshot (Context);
      Report.Released := Before.Active and then not Report.After.Active;
      Report.Status := Result.Status;
      Report.Class :=
        (if A11y.Results.Failed (Result) then
           Return_Class (Result.Status)
         else
           Return_Class (Previous_Status));
   exception
      when others =>
         Context := Empty_Context (A11y.Results.Internal_Error);
         Report :=
           (Before => (others => <>),
            After  => Snapshot (Context),
            Preserved_Status => A11y.Results.Internal_Error,
            End_Result_Status => A11y.Results.Internal_Error,
            Released => False,
            Status => A11y.Results.Internal_Error,
            Class => Return_Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end End_Call_With_Report;

   procedure Record_Status
     (Context : in out Boundary_Call_Context;
      Status  : A11y.Results.Status_Code;
      Result  : out A11y.Results.Result)
   is
   begin
      if not Context.Active then
         Context := Empty_Context (A11y.Results.Invalid_State);
         Result := (Status => A11y.Results.Invalid_State);
      else
         Context.Last_Status := Status;
         Result := A11y.Results.Ok;
      end if;
   exception
      when others =>
         Context := Empty_Context (A11y.Results.Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Record_Status;

   procedure Complete_Call
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Status  : in out A11y.Results.Status_Code;
      Result  : out A11y.Results.Result)
   is
      Report : Boundary_Call_Completion_Report;
   begin
      Complete_Call_With_Report (Gate, Context, Status, Report, Result);
   end Complete_Call;

   procedure Complete_Call_With_Report
     (Gate    : in out A11y.Native_Callbacks.Callback_Gate;
      Context : in out Boundary_Call_Context;
      Status  : in out A11y.Results.Status_Code;
      Report  : out Boundary_Call_Completion_Report;
      Result  : out A11y.Results.Result)
   is
      Record_Result : A11y.Results.Result;
      End_Result : A11y.Results.Result;
      Release_Report : Boundary_Call_Release_Report;
      Requested_Status : constant A11y.Results.Status_Code := Status;
      Before : constant Boundary_Call_Snapshot := Snapshot (Context);
   begin
      Report :=
        (Before => Before,
         After  => Before,
         Requested_Status => Requested_Status,
         Final_Status => Status,
         Record_Result_Status => A11y.Results.Success,
         End_Result_Status => A11y.Results.Success,
         Recorded => False,
         Released => False,
         Status => A11y.Results.Success,
         Class => Return_Class (Status));

      Record_Status (Context, Status, Record_Result);
      Report.Record_Result_Status := Record_Result.Status;
      Report.Recorded := A11y.Results.Succeeded (Record_Result);
      if Should_Replace_Final_Status (Status, Record_Result.Status)
      then
         Status := Record_Result.Status;
      end if;

      End_Call_With_Report (Gate, Context, Release_Report, End_Result);
      Report.End_Result_Status := End_Result.Status;
      if Should_Replace_Final_Status (Status, End_Result.Status)
      then
         Status := End_Result.Status;
      end if;
      Report.After := Release_Report.After;
      Report.Final_Status := Status;
      Report.Released := Release_Report.Released;
      Report.Status :=
        Completion_Operation_Status (Record_Result.Status, End_Result.Status);
      Report.Class := Return_Class (Status);

      if A11y.Results.Failed (End_Result) then
         Result := End_Result;
      else
         Result := Record_Result;
      end if;
   exception
      when others =>
         Status := A11y.Results.Internal_Error;
         Context := Empty_Context (A11y.Results.Internal_Error);
         Report :=
           (Before => (others => <>),
            After  => Snapshot (Context),
            Requested_Status => A11y.Results.Internal_Error,
            Final_Status => A11y.Results.Internal_Error,
            Record_Result_Status => A11y.Results.Internal_Error,
            End_Result_Status => A11y.Results.Internal_Error,
            Recorded => False,
            Released => False,
            Status => A11y.Results.Internal_Error,
            Class => Return_Internal_Error);
         Result := (Status => A11y.Results.Internal_Error);
   end Complete_Call_With_Report;

   function Snapshot
     (Context : Boundary_Call_Context)
     return Boundary_Call_Snapshot is
     (Active  => Context.Active,
      Object  => Context.Object,
      Runtime_Generation => Context.Runtime_Generation,
      Cache_Generation => Context.Item.Cache_Generation,
      Node    => Context.Item.Node,
      Defunct => Context.Item.Defunct,
      Kind    => Context.Kind,
      Timeout_Limit => A11y.Dispatchers.Timeout_Limit (Context.Kind),
      Last_Status => Context.Last_Status);

   function Outcome
     (Context : Boundary_Call_Context)
     return Boundary_Call_Outcome is
     (Active        => Context.Active,
      Object        => Context.Object,
      Runtime_Generation => Context.Runtime_Generation,
      Cache_Generation => Context.Item.Cache_Generation,
      Node          => Context.Item.Node,
      Defunct       => Context.Item.Defunct,
      Kind          => Context.Kind,
      Timeout_Limit => A11y.Dispatchers.Timeout_Limit (Context.Kind),
      Status        => Context.Last_Status,
      Class         => Return_Class (Context.Last_Status));

end A11y.Native_Boundary_Calls;
