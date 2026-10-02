with Ada.Strings.Unbounded;

with A11y.Geometry;
with A11y.Resource_Limits;
with A11y.Roles;
with A11y.Results;
with A11y.States;

package A11y.Properties is
   pragma SPARK_Mode (On);

   subtype UString is Ada.Strings.Unbounded.Unbounded_String;

   type Property_Status is
     (Present,
      Empty,
      Unsupported,
      Temporarily_Unavailable,
      Node_Unavailable,
      Resource_Limited,
      Permission_Denied,
      Error);

   type Property_Id is
     (Accessible_Name,
      Visible_Title,
      Description,
      Help_Text,
      Placeholder,
      Value_Text,
      Keyboard_Shortcut,
      Semantic_Identifier,
      Locale,
      Bounds,
      Orientation,
      Set_Position,
      Set_Size,
      Hierarchical_Level,
      Heading_Level,
      Landmark,
      Role_Property,
      State_Property);

   type Property_Value_Kind is
     (String_Value,
      Integer_Value,
      Boolean_Value,
      Rectangle_Value,
      Role_Value,
      State_Set_Value);

   type Stable_Name_Access is access constant String;

   type Property_Status_Metadata is record
      Stable_Name      : Stable_Name_Access;
      Available        : Boolean := False;
      Expected_Failure : Boolean := False;
   end record;

   type Property_Value_Kind_Metadata is record
      Stable_Name : Stable_Name_Access;
   end record;

   type Property_Metadata is record
      Stable_Name : Stable_Name_Access;
      Value_Kind  : Property_Value_Kind := String_Value;
   end record;

   function Metadata
     (Status : Property_Status)
      return Property_Status_Metadata
   with
      Global => null,
      Post =>
        Metadata'Result.Available =
          (Status in Present | Empty)
        and then Metadata'Result.Expected_Failure =
          (Status in Unsupported
           | Temporarily_Unavailable
           | Node_Unavailable
           | Resource_Limited
           | Permission_Denied);

   function Stable_Name (Status : Property_Status) return String;

   function Status_From_Result
     (Status : A11y.Results.Status_Code)
      return Property_Status
   with
      Global => null,
      Post =>
        (case Status is
           when A11y.Results.Success =>
             Status_From_Result'Result = Present,
           when A11y.Results.Node_Unavailable =>
             Status_From_Result'Result = Node_Unavailable,
           when A11y.Results.Timed_Out
              | A11y.Results.Cancelled
              | A11y.Results.Busy
              | A11y.Results.Shutting_Down =>
             Status_From_Result'Result = Temporarily_Unavailable,
           when A11y.Results.Unsupported_Property
              | A11y.Results.Unsupported_Capability =>
             Status_From_Result'Result = Unsupported,
           when A11y.Results.Resource_Limit
              | A11y.Results.Out_Of_Resources =>
             Status_From_Result'Result = Resource_Limited,
           when A11y.Results.Permission_Denied =>
             Status_From_Result'Result = Permission_Denied,
           when others =>
             Status_From_Result'Result = Error);

   function Metadata
     (Kind : Property_Value_Kind)
      return Property_Value_Kind_Metadata
   with
      Global => null;

   function Stable_Name (Kind : Property_Value_Kind) return String;

   function Metadata (Id : Property_Id) return Property_Metadata
   with
      Global => null,
      Post =>
        (case Id is
           when Bounds =>
             Metadata'Result.Value_Kind = Rectangle_Value,
           when Set_Position
              | Set_Size
              | Hierarchical_Level
              | Heading_Level =>
             Metadata'Result.Value_Kind = Integer_Value,
           when Role_Property =>
             Metadata'Result.Value_Kind = Role_Value,
           when State_Property =>
             Metadata'Result.Value_Kind = State_Set_Value,
           when others =>
             Metadata'Result.Value_Kind = String_Value);

   function Stable_Name (Id : Property_Id) return String;

   type String_Property is record
      Status : Property_Status := Unsupported;
      Value  : UString;
   end record;

   type Integer_Property is record
      Status : Property_Status := Unsupported;
      Value  : Integer := 0;
   end record;

   type Boolean_Property is record
      Status : Property_Status := Unsupported;
      Value  : Boolean := False;
   end record;

   type Rectangle_Property is record
      Status : Property_Status := Unsupported;
      Value  : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
   end record;

   type Role_Value_Property is record
      Status : Property_Status := Unsupported;
      Value  : A11y.Roles.Role := A11y.Roles.Custom;
   end record;

   type State_Set_Value_Property is record
      Status : Property_Status := Unsupported;
      Value  : A11y.States.State_Set := A11y.States.Empty_State_Set;
   end record;

   type Textual_Property_Provider is limited interface;

   function Visible_Title
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Help_Text
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Placeholder
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Value_Text
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Keyboard_Shortcut
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Semantic_Identifier
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Locale
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Orientation
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Landmark
     (Self : Textual_Property_Provider)
      return String_Property is abstract;

   function Textual_Property_Safely
     (Self   : Textual_Property_Provider'Class;
      Id     : Property_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return String_Property;

   function Textual_Property_Safely
     (Self : Textual_Property_Provider'Class;
      Id   : Property_Id)
      return String_Property;

   type Privacy_Property_Provider is limited interface;

   function Protected_Value_Text
     (Self : Privacy_Property_Provider)
      return Boolean_Property is abstract;

   type Structural_Property_Provider is limited interface;

   function Set_Position
     (Self : Structural_Property_Provider)
      return Integer_Property is abstract;

   function Set_Size
     (Self : Structural_Property_Provider)
      return Integer_Property is abstract;

   function Hierarchical_Level
     (Self : Structural_Property_Provider)
      return Integer_Property is abstract;

   function Heading_Level
     (Self : Structural_Property_Provider)
      return Integer_Property is abstract;

   function Structural_Property_Safely
     (Self : Structural_Property_Provider'Class;
      Id     : Property_Id;
      Limits : A11y.Resource_Limits.Resource_Limit_Config)
      return Integer_Property;

   function Structural_Property_Safely
     (Self : Structural_Property_Provider'Class;
      Id   : Property_Id)
      return Integer_Property;

   function Present (Value : String) return String_Property;
   function Present (Value : Integer) return Integer_Property
   with
      Global => null,
      Post =>
        Present'Result.Status = A11y.Properties.Present
        and then Present'Result.Value = Value;
   function Present (Value : Boolean) return Boolean_Property
   with
      Global => null,
      Post =>
        Present'Result.Status = A11y.Properties.Present
        and then Present'Result.Value = Value;
   function Present
     (Value : A11y.Geometry.Rectangle)
      return Rectangle_Property
   with
      Global => null,
      Post =>
        Present'Result.Status = A11y.Properties.Present
        and then A11y.Geometry."=" (Present'Result.Value, Value);
   function Present (Value : A11y.Roles.Role) return Role_Value_Property
   with
      Global => null,
      Post =>
        Present'Result.Status = A11y.Properties.Present
        and then A11y.Roles."=" (Present'Result.Value, Value);
   function Present
     (Value : A11y.States.State_Set)
      return State_Set_Value_Property
   with
      Global => null,
      Post =>
        Present'Result.Status = A11y.Properties.Present
        and then A11y.States."=" (Present'Result.Value, Value);
   function Empty return String_Property;

end A11y.Properties;
