with A11y.Backends.Classification;

package body A11y.Backends is

   Created_Name         : aliased constant String := "created";
   Initialized_Name     : aliased constant String := "initialized";
   Running_Name         : aliased constant String := "running";
   Stopping_Name        : aliased constant String := "stopping";
   Stopped_Name         : aliased constant String := "stopped";
   Failed_Name          : aliased constant String := "failed";

   Default_Backend_Name : aliased constant String := "default";
   Native_Name          : aliased constant String := "native";
   Null_Backend_Name    : aliased constant String := "null";
   Disabled_Name        : aliased constant String := "disabled";

   function Metadata (State : Backend_State) return Backend_State_Metadata is
     (case State is
        when Created =>
          (Stable_Name => Created_Name'Access,
           Accepts_Events => Accepts_Events (Created),
           Terminal => Is_Terminal (Created)),
        when Initialized =>
          (Stable_Name => Initialized_Name'Access,
           Accepts_Events => Accepts_Events (Initialized),
           Terminal => Is_Terminal (Initialized)),
        when Running =>
          (Stable_Name => Running_Name'Access,
           Accepts_Events => Accepts_Events (Running),
           Terminal => Is_Terminal (Running)),
        when Stopping =>
          (Stable_Name => Stopping_Name'Access,
           Accepts_Events => Accepts_Events (Stopping),
           Terminal => Is_Terminal (Stopping)),
        when Stopped =>
          (Stable_Name => Stopped_Name'Access,
           Accepts_Events => Accepts_Events (Stopped),
           Terminal => Is_Terminal (Stopped)),
        when Failed =>
          (Stable_Name => Failed_Name'Access,
           Accepts_Events => Accepts_Events (Failed),
           Terminal => Is_Terminal (Failed)));

   function Stable_Name (State : Backend_State) return String is
     (Metadata (State).Stable_Name.all);

   function Metadata (Kind : Backend_Kind) return Backend_Kind_Metadata is
     (case Kind is
        when Default_Backend =>
          (Stable_Name => Default_Backend_Name'Access,
           Native_Transport => Has_Native_Transport (Default_Backend)),
        when Native =>
          (Stable_Name => Native_Name'Access,
           Native_Transport => Has_Native_Transport (Native)),
        when Null_Backend =>
          (Stable_Name => Null_Backend_Name'Access,
           Native_Transport => Has_Native_Transport (Null_Backend)),
        when Disabled =>
          (Stable_Name => Disabled_Name'Access,
           Native_Transport => Has_Native_Transport (Disabled)));

   function Stable_Name (Kind : Backend_Kind) return String is
     (Metadata (Kind).Stable_Name.all);

   function Accepts_Events
     (State : Backend_State)
      return Boolean is
     (A11y.Backends.Classification.Accepts_Events (State))
   with SPARK_Mode => On;

   function Is_Terminal
     (State : Backend_State)
      return Boolean is
     (A11y.Backends.Classification.Is_Terminal (State))
   with SPARK_Mode => On;

   function Can_Initialize
     (State : Backend_State)
      return Boolean is
     (A11y.Backends.Classification.Can_Initialize (State))
   with SPARK_Mode => On;

   function Can_Start
     (State : Backend_State)
      return Boolean is
     (A11y.Backends.Classification.Can_Start (State))
   with SPARK_Mode => On;

   function Can_Stop
     (State : Backend_State)
      return Boolean is
     (A11y.Backends.Classification.Can_Stop (State))
   with SPARK_Mode => On;

   function Has_Native_Transport
     (Kind : Backend_Kind)
      return Boolean is
     (A11y.Backends.Classification.Has_Native_Transport (Kind))
   with SPARK_Mode => On;

   function Constructed_Backend
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Backend_Kind is
     (if Selected = Native and then Native_Target_Supported then
        Native
      elsif Selected = Disabled then
        Disabled
      else
        Null_Backend)
   with SPARK_Mode => On;

   function Requires_Target_Lookup
     (Selected : Backend_Kind)
      return Boolean is
     (Selected = Native)
   with SPARK_Mode => On;

   function Is_Defensive_Fallback
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Boolean is
     (Selected = Native and then not Native_Target_Supported)
   with SPARK_Mode => On;

   function Can_Mutate_Transport
     (Runtime_State : Backend_State)
      return Boolean is
     (Runtime_State in Created | Initialized | Stopped)
   with SPARK_Mode => On;

   function Failure_Status_Allowed
     (Status : A11y.Results.Status_Code)
      return Boolean is
     (Status /= A11y.Results.Success)
   with SPARK_Mode => On;

   function Should_Advance_On_Admission
     (Admitted    : Boolean;
      Last_Status : A11y.Results.Status_Code)
      return Boolean is
     ((not Admitted) or else Last_Status /= A11y.Results.Success)
   with SPARK_Mode => On;

   function Should_Advance_On_Failure
     (Admitted         : Boolean;
      Last_Status      : A11y.Results.Status_Code;
      Requested_Status : A11y.Results.Status_Code)
      return Boolean is
     (Admitted or else Last_Status /= Requested_Status)
   with SPARK_Mode => On;

   function Should_Advance_On_Stop
     (Was_Admitted : Boolean;
      Was_Running  : Boolean;
      Last_Status  : A11y.Results.Status_Code;
      Stop_Status  : A11y.Results.Status_Code)
      return Boolean is
     (Was_Admitted
      or else Was_Running
      or else Last_Status /= Stop_Status)
   with SPARK_Mode => On;

   function Should_Advance_On_Start_Connected
     (Admitted : Boolean)
      return Boolean is
     (Admitted)
   with SPARK_Mode => On;

   function Should_Advance_On_Start_Unavailable
     (Last_Status : A11y.Results.Status_Code)
      return Boolean is
     (Last_Status /= A11y.Results.Backend_Unavailable)
   with SPARK_Mode => On;

   function Can_Prepare_Publication
     (Admitted : Boolean)
      return Boolean is
     (Admitted)
   with SPARK_Mode => On;

   function Should_Advance_On_Publication_Status
     (Last_Status        : A11y.Results.Status_Code;
      Publication_Status : A11y.Results.Status_Code)
      return Boolean is
     (Last_Status /= Publication_Status)
   with SPARK_Mode => On;

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean is
     (After > Before)
   with SPARK_Mode => On;

   function Flag_Changed
     (Before : Boolean;
      After  : Boolean)
      return Boolean is
     (After /= Before)
   with SPARK_Mode => On;

end A11y.Backends;
