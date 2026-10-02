with Ada.Strings.Unbounded;

package body A11y.Nodes is
   use Ada.Strings.Unbounded;
   use type A11y.Node_Ids.Node_Id;

   Created_Name                 : aliased constant String := "created";
   Attached_Name                : aliased constant String := "attached";
   Active_Name                  : aliased constant String := "active";
   Removing_Name                : aliased constant String := "removing";
   Defunct_Name                 : aliased constant String := "defunct";
   Removed_Name                 : aliased constant String := "removed";

   Expose_Node_Name             : aliased constant String := "expose-node";
   Flatten_Node_Name            : aliased constant String := "flatten-node";
   Hide_Node_And_Subtree_Name   : aliased constant String :=
     "hide-node-and-subtree";
   Expose_Descendants_Only_Name : aliased constant String :=
     "expose-descendants-only";

   function Metadata (State : Lifecycle_State) return Lifecycle_Metadata is
     (case State is
        when Created =>
          (Stable_Name => Created_Name'Access,
           Externally_Live => Is_Externally_Live (Created),
           Provider_Access => Allows_Provider_Access (Created)),
        when Attached =>
          (Stable_Name => Attached_Name'Access,
           Externally_Live => Is_Externally_Live (Attached),
           Provider_Access => Allows_Provider_Access (Attached)),
        when Active =>
          (Stable_Name => Active_Name'Access,
           Externally_Live => Is_Externally_Live (Active),
           Provider_Access => Allows_Provider_Access (Active)),
        when Removing =>
          (Stable_Name => Removing_Name'Access,
           Externally_Live => Is_Externally_Live (Removing),
           Provider_Access => Allows_Provider_Access (Removing)),
        when Defunct =>
          (Stable_Name => Defunct_Name'Access,
           Externally_Live => Is_Externally_Live (Defunct),
           Provider_Access => Allows_Provider_Access (Defunct)),
        when Removed =>
          (Stable_Name => Removed_Name'Access,
           Externally_Live => Is_Externally_Live (Removed),
           Provider_Access => Allows_Provider_Access (Removed)));

   function Stable_Name (State : Lifecycle_State) return String is
     (Metadata (State).Stable_Name.all);

   function Is_Externally_Live
     (State : Lifecycle_State)
      return Boolean is
     (State = Active)
   with SPARK_Mode => On;

   function Allows_Provider_Access
     (State : Lifecycle_State)
      return Boolean is
     (State in Created | Attached | Active)
   with SPARK_Mode => On;

   function Is_Final
     (State : Lifecycle_State)
      return Boolean is
     (State in Defunct | Removed)
   with SPARK_Mode => On;

   function Can_Transition
     (From_State : Lifecycle_State;
      To_State   : Lifecycle_State)
      return Boolean is
     (if From_State = To_State then True
      elsif From_State = Created then
        To_State in Attached | Active | Removing | Defunct | Removed
      elsif From_State = Attached then
        To_State in Active | Removing | Defunct | Removed
      elsif From_State = Active then
        To_State in Attached | Removing | Defunct | Removed
      elsif From_State = Removing then
        To_State in Defunct | Removed
      else False)
   with SPARK_Mode => On;

   function Validate_Transition
     (From_State : Lifecycle_State;
      To_State   : Lifecycle_State)
      return A11y.Results.Result is
   begin
      if Can_Transition (From_State, To_State) then
         return A11y.Results.Ok;
      end if;

      return (Status => A11y.Results.Invalid_State);
   end Validate_Transition;

   function Metadata (Policy : Exposure_Policy) return Exposure_Metadata is
     (case Policy is
        when Expose_Node =>
          (Stable_Name => Expose_Node_Name'Access,
           Exposes_Node => Exposes_Node (Expose_Node),
           Exposes_Descendants => Exposes_Descendants (Expose_Node)),
        when Flatten_Node =>
          (Stable_Name => Flatten_Node_Name'Access,
           Exposes_Node => Exposes_Node (Flatten_Node),
           Exposes_Descendants => Exposes_Descendants (Flatten_Node)),
        when Hide_Node_And_Subtree =>
          (Stable_Name => Hide_Node_And_Subtree_Name'Access,
           Exposes_Node => Exposes_Node (Hide_Node_And_Subtree),
           Exposes_Descendants => Exposes_Descendants
             (Hide_Node_And_Subtree)),
        when Expose_Descendants_Only =>
          (Stable_Name => Expose_Descendants_Only_Name'Access,
           Exposes_Node => Exposes_Node (Expose_Descendants_Only),
           Exposes_Descendants => Exposes_Descendants
             (Expose_Descendants_Only)));

   function Stable_Name (Policy : Exposure_Policy) return String is
     (Metadata (Policy).Stable_Name.all);

   function Exposes_Node
     (Policy : Exposure_Policy)
      return Boolean is
     (Policy = Expose_Node)
   with SPARK_Mode => On;

   function Exposes_Descendants
     (Policy : Exposure_Policy)
      return Boolean is
     (Policy in Expose_Node | Flatten_Node | Expose_Descendants_Only)
   with SPARK_Mode => On;

   function Hides_Subtree
     (Policy : Exposure_Policy)
      return Boolean is
     (Policy = Hide_Node_And_Subtree)
   with SPARK_Mode => On;

   function Protected_Value_Query_Status
     (Role              : A11y.Roles.Role;
      Protection_Status : A11y.Properties.Property_Status;
      Protection_Value  : Boolean)
      return A11y.Properties.Property_Status is
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
        Protection_Status)
   with SPARK_Mode => On;

   function Has
     (Set  : A11y.Capabilities.Capability_Set;
      Item : A11y.Capabilities.Capability)
      return Boolean is
     (Set (Item));

   function Validate_Contract
     (Role         : A11y.Roles.Role;
      States       : A11y.States.State_Set;
      Capabilities : A11y.Capabilities.Capability_Set;
      Exposure     : Exposure_Policy)
      return A11y.Results.Result
   is
      Effective_States : constant A11y.States.State_Set :=
        A11y.States.Derive (States, Role, Capabilities);
      State_Result : constant A11y.Results.Result :=
        A11y.States.Validate (Effective_States);
   begin
      if not A11y.Results.Succeeded (State_Result) then
         return State_Result;
      end if;

      if Exposure = Hide_Node_And_Subtree
        and then (Effective_States (A11y.States.Showing)
                  or else Effective_States (A11y.States.Focused)
                  or else Effective_States (A11y.States.Active))
      then
         return (Status => A11y.Results.Invalid_State);
      end if;

      if Has (Capabilities, A11y.Capabilities.Editable_Text)
        and then not Has (Capabilities, A11y.Capabilities.Text)
      then
         return (Status => A11y.Results.Invalid_State);
      end if;

      if Effective_States (A11y.States.Editable)
        and then not Has (Capabilities, A11y.Capabilities.Editable_Text)
      then
         return (Status => A11y.Results.Unsupported_Capability);
      end if;

      if Effective_States (A11y.States.Multi_Selectable) then
         if not A11y.Roles.Is_Selection_Container (Role) then
            return (Status => A11y.Results.Invalid_State);
         elsif not Has (Capabilities, A11y.Capabilities.Selection) then
            return (Status => A11y.Results.Unsupported_Capability);
         end if;
      end if;

      if Effective_States (A11y.States.Selected)
        and then not A11y.Roles.Is_Selectable_Item (Role)
      then
         return (Status => A11y.Results.Invalid_State);
      end if;

      if Effective_States (A11y.States.Selectable)
        and then not A11y.Roles.Is_Selectable_Item (Role)
        and then not A11y.Roles.Is_Selection_Container (Role)
      then
         return (Status => A11y.Results.Invalid_State);
      end if;

      case Role is
         when A11y.Roles.Button |
              A11y.Roles.Toggle_Button |
              A11y.Roles.Check_Box |
              A11y.Roles.Radio_Button |
              A11y.Roles.Combo_Box |
              A11y.Roles.Menu_Item |
              A11y.Roles.Tab |
              A11y.Roles.Link =>
            if not Has (Capabilities, A11y.Capabilities.Action) then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when A11y.Roles.Text_Field |
              A11y.Roles.Search_Field |
              A11y.Roles.Password_Field =>
            if not Has (Capabilities, A11y.Capabilities.Text) then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when A11y.Roles.Slider |
              A11y.Roles.Spin_Button |
              A11y.Roles.Progress_Bar |
              A11y.Roles.Scroll_Bar =>
            if not Has (Capabilities, A11y.Capabilities.Value) then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when A11y.Roles.List |
              A11y.Roles.Tree |
              A11y.Roles.Table |
              A11y.Roles.Tab_List =>
            if Role = A11y.Roles.Table
              and then not Has (Capabilities, A11y.Capabilities.Table)
            then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when A11y.Roles.Document =>
            if not Has (Capabilities, A11y.Capabilities.Document) then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when A11y.Roles.Image =>
            if not Has (Capabilities, A11y.Capabilities.Image) then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when A11y.Roles.Window |
              A11y.Roles.Dialog |
              A11y.Roles.Alert |
              A11y.Roles.Tooltip =>
            if not Has (Capabilities, A11y.Capabilities.Surface) then
               return (Status => A11y.Results.Unsupported_Capability);
            end if;

         when others =>
            null;
      end case;

      return A11y.Results.Ok;
   end Validate_Contract;

   function Contract_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return Node_Contract_Snapshot
   is
      Snapshot : Node_Contract_Snapshot;
   begin
      Snapshot.Role := Role (Self);
      Snapshot.States := States (Self);
      Snapshot.Capabilities := Capabilities (Self);
      Snapshot.Exposure := Exposure (Self);
      Result :=
        Validate_Contract
          (Role         => Snapshot.Role,
           States       => Snapshot.States,
           Capabilities => Snapshot.Capabilities,
           Exposure     => Snapshot.Exposure);
      if A11y.Results.Failed (Result) then
         return
           (Role         => A11y.Roles.Custom,
            States       => A11y.States.Empty_State_Set,
            Capabilities => A11y.Capabilities.Empty_Capability_Set,
            Exposure     => Expose_Node);
      end if;

      return Snapshot;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Role         => A11y.Roles.Custom,
            States       => A11y.States.Empty_State_Set,
            Capabilities => A11y.Capabilities.Empty_Capability_Set,
            Exposure     => Expose_Node);
   end Contract_Snapshot_Safely;

   procedure Enforce_String_Property_Limit
     (Item   : in out A11y.Properties.String_Property;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
   begin
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if Item.Status in A11y.Properties.Present | A11y.Properties.Empty
        and then A11y.Resource_Limits.Exceeded
          (Limits,
           A11y.Resource_Limits.Native_String_Size,
           Length (Item.Value))
      then
         Result := (Status => A11y.Results.Resource_Limit);
         Item :=
           (Status => A11y.Properties.Resource_Limited,
            Value  => <>);
      end if;
   end Enforce_String_Property_Limit;

   function Basic_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return Node_Basic_Snapshot
   is
      Validation : constant A11y.Results.Result :=
        A11y.Resource_Limits.Validate (Limits);
      Snapshot : Node_Basic_Snapshot;
   begin
      if A11y.Results.Failed (Validation) then
         Result := Validation;
         return
           (Name        =>
              (Status => A11y.Properties.Status_From_Result
                 (Validation.Status),
               Value => <>),
            Description =>
              (Status => A11y.Properties.Status_From_Result
                 (Validation.Status),
               Value => <>),
            Bounds      => A11y.Geometry.Empty_Rectangle);
      end if;

      Snapshot.Name := Name (Self);
      Snapshot.Description := Description (Self);
      Snapshot.Bounds := Bounds (Self);
      Result := A11y.Results.Ok;

      Enforce_String_Property_Limit (Snapshot.Name, Limits, Result);
      Enforce_String_Property_Limit (Snapshot.Description, Limits, Result);
      if A11y.Results.Failed (Result) then
         Snapshot.Bounds := A11y.Geometry.Empty_Rectangle;
      end if;

      return Snapshot;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return
           (Name        => (Status => A11y.Properties.Error, Value => <>),
            Description => (Status => A11y.Properties.Error, Value => <>),
            Bounds      => A11y.Geometry.Empty_Rectangle);
   end Basic_Snapshot_Safely;

   function Basic_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return Node_Basic_Snapshot is
     (Basic_Snapshot_Safely
        (Self, A11y.Resource_Limits.Default_Config, Result));

   function Bounds_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return A11y.Geometry.Rectangle
   is
   begin
      Result := A11y.Results.Ok;
      return Bounds (Self);
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Geometry.Empty_Rectangle;
   end Bounds_Safely;

   function Result_From_Property_Status
     (Status : A11y.Properties.Property_Status)
      return A11y.Results.Result is
     (Status =>
        (case Status is
           when A11y.Properties.Present |
                A11y.Properties.Empty |
                A11y.Properties.Unsupported =>
              A11y.Results.Success,
           when A11y.Properties.Temporarily_Unavailable =>
              A11y.Results.Busy,
           when A11y.Properties.Node_Unavailable =>
              A11y.Results.Node_Unavailable,
           when A11y.Properties.Resource_Limited =>
              A11y.Results.Resource_Limit,
           when A11y.Properties.Permission_Denied =>
              A11y.Results.Permission_Denied,
           when A11y.Properties.Error =>
              A11y.Results.Internal_Error))
   with SPARK_Mode => On;

   function Protected_Value_Query_Status
     (Self : Accessible_Node'Class;
      Role : A11y.Roles.Role)
      return A11y.Properties.Property_Status
   is
      Protection : A11y.Properties.Boolean_Property;
   begin
      if Role = A11y.Roles.Password_Field then
         return A11y.Nodes.Protected_Value_Query_Status
           (Role,
            A11y.Properties.Unsupported,
            False);
      elsif Self in A11y.Properties.Privacy_Property_Provider'Class then
         Protection :=
           A11y.Properties.Protected_Value_Text
             (A11y.Properties.Privacy_Property_Provider'Class (Self));
         return A11y.Nodes.Protected_Value_Query_Status
           (Role,
            Protection.Status,
            (if Protection.Status = A11y.Properties.Present then
               Protection.Value
             else
               False));
      end if;

      return A11y.Nodes.Protected_Value_Query_Status
        (Role,
         A11y.Properties.Unsupported,
         False);
   exception
      when others =>
         return A11y.Properties.Error;
   end Protected_Value_Query_Status;

   function Value_Text_Safely
     (Self   : Accessible_Node'Class;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
      return A11y.Properties.String_Property
   is
      Protection : A11y.Properties.Property_Status;
      Contract_Result : A11y.Results.Result;
      Snapshot : constant Node_Contract_Snapshot :=
        Contract_Snapshot_Safely (Self, Contract_Result);
   begin
      if A11y.Results.Failed (Contract_Result) then
         Result := Contract_Result;
         return
           (Status => A11y.Properties.Status_From_Result
              (Contract_Result.Status),
            Value  => <>);
      end if;

      Protection := Protected_Value_Query_Status (Self, Snapshot.Role);
      if Protection /= A11y.Properties.Present then
         Result := Result_From_Property_Status (Protection);
         return (Status => Protection, Value => <>);
      elsif Self in A11y.Properties.Textual_Property_Provider'Class then
         declare
            Value : constant A11y.Properties.String_Property :=
              A11y.Properties.Textual_Property_Safely
                (A11y.Properties.Textual_Property_Provider'Class (Self),
                 A11y.Properties.Value_Text,
                 Limits);
         begin
            Result := Result_From_Property_Status (Value.Status);
            return Value;
         end;
      else
         Result := A11y.Results.Ok;
         return (Status => A11y.Properties.Unsupported, Value => <>);
      end if;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Status => A11y.Properties.Error, Value => <>);
   end Value_Text_Safely;

   function Value_Text_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return A11y.Properties.String_Property is
     (Value_Text_Safely
        (Self, A11y.Resource_Limits.Default_Config, Result));

   function Tree_Snapshot_Safely
     (Self   : Accessible_Node'Class;
      Result : out A11y.Results.Result)
      return Node_Tree_Snapshot
   is
      Snapshot : Node_Tree_Snapshot;
   begin
      Snapshot.Parent := Parent (Self);
      Snapshot.Child_Count := Child_Count (Self);
      if Snapshot.Parent /= A11y.Node_Ids.No_Node
        and then not A11y.Node_Ids.Is_Valid (Snapshot.Parent)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return (Parent => A11y.Node_Ids.No_Node, Child_Count => 0);
      end if;

      Result := A11y.Results.Ok;
      return Snapshot;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return (Parent => A11y.Node_Ids.No_Node, Child_Count => 0);
   end Tree_Snapshot_Safely;

   function Child_At_Safely
     (Self   : Accessible_Node'Class;
      Index  : Positive;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      Count : Natural;
      Child : A11y.Node_Ids.Node_Id;
   begin
      Count := Child_Count (Self);
      if Index > Count then
         Result := (Status => A11y.Results.Invalid_Range);
         return A11y.Node_Ids.No_Node;
      end if;

      Child := Child_At (Self, Index);
      if not A11y.Node_Ids.Is_Valid (Child) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return A11y.Node_Ids.No_Node;
      end if;

      Result := A11y.Results.Ok;
      return Child;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
         return A11y.Node_Ids.No_Node;
   end Child_At_Safely;

end A11y.Nodes;
