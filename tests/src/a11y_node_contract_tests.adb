with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with A11y.Capabilities;
with A11y.Geometry;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.States;

with A11ykit_Test_Support;
with A11y_Node_Provider_Fixtures; use A11y_Node_Provider_Fixtures;

package body A11y_Node_Contract_Tests is
   use type A11y.Geometry.Rectangle;
   use type A11y.Geometry.Length;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Properties.Property_Status;
   use type A11y.Results.Status_Code;
   use type A11y.Roles.Role;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run_Contract_Snapshot_Tests is
      Provider : Test_Node_Provider :=
        (Node_Role => A11y.Roles.Button,
         Node_Capabilities => A11y.Capabilities.With_Capability
           (A11y.Capabilities.Empty_Capability_Set,
            A11y.Capabilities.Action),
         others => <>);
      Snapshot : A11y.Nodes.Node_Contract_Snapshot;
      Result : A11y.Results.Result;
   begin
      Snapshot := A11y.Nodes.Contract_Snapshot_Safely
        (Provider, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Role = A11y.Roles.Button
         and then Snapshot.Capabilities (A11y.Capabilities.Action),
         "node provider contract safely returns validated snapshots");

      Provider.Node_Capabilities :=
        A11y.Capabilities.Empty_Capability_Set;
      Snapshot := A11y.Nodes.Contract_Snapshot_Safely
        (Provider, Result);
      Check
        (Result.Status = A11y.Results.Unsupported_Capability
         and then Snapshot.Role = A11y.Roles.Custom
         and then not Snapshot.Capabilities (A11y.Capabilities.Action),
         "node provider contract normalizes invalid snapshots");

      Provider.Node_Capabilities :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set,
           A11y.Capabilities.Action);
      Provider.Raise_On_Query := True;
      Snapshot := A11y.Nodes.Contract_Snapshot_Safely
        (Provider, Result);
      Check
        (Result.Status = A11y.Results.Internal_Error
         and then Snapshot.Role = A11y.Roles.Custom
         and then not Snapshot.Capabilities (A11y.Capabilities.Action),
         "node provider contract contains query exceptions as empty snapshots");
   end Run_Contract_Snapshot_Tests;

   procedure Run_Basic_Snapshot_Tests is
      Provider : Test_Node_Provider :=
        (Node_Name        => To_Unbounded_String ("Open"),
         Node_Description => To_Unbounded_String ("Opens settings"),
         Node_Bounds      =>
           (Origin => (X => 10, Y => 20),
            Extent => (Width => 30, Height => 40)),
         others           => <>);
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Limit_Result : A11y.Results.Result;
      Basic : A11y.Nodes.Node_Basic_Snapshot;
      Result : A11y.Results.Result;
   begin
      Basic := A11y.Nodes.Basic_Snapshot_Safely (Provider, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Basic.Name.Status = A11y.Properties.Present
         and then To_String (Basic.Name.Value) = "Open"
         and then Basic.Description.Status = A11y.Properties.Present
         and then To_String (Basic.Description.Value) = "Opens settings"
         and then Basic.Bounds.Extent.Width = 30,
         "node provider basics safely return bounded snapshots");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_String_Size,
         4,
         Limit_Result);
      Basic := A11y.Nodes.Basic_Snapshot_Safely
        (Provider, Limits, Result);
      Check
        (A11y.Results.Succeeded (Limit_Result)
         and then Result.Status = A11y.Results.Resource_Limit
         and then Basic.Description.Status =
           A11y.Properties.Resource_Limited
         and then Basic.Bounds = A11y.Geometry.Empty_Rectangle,
         "node provider basics enforce native string limits");

      Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
      Basic := A11y.Nodes.Basic_Snapshot_Safely
        (Provider, Limits, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then Basic.Name.Status = A11y.Properties.Error
         and then Basic.Description.Status = A11y.Properties.Error,
         "node provider basics validate resource-limit configs");

      Provider.Raise_On_Query := True;
      Basic := A11y.Nodes.Basic_Snapshot_Safely (Provider, Result);
      Check
        (Result.Status = A11y.Results.Internal_Error
         and then Basic.Name.Status = A11y.Properties.Error
         and then Basic.Description.Status = A11y.Properties.Error
         and then Basic.Bounds = A11y.Geometry.Empty_Rectangle,
         "node provider basics contain query exceptions as empty snapshots");

      Provider.Raise_On_Query := False;
      Provider.Node_Name :=
        To_Unbounded_String
          (String'
             (1 .. Natural
               (A11y.Resource_Limits.Value
                  (A11y.Resource_Limits.Default_Config,
                   A11y.Resource_Limits.Native_String_Size)) + 1 => 'x'));
      declare
         Bounds : constant A11y.Geometry.Rectangle :=
           A11y.Nodes.Bounds_Safely (Provider, Result);
      begin
         Check
           (A11y.Results.Succeeded (Result)
            and then Bounds.Extent.Width = 30,
            "node provider bounds safely ignores unrelated text limits");
      end;

      Provider.Raise_On_Query := True;
      declare
         Bounds : constant A11y.Geometry.Rectangle :=
           A11y.Nodes.Bounds_Safely (Provider, Result);
      begin
         Check
           (Result.Status = A11y.Results.Internal_Error
            and then Bounds = A11y.Geometry.Empty_Rectangle,
            "node provider bounds contains geometry query exceptions");
      end;

      Provider.Raise_On_Query := False;
      Provider.Node_Role := A11y.Roles.Text_Field;
      Provider.Node_Capabilities :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set,
           A11y.Capabilities.Text);
      Provider.Node_Value_Text := To_Unbounded_String ("42%");
      Provider.Node_Protected_Value_Text :=
        A11y.Properties.Present (False);
      declare
         Value : constant A11y.Properties.String_Property :=
           A11y.Nodes.Value_Text_Safely (Provider, Result);
      begin
         Check
           (A11y.Results.Succeeded (Result)
            and then Value.Status = A11y.Properties.Present
            and then To_String (Value.Value) = "42%",
            "node provider value text safely applies provider privacy policy");
      end;

      Provider.Node_Role := A11y.Roles.Password_Field;
      Provider.Node_Value_Text := To_Unbounded_String ("secret");
      Provider.Node_Protected_Value_Text :=
        A11y.Properties.Present (False);
      declare
         Value : constant A11y.Properties.String_Property :=
           A11y.Nodes.Value_Text_Safely (Provider, Result);
      begin
         Check
           (Result.Status = A11y.Results.Permission_Denied
            and then Value.Status = A11y.Properties.Permission_Denied
            and then Length (Value.Value) = 0,
            "node provider value text denies password text before textual queries");
      end;

      Provider.Node_Role := A11y.Roles.Text_Field;
      Provider.Node_Protected_Value_Text :=
        (Status => A11y.Properties.Temporarily_Unavailable,
         Value  => False);
      declare
         Value : constant A11y.Properties.String_Property :=
           A11y.Nodes.Value_Text_Safely (Provider, Result);
      begin
         Check
           (Result.Status = A11y.Results.Busy
            and then Value.Status =
              A11y.Properties.Temporarily_Unavailable
            and then Length (Value.Value) = 0,
            "node provider value text fails closed when privacy policy is unavailable");
      end;

      Provider.Node_Role := A11y.Roles.Button;
      Provider.Node_Capabilities := A11y.Capabilities.Empty_Capability_Set;
      Provider.Node_Protected_Value_Text :=
        A11y.Properties.Present (False);
      declare
         Value : constant A11y.Properties.String_Property :=
           A11y.Nodes.Value_Text_Safely (Provider, Result);
      begin
         Check
           (Result.Status = A11y.Results.Unsupported_Capability
            and then Value.Status = A11y.Properties.Unsupported
            and then Length (Value.Value) = 0,
            "node provider value text rejects invalid provider contracts");
      end;
   end Run_Basic_Snapshot_Tests;

   procedure Run_Tree_Snapshot_Tests is
      Provider : Test_Node_Provider :=
        (Parent_Node => A11y.Node_Ids.From_Natural (10),
         Child_Node  => A11y.Node_Ids.From_Natural (11),
         Child_Total => 1,
         others      => <>);
      Tree : A11y.Nodes.Node_Tree_Snapshot;
      Child : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
   begin
      Tree := A11y.Nodes.Tree_Snapshot_Safely (Provider, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Tree.Parent = A11y.Node_Ids.From_Natural (10)
         and then Tree.Child_Count = 1,
         "node provider tree safely returns lazy parent and child-count snapshots");

      Child := A11y.Nodes.Child_At_Safely (Provider, 1, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Child = A11y.Node_Ids.From_Natural (11),
         "node provider tree safely resolves indexed children lazily");

      Child := A11y.Nodes.Child_At_Safely (Provider, 2, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Range
         and then Child = A11y.Node_Ids.No_Node,
         "node provider tree rejects out-of-range child snapshots");

      Provider.Parent_Node := A11y.Node_Ids.From_Natural
        (A11y.Node_Ids.Max_Node_Ids + 1);
      Tree := A11y.Nodes.Tree_Snapshot_Safely (Provider, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Tree.Parent = A11y.Node_Ids.No_Node
         and then Tree.Child_Count = 0,
         "node provider tree rejects invalid parent snapshots");

      Provider.Parent_Node := A11y.Node_Ids.From_Natural (10);
      Provider.Child_Node := A11y.Node_Ids.No_Node;
      Child := A11y.Nodes.Child_At_Safely (Provider, 1, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then Child = A11y.Node_Ids.No_Node,
         "node provider tree rejects invalid child snapshots");

      Provider.Child_Node := A11y.Node_Ids.From_Natural (11);
      Provider.Raise_On_Query := True;
      Tree := A11y.Nodes.Tree_Snapshot_Safely (Provider, Result);
      Check
        (Result.Status = A11y.Results.Internal_Error
         and then Tree.Parent = A11y.Node_Ids.No_Node
         and then Tree.Child_Count = 0,
         "node provider tree contains parent and count query exceptions");

      Child := A11y.Nodes.Child_At_Safely (Provider, 1, Result);
      Check
        (Result.Status = A11y.Results.Internal_Error
         and then Child = A11y.Node_Ids.No_Node,
         "node provider tree contains indexed child query exceptions");
   end Run_Tree_Snapshot_Tests;

   procedure Run_Contract_Validation_Tests is
      Empty_States : constant A11y.States.State_Set :=
        A11y.States.Empty_State_Set;
      Showing_States : constant A11y.States.State_Set :=
        A11y.States.With_State
          (A11y.States.Empty_State_Set, A11y.States.Showing);
      Multi_Select_States : constant A11y.States.State_Set :=
        A11y.States.With_State
          (A11y.States.With_State
             (A11y.States.Empty_State_Set, A11y.States.Selectable),
           A11y.States.Multi_Selectable);
      Focused_States : constant A11y.States.State_Set :=
        A11y.States.With_State
          (A11y.States.Empty_State_Set, A11y.States.Focused);
      Selected_States : constant A11y.States.State_Set :=
        A11y.States.With_State
          (A11y.States.With_State
             (A11y.States.Empty_State_Set, A11y.States.Selectable),
           A11y.States.Selected);
      Selection_Caps : constant A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set,
           A11y.Capabilities.Selection);
      Action_Caps : constant A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set,
           A11y.Capabilities.Action);
      Text_Caps : constant A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set,
           A11y.Capabilities.Text);
      Table_Selection_Caps : constant A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.With_Capability
             (A11y.Capabilities.Empty_Capability_Set,
              A11y.Capabilities.Table),
           A11y.Capabilities.Selection);
      Image_Caps : constant A11y.Capabilities.Capability_Set :=
        A11y.Capabilities.With_Capability
          (A11y.Capabilities.Empty_Capability_Set,
           A11y.Capabilities.Image);
   begin
      Check
        (A11y.Results.Succeeded
           (A11y.Nodes.Validate_Contract
              (A11y.Roles.Button,
               Empty_States,
               Action_Caps,
               A11y.Nodes.Expose_Node))
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Button,
            Empty_States,
            A11y.Capabilities.Empty_Capability_Set,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Unsupported_Capability
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Text_Field,
            Empty_States,
            Text_Caps,
            A11y.Nodes.Expose_Node).Status = A11y.Results.Success
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Text_Field,
            Focused_States,
            Text_Caps,
            A11y.Nodes.Expose_Node).Status = A11y.Results.Success,
         "node provider contract validates role capability requirements");

      Check
        (A11y.Nodes.Validate_Contract
           (A11y.Roles.Text_Field,
            Empty_States,
            A11y.Capabilities.With_Capability
              (A11y.Capabilities.Empty_Capability_Set,
               A11y.Capabilities.Editable_Text),
            A11y.Nodes.Expose_Node).Status = A11y.Results.Invalid_State
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Text_Field,
            A11y.States.With_State
              (A11y.States.Empty_State_Set, A11y.States.Editable),
            Text_Caps,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Invalid_State,
         "node provider contract validates editable text invariants");

      Check
        (A11y.Nodes.Validate_Contract
           (A11y.Roles.Group,
            Showing_States,
            A11y.Capabilities.Empty_Capability_Set,
            A11y.Nodes.Hide_Node_And_Subtree).Status =
              A11y.Results.Invalid_State
         and then A11y.Results.Succeeded
           (A11y.Nodes.Validate_Contract
              (A11y.Roles.Table,
               Multi_Select_States,
               Table_Selection_Caps,
               A11y.Nodes.Expose_Node))
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Button,
            Multi_Select_States,
            Action_Caps,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Invalid_State
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.List,
            Multi_Select_States,
            A11y.Capabilities.Empty_Capability_Set,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Unsupported_Capability
         and then A11y.Results.Succeeded
           (A11y.Nodes.Validate_Contract
              (A11y.Roles.List_Item,
               Selected_States,
               Selection_Caps,
               A11y.Nodes.Expose_Node))
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Button,
            Selected_States,
            Action_Caps,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Invalid_State
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Table,
            Empty_States,
            A11y.Capabilities.Empty_Capability_Set,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Unsupported_Capability
         and then A11y.Nodes.Validate_Contract
           (A11y.Roles.Window,
            Empty_States,
            A11y.Capabilities.Empty_Capability_Set,
            A11y.Nodes.Expose_Node).Status =
              A11y.Results.Unsupported_Capability
         and then A11y.Results.Succeeded
           (A11y.Nodes.Validate_Contract
              (A11y.Roles.Image,
               Empty_States,
               Image_Caps,
               A11y.Nodes.Expose_Node)),
         "node provider contract validates exposure and structural capability rules");
   end Run_Contract_Validation_Tests;

   procedure Run is
   begin
      Run_Contract_Snapshot_Tests;
      Run_Basic_Snapshot_Tests;
      Run_Tree_Snapshot_Tests;
      Run_Contract_Validation_Tests;
   end Run;
end A11y_Node_Contract_Tests;
