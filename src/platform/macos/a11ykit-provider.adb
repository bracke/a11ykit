with System;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;
with A11ykit.Provider_Runtime;

with A11y.MacOS_Backend.NSAccessibility_Element_Registry;
with A11y.MacOS_Backend.NSAccessibility_Events;
with A11y.MacOS_Backend.NSAccessibility_Native_Bridge;
with A11y.MacOS_Backend.NSAccessibility_Native_Callbacks;
with A11y.MacOS_Backend.NSAccessibility_Public_Roots;
with A11y.MacOS_Backend.NSAccessibility_Request_Router;
with A11y.Geometry;
with A11y.Events;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Properties;
with A11y.Results;
with A11y.Semantic_Snapshots;
with A11y.Sessions;
with A11y.Trees;

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
   use type A11y.Properties.Property_Status;
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
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Snapshots : out Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
      Metadata : A11y.Semantic_Snapshots.Node_Metadata;
      Check    : A11y.Results.Result;
   begin
      Snapshots.Properties.Nodes :=
        A11ykit.Compatibility.To_Semantic_Snapshot (Tree, Result);
      if A11y.Results.Failed (Result) then
         return;
      end if;

      A11y.Trees.Set_Root (Snapshots.Properties.Tree, Root, Check);
      if A11y.Results.Failed (Check) then
         Result := Check;
         return;
      end if;

      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         declare
            Node : constant A11y.Node_Ids.Node_Id :=
              A11ykit.Compatibility.Node_Id_For_Index (Tree, Index);
            Parent_Index : constant Natural := Tree.Nodes (Index).Parent;
         begin
            if Parent_Index /= 0 then
               A11y.Trees.Attach
                 (Snapshots.Properties.Tree,
                  A11ykit.Compatibility.Node_Id_For_Index
                    (Tree, Parent_Index),
                  Node,
                  Check);
               if A11y.Results.Failed (Check) then
                  Result := Check;
                  return;
               end if;
            end if;

            Metadata :=
              A11y.Semantic_Snapshots.Metadata
                (Snapshots.Properties.Nodes, Node);
            if Metadata.Present
              and then A11y.Node_Ids.To_Natural (Node)
                in Snapshots.Hierarchy.Bounds'Range
              and then Metadata.Bounds.Status = A11y.Properties.Present
            then
               Snapshots.Hierarchy.Bounds
                 (A11y.Node_Ids.To_Natural (Node)) := Metadata.Bounds.Value;
            end if;
         end;
      end loop;

      Metadata :=
        A11y.Semantic_Snapshots.Metadata
          (Snapshots.Properties.Nodes, Root);
      if not Metadata.Present then
         Result := (Status => A11y.Results.Node_Unavailable);
         return;
      end if;

      Snapshots.Properties.Id := Root;
      Snapshots.Properties.Root := Root;
      Snapshots.Properties.Role := Metadata.Role;
      Snapshots.Properties.States := Metadata.States;
      Snapshots.Properties.Capabilities := Metadata.Capabilities;
      Snapshots.Properties.Bounds :=
        (if Metadata.Bounds.Status = A11y.Properties.Present
         then Metadata.Bounds.Value
         else A11y.Geometry.Empty_Rectangle);
      Snapshots.Properties.Title :=
        (if Metadata.Visible_Title.Status in A11y.Properties.Present |
           A11y.Properties.Empty
         then Metadata.Visible_Title
         else Metadata.Name);
      Snapshots.Properties.Label := Metadata.Name;
      Snapshots.Properties.Description := Metadata.Description;
      Snapshots.Properties.Help := Metadata.Help_Text;
      Snapshots.Properties.Placeholder := Metadata.Placeholder;
      Snapshots.Properties.Value_Text := Metadata.Value_Text;
      Snapshots.Properties.Protected_Value_Text :=
        Metadata.Protected_Value_Text;
      Snapshots.Properties.Keyboard_Shortcut := Metadata.Keyboard_Shortcut;
      Snapshots.Properties.Locale := Metadata.Locale;
      Snapshots.Properties.Orientation := Metadata.Orientation;
      Snapshots.Properties.Landmark := Metadata.Landmark;
      Snapshots.Properties.Identifier := Metadata.Semantic_Identifier;
      Snapshots.Properties.Use_Tree_Projection := True;
      Snapshots.Properties.Use_Node_Metadata := True;
      Snapshots.Properties.Defunct := False;

      Snapshots.Hierarchy.Session := Session;
      Snapshots.Hierarchy.Root := Root;
      Snapshots.Hierarchy.Tree := Snapshots.Properties.Tree;
      Snapshots.Hierarchy.Node := Root;
      Snapshots.Hierarchy.Focused_Node := Root;
      Snapshots.Hierarchy.Defunct := False;

      Snapshots.Action_Node := Root;
      Snapshots.Action_Root := Root;
      Snapshots.Action_Tree := Snapshots.Properties.Tree;
      Snapshots.Action_Use_Tree_Projection := True;

      Snapshots.Relation_Source := Root;
      Snapshots.Relation_Root := Root;
      Snapshots.Relation_Tree := Snapshots.Properties.Tree;
      Snapshots.Relation_Use_Tree_Projection := True;

      Snapshots.Event_Root := Root;
      Snapshots.Event_Tree := Snapshots.Properties.Tree;
      Snapshots.Event_Use_Tree_Projection := True;

      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Build_Snapshots;

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
