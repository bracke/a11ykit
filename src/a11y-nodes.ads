with A11y.Capabilities;
with A11y.Geometry;
with A11y.Node_Ids;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.States;

package A11y.Nodes is

   use type A11y.Properties.Property_Status;
   use type A11y.Roles.Role;

   type Lifecycle_State is
     (Created,
      Attached,
      Active,
      Removing,
      Defunct,
      Removed);

   type Exposure_Policy is
     (Expose_Node,
      Flatten_Node,
      Hide_Node_And_Subtree,
      Expose_Descendants_Only);

   type Lifecycle_Metadata is record
      Stable_Name      : access constant String;
      Externally_Live  : Boolean := False;
      Provider_Access  : Boolean := False;
   end record;

   type Exposure_Metadata is record
      Stable_Name         : access constant String;
      Exposes_Node        : Boolean := False;
      Exposes_Descendants : Boolean := False;
   end record;

   function Metadata (State : Lifecycle_State) return Lifecycle_Metadata;

   function Stable_Name (State : Lifecycle_State) return String;

   function Is_Externally_Live
     (State : Lifecycle_State)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Externally_Live'Result = (State = Active);

   function Allows_Provider_Access
     (State : Lifecycle_State)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Allows_Provider_Access'Result =
       (State in Created | Attached | Active);

   function Is_Final
     (State : Lifecycle_State)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Is_Final'Result = (State in Defunct | Removed);

   function Can_Transition
     (From_State : Lifecycle_State;
      To_State   : Lifecycle_State)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Can_Transition'Result =
         (if From_State = To_State then True
          elsif From_State = Created then
            To_State in Attached | Active | Removing | Defunct | Removed
          elsif From_State = Attached then
            To_State in Active | Removing | Defunct | Removed
          elsif From_State = Active then
            To_State in Attached | Removing | Defunct | Removed
          elsif From_State = Removing then
            To_State in Defunct | Removed
          else False);

   function Validate_Transition
     (From_State : Lifecycle_State;
      To_State   : Lifecycle_State)
      return A11y.Results.Result;

   function Metadata (Policy : Exposure_Policy) return Exposure_Metadata;

   function Stable_Name (Policy : Exposure_Policy) return String;

   function Exposes_Node
     (Policy : Exposure_Policy)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Exposes_Node'Result = (Policy = Expose_Node);

   function Exposes_Descendants
     (Policy : Exposure_Policy)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Exposes_Descendants'Result =
       (Policy in Expose_Node | Flatten_Node | Expose_Descendants_Only);

   function Hides_Subtree
     (Policy : Exposure_Policy)
      return Boolean
   with
     SPARK_Mode => On,
     Global => null,
     Post => Hides_Subtree'Result = (Policy = Hide_Node_And_Subtree);

   function Protected_Value_Query_Status
     (Role              : A11y.Roles.Role;
      Protection_Status : A11y.Properties.Property_Status;
      Protection_Value  : Boolean)
      return A11y.Properties.Property_Status
   with
     SPARK_Mode => On,
     Global => null,
     Post =>
       Protected_Value_Query_Status'Result =
         (if Role = A11y.Roles.Password_Field then
            A11y.Properties.Permission_Denied
          elsif Protection_Status = A11y.Properties.Present then
            (if Protection_Value then A11y.Properties.Permission_Denied
             else A11y.Properties.Present)
          elsif Protection_Status in A11y.Properties.Unsupported
                                     | A11y.Properties.Empty
          then
            A11y.Properties.Present
          else
            Protection_Status);

   function Validate_Contract
     (Role         : A11y.Roles.Role;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : Exposure_Policy)
      return A11y.Results.Result;

   type Node_Contract_Snapshot is record
      Role         : A11y.Roles.Role := A11y.Roles.Custom;
      States       : A11y.States.State_Set := A11y.States.Empty_State_Set;
      Capabilities : A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.Empty_Capability_Set;
      Exposure     : Exposure_Policy := Expose_Node;
   end record;

   type Node_Basic_Snapshot is record
      Name        : A11y.Properties.String_Property;
      Description : A11y.Properties.String_Property;
      Bounds      : A11y.Geometry.Rectangle := A11y.Geometry.Empty_Rectangle;
   end record;

   type Node_Tree_Snapshot is record
      Parent      : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Child_Count : Natural := 0;
   end record;

   type Accessible_Node is limited interface;

   function Id
     (Self : Accessible_Node)
      return A11y.Node_Ids.Node_Id is abstract;

   function Role
     (Self : Accessible_Node)
      return A11y.Roles.Role is abstract;

   function States
     (Self : Accessible_Node)
      return A11y.States.State_Set is abstract;

   function Parent
     (Self : Accessible_Node)
      return A11y.Node_Ids.Node_Id is abstract;

   function Child_Count
     (Self : Accessible_Node)
      return Natural is abstract;

   function Child_At
     (Self  : Accessible_Node;
      Index : Positive)
      return A11y.Node_Ids.Node_Id is abstract;

   function Name
     (Self : Accessible_Node)
      return A11y.Properties.String_Property is abstract;

   function Description
     (Self : Accessible_Node)
      return A11y.Properties.String_Property is abstract;

   function Bounds
     (Self : Accessible_Node)
      return A11y.Geometry.Rectangle is abstract;

   function Capabilities
     (Self : Accessible_Node)
      return A11y.Capabilities.Capability_Set is abstract;

   function Exposure
     (Self : Accessible_Node)
      return Exposure_Policy is abstract;

   function Contract_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return Node_Contract_Snapshot;

   function Basic_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Node_Basic_Snapshot;

   function Basic_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return Node_Basic_Snapshot;

   function Bounds_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return A11y.Geometry.Rectangle;

   function Value_Text_Safely
     (Self   : Accessible_Node'Class;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Properties.String_Property;

   function Value_Text_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return A11y.Properties.String_Property;

   function Tree_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return Node_Tree_Snapshot;

   function Child_At_Safely
     (Self   : Accessible_Node'Class;
      Index  : Positive;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id;

end A11y.Nodes;
