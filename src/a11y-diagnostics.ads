with Ada.Calendar;
with Ada.Containers.Vectors;
with Ada.Strings.Unbounded;

with A11y.Node_Ids;
with A11y.Resource_Limits;
with A11y.Results;

package A11y.Diagnostics is

   Max_Diagnostics : constant Natural := 1_024;
   Max_Diagnostic_Identifier_Length : constant Natural := 256;
   Max_Diagnostic_Feature_Length : constant Natural := 256;
   Max_Diagnostic_Fields : constant Natural := 16;
   Max_Diagnostic_Key_Length : constant Natural := 256;
   Max_Diagnostic_Value_Length : constant Natural := 4_096;

   type Severity is (Trace, Info, Warning, Error, Fatal);

   type Category is
     (Backend_Initialization,
      Native_Runtime_Connection,
      Native_Registration,
      Node_Lifecycle,
      Provider_Timeout,
      Mapping_Fallback,
      Unsupported_Capability,
      Resource_Limit,
      Event_Overflow,
      Stale_Native_Query,
      Text_Conversion,
      Native_Allocation,
      ABI_Boundary_Failure,
      Reference_Count_Anomaly,
      Autorelease_Anomaly,
      Shutdown_Anomaly,
      Conformance_Failure);

   type Category_Metadata is record
      Stable_Name      : access constant String;
      Default_Severity : Severity := Info;
   end record;

   type Diagnostic_Field is record
      Key      : Ada.Strings.Unbounded.Unbounded_String;
      Value    : Ada.Strings.Unbounded.Unbounded_String;
      Redacted : Boolean := True;
   end record;

   package Diagnostic_Field_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Diagnostic_Field);

   type Diagnostic is record
      Identifier : Ada.Strings.Unbounded.Unbounded_String;
      Level      : Severity := Info;
      Class      : Category := Node_Lifecycle;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Timestamp  : A11y.Timestamp := Ada.Calendar.Clock;
      Feature    : Ada.Strings.Unbounded.Unbounded_String;
      Fields     : Diagnostic_Field_Vectors.Vector;
      Redacted   : Boolean := True;
   end record;

   package Diagnostic_Vectors is new Ada.Containers.Vectors
     (Index_Type => Positive, Element_Type => Diagnostic);

   function Metadata (Class : Category) return Category_Metadata;

   function Stable_Name (Level : Severity) return String;

   function Stable_Name (Class : Category) return String;

   function Default_Severity
     (Class : Category)
      return Severity
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (case Class is
           when Backend_Initialization
              | Node_Lifecycle =>
             Default_Severity'Result = Info,
           when Native_Runtime_Connection
              | Native_Registration
              | Provider_Timeout
              | Mapping_Fallback
              | Resource_Limit
              | Stale_Native_Query
              | Shutdown_Anomaly =>
             Default_Severity'Result = Warning,
           when Unsupported_Capability =>
             Default_Severity'Result = Trace,
           when Event_Overflow
              | Text_Conversion
              | ABI_Boundary_Failure
              | Reference_Count_Anomaly
              | Autorelease_Anomaly
              | Conformance_Failure =>
             Default_Severity'Result = Error,
           when Native_Allocation =>
             Default_Severity'Result = Fatal);

   function Category_For_Status
     (Status : A11y.Results.Status_Code)
      return Category
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (case Status is
           when A11y.Results.Success
              | A11y.Results.Accepted_Asynchronous
              | A11y.Results.Invalid_State
              | A11y.Results.Read_Only
              | A11y.Results.Disabled
              | A11y.Results.Busy
              | A11y.Results.Cancelled
              | A11y.Results.Permission_Denied =>
             Category_For_Status'Result = Node_Lifecycle,
           when A11y.Results.Backend_Unavailable
              | A11y.Results.Accessibility_Service_Unavailable =>
             Category_For_Status'Result = Native_Runtime_Connection,
           when A11y.Results.Node_Unavailable =>
             Category_For_Status'Result = Stale_Native_Query,
           when A11y.Results.Unsupported_Property
              | A11y.Results.Unsupported_Capability
              | A11y.Results.Unsupported_Action =>
             Category_For_Status'Result = Unsupported_Capability,
           when A11y.Results.Invalid_Argument
              | A11y.Results.Invalid_Range
              | A11y.Results.Protocol_Failure
              | A11y.Results.Native_Failure
              | A11y.Results.Internal_Error =>
             Category_For_Status'Result = ABI_Boundary_Failure,
           when A11y.Results.Timed_Out =>
             Category_For_Status'Result = Provider_Timeout,
           when A11y.Results.Shutting_Down =>
             Category_For_Status'Result = Shutdown_Anomaly,
           when A11y.Results.Resource_Limit =>
             Category_For_Status'Result = Resource_Limit,
           when A11y.Results.Out_Of_Resources =>
             Category_For_Status'Result = Native_Allocation);

   function Severity_For_Status
     (Status : A11y.Results.Status_Code)
      return Severity
   with
      SPARK_Mode => On,
      Global => null,
      Post =>
        (if Status in A11y.Results.Success
                    | A11y.Results.Accepted_Asynchronous
         then Severity_For_Status'Result = Trace
         else Severity_For_Status'Result =
              Default_Severity (Category_For_Status (Status)));

   function Is_Reportable
     (Level : Severity)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Reportable'Result = (Level in Warning | Error | Fatal);

   function Is_Native_Boundary_Category
     (Class : Category)
      return Boolean
   with
      SPARK_Mode => On,
      Global => null,
      Post => Is_Native_Boundary_Category'Result =
        (Class in Native_Runtime_Connection | Native_Registration
         | Stale_Native_Query | Native_Allocation | ABI_Boundary_Failure
         | Reference_Count_Anomaly | Autorelease_Anomaly);

   procedure Create
     (Identifier : String;
      Class      : Category;
      Item       : out Diagnostic;
      Result     : out A11y.Results.Result;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Feature    : String := "";
      Level      : Severity := Info;
      Redacted   : Boolean := True);

   procedure Create_For_Status
     (Identifier : String;
      Status     : A11y.Results.Status_Code;
      Item       : out Diagnostic;
      Result     : out A11y.Results.Result;
      Node       : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Sequence   : A11y.Event_Sequence := A11y.No_Event;
      Feature    : String := "";
      Redacted   : Boolean := True);

   procedure Add_Field
     (Item     : in out Diagnostic;
      Key      : String;
      Value    : String;
      Result   : out A11y.Results.Result;
      Redacted : Boolean := True);

   procedure Add_Field
     (Item     : in out Diagnostic;
      Key      : String;
      Value    : String;
      Limits   : A11y.Resource_Limits.Resource_Limit_Config;
      Result   : out A11y.Results.Result;
      Redacted : Boolean := True);

   function Has_Field
     (Item : Diagnostic;
      Key  : String)
      return Boolean;

   function Has_Field
     (Item  : Diagnostic;
      Key   : String;
      Value : String)
      return Boolean;

   type Diagnostic_Log is private;

   procedure Append
     (Self   : in out Diagnostic_Log;
      Item   : Diagnostic;
      Result : out A11y.Results.Result);

   function Count (Self : Diagnostic_Log) return Natural;
   function Dropped_Count (Self : Diagnostic_Log) return Natural;
   function Capacity (Self : Diagnostic_Log) return Natural;

   procedure Set_Capacity
     (Self     : in out Diagnostic_Log;
      Capacity : Natural;
      Result   : out A11y.Results.Result);

   procedure Configure
     (Self   : in out Diagnostic_Log;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   procedure Can_Configure
     (Self   : Diagnostic_Log;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result);

   function Snapshot (Self : Diagnostic_Log) return Diagnostic_Vectors.Vector;
   function Last (Self : Diagnostic_Log) return Diagnostic;

private
   type Diagnostic_Log is record
      Items   : Diagnostic_Vectors.Vector;
      Dropped : Natural := 0;
      Limit   : Natural := Max_Diagnostics;
      String_Limit : Natural := Max_Diagnostic_Value_Length;
   end record;

end A11y.Diagnostics;
