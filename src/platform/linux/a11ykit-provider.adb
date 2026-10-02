with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;
with A11ykit.Provider_Runtime;

with A11y.Events;
with A11y.Linux.ATSPi_Backend_Sessions;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.DBus_Auth;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Semantic_Snapshots;
with A11y.Sessions;
with A11y.Trees;
with Hostkit.Process;

package body A11ykit.Provider is
   use Ada.Strings.Unbounded;
   use type A11y.Results.Status_Code;

   Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;

   function Current_User return A11y.Linux.DBus_Auth.External_User_Id is
      User_Id : Natural := 0;
   begin
      if Hostkit.Process.Current_User_Id (User_Id) then
         return A11y.Linux.DBus_Auth.External_User_Id (User_Id);
      end if;
      return 0;
   exception
      when others =>
         return 0;
   end Current_User;

   function Root_Node
     (Tree   : A11ykit.Tree.Accessibility_Tree;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
   is
   begin
      Result := A11y.Results.Ok;
      if Tree.Nodes.Is_Empty then
         Result := (Status => A11y.Results.Invalid_State);
         return A11y.Node_Ids.No_Node;
      end if;

      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         if Tree.Nodes (Index).Parent = 0 then
            return A11ykit.Compatibility.Node_Id_For_Index (Tree, Index);
         end if;
      end loop;

      Result := (Status => A11y.Results.Invalid_State);
      return A11y.Node_Ids.No_Node;
   end Root_Node;

   procedure Build_Snapshots
     (Tree      : A11ykit.Tree.Accessibility_Tree;
      Root      : A11y.Node_Ids.Node_Id;
      Snapshots : out A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
      Metadata : A11y.Semantic_Snapshots.Node_Metadata;
      Check    : A11y.Results.Result;
   begin
      --  Publish allocates a fresh, default-initialized bundle. Reassigning the
      --  25+ MiB aggregate here would materialize a temporary on the caller's
      --  task stack before copying it into the heap-owned bundle.
      Snapshots.Accessible.Nodes :=
        A11ykit.Compatibility.To_Semantic_Snapshot (Tree, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Trees.Set_Root (Snapshots.Accessible.Tree, Root, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return;
      end if;

      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         declare
            Parent_Index : constant Natural := Tree.Nodes (Index).Parent;
         begin
            if Parent_Index /= 0 then
               A11y.Trees.Attach
                 (Snapshots.Accessible.Tree,
                  A11ykit.Compatibility.Node_Id_For_Index
                    (Tree, Parent_Index),
                  A11ykit.Compatibility.Node_Id_For_Index
                    (Tree, Index),
                  Check);
               if A11y.Results.Failed (Check) then
                  Result := Check;
                  return;
               end if;
            end if;
         end;
      end loop;

      Metadata :=
        A11y.Semantic_Snapshots.Metadata
          (Snapshots.Accessible.Nodes, Root);
      if not Metadata.Present then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Snapshots.Application.Id := Root;
      Snapshots.Application.Application_Id := 1;
      Snapshots.Application.Toolkit_Name := To_Unbounded_String ("a11ykit");
      Snapshots.Application.Version := To_Unbounded_String ("0.1.0-dev");

      Snapshots.Accessible.Id := Root;
      Snapshots.Accessible.Root := Root;
      Snapshots.Accessible.Role := Metadata.Role;
      Snapshots.Accessible.Name := Metadata.Name.Value;
      Snapshots.Accessible.Description := Metadata.Description.Value;
      Snapshots.Accessible.States := Metadata.States;
      Snapshots.Accessible.Capabilities := Metadata.Capabilities;
      Snapshots.Accessible.Use_Tree_Projection := True;
      Snapshots.Accessible.Use_Node_Metadata := True;

      Snapshots.Component.Id := Root;
      Snapshots.Component.Root := Root;
      Snapshots.Component.Bounds := Metadata.Bounds.Value;
      Snapshots.Component.Hit_Test_Node := Root;
      Snapshots.Component.Tree := Snapshots.Accessible.Tree;
      Snapshots.Component.Use_Tree_Projection := True;

      Snapshots.Action.Id := Root;
      Snapshots.Action.Root := Root;
      Snapshots.Action.Tree := Snapshots.Accessible.Tree;
      Snapshots.Action.Use_Tree_Projection := True;
      Snapshots.Action.States := Metadata.States;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Build_Snapshots;

   procedure Publish_Queued_Events
     (Semantic  : in out A11y.Sessions.Semantic_Session;
      Delivered : out Natural;
      Result    : out A11y.Results.Result)
   is
      Event : A11y.Events.Event;
      Queue_Result : A11y.Results.Result;
      Ack_Result : A11y.Results.Result;
   begin
      Delivered := 0;
      while A11y.Sessions.Pending_Event_Count (Semantic) > 0 loop
         if Delivered >= A11y.Sessions.Event_Capacity (Semantic) then
            Result := (Status => A11y.Results.Resource_Limit);
            return;
         end if;

         A11y.Sessions.Peek_Event (Semantic, Event, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         A11y.Linux.ATSPi_Backend_Sessions.Queue_Event_Signal
           (Session, Event, Queue_Result);
         if A11y.Results.Failed (Queue_Result) then
            Result := Queue_Result;
            return;
         end if;

         A11y.Sessions.Acknowledge_Event
           (Semantic, Event.Sequence, Ack_Result);
         if A11y.Results.Failed (Ack_Result) then
            Result := Ack_Result;
            return;
         end if;
         Delivered := Delivered + 1;
      end loop;
      Result := A11y.Results.Ok;
   exception
      when others =>
         Delivered := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Publish_Queued_Events;

   function Available return Boolean is
   begin
      return A11y.Linux.ATSPi_Backend_Sessions.Registered (Session);
   end Available;

   procedure Start is
   begin
      null;
   end Start;

   procedure Stop is
      Result : A11y.Results.Result;
   begin
      if A11y.Linux.ATSPi_Backend_Sessions.Registered (Session) then
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
      end if;
   exception
      when others =>
         null;
   end Stop;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
      type Semantic_Access is access A11y.Sessions.Semantic_Session;
      type Snapshot_Access is access
        A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
      procedure Free is new Ada.Unchecked_Deallocation
        (A11y.Sessions.Semantic_Session, Semantic_Access);
      procedure Free is new Ada.Unchecked_Deallocation
        (A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle, Snapshot_Access);

      Root : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Semantic : Semantic_Access := null;
      Snapshots : Snapshot_Access := null;
      Delivered : Natural := 0;
      Event_Loop_Report :
        A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;

      procedure Release_Working_State is
      begin
         Free (Semantic);
         Free (Snapshots);
      end Release_Working_State;
   begin
      Root := Root_Node (Tree, Result);
      if A11y.Results.Failed (Result) then
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      --  Both semantic sessions and native snapshot bundles contain bounded
      --  stores sized for a complete accessibility tree. Keep them off the
      --  caller's stack: GUI and test runtimes commonly give Ada tasks a much
      --  smaller stack than the main environment task.
      Semantic := new A11y.Sessions.Semantic_Session;
      Snapshots := new A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;

      Build_Snapshots (Tree, Root, Snapshots.all, Result);
      if A11y.Results.Failed (Result) then
         Release_Working_State;
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      A11ykit.Compatibility.Populate_Session (Tree, Semantic.all, Result);
      if A11y.Results.Failed (Result) then
         Release_Working_State;
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      if A11y.Linux.ATSPi_Backend_Sessions.Registered (Session) then
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
      end if;

      A11y.Linux.ATSPi_Backend_Sessions.Start_From_Host_Environment
        (Session, Current_User, Root, Result);
      if A11y.Results.Failed (Result)
        or else not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session)
      then
         Release_Working_State;
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Publish_Queued_Events (Semantic.all, Delivered, Result);
      if A11y.Results.Failed (Result) then
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
         Release_Working_State;
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
        (Session, Snapshots.all, 8, 0, Event_Loop_Report, Result);
      if Result.Status = A11y.Results.Backend_Unavailable then
         Result := A11y.Results.Ok;
      elsif A11y.Results.Failed (Result) then
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
         Release_Working_State;
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Release_Working_State;
      A11ykit.Provider_Runtime.Record_Publish_Result
        (Result.Status, Delivered, Backend_Name, False, Result.Status);
   exception
      when others =>
         Release_Working_State;
         A11ykit.Provider_Runtime.Record_Publish_Result
           (A11y.Results.Internal_Error, 0, Backend_Name, False,
            A11y.Results.Internal_Error);
   end Publish;

   function Last_Publish_Status return A11y.Results.Status_Code is
     (A11ykit.Provider_Runtime.Last_Publish_Status);

   function Last_Published_Event_Count return Natural is
     (A11ykit.Provider_Runtime.Last_Published_Event_Count);

   function Last_Publish_Backend_Name return String is
     (A11ykit.Provider_Runtime.Last_Publish_Backend_Name);

   function Last_Publish_Used_Fallback return Boolean is
     (A11ykit.Provider_Runtime.Last_Publish_Used_Fallback);

   function Last_Publish_Selection_Status return A11y.Results.Status_Code is
     (A11ykit.Provider_Runtime.Last_Publish_Selection_Status);

   function Backend_Name return String is
   begin
      return A11y.Platforms.Native_Backend_Name;
   end Backend_Name;

end A11ykit.Provider;
