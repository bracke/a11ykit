with A11y.Trees.Exposure_Views;

package body A11y.Sessions is
   use type A11y.Capabilities.Capability_Set;
   use type A11y.Events.Event_Kind;
   use type A11y.Node_Ids.Node_Id;
   use type A11y.Registry.Node_Access;
   use type A11y.Relations.Relation_Kind;

   procedure Next_Revision (Self : in out Semantic_Session) is
   begin
      Self.Revision := Self.Revision + 1;
   end Next_Revision;

   procedure Require_Event_Capacity
     (Self   : Semantic_Session;
      Count  : Natural;
      Result : out A11y.Results.Result)
   is
   begin
      if A11y.Event_Queues.Available_Capacity (Self.Events) < Count then
         Result := (Status => A11y.Results.Resource_Limit);
      else
         Result := A11y.Results.Ok;
      end if;
   end Require_Event_Capacity;

   procedure Validate_Provider
     (Provider     : A11y.Registry.Node_Access;
      Capabilities : out A11y.Capabilities.Capability_Set;
      Result       : out A11y.Results.Result)
   is
      Snapshot : A11y.Nodes.Node_Contract_Snapshot;
   begin
      Capabilities := A11y.Capabilities.Empty_Capability_Set;
      if Provider = null then
         Result := A11y.Results.Ok;
         return;
      end if;

      Snapshot := A11y.Nodes.Contract_Snapshot_Safely (Provider.all, Result);
      Capabilities := Snapshot.Capabilities;
   end Validate_Provider;

   procedure Configure_Limits
     (Self   : in out Semantic_Session;
      Limits : A11y.Resource_Limits.Resource_Limit_Config;
      Result : out A11y.Results.Result)
   is
   begin
      A11y.Event_Queues.Can_Configure (Self.Events, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Relations.Can_Configure_Limits (Self.Relations, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Can_Configure_Limits (Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Event_Queues.Configure (Self.Events, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Relations.Configure_Limits (Self.Relations, Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Configure_Limits (Limits, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Limits := Limits;
   end Configure_Limits;

   procedure Emit
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Events.Event_Kind;
      Result : out A11y.Results.Result)
   is
      Event : A11y.Events.Event;
   begin
      Next_Revision (Self);
      A11y.Event_Queues.Enqueue
        (Self.Events, Source, Kind, Self.Revision, Event, Result);
   end Emit;

   function Is_Provider_Notification
     (Kind : A11y.Events.Event_Kind)
      return Boolean is
     (not A11y.Events.Is_Lifecycle_Event (Kind)
      and then not A11y.Events.Is_Tree_Event (Kind)
      and then not A11y.Events.Is_Relation_Event (Kind)
      and then Kind /= A11y.Events.Focus_Changed);

   function Node_Available
     (Self : in out Semantic_Session;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Snapshot : A11y.Registry.Entry_Snapshot;
      Result : A11y.Results.Result;
   begin
      Self.Registry.Snapshot (Node, Snapshot, Result);
      return A11y.Results.Succeeded (Result) and then not Snapshot.Tombstone;
   end Node_Available;

   function Relation_Target_Present
     (Self   : Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind;
      Target : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Targets : constant A11y.Relations.Target_Vectors.Vector :=
        A11y.Relations.Targets (Self.Relations, Source, Kind);
   begin
      for Item of Targets loop
         if Item = Target then
            return True;
         end if;
      end loop;

      return False;
   end Relation_Target_Present;

   function Subtree_Contains
     (Items : A11y.Trees.Child_Vectors.Vector;
      Node  : A11y.Node_Ids.Node_Id)
      return Boolean
   is
   begin
      if not A11y.Node_Ids.Is_Valid (Node) then
         return False;
      end if;

      for Item of Items loop
         if Item = Node then
            return True;
         end if;
      end loop;

      return False;
   end Subtree_Contains;

   function Is_Strict_Descendant
     (Self     : Semantic_Session;
      Ancestor : A11y.Node_Ids.Node_Id;
      Node     : A11y.Node_Ids.Node_Id)
      return Boolean
   is
      Current : A11y.Node_Ids.Node_Id := A11y.Trees.Parent_Of
        (Self.Tree, Node);
   begin
      while A11y.Node_Ids.Is_Valid (Current) loop
         if Current = Ancestor then
            return True;
         end if;
         Current := A11y.Trees.Parent_Of (Self.Tree, Current);
      end loop;

      return False;
   end Is_Strict_Descendant;

   procedure Create_Node
     (Self     : in out Semantic_Session;
      Provider : A11y.Registry.Node_Access;
      Id       : out A11y.Node_Ids.Node_Id;
      Result   : out A11y.Results.Result)
   is
      Capabilities : A11y.Capabilities.Capability_Set;
   begin
      Id := A11y.Node_Ids.No_Node;
      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Validate_Provider (Provider, Capabilities, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Allocate (Id);
      if not A11y.Node_Ids.Is_Valid (Id) then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Self.Registry.Register
        (Id, Provider, Result, Capabilities => Capabilities);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Id, A11y.Events.Node_Created, Result);
   end Create_Node;

   procedure Create_Node_With_Capabilities
     (Self         : in out Semantic_Session;
      Provider     : A11y.Registry.Node_Access;
      Capabilities : A11y.Capabilities.Capability_Set;
      Id           : out A11y.Node_Ids.Node_Id;
      Result       : out A11y.Results.Result)
   is
      Provider_Capabilities : A11y.Capabilities.Capability_Set;
   begin
      Id := A11y.Node_Ids.No_Node;
      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if Provider /= null then
         Validate_Provider (Provider, Provider_Capabilities, Result);
         if A11y.Results.Failed (Result) then
            return;
         elsif Provider_Capabilities /= Capabilities then
            Result := (Status => A11y.Results.Invalid_State);
            return;
         end if;
      end if;

      Self.Registry.Allocate (Id);
      if not A11y.Node_Ids.Is_Valid (Id) then
         Result := (Status => A11y.Results.Resource_Limit);
         return;
      end if;

      Self.Registry.Register
        (Id, Provider, Result, Capabilities => Capabilities);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Id, A11y.Events.Node_Created, Result);
   end Create_Node_With_Capabilities;

   procedure Attach_Root
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not Node_Available (Self, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if A11y.Node_Ids.Is_Valid (A11y.Trees.Root (Self.Tree))
        or else A11y.Trees.Is_Attached (Self.Tree, Node)
      then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Trees.Set_Root (Self.Tree, Node, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Set_Lifecycle (Node, A11y.Nodes.Active, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Set_Parent (Node, A11y.Node_Ids.No_Node, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Node, A11y.Events.Node_Attached, Result);
   end Attach_Root;

   procedure Attach
     (Self   : in out Semantic_Session;
      Parent : A11y.Node_Ids.Node_Id;
      Child  : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not Node_Available (Self, Parent)
        or else not Node_Available (Self, Child)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if Parent = Child then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif not A11y.Trees.Is_Attached (Self.Tree, Parent) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      elsif A11y.Trees.Is_Attached (Self.Tree, Child) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Require_Event_Capacity (Self, 2, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Trees.Attach (Self.Tree, Parent, Child, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Set_Parent (Child, Parent, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Set_Lifecycle (Child, A11y.Nodes.Active, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Parent, A11y.Events.Child_Added, Result);
      if A11y.Results.Succeeded (Result) then
         Emit (Self, Child, A11y.Events.Node_Attached, Result);
      end if;
   end Attach;

   procedure Detach
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Ignored : A11y.Results.Result;
      Detached : A11y.Trees.Child_Vectors.Vector;
      Old_Parent : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Event_Count : Natural := 1;

      procedure Collect_Subtree (Current : A11y.Node_Ids.Node_Id) is
         Children : constant A11y.Trees.Child_Vectors.Vector :=
           A11y.Trees.Children_Of (Self.Tree, Current);
      begin
         Detached.Append (Current);
         for Child of Children loop
            Collect_Subtree (Child);
         end loop;
      end Collect_Subtree;
   begin
      if not Node_Available (Self, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      elsif not A11y.Trees.Is_Attached (Self.Tree, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Old_Parent := A11y.Trees.Parent_Of (Self.Tree, Node);
      Collect_Subtree (Node);
      Event_Count := Natural (Detached.Length);
      if A11y.Node_Ids.Is_Valid (Old_Parent) then
         Event_Count := Event_Count + 1;
      end if;
      if Subtree_Contains (Detached, Self.Focused) then
         Event_Count := Event_Count + 1;
      end if;

      Require_Event_Capacity (Self, Event_Count, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Trees.Detach_Subtree (Self.Tree, Node, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      for Detached_Node of Detached loop
         Self.Registry.Set_Lifecycle
           (Detached_Node, A11y.Nodes.Attached, Ignored);
         if A11y.Results.Failed (Ignored) then
            Result := Ignored;
            return;
         end if;

         Self.Registry.Set_Parent
           (Detached_Node, A11y.Node_Ids.No_Node, Ignored);
         if A11y.Results.Failed (Ignored) then
            Result := Ignored;
            return;
         end if;
      end loop;

      if Subtree_Contains (Detached, Self.Focused) then
         declare
            Old_Focus : constant A11y.Node_Ids.Node_Id := Self.Focused;
         begin
            Self.Focused := A11y.Node_Ids.No_Node;
            Emit (Self, Old_Focus, A11y.Events.Focus_Changed, Result);
            if A11y.Results.Failed (Result) then
               return;
            end if;
         end;
      end if;

      if A11y.Node_Ids.Is_Valid (Old_Parent) then
         Emit (Self, Old_Parent, A11y.Events.Child_Removed, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end if;

      for Detached_Node of Detached loop
         Emit (Self, Detached_Node, A11y.Events.Node_Detached, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end loop;
   end Detach;

   procedure Move
     (Self       : in out Semantic_Session;
      New_Parent : A11y.Node_Ids.Node_Id;
      Node       : A11y.Node_Ids.Node_Id;
      Result     : out A11y.Results.Result)
   is
      Old_Parent : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Event_Count : Natural := 1;
      Current : A11y.Node_Ids.Node_Id := New_Parent;
   begin
      if not Node_Available (Self, New_Parent)
        or else not Node_Available (Self, Node)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      elsif New_Parent = Node then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif Node = A11y.Trees.Root (Self.Tree)
        or else not A11y.Trees.Is_Attached (Self.Tree, Node)
        or else not A11y.Trees.Is_Attached (Self.Tree, New_Parent)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Old_Parent := A11y.Trees.Parent_Of (Self.Tree, Node);
      while A11y.Node_Ids.Is_Valid (Current) loop
         if Current = Node then
            Result := (Status => A11y.Results.Invalid_State);
            return;
         end if;
         Current := A11y.Trees.Parent_Of (Self.Tree, Current);
      end loop;

      if A11y.Node_Ids.Is_Valid (Old_Parent)
        and then Old_Parent /= New_Parent
      then
         Event_Count := 3;
      end if;

      Require_Event_Capacity (Self, Event_Count, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Trees.Move (Self.Tree, New_Parent, Node, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Registry.Set_Parent (Node, New_Parent, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if A11y.Node_Ids.Is_Valid (Old_Parent)
        and then Old_Parent /= New_Parent
      then
         Emit (Self, Old_Parent, A11y.Events.Child_Removed, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Emit (Self, New_Parent, A11y.Events.Child_Added, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end if;

      Emit (Self, New_Parent, A11y.Events.Children_Reordered, Result);
   end Move;

   procedure Destroy
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Ignored : A11y.Results.Result;
      Detached : A11y.Trees.Child_Vectors.Vector;
      Was_Attached : Boolean := False;
      Old_Parent : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
      Event_Count : Natural := 1;
      Clear_Focus : Boolean := False;
      Relation_Sources : A11y.Relations.Target_Vectors.Vector;
      Active_Descendant_Sources : A11y.Relations.Target_Vectors.Vector;

      procedure Append_Unique
        (Items : in out A11y.Relations.Target_Vectors.Vector;
         Node  : A11y.Node_Ids.Node_Id)
      is
      begin
         for Item of Items loop
            if Item = Node then
               return;
            end if;
         end loop;
         Items.Append (Node);
      end Append_Unique;

      procedure Collect_Subtree (Current : A11y.Node_Ids.Node_Id) is
         Children : constant A11y.Trees.Child_Vectors.Vector :=
           A11y.Trees.Children_Of (Self.Tree, Current);
      begin
         Detached.Append (Current);
         for Child of Children loop
            Collect_Subtree (Child);
         end loop;
      end Collect_Subtree;
   begin
      if not Node_Available (Self, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Was_Attached := A11y.Trees.Is_Attached (Self.Tree, Node);
      if Was_Attached then
         Old_Parent := A11y.Trees.Parent_Of (Self.Tree, Node);
         Collect_Subtree (Node);
         Event_Count := Natural (Detached.Length) + 1;
         if A11y.Node_Ids.Is_Valid (Old_Parent) then
            Event_Count := Event_Count + 1;
         end if;
      end if;
      Clear_Focus := Subtree_Contains (Detached, Self.Focused)
        or else (not Was_Attached and then Self.Focused = Node);
      if Clear_Focus then
         Event_Count := Event_Count + 1;
      end if;

      for Kind in A11y.Relations.Relation_Kind loop
         declare
            Sources : constant A11y.Relations.Target_Vectors.Vector :=
              A11y.Relations.Sources_Targeting (Self.Relations, Node, Kind);
         begin
            for Source of Sources loop
               if Kind = A11y.Relations.Active_Descendant then
                  Append_Unique (Active_Descendant_Sources, Source);
               else
                  Append_Unique (Relation_Sources, Source);
               end if;
            end loop;
         end;
      end loop;
      Event_Count := Event_Count + Natural (Relation_Sources.Length);
      Event_Count := Event_Count + Natural (Active_Descendant_Sources.Length);

      Require_Event_Capacity (Self, Event_Count, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if Clear_Focus then
         declare
            Old_Focus : constant A11y.Node_Ids.Node_Id := Self.Focused;
         begin
            Self.Focused := A11y.Node_Ids.No_Node;
            Emit (Self, Old_Focus, A11y.Events.Focus_Changed, Result);
            if A11y.Results.Failed (Result) then
               return;
            end if;
         end;
      end if;

      if Was_Attached then
         A11y.Trees.Detach_Subtree (Self.Tree, Node, Ignored);
         if A11y.Results.Failed (Ignored) then
            Result := Ignored;
            return;
         end if;

         for Detached_Node of Detached loop
            if Detached_Node /= Node then
               Self.Registry.Set_Parent
                 (Detached_Node, A11y.Node_Ids.No_Node, Ignored);
               if A11y.Results.Failed (Ignored) then
                  Result := Ignored;
                  return;
               end if;

               Self.Registry.Set_Lifecycle
                 (Detached_Node, A11y.Nodes.Attached, Ignored);
               if A11y.Results.Failed (Ignored) then
                  Result := Ignored;
                  return;
               end if;
            end if;
         end loop;
      end if;

      Self.Registry.Set_Lifecycle (Node, A11y.Nodes.Removing, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Relations.Remove_Node (Self.Relations, Node);

      for Source of Active_Descendant_Sources loop
         Emit
           (Self,
            Source,
            A11y.Events.Active_Descendant_Changed,
            Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end loop;

      for Source of Relation_Sources loop
         Emit
           (Self,
            Source,
            A11y.Events.Relation_Targets_Changed,
            Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;
      end loop;

      Self.Registry.Remove (Node, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      if Was_Attached then
         if A11y.Node_Ids.Is_Valid (Old_Parent) then
            Emit (Self, Old_Parent, A11y.Events.Child_Removed, Result);
            if A11y.Results.Failed (Result) then
               return;
            end if;
         end if;

         Emit (Self, Node, A11y.Events.Node_Detached, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         for Detached_Node of Detached loop
            if Detached_Node /= Node then
               Emit
                 (Self,
                  Detached_Node,
                  A11y.Events.Node_Detached,
                  Result);
               if A11y.Results.Failed (Result) then
                  return;
               end if;
            end if;
         end loop;
      end if;

      Emit (Self, Node, A11y.Events.Node_Destroyed, Result);
   end Destroy;

   procedure Set_Focus
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not Node_Available (Self, Node) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      elsif not A11y.Trees.Is_Attached (Self.Tree, Node) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      elsif Self.Focused = Node then
         Result := A11y.Results.Ok;
         return;
      end if;

      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Self.Focused := Node;
      Emit (Self, Node, A11y.Events.Focus_Changed, Result);
   end Set_Focus;

   procedure Notify_Node_Event
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Events.Event_Kind;
      Result : out A11y.Results.Result)
   is
   begin
      if not Is_Provider_Notification (Kind) then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      elsif not Node_Available (Self, Source) then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      elsif not A11y.Trees.Is_Attached (Self.Tree, Source) then
         Result := (Status => A11y.Results.Invalid_State);
         return;
      end if;

      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Source, Kind, Result);
   end Notify_Node_Event;

   procedure Add_Relation
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
      Existing : A11y.Relations.Target_Vectors.Vector;
      Ignored : A11y.Results.Result;
   begin
      if not Node_Available (Self, Source)
        or else not Node_Available (Self, Target)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if Kind = A11y.Relations.Active_Descendant
        and then not Is_Strict_Descendant (Self, Source, Target)
      then
         Result := (Status => A11y.Results.Invalid_Argument);
         return;
      end if;

      if Relation_Target_Present (Self, Source, Kind, Target) then
         Result := A11y.Results.Ok;
         return;
      end if;

      if Kind = A11y.Relations.Active_Descendant then
         Require_Event_Capacity (Self, 1, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Existing := A11y.Relations.Targets (Self.Relations, Source, Kind);
         for Item of Existing loop
            A11y.Relations.Remove (Self.Relations, Source, Kind, Item, Ignored);
         end loop;

         A11y.Relations.Add (Self.Relations, Source, Kind, Target, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Emit (Self, Source, A11y.Events.Active_Descendant_Changed, Result);
         return;
      end if;

      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Relations.Add (Self.Relations, Source, Kind, Target, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Source, A11y.Events.Relation_Added, Result);
   end Add_Relation;

   procedure Remove_Relation
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind;
      Target : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
   is
   begin
      if not Node_Available (Self, Source)
        or else not Node_Available (Self, Target)
      then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      if not Relation_Target_Present (Self, Source, Kind, Target) then
         Result := A11y.Results.Ok;
         return;
      end if;

      if Kind = A11y.Relations.Active_Descendant then
         Require_Event_Capacity (Self, 1, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         A11y.Relations.Remove (Self.Relations, Source, Kind, Target, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Emit (Self, Source, A11y.Events.Active_Descendant_Changed, Result);
         return;
      end if;

      Require_Event_Capacity (Self, 1, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Relations.Remove (Self.Relations, Source, Kind, Target, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      Emit (Self, Source, A11y.Events.Relation_Removed, Result);
   end Remove_Relation;

   procedure Dequeue_Event
     (Self   : in out Semantic_Session;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result)
   is
   begin
      A11y.Event_Queues.Dequeue (Self.Events, Event, Result);
   end Dequeue_Event;

   procedure Peek_Event
     (Self   : Semantic_Session;
      Event  : out A11y.Events.Event;
      Result : out A11y.Results.Result)
   is
   begin
      A11y.Event_Queues.Peek (Self.Events, Event, Result);
   end Peek_Event;

   procedure Acknowledge_Event
     (Self     : in out Semantic_Session;
      Sequence : A11y.Event_Sequence;
      Result   : out A11y.Results.Result)
   is
   begin
      A11y.Event_Queues.Acknowledge (Self.Events, Sequence, Result);
   end Acknowledge_Event;

   function Is_Attached
     (Self : Semantic_Session;
      Node : A11y.Node_Ids.Node_Id)
      return Boolean is
     (A11y.Trees.Is_Attached (Self.Tree, Node));

   function Parent_Of
     (Self : Semantic_Session;
      Node : A11y.Node_Ids.Node_Id)
      return A11y.Node_Ids.Node_Id is
     (A11y.Trees.Parent_Of (Self.Tree, Node));

   procedure Exposed_Children_Of
     (Self     : in out Semantic_Session;
      Node     : A11y.Node_Ids.Node_Id;
      Children : out A11y.Trees.Child_Vectors.Vector;
      Result   : out A11y.Results.Result)
   is
      function Exposure_Of
        (Item : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy
      is
         Provider : A11y.Registry.Node_Access;
         State    : A11y.Nodes.Lifecycle_State;
         Lookup_Result : A11y.Results.Result;
         Snapshot_Result : A11y.Results.Result;
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
      begin
         Self.Registry.Lookup (Item, Provider, State, Lookup_Result);
         if A11y.Results.Failed (Lookup_Result) then
            return A11y.Nodes.Hide_Node_And_Subtree;
         elsif Provider = null then
            return A11y.Nodes.Expose_Node;
         end if;

         Snapshot :=
           A11y.Nodes.Contract_Snapshot_Safely
             (Provider.all, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            return A11y.Nodes.Hide_Node_And_Subtree;
         end if;

         return Snapshot.Exposure;
      exception
         when others =>
            return A11y.Nodes.Hide_Node_And_Subtree;
      end Exposure_Of;

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Exposure_Of);
   begin
      Exposure_View.Exposed_Children_Of
        (Self.Tree, Node, Self.Limits, Children, Result);
   end Exposed_Children_Of;

   function Exposed_Parent_Of
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
      function Exposure_Of
        (Item : A11y.Node_Ids.Node_Id)
         return A11y.Nodes.Exposure_Policy
      is
         Provider : A11y.Registry.Node_Access;
         State    : A11y.Nodes.Lifecycle_State;
         Lookup_Result : A11y.Results.Result;
         Snapshot_Result : A11y.Results.Result;
         Snapshot : A11y.Nodes.Node_Contract_Snapshot;
      begin
         Self.Registry.Lookup (Item, Provider, State, Lookup_Result);
         if A11y.Results.Failed (Lookup_Result) then
            return A11y.Nodes.Hide_Node_And_Subtree;
         elsif Provider = null then
            return A11y.Nodes.Expose_Node;
         end if;

         Snapshot :=
           A11y.Nodes.Contract_Snapshot_Safely
             (Provider.all, Snapshot_Result);
         if A11y.Results.Failed (Snapshot_Result) then
            return A11y.Nodes.Hide_Node_And_Subtree;
         end if;

         return Snapshot.Exposure;
      exception
         when others =>
            return A11y.Nodes.Hide_Node_And_Subtree;
      end Exposure_Of;

      package Exposure_View is new A11y.Trees.Exposure_Views
        (Exposure_Of => Exposure_Of);
   begin
      return Exposure_View.Exposed_Parent_Of
        (Self.Tree, Node, Self.Limits, Result);
   end Exposed_Parent_Of;

   function Focused_Node
     (Self : Semantic_Session)
      return A11y.Node_Ids.Node_Id is
     (Self.Focused);

   function Relation_Targets
     (Self   : in out Semantic_Session;
      Source : A11y.Node_Ids.Node_Id;
      Kind   : A11y.Relations.Relation_Kind)
      return A11y.Relations.Target_Vectors.Vector
   is
      Raw : constant A11y.Relations.Target_Vectors.Vector :=
        A11y.Relations.Targets (Self.Relations, Source, Kind);
      Filtered : A11y.Relations.Target_Vectors.Vector;

      function Externally_Exposed
        (Node : A11y.Node_Ids.Node_Id)
         return Boolean
      is
         Result : A11y.Results.Result;
         Parent : A11y.Node_Ids.Node_Id;
      begin
         if not A11y.Trees.Is_Attached (Self.Tree, Node) then
            return False;
         end if;

         Parent := Exposed_Parent_Of (Self, Node, Result);
         return A11y.Results.Succeeded (Result)
           and then
             (A11y.Node_Ids.Is_Valid (Parent)
              or else Node = A11y.Trees.Root (Self.Tree));
      end Externally_Exposed;
   begin
      if not Externally_Exposed (Source) then
         return A11y.Relations.Target_Vectors.Empty_Vector;
      end if;

      for Target of Raw loop
         if Externally_Exposed (Target) then
            Filtered.Append (Target);
         end if;
      end loop;

      return Filtered;
   end Relation_Targets;

   procedure Registry_Snapshot
     (Self   : in out Semantic_Session;
      Node   : A11y.Node_Ids.Node_Id;
      Item   : out A11y.Registry.Entry_Snapshot;
      Result : out A11y.Results.Result)
   is
   begin
      Self.Registry.Snapshot (Node, Item, Result);
   end Registry_Snapshot;

   function Validate_Tree (Self : Semantic_Session) return A11y.Results.Result is
     (A11y.Trees.Validate (Self.Tree));

   function Pending_Event_Count (Self : Semantic_Session) return Natural is
     (A11y.Event_Queues.Length (Self.Events));

   function Event_Capacity (Self : Semantic_Session) return Natural is
     (A11y.Event_Queues.Capacity (Self.Events));

end A11y.Sessions;
