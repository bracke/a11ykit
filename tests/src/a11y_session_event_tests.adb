with A11y;
with A11y.Events;
with A11y.Node_Ids;
with A11y.Nodes;
with A11y.Relations;
with A11y.Registry;
with A11y.Resource_Limits;
with A11y.Results;
with A11y.Sessions;

with A11ykit_Test_Support;

package body A11y_Session_Event_Tests is
   use type A11y.Event_Sequence;
   use type A11y.Semantic_Revision;
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Nodes.Lifecycle_State;
   use type A11y.Results.Status_Code;

   procedure Check (Condition : Boolean; Message : String)
      renames A11ykit_Test_Support.Check;

   procedure Run_Attach_Destroy_Lifecycle_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root : A11y.Node_Ids.Node_Id;
      Child : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      Snapshot : A11y.Registry.Entry_Snapshot;
   begin
      A11y.Sessions.Create_Node (Session, null, Root, Result);
      Check (A11y.Results.Succeeded (Result), "session creates a root candidate");
      A11y.Sessions.Create_Node (Session, null, Child, Result);
      Check (A11y.Results.Succeeded (Result), "session creates a child candidate");
      Check
        (A11y.Sessions.Pending_Event_Count (Session) = 2,
         "session records node creation events");

      A11y.Sessions.Attach_Root (Session, Root, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Sessions.Is_Attached (Session, Root),
         "session commits root attachment before reporting success");
      A11y.Sessions.Registry_Snapshot (Session, Root, Snapshot, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Lifecycle = A11y.Nodes.Active
         and then Snapshot.Parent = A11y.Node_Ids.No_Node,
         "session commits lifecycle before emitting attachment events");

      A11y.Sessions.Attach (Session, Root, Child, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Sessions.Parent_Of (Session, Child) = Root,
         "session commits child ownership before events are consumed");
      A11y.Sessions.Registry_Snapshot (Session, Child, Snapshot, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Parent = Root,
         "session mirrors committed tree parent into registry metadata");

      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Created
         and then Event.Source = Root,
         "session emits root creation first");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Created
         and then Event.Source = Child,
         "session emits child creation second");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Attached
         and then Event.Source = Root,
         "session emits root attachment after state commit");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Child_Added
         and then Event.Source = Root,
         "session emits child-added before child attachment");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Attached
         and then Event.Source = Child,
         "session emits child attachment before later removal events");

      A11y.Sessions.Destroy (Session, Child, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Sessions.Is_Attached (Session, Child),
         "session destroys a child without leaving it attached");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Child_Removed
         and then Event.Source = Root,
         "session emits child-removed before detached and destroyed events");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Detached
         and then Event.Source = Child,
         "session emits node-detached before final destruction");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Destroyed
         and then Event.Source = Child,
         "session emits node-destroyed as the final node event");
      A11y.Sessions.Registry_Snapshot (Session, Child, Snapshot, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Tombstone
         and then Snapshot.Parent = A11y.Node_Ids.No_Node,
         "session leaves a tombstone for destroyed nodes");
      A11y.Sessions.Attach (Session, Root, Child, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable,
         "session rejects operations on destroyed nodes");
   end Run_Attach_Destroy_Lifecycle_Tests;

   procedure Run_Provider_Notification_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root : A11y.Node_Ids.Node_Id;
      Child : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      First_Revision : A11y.Semantic_Revision;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Sessions.Create_Node (Session, null, Root, Result);
      A11y.Sessions.Create_Node (Session, null, Child, Result);
      A11y.Sessions.Attach_Root (Session, Root, Result);
      A11y.Sessions.Attach (Session, Root, Child, Result);

      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Property_Changed, Result);
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      First_Revision := Event.Revision;
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Source = Child
         and then Event.Kind = A11y.Events.Property_Changed
         and then Event.Sequence /= A11y.No_Event,
         "session accepts provider property-change notifications");

      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Node_Destroyed, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects provider lifecycle notifications");
      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Child_Added, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects provider tree notifications");
      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Focus_Changed, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects provider focus notifications");
      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Relation_Targets_Changed, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects provider relation notifications");

      A11y.Sessions.Notify_Node_Event
        (Session, A11y.Node_Ids.No_Node, A11y.Events.State_Changed, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects provider notifications from invalid nodes");

      A11y.Sessions.Detach (Session, Child, Result);
      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;
      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Bounds_Changed, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects provider notifications from detached nodes");

      A11y.Sessions.Attach (Session, Root, Child, Result);
      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         1,
         Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Value_Changed, Result);
      A11y.Sessions.Notify_Node_Event
        (Session, Child, A11y.Events.Text_Inserted, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session rejects provider notifications before event overflow");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Value_Changed
         and then Event.Revision > First_Revision,
         "session notification events advance semantic revisions");
   end Run_Provider_Notification_Tests;

   procedure Run_Explicit_Detach_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root : A11y.Node_Ids.Node_Id;
      Child : A11y.Node_Ids.Node_Id;
      Filler : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Sessions.Create_Node (Session, null, Root, Result);
      A11y.Sessions.Create_Node (Session, null, Child, Result);
      A11y.Sessions.Attach_Root (Session, Root, Result);
      A11y.Sessions.Attach (Session, Root, Child, Result);

      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Sessions.Detach (Session, Child, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Sessions.Is_Attached (Session, Child)
         and then A11y.Sessions.Parent_Of (Session, Child)
           = A11y.Node_Ids.No_Node,
         "session commits explicit detach before events are consumed");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Child_Removed
         and then Event.Source = Root,
         "session emits parent child-removed for explicit detach first");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Detached
         and then Event.Source = Child,
         "session emits node-detached after explicit parent removal");

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         1,
         Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Create_Node (Session, null, Filler, Result);
      A11y.Sessions.Attach_Root (Session, Filler, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session rejects duplicate root attachment before event-capacity preflight");
      A11y.Sessions.Detach (Session, Child, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session rejects detached nodes before event-capacity preflight");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Limits := A11y.Resource_Limits.Default_Config;
      A11y.Sessions.Configure_Limits (Session, Limits, Result);

      A11y.Sessions.Attach (Session, Root, Child, Result);
      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         1,
         Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Set_Focus (Session, Child, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session fills a single event slot for attach validation checks");
      A11y.Sessions.Attach (Session, Root, Child, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session rejects already-attached children before event-capacity preflight");
      A11y.Sessions.Attach (Session, Child, Child, Result);
      Check
        (Result.Status = A11y.Results.Invalid_Argument
         and then A11y.Sessions.Pending_Event_Count (Session) = 1,
         "session rejects self-parent attachment before event-capacity preflight");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      A11y.Sessions.Detach (Session, Child, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then A11y.Sessions.Is_Attached (Session, Child)
         and then A11y.Sessions.Parent_Of (Session, Child) = Root
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects explicit detach before partial event emission");
   end Run_Explicit_Detach_Tests;

   procedure Run_Subtree_Detach_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root : A11y.Node_Ids.Node_Id;
      Child : A11y.Node_Ids.Node_Id;
      Grandchild : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      Snapshot : A11y.Registry.Entry_Snapshot;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Sessions.Create_Node (Session, null, Root, Result);
      A11y.Sessions.Create_Node (Session, null, Child, Result);
      A11y.Sessions.Create_Node (Session, null, Grandchild, Result);
      A11y.Sessions.Attach_Root (Session, Root, Result);
      A11y.Sessions.Attach (Session, Root, Child, Result);
      A11y.Sessions.Attach (Session, Child, Grandchild, Result);

      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Sessions.Set_Focus (Session, Grandchild, Result);
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      A11y.Sessions.Detach (Session, Child, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then not A11y.Sessions.Is_Attached (Session, Child)
         and then not A11y.Sessions.Is_Attached (Session, Grandchild)
         and then A11y.Sessions.Focused_Node (Session)
           = A11y.Node_Ids.No_Node,
         "session detaches explicit subtrees and clears contained focus");
      A11y.Sessions.Registry_Snapshot
        (Session, Grandchild, Snapshot, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Snapshot.Lifecycle = A11y.Nodes.Attached
         and then Snapshot.Parent = A11y.Node_Ids.No_Node
         and then not Snapshot.Tombstone,
         "session marks detached descendants live but non-exposed");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Focus_Changed
         and then Event.Source = Grandchild,
         "session emits focus clear before subtree detach events");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Child_Removed
         and then Event.Source = Root,
         "session emits parent removal for explicit subtree detach");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Detached
         and then Event.Source = Child,
         "session detaches explicit subtree roots");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Node_Detached
         and then Event.Source = Grandchild,
         "session detaches explicit subtree descendants");

      A11y.Sessions.Attach (Session, Root, Child, Result);
      A11y.Sessions.Attach (Session, Child, Grandchild, Result);
      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         2,
         Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Detach (Session, Child, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then A11y.Sessions.Is_Attached (Session, Child)
         and then A11y.Sessions.Is_Attached (Session, Grandchild)
         and then A11y.Sessions.Parent_Of (Session, Grandchild) = Child
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects subtree detach before partial event emission");
   end Run_Subtree_Detach_Tests;

   procedure Run_Cross_Parent_Move_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root : A11y.Node_Ids.Node_Id;
      Old_Parent : A11y.Node_Ids.Node_Id;
      New_Parent : A11y.Node_Ids.Node_Id;
      Child : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      Snapshot : A11y.Registry.Entry_Snapshot;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Sessions.Create_Node (Session, null, Root, Result);
      A11y.Sessions.Create_Node (Session, null, Old_Parent, Result);
      A11y.Sessions.Create_Node (Session, null, New_Parent, Result);
      A11y.Sessions.Create_Node (Session, null, Child, Result);
      A11y.Sessions.Attach_Root (Session, Root, Result);
      A11y.Sessions.Attach (Session, Root, Old_Parent, Result);
      A11y.Sessions.Attach (Session, Root, New_Parent, Result);
      A11y.Sessions.Attach (Session, Old_Parent, Child, Result);

      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Sessions.Move (Session, New_Parent, Child, Result);
      A11y.Sessions.Registry_Snapshot (Session, Child, Snapshot, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then A11y.Sessions.Parent_Of (Session, Child) = New_Parent
         and then Snapshot.Parent = New_Parent,
         "session commits cross-parent moves before events are consumed");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Child_Removed
         and then Event.Source = Old_Parent,
         "session emits old-parent child-removed for cross-parent moves");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Child_Added
         and then Event.Source = New_Parent,
         "session emits new-parent child-added for cross-parent moves");
      A11y.Sessions.Dequeue_Event (Session, Event, Result);
      Check
        (A11y.Results.Succeeded (Result)
         and then Event.Kind = A11y.Events.Children_Reordered
         and then Event.Source = New_Parent,
         "session emits reorder after cross-parent move ownership changes");

      A11y.Sessions.Move (Session, Old_Parent, Child, Result);
      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         2,
         Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Move (Session, New_Parent, Child, Result);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then A11y.Sessions.Parent_Of (Session, Child) = Old_Parent
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects cross-parent moves before partial event emission");

      A11y.Sessions.Move (Session, Child, Root, Result);
      Check
        (Result.Status = A11y.Results.Node_Unavailable
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects root moves before event-capacity preflight");

      A11y.Sessions.Move (Session, Child, Old_Parent, Result);
      Check
        (Result.Status = A11y.Results.Invalid_State
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects cyclic moves before event-capacity preflight");
   end Run_Cross_Parent_Move_Tests;

   procedure Run_Relation_Cleanup_Rollback_Tests is
      Session : A11y.Sessions.Semantic_Session;
      Root : A11y.Node_Ids.Node_Id;
      Field : A11y.Node_Ids.Node_Id;
      Label : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Event : A11y.Events.Event;
      Targets : A11y.Relations.Target_Vectors.Vector;
      Limits : A11y.Resource_Limits.Resource_Limit_Config :=
        A11y.Resource_Limits.Default_Config;
   begin
      A11y.Sessions.Create_Node (Session, null, Root, Result);
      A11y.Sessions.Create_Node (Session, null, Field, Result);
      A11y.Sessions.Create_Node (Session, null, Label, Result);
      A11y.Sessions.Attach_Root (Session, Root, Result);
      A11y.Sessions.Attach (Session, Root, Field, Result);
      A11y.Sessions.Attach (Session, Root, Label, Result);

      while A11y.Sessions.Pending_Event_Count (Session) > 0 loop
         A11y.Sessions.Dequeue_Event (Session, Event, Result);
      end loop;

      A11y.Sessions.Add_Relation
        (Session, Field, A11y.Relations.Labelled_By, Label, Result);
      A11y.Sessions.Dequeue_Event (Session, Event, Result);

      A11y.Resource_Limits.Set_Limit
        (Limits,
         A11y.Resource_Limits.Event_Queue_Size,
         3,
         Result);
      A11y.Sessions.Configure_Limits (Session, Limits, Result);
      A11y.Sessions.Destroy (Session, Label, Result);
      Targets := A11y.Sessions.Relation_Targets
        (Session, Field, A11y.Relations.Labelled_By);
      Check
        (Result.Status = A11y.Results.Resource_Limit
         and then Natural (Targets.Length) = 1
         and then Targets.First_Element = Label
         and then A11y.Sessions.Parent_Of (Session, Label) = Root
         and then A11y.Sessions.Pending_Event_Count (Session) = 0,
         "session rejects relation-cleanup destroy before partial mutation");
   end Run_Relation_Cleanup_Rollback_Tests;

   procedure Run is
   begin
      Run_Attach_Destroy_Lifecycle_Tests;
      Run_Provider_Notification_Tests;
      Run_Explicit_Detach_Tests;
      Run_Subtree_Detach_Tests;
      Run_Cross_Parent_Move_Tests;
      Run_Relation_Cleanup_Rollback_Tests;
   end Run;
end A11y_Session_Event_Tests;
