with Ada.Text_IO;
with Ada.Calendar;
with Ada.Containers.Vectors;
with Ada.Command_Line;
with Ada.Directories;
with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;
with A11ykit.Provider_Runtime;

with A11y;
with A11y.Events;
with A11y.Linux.ATSPi_Backend_Sessions;
with A11y.Linux.ATSPi_Startup;
with A11y.Linux.ATSPi_Method_Router;
with A11y.Linux.ATSPi_Requests;
with A11y.Linux.ATSPi_Object_Registry;
with A11y.Linux.DBus_Auth;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Semantic_Snapshots;
with A11y.Sessions;
with A11y.Trees;
with Hostkit.Process;

package body A11ykit.Provider is
   use Ada.Strings.Unbounded;
   use type A11y.Event_Sequence;
   use type A11y.Events.Event_Kind;
   use type A11y.Results.Status_Code;
   use type A11y.Linux.ATSPi_Startup.Pump_Bounded_Stop_Reason;

   Session : A11y.Linux.ATSPi_Backend_Sessions.Backend_Session;

   type Snapshot_Access is access A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle;
   procedure Free is new Ada.Unchecked_Deallocation
     (A11y.Linux.ATSPi_Method_Router.Snapshot_Bundle, Snapshot_Access);

   --  The tree the screen reader is answered from between publications. A
   --  registration lives as long as the application does: the session is
   --  started once and only its snapshots are replaced, because a screen
   --  reader holds on to the application it found and its object paths.
   Latest : Snapshot_Access := null;

   --  The window's focus as last reported by Set_Active, and the last tree
   --  published, so a focus change can be published without the application.
   Window_Active : Boolean := False;
   Last_Tree     : A11ykit.Tree.Accessibility_Tree;

   --  What the screen reader last heard: each node's signature (its role,
   --  name and parent) and which node had the focus.
   package Signature_Vectors is new Ada.Containers.Vectors (Positive, Unbounded_String);

   Last_Signatures : Signature_Vectors.Vector;

   package Index_Vectors is new Ada.Containers.Vectors (Positive, Natural);

   --  Each node's parent in the last publication, to tell a parent that a
   --  child is gone.
   Last_Parents : Index_Vectors.Vector;
   Last_Focus      : Unbounded_String;

   --  Nodes whose signature differs from the last publication's, or that are
   --  new; only these are announced again.
   Changed : array (1 .. 65_536) of Boolean := [others => False];

   function Signatures_Of (Tree : A11ykit.Tree.Accessibility_Tree) return Signature_Vectors.Vector is
      Result : Signature_Vectors.Vector;
   begin
      for Item of Tree.Nodes loop
         Result.Append
           (To_Unbounded_String
              (A11ykit.Role'Image (Item.Node_Role) & ASCII.NUL & To_String (Item.Name)
               & ASCII.NUL & Natural'Image (Item.Parent)));
      end loop;
      return Result;
   end Signatures_Of;

   function Focus_Of (Tree : A11ykit.Tree.Accessibility_Tree) return Unbounded_String is
     (if Tree.Focused = 0 then Null_Unbounded_String
      else To_Unbounded_String
             (Natural'Image (Tree.Focused) & ASCII.NUL & To_String (Tree.Nodes (Tree.Focused).Name)));

   --  The sequence number given to the last event handed to the backend.
   Last_Delivered : A11y.Event_Sequence := A11y.No_Event;


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

      A11ykit.Compatibility.Attach_Parents_First (Tree, Snapshots.Accessible.Tree, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return;
      end if;

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

   --  Which of a publication's events go out: a changed tree announces all
   --  of them; an unchanged one only a focus that moved, or nothing.
   type Event_Filter is (All_Events, Changed_Nodes, Focus_Only, No_Events);

   procedure Publish_Queued_Events
     (Semantic  : in out A11y.Sessions.Semantic_Session;
      Which     : Event_Filter;
      Focus_Moved : Boolean;
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

         if Which = All_Events
           or else (Which in Changed_Nodes | Focus_Only
                    and then Event.Kind = A11y.Events.Focus_Changed
                    and then Focus_Moved)
           or else (Which = Changed_Nodes
                    and then A11y.Node_Ids.To_Natural (Event.Source) in Changed'Range
                    and then Changed (A11y.Node_Ids.To_Natural (Event.Source)))
         then
            --  Each publication's semantic session numbers its events from
            --  the start, while the backend admits only ever-later sequences;
            --  number them afresh from one counter that lives as long as the
            --  provider.
            Last_Delivered := Last_Delivered + 1;
            A11y.Linux.ATSPi_Backend_Sessions.Queue_Event_Signal
              (Session, (Event with delta Sequence => Last_Delivered), Queue_Result);
            if A11y.Results.Failed (Queue_Result) then
               Result := Queue_Result;
               return;
            end if;
            Delivered := Delivered + 1;
         end if;

         A11y.Sessions.Acknowledge_Event
           (Semantic, Event.Sequence, Ack_Result);
         if A11y.Results.Failed (Ack_Result) then
            Result := Ack_Result;
            return;
         end if;
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

   --  A11YKIT_TRACE set in the environment reports, on standard error, why
   --  a registration ended or a publication fell back -- the questions a
   --  screen reader that cannot find the application leaves.
   function Trace_Requested return Boolean is
      Value : Unbounded_String;
   begin
      return Hostkit.Process.Environment_Value ("A11YKIT_TRACE", Value) and then Length (Value) /= 0;
   end Trace_Requested;

   Tracing : constant Boolean := Trace_Requested;

   procedure Trace (Message : String) is
   begin
      if Tracing then
         Ada.Text_IO.Put_Line (Ada.Text_IO.Standard_Error, "a11ykit: " & Message);
      end if;
   end Trace;

   procedure Stop is
      Result : A11y.Results.Result;
   begin
      if A11y.Linux.ATSPi_Backend_Sessions.Registered (Session) then
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
      end if;
      Free (Latest);
   exception
      when others =>
         null;
   end Stop;

   --  Answer pending calls from the latest snapshots; a transport failure
   --  ends the registration so the next Publish starts a fresh one.
   procedure Serve (Iterations : Natural) is
      Report : A11y.Linux.ATSPi_Backend_Sessions.Event_Loop_Bounded_Report;
      Result : A11y.Results.Result;
   begin
      if Latest = null or else not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session) then
         return;
      end if;
      A11y.Linux.ATSPi_Backend_Sessions.Drive_Bounded_Event_Loop
        (Session, Latest.all, Iterations, 0, Report, Result);
      --  One call that cannot be served (an unknown method, say, as a client
      --  that introspects first sends) is that caller's problem, not the
      --  connection's: only a transport failure ends the registration.
      if A11y.Results.Failed (Result)
        and then Result.Status /= A11y.Results.Backend_Unavailable
        and then Report.Pump.Stop_Reason /= A11y.Linux.ATSPi_Startup.Iteration_Failed
      then
         Trace ("serving failed (" & Result.Status'Image & ", "
                & Report.Last_Operation'Image & ", " & Report.Last_Step_Stop_Reason'Image
                & "); registration ended");
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
      elsif A11y.Results.Failed (Result) and then Result.Status /= A11y.Results.Backend_Unavailable then
         Trace ("a call could not be served (" & Result.Status'Image & ")");
      end if;
   exception
      when others =>
         null;
   end Serve;

   --  The bus reaches the tree without a window.
   procedure Attach_Window (Window : System.Address) is null;

   procedure Service is
   begin
      Serve (16);
   end Service;


   --  The node the application marked active, or 0.
   function Active_Window (Tree : A11ykit.Tree.Accessibility_Tree) return Natural is
   begin
      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         if Tree.Nodes (Index).Node_State.Active then
            return Index;
         end if;
      end loop;
      return 0;
   end Active_Window;

   --  The tree under an application node, the root AT-SPI expects: the
   --  application is node 1, its children the tree's top-level nodes.
   function Under_Application
     (Tree : A11ykit.Tree.Accessibility_Tree)
      return A11ykit.Tree.Accessibility_Tree
   is
      Result : A11ykit.Tree.Accessibility_Tree;
      Name   : constant String := Ada.Directories.Simple_Name (Ada.Command_Line.Command_Name);
   begin
      if Tree.Nodes.Is_Empty then
         return Tree;
      end if;
      Result.Nodes.Append
        (A11ykit.Tree.Node'
           (Node_Role   => A11ykit.Role_Application,
          Bounds      => Tree.Nodes.First_Element.Bounds,
          Name        => To_Unbounded_String (Name),
          Description => Null_Unbounded_String,
          Node_State  => (others => <>),
          Parent      => 0));
      for Item of Tree.Nodes loop
         Result.Nodes.Append ((Item with delta Parent => Item.Parent + 1));
      end loop;
      --  An application with several windows marks the active one itself;
      --  otherwise the window (the tree's root, now node 2) is active while
      --  focused.
      if Active_Window (Tree) = 0 then
         Result.Nodes.Reference (2).Node_State.Active := Window_Active;
      end if;
      Result.Focused := (if Tree.Focused = 0 then 0 else Tree.Focused + 1);
      return Result;
   exception
      when others =>
         return Tree;
   end Under_Application;

   procedure Publish_Under_Application (Tree : A11ykit.Tree.Accessibility_Tree) is
      type Semantic_Access is access A11y.Sessions.Semantic_Session;
      procedure Free is new Ada.Unchecked_Deallocation
        (A11y.Sessions.Semantic_Session, Semantic_Access);

      Root      : A11y.Node_Ids.Node_Id;
      Result    : A11y.Results.Result;
      Semantic  : Semantic_Access := null;
      Snapshots : Snapshot_Access := null;
      Delivered : Natural := 0;
      First     : Boolean;

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
         Trace ("tree not publishable (" & Result.Status'Image & ")");
         Release_Working_State;
         return;
      end if;

      A11ykit.Compatibility.Populate_Session (Tree, Semantic.all, Result);
      if A11y.Results.Failed (Result) then
         Release_Working_State;
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      First := not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session);
      if First then
         A11y.Linux.ATSPi_Backend_Sessions.Start_From_Host_Environment
           (Session, Current_User, Root, Result);
         if A11y.Results.Failed (Result)
           or else not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session)
         then
            Trace ("registration failed (" & Result.Status'Image & ")");
            Release_Working_State;
            return;
         end if;
      end if;

      --  Every node is a D-Bus object a screen reader can address; only the
      --  application root is registered with the session itself.
      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         declare
            Descriptor : A11y.Linux.ATSPi_Object_Registry.Object_Export_Descriptor;
         begin
            A11y.Linux.ATSPi_Backend_Sessions.Node_Descriptor
              (Session, A11ykit.Compatibility.Node_Id_For_Index (Tree, Index), Descriptor);
         end;
      end loop;

      --  The first tree is announced in full; later ones only by the nodes
      --  that changed or are new, and by a focus that moved -- announcing
      --  everything again on each redraw would flood the screen reader and
      --  have it repeat the focused item each time the pointer moves.
      declare
         Signatures : constant Signature_Vectors.Vector := Signatures_Of (Tree);
         Focus      : constant Unbounded_String := Focus_Of (Tree);
         Any_Change : Boolean := False;
         Which      : Event_Filter;
      begin
         for Index in Signatures.First_Index .. Signatures.Last_Index loop
            if Index in Changed'Range then
               Changed (Index) :=
                 Index > Last_Signatures.Last_Index
                 or else Signatures (Index) /= Last_Signatures (Index);
               Any_Change := Any_Change or else Changed (Index);
            end if;
         end loop;
         Which :=
           (if First then All_Events
            elsif Any_Change then Changed_Nodes
            elsif Focus /= Last_Focus then Focus_Only
            else No_Events);
         Publish_Queued_Events (Semantic.all, Which, Focus /= Last_Focus, Delivered, Result);

         --  Nodes past the new tree's end are gone: tell each one's parent,
         --  when that parent is still there, that a child was removed.
         if not First and then A11y.Results.Succeeded (Result) then
            for Index in Natural (Tree.Nodes.Length) + 1 .. Natural (Last_Parents.Length) loop
               declare
                  Parent : constant Natural := Last_Parents (Index);
                  Queued : A11y.Results.Result;
                  --  Where the child sat among its parent's children.
                  Position : Positive := 1;
               begin
                  for Earlier in 1 .. Index - 1 loop
                     if Last_Parents (Earlier) = Parent then
                        Position := Position + 1;
                     end if;
                  end loop;
                  if Parent in 1 .. Natural (Tree.Nodes.Length) then
                     Last_Delivered := Last_Delivered + 1;
                     A11y.Linux.ATSPi_Backend_Sessions.Queue_Tree_Event_Signal
                       (Session,
                        (Sequence  => Last_Delivered,
                         Timestamp => Ada.Calendar.Clock,
                         Source    => A11y.Node_Ids.From_Natural (Parent),
                         Kind      => A11y.Events.Child_Removed,
                         Revision  => A11y.Initial_Revision),
                        (Parent    => A11y.Node_Ids.From_Natural (Parent),
                         Child     => A11y.Node_Ids.From_Natural (Index),
                         Has_Child => True,
                         Index     => Position,
                         Has_Index => True),
                        Queued);
                     if A11y.Results.Succeeded (Queued) then
                        Delivered := Delivered + 1;
                     end if;
                  end if;
               end;
            end loop;
         end if;

         Last_Signatures := Signatures;
         Last_Focus := Focus;
         Last_Parents.Clear;
         for Item of Tree.Nodes loop
            Last_Parents.Append (Item.Parent);
         end loop;
      end;
      if A11y.Results.Failed (Result) then
         Trace ("events not delivered (" & Result.Status'Image & ", " & Delivered'Image
                & " sent); registration ended");
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
         Release_Working_State;
         return;
      end if;

      Free (Latest);
      Latest := Snapshots;
      Snapshots := null;
      Free (Semantic);
      Serve (8);

      A11ykit.Provider_Runtime.Record_Publish_Result
        (A11y.Results.Success, Delivered, Backend_Name, False, A11y.Results.Success);
   exception
      when others =>
         Release_Working_State;
         A11ykit.Provider_Runtime.Record_Publish_Result
           (A11y.Results.Internal_Error, 0, Backend_Name, False,
            A11y.Results.Internal_Error);
   end Publish_Under_Application;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
   begin
      Last_Tree := Tree;
      Publish_Under_Application (Under_Application (Tree));
      --  Without a host registration the tree is validated as given.
      if not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session) then
         A11ykit.Provider_Runtime.Publish (Tree);
      end if;
   end Publish;

   procedure Set_Active (Active : Boolean) is
      Result : A11y.Results.Result;
   begin
      Trace ("window " & (if Active then "activated" else "deactivated"));
      Window_Active := Active;
      if Latest = null or else not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session) then
         return;
      end if;
      --  Answer from a tree whose window carries the new active state.
      Publish_Under_Application (Under_Application (Last_Tree));
      Last_Delivered := Last_Delivered + 1;
      A11y.Linux.ATSPi_Backend_Sessions.Queue_Event_Signal
        (Session,
         (Sequence  => Last_Delivered,
          Timestamp => Ada.Calendar.Clock,
          --  The window the application marked active, else the first
          --  (node 2, under the application node).
          Source    =>
            A11y.Node_Ids.From_Natural
              ((if Active_Window (Last_Tree) = 0 then 2 else Active_Window (Last_Tree) + 1)),
          Kind      => (if Active then A11y.Events.Window_Activated else A11y.Events.Window_Deactivated),
          Revision  => A11y.Initial_Revision),
         Result);
      if A11y.Results.Failed (Result) then
         Trace ("window activation not delivered (" & Result.Status'Image & ")");
      end if;
      Serve (4);
   exception
      when others =>
         null;
   end Set_Active;

   function Next_Request (Item : out Request) return Boolean is
      Raw : A11y.Linux.ATSPi_Requests.Request;
   begin
      Item := (others => <>);
      while A11y.Linux.ATSPi_Requests.Pop (Raw) loop
         declare
            --  Published under the application node, so one index on.
            Index : constant Integer := A11y.Node_Ids.To_Natural (Raw.Node) - 1;
         begin
            if Index in Last_Tree.Nodes.First_Index .. Last_Tree.Nodes.Last_Index then
               Item :=
                 (Kind   =>
                    (case Raw.Kind is
                       when A11y.Linux.ATSPi_Requests.Activate => Activate_Request,
                       when A11y.Linux.ATSPi_Requests.Focus    => Focus_Request),
                  Node   => Index,
                  Bounds => Last_Tree.Nodes (Index).Bounds);
               Trace ("screen reader asks to " & Item.Kind'Image & " node" & Index'Image);
               return True;
            end if;
         end;
      end loop;
      return False;
   exception
      when others =>
         return False;
   end Next_Request;

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
