with Interfaces.C;
with System;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;
with A11ykit.MacOS_Snapshots;
with A11ykit.Provider_Runtime;

with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Events;
with A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
with A11y.MacOS_Backend.NSAccessibility_Native_Callbacks;
with A11y.MacOS_Backend.NSAccessibility_Public_Roots;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.Events;
with A11y.Native_Identity;
with A11y.Native_Requests;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Results;
with A11y.Sessions;

package body A11ykit.Provider is

   package Registry_API renames
     A11y.MacOS_Backend.NSAccessibility_Element_Registry;
   package Native renames
     A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
   package Callbacks renames
     A11y.MacOS_Backend.NSAccessibility_Native_Callbacks;
   package Router renames
     A11y.MacOS_Backend.NSAccessibility_Request_Router;
   package NSAX_Events renames
     A11y.MacOS_Backend.NSAccessibility_Events;

   type Snapshot_Access is access all Router.Snapshot_Bundle;
   procedure Free is new Ada.Unchecked_Deallocation
     (Router.Snapshot_Bundle, Snapshot_Access);

   use type A11y.Results.Status_Code;
   use type A11y.Node_Ids.Node_Id;
   use type Native.Native_UInt32;
   use type Native.Native_Status;
   use type Native.Native_UInt64;
   use type System.Address;

   Registry : aliased Registry_API.Element_Registry;
   Snapshots : Snapshot_Access := new Router.Snapshot_Bundle;
   Callback_Context : aliased Callbacks.Callback_Context :=
     (Registry => Registry'Access,
      Snapshots => Snapshots,
      others => <>);
   Session : A11y.Native_Identity.Backend_Session_Id :=
     A11y.Native_Identity.No_Session;
   Host_Object : System.Address := System.Null_Address;

   --  The application's window the tree is shown in (Attach_Window); null
   --  until the application names it.
   Max_Windows : constant := 16;
   type Window_Handles is array (1 .. Max_Windows) of System.Address;
   type Window_Nodes is array (1 .. Max_Windows) of Natural;
   Windows       : Window_Handles := [others => System.Null_Address];
   Attached_Node : Window_Nodes := [others => 0];
   Attached_Window : System.Address renames Windows (1);

   --  The tree last published, to turn a request's node into the index and
   --  bounds the application acts on.
   Last_Tree : A11ykit.Tree.Accessibility_Tree;

   --  The root the host was installed for and the focus last announced, so a
   --  republish of the same window keeps the elements a client holds.
   Published_Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   Last_Focus     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;

   function Root_Node
     (Tree   : A11ykit.Tree.Accessibility_Tree;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
     renames A11ykit.MacOS_Snapshots.Root_Node;

   procedure Build_Snapshots
     (Tree      : A11ykit.Tree.Accessibility_Tree;
      Root      : A11y.Node_Ids.Node_Id;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Snapshots : out Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
     renames A11ykit.MacOS_Snapshots.Build_Snapshots;

   procedure Reset_Snapshots is
      Previous : Snapshot_Access := Snapshots;
   begin
      --  Snapshot bundles contain several bounded semantic trees and are tens
      --  of MiB. Replace the heap object rather than constructing a reset
      --  aggregate on the GUI task's stack.
      Snapshots := new Router.Snapshot_Bundle;
      Callback_Context.Snapshots := Snapshots;
      Free (Previous);
   end Reset_Snapshots;

   procedure Publish_Queued_Events
     (Semantic  : in out A11y.Sessions.Semantic_Session;
      Root      : A11y.Node_Ids.Node_Id;
      Delivered : out Natural;
      Result    : out A11y.Results.Result)
   is
      Event : A11y.Events.Event;
      Emission : NSAX_Events.NSAX_Event_Emission;
      Acknowledge_Result : A11y.Results.Result;
      Max_Attempts : constant Natural :=
        A11y.Sessions.Event_Capacity (Semantic);
      Native_Result : Native.Native_Status;

      function Create_Target_Object
        (Source : A11y.Node_Ids.Node_Id)
         return System.Address
      is
         Element : Registry_API.Element_Id := Registry_API.No_Element;
         Target_Result : A11y.Results.Result;
      begin
         if Source = Root then
            return Host_Object;
         end if;

         Registry_API.Ensure_Element
           (Registry, Session, Root, Source, Element, Target_Result);
         if A11y.Results.Failed (Target_Result) then
            Result := Target_Result;
            return System.Null_Address;
         end if;

         Registry_API.Bind_Main_Thread
           (Registry, Session, Element, Target_Result);
         if A11y.Results.Failed (Target_Result) then
            Result := Target_Result;
            return System.Null_Address;
         end if;

         return
           Native.Create_Virtual_Element_With_Callbacks
             (Callbacks.Dispatch_Selector_Callback'Access,
              Callbacks.Copy_Value_Callback'Access,
              Callbacks.Copy_Object_Callback'Access,
              Native.Native_UInt64
                (A11y.Native_Identity.To_Natural (Session)),
              Native.Native_UInt64 (Registry_API.To_Natural (Element)),
              Callback_Context'Address);
      exception
         when others =>
            Result := (Status => A11y.Results.Internal_Error);
            return System.Null_Address;
      end Create_Target_Object;
   begin
      Delivered := 0;
      Result := A11y.Results.Ok;

      while A11y.Sessions.Pending_Event_Count (Semantic) > 0 loop
         if Delivered >= Max_Attempts then
            Result := (Status => A11y.Results.Resource_Limit);
            return;
         end if;

         A11y.Sessions.Peek_Event (Semantic, Event, Result);
         if A11y.Results.Failed (Result) then
            return;
         end if;

         Emission := NSAX_Events.Build_Event (Event);
         if not Emission.Publishable then
            Result := (Status => Emission.Status);
            return;
         end if;

         declare
            Target_Object : System.Address :=
              Create_Target_Object (Emission.Source);
            Release_Target : constant Boolean := Target_Object /= Host_Object;
         begin
            if Target_Object = System.Null_Address then
               if A11y.Results.Succeeded (Result) then
                  Result := (Status => A11y.Results.Native_Failure);
               end if;
               return;
            end if;

            Native_Result :=
              Native.Post_Notification_For_Object
                (Target_Object,
                 Native.Native_UInt32
                   (NSAX_Events.Notification_Code
                      (Emission.Notification)));
            if Release_Target then
               Native.Release_Object (Target_Object);
            end if;
            if Native_Result = Native.Native_Status (0) then
               Result := (Status => A11y.Results.Native_Failure);
               return;
            end if;
         exception
            when others =>
               if Release_Target
                 and then Target_Object /= System.Null_Address
               then
                  Native.Release_Object (Target_Object);
               end if;
               Result := (Status => A11y.Results.Internal_Error);
               return;
         end;

         A11y.Sessions.Acknowledge_Event
           (Semantic, Event.Sequence, Acknowledge_Result);
         if A11y.Results.Failed (Acknowledge_Result) then
            Result := Acknowledge_Result;
            return;
         end if;

         Delivered := Delivered + 1;
      end loop;
   exception
      when others =>
         Delivered := 0;
         Result := (Status => A11y.Results.Internal_Error);
   end Publish_Queued_Events;

   function Available return Boolean is
   begin
      return Host_Object /= System.Null_Address;
   end Available;

   procedure Attach_Host is
      Ignored : Native.Native_Status;
   begin
      if Attached_Window /= System.Null_Address
        and then Host_Object /= System.Null_Address
      then
         Ignored := Native.Attach_Process_Root_To_Window (Host_Object, Attached_Window);
      end if;
   end Attach_Host;

   --  The element code a client knows Node's element by: the root's is its
   --  node, as installed; any other is registered on first use.
   function Element_Code (Node : Natural) return Native.Native_UInt64 is
      Element : Registry_API.Element_Id := Registry_API.No_Element;
      Result  : A11y.Results.Result;
   begin
      if Node = A11y.Node_Ids.To_Natural (Published_Root) then
         return Native.Native_UInt64 (Node);
      end if;
      Registry_API.Ensure_Element
        (Registry, Session, Published_Root, A11y.Node_Ids.From_Natural (Node), Element, Result);
      if A11y.Results.Succeeded (Result) then
         Registry_API.Bind_Main_Thread (Registry, Session, Element, Result);
      end if;
      return (if A11y.Results.Succeeded (Result)
              then Native.Native_UInt64 (Registry_API.To_Natural (Element)) else 0);
   exception
      when others =>
         return 0;
   end Element_Code;

   --  The tree's nodes without a parent, the application's windows, in tree
   --  order; and for each node the window it belongs to.
   procedure Note_Windows (Tree : A11ykit.Tree.Accessibility_Tree; Tops : out Window_Nodes) is
      Count : Natural := 0;
   begin
      Tops := [others => 0];
      Callback_Context.Window_Of := [others => 0];
      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         if Tree.Nodes (Index).Parent = 0 then
            Count := Count + 1;
            if Count <= Max_Windows then
               Tops (Count) := Index;
            end if;
         end if;
         if Index in Callback_Context.Window_Of'Range then
            declare
               Current : Natural := Index;
               Steps   : Natural := 0;
            begin
               while Tree.Nodes (Current).Parent /= 0 and then Steps < Natural (Tree.Nodes.Length) loop
                  Current := Tree.Nodes (Current).Parent;
                  Steps := Steps + 1;
               end loop;
               Callback_Context.Window_Of (Index) := Current;
            end;
         end if;
      end loop;
   end Note_Windows;

   --  Show each further window's top-level node in it, where that changed;
   --  the first window shows the root.
   procedure Attach_Further_Windows is
      Tops    : Window_Nodes;
      Code    : Native.Native_UInt64;
      Ignored : Native.Native_Status;
   begin
      Note_Windows (Last_Tree, Tops);
      for K in 2 .. Max_Windows loop
         if Windows (K) /= System.Null_Address
           and then Tops (K) /= 0
           and then Attached_Node (K) /= Tops (K)
           and then Host_Object /= System.Null_Address
         then
            Code := Element_Code (Tops (K));
            if Code /= 0 then
               Ignored := Native.Attach_Node_To_Window (Host_Object, Windows (K), Code);
               Attached_Node (K) := Tops (K);
            end if;
         end if;
      end loop;
   end Attach_Further_Windows;

   --  Post Notification on the element of the tree's node Node.
   procedure Post_On (Node : Natural; Notification : NSAX_Events.NSAX_Notification) is
      Code    : Native.Native_UInt64;
      Ignored : Native.Native_Status;
   begin
      if Host_Object = System.Null_Address or else Node = 0 then
         return;
      end if;
      Code := Element_Code (Node);
      if Code /= 0 then
         Ignored :=
           Native.Post_Notification_For_Node
             (Host_Object, Code, Native.Native_UInt32 (NSAX_Events.Notification_Code (Notification)));
      end if;
   end Post_On;

   procedure Attach_Window (Window : System.Address; Top_Level : Positive := 1) is
   begin
      if Top_Level > Max_Windows then
         return;
      end if;
      if Windows (Top_Level) /= Window then
         Attached_Node (Top_Level) := 0;
      end if;
      Windows (Top_Level) := Window;
      if Top_Level = 1 then
         Attach_Host;
      elsif Host_Object /= System.Null_Address then
         Attach_Further_Windows;
      end if;
   end Attach_Window;

   procedure Start is
   begin
      null;
   end Start;

   procedure Stop is
      Result : A11y.Results.Result;
   begin
      if Host_Object /= System.Null_Address then
         Native.Release_Object (Host_Object);
         Host_Object := System.Null_Address;
      end if;

      Published_Root := A11y.Node_Ids.No_Node;
      Last_Focus := A11y.Node_Ids.No_Node;
      Registry_API.Reset_When_Drained (Registry, Result);
      if A11y.Results.Failed (Result) then
         Registry_API.Reset (Registry);
      end if;
      Session := A11y.Native_Identity.No_Session;
   exception
      when others =>
         Host_Object := System.Null_Address;
         Session := A11y.Native_Identity.No_Session;
   end Stop;

   procedure Publish (Tree : A11ykit.Tree.Accessibility_Tree) is
      Changed : Boolean;
      type Semantic_Access is access A11y.Sessions.Semantic_Session;
      procedure Free is new Ada.Unchecked_Deallocation
        (A11y.Sessions.Semantic_Session, Semantic_Access);

      Root : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Semantic : Semantic_Access := null;
      Export_Report :
        A11y.MacOS_Backend.NSAccessibility_Public_Roots
          .Public_Root_Export_Report;
      Delivered_Events : Natural := 0;
   begin
      Changed := not A11ykit.Tree."=" (Tree, Last_Tree);
      Last_Tree := Tree;
      Root := Root_Node (Tree, Result);
      if A11y.Results.Failed (Result) then
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      Semantic := new A11y.Sessions.Semantic_Session;
      A11ykit.Compatibility.Populate_Session (Tree, Semantic.all, Result);
      if A11y.Results.Failed (Result) then
         Free (Semantic);
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      if Native.Bridge_Is_MacOS = 0 then
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      --  The same window again: keep the session, host and elements a client
      --  holds, swap the snapshot they answer from, and announce a moved
      --  focus. Starting over would strand every element the client has.
      if Host_Object /= System.Null_Address and then Root = Published_Root then
         Reset_Snapshots;
         Build_Snapshots (Tree, Root, Session, Snapshots.all, Result);
         if A11y.Results.Failed (Result) then
            Stop;
            Free (Semantic);
            A11ykit.Provider_Runtime.Publish (Tree);
            return;
         end if;

         Attach_Further_Windows;

         --  What changed: each window's layout, and the focus, posted on the
         --  element it moved to.
         if Changed then
            declare
               Tops : Window_Nodes;
            begin
               Note_Windows (Last_Tree, Tops);
               for Top of Tops loop
                  if Top /= 0 then
                     Post_On (Top, NSAX_Events.Layout_Changed);
                  end if;
               end loop;
            end;
         end if;
         if Snapshots.Hierarchy.Focused_Node /= Last_Focus then
            Last_Focus := Snapshots.Hierarchy.Focused_Node;
            Post_On (A11y.Node_Ids.To_Natural (Last_Focus), NSAX_Events.Focused_UI_Element_Changed);
            Delivered_Events := 1;
         end if;

         Free (Semantic);
         A11ykit.Provider_Runtime.Record_Publish_Result
           (A11y.Results.Success, Delivered_Events, Backend_Name, False, A11y.Results.Success);
         return;
      end if;

      Stop;
      Reset_Snapshots;
      Session := A11y.Native_Identity.Create_Session;
      Build_Snapshots (Tree, Root, Session, Snapshots.all, Result);
      if A11y.Results.Failed (Result) then
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      A11y.MacOS_Backend.NSAccessibility_Public_Roots.Export_Public_Root
        (Registry, Session, Root, Root, Export_Report);
      if Export_Report.Status /= A11y.Results.Success then
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Host_Object :=
        Native.Install_Process_Root
          (Callbacks.Dispatch_Selector_Callback'Access,
           Callbacks.Copy_Value_Callback'Access,
           Callbacks.Copy_Object_Callback'Access,
           Native.Native_UInt64
             (A11y.Native_Identity.To_Natural (Session)),
           Native.Native_UInt64 (A11y.Node_Ids.To_Natural (Root)),
           Callback_Context'Address);
      if Host_Object = System.Null_Address then
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;
      Published_Root := Root;
      Last_Focus := Snapshots.Hierarchy.Focused_Node;
      Attached_Node (2 .. Max_Windows) := [others => 0];
      Attach_Host;
      Attach_Further_Windows;

      Publish_Queued_Events (Semantic.all, Root, Delivered_Events, Result);
      if A11y.Results.Failed (Result) then
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Free (Semantic);
      A11ykit.Provider_Runtime.Record_Publish_Result
        (A11y.Results.Success,
         Delivered_Events,
         Backend_Name,
         False,
         A11y.Results.Success);
   exception
      when others =>
         Free (Semantic);
         A11ykit.Provider_Runtime.Record_Publish_Result
           (A11y.Results.Internal_Error, 0, Backend_Name, False,
            A11y.Results.Internal_Error);
   end Publish;

   --  Queries reach this host's provider through the window system's own
   --  message loop, which the application already pumps.
   --  Requests from an accessibility client reach the process through the
   --  main thread's run loop; let it handle whatever is waiting. An
   --  application whose event loop already runs it pays one empty pass.
   procedure Service is
      Default_Mode : constant System.Address
      with Import, Convention => C, External_Name => "kCFRunLoopDefaultMode";

      function Run_In_Mode
        (Mode : System.Address; Seconds : Long_Float; Return_After_Source : Interfaces.C.unsigned_char)
         return Interfaces.C.int
      with Import, Convention => C, External_Name => "CFRunLoopRunInMode";

      Ignored : Interfaces.C.int;
   begin
      if Host_Object /= System.Null_Address then
         Ignored := Run_In_Mode (Default_Mode, 0.0, 0);
      end if;
   end Service;

   --  The window system activates the window itself; announce where the
   --  focus is in it, so the screen reader starts from there.
   procedure Set_Active (Active : Boolean) is
   begin
      if Active and then Host_Object /= System.Null_Address and then A11y.Node_Ids.Is_Valid (Last_Focus) then
         Post_On (A11y.Node_Ids.To_Natural (Last_Focus), NSAX_Events.Focused_UI_Element_Changed);
      end if;
   end Set_Active;

   --  A press or focus the screen reader asked for, as the node's index in
   --  the last published tree (whose node ids are those indices).
   function Next_Request (Item : out Request) return Boolean is
      Raw : A11y.Native_Requests.Request;
   begin
      Item := (others => <>);
      while A11y.Native_Requests.Pop (Raw) loop
         declare
            Index : constant Natural := A11y.Node_Ids.To_Natural (Raw.Node);
         begin
            if Index in Last_Tree.Nodes.First_Index .. Last_Tree.Nodes.Last_Index then
               Item :=
                 (Kind   =>
                    (case Raw.Kind is
                       when A11y.Native_Requests.Activate => Activate_Request,
                       when A11y.Native_Requests.Focus    => Focus_Request,
                       when A11y.Native_Requests.Select_Item => Select_Request),
                  Node   => Index,
                  Bounds => Last_Tree.Nodes (Index).Bounds);
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
