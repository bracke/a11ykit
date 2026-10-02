with System;

with A11ykit.Compatibility;
with A11ykit.Provider_Runtime;

with A11y.Actions;
with A11y.Capabilities;
with A11y.Events;
with A11y.Geometry;
with A11y.Native_Identity;
with A11y.Node_Ids;
with A11y.Platforms;
with A11y.Properties;
with A11y.Results;
with A11y.Roles;
with A11y.Selection;
with A11y.Semantic_Snapshots;
with A11y.Sessions;
with A11y.States;
with A11y.Trees;
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

   use type A11y.Results.Status_Code;
   use type A11y.Properties.Property_Status;
   use type A11y.Native_Identity.Backend_Session_Id;
   use type Native.Native_UInt32;
   use type Native.Native_HResult;
   use type System.Address;

   Registry : aliased Registry_API.Provider_Registry;
   Object_Table : aliased Exports.COM_Object_Export_Table;
   Snapshots : aliased Router.Snapshot_Bundle;
   Callback_Context : aliased Callbacks.Callback_Context :=
     (Object_Table => Object_Table'Access,
      Registry     => Registry'Access,
      Snapshots    => Snapshots'Access,
      others       => <>);
   Session : A11y.Native_Identity.Backend_Session_Id :=
     A11y.Native_Identity.No_Session;
   Published : Boolean := False;
   Exported_Provider : Registry_API.Provider_Id :=
     Registry_API.No_Provider;
   Exported_Object : Exports.COM_Object_Token := Exports.No_COM_Object;
   Provider_Host : System.Address := System.Null_Address;

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

   procedure Add_Default_Actions
     (Metadata : A11y.Semantic_Snapshots.Node_Metadata;
      Actions  : in out A11y.Actions.Action_Set)
   is
      use type A11y.Roles.Role;
   begin
      Actions := A11y.Actions.Empty_Action_Set;
      if Metadata.Capabilities (A11y.Capabilities.Action) then
         Actions (A11y.Actions.Activate) := True;
         Actions (A11y.Actions.Press) := True;
      end if;

      if Metadata.States (A11y.States.Focusable) then
         Actions (A11y.Actions.Set_Focus) := True;
      end if;

      if Metadata.States (A11y.States.Expandable) then
         Actions (A11y.Actions.Expand) := True;
         Actions (A11y.Actions.Collapse) := True;
      end if;

      if Metadata.Role in A11y.Roles.Window | A11y.Roles.Dialog then
         Actions (A11y.Actions.Close) := True;
      end if;

      Actions (A11y.Actions.Scroll_Into_View) := True;
   end Add_Default_Actions;

   procedure Build_Snapshots
     (Tree      : A11ykit.Tree.Accessibility_Tree;
      Root      : A11y.Node_Ids.Node_Id;
      Session   : A11y.Native_Identity.Backend_Session_Id;
      Snapshots : out Router.Snapshot_Bundle;
      Result    : out A11y.Results.Result)
   is
      Metadata : A11y.Semantic_Snapshots.Node_Metadata;
      Check    : A11y.Results.Result;
      Focused  : A11y.Node_Ids.Node_Id :=
        A11ykit.Compatibility.Focused_Node (Tree);
   begin
      Snapshots := (others => <>);
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
                in Snapshots.Fragment.Bounds'Range
              and then Metadata.Bounds.Status = A11y.Properties.Present
            then
               Snapshots.Fragment.Bounds
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

      if not A11y.Node_Ids.Is_Valid (Focused) then
         Focused := Root;
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
      Snapshots.Properties.Name := Metadata.Name;
      Snapshots.Properties.Visible_Title := Metadata.Visible_Title;
      Snapshots.Properties.Automation_Id := Metadata.Semantic_Identifier;
      Snapshots.Properties.Description := Metadata.Description;
      Snapshots.Properties.Value_Text := Metadata.Value_Text;
      Snapshots.Properties.Protected_Value_Text :=
        Metadata.Protected_Value_Text;
      Snapshots.Properties.Help_Text := Metadata.Help_Text;
      Snapshots.Properties.Placeholder := Metadata.Placeholder;
      Snapshots.Properties.Keyboard_Shortcut := Metadata.Keyboard_Shortcut;
      Snapshots.Properties.Locale := Metadata.Locale;
      Snapshots.Properties.Orientation := Metadata.Orientation;
      Snapshots.Properties.Landmark := Metadata.Landmark;
      Snapshots.Properties.Use_Tree_Projection := True;
      Snapshots.Properties.Use_Node_Metadata := True;
      Snapshots.Properties.Defunct := False;

      Snapshots.Fragment.Session := Session;
      Snapshots.Fragment.Fragment_Root := Root;
      Snapshots.Fragment.Tree := Snapshots.Properties.Tree;
      Snapshots.Fragment.Node := Root;
      Snapshots.Fragment.Focused_Node := Focused;
      Snapshots.Fragment.Hit_Test_Point := Snapshots.Properties.Bounds.Origin;

      Add_Default_Actions (Metadata, Snapshots.Actions);
      Snapshots.Action_Node := Root;
      Snapshots.Action_Root := Root;
      Snapshots.Action_Tree := Snapshots.Properties.Tree;
      Snapshots.Action_Use_Tree_Projection := True;
      Snapshots.Action_States := Metadata.States;

      Snapshots.Relation_Source := Root;
      Snapshots.Relation_Root := Root;
      Snapshots.Relation_Tree := Snapshots.Properties.Tree;
      Snapshots.Relation_Use_Tree_Projection := True;

      Snapshots.Event_Root := Root;
      Snapshots.Event_Tree := Snapshots.Properties.Tree;
      Snapshots.Event_Use_Tree_Projection := True;

      Snapshots.Selection.Root := Root;
      Snapshots.Selection.Item := Focused;
      A11y.Selection.Configure
        (Snapshots.Selection.Selection, A11y.Selection.Single);

      Result := A11y.Results.Ok;
   exception
      when others =>
         Result := (Status => A11y.Results.Internal_Error);
   end Build_Snapshots;

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

   procedure Start is
   begin
      null;
   end Start;

   procedure Stop is
      Result : A11y.Results.Result;
      Object_Release : Exports.Object_Release_Report;
   begin
      Published := False;
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
      Root : A11y.Node_Ids.Node_Id;
      Result : A11y.Results.Result;
      Semantic : A11y.Sessions.Semantic_Session;
      Delivered : Natural := 0;
      Export_Report : A11y.Windows_Backend.UIA_Public_Roots
        .Public_Root_Export_Report;
   begin
      Root := Root_Node (Tree, Result);
      if A11y.Results.Failed (Result) then
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      A11ykit.Compatibility.Populate_Session (Tree, Semantic, Result);
      if A11y.Results.Failed (Result) then
         A11ykit.Provider_Runtime.Record_Publish_Result
           (Result.Status, 0, Backend_Name, False, Result.Status);
         return;
      end if;

      if Native.Bridge_Is_Windows = 0 then
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Stop;
      Session := A11y.Native_Identity.Create_Session;
      Build_Snapshots (Tree, Root, Session, Snapshots, Result);
      if A11y.Results.Failed (Result) then
         Stop;
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
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Exported_Provider := Export_Report.Provider;
      Exported_Object := Export_Report.Object_Export.Token;
      Provider_Host := Create_Callback_Host;
      Published := Provider_Host /= System.Null_Address;
      if not Published then
         Stop;
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      Publish_Queued_Events (Semantic, Delivered, Result);
      if A11y.Results.Failed (Result) then
         Stop;
         A11ykit.Provider_Runtime.Publish (Tree);
         return;
      end if;

      A11ykit.Provider_Runtime.Record_Publish_Result
        (A11y.Results.Success,
         Delivered,
         Backend_Name,
         False,
         A11y.Results.Success);
   exception
      when others =>
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
