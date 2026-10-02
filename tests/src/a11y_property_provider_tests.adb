with Ada.Strings.Unbounded; use Ada.Strings.Unbounded;

with A11y.Geometry;
with A11y.Properties;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.States;

with A11ykit_Test_Support;
with A11y_Node_Provider_Fixtures; use A11y_Node_Provider_Fixtures;

package body A11y_Property_Provider_Tests is
   use type A11y.Geometry.Coordinate;
   use type A11y.Geometry.Rectangle;
   use type A11y.Properties.Property_Status;
   use type A11y.Properties.Property_Value_Kind;
   use type A11y.Results.Status_Code;
   use type A11y.Roles.Role;
   use type A11y.States.State_Set;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
      Property_Provider : Test_Node_Provider :=
        (Node_Visible_Title => To_Unbounded_String ("Preferences"),
         Node_Set_Position  => A11y.Properties.Present (2),
         others             => <>);
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
      Limit_Result : A11y.Results.Result;
      Property_Result : A11y.Properties.String_Property;
      Integer_Result : A11y.Properties.Integer_Property;
   begin
      Check
        (A11y.Properties.Stable_Name (A11y.Properties.Keyboard_Shortcut)
         = "keyboard-shortcut"
         and then A11y.Properties.Metadata
           (A11y.Properties.Bounds).Value_Kind
           = A11y.Properties.Rectangle_Value
         and then A11y.Properties.Stable_Name (A11y.Properties.Locale)
           = "locale"
         and then A11y.Properties.Metadata
           (A11y.Properties.Heading_Level).Value_Kind
           = A11y.Properties.Integer_Value
         and then A11y.Properties.Stable_Name
           (A11y.Properties.Hierarchical_Level) = "hierarchical-level"
         and then A11y.Properties.Metadata
           (A11y.Properties.Landmark).Value_Kind
           = A11y.Properties.String_Value,
         "property framework exposes stable property metadata");

      Check
        (A11y.Properties.Stable_Name (A11y.Properties.Empty) = "empty"
         and then A11y.Properties.Metadata (A11y.Properties.Empty).Available
         and then not A11y.Properties.Metadata
           (A11y.Properties.Empty).Expected_Failure
         and then A11y.Properties.Stable_Name
           (A11y.Properties.Unsupported) = "unsupported"
         and then A11y.Properties.Metadata
           (A11y.Properties.Unsupported).Expected_Failure
         and then A11y.Properties.Stable_Name
           (A11y.Properties.Resource_Limited) = "resource-limited"
         and then A11y.Properties.Metadata
           (A11y.Properties.Resource_Limited).Expected_Failure
         and then A11y.Properties.Stable_Name
           (A11y.Properties.Permission_Denied) = "permission-denied"
         and then A11y.Properties.Metadata
           (A11y.Properties.Permission_Denied).Expected_Failure,
         "property framework exposes stable status metadata");

      Check
        (A11y.Properties.Status_From_Result (A11y.Results.Success)
         = A11y.Properties.Present
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Node_Unavailable)
           = A11y.Properties.Node_Unavailable
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Timed_Out)
           = A11y.Properties.Temporarily_Unavailable
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Cancelled)
           = A11y.Properties.Temporarily_Unavailable
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Busy)
           = A11y.Properties.Temporarily_Unavailable
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Shutting_Down)
           = A11y.Properties.Temporarily_Unavailable
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Unsupported_Property)
           = A11y.Properties.Unsupported
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Unsupported_Capability)
           = A11y.Properties.Unsupported
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Resource_Limit)
           = A11y.Properties.Resource_Limited
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Out_Of_Resources)
           = A11y.Properties.Resource_Limited
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Permission_Denied)
           = A11y.Properties.Permission_Denied
         and then A11y.Properties.Status_From_Result
           (A11y.Results.Invalid_Argument)
           = A11y.Properties.Error,
         "property framework centrally classifies result statuses");

      Check
        (A11y.Properties.Stable_Name (A11y.Properties.State_Set_Value)
         = "state-set"
         and then A11y.Properties.Stable_Name
           (A11y.Properties.Integer_Value) = "integer"
         and then A11y.Properties.Stable_Name
           (A11y.Properties.Boolean_Value) = "boolean",
         "property framework exposes stable value-kind metadata");

      declare
         Rect : constant A11y.Geometry.Rectangle :=
           (Origin => (X => 7, Y => -3),
            Extent => (Width => 11, Height => 13));
         States : constant A11y.States.State_Set :=
           A11y.States.With_State
             (A11y.States.Empty_State_Set, A11y.States.Focused);
         Integer_Result : constant A11y.Properties.Integer_Property :=
           A11y.Properties.Present (3);
         Boolean_Result : constant A11y.Properties.Boolean_Property :=
           A11y.Properties.Present (True);
         Rectangle_Result : constant A11y.Properties.Rectangle_Property :=
           A11y.Properties.Present (Rect);
         Role_Result : constant A11y.Properties.Role_Value_Property :=
           A11y.Properties.Present (A11y.Roles.Button);
         State_Set_Result :
           constant A11y.Properties.State_Set_Value_Property :=
             A11y.Properties.Present (States);
      begin
         Check
           (Integer_Result.Status = A11y.Properties.Present
            and then Integer_Result.Value = 3
            and then Boolean_Result.Status = A11y.Properties.Present
            and then Boolean_Result.Value
            and then Rectangle_Result.Status = A11y.Properties.Present
            and then Rectangle_Result.Value = Rect
            and then Role_Result.Status = A11y.Properties.Present
            and then Role_Result.Value = A11y.Roles.Button
            and then State_Set_Result.Status = A11y.Properties.Present
            and then State_Set_Result.Value = States,
            "property framework exposes typed present property records");
      end;

      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider, A11y.Properties.Visible_Title);
      Check
        (Property_Result.Status = A11y.Properties.Present
         and then To_String (Property_Result.Value) = "Preferences",
         "textual property provider safely returns bounded strings");

      Property_Provider.Override_Visible_Title := True;
      Property_Provider.Visible_Title_Override :=
        (Status => A11y.Properties.Unsupported,
         Value  => To_Unbounded_String ("must-not-project"));
      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider, A11y.Properties.Visible_Title);
      Check
        (Property_Result.Status = A11y.Properties.Unsupported
         and then Length (Property_Result.Value) = 0,
         "textual property provider clears unavailable string payloads before native projection");

      Property_Provider.Visible_Title_Override :=
        (Status => A11y.Properties.Present,
         Value  => Null_Unbounded_String);
      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider, A11y.Properties.Visible_Title);
      Check
        (Property_Result.Status = A11y.Properties.Empty
         and then Length (Property_Result.Value) = 0,
         "textual property provider normalizes present empty strings before native projection");

      Property_Provider.Override_Visible_Title := False;

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_String_Size,
         3,
         Limit_Result);
      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider,
           A11y.Properties.Visible_Title,
           Limits);
      Check
        (Limit_Result.Status = A11y.Results.Success
         and then Property_Result.Status = A11y.Properties.Resource_Limited
         and then Length (Property_Result.Value) = 0,
         "textual property provider enforces native string limits");

      Limits.Limits (A11y.Resource_Limits.Native_String_Size) := 0;
      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider,
           A11y.Properties.Visible_Title,
           Limits);
      Check
        (Property_Result.Status = A11y.Properties.Error
         and then Length (Property_Result.Value) = 0,
         "textual property provider validates resource-limit configs");

      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider, A11y.Properties.Bounds);
      Check
        (Property_Result.Status = A11y.Properties.Unsupported,
         "textual property provider rejects non-textual property ids");

      Property_Provider.Raise_On_Query := True;
      Property_Result :=
        A11y.Properties.Textual_Property_Safely
          (Property_Provider, A11y.Properties.Visible_Title);
      Check
        (Property_Result.Status = A11y.Properties.Error
         and then Length (Property_Result.Value) = 0,
         "textual property provider contains query exceptions");

      Property_Provider.Raise_On_Query := False;
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider, A11y.Properties.Set_Position);
      Check
        (Integer_Result.Status = A11y.Properties.Present
         and then Integer_Result.Value = 2,
         "structural property provider safely returns structural integers");

      Property_Provider.Node_Set_Position :=
        (Status => A11y.Properties.Unsupported, Value => 7);
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider, A11y.Properties.Set_Position);
      Check
        (Integer_Result.Status = A11y.Properties.Unsupported
         and then Integer_Result.Value = 0,
         "structural property provider clears unavailable integer payloads before native projection");

      Property_Provider.Node_Set_Position :=
        A11y.Properties.Present (-1);
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider, A11y.Properties.Set_Position);
      Check
        (Integer_Result.Status = A11y.Properties.Error
         and then Integer_Result.Value = 0,
         "structural property provider rejects negative structural integers");

      Limits := A11y.Resource_Limits.Default_Config;
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Native_Array_Size,
         1,
         Limit_Result);
      Property_Provider.Node_Set_Position := A11y.Properties.Present (2);
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider,
           A11y.Properties.Set_Position,
           Limits);
      Check
        (Limit_Result.Status = A11y.Results.Success
         and then Integer_Result.Status = A11y.Properties.Resource_Limited
         and then Integer_Result.Value = 0,
         "structural property provider enforces native array limits for set positions");

      Property_Provider.Node_Set_Position := A11y.Properties.Present (1);
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider,
           A11y.Properties.Set_Position,
           Limits);
      Check
        (Integer_Result.Status = A11y.Properties.Present
         and then Integer_Result.Value = 1,
         "structural property provider accepts set positions within native array limits");

      Limits := A11y.Resource_Limits.Default_Config;
      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Traversal_Depth,
         2,
         Limit_Result);
      Property_Provider.Node_Hierarchical_Level :=
        A11y.Properties.Present (3);
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider,
           A11y.Properties.Hierarchical_Level,
           Limits);
      Check
        (Limit_Result.Status = A11y.Results.Success
         and then Integer_Result.Status = A11y.Properties.Resource_Limited
         and then Integer_Result.Value = 0,
         "structural property provider enforces traversal-depth limits for hierarchy levels");

      Limits.Limits (A11y.Resource_Limits.Traversal_Depth) := 0;
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider,
           A11y.Properties.Hierarchical_Level,
           Limits);
      Check
        (Integer_Result.Status = A11y.Properties.Error
         and then Integer_Result.Value = 0,
         "structural property provider validates resource-limit configs");

      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider, A11y.Properties.Visible_Title);
      Check
        (Integer_Result.Status = A11y.Properties.Unsupported,
         "structural property provider rejects non-structural property ids");

      Property_Provider.Raise_On_Query := True;
      Integer_Result :=
        A11y.Properties.Structural_Property_Safely
          (Property_Provider, A11y.Properties.Set_Position);
      Check
        (Integer_Result.Status = A11y.Properties.Error
         and then Integer_Result.Value = 0,
         "structural property provider contains query exceptions");
   end Run;
end A11y_Property_Provider_Tests;
