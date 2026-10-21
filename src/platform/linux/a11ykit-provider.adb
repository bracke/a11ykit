with Ada.Text_IO;
with Ada.Strings.Unbounded;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;
with A11ykit.Provider_Runtime;

with A11y;
with A11y.Events;
with A11y.Linux.ATSPi_Backend_Sessions;
with A11y.Linux.ATSPi_Startup;
with A11y.Linux.ATSPi_Method_Router;
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

         --  Each publication's semantic session numbers its events from the
         --  start, while the backend admits only ever-later sequences; number
         --  them afresh from one counter that lives as long as the provider.
         Last_Delivered := Last_Delivered + 1;
         A11y.Linux.ATSPi_Backend_Sessions.Queue_Event_Signal
           (Session, (Event with delta Sequence => Last_Delivered), Queue_Result);
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

   procedure Service is
   begin
      Serve (16);
   end Service;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
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

      First := not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session);
      if First then
         A11y.Linux.ATSPi_Backend_Sessions.Start_From_Host_Environment
           (Session, Current_User, Root, Result);
         if A11y.Results.Failed (Result)
           or else not A11y.Linux.ATSPi_Backend_Sessions.Registered (Session)
         then
            Trace ("registration failed (" & Result.Status'Image & ")");
            Release_Working_State;
            A11ykit.Provider_Runtime.Publish (Tree);
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

      --  Every publication announces its tree's events: the screen reader
      --  learns of a change only from them. The registration itself is kept.
      Publish_Queued_Events (Semantic.all, Delivered, Result);
      if A11y.Results.Failed (Result) then
         Trace ("events not delivered (" & Result.Status'Image & ", " & Delivered'Image
                & " sent); registration ended");
         A11y.Linux.ATSPi_Backend_Sessions.Stop (Session, Result);
         Release_Working_State;
         A11ykit.Provider_Runtime.Publish (Tree);
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
