with A11y.Diagnostics;
with A11y.Events;
with A11y.Conformance;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Backends is
   use type A11y.Results.Status_Code;

   type Backend_State is
     (Created,
      Initialized,
      Running,
      Stopping,
      Stopped,
      Failed);

   type Backend_Kind is
     (Default_Backend,
      Native,
      Null_Backend,
      Disabled);

   type Backend_State_Metadata is record
      Stable_Name : access constant String;
      Accepts_Events : Boolean := False;
      Terminal : Boolean := False;
   end record;

   type Backend_Kind_Metadata is record
      Stable_Name : access constant String;
      Native_Transport : Boolean := False;
   end record;

   function Metadata (State : Backend_State) return Backend_State_Metadata;

   function Stable_Name (State : Backend_State) return String;

   function Metadata (Kind : Backend_Kind) return Backend_Kind_Metadata;

   function Stable_Name (Kind : Backend_Kind) return String;

   function Accepts_Events
     (State : Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Accepts_Events'Result = (State = Running);

   function Is_Terminal
     (State : Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Terminal'Result = (State in Stopped | Failed);

   function Can_Initialize
     (State : Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Initialize'Result = (State in Created | Stopped);

   function Can_Start
     (State : Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Start'Result = (State in Created | Initialized | Stopped);

   function Can_Stop
     (State : Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Stop'Result = (State not in Stopped | Failed);

   function Has_Native_Transport
     (Kind : Backend_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Has_Native_Transport'Result = (Kind = Native);

   function Constructed_Backend
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Backend_Kind
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Selected = Native and then Native_Target_Supported then
           Constructed_Backend'Result = Native
         elsif Selected = Disabled then
           Constructed_Backend'Result = Disabled
         else
           Constructed_Backend'Result = Null_Backend);

   function Requires_Target_Lookup
     (Selected : Backend_Kind)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Requires_Target_Lookup'Result = (Selected = Native);

   function Is_Defensive_Fallback
     (Selected                : Backend_Kind;
      Native_Target_Supported : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Is_Defensive_Fallback'Result =
          (Selected = Native and then not Native_Target_Supported);

   function Can_Mutate_Transport
     (Runtime_State : Backend_State)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Can_Mutate_Transport'Result =
          (Runtime_State in Created | Initialized | Stopped);

   function Failure_Status_Allowed
     (Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Failure_Status_Allowed'Result = (Status /= A11y.Results.Success);

   function Should_Advance_On_Admission
     (Admitted    : Boolean;
      Last_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Should_Advance_On_Admission'Result =
          ((not Admitted) or else Last_Status /= A11y.Results.Success);

   function Should_Advance_On_Failure
     (Admitted         : Boolean;
      Last_Status      : A11y.Results.Status_Code;
      Requested_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Pre => Failure_Status_Allowed (Requested_Status),
      Post =>
        Should_Advance_On_Failure'Result =
          (Admitted or else Last_Status /= Requested_Status);

   function Should_Advance_On_Stop
     (Was_Admitted : Boolean;
      Was_Running  : Boolean;
      Last_Status  : A11y.Results.Status_Code;
      Stop_Status  : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Should_Advance_On_Stop'Result =
          (Was_Admitted
           or else Was_Running
           or else Last_Status /= Stop_Status);

   function Should_Advance_On_Start_Connected
     (Admitted : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Should_Advance_On_Start_Connected'Result = Admitted;

   function Should_Advance_On_Start_Unavailable
     (Last_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Should_Advance_On_Start_Unavailable'Result =
          (Last_Status /= A11y.Results.Backend_Unavailable);

   function Can_Prepare_Publication
     (Admitted : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Can_Prepare_Publication'Result = Admitted;

   function Should_Advance_On_Publication_Status
     (Last_Status        : A11y.Results.Status_Code;
      Publication_Status : A11y.Results.Status_Code)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        Should_Advance_On_Publication_Status'Result =
          (Last_Status /= Publication_Status);

   function Generation_Changed
     (Before : Natural;
      After  : Natural)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Generation_Changed'Result = (After > Before);

   function Flag_Changed
     (Before : Boolean;
      After  : Boolean)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Flag_Changed'Result = (After /= Before);

   type Backend is limited interface;

   function Name (Self : Backend) return String is abstract;
   function State (Self : Backend) return Backend_State is abstract;

   function Configure_Limits
     (Self   : in out Backend;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return A11y.Results.Result is abstract;

   function Initialize
     (Self : in out Backend)
      return A11y.Results.Result is abstract;

   function Start
     (Self : in out Backend)
      return A11y.Results.Result is abstract;

   function Stop
     (Self : in out Backend)
      return A11y.Results.Result is abstract;

   function Publish
     (Self  : in out Backend;
      Event : A11y.Events.Event)
      return A11y.Results.Result is abstract;

   function Diagnostics
     (Self : Backend)
      return A11y.Diagnostics.Diagnostic_Vectors.Vector is abstract;

   function Support_Declarations
     (Self : Backend)
      return A11y.Conformance.Declaration_Vectors.Vector is abstract;

end A11y.Backends;
