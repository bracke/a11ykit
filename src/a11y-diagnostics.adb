package body A11y.Diagnostics is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   Backend_Initialization_Name     : aliased constant String :=
     "backend.initialization";
   Native_Runtime_Connection_Name  : aliased constant String :=
     "native-runtime.connection";
   Native_Registration_Name        : aliased constant String :=
     "native.registration";
   Node_Lifecycle_Name             : aliased constant String :=
     "node.lifecycle";
   Provider_Timeout_Name           : aliased constant String :=
     "provider.timeout";
   Mapping_Fallback_Name           : aliased constant String :=
     "mapping.fallback";
   Unsupported_Capability_Name     : aliased constant String :=
     "unsupported.capability";
   Resource_Limit_Name             : aliased constant String :=
     "resource.limit";
   Event_Overflow_Name             : aliased constant String :=
     "event.overflow";
   Stale_Native_Query_Name         : aliased constant String :=
     "stale-native.query";
   Text_Conversion_Name            : aliased constant String :=
     "text.conversion";
   Native_Allocation_Name          : aliased constant String :=
     "native.allocation";
   ABI_Boundary_Failure_Name       : aliased constant String :=
     "abi-boundary.failure";
   Reference_Count_Anomaly_Name    : aliased constant String :=
     "reference-count.anomaly";
   Autorelease_Anomaly_Name        : aliased constant String :=
     "autorelease.anomaly";
   Shutdown_Anomaly_Name           : aliased constant String :=
     "shutdown.anomaly";
   Conformance_Failure_Name        : aliased constant String :=
     "conformance.failure";

   Trace_Name   : aliased constant String := "trace";
   Info_Name    : aliased constant String := "info";
   Warning_Name : aliased constant String := "warning";
   Error_Name   : aliased constant String := "error";
   Fatal_Name   : aliased constant String := "fatal";

   function Metadata (Class : Category) return Category_Metadata is
     (case Class is
        when Backend_Initialization =>
          (Stable_Name => Backend_Initialization_Name'Access,
           Default_Severity => Info),
        when Native_Runtime_Connection =>
          (Stable_Name => Native_Runtime_Connection_Name'Access,
           Default_Severity => Warning),
        when Native_Registration =>
          (Stable_Name => Native_Registration_Name'Access,
           Default_Severity => Warning),
        when Node_Lifecycle =>
          (Stable_Name => Node_Lifecycle_Name'Access,
           Default_Severity => Info),
        when Provider_Timeout =>
          (Stable_Name => Provider_Timeout_Name'Access,
           Default_Severity => Warning),
        when Mapping_Fallback =>
          (Stable_Name => Mapping_Fallback_Name'Access,
           Default_Severity => Warning),
        when Unsupported_Capability =>
          (Stable_Name => Unsupported_Capability_Name'Access,
           Default_Severity => Trace),
        when Resource_Limit =>
          (Stable_Name => Resource_Limit_Name'Access,
           Default_Severity => Warning),
        when Event_Overflow =>
          (Stable_Name => Event_Overflow_Name'Access,
           Default_Severity => Error),
        when Stale_Native_Query =>
          (Stable_Name => Stale_Native_Query_Name'Access,
           Default_Severity => Warning),
        when Text_Conversion =>
          (Stable_Name => Text_Conversion_Name'Access,
           Default_Severity => Error),
        when Native_Allocation =>
          (Stable_Name => Native_Allocation_Name'Access,
           Default_Severity => Fatal),
        when ABI_Boundary_Failure =>
          (Stable_Name => ABI_Boundary_Failure_Name'Access,
           Default_Severity => Error),
        when Reference_Count_Anomaly =>
          (Stable_Name => Reference_Count_Anomaly_Name'Access,
           Default_Severity => Error),
        when Autorelease_Anomaly =>
          (Stable_Name => Autorelease_Anomaly_Name'Access,
           Default_Severity => Error),
        when Shutdown_Anomaly =>
          (Stable_Name => Shutdown_Anomaly_Name'Access,
           Default_Severity => Warning),
        when Conformance_Failure =>
          (Stable_Name => Conformance_Failure_Name'Access,
           Default_Severity => Error));

   function Stable_Name (Class : Category) return String is
     (Metadata (Class).Stable_Name.all);

   function Stable_Name (Level : Severity) return String is
     (case Level is
        when Trace   => Trace_Name,
        when Info    => Info_Name,
        when Warning => Warning_Name,
        when Error   => Error_Name,
        when Fatal   => Fatal_Name);

   function Default_Severity
     (Class : Category)
      return Severity is
     (case Class is
        when Backend_Initialization =>
          Info,
        when Native_Runtime_Connection =>
          Warning,
        when Native_Registration =>
          Warning,
        when Node_Lifecycle =>
          Info,
        when Provider_Timeout =>
          Warning,
        when Mapping_Fallback =>
          Warning,
        when Unsupported_Capability =>
          Trace,
        when Resource_Limit =>
          Warning,
        when Event_Overflow =>
          Error,
        when Stale_Native_Query =>
          Warning,
        when Text_Conversion =>
          Error,
        when Native_Allocation =>
          Fatal,
        when ABI_Boundary_Failure =>
          Error,
        when Reference_Count_Anomaly =>
          Error,
        when Autorelease_Anomaly =>
          Error,
        when Shutdown_Anomaly =>
          Warning,
        when Conformance_Failure =>
          Error)
   with SPARK_Mode => On;

   function Category_For_Status
     (Status : A11y.Results.Status_Code)
      return Category is
     (case Status is
        when A11y.Results.Success
           | A11y.Results.Accepted_Asynchronous =>
          Node_Lifecycle,
        when A11y.Results.Backend_Unavailable
           | A11y.Results.Accessibility_Service_Unavailable =>
          Native_Runtime_Connection,
        when A11y.Results.Node_Unavailable =>
          Stale_Native_Query,
        when A11y.Results.Unsupported_Property
           | A11y.Results.Unsupported_Capability
           | A11y.Results.Unsupported_Action =>
          Unsupported_Capability,
        when A11y.Results.Invalid_Argument
           | A11y.Results.Invalid_Range
           | A11y.Results.Protocol_Failure
           | A11y.Results.Native_Failure
           | A11y.Results.Internal_Error =>
          ABI_Boundary_Failure,
        when A11y.Results.Invalid_State
           | A11y.Results.Read_Only
           | A11y.Results.Disabled
           | A11y.Results.Busy
           | A11y.Results.Cancelled
           | A11y.Results.Permission_Denied =>
          Node_Lifecycle,
        when A11y.Results.Timed_Out =>
          Provider_Timeout,
        when A11y.Results.Shutting_Down =>
          Shutdown_Anomaly,
        when A11y.Results.Resource_Limit =>
          Resource_Limit,
        when A11y.Results.Out_Of_Resources =>
          Native_Allocation)
   with SPARK_Mode => On;

   function Severity_For_Status
     (Status : A11y.Results.Status_Code)
      return Severity is
     (if Status in A11y.Results.Success
               | A11y.Results.Accepted_Asynchronous
      then Trace
      else Default_Severity (Category_For_Status (Status)))
   with SPARK_Mode => On;

   function Is_Reportable
     (Level : Severity)
      return Boolean is
     (Level in Warning | Error | Fatal)
   with SPARK_Mode => On;

   function Is_Native_Boundary_Category
     (Class : Category)
      return Boolean is
     (Class in Native_Runtime_Connection | Native_Registration
      | Stale_Native_Query | Native_Allocation | ABI_Boundary_Failure
      | Reference_Count_Anomaly | Autorelease_Anomaly)
   with SPARK_Mode => On;

   procedure Create
     (Identifier : String;
      Class      : Category;
      Item       : out Diagnostic;
      Result     : out A11y.Results.Result;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Feature    : String := "";
      Level      : Severity := Info;
      Redacted   : Boolean := True)
   is
   begin
      Item :=
        (Identifier => Null_Unbounded_String,
         Level      => Level,
         Class      => Class,
         Node       => Node,
         Sequence   => Sequence,
         Timestamp  => Ada.Calendar.Clock,
         Feature    => Null_Unbounded_String,
         Fields     => <>,
         Redacted   => Redacted);

      if Identifier'Length = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif Identifier'Length > Max_Diagnostic_Identifier_Length
        or else Feature'Length > Max_Diagnostic_Feature_Length
      then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Item.Identifier := To_Unbounded_String (Identifier);
      Item.Feature := To_Unbounded_String (Feature);
      Result := A11y.Results.Ok;
   end Create;

   procedure Create_For_Status
     (Identifier : String;
      Status     : A11y.Results.Status_Code;
      Item       : out Diagnostic;
      Result     : out A11y.Results.Result;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Feature    : String := "";
      Redacted   : Boolean := True) is
   begin
      Create
        (Identifier => Identifier,
         Class      => Category_For_Status (Status),
         Item       => Item,
         Result     => Result,
         Node       => Node,
         Sequence   => Sequence,
         Feature    => Feature,
         Level      => Severity_For_Status (Status),
         Redacted   => Redacted);
   end Create_For_Status;

   function Effective_Limit
     (Limit      : Natural;
      Configured : A11y.Resource_Limits.Limit_Value)
      return Natural is
     (Natural'Min (Limit, Natural (Configured)))
   with SPARK_Mode => On;

   procedure Add_Field
     (Item     : in out Diagnostic;
      Key      : String;
      Value    : String;
      Result   : out A11y.Results.Result;
      Redacted : Boolean := True)
   is
   begin
      Add_Field
        (Item,
         Key,
         Value,
         A11y.Resource_Limits.Default_Config,
         Result,
         Redacted);
   end Add_Field;

   procedure Add_Field
     (Item     : in out Diagnostic;
      Key      : String;
      Value    : String;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result;
      Redacted : Boolean := True)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Configured_String_Limit : constant A11y.Resource_Limits.Limit_Value :=
        A11y.Resource_Limits.Value
          (Limits, A11y.Resource_Limits.Native_String_Size);
      Key_Limit : constant Natural :=
        Effective_Limit
          (Max_Diagnostic_Key_Length, Configured_String_Limit);
      Value_Limit : constant Natural :=
        Effective_Limit
          (Max_Diagnostic_Value_Length, Configured_String_Limit);
      Field : Diagnostic_Field;
   begin
      if not A11y.Results.Succeeded (Validation) then
         Result := Validation;
         return;
      end if;

      if Key'Length = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if Natural (Item.Fields.Length) >= Max_Diagnostic_Fields then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      if Key'Length > Key_Limit or else Value'Length > Value_Limit then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Field.Key := To_Unbounded_String (Key);
      Field.Value := To_Unbounded_String (Value);
      Field.Redacted := Redacted;
      Item.Fields.Append (Field);
      Result := A11y.Results.Ok;
   end Add_Field;

   function Has_Field
     (Item : Diagnostic;
      Key  : String)
      return Boolean
   is
   begin
      if Key'Length = 0 then
         return False;
      end if;

      for Field of Item.Fields loop
         if To_String (Field.Key) = Key then
            return True;
         end if;
      end loop;

      return False;
   end Has_Field;

   function Has_Field
     (Item  : Diagnostic;
      Key   : String;
      Value : String)
      return Boolean
   is
   begin
      if Key'Length = 0 then
         return False;
      end if;

      for Field of Item.Fields loop
         if To_String (Field.Key) = Key
           and then To_String (Field.Value) = Value
         then
            return True;
         end if;
      end loop;

      return False;
   end Has_Field;

   function Same_Diagnostic (Left, Right : Diagnostic) return Boolean is
     (To_String (Left.Identifier) = To_String (Right.Identifier)
      and then To_String (Left.Feature) = To_String (Right.Feature)
      and then Left.Class = Right.Class
      and then Left.Node = Right.Node);

   function Field_Exceeds
     (Field : Diagnostic_Field;
      Key_Limit : Natural;
      Value_Limit : Natural)
      return Boolean is
     (Length (Field.Key) = 0
      or else Length (Field.Key) > Key_Limit
      or else Length (Field.Value) > Value_Limit)
   with SPARK_Mode => On;

   procedure Append
     (Self   : in out Diagnostic_Log;
      Item   : Diagnostic;
      Result : out A11y.Results.Result)
   is
      Identifier_Length : constant Natural := Length (Item.Identifier);
      Feature_Length    : constant Natural := Length (Item.Feature);
      Identifier_Limit : constant Natural :=
        Effective_Limit
          (Max_Diagnostic_Identifier_Length,
           A11y.Resource_Limits.Limit_Value (Self.String_Limit));
      Feature_Limit : constant Natural :=
        Effective_Limit
          (Max_Diagnostic_Feature_Length,
           A11y.Resource_Limits.Limit_Value (Self.String_Limit));
      Key_Limit : constant Natural :=
        Effective_Limit
          (Max_Diagnostic_Key_Length,
           A11y.Resource_Limits.Limit_Value (Self.String_Limit));
      Value_Limit : constant Natural :=
        Effective_Limit
          (Max_Diagnostic_Value_Length,
           A11y.Resource_Limits.Limit_Value (Self.String_Limit));
   begin
      if Identifier_Length = 0 then
         Self.Dropped := Self.Dropped + 1;
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if Identifier_Length > Identifier_Limit
        or else Feature_Length > Feature_Limit
      then
         Self.Dropped := Self.Dropped + 1;
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      if Natural (Item.Fields.Length) > Max_Diagnostic_Fields then
         Self.Dropped := Self.Dropped + 1;
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      for Field of Item.Fields loop
         if Field_Exceeds (Field, Key_Limit, Value_Limit) then
            Self.Dropped := Self.Dropped + 1;
            Result := (Status => A11y.Results.Resource_Limit);
            return;
         end if;
      end loop;

      if not Self.Items.Is_Empty
        and then Same_Diagnostic (Self.Items.Last_Element, Item)
      then
         Self.Dropped := Self.Dropped + 1;
         Result := A11y.Results.Ok;
         return;
      end if;

      if Natural (Self.Items.Length) >= Self.Limit then
         Self.Dropped := Self.Dropped + 1;
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Self.Items.Append (Item);
      Result := A11y.Results.Ok;
   end Append;

   function Count (Self : Diagnostic_Log) return Natural is
     (Natural (Self.Items.Length));

   function Dropped_Count (Self : Diagnostic_Log) return Natural is
     (Self.Dropped);

   function Capacity (Self : Diagnostic_Log) return Natural is
     (Self.Limit);

   procedure Set_Capacity
     (Self     : in out Diagnostic_Log;
      Capacity : Natural;
      Result   : out A11y.Results.Result)
   is
   begin
      if Capacity = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if Capacity < Natural (Self.Items.Length) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Self.Limit := Capacity;
      Result := A11y.Results.Ok;
   end Set_Capacity;

   procedure Configure
     (Self   : in out Diagnostic_Log;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      New_Capacity : Natural;
      New_String_Limit : Natural;
   begin
      if not A11y.Results.Succeeded (Validation) then
         Result := Validation;
         return;
      end if;

      New_Capacity :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Diagnostic_Trace_Size));
      New_String_Limit :=
        Effective_Limit
          (Max_Diagnostic_Value_Length,
           A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Native_String_Size));

      Set_Capacity
        (Self, New_Capacity, Result);
      if A11y.Results.Succeeded (Result) then
         Self.String_Limit := New_String_Limit;
      end if;
   end Configure;

   procedure Can_Configure
     (Self   : Diagnostic_Log;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      New_Capacity : Natural;
   begin
      if not A11y.Results.Succeeded (Validation) then
         Result := Validation;
         return;
      end if;

      New_Capacity :=
        Natural
          (A11y.Resource_Limits.Value
             (Limits, A11y.Resource_Limits.Diagnostic_Trace_Size));
      if New_Capacity = 0 then
         Result := (Status => A11y.Results.Invalid_Argument);
      elsif New_Capacity < Natural (Self.Items.Length) then
         Result := (Status => A11y.Results.Invalid_State);
      else
         Result := A11y.Results.Ok;
      end if;
   end Can_Configure;

   function Snapshot (Self : Diagnostic_Log) return Diagnostic_Vectors.Vector is
     (Self.Items);

   function Last (Self : Diagnostic_Log) return Diagnostic is
     (if Self.Items.Is_Empty
      then
        (Identifier => Null_Unbounded_String,
         Level      => Info,
         Class      => Node_Lifecycle,
         Node       => A11y.Node_Ids.No_Node,
         Sequence   => A11y.No_Event,
         Timestamp  => Ada.Calendar.Clock,
         Feature    => Null_Unbounded_String,
         Fields     => <>,
         Redacted   => True)
      else Self.Items.Last_Element);

end A11y.Diagnostics;
