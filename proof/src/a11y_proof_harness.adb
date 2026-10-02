with A11y.Actions;
with A11y.Actions.Classification;
with A11y.Backends;
with A11y.Backends.Classification;
with A11y.Backends.Default_Classification;
with A11y.Backends.Selection;
with A11y.Backends.Selection.Classification;
with A11y.Backends.Transport_Classification;
with A11y.Capabilities;
with A11y.Conformance;
with A11y.Conformance.Classification;
with A11y.Diagnostics;
with A11y.Diagnostics.Classification;
with A11y.Dispatchers;
with A11y.Dispatchers.Classification;
with A11y.Documents;
with A11y.Documents.Classification;
with A11y.Event_Queues;
with A11y.Event_Queues.Classification;
with A11y.Event_Subscriptions;
with A11y.Event_Subscriptions.Classification;
with A11y.Events;
with A11y.Events.Classification;
with A11y.Geometry;
with A11y.Images;
with A11y.Images.Classification;
with A11y.Live_Regions;
with A11y.Live_Regions.Classification;
with A11y.Native_Boundary_Calls;
with A11y.Native_Boundary_Calls.Classification;
with A11y.Native_Callbacks;
with A11y.Native_Callbacks.Classification;
with A11y.Native_Identity;
with A11y.Native_Identity.Classification;
with A11y.Native_Object_Caches;
with A11y.Native_Object_Caches.Classification;
with A11y.Native_Runtimes.Classification;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Nodes.Classification;
with A11y.Platforms;
with A11y.Platforms.Classification;
with A11y.Properties;
with A11y.Properties.Classification;
with A11y.Relations;
with A11y.Relations.Classification;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Results.Classification;
with A11y.Roles;
with A11y.Selection;
with A11y.Selection.Classification;
with A11y.States;
with A11y.Tables;
with A11y.Tables.Classification;
with A11y.Text;
with A11y.Text.Classification;
with A11y.Trees;
with A11y.Trees.Classification;
with A11y.Values;
with A11y.Values.Classification;
with A11y.Windows;
with A11y.Windows.Classification;

procedure A11y_Proof_Harness is
   pragma SPARK_Mode (On);

   use type A11y.Results.Status_Code;
   use type A11y.Resource_Limits.Limit_Kind;
   use type A11y.Resource_Limits.Limit_Value;
   use type A11y.Properties.Property_Status;
   use type A11y.Properties.Property_Value_Kind;
   use type A11y.Relations.Relation_Kind;
   use type A11y.Values.Value_Kind;
   use type A11y.Actions.Action_Id;
   use type A11y.Backends.Backend_State;
   use type A11y.Backends.Backend_Kind;
   use type A11y.Backends.Selection.Selection_Mode;
   use type A11y.Conformance.Support_Level;
   use type A11y.Documents.Document_Role;
   use type A11y.Diagnostics.Category;
   use type A11y.Diagnostics.Severity;
   use type A11y.Dispatchers.Call_Kind;
   use type A11y.Events.Event_Kind;
   use type A11y.Event_Subscriptions.Subscription_Id;
   use type A11y.Images.Image_Kind;
   use type A11y.Live_Regions.Live_Setting;
   use type A11y.Native_Boundary_Calls.Boundary_Return_Class;
   use type A11y.Native_Callbacks.Callback_Token;
   use type A11y.Native_Object_Caches.Native_Object_Id;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type A11y.Nodes.Lifecycle_State;
   use type A11y.Nodes.Exposure_Policy;
   use type A11y.Selection.Selection_Mode;
   use type A11y.Selection.Selection_Direction;
   use type A11y.Tables.Coordinate_Space;
   use type A11y.Tables.Header_Scope;
   use type A11y.Tables.Sort_Order;
   use type A11y.Text.Protected_Text_Policy;
   use type A11y.Text.Text_Edit_Kind;
   use type A11y.Windows.Surface_Kind;
   use A11y.Geometry;

   Id       : constant A11y.Node_Ids.Node_Id :=
     A11y.Node_Ids.From_Natural (1);
   Missing  : constant A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   Viewport : constant Rectangle :=
     (Origin => (X => -10, Y => -10),
      Extent => (Width => 20, Height => 20));
   Inside   : constant Rectangle :=
     (Origin => (X => 0, Y => 0),
      Extent => (Width => 5, Height => 5));
   Outside  : constant Rectangle :=
     (Origin => (X => 100, Y => 100),
      Extent => (Width => 5, Height => 5));
   Visible  : constant Rectangle := Intersection (Viewport, Inside);
   Clipped  : constant Rectangle := Intersection (Viewport, Outside);
   Region_1 : Region (2);
   Added    : Boolean;
   Ok        : constant A11y.Results.Result :=
     (Status => A11y.Results.Success);
   Failure   : constant A11y.Results.Result :=
     (Status => A11y.Results.Protocol_Failure);
   Cap_Set   : constant A11y.Capabilities.Capability_Set :=
     A11y.Capabilities.With_Capability
       (A11y.Capabilities.Empty_Capability_Set,
        A11y.Capabilities.Action);
   Focused_Only : constant A11y.States.State_Set :=
     A11y.States.With_State
       (A11y.States.Empty_State_Set,
        A11y.States.Focused);
   Focusable_Focused : constant A11y.States.State_Set :=
     A11y.States.With_State (Focused_Only, A11y.States.Focusable);
   Limits    : A11y.Resource_Limits.Resource_Limit_Config :=
     A11y.Resource_Limits.Default_Config;
   Set_Result : A11y.Results.Result;
   Integer_Value : constant A11y.Values.Semantic_Value :=
     (Kind => A11y.Values.Integer_Value, Integer_Item => 42);
   Unknown_Value : constant A11y.Values.Semantic_Value :=
     (Kind => A11y.Values.Unknown);
   Visible_Surface : constant A11y.Windows.Surface_Metadata :=
     (Kind  => A11y.Windows.Modal_Dialog,
      State => (Visible    => True,
                Active     => False,
                Modal      => False,
                Minimized  => False,
                Maximized  => False,
                Fullscreen => False,
                Closable   => True,
                Resizable  => True,
                Movable    => False));
   Live_Set : constant A11y.Live_Regions.Relevant_Change_Set :=
     A11y.Live_Regions.Classification.With_Change
       (A11y.Live_Regions.Empty_Relevant_Change_Set,
        A11y.Live_Regions.Text);
   Focus_Filter : constant A11y.Event_Subscriptions.Event_Filter :=
     [A11y.Events.Focus_Changed => True, others => False];
   Live_Metadata : constant A11y.Live_Regions.Live_Region_Metadata :=
     (Setting  => A11y.Live_Regions.Polite,
      Atomic   => False,
      Relevant => Live_Set);
