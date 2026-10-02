with A11y.Backends;
with A11y.Backends.Classification;
with A11y.Capabilities;
with A11y.Nodes;
with A11y.Nodes.Classification;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Roles;
with A11y.States;
with A11y.Text;

with A11ykit_Test_Support;

package body A11y_Framework_Metadata_Tests is
   use type A11y.Backends.Backend_Kind;
   use type A11y.Backends.Backend_State;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Nodes.Lifecycle_State;
   use type A11y.Resource_Limits.Limit_Value;
   use type A11y.Results.Status_Code;
   use type A11y.Roles.Role_Focus_Behavior;
   use type A11y.Roles.Role_Selection_Behavior;
   use type A11y.States.State_Source;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run is
   begin
      Check
        (A11y.Roles.Stable_Name (A11y.Roles.Password_Field)
         = "password-field"
         and then A11y.Roles.Metadata (A11y.Roles.Password_Field).Text_Entry
         and then not A11y.Roles.Metadata
           (A11y.Roles.Password_Field).Surface
         and then A11y.Roles.Focus_Behavior
           (A11y.Roles.Password_Field) =
             A11y.Roles.Focusable_When_Text_Entry,
         "role framework exposes stable role metadata");
      Check
        (A11y.Roles.Is_Surface (A11y.Roles.Dialog)
         and then not A11y.Roles.Is_Text_Entry (A11y.Roles.Dialog)
         and then A11y.Roles.Focus_Behavior (A11y.Roles.Dialog) =
           A11y.Roles.Focusable_Surface,
         "role framework derives helper predicates from metadata");
      Check
        (A11y.Roles.Is_Selection_Container (A11y.Roles.List)
         and then A11y.Roles.Selection_Behavior (A11y.Roles.Table) =
           A11y.Roles.Selection_Container
         and then A11y.Roles.Is_Selectable_Item (A11y.Roles.List_Item)
         and then A11y.Roles.Is_Selectable_Item (A11y.Roles.Cell)
         and then not A11y.Roles.Is_Selectable_Item (A11y.Roles.Button),
         "role framework centralizes selection behavior metadata");
      Check
        (A11y.Nodes.Stable_Name (A11y.Nodes.Active) = "active"
         and then A11y.Nodes.Metadata (A11y.Nodes.Active).Externally_Live
         and then A11y.Nodes.Classification.Is_Externally_Live
           (A11y.Nodes.Active)
         and then not A11y.Nodes.Classification.Is_Externally_Live
           (A11y.Nodes.Attached)
         and then A11y.Nodes.Classification.Allows_Provider_Access
           (A11y.Nodes.Created)
         and then A11y.Nodes.Metadata (A11y.Nodes.Defunct).Provider_Access
           = False
         and then not A11y.Nodes.Classification.Allows_Provider_Access
           (A11y.Nodes.Defunct)
         and then A11y.Nodes.Classification.Is_Final
           (A11y.Nodes.Removed)
         and then not A11y.Nodes.Classification.Is_Final
           (A11y.Nodes.Removing),
         "node lifecycle framework exposes stable lifecycle metadata");
      Check
        (A11y.Nodes.Can_Transition
           (A11y.Nodes.Created, A11y.Nodes.Active)
         and then A11y.Nodes.Classification.Can_Transition
           (A11y.Nodes.Created, A11y.Nodes.Active)
         and then A11y.Nodes.Can_Transition
           (A11y.Nodes.Active, A11y.Nodes.Attached)
         and then not A11y.Nodes.Classification.Can_Transition
           (A11y.Nodes.Removed, A11y.Nodes.Active)
         and then A11y.Nodes.Validate_Transition
           (A11y.Nodes.Removed, A11y.Nodes.Active).Status =
             A11y.Results.Invalid_State,
         "node lifecycle framework validates semantic transitions");
      Check
        (A11y.Nodes.Stable_Name (A11y.Nodes.Flatten_Node)
         = "flatten-node"
         and then A11y.Nodes.Classification.Exposes_Node
           (A11y.Nodes.Expose_Node)
         and then not A11y.Nodes.Classification.Exposes_Node
           (A11y.Nodes.Flatten_Node)
         and then A11y.Nodes.Classification.Exposes_Descendants
           (A11y.Nodes.Expose_Descendants_Only)
         and then not A11y.Nodes.Metadata
           (A11y.Nodes.Hide_Node_And_Subtree).Exposes_Descendants
         and then A11y.Nodes.Classification.Hides_Subtree
           (A11y.Nodes.Hide_Node_And_Subtree),
         "node exposure framework exposes stable exposure metadata");
      Check
        (A11y.Backends.Stable_Name (A11y.Backends.Native) = "native"
         and then A11y.Backends.Metadata
           (A11y.Backends.Native).Native_Transport
         and then A11y.Backends.Metadata
           (A11y.Backends.Running).Accepts_Events
         and then A11y.Backends.Classification.Accepts_Events
           (A11y.Backends.Running)
         and then not A11y.Backends.Classification.Accepts_Events
           (A11y.Backends.Initialized)
         and then A11y.Backends.Classification.Is_Terminal
           (A11y.Backends.Stopped)
         and then A11y.Backends.Classification.Is_Terminal
           (A11y.Backends.Failed)
         and then A11y.Backends.Classification.Can_Initialize
           (A11y.Backends.Created)
         and then not A11y.Backends.Classification.Can_Initialize
           (A11y.Backends.Running)
         and then A11y.Backends.Classification.Can_Start
           (A11y.Backends.Initialized)
         and then A11y.Backends.Classification.Can_Stop
           (A11y.Backends.Running)
         and then not A11y.Backends.Classification.Can_Stop
           (A11y.Backends.Failed)
         and then A11y.Backends.Classification.Has_Native_Transport
           (A11y.Backends.Native)
         and then not A11y.Backends.Classification.Has_Native_Transport
           (A11y.Backends.Null_Backend),
         "backend framework exposes stable kind and state metadata");
      Check
        (A11y.States.Stable_Name (A11y.States.Read_Only)
         = "read-only"
         and then A11y.States.Source (A11y.States.Read_Only)
           = A11y.States.Centrally_Derived,
         "state framework exposes stable state metadata");
      Check
        (A11y.States.Source (A11y.States.Checked)
         = A11y.States.Application_Provided,
         "state framework classifies application-provided states");
      declare
         Text_Caps : constant A11y.Capabilities.Capability_Set :=
           A11y.Capabilities.With_Capability
             (A11y.Capabilities.Empty_Capability_Set,
              A11y.Capabilities.Text);
         Editable_Caps : constant A11y.Capabilities.Capability_Set :=
           A11y.Capabilities.With_Capability
             (Text_Caps, A11y.Capabilities.Editable_Text);
         Text_States : constant A11y.States.State_Set :=
           A11y.States.Derive
             (A11y.States.Empty_State_Set,
              A11y.Roles.Text_Field,
              Text_Caps);
         Editable_States : constant A11y.States.State_Set :=
           A11y.States.Derive
             (A11y.States.Empty_State_Set,
              A11y.Roles.Text_Field,
              Editable_Caps);
      begin
         Check
           (Text_States (A11y.States.Focusable)
            and then Text_States (A11y.States.Read_Only)
            and then not Text_States (A11y.States.Editable)
            and then Editable_States (A11y.States.Focusable)
            and then Editable_States (A11y.States.Editable)
            and then not Editable_States (A11y.States.Read_Only),
            "state framework derives role and capability states centrally");
      end;
      Check
        (A11y.Results.Succeeded
           (A11y.States.Validate
              (A11y.States.With_State
                 (A11y.States.With_State
                    (A11y.States.Empty_State_Set, A11y.States.Focusable),
                  A11y.States.Focused)))
         and then A11y.States.Validate
           (A11y.States.With_State
              (A11y.States.Empty_State_Set, A11y.States.Focused)).Status =
                A11y.Results.Invalid_State,
         "state framework validates focus state invariants");
      Check
        (A11y.Results.Succeeded
           (A11y.States.Validate
              (A11y.States.With_State
                 (A11y.States.With_State
                    (A11y.States.Empty_State_Set, A11y.States.Selectable),
                  A11y.States.Multi_Selectable)))
         and then A11y.States.Validate
           (A11y.States.With_State
              (A11y.States.Empty_State_Set,
               A11y.States.Multi_Selectable)).Status =
                A11y.Results.Invalid_State,
         "state framework validates multi-selection state invariants");
      Check
        (A11y.Capabilities.Stable_Name (A11y.Capabilities.Editable_Text)
         = "editable-text"
         and then A11y.Capabilities.Stable_Name
           (A11y.Capabilities.Live_Region) = "live-region"
         and then A11y.Capabilities.Metadata
           (A11y.Capabilities.Surface).Stable_Name.all = "surface",
         "capability framework exposes stable capability metadata");
      Check
        (A11y.Results.Stable_Name (A11y.Results.Permission_Denied)
         = "permission-denied"
         and then A11y.Results.Metadata (A11y.Results.Success).Is_Success
         and then A11y.Results.Metadata
           (A11y.Results.Internal_Error).Expected = False,
         "result framework exposes stable status metadata");
      Check
        (A11y.Resource_Limits.Stable_Name
           (A11y.Resource_Limits.Text_Returned) = "text-returned"
         and then A11y.Resource_Limits.Metadata
           (A11y.Resource_Limits.Text_Returned).Default_Value
           = A11y.Resource_Limits.Limit_Value
             (A11y.Text.Max_Text_Returned),
         "resource-limit framework exposes stable limit metadata");
   end Run;
end A11y_Framework_Metadata_Tests;
