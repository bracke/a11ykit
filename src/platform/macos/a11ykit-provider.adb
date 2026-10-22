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
   Attached_Window : System.Address := System.Null_Address;

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

   procedure Attach_Window (Window : System.Address) is
   begin
      Attached_Window := Window;
      Attach_Host;
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

         if Snapshots.Hierarchy.Focused_Node /= Last_Focus then
            Last_Focus := Snapshots.Hierarchy.Focused_Node;
            if Native.Post_Notification_For_Object
                 (Host_Object,
                  Native.Native_UInt32
                    (NSAX_Events.Notification_Code (NSAX_Events.Focused_UI_Element_Changed)))
               /= Native.Native_Status (0)
            then
               Delivered_Events := 1;
            end if;
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
      Attach_Host;

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

   --  This host's window system tells its screen reader about activation.
   procedure Set_Active (Active : Boolean) is null;

   --  Requests from this host's screen reader are not routed back yet.
   function Next_Request (Item : out Request) return Boolean is
   begin
      Item := (others => <>);
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
