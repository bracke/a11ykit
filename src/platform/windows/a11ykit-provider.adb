with System;
with Ada.Unchecked_Deallocation;

with A11ykit.Compatibility;
with A11ykit.UIA_Snapshots;
with A11ykit.Provider_Runtime;

with A11y.Events;
with A11y.Native_Identity;
with A11y.Native_Requests;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Results;
with A11y.Sessions;
with A11y.Windows_Backend.UIA_ABI_Surface;
with A11y.Windows_Backend.UIA_COM_Object_Exports;
with A11y.Windows_Backend.UIA_Events;
with A11y.Windows_Backend.UIA_Native_Bridge;
with A11y.Windows_Backend.UIA_Native_Callbacks;
with A11y.Windows_Backend.UIA_Provider_Registry;
with A11y.Windows_Backend.UIA_Public_Roots;
with A11y.Windows_Backend.UIA_Request_Router;

package body A11ykit.Provider is

   package ABI renames A11y.Windows_Backend.UIA_ABI_Surface;
   package Exports renames A11y.Windows_Backend.UIA_COM_Object_Exports;
   package Events renames A11y.Windows_Backend.UIA_Events;
   package Native renames A11y.Windows_Backend.UIA_Native_Bridge;
   package Callbacks renames A11y.Windows_Backend.UIA_Native_Callbacks;
   package Registry_API renames A11y.Windows_Backend.UIA_Provider_Registry;
   package Router renames A11y.Windows_Backend.UIA_Request_Router;

   type Snapshot_Access is access all Router.Snapshot_Bundle;
   procedure Free is new Ada.Unchecked_Deallocation
     (Router.Snapshot_Bundle, Snapshot_Access);

   use type A11y.Results.Status_Code;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type Native.Native_UInt32;
   use type Native.Native_HResult;
   use type Native.Native_UInt64;
   use type System.Address;

   Registry : aliased Registry_API.Provider_Registry;
   Object_Table : aliased Exports.COM_Object_Export_Table;
   Snapshots : Snapshot_Access := new Router.Snapshot_Bundle;
   Callback_Context : aliased Callbacks.Callback_Context :=
     (Object_Table => Object_Table'Access,
      Registry     => Registry'Access,
      Snapshots    => Snapshots,
      others       => <>);
   Session : A11y.Native_Identity.Backend_Session_Id :=
     A11y.Native_Identity.No_Session;
   Published : Boolean := False;
   Exported_Provider : Registry_API.Provider_Id :=
     Registry_API.No_Provider;
   Exported_Object : Exports.COM_Object_Token := Exports.No_COM_Object;
   Provider_Host : System.Address := System.Null_Address;

   --  The application's windows the provider answers through, by the
   --  top-level node each shows (Attach_Window); null until named. The first
   --  shows the tree's root, through the host's own provider; each further
   --  one is attached to its node's element, noted in Attached_Node.
   Max_Windows : constant := 16;
   type Window_Handles is array (1 .. Max_Windows) of System.Address;
   type Window_Nodes is array (1 .. Max_Windows) of Natural;
   Windows       : Window_Handles := [others => System.Null_Address];
   Attached_Node : Window_Nodes := [others => 0];
   Attached_Window : System.Address renames Windows (1);

   --  The tree last published, to turn a request's node into the index and
   --  bounds the application acts on.
   Last_Tree : A11ykit.Tree.Accessibility_Tree;

   --  The root the host was exported for and the focus last announced, so a
   --  republish of the same window keeps its host and says only what moved.
   Published_Root : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   Last_Focus     : A11y.Node_Ids.Node_Id := A11y.Node_Ids.No_Node;
   --  The selected node a screen reader was last told about; 0 for none.
   Last_Selected  : Natural := 0;

   function Method (Item : ABI.UIA_ABI_Method) return Native.Native_UInt32 is
     (Native.Native_UInt32 (ABI.Method_Code (Item)));

   function Return_S_OK
     (Session  : Native.Native_UInt64;
      Provider : Native.Native_UInt64;
      Method   : Native.Native_UInt32;
      Context  : System.Address)
      return Native.Native_UInt32
   with Convention => C;

   function Return_S_OK
     (Session  : Native.Native_UInt64;
      Provider : Native.Native_UInt64;
      Method   : Native.Native_UInt32;
      Context  : System.Address)
      return Native.Native_UInt32 is
   begin
      pragma Unreferenced (Session, Provider, Method, Context);
      return 0;
   end Return_S_OK;

   function Root_Node
     (Tree   : A11ykit.Tree.Accessibility_Tree;
      Result : out A11y.Results.Result)
      return A11y.Node_Ids.Node_Id
     renames A11ykit.UIA_Snapshots.Root_Node;

   procedure Build_Snapshots
     (Tree      : A11ykit.Tree.Accessibility_Tree;
      Root      : A11y.Node_Ids.Node_Id;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Snapshots : out Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
     renames A11ykit.UIA_Snapshots.Build_Snapshots;

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

   function Create_Callback_Host return System.Address is
   begin
      if Session = A11y.Native_Identity.No_Session
        or else not Registry_API.Is_Valid (Exported_Provider)
        or else not Exports.Is_Valid (Exported_Object)
      then
         return System.Null_Address;
      end if;

      return
        Native.Create_Callback_Provider_Host_Window
          (Native.Native_UInt64 (A11y.Native_Identity.To_Natural (Session)),
           Native.Native_UInt64
             (Registry_API.To_Natural (Exported_Provider)),
           Native.Native_UInt64 (Exports.To_Natural (Exported_Object)),
           Method (ABI.Simple_Get_Provider_Options),
           Method (ABI.Simple_Get_Pattern_Provider),
           Method (ABI.Simple_Get_Property_Value),
           Method (ABI.Simple_Get_Host_Raw_Element_Provider),
           Method (ABI.Fragment_Navigate),
           Method (ABI.Fragment_Get_Runtime_Id),
           Method (ABI.Fragment_Get_Bounding_Rectangle),
           Method (ABI.Fragment_Get_Embedded_Fragment_Roots),
           Method (ABI.Fragment_Set_Focus),
           Method (ABI.Fragment_Get_Fragment_Root),
           Method (ABI.Fragment_Root_Element_Provider_From_Point),
           Method (ABI.Fragment_Root_Get_Focus),
           Method (ABI.Invoke_Provider_Invoke),
           Method (ABI.Toggle_Provider_Toggle),
           Method (ABI.Expand_Collapse_Provider_Expand),
           Method (ABI.Expand_Collapse_Provider_Collapse),
           Method (ABI.Scroll_Item_Provider_Scroll_Into_View),
           Method (ABI.Selection_Item_Provider_Select),
           Method (ABI.Selection_Item_Provider_Add_To_Selection),
           Method (ABI.Selection_Item_Provider_Remove_From_Selection),
           Method (ABI.Selection_Item_Provider_Get_Is_Selected),
           Method (ABI.Selection_Item_Provider_Get_Selection_Container),
           Method (ABI.Range_Value_Provider_Set_Value),
           Method (ABI.Range_Value_Provider_Get_Value),
           Method (ABI.Range_Value_Provider_Get_Is_Read_Only),
           Method (ABI.Range_Value_Provider_Get_Maximum),
           Method (ABI.Range_Value_Provider_Get_Minimum),
           Method (ABI.Range_Value_Provider_Get_Large_Change),
           Method (ABI.Range_Value_Provider_Get_Small_Change),
           Method (ABI.Window_Provider_Close),
           Method (ABI.Window_Provider_Get_Can_Maximize),
           Method (ABI.Window_Provider_Get_Can_Minimize),
           Method (ABI.Window_Provider_Get_Is_Modal),
           Method (ABI.Window_Provider_Get_Window_Visual_State),
           Method (ABI.Window_Provider_Get_Window_Interaction_State),
           Method (ABI.Advise_Events_Advise),
           Method (ABI.Advise_Events_Unadvise),
           Return_S_OK'Access,
           Callbacks.Dispatch_Interface_Frame_Callback'Access,
           Callbacks.Copy_Property_Value_Callback'Access,
           Callbacks.Copy_Runtime_Id_Callback'Access,
           Callbacks.Copy_Bounding_Rectangle_Callback'Access,
           Callbacks.Copy_Boolean_Callback'Access,
           Callbacks.Check_Pattern_Supported_Callback'Access,
           Callbacks.Copy_Pattern_State_Callback'Access,
           Callbacks.Dispatch_Range_Value_Set_Callback'Access,
           Callbacks.Copy_Range_Value_Query_Callback'Access,
           Callbacks.Copy_Window_Query_Callback'Access,
           Callback_Context'Address);
   exception
      when others =>
         return System.Null_Address;
   end Create_Callback_Host;

   function Native_Event_Id
     (Emission : Events.UIA_Event_Emission)
      return Native.Native_UInt32
   is
      use type Events.UIA_Event_Kind;
      use type Events.UIA_Window_Event;
   begin
      case Emission.Kind is
         when Events.Automation_Focus_Changed =>
            return 20_005;
         when Events.Automation_Property_Changed =>
            return 20_004;
         when Events.Automation_Structure_Changed =>
            return 20_002;
         when Events.Automation_Selection_Invalidated =>
            return 20_013;
         when Events.Automation_Text_Changed =>
            return 20_015;
         when Events.Automation_Text_Selection_Changed =>
            return 20_014;
         when Events.Automation_Live_Region_Changed =>
            return 20_024;
         when Events.Automation_Notification =>
            return 20_035;
         when Events.Automation_Window_Opened =>
            if Emission.Window = Events.Window_Closed_Event then
               return 20_017;
            else
               return 20_016;
            end if;
         when Events.Automation_Window_Closed =>
            return 20_017;
         when Events.Automation_Layout_Invalidated =>
            return 20_008;
      end case;
   end Native_Event_Id;

   procedure Publish_Queued_Events
     (Semantic  : in out A11y.Sessions.Semantic_Session;
      Delivered : out Natural;
      Result    : out A11y.Results.Result)
   is
      Event : A11y.Events.Event;
      Emission : Events.UIA_Event_Emission;
      Acknowledge_Result : A11y.Results.Result;
      Native_Status : Native.Native_HResult;
      Max_Attempts : constant Natural :=
        A11y.Sessions.Event_Capacity (Semantic);
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

         Emission := Events.Build_Event (Event);
         if not Emission.Publishable then
            Result := (Status => Emission.Status);
            return;
         end if;

         Native_Status :=
           Native.Raise_Automation_Event
             (Provider_Host, Native_Event_Id (Emission));
         if Native_Status /= 0 then
            Result := (Status => A11y.Results.Native_Failure);
            return;
         end if;

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
      return Published;
   end Available;

   procedure Attach_Host is
      Ignored : Native.Native_UInt32;
   begin
      if Attached_Window /= System.Null_Address
        and then Provider_Host /= System.Null_Address
      then
         Ignored := Native.Attach_Callback_Provider_Host_Window (Provider_Host, Attached_Window);
      end if;
   end Attach_Host;

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

   --  Attach each further window to its top-level node's element, where that
   --  changed; the first window carries the host's own provider.
   procedure Attach_Further_Windows is
      Tops     : Window_Nodes;
      Provider : Native.Native_UInt64;
      Object   : Native.Native_UInt64;
      Ignored  : Native.Native_UInt32;
   begin
      Note_Windows (Last_Tree, Tops);
      for K in 2 .. Max_Windows loop
         if Windows (K) /= System.Null_Address
           and then Tops (K) /= 0
           and then Attached_Node (K) /= Tops (K)
           and then Provider_Host /= System.Null_Address
         then
            Callbacks.Ensure_Export (Callback_Context, Tops (K), Provider, Object);
            if Provider /= 0 then
               Ignored := Native.Attach_Element_To_Window (Provider_Host, Windows (K), Provider, Object);
               Attached_Node (K) := Tops (K);
            end if;
         end if;
      end loop;
   end Attach_Further_Windows;

   --  Raise Event_Id (or, with Structure, a children-changed event) on the
   --  tree's node Node, in its window's fragment.
   --  The first selected item or row of a tree, by its node number; 0 when
   --  nothing is selected.
   function First_Selected (Tree : A11ykit.Tree.Accessibility_Tree) return Natural is
   begin
      for Index in Tree.Nodes.First_Index .. Tree.Nodes.Last_Index loop
         if Tree.Nodes (Index).Node_State.Selected
           and then Tree.Nodes (Index).Node_Role in
             A11ykit.Role_List_Item | A11ykit.Role_Table_Row
         then
            return Index;
         end if;
      end loop;
      return 0;
   end First_Selected;

   procedure Raise_On (Node : Natural; Event_Id : Native.Native_UInt32; Structure : Boolean := False) is
      Window   : Natural;
      Root_P, Root_O, Provider, Object : Native.Native_UInt64;
      Ignored  : Native.Native_HResult;
   begin
      if Provider_Host = System.Null_Address
        or else Node not in Callback_Context.Window_Of'Range
      then
         return;
      end if;
      Window := Callback_Context.Window_Of (Node);
      Callbacks.Ensure_Export (Callback_Context, (if Window = 0 then Node else Window), Root_P, Root_O);
      Callbacks.Ensure_Export (Callback_Context, Node, Provider, Object);
      if Provider /= 0 then
         Ignored :=
           Native.Raise_Element_Event
             (Provider_Host, Root_P, Provider, Object, Event_Id, (if Structure then 1 else 0));
      end if;
   end Raise_On;

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
      elsif Published then
         Attach_Further_Windows;
      end if;
   end Attach_Window;

   procedure Start is
   begin
      null;
   end Start;

   procedure Stop is
      Result : A11y.Results.Result;
      Object_Release : Exports.Object_Release_Report;
   begin
      Published := False;
      Published_Root := A11y.Node_Ids.No_Node;
      Last_Focus := A11y.Node_Ids.No_Node;
      Last_Selected := 0;
      Callback_Context.Exports := [others => <>];
      if Provider_Host /= System.Null_Address then
         Native.Destroy_Callback_Provider_Host_Window (Provider_Host);
         Provider_Host := System.Null_Address;
      end if;
      if Exports.Is_Valid (Exported_Object) then
         Exports.Release_Object (Object_Table, Exported_Object, Object_Release);
         Exported_Object := Exports.No_COM_Object;
      end if;
      if Registry_API.Is_Valid (Exported_Provider) then
         Registry_API.Release
           (Registry, Session, Exported_Provider, Result);
         Exported_Provider := Registry_API.No_Provider;
      end if;
      Registry_API.Reset_When_Drained (Registry, Result);
      if A11y.Results.Failed (Result) then
         Registry_API.Reset (Registry);
      end if;
      Session := A11y.Native_Identity.No_Session;
   exception
      when others =>
         Published := False;
         Provider_Host := System.Null_Address;
         Exported_Provider := Registry_API.No_Provider;
         Exported_Object := Exports.No_COM_Object;
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
      Delivered : Natural := 0;
      Export_Report : A11y.Windows_Backend.UIA_Public_Roots
        .Public_Root_Export_Report;
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

      if Native.Bridge_Is_Windows = 0 then
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      --  The same window again: keep the session and host a screen reader is
      --  holding on to, swap the snapshot it reads from, and announce a
      --  moved focus. Starting over would hand it a new provider each time.
      if Published and then A11y.Node_Ids."=" (Root, Published_Root) then
         Reset_Snapshots;
         Build_Snapshots (Tree, Root, Session, Snapshots.all, Result);
         if A11y.Results.Failed (Result) then
            Stop;
            Free (Semantic);
            A11ykit.Provider_Runtime.Publish (Tree);
            return;
         end if;

         Attach_Further_Windows;

         --  What changed: each window's children, and the focus, raised on
         --  the element it moved to.
         if Changed then
            declare
               Tops : Window_Nodes;
            begin
               Note_Windows (Last_Tree, Tops);
               for Top of Tops loop
                  if Top /= 0 then
                     Raise_On (Top, 0, Structure => True);
                  end if;
               end loop;
            end;
         end if;
         declare
            Focus : constant A11y.Node_Ids.Node_Id := Snapshots.Fragment.Focused_Node;
         begin
            if not A11y.Node_Ids."=" (Focus, Last_Focus) then
               Last_Focus := Focus;
               Raise_On (A11y.Node_Ids.To_Natural (Focus), 20_005);
               Delivered := 1;
            end if;
         end;
         --  A new single selection is announced with ElementSelected on the
         --  item, which Narrator reads when the selection moves -- whether or
         --  not the keyboard focus moved with it.
         declare
            Selected : constant Natural := First_Selected (Last_Tree);
         begin
            if Selected /= 0 and then Selected /= Last_Selected then
               Raise_On (Selected, 20_012);
               Delivered := Delivered + 1;
            end if;
            Last_Selected := Selected;
         end;

         Free (Semantic);
         A11ykit.Provider_Runtime.Record_Publish_Result
           (A11y.Results.Success, Delivered, Backend_Name, False, A11y.Results.Success);
         return;
      end if;

      Stop;
      Reset_Snapshots;
      Session := A11y.Native_Identity.Create_Session;
      Build_Snapshots (Tree, Root, Session, Snapshots.all, Result);
      if A11y.Results.Failed (Result) then
         Stop;
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      A11y.Windows_Backend.UIA_Public_Roots.Export_Public_Root
        (Registry, Object_Table, Session, Root, Root, Export_Report);
      if Export_Report.Status /= A11y.Results.Success
        or else not Export_Report.Provider_Initialized
        or else not Export_Report.Object_Exported
        or else not Export_Report.Fragment_Interface_Queryable
        or else not Export_Report.Simple_Interface_Queryable
        or else not Export_Report.Fragment_Root_Interface_Queryable
      then
         Stop;
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Exported_Provider := Export_Report.Provider;
      Exported_Object := Export_Report.Object_Export.Token;
      Provider_Host := Create_Callback_Host;
      Published := Provider_Host /= System.Null_Address;
      if Published then
         Published_Root := Root;
         Last_Focus := Snapshots.Fragment.Focused_Node;
         Last_Selected := First_Selected (Tree);
         --  Navigation back to the root names the root's own provider.
         Callback_Context.Exports := [others => <>];
         if A11y.Node_Ids.To_Natural (Root) in Callback_Context.Exports'Range then
            Callback_Context.Exports (A11y.Node_Ids.To_Natural (Root)) :=
              (Provider => Native.Native_UInt64 (Registry_API.To_Natural (Exported_Provider)),
               Object   => Native.Native_UInt64 (Exports.To_Natural (Exported_Object)));
         end if;
         Native.Set_Callback_Provider_Host_Navigation
           (Provider_Host, Callbacks.Navigation_Callback'Access);
         Attached_Node (2 .. Max_Windows) := [others => 0];
         Attach_Host;
         Attach_Further_Windows;
      end if;
      if not Published then
         Stop;
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Publish_Queued_Events (Semantic.all, Delivered, Result);
      if A11y.Results.Failed (Result) then
         Stop;
         Free (Semantic);
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Free (Semantic);
      A11ykit.Provider_Runtime.Record_Publish_Result
        (A11y.Results.Success,
         Delivered,
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
   --  Answer the screen reader's requests to the provider's window.
   procedure Service is
   begin
      if Provider_Host /= System.Null_Address then
         Native.Pump_Callback_Provider_Host_Window (Provider_Host);
      end if;
   end Service;

   --  The window system activates the window itself; announce where the
   --  focus is in it, so the screen reader starts from there.
   procedure Set_Active (Active : Boolean) is
   begin
      if Active and then Published and then A11y.Node_Ids.Is_Valid (Last_Focus) then
         Raise_On (A11y.Node_Ids.To_Natural (Last_Focus), 20_005);
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