begin
   pragma Assert
     (A11y.Backends.Classification.Accepts_Events (A11y.Backends.Running));
   pragma Assert
     (not A11y.Backends.Classification.Accepts_Events
        (A11y.Backends.Initialized));
   pragma Assert
     (A11y.Backends.Classification.Is_Terminal (A11y.Backends.Stopped));
   pragma Assert
     (A11y.Backends.Classification.Is_Terminal (A11y.Backends.Failed));
   pragma Assert
     (A11y.Backends.Classification.Can_Initialize (A11y.Backends.Created));
   pragma Assert
     (not A11y.Backends.Classification.Can_Initialize
        (A11y.Backends.Running));
   pragma Assert
     (A11y.Backends.Classification.Can_Start (A11y.Backends.Created));
   pragma Assert
     (A11y.Backends.Classification.Can_Start (A11y.Backends.Initialized));
   pragma Assert
     (A11y.Backends.Classification.Can_Stop (A11y.Backends.Running));
   pragma Assert
     (not A11y.Backends.Classification.Can_Stop (A11y.Backends.Failed));
   pragma Assert
     (A11y.Backends.Classification.Has_Native_Transport
        (A11y.Backends.Native));
   pragma Assert
     (not A11y.Backends.Classification.Has_Native_Transport
        (A11y.Backends.Null_Backend));
   pragma Assert
     (A11y.Backends.Default_Classification.Requires_Target_Lookup
        (A11y.Backends.Native));
   pragma Assert
     (not A11y.Backends.Default_Classification.Requires_Target_Lookup
        (A11y.Backends.Null_Backend));
   pragma Assert
     (A11y.Backends.Default_Classification.Constructed_Backend
        (A11y.Backends.Native, True) = A11y.Backends.Native);
   pragma Assert
     (A11y.Backends.Default_Classification.Constructed_Backend
        (A11y.Backends.Native, False) = A11y.Backends.Null_Backend);
   pragma Assert
     (A11y.Backends.Default_Classification.Constructed_Backend
        (A11y.Backends.Disabled, False) = A11y.Backends.Disabled);
   pragma Assert
     (A11y.Backends.Default_Classification.Constructed_Backend
        (A11y.Backends.Default_Backend, True) = A11y.Backends.Null_Backend);
   pragma Assert
     (A11y.Backends.Default_Classification.Is_Defensive_Fallback
        (A11y.Backends.Native, False));
   pragma Assert
     (not A11y.Backends.Default_Classification.Is_Defensive_Fallback
        (A11y.Backends.Native, True));
   pragma Assert
     (A11y.Backends.Transport_Classification.Can_Mutate_Transport
        (A11y.Backends.Created));
   pragma Assert
     (A11y.Backends.Transport_Classification.Can_Mutate_Transport
        (A11y.Backends.Stopped));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Can_Mutate_Transport
        (A11y.Backends.Running));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Failure_Status_Allowed
        (A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification.Failure_Status_Allowed
        (A11y.Results.Protocol_Failure));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Admission
        (False, A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Admission
        (True, A11y.Results.Backend_Unavailable));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Should_Advance_On_Admission
        (True, A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Failure
        (True, A11y.Results.Success, A11y.Results.Protocol_Failure));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Failure
        (False, A11y.Results.Backend_Unavailable,
         A11y.Results.Protocol_Failure));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Should_Advance_On_Failure
        (False, A11y.Results.Protocol_Failure,
         A11y.Results.Protocol_Failure));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Stop
        (True, False, A11y.Results.Success, A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Stop
        (False, True, A11y.Results.Success, A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification.Should_Advance_On_Stop
        (False, False, A11y.Results.Protocol_Failure, A11y.Results.Success));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Should_Advance_On_Stop
        (False, False, A11y.Results.Success, A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification
        .Should_Advance_On_Start_Connected
        (True));
   pragma Assert
     (not A11y.Backends.Transport_Classification
        .Should_Advance_On_Start_Connected
        (False));
   pragma Assert
     (A11y.Backends.Transport_Classification
        .Should_Advance_On_Start_Unavailable
        (A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification
        .Should_Advance_On_Start_Unavailable
        (A11y.Results.Protocol_Failure));
   pragma Assert
     (not A11y.Backends.Transport_Classification
        .Should_Advance_On_Start_Unavailable
        (A11y.Results.Backend_Unavailable));
   pragma Assert
     (A11y.Backends.Transport_Classification.Can_Prepare_Publication (True));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Can_Prepare_Publication
        (False));
   pragma Assert
     (A11y.Backends.Transport_Classification
        .Should_Advance_On_Publication_Status
        (A11y.Results.Backend_Unavailable, A11y.Results.Success));
   pragma Assert
     (A11y.Backends.Transport_Classification
        .Should_Advance_On_Publication_Status
        (A11y.Results.Success, A11y.Results.Protocol_Failure));
   pragma Assert
     (not A11y.Backends.Transport_Classification
        .Should_Advance_On_Publication_Status
        (A11y.Results.Success, A11y.Results.Success));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Generation_Changed
        (3, 3));
   pragma Assert
     (A11y.Backends.Transport_Classification.Generation_Changed
        (3, 4));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Generation_Changed
        (4, 3));
   pragma Assert
     (not A11y.Backends.Transport_Classification.Flag_Changed
        (True, True));
   pragma Assert
     (A11y.Backends.Transport_Classification.Flag_Changed
        (True, False));
   pragma Assert
     (A11y.Backends.Transport_Classification.Flag_Changed
        (False, True));
   pragma Assert
     (A11y.Backends.Selection.Classification.Is_Valid_Mode
        (A11y.Backends.Selection.Use_Default));
   pragma Assert
     (not A11y.Backends.Selection.Classification.Is_Valid_Mode
        (A11y.Backends.Selection.Invalid));
   pragma Assert
     (A11y.Backends.Selection.Classification.Is_Explicit_Mode
        (A11y.Backends.Selection.Use_Native));
   pragma Assert
     (not A11y.Backends.Selection.Classification.Is_Explicit_Mode
        (A11y.Backends.Selection.Use_Default));
   pragma Assert
     (A11y.Backends.Selection.Classification.Requires_Native_Transport
        (A11y.Backends.Selection.Use_Native));
   pragma Assert
     (not A11y.Backends.Selection.Classification.Requires_Native_Transport
        (A11y.Backends.Selection.Use_Null));
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Selected_Backend
        (A11y.Backends.Selection.Use_Default, True, True) =
        A11y.Backends.Native);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Selected_Backend
        (A11y.Backends.Selection.Use_Default, True, False) =
        A11y.Backends.Null_Backend);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Selected_Backend
        (A11y.Backends.Selection.Use_Native, True, False) =
        A11y.Backends.Native);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Selected_Backend
        (A11y.Backends.Selection.Use_Native, False, False) =
        A11y.Backends.Null_Backend);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Selected_Backend
        (A11y.Backends.Selection.Use_Disabled, True, True) =
        A11y.Backends.Disabled);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Status
        (A11y.Backends.Selection.Use_Default, True, True) =
        A11y.Results.Success);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Status
        (A11y.Backends.Selection.Use_Default, True, False) =
        A11y.Results.Backend_Unavailable);
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Status
        (A11y.Backends.Selection.Invalid, True, True) =
        A11y.Results.Invalid_Argument);
   pragma Assert
     (not A11y.Backends.Selection.Classification.Expected_Fallback
        (A11y.Backends.Selection.Use_Native, True, False));
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Fallback
        (A11y.Backends.Selection.Use_Native, False, False));
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Fallback
        (A11y.Backends.Selection.Use_Default, True, False));
   pragma Assert
     (A11y.Backends.Selection.Classification.Expected_Fallback
        (A11y.Backends.Selection.Invalid, True, True));
   pragma Assert
     (A11y.Nodes.Classification.Is_Externally_Live (A11y.Nodes.Active));
   pragma Assert
     (not A11y.Nodes.Classification.Is_Externally_Live
        (A11y.Nodes.Attached));
   pragma Assert
     (A11y.Nodes.Classification.Allows_Provider_Access
        (A11y.Nodes.Created));
   pragma Assert
     (not A11y.Nodes.Classification.Allows_Provider_Access
        (A11y.Nodes.Defunct));
   pragma Assert
     (A11y.Nodes.Classification.Is_Final (A11y.Nodes.Removed));
   pragma Assert
     (not A11y.Nodes.Classification.Is_Final (A11y.Nodes.Removing));
   pragma Assert
     (A11y.Nodes.Classification.Can_Transition
        (A11y.Nodes.Created, A11y.Nodes.Active));
   pragma Assert
     (not A11y.Nodes.Classification.Can_Transition
        (A11y.Nodes.Removed, A11y.Nodes.Active));
   pragma Assert
     (A11y.Nodes.Classification.Exposes_Node (A11y.Nodes.Expose_Node));
   pragma Assert
     (not A11y.Nodes.Classification.Exposes_Node
        (A11y.Nodes.Flatten_Node));
   pragma Assert
     (A11y.Nodes.Classification.Exposes_Descendants
        (A11y.Nodes.Expose_Descendants_Only));
   pragma Assert
     (not A11y.Nodes.Classification.Exposes_Descendants
        (A11y.Nodes.Hide_Node_And_Subtree));
   pragma Assert
     (A11y.Nodes.Classification.Hides_Subtree
        (A11y.Nodes.Hide_Node_And_Subtree));
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Password_Field,
         A11y.Properties.Present,
         False) = A11y.Properties.Permission_Denied);
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Button,
         A11y.Properties.Present,
         True) = A11y.Properties.Permission_Denied);
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Button,
         A11y.Properties.Present,
         False) = A11y.Properties.Present);
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Button,
         A11y.Properties.Unsupported,
         True) = A11y.Properties.Present);
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Button,
         A11y.Properties.Empty,
         True) = A11y.Properties.Present);
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Button,
         A11y.Properties.Temporarily_Unavailable,
         True) = A11y.Properties.Temporarily_Unavailable);
   pragma Assert
     (A11y.Nodes.Classification.Protected_Value_Query_Status
        (A11y.Roles.Button,
         A11y.Properties.Error,
         True) = A11y.Properties.Error);
   pragma Assert (A11y.Trees.Classification.Is_Addressable (Id));
   pragma Assert
     (not A11y.Trees.Classification.Is_Addressable
        (A11y.Node_Ids.From_Natural
           (A11y.Trees.Max_Attached_Nodes + 1)));
   pragma Assert
     (A11y.Trees.Classification.Valid_Attachment_Pair
        (Id, A11y.Node_Ids.From_Natural (2)));
   pragma Assert
     (not A11y.Trees.Classification.Valid_Attachment_Pair (Id, Id));
   pragma Assert
     (A11y.Trees.Classification.Can_Detach_Node
        (Id, A11y.Node_Ids.From_Natural (2)));
   pragma Assert
     (not A11y.Trees.Classification.Can_Detach_Node (Id, Id));
   pragma Assert
     (A11y.Trees.Classification.Can_Move_Node
        (Id, A11y.Node_Ids.From_Natural (2),
         A11y.Node_Ids.From_Natural (3)));
   pragma Assert
     (not A11y.Trees.Classification.Can_Move_Node
        (Id, A11y.Node_Ids.From_Natural (2), Id));
   pragma Assert
     (A11y.Event_Queues.Classification.Valid_Capacity
        (A11y.Event_Queues.Max_Queued_Events));
   pragma Assert
     (not A11y.Event_Queues.Classification.Valid_Capacity (0));
   pragma Assert
     (A11y.Event_Queues.Classification.Can_Set_Capacity (2, 2));
   pragma Assert
     (not A11y.Event_Queues.Classification.Can_Set_Capacity (3, 2));
   pragma Assert
     (A11y.Event_Queues.Classification.Available_Slots (2, 5) = 3);
   pragma Assert
     (A11y.Event_Queues.Classification.Available_Slots (5, 5) = 0);
   pragma Assert
     (A11y.Event_Queues.Classification.Can_Coalesce
        (Id, Id, A11y.Events.Bounds_Changed, A11y.Events.Bounds_Changed));
   pragma Assert
     (not A11y.Event_Queues.Classification.Can_Coalesce
        (Id, Id, A11y.Events.Text_Inserted, A11y.Events.Text_Inserted));
   pragma Assert
     (A11y.Event_Subscriptions.Classification.Valid_Capacity
        (A11y.Event_Subscriptions.Max_Subscriptions));
   pragma Assert
     (not A11y.Event_Subscriptions.Classification.Valid_Capacity (0));
   pragma Assert
     (A11y.Event_Subscriptions.Classification.Can_Set_Capacity (2, 2));
   pragma Assert
     (not A11y.Event_Subscriptions.Classification.Can_Set_Capacity (3, 2));
   pragma Assert
     (not A11y.Event_Subscriptions.Classification.Has_Enabled_Event
        (A11y.Event_Subscriptions.No_Events));
   pragma Assert
     (A11y.Event_Subscriptions.Classification.Accepts
        (Focus_Filter, A11y.Events.Focus_Changed));
   pragma Assert
     (not A11y.Event_Subscriptions.Classification.Accepts
        (Focus_Filter, A11y.Events.Text_Inserted));
   pragma Assert
     (A11y.Dispatchers.Classification.Timeout_Limit_For
        (A11y.Dispatchers.Shutdown) =
        A11y.Resource_Limits.Shutdown_Duration_MS);
   pragma Assert
     (A11y.Dispatchers.Classification.Timeout_Limit_For
        (A11y.Dispatchers.Text_Query) =
        A11y.Resource_Limits.Callback_Duration_MS);
   pragma Assert
     (A11y.Dispatchers.Classification.Is_Cancellable_Kind
        (A11y.Dispatchers.Action_Invocation));
   pragma Assert
     (not A11y.Dispatchers.Classification.Is_Cancellable_Kind
        (A11y.Dispatchers.Shutdown));
   pragma Assert
     (A11y.Dispatchers.Classification.Has_Timed_Out
        (Limits, A11y.Dispatchers.Text_Query, Natural'Last));
   pragma Assert
     (A11y.Dispatchers.Classification.Before_Callback_Rejection_Status
        (True, False, A11y.Dispatchers.Text_Query, True, 0) =
        A11y.Results.Shutting_Down);
   pragma Assert
     (A11y.Dispatchers.Classification.Before_Callback_Rejection_Status
        (False, True, A11y.Dispatchers.Text_Query, True, 0) =
        A11y.Results.Cancelled);
   pragma Assert
     (A11y.Dispatchers.Classification.Before_Callback_Rejection_Status
        (False, False, A11y.Dispatchers.Text_Query, False, 0) =
        A11y.Results.Invalid_Argument);
   pragma Assert
     (A11y.Dispatchers.Classification.Before_Callback_Rejection_Status
        (False, False, A11y.Dispatchers.Text_Query, True, 1) =
        A11y.Results.Busy);
   pragma Assert
     (A11y.Dispatchers.Classification.Rejects_Before_Callback
        (False, True, A11y.Dispatchers.Text_Query, True, 0));
   pragma Assert
     (not A11y.Dispatchers.Classification.Rejects_Before_Callback
        (False, True, A11y.Dispatchers.Shutdown, True, 0));
   pragma Assert
     (A11y.Dispatchers.Classification.Rejects_Before_Callback
        (False, False, A11y.Dispatchers.Text_Query, False, 0));
   pragma Assert
     (A11y.Dispatchers.Classification.Rejects_Before_Callback
        (False, False, A11y.Dispatchers.Text_Query, True, 1));
   pragma Assert
     (A11y.Dispatchers.Classification.Rejects_On_Dispatch_Thread
        (False, False, A11y.Dispatchers.Text_Query, 0));
   pragma Assert
     (not A11y.Dispatchers.Classification.Rejects_On_Dispatch_Thread
        (False, False, A11y.Dispatchers.Text_Query, 1));
   pragma Assert
     (A11y.Dispatchers.Classification.Dispatch_Thread_Rejection_Status
        (True, False, A11y.Dispatchers.Text_Query, 1) =
        A11y.Results.Shutting_Down);
   pragma Assert
     (A11y.Dispatchers.Classification.Dispatch_Thread_Rejection_Status
        (False, True, A11y.Dispatchers.Text_Query, 1) =
        A11y.Results.Cancelled);
   pragma Assert
     (A11y.Dispatchers.Classification.Dispatch_Thread_Rejection_Status
        (False, False, A11y.Dispatchers.Text_Query, 0) =
        A11y.Results.Invalid_State);
   pragma Assert
     (A11y.Native_Callbacks.Classification.Valid_Capacity
        (A11y.Native_Callbacks.Max_Callbacks));
   pragma Assert
     (not A11y.Native_Callbacks.Classification.Valid_Capacity (0));
   pragma Assert
     (A11y.Native_Callbacks.Classification.Can_Set_Limit (2, 3, 3));
   pragma Assert
     (not A11y.Native_Callbacks.Classification.Can_Set_Limit (4, 3, 3));
   pragma Assert
     (A11y.Native_Callbacks.Classification.Can_Begin_Callback
        (True, 1, 2, 1));
   pragma Assert
     (not A11y.Native_Callbacks.Classification.Can_Begin_Callback
        (False, 1, 2, 1));
   pragma Assert
     (not A11y.Native_Callbacks.Classification.Can_Begin_Callback
        (True, 2, 2, 1));
   pragma Assert
     (A11y.Native_Callbacks.Classification.Can_Advance_Gate_Generation (0));
   pragma Assert
     (not A11y.Native_Callbacks.Classification.Can_Advance_Gate_Generation
        (Natural'Last));
   pragma Assert
     (A11y.Native_Callbacks.Classification.Should_Advance_On_Shutdown
        (True));
   pragma Assert
     (not A11y.Native_Callbacks.Classification.Should_Advance_On_Shutdown
        (False));
   pragma Assert (A11y.Native_Callbacks.Classification.Can_Reset (0));
   pragma Assert (not A11y.Native_Callbacks.Classification.Can_Reset (1));
   pragma Assert (A11y.Native_Callbacks.Classification.Is_Drained (0));
   pragma Assert (not A11y.Native_Callbacks.Classification.Is_Drained (1));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Valid_Capacity
        (A11y.Native_Object_Caches.Max_Native_Objects));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Valid_Capacity (0));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Allocated_Count (1) = 0);
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Allocated_Count (4) = 3);
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Can_Set_Limits
        (4, 1, 3, 1));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Can_Set_Limits
        (4, 1, 2, 1));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Can_Set_Limits
        (4, 2, 3, 1));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Can_Advance_Generation (0));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Can_Advance_Generation
        (Natural'Last));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Generation_Advanced
        (3, 3));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Generation_Advanced (3, 4));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Count_Changed (3, 3));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Count_Changed (3, 2));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Object_Returned
        (A11y.Native_Object_Caches.No_Object));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Active_Slot (1, 2));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Active_Slot (0, 2));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Active_Slot (2, 2));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Live_Record
        (True, False, False));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Live_Record
        (True, True, False));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Live_Record
        (True, False, True));
   pragma Assert
     (A11y.Native_Object_Caches.Classification.Releasable_Record
        (True, False));
   pragma Assert
     (not A11y.Native_Object_Caches.Classification.Releasable_Record
        (True, True));
   pragma Assert
     (A11y.Native_Identity.Classification.Valid_Session_Value (1));
   pragma Assert
     (not A11y.Native_Identity.Classification.Valid_Session_Value (0));
   pragma Assert
     (A11y.Native_Identity.Classification.Valid_Runtime_Node_Component
        (A11y.Node_Ids.Max_Node_Ids));
   pragma Assert
     (not A11y.Native_Identity.Classification.Valid_Runtime_Node_Component
        (0));
   pragma Assert
     (A11y.Native_Identity.Classification.Can_Encode_Runtime_Component
        (1, 1));
   pragma Assert
     (not A11y.Native_Identity.Classification.Can_Encode_Runtime_Component
        (0, 1));
   pragma Assert
     (A11y.Native_Identity.Classification.Runtime_Component (1, 1)
      = A11y.Native_Identity.Classification.Runtime_Node_Factor + 1);
   pragma Assert
     (A11y.Native_Identity.Classification.Component_Session_Value
        (A11y.Native_Identity.Classification.Runtime_Node_Factor + 1) = 1);
   pragma Assert
     (A11y.Native_Identity.Classification.Component_Node_Value
        (A11y.Native_Identity.Classification.Runtime_Node_Factor + 1) = 1);
   pragma Assert
     (A11y.Native_Identity.Classification.Component_Matches_Session
        (1, A11y.Native_Identity.Classification.Runtime_Node_Factor + 1));
   pragma Assert
     (not A11y.Native_Identity.Classification.Component_Matches_Session
        (2, A11y.Native_Identity.Classification.Runtime_Node_Factor + 1));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Can_Initialize
        (A11y.Backends.Created));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Can_Initialize
        (A11y.Backends.Running));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Needs_Initialize_Before_Start
        (A11y.Backends.Stopped));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Needs_Initialize_Before_Start
        (A11y.Backends.Initialized));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Can_Enter_Running
        (A11y.Backends.Initialized));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Can_Enter_Running
        (A11y.Backends.Created));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Accepts_Object_Work
        (A11y.Backends.Running));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Accepts_Object_Work
        (A11y.Backends.Stopping));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Accepts_Event_Work
        (A11y.Backends.Running));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Accepts_Defunct_Mark
        (A11y.Backends.Stopping));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Accepts_Defunct_Mark
        (A11y.Backends.Stopped));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Stop_Is_Idempotent
        (A11y.Backends.Stopped));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Can_Advance_Generation (0));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Can_Advance_Generation
        (Natural'Last));
   pragma Assert (A11y.Native_Runtimes.Classification.Drained (0, 0, 0));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Drained (1, 0, 0));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Generation_Changed (3, 3));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Generation_Changed (3, 4));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Generation_Changed (4, 3));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.State_Changed
        (A11y.Backends.Running, A11y.Backends.Running));
   pragma Assert
     (A11y.Native_Runtimes.Classification.State_Changed
        (A11y.Backends.Initialized, A11y.Backends.Running));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Session_Changed
        (A11y.Native_Identity.From_Natural (1),
         A11y.Native_Identity.From_Natural (1)));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Session_Changed
        (A11y.Native_Identity.From_Natural (1),
         A11y.Native_Identity.From_Natural (2)));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Cache_Reset (1, 0, 0, 0));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Cache_Reset (0, 1, 0, 0));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Cache_Reset (0, 0, 0, 0));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Cache_Reset (1, 0, 1, 0));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Event_Order_Reset
        (A11y.Event_Sequence (1), A11y.No_Event));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Event_Order_Reset
        (A11y.No_Event, A11y.No_Event));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Event_Order_Reset
        (A11y.Event_Sequence (1), A11y.Event_Sequence (1)));
   pragma Assert (A11y.Native_Runtimes.Classification.Valid_Node_Slot (1));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Valid_Node_Slot
        (A11y.Node_Ids.Max_Node_Ids));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Valid_Node_Slot (0));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Sequence_Advances
        (A11y.Event_Sequence (1), A11y.Event_Sequence (2)));
   pragma Assert
     (not A11y.Native_Runtimes.Classification.Sequence_Advances
        (A11y.Event_Sequence (2), A11y.Event_Sequence (2)));
   pragma Assert
     (A11y.Native_Runtimes.Classification.Destroyed_Node_Status
        (A11y.Events.Node_Destroyed) = A11y.Results.Invalid_State);
   pragma Assert
     (A11y.Native_Runtimes.Classification.Destroyed_Node_Status
        (A11y.Events.Focus_Changed) = A11y.Results.Node_Unavailable);
   pragma Assert
     (not A11y.Native_Runtimes.Classification
        .Defunct_Mark_Cache_Failure_Blocks (A11y.Results.Success));
   pragma Assert
     (not A11y.Native_Runtimes.Classification
        .Defunct_Mark_Cache_Failure_Blocks
           (A11y.Results.Node_Unavailable));
   pragma Assert
     (A11y.Native_Runtimes.Classification
        .Defunct_Mark_Cache_Failure_Blocks
           (A11y.Results.Internal_Error));
   pragma Assert
     (A11y.Platforms.Classification.Has_Native_Backend
        (A11y.Platforms.Linux));
   pragma Assert
     (A11y.Platforms.Classification.Has_Native_Backend
        (A11y.Platforms.MacOS));
   pragma Assert
     (A11y.Platforms.Classification.Has_Native_Backend
        (A11y.Platforms.Windows));
   pragma Assert
     (not A11y.Platforms.Classification.Has_Native_Backend
        (A11y.Platforms.Unsupported));
   pragma Assert
     (A11y.Platforms.Classification.Uses_Null_Backend_By_Default
        (A11y.Platforms.Unsupported));
   pragma Assert
     (A11y.Platforms.Classification.Requires_ATSPI2
        (A11y.Platforms.Linux));
   pragma Assert
     (not A11y.Platforms.Classification.Requires_ATSPI2
        (A11y.Platforms.Windows));
   pragma Assert
     (A11y.Platforms.Classification.Requires_UIA
        (A11y.Platforms.Windows));
   pragma Assert
     (not A11y.Platforms.Classification.Requires_UIA
        (A11y.Platforms.MacOS));
   pragma Assert
     (A11y.Platforms.Classification.Requires_NSAccessibility
        (A11y.Platforms.MacOS));
   pragma Assert
     (not A11y.Platforms.Classification.Requires_NSAccessibility
        (A11y.Platforms.Linux));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Success) =
      A11y.Native_Boundary_Calls.Return_Success);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Unsupported_Action) =
      A11y.Native_Boundary_Calls.Return_Unsupported);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Node_Unavailable) =
      A11y.Native_Boundary_Calls.Return_Unavailable);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Invalid_Range) =
      A11y.Native_Boundary_Calls.Return_Invalid_Argument);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Invalid_State) =
      A11y.Native_Boundary_Calls.Return_Invalid_State);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Out_Of_Resources) =
      A11y.Native_Boundary_Calls.Return_Resource_Limit);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Return_Class
        (A11y.Results.Internal_Error) =
      A11y.Native_Boundary_Calls.Return_Internal_Error);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Should_Replace_Final_Status
        (A11y.Results.Success, A11y.Results.Invalid_State));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification.Should_Replace_Final_Status
        (A11y.Results.Invalid_Argument, A11y.Results.Invalid_State));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification.Should_Replace_Final_Status
        (A11y.Results.Success, A11y.Results.Accepted_Asynchronous));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Completion_Operation_Status
        (A11y.Results.Success, A11y.Results.Invalid_State) =
      A11y.Results.Invalid_State);
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Completion_Operation_Status
        (A11y.Results.Invalid_Argument, A11y.Results.Success) =
      A11y.Results.Invalid_Argument);
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Final_Status_Overrides_Action
           (A11y.Results.Success, A11y.Results.Success));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Final_Status_Overrides_Action
        (A11y.Results.Internal_Error, A11y.Results.Success));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification.Final_Status_Overrides_Action
        (A11y.Results.Shutting_Down, A11y.Results.Accepted_Asynchronous));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Query (A11y.Results.Success));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Query
           (A11y.Results.Accepted_Asynchronous));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Query (A11y.Results.Timed_Out));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Action (A11y.Results.Success));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Action
           (A11y.Results.Accepted_Asynchronous));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification
        .Dispatch_Status_Overrides_Action (A11y.Results.Timed_Out));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Begin_Status_Rejects_Call (A11y.Results.Success));
   pragma Assert
     (not A11y.Native_Boundary_Calls.Classification
        .Begin_Status_Rejects_Call (A11y.Results.Accepted_Asynchronous));
   pragma Assert
     (A11y.Native_Boundary_Calls.Classification
        .Begin_Status_Rejects_Call (A11y.Results.Node_Unavailable));
   pragma Assert (A11y.Node_Ids.Is_Valid (Id));
   pragma Assert (A11y.Node_Ids.To_Natural (Id) = 1);

   Add_Rectangle (Region_1, Inside, Added);

   Clear (Region_1);
   pragma Assert (Rectangle_Count (Region_1) = 0);

   pragma Assert (A11y.Results.Classification.Succeeded (Ok));
   pragma Assert (A11y.Results.Classification.Failed (Failure));
   pragma Assert
     (not A11y.Results.Classification.Is_Expected_Status (Failure.Status));
   pragma Assert (Cap_Set (A11y.Capabilities.Action));
   pragma Assert (not Cap_Set (A11y.Capabilities.Text));
   pragma Assert (A11y.Roles.Is_Surface (A11y.Roles.Application));
   pragma Assert (A11y.Roles.Is_Text_Entry (A11y.Roles.Password_Field));
   pragma Assert
     (A11y.Roles.Is_Selection_Container (A11y.Roles.List));
   pragma Assert
     (A11y.Roles.Is_Selectable_Item (A11y.Roles.List_Item));
   pragma Assert
     (A11y.Results.Failed (A11y.States.Validate (Focused_Only)));
   pragma Assert
     (A11y.Results.Succeeded (A11y.States.Validate (Focusable_Focused)));

   A11y.Resource_Limits.Set_Limit
     (Limits, A11y.Resource_Limits.Text_Returned, 16, Set_Result);
   pragma Assert (A11y.Results.Succeeded (Set_Result));
   pragma Assert
     (A11y.Resource_Limits.Value
        (Limits, A11y.Resource_Limits.Text_Returned) = 16);
   pragma Assert
     (A11y.Resource_Limits.Exceeded
        (Limits, A11y.Resource_Limits.Text_Returned, 17));
   pragma Assert
     (A11y.Properties.Classification.Is_Available
        (A11y.Properties.Present));
   pragma Assert
     (A11y.Properties.Classification.Is_Expected_Failure
        (A11y.Properties.Unsupported));
   pragma Assert
     (A11y.Properties.Classification.Status_From_Result
        (A11y.Results.Node_Unavailable) = A11y.Properties.Node_Unavailable);
   pragma Assert
     (A11y.Properties.Classification.Value_Kind_For
        (A11y.Properties.Bounds) = A11y.Properties.Rectangle_Value);
   pragma Assert
     (A11y.Relations.Classification.Canonical_Inverse
        (A11y.Relations.Labelled_By) = A11y.Relations.Label_For);
   pragma Assert
     (A11y.Relations.Classification.Is_Canonical_Pair
        (A11y.Relations.Described_By, A11y.Relations.Description_For));
   pragma Assert
     (A11y.Relations.Classification.Is_Self_Inverse
        (A11y.Relations.Member_Of));
   pragma Assert
     (not A11y.Relations.Classification.Is_Self_Inverse
        (A11y.Relations.Embeds));
   pragma Assert
     (A11y.Relations.Classification.Is_Label_Relation
        (A11y.Relations.Label_For));
   pragma Assert
     (A11y.Relations.Classification.Is_Description_Relation
        (A11y.Relations.Error_Message));
   pragma Assert
     (A11y.Relations.Classification.Is_Control_Relation
        (A11y.Relations.Active_Descendant));
   pragma Assert
     (A11y.Relations.Classification.Allows_Cycles
        (A11y.Relations.Flows_To));
   pragma Assert
     (not A11y.Relations.Classification.Allows_Cycles
        (A11y.Relations.Labelled_By));
   pragma Assert
     (A11y.Events.Classification.Is_Coalescible
        (A11y.Events.Bounds_Changed));
   pragma Assert
     (not A11y.Events.Classification.Is_Coalescible
        (A11y.Events.Text_Inserted));
   pragma Assert
     (A11y.Events.Classification.Is_Text_Event
        (A11y.Events.Text_Replaced));
   pragma Assert
     (A11y.Events.Classification.Is_Property_Event
        (A11y.Events.Property_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_State_Event
        (A11y.Events.Active_Descendant_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_Value_Event
        (A11y.Events.Range_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_Selection_Event
        (A11y.Events.Current_Item_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_Focus_Event
        (A11y.Events.Focus_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_Lifecycle_Event
        (A11y.Events.Node_Destroyed));
   pragma Assert
     (A11y.Events.Classification.Is_Tree_Event
        (A11y.Events.Child_Added));
   pragma Assert
     (A11y.Events.Classification.Is_Table_Event
        (A11y.Events.Cell_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_Document_Event
        (A11y.Events.Document_Loaded));
   pragma Assert
     (A11y.Events.Classification.Is_Relation_Event
        (A11y.Events.Relation_Targets_Changed));
   pragma Assert
     (A11y.Events.Classification.Is_Window_Event
        (A11y.Events.Window_Activated));
   pragma Assert
     (A11y.Events.Classification.Must_Preserve_Individual_Order
        (A11y.Events.Text_Removed));
   pragma Assert
     (not A11y.Events.Classification.Must_Preserve_Individual_Order
        (A11y.Events.Value_Changed));
   pragma Assert
     (A11y.Diagnostics.Classification.Category_For_Status
        (A11y.Results.Timed_Out) = A11y.Diagnostics.Provider_Timeout);
   pragma Assert
     (A11y.Diagnostics.Classification.Category_For_Status
        (A11y.Results.Node_Unavailable) = A11y.Diagnostics.Stale_Native_Query);
   pragma Assert
     (A11y.Diagnostics.Classification.Category_For_Status
        (A11y.Results.Out_Of_Resources) = A11y.Diagnostics.Native_Allocation);
   pragma Assert
     (A11y.Diagnostics.Classification.Default_Severity
        (A11y.Diagnostics.Native_Allocation) = A11y.Diagnostics.Fatal);
   pragma Assert
     (A11y.Diagnostics.Classification.Severity_For_Status
        (A11y.Results.Success) = A11y.Diagnostics.Trace);
   pragma Assert
     (A11y.Diagnostics.Classification.Severity_For_Status
        (A11y.Results.Protocol_Failure) = A11y.Diagnostics.Error);
   pragma Assert
     (A11y.Diagnostics.Classification.Is_Reportable
        (A11y.Diagnostics.Warning));
   pragma Assert
     (not A11y.Diagnostics.Classification.Is_Reportable
        (A11y.Diagnostics.Info));
   pragma Assert
     (A11y.Diagnostics.Classification.Is_Native_Boundary_Category
        (A11y.Diagnostics.ABI_Boundary_Failure));
   pragma Assert
     (not A11y.Diagnostics.Classification.Is_Native_Boundary_Category
        (A11y.Diagnostics.Node_Lifecycle));
   pragma Assert
     (A11y.Conformance.Classification.Is_Production_Support
        (A11y.Conformance.Exact));
   pragma Assert
     (A11y.Conformance.Classification.Is_Production_Support
        (A11y.Conformance.Equivalent));
   pragma Assert
     (A11y.Conformance.Classification.Is_Production_Support
        (A11y.Conformance.Approximate));
   pragma Assert
     (not A11y.Conformance.Classification.Is_Production_Support
        (A11y.Conformance.Internal_Only));
   pragma Assert
     (A11y.Conformance.Classification.Is_Internal_Or_Unsupported
        (A11y.Conformance.Unsupported));
   pragma Assert
     (A11y.Conformance.Classification.Support_Rank
        (A11y.Conformance.Unsupported) = 0);
   pragma Assert
     (A11y.Conformance.Classification.Support_Rank
        (A11y.Conformance.Exact) = 4);
   pragma Assert
     (A11y.Conformance.Classification.At_Least
        (A11y.Conformance.Equivalent, A11y.Conformance.Approximate));
   pragma Assert
     (not A11y.Conformance.Classification.At_Least
        (A11y.Conformance.Internal_Only, A11y.Conformance.Approximate));
   pragma Assert
     (A11y.Values.Classification.Is_Numeric_Kind
        (A11y.Values.Decimal_Value));
   pragma Assert
     (not A11y.Values.Classification.Is_Numeric_Kind
        (A11y.Values.Boolean_Value));
   pragma Assert
     (A11y.Values.Classification.Is_Known_Value (Integer_Value));
   pragma Assert
     (not A11y.Values.Classification.Is_Known_Value (Unknown_Value));
   pragma Assert
     (A11y.Values.Classification.Is_Mutable (A11y.Values.Writable));
   pragma Assert
     (A11y.Actions.Classification.Is_Value_Mutation
        (A11y.Actions.Increment));
   pragma Assert
     (A11y.Actions.Classification.Is_Selection_Mutation
        (A11y.Actions.Clear_Selection));
   pragma Assert
     (A11y.Actions.Classification.Is_Window_Operation
        (A11y.Actions.Open));
   pragma Assert
     (A11y.Actions.Classification.Is_Idempotent_By_Default
        (A11y.Actions.Set_Focus));
   pragma Assert
     (A11y.Actions.Classification.Failure_For
        (A11y.Actions.Requires_Writable) = A11y.Results.Read_Only);
   pragma Assert
     (A11y.Windows.Classification.Is_Top_Level_Kind
        (A11y.Windows.Window));
   pragma Assert
     (not A11y.Windows.Classification.Is_Top_Level_Kind
        (A11y.Windows.Embedded_Surface));
   pragma Assert
     (A11y.Windows.Classification.Is_Modal_Kind
        (A11y.Windows.Modal_Dialog));
   pragma Assert
     (A11y.Windows.Classification.Is_Operation_State
        (A11y.Windows.Closable));
   pragma Assert
     (A11y.Windows.Classification.Has_State
        (Visible_Surface.State, A11y.Windows.Visible));
   pragma Assert
     (A11y.Windows.Classification.Is_Modal_Surface (Visible_Surface));
   pragma Assert
     (A11y.Windows.Classification.State_Is_Coherent
        (Visible_Surface.State));
   pragma Assert
     (A11y.Images.Classification.Exposed_By_Default
        (A11y.Images.Informative));
   pragma Assert
     (not A11y.Images.Classification.Exposed_By_Default
        (A11y.Images.Decorative));
   pragma Assert
     (A11y.Images.Classification.Is_Structured_Kind
        (A11y.Images.Chart));
   pragma Assert
     (A11y.Images.Classification.Is_Informative_Kind
        (A11y.Images.Canvas));
   pragma Assert
     (A11y.Documents.Classification.Is_Landmark_Role
        (A11y.Documents.Navigation));
   pragma Assert
     (not A11y.Documents.Classification.Is_Structural_Block_Role
        (A11y.Documents.Annotation));
   pragma Assert
     (A11y.Documents.Classification.Valid_Heading_Level (6));
   pragma Assert
     (A11y.Documents.Classification.Heading_Level_Applies
        (A11y.Documents.Heading, 2));
   pragma Assert
     (A11y.Documents.Classification.Pagination_Applies
        (A11y.Documents.Document, 10, 1));
   pragma Assert
     (A11y.Live_Regions.Classification.Is_Externally_Announced
        (A11y.Live_Regions.Polite));
   pragma Assert
     (A11y.Live_Regions.Classification.Is_Interruptive
        (A11y.Live_Regions.Assertive));
   pragma Assert
     (A11y.Live_Regions.Classification.Has_Relevant_Changes (Live_Set));
   pragma Assert
     (A11y.Live_Regions.Classification.Relevant_Count (Live_Set) = 1);
   pragma Assert
     (A11y.Live_Regions.Classification.Metadata_Is_Coherent
        (Live_Metadata));
   pragma Assert
     (A11y.Selection.Classification.Allows_Selection
        (A11y.Selection.Single));
   pragma Assert
     (not A11y.Selection.Classification.Allows_Selection
        (A11y.Selection.None));
   pragma Assert
     (A11y.Selection.Classification.Allows_Multiple
        (A11y.Selection.Extended));
   pragma Assert
     (A11y.Selection.Classification.Allows_Range
        (A11y.Selection.Contiguous_Multiple));
   pragma Assert
     (not A11y.Selection.Classification.Count_Allowed
        (A11y.Selection.Single, 2));
   pragma Assert
     (A11y.Selection.Classification.Count_Allowed
        (A11y.Selection.Multiple, 2));
   pragma Assert
     (A11y.Selection.Classification.Is_Known_Direction
        (A11y.Selection.Forward));
   pragma Assert
     (not A11y.Selection.Classification.Is_Known_Direction
        (A11y.Selection.Unknown));
   pragma Assert
     (not A11y.Selection.Classification.Direction_Allowed
        (A11y.Selection.Single, A11y.Selection.Forward));
   pragma Assert
     (A11y.Selection.Classification.Direction_Allowed
        (A11y.Selection.Extended, A11y.Selection.Backward));
   pragma Assert
     (not A11y.Tables.Classification.Is_Presentation_Space
        (A11y.Tables.Logical_Coordinates));
   pragma Assert
     (A11y.Tables.Classification.Is_Presentation_Space
        (A11y.Tables.Display_Coordinates));
   pragma Assert
     (not A11y.Tables.Classification.Is_Header
        (A11y.Tables.Not_Header));
   pragma Assert
     (A11y.Tables.Classification.Header_Applies_To_Rows
        (A11y.Tables.Row_And_Column_Header));
   pragma Assert
     (A11y.Tables.Classification.Header_Applies_To_Columns
        (A11y.Tables.Corner_Header));
   pragma Assert
     (not A11y.Tables.Classification.Is_Sorted
        (A11y.Tables.Not_Sorted));
   pragma Assert
     (A11y.Tables.Classification.Is_Directional_Sort
        (A11y.Tables.Descending));
   pragma Assert
     (A11y.Tables.Classification.Sort_Key_Required
        (A11y.Tables.Ascending));
   pragma Assert
     (A11y.Tables.Classification.Range_Fits
        ((First => 2, Count => 3), 5));
   pragma Assert
     (not A11y.Tables.Classification.Range_Fits
        ((First => 4, Count => 2), 5));
   pragma Assert
     (A11y.Tables.Classification.Span_Fits (2, 5, 3));
   pragma Assert
     (not A11y.Tables.Classification.Span_Fits (2, 5, 4));
   pragma Assert
     (A11y.Tables.Classification.Covers
        ((Row => 2, Column => 3), 3, 4, 2, 2));
   pragma Assert
     (not A11y.Tables.Classification.Covers
        ((Row => 2, Column => 3), 4, 4, 2, 2));
   pragma Assert
     (A11y.Text.Classification.Exposes_Text (A11y.Text.Plain_Text));
   pragma Assert
     (not A11y.Text.Classification.Exposes_Text
        (A11y.Text.Protected_Text));
   pragma Assert
     (A11y.Text.Classification.Is_Protected
        (A11y.Text.Protected_Text));
   pragma Assert
     (A11y.Text.Classification.Edit_Requires_Range
        (A11y.Text.Insert_Text));
   pragma Assert
     (not A11y.Text.Classification.Edit_Requires_Range
        (A11y.Text.Set_Text));
   pragma Assert
     (A11y.Text.Classification.Edit_Requires_Text
        (A11y.Text.Replace_Text));
   pragma Assert
     (not A11y.Text.Classification.Edit_Requires_Text
        (A11y.Text.Delete_Text));
   pragma Assert
     (A11y.Text.Classification.Edit_Requires_Nonempty_Range
        (A11y.Text.Delete_Text));
   pragma Assert
     (A11y.Text.Classification.Edit_Span_Count_Allowed
        (A11y.Text.Insert_Text, 0));
   pragma Assert
     (not A11y.Text.Classification.Edit_Span_Count_Allowed
        (A11y.Text.Replace_Text, 0));
   pragma Assert
     (A11y.Text.Classification.Edit_Span_Count_Allowed
        (A11y.Text.Set_Text, 0));
   pragma Assert
     (not A11y.Text.Classification.Edit_Span_Count_Allowed
        (A11y.Text.Set_Text, 1));
   pragma Assert
     (A11y.Text.Classification.Edit_Allowed_By_Policy
        (A11y.Text.Plain_Text, False));
   pragma Assert
     (not A11y.Text.Classification.Edit_Allowed_By_Policy
        (A11y.Text.Protected_Text, False));
   pragma Assert
     (not A11y.Text.Classification.Edit_Allowed_By_Policy
        (A11y.Text.Plain_Text, True));
   pragma Assert
     (A11y.Text.Classification.Edit_Policy_Status
        (A11y.Text.Protected_Text, False) = A11y.Results.Permission_Denied);
   pragma Assert
     (A11y.Text.Classification.Edit_Policy_Status
        (A11y.Text.Protected_Text, True) = A11y.Results.Permission_Denied);
   pragma Assert
     (A11y.Text.Classification.Edit_Policy_Status
        (A11y.Text.Plain_Text, True) = A11y.Results.Read_Only);
   pragma Assert
     (A11y.Text.Classification.Edit_Policy_Status
        (A11y.Text.Plain_Text, False) = A11y.Results.Success);
end A11y_Proof_Harness;
